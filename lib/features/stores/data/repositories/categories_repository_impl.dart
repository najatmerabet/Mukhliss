import 'package:mukhliss/features/stores/data/datasources/categories_remote_datasource.dart';
import 'package:mukhliss/features/stores/domain/entities/category_entity.dart';
import 'package:mukhliss/features/stores/domain/repositories/categories_repository.dart';

/// Implementation of CategoriesRepository
class CategoriesRepositoryImpl implements CategoriesRepository {
  final CategoriesRemoteDataSource _remoteDataSource;

  CategoriesRepositoryImpl({
    required CategoriesRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final models = await _remoteDataSource.getCategories();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<CategoryEntity?> getCategoryById(int id) async {
    final model = await _remoteDataSource.getCategoryById(id);
    return model?.toEntity();
  }
}
