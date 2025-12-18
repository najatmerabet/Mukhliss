/// ============================================================
/// Rewards Repository Interface - Domain Layer
/// ============================================================
library;

import '../entities/reward_entity.dart';

/// Interface du repository des récompenses
abstract class RewardsRepository {
  /// Récupère toutes les récompenses actives
  Future<List<RewardEntity>> getRewards();

  /// Récupère les récompenses d'un magasin
  Future<List<RewardEntity>> getRewardsByStore(String storeId);

  /// Récupère les récompenses récentes (< 7 jours)
  Future<List<RewardEntity>> getRecentRewards();

  /// Récupère une récompense par son ID
  Future<RewardEntity?> getRewardById(String id);

  /// Échange une récompense contre des points
  Future<void> redeemReward({
    required String clientId,
    required String rewardId,
    required int pointsCost,
  });
}
