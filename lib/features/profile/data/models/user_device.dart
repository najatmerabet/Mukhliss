/// ============================================================
/// DEPRECATED - Utiliser features/profile/profile.dart
/// ============================================================
library;

/// @deprecated Utiliser DeviceEntity de features/profile/
class UserDevice {
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

  UserDevice({
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

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      deviceName: json['device_name'],
      deviceType: json['device_type'],
      platform: json['platform'],
      appVersion: json['app_version'],
      lastActiveAt: DateTime.parse(json['last_active_at']),
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] ?? true,
      pushToken: json['push_token'],
      deviceInfo:
          json['device_info'] != null
              ? Map<String, dynamic>.from(json['device_info'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': deviceType,
      'platform': platform,
      'app_version': appVersion,
      'last_active_at': lastActiveAt.toIso8601String(),
      'is_active': isActive,
      'push_token': pushToken,
      'device_info': deviceInfo,
    };
  }

  UserDevice copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? deviceName,
    String? deviceType,
    String? platform,
    String? appVersion,
    DateTime? lastActiveAt,
    DateTime? createdAt,
    bool? isActive,
    String? pushToken,
    Map<String, dynamic>? deviceInfo,
  }) {
    return UserDevice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      pushToken: pushToken ?? this.pushToken,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  @override
  String toString() {
    return 'UserDevice(id: $id, deviceName: $deviceName, platform: $platform, isActive: $isActive)';
  }
}
