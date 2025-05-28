// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mukhliss/providers/auth_provider.dart';
// import 'package:mukhliss/routes/app_router.dart';
// import 'package:mukhliss/services/auth_service.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class AuthStateListener extends ConsumerStatefulWidget {
//   final Widget child;
  
//   const AuthStateListener({Key? key, required this.child}) : super(key: key);
  
//   @override
//   ConsumerState<AuthStateListener> createState() => _AuthStateListenerState();
// }

// class _AuthStateListenerState extends ConsumerState<AuthStateListener> {
//   late final Stream<AuthState> _authStateStream;
  
//   @override
//   void initState() {
//     super.initState();
//     final authService = ref.read(authProvider);
//     _authStateStream = authService.authStateChanges;
    
//     // Écouter les changements d'état d'authentification
//     _authStateStream.listen((AuthState data) {
//       _handleAuthStateChange(data);
//     });
//   }
  
//   Future<void> _handleAuthStateChange(AuthState authState) async {
//     print('Changement d\'état auth: ${authState.event}');
    
//     if (!mounted) return;
    
//     switch (authState.event) {
//       case AuthChangeEvent.signedIn:
//         await _handleSignedIn(authState);
//         break;
//       case AuthChangeEvent.signedOut:
//         _handleSignedOut();
//         break;
//       case AuthChangeEvent.userUpdated:
//         // Gérer la mise à jour de l'utilisateur si nécessaire
//         break;
//       default:
//         break;
//     }
//   }
  
//   Future<void> _handleSignedIn(AuthState authState) async {
//     final user = authState.session?.user;
//     if (user == null) return;
    
//     print('Utilisateur connecté: ${user.email}');
    
//     try {
//       final authService = ref.read(authProvider);
      
//       // Si c'est une connexion Google, créer le profil client si nécessaire
//       if (user.appMetadata['provider'] == 'google') {
//         print('Connexion Google détectée, création du profil...');
//         await authService._createClientProfileIfNeeded();
//       }
      
//       // Vérifier le type d'utilisateur et rediriger
//       final userType = await authService.getUserType();
      
//       if (mounted) {
//         // ignore: unrelated_type_equality_checks
//         if (userType == 'client') {
//           Navigator.pushReplacementNamed(context, AppRouter.main);
//         } else if (userType == 'magasin') {
//           // ignore: avoid_print
//           print('Redirection vers magasin home');
//           Navigator.pushReplacementNamed(context, AppRouter.signupClient);
//         }
//       }
//     } catch (e) {
//       print('Erreur lors de la gestion de la connexion: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erreur lors de la connexion: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
  
//   void _handleSignedOut() {
//     print('Utilisateur déconnecté');
//     if (mounted) {
//       Navigator.pushNamedAndRemoveUntil(
//         context, 
//         AppRouter.login, 
//         (route) => false
//       );
//     }
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return widget.child;
//   }
// }

// // Extension pour accéder aux méthodes privées
// extension AuthServiceExtension on AuthService {
//   Future<void> _createClientProfileIfNeeded() async {
//     final user = client.auth.currentUser;
//     if (user == null) {
//       throw AuthApiException('Aucun utilisateur connecté');
//     }

//     print('Création du profil pour: ${user.email}');

//     try {
//       // Vérifier si le profil client existe déjà
//       final existingClient = await client
//           .from('clients')
//           .select('id')
//           .eq('id', user.id)
//           .maybeSingle();

//       if (existingClient == null) {
//         // Extraire les informations du profil Google
//         final fullName = user.userMetadata?['full_name'] as String? ?? 
//                         user.userMetadata?['name'] as String? ?? '';
//         final avatar = user.userMetadata?['avatar_url'] as String? ?? 
//                       user.userMetadata?['picture'] as String?;
        
//         final names = fullName.trim().split(' ');
//         final firstName = names.isNotEmpty ? names.first : '';
//         final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

//         // Créer le profil client
//         await client.from('clients').insert({
//           'id': user.id,
//           'email': user.email ?? '',
//           'prenom': firstName,
//           'nom': lastName,
//           'avatar_url': avatar,
//           'created_at': DateTime.now().toIso8601String(),
//         });
        
//         // ignore: avoid_print
//         print('Profil client créé avec succès pour: ${user.email}');
//       } else {
//         // ignore: avoid_print
//         print('Profil client existe déjà pour: ${user.email}');
//       }
//     } catch (e) {
//         // ignore: avoid_print
//       print('Erreur création profil client: $e');
//       throw AuthApiException('Échec création du profil client: $e');
//     }
//   }
// }