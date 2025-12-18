/// ============================================================
/// Client-Store Service - Data Layer
/// ============================================================
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mukhliss/core/logger/app_logger.dart';
import 'package:mukhliss/features/profile/domain/entities/client_store_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing client-store relationships
/// Handles loyalty points and balances
class ClientStoreService {
  final SupabaseClient _client;

  ClientStoreService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Check internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      AppLogger.debug('Connectivity check error: $e');
      return false;
    }
  }

  /// Get client-store relationship with points and balance
  Future<ClientStoreModel?> getClientStorePoints(
    String clientId,
    String storeId,
  ) async {
    try {
      // Check internet connection first
      if (!await _hasInternetConnection()) {
        throw Exception('no_internet_connection');
      }

      AppLogger.debug('Fetching points for client:$clientId, store:$storeId');

      final response =
          await _client
              .from('clientmagasin')
              .select()
              .eq('client_id', clientId)
              .eq('magasin_id', storeId)
              .maybeSingle();

      if (response == null) {
        AppLogger.debug('No client-store relationship found');
        return null;
      }

      AppLogger.debug('ClientStoreService response: $response');
      return ClientStoreModel.fromJson(response);
    } catch (error) {
      AppLogger.error('ClientStoreService error: $error');
      rethrow;
    }
  }

  /// Get all stores for a client
  Future<List<ClientStoreModel>> getClientStores(String clientId) async {
    try {
      if (!await _hasInternetConnection()) {
        throw Exception('no_internet_connection');
      }

      AppLogger.debug('Fetching all stores for client: $clientId');

      final response = await _client
          .from('clientmagasin')
          .select()
          .eq('client_id', clientId);

      return (response as List)
          .map((json) => ClientStoreModel.fromJson(json))
          .toList();
    } catch (error) {
      AppLogger.error('getClientStores error: $error');
      rethrow;
    }
  }

  /// Update client points for a store
  Future<ClientStoreModel?> updateClientPoints({
    required String clientId,
    required String storeId,
    required int points,
  }) async {
    try {
      if (!await _hasInternetConnection()) {
        throw Exception('no_internet_connection');
      }

      AppLogger.debug(
        'Updating points for client:$clientId, store:$storeId, points:$points',
      );

      final response =
          await _client
              .from('clientmagasin')
              .update({'cumulpoint': points})
              .eq('client_id', clientId)
              .eq('magasin_id', storeId)
              .select()
              .maybeSingle();

      if (response == null) return null;

      return ClientStoreModel.fromJson(response);
    } catch (error) {
      AppLogger.error('updateClientPoints error: $error');
      rethrow;
    }
  }
}
