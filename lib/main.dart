/// ============================================================
/// MUKHLISS - Point d'entrée de l'application
/// ============================================================
///
/// Application de fidélité client Mukhliss.
/// Gestion des offres, récompenses et magasins partenaires.
///
/// Architecture: Clean Architecture avec Riverpod
/// Backend: Supabase (PostgreSQL, Auth, Storage)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/app/mukhliss_app.dart';
import 'package:mukhliss/core/di/injection_container.dart' as di;
import 'package:mukhliss/core/logger/app_logger.dart';

/// Point d'entrée de l'application
///
/// 1. Initialise les bindings Flutter
/// 2. Charge les dépendances via injection_container
/// 3. Lance l'application avec Riverpod
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialiser toutes les dépendances
    await di.init();

    // Lancer l'application
    runApp(const ProviderScope(child: MukhlissApp()));
  } catch (e, stack) {
    // En cas d'erreur d'initialisation, afficher l'écran d'erreur
    AppLogger.debug('Erreur d\'initialisation: $e');
    AppLogger.debug('Stack: $stack');
    runApp(ErrorApp(errorMessage: e.toString()));
  }
}
