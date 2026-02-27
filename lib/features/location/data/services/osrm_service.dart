import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

enum TransportMode { driving, walking, cycling }

class OSRMRoutingService {
  static const String _baseUrl =
      'https://api.openrouteservice.org/v2/directions';
  static const String _apiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjFhM2EwYmZjNTJlMjI1MmU0ZTU0OWViNzJhNjY0OWU2MGVlMTI1YjE4YzEzMWJjOTZlOTgwM2I2IiwiaCI6Im11cm11cjY0In0='; 

  String _getModeString(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving:
        return 'driving-car';
      case TransportMode.walking:
        return 'foot-hiking';
      case TransportMode.cycling:
        return 'cycling-regular';
    }
  }

  // URL de base pour OSRM (serveur public)

  /// Obtient les coordonnées d'un itinéraire entre deux points
  /// [start] : Point de départ (LatLng)
  /// [end] : Point d'arrivée (LatLng)
  /// Retourne une liste de LatLng représentant l'itinéraire
  Future<List<LatLng>> getRouteCoordinates(
    LatLng start,
    LatLng end,
    TransportMode mode,
  ) async {
    try {
      final response = await _makeOpenRouteRequest(start, end, mode);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry'];
        return _decodePolyline(geometry);
      } else {
        debugPrint('Error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error in getRouteCoordinates: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getRouteInfo(
    LatLng start,
    LatLng end,
    TransportMode mode,
  ) async {
    try {
      final response = await _makeOpenRouteRequest(start, end, mode);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];
        return {
          'distance': route['summary']['distance']?.toDouble() ?? 0.0,
          'duration': route['summary']['duration']?.toDouble() ?? 0.0,
          'polyline': _decodePolyline(route['geometry']),
        };
      } else {
        debugPrint('Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error in getRouteInfo: $e');
      return null;
    }
  }

  Future<http.Response> _makeOpenRouteRequest(
    LatLng start,
    LatLng end,
    TransportMode mode,
  ) async {
    final modeStr = _getModeString(mode);

    debugPrint('[ORS] Making request for mode: $modeStr');
    debugPrint('[ORS] From: ${start.latitude},${start.longitude}');
    debugPrint('[ORS] To: ${end.latitude},${end.longitude}');
    final url = '$_baseUrl/$modeStr/json';
    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Authorization': _apiKey,
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json, application/geo+json',
          },
          body: json.encode({
            'coordinates': [
              [start.longitude, start.latitude],
              [end.longitude, end.latitude],
              
            ],
            'instructions': false,
            'geometry': true,
          }),
        )
        .timeout(const Duration(seconds: 15));
   debugPrint('url========== : $url');
    debugPrint('[ORS] Response status: ${response.statusCode}');
    debugPrint('[ORS] Response body: ${response.body}');

    return response;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

 Future<List<LatLng>> getRouteSteps(
  LatLng start,
  LatLng end,
  TransportMode mode,
) async {
  try {
    // ✅ Utilise le même POST ORS que getRouteCoordinates
    final response = await _makeOpenRouteRequest(start, end, mode);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0];
      // ORS retourne la géométrie encodée, on la décode directement
      return _decodePolyline(route['geometry']);
    } else {
      debugPrint('Error getRouteSteps ${response.statusCode}: ${response.body}');
      return [];
    }
  } catch (e) {
    debugPrint('Error getting route steps: $e');
    return [];
  }
}

  /// Formate la distance en texte lisible
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Formate la durée en texte lisible
  String formatDuration(double durationInSeconds) {
    if (durationInSeconds < 60) {
      return '${durationInSeconds.toStringAsFixed(0)} sec';
    } else if (durationInSeconds < 3600) {
      final minutes = (durationInSeconds / 60).toStringAsFixed(0);
      return '$minutes min';
    } else {
      final hours = (durationInSeconds / 3600).floor();
      final minutes = ((durationInSeconds % 3600) / 60).toStringAsFixed(0);
      return '${hours}h ${minutes}min';
    }
  }
}
