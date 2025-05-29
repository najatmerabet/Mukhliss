import 'package:flutter/material.dart';
import 'package:mukhliss/screen/auth/Otp_Verification_page.dart';
import 'package:mukhliss/screen/auth/login_page.dart';
import 'package:mukhliss/screen/auth/password_reset_page.dart';
import 'package:mukhliss/screen/auth/signup_page.dart';
import 'package:mukhliss/screen/client/profile.dart';
import 'package:mukhliss/screen/client/profile/settings_screen.dart';
import 'package:mukhliss/screen/client/profile_new.dart';
import 'package:mukhliss/screen/layout/main_navigation_screen.dart';

class AppRouter {
  static const String login = '/';
  static const String signupClient = '/signup-client';
  static const String clientHome = '/home';
  static const String passwordReset = '/password-reset';
  static const String otpVerification = '/otp-verification';
  static const String profile = '/profile';
  static const String main = '/main'; // Route vers le layout principal
  static const String setting = '/setting'; // Route vers le layout principal

  static Route<dynamic> unknownRoute() {
    return MaterialPageRoute(
      builder:
          (_) => Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: const Center(child: Text('Page non trouvée')),
          ),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (settings.name?.contains('login-callback') ?? false) {
      return MaterialPageRoute(
        builder: (_) => MainNavigationScreen(), // Écran de chargement
        settings: settings,
      );
    }
    print('AppRouter - Route: ${settings.name}');

    switch (settings.name) {
      case setting:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case main:
        return MaterialPageRoute(builder: (_) => MainNavigationScreen());
      case clientHome:
        return MaterialPageRoute(builder: (_) => MainNavigationScreen());
      case signupClient:
        return MaterialPageRoute(builder: (_) => const ClientSignup());
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
          settings: settings, // Important pour récupérer les arguments
        );
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      default:
        print('Route non définie: ${settings.name}');
        // Au lieu de montrer une erreur, rediriger vers login
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
