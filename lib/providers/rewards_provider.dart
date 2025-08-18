import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/models/rewards.dart';
import 'package:mukhliss/services/rewards_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// Provider pour le service rewards
final rewardsServiceProvider = Provider<RewardsService>((ref) => RewardsService());

// Provider pour les rewards récents avec gestion d'erreur améliorée
final recentRewardsProvider = FutureProvider<List<Rewards>>((ref) async {
  final rewardsService = ref.read(rewardsServiceProvider);
  
  try {
    return await rewardsService.getRecentRewards();
  } catch (e) {
    // Log l'erreur pour le debugging
    print('Provider Error - Recent Rewards: $e');
    
    // Si c'est une exception de connectivité, on la propage
    if (e is ConnectivityException) {
      throw e;
    }
    
    // Pour les autres erreurs, on lance une erreur généralisée
    throw Exception('Erreur lors du chargement des offres: ${e.toString()}');
  }
});

// Provider pour les rewards d'un magasin spécifique
final rewardsByMagasinProvider = FutureProvider.family<List<Rewards>, String>((ref, magasinId) async {
  final rewardsService = ref.read(rewardsServiceProvider);
  
  try {
    return await rewardsService.getRewardsByMagasin(magasinId);
  } catch (e) {
    // Log l'erreur pour le debugging
    print('Provider Error - Rewards by Magasin ($magasinId): $e');
    
    // Si c'est une exception de connectivité, on la propage
    if (e is ConnectivityException) {
      throw e;
    }
    
    // Pour les autres erreurs, on lance une erreur généralisée
    throw Exception('Erreur lors du chargement des offres du magasin: ${e.toString()}');
  }
});

// Provider pour vérifier l'état de la connectivité
final connectivityProvider = StreamProvider<bool>((ref) async* {
  yield* Stream.periodic(Duration(seconds: 5), (_) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }).asyncMap((future) => future);
});

