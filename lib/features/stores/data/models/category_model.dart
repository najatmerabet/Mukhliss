/// ============================================================
/// Category Model - Data Layer
/// ============================================================
library;

import '../../domain/entities/category_entity.dart';

class CategoryModel {
  final int id;
  final String name;
  final String nameFr;
  final String nameAr;
  final String nameEn;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.nameFr,
    required this.nameAr,
    required this.nameEn,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameFr: json['nameFr'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameFr': nameFr,
      'nameAr': nameAr,
      'nameEn': nameEn,
    };
  }

  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      name: name,
      nameFr: nameFr,
      nameAr: nameAr,
      nameEn: nameEn,
    );
  }
}
