import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/services/osrm_service.dart';

// Provider for the routing service
final routingServiceProvider = Provider((ref) {
  return OSRMRoutingService();
});

// Provider to get both route coordinates and info together
final routeDataProvider = FutureProvider.family<RouteData, RouteParams>((
  ref,
  params,
) async {
  final routingService = ref.read(routingServiceProvider);
  final coordinates = await routingService.getRouteCoordinates(
    params.start,
    params.end,
    params.mode,
  );
  final info = await routingService.getRouteInfo(
    params.start,
    params.end,
    params.mode,
  );
  return RouteData(coordinates: coordinates, info: info);
});

// Class to hold route parameters
class RouteParams {
  final LatLng start;
  final LatLng end;
  final TransportMode mode;

  const RouteParams({
    required this.start,
    required this.end,
    required this.mode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteParams &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          mode == other.mode;

  @override
  int get hashCode => start.hashCode ^ end.hashCode ^ mode.hashCode;
}

// Class to hold both route coordinates and info
class RouteData {
  final List<LatLng> coordinates;
  final Map<String, dynamic>? info;

  RouteData({required this.coordinates, this.info});
}
