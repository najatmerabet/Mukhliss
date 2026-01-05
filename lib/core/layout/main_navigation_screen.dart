import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/core/providers/theme_provider.dart';
import 'package:mukhliss/core/providers/guest_mode_provider.dart';
import 'package:mukhliss/core/routes/app_router.dart';
import 'package:mukhliss/features/stores/presentation/screens/location_screen.dart';
import 'package:mukhliss/features/offers/offers.dart' show MyOffersScreen;
import 'package:mukhliss/features/profile/profile.dart'
    show QRCodeScreen, ProfileScreen;
import 'package:mukhliss/core/theme/app_theme.dart';

/// Écran principal de navigation avec bottom navigation bar.
///
/// Gère la navigation entre les écrans principaux.
/// En mode invité, seuls certains onglets sont accessibles.

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Écrans disponibles selon le mode (invité ou connecté)
  List<Widget> _getScreens(bool isGuestMode) {
    if (isGuestMode) {
      // Mode invité : Offres et Localisation seulement
      return [
        MyOffersScreen(),
        LocationScreen(),
        _buildLoginPromptScreen(), // Au lieu du profil
      ];
    } else {
      // Mode connecté : tous les écrans
      return [
        QRCodeScreen(),
        MyOffersScreen(),
        LocationScreen(),
        ProfileScreen(),
      ];
    }
  }

  /// Écran incitant à se connecter (pour mode invité)
  Widget _buildLoginPromptScreen() {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A0E27) : AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Connectez-vous pour plus de fonctionnalités',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Créez un compte pour accéder à votre QR Code fidélité, gérer votre profil et accumuler des points.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(guestModeProvider.notifier).disableGuestMode();
                      Navigator.pushReplacementNamed(context, AppRouter.login);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    ref.read(guestModeProvider.notifier).disableGuestMode();
                    Navigator.pushReplacementNamed(
                        context, AppRouter.signupClient);
                  },
                  child: Text(
                    'Créer un compte',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.dark;
    final isGuestMode = ref.watch(guestModeProvider);
    final screens = _getScreens(isGuestMode);

    // Réinitialiser l'index si nécessaire
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0A0E27) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 85,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: isGuestMode
                  ? [
                      // Mode invité : Offres, Localisation, Compte
                      _buildNavItem(0, Icons.local_offer, 'Offres'),
                      _buildNavItem(1, Icons.location_on, 'Magasins'),
                      _buildNavItem(2, Icons.person, 'Compte'),
                    ]
                  : [
                      // Mode connecté : QR, Offres, Localisation, Profil
                      _buildNavItem(0, Icons.qr_code, 'QR Code'),
                      _buildNavItem(1, Icons.local_offer, 'Offres'),
                      _buildNavItem(2, Icons.location_on, 'Magasins'),
                      _buildNavItem(3, Icons.person, 'Profil'),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == _currentIndex;
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isDarkMode
                      ? (isSelected ? Colors.white : Colors.white)
                      : (isSelected
                          ? Colors.white
                          : const Color.fromARGB(255, 195, 201, 212)
                              .withValues(alpha: 0.7)),
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
