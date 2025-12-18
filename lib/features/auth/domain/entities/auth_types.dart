/// ============================================================
/// Auth Types - Domain Layer
/// ============================================================
///
/// Types communs pour l'authentification.
library;

/// Type de vérification OTP
enum OtpVerificationType {
  /// Inscription d'un nouveau compte
  signup,

  /// Réinitialisation du mot de passe
  passwordReset,
}

/// États possibles de l'authentification
enum AuthStatus {
  /// État initial, non encore déterminé
  initial,

  /// Chargement en cours
  loading,

  /// Utilisateur authentifié
  authenticated,

  /// Utilisateur non authentifié
  unauthenticated,

  /// Erreur d'authentification
  error,
}
