// lib/screens/onboarding/widgets/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:mukhliss/screen/onboarding/onboarding_screen.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          
          // Illustration
          _buildIllustration(),
          
          const SizedBox(height: 48),
          
          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
              letterSpacing: 0.1,
            ),
          ),
          
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            data.secondaryColor.withOpacity(0.1),
            data.primaryColor.withOpacity(0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated circles
          ...List.generate(3, (index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 2000 + (index * 500)),
              width: 200 - (index * 40.0),
              height: 200 - (index * 40.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: data.primaryColor.withOpacity(0.1 - (index * 0.03)),
                  width: 2,
                ),
              ),
            );
          }),
          
          // Main icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.primaryColor,
                  data.secondaryColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: data.primaryColor.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 56,
              color: Colors.white,
            ),
          ),
          
          // Floating particles
          Positioned(
            top: 40,
            right: 50,
            child: _buildFloatingParticle(12, data.primaryColor),
          ),
          Positioned(
            bottom: 60,
            left: 40,
            child: _buildFloatingParticle(8, data.secondaryColor),
          ),
          Positioned(
            top: 80,
            left: 60,
            child: _buildFloatingParticle(10, data.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(double size, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2000),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -10 * value),
          child: Opacity(
            opacity: 1 - (value * 0.5),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
      onEnd: () {
        // Loop animation
      },
    );
  }
}