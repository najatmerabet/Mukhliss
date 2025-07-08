

class Offers {
  final String id;
  final String magasin_id;
  final double min_amount;
  final double points_given;
  final bool is_active;
  final DateTime createdAt;

  const Offers({
    required this.id,
    required this.magasin_id,
    required this.min_amount,
    required this.points_given,
    required this.is_active,
    required this.createdAt,
  });
  factory Offers.fromJson(Map<String, dynamic> json) {
    return Offers(
      id: json['id'] as String? ?? '',
      magasin_id: json['magasin_id'] as String? ?? '',
      min_amount: (json['min_amount'] as num?)?.toDouble() ?? 0.0,
      points_given: (json['points_given'] as num?)?.toDouble() ?? 0.0,
      is_active: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

}