// ===========================================
// TESTS AVEC MOCKS - NIVEAU INTERMÉDIAIRE
// ===========================================
//
// Ce fichier montre comment tester des fonctions qui
// appellent des services externes (comme Supabase)
// SANS avoir besoin du vrai service.
//
// C'est ce que font les entreprises moyennes/grandes!

import 'package:flutter_test/flutter_test.dart';
import 'package:mukhliss/core/errors/result.dart';
import 'package:mukhliss/core/errors/failures.dart';

// ============================================
// ÉTAPE 1: Définir une INTERFACE (contrat)
// ============================================
//
// Une interface dit "voici ce que la classe doit pouvoir faire"
// mais PAS comment elle le fait.

/// Interface pour le service d'authentification
abstract class IAuthService {
  Future<Result<String>> login(String email, String password);
  Future<Result<void>> logout();
  bool get isLoggedIn;
}

// ============================================
// ÉTAPE 2: La VRAIE implémentation
// ============================================
//
// Cette classe appelle le VRAI Supabase.
// On ne peut pas la tester facilement.

class RealAuthService implements IAuthService {
  bool _isLoggedIn = false;

  @override
  Future<Result<String>> login(String email, String password) async {
    // Ici on appellerait Supabase...
    // await supabase.auth.signInWithPassword(...)

    // Simulation pour l'exemple:
    if (email == 'test@test.com' && password == '123456') {
      _isLoggedIn = true;
      return const Result.success('user-id-123');
    }
    return const Result.failure(InvalidCredentialsFailure());
  }

  @override
  Future<Result<void>> logout() async {
    _isLoggedIn = false;
    return const Result.success(null);
  }

  @override
  bool get isLoggedIn => _isLoggedIn;
}

// ============================================
// ÉTAPE 3: Le MOCK (fausse implémentation)
// ============================================
//
// Cette classe ne fait RIEN de réel.
// Elle retourne juste ce qu'on lui dit de retourner.

class MockAuthService implements IAuthService {
  // On peut configurer ce que le mock va retourner
  Result<String>? loginResult;
  Result<void>? logoutResult;
  bool mockIsLoggedIn = false;

  @override
  Future<Result<String>> login(String email, String password) async {
    // Retourne ce qu'on a configuré, ou une erreur par défaut
    return loginResult ?? const Result.failure(AuthFailure('Not configured'));
  }

  @override
  Future<Result<void>> logout() async {
    mockIsLoggedIn = false;
    return logoutResult ?? const Result.success(null);
  }

  @override
  bool get isLoggedIn => mockIsLoggedIn;
}

// ============================================
// ÉTAPE 4: Une classe qui UTILISE l'auth service
// ============================================
//
// Cette classe ne sait pas si elle utilise le vrai
// service ou le mock. Elle utilise juste l'interface.

class LoginUseCase {
  final IAuthService authService; // ← Interface, pas implémentation!

  LoginUseCase(this.authService);

  Future<String> execute(String email, String password) async {
    // Valider l'email
    if (!email.contains('@')) {
      return 'Email invalide';
    }

    // Valider le mot de passe
    if (password.length < 6) {
      return 'Mot de passe trop court';
    }

    // Appeler le service d'auth
    final result = await authService.login(email, password);

    return result.when(
      success: (userId) => 'Connexion réussie! ID: $userId',
      failure: (error) => 'Erreur: ${error.message}',
    );
  }
}

// ============================================
// ÉTAPE 5: LES TESTS!
// ============================================

void main() {
  group('LoginUseCase', () {
    // Variables pour les tests
    late MockAuthService mockAuthService;
    late LoginUseCase loginUseCase;

    setUp(() {
      // Avant chaque test, créer un nouveau mock
      mockAuthService = MockAuthService();
      loginUseCase = LoginUseCase(mockAuthService);
    });

    // ----------------------------------------
    // Test 1: Email invalide
    // ----------------------------------------
    test('devrait retourner erreur si email invalide', () async {
      // Pas besoin de configurer le mock car on n'atteint jamais le login

      final result = await loginUseCase.execute('email-sans-arobase', '123456');

      expect(result, 'Email invalide');
    });

    // ----------------------------------------
    // Test 2: Mot de passe trop court
    // ----------------------------------------
    test('devrait retourner erreur si mot de passe trop court', () async {
      final result = await loginUseCase.execute('test@test.com', '123');

      expect(result, 'Mot de passe trop court');
    });

    // ----------------------------------------
    // Test 3: Login réussi
    // ----------------------------------------
    test('devrait retourner succès si login OK', () async {
      // CONFIGURER le mock pour retourner un succès
      mockAuthService.loginResult = const Result.success('user-abc-123');

      final result = await loginUseCase.execute('test@test.com', '123456');

      expect(result, 'Connexion réussie! ID: user-abc-123');
    });

    // ----------------------------------------
    // Test 4: Login échoué (mauvais credentials)
    // ----------------------------------------
    test('devrait retourner erreur si credentials invalides', () async {
      // CONFIGURER le mock pour retourner une erreur
      mockAuthService.loginResult = const Result.failure(
        InvalidCredentialsFailure(),
      );

      final result = await loginUseCase.execute('test@test.com', '123456');

      expect(result, contains('mot de passe incorrect'));
    });

    // ----------------------------------------
    // Test 5: Erreur réseau
    // ----------------------------------------
    test('devrait retourner erreur si pas de connexion', () async {
      // CONFIGURER le mock pour simuler une erreur réseau
      mockAuthService.loginResult = const Result.failure(
        NetworkFailure('Pas de connexion internet'),
      );

      final result = await loginUseCase.execute('test@test.com', '123456');

      expect(result, contains('Pas de connexion internet'));
    });
  });
}

// ============================================
// RÉSUMÉ - CE QU'ON A APPRIS
// ============================================
//
// 1. INTERFACE (IAuthService)
//    → Définit le "contrat" de ce que la classe doit faire
//
// 2. VRAIE IMPLÉMENTATION (RealAuthService)
//    → Appelle les vrais services (Supabase, Google, etc.)
//
// 3. MOCK (MockAuthService)
//    → Fausse implémentation pour les tests
//    → On peut configurer ce qu'elle retourne
//
// 4. INJECTION DE DÉPENDANCE
//    → LoginUseCase reçoit l'interface, pas l'implémentation
//    → En prod: on donne RealAuthService
//    → En test: on donne MockAuthService
//
// 5. TESTS
//    → On configure le mock pour différents scénarios
//    → On vérifie que LoginUseCase réagit correctement
//
// ============================================
