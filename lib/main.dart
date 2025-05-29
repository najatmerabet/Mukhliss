// main.dart - Version avec gestion du thème
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/l10n.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:mukhliss/screen/slash_screen.dart';
import 'package:mukhliss/services/device_management_service.dart';
import 'package:mukhliss/providers/langue_provider.dart'; // Ajoutez cette import
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

    runApp(ProviderScope(child: AuthWrapper()));
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
  final DeviceManagementService _deviceService = DeviceManagementService();
  Timer? _activityTimer;

  @override
  void initState() {
    super.initState();
    
    // Configuration des callbacks temps réel
    _setupRealtimeCallbacks();
    
    // Initialiser la surveillance des appareils
    _initializeDeviceMonitoring();
    
    // Écoute des changements d'authentification
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      _handleAuthChange,
    );
  }

  void _setupRealtimeCallbacks() {
    // Callback pour déconnexion forcée
    _deviceService.onForceLogout = () {
      debugPrint('🚨 [Main] Déconnexion forcée détectée - déconnexion immédiate');
      
      // Afficher une notification à l'utilisateur
      _showForceLogoutNotification();
      
      // Déconnecter immédiatement
      Supabase.instance.client.auth.signOut();
      
      // Redirection vers login
      if (mounted && navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          AppRouter.login,
          (route) => false,
        );
      }
    };

    // Callback pour notification de déconnexion d'un autre appareil
    _deviceService.onRemoteDisconnect = (deviceId, deviceName) {
      debugPrint('🔔 [Main] Appareil déconnecté à distance: $deviceName');
      _showRemoteDisconnectNotification(deviceName);
    };
  }

  Future<void> _initializeDeviceMonitoring() async {
    // Attendre que l'authentification soit prête
    await Future.delayed(const Duration(milliseconds: 500));
    
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      debugPrint('🔹 [Main] Initialisation surveillance temps réel');
      await _deviceService.initCurrentDeviceFromSession();
      await _deviceService.initializeRealtimeMonitoring();
      
      // Démarrer le timer d'activité
      _startActivityTimer();
    }
  }

  void _startActivityTimer() {
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await _deviceService.updateDeviceActivity();
      } else {
        timer.cancel();
      }
    });
  }

  void _showForceLogoutNotification() {
    // Afficher un SnackBar ou un Dialog pour informer l'utilisateur
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

  void _handleAuthChange(AuthState data) {
    if (!mounted) return;

    debugPrint('🔹 [Main] Auth event: ${data.event}');
    debugPrint('🔹 [Main] Session: ${data.session?.user.email ?? 'null'}');

    switch (data.event) {
      case AuthChangeEvent.initialSession:
        if (data.session != null) {
          debugPrint('🔹 [Main] Session initiale trouvée, redirection vers main');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && navigatorKey.currentState != null) {
              navigatorKey.currentState!.pushReplacementNamed(AppRouter.main);
              // Initialiser le monitoring après la navigation
              _initializeDeviceMonitoring();
            }
          });
        } else {
          debugPrint('🔹 [Main] Pas de session initiale, redirection vers login');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && navigatorKey.currentState != null) {
              navigatorKey.currentState!.pushReplacementNamed(AppRouter.login);
            }
          });
        }
        break;

      case AuthChangeEvent.signedIn:
        if (data.session != null) {
          debugPrint('🔹 [Main] Connexion réussie, redirection vers main');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && navigatorKey.currentState != null) {
              navigatorKey.currentState!.pushReplacementNamed(AppRouter.main);
              // Initialiser le monitoring après la navigation
              _initializeDeviceMonitoring();
            }
          });
        }
        break;

      case AuthChangeEvent.signedOut:
        debugPrint('🔹 [Main] Déconnexion, nettoyage et redirection vers login');
        _cleanupOnSignOut();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && navigatorKey.currentState != null) {
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              AppRouter.login,
              (route) => false,
            );
          }
        });
        break;

      case AuthChangeEvent.passwordRecovery:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        debugPrint('🔹 [Main] Événement ${data.event} - pas de redirection');
        break;
      
      case AuthChangeEvent.userDeleted:
        _cleanupOnSignOut();
        break;
      case AuthChangeEvent.mfaChallengeVerified:
        break;
    }
  }

  void _cleanupOnSignOut() {
    // Nettoyer les timers et subscriptions
    _activityTimer?.cancel();
    _activityTimer = null;
    
    // Nettoyer le service des appareils
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
    final currentThemeMode = ref.watch(themeProvider);
    
    if (_initialized) {
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


