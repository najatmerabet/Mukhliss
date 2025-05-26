import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/routes/app_router.dart';

import 'package:mukhliss/screen/slash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  try {
    await dotenv.load(fileName: '.env');
    
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_KEY']!,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    
    runApp(ProviderScope(
      child: AuthWrapper(),
    ));
  } catch (e) {
    print('Erreur d\'initialisation: $e');
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    
      home: Scaffold(
        body: Center(
          child: Text(
            'Erreur d\'initialisation',
            style: TextStyle(fontSize: 24, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) { 
    return MaterialApp(
       title: 'MUKHLISS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthStateHandler(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Vérifier l'état d'authentification initial
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final initialSession = Supabase.instance.client.auth.currentSession;
        if (initialSession != null && mounted) {
          navigatorKey.currentState?.pushReplacementNamed(AppRouter.clientHome);
        } else if (mounted) {
          navigatorKey.currentState?.pushReplacementNamed(AppRouter.login);
        }

        // Écouter les changements d'état d'authentification
        _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          if (!mounted) return;
          
          print('Changement d\'état auth: ${data.event}');
          
          final session = data.session;
          if (session != null && data.event == AuthChangeEvent.signedIn) {
            // Utilisateur vient de se connecter - rediriger vers la page d'accueil
            print('Utilisateur connecté, redirection vers home');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                navigatorKey.currentState?.pushReplacementNamed(AppRouter.clientHome);
              }
            });
          } else if (session == null && data.event == AuthChangeEvent.signedOut) {
            // Utilisateur déconnecté - rediriger vers login
            print('Utilisateur déconnecté, redirection vers login');
            navigatorKey.currentState?.pushReplacementNamed(AppRouter.login);
          }
        });

        if (mounted) {
          setState(() => _initialized = true);
        }
      } catch (e) {
        print('Erreur lors de l\'initialisation de l\'auth: $e');
        if (mounted) {
          navigatorKey.currentState?.pushReplacementNamed(AppRouter.login);
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MUKHLISS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        print('Route demandée: ${settings.name}');
        
        // Gérer les callbacks d'authentification (Google, etc.)
        if (settings.name != null && settings.name!.contains('code=')) {
          print('Callback d\'authentification détecté avec code');
          return MaterialPageRoute(
            builder: (_) => const SplashScreen(),
            settings: settings,
          );
        }
        
        // Routes normales
        return AppRouter.generateRoute(settings);
      },
      home: const SplashScreen(),
    );
  }
}
