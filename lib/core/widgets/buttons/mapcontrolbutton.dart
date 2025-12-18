import 'package:flutter/material.dart';

class MapControllerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final LinearGradient backgroundGradient;
  final bool isLoading;

  const MapControllerButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.isLoading,
    required this.backgroundGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: backgroundGradient, // Utilisation directe du gradient
        ),
        child: IconButton(
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                )
              : Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
      ),
    );
  }
}