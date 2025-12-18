/// ============================================================
/// Device Session Manager - Data Layer
/// ============================================================
///
/// Gestion des sessions d'appareils.
/// Extrait de device_management_service.dart pour respecter SRP.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gestionnaire des sessions d'appareils
class DeviceSessionManager {
  static const String _deviceIdKey = 'current_device_id';

  final SupabaseClient _supabase;
  String? _currentDeviceId;
  Timer? _activityTimer;

  DeviceSessionManager({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// ID de l'appareil actuel
  String? get currentDeviceId => _currentDeviceId;

  /// Charge le deviceId depuis le stockage local
  Future<String?> loadStoredDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentDeviceId = prefs.getString(_deviceIdKey);
      debugPrint('📱 DeviceId chargé: $_currentDeviceId');
      return _currentDeviceId;
    } catch (e) {
      debugPrint('❌ Erreur chargement deviceId: $e');
      return null;
    }
  }

  /// Sauvegarde le deviceId dans le stockage local
  Future<bool> saveDeviceId(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deviceIdKey, deviceId);
      _currentDeviceId = deviceId;
      debugPrint('💾 DeviceId sauvegardé: $deviceId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde deviceId: $e');
      return false;
    }
  }

  /// Efface le deviceId stocké
  Future<void> clearStoredDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deviceIdKey);
      _currentDeviceId = null;
      debugPrint('🗑️ DeviceId effacé');
    } catch (e) {
      debugPrint('❌ Erreur effacement deviceId: $e');
    }
  }

  /// Valide que le deviceId existe dans la base
  Future<bool> validateDeviceId(String deviceId) async {
    try {
      final response =
          await _supabase
              .from('user_devices')
              .select('id')
              .eq('device_id', deviceId)
              .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('❌ Erreur validation deviceId: $e');
      return false;
    }
  }

  /// Crée une session pour l'appareil
  Future<void> createSession(String deviceId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('device_sessions').upsert({
        'device_id': deviceId,
        'user_id': userId,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
      }, onConflict: 'device_id');

      debugPrint('✅ Session créée pour: $deviceId');
    } catch (e) {
      debugPrint('❌ Erreur création session: $e');
    }
  }

  /// Met à jour l'activité de la session
  Future<void> updateSessionActivity() async {
    if (_currentDeviceId == null) return;

    try {
      await _supabase
          .from('device_sessions')
          .update({'last_activity': DateTime.now().toIso8601String()})
          .eq('device_id', _currentDeviceId!);
    } catch (e) {
      debugPrint('❌ Erreur mise à jour activité: $e');
    }
  }

  /// Démarre le timer de mise à jour d'activité
  void startActivityUpdater({Duration interval = const Duration(minutes: 5)}) {
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(interval, (_) {
      updateSessionActivity();
    });
    debugPrint(
      '⏰ Activity updater démarré (intervalle: ${interval.inMinutes} min)',
    );
  }

  /// Arrête le timer d'activité
  void stopActivityUpdater() {
    _activityTimer?.cancel();
    _activityTimer = null;
    debugPrint('⏹️ Activity updater arrêté');
  }

  /// Termine la session actuelle
  Future<void> endSession() async {
    if (_currentDeviceId == null) return;

    try {
      await _supabase
          .from('device_sessions')
          .update({'is_active': false})
          .eq('device_id', _currentDeviceId!);

      await clearStoredDeviceId();
      debugPrint('👋 Session terminée');
    } catch (e) {
      debugPrint('❌ Erreur fin session: $e');
    }
  }

  /// Vérifie si l'appareil actuel est en session active
  bool isCurrentDevice(String deviceId) {
    return _currentDeviceId == deviceId;
  }

  /// Nettoie les ressources
  void dispose() {
    stopActivityUpdater();
    _currentDeviceId = null;
  }
}
