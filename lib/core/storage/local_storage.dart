/// Stockage local pour Mukhliss.
library;

// ============================================================
// MUKHLISS - Stockage Local
// ============================================================
//
// Wrapper autour de SharedPreferences pour un accès typé et sécurisé.

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../logger/app_logger.dart';

/// Service de stockage local centralisé
class LocalStorage {
  static SharedPreferences? _prefs;

  /// Initialise le stockage local (à appeler dans main())
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.info('LocalStorage initialisé', tag: 'Storage');
  }

  /// Vérifie si le stockage est initialisé
  static bool get isInitialized => _prefs != null;

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError(
        'LocalStorage non initialisé. Appelez LocalStorage.init() dans main()',
      );
    }
    return _prefs!;
  }

  // ============================================================
  // MÉTHODES GÉNÉRIQUES
  // ============================================================

  /// Récupère une chaîne
  static String? getString(String key) {
    return _instance.getString(key);
  }

  /// Sauvegarde une chaîne
  static Future<bool> setString(String key, String value) {
    return _instance.setString(key, value);
  }

  /// Récupère un entier
  static int? getInt(String key) {
    return _instance.getInt(key);
  }

  /// Sauvegarde un entier
  static Future<bool> setInt(String key, int value) {
    return _instance.setInt(key, value);
  }

  /// Récupère un booléen
  static bool? getBool(String key) {
    return _instance.getBool(key);
  }

  /// Sauvegarde un booléen
  static Future<bool> setBool(String key, bool value) {
    return _instance.setBool(key, value);
  }

  /// Récupère un double
  static double? getDouble(String key) {
    return _instance.getDouble(key);
  }

  /// Sauvegarde un double
  static Future<bool> setDouble(String key, double value) {
    return _instance.setDouble(key, value);
  }

  /// Récupère une liste de chaînes
  static List<String>? getStringList(String key) {
    return _instance.getStringList(key);
  }

  /// Sauvegarde une liste de chaînes
  static Future<bool> setStringList(String key, List<String> value) {
    return _instance.setStringList(key, value);
  }

  /// Supprime une clé
  static Future<bool> remove(String key) {
    return _instance.remove(key);
  }

  /// Vérifie si une clé existe
  static bool containsKey(String key) {
    return _instance.containsKey(key);
  }

  /// Efface tout le stockage
  static Future<bool> clear() {
    AppLogger.warning('Stockage local effacé', tag: 'Storage');
    return _instance.clear();
  }

  // ============================================================
  // MÉTHODES SPÉCIFIQUES À L'APP
  // ============================================================

  // --- Thème ---

  /// Récupère le thème sauvegardé
  static String? getTheme() {
    return getString(AppConstants.themeKey);
  }

  /// Sauvegarde le thème
  static Future<bool> setTheme(String theme) {
    return setString(AppConstants.themeKey, theme);
  }

  // --- Langue ---

  /// Récupère la langue sauvegardée
  static String? getLanguage() {
    return getString(AppConstants.languageKey);
  }

  /// Sauvegarde la langue
  static Future<bool> setLanguage(String languageCode) {
    return setString(AppConstants.languageKey, languageCode);
  }

  // --- Onboarding ---

  /// Vérifie si l'onboarding est complété
  static bool isOnboardingComplete() {
    return getBool(AppConstants.onboardingCompleteKey) ?? false;
  }

  /// Marque l'onboarding comme complété
  static Future<bool> setOnboardingComplete() {
    return setBool(AppConstants.onboardingCompleteKey, true);
  }

  // --- Device ID ---

  /// Récupère l'ID de l'appareil
  static String? getDeviceId() {
    return getString(AppConstants.deviceIdKey);
  }

  /// Sauvegarde l'ID de l'appareil
  static Future<bool> setDeviceId(String deviceId) {
    return setString(AppConstants.deviceIdKey, deviceId);
  }

  // --- User ID ---

  /// Récupère l'ID de l'utilisateur
  static String? getUserId() {
    return getString(AppConstants.userIdKey);
  }

  /// Sauvegarde l'ID de l'utilisateur
  static Future<bool> setUserId(String userId) {
    return setString(AppConstants.userIdKey, userId);
  }

  /// Supprime l'ID de l'utilisateur (déconnexion)
  static Future<bool> clearUserId() {
    return remove(AppConstants.userIdKey);
  }

  // ============================================================
  // MÉTHODES DE DÉCONNEXION
  // ============================================================

  /// Efface les données de session (garde les préférences)
  ///
  /// Note: Les tokens sont maintenant gérés par [SecureStorage]
  /// Cette méthode ne gère que les données non-sensibles
  static Future<void> clearSession() async {
    // Les tokens sont maintenant dans SecureStorage
    // Voir: SecureStorage.clearSession()
    await remove(AppConstants.userIdKey);
    AppLogger.info('Session effacée (local storage)', tag: 'Storage');
  }

  // ============================================================
  // ⚠️ DEPRECATED - Utiliser SecureStorage
  // ============================================================

  /// @deprecated Utiliser SecureStorage.getAuthToken() à la place
  @Deprecated('Utiliser SecureStorage.getAuthToken() pour les tokens')
  static String? getAuthToken() {
    return getString(AppConstants.authTokenKey);
  }

  /// @deprecated Utiliser SecureStorage.setAuthToken() à la place
  @Deprecated('Utiliser SecureStorage.setAuthToken() pour les tokens')
  static Future<bool> setAuthToken(String token) {
    return setString(AppConstants.authTokenKey, token);
  }
}
