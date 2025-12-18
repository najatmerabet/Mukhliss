/// ============================================================
/// Rewards Repository Implementation - Data Layer
/// ============================================================
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mukhliss/core/logger/app_logger.dart';

import '../../domain/entities/reward_entity.dart';
import '../../domain/repositories/rewards_repository.dart';
import '../datasources/rewards_remote_datasource.dart';

class RewardsRepositoryImpl implements RewardsRepository {
  final RewardsRemoteDataSource _remoteDataSource;
  final SupabaseClient _client;

  RewardsRepositoryImpl({
    RewardsRemoteDataSource? remoteDataSource,
    SupabaseClient? client,
  }) : _remoteDataSource = remoteDataSource ?? RewardsRemoteDataSourceImpl(),
       _client = client ?? Supabase.instance.client;

  @override
  Future<List<RewardEntity>> getRewards() async {
    final models = await _remoteDataSource.getRewards();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<RewardEntity>> getRewardsByStore(String storeId) async {
    final models = await _remoteDataSource.getRewardsByStore(storeId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<RewardEntity>> getRecentRewards() async {
    final models = await _remoteDataSource.getRecentRewards();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<RewardEntity?> getRewardById(String id) async {
    final model = await _remoteDataSource.getRewardById(id);
    return model?.toEntity();
  }

  @override
  Future<void> redeemReward({
    required String clientId,
    required String rewardId,
    required int pointsCost,
  }) async {
    try {
      // 1. Vérifier les points du client
      final clientResponse =
          await _client
              .from('clients')
              .select('points_total')
              .eq('id', clientId)
              .single();

      final currentPoints = clientResponse['points_total'] as int? ?? 0;

      if (currentPoints < pointsCost) {
        throw Exception('Points insuffisants');
      }

      // 2. Déduire les points
      await _client
          .from('clients')
          .update({'points_total': currentPoints - pointsCost})
          .eq('id', clientId);

      // 3. Enregistrer l'échange
      await _client.from('client_rewards').insert({
        'client_id': clientId,
        'reward_id': rewardId,
        'redeemed_at': DateTime.now().toIso8601String(),
        'points_spent': pointsCost,
      });

      AppLogger.info(
        'Reward redeemed: $rewardId by $clientId (-$pointsCost pts)',
        tag: 'RewardsRepo',
      );
    } catch (e) {
      AppLogger.error('Erreur redeemReward', tag: 'RewardsRepo', error: e);
      rethrow;
    }
  }
}
