

import 'package:mukhliss/models/store.dart';

class Rewards {
 
  final String id;
  final String name;
  final int points_required;
   final String? description;
  final bool is_active;
  final Store magasin;
  final DateTime created_at;

  Rewards({
    required this.id,
    required this.name,
    required this.points_required,
    this.description,
    required this.is_active,
    required this.magasin,
    required this.created_at,
  
  });

factory Rewards.fromJson(Map<String, dynamic> json) {
  return Rewards(
    id: json['id'] as String,
    name: json['name'] as String,
    points_required: json['points_required'] as int,
    description: json['description'] as String?,
    is_active: json['is_active'] as bool,
    magasin: json['magasins'] != null 
      ? Store.fromJson(json['magasins'] as Map<String, dynamic>)
      : Store(id: '', nom_enseigne: 'Magasin inconnu', siret: '', adresse: '', ville: '', code_postal: '', telephone: '', description: '', geom: {}, Categorieid: 0), // Valeur par défaut
    created_at: DateTime.parse(json['created_at'] as String),
  );
}

 
}