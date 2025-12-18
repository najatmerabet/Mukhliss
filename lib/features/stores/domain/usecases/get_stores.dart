/// ============================================================
/// GetStores Use Case - Domain Layer
/// ============================================================
///
/// Cas d'utilisation pour récupérer la liste des magasins.
/// Un UseCase = Une action métier.
library;

import '../entities/store_entity.dart';
import '../repositories/stores_repository.dart';

/// Use case pour récupérer tous les magasins
class GetStoresUseCase {
  final StoresRepository _repository;

  GetStoresUseCase(this._repository);

  /// Exécute le use case
  Future<List<StoreEntity>> call() async {
    return await _repository.getStores();
  }
}

/// Use case pour récupérer les magasins proches
class GetNearbyStoresUseCase {
  final StoresRepository _repository;

  GetNearbyStoresUseCase(this._repository);

  /// Exécute le use case
  Future<List<StoreEntity>> call({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    return await _repository.getNearbyStores(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
}

/// Use case pour rechercher des magasins
class SearchStoresUseCase {
  final StoresRepository _repository;

  SearchStoresUseCase(this._repository);

  /// Exécute le use case
  Future<List<StoreEntity>> call(String query) async {
    if (query.isEmpty) return [];
    return await _repository.searchStores(query);
  }
}
