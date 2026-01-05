// ===========================================
// MOCK DE IAuthClient POUR LES TESTS
// ===========================================
//
// Ce fichier crée une FAUSSE version de IAuthClient
// pour tester la logique sans appeler Supabase.

import 'package:mukhliss/core/auth/auth_client.dart';
import 'package:mukhliss/core/errors/result.dart';
import 'package:mukhliss/core/errors/failures.dart';

/// Mock de IAuthClient pour les tests
///
/// Usage:
/// ```dart
/// final mockClient = MockAuthClient();
/// mockClient.signInResult = Result.success(fakeUser);
///
/// // Maintenant signInWithEmailPassword retourne success!
/// ```
class MockAuthClient implements IAuthClient {
  // ============================================
  // RÉSULTATS CONFIGURABLES
  // ============================================
  //
  // On peut configurer ce que chaque méthode retourne

  Result<AppUser>? signInResult;
  Result<AppUser>? signInWithGoogleResult;
  Result<AppUser>? signUpResult;
  Result<void>? sendOtpResult;
  Result<AppUser>? verifyOtpResult;
  Result<void>? signOutResult;
  Result<void>? updatePasswordResult;

  // État interne
  AppUser? _currentUser;
  bool _isAuthenticated = false;

  // ============================================
  // IMPLÉMENTATION DES MÉTHODES
  // ============================================

  @override
  Future<Result<AppUser>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (signInResult != null) {
      signInResult!.onSuccess((user) {
        _currentUser = user;
        _isAuthenticated = true;
      });
      return signInResult!;
    }
    return const Result.failure(AuthFailure('signInResult non configuré'));
  }

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    if (signInWithGoogleResult != null) {
      signInWithGoogleResult!.onSuccess((user) {
        _currentUser = user;
        _isAuthenticated = true;
      });
      return signInWithGoogleResult!;
    }
    return const Result.failure(
      AuthFailure('signInWithGoogleResult non configuré'),
    );
  }

  @override
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    return signUpResult ??
        const Result.failure(AuthFailure('signUpResult non configuré'));
  }

  @override
  Future<Result<void>> sendOtp(String email, {bool isRecovery = false}) async {
    return sendOtpResult ?? const Result.success(null);
  }

  @override
  Future<Result<AppUser>> verifyOtp({
    required String email,
    required String token,
    bool isRecovery = false,
  }) async {
    return verifyOtpResult ??
        const Result.failure(AuthFailure('verifyOtpResult non configuré'));
  }

  @override
  Future<Result<void>> signOut() async {
    _currentUser = null;
    _isAuthenticated = false;
    return signOutResult ?? const Result.success(null);
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    return updatePasswordResult ?? const Result.success(null);
  }

  @override
  Future<Result<AppUser>> completeSignup({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    return signUpResult ??
        const Result.failure(AuthFailure('signUpResult non configuré'));
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(_currentUser);

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    return sendOtpResult ?? const Result.success(null);
  }

  @override
  Future<Result<void>> updatePasswordWithVerification({
    required String currentPassword,
    required String newPassword,
  }) async {
    return updatePasswordResult ?? const Result.success(null);
  }

  @override
  Future<Result<AppUser>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
  }) async {
    return signUpResult ??
        const Result.failure(AuthFailure('updateProfile non configuré'));
  }

  @override
  Future<Result<AppUser>> signInWithFacebook() async {
    return signInWithGoogleResult ??
        const Result.failure(AuthFailure('signInWithFacebook non configuré'));
  }

  @override
  Future<Result<AppUser>> signInWithApple() async {
    return signInWithGoogleResult ??
        const Result.failure(AuthFailure('signInWithApple non configuré'));
  }

  @override
  Future<Result<void>> deleteAccount() async {
    _currentUser = null;
    _isAuthenticated = false;
    return const Result.success(null);
  }

  // ============================================
  // MÉTHODES UTILITAIRES POUR LES TESTS
  // ============================================

  /// Réinitialiser le mock
  void reset() {
    signInResult = null;
    signInWithGoogleResult = null;
    signUpResult = null;
    sendOtpResult = null;
    verifyOtpResult = null;
    signOutResult = null;
    updatePasswordResult = null;
    _currentUser = null;
    _isAuthenticated = false;
  }

  /// Simuler un utilisateur déjà connecté
  void setLoggedInUser(AppUser user) {
    _currentUser = user;
    _isAuthenticated = true;
  }
}

/// Utilisateur de test
AppUser createTestUser({
  String id = 'test-user-id',
  String email = 'test@test.com',
  String? firstName = 'Test',
  String? lastName = 'User',
}) {
  return AppUser(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
  );
}
