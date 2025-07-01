import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/models/offers.dart';
import 'package:mukhliss/services/offres_service.dart';

final offersProvider = Provider<OffresService>((ref) {
  return OffresService();
});

final offersListProvider = FutureProvider<List<Offers>>((ref) async {
  final offersService = ref.read(offersProvider);
  return await offersService.getOffres();
});

final offersByStoreProvider = FutureProvider.family<List<Offers>, String>((ref, storeId) async {
  debugPrint('offersByStoreProvider called with storeId: $storeId');
  

  
  final offersService = ref.read(offersProvider);
  try {
    final offers = await offersService.getOffresByMagasin(storeId);
    debugPrint('Fetched ${offers.length} offers for store: $storeId');
    return offers;
  } catch (e, stack) {
    debugPrint('Error fetching offers: $e\n$stack');
    throw e;
  }
});

// Simplified provider - just use the FutureProvider directly
final shopOffersProvider = StateNotifierProvider.autoDispose.family<ShopOffersNotifier, AsyncValue<List<Offers>>, String>((ref, shopId) {
  return ShopOffersNotifier(ref, shopId);
});

class ShopOffersNotifier extends StateNotifier<AsyncValue<List<Offers>>> {
  final Ref ref;
  final String shopId;

  ShopOffersNotifier(this.ref, this.shopId) : super(const AsyncValue.loading()) {
    _loadOffers(); // appel immédiat
  }

  Future<void> _loadOffers() async {
    if (shopId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      print('Loading offers for shop: $shopId');
      final offersService = ref.read(offersProvider);
      final offers = await offersService.getOffresByMagasin(shopId);
      print('Loaded ${offers.length} offers');
      state = AsyncValue.data(offers);
    } catch (error, stackTrace) {
      print('Error loading offers: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadOffers();
  }
}
