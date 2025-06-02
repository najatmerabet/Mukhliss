// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/screen/auth/login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/theme/app_theme.dart';

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
    await Future.delayed(const Duration(seconds: 5));
    
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
   final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
   final isDarkMode = themeMode == AppThemeMode.light;
    
    return Scaffold(
    backgroundColor: isDarkMode 
          ? AppColors.darkBackground 
          : AppColors.lightBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
             colors: isDarkMode ? AppColors.darkGradient :AppColors.lightGradient,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isDarkMode.toString()),
              Text(
                l10n?.hello ?? 'Bienvenue sur MUKHLISS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Image.asset(
                'images/withoutbg.png',
                width: 200,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: themeMode == AppThemeMode.dark
                        ? Colors.grey[400]
                        : Colors.white,
                  );
                },
              ),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  themeMode == AppThemeMode.dark
                      ? Colors.grey[400]!
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}