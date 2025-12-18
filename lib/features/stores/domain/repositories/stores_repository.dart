/// ============================================================
/// Stores Repository Interface - Domain Layer
/// ============================================================
///
/// Interface abstraite définissant le contrat du repository.
/// Permet de changer l'implémentation sans toucher au domain.
/// Optimisée pour gérer des milliers de magasins.
library;

import '../entities/store_entity.dart';

/// Résultat paginé pour les entités magasins
class PaginatedStoresResult {
  final List<StoreEntity> stores;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  
  PaginatedStoresResult({
    required this.stores,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  });
  
  bool get hasMore => (currentPage + 1) * pageSize < totalCount;
  int get totalPages => (totalCount / pageSize).ceil();
}

/// Interface du repository des magasins
abstract class StoresRepository {
  /// Récupère tous les magasins (limité pour l'affichage initial)
  Future<List<StoreEntity>> getStores();

  /// Récupère un magasin par son ID
  Future<StoreEntity?> getStoreById(String id);

  /// Recherche des magasins par nom
  Future<List<StoreEntity>> searchStores(String query);

  /// Récupère les magasins par catégorie
  Future<List<StoreEntity>> getStoresByCategory(String categoryId);

  /// Récupère les magasins proches d'une position
  Future<List<StoreEntity>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  });

  /// Récupère les magasins dans une zone visible (viewport)
  Future<List<StoreEntity>> getStoresInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  });

  /// Récupère les magasins triés par distance (du plus proche au plus loin)
  /// Utilise PostGIS côté serveur pour les performances
  Future<List<StoreEntity>> getNearbyStoresSorted({
    required double userLat,
    required double userLng,
    int limit = 50,
  });

  /// Récupère les magasins avec pagination
  /// Idéal pour les listes avec scroll infini
  Future<PaginatedStoresResult> getStoresPaginated({
    int page = 0,
    int pageSize = 20,
    String? categoryId,
    String? searchQuery,
  });
}
