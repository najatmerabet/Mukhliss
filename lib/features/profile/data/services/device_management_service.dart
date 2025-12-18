import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mukhliss/features/profile/data/models/user_device.dart';

class DeviceManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const String _deviceIdUserKey = 'device_id_user_';

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
  bool _isMonitoringInitialized = false;

  // Callbacks for UI updates
  Function()? onForceLogout;
  Function(String deviceId, String deviceName)? onRemoteDisconnect;

  // Déduplication des notifications
  final Set<String> _notifiedDisconnections = {};
  Timer? _cleanupTimer;

  // ============= NOUVELLES MÉTHODES POUR LA PERSISTANCE =============

  /// Initialiser le service au démarrage de l'application
  Future<void> initialize() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint(
          '🔹 [DeviceService] Pas d\'utilisateur connecté lors de l\'initialisation',
        );
        return;
      }

      // Charger le deviceId depuis SharedPreferences
      await _loadCurrentDeviceId();

      // Si on a un deviceId en mémoire locale, vérifier qu'il est toujours valide
      if (_currentDeviceId != null) {
        final isValid = await _validateDeviceId(_currentDeviceId!);
        if (!isValid) {
          debugPrint(
            '⚠️ [DeviceService] DeviceId invalide, réinitialisation...',
          );
          _currentDeviceId = null;
          await _clearStoredDeviceId();
        }
      }

      // Si toujours pas de deviceId, essayer de le récupérer depuis la session
      if (_currentDeviceId == null) {
        await initCurrentDeviceFromSession();
      }

      // Si on a un deviceId valide, initialiser le monitoring
      if (_currentDeviceId != null) {
        await initializeRealtimeMonitoring();
      }

      debugPrint(
        '✅ [DeviceService] Service initialisé avec deviceId: $_currentDeviceId',
      );
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur lors de l\'initialisation: $e');
    }
  }

  /// Charger le deviceId depuis SharedPreferences
  Future<void> _loadCurrentDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Utiliser une clé spécifique à l'utilisateur
      final userKey = '$_deviceIdUserKey${user.id}';
      _currentDeviceId = prefs.getString(userKey);

      debugPrint(
        '🔹 [DeviceService] DeviceId chargé depuis SharedPreferences: $_currentDeviceId',
      );
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur chargement deviceId: $e');
    }
  }

  /// Sauvegarder le deviceId dans SharedPreferences
  Future<void> _saveCurrentDeviceId(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Utiliser une clé spécifique à l'utilisateur
      final userKey = '$_deviceIdUserKey${user.id}';
      await prefs.setString(userKey, deviceId);

      debugPrint(
        '🔹 [DeviceService] DeviceId sauvegardé dans SharedPreferences: $deviceId',
      );
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur sauvegarde deviceId: $e');
    }
  }

  /// Effacer le deviceId stocké
  Future<void> _clearStoredDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final userKey = '$_deviceIdUserKey${user.id}';
      await prefs.remove(userKey);

      debugPrint('🔹 [DeviceService] DeviceId effacé de SharedPreferences');
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur effacement deviceId: $e');
    }
  }

  /// Valider que le deviceId existe toujours dans la base de données
  Future<bool> _validateDeviceId(String deviceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final device =
          await _supabase
              .from('user_devices')
              .select('id')
              .eq('device_id', deviceId)
              .eq('user_id', user.id)
              .maybeSingle();

      return device != null;
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur validation deviceId: $e');
      return false;
    }
  }

  // ============= MÉTHODES MODIFIÉES =============

  /// Initialize real-time monitoring for the current device
  Future<void> initializeRealtimeMonitoring() async {
    if (_isMonitoringInitialized) {
      debugPrint('🔹 [DeviceService] Monitoring déjà initialisé, ignoré');
      return;
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint(
          '❌ [DeviceService] Utilisateur non connecté pour monitoring',
        );
        return;
      }

      await _cleanupRealtimeChannels();

      // Subscribe to device changes
      _deviceChannel =
          _supabase
              .channel(
                'device_changes_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
              )
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
      _sessionChannel =
          _supabase
              .channel(
                'session_changes_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
              )
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
      _startCleanupTimer();

      debugPrint('✅ [DeviceService] Real-time monitoring initialized');
    } catch (e) {
      debugPrint('❌ [DeviceService] Error initializing real-time: $e');
      _isMonitoringInitialized = false;
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

      debugPrint(
        '🔹 [DeviceService] Enregistrement appareil pour ${user.email}',
      );

      final deviceId = await _generateDeviceId();
      _currentDeviceId = deviceId;

      // Sauvegarder le deviceId immédiatement
      await _saveCurrentDeviceId(deviceId);

      final deviceInfo = await _getDeviceInfo();
      final appVersion = await _getAppVersion();

      String deviceName = customDeviceName ?? await _getDefaultDeviceName();

      // Vérifier si l'appareil existe déjà
      final existingDevice =
          await _supabase
              .from('user_devices')
              .select()
              .eq('device_id', deviceId)
              .eq('user_id', user.id)
              .maybeSingle();

      UserDevice device;

      if (existingDevice != null) {
        debugPrint(
          '🔹 [DeviceService] Appareil existant trouvé, mise à jour...',
        );

        final updatedDevice =
            await _supabase
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
        debugPrint('🔹 [DeviceService] Création nouvel appareil...');

        final newDevice =
            await _supabase
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

      await _createSession(deviceId);
      await initializeRealtimeMonitoring();

      return device;
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur enregistrement: $e');
      return null;
    }
  }

  /// À appeler au démarrage pour recharger currentDeviceId
  Future<void> initCurrentDeviceFromSession() async {
    try {
      // Vérifier d'abord la connexion internet
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint(
          '📵 [DeviceService] Mode hors ligne - Chargement depuis le cache',
        );
        await _loadCurrentDeviceId(); // Charger depuis le stockage local
        return;
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        debugPrint('⚠️ [DeviceService] Pas de session active');
        return;
      }

      final row = await _supabase
          .from('user_sessions')
          .select('device_id')
          .eq('session_token', session.accessToken)
          .eq('is_active', true)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 10),
          ); // Timeout pour éviter l'attente infinie

      if (row != null && row['device_id'] != null) {
        _currentDeviceId = row['device_id'] as String;
        await _saveCurrentDeviceId(_currentDeviceId!);

        if (!_isMonitoringInitialized) {
          await initializeRealtimeMonitoring();
        }
        debugPrint('✅ [DeviceService] DeviceId actualisé depuis le serveur');
      } else {
        debugPrint('⚠️ [DeviceService] Aucune session active trouvée');
        await _loadCurrentDeviceId(); // Fallback sur le cache local
      }
    } on TimeoutException {
      debugPrint('⏱️ [DeviceService] Timeout - Utilisation du cache local');
      await _loadCurrentDeviceId();
    } on SocketException catch (e) {
      debugPrint('📵 [DeviceService] Erreur réseau: ${e.message}');
      await _loadCurrentDeviceId(); // Fallback sur le cache local
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur inattendue: $e');
      await _loadCurrentDeviceId(); // Fallback sur le cache local
    }
  }

  /// Nettoie les ressources et efface les données stockées
  void dispose() {
    _sessionCheckTimer?.cancel();
    _cleanupTimer?.cancel();
    _cleanupRealtimeChannels();
    _notifiedDisconnections.clear();
  }

  /// Déconnexion - effacer aussi le deviceId stocké
  Future<void> _handleForcedLogout() async {
    try {
      _sessionCheckTimer?.cancel();
      _currentSessionToken = null;
      final previousDeviceId = _currentDeviceId;
      _currentDeviceId = null;

      // Effacer le deviceId stocké
      await _clearStoredDeviceId();

      await _cleanupRealtimeChannels();
      await _supabase.auth.signOut();

      debugPrint(
        '🔹 [DeviceService] Déconnexion forcée effectuée pour appareil: $previousDeviceId',
      );
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur lors de la déconnexion forcée: $e');
    }
  }

  // ============= RESTE DU CODE INCHANGÉ =============

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

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _notifiedDisconnections.clear();
      debugPrint('🧹 [DeviceService] Nettoyage cache notifications');
    });
  }

  void _handleDeviceChange(Map<String, dynamic>? newRecord) {
    if (newRecord == null) return;

    final deviceId = newRecord['device_id'] as String?;
    final forceLogout = newRecord['force_logout'] as bool? ?? false;

    debugPrint(
      '📱 [DeviceService] Device change: $deviceId, forceLogout: $forceLogout',
    );

    if (deviceId == _currentDeviceId && forceLogout) {
      debugPrint('🚨 [DeviceService] Force logout detected for current device');
      onForceLogout?.call();
      _handleForcedLogout();
    } else if (deviceId != null &&
        deviceId != _currentDeviceId &&
        forceLogout) {
      final notificationKey =
          '${deviceId}_disconnect_${DateTime.now().millisecondsSinceEpoch ~/ 30000}';
      if (!_notifiedDisconnections.contains(notificationKey)) {
        _notifiedDisconnections.add(notificationKey);
        debugPrint('🔔 [DeviceService] Remote device force logout: $deviceId');
        _notifyRemoteDisconnection(deviceId);
      }
    }
  }

  void _handleSessionChange(PostgresChangePayload payload) {
    if (payload.eventType != PostgresChangeEvent.update) return;

    final newRecord = payload.newRecord;
    final deviceId = newRecord['device_id'] as String?;
    final isActive = newRecord['is_active'] as bool? ?? true;
    final forceLogout = newRecord['force_logout'] as bool? ?? false;

    debugPrint(
      '📋 [DeviceService] Session change: $deviceId, active: $isActive, forceLogout: $forceLogout',
    );

    if (deviceId != null &&
        deviceId != _currentDeviceId &&
        (!isActive || forceLogout)) {
      final notificationKey =
          '${deviceId}_session_${DateTime.now().millisecondsSinceEpoch ~/ 60000}';
      if (!_notifiedDisconnections.contains(notificationKey)) {
        _notifiedDisconnections.add(notificationKey);
        debugPrint('🔔 [DeviceService] Remote session disconnected: $deviceId');
        _notifyRemoteDisconnection(deviceId);
      }
    }
  }

  Future<void> _notifyRemoteDisconnection(String deviceId) async {
    try {
      final cacheKey = 'notify_$deviceId';
      if (_notifiedDisconnections.contains(cacheKey)) {
        return;
      }
      _notifiedDisconnections.add(cacheKey);

      final device =
          await _supabase
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
        deviceData['is_current_device'] =
            device['device_id'] == _currentDeviceId;
        return deviceData;
      }).toList();
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur récupération: $e');
      return [];
    }
  }

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

  bool isCurrentDevice(String deviceId) {
    return deviceId == _currentDeviceId;
  }

  Future<void> updateDeviceActivity() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final deviceId = _currentDeviceId ?? await _generateDeviceId();

      await _supabase
          .from('user_devices')
          .update({'last_active_at': DateTime.now().toIso8601String()})
          .eq('device_id', deviceId)
          .eq('user_id', user.id);

      await _updateSessionActivity();

      debugPrint('🔹 [DeviceService] Activité mise à jour');
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur mise à jour activité: $e');
    }
  }

  Future<bool> removeDevice(String deviceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      if (deviceId == _currentDeviceId) {
        debugPrint('❌ [DeviceService] Cannot remove current device');
        return false;
      }

      await _supabase
          .from('user_sessions')
          .delete()
          .eq('device_id', deviceId)
          .eq('user_id', user.id);

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

  Future<bool> deactivateDevice(String deviceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      if (deviceId == _currentDeviceId) {
        debugPrint('❌ [DeviceService] Cannot deactivate current device');
        return false;
      }

      await _supabase
          .from('user_devices')
          .update({'is_active': false})
          .eq('device_id', deviceId)
          .eq('user_id', user.id);

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

  Future<bool> disconnectDeviceRemotely(String deviceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ [DeviceService] Utilisateur non connecté');
        return false;
      }

      if (deviceId == _currentDeviceId) {
        debugPrint(
          '❌ [DeviceService] Cannot disconnect current device remotely',
        );
        return false;
      }

      debugPrint(
        '🔹 [DeviceService] Début déconnexion à distance pour: $deviceId',
      );

      final deviceUpdate =
          await _supabase
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

      final sessionUpdate =
          await _supabase
              .from('user_sessions')
              .update({'force_logout': true, 'is_active': false})
              .eq('user_id', user.id)
              .eq('device_id', deviceId)
              .select();

      debugPrint('🔹 [DeviceService] Session update result: $sessionUpdate');

      if (deviceUpdate.isEmpty) {
        debugPrint('❌ [DeviceService] Aucun appareil trouvé avec cet ID');
        return false;
      }

      debugPrint(
        '✅ [DeviceService] Déconnexion forcée configurée pour appareil: $deviceId',
      );

      return true;
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur déconnexion forcée: $e');
      return false;
    }
  }

  Future<void> triggerForceLogoutCheck() async {
    try {
      final shouldLogout = await _checkForceLogout();
      if (shouldLogout) {
        debugPrint(
          '🚨 [DeviceService] Force logout détecté lors de la vérification manuelle',
        );
        await _handleForcedLogout();
      }
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur vérification manuelle: $e');
    }
  }

  Timer startActivityUpdater() {
    debugPrint('🔹 [DeviceService] Démarrage du suivi d\'activité');

    return Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_supabase.auth.currentUser != null) {
        await updateDeviceActivity();

        final shouldLogout = await _checkForceLogout();
        if (shouldLogout) {
          debugPrint(
            '🔹 [DeviceService] Déconnexion forcée détectée via timer',
          );
          await _handleForcedLogout();
          timer.cancel();
        }
      } else {
        debugPrint(
          '🔹 [DeviceService] Arrêt du suivi - utilisateur déconnecté',
        );
        timer.cancel();
      }
    });
  }

  Future<Map<String, dynamic>?> getDeviceStatus(String deviceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final device =
          await _supabase
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

  Future<void> forceSyncDevices() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('user_devices')
          .update({'last_sync': DateTime.now().toIso8601String()})
          .eq('user_id', user.id);

      debugPrint('🔄 [DeviceService] Synchronisation forcée des appareils');
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur sync forcée: $e');
    }
  }

  Future<bool> _checkForceLogout() async {
    if (_currentDeviceId == null) return false;
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final latestSession =
        await _supabase
            .from('user_sessions')
            .select('force_logout, is_active')
            .eq('device_id', _currentDeviceId!)
            .eq('user_id', user.id)
            .eq('is_active', true)
            .order('last_activity', ascending: false)
            .limit(1)
            .maybeSingle();

    final sessionForceLogout =
        latestSession?['force_logout'] == true ||
        latestSession?['is_active'] == false;

    return sessionForceLogout;
  }

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

  Future<List<Map<String, dynamic>>>
  getActiveDevicesWithSessionsExcludingCurrent() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final devices = await getOtherUserDevices();
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
          'is_current_device': false,
        });
      }

      return result;
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur récupération sessions: $e');
      return [];
    }
  }

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

  // ============= SESSION MANAGEMENT =============
  Future<void> _createSession(String deviceId) async {
    final session = _supabase.auth.currentSession;
    final token = session?.accessToken;
    if (token == null) return;

    _currentSessionToken = token;

    try {
      await _supabase.from('user_sessions').upsert({
        'user_id': session?.user.id,
        'device_id': deviceId,
        'session_token': token,
        'is_active': true,
        'force_logout': false,
        'last_activity': DateTime.now().toIso8601String(),
      }, onConflict: 'session_token');

      debugPrint('🔹 Session créée/mise à jour (token Supabase)');
    } catch (e) {
      debugPrint('❌ Erreur création session: $e');
      rethrow;
    }
  }

  Future<void> _updateSessionActivity() async {
    if (_currentSessionToken == null) return;

    try {
      await _supabase
          .from('user_sessions')
          .update({'last_activity': DateTime.now().toIso8601String()})
          .eq('session_token', _currentSessionToken!);
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur mise à jour session: $e');
    }
  }

  // ============= PRIVATE METHODS (VERSION ROBUSTE) =============

  Future<String> _generateDeviceId() async {
    try {
      if (kIsWeb) {
        return _generateWebDeviceId();
      } else if (Platform.isAndroid) {
        try {
          AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
          return androidInfo.id;
        } catch (e) {
          debugPrint(
            '⚠️ [DeviceService] Plugin device_info non disponible, utilisation UUID',
          );
          return _generateFallbackDeviceId();
        }
      } else if (Platform.isIOS) {
        try {
          IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
          return iosInfo.identifierForVendor ?? _generateFallbackDeviceId();
        } catch (e) {
          debugPrint(
            '⚠️ [DeviceService] Plugin device_info non disponible, utilisation UUID',
          );
          return _generateFallbackDeviceId();
        }
      }
    } catch (e) {
      debugPrint('❌ [DeviceService] Erreur génération ID: $e');
    }
    return _generateFallbackDeviceId();
  }

  String _generateFallbackDeviceId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(999999);
    return 'device_${timestamp}_$randomSuffix';
  }

  String _generateWebDeviceId() {
    final userAgent = kIsWeb ? 'web_browser' : 'unknown';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'web_${userAgent.hashCode}_${timestamp}_$random';
  }

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

  Future<String> _getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      debugPrint(
        '⚠️ [DeviceService] Plugin package_info non disponible, version par défaut',
      );
      return '1.0.0+1';
    }
  }

  String _getDeviceType() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid || Platform.isIOS) return 'mobile';
    return 'unknown';
  }

  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

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
