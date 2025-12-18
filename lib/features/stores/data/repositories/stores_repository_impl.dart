/// ============================================================
/// Stores Repository Implementation - Data Layer
/// ============================================================
///
/// Implémentation concrète du repository.
/// Coordonne les datasources et convertit en entités.
/// Optimisée pour gérer des milliers de magasins.
library;

import '../../domain/entities/store_entity.dart';
import '../../domain/repositories/stores_repository.dart' as domain;
import '../datasources/stores_remote_datasource.dart' as data;

class StoresRepositoryImpl implements domain.StoresRepository {
  final data.StoresRemoteDataSource _remoteDataSource;

  StoresRepositoryImpl({data.StoresRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? data.StoresRemoteDataSourceImpl();

  @override
  Future<List<StoreEntity>> getStores() async {
    final models = await _remoteDataSource.getStores();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<StoreEntity?> getStoreById(String id) async {
    final model = await _remoteDataSource.getStoreById(id);
    return model?.toEntity();
  }

  @override
  Future<List<StoreEntity>> searchStores(String query) async {
    final models = await _remoteDataSource.searchStores(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<StoreEntity>> getStoresByCategory(String categoryId) async {
    final models = await _remoteDataSource.getStoresByCategory(categoryId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<StoreEntity>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    // Utiliser la nouvelle méthode RPC avec le rayon en mètres
    final models = await _remoteDataSource.getNearbyStoresSorted(
      userLat: latitude,
      userLng: longitude,
      radiusMeters: radiusKm * 1000,
      limit: 100,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<StoreEntity>> getStoresInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    final models = await _remoteDataSource.getStoresInBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<StoreEntity>> getNearbyStoresSorted({
    required double userLat,
    required double userLng,
    int limit = 50,
  }) async {
    final models = await _remoteDataSource.getNearbyStoresSorted(
      userLat: userLat,
      userLng: userLng,
      limit: limit,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<domain.PaginatedStoresResult> getStoresPaginated({
    int page = 0,
    int pageSize = 20,
    String? categoryId,
    String? searchQuery,
  }) async {
    final result = await _remoteDataSource.getStoresPaginated(
      page: page,
      pageSize: pageSize,
      categoryId: categoryId,
      searchQuery: searchQuery,
    );
    
    return domain.PaginatedStoresResult(
      stores: result.stores.map((m) => m.toEntity()).toList(),
      totalCount: result.totalCount,
      currentPage: result.currentPage,
      pageSize: result.pageSize,
    );
  }
}
