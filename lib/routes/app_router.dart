import 'package:flutter/material.dart';
import 'package:mukhliss/screen/auth/Otp_Verification_page.dart';
import 'package:mukhliss/screen/auth/login_page.dart';
import 'package:mukhliss/screen/auth/password_reset_page.dart';
import 'package:mukhliss/screen/auth/signup_page.dart';
import 'package:mukhliss/screen/client/clienthome.dart';
import 'package:mukhliss/screen/client/profile.dart';


class AppRouter {
  
  static const String login = '/';
  static const String signupClient = '/signup-client';
  static const String clientHome = '/home';
  static const String passwordReset = '/password-reset';
  static const String otpVerification = '/otp-verification';
  static const String profile = '/profile';
  
  static Route<dynamic> unknownRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Page non trouvée')),
      ),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
     if (settings.name?.contains('login-callback') ?? false) {
    return MaterialPageRoute(
      builder: (_) => const ClientHome(), // Écran de chargement
      settings: settings,
    );
  }
    print('AppRouter - Route: ${settings.name}');
    
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case clientHome:
        return MaterialPageRoute(builder: (_) => const ClientHome());
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
          builder: (_) => OtpVerificationPage(email: args['email']),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => const Profile());
      
      default:
        print('Route non définie: ${settings.name}');
        // Au lieu de montrer une erreur, rediriger vers login
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }

  
}