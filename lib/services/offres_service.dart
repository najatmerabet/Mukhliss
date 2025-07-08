
import 'dart:async';

import 'package:mukhliss/models/offers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OffresService {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Offers>> getOffres() async {
    final response = await client.from('offers').select().eq('is_active', true);
    if (response.isEmpty) {
      throw Exception('Failed to load offres');
    }
    return response.map((json)=> Offers.fromJson(json)).toList();
  }

Future<List<Offers>> getOffresByMagasin(String magasinId) async {
  try {
    print('🔵 Fetching offers for magasinId: $magasinId');
    
    if (magasinId.isEmpty) {
      print('🟠 Empty magasinId provided');
      return [];
    }

    final response = await client.from('offers')
      .select()
      .eq('magasin_id', magasinId)
      .then((data) {
        print('🟢 Raw API response: ${data.length} items');
        return data;
      })
      .timeout(const Duration(seconds: 10), onTimeout: () {
        print('🔴 Timeout fetching offers');
        throw TimeoutException('Request timed out');
      });

    final offers = response.map((json) {
      try {
        return Offers.fromJson(json);
      } catch (e) {
        print('🟠 Error parsing offer: $e\nJSON: $json');
        throw FormatException('Failed to parse offer: $e');
      }
    }).toList();

    print('🟢 Successfully fetched ${offers.length} offers');
    return offers;

  } on TimeoutException catch (e) {
    print('🔴 Timeout: $e');
    rethrow;
  } on PostgrestException catch (e) {
    print('🔴 Supabase error: ${e.message}');
    rethrow;
  } on FormatException catch (e) {
    print('🔴 Parsing error: $e');
    rethrow;
  } catch (e, stack) {
    print('🔴 Unexpected error: $e\n$stack');
    rethrow;
  }
}

}