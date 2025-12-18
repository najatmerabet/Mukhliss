/// ============================================================
/// Offers Repository Interface - Domain Layer
/// ============================================================
///
/// Contrat abstrait pour les opérations sur les offres.
library;

import '../entities/offer_entity.dart';
import '../entities/claimed_offer_entity.dart';

/// Interface du repository des offres
abstract class OffersRepository {
  /// Récupère toutes les offres actives
  Future<List<OfferEntity>> getOffers();

  /// Récupère les offres d'un magasin
  Future<List<OfferEntity>> getOffersByStore(String storeId);

  /// Récupère une offre par son ID
  Future<OfferEntity?> getOfferById(String id);

  /// Récupère les offres réclamées par un client
  Future<List<ClaimedOfferEntity>> getClaimedOffers(String clientId);

  /// Réclame une offre pour un client
  Future<void> claimOffer({required String clientId, required String rewardId});
}
