// lib/core/services/firebase_checker.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mukhliss/core/services/migration_service.dart';
import 'package:mukhliss/firebase_options.dart';

class FirebaseChecker {
  /// Vérifie la connexion à Firebase
  static Future<bool> checkFirebaseConnection() async {
    try {
      // Initialise Firebase si ce n'est pas déjà fait
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
// Exécuter les migrations au lancement
  final migrationService = MigrationService(FirebaseFirestore.instance);
  await migrationService.runMigrations();
      // Vérification supplémentaire (optionnelle)
      // Vous pouvez tester un accès simple à Firestore ou Auth
      // final snapshot = await FirebaseFirestore.instance.collection('test').limit(1).get();

      return true;
    } catch (e) {
      debugPrint('Erreur de connexion Firebase: $e');
      return false;
    }
  }
}
