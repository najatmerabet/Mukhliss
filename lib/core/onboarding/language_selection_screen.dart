// lib/screens/onboarding/language_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/core/providers/langue_provider.dart';
import 'package:mukhliss/core/routes/app_router.dart';
import 'package:mukhliss/core/services/onboarding_service.dart';
import 'package:mukhliss/core/theme/app_theme.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  Locale? _selectedLocale;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _selectLanguage(Locale locale) {
    setState(() {
      _selectedLocale = locale;
    });
  }

  Future<void> _continueToOnboarding() async {
    if (_selectedLocale == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Mettre à jour la langue sélectionnée
      await ref.read(languageProvider.notifier).setLocale(_selectedLocale!);

      // Marquer que la langue a été sélectionnée
      await OnboardingService.markLanguageAsSelected();

      if (!mounted) return;

      // Naviguer vers l'onboarding
      Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
    } catch (e) {
      debugPrint('Erreur lors de la sélection de la langue: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir la langue actuelle depuis le provider
    final currentLocale = ref.watch(languageProvider);

    // Initialiser la sélection si pas encore fait
    _selectedLocale ??= currentLocale;

    // Utiliser directement la liste du provider
    final supportedLanguages = LanguageNotifier.supportedLanguages;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Icône
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, const Color(0xFF818CF8)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Titre - Utiliser _selectedLocale au lieu de currentLocale
                  Text(
                    _getLocalizedTitle(_selectedLocale!),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Description - Utiliser _selectedLocale au lieu de currentLocale
                  Text(
                    _getLocalizedDescription(_selectedLocale!),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Liste des langues
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ListView.separated(
                  itemCount: supportedLanguages.length,
                  separatorBuilder:
                      (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final language = supportedLanguages[index];
                    final isSelected = _selectedLocale == language.locale;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            language.flag,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      title: Text(
                        language.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      trailing:
                          isSelected
                              ? Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              )
                              : null,
                      onTap: () => _selectLanguage(language.locale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bouton Continuer - Utiliser _selectedLocale au lieu de currentLocale
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                        : ElevatedButton(
                          onPressed:
                              _selectedLocale != null
                                  ? _continueToOnboarding
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getLocalizedButtonText(_selectedLocale!),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 22),
                            ],
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes pour la localisation des textes
  String _getLocalizedTitle(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Choisissez votre langue';
      case 'en':
        return 'Choose your language';
      case 'ar':
        return 'اختر لغتك';
      default:
        return 'Choose your language';
    }
  }

  String _getLocalizedDescription(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Sélectionnez votre langue préférée pour continuer';
      case 'en':
        return 'Select your preferred language to continue';
      case 'ar':
        return 'اختر اللغة المفضلة للمتابعة';
      default:
        return 'Select your preferred language to continue';
    }
  }

  String _getLocalizedButtonText(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Continuer';
      case 'en':
        return 'Continue';
      case 'ar':
        return 'متابعة';
      default:
        return 'Continue';
    }
  }
}
