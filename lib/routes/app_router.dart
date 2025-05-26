import 'package:flutter/material.dart';
import 'package:mukhliss/screen/auth/Otp_Verification_page.dart';
import 'package:mukhliss/screen/auth/login_page.dart';
import 'package:mukhliss/screen/auth/password_reset_page.dart';
import 'package:mukhliss/screen/auth/signup_page.dart';
import 'package:mukhliss/screen/client/clienthome.dart';
import 'package:mukhliss/screen/client/profile.dart';
import 'package:mukhliss/screen/layout/main_navigation_screen.dart';


class AppRouter {
  static const String login = '/';
  static const String signupClient = '/signup-client';
  static const String clientHome = '/home';
  static const String passwordReset = '/password-reset';
  static const String otpVerification = '/otp-verification';
  static const String profile='/profile';
    static const String main = '/main'; // Route vers le layout principal

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
         case main:
        return MaterialPageRoute(builder: (_) =>  MainNavigationScreen());
      case clientHome:
        return MaterialPageRoute(builder: (_) => const ClientHome());
      case signupClient:
        return MaterialPageRoute(builder: (_) => const ClientSignup());
      case passwordReset:
        final email = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PasswordResetPage( email:email),
        );
      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OtpVerificationPage(email: args['email']),
        );
       case profile :
         return MaterialPageRoute(builder: (_)=> const Profile() );
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route non définie: ${settings.name}')),
          ),
        );
    }
  }
}