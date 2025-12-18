/// ============================================================
/// Offer Entity - Domain Layer
/// ============================================================
///
/// Entité pure représentant une offre.
/// Pas de logique JSON ici (c'est le rôle du Model).
library;

/// Entité représentant une offre de points
class OfferEntity {
  final String id;
  final String storeId;
  final double minAmount;
  final double pointsGiven;
  final bool isActive;
  final DateTime createdAt;

  const OfferEntity({
    required this.id,
    required this.storeId,
    required this.minAmount,
    required this.pointsGiven,
    required this.isActive,
    required this.createdAt,
  });

  /// Calcule les points pour un montant donné
  double calculatePoints(double amount) {
    if (!isActive || amount < minAmount) return 0;
    return (amount / minAmount).floor() * pointsGiven;
  }

  /// Vérifie si le montant est éligible
  bool isEligible(double amount) => isActive && amount >= minAmount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfferEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'OfferEntity(id: $id, storeId: $storeId, points: $pointsGiven)';
}
