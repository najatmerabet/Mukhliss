/// ============================================================
/// Rewards Use Cases - Domain Layer
/// ============================================================
library;

import '../entities/reward_entity.dart';
import '../repositories/rewards_repository.dart';

/// Use case: Récupérer toutes les récompenses
class GetRewardsUseCase {
  final RewardsRepository _repository;

  GetRewardsUseCase(this._repository);

  Future<List<RewardEntity>> call() async {
    return await _repository.getRewards();
  }
}

/// Use case: Récupérer les récompenses d'un magasin
class GetRewardsByStoreUseCase {
  final RewardsRepository _repository;

  GetRewardsByStoreUseCase(this._repository);

  Future<List<RewardEntity>> call(String storeId) async {
    if (storeId.isEmpty) return [];
    return await _repository.getRewardsByStore(storeId);
  }
}

/// Use case: Récupérer les récompenses récentes
class GetRecentRewardsUseCase {
  final RewardsRepository _repository;

  GetRecentRewardsUseCase(this._repository);

  Future<List<RewardEntity>> call() async {
    return await _repository.getRecentRewards();
  }
}

/// Use case: Échanger une récompense
class RedeemRewardUseCase {
  final RewardsRepository _repository;

  RedeemRewardUseCase(this._repository);

  Future<void> call({
    required String clientId,
    required String rewardId,
    required int pointsCost,
  }) async {
    await _repository.redeemReward(
      clientId: clientId,
      rewardId: rewardId,
      pointsCost: pointsCost,
    );
  }
}
