/// ============================================================
/// Map Control Widgets - Presentation Layer
/// ============================================================
///
/// Widgets pour les contrôles de la carte (boutons, panneau, etc.)
/// SOLID: Single Responsibility - uniquement les contrôles de carte.
library;

import 'package:flutter/material.dart';
import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/l10n/app_localizations.dart';

/// Bouton de contrôle circulaire pour la carte
class MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDarkMode;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final String? tooltip;

  const MapControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isDarkMode = false,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDarkMode ? AppColors.darkSurface : Colors.white),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              color:
                  iconColor ?? (isDarkMode ? Colors.white : AppColors.primary),
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Panneau de contrôles de carte (localisation, refresh, layers, etc.)
class MapControlsPanel extends StatelessWidget {
  final VoidCallback onLocationPressed;
  final VoidCallback onRefreshPressed;
  final VoidCallback onLayersPressed;
  final VoidCallback? onStopNavigationPressed;
  final bool isNavigating;
  final bool isLoading;
  final bool isDarkMode;

  const MapControlsPanel({
    super.key,
    required this.onLocationPressed,
    required this.onRefreshPressed,
    required this.onLayersPressed,
    this.onStopNavigationPressed,
    this.isNavigating = false,
    this.isLoading = false,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton ma localisation
          MapControlButton(
            icon: Icons.my_location,
            onPressed: onLocationPressed,
            isDarkMode: isDarkMode,
            tooltip: 'Ma position',
          ),
          const SizedBox(height: 12),

          // Bouton rafraîchir
          MapControlButton(
            icon: isLoading ? Icons.hourglass_empty : Icons.refresh,
            onPressed: isLoading ? () {} : onRefreshPressed,
            isDarkMode: isDarkMode,
            tooltip: 'Rafraîchir',
          ),
          const SizedBox(height: 12),

          // Bouton couches de carte
          MapControlButton(
            icon: Icons.layers,
            onPressed: onLayersPressed,
            isDarkMode: isDarkMode,
            tooltip: 'Couches',
          ),

          // Bouton arrêter navigation (conditionnel)
          if (isNavigating && onStopNavigationPressed != null) ...[
            const SizedBox(height: 12),
            MapControlButton(
              icon: Icons.close,
              onPressed: onStopNavigationPressed!,
              isDarkMode: isDarkMode,
              backgroundColor: Colors.red,
              iconColor: Colors.white,
              tooltip: 'Arrêter navigation',
            ),
          ],
        ],
      ),
    );
  }
}

/// Barre de recherche de la carte
class MapSearchBar extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDarkMode;
  final String? hintText;

  const MapSearchBar({
    super.key,
    required this.onTap,
    this.isDarkMode = false,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: isDarkMode ? Colors.white70 : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hintText ?? l10n?.chercher ?? 'Rechercher un magasin...',
                style: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget d'état de chargement de la carte
class MapLoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isDarkMode;

  const MapLoadingOverlay({super.key, this.message, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: (isDarkMode ? Colors.black : Colors.white).withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget d'erreur de connexion pour la carte
class MapConnectionError extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isDarkMode;

  const MapConnectionError({
    super.key,
    required this.onRetry,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              child: const Icon(Icons.wifi_off, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),

            // Message
            Text(
              l10n?.somethingwrong ?? 'Problème de connexion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Bouton réessayer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  l10n?.retry ?? 'Réessayer',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
