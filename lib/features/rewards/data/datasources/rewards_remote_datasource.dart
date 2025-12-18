/// ============================================================
/// Rewards Remote DataSource - Data Layer
/// ============================================================
library;

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mukhliss/core/logger/app_logger.dart';
import '../models/reward_model.dart';

/// Exception pour les problèmes de connectivité
class ConnectivityException implements Exception {
  final String message;

  ConnectivityException(this.message);

  @override
  String toString() => message;
}

/// Interface pour la source de données distante
abstract class RewardsRemoteDataSource {
  Future<List<RewardModel>> getRewards();
  Future<List<RewardModel>> getRewardsByStore(String storeId);
  Future<List<RewardModel>> getRecentRewards();
  Future<RewardModel?> getRewardById(String id);
}

/// Implémentation Supabase
class RewardsRemoteDataSourceImpl implements RewardsRemoteDataSource {
  final SupabaseClient _client;

  RewardsRemoteDataSourceImpl({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Vérifie la connectivité
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      AppLogger.warning('Erreur vérification connectivité', error: e);
      return false;
    }
  }

  /// Vérifie la connectivité et lance une exception si pas de connexion
  Future<void> _checkConnectivity() async {
    if (!await _hasInternetConnection()) {
      throw ConnectivityException(
        'Pas de connexion Internet. Veuillez vérifier votre connexion.',
      );
    }
  }

  @override
  Future<List<RewardModel>> getRewards() async {
    await _checkConnectivity();

    try {
      final response = await _client
          .from('rewards')
          .select('*, magasins:magasin_id(*)')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 15));

      return (response as List)
          .map((json) => RewardModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Erreur getRewards', tag: 'RewardsDataSource', error: e);
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<RewardModel>> getRewardsByStore(String storeId) async {
    if (storeId.isEmpty) return [];

    await _checkConnectivity();

    try {
      AppLogger.debug(
        'Fetching rewards for store: $storeId',
        tag: 'RewardsDataSource',
      );

      final response = await _client
          .from('rewards')
          .select('*, magasins:magasin_id(*)')
          .eq('magasin_id', storeId)
          .timeout(const Duration(seconds: 10));

      final rewards =
          (response as List).map((json) => RewardModel.fromJson(json)).toList();

      AppLogger.debug(
        'Fetched ${rewards.length} rewards',
        tag: 'RewardsDataSource',
      );
      return rewards;
    } catch (e) {
      AppLogger.error(
        'Erreur getRewardsByStore',
        tag: 'RewardsDataSource',
        error: e,
      );
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<List<RewardModel>> getRecentRewards() async {
    await _checkConnectivity();

    try {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      final response = await _client
          .from('rewards')
          .select('*, magasins:magasin_id(*)')
          .gte('created_at', oneWeekAgo.toIso8601String())
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 15));

      return (response as List)
          .map((json) => RewardModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error(
        'Erreur getRecentRewards',
        tag: 'RewardsDataSource',
        error: e,
      );
      _handleError(e);
      rethrow;
    }
  }

  @override
  Future<RewardModel?> getRewardById(String id) async {
    await _checkConnectivity();

    try {
      final response =
          await _client
              .from('rewards')
              .select('*, magasins:magasin_id(*)')
              .eq('id', id)
              .maybeSingle();

      if (response == null) return null;
      return RewardModel.fromJson(response);
    } catch (e) {
      AppLogger.error(
        'Erreur getRewardById',
        tag: 'RewardsDataSource',
        error: e,
      );
      rethrow;
    }
  }

  /// Gère les erreurs réseau
  void _handleError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('SocketException') ||
        errorStr.contains('TimeoutException') ||
        errorStr.contains('network')) {
      throw ConnectivityException('Problème de connexion réseau.');
    }
  }
}
