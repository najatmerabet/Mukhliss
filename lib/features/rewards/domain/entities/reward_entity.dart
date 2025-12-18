/// ============================================================
/// Reward Entity - Domain Layer
/// ============================================================
///
/// Entité pure représentant une récompense.
library;

/// Entité représentant une récompense disponible
class RewardEntity {
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

  const RewardEntity({
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

  /// Crée une RewardEntity vide (pour fallback)
  factory RewardEntity.empty() {
    return RewardEntity(
      id: '',
      name: 'Récompense inconnue',
      pointsRequired: 0,
      isActive: false,
      storeId: '',
      createdAt: DateTime.now(),
    );
  }

  /// Vérifie si le client a assez de points
  bool canRedeem(int clientPoints) =>
      isActive && clientPoints >= pointsRequired;

  /// Vérifie si c'est une nouvelle récompense (moins de 7 jours)
  bool get isNew {
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    return daysSinceCreation < 7;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'RewardEntity(id: $id, name: $name, points: $pointsRequired)';
}
