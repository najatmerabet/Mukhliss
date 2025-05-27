import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // Pour kIsWeb

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;
  SupabaseClient get client => _client;

  Future<AuthResponse> signUpClient({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    required String adr,
  }) async {
    try {
      // 1. Inscription avec email et mot de passe
      final AuthResponse authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      // 2. Si l'inscription est réussie, créer le profil client dans la table 'clients'
      if (authResponse.user != null) {
        await _client.from('clients').insert({
          'id': authResponse.user!.id,
          'email': email,
          'prenom': firstName,
          'nom': lastName,
          'telephone': phone,
          'adresse':adr,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return authResponse;
    } catch (e) {
      print('Erreur lors de l\'inscription du client: $e');
      rethrow;
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }


 Future<String> getUserType() async {
  final userId = _client.auth.currentUser?.id;
  if (userId == null) throw Exception('Utilisateur non connecté');

  try {
    // Vérifie d'abord dans clients
    final clientResponse = await _client
        .from('clients')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (clientResponse != null) return 'client';

    // Si pas client, vérifie dans magasins
    final magasinResponse = await _client
        .from('magasins')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (magasinResponse != null) return 'magasin';

    throw Exception('Type d\'utilisateur inconnu');
  } catch (e) {
   print('Erreur getUserType: $e');
    rethrow;
  }
}


Future<void> nativeGoogleSignIn() async {
  // ⚠️ IMPORTANT: Utilisez le WEB CLIENT ID ici, pas l'Android Client ID
  const webClientId = '175331686220-np99oq9iq1pfd99glovuobbuj2bicpgd.apps.googleusercontent.com';
 
  final GoogleSignIn googleSignIn = GoogleSignIn(
    // ⚠️ IMPORTANT: Utilisez l'ANDROID CLIENT ID ici
    clientId: "175331686220-o9f5t46pna1nmnh0b42fjhdfles9qphh.apps.googleusercontent.com",
    serverClientId: webClientId, // Web Client ID
    scopes: ['email', 'profile'], // Ajoutez les scopes nécessaires
  );

  try {
    // Déconnectez d'abord pour éviter les tokens en cache
    await googleSignIn.signOut();
    
    print('🔄 Tentative de connexion Google...');
    final googleUser = await googleSignIn.signIn();
    
    if (googleUser == null) {
      print('❌ Connexion annulée par l\'utilisateur');
      return;
    }

    print('✅ Utilisateur Google connecté: ${googleUser.email}');
    
    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;
    
    print('🔑 Access Token: ${accessToken != null ? "✅" : "❌"}');
    print('🔑 ID Token: ${idToken != null ? "✅" : "❌"}');
    
    if (accessToken == null) {
      throw 'No Access Token found.'; 
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }
    
    print('🔄 Connexion avec Supabase...');
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken, 
    );
    
    print('✅ Connexion Supabase réussie !');
    
  } catch (error) {
    print('❌ Erreur lors de l\'inscription Google: $error');
    
    // Debug supplémentaire
    if (error.toString().contains('ApiException: 10')) {
      print('💡 Erreur DEVELOPER_ERROR - Vérifiez:');
      print('   - SHA-1 dans Google Console');
      print('   - Package name correct');
      print('   - Client IDs corrects');
    }
    
    rethrow;
  }
}


Future<void> signUpWithFacebook() async {
  try {
    debugPrint('🚀 Début de l\'authentification Facebook...');
    // Lance l'authentification Facebook
    var result = await  FacebookAuth.i.login(
      permissions: ['public_profile' ,'email'],
    );
if(result.status != LoginStatus.success) {
      throw Exception('Échec de l\'authentification Facebook: ${result.message}');
    }else{
      debugPrint('✅ Authentification Facebook réussie: ${result.accessToken}');
    }
    // Crée le profil client après l'authentification
    // final user = _client.auth.currentUser!;
    // await _createClientProfile(
    //   user.id,
    //   user.email ?? '',
    //   user.phone ?? '',
    //   (user.userMetadata?['full_name'] ?? user.userMetadata?['name']) as String?,
    // );
    debugPrint('✅ Inscription Facebook réussie');
  } catch (e) {
    debugPrint('❌ Erreur lors de l\'inscription Facebook: $e');
    rethrow;
  }
}

 Future<void> signUpWithGoogle() async {
  try {
    debugPrint('🚀 Début de l\'authentification Google...');
    if(!kIsWeb && (Platform.isAndroid || Platform.isIOS)){
      await  nativeGoogleSignIn();
      
    }
  
    // 1. Lance l'authentification Google
await _createClientProfile(_client.auth.currentUser!.id, _client.auth.currentUser!.email ?? '',_client.auth.currentUser!.phone ?? '',_client.auth.currentUser!.userMetadata?['full_name'],);
      
      
  } catch (e) {
    debugPrint('❌ Erreur lors de l\'inscription Google: $e');
    rethrow;
  }
}





Future<void> _createClientProfile(String userId, String email, String ? phone ,String? full_name ) async {
  
  try {
    await _client.from('clients').upsert({
      'id': userId,
      'email': email,
      'nom':full_name,
      'telephone':phone,
     
    });
  } catch (e) {
    debugPrint('❌ Erreur création profil client: $e');
    throw AuthException('Échec création du profil client');
  }
}



  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // Envoyer OTP par email pour réinitialisation
  Future<void> sendPasswordResetOtpEmail(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
      emailRedirectTo: 'yourapp://reset-password',
    );
  }

  // Vérifier l'OTP
  Future<void> verifyEmailOtp(String email, String token) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
    
    if (response.session == null) {
      throw Exception('Échec de la vérification');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}