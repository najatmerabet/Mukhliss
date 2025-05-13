import 'package:cloud_firestore/cloud_firestore.dart';

class CreateProductsTable {
  final FirebaseFirestore firestore;

  CreateProductsTable(this.firestore);

  Future<void> up() async {
    // Créer la collection avec des documents initiaux
    await firestore.collection('products').doc('template').set({ 
      'name': 'Template',
      'description': 'This is a template product',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> down() async {
    // Supprimer la collection (attention: cette opération est sensible)
    final query = await firestore.collection('products').get();
    final batch = firestore.batch();
    for (var doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}