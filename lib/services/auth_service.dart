import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;
 SupabaseClient get client => _client;
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
  
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // Envoyer OTP par email pour réinitialisation
  Future<void> sendPasswordResetOtpEmail(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
      emailRedirectTo: 'yourapp://reset-password', // Optionnel mais recommandé
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