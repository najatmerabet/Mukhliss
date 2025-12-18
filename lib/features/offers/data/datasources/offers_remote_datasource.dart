/// ============================================================
/// Offers Remote DataSource - Data Layer
/// ============================================================
///
/// Source de données distante (Supabase) pour les offres.
library;

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mukhliss/core/logger/app_logger.dart';
import '../models/offer_model.dart';

/// Interface pour la source de données distante
abstract class OffersRemoteDataSource {
  Future<List<OfferModel>> getOffers();
  Future<List<OfferModel>> getOffersByStore(String storeId);
  Future<OfferModel?> getOfferById(String id);
}

/// Implémentation Supabase
class OffersRemoteDataSourceImpl implements OffersRemoteDataSource {
  final SupabaseClient _client;

  OffersRemoteDataSourceImpl({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<List<OfferModel>> getOffers() async {
    try {
      final response = await _client
          .from('offers')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OfferModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Erreur getOffers', tag: 'OffersDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<List<OfferModel>> getOffersByStore(String storeId) async {
    if (storeId.isEmpty) {
      AppLogger.warning('storeId vide', tag: 'OffersDataSource');
      return [];
    }

    try {
      AppLogger.debug(
        'Fetching offers for storeId: $storeId',
        tag: 'OffersDataSource',
      );

      final response = await _client
          .from('offers')
          .select()
          .eq('magasin_id', storeId)
          .timeout(const Duration(seconds: 10));

      final offers =
          (response as List).map((json) => OfferModel.fromJson(json)).toList();

      AppLogger.debug(
        'Fetched ${offers.length} offers',
        tag: 'OffersDataSource',
      );
      return offers;
    } on TimeoutException {
      AppLogger.error('Timeout getOffersByStore', tag: 'OffersDataSource');
      rethrow;
    } catch (e) {
      AppLogger.error(
        'Erreur getOffersByStore',
        tag: 'OffersDataSource',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<OfferModel?> getOfferById(String id) async {
    try {
      final response =
          await _client.from('offers').select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return OfferModel.fromJson(response);
    } catch (e) {
      AppLogger.error('Erreur getOfferById', tag: 'OffersDataSource', error: e);
      rethrow;
    }
  }
}
