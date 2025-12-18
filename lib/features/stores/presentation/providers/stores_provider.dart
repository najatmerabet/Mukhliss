/// ============================================================
/// Stores Provider - Presentation Layer
/// ============================================================
///
/// Providers Riverpod pour la feature Stores.
/// Optimisés pour gérer des milliers de magasins sans crash.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/store_entity.dart';
import '../../domain/repositories/stores_repository.dart';
import '../../domain/usecases/get_stores.dart';
import '../../data/repositories/stores_repository_impl.dart';

// ============================================================
// PROVIDERS D'INJECTION DE DÉPENDANCES
// ============================================================

/// Provider du repository (pour injection)
final storesRepositoryProvider = Provider<StoresRepository>((ref) {
  return StoresRepositoryImpl();
});

/// Provider du GetStoresUseCase
final getStoresUseCaseProvider = Provider<GetStoresUseCase>((ref) {
  return GetStoresUseCase(ref.watch(storesRepositoryProvider));
});

/// Provider du SearchStoresUseCase
final searchStoresUseCaseProvider = Provider<SearchStoresUseCase>((ref) {
  return SearchStoresUseCase(ref.watch(storesRepositoryProvider));
});

/// Provider du GetNearbyStoresUseCase
final getNearbyStoresUseCaseProvider = Provider<GetNearbyStoresUseCase>((ref) {
  return GetNearbyStoresUseCase(ref.watch(storesRepositoryProvider));
});

// ============================================================
// PROVIDERS DE DONNÉES (OPTIMISÉS)
// ============================================================

/// Provider pour la liste des magasins (chargement initial limité)
/// Utilisé pour l'affichage initial - limité à 100 magasins
final storesProvider = FutureProvider<List<StoreEntity>>((ref) async {
  final useCase = ref.watch(getStoresUseCaseProvider);
  return await useCase();
});

/// Provider pour la recherche de magasins
final storesSearchProvider = FutureProvider.family<List<StoreEntity>, String>((
  ref,
  query,
) async {
  final useCase = ref.watch(searchStoresUseCaseProvider);
  return await useCase(query);
});

/// Provider pour les magasins proches (utilise PostGIS côté serveur)
final nearbyStoresProvider =
    FutureProvider.family<List<StoreEntity>, ({double lat, double lng})>((
      ref,
      position,
    ) async {
      final repository = ref.watch(storesRepositoryProvider);
      return await repository.getNearbyStoresSorted(
        userLat: position.lat,
        userLng: position.lng,
        limit: 50,
      );
    });

/// Provider pour un magasin spécifique

final storeByIdProvider = FutureProvider.family<StoreEntity?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(storesRepositoryProvider);
  return await repository.getStoreById(id);
});

// ============================================================
// PAGINATION STATE NOTIFIER
// ============================================================

/// État pour la pagination des magasins
class PaginatedStoresState {
  final List<StoreEntity> stores;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final String? categoryFilter;
  final String? searchQuery;

  const PaginatedStoresState({
    this.stores = const [],
    this.currentPage = 0,
    this.totalCount = 0,
    this.pageSize = 20,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.categoryFilter,
    this.searchQuery,
  });

  PaginatedStoresState copyWith({
    List<StoreEntity>? stores,
    int? currentPage,
    int? totalCount,
    int? pageSize,
    bool? isLoading,
    bool? hasMore,
    String? error,
    String? categoryFilter,
    String? searchQuery,
  }) {
    return PaginatedStoresState(
      stores: stores ?? this.stores,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      pageSize: pageSize ?? this.pageSize,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier pour la pagination des magasins
class PaginatedStoresNotifier extends StateNotifier<PaginatedStoresState> {
  final Ref _ref;

  PaginatedStoresNotifier(this._ref) : super(const PaginatedStoresState());

  /// Charger la première page
  Future<void> loadInitial({String? categoryId, String? searchQuery}) async {
    state = PaginatedStoresState(
      isLoading: true,
      categoryFilter: categoryId,
      searchQuery: searchQuery,
    );

    try {
      final repository = _ref.read(storesRepositoryProvider);
      final result = await repository.getStoresPaginated(
        page: 0,
        pageSize: state.pageSize,
        categoryId: categoryId,
        searchQuery: searchQuery,
      );

      state = state.copyWith(
        stores: result.stores,
        currentPage: 0,
        totalCount: result.totalCount,
        hasMore: result.hasMore,
        isLoading: false,
      );
      
      debugPrint('📦 Initial load: ${result.stores.length} stores (total: ${result.totalCount})');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      debugPrint('❌ Error loading stores: $e');
    }
  }

  /// Charger la page suivante
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final repository = _ref.read(storesRepositoryProvider);
      final nextPage = state.currentPage + 1;
      
      final result = await repository.getStoresPaginated(
        page: nextPage,
        pageSize: state.pageSize,
        categoryId: state.categoryFilter,
        searchQuery: state.searchQuery,
      );

      state = state.copyWith(
        stores: [...state.stores, ...result.stores],
        currentPage: nextPage,
        hasMore: result.hasMore,
        isLoading: false,
      );
      
      debugPrint('📦 Loaded page $nextPage: ${result.stores.length} more stores');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Rafraîchir (recharger depuis le début)
  Future<void> refresh() async {
    await loadInitial(
      categoryId: state.categoryFilter,
      searchQuery: state.searchQuery,
    );
  }

  /// Filtrer par catégorie
  Future<void> filterByCategory(String? categoryId) async {
    await loadInitial(categoryId: categoryId, searchQuery: state.searchQuery);
  }

  /// Rechercher
  Future<void> search(String query) async {
    await loadInitial(categoryId: state.categoryFilter, searchQuery: query);
  }

  /// Réinitialiser les filtres
  Future<void> clearFilters() async {
    await loadInitial();
  }
}

/// Provider du StateNotifier pour la pagination
final paginatedStoresProvider =
    StateNotifierProvider<PaginatedStoresNotifier, PaginatedStoresState>((ref) {
      return PaginatedStoresNotifier(ref);
    });

// ============================================================
// STATE NOTIFIER POUR MAGASIN SÉLECTIONNÉ
// ============================================================

/// État de la sélection de magasin
class SelectedStoreState {
  final StoreEntity? store;
  final bool isLoading;
  final String? error;

  const SelectedStoreState({this.store, this.isLoading = false, this.error});

  SelectedStoreState copyWith({
    StoreEntity? store,
    bool? isLoading,
    String? error,
  }) {
    return SelectedStoreState(
      store: store ?? this.store,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour le magasin sélectionné
class SelectedStoreNotifier extends StateNotifier<SelectedStoreState> {
  final Ref _ref;

  SelectedStoreNotifier(this._ref) : super(const SelectedStoreState());

  void selectStore(StoreEntity store) {
    state = state.copyWith(store: store, error: null);
  }

  void clearSelection() {
    state = const SelectedStoreState();
  }

  Future<void> loadStoreById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = _ref.read(storesRepositoryProvider);
      final store = await repository.getStoreById(id);
      state = state.copyWith(store: store, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider du StateNotifier pour le magasin sélectionné
final selectedStoreProvider =
    StateNotifierProvider<SelectedStoreNotifier, SelectedStoreState>((ref) {
      return SelectedStoreNotifier(ref);
    });
