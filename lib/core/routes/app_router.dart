import 'package:flutter/material.dart';

// ✅ Core (inclut OtpVerificationType, AppLogger)
import 'package:mukhliss/core/core.dart';

// ✅ Auth screens (from features - provides LoginPage, SignupPage, etc.)
import 'package:mukhliss/features/auth/auth.dart';

// Core screens
import 'package:mukhliss/core/screens/splash_screen.dart';
import 'package:mukhliss/core/onboarding/language_selection_screen.dart';
import 'package:mukhliss/core/onboarding/onboarding_screen.dart';

// Pages existantes
import 'package:mukhliss/features/profile/profile.dart'
    show ProfileScreen, SettingsScreen;
import 'package:mukhliss/core/layout/main_navigation_screen.dart';

/// Router centralisé pour l'application Mukhliss
class AppRouter {
  static const String splash = '/';
  static const String languageSelection = '/language-selection';
  static const String login = '/login';
  static const String signupClient = '/signup-client';
  static const String clientHome = '/home';
  static const String passwordReset = '/password-reset';
  static const String otpVerification = '/otp-verification';
  static const String profile = '/profile';
  static const String main = '/main';
  static const String setting = '/setting';
  static const String maptest = '/test';
  static const String onboarding = '/onboarding';

  /// Route inconnue - fallback
  static Route<dynamic> unknownRoute() {
    return MaterialPageRoute(
      builder:
          (_) => Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: const Center(child: Text('Page non trouvée')),
          ),
    );
  }

  /// Génère une route à partir des settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Gérer les callbacks d'authentification
    if (settings.name?.contains('login-callback') ?? false) {
      AppLogger.navigation('Callback auth détecté');
      return MaterialPageRoute(
        builder: (_) => MainNavigationScreen(),
        settings: settings,
      );
    }

    AppLogger.navigation('Navigation vers: ${settings.name}');

    switch (settings.name) {
      case languageSelection:
        return MaterialPageRoute(
          builder: (_) => const LanguageSelectionScreen(),
        );

      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case setting:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case main:
        return MaterialPageRoute(builder: (_) => MainNavigationScreen());

      case clientHome:
        return MaterialPageRoute(builder: (_) => MainNavigationScreen());

      case signupClient:
        return MaterialPageRoute(builder: (_) => const SignupPage());

      // maptest route removed - test_map.dart was deleted

      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case passwordReset:
        final email = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PasswordResetPage(email: email),
        );

      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder:
              (_) => OtpVerificationPage(
                email: args['email'],
                type: args['type'] as OtpVerificationType,
              ),
          settings: settings,
        );

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      default:
        AppLogger.warning('Route non définie: ${settings.name}', tag: 'Router');
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
