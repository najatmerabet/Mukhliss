/// ============================================================
/// Store Providers - Presentation Layer
/// ============================================================
///
/// Providers Riverpod pour la gestion des magasins.
/// Utilise Clean Architecture avec datasources.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/core/logger/app_logger.dart';

import '../../data/datasources/stores_remote_datasource.dart';
import '../../data/repositories/stores_repository_impl.dart';
import '../../domain/entities/store_entity.dart';
import '../../domain/repositories/stores_repository.dart';

// ============================================================
// DATASOURCE PROVIDERS
// ============================================================

/// Provider pour la source de données distante des magasins
final storesRemoteDataSourceProvider = Provider<StoresRemoteDataSource>((ref) {
  return StoresRemoteDataSourceImpl();
});

// ============================================================
// REPOSITORY PROVIDERS
// ============================================================

/// Provider pour le repository des magasins
final storesRepositoryProvider = Provider<StoresRepository>((ref) {
  return StoresRepositoryImpl(
    remoteDataSource: ref.read(storesRemoteDataSourceProvider),
  );
});

// ============================================================
// STATE PROVIDERS
// ============================================================

/// État des magasins avec pagination
class StoresState {
  final List<StoreEntity> stores;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const StoresState({
    this.stores = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  StoresState copyWith({
    List<StoreEntity>? stores,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return StoresState(
      stores: stores ?? this.stores,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Notifier pour gérer l'état des magasins
class StoresStateNotifier extends StateNotifier<StoresState> {
  final StoresRepository _repository;

  StoresStateNotifier(this._repository) : super(const StoresState()) {
    loadStores();
  }

  /// Charge les magasins initiaux
  Future<void> loadStores() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final stores = await _repository.getStores();
      state = state.copyWith(
        stores: stores,
        isLoading: false,
        hasMore: false, // Pour l'instant, pas de pagination côté API
      );
    } catch (e) {
      AppLogger.error('Erreur chargement magasins: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Rafraîchit la liste des magasins
  Future<void> refresh() async {
    await loadStores();
  }

  /// Recherche des magasins
  Future<void> searchStores(String query) async {
    if (query.isEmpty) {
      await loadStores();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final stores = await _repository.searchStores(query);
      state = state.copyWith(stores: stores, isLoading: false);
    } catch (e) {
      AppLogger.error('Erreur recherche magasins: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Filtre par catégorie
  Future<void> filterByCategory(String categoryId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final stores = await _repository.getStoresByCategory(categoryId);
      state = state.copyWith(stores: stores, isLoading: false);
    } catch (e) {
      AppLogger.error('Erreur filtrage magasins: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider principal pour les magasins
final storesStateProvider =
    StateNotifierProvider<StoresStateNotifier, StoresState>((ref) {
      return StoresStateNotifier(ref.read(storesRepositoryProvider));
    });

// ============================================================
// COMPUTED PROVIDERS
// ============================================================

/// Tous les magasins
final allStoresProvider = Provider<List<StoreEntity>>((ref) {
  return ref.watch(storesStateProvider).stores;
});

/// Magasins chargés avec AsyncValue
final storesAsyncProvider = Provider<AsyncValue<List<StoreEntity>>>((ref) {
  final state = ref.watch(storesStateProvider);

  if (state.isLoading && state.stores.isEmpty) {
    return const AsyncValue.loading();
  }

  if (state.error != null && state.stores.isEmpty) {
    return AsyncValue.error(state.error!, StackTrace.current);
  }

  return AsyncValue.data(state.stores);
});

/// Un magasin par ID
final storeByIdProvider = Provider.family<StoreEntity?, String>((ref, id) {
  final stores = ref.watch(allStoresProvider);
  try {
    return stores.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});

/// Magasins par catégorie
final storesByCategoryProvider = Provider.family<List<StoreEntity>, String>((
  ref,
  categoryId,
) {
  final stores = ref.watch(allStoresProvider);
  return stores.where((s) => s.categoryId == categoryId).toList();
});

/// Provider pour obtenir l'URL complète du logo d'un magasin
/// Si l'URL est déjà complète (http/https), la retourne telle quelle.
/// Sinon, retourne une chaîne vide.
final storeLogoUrlProvider = Provider.family<String, String>((ref, fileName) {
  if (fileName.isEmpty) return '';

  // Si c'est déjà une URL complète, la retourner
  if (fileName.startsWith('http://') || fileName.startsWith('https://')) {
    return fileName;
  }

  // Sinon, c'est probablement une URL invalide
  return '';
});

// ============================================================
// VIEWPORT & DISTANCE PROVIDERS
// ============================================================

/// Paramètres pour le chargement par viewport
class ViewportBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const ViewportBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ViewportBounds &&
        other.minLat == minLat &&
        other.maxLat == maxLat &&
        other.minLng == minLng &&
        other.maxLng == maxLng;
  }

  @override
  int get hashCode => Object.hash(minLat, maxLat, minLng, maxLng);
}

/// Provider pour les magasins dans le viewport visible
final storesInBoundsProvider = FutureProvider.family<List<StoreEntity>, ViewportBounds>((ref, bounds) async {
  final repository = ref.read(storesRepositoryProvider);
  return repository.getStoresInBounds(
    minLat: bounds.minLat,
    maxLat: bounds.maxLat,
    minLng: bounds.minLng,
    maxLng: bounds.maxLng,
  );
});

/// Paramètres pour la position utilisateur
class UserPosition {
  final double latitude;
  final double longitude;

  const UserPosition({required this.latitude, required this.longitude});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPosition &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Provider pour les magasins triés par distance (du plus proche au plus loin)
final nearbyStoresSortedProvider = FutureProvider.family<List<StoreEntity>, UserPosition>((ref, position) async {
  final repository = ref.read(storesRepositoryProvider);
  return repository.getNearbyStoresSorted(
    userLat: position.latitude,
    userLng: position.longitude,
    limit: 50,
  );
});

/// Provider pour la position actuelle de l'utilisateur (à setter depuis la carte)
final currentUserPositionProvider = StateProvider<UserPosition?>((ref) => null);

/// Provider qui combine : magasins triés par distance si position disponible
final storesSortedByDistanceProvider = Provider<AsyncValue<List<StoreEntity>>>((ref) {
  final position = ref.watch(currentUserPositionProvider);
  
  if (position == null) {
    // Pas de position, retourner les magasins normaux
    return ref.watch(storesAsyncProvider);
  }
  
  // Retourner les magasins triés par distance
  return ref.watch(nearbyStoresSortedProvider(position));
});

/// @deprecated Utiliser storesStateProvider à la place
final storeServiceProvider = Provider((ref) {
  AppLogger.warning(
    'storeServiceProvider est deprecated, utiliser storesStateProvider',
  );
  return ref.read(storesRepositoryProvider);
});

/// @deprecated Utiliser storesAsyncProvider à la place
final storesListProvider = Provider((ref) {
  AppLogger.warning(
    'storesListProvider est deprecated, utiliser storesAsyncProvider',
  );
  return ref.watch(storesAsyncProvider);
});
