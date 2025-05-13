import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mukhliss/migrations/0001_create_products_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MigrationService {
  final FirebaseFirestore firestore;
  final List<Function> migrations = [
    (firestore) => CreateProductsTable(firestore),
    // Ajouter d'autres migrations ici
  ];

  MigrationService(this.firestore);

  Future<void> runMigrations() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMigration = prefs.getInt('last_migration') ?? 0;

    for (int i = lastMigration; i < migrations.length; i++) {
      final migration = migrations[i](firestore);
      await migration.up();
      await prefs.setInt('last_migration', i + 1);
      print('Migration ${i + 1} exécutée avec succès');
    }
  }

  Future<void> rollback() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMigration = prefs.getInt('last_migration') ?? 0;

    if (lastMigration > 0) {
      final migration = migrations[lastMigration - 1](firestore);
      await migration.down(); 
      await prefs.setInt('last_migration', lastMigration - 1);
      print('Rollback de la migration $lastMigration effectué');
    }
  }
}