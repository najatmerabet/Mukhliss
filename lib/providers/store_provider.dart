import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/services/store_service.dart';

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService();
});

// Provider pour le logo (inchangé)
final storeLogoUrlProvider = Provider.family<String, String>((ref, fileName) {
  final storeService = ref.read(storeServiceProvider);
  return storeService.getStoreLogoUrl(fileName);
});

// Nouveau provider avec pagination
final storesListProvider = StateNotifierProvider<StoresNotifier, AsyncValue<List<Store>>>((ref) {
  final service = ref.watch(storeServiceProvider);
  return StoresNotifier(service);
});

class StoresNotifier extends StateNotifier<AsyncValue<List<Store>>> {
  StoresNotifier(this._service) : super(const AsyncValue.loading()) {
    loadInitialStores();
  }

  final StoreService _service;
  int _currentOffset = 0;
  static const int _batchSize = 5; // Charger 20 magasins à la fois
  bool _isLoadingMore = false;
  bool _hasMore = true;

  // Charger les premiers magasins
  Future<void> loadInitialStores() async {
    state = const AsyncValue.loading();
    
    try {
      final stores = await _service.getStoresWithLogos(
        limit: _batchSize,
        offset: 0,
      );
      
      _currentOffset = _batchSize;
      _hasMore = stores.length == _batchSize;
      
      state = AsyncValue.data(stores);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Charger plus de magasins (appelé lors du scroll)
  Future<void> loadMoreStores() async {
    if (_isLoadingMore || !_hasMore || state.isLoading) return;

    _isLoadingMore = true;
    
    try {
      final currentStores = state.value ?? [];
      
      final newStores = await _service.getStoresWithLogos(
        limit: _batchSize,
        offset: _currentOffset,
      );

      if (newStores.isEmpty) {
        _hasMore = false;
      } else {
        _currentOffset += _batchSize;
        state = AsyncValue.data([...currentStores, ...newStores]);
      }
    } catch (e, stack) {
      print('Erreur loadMore: $e');
      // Garder l'état actuel en cas d'erreur
    } finally {
      _isLoadingMore = false;
    }
  }

  // Recharger tout depuis le début
  Future<void> refresh() async {
    _currentOffset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    await loadInitialStores();
  }

  // Getters utiles
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
}