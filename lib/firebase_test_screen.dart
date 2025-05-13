// lib/features/auth/screens/firebase_test_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/firebase_checker.dart';

class FirebaseTestScreen extends StatelessWidget {
  
  const FirebaseTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Firebase')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final isConnected = await FirebaseChecker.checkFirebaseConnection();
                Get.snackbar(
                  'Résultat du test',
                  isConnected ? 'Connectée à Firebase ✅' : 'Échec de connexion ❌',
                  backgroundColor: isConnected ? Colors.green : Colors.red,
                  colorText: Colors.white,
                );
              },
              child: const Text('Tester la connexion Firebase'),
            ),
            const SizedBox(height: 20),
            FutureBuilder(
              future: FirebaseChecker.checkFirebaseConnection(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                final isConnected = snapshot.data ?? false;
                return Text(
                  'Statut: ${isConnected ? 'CONNECTÉE' : 'NON CONNECTÉ'}',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}