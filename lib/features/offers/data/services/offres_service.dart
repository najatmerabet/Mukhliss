/// ============================================================
/// Offers Service - Data Layer
/// ============================================================
///
/// Service pour récupérer les offres depuis Supabase.
library;

import 'dart:async';
import 'package:mukhliss/core/logger/app_logger.dart';
import 'package:mukhliss/features/offers/data/models/offer_model.dart';
import 'package:mukhliss/features/offers/domain/entities/offer_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour gérer les offres
class OffersService {
  final SupabaseClient _client;

  OffersService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Récupère toutes les offres actives
  Future<List<OfferEntity>> getOffers() async {
    try {
      final response = await _client
          .from('offers')
          .select('*, magasins:magasin_id (*)')
          .eq('is_active', true)
          .timeout(const Duration(seconds: 10));

      if (response.isEmpty) {
        return [];
      }

      return (response as List)
          .map((json) => OfferModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching offers', error: e);
      rethrow;
    }
  }

  /// Récupère les offres pour un magasin spécifique
  Future<List<OfferEntity>> getOffersByStore(String storeId) async {
    try {
      if (storeId.isEmpty) {
        return [];
      }

      AppLogger.debug('Fetching offers for storeId: $storeId');

      final response = await _client
          .from('offers')
          .select('*, magasins:magasin_id (*)')
          .eq('magasin_id', storeId)
          .timeout(const Duration(seconds: 10));

      final offers =
          (response as List)
              .map((json) => OfferModel.fromJson(json).toEntity())
              .toList();

      AppLogger.debug('Fetched ${offers.length} offers');
      return offers;
    } catch (e) {
      AppLogger.error('Error fetching offers by store', error: e);
      rethrow;
    }
  }
}

/// Alias pour compatibilité (ancien nom)
/// @deprecated Utiliser OffersService
typedef OffresService = OffersService;
