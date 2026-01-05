import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/core/providers/auth_provider.dart';
import 'package:mukhliss/features/stores/data/models/clientmagazin.dart';
import 'package:mukhliss/features/stores/data/services/client_store_service.dart';
import 'package:tuple/tuple.dart';

final clientMagazinServiceProvider = Provider<ClientStoreService>((ref) {
  return ClientStoreService();
});

/// Provider pour forcer le rafraîchissement du cache des points
/// Incrémentez ce compteur pour forcer TOUS les providers de points à se recharger
/// Utilisé lors de la déconnexion pour nettoyer le cache
final clientPointsCacheRefreshProvider = StateProvider<int>((ref) => 0);

/// Méthode utilitaire pour effacer le cache des points
/// Appeler lors de la déconnexion
void clearClientPointsCache(WidgetRef ref) {
  debugPrint('🧹 [Cache] Clearing client points cache');
  ref.read(clientPointsCacheRefreshProvider.notifier).state++;
}

/// Même méthode mais pour les providers (Ref au lieu de WidgetRef)
void clearClientPointsCacheFromRef(Ref ref) {
  debugPrint('🧹 [Cache] Clearing client points cache from Ref');
  ref.read(clientPointsCacheRefreshProvider.notifier).state++;
}

/// Provider pour les points client-magasin
/// 
/// Ce provider DÉPEND de:
/// 1. L'utilisateur connecté via `currentUserProvider` (SYNCHRONE)
/// 2. Le compteur de rafraîchissement `clientPointsCacheRefreshProvider`
/// 
/// ⚠️ IMPORTANT: On utilise currentUserProvider (synchrone) et NON authStateProvider (Stream)
/// pour éviter les race conditions lors du changement de compte.
/// 
/// Cela garantit que le cache est automatiquement invalidé lorsque:
/// - L'utilisateur se déconnecte
/// - L'utilisateur se connecte avec un autre compte
/// - `clearClientPointsCache()` est appelé
final clientMagazinPointsProvider = FutureProvider.autoDispose.family<
  ClientMagazin?,
  Tuple2<String?, String?>
>((ref, ids) async {
  // ⚠️ IMPORTANT: Dépendance sur le compteur de rafraîchissement
  // Quand ce compteur change (lors de déconnexion), le cache est invalidé
  final refreshCounter = ref.watch(clientPointsCacheRefreshProvider);
  debugPrint('🔄 [Points] Cache refresh counter: $refreshCounter');
  
  // ⚠️ IMPORTANT: Dépendance SYNCHRONE sur l'utilisateur courant
  // On utilise currentUserProvider au lieu de authStateProvider pour éviter les race conditions
  final currentUser = ref.watch(currentUserProvider);
  
  // Si pas d'utilisateur connecté, retourner null immédiatement
  if (currentUser == null) {
    debugPrint('🔐 [Points] No authenticated user - returning null');
    return null;
  }
  
  // Vérifier que le clientId demandé correspond à l'utilisateur connecté
  // Cela empêche l'affichage des données d'un autre utilisateur
  if (ids.item1 == null || ids.item1 != currentUser.id) {
    debugPrint('⚠️ [Points] Client ID mismatch or null: requested=${ids.item1}, current=${currentUser.id}');
    return null;
  }
  
  if (ids.item2 == null) {
    debugPrint('⚠️ [Points] Store ID is null');
    return null;
  }

  debugPrint('📊 [Points] Fetching points for client=${ids.item1}, store=${ids.item2}');
  
  final service = ref.read(clientMagazinServiceProvider);
  
  // Use new service and convert to legacy ClientMagazin for backward compatibility
  final result = await service.getClientStorePoints(ids.item1!, ids.item2!);

  if (result == null) {
    debugPrint('📊 [Points] No points found for this client/store');
    return null;
  }

  debugPrint('📊 [Points] Found ${result.cumulPoints} points for ${currentUser.email}');
  
  // Convert ClientStoreModel to ClientMagazin
  return ClientMagazin(
    id: result.id,
    client_id: result.clientId,
    magasin_id: result.storeId,
    createdAt: result.createdAt,
    cumulpoint: result.cumulPoints,
    solde: result.balance,
  );
});
