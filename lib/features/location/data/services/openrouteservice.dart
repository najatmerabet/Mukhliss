import 'package:mukhliss/core/logger/app_logger.dart';
// lib/services/osrm_service.dart

import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OSRMService {
  // Public OSRM demo server (for testing only)
  // For production, use your own OSRM server or a paid service
  static const String baseUrl = 'https://router.project-osrm.org/route/v1';
  
  // Route profiles: driving, walking, cycling
  static const String profile = 'cycling';

  /// Get route between two points using OSRM
  static Future<OSRMRoute?> getRoute(LatLng start, LatLng end) async {
    // OSRM expects coordinates as longitude,latitude
    final String coordinates = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
    // Build URL with options
    final String url = '$baseUrl/$profile/$coordinates'
        '?overview=full'  // Get full route geometry
        '&geometries=geojson'  // Get as GeoJSON
        '&steps=true'  // Include turn-by-turn instructions
        '&annotations=true';  // Include additional metadata
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          return OSRMRoute.fromJson(data['routes'][0]);
        } else {
          AppLogger.debug('OSRM Error: ${data['code']} - ${data['message']}');
        }
      } else {
        AppLogger.debug('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.debug('Error getting OSRM route: $e');
    }

    return null;
  }

  /// Get route with waypoints
  static Future<OSRMRoute?> getRouteWithWaypoints(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;
    
    // Build coordinates string
    final String coordinates = waypoints
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');
    
    final String url = '$baseUrl/$profile/$coordinates'
        '?overview=simplified'
        '&geometries=geojson'
        '&steps=true';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          return OSRMRoute.fromJson(data['routes'][0]);
        }
      }
    }
     catch (e) {
      AppLogger.debug('Error getting OSRM route with waypoints: $e');
    }
    
    return null;
  }
}

/// OSRM Route model
class OSRMRoute {
  final List<LatLng> coordinates;
  final double distance; // in meters
  final double duration; // in seconds
  final List<OSRMStep> steps;
  
  OSRMRoute({
    required this.coordinates,
    required this.distance,
    required this.duration,
    required this.steps,
  });
  
  factory OSRMRoute.fromJson(Map<String, dynamic> json) {
    // Extract coordinates from GeoJSON geometry
    List<LatLng> coords = [];
    if (json['geometry'] != null && json['geometry']['coordinates'] != null) {
      coords = (json['geometry']['coordinates'] as List)
          .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
          .toList();
    }
    
    // Parse steps
    List<OSRMStep> steps = [];
    if (json['legs'] != null) {
      for (var leg in json['legs']) {
        if (leg['steps'] != null) {
          steps.addAll(
            (leg['steps'] as List).map((step) => OSRMStep.fromJson(step)).toList()
          );
        }
      }
    }
    
    return OSRMRoute(
      coordinates: coords,
      distance: json['distance']?.toDouble() ?? 0,
      duration: json['duration']?.toDouble() ?? 0,
      steps: steps,
    );
  }
  
  String get distanceText {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.round()} m';
  }
  
  String get durationText {
    int minutes = (duration / 60).round();
    if (minutes >= 60) {
      int hours = minutes ~/ 60;
      int mins = minutes % 60;
      return '$hours h $mins min';
    }
    return '$minutes min';
  }
}

/// OSRM Step (turn-by-turn instruction)
class OSRMStep {
  final String instruction;
  final double distance;
  final double duration;
  final String maneuver;
  
  OSRMStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
  });
  
  factory OSRMStep.fromJson(Map<String, dynamic> json) {
    String instruction = json['name'] ?? '';
    
    // Build instruction from maneuver
    if (json['maneuver'] != null) {
      String modifier = json['maneuver']['modifier'] ?? '';
      String type = json['maneuver']['type'] ?? '';
      
      if (type == 'turn') {
        instruction = 'Turn $modifier onto $instruction';
      } else if (type == 'new name') {
        instruction = 'Continue onto $instruction';
      } else if (type == 'depart') {
        instruction = 'Start on $instruction';
      } else if (type == 'arrive') {
        instruction = 'Arrive at destination';
      } else {
        instruction = '$type $modifier $instruction'.trim();
      }
    }
    
    return OSRMStep(
      instruction: instruction,
      distance: json['distance']?.toDouble() ?? 0,
      duration: json['duration']?.toDouble() ?? 0,
      maneuver: json['maneuver']?['type'] ?? '',
    );
  }
}