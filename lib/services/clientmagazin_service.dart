import 'package:mukhliss/models/clientmagazin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientMagazinService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<ClientMagazin?> getClientMagazinPoints(String clientId, String magazinId) async {
    try {
      print('Recherche points pour client:$clientId, magasin:$magazinId');
      final response = await _client
          .from('clientmagazin')
          .select()
          .eq('client_id', clientId) // Maintenant en String pour UUID
          .eq('magazin_id', magazinId)
          .maybeSingle();
 print('r===================== ClientMagazinService: $response');
      return response == null ? null : ClientMagazin.fromJson(response);
    
    } catch (error) {
      print('Erreur ClientMagazinService: $error');
      return null;
    }
  }
}
