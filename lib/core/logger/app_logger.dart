/// ============================================================
/// MUKHLISS - Logger Centralisé
/// ============================================================
///
/// Utiliser ceci au lieu de print() ou debugPrint().
///
/// EXEMPLE:
/// ```dart
/// AppLogger.info('Utilisateur connecté', tag: 'Auth');
/// AppLogger.error('Échec login', tag: 'Auth', error: e);
/// ```
library;

import 'package:flutter/foundation.dart';

/// Niveaux de log
enum LogLevel {
  debug, // Pour le développement
  info, // Informations générales
  warning, // Attention requise
  error, // Erreurs
}

/// Logger centralisé pour l'application Mukhliss
class AppLogger {
  // Configuration
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  static bool _enabled = true;
  static const String _prefix = '🔷 MUKHLISS';

  /// Active/désactive le logging
  static void setEnabled(bool enabled) => _enabled = enabled;

  /// Change le niveau minimum de log
  static void setMinLevel(LogLevel level) => _minLevel = level;

  // ============================================================
  // MÉTHODES DE LOG
  // ============================================================

  /// Log de niveau DEBUG (développement uniquement)
  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// Log de niveau INFO
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// Log de niveau WARNING
  static void warning(String message, {String? tag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  /// Log de niveau ERROR
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ============================================================
  // LOGS SPÉCIFIQUES PAR DOMAINE
  // ============================================================

  /// Log pour l'authentification
  static void auth(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
  }) {
    _log(level, message, tag: 'Auth', error: error);
  }

  /// Log pour le réseau
  static void network(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
  }) {
    _log(level, message, tag: 'Network', error: error);
  }

  /// Log pour la navigation
  static void navigation(String message) {
    _log(LogLevel.debug, message, tag: 'Navigation');
  }

  /// Log pour les providers/state
  static void state(String message, {LogLevel level = LogLevel.debug}) {
    _log(level, message, tag: 'State');
  }

  // ============================================================
  // MÉTHODE INTERNE
  // ============================================================

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final icon = _getIcon(level);
    final tagStr = tag != null ? '[$tag] ' : '';

    final logMessage = '$icon $timestamp $_prefix $tagStr$message';

    debugPrint(logMessage);

    if (error != null) {
      debugPrint('   └─ Error: $error');
    }
    if (stackTrace != null && level == LogLevel.error) {
      final lines = stackTrace.toString().split('\n').take(5);
      for (final line in lines) {
        debugPrint('   │ $line');
      }
    }
  }

  static String _getIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return '📘';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
}
