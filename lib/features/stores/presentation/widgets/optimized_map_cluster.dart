/// ============================================================
/// Optimized Map Cluster Widget
/// ============================================================
/// 
/// Widget optimisé pour afficher des milliers de marqueurs
/// avec clustering automatique selon le niveau de zoom.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/store_entity.dart';
import '../../domain/entities/category_entity.dart';
import 'package:mukhliss/core/utils/category_helpers.dart';
import 'package:mukhliss/core/utils/geticategoriesbyicon.dart';

/// Widget de clustering optimisé pour les marqueurs de magasins
class OptimizedStoreClusterLayer extends ConsumerWidget {
  final List<StoreEntity> stores;
  final CategoryEntity? selectedCategory;
  final ValueChanged<StoreEntity> onStoreSelected;
  final MapController mapController;

  const OptimizedStoreClusterLayer({
    super.key,
    required this.stores,
    this.selectedCategory,
    required this.onStoreSelected,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🗺️ OptimizedStoreClusterLayer: ${stores.length} magasins reçus');
    
    // Filtrer par catégorie si nécessaire
    final filteredStores = selectedCategory != null
        ? stores.where((s) => s.categoryId == selectedCategory!.id.toString()).toList()
        : stores;

    debugPrint('🗺️ Après filtre catégorie: ${filteredStores.length} magasins');

    // Filtrer les magasins avec des coordonnées invalides
    final validStores = filteredStores.where((store) => _isValidCoordinate(store)).toList();

    debugPrint('🗺️ Après validation coordonnées: ${validStores.length} magasins valides');

    // Si aucun magasin valide, afficher un message de debug
    if (validStores.isEmpty) {
      debugPrint('⚠️ Aucun magasin valide à afficher!');
      if (filteredStores.isNotEmpty) {
        // Logger le premier magasin filtré pour debug
        final first = filteredStores.first;
        debugPrint('⚠️ Premier magasin: lat=${first.latitude}, lng=${first.longitude}');
      }
      return const SizedBox.shrink();
    }

    // Créer les marqueurs optimisés
    final markers = _buildOptimizedMarkers(validStores, ref);

    debugPrint('🗺️ Marqueurs créés: ${markers.length}');

    if (markers.isEmpty) {
      return const SizedBox.shrink();
    }

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        maxClusterRadius: 80,
        size: const Size(50, 50),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(50),
        maxZoom: 15,
        markers: markers,
        builder: (context, markers) {
          return _buildClusterWidget(markers.length);
        },
        // Optimisations de performance
        spiderfyCircleRadius: 40,
        spiderfySpiralDistanceMultiplier: 2,
        showPolygon: false,
        // Animation fluide
        animationsOptions: const AnimationsOptions(
          zoom: Duration(milliseconds: 200),
          fitBound: Duration(milliseconds: 300),
          centerMarkerCurves: Curves.easeInOut,
          spiderfy: Duration(milliseconds: 200),
        ),
      ),
    );
  }

  /// Vérifie si les coordonnées du magasin sont valides
  bool _isValidCoordinate(StoreEntity store) {
    final lat = store.latitude;
    final lng = store.longitude;
    
    // Latitude: -90 à 90, Longitude: -180 à 180
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    
    // Exclure les coordonnées nulles (0, 0)
    if (lat == 0 && lng == 0) return false;
    
    return true;
  }

  /// Construit les marqueurs optimisés avec cache
  List<Marker> _buildOptimizedMarkers(List<StoreEntity> stores, WidgetRef ref) {
    return stores.map((store) {
      final categoryName = CategoryHelpers.getCategoryName(ref, store.categoryId);
      
      return Marker(
        point: LatLng(store.latitude, store.longitude),
        width: 40,
        height: 40,
        child: _OptimizedMarkerWidget(
          store: store,
          categoryName: categoryName,
          onTap: () => onStoreSelected(store),
        ),
      );
    }).toList();
  }

  /// Widget du cluster avec compteur
  Widget _buildClusterWidget(int count) {
    // Couleur dynamique selon le nombre
    Color clusterColor;
    if (count < 10) {
      clusterColor = Colors.blue.shade400;
    } else if (count < 50) {
      clusterColor = Colors.orange.shade400;
    } else if (count < 100) {
      clusterColor = Colors.deepOrange.shade400;
    } else {
      clusterColor = Colors.red.shade400;
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: clusterColor,
        boxShadow: [
          BoxShadow(
            color: clusterColor.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          count > 999 ? '999+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Widget de marqueur optimisé avec RepaintBoundary
class _OptimizedMarkerWidget extends StatelessWidget {
  final StoreEntity store;
  final String categoryName;
  final VoidCallback onTap;

  const _OptimizedMarkerWidget({
    required this.store,
    required this.categoryName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary pour éviter les repaints inutiles
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: CategoryMarkers.getPinWidget(
          categoryName,
          size: 40,
        ),
      ),
    );
  }
}

/// Provider pour le viewport des magasins visibles
final visibleStoresProvider = Provider.family<List<StoreEntity>, VisibleBounds>(
  (ref, bounds) {
    // Ce provider pourrait être utilisé pour filtrer les magasins
    // par viewport côté serveur si nécessaire
    return [];
  },
);

/// Classe pour définir les limites visibles
class VisibleBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const VisibleBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  /// Crée depuis les bounds de la carte
  factory VisibleBounds.fromLatLngBounds(LatLngBounds bounds) {
    return VisibleBounds(
      minLat: bounds.southWest.latitude,
      maxLat: bounds.northEast.latitude,
      minLng: bounds.southWest.longitude,
      maxLng: bounds.northEast.longitude,
    );
  }

  /// Vérifie si un point est dans les limites
  bool contains(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  /// Étend les limites d'un certain pourcentage (pour le préchargement)
  VisibleBounds expand(double factor) {
    final latDiff = (maxLat - minLat) * factor;
    final lngDiff = (maxLng - minLng) * factor;
    return VisibleBounds(
      minLat: minLat - latDiff,
      maxLat: maxLat + latDiff,
      minLng: minLng - lngDiff,
      maxLng: maxLng + lngDiff,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisibleBounds &&
        other.minLat == minLat &&
        other.maxLat == maxLat &&
        other.minLng == minLng &&
        other.maxLng == maxLng;
  }

  @override
  int get hashCode => Object.hash(minLat, maxLat, minLng, maxLng);
}
