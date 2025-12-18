/// ============================================================
/// DEPRECATED - Utiliser features/profile/profile.dart
/// ============================================================
library;

/// @deprecated Utiliser ClientStoreEntity de features/profile/
class ClientMagazin {
  final int id;
  final String client_id;
  final String magasin_id;
  final String createdAt;
  final int cumulpoint;
  final int solde;

  const ClientMagazin({
    required this.id,
    required this.client_id,
    required this.magasin_id,
    required this.createdAt,
    required this.cumulpoint,
    required this.solde,
  });

  factory ClientMagazin.fromJson(Map<String, dynamic> json) {
    return ClientMagazin(
      id: json['id'] as int? ?? 0,
      client_id: json['client_id'] as String? ?? '',
      magasin_id: json['magasin_id'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      cumulpoint: json['cumulpoint'] as int? ?? 0,
      solde: json['solde'] as int? ?? 0,
    );
  }
}
