import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mukhliss/models/clientoffre.dart';
import 'package:mukhliss/models/rewards.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientoffreService {
  final SupabaseClient _client = Supabase.instance.client;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Erreur lors de la vérification de la connectivité: $e');
      return false;
    }
  }

  Future<List<ClientOffre>> getClientOffres(String clientId) async {
    try {
      if (!await _hasInternetConnection()) {
        throw Exception('no_internet_connection');
      }
      
      print('clientId: $clientId');
      
      // Add timeout to the query
      final response = await _client
          .from('reward_claims')
          .select('''
            *,
            rewards:reward_id (*, magasin:magasin_id (*))
          ''')
          .eq('client_id', clientId)
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              throw Exception('connection_timeout');
            },
          );
      
      if (response.isEmpty) {
        return [];
      }
      
      print("response des recompence reclamation: $response");
      
      return (response as List).map((json) {
        return ClientOffre(
          client_id: json['client_id'] as String,
          reward: Rewards.fromJson(json['rewards']),
          claimed_at: DateTime.parse(json['claimed_at'] as String),
        );
      }).toList();
      
    } on TimeoutException {
      print('Connection timeout - server took too long to respond');
      throw Exception('connection_timeout');
    } catch (e) {
      print('Error fetching client offers: $e');
      
      // Better error handling
      if (e.toString().contains('SocketException')) {
        throw Exception('network_error');
      }
      throw Exception('Failed to load client offers: $e');
    }
  }
}