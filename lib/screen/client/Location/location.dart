import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/providers/store_provider.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/screen/client/Location/location_controller.dart';
import 'package:mukhliss/services/osrm_service.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/utils/category_helpers.dart';
import 'package:mukhliss/utils/geticategoriesbyicon.dart';
import 'package:mukhliss/providers/categories_provider.dart'; // Ajout du provider des catégories
import 'package:mukhliss/models/categories.dart';
import 'package:mukhliss/utils/map_layer_utils.dart';
import 'package:mukhliss/widgets/buttons/buildmaplayerbutton.dart';
import 'package:mukhliss/widgets/buttons/categories_bottom_sheet.dart';
import 'package:mukhliss/widgets/buttons/mapcontrolbutton.dart';
import 'package:mukhliss/widgets/buttons/route_bottom_sheet.dart';
import 'package:mukhliss/widgets/buttons/ShopDetailsBottomSheet.dart';
import 'package:mukhliss/widgets/direction_arrow_widget.dart';
import 'package:mukhliss/widgets/search.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
enum BottomSheetState {
  none,
  categories,
  shopDetails,
  route,
  search
}

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationScreen> createState() => LocationScreenState();
}
class LocationScreenState extends ConsumerState<LocationScreen> with TickerProviderStateMixin {
 late final LocationController controller;
   final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  final MapController _mapController = MapController();
  Categories? _selectedCategory; 
  Position? _currentPosition;
  bool _isLocationLoading = false;
  bool _isRouting = false;
  List<LatLng> _polylinePoints = [];
Store? _selectedShop;
  Map<String, dynamic>? _routeInfo;
  TransportMode _selectedMode = TransportMode.walking;
  bool _showTransportModes = false;
  bool _storesLoaded = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;
  List<Store> _searchResults = [];
  
  // Énumérations et variables pour les couches de carte
  MapLayerType _selectedMapLayer = MapLayerType.plan;
  bool _showMapLayers = false;
  bool _categoriesBottomSheetShown = false; 
  // Données statiques des magasins - Région de San Francisco Bay Area
    List<String> imageUrls = [];
    // Dans _LocationScreenState
Position? _lastPosition;
double? _currentBearing;
// StreamSubscription<Position>? _positionStream;
bool _isNavigating = false;
List<LatLng> _routeSteps = []; // Pour stocker les étapes de l'itinéraire
int _currentStepIndex = 0; // Index de l'étape actuelle
Timer? _searchDebounceTimer;
StreamSubscription<Position>? _positionStream;
  Timer? _navigationTimer;
BottomSheetState _bottomSheetState = BottomSheetState.none;
bool _disposed = false;

// Update the initState method to use safe callbacks
@override
void initState() {
  super.initState();
  
  controller = LocationController(
    ref, 
    context,
    _mapController,
    (position) {
      _safeSetState(() => _currentPosition = position);
    },
    (isLoading) {
      _safeSetState(() => _isLocationLoading = isLoading);
    },
    (points) {
      _safeSetState(() {
        _polylinePoints = points;
      });
    },
    (isNavigating) {
      _safeSetState(() {
        _isNavigating = isNavigating;
      });
    },
  );
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && !_disposed) {
      controller.getCurrentLocation();
    }
  });
}


  void _handleStoreSelection(Store? store, Categories? category) {
  if (store == null || _disposed) return;

  _safeSetState(() {
    _selectedShop = store;
    _selectedCategory = category;
    _bottomSheetState = BottomSheetState.shopDetails;
  });
  
  // Centrer la carte sur le magasin
  _mapController.move(
    LatLng(store.latitude, store.longitude),
    17.0,
  );
  
  // Afficher le sheet après un léger délai
  Future.delayed(const Duration(milliseconds: 300), () {
    _showShopDetails(store);
  });
}
   
  void _startNavigation() {
    if (_selectedShop == null || _currentPosition == null || _disposed) return;

    _safeSetState(() {
      _isNavigating = true;
      // Calculer le bearing initial
      _currentBearing = Geolocator.bearingBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _selectedShop!.latitude,
        _selectedShop!.longitude,
      );
    });
    
    // Démarrer les mises à jour de position
    _startPositionUpdates();
  }

void _startPositionUpdates() {
  if (_disposed) return;
  
  const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Update every 5 meters
  );

  // Cancel existing stream
  _positionStream?.cancel();

  _positionStream = Geolocator.getPositionStream(
    locationSettings: locationSettings,
  ).listen(
    (Position position) {
      if (_disposed || !mounted || !_isNavigating || _selectedShop == null) return;
      
      // Update position and bearing
      _safeSetState(() {
        _currentPosition = position;
        _currentBearing = Geolocator.bearingBetween(
          position.latitude,
          position.longitude,
          _selectedShop!.latitude,
          _selectedShop!.longitude,
        );
      });
      
      // Update camera position
      _updateCameraPosition(position, _currentBearing);
      
      // Check if arrived
      _checkArrival(position);
    },
    onError: (error) {
      if (!_disposed) {
        debugPrint('Position stream error: $error');
      }
    },
  );
}

 void _closeAllSheets() {
  if (_disposed) return;
  _safeSetState(() {
    _bottomSheetState = BottomSheetState.none;
    // Optionnel: reset d'autres états si nécessaire
    _selectedShop = null;
    _polylinePoints = [];
  });
  
  // Recentrer la carte si position disponible
  if (_currentPosition != null) {
    _mapController.move(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      17.0,
    );
  }
}

    // Callback pour le CategoriesBottomSheet
void _onCategorySelected(Categories? category, Store? store) {
   if (_disposed) return;
  _safeSetState(() {
    _selectedCategory = category;
    if (store != null) {
      _selectedShop = store;
      _showTransportModes = true;
    }
    _categoriesBottomSheetShown = false;
  });
  
  if (store != null) {
    _mapController.move(
      LatLng(store.latitude, store.longitude),
      17.0,
    );
  }
}
 
@override
void dispose() {
  debugPrint('[DISPOSE] LocationScreen disposing...');
  
  // Set disposed flag first
  _disposed = true;
  
  // Cancel all streams and timers
  _positionStream?.cancel();
  _positionStream = null;
  _navigationTimer?.cancel();
  _navigationTimer = null;
  _searchDebounceTimer?.cancel();
  _searchDebounceTimer = null;
  
  // Dispose controller (this will also cancel its streams)
  controller.dispose();
  
  // Dispose other controllers
  _mapController.dispose();
  _searchController.dispose();
  
  // Clear references
  _selectedShop = null;
  _routeInfo = null;
  _polylinePoints.clear();
  _searchResults.clear();
  
  debugPrint('[DISPOSE] LocationScreen disposed');
  super.dispose();
}

// Also add this helper method to safely call setState
void _safeSetState(VoidCallback fn) {
  if (mounted && !_disposed) {
    setState(fn);
  }
}

void _handleCategoriesAndPosition(WidgetRef ref) {
  final categoriesAsync = ref.watch(categoriesListProvider);
  final position = _currentPosition;
  
  // Vérifiez que la position est disponible ET que les magasins sont chargés
  if (position != null && !_categoriesBottomSheetShown && _storesLoaded) {
    categoriesAsync.whenData((categories) {
      if (categories.isNotEmpty && mounted) {
        _showCategoriesBottomSheetAuto(categories);
      }
    });
  }
}
  Future<void> _centerOnCurrentLocation() async {
    if (_currentPosition != null) {
   
     if (_currentPosition != null) {
  _mapController.move(
    LatLng(_currentPosition!.latitude.toDouble(), _currentPosition!.longitude.toDouble()),
    17.0,
  );
}
    } else {
      controller.getCurrentLocation();
    }
  }

void _showCategoriesBottomSheetAuto(List<Categories> categories) {
  if (_categoriesBottomSheetShown || !mounted || _disposed) return;

  _safeSetState(() => _categoriesBottomSheetShown = true);
}
void _initiateRouting(Store shop) async {
  if (_disposed) return;

  debugPrint('[ROUTE] Initiating routing to ${shop.nom_enseigne}');
   setState(() {
    _isRouting = true;
   
  });
  
  try {
    final routeInfo = await OSRMRoutingService().getRouteInfo(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      LatLng(shop.latitude, shop.longitude),
      _selectedMode,
    );

    if (_disposed || !mounted) return;

    _safeSetState(() {
      _routeInfo = routeInfo;
      _isRouting = false;
      _polylinePoints = routeInfo?['polyline'] ?? []; // Assurez-vous que c'est bien 'polyline'
      _selectedShop = shop;
    });

    debugPrint('Polyline points count: ${_polylinePoints.length}'); // Debug
    if (_polylinePoints.isEmpty) {
      debugPrint('Aucun point de polyline reçu!');
    }

    _showRouteBottomSheet(shop, routeInfo ?? {});
    _fitMapToRoute(_polylinePoints);

      // Démarrer automatiquement la navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        _startNavigation();
      });
  } catch (e, stack) {
    debugPrint('[ROUTE ERROR] $e');
    debugPrint(stack.toString());
    if (mounted && !_disposed) {
      setState(() => _isRouting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }
}
void _updateCameraPosition(Position position, double? bearing) {
    final newCenter = LatLng(position.latitude, position.longitude);
    if (bearing != null && _isNavigating) {
      // Centrer la carte sur la nouvelle position avec rotation
      _mapController.move(newCenter, 18.0); // Zoom plus proche pour la navigation
      // Optionnel : faire tourner la carte selon la direction
    } else {
      _mapController.move(newCenter, _mapController.camera.zoom);
    }
  }
 void _checkArrival(Position position) {
    if (_selectedShop == null) return;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _selectedShop!.latitude,
      _selectedShop!.longitude,
    );

    if (distance < 50) { // 50 mètres
      _showArrivalNotification();
      _stopNavigation();
    }
  }
void _showArrivalNotification() {
    if (!mounted) return;
    
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text( l10n?.arrivee ??'Vous êtes arrivé à ${_selectedShop?.nom_enseigne}'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.surface,
          onPressed: () {},
        ),
      ),
    );
  }
void _showRouteBottomSheet(Store shop, Map<String, dynamic> routeInfo) {
   if (_disposed) return;
  _safeSetState(() {
    _selectedShop = shop;
    _routeInfo = routeInfo;
    _bottomSheetState = BottomSheetState.route;
      _categoriesBottomSheetShown = false; 
  });
}
  void _fitMapToRoute(List<LatLng> points) {
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

    final southWest = LatLng(minLat, minLng);
    final northEast = LatLng(maxLat, maxLng);
    final bounds = LatLngBounds(southWest, northEast);

    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)));
  }

  void _toggleMapLayers() {
    setState(() {
      _showMapLayers = !_showMapLayers;
    });
  }

void _navigateToStoreAndShowDetails(Store store) async {
  // 1. Fermer la feuille de recherche si elle est ouverte
  if (_bottomSheetState == BottomSheetState.search && Navigator.canPop(context)) {
    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 200));
  }
  // 2. Mettre à jour l'état avant toute animation
  if (!mounted) return;
  setState(() {
    _selectedShop = store;
    _bottomSheetState = BottomSheetState.shopDetails;
  });
  // 3. Animer la carte vers le magasin
  _mapController.move(
    LatLng(store.latitude, store.longitude),
    17.0,
  );
  // 4. Attendre que la carte ait fini de se déplacer
  await Future.delayed(const Duration(milliseconds: 500));
  
  // 5. Afficher les détails
  if (!mounted) return;
  debugPrint('Showing shop details...');
  _showShopDetails(store);
}

  void _stopNavigation() {
    if (_disposed) return;
    _positionStream?.cancel();
    _navigationTimer?.cancel();

    _safeSetState(() {
      _isNavigating = false;
      _currentBearing = null;
      _lastPosition = null;
    });
  }

   @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesListProvider);
     final themeMode = ref.watch(themeProvider);
      final isDarkMode = themeMode == AppThemeMode.light;

    print('[DEBUG] RouteBottomSheet conditions: '
      'isRouteBottomSheetShowing: ${controller.isRouteBottomSheetShowing}, '
      'selectedShop: ${controller.selectedShop != null}, '
      'routeInfo: ${controller.routeInfo != null}, '
      'isNavigating: $_isNavigating');
 
    storesAsync.whenData((_) {
    if (mounted) {
      setState(() {
        _storesLoaded = true;
      });
    }
  });
     _handleCategoriesAndPosition(ref);

    return Scaffold(
      body:  Stack(
        children: [
          Positioned.fill(child:  FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition != null 
                        ? LatLng(_currentPosition!.latitude.toDouble(), _currentPosition!.longitude.toDouble())
                        : const LatLng(35.7595, -5.8340),
                    initialZoom: _currentPosition != null ? 17.0 : 13.0,
                  ),
                  children: [
                    // Map layers
                   ...MapLayerUtils.getMapLayers(_selectedMapLayer),
                    // Route polyline
                    if (_polylinePoints.isNotEmpty)
                      PolylineLayer( 
                        polylines: [
                           Polyline(
                           points: _polylinePoints,
                           color: _getRouteColor(_selectedMode),
                           strokeWidth: 6.0,
                           borderColor: Colors.white.withOpacity(0.5),
                          borderStrokeWidth: 3.0,
                           )
                        ],
                      ),
                    // Shop markers
                    MarkerLayer(
                      markers: storesAsync.maybeWhen(
                        data: (stores) {
                          List<Store> filteredStores = stores;
                          if (_selectedCategory != null) {
                            filteredStores = stores.where((store) => 
                              store.Categorieid == _selectedCategory!.id
                            ).toList();
                          }
                          return filteredStores.map((store) {
                            return Marker(
                              point: LatLng(store.latitude.toDouble(), store.longitude.toDouble()),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _navigateToStoreAndShowDetails(store),
                                child: CategoryMarkers.getPinWidget(
                                  CategoryHelpers.getCategoryName(ref, store.Categorieid),
                                  size: 40,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        orElse: () => [],
                      ),
                    ),
                    // Current position marker
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              _currentPosition!.latitude.toDouble(),
                              _currentPosition!.longitude.toDouble(),
                            ),
                            width: 48,
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:Colors.blue.withOpacity(0.2),
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.shade700,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
           if (_isNavigating && _selectedShop != null && _currentPosition != null)
           Positioned(
               bottom: 0,
                left: 0,
                 right: 0,
                  child: Container(
                     height: MediaQuery.of(context).size.height * 0.7,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                          child: controller.isRouteBottomSheetShowing && 
                               controller.selectedShop != null && 
                              controller.routeInfo != null
                                ? RouteBottomSheet(
                                  key: ValueKey(controller.selectedShop?.id ?? 'routeSheet'),
                                      shop: controller.selectedShop!,
                                     currentPosition: _currentPosition,
                                      selectedMode: controller.selectedMode,
                                      routeInfo: controller.routeInfo,
                                        showTransportModes: _showTransportModes,
                                         onModeChanged: (newMode) {
                                           setState(() => _selectedMode = newMode);
                                            _initiateRouting(_selectedShop!);
                                              },
                                            onRecenter: _centerOnCurrentLocation,
                                              onCancel: () {
                                               controller.clearRoute();
                                                 setState(() {
                                                       _showTransportModes = false;
                                                     });
                                                   },
                                                onShowShopDetails: () async {
                                   if (!mounted || controller.selectedShop == null) return;
                                },
              )
            : const SizedBox.shrink(),
                 ),
               ),
                  ),
          MarkerLayer(
            markers: storesAsync.maybeWhen(
              data: (stores) {
                List<Store> filteredStores = stores;
                if (_selectedCategory != null) {
                  filteredStores = stores.where((store) => 
                    store.Categorieid == _selectedCategory!.id
                  ).toList();
                }
                
                return filteredStores.map((store) {
                  return Marker(
                    point: LatLng(store.latitude.toDouble(), store.longitude.toDouble()),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _navigateToStoreAndShowDetails(store),
                      child: CategoryMarkers.getPinWidget(
                        CategoryHelpers.getCategoryName(ref, store.Categorieid),
                        size: 40,
                      ),
                    ),
                  );
                }).toList();
              },
              orElse: () => [],
            ),
          ),
                  ],
                ),),
        // Résultats de recherche
        if (_showSearchBar && _searchResults.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            right: 16,
            child: _buildSearchResults(),
          ),
Positioned(
  top: MediaQuery.of(context).padding.top + 16,
  right: 16,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      _buildSearchButton(context, ref),
      const SizedBox(height: 10),
      // Bouton pour arrêter la navigation (visible seulement pendant la navigation)
      if (_isNavigating)
        MapControllerButton(
          icon: Icons.stop,
          onPressed: () {
            _stopNavigation();
            setState(() {
              _bottomSheetState = BottomSheetState.none;
              _polylinePoints = []; 
            });
          },
          backgroundColor: AppColors.error,
          isLoading: false,
        ),
      if (_isNavigating)
        const SizedBox(height: 10),
      // Boutons de contrôle
      MapControllerButton(
        icon: Icons.my_location,
        onPressed: _currentPosition != null ? _centerOnCurrentLocation : null,
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.primary,
        isLoading: _isLocationLoading,
      ),
      const SizedBox(height: 10),
      MapControllerButton(
        icon: Icons.refresh,
        onPressed: _isLocationLoading ? null : () => controller.getCurrentLocation(),
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.primary,
        isLoading: _isLocationLoading,
      ),
      const SizedBox(height: 10),
      MapControllerButton(
        icon: Icons.layers,
        onPressed: _toggleMapLayers,
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.primary,
        isLoading: _isLocationLoading,
      ),
      const SizedBox(height: 20),
    ],
  ),
),
if (_isNavigating && _selectedShop != null && _currentPosition != null)
  Positioned(
    top: MediaQuery.of(context).padding.top + 10,
    right: 120,
    child: NavigationArrowWidget(
      currentPosition: _currentPosition,
      selectedShop: _selectedShop,
      isNavigating: _isNavigating,
      currentBearing: _currentBearing,
      onStopNavigation: _stopNavigation,
      onPositionUpdate: (newPosition) {
        setState(() {
          _currentPosition = newPosition;
          _lastPosition = newPosition;
          _currentBearing = Geolocator.bearingBetween(
            newPosition.latitude,
            newPosition.longitude,
            _selectedShop!.latitude,
            _selectedShop!.longitude,
          );
        });
      },
      updateCameraPosition: _updateCameraPosition,
    ),
  ),
          // Categories BottomSheet
        if (_categoriesBottomSheetShown && !_showTransportModes)
      Positioned(
        child:  CategoriesBottomSheet(
    navigatorKey: navigatorKey,
  initialCategory: _selectedCategory,
  currentPosition: _currentPosition,
  mapController: _mapController,
  onStoreSelected: _handleStoreSelection,
  onCategorySelected: _onCategorySelected,
  onClose: _closeAllSheets,
),),
   if (_bottomSheetState == BottomSheetState.shopDetails && _selectedShop != null)
             ShopDetailsBottomSheet(
              navigatorKey: navigatorKey,
              shop: _selectedShop!,
              currentPosition: _currentPosition,
              ref: ref,
              vsync: this,
              isRouting: _isRouting,
              onStoreSelected: _handleStoreSelection,
              selectedCategory: _selectedCategory,
              initiateRouting: _initiateRouting,
              closeCategoriesSheet:  () {
      setState(() {
        _bottomSheetState = BottomSheetState.none; // Réinitialise l'état
      });
    },
            ),    
  // Dans la méthode build, ajoutez ce widget conditionnel
if (_bottomSheetState == BottomSheetState.route && _selectedShop != null && _routeInfo != null)
  RouteBottomSheet(
    shop: _selectedShop!,
    currentPosition: _currentPosition,
    selectedMode: _selectedMode,
    routeInfo: _routeInfo!,
    showTransportModes: true,
    onModeChanged: (mode) {
      setState(() => _selectedMode = mode);
      _initiateRouting(_selectedShop!);
    },
    onRecenter: _centerOnCurrentLocation,
    onCancel: () {
      setState(() {
        _polylinePoints = [];
        _bottomSheetState = BottomSheetState.none;
      });
    },
    onShowShopDetails: () {
      setState(() {
        _bottomSheetState = BottomSheetState.shopDetails;
      });
    },
  ),
          // Map layers selector
          if (_showMapLayers)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.layers, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Type de carte',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _showMapLayers = false),
                          child: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MapLayerButton(
          layer: MapLayerType.plan,
          selectedLayer: _selectedMapLayer,
          icon: Icons.map,
          label: 'Plan',
          onSelected: (layer) {
              setState(() {
                _selectedMapLayer = layer;
                _showMapLayers = false;
              });
            },
        ),
        MapLayerButton(
          layer: MapLayerType.satellite,
          selectedLayer: _selectedMapLayer,
          icon: Icons.satellite_alt,
          label: 'Satellite',
          onSelected: (layer) {
              setState(() {
                _selectedMapLayer = layer;
                _showMapLayers = false;
              });
            },
        ),
        MapLayerButton(
          layer: MapLayerType.terrain,
          selectedLayer: _selectedMapLayer,
          icon: Icons.terrain,
          label: 'Terrain',
          onSelected: (layer) {
              setState(() {
                _selectedMapLayer = layer;
                _showMapLayers = false;
              });
            },
        ),
        MapLayerButton(
          layer: MapLayerType.trafic,
          selectedLayer: _selectedMapLayer,
          icon: Icons.traffic,
          label: 'Trafic',
          onSelected: (layer) {
              setState(() {
                _selectedMapLayer = layer;
                _showMapLayers = false;
              });
            },
        ),
                  ],
                ),
              ),
            ),
        ],
      ),  
    );
  }
  Widget _buildSearchButton(BuildContext context, WidgetRef ref) {
  final themeMode = ref.watch(themeProvider);
  final isDarkMode = themeMode == AppThemeMode.light;
  return Material(
    shape: const CircleBorder(),
    elevation: 2,
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode ? AppColors.darkSurface : AppColors.primary,
      ),
      child: IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: () => _showSearchBottomSheet(),
      ),
    ),
  );
}
void _showSearchBottomSheet() {
  final themeMode = ref.watch(themeProvider);
  final isDarkMode = themeMode == AppThemeMode.light;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Important pour le clavier
    backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
    builder: (context) {
      return SearchWidget(
        initialStores: ref.read(storesListProvider).value ?? [], // Votre liste de magasins
        currentPosition: _currentPosition, // Position GPS
        moveMap: (latLng) {
          // Déplacer la carte vers la position
          _mapController.move(latLng, 17.0);
        },
        showShopDetails:  (store) async {
          Navigator.pop(context); // Fermez d'abord la search sheet
          _navigateToStoreAndShowDetails(store);
        },
        searchResultsPerPage: 10, // Nombre d'éléments par page
      );
    },
  );
}
  Color _getRouteColor(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving:
        return AppColors.accent;
      case TransportMode.walking:
        return AppColors.success;
      case TransportMode.cycling:
        return AppColors.warning;
    }
  }

Widget _buildSearchResults() {
  return Material(
    elevation: 4,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final store = _searchResults[index];
          final distance = _currentPosition != null
              ? Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  store.latitude,
                  store.longitude,
                )
              : 0.0;
          
          return ListTile(
            leading: Icon(
              CategoryMarkers.getPinIcon(
                CategoryHelpers.getCategoryName(ref, store.Categorieid),
              ),
              color: CategoryMarkers.getPinColor(
                CategoryHelpers.getCategoryName(ref, store.Categorieid),
              ),
            ),
            title: Text(store.nom_enseigne),
            subtitle: Text(store.adresse),
            trailing: Text(
              distance < 1000
                  ? '${distance.toStringAsFixed(0)} m'
                  : '${(distance / 1000).toStringAsFixed(1)} km',
            ),
           onTap: () async {
  if (!mounted) return;
  
  setState(() {
    _showSearchBar = false;
    _searchController.clear();
    _searchResults = [];
  });
  
  _mapController.move(
    LatLng(store.latitude.toDouble(), store.longitude.toDouble()),
    17.0,
  );
  
  await Future.delayed(const Duration(milliseconds: 400));
  if (!mounted) return;
   _navigateToStoreAndShowDetails(store);
},
          );
        },
      ),
    ),
  );
}
void _showShopDetails(Store store) {
  if (!mounted || _disposed) return;
  debugPrint('Updating UI for shop details...');
  _safeSetState(() {
    _selectedShop = store;
    _bottomSheetState = BottomSheetState.shopDetails;
  });
}

}
