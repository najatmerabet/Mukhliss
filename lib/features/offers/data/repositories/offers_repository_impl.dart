/// ============================================================
/// Offers Repository Implementation - Data Layer
/// ============================================================
///
/// Implémentation concrète du repository des offres.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mukhliss/core/logger/app_logger.dart';

import '../../domain/entities/offer_entity.dart';
import '../../domain/entities/claimed_offer_entity.dart';
import '../../domain/repositories/offers_repository.dart';
import '../datasources/offers_remote_datasource.dart';

class OffersRepositoryImpl implements OffersRepository {
  final OffersRemoteDataSource _remoteDataSource;
  final SupabaseClient _client;

  OffersRepositoryImpl({
    OffersRemoteDataSource? remoteDataSource,
    SupabaseClient? client,
  }) : _remoteDataSource = remoteDataSource ?? OffersRemoteDataSourceImpl(),
       _client = client ?? Supabase.instance.client;

  @override
  Future<List<OfferEntity>> getOffers() async {
    final models = await _remoteDataSource.getOffers();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<OfferEntity>> getOffersByStore(String storeId) async {
    final models = await _remoteDataSource.getOffersByStore(storeId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<OfferEntity?> getOfferById(String id) async {
    final model = await _remoteDataSource.getOfferById(id);
    return model?.toEntity();
  }

  @override
  Future<List<ClaimedOfferEntity>> getClaimedOffers(String clientId) async {
    try {
      final response = await _client
          .from('client_offers')
          .select('*, rewards(*)')
          .eq('client_id', clientId)
          .order('claimed_at', ascending: false);

      return (response as List).map((json) {
        final reward = json['rewards'] as Map<String, dynamic>?;
        return ClaimedOfferEntity(
          clientId: json['client_id'] as String,
          rewardId: json['reward_id'] as String? ?? '',
          rewardTitle: reward?['titre'] as String? ?? '',
          rewardDescription: reward?['description'] as String?,
          claimedAt:
              DateTime.tryParse(json['claimed_at'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Erreur getClaimedOffers', tag: 'OffersRepo', error: e);
      rethrow;
    }
  }

  @override
  Future<void> claimOffer({
    required String clientId,
    required String rewardId,
  }) async {
    try {
      await _client.from('client_offers').insert({
        'client_id': clientId,
        'reward_id': rewardId,
        'claimed_at': DateTime.now().toIso8601String(),
      });
      AppLogger.info(
        'Offer claimed: $rewardId by $clientId',
        tag: 'OffersRepo',
      );
    } catch (e) {
      AppLogger.error('Erreur claimOffer', tag: 'OffersRepo', error: e);
      rethrow;
    }
  }
}
