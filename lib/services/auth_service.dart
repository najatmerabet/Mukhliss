import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:mukhliss/models/user_device.dart';
import 'package:mukhliss/services/device_management_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service d'authentification gérant les connexions et inscriptions
class AuthService {
  // static const String _webClientId = 
    String? get currentDeviceId => _deviceService.currentDeviceId;

  static const List<String> _googleScopes = ['email', 'profile'];
  
  final SupabaseClient _client = Supabase.instance.client;
  SupabaseClient get client => _client;
  
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  // Ajoutez cette propriété
  final DeviceManagementService _deviceService = DeviceManagementService();
  Timer? _activityTimer;
  // ============= AUTHENTICATION METHODS =============
  
  /// Inscription d'un nouveau client avec email et mot de passe
 /// Inscription d'un nouveau client avec email et mot de passe
Future<AuthResponse> signUpClient({
  required String email,
  required String password,
  required String firstName,
  required String lastName,
  String? phone,
  required String address,
}) async {
  try {
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (authResponse.user != null) {
      await _createClientProfile(
        userId: authResponse.user!.id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        address: address,
      );

      // Enregistrer automatiquement l'appareil
      await _deviceService.registerCurrentDevice();
      
      // Démarrer le suivi d'activité
      _startActivityTracking();
      
      _log('Inscription réussie avec enregistrement appareil ✅');
    }

    return authResponse;
  } catch (e) {
    _logError('Erreur inscription client', e);
    rethrow;
  }
}
/// Connexion avec email et mot de passe
// Future<AuthResponse> login(String email, String password) async {
//   try {
//     final response = await _client.auth.signInWithPassword(
//       email: email,
//       password: password,
//     );

//     if (response.user != null) {
//       // Enregistrer automatiquement l'appareil
//       await _deviceService.registerCurrentDevice();     
//       // Démarrer le suivi d'activité
//       _startActivityTracking();
      
//       _log('Connexion réussie avec enregistrement appareil ✅');
//     }

//     return response;
//   } catch (e) {
//     _logError('Erreur connexion', e);
//     rethrow;
//   }
// }
Future<AuthResponse> login(String email, String password) async {
  try {
    // 1. Première vérification : existe-t-il dans la table client ?
    _log('Vérification de l\'existence du client pour: $email');
    
    final clientCheck = await _client
        .from('clients')
        .select('email') // Vous pouvez aussi vérifier un statut actif
        .eq('email', email)
        .maybeSingle();

    // Si l'email n'existe pas dans la table client
    if (clientCheck == null) {
      _logError('Connexion refusée', 'Email $email non trouvé dans la table client');
      throw Exception('Accès non autorisé. Votre compte n\'est pas enregistré dans le système.');
    }

    // Optionnel : vérifier si le client est actif
    if (clientCheck['active'] == false) {
      _logError('Connexion refusée', 'Compte client désactivé pour: $email');
      throw Exception('Votre compte est désactivé. Veuillez contacter l\'administrateur.');
    }

    _log('Client vérifié dans la table ✅ Tentative d\'authentification...');

    // 2. Si l'email existe dans client, procéder à l'authentification Supabase
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Enregistrer automatiquement l'appareil
      await _deviceService.registerCurrentDevice();     
      // Démarrer le suivi d'activité
      _startActivityTracking();
      
      _log('Connexion réussie avec vérification client et enregistrement appareil ✅');
    }

    return response;
  } on PostgrestException catch (e) {
    _logError('Erreur base de données lors de la vérification client', e);
    throw Exception('Erreur de connexion à la base de données. Veuillez réessayer.');
  } on AuthException catch (e) {
    _logError('Erreur authentification', e);
    // L'erreur d'auth sera plus spécifique (mot de passe incorrect, etc.)
    rethrow;
  } catch (e) {
    _logError('Erreur connexion', e);
    rethrow;
  }
}
// ============= DEVICE MANAGEMENT =============

/// Démarre le suivi automatique d'activité
void _startActivityTracking() {
  _stopActivityTracking(); // S'assurer qu'il n'y a qu'un seul timer
  _activityTimer = _deviceService.startActivityUpdater();
}

/// Arrête le suivi d'activité
void _stopActivityTracking() {
  _activityTimer?.cancel();
  _activityTimer = null;
}
/// Déconnecte un appareil à distance
Future<bool> disconnectDeviceRemotely(String deviceId) async {
  return await _deviceService.disconnectDeviceRemotely(deviceId);
}

/// Récupère la liste des appareils de l'utilisateur
Future<List<UserDevice>> getUserDevices() async {
  return await _deviceService.getUserDevices();
}

/// Supprime un appareil
Future<bool> removeDevice(String deviceId) async {
  return await _deviceService.removeDevice(deviceId);
}

/// Désactive un appareil
Future<bool> deactivateDevice(String deviceId) async {
  return await _deviceService.deactivateDevice(deviceId);
}

/// Obtient les statistiques des appareils
Future<Map<String, dynamic>> getDeviceStats() async {
  return await _deviceService.getDeviceStats();
}

/// Enregistre manuellement l'appareil actuel
Future<UserDevice?> registerCurrentDevice({String? customName}) async {
  return await _deviceService.registerCurrentDevice(
    customDeviceName: customName,
  );
}
  /// Connexion/Inscription avec Google
/// Connexion/Inscription avec Google
Future<void> signInWithGoogle() async {
  try {
    _log('Début connexion Google...');
    
    await _authenticateWithGoogle();
    await _ensureClientProfileExists();
    
    // Enregistrer automatiquement l'appareil
    await _deviceService.registerCurrentDevice();
    
    // Démarrer le suivi d'activité
    _startActivityTracking();
    
    _log('Connexion Google réussie avec enregistrement appareil ✅');
  } catch (e) {
    _logError('Erreur Google Auth', e);
    rethrow;
  }
}
  /// Déconnexion
/// Déconnexion
Future<void> logout() async {
  try {
    // Arrêter le suivi d'activité
    _stopActivityTracking();
    
    // Déconnecter
    await _client.auth.signOut();
    
    _log('Déconnexion réussie ✅');
  } catch (e) {
    _logError('Erreur déconnexion', e);
    rethrow;
  }
}

  // ============= USER MANAGEMENT =============
  
  /// Détermine le type d'utilisateur (client ou magasin)
  Future<UserType> getUserType() async {
    final userId = _validateCurrentUser();
    
    try {
      // Vérifier si c'est un client
      if (await _isUserInTable(userId, 'clients')) {
        return UserType.client;
      }
      
      // Vérifier si c'est un magasin
      if (await _isUserInTable(userId, 'magasins')) {
        return UserType.magasin;
      }
      
      throw AuthException('Type utilisateur inconnu');
    } catch (e) {
      _logError('Erreur getUserType', e);
      rethrow;
    }
  }

  /// Met à jour le profil utilisateur
  Future<void> updateUserProfile({
    required String userId,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (email != null) updates['email'] = email;
      if (firstName != null) updates['prenom'] = firstName;
      if (lastName != null) updates['nom'] = lastName;
      if (phone != null) updates['telephone'] = phone;
      if (address != null) updates['adresse'] = address;
      
      if (updates.isNotEmpty) {
        await _client.from('clients').update(updates).eq('id', userId);
      }

      // Mettre à jour l'email dans Auth si modifié
      if (email != null) {
        await _client.auth.updateUser(UserAttributes(email: email));
      }
    } catch (e) {
      _logError('Erreur mise à jour profil', e);
      rethrow;
    }
  }
  
// ============== Signup With OTP =============

/// Envoie un OTP pour la vérification d'email lors de l'inscription
Future<void> sendSignupOtpWithRetry(String email, {int maxRetries = 3}) async {
  int attempt = 0;
  
  while (attempt < maxRetries) {
    try {
      attempt++;
      print('Tentative $attempt pour envoyer OTP à $email');
      
      final response = await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Timeout lors de l\'envoi de l\'OTP');
        },
      );
      
      // Si on arrive ici, c'est réussi
      print('OTP envoyé avec succès à $email');
      return;
      
    } catch (e) {
      print('Tentative $attempt échouée: $e');
      
      if (attempt >= maxRetries) {
        throw Exception('Impossible d\'envoyer l\'OTP après $maxRetries tentatives');
      }
      
      // Attendre avant la prochaine tentative
      await Future.delayed(Duration(seconds: attempt * 2));
    }
  }
}

/// Vérifie l'OTP pour l'inscription
Future<AuthResponse> verifySignupOtp({
  required String email, 
  required String token,
}) async {
  final response = await _client.auth.verifyOTP(
    email: email,
    token: token,
    type: OtpType.signup,
  );

  if (response.session == null) {
    throw AuthException('Échec de la vérification OTP');
  }
  
  return response;
}

  // ============= PASSWORD RESET =============
  
  /// Envoie un OTP par email pour réinitialisation du mot de passe
  Future<void> sendPasswordResetOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
      emailRedirectTo: 'yourapp://reset-password',
    );
  }
Future<void> completeSignupAfterOtpVerification({
  required String email,
  required String password,
  required String firstName,
  required String lastName,
  String? phone,
  String? address,
}) async {
  try {
    // Get the current user (created during OTP verification)
    final user = _client.auth.currentUser;
    
    if (user == null) {
      throw AuthException('No authenticated user found');
    }

    // Update the user with password if needed
    if (password.isNotEmpty) {
      await _client.auth.updateUser(
        UserAttributes(password: password),
      );
    }

    // Create or update client profile
    await _createClientProfile(
      userId: user.id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      address: address,
    );
    
    _log('Profile completed successfully for ${user.email}');
  } catch (e) {
    _logError('Error completing signup', e);
    rethrow;
  }
}


/// Vérifie l'OTP pour la réinitialisation de mot de passe
Future<AuthResponse> verifyPasswordResetOtp({
  required String email, 
  required String token,
}) async {
  final response = await _client.auth.verifyOTP(
    email: email,
    token: token,
    type: OtpType.recovery,
  );

  if (response.session == null) {
    throw AuthException('Échec de la vérification OTP');
  }
  
  return response;
}
  /// Vérifie l'OTP reçu par email
  Future<void> verifyEmailOtp(String email, String token) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );

    if (response.session == null) {
      throw AuthException('Échec de la vérification OTP');
    }
  }

  /// Met à jour le mot de passe
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
/// Met à jour le mot de passe avec vérification de l'ancien mot de passe
Future<void> updatePasswordWithVerify({
  required String currentPassword,
  required String newPassword,
}) async {
  // First verify current password by signing in again
  final user = currentUser;
  if (user == null) throw AuthException('Utilisateur non connecté');
  
  if (user.email == null) throw AuthException('Email utilisateur non disponible');
  
  // Verify current password
  try {
    await _client.auth.signInWithPassword(
      email: user.email!,
      password: currentPassword,
    );
  } catch (e) {
    throw AuthException('Mot de passe actuel incorrect');
  }

  // If verification succeeds, update password
  await _client.auth.updateUser(
    UserAttributes(password: newPassword),
  );
}
  // ============= PRIVATE METHODS =============
  
  /// Authentification native avec Google
 Future<void> _authenticateWithGoogle() async {
  final googleSignIn = GoogleSignIn(
    clientId: dotenv.get('androidClientId'),
    serverClientId: dotenv.get('webClientId'),
    scopes: _googleScopes,
  );

  try {
    // Nettoyer les tokens en cache
    await googleSignIn.signOut();

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException('Connexion annulée par l\'utilisateur');
    }

    _log('Utilisateur Google: ${googleUser.email}');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null || accessToken == null) {
      throw AuthException('Tokens manquants (idToken: $idToken, accessToken: $accessToken)');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  } catch (error) {
    // _log('❌ Erreur d\'authentification Google:', error: error, stackTrace: stackTrace);
    
    if (error is PlatformException) {
      _log('Détails de l\'erreur PlatformException:');
      _log('Code: ${error.code}');
      _log('Message: ${error.message}');
      _log('Details: ${error.details}');
    }

    if (error.toString().contains('ApiException: 10')) {
      _log('💡 DEVELOPER_ERROR - Vérifiez:');
      _log('1. SHA-1 dans Firebase Console');
      _log('2. Client ID dans Google Cloud Console');
      _log('3. "supportEmail" dans android/app/build.gradle');
    }

    // Vous pouvez aussi afficher l'erreur à l'utilisateur via un SnackBar ou une AlertDialog
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${error.toString()}')));
    
    rethrow;
  }
}
  /// Crée le profil client s'il n'existe pas déjà
  Future<void> _ensureClientProfileExists() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final exists = await _isUserInTable(user.id, 'clients');
      if (exists) {
        _log('Profil client existe déjà');
        return;
      }

      await _createClientProfile(
        userId: user.id,
        email: user.email ?? '',
        lastName: _extractFullName(user),
        phone: user.phone,
      );
    } catch (e) {
      _logError('Erreur création profil', e);
      rethrow;
    }
  }

  /// Crée un profil client dans la base de données
  Future<void> _createClientProfile({
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    await _client.from('clients').insert({
      'id': userId,
      'email': email,
      'prenom': firstName,
      'nom': lastName,
      'telephone': phone,
      'adresse': address,
      'created_at': DateTime.now().toIso8601String(),
    });
    _log('Profil client créé ✅');
  }

  /// Vérifie si un utilisateur existe dans une table
  Future<bool> _isUserInTable(String userId, String tableName) async {
    final response = await _client
        .from(tableName)
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    
    return response != null;
  }

  /// Valide que l'utilisateur est connecté et retourne son ID
  String _validateCurrentUser() {
    final userId = currentUser?.id;
    if (userId == null) {
      throw AuthException('Utilisateur non connecté');
    }
    return userId;
  }

  /// Extrait le nom complet des métadonnées utilisateur
  String? _extractFullName(User user) {
    final metadata = user.userMetadata;
    if (metadata == null) return null;
    
    return metadata['full_name'] as String? ?? 
           metadata['name'] as String?;
  }

  /// Log un message en mode debug
  void _log(String message) {
    debugPrint('🔹 [AuthService] $message');
  }

  /// Log une erreur
  void _logError(String context, dynamic error) {
    debugPrint('❌ [AuthService] $context: $error');
  }
}

// ============= CUSTOM TYPES =============

/// Types d'utilisateurs supportés
enum UserType { client, magasin }

/// Exception personnalisée pour les erreurs d'authentification
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}