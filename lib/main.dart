// main.dart - Version avec gestion du thème
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/l10n.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:mukhliss/screen/slash_screen.dart';
import 'package:mukhliss/providers/langue_provider.dart';
import 'package:mukhliss/providers/theme_provider.dart'; // Nouveau import
import 'package:mukhliss/theme/app_theme.dart'; // Nouveau import
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart' as flutter_material show ThemeMode;
typedef flutter_ThemeMode = flutter_material.ThemeMode;
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
      supportedLocales: L10n.all,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      theme: AppColors.lightTheme, // Thème par défaut
    );
  }
}

// AuthWrapper modifié pour écouter le thème ET la langue
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { 
    final currentLocale = ref.watch(languageProvider);
    final currentThemeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'MUKHLISS',
      
      // Configuration des thèmes
      theme: AppColors.lightTheme,
      darkTheme: AppColors.darkTheme,
      themeMode: _convertToFlutterThemeMode(currentThemeMode),
      
      debugShowCheckedModeBanner: false,
      supportedLocales: L10n.all,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: currentLocale,
      
      home: const AuthStateHandler(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }

  // Convertir notre ThemeMode vers celui de Flutter
 // Correction de la méthode _getFlutterThemeMode
 ThemeMode _convertToFlutterThemeMode(AppThemeMode appThemeMode) {
    switch (appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

// AuthStateHandler modifié pour écouter le thème ET la langue
class AuthStateHandler extends ConsumerStatefulWidget {
  const AuthStateHandler({super.key});

  @override
  ConsumerState<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends ConsumerState<AuthStateHandler> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final initialSession = Supabase.instance.client.auth.currentSession;
        if (initialSession != null && mounted) {
          navigatorKey.currentState?.pushReplacementNamed(AppRouter.main);
        } else if (mounted) {
          navigatorKey.currentState?.pushReplacementNamed(AppRouter.login);
        }

        _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          if (!mounted) return;
          
          print('Changement d\'état auth: ${data.event}');
          
          final session = data.session;
          if (session != null && data.event == AuthChangeEvent.signedIn) {
            print('Utilisateur connecté, redirection vers home');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                navigatorKey.currentState?.pushReplacementNamed(AppRouter.main);
              }
            });
          } else if (session == null && data.event == AuthChangeEvent.signedOut) {
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
    final currentLocale = ref.watch(languageProvider);
    final currentThemeMode = ref.watch(themeProvider);
    
    if (!_initialized) {
      return MaterialApp(
        locale: currentLocale,
        supportedLocales: L10n.all,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppColors.lightTheme,
        darkTheme: AppColors.darkTheme,
        themeMode: _convertToFlutterThemeMode(currentThemeMode),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MUKHLISS',
      
      // Configuration des thèmes
      theme: AppColors.lightTheme,
      darkTheme: AppColors.darkTheme,
      themeMode: _convertToFlutterThemeMode(currentThemeMode),
      
      debugShowCheckedModeBanner: false,
      supportedLocales: L10n.all,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: currentLocale,
      onGenerateRoute: (settings) {
        print('Route demandée: ${settings.name}');
        
        if (settings.name != null && settings.name!.contains('code=')) {
          print('Callback d\'authentification détecté avec code');
          return MaterialPageRoute(
            builder: (_) => const SplashScreen(),
            settings: settings,
          );
        }
        
        return AppRouter.generateRoute(settings);
      },
      home: const SplashScreen(),
    );
  }

  // Convertir notre ThemeMode vers celui de Flutter
 ThemeMode _convertToFlutterThemeMode(AppThemeMode appThemeMode) {
    switch (appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}


