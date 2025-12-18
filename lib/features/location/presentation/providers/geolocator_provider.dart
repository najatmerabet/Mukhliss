import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/services/geolocator_service.dart';

final geolocationServiceProvider = Provider<GeolocationService>((ref) {
  return GeolocationService();
});

// Provider pour obtenir la position actuelle
final currentPositionProvider = FutureProvider<Position>((ref) async {
  final geolocationService = ref.read(geolocationServiceProvider);
  return await geolocationService.determinePosition();
});

// Provider pour suivre la position avec un seuil de distance
final positionStreamProvider = StreamProvider.autoDispose
    .family<Position, double>((ref, distanceThreshold) {
      final geolocationService = ref.read(geolocationServiceProvider);
      return geolocationService.trackPositionWithThreshold(
        distanceThreshold: distanceThreshold,
      );
    });
