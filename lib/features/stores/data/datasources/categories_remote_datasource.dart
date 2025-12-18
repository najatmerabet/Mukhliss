import 'package:mukhliss/core/logger/app_logger.dart';
import 'package:mukhliss/features/stores/data/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for fetching categories from Supabase
class CategoriesRemoteDataSource {
  final SupabaseClient _client;

  CategoriesRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Fetch all categories from Supabase 'categories' table
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _client.from('categories').select();
      AppLogger.debug(
        'Categories fetched from Supabase: ${response.length} items',
      );

      return (response as List)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error) {
      AppLogger.error('Failed to fetch categories: $error');
      throw Exception('Failed to fetch categories: $error');
    }
  }

  /// Fetch a single category by ID
  Future<CategoryModel?> getCategoryById(int id) async {
    try {
      final response =
          await _client.from('categories').select().eq('id', id).maybeSingle();

      if (response == null) {
        AppLogger.warning('Category with id $id not found');
        return null;
      }

      return CategoryModel.fromJson(response);
    } catch (error) {
      AppLogger.error('Failed to fetch category by id: $error');
      throw Exception('Failed to fetch category by id: $error');
    }
  }
}
