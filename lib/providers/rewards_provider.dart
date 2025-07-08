



import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/models/rewards.dart';
import 'package:mukhliss/services/rewards_service.dart';

final RewardsProvider = Provider<RewardsService>((ref) {
  return RewardsService();
});


// Provider pour récupérer les récompenses d'un magasin spécifique
final rewardsByMagasinProvider = FutureProvider.family<List<Rewards>, String>((ref, magasinId) {
  final rewardsService = ref.watch(RewardsProvider);
  return rewardsService.getRewardsByMagasin(magasinId);
});

// Provider pour récupérer les récompenses récentes
final recentRewardsProvider = FutureProvider<List<Rewards>>((ref) {
  final rewardsService = ref.watch(RewardsProvider);
  return rewardsService.getRecentRewards();
});