


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/services/clientmagazin_service.dart';

final clientMagazinServiceProvider = Provider<ClientMagazinService>((ref) {
  return ClientMagazinService();
});