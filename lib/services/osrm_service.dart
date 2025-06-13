import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

enum TransportMode { driving, walking, cycling }
class OSRMRoutingService {
  

  String _getModeString(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving:
        return 'driving';
      case TransportMode.walking:
        return 'walking';
      case TransportMode.cycling:
        return 'cycling';
    }
  }
  
  // URL de base pour OSRM (serveur public)
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1';
  
  /// Obtient les coordonnées d'un itinéraire entre deux points
  /// [start] : Point de départ (LatLng)
  /// [end] : Point d'arrivée (LatLng)
  /// Retourne une liste de LatLng représentant l'itinéraire
  Future<List<LatLng>> getRouteCoordinates(
    LatLng start, 
    LatLng end, 
    TransportMode mode,
  ) async {
    final modeStr = _getModeString(mode);
    try {
      final String url = '$_baseUrl/$modeStr/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full&steps=true&annotations=true';
      
      print('Route request: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Flutter App',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          
          if (geometry != null && geometry['coordinates'] != null) {
            final List<dynamic> coords = geometry['coordinates'];
            return coords.map((coord) => LatLng(coord[1], coord[0])).toList();
          }
        }
        
        print('No route found in response');
        return [];
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calculating route: $e');
      throw Exception('Failed to calculate route: $e');
    }
  }
  
  
  /// Obtient des informations détaillées sur l'itinéraire (distance, durée)
  Future<Map<String, dynamic>?> getRouteInfo(
    LatLng start, 
    LatLng end, 
    TransportMode mode,
  ) async {
    final modeStr = _getModeString(mode);
    try {
      final String url = '$_baseUrl/$modeStr/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=false';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Flutter App',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          return {
            'distance': route['distance'], // in meters
            'duration': route['duration'], // in seconds
          };
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting route info: $e');
      return null;
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