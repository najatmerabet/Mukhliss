/// ============================================================
/// Device Entity - Domain Layer
/// ============================================================
library;

/// Entité représentant un appareil utilisateur
class DeviceEntity {
  final String id;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String platform;
  final String? appVersion;
  final DateTime lastActiveAt;
  final DateTime createdAt;
  final bool isActive;
  final String? pushToken;
  final Map<String, dynamic>? deviceInfo;

  const DeviceEntity({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.platform,
    this.appVersion,
    required this.lastActiveAt,
    required this.createdAt,
    this.isActive = true,
    this.pushToken,
    this.deviceInfo,
  });

  @override
  String toString() =>
      'DeviceEntity(id: $id, deviceName: $deviceName, platform: $platform)';
}

/// Entité représentant une session utilisateur
class SessionEntity {
  final String id;
  final String userId;
  final String deviceId;
  final String sessionToken;
  final DateTime createdAt;
  final DateTime lastActivity;
  final bool isActive;
  final bool forceLogout;

  const SessionEntity({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.sessionToken,
    required this.createdAt,
    required this.lastActivity,
    this.isActive = true,
    this.forceLogout = false,
  });
}
