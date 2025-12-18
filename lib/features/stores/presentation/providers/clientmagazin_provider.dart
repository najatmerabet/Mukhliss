import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/features/stores/data/models/clientmagazin.dart';
import 'package:mukhliss/features/stores/data/services/client_store_service.dart';
import 'package:tuple/tuple.dart';

final clientMagazinServiceProvider = Provider<ClientStoreService>((ref) {
  return ClientStoreService();
});

final clientMagazinPointsProvider = FutureProvider.autoDispose.family<
  ClientMagazin?,
  Tuple2<String?, String?>
>((ref, ids) async {
  final service = ref.read(clientMagazinServiceProvider);
  if (ids.item1 == null || ids.item2 == null) {
    return Future.value(null);
  }

  // Use new service and convert to legacy ClientMagazin for backward compatibility
  final result = await service.getClientStorePoints(ids.item1!, ids.item2!);

  if (result == null) return null;

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
