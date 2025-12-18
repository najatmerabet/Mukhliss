// ===========================================
// TEST QUI VA ÉCHOUER (exprès!)
// ===========================================

import 'package:flutter_test/flutter_test.dart';

// Une fonction avec un BUG (volontairement)
int additionnerAvecBug(int a, int b) {
  return a + b + 1; // ← BUG! On ajoute 1 de trop
}

void main() {
  test('additionner 2 + 3 devrait donner 5', () {
    int resultat = additionnerAvecBug(2, 3);

    // Le résultat sera 6 (à cause du bug)
    // Mais on attend 5
    // Donc le test va ÉCHOUER!
    expect(resultat, 5);
  });
}
