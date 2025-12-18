/// ============================================================
/// DEPRECATED - Utiliser features/profile/profile.dart
/// ============================================================
///
/// @deprecated Ce fichier est conservé pour compatibilité.
/// Pour les nouveaux développements, utiliser:
/// ```dart
/// import 'package:mukhliss/features/profile/profile.dart';
/// ```
library;

import 'package:flutter/foundation.dart';

/// Ancien modèle Client - Conservé pour compatibilité
/// @deprecated Utiliser ProfileEntity de features/profile/
@immutable
class Client {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String adr;
  final String tel;
  final String password;
  final String updatedAt;
  final int code_unique;

  const Client({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.adr,
    required this.tel,
    required this.code_unique,
    required this.password,
    required this.updatedAt,
  });
}
