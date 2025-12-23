/// ============================================================
/// Logo Cache Service - Gestion Haute Performance des Logos
/// ============================================================
///
/// Service de cache multi-niveau pour gérer efficacement
/// des milliers de logos de magasins.
///
/// Architecture:
/// - Niveau 1: Mémoire (LRU Cache - accès < 1ms)
/// - Niveau 2: Disque (Hive - accès < 10ms)
/// - Niveau 3: CDN Supabase (accès ~100-500ms)
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Tailles de logos disponibles
enum LogoSize {
  thumbnail(64),   // Pour les marqueurs de carte
  medium(256),     // Pour les bottom sheets
  large(512);      // Pour les pages de détail

  final int pixels;
  const LogoSize(this.pixels);
}

/// Configuration du cache
class LogoCacheConfig {
  /// Nombre max d'images en mémoire
  static const int memoryCacheSize = 100;
  
  /// Nombre max d'images sur disque
  static const int diskCacheSize = 1000;
  
  /// Durée de validité du cache disque (jours)
  static const int cacheValidityDays = 7;
  
  /// Timeout pour les requêtes HTTP
  static const Duration httpTimeout = Duration(seconds: 10);
  
  /// Nombre de retries pour les téléchargements
  static const int maxRetries = 3;
}

/// Entrée de cache avec métadonnées
class CacheEntry {
  final Uint8List data;
  final DateTime cachedAt;
  final String etag;

  CacheEntry({
    required this.data,
    required this.cachedAt,
    this.etag = '',
  });

  bool get isExpired {
    final expiryDate = cachedAt.add(
      Duration(days: LogoCacheConfig.cacheValidityDays),
    );
    return DateTime.now().isAfter(expiryDate);
  }

  Map<String, dynamic> toJson() => {
    'data': data,
    'cachedAt': cachedAt.toIso8601String(),
    'etag': etag,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    data: json['data'] as Uint8List,
    cachedAt: DateTime.parse(json['cachedAt'] as String),
    etag: json['etag'] as String? ?? '',
  );
}

/// LRU Cache en mémoire
class LruMemoryCache<K, V> {
  final int maxSize;
  final _cache = <K, V>{};
  final _accessOrder = <K>[];

  LruMemoryCache({required this.maxSize});

  V? get(K key) {
    if (_cache.containsKey(key)) {
      // Mettre à jour l'ordre d'accès
      _accessOrder.remove(key);
      _accessOrder.add(key);
      return _cache[key];
    }
    return null;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    } else if (_cache.length >= maxSize) {
      // Supprimer le moins récemment utilisé
      final lruKey = _accessOrder.removeAt(0);
      _cache.remove(lruKey);
    }
    _cache[key] = value;
    _accessOrder.add(key);
  }

  bool containsKey(K key) => _cache.containsKey(key);
  
  void remove(K key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  int get length => _cache.length;
}

/// Service principal de cache des logos
class LogoCacheService {
  static LogoCacheService? _instance;
  static LogoCacheService get instance => _instance ??= LogoCacheService._();

  LogoCacheService._();

  // Cache mémoire (Niveau 1)
  final _memoryCache = LruMemoryCache<String, Uint8List>(
    maxSize: LogoCacheConfig.memoryCacheSize,
  );

  // Cache disque (Niveau 2)
  Box<Uint8List>? _diskCache;
  Box<String>? _metadataCache;

  // Stats de performance
  int _memoryHits = 0;
  int _diskHits = 0;
  int _networkRequests = 0;

  // Requêtes en cours (éviter les doublons)
  final _pendingRequests = <String, Future<Uint8List?>>{};

  /// Initialiser le cache disque
  Future<void> initialize() async {
    if (_diskCache != null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      Hive.init('${dir.path}/logo_cache');
      
      _diskCache = await Hive.openBox<Uint8List>('logos');
      _metadataCache = await Hive.openBox<String>('logos_meta');
      
      // Nettoyer les entrées expirées au démarrage
      await _cleanExpiredEntries();
      
      debugPrint('✅ LogoCacheService initialisé');
      debugPrint('   📦 ${_diskCache!.length} logos en cache disque');
    } catch (e) {
      debugPrint('❌ Erreur init LogoCacheService: $e');
    }
  }

  /// Récupérer un logo (avec cache multi-niveau)
  Future<Uint8List?> getLogo(String logoUrl, {LogoSize size = LogoSize.thumbnail}) async {
    if (logoUrl.isEmpty) return null;

    final cacheKey = _buildCacheKey(logoUrl, size);

    // 1. Vérifier le cache mémoire (< 1ms)
    final memoryResult = _memoryCache.get(cacheKey);
    if (memoryResult != null) {
      _memoryHits++;
      return memoryResult;
    }

    // 2. Vérifier le cache disque (< 10ms)
    final diskResult = await _getFromDisk(cacheKey);
    if (diskResult != null) {
      _diskHits++;
      _memoryCache.put(cacheKey, diskResult); // Promouvoir en mémoire
      return diskResult;
    }

    // 3. Éviter les requêtes en double
    if (_pendingRequests.containsKey(cacheKey)) {
      return _pendingRequests[cacheKey];
    }

    // 4. Télécharger depuis le réseau
    final future = _downloadLogo(logoUrl, size, cacheKey);
    _pendingRequests[cacheKey] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Précharger les logos pour une liste de magasins
  Future<void> preloadLogos(List<String> logoUrls, {LogoSize size = LogoSize.thumbnail}) async {
    final urlsToLoad = <String>[];

    for (final url in logoUrls) {
      if (url.isEmpty) continue;
      final key = _buildCacheKey(url, size);
      if (!_memoryCache.containsKey(key) && !await _existsOnDisk(key)) {
        urlsToLoad.add(url);
      }
    }

    if (urlsToLoad.isEmpty) return;

    debugPrint('🔄 Préchargement de ${urlsToLoad.length} logos...');

    // Charger en parallèle (max 5 à la fois)
    await Future.wait(
      urlsToLoad.take(50).map((url) => getLogo(url, size: size)),
    );
  }

  /// Construire la clé de cache
  String _buildCacheKey(String url, LogoSize size) {
    // Extraire l'ID du fichier de l'URL
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    final filename = pathSegments.isNotEmpty ? pathSegments.last : url.hashCode.toString();
    return '${filename}_${size.pixels}';
  }

  /// Récupérer depuis le cache disque
  Future<Uint8List?> _getFromDisk(String key) async {
    if (_diskCache == null) return null;
    
    try {
      final data = _diskCache!.get(key);
      if (data == null) return null;

      // Vérifier l'expiration
      final metaJson = _metadataCache?.get(key);
      if (metaJson != null) {
        final cachedAt = DateTime.tryParse(metaJson);
        if (cachedAt != null) {
          final expiryDate = cachedAt.add(
            Duration(days: LogoCacheConfig.cacheValidityDays),
          );
          if (DateTime.now().isAfter(expiryDate)) {
            // Expiré, supprimer
            await _diskCache!.delete(key);
            await _metadataCache?.delete(key);
            return null;
          }
        }
      }

      return data;
    } catch (e) {
      debugPrint('⚠️ Erreur lecture cache disque: $e');
      return null;
    }
  }

  /// Vérifier si existe sur disque
  Future<bool> _existsOnDisk(String key) async {
    if (_diskCache == null) return false;
    return _diskCache!.containsKey(key);
  }

  /// Télécharger un logo depuis le réseau
  Future<Uint8List?> _downloadLogo(String url, LogoSize size, String cacheKey) async {
    _networkRequests++;

    // Construire l'URL avec transformation Supabase
    final transformedUrl = _buildTransformedUrl(url, size);

    for (int retry = 0; retry < LogoCacheConfig.maxRetries; retry++) {
      try {
        final response = await http
            .get(Uri.parse(transformedUrl))
            .timeout(LogoCacheConfig.httpTimeout);

        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          
          // Sauvegarder dans les caches
          _memoryCache.put(cacheKey, bytes);
          await _saveToDisk(cacheKey, bytes);
          
          return bytes;
        } else if (response.statusCode == 404) {
          debugPrint('⚠️ Logo non trouvé: $url');
          return null;
        }
      } catch (e) {
        if (retry == LogoCacheConfig.maxRetries - 1) {
          debugPrint('❌ Échec téléchargement logo après $retry retries: $e');
        }
        await Future.delayed(Duration(milliseconds: 100 * (retry + 1)));
      }
    }

    return null;
  }

  /// Construire l'URL avec transformation d'image Supabase
  String _buildTransformedUrl(String originalUrl, LogoSize size) {
    // Si c'est une URL Supabase Storage, ajouter les paramètres de transformation
    if (originalUrl.contains('supabase') && originalUrl.contains('storage')) {
      final uri = Uri.parse(originalUrl);
      final newParams = Map<String, String>.from(uri.queryParameters);
      
      // Paramètres de transformation Supabase
      newParams['width'] = size.pixels.toString();
      newParams['height'] = size.pixels.toString();
      newParams['format'] = 'webp';
      newParams['quality'] = '80';
      
      return uri.replace(queryParameters: newParams).toString();
    }
    
    return originalUrl;
  }

  /// Sauvegarder sur disque
  Future<void> _saveToDisk(String key, Uint8List data) async {
    if (_diskCache == null) return;

    try {
      // Vérifier la limite de taille
      if (_diskCache!.length >= LogoCacheConfig.diskCacheSize) {
        // Supprimer les plus anciennes entrées
        final keysToRemove = _diskCache!.keys.take(100).toList();
        for (final k in keysToRemove) {
          await _diskCache!.delete(k);
          await _metadataCache?.delete(k);
        }
      }

      await _diskCache!.put(key, data);
      await _metadataCache?.put(key, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde cache disque: $e');
    }
  }

  /// Nettoyer les entrées expirées
  Future<void> _cleanExpiredEntries() async {
    if (_diskCache == null || _metadataCache == null) return;

    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final key in _metadataCache!.keys) {
      final metaJson = _metadataCache!.get(key);
      if (metaJson != null) {
        final cachedAt = DateTime.tryParse(metaJson);
        if (cachedAt != null) {
          final expiryDate = cachedAt.add(
            Duration(days: LogoCacheConfig.cacheValidityDays),
          );
          if (now.isAfter(expiryDate)) {
            keysToRemove.add(key);
          }
        }
      }
    }

    for (final key in keysToRemove) {
      await _diskCache!.delete(key);
      await _metadataCache!.delete(key);
    }

    if (keysToRemove.isNotEmpty) {
      debugPrint('🧹 Nettoyé ${keysToRemove.length} logos expirés');
    }
  }

  /// Vider tout le cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    await _diskCache?.clear();
    await _metadataCache?.clear();
    debugPrint('🗑️ Cache logos vidé');
  }

  /// Obtenir les statistiques de performance
  Map<String, dynamic> getStats() {
    final total = _memoryHits + _diskHits + _networkRequests;
    return {
      'memoryHits': _memoryHits,
      'diskHits': _diskHits,
      'networkRequests': _networkRequests,
      'memoryCacheSize': _memoryCache.length,
      'diskCacheSize': _diskCache?.length ?? 0,
      'hitRate': total > 0 ? ((_memoryHits + _diskHits) / total * 100).toStringAsFixed(1) : '0',
    };
  }

  /// Afficher les stats
  void printStats() {
    final stats = getStats();
    debugPrint('''
📊 Logo Cache Stats:
   Memory Hits: ${stats['memoryHits']}
   Disk Hits: ${stats['diskHits']}
   Network Requests: ${stats['networkRequests']}
   Hit Rate: ${stats['hitRate']}%
   Memory Cache: ${stats['memoryCacheSize']} logos
   Disk Cache: ${stats['diskCacheSize']} logos
''');
  }
}
