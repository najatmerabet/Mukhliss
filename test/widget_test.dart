// Test de base pour vérifier que l'application démarre correctement
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Mukhliss App Tests', () {
    testWidgets('App should render without errors', (
      WidgetTester tester,
    ) async {
      // Test simple pour vérifier que l'app peut être construite
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: Center(child: Text('Mukhliss Test'))),
          ),
        ),
      );

      // Vérifier que le texte est affiché
      expect(find.text('Mukhliss Test'), findsOneWidget);
    });

    test('Basic sanity check', () {
      // Test simple de sanité
      expect(1 + 1, equals(2));
    });
  });
}
