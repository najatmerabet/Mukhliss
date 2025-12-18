/// ============================================================
/// Category Entity - Domain Layer
/// ============================================================
library;

/// Entité représentant une catégorie de magasin
class CategoryEntity {
  final int id;
  final String name;
  final String nameFr;
  final String nameAr;
  final String nameEn;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.nameFr,
    required this.nameAr,
    required this.nameEn,
  });

  /// Obtient le nom selon la langue
  String getName(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return nameFr.isNotEmpty ? nameFr : name;
      case 'en':
        return nameEn.isNotEmpty ? nameEn : name;
      case 'ar':
        return nameAr.isNotEmpty ? nameAr : name;
      default:
        return name;
    }
  }

  /// Nom localisé avec fallback
  String getLocalizedName(String languageCode) {
    final localizedName = getName(languageCode);
    return localizedName.isNotEmpty ? localizedName : name;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
