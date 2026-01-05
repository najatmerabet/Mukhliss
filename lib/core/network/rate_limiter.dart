/// ============================================================
/// MUKHLISS - Rate Limiter
/// ============================================================
///
/// Limite le nombre de requêtes pour éviter de surcharger le serveur.
/// 
/// Usage:
/// ```dart
/// final limiter = RateLimiter(maxRequests: 10, perDuration: Duration(seconds: 1));
/// 
/// if (await limiter.tryAcquire()) {
///   // Faire la requête
/// } else {
///   // Trop de requêtes, attendre
/// }
/// ```
library;

import 'dart:async';
import 'dart:collection';

/// Rate Limiter avec algorithme Token Bucket
class RateLimiter {
  /// Nombre maximum de requêtes autorisées
  final int maxRequests;
  
  /// Période pendant laquelle les requêtes sont comptées
  final Duration perDuration;
  
  /// File des timestamps des requêtes
  final Queue<DateTime> _requestTimestamps = Queue<DateTime>();
  
  /// Lock pour éviter les conditions de course
  final _lock = _AsyncLock();

  RateLimiter({
    this.maxRequests = 30,
    this.perDuration = const Duration(seconds: 1),
  });

  /// Tente d'acquérir un slot de requête
  /// Retourne true si autorisé, false sinon
  Future<bool> tryAcquire() async {
    return _lock.synchronized(() async {
      _cleanOldRequests();
      
      if (_requestTimestamps.length < maxRequests) {
        _requestTimestamps.add(DateTime.now());
        return true;
      }
      
      return false;
    });
  }

  /// Acquiert un slot, attend si nécessaire
  Future<void> acquire() async {
    while (!await tryAcquire()) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Temps d'attente estimé avant le prochain slot disponible
  Duration? get waitTime {
    _cleanOldRequests();
    
    if (_requestTimestamps.length < maxRequests) {
      return Duration.zero;
    }
    
    final oldestRequest = _requestTimestamps.first;
    final waitUntil = oldestRequest.add(perDuration);
    final now = DateTime.now();
    
    if (waitUntil.isAfter(now)) {
      return waitUntil.difference(now);
    }
    
    return Duration.zero;
  }

  /// Nettoie les requêtes expirées
  void _cleanOldRequests() {
    final cutoff = DateTime.now().subtract(perDuration);
    
    while (_requestTimestamps.isNotEmpty && 
           _requestTimestamps.first.isBefore(cutoff)) {
      _requestTimestamps.removeFirst();
    }
  }

  /// Réinitialise le compteur
  void reset() {
    _requestTimestamps.clear();
  }

  /// Nombre de requêtes disponibles
  int get availableRequests {
    _cleanOldRequests();
    return maxRequests - _requestTimestamps.length;
  }
}

/// Rate Limiter par endpoint spécifique
class EndpointRateLimiter {
  final Map<String, RateLimiter> _limiters = {};
  final int defaultMaxRequests;
  final Duration defaultDuration;

  EndpointRateLimiter({
    this.defaultMaxRequests = 30,
    this.defaultDuration = const Duration(seconds: 1),
  });

  /// Obtient ou crée un rate limiter pour un endpoint
  RateLimiter forEndpoint(String endpoint, {int? maxRequests, Duration? duration}) {
    return _limiters.putIfAbsent(
      endpoint,
      () => RateLimiter(
        maxRequests: maxRequests ?? defaultMaxRequests,
        perDuration: duration ?? defaultDuration,
      ),
    );
  }

  /// Tente d'acquérir pour un endpoint
  Future<bool> tryAcquire(String endpoint) async {
    return forEndpoint(endpoint).tryAcquire();
  }

  /// Acquiert pour un endpoint, attend si nécessaire
  Future<void> acquire(String endpoint) async {
    await forEndpoint(endpoint).acquire();
  }

  /// Réinitialise tous les limiters
  void resetAll() {
    for (final limiter in _limiters.values) {
      limiter.reset();
    }
  }
}

/// Lock asynchrone simple
class _AsyncLock {
  Completer<void>? _completer;

  Future<T> synchronized<T>(Future<T> Function() action) async {
    while (_completer != null) {
      await _completer!.future;
    }
    
    _completer = Completer<void>();
    
    try {
      return await action();
    } finally {
      final completer = _completer;
      _completer = null;
      completer?.complete();
    }
  }
}
