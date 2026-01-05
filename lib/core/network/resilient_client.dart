/// ============================================================
/// MUKHLISS - Resilient API Client
/// ============================================================
///
/// Client API résilient qui combine:
/// - Rate Limiting
/// - Circuit Breaker
/// - Retry avec Exponential Backoff
/// - Request Queue
///
/// Ce client enveloppe les appels existants sans les modifier.
///
/// Usage:
/// ```dart
/// final resilientClient = ResilientClient();
/// 
/// // Au lieu de: await supabase.from('users').select()
/// final result = await resilientClient.execute(
///   name: 'get-users',
///   action: () => supabase.from('users').select(),
/// );
/// ```
library;

import 'dart:async';

import '../errors/failures.dart';
import '../errors/result.dart';
import '../logger/app_logger.dart';
import 'circuit_breaker.dart';
import 'rate_limiter.dart';
import 'request_queue.dart';
import 'retry_handler.dart';

/// Configuration du client résilient
class ResilientClientConfig {
  /// Activer le rate limiting
  final bool enableRateLimit;
  
  /// Activer le circuit breaker
  final bool enableCircuitBreaker;
  
  /// Activer le retry automatique
  final bool enableRetry;
  
  /// Activer la file d'attente
  final bool enableQueue;
  
  /// Configuration du rate limiter
  final int maxRequestsPerSecond;
  
  /// Configuration du circuit breaker
  final CircuitBreakerConfig circuitBreakerConfig;
  
  /// Configuration du retry
  final RetryConfig retryConfig;
  
  /// Nombre max de requêtes concurrentes
  final int maxConcurrent;

  const ResilientClientConfig({
    this.enableRateLimit = true,
    this.enableCircuitBreaker = true,
    this.enableRetry = true,
    this.enableQueue = true,
    this.maxRequestsPerSecond = 30,
    this.circuitBreakerConfig = CircuitBreakerConfig.standard,
    this.retryConfig = RetryConfig.standard,
    this.maxConcurrent = 4,
  });

  /// Configuration par défaut
  static const standard = ResilientClientConfig();

  /// Configuration minimale (juste retry)
  static const minimal = ResilientClientConfig(
    enableRateLimit: false,
    enableCircuitBreaker: false,
    enableQueue: false,
  );

  /// Configuration stricte (toutes protections actives)
  static const strict = ResilientClientConfig(
    maxRequestsPerSecond: 20,
    circuitBreakerConfig: CircuitBreakerConfig.sensitive,
    retryConfig: RetryConfig.aggressive,
    maxConcurrent: 2,
  );
}

/// Client API résilient
class ResilientClient {
  final ResilientClientConfig config;
  
  late final RateLimiter _rateLimiter;
  late final CircuitBreaker _circuitBreaker;
  late final RequestQueue _requestQueue;

  ResilientClient({
    this.config = ResilientClientConfig.standard,
    String circuitName = 'default',
  }) {
    _rateLimiter = RateLimiter(
      maxRequests: config.maxRequestsPerSecond,
      perDuration: const Duration(seconds: 1),
    );
    
    _circuitBreaker = CircuitBreaker(
      name: circuitName,
      config: config.circuitBreakerConfig,
    );
    
    _requestQueue = RequestQueue(
      maxConcurrent: config.maxConcurrent,
    );
  }

  /// Exécute une action avec toutes les protections
  Future<Result<T>> execute<T>({
    required String name,
    required Future<T> Function() action,
    RequestPriority priority = RequestPriority.normal,
    bool? enableRetry,
    bool? enableRateLimit,
    bool? enableCircuitBreaker,
  }) async {
    final shouldRetry = enableRetry ?? config.enableRetry;
    final shouldRateLimit = enableRateLimit ?? config.enableRateLimit;
    final shouldCircuitBreak = enableCircuitBreaker ?? config.enableCircuitBreaker;

    try {
      // 1. Vérifier le circuit breaker
      if (shouldCircuitBreak && _circuitBreaker.isOpen) {
        AppLogger.warning('Circuit breaker is open for: $name');
        return Result.failure(
          ServerFailure('Service temporairement indisponible'),
        );
      }

      // 2. Rate limiting
      if (shouldRateLimit) {
        await _rateLimiter.acquire();
      }

      // 3. File d'attente si activée
      Future<T> executeAction() async {
        if (config.enableQueue) {
          return _requestQueue.add(
            () => _executeWithRetry(action, shouldRetry, shouldCircuitBreak),
            priority: priority,
            tag: name,
          );
        } else {
          return _executeWithRetry(action, shouldRetry, shouldCircuitBreak);
        }
      }

      final result = await executeAction();
      return Result.success(result);
      
    } on CircuitOpenException catch (e) {
      AppLogger.error('Circuit breaker open: $e');
      return Result.failure(
        ServerFailure('Service temporairement indisponible. Réessayez dans quelques instants.'),
      );
      
    } catch (error) {
      AppLogger.error('Resilient client error for $name: $error');
      return Result.failure(_mapError(error));
    }
  }

  /// Exécute avec retry et circuit breaker
  Future<T> _executeWithRetry<T>(
    Future<T> Function() action,
    bool shouldRetry,
    bool shouldCircuitBreak,
  ) async {
    Future<T> wrappedAction() async {
      if (shouldCircuitBreak) {
        return _circuitBreaker.execute(action);
      }
      return action();
    }

    if (shouldRetry) {
      return RetryHandler.execute(
        action: wrappedAction,
        config: config.retryConfig,
      );
    }
    
    return wrappedAction();
  }

  /// Mappe les erreurs en Failure
  Failure _mapError(dynamic error) {
    if (error is Failure) return error;
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socket') || 
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return const NetworkFailure();
    }
    
    if (errorString.contains('timeout')) {
      return const TimeoutFailure();
    }
    
    return UnknownFailure(error.toString());
  }

  /// Pause la file d'attente
  void pause() => _requestQueue.pause();

  /// Reprend la file d'attente
  void resume() => _requestQueue.resume();

  /// Reset le circuit breaker
  void resetCircuit() => _circuitBreaker.reset();

  /// Statistiques actuelles
  Map<String, dynamic> get stats => {
    'circuitState': _circuitBreaker.state.name,
    'availableRequests': _rateLimiter.availableRequests,
    'pendingRequests': _requestQueue.pendingCount,
    'runningRequests': _requestQueue.runningCount,
    'isPaused': _requestQueue.isPaused,
  };
}

/// Instance globale du client résilient
class GlobalResilientClient {
  static ResilientClient? _instance;

  static ResilientClient get instance {
    _instance ??= ResilientClient(circuitName: 'supabase');
    return _instance!;
  }

  /// Configure l'instance globale
  static void configure(ResilientClientConfig config) {
    _instance = ResilientClient(
      config: config,
      circuitName: 'supabase',
    );
  }

  /// Raccourci pour exécuter une action
  static Future<Result<T>> execute<T>({
    required String name,
    required Future<T> Function() action,
    RequestPriority priority = RequestPriority.normal,
  }) {
    return instance.execute(
      name: name,
      action: action,
      priority: priority,
    );
  }
}
