/// ============================================================
/// ClientStore Entity - Domain Layer
/// ============================================================
///
/// Relation entre un client et un magasin (points accumulés, solde)
library;

/// Entité représentant la relation client-magasin
class ClientStoreEntity {
  final int id;
  final String clientId;
  final String storeId;
  final DateTime createdAt;
  final int cumulPoints;
  final int balance;

  const ClientStoreEntity({
    required this.id,
    required this.clientId,
    required this.storeId,
    required this.createdAt,
    required this.cumulPoints,
    required this.balance,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientStoreEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model pour JSON
class ClientStoreModel {
  final int id;
  final String clientId;
  final String storeId;
  final String createdAt;
  final int cumulPoints;
  final int balance;

  const ClientStoreModel({
    required this.id,
    required this.clientId,
    required this.storeId,
    required this.createdAt,
    required this.cumulPoints,
    required this.balance,
  });

  factory ClientStoreModel.fromJson(Map<String, dynamic> json) {
    return ClientStoreModel(
      id: json['id'] as int? ?? 0,
      clientId: json['client_id'] as String? ?? '',
      storeId: json['magasin_id'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      cumulPoints: json['cumulpoint'] as int? ?? 0,
      balance: json['solde'] as int? ?? 0,
    );
  }

  ClientStoreEntity toEntity() {
    return ClientStoreEntity(
      id: id,
      clientId: clientId,
      storeId: storeId,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      cumulPoints: cumulPoints,
      balance: balance,
    );
  }
}
