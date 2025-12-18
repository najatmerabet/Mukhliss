/// ============================================================
/// Map Control Buttons Panel - Presentation Layer
/// ============================================================
///
/// Panneau de boutons de contrôle pour la carte.
/// Extrait de location_screen.dart pour respecter SRP.
library;

import 'package:flutter/material.dart';
import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/core/widgets/buttons/mapcontrolbutton.dart';

/// Panneau de contrôle de la carte (localisation, refresh, layers)
class MapControlButtonsPanel extends StatelessWidget {
  final bool isDarkMode;
  final bool isNavigating;
  final bool isLocationLoading;
  final bool hasCurrentPosition;
  final VoidCallback? onMyLocation;
  final VoidCallback? onRefresh;
  final VoidCallback? onToggleLayers;
  final VoidCallback? onStopNavigation;

  const MapControlButtonsPanel({
    super.key,
    required this.isDarkMode,
    this.isNavigating = false,
    this.isLocationLoading = false,
    this.hasCurrentPosition = false,
    this.onMyLocation,
    this.onRefresh,
    this.onToggleLayers,
    this.onStopNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Bouton stop navigation (visible seulement pendant la navigation)
        if (isNavigating) ...[
          MapControllerButton(
            icon: Icons.stop,
            onPressed: onStopNavigation,
            backgroundGradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red, AppColors.error],
            ),
            isLoading: false,
          ),
          const SizedBox(height: 10),
        ],

        // Bouton ma position
        MapControllerButton(
          icon: Icons.my_location,
          onPressed: hasCurrentPosition ? onMyLocation : null,
          backgroundGradient: _getButtonGradient(),
          isLoading: isLocationLoading,
        ),
        const SizedBox(height: 10),

        // Bouton rafraîchir
        MapControllerButton(
          icon: Icons.refresh,
          onPressed: isLocationLoading ? null : onRefresh,
          backgroundGradient: _getButtonGradient(),
          isLoading: isLocationLoading,
        ),
        const SizedBox(height: 10),

        // Bouton layers
        MapControllerButton(
          icon: Icons.layers,
          onPressed: onToggleLayers,
          backgroundGradient: _getButtonGradient(),
          isLoading: isLocationLoading,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  LinearGradient _getButtonGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors:
          isDarkMode
              ? [const Color(0xFF0A0E27), const Color(0xFF0A0E27)]
              : [AppColors.lightPrimary, AppColors.lightSecondary],
    );
  }
}
