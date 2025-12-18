/// ============================================================
/// Navigation Bar Widget - Style Google Maps
/// ============================================================
///
/// Affiche les instructions de navigation en temps réel
/// avec un design similaire à Google Maps.
library;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Widget de barre de navigation style Google Maps
class MapNavigationBar extends StatelessWidget {
  final String? nextInstruction;
  final String? distanceToNext;
  final String? estimatedTime;
  final String? destination;
  final VoidCallback onClose;
  final bool isNavigating;

  const MapNavigationBar({
    super.key,
    this.nextInstruction,
    this.distanceToNext,
    this.estimatedTime,
    this.destination,
    required this.onClose,
    required this.isNavigating,
  });

  @override
  Widget build(BuildContext context) {
    if (!isNavigating) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Instruction principale
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextInstruction ?? 'Navigation en cours...',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        distanceToNext ?? 'Calcul en cours...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Infos ETA et destination
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Temps estimé
                Row(
                  children: [
                    Icon(Icons.access_time, 
                         color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      estimatedTime ?? '--:--',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                
                // Destination
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.place, 
                           color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          destination ?? 'Destination',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget indicateur de position actuelle amélioré
class CurrentPositionIndicator extends StatelessWidget {
  final double? heading;
  final bool isNavigating;

  const CurrentPositionIndicator({
    super.key,
    this.heading,
    required this.isNavigating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade600,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: isNavigating && heading != null
          ? Transform.rotate(
              angle: heading! * 3.14159 / 180,
              child: const Icon(
                Icons.navigation,
                color: Colors.white,
                size: 14,
              ),
            )
          : null,
    );
  }
}

/// Calcule les instructions de navigation basées sur les points de route
class NavigationInstructions {
  /// Calcule la prochaine instruction basée sur la position actuelle
  static Map<String, String> getNextInstruction({
    required LatLng currentPosition,
    required List<LatLng> routePoints,
    required LatLng destination,
  }) {
    if (routePoints.isEmpty) {
      return {
        'instruction': 'Aucune route',
        'distance': '--',
      };
    }

    // Trouver le point le plus proche sur la route
    int nearestIndex = 0;
    double minDistance = double.infinity;
    
    for (int i = 0; i < routePoints.length; i++) {
      final dist = _distanceBetween(currentPosition, routePoints[i]);
      if (dist < minDistance) {
        minDistance = dist;
        nearestIndex = i;
      }
    }

    // Distance restante
    double remainingDistance = 0;
    for (int i = nearestIndex; i < routePoints.length - 1; i++) {
      remainingDistance += _distanceBetween(routePoints[i], routePoints[i + 1]);
    }

    // Formater la distance
    String distanceText;
    if (remainingDistance < 100) {
      distanceText = '${remainingDistance.toInt()} m';
    } else if (remainingDistance < 1000) {
      distanceText = '${(remainingDistance / 100).round() * 100} m';
    } else {
      distanceText = '${(remainingDistance / 1000).toStringAsFixed(1)} km';
    }

    // Déterminer l'instruction
    String instruction = 'Continuez tout droit';
    if (nearestIndex < routePoints.length - 2) {
      final angle = _calculateTurnAngle(
        routePoints[nearestIndex],
        routePoints[nearestIndex + 1],
        nearestIndex + 2 < routePoints.length 
            ? routePoints[nearestIndex + 2] 
            : destination,
      );
      
      if (angle > 30) {
        instruction = 'Tournez à droite';
      } else if (angle < -30) {
        instruction = 'Tournez à gauche';
      }
    }

    if (remainingDistance < 50) {
      instruction = 'Vous êtes arrivé!';
    }

    return {
      'instruction': instruction,
      'distance': distanceText,
    };
  }

  static double _distanceBetween(LatLng a, LatLng b) {
    const double earthRadius = 6371000; // mètres
    final dLat = (b.latitude - a.latitude) * 3.14159 / 180;
    final dLng = (b.longitude - a.longitude) * 3.14159 / 180;
    
    final lat1 = a.latitude * 3.14159 / 180;
    final lat2 = b.latitude * 3.14159 / 180;
    
    final sinDLat = (dLat / 2);
    final sinDLng = (dLng / 2);
    
    final c = sinDLat * sinDLat + sinDLng * sinDLng * 
              (1 - lat1 * lat1 / 2) * (1 - lat2 * lat2 / 2);
    
    return earthRadius * 2 * c.abs();
  }

  static double _calculateTurnAngle(LatLng p1, LatLng p2, LatLng p3) {
    final bearing1 = _bearing(p1, p2);
    final bearing2 = _bearing(p2, p3);
    var angle = bearing2 - bearing1;
    if (angle > 180) angle -= 360;
    if (angle < -180) angle += 360;
    return angle;
  }

  static double _bearing(LatLng start, LatLng end) {
    final dLng = (end.longitude - start.longitude) * 3.14159 / 180;
    final lat1 = start.latitude * 3.14159 / 180;
    final lat2 = end.latitude * 3.14159 / 180;
    
    final y = dLng * (1 - lat2 * lat2 / 2);
    final x = (lat2 - lat1);
    
    return (x != 0 || y != 0) ? (y / x) * 180 / 3.14159 : 0;
  }
}
