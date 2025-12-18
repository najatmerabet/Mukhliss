/// ============================================================
/// Global Error Handler
/// ============================================================
///
/// Gestionnaire centralisé des erreurs non gérées de l'application.
/// Capture les erreurs Flutter, les erreurs asynchrones, et les erreurs Supabase.
///
/// Usage:
/// ```dart
/// // Dans injection_container.dart
/// GlobalErrorHandler.initialize();
/// GlobalErrorHandler.setupSupabaseAuthListener();
/// ```
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gestionnaire d'erreurs global pour l'application Mukhliss
class GlobalErrorHandler {
  /// Clé pour accéder au ScaffoldMessenger depuis n'importe où
  static GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  /// Flag pour éviter de configurer plusieurs fois le listener Supabase
  static bool _supabaseListenerSetup = false;

  /// Constructeur privé - classe utilitaire statique
  GlobalErrorHandler._();

  /// Initialise les gestionnaires d'erreurs Flutter et Platform
  ///
  /// Doit être appelé AVANT Supabase.initialize()
  static void initialize() {
    // Capturer les erreurs Flutter synchrones (widgets, rendu, etc.)
    FlutterError.onError = _handleFlutterError;

    // Capturer les erreurs asynchrones non gérées
    PlatformDispatcher.instance.onError = _handlePlatformError;

    debugPrint('🛡️ GlobalErrorHandler initialized');
  }

  /// Configure l'écouteur d'état d'authentification Supabase
  ///
  /// Doit être appelé APRÈS Supabase.initialize()
  static void setupSupabaseAuthListener() {
    if (_supabaseListenerSetup) {
      debugPrint('⚠️ Supabase auth listener already setup');
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      // Écouter les changements d'état d'authentification
      supabase.auth.onAuthStateChange.listen(
        _handleAuthStateChange,
        onError: (error) {
          debugPrint('❌ Auth state change error: $error');
          _handleSupabaseAuthError(error);
        },
      );

      _supabaseListenerSetup = true;
      debugPrint('✅ Supabase auth listener setup successfully');
    } catch (e) {
      debugPrint('❌ Failed to setup Supabase auth listener: $e');
    }
  }

  /// Gère les erreurs Flutter (synchrones)
  static void _handleFlutterError(FlutterErrorDetails details) {
    debugPrint('🔴 Flutter Error: ${details.exception}');
    if (details.stack != null) {
      debugPrint('Stack trace:\n${details.stack}');
    }

    // Vérifier si c'est une erreur d'auth Supabase
    _handleSupabaseAuthError(details.exception);
  }

  /// Gère les erreurs Platform (asynchrones)
  static bool _handlePlatformError(Object error, StackTrace stack) {
    debugPrint('🔴 Platform Error: $error');
    debugPrint('Stack trace:\n$stack');

    // Vérifier si c'est une erreur d'auth Supabase
    _handleSupabaseAuthError(error);

    // Retourner true pour indiquer que l'erreur a été gérée
    return true;
  }

  /// Gère les changements d'état d'authentification
  static void _handleAuthStateChange(AuthState data) {
    final event = data.event;
    final session = data.session;

    debugPrint('🔐 Auth state changed: $event');

    if (event == AuthChangeEvent.signedOut && session == null) {
      debugPrint('🚪 User signed out - possibly due to auth error');
    }

    if (event == AuthChangeEvent.tokenRefreshed) {
      debugPrint('🔄 Token refreshed successfully');
    }
  }

  /// Détecte et gère les erreurs d'authentification Supabase
  static void _handleSupabaseAuthError(dynamic error) {
    if (error == null) return;

    final errorString = error.toString();

    // Patterns d'erreurs d'authentification Supabase
    const authErrorPatterns = [
      'AuthRetryableFetchException',
      'Failed host lookup',
      'supabase.co',
      'refresh_token',
      'No address associated with hostname',
      'SocketException',
      'Connection refused',
    ];

    final isAuthError = authErrorPatterns.any(
      (pattern) => errorString.contains(pattern),
    );

    if (isAuthError) {
      debugPrint('🔧 Supabase auth error detected: $errorString');
      _notifyNetworkError();
    }
  }

  /// Affiche une notification de problème réseau
  static void _notifyNetworkError() {
    debugPrint('📡 Notifying user of network connectivity issues');

    final messenger = scaffoldMessengerKey?.currentState;
    if (messenger == null) {
      debugPrint('⚠️ ScaffoldMessenger not available for notification');
      return;
    }

    try {
      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
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

  /// Affiche une erreur personnalisée à l'utilisateur
  static void showError(String message, {bool isWarning = false}) {
    final messenger = scaffoldMessengerKey?.currentState;
    if (messenger == null) return;

    try {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isWarning ? Icons.warning_amber : Icons.error_outline,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          backgroundColor: isWarning ? Colors.orange[700] : Colors.red[700],
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      debugPrint('Failed to show error: $e');
    }
  }

  /// Affiche un message de succès
  static void showSuccess(String message) {
    final messenger = scaffoldMessengerKey?.currentState;
    if (messenger == null) return;

    try {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      debugPrint('Failed to show success: $e');
    }
  }
}
