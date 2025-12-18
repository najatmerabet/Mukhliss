/// ============================================================
/// Location Widgets - Composants UI réutilisables
/// ============================================================
///
/// Contient tous les widgets UI extraits de LocationScreen
/// pour respecter le principe SRP (Single Responsibility)
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/core/utils/category_helpers.dart';
import 'package:mukhliss/core/utils/geticategoriesbyicon.dart';
import 'package:mukhliss/core/widgets/buttons/buildmaplayerbutton.dart';
import 'package:mukhliss/core/widgets/buttons/mapcontrolbutton.dart';
import 'package:mukhliss/features/stores/stores.dart';
import 'package:mukhliss/features/location/data/services/osrm_service.dart';

// ============================================================
// PANNEAU DE CONTRÔLE
// ============================================================

/// Panneau de boutons de contrôle de la carte
class MapControlPanel extends StatelessWidget {
  final bool isNavigating;
  final bool isLocationLoading;
  final bool hasPosition;
  final bool isDarkMode;
  final VoidCallback onStopNavigation;
  final VoidCallback? onCenterLocation;
  final VoidCallback? onRefresh;
  final VoidCallback onToggleLayers;
  final Widget searchButton;

  const MapControlPanel({
    super.key,
    required this.isNavigating,
    required this.isLocationLoading,
    required this.hasPosition,
    required this.isDarkMode,
    required this.onStopNavigation,
    required this.onCenterLocation,
    required this.onRefresh,
    required this.onToggleLayers,
    required this.searchButton,
  });

  LinearGradient get _defaultGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors:
        isDarkMode
            ? [const Color(0xFF0A0E27), const Color(0xFF0A0E27)]
            : [AppColors.lightPrimary, AppColors.lightSecondary],
  );

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          searchButton,
          const SizedBox(height: 10),

          if (isNavigating) ...[
            MapControllerButton(
              icon: Icons.stop,
              onPressed: onStopNavigation,
              backgroundGradient: const LinearGradient(
                colors: [Colors.red, Colors.red],
              ),
              isLoading: false,
            ),
            const SizedBox(height: 10),
          ],

          MapControllerButton(
            icon: Icons.my_location,
            onPressed: hasPosition ? onCenterLocation : null,
            backgroundGradient: _defaultGradient,
            isLoading: isLocationLoading,
          ),
          const SizedBox(height: 10),

          MapControllerButton(
            icon: Icons.refresh,
            onPressed: isLocationLoading ? null : onRefresh,
            backgroundGradient: _defaultGradient,
            isLoading: isLocationLoading,
          ),
          const SizedBox(height: 10),

          MapControllerButton(
            icon: Icons.layers,
            onPressed: onToggleLayers,
            backgroundGradient: _defaultGradient,
            isLoading: false,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================
// SÉLECTEUR DE COUCHES
// ============================================================

/// Sélecteur de type de carte (Plan, Satellite, etc.)
class MapLayerSelectorPanel extends StatelessWidget {
  final MapLayerType selectedLayer;
  final ValueChanged<MapLayerType> onLayerSelected;
  final VoidCallback onClose;

  const MapLayerSelectorPanel({
    super.key,
    required this.selectedLayer,
    required this.onLayerSelected,
    required this.onClose,
  });

  static const _layers = [
    (MapLayerType.plan, Icons.map, 'Plan'),
    (MapLayerType.satellite, Icons.satellite_alt, 'Satellite'),
    (MapLayerType.terrain, Icons.terrain, 'Terrain'),
    (MapLayerType.trafic, Icons.traffic, 'Trafic'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Type de carte',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._layers.map(
            (layer) => MapLayerButton(
              layer: layer.$1,
              selectedLayer: selectedLayer,
              icon: layer.$2,
              label: layer.$3,
              onSelected: onLayerSelected,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MARQUEURS
// ============================================================

/// Marqueur de position actuelle (mode normal)
class StaticPositionMarker extends StatelessWidget {
  const StaticPositionMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withValues(alpha: 0.2),
          ),
        ),
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
}

/// Marqueur pulsant pour la navigation
class PulsatingNavigationMarker extends StatelessWidget {
  final double bearing;
  final double pulseValue;

  const PulsatingNavigationMarker({
    super.key,
    required this.bearing,
    required this.pulseValue,
  });

  static const _primaryColor = Color.fromARGB(255, 35, 143, 252);

  @override
  Widget build(BuildContext context) {
    final pulseSize = 48 + (6 * math.sin(pulseValue * 2 * math.pi));

    return Stack(
      alignment: Alignment.center,
      children: [
        // Effet de pulsation
        Container(
          width: pulseSize,
          height: pulseSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primaryColor.withValues(alpha: 0.2),
          ),
        ),
        // Point central
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primaryColor,
            boxShadow: [
              BoxShadow(
                color: _primaryColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        // Flèche de direction
        Transform.translate(
          offset: Offset(
            25 * math.cos(bearing * math.pi / 180 - math.pi / 2),
            25 * math.sin(bearing * math.pi / 180 - math.pi / 2),
          ),
          child: Transform.rotate(
            angle: bearing * (math.pi / 180),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.navigation,
                color: _primaryColor,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// RÉSULTATS DE RECHERCHE
// ============================================================

/// Liste des résultats de recherche
class SearchResultsList extends ConsumerWidget {
  final List<StoreEntity> results;
  final Position? currentPosition;
  final ValueChanged<StoreEntity> onStoreSelected;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.currentPosition,
    required this.onStoreSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final store = results[index];
            return _SearchResultTile(
              store: store,
              currentPosition: currentPosition,
              onTap: () => onStoreSelected(store),
              ref: ref,
            );
          },
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final StoreEntity store;
  final Position? currentPosition;
  final VoidCallback onTap;
  final WidgetRef ref;

  const _SearchResultTile({
    required this.store,
    required this.currentPosition,
    required this.onTap,
    required this.ref,
  });

  String get _distanceText {
    if (currentPosition == null) return '';
    final distance = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      store.latitude,
      store.longitude,
    );
    return distance < 1000
        ? '${distance.toStringAsFixed(0)} m'
        : '${(distance / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = CategoryHelpers.getCategoryName(ref, store.categoryId);

    return ListTile(
      leading: Icon(
        CategoryMarkers.getPinIcon(categoryName),
        color: CategoryMarkers.getPinColor(categoryName),
      ),
      title: Text(store.name),
      subtitle: Text(store.address ?? ''),
      trailing: Text(_distanceText),
      onTap: onTap,
    );
  }
}

// ============================================================
// LISTE DE MARQUEURS
// ============================================================

/// Génère la liste des marqueurs de magasins
List<Marker> buildStoreMarkers({
  required List<StoreEntity> stores,
  required CategoryEntity? selectedCategory,
  required ValueChanged<StoreEntity> onStoreSelected,
  required WidgetRef ref,
}) {
  if (stores.isEmpty) return [];

  final filteredStores =
      selectedCategory != null
          ? stores
              .where((s) => s.categoryId == selectedCategory.id.toString())
              .toList()
          : stores;

  if (filteredStores.isEmpty) return [];

  return filteredStores.map((store) {
    return Marker(
      point: LatLng(store.latitude, store.longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => onStoreSelected(store),
        child: CategoryMarkers.getPinWidget(
          CategoryHelpers.getCategoryName(ref, store.categoryId),
          size: 40,
        ),
      ),
    );
  }).toList();
}

// ============================================================
// UTILITAIRES
// ============================================================

/// Retourne la couleur de route selon le mode de transport
Color getRouteColor(TransportMode mode) {
  switch (mode) {
    case TransportMode.walking:
      return Colors.green.shade600;
    case TransportMode.cycling:
      return Colors.orange.shade600;
    case TransportMode.driving:
      return Colors.blue.shade600;
  }
}

/// Calcule le bearing de navigation
double? calculateNavigationBearing({
  required LatLng currentPosition,
  required List<LatLng> polylinePoints,
}) {
  if (polylinePoints.isEmpty) return null;

  // Trouver le point le plus proche
  double minDistance = double.infinity;
  int nearestIndex = 0;

  for (int i = 0; i < polylinePoints.length; i++) {
    final distance = _calculateDistance(currentPosition, polylinePoints[i]);
    if (distance < minDistance) {
      minDistance = distance;
      nearestIndex = i;
    }
  }

  // Prendre le prochain point comme cible
  final targetIndex = (nearestIndex + 1).clamp(0, polylinePoints.length - 1);
  final target = polylinePoints[targetIndex];

  // Calculer le bearing
  final lat1 = currentPosition.latitude * math.pi / 180;
  final lat2 = target.latitude * math.pi / 180;
  final dLon = (target.longitude - currentPosition.longitude) * math.pi / 180;

  final y = math.sin(dLon) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

  var bearing = math.atan2(y, x) * 180 / math.pi;
  return (bearing + 360) % 360;
}

double _calculateDistance(LatLng p1, LatLng p2) {
  final dx = p1.latitude - p2.latitude;
  final dy = p1.longitude - p2.longitude;
  return math.sqrt(dx * dx + dy * dy);
}
