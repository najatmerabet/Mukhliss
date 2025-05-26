import 'package:flutter/material.dart';
import 'package:mukhliss/screen/client/location.dart';
import 'package:mukhliss/screen/client/offres.dart';
import 'package:mukhliss/screen/client/profile_new.dart';
import 'package:mukhliss/screen/client/qr_code_screen.dart';
// Couleurs modernes
class AppColors {
  static const primary = Color(0xFF6366F1);
  static const secondary = Color(0xFF8B5CF6);
  static const accent = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const surface = Color(0xFFF8FAFC);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
}
Widget _buildModernHeader({
  required String title,
  String? subtitle,
  IconData? actionIcon,
  VoidCallback? onActionPressed,
  List<Color>? gradientColors,
}) {
  return SliverAppBar(
    expandedHeight: 140,
    floating: false,
    pinned: true,
    automaticallyImplyLeading: false,
    elevation: 0,
    backgroundColor: Colors.transparent,
    flexibleSpace: FlexibleSpaceBar(
      background: Stack(
        children: [
          // Main gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ?? [AppColors.primary, AppColors.secondary],
              ),
            ),
          ),
          // Animated circles background
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 50,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actionIcon != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: onActionPressed,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            actionIcon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(0),
      child: Container(
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
      ),
    ),
  );
}
class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> 
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  final List<Widget> _screens = [
    QRCodeScreen(),
    MyOffersScreen(),
    LocationScreen(),
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                _buildNavItem(3, Icons.person),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildNavItem(int index, IconData icon) {
  final isSelected = index == _currentIndex;
  
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
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? Colors.white 
                    : AppColors.textSecondary.withOpacity(0.7),
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