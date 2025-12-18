/// ============================================================
/// User Entity - Domain Layer
/// ============================================================
///
/// Entité représentant un utilisateur authentifié.
/// C'est le modèle de domaine, indépendant de Supabase/Firebase.
library;

import 'package:flutter/foundation.dart';

/// Modèle utilisateur unifié (indépendant de Supabase/Firebase)
///
/// Nommé AppUser pour éviter le conflit avec Supabase.User
@immutable
class AppUser {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.photoUrl,
    this.emailVerified = false,
    this.createdAt,
  });

  /// Nom complet de l'utilisateur
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? email ?? 'Utilisateur';
  }

  /// Initiales pour l'avatar
  String get initials {
    final first = firstName?.isNotEmpty == true ? firstName![0] : '';
    final last = lastName?.isNotEmpty == true ? lastName![0] : '';
    if (first.isEmpty && last.isEmpty) {
      return email?.isNotEmpty == true ? email![0].toUpperCase() : 'U';
    }
    return '$first$last'.toUpperCase();
  }

  /// Copie avec modification
  AppUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
    bool? emailVerified,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'AppUser(id: $id, email: $email)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser &&
        other.id == id &&
        other.email == email &&
        other.firstName == firstName &&
        other.lastName == lastName;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
