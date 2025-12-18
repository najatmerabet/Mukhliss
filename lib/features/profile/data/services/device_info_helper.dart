/// ============================================================
/// Device Info Helper - Data Layer
/// ============================================================
///
/// Service utilitaire pour récupérer les informations de l'appareil.
/// Extrait de device_management_service.dart pour respecter SRP.
library;

import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service pour récupérer les informations de l'appareil
class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Génère un ID unique pour l'appareil
  static Future<String> generateDeviceId() async {
    try {
      if (kIsWeb) {
        return _generateWebDeviceId();
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? _generateFallbackDeviceId();
      }
      return _generateFallbackDeviceId();
    } catch (e) {
      debugPrint('Erreur génération device ID: $e');
      return _generateFallbackDeviceId();
    }
  }

  /// Génère un ID de secours
  static String _generateFallbackDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Génère un ID pour le web
  static String _generateWebDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return 'web_${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  /// Récupère les informations de l'appareil
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        return {'model': 'Web Browser', 'manufacturer': 'Unknown'};
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'model': iosInfo.model,
          'manufacturer': 'Apple',
          'version': iosInfo.systemVersion,
          'name': iosInfo.name,
        };
      }
      return {'model': 'Unknown', 'manufacturer': 'Unknown'};
    } catch (e) {
      debugPrint('Erreur récupération device info: $e');
      return {'model': 'Unknown', 'manufacturer': 'Unknown'};
    }
  }

  /// Récupère la version de l'application
  static Future<String> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Détermine le type d'appareil
  static String getDeviceType() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Récupère la plateforme
  static String getPlatform() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Génère un nom d'appareil par défaut
  static Future<String> getDefaultDeviceName() async {
    try {
      if (kIsWeb) {
        return 'Navigateur Web';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.name;
      }
      return 'Appareil ${getDeviceType()}';
    } catch (e) {
      return 'Appareil inconnu';
    }
  }
}
