/// ============================================================
/// Mukhliss App - Widget Principal
/// ============================================================
///
/// Widget MaterialApp principal de l'application.
/// Configuré avec thème, localisation, et routing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/core/errors/global_error_handler.dart';
import 'package:mukhliss/core/providers/langue_provider.dart';
import 'package:mukhliss/core/providers/theme_provider.dart';
import 'package:mukhliss/core/routes/app_router.dart';
import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/l10n/l10n.dart';
import 'auth_state_handler.dart';

/// Widget principal de l'application Mukhliss
///
/// Responsabilités:
/// - Configuration du thème (clair/sombre)
/// - Configuration de la localisation (fr/en/ar)
/// - Configuration du routing
/// - Liaison avec le GlobalErrorHandler pour les notifications
class MukhlissApp extends ConsumerWidget {
  const MukhlissApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observer les préférences utilisateur
    final currentLocale = ref.watch(languageProvider);
    final currentThemeMode = ref.watch(themeProvider);

    // Créer la clé pour le ScaffoldMessenger global
    final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    GlobalErrorHandler.scaffoldMessengerKey = scaffoldMessengerKey;

    return MaterialApp(
      // Métadonnées
      title: 'MUKHLISS',
      debugShowCheckedModeBanner: false,

      // Thème
      theme: AppColors.lightTheme,
      darkTheme: AppColors.darkTheme,
      themeMode: _convertThemeMode(currentThemeMode),

      // Localisation
      supportedLocales: L10n.all,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: currentLocale,

      // Navigation
      onGenerateRoute: AppRouter.generateRoute,

      // Clé pour les notifications globales
      scaffoldMessengerKey: scaffoldMessengerKey,

      // Page d'accueil - gestion de l'état d'authentification
      home: const AuthStateHandler(),
    );
  }

  /// Convertit AppThemeMode en ThemeMode Flutter
  ThemeMode _convertThemeMode(AppThemeMode appThemeMode) {
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

/// Widget d'erreur affiché si l'initialisation échoue
class ErrorApp extends StatelessWidget {
  final String? errorMessage;

  const ErrorApp({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MUKHLISS - Erreur',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône d'erreur
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 24),

                // Titre
                Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  errorMessage ??
                      'L\'application n\'a pas pu démarrer.\nVeuillez vérifier votre connexion internet et réessayer.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Bouton réessayer (optionnel)
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter le redémarrage de l'app
                    debugPrint('Attempting to restart...');
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
