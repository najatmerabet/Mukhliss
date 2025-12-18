/// ============================================================
/// Auth Use Cases - Domain Layer
/// ============================================================
library;

// Utiliser le barrel export de core
import 'package:mukhliss/core/core.dart';

/// Use case: Connexion avec email/password
class SignInUseCase {
  final IAuthClient _authClient;

  SignInUseCase(this._authClient);

  Future<Result<AppUser>> call(String email, String password) async {
    return await _authClient.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }
}

/// Use case: Inscription
class SignUpUseCase {
  final IAuthClient _authClient;

  SignUpUseCase(this._authClient);

  Future<Result<void>> call({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? address,
  }) async {
    return await _authClient.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      address: address,
    );
  }
}

/// Use case: Déconnexion
class SignOutUseCase {
  final IAuthClient _authClient;

  SignOutUseCase(this._authClient);

  Future<void> call() async {
    await _authClient.signOut();
  }
}

/// Use case: Connexion Google
class SignInWithGoogleUseCase {
  final IAuthClient _authClient;

  SignInWithGoogleUseCase(this._authClient);

  Future<Result<AppUser>> call() async {
    return await _authClient.signInWithGoogle();
  }
}

/// Use case: Envoyer OTP
class SendOtpUseCase {
  final IAuthClient _authClient;

  SendOtpUseCase(this._authClient);

  Future<Result<void>> call(String email, {bool isRecovery = false}) async {
    return await _authClient.sendOtp(email, isRecovery: isRecovery);
  }
}

/// Use case: Vérifier OTP
class VerifyOtpUseCase {
  final IAuthClient _authClient;

  VerifyOtpUseCase(this._authClient);

  Future<Result<void>> call({
    required String email,
    required String token,
    bool isRecovery = false,
  }) async {
    return await _authClient.verifyOtp(
      email: email,
      token: token,
      isRecovery: isRecovery,
    );
  }
}

/// Use case: Changer mot de passe
class UpdatePasswordUseCase {
  final IAuthClient _authClient;

  UpdatePasswordUseCase(this._authClient);

  Future<Result<void>> call(String newPassword) async {
    return await _authClient.updatePassword(newPassword);
  }
}
