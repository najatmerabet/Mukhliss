import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/models/categories.dart';
import 'package:mukhliss/providers/categories_provider.dart';

class CategoryHelpers {
  static String getCategoryName(WidgetRef ref, int? categoryId) {
    final categories = ref.read(categoriesListProvider).maybeWhen(
      data: (categories) => categories,
      orElse: () => <Categories>[],
    );

    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Categories(id: -1, name: 'Inconnue', nameFr: 'Inconnue', nameAr: 'غير معروف', nameEn: 'Unknown'),
    );

    return category.name;
  }

  static Categories getCategory(WidgetRef ref, int? categoryId) {
    final categories = ref.read(categoriesListProvider).maybeWhen(
      data: (categories) => categories,
      orElse: () => <Categories>[],
    );

    return categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Categories(id: -1, name: 'Inconnue', nameFr: 'Inconnue', nameAr: 'غير معروف', nameEn: 'Unknown'),
    );
  }
}