/// ============================================================
/// Offer Model - Data Layer
/// ============================================================
///
/// DTO pour la sérialisation JSON depuis Supabase.
library;

import '../../domain/entities/offer_entity.dart';

/// Model pour la sérialisation d'une Offer
class OfferModel {
  final String id;
  final String magasinId;
  final double minAmount;
  final double pointsGiven;
  final bool isActive;
  final DateTime createdAt;

  const OfferModel({
    required this.id,
    required this.magasinId,
    required this.minAmount,
    required this.pointsGiven,
    required this.isActive,
    required this.createdAt,
  });

  /// Crée depuis JSON (Supabase)
  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] as String? ?? '',
      magasinId: json['magasin_id'] as String? ?? '',
      minAmount: (json['min_amount'] as num?)?.toDouble() ?? 0.0,
      pointsGiven: (json['points_given'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'magasin_id': magasinId,
      'min_amount': minAmount,
      'points_given': pointsGiven,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convertit en entité du domain
  OfferEntity toEntity() {
    return OfferEntity(
      id: id,
      storeId: magasinId,
      minAmount: minAmount,
      pointsGiven: pointsGiven,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  /// Crée depuis une entité
  factory OfferModel.fromEntity(OfferEntity entity) {
    return OfferModel(
      id: entity.id,
      magasinId: entity.storeId,
      minAmount: entity.minAmount,
      pointsGiven: entity.pointsGiven,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}
