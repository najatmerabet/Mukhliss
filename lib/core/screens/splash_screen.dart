/// Page de splash migrée vers Clean Architecture.
library;

// ============================================================
// MUKHLISS - Splash Screen (Migrée)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/core/routes/app_router.dart';
import 'package:mukhliss/core/services/onboarding_service.dart';
import 'package:mukhliss/core/theme/app_theme.dart';

// ✅ Nouveau système
import 'package:mukhliss/core/core.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    AppLogger.navigation('SplashScreen initialisé');
    // Utiliser addPostFrameCallback pour éviter l'accès prématuré au context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Charger l'image (maintenant le context est prêt)
      if (mounted) {
        await precacheImage(
          const AssetImage('images/mukhlislogo1.png'),
          context,
        );
      }

      // 2. Afficher l'écran
      if (mounted) {
        setState(() => _isReady = true);
      }

      // 3. Attendre 3 secondes
      await Future.delayed(const Duration(seconds: 3));

      // 4. Naviguer
      if (mounted) {
        await _navigateToNextScreen();
      }
    } catch (e) {
      AppLogger.error('Erreur initialisation splash', error: e);
      if (mounted) {
        setState(() => _isReady = true);
        await Future.delayed(const Duration(seconds: 2));
        await _navigateToNextScreen();
      }
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    try {
      // Vérifier onboarding
      final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();

      if (!hasSeenOnboarding) {
        AppLogger.navigation('Première ouverture → Onboarding');
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.onboarding);
        }
        return;
      }

      // ✅ Utiliser le nouveau système d'auth
      final authClient = ref.read(authClientProvider);
      final currentUser = authClient.currentUser;

      if (currentUser != null) {
        AppLogger.auth('Session active → Main');
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.main);
        }
      } else {
        AppLogger.auth('Pas de session → Login');
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.login);
        }
      }
    } catch (e) {
      AppLogger.error('Erreur navigation splash', error: e);
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDarkMode = ThemeUtils.isDarkMode(ref); // ✅ Utilise ThemeUtils

    // Si l'image n'est pas encore chargée
    if (!_isReady) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:
                  isDarkMode
                      ? [
                        AppColors.darkWhite,
                        AppColors.darkGrey50,
                        AppColors.darkPurpleDark,
                      ]
                      : [
                        AppColors.lightWhite,
                        AppColors.lightGrey50,
                        AppColors.lightPurpleDark,
                      ],
            ),
          ),
        ),
      );
    }

    // L'image est chargée
    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? [
                      AppColors.darkWhite,
                      AppColors.darkGrey50,
                      AppColors.darkPurpleDark,
                    ]
                    : [
                      AppColors.lightWhite,
                      AppColors.lightGrey50,
                      AppColors.lightPurpleDark,
                    ],
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
                          scale: value.clamp(0.0, 1.0),
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: Image.asset(
                        'images/mukhlislogo1.png',
                        width: 200,
                        height: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.card_membership_rounded,
                            size: 100,
                            color: isDarkMode ? Colors.grey[400] : Colors.white,
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
                              color: Colors.black.withValues(alpha: 0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      l10n?.votrecartefidelite ??
                          'Votre carte de fidélité intelligente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 48),

                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode ? Colors.grey[400]! : Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      l10n?.chargement ?? 'Chargement...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
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
