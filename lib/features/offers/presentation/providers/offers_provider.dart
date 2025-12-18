/// ============================================================
/// Offers Provider - DEPRECATED
/// ============================================================
///
/// @deprecated Ce fichier est obsolète. Utiliser le nouveau système:
/// ```dart
/// import 'package:mukhliss/features/offers/offers.dart';
/// ```
///
/// Mapping des anciens providers vers les nouveaux:
/// - offersListProvider → allOffersProvider
/// - offersByStoreProvider → offersByStoreProvider (même nom)
/// - shopOffersProvider → offersByStoreProvider
library;

// Réexporter les nouveaux providers pour compatibilité
export 'package:mukhliss/features/offers/offers.dart';

// L'ancien code est conservé ci-dessous pour référence
// mais ne devrait plus être utilisé.

/*
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/features/offers/data/models/offers.dart';
import 'package:mukhliss/services/offres_service.dart';

final offersProvider = Provider<OffresService>((ref) {
  return OffresService();
});

final offersListProvider = FutureProvider<List<Offers>>((ref) async {
  final offersService = ref.read(offersProvider);
  return await offersService.getOffres();
});
*/
