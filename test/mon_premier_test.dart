// ===========================================
// TON PREMIER TEST UNITAIRE - SUPER SIMPLE!
// ===========================================

import 'package:flutter_test/flutter_test.dart';

// ============================================
// ÉTAPE 1: Voici une fonction à tester
// ============================================
int additionner(int a, int b) {
  return a + b;
}

// ============================================
// ÉTAPE 2: Voici le test de cette fonction
// ============================================
void main() {
  test('additionner 2 + 3 devrait donner 5', () {
    // 1. On appelle la fonction
    int resultat = additionner(2, 3);

    // 2. On vérifie le résultat
    expect(resultat, 5);
    //     ^^^^^^^^  ^
    //     |         |
    //     |         Ce qu'on ATTEND (la bonne réponse)
    //     |
    //     Ce qu'on a OBTENU (le résultat de la fonction)
  });
}

// ============================================
// COMMENT ÇA MARCHE?
// ============================================
//
// test('description', () { ... })
//   → Définit UN test avec une description
//
// expect(resultat, 5)
//   → Vérifie que "resultat" est égal à 5
//   → Si c'est vrai → TEST RÉUSSI ✅
//   → Si c'est faux → TEST ÉCHOUÉ ❌
//
// ============================================
