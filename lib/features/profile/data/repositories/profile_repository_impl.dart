/// ============================================================
/// Profile Repository Implementation - Data Layer
/// ============================================================
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final SupabaseClient _client;

  ProfileRepositoryImpl({
    ProfileRemoteDataSource? remoteDataSource,
    SupabaseClient? client,
  }) : _remoteDataSource = remoteDataSource ?? ProfileRemoteDataSourceImpl(),
       _client = client ?? Supabase.instance.client;

  @override
  Future<ProfileEntity?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return await getProfileById(user.id);
  }

  @override
  Future<ProfileEntity?> getProfileById(String id) async {
    final model = await _remoteDataSource.getProfileById(id);
    return model?.toEntity();
  }

  @override
  Future<void> updateProfile(ProfileEntity profile) async {
    final model = ProfileModel.fromEntity(profile);
    await _remoteDataSource.updateProfile(model);
  }

  @override
  Future<void> updateProfileField(
    String id,
    String field,
    dynamic value,
  ) async {
    await _client
        .from('clients')
        .update({field: value, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  @override
  Future<int> getTotalPoints(String clientId) async {
    return await _remoteDataSource.getTotalPoints(clientId);
  }
}
