/// ============================================================
/// Client Offers Providers - Presentation Layer
/// ============================================================
///
/// Providers Riverpod pour les offres réclamées par les clients.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/client_offer_service.dart';

// ============================================================
// SERVICE PROVIDERS
// ============================================================

/// Provider pour le service des offres client
final clientOfferServiceProvider = Provider<ClientOfferService>((ref) {
  return ClientOfferService();
});

// ============================================================
// STATE PROVIDERS
// ============================================================

/// Provider pour récupérer les offres réclamées par un client
final clientOffersProvider = FutureProvider.family<List<ClaimedOffer>, String>((
  ref,
  clientId,
) async {
  if (clientId.isEmpty) return [];

  final service = ref.read(clientOfferServiceProvider);
  return await service.getClientOffers(clientId);
});

// ============================================================
// LEGACY COMPATIBILITY
// ============================================================

/// @deprecated Utiliser clientOfferServiceProvider
final clientoffreprovider = clientOfferServiceProvider;

/// @deprecated Utiliser clientOffersProvider
final clientOffresProvider = clientOffersProvider;
