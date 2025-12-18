/// ============================================================
/// Store Markers Layer - Presentation Layer
/// ============================================================
///
/// Widget responsable de l'affichage des marqueurs de magasins sur la carte.
/// SOLID: Single Responsibility - uniquement les marqueurs de magasins.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mukhliss/features/stores/domain/entities/category_entity.dart';
import 'package:mukhliss/features/stores/domain/entities/store_entity.dart';
import 'package:mukhliss/features/stores/presentation/providers/stores_provider.dart';
import 'package:mukhliss/core/utils/category_helpers.dart';
import 'package:mukhliss/core/utils/geticategoriesbyicon.dart';

/// Widget qui affiche les marqueurs de magasins sur la carte
///
/// Utilise Consumer pour écouter les changements de données.
/// Filtre automatiquement par catégorie si spécifiée.
class StoreMarkersLayer extends ConsumerWidget {
  /// Catégorie sélectionnée pour le filtrage (null = tous les magasins)
  final CategoryEntity? selectedCategory;

  /// Callback appelé quand un magasin est sélectionné
  final void Function(StoreEntity store) onStoreSelected;

  const StoreMarkersLayer({
    super.key,
    this.selectedCategory,
    required this.onStoreSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);

    return storesAsync.when(
      data: (stores) => MarkerLayer(markers: _buildMarkers(stores, ref)),
      loading: () => const MarkerLayer(markers: []),
      error: (_, __) => const MarkerLayer(markers: []),
    );
  }

  /// Construit la liste des marqueurs filtrée
  List<Marker> _buildMarkers(List<StoreEntity> stores, WidgetRef ref) {
    if (stores.isEmpty) return [];

    // Filtrer par catégorie si spécifiée
    final filteredStores =
        selectedCategory != null
            ? stores
                .where((s) => s.categoryId == selectedCategory!.id.toString())
                .toList()
            : stores;

    // Convertir en marqueurs
    return filteredStores
        .map((store) => _createStoreMarker(store, ref))
        .toList();
  }

  /// Crée un marqueur pour un magasin
  Marker _createStoreMarker(StoreEntity store, WidgetRef ref) {
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
  }
}

/// Widget pour le marqueur de position actuelle
class CurrentPositionMarker extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool isNavigating;
  final double? bearing;

  const CurrentPositionMarker({
    super.key,
    required this.latitude,
    required this.longitude,
    this.isNavigating = false,
    this.bearing,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(latitude, longitude),
          width: isNavigating ? 56 : 48,
          height: isNavigating ? 56 : 48,
          child: isNavigating ? _buildNavigationMarker() : _buildStaticMarker(),
        ),
      ],
    );
  }

  Widget _buildStaticMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo externe
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
}

/// Widget pour la ligne de route (polyline)
class RoutePolylineLayer extends StatelessWidget {
  final List<LatLng> points;
  final String mode;

  const RoutePolylineLayer({
    super.key,
    required this.points,
    this.mode = 'walking',
  });

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
