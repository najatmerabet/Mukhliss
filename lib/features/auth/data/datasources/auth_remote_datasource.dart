/// ============================================================
/// Auth Remote DataSource - Data Layer
/// ============================================================
///
/// Implémentation Supabase de l'authentification.
/// C'est ici que se trouve toute la logique d'appel à Supabase Auth.
///
/// Pour changer de backend (Firebase, AWS Cognito, etc.),
/// créer une nouvelle classe implémentant IAuthClient.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';
import 'package:mukhliss/core/errors/failures.dart';
import 'package:mukhliss/core/errors/result.dart';
import 'package:mukhliss/core/logger/app_logger.dart';

/// Interface pour le client d'authentification
///
/// Définit le contrat que toute implémentation d'auth doit respecter.
/// Permet de changer de Supabase à Firebase sans toucher au reste du code.
abstract class IAuthClient {
  /// Utilisateur actuellement connecté (null si déconnecté)
  AppUser? get currentUser;

  /// Stream des changements d'état d'authentification
  Stream<AppUser?> get authStateChanges;

  /// Vérifie si un utilisateur est connecté
  bool get isAuthenticated;

  /// Connexion avec email et mot de passe
  Future<Result<AppUser>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Connexion avec Google
  Future<Result<AppUser>> signInWithGoogle();

  /// Connexion avec Facebook
  Future<Result<AppUser>> signInWithFacebook();

  /// Inscription avec email et mot de passe
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  });

  /// Envoyer un OTP pour vérification
  Future<Result<void>> sendOtp(String email, {bool isRecovery = false});

  /// Vérifier l'OTP
  Future<Result<AppUser>> verifyOtp({
    required String email,
    required String token,
    bool isRecovery = false,
  });

  /// Compléter l'inscription après vérification OTP
  Future<Result<AppUser>> completeSignup({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  });

  /// Déconnexion
  Future<Result<void>> signOut();

  /// Envoyer un email de réinitialisation
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Mettre à jour le mot de passe
  Future<Result<void>> updatePassword(String newPassword);

  /// Vérifier le mot de passe actuel et mettre à jour
  Future<Result<void>> updatePasswordWithVerification({
    required String currentPassword,
    required String newPassword,
  });

  /// Mettre à jour le profil utilisateur
  Future<Result<AppUser>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
  });
}

/// Implémentation Supabase de IAuthClient
class SupabaseAuthClient implements IAuthClient {
  final SupabaseClient _client;
  late final GoogleSignIn _googleSignIn;

  SupabaseAuthClient({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client {
    _googleSignIn = _createGoogleSignIn();
  }

  GoogleSignIn _createGoogleSignIn() {
    print("defaultTargetPlatform: $defaultTargetPlatform");
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return GoogleSignIn(
        clientId:
            '562124159804-f6p1std0vf6dfl6gncg73vj7f4n5ni3n.apps.googleusercontent.com',
      );
    }
    return GoogleSignIn(
      serverClientId:
          '562124159804-t9fsl2c9bbcmtj9jvt2pcooamlhmi4oq.apps.googleusercontent.com',
    );
  }

  // ============================================================
  // PROPRIÉTÉS
  // ============================================================

  @override
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _mapToAppUser(user);
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return _mapToAppUser(user);
    });
  }

  @override
  bool get isAuthenticated => _client.auth.currentUser != null;

  // ============================================================
  // CONNEXION
  // ============================================================

  @override
  Future<Result<AppUser>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.debug('Tentative de connexion: $email');

      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return Result.failure(const AuthFailure('Échec de la connexion'));
      }

      return Result.success(_mapToAppUser(response.user!));
    } on AuthException catch (e) {
      AppLogger.error('Erreur auth: ${e.message}');
      return Result.failure(_mapAuthException(e));
    } catch (e) {
      AppLogger.error('Erreur inattendue: $e');
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    try {
      AppLogger.debug('Tentative de connexion Google');

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return Result.failure(const AuthFailure('Connexion Google annulée'));
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        return Result.failure(const AuthFailure('Token Google introuvable'));
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        return Result.failure(
          const AuthFailure('Échec de la connexion Google'),
        );
      }

      // Créer ou mettre à jour le profil client avec code_unique
      try {
        final user = response.user!;
        final existingClient = await _client
            .from('clients')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        if (existingClient == null) {
          // Nouveau utilisateur - créer le profil
          final codeUnique = _generateUniqueCode();
          final displayName = googleUser.displayName ?? '';
          final nameParts = displayName.split(' ');
          final firstName = nameParts.isNotEmpty ? nameParts.first : '';
          final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

          await _client.from('clients').insert({
            'id': user.id,
            'email': user.email ?? googleUser.email,
            'prenom': firstName,
            'nom': lastName,
            'code_unique': codeUnique,
            'created_at': DateTime.now().toIso8601String(),
          });
          AppLogger.info('Profil client créé pour Google user: ${user.email}');
        }
      } catch (e) {
        AppLogger.warning('Erreur création/vérification profil client: $e');
        // Ne pas échouer la connexion si le profil existe déjà
      }

      return Result.success(_mapToAppUser(response.user!));
    } on AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } catch (e) {
      AppLogger.error('Erreur Google Sign In: $e');
      return Result.failure(UnknownFailure(e.toString()));
    }
  }


  @override
  Future<Result<AppUser>> signInWithFacebook() async {
    return Result.failure(const AuthFailure('Facebook login non implémenté'));
  }

  // ============================================================
  // INSCRIPTION
  // ============================================================

  @override
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    try {
      AppLogger.debug('Tentative d\'inscription: $email');

      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'address': address,
        },
      );

      if (response.user == null) {
        return Result.failure(const AuthFailure('Échec de l\'inscription'));
      }

      // Créer le profil client avec code_unique
      try {
        // Générer un code unique (timestamp + random)
        final codeUnique = _generateUniqueCode();

        await _client.from('clients').insert({
          'id': response.user!.id,
          'email': email.trim(),
          'prenom': firstName,
          'nom': lastName,
          'telephone': phone,
          'adresse': address,
          'code_unique': codeUnique,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        AppLogger.warning(
          'Erreur création profil client (peut-être déjà existant): $e',
        );
      }

      return Result.success(_mapToAppUser(response.user!));
    } on AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> sendOtp(String email, {bool isRecovery = false}) async {
    try {
      AppLogger.debug('Envoi OTP à: $email (isRecovery: $isRecovery)');

      if (isRecovery) {
        // Mode récupération de mot de passe
        // Vérifier d'abord si l'email existe dans la base
        try {
          final existingClient = await _client
              .from('clients')
              .select('email')
              .eq('email', email.trim().toLowerCase())
              .maybeSingle();

          if (existingClient == null) {
            // L'email n'existe pas - ne pas envoyer d'email
            return Result.failure(const UserNotFoundFailure());
          }
        } catch (e) {
          AppLogger.debug('Vérification email recovery: $e');
          // En cas d'erreur, on continue quand même
        }

        // Envoyer un code OTP pour récupération
        await _client.auth.signInWithOtp(
          email: email.trim(),
          shouldCreateUser: false, // Ne pas créer de compte si n'existe pas
        );
      } else {
        // Mode inscription - vérifier d'abord si l'email existe
        // Vérifier dans la table auth.users via une tentative de connexion
        try {
          // Essayer de voir si l'utilisateur existe dans la table clients
          final existingClient = await _client
              .from('clients')
              .select('email')
              .eq('email', email.trim().toLowerCase())
              .maybeSingle();

          if (existingClient != null) {
            // L'email existe déjà
            return Result.failure(const EmailAlreadyInUseFailure());
          }
        } catch (e) {
          // Ignorer les erreurs de vérification et continuer
          AppLogger.debug('Vérification email: $e');
        }

        // Envoyer l'OTP pour inscription
        await _client.auth.signInWithOtp(
          email: email.trim(),
          shouldCreateUser: true,
        );
      }

      return const Result.success(null);
    } on AuthException catch (e) {
      // Supabase retourne cette erreur si l'utilisateur existe déjà
      if (e.message.toLowerCase().contains('user already registered') ||
          e.message.toLowerCase().contains('email already registered')) {
        return Result.failure(const EmailAlreadyInUseFailure());
      }
      return Result.failure(_mapAuthException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }


  @override
  Future<Result<AppUser>> verifyOtp({
    required String email,
    required String token,
    bool isRecovery = false,
  }) async {
    try {
      AppLogger.debug('Vérification OTP: $email (isRecovery: $isRecovery)');

      final response = await _client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: isRecovery ? OtpType.recovery : OtpType.signup,
      );

      if (response.user == null) {
        return Result.failure(const AuthFailure('Code OTP invalide'));
      }

      return Result.success(_mapToAppUser(response.user!));
    } on AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
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
    try {
      AppLogger.debug('Complétion inscription: $email');

      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return Result.failure(const AuthFailure('Utilisateur non connecté'));
      }

      // Mettre à jour le mot de passe
      await _client.auth.updateUser(UserAttributes(password: password));

      // Mettre à jour les métadonnées
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'first_name': firstName,
            'last_name': lastName,
            'phone': phone,
            'address': address,
          },
        ),
      );

      // Créer ou mettre à jour le profil client avec code_unique
      final codeUnique = _generateUniqueCode();
      await _client.from('clients').upsert({
        'id': currentUser.id,
        'email': email.trim(),
        'prenom': firstName,
        'nom': lastName,
        'telephone': phone,
        'adresse': address,
        'code_unique': codeUnique,
      });

      return Result.success(_mapToAppUser(currentUser));
    } on AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  // ============================================================
  // DÉCONNEXION
  // ============================================================

  @override
  Future<Result<void>> signOut() async {
    try {
      AppLogger.debug('Déconnexion en cours');
      await _googleSignIn.signOut();
      await _client.auth.signOut();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  // ============================================================
  // MOT DE PASSE
  // ============================================================

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    }
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    }
  }

  @override
  Future<Result<void>> updatePasswordWithVerification({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user?.email == null) {
        return Result.failure(const AuthFailure('Utilisateur non connecté'));
      }

      // Vérifier le mot de passe actuel
      await _client.auth.signInWithPassword(
        email: user!.email!,
        password: currentPassword,
      );

      // Mettre à jour le mot de passe
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    }
  }

  // ============================================================
  // PROFIL
  // ============================================================

  @override
  Future<Result<AppUser>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (phone != null) updates['phone'] = phone;
      if (photoUrl != null) updates['photo_url'] = photoUrl;

      await _client.auth.updateUser(UserAttributes(data: updates));

      final updatedUser = _client.auth.currentUser;
      if (updatedUser == null) {
        return Result.failure(const AuthFailure('Erreur mise à jour profil'));
      }

      return Result.success(_mapToAppUser(updatedUser));
    } on AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Convertit un User Supabase en AppUser
  AppUser _mapToAppUser(User user) {
    final metadata = user.userMetadata ?? {};
    return AppUser(
      id: user.id,
      email: user.email,
      firstName: metadata['first_name'] as String?,
      lastName: metadata['last_name'] as String?,
      phone: metadata['phone'] as String? ?? user.phone,
      photoUrl:
          metadata['photo_url'] as String? ?? metadata['avatar_url'] as String?,
      emailVerified: user.emailConfirmedAt != null,
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }

  /// Génère un code unique à 6 chiffres pour le client
  int _generateUniqueCode() {
    // Utiliser les derniers chiffres du timestamp + random
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 900000) + 100000; // 6 chiffres (100000-999999)
    return random;
  }

  /// Convertit une AuthException Supabase en Failure
  Failure _mapAuthException(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return const InvalidCredentialsFailure();
    }
    if (message.contains('email not confirmed')) {
      return const AuthFailure('Email non confirmé');
    }
    if (message.contains('user not found')) {
      return const UserNotFoundFailure();
    }
    if (message.contains('email already registered') ||
        message.contains('user already registered')) {
      return const EmailAlreadyInUseFailure();
    }
    if (message.contains('weak password')) {
      return const WeakPasswordFailure();
    }
    if (message.contains('token expired') || message.contains('otp expired')) {
      return const AuthFailure('Code expiré');
    }

    return AuthFailure(e.message);
  }
}
