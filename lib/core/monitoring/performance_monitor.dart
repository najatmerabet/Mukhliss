/// ============================================================
/// Performance Monitor - Widget de Monitoring en Temps Réel
/// ============================================================
/// 
/// Affiche les métriques de performance en temps réel sur l'écran
/// pour détecter les problèmes AVANT qu'ils n'arrivent en production.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Statistiques de performance collectées
class AppPerformanceStats {
  final int frameCount;
  final double fps;
  final int memoryUsageMB;
  final int activeRequests;
  final double avgResponseTimeMs;
  final int errorCount;
  final int cacheHits;
  final int cacheMisses;
  final DateTime timestamp;

  const AppPerformanceStats({
    required this.frameCount,
    required this.fps,
    required this.memoryUsageMB,
    required this.activeRequests,
    required this.avgResponseTimeMs,
    required this.errorCount,
    required this.cacheHits,
    required this.cacheMisses,
    required this.timestamp,
  });

  double get cacheHitRate => 
      (cacheHits + cacheMisses) > 0 
          ? cacheHits / (cacheHits + cacheMisses) * 100 
          : 0;

  String get healthStatus {
    if (fps < 30 || avgResponseTimeMs > 1000 || errorCount > 10) {
      return '🔴 CRITIQUE';
    } else if (fps < 50 || avgResponseTimeMs > 500 || errorCount > 5) {
      return '🟡 ATTENTION';
    }
    return '🟢 OK';
  }
}

/// Provider pour le monitoring des performances
final performanceMonitorProvider = StateNotifierProvider<PerformanceMonitorNotifier, AppPerformanceStats?>((ref) {
  return PerformanceMonitorNotifier();
});

/// Notifier qui collecte les métriques
class PerformanceMonitorNotifier extends StateNotifier<AppPerformanceStats?> {
  Timer? _timer;
  int _frameCount = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _errorCount = 0;
  final List<double> _responseTimes = [];
  DateTime _lastUpdate = DateTime.now();

  PerformanceMonitorNotifier() : super(null);

  /// Démarrer le monitoring
  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStats();
    });
  }

  /// Arrêter le monitoring
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  /// Enregistrer un frame rendu
  void recordFrame() {
    _frameCount++;
  }

  /// Enregistrer un temps de réponse
  void recordResponseTime(double ms) {
    _responseTimes.add(ms);
    if (_responseTimes.length > 100) {
      _responseTimes.removeAt(0);
    }
  }

  /// Enregistrer un hit cache
  void recordCacheHit() => _cacheHits++;

  /// Enregistrer un miss cache
  void recordCacheMiss() => _cacheMisses++;

  /// Enregistrer une erreur
  void recordError() => _errorCount++;

  void _updateStats() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastUpdate).inMilliseconds;
    
    final fps = elapsed > 0 ? (_frameCount / elapsed * 1000) : 0.0;
    final avgResponseTime = _responseTimes.isNotEmpty
        ? _responseTimes.reduce((a, b) => a + b) / _responseTimes.length
        : 0.0;

    state = AppPerformanceStats(
      frameCount: _frameCount,
      fps: fps.clamp(0, 120),
      memoryUsageMB: _estimateMemoryUsage(),
      activeRequests: 0, // À implémenter selon vos besoins
      avgResponseTimeMs: avgResponseTime,
      errorCount: _errorCount,
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      timestamp: now,
    );

    _frameCount = 0;
    _lastUpdate = now;
  }

  int _estimateMemoryUsage() {
    // Estimation basée sur les objets en cache
    // En production, utilisez dart:developer pour des métriques précises
    return 50 + (_cacheHits + _cacheMisses) ~/ 10; // Approximation
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Widget qui affiche les performances en overlay
class PerformanceOverlay extends ConsumerWidget {
  final bool show;
  final Widget child;

  const PerformanceOverlay({
    super.key,
    this.show = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return child;

    final stats = ref.watch(performanceMonitorProvider);

    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 10,
          child: _buildStatsPanel(stats),
        ),
      ],
    );
  }

  Widget _buildStatsPanel(AppPerformanceStats? stats) {
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '📊 PERFORMANCE ${stats.healthStatus}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetric('FPS', '${stats.fps.toStringAsFixed(0)}', 
              stats.fps >= 50 ? Colors.green : Colors.orange),
          _buildMetric('Latence', '${stats.avgResponseTimeMs.toStringAsFixed(0)}ms',
              stats.avgResponseTimeMs <= 200 ? Colors.green : Colors.orange),
          _buildMetric('Cache Hit', '${stats.cacheHitRate.toStringAsFixed(0)}%',
              stats.cacheHitRate >= 70 ? Colors.green : Colors.orange),
          _buildMetric('Erreurs', '${stats.errorCount}',
              stats.errorCount == 0 ? Colors.green : Colors.red),
          _buildMetric('Mémoire', '~${stats.memoryUsageMB}MB', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// SEUILS D'ALERTE - Quand s'inquiéter
/// ============================================================
/// 
/// 🟢 OK:
///    - FPS > 50
///    - Latence < 200ms
///    - Cache Hit > 70%
///    - Erreurs = 0
/// 
/// 🟡 ATTENTION:
///    - FPS entre 30-50
///    - Latence entre 200-500ms
///    - Cache Hit entre 50-70%
///    - Erreurs < 5
/// 
/// 🔴 CRITIQUE:
///    - FPS < 30
///    - Latence > 500ms
///    - Cache Hit < 50%
///    - Erreurs > 5
/// 
/// Actions si CRITIQUE:
///    1. Réduire le nombre d'éléments affichés
///    2. Augmenter le cache
///    3. Optimiser les requêtes
///    4. Upgrader le serveur
