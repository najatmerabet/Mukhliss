import 'package:mukhliss/core/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum personnalisé pour les modes de thème (renommé pour éviter le conflit)
enum AppThemeMode { light, dark, system }

// Provider pour le thème
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const String _themeKey = 'selected_theme_mode';
  
  ThemeNotifier() : super(AppThemeMode.system) {
    _loadThemeMode();
  }

  // Charger le thème sauvegardé
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        state = AppThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => AppThemeMode.system,
        );
      }
    } catch (e) {
      AppLogger.debug('Erreur lors du chargement du thème: $e');
    }
  }

  // Changer le thème
  Future<void> changeTheme(AppThemeMode newTheme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, newTheme.toString());
      state = newTheme;
    } catch (e) {
      AppLogger.debug('Erreur lors de la sauvegarde du thème: $e');
    }
  }

  // Basculer entre light et dark
  Future<void> toggleTheme() async {
    final newTheme = state == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light;
    await changeTheme(newTheme);
  }

  // Obtenir le titre du thème actuel
  String getThemeTitle() {
    switch (state) {
      case AppThemeMode.light:
        return 'Clair';
      case AppThemeMode.dark:
        return 'Sombre';
      case AppThemeMode.system:
        return 'Système';
    }
  }

  // Vérifier si le mode sombre est activé
  bool get isDarkMode => state == AppThemeMode.dark;
  
  // Vérifier si c'est le mode système
  bool get isSystemMode => state == AppThemeMode.system;
}