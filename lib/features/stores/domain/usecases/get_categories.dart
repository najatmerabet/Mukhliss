import 'package:mukhliss/features/stores/domain/entities/category_entity.dart';
import 'package:mukhliss/features/stores/domain/repositories/categories_repository.dart';

/// Use case for getting all categories
class GetCategories {
  final CategoriesRepository _repository;

  GetCategories(this._repository);

  Future<List<CategoryEntity>> call() async {
    return await _repository.getCategories();
  }
}

/// Use case for getting a category by ID
class GetCategoryById {
  final CategoriesRepository _repository;

  GetCategoryById(this._repository);

  Future<CategoryEntity?> call(int id) async {
    return await _repository.getCategoryById(id);
  }
}
