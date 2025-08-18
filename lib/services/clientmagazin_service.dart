import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mukhliss/models/clientmagazin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientMagazinService {
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
   
  Future<ClientMagazin?> getClientMagazinPoints(String clientId, String magazinId) async {
    try {
      // Vérifier la connexion Internet d'abord
      if (!await _hasInternetConnection()) {
        throw Exception('no_internet_connection');
      }
      
      print('Recherche points pour client:$clientId, magasin:$magazinId');
      final response = await _client
          .from('clientmagasin')
          .select()
          .eq('client_id', clientId)
          .eq('magasin_id', magazinId)
          .maybeSingle();

      print('ClientMagazinServicerespponse: $response');
      return response == null ? null : ClientMagazin.fromJson(response);
         
    } catch (error) {
      print('Erreur ClientMagazinService: $error');
      // Relancer l'erreur pour que le provider puisse la gérer
      rethrow;
    }
  }
}