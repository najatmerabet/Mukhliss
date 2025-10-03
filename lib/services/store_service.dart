<<<<<<< HEAD

=======
import 'dart:async';
import 'package:flutter/material.dart';
>>>>>>> 208f1a40e490935eeded42d2270eb886ca7b6aad
import 'package:mukhliss/models/store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucketName = 'store-logo/logos';

  // Méthode avec pagination AMÉLIORÉE
  Future<List<Store>> getStoresWithLogos({
    int limit = 20, // ✅ Augmenté de 5 à 20
    int offset = 0,
  }) async {
    try {
      debugPrint('🔄 Chargement magasins (limit: $limit, offset: $offset)...');
      
      final response = await _client
          .from('magasins')
          .select('*')
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false)
          .timeout(
            const Duration(seconds: 45), // ✅ Augmenté de 15 à 45 secondes
            onTimeout: () {
              debugPrint('⚠️ Timeout dépassé pour batch $offset-${offset + limit}');
              throw TimeoutException('Timeout après 45 secondes');
            },
          );

<<<<<<< HEAD
    return response.map<Store>((item) {
      try {
        // Conversion sécurisée en Map
        final json = (item as Map<String, dynamic>?) ?? {};
=======
      debugPrint('📦 Batch reçu: ${response?.length ?? 0} items');

      if (response == null || response is! List) {
        debugPrint('❌ Réponse invalide');
        return [];
      }

      if (response.isEmpty) {
        debugPrint('⚠️ Aucun magasin dans ce batch');
        return [];
      }

      final stores = response.map<Store>((item) {
        try {
          final json = item as Map<String, dynamic>;
          
          // Traitement du logo OPTIMISÉ
          final String? rawLogoUrl = json['logoUrl']?.toString();
          String? publicUrl;
          
          if (rawLogoUrl != null && rawLogoUrl.isNotEmpty) {
            try {
              // Ne pas générer l'URL publique si déjà une URL complète
              if (rawLogoUrl.startsWith('http')) {
                publicUrl = rawLogoUrl;
              } else {
                final fileName = rawLogoUrl.split('/').last;
                publicUrl = _client.storage.from(_bucketName).getPublicUrl(fileName);
              }
            } catch (e) {
              debugPrint('⚠️ Erreur génération URL pour $rawLogoUrl: $e');
              publicUrl = rawLogoUrl;
            }
          }

          final store = Store.fromJson({
            ...json,
            'logoUrl': publicUrl ?? json['logoUrl'],
          });

          return store;
        } catch (e) {
          debugPrint('❌ Erreur parsing magasin: $e');
          rethrow;
        }
      }).toList();

      debugPrint('✅ ${stores.length} magasins chargés (batch $offset)');
      return stores;
      
    } on TimeoutException catch (e) {
      debugPrint('❌ TIMEOUT batch $offset: $e');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ ERREUR batch $offset: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    }
  }

  // Méthode pour charger TOUS les magasins avec retry
  Future<List<Store>> getAllStoresWithPagination({
    int batchSize = 20, // ✅ Augmenté
    int maxRetries = 3, // ✅ Ajout de retry
  }) async {
    List<Store> allStores = [];
    int offset = 0;
    bool hasMore = true;
>>>>>>> 208f1a40e490935eeded42d2270eb886ca7b6aad

    try {
      while (hasMore) {
        debugPrint('📥 Chargement batch $offset...');
        
        int retries = 0;
        bool success = false;
        List<Store>? batch;

        // ✅ Retry logic pour chaque batch
        while (retries < maxRetries && !success) {
          try {
            batch = await getStoresWithLogos(
              limit: batchSize,
              offset: offset,
            );
            success = true;
          } on TimeoutException catch (e) {
            retries++;
            debugPrint('⚠️ Retry $retries/$maxRetries pour batch $offset');
            
            if (retries >= maxRetries) {
              debugPrint('❌ Abandon après $maxRetries tentatives');
              throw Exception('Timeout persistant après $maxRetries essais');
            }
            
            // Attendre avant de réessayer (backoff exponentiel)
            await Future.delayed(Duration(seconds: retries * 2));
          }
        }

        if (batch == null || batch.isEmpty) {
          hasMore = false;
          debugPrint('✅ Tous les magasins chargés: ${allStores.length} total');
        } else {
          allStores.addAll(batch);
          offset += batchSize;
          
          // Pause entre les requêtes
          await Future.delayed(const Duration(milliseconds: 300)); // ✅ Augmenté
        }
      }

      return allStores;
    } catch (e) {
      debugPrint('❌ Erreur chargement total: $e');
      // Retourner ce qui a été chargé jusqu'ici
      return allStores;
    }
  }

  String getStoreLogoUrl(String filePath) {
    final fileName = filePath.split('/').last;
    return _client.storage.from(_bucketName).getPublicUrl(fileName);
  }
}