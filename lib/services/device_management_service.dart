import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_device.dart';

class DeviceManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();
  
  DeviceManagementService._();
  static final DeviceManagementService _i = DeviceManagementService._();
  factory DeviceManagementService() => _i;
  
  // Session management
  String? _currentSessionToken;
  Timer? _sessionCheckTimer;
  String? _currentDeviceId;
  String? get currentDeviceId => _currentDeviceId;

  // Real-time subscriptions
  RealtimeChannel? _deviceChannel;
  RealtimeChannel? _sessionChannel;
  bool _isMonitoringInitialized = false; // ✅ Nouveau flag
  
  // Callbacks for UI updates
  Function()? onForceLogout;
  Function(String deviceId, String deviceName)? onRemoteDisconnect;

  // ✅ Déduplication des notifications
  final Set<String> _notifiedDisconnections = {};
  Timer? _cleanupTimer;

  // ============= PUBLIC METHODS =============

  /// Initialize real-time monitoring for the current device
  Future<void> initializeRealtimeMonitoring() async {
    // ✅ Éviter les initialisations multiples
    if (_isMonitoringInitialized) {
      debugPrint('🔹 [DeviceService] Monitoring déjà initialisé, ignoré');
      return;
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ [DeviceService] Utilisateur non connecté pour monitoring');
        return;
      }

      // ✅ Nettoyer les anciens channels
      await _cleanupRealtimeChannels();

      // Subscribe to device changes
      _deviceChannel = _supabase
          .channel('device_changes_${user.id}_${DateTime.now().millisecondsSinceEpoch}') // ✅ Channel unique
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'user_devices',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.id,
            ),
            callback: (payload) {
              _handleDeviceChange(payload.newRecord);
            },
          )
          .subscribe();

      // Subscribe to session changes
      _sessionChannel = _supabase
          .channel('session_changes_${user.id}_${DateTime.now().millisecondsSinceEpoch}') // ✅ Channel unique
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_sessions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.id,
            ),
            callback: (payload) {
              _handleSessionChange(payload);
            },
          )
          .subscribe();

      _isMonitoringInitialized = true;
      
      // ✅ Démarrer le nettoyage périodique des notifications
      _startCleanupTimer();
      
      debugPrint('✅ [DeviceService] Real-time monitoring initialized');
    } catch (e) {
      debugPrint('❌ [DeviceService] Error initializing real-time: $e');
      _isMonitoringInitialized = false;
    }
  }

  // ✅ Nouvelle méthode pour nettoyer les channels
  Future<void> _cleanupRealtimeChannels() async {
    try {
      if (_deviceChannel != null) {
        await _deviceChannel!.unsubscribe();
        _deviceChannel = null;
      }
      if (_sessionChannel != null) {
        await _sessionChannel!.unsubscribe();
        _sessionChannel = null;
      }
      _isMonitoringInitialized = false;
    } catch (e) {
      debugPrint('⚠️ [DeviceService] Erreur nettoyage channels: $e');
    }
  }

  // ✅ Timer pour nettoyer les notifications anciennes
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      // Nettoyer les notifications de plus de 10 minutes
      _notifiedDisconnections.clear();
      debugPrint('🧹 [DeviceService] Nettoyage cache notifications');
    });
  }

  /// Handle device changes from real-time updates
  void _handleDeviceChange(Map<String, dynamic>? newRecord) {
    if (newRecord == null) return;

    final deviceId = newRecord['device_id'] as String?;
    final forceLogout = newRecord['force_logout'] as bool? ?? false;
    
    debugPrint('📱 [DeviceService] Device change: $deviceId, forceLogout: $forceLogout');
    
    if (deviceId == _currentDeviceId && forceLogout) {
      debugPrint('🚨 [DeviceService] Force logout detected for current device');
      onForceLogout?.call();
      _handleForcedLogout();
    } else if (deviceId != null && deviceId != _currentDeviceId && forceLogout) {
      // ✅ Vérifier la déduplication AVANT de notifier
      final notificationKey = '${deviceId}_disconnect_${DateTime.now().millisecondsSinceEpoch ~/ 30000}'; // 30 sec window
      if (!_notifiedDisconnections.contains(notificationKey)) {
        _notifiedDisconnections.add(notificationKey);
        debugPrint('🔔 [DeviceService] Remote device force logout: $deviceId');
        _notifyRemoteDisconnection(deviceId);
      } else {
        debugPrint('🔕 [DeviceService] Notification déjà envoyée pour: $deviceId');
      }
    }
  }

  /// Handle session changes from real-time updates
  void _handleSessionChange(PostgresChangePayload payload) {
    // ✅ Filtrer uniquement les événements UPDATE significatifs
    if (payload.eventType != PostgresChangeEvent.update) return;
    
    final newRecord = payload.newRecord;
    final deviceId = newRecord['device_id'] as String?;
    final isActive = newRecord['is_active'] as bool? ?? true;
    final forceLogout = newRecord['force_logout'] as bool? ?? false;
    
    debugPrint('📋 [DeviceService] Session change: $deviceId, active: $isActive, forceLogout: $forceLogout');
    
    // ✅ Ne traiter que les sessions d'autres appareils qui deviennent inactives
    if (deviceId != null && 
        deviceId != _currentDeviceId && 
        (!isActive || forceLogout)) {
      
      // ✅ Déduplication avec fenêtre temporelle plus large pour les sessions
      final notificationKey = '${deviceId}_session_${DateTime.now().millisecondsSinceEpoch ~/ 60000}'; // 1 min window
      if (!_notifiedDisconnections.contains(notificationKey)) {
        _notifiedDisconnections.add(notificationKey);
        debugPrint('🔔 [DeviceService] Remote session disconnected: $deviceId');
        _notifyRemoteDisconnection(deviceId);
      } else {
        debugPrint('🔕 [DeviceService] Session notification déjà envoyée pour: $deviceId');
      }
    }
  }

  /// Notify UI about remote disconnection
  Future<void> _notifyRemoteDisconnection(String deviceId) async {
    try {
      // ✅ Double vérification pour éviter les appels multiples
      final cacheKey = 'notify_$deviceId';
      if (_notifiedDisconnections.contains(cacheKey)) {
        debugPrint('🔕 [DeviceService] Notification UI déjà envoyée pour: $deviceId');
        return;
      }
      _notifiedDisconnections.add(cacheKey);
      
      // Get device details
      final device = await _supabase
          .from('user_devices')
          .select()
          .eq('device_id', deviceId)
          .maybeSingle();
      
      if (device != null) {
        final deviceName = device['device_name'] as String? ?? 'Unknown Device';
        debugPrint('📤 [DeviceService] Envoi notification UI: $deviceName');
        onRemoteDisconnect?.call(deviceId, deviceName);
      }
    } catch (e) {
      debugPrint('❌ [DeviceService] Error getting device details: $e');
    }
  }

  /// Enregistre l'appareil actuel automatiquement
  Future<UserDevice?> registerCurrentDevice({String? customDeviceName}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ [DeviceService] Utilisateur non connecté');
        return null;
      }

      debugPrint('🔹 [DeviceService] Enregistrement appareil pour ${user.email}');

      final deviceId = await _generateDeviceId();
      _currentDeviceId = deviceId;
      final deviceInfo = await _getDeviceInfo();
      final appVersion = await _getAppVersion();
      
      String deviceName = customDeviceName ?? await _getDefaultDeviceName();

      // Vérifier si l'appareil existe déjà
      final existingDevice = await _supabase
          .from('user_devices')
          .select()
          .eq('device_id', deviceId)
          .eq('user_id', user.id)
          .maybeSingle();

      UserDevice device;

      if (existingDevice != null) {
        // Mettre à jour l'appareil existant
        debugPrint('🔹 [DeviceService] Appareil existant trouvé, mise à jour...');
        
        final updatedDevice = await _supabase
            .from('user_devices')
            .update({
              'last_active_at': DateTime.now().toIso8601String(),
              'is_active': true,
              'force_logout': false,
              'device_info': deviceInfo,
              'app_version': appVersion,
            })
            .eq('id', existingDevice['id'])
            .select()
            .single();
        
        device = UserDevice.fromJson(updatedDevice);
        debugPrint('✅ [DeviceService] Appareil mis à jour');
      } else {
        // Créer un nouvel appareil
        debugPrint('🔹 [DeviceService] Création nouvel appareil...');
        
        final newDevice = await _supabase
            .from('user_devices')
            .insert({
              'user_id': user.id,
              'device_id': deviceId,
              'device_name': deviceName,
              'device_type': _getDeviceType(),
              'platform': _getPlatform(),
              'app_version': appVersion,
              'device_info': deviceInfo,
              'is_active': true,
              'force_logout': false,
            })
            .select()
            .single();
        
        device = UserDevice.fromJson(newDevice);
        debugPrint('✅ [DeviceService] Nouvel appareil créé');
      }

      // Créer une session pour cet appareil
      await _createSession(deviceId);
      
      // Initialize real-time monitoring after device registration
      await initializeRealtimeMonitoring();

      return device;
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur enregistrement: $e');
      return null;
    }
  }

  /// À appeler au démarrage pour recharger currentDeviceId
  Future<void> initCurrentDeviceFromSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return;
    
    final row = await _supabase
        .from('user_sessions')
        .select('device_id')
        .eq('session_token', session.accessToken)
        .maybeSingle();
    
    _currentDeviceId = row?['device_id'] as String?;
    
    if (_currentDeviceId != null) {
      // ✅ Éviter la double initialisation
      if (!_isMonitoringInitialized) {
        await initializeRealtimeMonitoring();
      }
      debugPrint('✅ currentDeviceId rechargé: $_currentDeviceId');
    }
  }

  /// Récupère tous les appareils de l'utilisateur avec identification de l'appareil actuel
  Future<List<Map<String, dynamic>>> getUserDevicesWithCurrentFlag() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('user_devices')
          .select()
          .eq('user_id', user.id)
          .order('last_active_at', ascending: false);

      return response.map<Map<String, dynamic>>((device) {
        final deviceData = Map<String, dynamic>.from(device);
        // Marquer si c'est l'appareil actuel
        deviceData['is_current_device'] = device['device_id'] == _currentDeviceId;
        return deviceData;
      }).toList();
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur récupération: $e');
      return [];
    }
  }

  /// Récupère tous les appareils de l'utilisateur (méthode originale maintenue)
  Future<List<UserDevice>> getUserDevices() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('user_devices')
          .select()
          .eq('user_id', user.id)
          .order('last_active_at', ascending: false);

      return response
          .map<UserDevice>((device) => UserDevice.fromJson(device))
          .toList();
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur récupération: $e');
      return [];
    }
  }

  /// Récupère les appareils autres que l'appareil actuel (pour l'UI de déconnexion)
  Future<List<UserDevice>> getOtherUserDevices() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('user_devices')
          .select()
          .eq('user_id', user.id)
          .neq('device_id', _currentDeviceId ?? '')
          .order('last_active_at', ascending: false);

      return response
          .map<UserDevice>((device) => UserDevice.fromJson(device))
          .toList();
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur récupération autres appareils: $e');
      return [];
    }
  }

  /// Vérifie si un appareil est l'appareil actuel
  bool isCurrentDevice(String deviceId) {
    return deviceId == _currentDeviceId;
  }

  /// Met à jour l'activité de l'appareil actuel
  Future<void> updateDeviceActivity() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final deviceId = _currentDeviceId ?? await _generateDeviceId();
      
      await _supabase
          .from('user_devices')
          .update({
            'last_active_at': DateTime.now().toIso8601String(),
          })
          .eq('device_id', deviceId)
          .eq('user_id', user.id);

      // Mettre à jour aussi la session
      await _updateSessionActivity();

      debugPrint('🔹 [DeviceService] Activité mise à jour');
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur mise à jour activité: $e');
    }
  }

  /// Supprime un appareil (seulement si ce n'est pas l'appareil actuel)
  Future<bool> removeDevice(String deviceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Vérifier que ce n'est pas l'appareil actuel
      if (deviceId == _currentDeviceId) {
        debugPrint('❌ [DeviceService] Cannot remove current device');
        return false;
      }

      // Supprimer d'abord les sessions associées
      await _supabase
          .from('user_sessions')
          .delete()
          .eq('device_id', deviceId)
          .eq('user_id', user.id);

      // Ensuite supprimer l'appareil
      await _supabase
          .from('user_devices')
          .delete()
          .eq('device_id', deviceId)
          .eq('user_id', user.id);

      debugPrint('✅ [DeviceService] Appareil supprimé');
      return true;
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur suppression: $e');
      return false;
    }
  }

  /// Désactive un appareil (seulement si ce n'est pas l'appareil actuel)
  Future<bool> deactivateDevice(String deviceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Vérifier que ce n'est pas l'appareil actuel
      if (deviceId == _currentDeviceId) {
        debugPrint('❌ [DeviceService] Cannot deactivate current device');
        return false;
      }

      await _supabase
          .from('user_devices')
          .update({'is_active': false})
          .eq('device_id', deviceId)
          .eq('user_id', user.id);

      // Désactiver aussi les sessions
      await _supabase
          .from('user_sessions')
          .update({'is_active': false})
          .eq('device_id', deviceId)
          .eq('user_id', user.id);

      debugPrint('✅ [DeviceService] Appareil désactivé');
      return true;
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur désactivation: $e');
      return false;
    }
  }

/// Déconnecte un appareil à distance (seulement si ce n'est pas l'appareil actuel)
/// Déconnecte un appareil à distance (seulement si ce n'est pas l'appareil actuel)
/// Version simplifiée sans broadcast manuel
Future<bool> disconnectDeviceRemotely(String deviceId) async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('❌ [DeviceService] Utilisateur non connecté');
      return false;
    }

    // ✅ Vérifier que ce n'est pas l'appareil actuel
    if (deviceId == _currentDeviceId) {
      debugPrint('❌ [DeviceService] Cannot disconnect current device remotely');
      return false;
    }

    debugPrint('🔹 [DeviceService] Début déconnexion à distance pour: $deviceId');
    debugPrint('🔹 [DeviceService] Current device ID: $_currentDeviceId');
    debugPrint('🔹 [DeviceService] User ID: ${user.id}');

    // ✅ Transaction pour assurer la cohérence
    // 1. Marquer l'appareil comme déconnecté
    final deviceUpdate = await _supabase
        .from('user_devices')
        .update({
          'force_logout': true,
          'logout_requested_at': DateTime.now().toIso8601String(),
          'is_active': false,
        })
        .eq('user_id', user.id)
        .eq('device_id', deviceId)
        .select();

    debugPrint('🔹 [DeviceService] Device update result: $deviceUpdate');

    // 2. Marquer toutes les sessions associées pour déconnexion
    final sessionUpdate = await _supabase
        .from('user_sessions')
        .update({
          'force_logout': true,
          'is_active': false,
        })
        .eq('user_id', user.id)
        .eq('device_id', deviceId)
        .select();

    debugPrint('🔹 [DeviceService] Session update result: $sessionUpdate');

    // ✅ Vérifier que les mises à jour ont réussi
    if (deviceUpdate.isEmpty) {
      debugPrint('❌ [DeviceService] Aucun appareil trouvé avec cet ID');
      return false;
    }

    debugPrint('✅ [DeviceService] Déconnexion forcée configurée pour appareil: $deviceId');
    
    // ✅ Le monitoring temps réel existant devrait détecter ces changements automatiquement
    // Pas besoin de broadcast manuel, les triggers PostgreSQL + Realtime s'en occupent

    return true;
  } catch (e) {
    debugPrint('❌ [DeviceService] Erreur déconnexion forcée: $e');
    return false;
  }
}

/// ✅ Méthode alternative pour déclencher une vérification immédiate
Future<void> triggerForceLogoutCheck() async {
  try {
    // Force une vérification immédiate du logout
    final shouldLogout = await _checkForceLogout();
    if (shouldLogout) {
      debugPrint('🚨 [DeviceService] Force logout détecté lors de la vérification manuelle');
      await _handleForcedLogout();
    }
  } catch (e) {
    debugPrint('❌ [DeviceService] Erreur vérification manuelle: $e');
  }
}

/// ✅ Version améliorée du timer d'activité avec vérification plus fréquente
Timer startActivityUpdater() {
  debugPrint('🔹 [DeviceService] Démarrage du suivi d\'activité');
  
  return Timer.periodic(const Duration(seconds: 30), (timer) async { // ✅ Plus fréquent : 30s au lieu de 1min
    if (_supabase.auth.currentUser != null) {
      await updateDeviceActivity();
      
      // ✅ Vérification du force logout à chaque cycle
      final shouldLogout = await _checkForceLogout();
      if (shouldLogout) {
        debugPrint('🔹 [DeviceService] Déconnexion forcée détectée via timer');
        await _handleForcedLogout();
        timer.cancel();
      }
    } else {
      debugPrint('🔹 [DeviceService] Arrêt du suivi - utilisateur déconnecté');
      timer.cancel();
    }
  });
}
/// ✅ Nouvelle méthode pour vérifier l'état d'un appareil spécifique
Future<Map<String, dynamic>?> getDeviceStatus(String deviceId) async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final device = await _supabase
        .from('user_devices')
        .select('*, user_sessions!inner(*)')
        .eq('user_id', user.id)
        .eq('device_id', deviceId)
        .maybeSingle();

    return device;
  } catch (e) {
    debugPrint('❌ [DeviceService] Erreur récupération statut appareil: $e');
    return null;
  }
}

/// ✅ Méthode pour forcer la synchronisation des appareils
Future<void> forceSyncDevices() async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Déclencher une mise à jour sur tous les appareils de l'utilisateur
    await _supabase
        .from('user_devices')
        .update({
          'last_sync': DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id);

    debugPrint('🔄 [DeviceService] Synchronisation forcée des appareils');
  } catch (e) {
    debugPrint('❌ [DeviceService] Erreur sync forcée: $e');
  }
}

/// ✅ Amélioration de la vérification de déconnexion forcée
Future<bool> _checkForceLogout() async {
  if (_currentDeviceId == null) return false;

  try {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    // Vérifier à la fois l'appareil ET les sessions
    final device = await _supabase
        .from('user_devices')
        .select('force_logout, is_active')
        .eq('device_id', _currentDeviceId!)
        .eq('user_id', user.id)
        .maybeSingle();

    final session = await _supabase
        .from('user_sessions')
        .select('force_logout, is_active')
        .eq('device_id', _currentDeviceId!)
        .eq('user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();

    final deviceForceLogout = device?['force_logout'] == true || device?['is_active'] == false;
    final sessionForceLogout = session?['force_logout'] == true || session?['is_active'] == false;

    final shouldLogout = deviceForceLogout || sessionForceLogout;
    
    if (shouldLogout) {
      debugPrint('🚨 [DeviceService] Force logout détecté:');
      debugPrint('   - Device force_logout: ${device?['force_logout']}');
      debugPrint('   - Device is_active: ${device?['is_active']}');
      debugPrint('   - Session force_logout: ${session?['force_logout']}');
      debugPrint('   - Session is_active: ${session?['is_active']}');
    }

    return shouldLogout;
  } catch (e) {
    debugPrint('❌ [DeviceService] Erreur vérification logout: $e');
    return false;
  }
}
  /// Obtient les statistiques des appareils
  Future<Map<String, dynamic>> getDeviceStats() async {
    try {
      final devices = await getUserDevices();
      
      final stats = {
        'total': devices.length,
        'active': devices.where((d) => d.isActive).length,
        'inactive': devices.where((d) => !d.isActive).length,
        'current_device_id': _currentDeviceId,
        'by_platform': <String, int>{},
        'by_type': <String, int>{},
      };

      // Grouper par plateforme
      for (final device in devices) {
        final platform = device.platform;
        final type = device.deviceType;
        
        (stats['by_platform'] as Map<String, int>)[platform] =
            ((stats['by_platform'] as Map<String, int>)[platform] ?? 0) + 1;
            
        (stats['by_type'] as Map<String, int>)[type] =
            ((stats['by_type'] as Map<String, int>)[type] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur statistiques: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'current_device_id': _currentDeviceId,
        'by_platform': {},
        'by_type': {},
      };
    }
  }

  /// Obtient les appareils avec leurs sessions actives, en excluant l'appareil actuel
  Future<List<Map<String, dynamic>>> getActiveDevicesWithSessionsExcludingCurrent() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final devices = await getOtherUserDevices(); // Utilise la nouvelle méthode
      final result = <Map<String, dynamic>>[];

      for (final device in devices) {
        final sessions = await _supabase
            .from('user_sessions')
            .select()
            .eq('user_id', user.id)
            .eq('device_id', device.deviceId)
            .eq('is_active', true);

        result.add({
          ...device.toJson(),
          'id': device.id,
          'user_sessions': sessions,
          'is_current_device': false, // Ces appareils ne sont jamais l'appareil actuel
        });
      }

      return result;
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur récupération sessions: $e');
      return [];
    }
  }

  /// Obtient les appareils avec leurs sessions actives (méthode originale)
  Future<List<Map<String, dynamic>>> getActiveDevicesWithSessions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final devices = await getUserDevices();
      final result = <Map<String, dynamic>>[];

      for (final device in devices) {
        final sessions = await _supabase
            .from('user_sessions')
            .select()
            .eq('user_id', user.id)
            .eq('device_id', device.deviceId)
            .eq('is_active', true);

        result.add({
          ...device.toJson(),
          'id': device.id,
          'user_sessions': sessions,
          'is_current_device': device.deviceId == _currentDeviceId,
        });
      }

      return result;
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur récupération sessions: $e');
      return [];
    }
  }

  /// Démarre la mise à jour périodique de l'activité

  /// Nettoie les ressources
  void dispose() {
    _sessionCheckTimer?.cancel();
    _cleanupTimer?.cancel(); // ✅ Nouveau nettoyage
    _cleanupRealtimeChannels();
    _notifiedDisconnections.clear(); // ✅ Nettoyer le cache
  }

  // ============= SESSION MANAGEMENT =============
  Future<void> _createSession(String deviceId) async {
    final session = _supabase.auth.currentSession;
    final token = session?.accessToken;
    if (token == null) return;
    _currentSessionToken = token;
    await _supabase.from('user_sessions').insert({
      'user_id': session?.user.id,
      'device_id': deviceId,
      'session_token': token,
      'is_active': true,
      'force_logout': false,
    });
    debugPrint('🔹 Session créée (token Supabase)');
  }

  Future<void> _updateSessionActivity() async {
    if (_currentSessionToken == null) return;

    try {
      await _supabase
          .from('user_sessions')
          .update({
            'last_activity': DateTime.now().toIso8601String(),
          })
          .eq('session_token', _currentSessionToken!);
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur mise à jour session: $e');
    }
  }


  Future<void> _handleForcedLogout() async {
    try {
      _sessionCheckTimer?.cancel();
      _currentSessionToken = null;
      final previousDeviceId = _currentDeviceId;
      _currentDeviceId = null;
      
      // ✅ Nettoyer les channels avant déconnexion
      await _cleanupRealtimeChannels();
      
      await _supabase.auth.signOut();
      
      debugPrint('🔹 [DeviceService] Déconnexion forcée effectuée pour appareil: $previousDeviceId');
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur lors de la déconnexion forcée: $e');
    }
  }

  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${_uuid.v4()}_$timestamp';
  }

  // ============= PRIVATE METHODS (VERSION ROBUSTE) =============

  /// Génère un ID unique pour l'appareil (VERSION ROBUSTE)
  Future<String> _generateDeviceId() async {
    try {
      if (kIsWeb) {
        // Pour le web, générer un UUID persistant
        return _generateWebDeviceId();
      } else if (Platform.isAndroid) {
        try {
          AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
          return androidInfo.id;
        } catch (e) {
          debugPrint('⚠️ [DeviceService] Plugin device_info non disponible, utilisation UUID');
          return _generateFallbackDeviceId();
        }
      } else if (Platform.isIOS) {
        try {
          IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
          return iosInfo.identifierForVendor ?? _generateFallbackDeviceId();
        } catch (e) {
          debugPrint('⚠️ [DeviceService] Plugin device_info non disponible, utilisation UUID');
          return _generateFallbackDeviceId();
        }
      }
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur génération ID: $e');
    }
    return _generateFallbackDeviceId();
  }

  /// Génère un ID de fallback
  String _generateFallbackDeviceId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(999999);
    return 'device_${timestamp}_$randomSuffix';
  }

  /// Génère un ID pour le web
  String _generateWebDeviceId() {
    // Pour le web, on peut utiliser une combinaison d'informations du navigateur
    final userAgent = kIsWeb ? 'web_browser' : 'unknown';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'web_${userAgent.hashCode}_${timestamp}_$random';
  }

  /// Récupère les informations de l'appareil (VERSION ROBUSTE)
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (kIsWeb) {
        try {
          WebBrowserInfo webInfo = await _deviceInfo.webBrowserInfo;
          return {
            'browser': webInfo.browserName.name,
            'userAgent': webInfo.userAgent ?? 'unknown',
            'platform': webInfo.platform ?? 'web',
            'vendor': webInfo.vendor ?? 'unknown',
          };
        } catch (e) {
          return {
            'browser': 'unknown',
            'userAgent': 'web_fallback',
            'platform': 'web',
            'vendor': 'unknown',
          };
        }
      } else if (Platform.isAndroid) {
        try {
          AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
          return {
            'model': androidInfo.model,
            'brand': androidInfo.brand,
            'manufacturer': androidInfo.manufacturer,
            'version': androidInfo.version.release,
            'sdkInt': androidInfo.version.sdkInt,
          };
        } catch (e) {
          return {
            'model': 'Android Device',
            'brand': 'unknown',
            'manufacturer': 'unknown',
            'version': 'unknown',
            'sdkInt': 0,
          };
        }
      } else if (Platform.isIOS) {
        try {
          IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
          return {
            'model': iosInfo.model,
            'name': iosInfo.name,
            'systemName': iosInfo.systemName,
            'systemVersion': iosInfo.systemVersion,
          };
        } catch (e) {
          return {
            'model': 'iOS Device',
            'name': 'iPhone/iPad',
            'systemName': 'iOS',
            'systemVersion': 'unknown',
          };
        }
      }
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur info appareil: $e');
    }
    
    return {
      'platform': _getPlatform(),
      'type': _getDeviceType(),
      'fallback': true,
    };
  }

  /// Récupère la version de l'application (VERSION ROBUSTE)
  Future<String> _getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      debugPrint('⚠️ [DeviceService] Plugin package_info non disponible, version par défaut');
      return '1.0.0+1';
    }
  }

  /// Détermine le type d'appareil
  String _getDeviceType() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid || Platform.isIOS) return 'mobile';
    return 'unknown';
  }

  /// Détermine la plateforme
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Génère un nom par défaut pour l'appareil (VERSION ROBUSTE)
  Future<String> _getDefaultDeviceName() async {
    try {
      if (kIsWeb) {
        try {
          WebBrowserInfo webInfo = await _deviceInfo.webBrowserInfo;
          return '${webInfo.browserName.name} sur ${webInfo.platform ?? 'Web'}';
        } catch (e) {
          return 'Navigateur Web';
        }
      } else if (Platform.isAndroid) {
        try {
          AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
          return '${androidInfo.brand} ${androidInfo.model}';
        } catch (e) {
          return 'Appareil Android';
        }
      } else if (Platform.isIOS) {
        try {
          IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
          return iosInfo.name;
        } catch (e) {
          return 'iPhone/iPad';
        }
      }
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur nom par défaut: $e');
    }
    
    final platform = _getPlatform();
    return 'Mon appareil ${platform.toUpperCase()}';
  }
}