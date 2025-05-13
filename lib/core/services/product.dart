import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProductMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Méthode pour ajouter un seul produit
  Future<void> migrateSingleProduct(Map<String, dynamic> productData) async {
    try {
      await _firestore.collection('produits').add(productData);
      if (kDebugMode) {
        print('Produit migré: ${productData['nom']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur migration ${productData['nom']}: $e');
      }
    }
  }

  // 2. Méthode pour migrer par lots (batch)
  Future<void> migrateProductsInBatch(List<Map<String, dynamic>> products) async {
    WriteBatch batch = _firestore.batch();
    const batchSize = 400; // Firestore limite à 500 opérations/batch

    for (int i = 0; i < products.length; i++) {
      if (i > 0 && i % batchSize == 0) {
        await batch.commit(); // Commit le batch actuel
        batch = _firestore.batch(); // Nouveau batch
        if (kDebugMode) {
          print('Batch $i/${products.length} migré');
        }
      }

      var docRef = _firestore.collection('produits').doc();
      batch.set(docRef, products[i]);
    }

    await batch.commit(); // Commit le dernier batch
    if (kDebugMode) {
      print('Migration terminée ! ${products.length} produits migrés');
    }
  }

  // 3. Méthode pour générer des données de test
  List<Map<String, dynamic>> generateSampleProducts(int count) {
    return List.generate(count, (index) => {
      'nom': 'Produit ${index + 1}',
      'description': 'Description du produit ${index + 1}',
      'prix': 10.0 + (index * 0.5),
      'categorie': ['électronique', 'meuble', 'vêtement'][index % 3],
      'stock': 100 - index,
      'date_creation': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
      'actif': true,
    });
  }
}