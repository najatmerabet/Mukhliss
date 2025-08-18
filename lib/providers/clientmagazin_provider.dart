import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/models/clientmagazin.dart';
import 'package:mukhliss/services/clientmagazin_service.dart';
import 'package:tuple/tuple.dart';

final clientMagazinServiceProvider = Provider<ClientMagazinService>((ref) {
  return ClientMagazinService();
});

final clientMagazinPointsProvider = FutureProvider.family<ClientMagazin?, Tuple2<String?, String?>>((ref, ids) {
  final service = ref.read(clientMagazinServiceProvider);
  if (ids.item1 == null || ids.item2 == null) {
    return Future.value(null);
  }
  return service.getClientMagazinPoints(ids.item1!, ids.item2!);
});