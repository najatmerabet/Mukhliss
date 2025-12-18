/// ============================================================
/// Logo Storage Service - Gestion Storage Supabase
/// ============================================================
///
/// Service pour uploader, gérer et optimiser les logos
/// des magasins dans Supabase Storage.
library;

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Configuration du storage
class LogoStorageConfig {
  /// Nom du bucket Supabase
  static const String bucketName = 'store-logos';
  
  /// Tailles des variantes à générer
  static const List<int> variantSizes = [64, 256, 512];
  
  /// Qualité de compression WebP
  static const int webpQuality = 80;
  
  /// Taille max upload (5 MB)
  static const int maxUploadSizeBytes = 5 * 1024 * 1024;
}

/// Résultat d'upload
class LogoUploadResult {
  final bool success;
  final String? originalUrl;
  final Map<int, String>? variantUrls;
  final String? errorMessage;

  LogoUploadResult({
    required this.success,
    this.originalUrl,
    this.variantUrls,
    this.errorMessage,
  });

  factory LogoUploadResult.error(String message) => LogoUploadResult(
    success: false,
    errorMessage: message,
  );

  factory LogoUploadResult.ok({
    required String originalUrl,
    required Map<int, String> variantUrls,
  }) => LogoUploadResult(
    success: true,
    originalUrl: originalUrl,
    variantUrls: variantUrls,
  );
}

/// Service de gestion du storage des logos
class LogoStorageService {
  static LogoStorageService? _instance;
  static LogoStorageService get instance => _instance ??= LogoStorageService._();

  LogoStorageService._();

  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  /// Uploader un logo avec génération automatique des variantes
  Future<LogoUploadResult> uploadLogo({
    required Uint8List imageBytes,
    required String storeId,
    String? mimeType,
  }) async {
    try {
      // Vérifier la taille
      if (imageBytes.length > LogoStorageConfig.maxUploadSizeBytes) {
        return LogoUploadResult.error(
          'Image trop grande. Maximum: ${LogoStorageConfig.maxUploadSizeBytes ~/ (1024 * 1024)} MB',
        );
      }

      final fileId = _uuid.v4();
      final extension = _getExtension(mimeType);

      // 1. Upload de l'original
      final originalPath = 'original/${storeId}_$fileId.$extension';
      await _supabase.storage
          .from(LogoStorageConfig.bucketName)
          .uploadBinary(originalPath, imageBytes);

      final originalUrl = _supabase.storage
          .from(LogoStorageConfig.bucketName)
          .getPublicUrl(originalPath);

      // 2. Générer et uploader les variantes
      final variantUrls = <int, String>{};
      
      for (final size in LogoStorageConfig.variantSizes) {
        final resizedBytes = await compute(
          _resizeImage,
          _ResizeParams(imageBytes, size),
        );

        if (resizedBytes != null) {
          final variantPath = 'variants/${size}x${size}/${storeId}_$fileId.webp';
          
          await _supabase.storage
              .from(LogoStorageConfig.bucketName)
              .uploadBinary(
                variantPath,
                resizedBytes,
                fileOptions: const FileOptions(contentType: 'image/webp'),
              );

          variantUrls[size] = _supabase.storage
              .from(LogoStorageConfig.bucketName)
              .getPublicUrl(variantPath);
        }
      }

      debugPrint('✅ Logo uploadé: $storeId');
      debugPrint('   Original: $originalUrl');
      debugPrint('   Variantes: ${variantUrls.keys.join(', ')}px');

      return LogoUploadResult.ok(
        originalUrl: originalUrl,
        variantUrls: variantUrls,
      );
    } catch (e) {
      debugPrint('❌ Erreur upload logo: $e');
      return LogoUploadResult.error(e.toString());
    }
  }

  /// Supprimer un logo et toutes ses variantes
  Future<bool> deleteLogo(String storeId) async {
    try {
      final List<FileObject> files = await _supabase.storage
          .from(LogoStorageConfig.bucketName)
          .list(path: 'original');

      final filesToDelete = <String>[];

      // Trouver les fichiers de ce store
      for (final file in files) {
        if (file.name.startsWith('${storeId}_')) {
          filesToDelete.add('original/${file.name}');
          
          // Ajouter les variantes
          for (final size in LogoStorageConfig.variantSizes) {
            final variantName = file.name.replaceAll(
              RegExp(r'\.(jpg|jpeg|png|gif|webp)$'),
              '.webp',
            );
            filesToDelete.add('variants/${size}x$size/$variantName');
          }
        }
      }

      if (filesToDelete.isNotEmpty) {
        await _supabase.storage
            .from(LogoStorageConfig.bucketName)
            .remove(filesToDelete);
        debugPrint('🗑️ Logo supprimé: $storeId (${filesToDelete.length} fichiers)');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression logo: $e');
      return false;
    }
  }

  /// Obtenir l'URL optimisée pour une taille spécifique
  String getOptimizedUrl(String originalUrl, {int size = 64}) {
    // Si pas d'URL, retourner vide
    if (originalUrl.isEmpty) return '';

    // Utiliser la transformation Supabase Storage
    try {
      final uri = Uri.parse(originalUrl);
      
      // Ajouter les paramètres de transformation
      final params = Map<String, String>.from(uri.queryParameters);
      params['width'] = size.toString();
      params['height'] = size.toString();
      params['resize'] = 'cover';
      params['format'] = 'webp';
      params['quality'] = LogoStorageConfig.webpQuality.toString();

      return uri.replace(queryParameters: params).toString();
    } catch (e) {
      return originalUrl;
    }
  }

  /// Vérifier si le bucket existe, sinon le créer
  Future<void> ensureBucketExists() async {
    try {
      final buckets = await _supabase.storage.listBuckets();
      final exists = buckets.any((b) => b.name == LogoStorageConfig.bucketName);

      if (!exists) {
        await _supabase.storage.createBucket(
          LogoStorageConfig.bucketName,
          const BucketOptions(public: true),
        );
        debugPrint('✅ Bucket créé: ${LogoStorageConfig.bucketName}');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur vérification bucket: $e');
    }
  }

  /// Obtenir les statistiques de storage
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final originalFiles = await _supabase.storage
          .from(LogoStorageConfig.bucketName)
          .list(path: 'original');

      int totalSize = 0;
      for (final file in originalFiles) {
        totalSize += file.metadata?['size'] as int? ?? 0;
      }

      return {
        'totalLogos': originalFiles.length,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  String _getExtension(String? mimeType) {
    switch (mimeType) {
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      default:
        return 'jpg';
    }
  }
}

/// Paramètres pour le redimensionnement
class _ResizeParams {
  final Uint8List bytes;
  final int size;
  _ResizeParams(this.bytes, this.size);
}

/// Fonction de redimensionnement (exécutée en isolate)
Uint8List? _resizeImage(_ResizeParams params) {
  try {
    final image = img.decodeImage(params.bytes);
    if (image == null) return null;

    // Redimensionner en gardant le ratio
    final resized = img.copyResizeCropSquare(image, size: params.size);

    // Encoder en WebP
    return Uint8List.fromList(
      img.encodeJpg(resized, quality: LogoStorageConfig.webpQuality),
    );
  } catch (e) {
    debugPrint('⚠️ Erreur redimensionnement: $e');
    return null;
  }
}
