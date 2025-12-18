/// ============================================================
/// Profile Remote DataSource - Data Layer
/// ============================================================
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mukhliss/core/logger/app_logger.dart';
import '../models/profile_model.dart';

/// Interface pour la source de données distante
abstract class ProfileRemoteDataSource {
  Future<ProfileModel?> getProfileById(String id);
  Future<void> updateProfile(ProfileModel profile);
  Future<int> getTotalPoints(String clientId);
}

/// Implémentation Supabase
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient _client;

  ProfileRemoteDataSourceImpl({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<ProfileModel?> getProfileById(String id) async {
    try {
      final response =
          await _client.from('clients').select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return ProfileModel.fromJson(response);
    } catch (e) {
      AppLogger.error(
        'Erreur getProfileById',
        tag: 'ProfileDataSource',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateProfile(ProfileModel profile) async {
    try {
      await _client
          .from('clients')
          .update(profile.toJson())
          .eq('id', profile.id);

      AppLogger.info(
        'Profile updated: ${profile.id}',
        tag: 'ProfileDataSource',
      );
    } catch (e) {
      AppLogger.error(
        'Erreur updateProfile',
        tag: 'ProfileDataSource',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<int> getTotalPoints(String clientId) async {
    try {
      final response =
          await _client
              .from('clients')
              .select('points_total')
              .eq('id', clientId)
              .maybeSingle();

      return response?['points_total'] as int? ?? 0;
    } catch (e) {
      AppLogger.error(
        'Erreur getTotalPoints',
        tag: 'ProfileDataSource',
        error: e,
      );
      return 0;
    }
  }
}
