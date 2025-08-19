
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mukhliss/models/clientoffre.dart';
import 'package:mukhliss/models/rewards.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class  ClientoffreService {
final SupabaseClient _client = Supabase.instance.client;

  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Erreur lors de la vérification de la connectivité: $e');
      return false;
    }
  }
//recuperer les recompenses pris par client
Future<List<ClientOffre>> getClientOffres(String clientId) async {
  try {
     if (!await _hasInternetConnection()) {
        throw Exception('no_internet_connection');
      }
      
    print('clientId: $clientId');
    final response = await _client
        .from('reward_claims')
        .select('''
          *,
          rewards:reward_id (*, magasin:magasin_id (*))
        ''')
        .eq('client_id', clientId);
    if (response.isEmpty) {
      return [];
    }
print("response des recompence reclamation"+response.toString());
    return (response as List).map((json) {
      return ClientOffre(
        client_id: json['client_id'] as String,
        reward: Rewards.fromJson(json['rewards']), // Notez 'Reward' au lieu de 'Rewards'
        claimed_at: DateTime.parse(json['claimed_at'] as String)
      );
    }).toList();
    
  } catch (e) {
    print('Error fetching client offers: $e');
    throw Exception('Failed to load client offers: $e');
  }
}

}