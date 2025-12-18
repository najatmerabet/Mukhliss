/// ============================================================
/// ClientOffer Entity - Domain Layer
/// ============================================================
///
/// Représente une offre réclamée par un client.
library;

/// Entité représentant une offre réclamée par un client
class ClaimedOfferEntity {
  final String clientId;
  final String rewardId;
  final String rewardTitle;
  final String? rewardDescription;
  final DateTime claimedAt;

  const ClaimedOfferEntity({
    required this.clientId,
    required this.rewardId,
    required this.rewardTitle,
    this.rewardDescription,
    required this.claimedAt,
  });

  /// Nombre de jours depuis la réclamation
  int get daysSinceClaimed {
    return DateTime.now().difference(claimedAt).inDays;
  }

  /// Vérifie si l'offre a été réclamée récemment (moins de 7 jours)
  bool get isRecent => daysSinceClaimed < 7;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimedOfferEntity &&
          runtimeType == other.runtimeType &&
          clientId == other.clientId &&
          rewardId == other.rewardId;

  @override
  int get hashCode => clientId.hashCode ^ rewardId.hashCode;

  @override
  String toString() =>
      'ClaimedOfferEntity(clientId: $clientId, rewardId: $rewardId)';
}
