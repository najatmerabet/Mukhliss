/// ============================================================
/// Auth State Handler
/// ============================================================
///
/// Widget qui gère l'état d'authentification et la navigation
/// basée sur cet état (login, onboarding, home).
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/features/auth/auth.dart' show AuthFlowHelper;
import 'package:mukhliss/core/logger/app_logger.dart';
import 'package:mukhliss/core/routes/app_router.dart';
import 'package:mukhliss/core/screens/splash_screen.dart';
import 'package:mukhliss/core/services/onboarding_service.dart';
import 'package:mukhliss/features/profile/data/services/device_management_service.dart';
import 'package:mukhliss/features/profile/presentation/providers/profile_provider.dart';
import 'package:mukhliss/features/stores/presentation/providers/client_store_provider.dart';
import 'package:mukhliss/features/stores/presentation/providers/clientmagazin_provider.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/l10n/l10n.dart';
import 'package:mukhliss/core/providers/langue_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gère l'état d'authentification et la navigation appropriée
class AuthStateHandler extends ConsumerStatefulWidget {
  const AuthStateHandler({super.key});

  @override
  ConsumerState<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends ConsumerState<AuthStateHandler> {
  /// Clé de navigation pour les redirections programmatiques
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Subscription aux changements d'état d'authentification
  StreamSubscription<AuthState>? _authSubscription;

  /// Flag pour éviter d'initialiser le monitoring plusieurs fois
  bool _monitoringInitialized = false;

  /// Service de gestion des appareils
  final DeviceManagementService _deviceService = DeviceManagementService();

  /// Timer pour mettre à jour l'activité de l'appareil
  Timer? _activityTimer;

  @override
  void initState() {
    super.initState();
    _setupRealtimeCallbacks();
    _setupAuthListener();
  }

  /// Configure l'écouteur d'état d'authentification Supabase
  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      _handleAuthChange,
      onError: (error) {
        debugPrint('❌ Auth subscription error: $error');
      },
    );
  }

  /// Configure les callbacks pour les événements temps réel
  void _setupRealtimeCallbacks() {
    // Callback pour déconnexion forcée (ex: depuis un autre appareil)
    _deviceService.onForceLogout = () {
      debugPrint('🚨 [AuthStateHandler] Force logout detected');
      _showForceLogoutNotification();
      Supabase.instance.client.auth.signOut();
      _navigateTo(AppRouter.login);
    };

    // Callback pour déconnexion d'un autre appareil
    _deviceService.onRemoteDisconnect = (deviceId, deviceName) {
      debugPrint(
        '🔔 [AuthStateHandler] Remote device disconnected: $deviceName',
      );
      _showRemoteDisconnectNotification(deviceName);
    };
  }

  /// Gère les changements d'état d'authentification
  Future<void> _handleAuthChange(AuthState data) async {
    if (!mounted) return;

    debugPrint('🔹 [AuthStateHandler] Auth event: ${data.event}');
    debugPrint(
      '🔹 [AuthStateHandler] User: ${data.session?.user.email ?? 'null'}',
    );

    // Vérifier le parcours d'onboarding
    final shouldShowOnboarding = await _checkOnboardingFlow();
    if (shouldShowOnboarding) return;

    // Gérer les événements d'authentification
    switch (data.event) {
      case AuthChangeEvent.signedIn:
        await _handleSignedIn();
      case AuthChangeEvent.signedOut:
        _handleSignedOut();
      case AuthChangeEvent.tokenRefreshed:
        debugPrint('🔄 Token refreshed');
      default:
        break;
    }
  }

  /// Vérifie si l'utilisateur doit passer par l'onboarding
  ///
  /// Retourne true si une redirection a été effectuée
  Future<bool> _checkOnboardingFlow() async {
    // 1. Vérifier la sélection de langue
    final hasSelectedLanguage = await OnboardingService.hasSelectedLanguage();
    if (!hasSelectedLanguage) {
      debugPrint('🎯 [AuthStateHandler] Language not selected - redirecting');
      _navigateTo(AppRouter.languageSelection);
      return true;
    }

    // 2. Vérifier l'onboarding
    final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
    if (!hasSeenOnboarding) {
      debugPrint('🎯 [AuthStateHandler] Onboarding not seen - redirecting');
      _navigateTo(AppRouter.onboarding);
      return true;
    }

    return false;
  }

  /// Gère la connexion réussie
  Future<void> _handleSignedIn() async {
    // Vérifier si on est dans un flux de reset password
    if (AuthFlowHelper.isPasswordResetInProgress) {
      debugPrint(
        '🔐 [AuthStateHandler] Password reset in progress - no redirect',
      );
      return;
    }

    debugPrint('✅ [AuthStateHandler] User signed in - initializing monitoring');
    await _initializeDeviceMonitoring();
    _navigateTo(AppRouter.clientHome);
  }

  /// Gère la déconnexion
  void _handleSignedOut() {
    debugPrint('🚪 [AuthStateHandler] User signed out - cleanup');
    _cleanupOnSignOut();
    _navigateTo(AppRouter.login);
  }

  /// Initialise la surveillance des appareils
  Future<void> _initializeDeviceMonitoring() async {
    if (_monitoringInitialized) {
      debugPrint('🔹 [AuthStateHandler] Monitoring already initialized');
      return;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      debugPrint('❌ [AuthStateHandler] No user for monitoring');
      return;
    }

    try {
      debugPrint('🔹 [AuthStateHandler] Initializing device monitoring');

      // D'abord essayer de charger le deviceId depuis la session existante
      await _deviceService.initCurrentDeviceFromSession();

      // Si aucun deviceId n'a été trouvé, enregistrer l'appareil actuel
      if (_deviceService.currentDeviceId == null) {
        debugPrint(
            '🔹 [AuthStateHandler] No existing device found, registering current device');
        final device = await _deviceService.registerCurrentDevice();
        if (device != null) {
          debugPrint(
              '✅ [AuthStateHandler] Device registered: ${device.deviceName}');
        } else {
          debugPrint('⚠️ [AuthStateHandler] Failed to register device');
        }
      } else {
        debugPrint(
            '✅ [AuthStateHandler] Existing device found: ${_deviceService.currentDeviceId}');
      }

      // Initialiser le monitoring temps réel
      await _deviceService.initializeRealtimeMonitoring();
      _startActivityTimer();
      _monitoringInitialized = true;
      debugPrint('✅ [AuthStateHandler] Monitoring initialized');
    } catch (e) {
      debugPrint('❌ [AuthStateHandler] Monitoring init error: $e');
      _monitoringInitialized = false;
    }
  }

  /// Démarre le timer d'activité
  void _startActivityTimer() {
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        try {
          await _deviceService.updateDeviceActivity();
        } catch (e) {
          debugPrint('❌ [AuthStateHandler] Activity update error: $e');
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Nettoie les ressources lors de la déconnexion
  void _cleanupOnSignOut() {
    _monitoringInitialized = false;
    _activityTimer?.cancel();
    _activityTimer = null;
    _deviceService.dispose();

    // Invalider les providers Riverpod pour forcer le rechargement des données
    // au prochain login avec un autre compte
    try {
      ref.invalidate(currentProfileProvider);
      ref.invalidate(totalPointsProvider);
      ref.invalidate(clientStoresProvider);
      
      // ⚠️ IMPORTANT: Effacer le cache des points cumulés
      // Cela force le rechargement des points pour le nouveau compte
      ref.read(clientPointsCacheRefreshProvider.notifier).state++;
      debugPrint('🧹 [AuthStateHandler] Client points cache invalidated');
      
      debugPrint('✅ [AuthStateHandler] Providers invalidated');
    } catch (e) {
      debugPrint('⚠️ [AuthStateHandler] Provider invalidation error: $e');
    }
  }

  /// Navigue vers une route donnée
  void _navigateTo(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushReplacementNamed(route);
      }
    });
  }

  /// Affiche une notification de déconnexion forcée
  void _showForceLogoutNotification() {
    if (!mounted || navigatorKey.currentContext == null) return;

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

  /// Affiche une notification de déconnexion d'appareil distant
  void _showRemoteDisconnectNotification(String deviceName) {
    if (!mounted || navigatorKey.currentContext == null) return;

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
        AppLogger.debug('Route requested: ${settings.name}');

        // Gérer les callbacks d'authentification avec code
        if (settings.name != null && settings.name!.contains('code=')) {
          AppLogger.debug('Auth callback detected with code');
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
