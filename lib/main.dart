// main.dart - Version corrigée (Fixed Supabase initialization order)
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/l10n/l10n.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:mukhliss/screen/slash_screen.dart';
import 'package:mukhliss/services/device_management_service.dart';
import 'package:mukhliss/providers/langue_provider.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/services/onboarding_service.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart' as flutter_material show ThemeMode;

typedef flutter_ThemeMode = flutter_material.ThemeMode;

// ✅ Gestionnaire d'erreurs global
class GlobalErrorHandler {
  static GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  static bool _supabaseListenerSetup = false;

  // ✅ Initialisation de base (sans Supabase)
  static void initialize() {
    // Capturer les erreurs Flutter non gérées
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
      
      _handleSupabaseAuthError(details.exception);
    };

    // Capturer les erreurs asynchrones non gérées
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Platform Error: $error');
      debugPrint('Stack trace: $stack');
      
      _handleSupabaseAuthError(error);
      return true;
    };
  }

  // ✅ Configuration Supabase (à appeler APRÈS Supabase.initialize())
  static void setupSupabaseAuthListener() {
    if (_supabaseListenerSetup) {
      debugPrint('⚠️ Supabase auth listener already setup');
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      
      // Écouter les changements d'état d'authentification
      supabase.auth.onAuthStateChange.listen(
        (data) {
          final event = data.event;
          final session = data.session;
          
          debugPrint('🔐 Auth state changed: $event');
          
          if (event == AuthChangeEvent.signedOut && session == null) {
            debugPrint('🚪 User signed out - possibly due to auth error');
          }
          
          if (event == AuthChangeEvent.tokenRefreshed) {
            debugPrint('🔄 Token refreshed successfully');
          }
        },
        onError: (error) {
          debugPrint('❌ Auth state change error: $error');
          _handleSupabaseAuthError(error);
        },
      );

      _supabaseListenerSetup = true;
      debugPrint('✅ Supabase auth listener setup successfully');
    } catch (e) {
      debugPrint('❌ Failed to setup Supabase auth error listener: $e');
    }
  }

  static void _handleSupabaseAuthError(dynamic error) {
    if (error == null) return;
    
    final errorString = error.toString();
    
    // Vérifier si c'est une erreur d'authentification Supabase
    if (errorString.contains('AuthRetryableFetchException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('supabase.co') ||
        errorString.contains('refresh_token') ||
        errorString.contains('No address associated with hostname')) {
      
      debugPrint('🔧 Supabase auth error detected and handled: $errorString');
      
      _notifyAuthError(errorString);
    }
  }

  static void _notifyAuthError(String error) {
    debugPrint('📡 Auth error notification: Network connectivity issues detected');
    
    if (scaffoldMessengerKey?.currentState != null) {
      try {
        scaffoldMessengerKey!.currentState!.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Problème de connexion détecté - Mode hors ligne activé',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      } catch (e) {
        debugPrint('Failed to show error notification: $e');
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ÉTAPE 1: Initialiser le gestionnaire d'erreurs (sans Supabase)
  GlobalErrorHandler.initialize();

  try {
    await dotenv.load(fileName: '.env');

    // ✅ ÉTAPE 2: Initialiser Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_KEY']!,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        timeout: Duration(seconds: 30),
      ),
    );

    // ✅ ÉTAPE 3: Configurer l'écouteur Supabase APRÈS l'initialisation
    GlobalErrorHandler.setupSupabaseAuthListener();

    runApp(const ProviderScope(child: AuthWrapper()));
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
      theme: AppColors.lightTheme,
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageProvider);
    final currentThemeMode = ref.watch(themeProvider);

    final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    GlobalErrorHandler.scaffoldMessengerKey = scaffoldMessengerKey;

    return MaterialApp(
      title: 'MUKHLISS',
      theme: AppColors.lightTheme,
      darkTheme: AppColors.darkTheme,
      themeMode: _convertToFlutterThemeMode(currentThemeMode),
      debugShowCheckedModeBanner: false,
      supportedLocales: L10n.all,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: currentLocale,
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: const AuthStateHandler(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }

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

class AuthStateHandler extends ConsumerStatefulWidget {
  const AuthStateHandler({super.key});

  @override
  ConsumerState<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends ConsumerState<AuthStateHandler> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  final bool _initialized = false;
  bool _monitoringInitialized = false;
  final DeviceManagementService _deviceService = DeviceManagementService();
  Timer? _activityTimer;

  @override
  void initState() {
    super.initState();

    _setupRealtimeCallbacks();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      _handleAuthChange,
      onError: (error) {
        debugPrint('❌ Auth subscription error: $error');
      },
    );
  }

  void _setupRealtimeCallbacks() {
    _deviceService.onForceLogout = () {
      debugPrint('🚨 [Main] Déconnexion forcée détectée - déconnexion immédiate');

      _showForceLogoutNotification();
      Supabase.instance.client.auth.signOut();

      if (mounted && navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          AppRouter.login,
          (route) => false,
        );
      }
    };

    _deviceService.onRemoteDisconnect = (deviceId, deviceName) {
      debugPrint('🔔 [Main] Appareil déconnecté à distance: $deviceName');
      _showRemoteDisconnectNotification(deviceName);
    };
  }

  Future<void> _initializeDeviceMonitoring() async {
    if (_monitoringInitialized) {
      debugPrint('🔹 [Main] Monitoring déjà initialisé, ignoré');
      return;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      debugPrint('❌ [Main] Pas d\'utilisateur connecté pour monitoring');
      return;
    }

    try {
      debugPrint('🔹 [Main] Initialisation surveillance temps réel');

      await _deviceService.initCurrentDeviceFromSession();
      await _deviceService.initializeRealtimeMonitoring();

      _startActivityTimer();

      _monitoringInitialized = true;
      debugPrint('✅ [Main] Monitoring initialisé avec succès');
    } catch (e) {
      debugPrint('❌ [Main] Erreur initialisation monitoring: $e');
      _monitoringInitialized = false;
    }
  }

  void _startActivityTimer() {
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        try {
          await _deviceService.updateDeviceActivity();
        } catch (e) {
          debugPrint('❌ [Main] Erreur mise à jour activité: $e');
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _showForceLogoutNotification() {
    if (mounted && navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.logout, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vous avez été déconnecté à distance depuis un autre appareil',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _showRemoteDisconnectNotification(String deviceName) {
    if (mounted && navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'L\'appareil "$deviceName" a été déconnecté',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleAuthChange(AuthState data) async {
    if (!mounted) return;

    debugPrint('🔹 [Main] Auth event: ${data.event}');
    debugPrint('🔹 [Main] Session: ${data.session?.user.email ?? 'null'}');

    // ✅ Vérifier d'abord si la langue a été sélectionnée
    final hasSelectedLanguage = await OnboardingService.hasSelectedLanguage();
    
    if (!hasSelectedLanguage) {
      debugPrint('🎯 [Main] Langue non sélectionnée - Redirection vers language selection');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushReplacementNamed(AppRouter.languageSelection);
        }
      });
      return;
    }

    // ✅ Vérifier ensuite l'onboarding
    final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
    
    if (!hasSeenOnboarding) {
      debugPrint('🎯 [Main] Onboarding non vu - Redirection vers onboarding');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushReplacementNamed(AppRouter.onboarding);
        }
      });
      return;
    }

    // ✅ Gérer les événements d'authentification
    if (data.event == AuthChangeEvent.signedIn) {
      debugPrint('✅ [Main] Utilisateur connecté - Initialisation monitoring');
      await _initializeDeviceMonitoring();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushReplacementNamed(AppRouter.clientHome);
        }
      });
    } else if (data.event == AuthChangeEvent.signedOut) {
      debugPrint('🚪 [Main] Utilisateur déconnecté - Nettoyage');
      _cleanupOnSignOut();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushReplacementNamed(AppRouter.login);
        }
      });
    }
  }
  
  void _cleanupOnSignOut() {
    _monitoringInitialized = false;
    _activityTimer?.cancel();
    _activityTimer = null;
    _deviceService.dispose();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _activityTimer?.cancel();
    _deviceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(languageProvider);

    if (_initialized) {
      return MaterialApp(
        locale: currentLocale,
        supportedLocales: L10n.all,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MUKHLISS',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
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
}