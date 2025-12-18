/// ============================================================
/// Rewards Providers - Presentation Layer
/// ============================================================
///
/// Providers Riverpod pour la gestion des récompenses.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/rewards_remote_datasource.dart';
import '../../data/repositories/rewards_repository_impl.dart';
import '../../domain/entities/reward_entity.dart';
import '../../domain/repositories/rewards_repository.dart';

// ============================================================
// DATASOURCE PROVIDERS
// ============================================================

/// Provider pour la source de données distante des rewards
final rewardsRemoteDataSourceProvider = Provider<RewardsRemoteDataSource>((
  ref,
) {
  return RewardsRemoteDataSourceImpl();
});

// ============================================================
// REPOSITORY PROVIDERS
// ============================================================

/// Provider pour le repository des rewards
final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  return RewardsRepositoryImpl(
    remoteDataSource: ref.read(rewardsRemoteDataSourceProvider),
  );
});

// ============================================================
// STATE PROVIDERS
// ============================================================

/// Provider pour les rewards par magasin
final rewardsByMagasinProvider =
    FutureProvider.family<List<RewardEntity>, String>((ref, magasinId) async {
      if (magasinId.isEmpty) return [];

      final repository = ref.read(rewardsRepositoryProvider);
      return await repository.getRewardsByStore(magasinId);
    });

/// Provider pour les rewards récentes
final recentRewardsProvider = FutureProvider<List<RewardEntity>>((ref) async {
  final repository = ref.read(rewardsRepositoryProvider);
  return await repository.getRecentRewards();
});

/// Provider pour toutes les rewards
final allRewardsProvider = FutureProvider<List<RewardEntity>>((ref) async {
  final repository = ref.read(rewardsRepositoryProvider);
  return await repository.getRewards();
});

// ============================================================
// LEGACY COMPATIBILITY
// ============================================================

/// @deprecated Utiliser rewardsRepositoryProvider
final rewardsProvider = rewardsRepositoryProvider;
