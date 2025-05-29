class UserSession {
  final String id;
  final String userId;
  final String deviceId;
  final String sessionToken;
  final DateTime createdAt;
  final DateTime lastActivity;
  final bool isActive;
  final bool forceLogout;

  UserSession({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.sessionToken,
    required this.createdAt,
    required this.lastActivity,
    this.isActive = true,
    this.forceLogout = false,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      sessionToken: json['session_token'],
      createdAt: DateTime.parse(json['created_at']),
      lastActivity: DateTime.parse(json['last_activity']),
      isActive: json['is_active'] ?? true,
      forceLogout: json['force_logout'] ?? false,
    );
  }
}
