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
  
  // Callbacks for UI updates
  Function()? onForceLogout;
  Function(String deviceId, String deviceName)? onRemoteDisconnect;

  // ============= PUBLIC METHODS =============

  /// Initialize real-time monitoring for the current device
  Future<void> initializeRealtimeMonitoring() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Subscribe to device changes
      _deviceChannel = _supabase
          .channel('device_changes_${user.id}')
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
          .channel('session_changes_${user.id}')
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

      debugPrint('✅ [DeviceService] Real-time monitoring initialized');
    } catch (e) {
      debugPrint('❌ [DeviceService] Error initializing real-time: $e');
    }
  }

  /// Handle device changes from real-time updates
  void _handleDeviceChange(Map<String, dynamic>? newRecord) {
    if (newRecord == null) return;

    final deviceId = newRecord['device_id'] as String?;
    final forceLogout = newRecord['force_logout'] as bool? ?? false;
    
    if (deviceId == _currentDeviceId && forceLogout) {
      debugPrint('🚨 [DeviceService] Force logout detected for current device');
      onForceLogout?.call();
      _handleForcedLogout();
    }
  }

  /// Handle session changes from real-time updates
  void _handleSessionChange(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.update) {
      final newRecord = payload.newRecord;
      final deviceId = newRecord['device_id'] as String?;
      final isActive = newRecord['is_active'] as bool? ?? true;
      final forceLogout = newRecord['force_logout'] as bool? ?? false;
      
      // Check if another device was disconnected
      if (deviceId != null && deviceId != _currentDeviceId && (!isActive || forceLogout)) {
        debugPrint('🔔 [DeviceService] Remote device disconnected: $deviceId');
        _notifyRemoteDisconnection(deviceId);
      }
    }
  }

  /// Notify UI about remote disconnection
  Future<void> _notifyRemoteDisconnection(String deviceId) async {
    try {
      // Get device details
      final device = await _supabase
          .from('user_devices')
          .select()
          .eq('device_id', deviceId)
          .maybeSingle();
      
      if (device != null) {
        final deviceName = device['device_name'] as String? ?? 'Unknown Device';
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
    await initializeRealtimeMonitoring();
    debugPrint('✅ currentDeviceId rechargé: $_currentDeviceId');
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
  Future<bool> disconnectDeviceRemotely(String deviceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Vérifier que ce n'est pas l'appareil actuel
      if (deviceId == _currentDeviceId) {
        debugPrint('❌ [DeviceService] Cannot disconnect current device remotely');
        return false;
      }

      // Marquer toutes les sessions de cet appareil pour déconnexion
      await _supabase
          .from('user_sessions')
          .update({
            'force_logout': true,
            'is_active': false,
          })
          .eq('user_id', user.id)
          .eq('device_id', deviceId);

      // Marquer l'appareil comme déconnecté
      await _supabase
          .from('user_devices')
          .update({
            'force_logout': true,
            'logout_requested_at': DateTime.now().toIso8601String(),
            'is_active': false,
          })
          .eq('user_id', user.id)
          .eq('device_id', deviceId);

      debugPrint('🔹 [DeviceService] Déconnexion forcée pour appareil: $deviceId');
      return true;
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur déconnexion forcée: $e');
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
  Timer startActivityUpdater() {
    debugPrint('🔹 [DeviceService] Démarrage du suivi d\'activité');
    
    return Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_supabase.auth.currentUser != null) {
        await updateDeviceActivity();
        
        final shouldLogout = await _checkForceLogout();
        if (shouldLogout) {
          debugPrint('🔹 [DeviceService] Déconnexion forcée détectée');
          await _handleForcedLogout();
          timer.cancel();
        }
      } else {
        debugPrint('🔹 [DeviceService] Arrêt du suivi - utilisateur déconnecté');
        timer.cancel();
      }
    });
  }

  /// Nettoie les ressources
  void dispose() {
    _sessionCheckTimer?.cancel();
    _deviceChannel?.unsubscribe();
    _sessionChannel?.unsubscribe();
  }

  // ============= SESSION MANAGEMENT =============
Future<void> _createSession(String deviceId) async {
  final session = _supabase.auth.currentSession;
  final token = session?.accessToken;
  if (token == null) return;
  _currentSessionToken = token;
  await _supabase.from('user_sessions').insert({
    'user_id':  session?.user.id,
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

  Future<bool> _checkForceLogout() async {
    if (_currentDeviceId == null) return false;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final device = await _supabase
          .from('user_devices')
          .select('force_logout')
          .eq('device_id', _currentDeviceId!)
          .eq('user_id', user.id)
          .maybeSingle();

      return device?['force_logout'] == true;
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur vérification logout: $e');
      return false;
    }
  }

  Future<void> _handleForcedLogout() async {
    try {
      _sessionCheckTimer?.cancel();
      _currentSessionToken = null;
      final previousDeviceId = _currentDeviceId;
      _currentDeviceId = null;
      
      // Unsubscribe from real-time channels
      await _deviceChannel?.unsubscribe();
      await _sessionChannel?.unsubscribe();
      
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