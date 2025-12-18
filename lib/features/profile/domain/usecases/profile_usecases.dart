/// ============================================================
/// Profile Use Cases - Domain Layer
/// ============================================================
library;

import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

/// Use case: Récupérer le profil courant
class GetCurrentProfileUseCase {
  final ProfileRepository _repository;

  GetCurrentProfileUseCase(this._repository);

  Future<ProfileEntity?> call() async {
    return await _repository.getCurrentProfile();
  }
}

/// Use case: Récupérer un profil par ID
class GetProfileByIdUseCase {
  final ProfileRepository _repository;

  GetProfileByIdUseCase(this._repository);

  Future<ProfileEntity?> call(String id) async {
    return await _repository.getProfileById(id);
  }
}

/// Use case: Mettre à jour le profil
class UpdateProfileUseCase {
  final ProfileRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<void> call(ProfileEntity profile) async {
    await _repository.updateProfile(profile);
  }
}

/// Use case: Récupérer les points
class GetTotalPointsUseCase {
  final ProfileRepository _repository;

  GetTotalPointsUseCase(this._repository);

  Future<int> call(String clientId) async {
    return await _repository.getTotalPoints(clientId);
  }
}
