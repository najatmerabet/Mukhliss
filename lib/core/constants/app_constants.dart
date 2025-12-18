/// Constantes de l'application Mukhliss.
library;

// ============================================================
// MUKHLISS - Constantes de l'Application
// ============================================================

/// Constantes générales de l'application
class AppConstants {
  AppConstants._();

  // ============================================================
  // INFORMATIONS APP
  // ============================================================

  static const String appName = 'Mukhliss';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // ============================================================
  // DURÉES
  // ============================================================

  /// Timeout pour les requêtes API
  static const Duration apiTimeout = Duration(seconds: 30);

  /// Durée d'animation par défaut
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  /// Durée avant expiration de session
  static const Duration sessionTimeout = Duration(hours: 24);

  /// Durée de cache par défaut
  static const Duration defaultCacheDuration = Duration(hours: 1);

  // ============================================================
  // PAGINATION
  // ============================================================

  /// Nombre d'éléments par page par défaut
  static const int defaultPageSize = 20;

  /// Nombre max d'éléments à charger
  static const int maxPageSize = 100;

  // ============================================================
  // VALIDATION
  // ============================================================

  /// Longueur minimum du mot de passe
  static const int minPasswordLength = 8;

  /// Longueur maximum du mot de passe
  static const int maxPasswordLength = 128;

  /// Longueur du code OTP
  static const int otpLength = 6;

  /// Durée de validité OTP
  static const Duration otpValidityDuration = Duration(minutes: 10);

  // ============================================================
  // STOCKAGE CLÉS
  // ============================================================

  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String deviceIdKey = 'device_id';

  // ============================================================
  // LIMITES
  // ============================================================

  /// Nombre max d'appareils par utilisateur
  static const int maxDevicesPerUser = 3;

  /// Taille max de fichier upload (5 MB)
  static const int maxFileUploadSize = 5 * 1024 * 1024;

  /// Nombre max de tentatives de connexion
  static const int maxLoginAttempts = 5;

  /// Durée de blocage après tentatives échouées
  static const Duration loginBlockDuration = Duration(minutes: 15);
}

/// Constantes liées aux tables Supabase
class DatabaseTables {
  DatabaseTables._();

  static const String clients = 'clients';
  static const String stores = 'stores';
  static const String offers = 'offers';
  static const String transactions = 'transactions';
  static const String devices = 'devices';
  static const String categories = 'categories';
  static const String favorites = 'favorites';
  static const String notifications = 'notifications';
}

/// Constantes pour le stockage de fichiers
class StorageBuckets {
  StorageBuckets._();

  static const String avatars = 'avatars';
  static const String storeImages = 'store-images';
  static const String offerImages = 'offer-images';
}
