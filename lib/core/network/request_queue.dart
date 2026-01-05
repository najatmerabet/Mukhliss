/// ============================================================
/// MUKHLISS - Request Queue
/// ============================================================
///
/// File d'attente pour gérer les requêtes de manière ordonnée.
/// Évite les surcharges en limitant les requêtes concurrentes.
///
/// Usage:
/// ```dart
/// final queue = RequestQueue(maxConcurrent: 3);
/// 
/// final result = await queue.add(() => apiCall());
/// ```
library;

import 'dart:async';
import 'dart:collection';

import '../logger/app_logger.dart';

/// Priorité des requêtes
enum RequestPriority {
  /// Requêtes critiques (auth, etc.)
  high,
  
  /// Requêtes normales
  normal,
  
  /// Requêtes de fond (prefetch, analytics, etc.)
  low,
}

/// Une requête dans la file d'attente
class _QueuedRequest<T> {
  final Future<T> Function() action;
  final Completer<T> completer;
  final RequestPriority priority;
  final DateTime createdAt;
  final String? tag;

  _QueuedRequest({
    required this.action,
    required this.completer,
    this.priority = RequestPriority.normal,
    this.tag,
  }) : createdAt = DateTime.now();
}

/// File d'attente pour les requêtes réseau
class RequestQueue {
  /// Nombre maximum de requêtes concurrentes
  final int maxConcurrent;
  
  /// Timeout pour chaque requête
  final Duration requestTimeout;
  
  /// Files d'attente par priorité
  final Queue<_QueuedRequest<dynamic>> _highQueue = Queue();
  final Queue<_QueuedRequest<dynamic>> _normalQueue = Queue();
  final Queue<_QueuedRequest<dynamic>> _lowQueue = Queue();
  
  /// Nombre de requêtes en cours
  int _runningCount = 0;
  
  /// Flag de pause
  bool _isPaused = false;

  RequestQueue({
    this.maxConcurrent = 4,
    this.requestTimeout = const Duration(seconds: 30),
  });

  /// Nombre de requêtes en attente
  int get pendingCount => _highQueue.length + _normalQueue.length + _lowQueue.length;

  /// Nombre de requêtes en cours
  int get runningCount => _runningCount;

  /// La queue est-elle en pause ?
  bool get isPaused => _isPaused;

  /// Ajoute une requête à la file
  Future<T> add<T>(
    Future<T> Function() action, {
    RequestPriority priority = RequestPriority.normal,
    String? tag,
  }) {
    final completer = Completer<T>();
    final request = _QueuedRequest<T>(
      action: action,
      completer: completer,
      priority: priority,
      tag: tag,
    );

    // Ajouter à la bonne file
    switch (priority) {
      case RequestPriority.high:
        _highQueue.add(request);
        break;
      case RequestPriority.normal:
        _normalQueue.add(request);
        break;
      case RequestPriority.low:
        _lowQueue.add(request);
        break;
    }

    AppLogger.debug('Request queued [${priority.name}]${tag != null ? ' ($tag)' : ''} - Pending: $pendingCount');

    // Démarrer le traitement
    _processQueue();

    return completer.future;
  }

  /// Traite la file d'attente
  void _processQueue() {
    if (_isPaused) return;

    while (_runningCount < maxConcurrent && _hasRequests()) {
      final request = _getNextRequest();
      if (request != null) {
        _executeRequest(request);
      }
    }
  }

  /// Vérifie s'il y a des requêtes en attente
  bool _hasRequests() {
    return _highQueue.isNotEmpty || 
           _normalQueue.isNotEmpty || 
           _lowQueue.isNotEmpty;
  }

  /// Récupère la prochaine requête (par priorité)
  _QueuedRequest<dynamic>? _getNextRequest() {
    if (_highQueue.isNotEmpty) {
      return _highQueue.removeFirst();
    }
    if (_normalQueue.isNotEmpty) {
      return _normalQueue.removeFirst();
    }
    if (_lowQueue.isNotEmpty) {
      return _lowQueue.removeFirst();
    }
    return null;
  }

  /// Exécute une requête
  void _executeRequest<T>(_QueuedRequest<T> request) {
    _runningCount++;

    AppLogger.debug('Executing request${request.tag != null ? ' (${request.tag})' : ''} - Running: $_runningCount');

    // Exécuter avec timeout
    request.action()
        .timeout(requestTimeout)
        .then((result) {
          if (!request.completer.isCompleted) {
            request.completer.complete(result);
          }
        })
        .catchError((error) {
          if (!request.completer.isCompleted) {
            request.completer.completeError(error);
          }
        })
        .whenComplete(() {
          _runningCount--;
          _processQueue();
        });
  }

  /// Met en pause la file
  void pause() {
    _isPaused = true;
    AppLogger.info('Request queue paused');
  }

  /// Reprend le traitement
  void resume() {
    _isPaused = false;
    AppLogger.info('Request queue resumed');
    _processQueue();
  }

  /// Annule les requêtes avec un tag spécifique
  void cancelByTag(String tag) {
    _cancelInQueue(_highQueue, tag);
    _cancelInQueue(_normalQueue, tag);
    _cancelInQueue(_lowQueue, tag);
  }

  void _cancelInQueue(Queue<_QueuedRequest<dynamic>> queue, String tag) {
    queue.removeWhere((request) {
      if (request.tag == tag) {
        if (!request.completer.isCompleted) {
          request.completer.completeError(
            Exception('Request cancelled: $tag'),
          );
        }
        return true;
      }
      return false;
    });
  }

  /// Annule toutes les requêtes en attente
  void cancelAll() {
    _cancelAllInQueue(_highQueue);
    _cancelAllInQueue(_normalQueue);
    _cancelAllInQueue(_lowQueue);
    AppLogger.info('All queued requests cancelled');
  }

  void _cancelAllInQueue(Queue<_QueuedRequest<dynamic>> queue) {
    for (final request in queue) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(
          Exception('Request cancelled'),
        );
      }
    }
    queue.clear();
  }

  /// Vide les requêtes de basse priorité
  void clearLowPriority() {
    _cancelAllInQueue(_lowQueue);
    AppLogger.debug('Low priority requests cleared');
  }
}

/// Instance globale pour les requêtes API
class GlobalRequestQueue {
  static RequestQueue? _instance;

  static RequestQueue get instance {
    _instance ??= RequestQueue(maxConcurrent: 4);
    return _instance!;
  }

  /// Configure l'instance globale
  static void configure({int? maxConcurrent, Duration? requestTimeout}) {
    _instance = RequestQueue(
      maxConcurrent: maxConcurrent ?? 4,
      requestTimeout: requestTimeout ?? const Duration(seconds: 30),
    );
  }
}
