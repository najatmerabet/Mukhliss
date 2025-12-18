/// Utilitaires de thème pour Mukhliss.
library;

// ============================================================
// MUKHLISS - Utilitaires de Thème
// ============================================================
//
// Ce fichier centralise la logique du thème pour éviter le bug
// isDarkMode inversé qui était présent dans 40+ fichiers.
//
// UTILISATION:
// ```dart
// import 'package:mukhliss/core/theme/theme_utils.dart';
//
// final isDarkMode = ThemeUtils.isDarkMode(ref);
// ```

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/core/providers/theme_provider.dart';

/// Utilitaires centralisés pour le thème
class ThemeUtils {
  ThemeUtils._(); // Constructeur privé - classe utilitaire

  /// ✅ Vérifie si le thème sombre est actif
  ///
  /// Utiliser cette méthode au lieu de:
  /// ```dart
  /// final isDarkMode = themeMode == AppThemeMode.dark;
  /// ```
  ///
  /// Utiliser:
  /// ```dart
  /// final isDarkMode = ThemeUtils.isDarkMode(ref); // ✅ CORRECT
  /// ```
  static bool isDarkMode(WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return themeMode == AppThemeMode.dark;
  }

  /// Vérifie si le thème clair est actif
  static bool isLightMode(WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return themeMode ==
        AppThemeMode.light; // ✅ Corrigé (.light au lieu de .dark)
  }

  /// Retourne AppThemeMode actuel
  static AppThemeMode currentMode(WidgetRef ref) {
    return ref.watch(themeProvider);
  }
}
