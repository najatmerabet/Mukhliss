/// ============================================================
/// MUKHLISS - Circuit Breaker Pattern
/// ============================================================
///
/// Protège l'application quand le serveur est surchargé ou en panne.
/// Évite d'envoyer des requêtes inutiles à un service défaillant.
///
/// États:
/// - CLOSED: Normal, les requêtes passent
/// - OPEN: Bloqué, les requêtes échouent immédiatement
/// - HALF_OPEN: Test, une requête passe pour vérifier
///
/// Usage:
/// ```dart
/// final breaker = CircuitBreaker(name: 'supabase-api');
/// 
/// try {
///   final result = await breaker.execute(() => apiCall());
/// } on CircuitOpenException {
///   // Le circuit est ouvert, service indisponible
/// }
/// ```
library;

import 'dart:async';

import '../logger/app_logger.dart';

/// États du circuit breaker
enum CircuitState {
  /// Circuit fermé - les requêtes passent normalement
  closed,
  
  /// Circuit ouvert - les requêtes échouent immédiatement
  open,
  
  /// Circuit semi-ouvert - test de récupération
  halfOpen,
}

/// Exception levée quand le circuit est ouvert
class CircuitOpenException implements Exception {
  final String circuitName;
  final DateTime? nextRetryTime;

  CircuitOpenException(this.circuitName, [this.nextRetryTime]);

  @override
  String toString() {
    if (nextRetryTime != null) {
      final waitTime = nextRetryTime!.difference(DateTime.now());
      return 'Circuit "$circuitName" is open. Retry in ${waitTime.inSeconds}s';
    }
    return 'Circuit "$circuitName" is open';
  }
}

/// Configuration du circuit breaker
class CircuitBreakerConfig {
  /// Nombre d'échecs avant d'ouvrir le circuit
  final int failureThreshold;
  
  /// Nombre de succès pour fermer le circuit (en half-open)
  final int successThreshold;
  
  /// Durée pendant laquelle le circuit reste ouvert
  final Duration openDuration;
  
  /// Fenêtre de temps pour compter les échecs
  final Duration failureWindow;

  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.successThreshold = 2,
    this.openDuration = const Duration(seconds: 30),
    this.failureWindow = const Duration(minutes: 1),
  });

  static const standard = CircuitBreakerConfig();
  
  static const sensitive = CircuitBreakerConfig(
    failureThreshold: 3,
    openDuration: Duration(seconds: 60),
  );
  
  static const resilient = CircuitBreakerConfig(
    failureThreshold: 10,
    openDuration: Duration(seconds: 15),
  );
}

/// Circuit Breaker pour protéger les appels réseau
class CircuitBreaker {
  /// Nom du circuit (pour le logging)
  final String name;
  
  /// Configuration
  final CircuitBreakerConfig config;
  
  /// État actuel
  CircuitState _state = CircuitState.closed;
  
  /// Timestamp des échecs récents
  final List<DateTime> _failures = [];
  
  /// Compteur de succès en half-open
  int _halfOpenSuccesses = 0;
  
  /// Moment où le circuit a été ouvert
  DateTime? _openedAt;
  
  /// Callbacks optionnels
  final void Function(CircuitState oldState, CircuitState newState)? onStateChange;

  CircuitBreaker({
    required this.name,
    this.config = CircuitBreakerConfig.standard,
    this.onStateChange,
  });

  /// État actuel du circuit
  CircuitState get state => _state;

  /// Le circuit est-il fermé (opérationnel) ?
  bool get isClosed => _state == CircuitState.closed;

  /// Le circuit est-il ouvert (bloqué) ?
  bool get isOpen => _state == CircuitState.open;

  /// Exécute une action à travers le circuit breaker
  Future<T> execute<T>(Future<T> Function() action) async {
    // Vérifier si on peut exécuter
    if (!_canExecute()) {
      throw CircuitOpenException(name, _getNextRetryTime());
    }
    
    try {
      final result = await action();
      _recordSuccess();
      return result;
    } catch (error) {
      _recordFailure();
      rethrow;
    }
  }

  /// Vérifie si une exécution est possible
  bool _canExecute() {
    switch (_state) {
      case CircuitState.closed:
        return true;
        
      case CircuitState.open:
        // Vérifier si on peut passer en half-open
        if (_shouldTransitionToHalfOpen()) {
          _transitionTo(CircuitState.halfOpen);
          return true;
        }
        return false;
        
      case CircuitState.halfOpen:
        return true;
    }
  }

  /// Enregistre un succès
  void _recordSuccess() {
    switch (_state) {
      case CircuitState.closed:
        // Rien à faire
        break;
        
      case CircuitState.halfOpen:
        _halfOpenSuccesses++;
        if (_halfOpenSuccesses >= config.successThreshold) {
          _transitionTo(CircuitState.closed);
        }
        break;
        
      case CircuitState.open:
        // Ne devrait pas arriver
        break;
    }
  }

  /// Enregistre un échec
  void _recordFailure() {
    final now = DateTime.now();
    _failures.add(now);
    
    // Nettoyer les vieux échecs
    _cleanOldFailures();
    
    switch (_state) {
      case CircuitState.closed:
        if (_failures.length >= config.failureThreshold) {
          _transitionTo(CircuitState.open);
        }
        break;
        
      case CircuitState.halfOpen:
        // Un échec en half-open réouvre le circuit
        _transitionTo(CircuitState.open);
        break;
        
      case CircuitState.open:
        // Déjà ouvert
        break;
    }
  }

  /// Vérifie si on peut passer de open à half-open
  bool _shouldTransitionToHalfOpen() {
    if (_openedAt == null) return true;
    
    final elapsed = DateTime.now().difference(_openedAt!);
    return elapsed >= config.openDuration;
  }

  /// Prochain moment où on peut réessayer
  DateTime? _getNextRetryTime() {
    if (_openedAt == null) return null;
    return _openedAt!.add(config.openDuration);
  }

  /// Transition vers un nouvel état
  void _transitionTo(CircuitState newState) {
    if (_state == newState) return;
    
    final oldState = _state;
    _state = newState;
    
    AppLogger.info('Circuit "$name": $oldState → $newState');
    
    switch (newState) {
      case CircuitState.open:
        _openedAt = DateTime.now();
        _halfOpenSuccesses = 0;
        break;
        
      case CircuitState.closed:
        _failures.clear();
        _openedAt = null;
        _halfOpenSuccesses = 0;
        break;
        
      case CircuitState.halfOpen:
        _halfOpenSuccesses = 0;
        break;
    }
    
    onStateChange?.call(oldState, newState);
  }

  /// Nettoie les échecs en dehors de la fenêtre
  void _cleanOldFailures() {
    final cutoff = DateTime.now().subtract(config.failureWindow);
    _failures.removeWhere((timestamp) => timestamp.isBefore(cutoff));
  }

  /// Reset manuel du circuit
  void reset() {
    _transitionTo(CircuitState.closed);
  }

  /// Force l'ouverture du circuit (maintenance, etc.)
  void forceOpen() {
    _transitionTo(CircuitState.open);
  }
}

/// Gestionnaire global des circuit breakers
class CircuitBreakerManager {
  static final Map<String, CircuitBreaker> _breakers = {};

  /// Obtient ou crée un circuit breaker
  static CircuitBreaker get(String name, {CircuitBreakerConfig? config}) {
    return _breakers.putIfAbsent(
      name,
      () => CircuitBreaker(
        name: name,
        config: config ?? CircuitBreakerConfig.standard,
      ),
    );
  }

  /// Liste tous les circuits
  static Map<String, CircuitState> get allStates {
    return _breakers.map((name, breaker) => MapEntry(name, breaker.state));
  }

  /// Reset tous les circuits
  static void resetAll() {
    for (final breaker in _breakers.values) {
      breaker.reset();
    }
  }
}
