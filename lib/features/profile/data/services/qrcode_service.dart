import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mukhliss/core/logger/app_logger.dart';

class QrcodeService {
  final SupabaseClient client = Supabase.instance.client;
  static const String _qrCacheKey = 'cached_qr_data';
  static const String _lastUserIdKey = 'last_user_id';
  final Connectivity _connectivity = Connectivity();

  // Vérifier la connexion internet avec test DNS
  Future<bool> get isConnected async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Test de connectivité réelle avec DNS lookup
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Méthode pour gérer l'authentification avec gestion d'erreur
  Future<User?> _getCurrentUserSafely() async {
    try {
      // Vérifier d'abord la session locale
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      // Vérifier si la session est expirée
      final session = client.auth.currentSession;
      if (session == null || session.expiresAt == null) {
        return null;
      }

      // Vérifier l'expiration
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (session.expiresAt! <= now) {
        // Session expirée, essayer de la rafraîchir seulement si en ligne
        if (await isConnected) {
          try {
            await client.auth.refreshSession();
            return client.auth.currentUser;
          } catch (e) {
            // Impossible de rafraîchir, mais on peut continuer avec les données en cache
            AppLogger.warning(
              'Failed to refresh session',
              tag: 'QRCode',
              error: e,
            );
            return currentUser; // Retourner l'utilisateur expiré pour accéder au cache
          }
        }
      }

      return currentUser;
    } catch (e) {
      AppLogger.warning('Error getting current user', tag: 'QRCode', error: e);
      // Retourner null si impossible d'obtenir l'utilisateur
      return null;
    }
  }

  
 // Récupérer les données du client avec gestion d'erreur améliorée
Future<Map<String, dynamic>> _getClientData() async {
  final prefs = await SharedPreferences.getInstance();
  String? currentUserId;

  try {
    // Obtenir l'utilisateur de manière sécurisée
    final user = await _getCurrentUserSafely();
    if (user == null) {
      final cachedData = prefs.getString(_qrCacheKey);
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        data['_isCached'] = true;
        data['_isOffline'] = true;
        return data;
      }
      throw Exception('User not authenticated and no cached data available');
    }
    
    currentUserId = user.id;

    // Vérifier si l'utilisateur a changé
    final lastUserId = prefs.getString(_lastUserIdKey);
    if (lastUserId != null && lastUserId != user.id) {
      AppLogger.info(
        'User changed from $lastUserId to ${user.id} - clearing cache',
        tag: 'QRCode',
      );
      await prefs.remove(_qrCacheKey);
    }

    await prefs.setString(_lastUserIdKey, user.id);

    // Si pas de connexion, utiliser le cache
    if (!await isConnected) {
      final cachedData = prefs.getString(_qrCacheKey);
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        if (data['id'] == user.id) {
          data['_isCached'] = true;
          data['_isOffline'] = true;
          return data;
        } else {
          await prefs.remove(_qrCacheKey);
          AppLogger.warning(
            'Cache belongs to different user - cleared',
            tag: 'QRCode',
          );
        }
      }
      throw Exception('No internet connection and no cached data available');
    }

    // ✅ SOLUTION : Essayer de récupérer le profil
    final response = await client
        .from('clients')
        .select()
        .eq('id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 8));

    // ✅ Si aucun profil n'existe, créer automatiquement
    if (response == null) {
      AppLogger.info(
        'Première connexion détectée - Création automatique du profil pour: ${user.id}',
        tag: 'QRCode',
      );
      
      return await _createUserProfile(user, prefs);
    }

    // Profil existant trouvé, le mettre en cache
    response['_isCached'] = false;
    response['_isOffline'] = false;
    response['_lastUpdate'] = DateTime.now().toIso8601String();
    await prefs.setString(_qrCacheKey, jsonEncode(response));

    return response;
  } on SocketException catch (e) {
    return _handleFallbackToCache(prefs, 'Network error: ${e.message}', currentUserId: currentUserId);
  } on TimeoutException {
    return _handleFallbackToCache(prefs, 'Request timeout', currentUserId: currentUserId);
  } on PostgrestException catch (e) {
    return _handleFallbackToCache(prefs, 'Database error: ${e.message}', currentUserId: currentUserId);
  } on AuthException catch (e) {
    return _handleFallbackToCache(
      prefs,
      'Authentication error: ${e.message}',
      currentUserId: currentUserId,
    );
  } catch (e) {
    return _handleFallbackToCache(prefs, 'Unexpected error: $e', currentUserId: currentUserId);
  }
}


Future<Map<String, dynamic>> _createUserProfile(
  User user,
  SharedPreferences prefs,
) async {
  try {
    // Générer un code unique aléatoire (6 chiffres)
    final codeUnique = _generateUniqueCode();
    
    // Créer le profil avec les données de l'auth user
    final newProfile = {
      'id': user.id,
      'email': user.email ?? '',
      'nom': user.userMetadata?['nom'] ?? user.userMetadata?['last_name'] ?? '',
      'prenom': user.userMetadata?['prenom'] ?? user.userMetadata?['first_name'] ?? '',
      'tel': user.userMetadata?['tel'] ?? user.phone ?? '',
      'adr': user.userMetadata?['adr'] ?? user.userMetadata?['address'] ?? '',
      'code_unique': codeUnique,
      'created_at': DateTime.now().toIso8601String(),
    };

    AppLogger.info(
      'Insertion du nouveau profil dans la base de données...',
      tag: 'QRCode',
    );

    // Insérer dans la base de données
    await client.from('clients').insert(newProfile);

    AppLogger.info(
      'Profil créé avec succès - Code unique: $codeUnique',
      tag: 'QRCode',
    );

    // Mettre en cache
    newProfile['_isCached'] = false;
    newProfile['_isOffline'] = false;
    newProfile['_lastUpdate'] = DateTime.now().toIso8601String();
    await prefs.setString(_qrCacheKey, jsonEncode(newProfile));

    return newProfile;
  } catch (e) {
    AppLogger.error(
      'Erreur lors de la création du profil automatique',
      tag: 'QRCode',
      error: e,
    );
    
    // ✅ Si l'insertion échoue, retourner quand même un profil temporaire
    // pour que l'utilisateur puisse voir son QR code
    final tempProfile = {
      'id': user.id,
      'email': user.email ?? '',
      'nom': user.userMetadata?['nom'] ?? '',
      'prenom': user.userMetadata?['prenom'] ?? '',
      'tel': user.userMetadata?['tel'] ?? user.phone ?? '',
      'adr': user.userMetadata?['adr'] ?? '',
      'code_unique': null, // Pas de code unique si échec
      '_isCached': false,
      '_isOffline': false,
      '_isTemporary': true, // Flag pour indiquer que c'est temporaire
    };
    
    return tempProfile;
  }
}

  // Méthode pour gérer le fallback vers le cache
  
  Future<Map<String, dynamic>> _handleFallbackToCache(
    SharedPreferences prefs,
    String error, {
    String? currentUserId,
  }) async {
    AppLogger.debug('Falling back to cache due to: $error', tag: 'QRCode');

    final cachedData = prefs.getString(_qrCacheKey);
    if (cachedData != null) {
      final data = jsonDecode(cachedData);
      
      // Vérifier que le cache appartient à l'utilisateur actuel
      if (currentUserId != null && data['id'] != currentUserId) {
        AppLogger.warning(
          'Cache belongs to different user (cache=${data['id']}, current=$currentUserId) - not using',
          tag: 'QRCode',
        );
        await prefs.remove(_qrCacheKey);
        throw Exception('$error and cache belongs to different user');
      }
      
      data['_isCached'] = true;
      data['_isOffline'] = true;
      data['_error'] = error;
      return data;
    }

    throw Exception('$error and no cached data available');
  }

  // Créer un QR code pour le client
  String _getQrCodeData(Map<String, dynamic> clientData) {
    final secureData = {
      'user_id': clientData['id'],
      'nom': clientData['nom'],
      'prenom': clientData['prenom'],
      'email': clientData['email'],
      'address': clientData['adr'],
      'phone': clientData['tel'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'is_cached': clientData['_isCached'] ?? false,
      'is_offline': clientData['_isOffline'] ?? false,
      'version': '1.0',
    };
    return jsonEncode(secureData);
  }

  Future<Widget> generateUserQR() async {
    try {
      final userData = await _getClientData();
      final qrData = _getQrCodeData(userData);

      return Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.blue,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return _buildErrorWidget(e.toString());
    }
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> getQRDataString() async {
    try {
      final userData = await _getClientData();
      return _getQrCodeData(userData);
    } catch (e) {
      throw Exception('Failed to get QR data: $e');
    }
  }

  // Méthode pour nettoyer le cache si nécessaire
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_qrCacheKey);
    await prefs.remove(_lastUserIdKey);
  }

  // Méthode pour vérifier l'état du cache
  Future<bool> hasCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_qrCacheKey);
  }

  // Dans qrcode_service.dart
  Future<int?> getCurrentUserCode() async {
    try {
      final clientData = await _getClientData();

      // Vérifier si le champ code_unique existe
      if (clientData.containsKey('code_unique')) {
        final codeValue = clientData['code_unique'];

        // Gérer les différents types possibles
        if (codeValue is int) {
          return codeValue;
        } else if (codeValue is String) {
          return int.tryParse(codeValue);
        } else if (codeValue is double) {
          return codeValue.toInt();
        }
      }

      return null;
    } catch (e) {
      AppLogger.warning('Error getting user code', tag: 'QRCode', error: e);
      return null;
    }
  }

  int _generateUniqueCode() {
  // Génère un nombre entre 100000 et 999999
  final random = DateTime.now().microsecondsSinceEpoch % 900000;
  return 100000 + random;
}
}
