/// ============================================================
/// Offers Use Cases - Domain Layer
/// ============================================================
///
/// Cas d'utilisation pour les offres.
/// Chaque UseCase = Une action métier spécifique.
library;

import '../entities/offer_entity.dart';
import '../entities/claimed_offer_entity.dart';
import '../repositories/offers_repository.dart';

/// Use case: Récupérer toutes les offres
class GetOffersUseCase {
  final OffersRepository _repository;

  GetOffersUseCase(this._repository);

  Future<List<OfferEntity>> call() async {
    return await _repository.getOffers();
  }
}

/// Use case: Récupérer les offres d'un magasin
class GetOffersByStoreUseCase {
  final OffersRepository _repository;

  GetOffersByStoreUseCase(this._repository);

  Future<List<OfferEntity>> call(String storeId) async {
    return await _repository.getOffersByStore(storeId);
  }
}

/// Use case: Récupérer les offres réclamées par un client
class GetClaimedOffersUseCase {
  final OffersRepository _repository;

  GetClaimedOffersUseCase(this._repository);

  Future<List<ClaimedOfferEntity>> call(String clientId) async {
    return await _repository.getClaimedOffers(clientId);
  }
}

/// Use case: Réclamer une offre
class ClaimOfferUseCase {
  final OffersRepository _repository;

  ClaimOfferUseCase(this._repository);

  Future<void> call({
    required String clientId,
    required String rewardId,
  }) async {
    await _repository.claimOffer(clientId: clientId, rewardId: rewardId);
  }
}
