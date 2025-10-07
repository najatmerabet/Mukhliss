// splash_screen.dart - Version corrigée
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:mukhliss/screen/auth/login_page.dart';
import 'package:mukhliss/services/onboarding_service.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Attendre un peu pour l'animation du splash
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    try {
      // ✅ ÉTAPE 1 : Vérifier d'abord l'onboarding
      final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
      
      if (!hasSeenOnboarding) {
        debugPrint('🎯 Première ouverture - Redirection vers onboarding');
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.onboarding);
        }
        return;
      }

      // ✅ ÉTAPE 2 : Si onboarding déjà vu, vérifier l'authentification
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        debugPrint('✅ Session active - Redirection vers Main');
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.main);
        }
      } else {
        debugPrint('❌ Aucune session - Redirection vers Login');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur navigation: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = themeMode == AppThemeMode.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? AppColors.darkBackground 
          : AppColors.lightBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
                ? AppColors.darkGradientscreen 
                : AppColors.lightGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo avec animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: Image.asset(
                        'images/withoutbg.png',
                        width: 200,
                        height: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.card_membership_rounded,
                            size: 100,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.white,
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Titre avec animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        l10n?.hello ?? 'Bienvenue sur MUKHLISS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Sous-titre
                    Text(
                    l10n?.votrecartefidelite ??  'Votre carte de fidélité intelligente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.3,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode
                              ? Colors.grey[400]!
                              : Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Texte de chargement
                    Text(
                 l10n?.chargement ?? 'Chargement...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}