import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service d'authentification gérant les connexions et inscriptions
class AuthService {
  static const String _webClientId = 
      '175331686220-np99oq9iq1pfd99glovuobbuj2bicpgd.apps.googleusercontent.com';
  static const String _androidClientId = 
      '175331686220-o9f5t46pna1nmnh0b42fjhdfles9qphh.apps.googleusercontent.com';
  
  static const List<String> _googleScopes = ['email', 'profile'];
  static const List<String> _facebookPermissions = ['public_profile', 'email'];
  
  final SupabaseClient _client = Supabase.instance.client;
  SupabaseClient get client => _client;
  
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ============= AUTHENTICATION METHODS =============
  
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
      }

      return authResponse;
    } catch (e) {
      _logError('Erreur inscription client', e);
      rethrow;
    }
  }

  /// Connexion avec email et mot de passe
  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Connexion/Inscription avec Google
  Future<void> signInWithGoogle() async {
    try {
      _log('Début connexion Google...');
      
      await _authenticateWithGoogle();
      await _ensureClientProfileExists();
      
      _log('Connexion Google réussie ✅');
    } catch (e) {
      _logError('Erreur Google Auth', e);
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    await _client.auth.signOut();
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

  // ============= PASSWORD RESET =============
  
  /// Envoie un OTP par email pour réinitialisation du mot de passe
  Future<void> sendPasswordResetOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
      emailRedirectTo: 'yourapp://reset-password',
    );
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
      clientId: _androidClientId,
      serverClientId: _webClientId,
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
        throw AuthException('Tokens manquants');
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (error) {
      if (error.toString().contains('ApiException: 10')) {
        _log('💡 DEVELOPER_ERROR - Vérifiez SHA-1 et configuration Google');
      }
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