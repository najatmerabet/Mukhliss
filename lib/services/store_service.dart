

import 'package:mukhliss/models/store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreService {
 
 final SupabaseClient _client = Supabase.instance.client;
 
Future<List<Store>> fetchStores() async {
    try {
      final response = await _client
          .from('magasins')
          .select() ;
      print('Données reçues de Supabase: $response');
           return (response as List)
          .map((json) => Store.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch stores: $error');
    }
  }

}
