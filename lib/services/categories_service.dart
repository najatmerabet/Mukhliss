import 'package:mukhliss/models/categories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoriesService {
  final SupabaseClient _client = Supabase.instance.client;
  
  Future<List<Categories>> fetchCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select();
       print('Données reçues de Supabase: $response');
      return (response as List)
          .map((json) => Categories.fromJson(json))
          .toList();
    } catch (error) {
      throw 'Failed to fetch categories: $error';
    }
  }

  Future<List<Categories>> fetchCategoriesWithLocalization(String languageCode) async {
    final categories = await fetchCategories();
    // Les catégories contiennent déjà toutes les traductions
    // La localisation se fait au niveau de l'affichage avec getName()
    return categories;
  }

}