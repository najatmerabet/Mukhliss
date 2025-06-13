


import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Categories {
  final int id;
  final String name;
  final String nameFr;
  final String nameAr;
  final String nameEn;

  Categories({
    required this.id,
    required this.name,
    required this.nameFr,
    required this.nameAr,
    required this.nameEn,
   
  });

   factory Categories.fromJson(Map<String, dynamic> json) {
    return Categories(
      id: json['id'] as int? ?? 0, // Valeur par défaut si null
     // Valeur par défaut si null
      name: json['name'] as String? ?? '', // Valeur par défaut si null
      nameFr: json['nameFr'] as String? ?? '', // Valeur par défaut si null
      nameAr: json['nameAr'] as String? ?? '', // Valeur par défaut si null
      nameEn: json['nameEn'] as String? ?? '', // Valeur par défaut si null
    );
  }

  // Méthode pour obtenir le nom selon la langue
  String getName(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return nameFr;
      case 'en':
        return nameEn;
      case 'ar':
        return nameAr;
      default:
        return nameEn; // Fallback à l'anglais
    }
  }

   // Méthode utilitaire pour obtenir le nom avec fallback
  String getLocalizedName(String languageCode) {
    final localizedName = getName(languageCode);
    return localizedName.isNotEmpty ? localizedName : name;
  }

}

