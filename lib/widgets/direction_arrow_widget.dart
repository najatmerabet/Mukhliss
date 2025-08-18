import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/theme/app_theme.dart';

class NavigationArrowWidget extends ConsumerStatefulWidget {
  final Position? currentPosition;
  final Store? selectedShop;
  final bool isNavigating;
  final double? currentBearing;
  final List<LatLng> routePoints;
  final Function() onStopNavigation;
  final Function(Position) onPositionUpdate;
  final Function(Position, double?) updateCameraPosition;
  final MapController mapController; 
  
  const NavigationArrowWidget({
    Key? key,
    required this.currentPosition,
    required this.selectedShop,
    required this.isNavigating,
    required this.currentBearing,
    required this.routePoints,
    required this.onStopNavigation,
    required this.onPositionUpdate,
    required this.updateCameraPosition,
    required this.mapController,
  }) : super(key: key);

  @override
  ConsumerState<NavigationArrowWidget> createState() => _NavigationArrowWidgetState();
}

class _NavigationArrowWidgetState extends ConsumerState<NavigationArrowWidget> 
    with TickerProviderStateMixin {
  StreamSubscription<Position>? _positionStream;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _currentSegmentIndex = 0;
  LatLng? _nextWaypoint;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    if (widget.isNavigating) {
      _startPositionUpdates();
      _findCurrentSegment();
    }
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(NavigationArrowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNavigating && !oldWidget.isNavigating) {
      _startPositionUpdates();
      _findCurrentSegment();
    } else if (!widget.isNavigating && oldWidget.isNavigating) {
      _stopPositionUpdates();
    }
  }

  @override
  void dispose() {
    _stopPositionUpdates();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPositionUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!widget.isNavigating) return;
      _handlePositionUpdate(position);
    });
  }

  // FONCTION CORRIGÉE : Calcul de la position sur l'itinéraire
Offset? _calculatePositionOnRoute(BuildContext context) {
  if (widget.currentPosition == null || widget.routePoints.isEmpty || !mounted) {
    return null;
  }

  try {
    // 1. Trouver le point le plus proche sur l'itinéraire
    final currentLatLng = LatLng(
      widget.currentPosition!.latitude, 
      widget.currentPosition!.longitude
    );
    
    LatLng closestPoint = widget.routePoints.reduce((a, b) => 
      _calculateDistance(currentLatLng, a) < _calculateDistance(currentLatLng, b) ? a : b
    );

    // 2. Obtenir la RenderBox de la carte
    final renderObject = context.findRenderObject();
    if (renderObject == null || !(renderObject is RenderBox)) return null;
    
    final mapRenderBox = renderObject as RenderBox;
    final mapSize = mapRenderBox.size;

    // 3. Calculer la position relative (approximation)
    // Cette partie suppose une projection plate - suffisante pour la plupart des cas
    final visibleBounds = _estimateVisibleBounds(mapRenderBox, widget.mapController);
    
    final xRatio = (closestPoint.longitude - visibleBounds.west) / 
                  (visibleBounds.east - visibleBounds.west);
    final yRatio = 1 - (closestPoint.latitude - visibleBounds.south) / 
                  (visibleBounds.north - visibleBounds.south);

    return Offset(
      xRatio * mapSize.width,
      yRatio * mapSize.height,
    );

  } catch (e) {
    debugPrint('Error calculating route position: $e');
    return null;
  }
}

LatLngBounds _estimateVisibleBounds(RenderBox mapRenderBox, MapController mapController) {
  // Estimation simple des limites visibles
  // Pour une solution plus précise, vous devrez peut-être implémenter
  // une logique spécifique selon votre version de flutter_map
  final center = mapController.camera.center;
  final zoom = mapController.camera.zoom;
  
  // Approximation de la taille en degrés (simplifiée)
  final delta = 180 / math.pow(2, zoom);
  
  return LatLngBounds(
    LatLng(center.latitude - delta, center.longitude - delta),
    LatLng(center.latitude + delta, center.longitude + delta),
  );
}

double _calculateDistance(LatLng point1, LatLng point2) {
  return Geolocator.distanceBetween(
    point1.latitude,
    point1.longitude,
    point2.latitude,
    point2.longitude,
  );
}
  void _stopPositionUpdates() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void _findCurrentSegment() {
    if (widget.currentPosition == null || widget.routePoints.isEmpty) return;

    final currentPos = LatLng(
      widget.currentPosition!.latitude,
      widget.currentPosition!.longitude,
    );

    double minDistance = double.infinity;
    int closestSegment = 0;

    // Trouver le segment le plus proche
    for (int i = 0; i < widget.routePoints.length - 1; i++) {
      final distance = _distanceToLineSegment(
        currentPos,
        widget.routePoints[i],
        widget.routePoints[i + 1],
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestSegment = i;
      }
    }

    setState(() {
      _currentSegmentIndex = closestSegment;
      if (closestSegment + 1 < widget.routePoints.length) {
        _nextWaypoint = widget.routePoints[closestSegment + 1];
      }
    });
  }

  double _distanceToLineSegment(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final A = point.latitude - lineStart.latitude;
    final B = point.longitude - lineStart.longitude;
    final C = lineEnd.latitude - lineStart.latitude;
    final D = lineEnd.longitude - lineStart.longitude;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    
    if (lenSq == 0) return math.sqrt(A * A + B * B);
    
    double param = dot / lenSq;
    param = math.max(0, math.min(1, param));

    final xx = lineStart.latitude + param * C;
    final yy = lineStart.longitude + param * D;

    final dx = point.latitude - xx;
    final dy = point.longitude - yy;
    
    return math.sqrt(dx * dx + dy * dy) * 111320;
  }

  void _handlePositionUpdate(Position newPosition) {
    if (widget.selectedShop == null) {
      debugPrint('No shop selected - cannot calculate bearing');
      return;
    }

    _findCurrentSegment();

    double bearing;
    if (_nextWaypoint != null) {
      bearing = Geolocator.bearingBetween(
        newPosition.latitude,
        newPosition.longitude,
        _nextWaypoint!.latitude,
        _nextWaypoint!.longitude,
      );
    } else {
      bearing = Geolocator.bearingBetween(
        newPosition.latitude,
        newPosition.longitude,
        widget.selectedShop!.latitude,
        widget.selectedShop!.longitude,
      );
    }

    widget.onPositionUpdate(newPosition);
    widget.updateCameraPosition(newPosition, bearing);
    _checkArrival(newPosition);
  }

  void _checkArrival(Position position) {
    if (widget.selectedShop == null) return;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.selectedShop!.latitude,
      widget.selectedShop!.longitude,
    );

    if (distance < 50) {
      _showArrivalNotification();
      widget.onStopNavigation();
    }

    if (_nextWaypoint != null) {
      final waypointDistance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _nextWaypoint!.latitude,
        _nextWaypoint!.longitude,
      );

      if (waypointDistance < 15) {
        if (_currentSegmentIndex + 2 < widget.routePoints.length) {
          setState(() {
            _currentSegmentIndex++;
            _nextWaypoint = widget.routePoints[_currentSegmentIndex + 1];
          });
        }
      }
    }
  }

  void _showArrivalNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vous êtes arrivé à ${widget.selectedShop?.nom_enseigne}'),
        duration: const Duration(seconds: 10),
        backgroundColor: AppColors.success,
      ),
    );
  }

  double _calculateBearingToNext() {
    if (widget.currentPosition == null) return 0;

    if (_nextWaypoint != null) {
      return Geolocator.bearingBetween(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
        _nextWaypoint!.latitude,
        _nextWaypoint!.longitude,
      );
    } else if (widget.selectedShop != null) {
      return Geolocator.bearingBetween(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
        widget.selectedShop!.latitude,
        widget.selectedShop!.longitude,
      );
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.light;
    
    if (!widget.isNavigating || 
        widget.selectedShop == null || 
        widget.currentPosition == null ||
        widget.routePoints.isEmpty) {
      return const SizedBox.shrink();
    }

    // CHANGEMENT PRINCIPAL : Utiliser la position calculée sur la route
    final routePosition = _calculatePositionOnRoute(context);
    
    // Si on ne peut pas calculer la position, ne pas afficher la flèche
    if (routePosition == null) {
      return const SizedBox.shrink();
    }

    // Calculer le bearing
    final bearing = _calculateBearingToNext();

    return Positioned(
      left: routePosition.dx - 30, // Centrer la flèche (30 = moitié de la largeur)
      top: routePosition.dy - 30,  // Centrer la flèche (30 = moitié de la hauteur)
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: GestureDetector(
                onTap: widget.onStopNavigation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  width: 60,
                  height: 60,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cercle intérieur
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        // Flèche avec rotation selon le bearing
                        Transform.rotate(
                          angle: (bearing * math.pi) / 180,
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}