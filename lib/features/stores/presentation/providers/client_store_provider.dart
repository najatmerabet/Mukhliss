/// ============================================================
/// Client-Store Provider - Presentation Layer
/// ============================================================
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/features/profile/domain/entities/client_store_entity.dart';
import 'package:mukhliss/features/stores/data/services/client_store_service.dart';
import 'package:tuple/tuple.dart';

// ============================================================
// Service Provider
// ============================================================

final clientStoreServiceProvider = Provider<ClientStoreService>((ref) {
  return ClientStoreService();
});

// ============================================================
// Providers
// ============================================================

/// Provider for getting client-store relationship (points and balance)
/// Takes Tuple2(clientId, storeId) as parameter
final clientStorePointsProvider =
    FutureProvider.family<ClientStoreEntity?, Tuple2<String, String>>((
      ref,
      params,
    ) async {
      final service = ref.read(clientStoreServiceProvider);
      final clientId = params.item1;
      final storeId = params.item2;

      final model = await service.getClientStorePoints(clientId, storeId);
      return model?.toEntity();
    });

/// Provider for getting all stores for a client
final clientStoresProvider =
    FutureProvider.family<List<ClientStoreEntity>, String>((
      ref,
      clientId,
    ) async {
      final service = ref.read(clientStoreServiceProvider);
      final models = await service.getClientStores(clientId);
      return models.map((model) => model.toEntity()).toList();
    });

/// State notifier for managing client-store operations
class ClientStoreNotifier
    extends StateNotifier<AsyncValue<ClientStoreEntity?>> {
  final ClientStoreService _service;

  ClientStoreNotifier(this._service) : super(const AsyncValue.loading());

  /// Fetch client-store relationship
  Future<void> fetchClientStorePoints(String clientId, String storeId) async {
    state = const AsyncValue.loading();

    try {
      final model = await _service.getClientStorePoints(clientId, storeId);
      state = AsyncValue.data(model?.toEntity());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update client points
  Future<void> updatePoints({
    required String clientId,
    required String storeId,
    required int points,
  }) async {
    try {
      final model = await _service.updateClientPoints(
        clientId: clientId,
        storeId: storeId,
        points: points,
      );
      state = AsyncValue.data(model?.toEntity());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh current state
  Future<void> refresh(String clientId, String storeId) async {
    await fetchClientStorePoints(clientId, storeId);
  }
}

/// Provider for ClientStoreNotifier
final clientStoreNotifierProvider = StateNotifierProvider.family<
  ClientStoreNotifier,
  AsyncValue<ClientStoreEntity?>,
  Tuple2<String, String>
>((ref, params) {
  final service = ref.read(clientStoreServiceProvider);
  final notifier = ClientStoreNotifier(service);

  // Auto-fetch on initialization
  notifier.fetchClientStorePoints(params.item1, params.item2);

  return notifier;
});
