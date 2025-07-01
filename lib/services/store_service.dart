import 'package:mukhliss/models/store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucketName = 'store-logo'; // Nom exact du bucket

  Future<List<Store>> getStoresWithLogos() async {
    try {
      final response = await _client
          .from('magasins')
          .select('*');

      return response.map<Store>((json) {
        // Extraction du nom de fichier seulement (pas de l'URL complète)
        final rawFileName = (json['logoUrl'] as String?)?.trim();
        final fileName = rawFileName != null 
            ? rawFileName.split('/').last // Prendre seulement le nom du fichier
            : null;
   print('stores'+response.toString());
        // Génération de l'URL publique valide
        final logoUrl = fileName != null
            ? _client.storage
                .from(_bucketName)
                .getPublicUrl(fileName)
            : null;

        print('Generated Logo URL: $logoUrl');

        return Store.fromJson({
          ...json,
          'logoUrl': logoUrl
        });
      }).toList();
    } catch (e) {
      print('Error fetching stores: $e');
      rethrow;
    }
  }


 String getStoreLogoUrl(String filePath) {
    // Prendre seulement le nom du fichier si une URL complète est fournie
    final fileName = filePath.split('/').last;
    return _client.storage
      .from(_bucketName)
      .getPublicUrl(fileName);
  }
}