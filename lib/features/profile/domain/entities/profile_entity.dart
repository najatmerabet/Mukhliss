/// ============================================================
/// Profile Entity - Domain Layer
/// ============================================================
///
/// Entité représentant le profil d'un utilisateur/client.
library;

/// Entité représentant le profil d'un client
class ProfileEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? address;
  final int? uniqueCode;
  final int totalPoints;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.address,
    this.uniqueCode,
    this.totalPoints = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Nom complet
  String get fullName => '$firstName $lastName'.trim();

  /// Initiales pour l'avatar
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  /// Vérifie si le profil est complet
  bool get isComplete =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      email.isNotEmpty &&
      phone != null &&
      phone!.isNotEmpty;

  /// Crée une copie avec des modifications
  ProfileEntity copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    int? uniqueCode,
    int? totalPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      totalPoints: totalPoints ?? this.totalPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ProfileEntity(id: $id, name: $fullName)';
}
