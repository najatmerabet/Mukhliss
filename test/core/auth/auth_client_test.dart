// ===========================================
// TESTS DE L'AUTHENTIFICATION AVEC MOCK
// ===========================================
//
// Ces tests utilisent MockAuthClient pour tester
// la logique d'authentification SANS appeler Supabase.

import 'package:flutter_test/flutter_test.dart';
import 'package:mukhliss/core/errors/result.dart';
import 'package:mukhliss/core/errors/failures.dart';
import '../../mocks/mock_auth_client.dart';

void main() {
  // Variables pour les tests
  late MockAuthClient mockAuthClient;

  setUp(() {
    // Avant chaque test, créer un nouveau mock vide
    mockAuthClient = MockAuthClient();
  });

  // ============================================
  // TESTS DE CONNEXION EMAIL/PASSWORD
  // ============================================
  group('signInWithEmailPassword', () {
    test('devrait retourner un utilisateur si credentials valides', () async {
      // 1. CONFIGURER le mock pour retourner un succès
      final testUser = createTestUser(
        id: 'user-123',
        email: 'ahmed@example.com',
        firstName: 'Ahmed',
      );
      mockAuthClient.signInResult = Result.success(testUser);

      // 2. APPELER la méthode
      final result = await mockAuthClient.signInWithEmailPassword(
        email: 'ahmed@example.com',
        password: 'password123',
      );

      // 3. VÉRIFIER le résultat
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.email, 'ahmed@example.com');
      expect(result.valueOrNull?.firstName, 'Ahmed');
    });

    test('devrait retourner erreur si credentials invalides', () async {
      // 1. CONFIGURER le mock pour retourner une erreur
      mockAuthClient.signInResult = const Result.failure(
        InvalidCredentialsFailure(),
      );

      // 2. APPELER la méthode
      final result = await mockAuthClient.signInWithEmailPassword(
        email: 'wrong@email.com',
        password: 'wrongpassword',
      );

      // 3. VÉRIFIER le résultat
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<InvalidCredentialsFailure>());
    });

    test('devrait retourner erreur si pas de connexion internet', () async {
      // 1. CONFIGURER le mock pour simuler une erreur réseau
      mockAuthClient.signInResult = const Result.failure(
        NetworkFailure('Pas de connexion internet'),
      );

      // 2. APPELER la méthode
      final result = await mockAuthClient.signInWithEmailPassword(
        email: 'test@test.com',
        password: 'password123',
      );

      // 3. VÉRIFIER le résultat
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(result.failureOrNull?.message, contains('connexion'));
    });

    test('devrait mettre à jour currentUser après connexion réussie', () async {
      // 1. Vérifier qu'il n'y a pas d'utilisateur au début
      expect(mockAuthClient.currentUser, isNull);
      expect(mockAuthClient.isAuthenticated, isFalse);

      // 2. CONFIGURER et APPELER
      final testUser = createTestUser();
      mockAuthClient.signInResult = Result.success(testUser);
      await mockAuthClient.signInWithEmailPassword(
        email: 'test@test.com',
        password: 'password123',
      );

      // 3. VÉRIFIER que l'utilisateur est maintenant connecté
      expect(mockAuthClient.currentUser, isNotNull);
      expect(mockAuthClient.isAuthenticated, isTrue);
    });
  });

  // ============================================
  // TESTS DE CONNEXION GOOGLE
  // ============================================
  group('signInWithGoogle', () {
    test(
      'devrait retourner un utilisateur si connexion Google réussie',
      () async {
        // CONFIGURER
        final googleUser = createTestUser(
          id: 'google-user-456',
          email: 'user@gmail.com',
          firstName: 'Google',
          lastName: 'User',
        );
        mockAuthClient.signInWithGoogleResult = Result.success(googleUser);

        // APPELER
        final result = await mockAuthClient.signInWithGoogle();

        // VÉRIFIER
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull?.email, 'user@gmail.com');
      },
    );

    test('devrait retourner erreur si Google login annulé', () async {
      // CONFIGURER
      mockAuthClient.signInWithGoogleResult = const Result.failure(
        AuthFailure('Connexion annulée par l\'utilisateur'),
      );

      // APPELER
      final result = await mockAuthClient.signInWithGoogle();

      // VÉRIFIER
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('annulée'));
    });
  });

  // ============================================
  // TESTS DE DÉCONNEXION
  // ============================================
  group('signOut', () {
    test('devrait déconnecter l\'utilisateur', () async {
      // 1. Simuler un utilisateur connecté
      mockAuthClient.setLoggedInUser(createTestUser());
      expect(mockAuthClient.isAuthenticated, isTrue);

      // 2. APPELER signOut
      await mockAuthClient.signOut();

      // 3. VÉRIFIER que l'utilisateur est déconnecté
      expect(mockAuthClient.currentUser, isNull);
      expect(mockAuthClient.isAuthenticated, isFalse);
    });
  });

  // ============================================
  // TESTS DE ENVOI OTP
  // ============================================
  group('sendOtp', () {
    test('devrait réussir l\'envoi d\'OTP', () async {
      // CONFIGURER
      mockAuthClient.sendOtpResult = const Result.success(null);

      // APPELER
      final result = await mockAuthClient.sendOtp('test@test.com');

      // VÉRIFIER
      expect(result.isSuccess, isTrue);
    });

    test('devrait retourner erreur si email n\'existe pas', () async {
      // CONFIGURER
      mockAuthClient.sendOtpResult = const Result.failure(
        UserNotFoundFailure('Cet email n\'existe pas'),
      );

      // APPELER
      final result = await mockAuthClient.sendOtp(
        'nonexistent@email.com',
        isRecovery: true,
      );

      // VÉRIFIER
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UserNotFoundFailure>());
    });
  });

  // ============================================
  // TESTS DE VÉRIFICATION OTP
  // ============================================
  group('verifyOtp', () {
    test('devrait retourner utilisateur si OTP correct', () async {
      // CONFIGURER
      mockAuthClient.verifyOtpResult = Result.success(createTestUser());

      // APPELER
      final result = await mockAuthClient.verifyOtp(
        email: 'test@test.com',
        token: '123456',
      );

      // VÉRIFIER
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNotNull);
    });

    test('devrait retourner erreur si OTP expiré', () async {
      // CONFIGURER
      mockAuthClient.verifyOtpResult = const Result.failure(
        AuthFailure('OTP expiré'),
      );

      // APPELER
      final result = await mockAuthClient.verifyOtp(
        email: 'test@test.com',
        token: '000000',
      );

      // VÉRIFIER
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('expiré'));
    });
  });

  // ============================================
  // TESTS DE MISE À JOUR MOT DE PASSE
  // ============================================
  group('updatePassword', () {
    test('devrait réussir la mise à jour du mot de passe', () async {
      // CONFIGURER
      mockAuthClient.updatePasswordResult = const Result.success(null);

      // APPELER
      final result = await mockAuthClient.updatePassword('newPassword123');

      // VÉRIFIER
      expect(result.isSuccess, isTrue);
    });

    test('devrait retourner erreur si mot de passe trop faible', () async {
      // CONFIGURER
      mockAuthClient.updatePasswordResult = const Result.failure(
        WeakPasswordFailure(),
      );

      // APPELER
      final result = await mockAuthClient.updatePassword('123');

      // VÉRIFIER
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<WeakPasswordFailure>());
    });
  });
}
