import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/models/categories.dart';
import 'package:mukhliss/providers/langue_provider.dart';
import 'package:mukhliss/services/categories_service.dart';


final categoriesServiceProvider = Provider<CategoriesService>((ref) {
  return CategoriesService();
});


final categoriesListProvider = FutureProvider<List<Categories>>((ref) async {
  final categoriesService = ref.read(categoriesServiceProvider);
  return await categoriesService.fetchCategories();
});

final localizedCategoriesProvider = FutureProvider<List<Categories>>((ref) async {
  final categories = await ref.watch(categoriesListProvider.future);
  final currentLocale = ref.watch(languageProvider);
  
  // Les catégories restent les mêmes, seul l'affichage change
  // Vous pouvez utiliser category.getName(currentLocale.languageCode) dans l'UI
  return categories;
});
// Provider pour une catégorie spécifique avec nom localisé
final categoryByIdProvider = Provider.family<Categories?, int>((ref, id) {
  final categoriesAsync = ref.watch(categoriesListProvider);
  
  return categoriesAsync.whenData((categories) {
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }).value;
});
