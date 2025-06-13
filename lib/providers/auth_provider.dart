

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authProvider =Provider<AuthService>((ref){
  return AuthService();
});


final authStateProvider =StreamProvider<User?>((ref){
  final authService=ref.watch(authProvider);
  return authService.authStateChanges.map((event)=>event.session?.user);
});

// Provider synchrone pour l'utilisateur actuel
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provider pour le client ID
final currentClientIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
});

// Ajouter cette méthode à votre AuthService
Future<void> sendPasswordResetEmail(String email) async {
  final supabase = Supabase.instance.client;
  await supabase.auth.resetPasswordForEmail(
    email,
    redirectTo: 'votre-url-de-redirection', // Optionnel
  );
}


// Dans auth_provider.dart
Future<void> sendPasswordResetOtpEmail(String email) async {
  final supabase = Supabase.instance.client;
  await supabase.auth.signInWithOtp(
    email: email,
  );
}

Future<void> verifyEmailOtp(String email, String token) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.auth.verifyOTP(
    email: email,
    token: token,
    type: OtpType.recovery,
  );
  
  if (response.session == null) {
    throw Exception('Verification failed');
  }
}

