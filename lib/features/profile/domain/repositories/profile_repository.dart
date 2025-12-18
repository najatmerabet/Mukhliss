/// ============================================================
/// Profile Repository Interface - Domain Layer
/// ============================================================
library;

import '../entities/profile_entity.dart';

/// Interface du repository du profil
abstract class ProfileRepository {
  /// Récupère le profil de l'utilisateur connecté
  Future<ProfileEntity?> getCurrentProfile();

  /// Récupère un profil par son ID
  Future<ProfileEntity?> getProfileById(String id);

  /// Met à jour le profil
  Future<void> updateProfile(ProfileEntity profile);

  /// Met à jour un champ spécifique
  Future<void> updateProfileField(String id, String field, dynamic value);

  /// Récupère les points totaux
  Future<int> getTotalPoints(String clientId);
}
