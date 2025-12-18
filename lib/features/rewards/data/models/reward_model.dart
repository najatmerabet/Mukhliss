/// ============================================================
/// Reward Model - Data Layer
/// ============================================================
///
/// DTO pour la sérialisation JSON depuis Supabase.
library;

import 'package:flutter/foundation.dart';
import '../../domain/entities/reward_entity.dart';

/// Model pour la sérialisation d'une Reward
class RewardModel {
  final String id;
  final String name;
  final int pointsRequired;
  final String? description;
  final bool isActive;
  final String storeId;
  final String? storeName;
  final String? storeLogoUrl;
  final String? storeAddress;
  final DateTime createdAt;

  const RewardModel({
    required this.id,
    required this.name,
    required this.pointsRequired,
    this.description,
    required this.isActive,
    required this.storeId,
    this.storeName,
    this.storeLogoUrl,
    this.storeAddress,
    required this.createdAt,
  });

  /// Crée depuis JSON (Supabase)
  factory RewardModel.fromJson(Map<String, dynamic> json) {
    // Gérer la jointure avec magasins
    final magasin = json['magasins'] as Map<String, dynamic>?;

    // Debug: voir les données du magasin
    debugPrint('🎁 Reward magasin data: $magasin');
    debugPrint('🖼️ Reward storeLogoUrl: ${magasin?['logoUrl']}');

    return RewardModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      pointsRequired: json['points_required'] as int? ?? 0,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      storeId: json['magasin_id'] as String? ?? '',
      storeName: magasin?['nom_enseigne'] as String?,
      storeLogoUrl: magasin?['logoUrl'] as String?,
      storeAddress: magasin?['adresse'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points_required': pointsRequired,
      'description': description,
      'is_active': isActive,
      'magasin_id': storeId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convertit en entité du domain
  RewardEntity toEntity() {
    return RewardEntity(
      id: id,
      name: name,
      pointsRequired: pointsRequired,
      description: description,
      isActive: isActive,
      storeId: storeId,
      storeName: storeName,
      storeLogoUrl: storeLogoUrl,
      storeAddress: storeAddress,
      createdAt: createdAt,
    );
  }

  /// Crée depuis une entité
  factory RewardModel.fromEntity(RewardEntity entity) {
    return RewardModel(
      id: entity.id,
      name: entity.name,
      pointsRequired: entity.pointsRequired,
      description: entity.description,
      isActive: entity.isActive,
      storeId: entity.storeId,
      storeName: entity.storeName,
      storeLogoUrl: entity.storeLogoUrl,
      storeAddress: entity.storeAddress,
      createdAt: entity.createdAt,
    );
  }
}
