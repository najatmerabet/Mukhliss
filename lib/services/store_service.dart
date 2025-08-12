import 'dart:convert';

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

    // Vérification que la réponse est une liste
    if (response == null || response is! List) {
      print('Réponse invalide ou vide de Supabase');
      return [];
    }

    return response.map<Store>((item) {
      try {
        // Conversion sécurisée en Map
        final json = (item as Map<String, dynamic>?) ?? {};

        // Extraction et traitement du logo (peut être null)
        final String? rawLogoUrl = json['logoUrl']?.toString();
        String? publicUrl;
        
        if (rawLogoUrl != null && rawLogoUrl.isNotEmpty) {
          try {
            final fileName = rawLogoUrl.split('/').last;
            publicUrl = _client.storage.from(_bucketName).getPublicUrl(fileName);
          } catch (e) {
            print('Erreur de génération URL pour $rawLogoUrl: $e');
            publicUrl = rawLogoUrl; // On conserve l'original si échec
          }
        }

        // Création du magasin avec ou sans logo
        return Store.fromJson({
          ...json,
          'logoUrl': publicUrl ?? json['logoUrl'], // Garde l'original si publicUrl est null
        });
      } catch (e, stackTrace) {
        print('Erreur traitement magasin: $e');
        print('Stack trace: $stackTrace');
        
        // Retourne un magasin minimal avec les données disponibles
        return Store(
          id: (item as Map<String, dynamic>?)?['id'] ?? '',
          nom_enseigne: (item as Map<String, dynamic>?)?['nom_enseigne'] ?? '',
          siret: (item as Map<String, dynamic>?)?['siret'] ?? '',
          adresse: (item as Map<String, dynamic>?)?['adresse'] ?? '',
          ville: (item as Map<String, dynamic>?)?['ville'] ?? '',
          code_postal: (item as Map<String, dynamic>?)?['code_postal'] ?? '',
          telephone: (item as Map<String, dynamic>?)?['telephone'] ?? '',
          description: (item as Map<String, dynamic>?)?['description'] ?? '',
          geom: (item as Map<String, dynamic>?)?['geom'] ?? {},
          Categorieid: (item as Map<String, dynamic>?)?['Categorieid'] ?? 0,
          logoUrl: (item as Map<String, dynamic>?)?['logoUrl'] ?? '', // Utilise l'URL publique ou null
        );
      }
    }).toList();
  } catch (e, stackTrace) {
    print('Erreur récupération magasins: $e');
    print('Stack trace: $stackTrace');
    return [];
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

/* Removed problematic extension on JsonCodec that caused [] to return void */