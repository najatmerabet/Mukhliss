/// ============================================================
/// MUKHLISS - Système de Gestion des Erreurs
/// ============================================================
///
/// Ce fichier définit toutes les erreurs possibles de l'application.
/// Utiliser ces classes au lieu de `throw Exception()`.
library;

import 'package:flutter/foundation.dart';

/// Classe de base pour toutes les erreurs de l'application
@immutable
abstract class Failure {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure({required this.message, this.code, this.originalError});

  @override
  String toString() =>
      'Failure: $message${code != null ? ' (code: $code)' : ''}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);
}

// ============================================================
// ERREURS RÉSEAU
// ============================================================

/// Erreur de connexion réseau
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Pas de connexion internet'])
    : super(message: message, code: 'NETWORK_ERROR');
}

/// Timeout de la requête
class TimeoutFailure extends Failure {
  const TimeoutFailure([String message = 'La requête a pris trop de temps'])
    : super(message: message, code: 'TIMEOUT');
}

// ============================================================
// ERREURS D'AUTHENTIFICATION
// ============================================================

/// Erreur d'authentification générale
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Erreur d\'authentification'])
    : super(message: message, code: 'AUTH_ERROR');
}

/// Email ou mot de passe incorrect
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([
    String message = 'Email ou mot de passe incorrect',
  ]) : super(message: message, code: 'INVALID_CREDENTIALS');
}

/// Utilisateur non trouvé
class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure([String message = 'Utilisateur non trouvé'])
    : super(message: message, code: 'USER_NOT_FOUND');
}

/// Email déjà utilisé
class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure([
    String message = 'Cet email est déjà utilisé',
  ]) : super(message: message, code: 'EMAIL_IN_USE');
}

/// Mot de passe trop faible
class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure([
    String message = 'Le mot de passe est trop faible',
  ]) : super(message: message, code: 'WEAK_PASSWORD');
}

/// Session expirée
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([String message = 'Votre session a expiré'])
    : super(message: message, code: 'SESSION_EXPIRED');
}

// ============================================================
// ERREURS SERVEUR
// ============================================================

/// Erreur serveur générale
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Erreur serveur'])
    : super(message: message, code: 'SERVER_ERROR');
}

/// Ressource non trouvée (404)
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Ressource non trouvée'])
    : super(message: message, code: 'NOT_FOUND');
}

/// Non autorisé (403)
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Action non autorisée'])
    : super(message: message, code: 'UNAUTHORIZED');
}

// ============================================================
// ERREURS DE VALIDATION
// ============================================================

/// Données invalides
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Données invalides'])
    : super(message: message, code: 'VALIDATION_ERROR');
}

// ============================================================
// ERREURS DE CACHE/STOCKAGE
// ============================================================

/// Erreur de cache
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Erreur de cache'])
    : super(message: message, code: 'CACHE_ERROR');
}

// ============================================================
// ERREUR INCONNUE
// ============================================================

/// Erreur inattendue
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Une erreur inattendue est survenue'])
    : super(message: message, code: 'UNKNOWN');
}
