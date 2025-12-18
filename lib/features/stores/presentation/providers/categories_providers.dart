/// ============================================================
/// Categories Providers - Presentation Layer
/// ============================================================
///
/// Providers Riverpod pour la gestion des catégories.
/// Utilise Clean Architecture avec datasources.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/core/providers/langue_provider.dart';

import '../../data/datasources/categories_remote_datasource.dart';
import '../../data/repositories/categories_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/categories_repository.dart';

// ============================================================
// DATASOURCE PROVIDERS
// ============================================================

/// Provider pour la source de données distante des catégories
final categoriesRemoteDataSourceProvider = Provider<CategoriesRemoteDataSource>(
  (ref) {
    return CategoriesRemoteDataSource();
  },
);

// ============================================================
// REPOSITORY PROVIDERS
// ============================================================

/// Provider pour le repository des catégories
final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepositoryImpl(
    remoteDataSource: ref.read(categoriesRemoteDataSourceProvider),
  );
});

// ============================================================
// STATE PROVIDERS
// ============================================================

/// Provider principal pour charger toutes les catégories
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repository = ref.read(categoriesRepositoryProvider);
  return await repository.getCategories();
});

/// Provider localisé - se recharge quand la langue change
final localizedCategoriesProvider = FutureProvider<List<CategoryEntity>>((
  ref,
) async {
  // Observer le changement de langue pour déclencher un rebuild
  ref.watch(languageProvider);

  final categories = await ref.watch(categoriesProvider.future);
  return categories;
});

// ============================================================
// COMPUTED PROVIDERS
// ============================================================

/// Provider pour obtenir une catégorie par son ID
final categoryByIdProvider = Provider.family<CategoryEntity?, int>((ref, id) {
  final categoriesAsync = ref.watch(categoriesProvider);

  return categoriesAsync.whenData((categories) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }).value;
});

/// Provider pour obtenir une catégorie par son ID (String)
final categoryByStringIdProvider = Provider.family<CategoryEntity?, String>((
  ref,
  id,
) {
  final intId = int.tryParse(id);
  if (intId == null) return null;
  return ref.watch(categoryByIdProvider(intId));
});

/// Nombre total de catégories
final categoriesCountProvider = Provider<int>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.whenData((cat) => cat.length).value ?? 0;
});

// ============================================================
// LEGACY COMPATIBILITY
// ============================================================

/// @deprecated Utiliser categoriesProvider à la place
final categoriesListProvider = categoriesProvider;

/// @deprecated Utiliser categoriesRemoteDataSourceProvider
final categoriesServiceProvider = categoriesRemoteDataSourceProvider;
