/// ============================================================
/// Profile Providers - Presentation Layer
/// ============================================================
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/profile_usecases.dart';
import '../../data/repositories/profile_repository_impl.dart';

// ============================================================
// PROVIDERS D'INJECTION DE DÉPENDANCES
// ============================================================

/// Provider du repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl();
});

/// Provider du GetCurrentProfileUseCase
final getCurrentProfileUseCaseProvider = Provider<GetCurrentProfileUseCase>((
  ref,
) {
  return GetCurrentProfileUseCase(ref.watch(profileRepositoryProvider));
});

/// Provider du UpdateProfileUseCase
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(profileRepositoryProvider));
});

/// Provider du GetTotalPointsUseCase
final getTotalPointsUseCaseProvider = Provider<GetTotalPointsUseCase>((ref) {
  return GetTotalPointsUseCase(ref.watch(profileRepositoryProvider));
});

// ============================================================
// PROVIDERS DE DONNÉES
// ============================================================

/// Provider pour le profil courant
final currentProfileProvider = FutureProvider<ProfileEntity?>((ref) async {
  final useCase = ref.watch(getCurrentProfileUseCaseProvider);
  return await useCase();
});

/// Provider pour les points totaux
final totalPointsProvider = FutureProvider.family<int, String>((
  ref,
  clientId,
) async {
  final useCase = ref.watch(getTotalPointsUseCaseProvider);
  return await useCase(clientId);
});

// ============================================================
// STATE NOTIFIER POUR ÉDITION DU PROFIL
// ============================================================

/// État pour l'édition du profil
class ProfileEditState {
  final ProfileEntity? profile;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final bool saveSuccess;

  const ProfileEditState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.saveSuccess = false,
  });

  ProfileEditState copyWith({
    ProfileEntity? profile,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool? saveSuccess,
  }) {
    return ProfileEditState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }
}

/// Notifier pour l'édition du profil
class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  final Ref _ref;

  ProfileEditNotifier(this._ref) : super(const ProfileEditState());

  /// Charge le profil
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final useCase = _ref.read(getCurrentProfileUseCaseProvider);
      final profile = await useCase();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Met à jour le profil
  Future<bool> updateProfile(ProfileEntity profile) async {
    state = state.copyWith(isSaving: true, error: null, saveSuccess: false);

    try {
      final useCase = _ref.read(updateProfileUseCaseProvider);
      await useCase(profile);

      state = state.copyWith(
        profile: profile,
        isSaving: false,
        saveSuccess: true,
      );

      // Rafraîchir le profil
      _ref.invalidate(currentProfileProvider);

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Met à jour un champ
  void updateField(ProfileEntity Function(ProfileEntity) updater) {
    if (state.profile != null) {
      state = state.copyWith(profile: updater(state.profile!));
    }
  }
}

/// Provider du ProfileEditNotifier
final profileEditNotifierProvider =
    StateNotifierProvider<ProfileEditNotifier, ProfileEditState>((ref) {
      return ProfileEditNotifier(ref);
    });
