
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mukhliss/features/auth/presentation/providers/auth_providers.dart';

import 'package:mukhliss/features/stores/stores.dart';
import 'package:mukhliss/features/location/data/services/osrm_service.dart';
import '../widgets/map_widgets.dart' as map_widgets;

/// États du bottom sheet
enum BottomSheetState { none, categories, shopDetails, route, search }

/// Mixin pour la gestion de la connectivité
mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  bool isCheckingConnectivity = true;
  bool hasConnection = true;
  String? _currentUserId;
  StreamSubscription<ConnectivityResult>? connectivitySubscription;
  
 void initializeUserId(WidgetRef ref) {
    final authClient = ref.read(authClientProvider);
    final currentUser = authClient.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.id;
      debugPrint('📍 LocationScreen - UserId initialisé: $_currentUserId');
    }
  }
 
 void checkUserChange(WidgetRef ref, VoidCallback onUserChanged) {
    final authClient = ref.read(authClientProvider);
    final currentUser = authClient.currentUser;
    
    if (currentUser != null && currentUser.id != _currentUserId) {
      debugPrint('🔄 LocationScreen - Changement d\'utilisateur détecté!');
      debugPrint('   Ancien: $_currentUserId');
      debugPrint('   Nouveau: ${currentUser.id}');
      _currentUserId = currentUser.id;
      onUserChanged();
    }
  }
  void resetUserId() {
    _currentUserId = null;
  }
  Future<void> checkConnectivity() async {
    try {
      final hasInternet = await InternetConnection().hasInternetAccess;
      if (mounted) {
        setState(() {
          hasConnection = hasInternet;
          isCheckingConnectivity = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isCheckingConnectivity = false);
      }
    }
  }
 
  Future<void> checkConnectivityWithRetry({int retryCount = 0}) async {
    if (!mounted || retryCount > 3) return;

    try {
      final hasInternet = await InternetConnection().hasInternetAccess;
      if (mounted) {
        setState(() {
          hasConnection = hasInternet;
          isCheckingConnectivity = false;
        });
      }
    } catch (e) {
      if (mounted && retryCount < 3) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        await checkConnectivityWithRetry(retryCount: retryCount + 1);
      } else if (mounted) {
        setState(() {
          hasConnection = false;
          isCheckingConnectivity = false;
        });
      }
    }
  }

  void disposeConnectivity() {
    connectivitySubscription?.cancel();
  }

  Widget buildNoConnectionWidget(BuildContext context, VoidCallback onRetry) {
    return map_widgets.NoConnectionWidget(onRetry: onRetry);
  }

  Widget buildConnectivityCheckWidget(BuildContext context) {
    return map_widgets.ConnectivityCheckWidget();
  }
}

/// Mixin pour la gestion de la navigation GPS
mixin NavigationMixin<T extends StatefulWidget> on State<T> {
  bool isNavigating = false;
  List<LatLng> polylinePoints = [];
  StoreEntity? selectedShop;
  Map<String, dynamic>? routeInfo;
  TransportMode selectedMode = TransportMode.walking;
  StreamSubscription<Position>? positionStream;
  Timer? navigationTimer;
  
  // GPS temps réel
  Position? _lastKnownPosition;
  DateTime? _lastRouteUpdate;
  int _deviationCount = 0;
  static const double _deviationThreshold = 50.0; // mètres
  static const Duration _minRouteUpdateInterval = Duration(seconds: 10);

  void startNavigation() {
    setState(() => isNavigating = true);
    _startGPSTracking();
  }

  void stopNavigation() {
    positionStream?.cancel();
    navigationTimer?.cancel();
    _deviationCount = 0;
    _lastRouteUpdate = null;
    setState(() {
      isNavigating = false;
      polylinePoints = [];
    });
  }

  /// Démarre le suivi GPS en temps réel
  void _startGPSTracking() {
    // Configuration GPS haute précision
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Met à jour tous les 5 mètres
    );

    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        debugPrint('❌ GPS Error: $error');
      },
    );
    
    debugPrint('📍 GPS tracking started - High accuracy mode');
  }

  /// Appelé à chaque mise à jour de position GPS
  void _onPositionUpdate(Position position) {
    if (!isNavigating || selectedShop == null) return;
    
    _lastKnownPosition = position;
    
    // 1. Vérifier si arrivé à destination
    final distanceToDestination = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      selectedShop!.latitude,
      selectedShop!.longitude,
    );
    
    if (distanceToDestination < 30) {
      _onArrived();
      return;
    }
    
    // 2. Vérifier si déviation de la route
    if (polylinePoints.isNotEmpty) {
      final deviationDistance = _calculateDeviationFromRoute(position);
      
      if (deviationDistance > _deviationThreshold) {
        _deviationCount++;
        debugPrint('⚠️ Déviation détectée: ${deviationDistance.toStringAsFixed(0)}m (count: $_deviationCount)');
        
        // Recalculer la route si déviation persistante
        if (_deviationCount >= 3 && _canUpdateRoute()) {
          _recalculateRoute(position);
        }
      } else {
        _deviationCount = 0; // Reset si retour sur la route
      }
    }
    
    // 3. Mettre à jour l'affichage
    if (mounted) {
      setState(() {});
    }
  }

  /// Calcule la distance minimale à la route
  double _calculateDeviationFromRoute(Position position) {
    if (polylinePoints.isEmpty) return 0;
    
    double minDistance = double.infinity;
    
    for (int i = 0; i < polylinePoints.length - 1; i++) {
      final distance = _distanceToSegment(
        LatLng(position.latitude, position.longitude),
        polylinePoints[i],
        polylinePoints[i + 1],
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    
    return minDistance;
  }

  /// Distance d'un point à un segment de ligne
  double _distanceToSegment(LatLng point, LatLng start, LatLng end) {
    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;
    
    if (dx == 0 && dy == 0) {
      return Geolocator.distanceBetween(
        point.latitude, point.longitude,
        start.latitude, start.longitude,
      );
    }
    
    var t = ((point.longitude - start.longitude) * dx + 
             (point.latitude - start.latitude) * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);
    
    final nearestLat = start.latitude + t * dy;
    final nearestLng = start.longitude + t * dx;
    
    return Geolocator.distanceBetween(
      point.latitude, point.longitude,
      nearestLat, nearestLng,
    );
  }

  /// Vérifie si on peut recalculer la route (évite spam)
  bool _canUpdateRoute() {
    if (_lastRouteUpdate == null) return true;
    return DateTime.now().difference(_lastRouteUpdate!) > _minRouteUpdateInterval;
  }

  /// Recalcule la route depuis la position actuelle
  Future<void> _recalculateRoute(Position position) async {
    if (selectedShop == null) return;
    
    debugPrint('🔄 Recalcul de la route...');
    _lastRouteUpdate = DateTime.now();
    _deviationCount = 0;
    
    try {
      final service = OSRMRoutingService();
      final routeData = await service.getRouteInfo(
        LatLng(position.latitude, position.longitude),
        LatLng(selectedShop!.latitude, selectedShop!.longitude),
        selectedMode,
      );

      if (routeData != null && routeData['polyline'] != null && mounted) {
        final points = (routeData['polyline'] as List).cast<LatLng>();
        setState(() {
          polylinePoints = points;
          routeInfo = routeData;
        });
        debugPrint('✅ Route recalculée: ${points.length} points');
      }
    } catch (e) {
      debugPrint('❌ Erreur recalcul route: $e');
    }
  }

  /// Appelé quand l'utilisateur arrive à destination
  void _onArrived() {
    debugPrint('🎉 Arrivé à destination!');
    stopNavigation();
    // TODO: Afficher notification d'arrivée
  }

  void updateRoute(List<LatLng> points) {
    setState(() => polylinePoints = points);
  }

  void selectShop(StoreEntity? shop) {
    setState(() => selectedShop = shop);
  }

  void setRouteInfo(Map<String, dynamic>? info) {
    setState(() => routeInfo = info);
  }

  void setTransportMode(TransportMode mode) {
    setState(() => selectedMode = mode);
  }

  void disposeNavigation() {
    positionStream?.cancel();
    navigationTimer?.cancel();
  }

  void fitMapToRoute(List<LatLng> points, MapController mapController) {
    if (points.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

    mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  void checkArrival(Position position, void Function() onArrival) {
    if (selectedShop == null) return;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      selectedShop!.latitude,
      selectedShop!.longitude,
    );

    if (distance < 50) {
      onArrival();
    }
  }

  Future<void> initiateRouting(
    StoreEntity shop,
    Position? currentPosition,
    void Function(List<LatLng>, Map<String, dynamic>) onRouteReady,
    void Function(String) onError,
  ) async {
    if (currentPosition == null) {
      onError('Position actuelle non disponible');
      return;
    }

    try {
      final service = OSRMRoutingService();
      final routeData = await service.getRouteInfo(
        LatLng(currentPosition.latitude, currentPosition.longitude),
        LatLng(shop.latitude, shop.longitude),
        selectedMode,
      );

      if (routeData != null && routeData['polyline'] != null) {
        final points = (routeData['polyline'] as List).cast<LatLng>();
        _lastRouteUpdate = DateTime.now();
        onRouteReady(points, routeData);
      } else {
        onError('Impossible de calculer l\'itinéraire');
      }
    } catch (e) {
      onError('Erreur: $e');
    }
  }
}

/// Mixin pour la gestion de la recherche
mixin SearchMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController searchController = TextEditingController();
  bool showSearchBar = false;
  List<StoreEntity> searchResults = [];
  Timer? searchDebounceTimer;

  void toggleSearchBar() {
    setState(() => showSearchBar = !showSearchBar);
    if (!showSearchBar) {
      searchController.clear();
      searchResults = [];
    }
  }

  void clearSearch() {
    setState(() {
      showSearchBar = false;
      searchController.clear();
      searchResults = [];
    });
  }

  void updateSearchResults(List<StoreEntity> results) {
    setState(() => searchResults = results);
  }

  void disposeSearch() {
    searchController.dispose();
    searchDebounceTimer?.cancel();
  }
}

/// Mixin pour la gestion de l'UI de la carte
mixin MapUIMixin<T extends StatefulWidget> on State<T> {
  bool showMapLayers = false;
  bool showTransportModes = false;
  bool categoriesBottomSheetShown = false;

  void toggleMapLayers() {
    setState(() => showMapLayers = !showMapLayers);
  }

  void hideMapLayers() {
    setState(() => showMapLayers = false);
  }

  void showTransportModesPanel() {
    setState(() => showTransportModes = true);
  }

  void hideTransportModesPanel() {
    setState(() => showTransportModes = false);
  }
}

/// Mixin pour la gestion des bottom sheets
mixin BottomSheetMixin<T extends StatefulWidget> on State<T> {
  BottomSheetState bottomSheetState = BottomSheetState.none;

  void updateBottomSheetState(BottomSheetState newState) {
    setState(() => bottomSheetState = newState);
  }

  void showCategoriesSheet() {
    updateBottomSheetState(BottomSheetState.categories);
  }

  void showShopDetailsSheet() {
    updateBottomSheetState(BottomSheetState.shopDetails);
  }

  void showRouteSheet() {
    updateBottomSheetState(BottomSheetState.route);
  }

  void closeAllSheets() {
    updateBottomSheetState(BottomSheetState.none);
  }
}

/// Mixin pour la gestion des erreurs avec snackbar
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  void showErrorSnackbar(String message, Color backgroundColor) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontSize: 14)),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void handleStoreLoadError(Object error, VoidCallback onRetry) {
    if (!mounted) return;

    final isTimeout =
        error is TimeoutException || error.toString().contains('Timeout');
    final isNetworkError =
        error.toString().contains('SocketException') ||
        error.toString().contains('Connection');

    if (isTimeout) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) onRetry();
      });
      showErrorSnackbar(
        'Connexion lente... Nouvelle tentative en cours',
        Colors.orange.shade700,
      );
    } else if (isNetworkError) {
      showErrorSnackbar('Problème de connexion réseau', Colors.red.shade700);
    } else {
      final errorMsg =
          error.toString().length > 60
              ? '${error.toString().substring(0, 60)}...'
              : error.toString();
      showErrorSnackbar('Erreur: $errorMsg', Colors.red.shade700);
    }
  }
}
