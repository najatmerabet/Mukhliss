/// ============================================================
/// Map Widgets - Presentation Layer
/// ============================================================
///
/// Widgets réutilisables pour la carte et la localisation.
/// Extrait de location_screen.dart pour respecter SRP.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/l10n/app_localizations.dart';

/// Marqueur de position actuelle avec animation de halo
class CurrentLocationMarker extends StatelessWidget {
  final Position position;
  final bool isNavigating;
  final double? bearing;

  const CurrentLocationMarker({
    super.key,
    required this.position,
    this.isNavigating = false,
    this.bearing,
  });

  @override
  Widget build(BuildContext context) {
    if (isNavigating && bearing != null) {
      return _buildNavigationMarker();
    }
    return _buildStaticMarker();
  }

  Widget _buildStaticMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withValues(alpha: 0.2),
          ),
        ),
        // Point central
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade700,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationMarker() {
    return Transform.rotate(
      angle: (bearing ?? 0) * 3.14159265359 / 180,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.shade700,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.navigation, color: Colors.white, size: 28),
      ),
    );
  }

  /// Crée un Marker pour FlutterMap
  Marker toMarker() {
    return Marker(
      point: LatLng(position.latitude, position.longitude),
      width: isNavigating ? 56 : 48,
      height: isNavigating ? 56 : 48,
      child: this,
    );
  }
}

/// Widget d'erreur de connexion
class NoConnectionWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isDarkMode;
  final AppLocalizations? l10n;

  const NoConnectionWidget({
    super.key,
    required this.onRetry,
    this.isDarkMode = false,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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
              // Icône d'avertissement
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              // Texte principal
              Text(
                l10n?.somethingwrong ?? "Something went wrong",
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Bouton "Réessayer"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  label: Text(
                    l10n?.retry ?? 'Réessayer',
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
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
      ),
    );
  }
}

/// Widget de vérification de connectivité
class ConnectivityCheckWidget extends StatelessWidget {
  final bool isDarkMode;
  final String? message;

  const ConnectivityCheckWidget({
    super.key,
    this.isDarkMode = false,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message ?? 'Vérification de la connexion...',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne de polyline pour la route
class RoutePolyline extends StatelessWidget {
  final List<LatLng> points;
  final String mode;

  const RoutePolyline({super.key, required this.points, this.mode = 'driving'});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          color: _getRouteColor(),
          strokeWidth: 6.0,
          borderColor: Colors.white.withValues(alpha: 0.5),
          borderStrokeWidth: 3.0,
        ),
      ],
    );
  }

  Color _getRouteColor() {
    switch (mode) {
      case 'walking':
        return Colors.green;
      case 'cycling':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

/// Bouton de contrôle de carte générique
class MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDarkMode;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const MapControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isDarkMode = false,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ??
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
  }
}

/// Panneau de boutons de contrôle de carte
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
        children: [
          // Bouton localisation
          MapControlButton(
            icon: Icons.my_location,
            onPressed: onLocationPressed,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          // Bouton rafraîchir
          MapControlButton(
            icon: isLoading ? Icons.hourglass_empty : Icons.refresh,
            onPressed: isLoading ? () {} : onRefreshPressed,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          // Bouton layers
          MapControlButton(
            icon: Icons.layers,
            onPressed: onLayersPressed,
            isDarkMode: isDarkMode,
          ),
          // Bouton arrêter navigation
          if (isNavigating && onStopNavigationPressed != null) ...[
            const SizedBox(height: 12),
            MapControlButton(
              icon: Icons.close,
              onPressed: onStopNavigationPressed!,
              isDarkMode: isDarkMode,
              backgroundColor: Colors.red,
              iconColor: Colors.white,
            ),
          ],
        ],
      ),
    );
  }
}

/// Barre de recherche
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
            Text(
              hintText ?? 'Rechercher un magasin...',
              style: TextStyle(
                color: isDarkMode ? Colors.white54 : Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget d'arrivée destination
class ArrivalNotification extends StatelessWidget {
  final String storeName;
  final VoidCallback onDismiss;

  const ArrivalNotification({
    super.key,
    required this.storeName,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(
                      l10n?.vousEtesArrive ?? 'Vous êtes arrivé!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
                Text(
                  storeName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
