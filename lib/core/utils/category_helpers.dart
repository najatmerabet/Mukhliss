import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/features/stores/domain/entities/category_entity.dart';
import 'package:mukhliss/features/stores/presentation/providers/categories_provider.dart';

class CategoryHelpers {
  static String getCategoryName(WidgetRef ref, String? categoryId) {
    if (categoryId == null) return 'Inconnue';

    final categoryIdInt = int.tryParse(categoryId);
    if (categoryIdInt == null) return 'Inconnue';

    final categories = ref
        .read(categoriesListProvider)
        .maybeWhen(
          data: (categories) => categories,
          orElse: () => <CategoryEntity>[],
        );

    final category = categories.firstWhere(
      (c) => c.id == categoryIdInt,
      orElse:
          () => const CategoryEntity(
            id: -1,
            name: 'Inconnue',
            nameFr: 'Inconnue',
            nameAr: 'غير معروف',
            nameEn: 'Unknown',
          ),
    );

    return category.name;
  }

  static CategoryEntity getCategory(WidgetRef ref, String? categoryId) {
    final categoryIdInt = categoryId != null ? int.tryParse(categoryId) : null;

    final categories = ref
        .read(categoriesListProvider)
        .maybeWhen(
          data: (categories) => categories,
          orElse: () => <CategoryEntity>[],
        );

    return categories.firstWhere(
      (c) => c.id == categoryIdInt,
      orElse:
          () => const CategoryEntity(
            id: -1,
            name: 'Inconnue',
            nameFr: 'Inconnue',
            nameAr: 'غير معروف',
            nameEn: 'Unknown',
          ),
    );
  }
}
