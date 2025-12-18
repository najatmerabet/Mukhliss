import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/features/stores/domain/entities/category_entity.dart';
import 'package:mukhliss/core/providers/langue_provider.dart';
import 'package:mukhliss/features/stores/data/services/categories_service.dart';

final categoriesServiceProvider = Provider<CategoriesService>((ref) {
  return CategoriesService();
});

/// Primary provider that returns CategoryEntity list (Clean Architecture)
final categoriesListProvider = FutureProvider<List<CategoryEntity>>((
  ref,
) async {
  final categoriesService = ref.read(categoriesServiceProvider);
  final models = await categoriesService.fetchCategories();

  // Convert CategoryModel to CategoryEntity (domain layer)
  return models.map((model) => model.toEntity()).toList();
});

// Main categories provider - returns List<CategoryEntity>
final categoriesProvider = categoriesListProvider;

/// Localized categories provider - triggers rebuild on language change
final localizedCategoriesProvider = FutureProvider<List<CategoryEntity>>((
  ref,
) async {
  final categories = await ref.watch(categoriesListProvider.future);
  // Note: languageProvider is watched to trigger rebuild on language change
  // Use category.getName(locale.languageCode) in the UI for localized names
  ref.watch(languageProvider);
  return categories;
});

/// Provider for a specific category by ID
final categoryByIdProvider = Provider.family<CategoryEntity?, int>((ref, id) {
  final categoriesAsync = ref.watch(categoriesListProvider);

  return categoriesAsync.whenData((categories) {
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }).value;
});
