
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mukhliss/models/categories.dart';
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/providers/geolocator_provider.dart';
import 'package:mukhliss/providers/osrm_provider.dart';
import 'package:mukhliss/services/osrm_service.dart';
import 'package:mukhliss/widgets/buttons/buildmaplayerbutton.dart';

class LocationController {
  final WidgetRef ref;
  final BuildContext context;
  final MapController mapController;
  final Function(Position?) onPositionUpdated;
  final Function(bool) onLoadingChanged;
  final Function(List<LatLng>)? onPolylineUpdated;
  final Function(bool)? onNavigatingUpdated;
  bool get isRouteBottomSheetShowing => _isRouteBottomSheetShowing;
  bool _isRouteBottomSheetShowing = false;
  Categories? selectedCategory;
  Position? currentPosition;
  bool isLocationLoading = false;
  bool isRouting = false;
  List<LatLng> polylinePoints = [];
  Store? selectedShop;
  Map<String, dynamic>? routeInfo;
  TransportMode selectedMode = TransportMode.walking;
  bool showTransportModes = false;
 
  MapLayerType selectedMapLayer = MapLayerType.plan;
  bool isNavigating = false;
  double? currentBearing;
  StreamSubscription<Position>? positionStream;



  LocationController(
    this.ref,
    this.context,
    this.mapController,
    this.onPositionUpdated,
    this.onLoadingChanged,
     this.onPolylineUpdated,
    this.onNavigatingUpdated,
  );

  Future<void> getCurrentLocation() async {
    if (!context.mounted) return;
    onLoadingChanged(true);
    
    try {
      final geolocationService = ref.read(geolocationServiceProvider);
      final position = await geolocationService.determinePosition();
      
      if (context.mounted) {
        currentPosition = position; // Update controller's position
        onPositionUpdated(position);
        onLoadingChanged(false);
      }

      if (position != null) {
        mapController.move(
          LatLng(position.latitude, position.longitude),
          17.0,
        );
      }
    } catch (e) {
      onLoadingChanged(false);
      if (context.mounted) {
        debugPrint('Location error: ${e.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'obtenir votre position: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: getCurrentLocation,
            ),
          ),
        );
      }
    }
  }

 void showRouteBottomSheet() {
    _isRouteBottomSheetShowing = true;
    // Notifiez les listeners si nécessaire
    if (onNavigatingUpdated != null) {
      onNavigatingUpdated!(true);
    }
  }

Future<Map<String, dynamic>> calculateRoute(Store? shop, TransportMode mode) async {
    if (shop == null) throw Exception("No shop selected");

    if (currentPosition == null) {
      await getCurrentLocation();
      if (currentPosition == null) throw Exception("Could not obtain current position");
    }
    
    onLoadingChanged(true);
    isRouting = true;
    isNavigating = true;
    
    try {
      final routingService = ref.read(routingServiceProvider);
      final start = LatLng(currentPosition!.latitude, currentPosition!.longitude);
      final end = LatLng(shop.latitude, shop.longitude);

      final routeCoordinates = await routingService.getRouteCoordinates(start, end, mode);
      final routeSteps = await routingService.getRouteSteps(start, end, mode);
      final routeInfo = await routingService.getRouteInfo(start, end, mode);

      // Mise à jour des états
      polylinePoints = routeCoordinates;
      this.routeInfo = routeInfo;
      selectedShop = shop;
      selectedMode = mode;
      
      // Force l'affichage du bottom sheet
      showRouteBottomSheet();
      
      if (onPolylineUpdated != null) {
        onPolylineUpdated!(routeCoordinates);
      }

      onLoadingChanged(false);
      isRouting = false;

      return {
        'coordinates': routeCoordinates,
        'info': routeInfo,
        'steps': routeSteps,
      };
    } catch (e) {
      _isRouteBottomSheetShowing = false;
      onLoadingChanged(false);
      isRouting = false;
      isNavigating = false;
      rethrow;
    }
  }

  void fitMapToRoute(List<LatLng> points) {
      print('[FIT] Fitting map to route with ${points.length} points');
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final bounds = LatLngBounds.fromPoints(points);
    
       mapController.fitCamera(
           CameraFit.bounds(
           bounds: bounds,
           padding: const EdgeInsets.all(50.0),
         ),
        );
  }

  void clearRoute() {
    polylinePoints = [];
    selectedShop = null;
    routeInfo = null;
    showTransportModes = false;
    _isRouteBottomSheetShowing = false;
    stopNavigation();
    if (onPolylineUpdated != null) {
    onPolylineUpdated!([]);
  }
  }

  void startPositionUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    positionStream?.cancel();

    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!isNavigating) return;
      handlePositionUpdate(position);
    });
  }

  void handlePositionUpdate(Position newPosition) {
    if (selectedShop == null) return;

    final bearingToShop = Geolocator.bearingBetween(
      newPosition.latitude,
      newPosition.longitude,
      selectedShop!.latitude,
      selectedShop!.longitude,
    );

    currentPosition = newPosition;
    currentBearing = bearingToShop;
    
    updateCameraPosition(newPosition, bearingToShop);
    checkArrival(newPosition);
  }

  void updateCameraPosition(Position position, double? bearing) {
    final newCenter = LatLng(position.latitude, position.longitude);
    
    if (bearing != null) {
      mapController.move(newCenter, mapController.camera.zoom ?? 17.0);
      mapController.rotate(bearing);
    } else {
      mapController.move(newCenter, mapController.camera.zoom ?? 17.0);
    }
  }

  void checkArrival(Position position) {
    if (selectedShop == null) return;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      selectedShop!.latitude,
      selectedShop!.longitude,
    );

    if (distance < 50) {
      showArrivalNotification();
      stopNavigation();
    }
  }

  void showArrivalNotification() {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vous êtes arrivé à ${selectedShop?.nom_enseigne}'),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  void stopNavigation() {
    positionStream?.cancel();
    isNavigating = false;
    currentBearing = null;
  }
}