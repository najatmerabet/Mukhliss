import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/core/providers/theme_provider.dart';
import 'package:mukhliss/features/stores/presentation/screens/location_screen.dart';
import 'package:mukhliss/features/offers/offers.dart' show MyOffersScreen;
import 'package:mukhliss/features/profile/profile.dart'
    show QRCodeScreen, ProfileScreen;
import 'package:mukhliss/core/theme/app_theme.dart';

/// Écran principal de navigation avec bottom navigation bar.
///
/// Gère la navigation entre les 4 écrans principaux:
/// - QR Code
/// - Offres
/// - Localisation
/// - Profil

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

  final List<Widget> _screens = [
    QRCodeScreen(),
    MyOffersScreen(),
    LocationScreen(), // Remplace LocationScreen()

    ProfileScreen(),
  ];

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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.dark;
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF0A0E27) : Colors.white,
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
              children: [
                _buildNavItem(0, Icons.qr_code),
                _buildNavItem(1, Icons.local_offer),
                _buildNavItem(2, Icons.location_on),

                _buildNavItem(4, Icons.person),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
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
                  gradient:
                      isSelected
                          ? LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      isSelected
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
                  color:
                      isDarkMode
                          ? (isSelected ? Colors.white : Colors.white)
                          : (isSelected
                              ? Colors.white
                              : const Color.fromARGB(
                                255,
                                195,
                                201,
                                212,
                              ).withValues(alpha: 0.7)),
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              // Optional: Add a small indicator dot
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
