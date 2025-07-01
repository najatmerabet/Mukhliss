


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/services/store_service.dart';

final storeServiceProvider= Provider<StoreService>((ref) {
  return StoreService();
});


final storesListProvider = FutureProvider<List<Store>>((ref) async {
  final storeService = ref.read(storeServiceProvider);
  return await storeService.getStoresWithLogos();
});

final storeLogoUrlProvider = Provider.family<String, String>((ref, fileName) {
  final storeService = ref.read(storeServiceProvider);
  return storeService.getStoreLogoUrl(fileName);
});