/// ============================================================
/// Profile Model - Data Layer
/// ============================================================
library;

import '../../domain/entities/profile_entity.dart';

/// Model pour la sérialisation d'un Profile
class ProfileModel {
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

  const ProfileModel({
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

  /// Crée depuis JSON (Supabase - table clients)
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      firstName: json['prenom'] as String? ?? '',
      lastName: json['nom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['tel'] as String?,
      address: json['adr'] as String?,
      uniqueCode: json['code_unique'] as int?,
      totalPoints: json['points_total'] as int? ?? 0,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'] as String)
              : null,
    );
  }

  /// Convertit en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prenom': firstName,
      'nom': lastName,
      'email': email,
      'tel': phone,
      'adr': address,
      'code_unique': uniqueCode,
      'points_total': totalPoints,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convertit en entité du domain
  ProfileEntity toEntity() {
    return ProfileEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      address: address,
      uniqueCode: uniqueCode,
      totalPoints: totalPoints,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Crée depuis une entité
  factory ProfileModel.fromEntity(ProfileEntity entity) {
    return ProfileModel(
      id: entity.id,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      phone: entity.phone,
      address: entity.address,
      uniqueCode: entity.uniqueCode,
      totalPoints: entity.totalPoints,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
