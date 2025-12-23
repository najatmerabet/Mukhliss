import 'package:mukhliss/core/logger/app_logger.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mukhliss/features/stores/domain/entities/category_entity.dart';
import 'package:mukhliss/features/stores/domain/entities/store_entity.dart';
import 'package:mukhliss/features/location/location.dart';
import 'package:mukhliss/core/widgets/buttons/buildmaplayerbutton.dart';

class LocationController {
  final WidgetRef ref;
  final BuildContext context;
  final MapController mapController;
  final Function(Position?)? onPositionUpdated;
  final Function(bool)? onLoadingChanged;
  final Function(List<LatLng>)? onPolylineUpdated;
  final Function(bool)? onNavigatingUpdated;
  bool get isRouteBottomSheetShowing => _isRouteBottomSheetShowing;
  bool _isRouteBottomSheetShowing = false;
  CategoryEntity? selectedCategory;
  Position? currentPosition;
  bool isLocationLoading = false;
  bool isRouting = false;
  List<LatLng> polylinePoints = [];
  StoreEntity? selectedShop;
  Map<String, dynamic>? routeInfo;
  TransportMode selectedMode = TransportMode.walking;
  bool showTransportModes = false;
  bool _isMapReady = false;
  MapLayerType selectedMapLayer = MapLayerType.plan;
  bool isNavigating = false;
  double? currentBearing;
  StreamSubscription<Position>? positionStream;
  bool _disposed = false;
  bool get isMapReady => _isMapReady;
  // Removed isMapReady getter as MapController does not have a 'ready' property.
  LocationController(
    this.ref,
    this.context,
    this.mapController,
    this.onPositionUpdated,
    this.onLoadingChanged,
    this.onPolylineUpdated,
    this.onNavigatingUpdated,
  );

  void markMapAsReady() {
    if (_disposed) return;
    _isMapReady = true;
    debugPrint('Carte marquée comme prête dans le controller');
  }

  void dispose() {
    _disposed = true;
    positionStream?.cancel();
    positionStream = null;
  }

  void _safeCallback(Function? callback, dynamic parameter) {
    if (!_disposed && callback != null) {
      callback(parameter);
    }
  }

  Future<void> getCurrentLocation() async {
    if (_disposed) return;
    if (!context.mounted) return;

    // Attendre que la carte soit prête (utilisez VOTRE flag _isMapReady)
    if (!_isMapReady) {
      debugPrint('En attente que la carte soit prête...');
      await Future.delayed(const Duration(milliseconds: 100));
      if (_disposed) return;
    }

    _safeCallback(onLoadingChanged, true);

    try {
      final geolocationService = ref.read(geolocationServiceProvider);
      final position = await geolocationService.determinePosition();

      if (_disposed || !context.mounted) {
        return;
      }

      currentPosition = position;
      _safeCallback(onPositionUpdated, position);
      _safeCallback(onLoadingChanged, false);

      // Vérifier à nouveau que la carte est prête (votre flag)
      if (!_disposed && _isMapReady) {
        mapController.move(LatLng(position.latitude, position.longitude), 17.0);
        debugPrint('Carte déplacée vers la position actuelle');
      } else {
        debugPrint('Carte non prête, impossible de déplacer');
      }
    } catch (e) {
      if (!_disposed) {
        _safeCallback(onLoadingChanged, false);

        if (context.mounted) {
          String errorMessage = e.toString();
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.replaceFirst('Exception: ', '');
          }
          
          debugPrint('Location error: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              action: SnackBarAction(
                label: 'Réessayer',
                onPressed: () {
                  if (!_disposed) {
                    getCurrentLocation();
                  }
                },
              ),
            ),
          );
        }
      }
    }
  }

  void showRouteBottomSheet() {
    if (_disposed) return;

    _isRouteBottomSheetShowing = true;
    _safeCallback(onNavigatingUpdated, true);
  }

  Future<Map<String, dynamic>> calculateRoute(
    StoreEntity? shop,
    TransportMode mode,
  ) async {
    if (_disposed) throw Exception("Controller disposed");
    if (shop == null) throw Exception("No shop selected");

    if (currentPosition == null) {
      await getCurrentLocation();
      if (_disposed) {
        throw Exception("Controller disposed during location fetch");
      }
      if (currentPosition == null) {
        throw Exception("Could not obtain current position");
      }
    }

    _safeCallback(onLoadingChanged, true);
    isRouting = true;
    isNavigating = true;

    try {
      final routingService = ref.read(routingServiceProvider);
      final start = LatLng(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );
      final end = LatLng(shop.latitude, shop.longitude);

      final routeCoordinates = await routingService.getRouteCoordinates(
        start,
        end,
        mode,
      );

      // Check if disposed after async operation
      if (_disposed) {
        throw Exception("Controller disposed during route calculation");
      }

      final routeSteps = await routingService.getRouteSteps(start, end, mode);

      if (_disposed) {
        throw Exception("Controller disposed during route calculation");
      }

      final routeInfo = await routingService.getRouteInfo(start, end, mode);

      if (_disposed) {
        throw Exception("Controller disposed during route calculation");
      }

      polylinePoints = routeCoordinates;
      this.routeInfo = routeInfo;
      selectedShop = shop;
      selectedMode = mode;

      showRouteBottomSheet();

      _safeCallback(onPolylineUpdated, routeCoordinates);
      _safeCallback(onLoadingChanged, false);

      isRouting = false;

      return {
        'coordinates': routeCoordinates,
        'info': routeInfo,
        'steps': routeSteps,
      };
    } catch (e) {
      if (!_disposed) {
        _isRouteBottomSheetShowing = false;
        _safeCallback(onLoadingChanged, false);
        isRouting = false;
        isNavigating = false;
      }
      rethrow;
    }
  }

  void fitMapToRoute(List<LatLng> points) {
    if (_disposed) return;

    AppLogger.debug('[FIT] Fitting map to route with ${points.length} points');
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
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)),
    );
  }

  void clearRoute() {
    if (_disposed) return;

    polylinePoints = [];
    selectedShop = null;
    routeInfo = null;
    showTransportModes = false;
    _isRouteBottomSheetShowing = false;
    stopNavigation();

    _safeCallback(onPolylineUpdated, <LatLng>[]);
  }

  void startPositionUpdates() {
    if (_disposed) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    positionStream?.cancel();

    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (_disposed || !isNavigating) return;
        handlePositionUpdate(position);
      },
      onError: (error) {
        if (!_disposed) {
          debugPrint('Position stream error: $error');
        }
      },
    );
  }

  void handlePositionUpdate(Position newPosition) {
    if (_disposed || !isNavigating || selectedShop == null) return;

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
    if (_disposed) return;

    final newCenter = LatLng(position.latitude, position.longitude);

    if (bearing != null) {
      mapController.move(newCenter, mapController.camera.zoom);
      mapController.rotate(bearing);
    } else {
      mapController.move(newCenter, mapController.camera.zoom);
    }
  }

  void checkArrival(Position position) {
    if (_disposed) return;
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
    if (_disposed || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vous êtes arrivé à ${selectedShop?.name}'),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  void stopNavigation() {
    if (_disposed) return;

    positionStream?.cancel();
    positionStream = null;
    isNavigating = false;
    currentBearing = null;
  }
}
