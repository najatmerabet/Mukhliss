/// ============================================================
/// Client Offer Service - Data Layer
/// ============================================================
///
/// Service pour récupérer les offres réclamées par un client.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mukhliss/core/logger/app_logger.dart';
import 'package:mukhliss/features/rewards/data/models/reward_model.dart';
import 'package:mukhliss/features/rewards/domain/entities/reward_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modèle pour une offre réclamée par un client
class ClaimedOffer {
  final String clientId;
  final RewardEntity reward;
  final DateTime claimedAt;

  const ClaimedOffer({
    required this.clientId,
    required this.reward,
    required this.claimedAt,
  });

  factory ClaimedOffer.fromJson(Map<String, dynamic> json) {
    final rewardJson = json['rewards'] as Map<String, dynamic>?;

    return ClaimedOffer(
      clientId: json['client_id'] as String? ?? '',
      reward:
          rewardJson != null
              ? RewardModel.fromJson(rewardJson).toEntity()
              : RewardEntity.empty(),
      claimedAt:
          DateTime.tryParse(json['claimed_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Service pour gérer les offres réclamées
class ClientOfferService {
  final SupabaseClient _client;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  ClientOfferService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      AppLogger.warning('Erreur vérification connectivité', error: e);
      return false;
    }
  }

  /// Récupère toutes les offres réclamées par un client
  Future<List<ClaimedOffer>> getClientOffers(String clientId) async {
    try {
      if (!await _hasInternetConnection()) {
        throw Exception('no_internet_connection');
      }

      AppLogger.debug('Fetching offers for client: $clientId');

      final response = await _client
          .from('reward_claims')
          .select('''
            *,
            rewards:reward_id (*, magasins:magasin_id (*))
          ''')
          .eq('client_id', clientId)
          .timeout(
            _timeoutDuration,
            onTimeout: () => throw Exception('connection_timeout'),
          );

      if (response.isEmpty) {
        return [];
      }

      AppLogger.debug('Got ${response.length} claimed offers');

      return (response as List)
          .map((json) => ClaimedOffer.fromJson(json as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      AppLogger.error('Connection timeout fetching client offers');
      throw Exception('connection_timeout');
    } catch (e) {
      AppLogger.error('Error fetching client offers', error: e);

      if (e.toString().contains('SocketException')) {
        throw Exception('network_error');
      }
      rethrow;
    }
  }
}

/// Alias pour compatibilité (ancien nom)
/// @deprecated Utiliser ClientOfferService
typedef ClientoffreService = ClientOfferService;
