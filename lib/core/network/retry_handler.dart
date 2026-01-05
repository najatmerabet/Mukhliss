/// ============================================================
/// MUKHLISS - Retry Handler avec Exponential Backoff
/// ============================================================
///
/// Gère les re-tentatives intelligentes avec backoff exponentiel.
/// 
/// Usage:
/// ```dart
/// final result = await RetryHandler.execute(
///   action: () => apiClient.getUsers(),
///   maxAttempts: 3,
/// );
/// ```
library;

import 'dart:async';
import 'dart:math';

import '../errors/failures.dart';
import '../logger/app_logger.dart';

/// Configuration pour le retry
class RetryConfig {
  /// Nombre maximum de tentatives
  final int maxAttempts;
  
  /// Délai initial entre les tentatives
  final Duration initialDelay;
  
  /// Facteur multiplicateur pour le backoff
  final double backoffMultiplier;
  
  /// Délai maximum entre les tentatives
  final Duration maxDelay;
  
  /// Ajoute du jitter (variation aléatoire) pour éviter la synchronisation
  final bool useJitter;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.useJitter = true,
  });

  /// Configuration par défaut
  static const standard = RetryConfig();

  /// Configuration agressive (plus de tentatives)
  static const aggressive = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 200),
  );

  /// Configuration légère (moins de tentatives)
  static const light = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 1000),
  );
}

/// Types d'erreurs qui peuvent être retryées
typedef RetryableChecker = bool Function(dynamic error);

/// Handler de retry avec exponential backoff
class RetryHandler {
  static final _random = Random();

  /// Exécute une action avec retry automatique
  static Future<T> execute<T>({
    required Future<T> Function() action,
    RetryConfig config = RetryConfig.standard,
    RetryableChecker? isRetryable,
    void Function(int attempt, dynamic error, Duration nextDelay)? onRetry,
  }) async {
    final retryableChecker = isRetryable ?? _defaultRetryableChecker;
    
    dynamic lastError;
    
    for (int attempt = 1; attempt <= config.maxAttempts; attempt++) {
      try {
        return await action();
      } catch (error) {
        lastError = error;
        
        // Vérifier si l'erreur peut être retryée
        if (!retryableChecker(error)) {
          AppLogger.warning('Non-retryable error on attempt $attempt: $error');
          rethrow;
        }
        
        // Si c'était la dernière tentative, relancer l'erreur
        if (attempt >= config.maxAttempts) {
          AppLogger.error('Max retry attempts reached ($attempt): $error');
          rethrow;
        }
        
        // Calculer le délai avec backoff exponentiel
        final delay = _calculateDelay(attempt, config);
        
        AppLogger.info(
          'Retry attempt $attempt/${config.maxAttempts} after ${delay.inMilliseconds}ms',
        );
        
        onRetry?.call(attempt, error, delay);
        
        await Future.delayed(delay);
      }
    }
    
    // Ne devrait jamais arriver, mais au cas où
    throw lastError ?? Exception('Retry failed');
  }

  /// Calcule le délai avec exponential backoff et jitter optionnel
  static Duration _calculateDelay(int attempt, RetryConfig config) {
    // Backoff exponentiel: delay = initialDelay * (multiplier ^ (attempt - 1))
    final exponentialDelay = config.initialDelay.inMilliseconds * 
        pow(config.backoffMultiplier, attempt - 1);
    
    var delayMs = exponentialDelay.toInt();
    
    // Appliquer le jitter (±25% de variation)
    if (config.useJitter) {
      final jitterFactor = 0.75 + (_random.nextDouble() * 0.5);
      delayMs = (delayMs * jitterFactor).toInt();
    }
    
    // Ne pas dépasser le max
    delayMs = min(delayMs, config.maxDelay.inMilliseconds);
    
    return Duration(milliseconds: delayMs);
  }

  /// Checker par défaut pour les erreurs retryables
  static bool _defaultRetryableChecker(dynamic error) {
    // Erreurs réseau - retryables
    if (error is NetworkFailure || error is TimeoutFailure) {
      return true;
    }
    
    // Erreurs serveur (5xx) - retryables
    if (error is ServerFailure) {
      return true;
    }
    
    // Vérifier le message d'erreur
    final errorString = error.toString().toLowerCase();
    
    // Erreurs de connexion - retryables
    final retryablePatterns = [
      'socketexception',
      'connection refused',
      'connection reset',
      'connection timed out',
      'no address associated',
      'host lookup',
      'network is unreachable',
      'temporary failure',
      '503', // Service Unavailable
      '502', // Bad Gateway
      '504', // Gateway Timeout
      '429', // Too Many Requests (mais avec plus de délai)
    ];
    
    for (final pattern in retryablePatterns) {
      if (errorString.contains(pattern)) {
        return true;
      }
    }
    
    // Par défaut, ne pas retry
    return false;
  }
}

/// Extension pour faciliter le retry sur les Futures
extension RetryExtension<T> on Future<T> Function() {
  /// Exécute avec retry
  Future<T> withRetry({
    RetryConfig config = RetryConfig.standard,
    RetryableChecker? isRetryable,
  }) {
    return RetryHandler.execute(
      action: this,
      config: config,
      isRetryable: isRetryable,
    );
  }
}
