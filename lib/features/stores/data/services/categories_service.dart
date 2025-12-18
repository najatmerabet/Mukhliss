/// ============================================================
/// Categories Service - Data Layer
/// ============================================================
library;

import 'package:mukhliss/core/logger/app_logger.dart';
import 'package:mukhliss/features/stores/data/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Legacy service for backwards compatibility
/// This service is being phased out in favor of CategoriesRemoteDataSource
///
/// @deprecated Use CategoriesRemoteDataSource from data/datasources instead
class CategoriesService {
  final SupabaseClient _client;

  CategoriesService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Fetch all categories
  /// Returns CategoryModel instances (new architecture)
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _client.from('categories').select();
      AppLogger.debug(
        'Data received from Supabase: ${response.length} categories',
      );

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (error) {
      AppLogger.error('Failed to fetch categories: $error');
      throw Exception('Failed to fetch categories: $error');
    }
  }

  /// Fetch categories with localization
  /// Note: Localization is now handled at the entity level using getName()
  Future<List<CategoryModel>> fetchCategoriesWithLocalization(
    String languageCode,
  ) async {
    final categories = await fetchCategories();
    // Categories already contain all translations
    // Localization is done at display level with CategoryEntity.getName()
    return categories;
  }
}
