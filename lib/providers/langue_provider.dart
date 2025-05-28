// lib/providers/language_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en')) {
    _loadSavedLanguage();
  }

  static const String _languageKey = 'selected_language';

  // Langues supportées
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(
      locale: Locale('fr'),
      name: 'Français',
      flag: '🇫🇷',
      code: 'fr',
    ),
    LanguageOption(
      locale: Locale('en'),
      name: 'English',
      flag: '🇺🇸',
      code: 'en',
    ),
    LanguageOption(
      locale: Locale('ar'),
      name: 'العربية',
      flag: '🇲🇦',
      code: 'ar',
    ),
  ];

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);
      
      if (savedLanguageCode != null) {
        final savedLanguage = supportedLanguages.firstWhere(
          (lang) => lang.code == savedLanguageCode,
          orElse: () => supportedLanguages[1], // English par défaut
        );
        state = savedLanguage.locale;
      }
    } catch (e) {
      print('Erreur lors du chargement de la langue: $e');
    }
  }

  Future<void> changeLanguage(Locale newLocale) async {
    try {
      state = newLocale;
      
      // Sauvegarder la préférence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, newLocale.languageCode);
      
      print('Langue changée vers: ${newLocale.languageCode}');
    } catch (e) {
      print('Erreur lors du changement de langue: $e');
    }
  }

  LanguageOption get currentLanguageOption {
    return supportedLanguages.firstWhere(
      (lang) => lang.locale.languageCode == state.languageCode,
      orElse: () => supportedLanguages[1],
    );
  }
}

class LanguageOption {
  final Locale locale;
  final String name;
  final String flag;
  final String code;

  const LanguageOption({
    required this.locale,
    required this.name,
    required this.flag,
    required this.code,
  });
}

// Provider global
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>(
  (ref) => LanguageNotifier(),
);