/// Tests unitaires pour le système d'authentification
///
/// Ces tests vérifient le bon fonctionnement de:
/// - AuthFlowHelper
/// - Result pattern
/// - Failures
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mukhliss/core/auth/auth_providers.dart';
import 'package:mukhliss/core/errors/result.dart';
import 'package:mukhliss/core/errors/failures.dart';

void main() {
  group('AuthFlowHelper', () {
    setUp(() {
      // Reset le flag avant chaque test
      AuthFlowHelper.endPasswordResetFlow();
    });

    test('devrait être false par défaut', () {
      expect(AuthFlowHelper.isPasswordResetInProgress, isFalse);
    });

    test('startPasswordResetFlow devrait mettre le flag à true', () {
      AuthFlowHelper.startPasswordResetFlow();
      expect(AuthFlowHelper.isPasswordResetInProgress, isTrue);
    });

    test('endPasswordResetFlow devrait mettre le flag à false', () {
      AuthFlowHelper.startPasswordResetFlow();
      expect(AuthFlowHelper.isPasswordResetInProgress, isTrue);

      AuthFlowHelper.endPasswordResetFlow();
      expect(AuthFlowHelper.isPasswordResetInProgress, isFalse);
    });
  });

  group('Result Pattern', () {
    test('Result.success devrait contenir la valeur', () {
      final result = Result<String>.success('test');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, equals('test'));
    });

    test('Result.failure devrait contenir l\'erreur', () {
      const failure = NetworkFailure('No internet');
      final result = Result<String>.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('when devrait appeler success callback pour success', () {
      final result = Result<int>.success(42);

      String? successValue;
      result.when(
        success: (value) => successValue = 'success: $value',
        failure: (error) => successValue = 'failure',
      );

      expect(successValue, equals('success: 42'));
    });

    test('when devrait appeler failure callback pour failure', () {
      const failure = AuthFailure('Auth error');
      final result = Result<int>.failure(failure);

      String? errorValue;
      result.when(
        success: (value) => errorValue = 'success',
        failure: (error) => errorValue = 'failure: ${error.message}',
      );

      expect(errorValue, equals('failure: Auth error'));
    });

    test('map devrait transformer success', () {
      final result = Result<int>.success(10);

      final transformed = result.map((value) => value * 2);

      expect(transformed.valueOrNull, equals(20));
    });

    test('map devrait propager failure', () {
      final result = Result<int>.failure(const NetworkFailure());

      final transformed = result.map((value) => value * 2);

      expect(transformed.isFailure, isTrue);
      expect(transformed.failureOrNull, isA<NetworkFailure>());
    });

    test('getOrElse devrait retourner la valeur pour success', () {
      final success = Result<int>.success(5);
      expect(success.getOrElse(0), equals(5));
    });

    test('getOrElse devrait retourner default pour failure', () {
      final failure = Result<int>.failure(const NetworkFailure());
      expect(failure.getOrElse(99), equals(99));
    });

    test('getOrElseGet devrait retourner la valeur pour success', () {
      final success = Result<int>.success(5);
      expect(success.getOrElseGet(() => 0), equals(5));
    });

    test('getOrElseGet devrait appeler function pour failure', () {
      final failure = Result<int>.failure(const NetworkFailure());
      expect(failure.getOrElseGet(() => 99), equals(99));
    });

    test('valueOrNull devrait retourner null pour failure', () {
      final success = Result<int>.success(5);
      final failure = Result<int>.failure(const NetworkFailure());

      expect(success.valueOrNull, equals(5));
      expect(failure.valueOrNull, isNull);
    });
  });

  group('Failures', () {
    test('NetworkFailure devrait avoir le bon code', () {
      const failure = NetworkFailure('No connection');
      expect(failure.code, equals('NETWORK_ERROR'));
      expect(failure.message, equals('No connection'));
    });

    test('AuthFailure devrait avoir le bon code', () {
      const failure = AuthFailure('Login failed');
      expect(failure.code, equals('AUTH_ERROR'));
      expect(failure.message, equals('Login failed'));
    });

    test('InvalidCredentialsFailure devrait avoir le bon message', () {
      const failure = InvalidCredentialsFailure();
      expect(failure.code, equals('INVALID_CREDENTIALS'));
      expect(failure.message, contains('mot de passe incorrect'));
    });

    test('UserNotFoundFailure devrait avoir le bon message', () {
      const failure = UserNotFoundFailure();
      expect(failure.code, equals('USER_NOT_FOUND'));
      expect(failure.message, contains('non trouvé'));
    });

    test('EmailAlreadyInUseFailure devrait avoir le bon message', () {
      const failure = EmailAlreadyInUseFailure();
      expect(failure.code, equals('EMAIL_IN_USE'));
      expect(failure.message, contains('déjà utilisé'));
    });

    test('WeakPasswordFailure devrait avoir le bon message', () {
      const failure = WeakPasswordFailure();
      expect(failure.code, equals('WEAK_PASSWORD'));
      expect(failure.message, contains('trop faible'));
    });

    test('ValidationFailure devrait avoir le bon code et message', () {
      const failure = ValidationFailure('Email invalide');
      expect(failure.code, equals('VALIDATION_ERROR'));
      expect(failure.message, equals('Email invalide'));
    });

    test('ServerFailure devrait avoir le bon code', () {
      const failure = ServerFailure('Server error');
      expect(failure.code, equals('SERVER_ERROR'));
      expect(failure.message, equals('Server error'));
    });

    test('TimeoutFailure devrait avoir le bon message', () {
      const failure = TimeoutFailure();
      expect(failure.code, equals('TIMEOUT'));
      expect(failure.message, contains('trop de temps'));
    });
  });

  group('Result Extensions', () {
    test('onSuccess devrait exécuter action pour success', () {
      final result = Result<int>.success(42);

      int? capturedValue;
      result.onSuccess((value) => capturedValue = value);

      expect(capturedValue, equals(42));
    });

    test('onSuccess ne devrait pas exécuter action pour failure', () {
      final result = Result<int>.failure(const NetworkFailure());

      int? capturedValue;
      result.onSuccess((value) => capturedValue = value);

      expect(capturedValue, isNull);
    });

    test('onFailure devrait exécuter action pour failure', () {
      final result = Result<int>.failure(const NetworkFailure('Error'));

      String? capturedMessage;
      result.onFailure((failure) => capturedMessage = failure.message);

      expect(capturedMessage, equals('Error'));
    });

    test('onFailure ne devrait pas exécuter action pour success', () {
      final result = Result<int>.success(42);

      String? capturedMessage;
      result.onFailure((failure) => capturedMessage = failure.message);

      expect(capturedMessage, isNull);
    });
  });
}
