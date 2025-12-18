/// ============================================================
/// Store Model - Data Layer
/// ============================================================
///
/// DTO (Data Transfer Object) pour la sérialisation JSON.
/// Fait le pont entre l'API et le domain.
library;

import 'package:flutter/foundation.dart';
import '../../domain/entities/store_entity.dart';

class StoreModel {
  final String id;
  final String nomEnseigne;
  final String? description;
  final String? logoUrl;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String? adresse;
  final String? telephone;
  final String? categorieId;
  final bool isActive;
  final DateTime? createdAt;

  const StoreModel({
    required this.id,
    required this.nomEnseigne,
    this.description,
    this.logoUrl,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.adresse,
    this.telephone,
    this.categorieId,
    this.isActive = true,
    this.createdAt,
  });

  /// Crée un StoreModel depuis JSON (Supabase)
  factory StoreModel.fromJson(Map<String, dynamic> json) {
    // Debug: voir les valeurs de logo
    debugPrint('🖼️ logoUrl=${json['logoUrl']}');

    // Extraire latitude/longitude depuis geom si disponible
    double lat = 0.0;
    double lng = 0.0;
    if (json['geom'] != null) {
      // geom est au format PostGIS, extraire les coordonnées
      final geom = json['geom'];
      if (geom is Map && geom['coordinates'] != null) {
        final coords = geom['coordinates'] as List;
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    }
    // Fallback sur latitude/longitude directes si présentes
    lat = (json['latitude'] as num?)?.toDouble() ?? lat;
    lng = (json['longitude'] as num?)?.toDouble() ?? lng;

    return StoreModel(
      id: json['id'].toString(), // Peut être int ou String
      nomEnseigne: json['nom_enseigne'] as String? ?? '',
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?, // U majuscule !
      imageUrl: json['imageUrl'] as String?,
      latitude: lat,
      longitude: lng,
      adresse: json['adresse'] as String?,
      telephone: json['telephone'] as String?,
      categorieId: json['Categorieid']?.toString(), // Peut être int ou String
      isActive: true,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
    );
  }

  /// Convertit en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_enseigne': nomEnseigne,
      'description': description,
      'logourl': logoUrl,
      'imageurl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'adresse': adresse,
      'telephone': telephone,
      'categorie_id': categorieId,
      // Note: is_active n'existe pas dans la table magasins
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Convertit en entité du domain
  StoreEntity toEntity() {
    return StoreEntity(
      id: id,
      name: nomEnseigne,
      description: description,
      logoUrl: logoUrl,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      address: adresse,
      phone: telephone,
      categoryId: categorieId,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  /// Crée un StoreModel depuis une entité
  factory StoreModel.fromEntity(StoreEntity entity) {
    return StoreModel(
      id: entity.id,
      nomEnseigne: entity.name,
      description: entity.description,
      logoUrl: entity.logoUrl,
      imageUrl: entity.imageUrl,
      latitude: entity.latitude,
      longitude: entity.longitude,
      adresse: entity.address,
      telephone: entity.phone,
      categorieId: entity.categoryId,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}
