import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

enum TransportMode { driving, walking, cycling }
class OSRMRoutingService {
  static const String _baseUrl = 'https://api.openrouteservice.org/v2/directions';
   static const String _apiKey = '5b3ce3597851110001cf6248bf571a9227874b15ae0e75d42bddb173'; 

   
 String _getModeString(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving: return 'driving-car';
      case TransportMode.walking: return 'foot-walking';
      case TransportMode.cycling: return 'cycling-regular';
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
        print('Error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error in getRouteCoordinates: $e');
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
        print('Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error in getRouteInfo: $e');
      return null;
    }
  }

Future<http.Response> _makeOpenRouteRequest(
    LatLng start, 
    LatLng end, 
    TransportMode mode,
  ) async {
    final modeStr = _getModeString(mode);
    
    print('[ORS] Making request for mode: $modeStr');
    print('[ORS] From: ${start.latitude},${start.longitude}');
    print('[ORS] To: ${end.latitude},${end.longitude}');

    final response = await http.post(
      Uri.parse('$_baseUrl/$modeStr'),
      headers: {
        'Authorization': _apiKey,
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json, application/geo+json',
      },
      body: json.encode({
        'coordinates': [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude]
        ],
        'instructions': false,
        'geometry': true
      }),
    ).timeout(const Duration(seconds: 15));

    print('[ORS] Response status: ${response.statusCode}');
    print('[ORS] Response body: ${response.body}');
    
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
Future<List<LatLng>> getRouteSteps(LatLng start, LatLng end, TransportMode mode) async {
  final modeStr = _getModeString(mode);
  try {
    final String url = '$_baseUrl/$modeStr/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline';
    
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
        final List<dynamic> steps = route['legs'][0]['steps'];
        
        // Convertir explicitement en List<LatLng>
        return steps.map<LatLng>((step) {
          final location = step['maneuver']['location'] as List<dynamic>;
          return LatLng(location[1], location[0]);
        }).toList();
      }
    }
    
    return []; // Retourne une liste vide explicitement typée
  } catch (e) {
    print('Error getting route steps: $e');
    return []; // Retourne une liste vide explicitement typée
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