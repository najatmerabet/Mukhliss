import 'package:mukhliss/features/stores/domain/entities/category_entity.dart';

/// Repository interface for Categories
abstract class CategoriesRepository {
  /// Get all categories
  Future<List<CategoryEntity>> getCategories();

  /// Get a single category by ID
  Future<CategoryEntity?> getCategoryById(int id);
}
