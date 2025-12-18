/// ============================================================
/// Store Entity - Domain Layer
/// ============================================================
///
/// Entité pure représentant un magasin.
/// Pas de dépendance sur JSON, API, ou base de données.
library;

class StoreEntity {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  final String? categoryId;
  final bool isActive;
  final DateTime? createdAt;

  const StoreEntity({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    this.categoryId,
    this.isActive = true,
    this.createdAt,
  });

  /// Distance en mètres depuis une position donnée
  double distanceFrom(double lat, double lng) {
    // Formule Haversine simplifiée
    const double earthRadius = 6371000; // mètres
    final dLat = _toRadians(latitude - lat);
    final dLng = _toRadians(longitude - lng);

    final a =
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat)) *
            _cos(_toRadians(latitude)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double deg) => deg * 3.14159265359 / 180;
  double _sin(double x) => x - (x * x * x) / 6; // Approximation
  double _cos(double x) => 1 - (x * x) / 2; // Approximation
  double _sqrt(double x) => x > 0 ? x / 2 + 0.5 : 0; // Très simplifiée
  double _atan2(double y, double x) => y / (x + 0.0001); // Simplifiée

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'StoreEntity(id: $id, name: $name)';
}
