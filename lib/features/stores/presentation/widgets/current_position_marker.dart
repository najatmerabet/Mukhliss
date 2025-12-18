/// ============================================================
/// Current Position Marker - Presentation Layer
/// ============================================================
///
/// Marqueur pour afficher la position actuelle sur la carte.
/// Extrait de location_screen.dart pour respecter SRP.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Widget pour le contenu visuel du marqueur de position
class CurrentPositionMarkerWidget extends StatelessWidget {
  final double size;
  final Color color;

  const CurrentPositionMarkerWidget({
    super.key,
    this.size = 48,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo externe
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
          ),
        ),
        // Point central
        Container(
          width: size / 2,
          height: size / 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade700,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Crée un Marker pour flutter_map à partir d'une Position
Marker createCurrentPositionMarker(Position position, {double size = 48}) {
  return Marker(
    point: LatLng(position.latitude, position.longitude),
    width: size,
    height: size,
    child: CurrentPositionMarkerWidget(size: size),
  );
}
