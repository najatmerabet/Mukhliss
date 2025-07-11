


import 'package:mukhliss/models/rewards.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardsService {

final SupabaseClient _client = Supabase.instance.client;

// recuperer reward d'un magasin 

Future<List<Rewards>> getRewardsByMagasin(String magasinId) async {
  print('Rewards fetched successfully for magasinId: $magasinId');
  try {
    if (magasinId.isEmpty) {
      return [];
    }

    final response = await _client
        .from('rewards')
        .select()
        .eq('magasin_id', magasinId);
        
    if (response.isEmpty) {

      print('No rewards found for magasinId: $magasinId');
      return [];
    }
print('response'+response.toString());
    return response.map<Rewards>((json) => Rewards.fromJson(json)).toList();
  } catch (e) {
    print('Error fetching rewards: $e');
    rethrow;
  }

}

// recuperer les nouveaux rewards 
Future<List<Rewards>> getRecentRewards() async {
  try {
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    
    final response = await _client.from('rewards')
      .select('''
        *,
        magasins:magasin_id (*)  // Jointure avec la table magasins
      ''')
      .gte('created_at', oneWeekAgo.toIso8601String())
      .order('created_at', ascending: false);


      print("les recompence"+response.toString());
    if (response == null || response.isEmpty) {
      return [];
    }
    
    return response.map<Rewards>((json) => Rewards.fromJson(json)).toList();
  } catch (e) {
    print('Error fetching recent rewards: $e');
    rethrow;
  }
}

}