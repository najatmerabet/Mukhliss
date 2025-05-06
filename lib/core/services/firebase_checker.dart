// lib/core/services/firebase_checker.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseChecker {
  /// Vérifie la connexion à Firebase
  static Future<bool> checkFirebaseConnection() async {
    try {
      // Initialise Firebase si ce n'est pas déjà fait
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      
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
