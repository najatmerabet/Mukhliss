/// ============================================================
/// MUKHLISS - Stockage Sécurisé
/// ============================================================
///
/// Utilise flutter_secure_storage pour stocker les données sensibles
/// de manière chiffrée (Keychain iOS / EncryptedSharedPreferences Android).
///
/// Usage:
/// ```dart
/// await SecureStorage.setAuthToken('token_ici');
/// final token = await SecureStorage.getAuthToken();
/// ```
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service de stockage sécurisé pour les données sensibles
class SecureStorage {
  // === Configuration ===
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // resetOnError: true pour éviter les crashes si le keystore est corrompu
      // Attention: cela supprime les données stockées
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      // Accessible après le premier déverrouillage
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // === Clés ===
  static const _authTokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';

  // ============================================================
  // AUTH TOKEN
  // ============================================================

  /// Sauvegarde le token d'authentification
  static Future<void> setAuthToken(String token) async {
    try {
      await _storage.write(key: _authTokenKey, value: token);
      debugPrint('🔐 Auth token saved securely');
    } catch (e) {
      debugPrint('❌ Failed to save auth token: $e');
      rethrow;
    }
  }

  /// Récupère le token d'authentification
  static Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _authTokenKey);
    } catch (e) {
      debugPrint('❌ Failed to read auth token: $e');
      return null;
    }
  }

  /// Supprime le token d'authentification
  static Future<void> deleteAuthToken() async {
    try {
      await _storage.delete(key: _authTokenKey);
      debugPrint('🔐 Auth token deleted');
    } catch (e) {
      debugPrint('❌ Failed to delete auth token: $e');
    }
  }

  // ============================================================
  // REFRESH TOKEN
  // ============================================================

  /// Sauvegarde le refresh token
  static Future<void> setRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      debugPrint('🔐 Refresh token saved securely');
    } catch (e) {
      debugPrint('❌ Failed to save refresh token: $e');
      rethrow;
    }
  }

  /// Récupère le refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Failed to read refresh token: $e');
      return null;
    }
  }

  /// Supprime le refresh token
  static Future<void> deleteRefreshToken() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Failed to delete refresh token: $e');
    }
  }

  // ============================================================
  // USER ID
  // ============================================================

  /// Sauvegarde l'ID utilisateur
  static Future<void> setUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
    } catch (e) {
      debugPrint('❌ Failed to save user ID: $e');
      rethrow;
    }
  }

  /// Récupère l'ID utilisateur
  static Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('❌ Failed to read user ID: $e');
      return null;
    }
  }

  // ============================================================
  // SESSION MANAGEMENT
  // ============================================================

  /// Efface toutes les données de session (déconnexion)
  static Future<void> clearSession() async {
    try {
      await Future.wait([
        _storage.delete(key: _authTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
      ]);
      debugPrint('🔐 Session cleared from secure storage');
    } catch (e) {
      debugPrint('❌ Failed to clear session: $e');
    }
  }

  /// Efface TOUT le stockage sécurisé
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      debugPrint('🔐 All secure storage cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear all secure storage: $e');
    }
  }

  /// Vérifie si un utilisateur est connecté (token présent)
  static Future<bool> hasSession() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
