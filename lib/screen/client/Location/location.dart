import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/providers/rewards_provider.dart';
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
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mukhliss/widgets/search.dart';

enum BottomSheetState { none, categories, shopDetails, route, search }

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationScreen> createState() => LocationScreenState();
}

class LocationScreenState extends ConsumerState<LocationScreen>
    with TickerProviderStateMixin {
  late final LocationController controller;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  final MapController _mapController = MapController();
  Categories? _selectedCategory;
  Position? _currentPosition;
  bool _isLocationLoading = false;
  bool _isRouting = false;
  AnimationController? _orbitController;
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
  bool _isCheckingConnectivity = true;
  bool _hasConnection = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  // Update the initState method to use safe callbacks
  void initState() {
    super.initState();
    _disposed = false;

    // 1. Initialize animation controller first
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // 2. Initialize location controller
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

    // 3. Initialize connectivity with proper error handling
    _initializeApp();
  }

  // Future<void> _initializeApp() async {
  //   try {
  //     // Check connectivity first
  //     await _checkConnectivity();

  //     // If we have connection, get location
  //     if (_hasConnection && mounted && !_disposed) {
  //       // Small delay to ensure everything is initialized
  //       await Future.delayed(const Duration(milliseconds: 500));

  //       if (mounted && !_disposed) {
  //         controller.getCurrentLocation();
  //       }
  //     }
  //   } catch (e) {
  //     print('[DEBUG] Initialization error: $e');
  //     if (mounted && !_disposed) {
  //       _safeSetState(() {
  //         _isCheckingConnectivity = false;
  //       });
  //     }
  //   }
  // }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🚀 Initialisation de l\'app...');

      // Vérifier la connexion sans bloquer le chargement initial
      _checkConnectivity().then((_) {
        debugPrint('✅ Vérification connexion terminée: $_hasConnection');
      });

      // Charger la position IMMÉDIATEMENT (en parallèle)
      if (mounted && !_disposed) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && !_disposed) {
          controller.getCurrentLocation();
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur initialisation: $e');
      if (mounted && !_disposed) {
        _safeSetState(() {
          _isCheckingConnectivity = false;
        });
      }
    }
  }

  Future<void> _checkConnectivity() async {
    if (!mounted || _disposed) return;

    _safeSetState(() {
      _isCheckingConnectivity = true;
    });

    try {
      // Your existing connectivity logic with retry
      await _checkConnectivityWithRetry();
    } catch (e) {
      print('[DEBUG] Connectivity check error: $e');
      if (mounted && !_disposed) {
        _safeSetState(() {
          _hasConnection = false;
          _isCheckingConnectivity = false;
        });
      }
    }
  }

  Future<void> _checkConnectivityWithRetry({int retryCount = 0}) async {
    const maxRetries = 2;

    if (!mounted || _disposed) return;

    try {
      final connectivityResult = await InternetConnection().hasInternetAccess;
      print('[DEBUG] Connectivity (attempt $retryCount): $connectivityResult');

      if (connectivityResult == ConnectivityResult.none &&
          retryCount < maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
        return _checkConnectivityWithRetry(retryCount: retryCount + 1);
      }

      final reallyConnected = await _checkRealInternetConnection();

      if (mounted && !_disposed) {
        _safeSetState(() {
          _hasConnection =
              connectivityResult != ConnectivityResult.none && reallyConnected;
          if (_hasConnection) {
            print('[DEBUG] Internet connection verified.');
            refreshData(); // Refresh
          } else {
            print('[DEBUG] No internet connection.');
          }
          _isCheckingConnectivity = false;
        });
      }
    } catch (e) {
      print('[DEBUG] Connectivity error: $e');
      if (mounted && !_disposed) {
        _safeSetState(() {
          _hasConnection = false;
          _isCheckingConnectivity = false;
        });
      }
    }
  }

  Future<bool> _checkRealInternetConnection() async {
    try {
      // Test multiple servers
      final futures = [
        InternetAddress.lookup('google.com'),
        InternetAddress.lookup('cloudflare.com'),
        InternetAddress.lookup('example.com'),
      ];

      final results = await Future.wait(
        futures,
      ).timeout(const Duration(seconds: 10));

      return results.any(
        (result) => result.isNotEmpty && result[0].rawAddress.isNotEmpty,
      );
    } catch (e) {
      debugPrint('Real internet check failed: $e');
      return false;
    }
  }

  // Dans votre LocationScreenState
  void _refreshStoresOnConnectionRestored() {
    if (_hasConnection) {
      debugPrint('🔄 Connexion restaurée - Rechargement des magasins');
      // Invalider le provider pour forcer le rechargement
      ref.invalidate(storesListProvider);

      // Optionnel: recharger aussi les catégories
      ref.invalidate(categoriesListProvider);
    }
  }

  // Modifiez votre méthode _updateConnectionStatus
  void _updateConnectionStatus(ConnectivityResult result) {
    if (!mounted || _disposed) return;

    final newStatus = result != ConnectivityResult.none;
    final wasDisconnected = !_hasConnection && newStatus;

    _safeSetState(() {
      _hasConnection = newStatus;
    });

    // Rafraîchir les données si la connexion revient
    if (wasDisconnected) {
      debugPrint('📡 Connexion restaurée - Rafraîchissement des données');
      _refreshStoresOnConnectionRestored();

      // Recharger aussi la position si nécessaire
      if (_currentPosition == null) {
        controller.getCurrentLocation();
      }
    }
  }

  Widget _buildNoConnectionWidget(
    BuildContext context,
    AppLocalizations? l10n,
    bool isDarkMode,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône d’avertissement
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.red.withOpacity(0.1),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 20),

              // Texte principal
              Text(
                l10n?.somethingwrong ?? "Something went wrong",
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Bouton "Réessayer"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checkConnectivity,

                  label: Text(
                    l10n?.retry ?? 'Réessayer',
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
void refreshShopRewards(Store? shop) {
  final shopId = shop?.id;
  if (shopId != null && shopId.isNotEmpty) {
    ref.invalidate(rewardsByMagasinProvider(shopId));
    
    // Appeler le callback parent si fourni
    
    
    print("🔄 Rewards rafraîchis pour le magasin: $shopId");
    
    
  }
}
  void _handleStoreSelection(Store? store, Categories? category) {
    if (store == null || _disposed) return;
    
    if (store.id != _selectedShop?.id) {
      refreshShopRewards(store);
    print('🔄 Rafraîchissement des rewards pour le magasin: ${store.id}');
  }

    _safeSetState(() {
      _selectedShop = store;
      _selectedCategory = category;
      _bottomSheetState = BottomSheetState.shopDetails;
    });

    // Centrer la carte sur le magasin
    _mapController.move(LatLng(store.latitude, store.longitude), 17.0);

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
      distanceFilter: 5, // 5 mètres pour équilibrer précision et performance
    );

    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (_disposed || !mounted || !_isNavigating) return;

        _safeSetState(() {
          _currentPosition = position;
          // La flèche sera automatiquement mise à jour via _buildNavigationMarkers
        });

        // Centrer la carte sur la nouvelle position
        _updateCameraPosition(position, null);

        // Vérifier l'arrivée
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
      _mapController.move(LatLng(store.latitude, store.longitude), 17.0);
    }
  }

  @override
  void dispose() {
    debugPrint('[DISPOSE] LocationScreen disposing...');
    _connectivitySubscription?.cancel();
    // Set disposed flag first
    _disposed = true;
    _orbitController?.dispose();
    _orbitController = null;
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
          LatLng(
            _currentPosition!.latitude.toDouble(),
            _currentPosition!.longitude.toDouble(),
          ),
          17.0,
        );
      }
    } else {
      controller.getCurrentLocation();
    }
  }

  void _showCategoriesBottomSheetAuto(List<Categories> categories) {
    if (_categoriesBottomSheetShown || !mounted || _disposed) return;
    debugPrint('[DEBUG] Attempting to show categories bottom sheet');
    _safeSetState(() {
      _categoriesBottomSheetShown = true;
      _bottomSheetState = BottomSheetState.categories; // AJOUT IMPORTANT
    });
    debugPrint(
      '[DEBUG] Categories bottom sheet state updated: $_categoriesBottomSheetShown',
    );
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
        _polylinePoints =
            routeInfo?['polyline'] ??
            []; // Assurez-vous que c'est bien 'polyline'
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  void _updateCameraPosition(Position position, double? bearing) {
    final newCenter = LatLng(position.latitude, position.longitude);
    if (bearing != null && _isNavigating) {
      // Centrer la carte sur la nouvelle position avec rotation
      _mapController.move(
        newCenter,
        18.0,
      ); // Zoom plus proche pour la navigation
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

    if (distance < 50) {
      // 50 mètres
      _showArrivalNotification();
      _stopNavigation();
    }
  }

  void refreshData() {
    if (_disposed) return;

    // Refresh both providers
    ref.refresh(categoriesListProvider);
    ref.refresh(storesListProvider);

    // Reset relevant state
    _safeSetState(() {
      _storesLoaded = false;
      _categoriesBottomSheetShown = false;
      _selectedCategory = null;
      _selectedShop = null;
      _bottomSheetState = BottomSheetState.none;
    });
    print("============> Refreshing data");

  }

  void _showArrivalNotification() {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.arrivee ?? 'Vous êtes arrivé à ${_selectedShop?.nom_enseigne}',
        ),
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

    _updateBottomSheetState(BottomSheetState.route);
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

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)),
    );
  }

  void _toggleMapLayers() {
    setState(() {
      _showMapLayers = !_showMapLayers;
    });
  }

  void _navigateToStoreAndShowDetails(Store store) async {
    // 1. Fermer la feuille de recherche si elle est ouverte
    if (_bottomSheetState == BottomSheetState.search &&
        Navigator.canPop(context)) {
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    refreshShopRewards(store);
    // 2. Mettre à jour l'état avant toute animation
    if (!mounted) return;
    setState(() {
      _selectedShop = store;
      _bottomSheetState = BottomSheetState.shopDetails;
    });
    // 3. Animer la carte vers le magasin
    _mapController.move(LatLng(store.latitude, store.longitude), 17.0);
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
    final l10n = AppLocalizations.of(context);
    print(
      '[DEBUG] RouteBottomSheet conditions: '
      'isRouteBottomSheetShowing: ${controller.isRouteBottomSheetShowing}, '
      'selectedShop: ${controller.selectedShop != null}, '
      'routeInfo: ${controller.routeInfo != null}, '
      'isNavigating: $_isNavigating',
    );
    if (_isCheckingConnectivity) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.surface,
        body: _buildConnectivityCheckWidget(context),
      );
    }
    print('[DEBUG] Connectivity status: hasConnection=$_hasConnection');
    if (!_hasConnection) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.surface,
        body: _buildNoConnectionWidget(context, l10n, isDarkMode),
      );
    }

    storesAsync.whenData((_) {
      if (mounted) {
        setState(() {
          _storesLoaded = true;
        });
      }
    });
    _handleCategoriesAndPosition(ref);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    _currentPosition != null
                        ? LatLng(
                          _currentPosition!.latitude.toDouble(),
                          _currentPosition!.longitude.toDouble(),
                        )
                        : const LatLng(35.7595, -5.8340),
                initialZoom: _currentPosition != null ? 17.0 : 13.0,
                onMapReady: () {
                  debugPrint('🎯 Carte FlutterMap prête !');

                  // Marquer la carte comme prête dans le controller
                  controller.markMapAsReady();

                  // Maintenant que la carte est prête, on peut obtenir la localisation
                  if (_hasConnection && _currentPosition == null) {
                    debugPrint('🔄 Démarrage de la localisation...');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_disposed) {
                        controller.getCurrentLocation();
                      }
                    });
                  }
                },
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
                      ),
                    ],
                  ),
                // Shop markers
                // MarkerLayer(
                //   markers: [
                //     ...storesAsync.maybeWhen(
                //       data: (stores) {
                //         List<Store> filteredStores = stores;
                //         if (_selectedCategory != null) {
                //           filteredStores =
                //               stores
                //                   .where(
                //                     (store) =>
                //                         store.Categorieid ==
                //                         _selectedCategory!.id,
                //                   )
                //                   .toList();
                //         }
                //         return filteredStores.map((store) {
                //           return Marker(
                //             point: LatLng(
                //               store.latitude.toDouble(),
                //               store.longitude.toDouble(),
                //             ),
                //             width: 40,
                //             height: 40,
                //             child: GestureDetector(
                //               onTap:
                //                   () => _navigateToStoreAndShowDetails(store),
                //               child: CategoryMarkers.getPinWidget(
                //                 CategoryHelpers.getCategoryName(
                //                   ref,
                //                   store.Categorieid,
                //                 ),
                //                 size: 40,
                //               ),
                //             ),
                //           );
                //         }).toList();
                //       },
                //       orElse: () => [],
                //     ),
                //   ],
                // ),
                // Current position marker
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      // Si on n'est PAS en navigation, affichage normal
                      if (!_isNavigating)
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
                                  color: Colors.blue.withOpacity(0.2),
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

                      // Si on EST en navigation, utiliser les marqueurs avec flèche orbitale
                      if (_isNavigating &&
                          _selectedShop != null &&
                          _polylinePoints.isNotEmpty)
                        ..._buildNavigationMarkers(),
                    ],
                  ),
                if (_isNavigating &&
                    _selectedShop != null &&
                    _currentPosition != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child:
                            controller.isRouteBottomSheetShowing &&
                                    controller.selectedShop != null &&
                                    controller.routeInfo != null
                                ? RouteBottomSheet(
                                  key: ValueKey(
                                    controller.selectedShop?.id ?? 'routeSheet',
                                  ),
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
                                    if (!mounted ||
                                        controller.selectedShop == null)
                                      return;
                                  },
                                )
                                : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                if (storesAsync.hasValue || storesAsync.isLoading)
                  MarkerLayer(markers: _buildStoreMarkers(storesAsync)),
                // MarkerLayer(
                //   markers: storesAsync.maybeWhen(
                //     data: (stores) {
                //       List<Store> filteredStores = stores;
                //       if (_selectedCategory != null) {
                //         filteredStores =
                //             stores
                //                 .where(
                //                   (store) =>
                //                       store.Categorieid ==
                //                       _selectedCategory!.id,
                //                 )
                //                 .toList();
                //       }

                //       return filteredStores.map((store) {
                //         return Marker(
                //           point: LatLng(
                //             store.latitude.toDouble(),
                //             store.longitude.toDouble(),
                //           ),
                //           width: 40,
                //           height: 40,
                //           child: GestureDetector(
                //             onTap: () => _navigateToStoreAndShowDetails(store),
                //             child: CategoryMarkers.getPinWidget(
                //               CategoryHelpers.getCategoryName(
                //                 ref,
                //                 store.Categorieid,
                //               ),
                //               size: 40,
                //             ),
                //           ),
                //         );
                //       }).toList();
                //     },
                //     orElse: () => [],
                //   ),
                // ),
              ],
            ),
          ),
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
                if (_isNavigating) const SizedBox(height: 10),
                // Boutons de contrôle
                MapControllerButton(
                  icon: Icons.my_location,
                  onPressed:
                      _currentPosition != null
                          ? _centerOnCurrentLocation
                          : null,
                  backgroundColor:
                      isDarkMode ? AppColors.darkSurface : AppColors.primary,
                  isLoading: _isLocationLoading,
                ),
                const SizedBox(height: 10),
                MapControllerButton(
                  icon: Icons.refresh,
                  onPressed:
                      _isLocationLoading
                          ? null
                          : () => controller.getCurrentLocation(),
                  backgroundColor:
                      isDarkMode ? AppColors.darkSurface : AppColors.primary,
                  isLoading: _isLocationLoading,
                ),
                const SizedBox(height: 10),
                MapControllerButton(
                  icon: Icons.layers,
                  onPressed: _toggleMapLayers,
                  backgroundColor:
                      isDarkMode ? AppColors.darkSurface : AppColors.primary,
                  isLoading: _isLocationLoading,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: CategoriesBottomSheet(
                  key: ValueKey('categoriesSheet'),
                  navigatorKey: navigatorKey,
                  initialCategory: _selectedCategory,
                  currentPosition: _currentPosition,
                  mapController: _mapController,
                  onStoreSelected: _handleStoreSelection,
                  onCategorySelected: _onCategorySelected,
                  onClose: _closeAllSheets,
                ),
              ),
            ),
          ),

          // Categories BottomSheet
          if (_bottomSheetState == BottomSheetState.categories &&
              _currentPosition != null)
            Positioned(
              child: CategoriesBottomSheet(
                navigatorKey: navigatorKey,
                initialCategory: _selectedCategory,
                currentPosition: _currentPosition,
                mapController: _mapController,
                onStoreSelected: _handleStoreSelection,
                onCategorySelected: _onCategorySelected,
                onClose: _closeAllSheets,
              ),
            ),
          if (_bottomSheetState == BottomSheetState.shopDetails &&
              _selectedShop != null)
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ShopDetailsBottomSheet(
                  navigatorKey: navigatorKey,
                  shop: _selectedShop!,
                  currentPosition: _currentPosition,
                  ref: ref,
                  vsync: this,
                  isRouting: _isRouting,
                  onStoreSelected: _handleStoreSelection,
                  selectedCategory: _selectedCategory,
                  initiateRouting: _initiateRouting,
                  closeCategoriesSheet: () {
                    _updateBottomSheetState(BottomSheetState.none);
                  },
                   onRefresh: () {
          // Cette fonction sera appelée quand le bottom sheet rafraîchit
          print("Parent: Les rewards ont été rafraîchis!");
          // Vous pouvez ajouter d'autres logiques ici si besoin
        },
                ),
              ),
            ),
          // Dans la méthode build, ajoutez ce widget conditionnel
          if (_bottomSheetState == BottomSheetState.route &&
              _selectedShop != null &&
              _routeInfo != null)
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: RouteBottomSheet(
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
                      _updateBottomSheetState(BottomSheetState.none);
                    });
                  },
                  onShowShopDetails: () {
                    _updateBottomSheetState(BottomSheetState.shopDetails);
                  },
                ),
              ),
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
                        Icon(
                          Icons.layers,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
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
                          child: Icon(
                            Icons.close,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
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

  List<Marker> _buildStoreMarkers(AsyncValue<List<Store>> storesAsync) {
    debugPrint('🎯 === DÉBUT _buildStoreMarkers ===');
    debugPrint(
      '   État: ${storesAsync.isLoading
          ? "LOADING"
          : storesAsync.hasError
          ? "ERROR"
          : storesAsync.hasValue
          ? "HAS_VALUE"
          : "UNKNOWN"}',
    );

    return storesAsync.when(
      data: (stores) {
        debugPrint('   📊 Données reçues: ${stores.length} magasins');

        if (stores.isEmpty) {
          debugPrint('   ⚠️ Liste vide - AUCUN MARQUEUR');
          return [];
        }

        // Afficher quelques exemples
        for (var i = 0; i < (stores.length > 3 ? 3 : stores.length); i++) {
          final s = stores[i];
          debugPrint(
            '   Store $i: ${s.nom_enseigne} - Lat:${s.latitude} Lng:${s.longitude} Cat:${s.Categorieid}',
          );
        }

        List<Store> filteredStores = stores;

        if (_selectedCategory != null) {
          filteredStores =
              stores
                  .where((store) => store.Categorieid == _selectedCategory!.id)
                  .toList();
          debugPrint(
            '   🔍 Filtre catégorie ${_selectedCategory!.id}: ${filteredStores.length} résultats',
          );
        } else {
          debugPrint(
            '   ℹ️ Pas de filtre catégorie - Affichage de TOUS les magasins',
          );
        }

        if (filteredStores.isEmpty) {
          debugPrint('   ⚠️ Aucun magasin après filtrage');
          return [];
        }

        final markers =
            filteredStores.map((store) {
              debugPrint('   🎯 Création marqueur pour: ${store.nom_enseigne}');

              return Marker(
                point: LatLng(
                  store.latitude.toDouble(),
                  store.longitude.toDouble(),
                ),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    debugPrint('   👆 Tap sur: ${store.nom_enseigne}');
                    _navigateToStoreAndShowDetails(store);
                  },
                  child: CategoryMarkers.getPinWidget(
                    CategoryHelpers.getCategoryName(ref, store.Categorieid),
                    size: 40,
                  ),
                ),
              );
            }).toList();

        debugPrint('   ✅ ${markers.length} MARQUEURS CRÉÉS');
        debugPrint('🎯 === FIN _buildStoreMarkers ===\n');

        return markers;
      },

      loading: () {
        debugPrint('   ⏳ CHARGEMENT en cours...');
        return [];
      },

      error: (error, stack) {
        debugPrint('   ❌ ERREUR: $error');
        debugPrint('   Stack: $stack');

        // Détection spécifique du type d'erreur
        final isTimeout =
            error is TimeoutException ||
            error.toString().contains('Timeout') ||
            error.toString().contains('TimeoutException') ||
            error.toString().contains('timed out');

        final isNetworkError =
            error.toString().contains('SocketException') ||
            error.toString().contains('Connection') ||
            error.toString().contains('network');

        debugPrint(
          '   🔍 Type erreur: ${isTimeout
              ? "TIMEOUT"
              : isNetworkError
              ? "NETWORK"
              : "OTHER"}',
        );

        // Gestion spécifique du timeout
        if (isTimeout && _hasConnection && mounted && !_disposed) {
          debugPrint(
            '   🔄 Timeout détecté - Planification retry automatique...',
          );

          // Retry automatique après 3 secondes
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && !_disposed && _hasConnection) {
              debugPrint('   🔄 Exécution retry automatique...');
              ref.invalidate(storesListProvider);
            }
          });

          // Notification utilisateur
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Connexion lente... Nouvelle tentative en cours',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange.shade700,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Réessayer maintenant',
                    textColor: Colors.white,
                    onPressed: () {
                      debugPrint('   👆 Retry manuel demandé');
                      ref.invalidate(storesListProvider);
                    },
                  ),
                ),
              );
            }
          });
        }
        // Gestion erreur réseau
        else if (isNetworkError && _hasConnection && mounted && !_disposed) {
          debugPrint('   📡 Erreur réseau détectée');

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Problème de connexion réseau',
                    style: TextStyle(fontSize: 14),
                  ),
                  backgroundColor: Colors.red.shade700,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Réessayer',
                    textColor: Colors.white,
                    onPressed: () {
                      ref.invalidate(storesListProvider);
                    },
                  ),
                ),
              );
            }
          });
        }
        // Autres erreurs
        else if (_hasConnection && mounted && !_disposed) {
          debugPrint('   ⚠️ Erreur générique');

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final errorMsg =
                  error.toString().length > 60
                      ? '${error.toString().substring(0, 60)}...'
                      : error.toString();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Erreur: $errorMsg',
                    style: const TextStyle(fontSize: 14),
                  ),
                  backgroundColor: Colors.red.shade700,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Réessayer',
                    textColor: Colors.white,
                    onPressed: () {
                      ref.invalidate(storesListProvider);
                    },
                  ),
                ),
              );
            }
          });
        }

        debugPrint('🎯 === FIN _buildStoreMarkers (ERROR) ===\n');
        return [];
      },
    );
  }

  int _findNearestPointIndex(LatLng point) {
    double minDistance = double.infinity;
    int nearestIndex = 0;

    for (int i = 0; i < _polylinePoints.length; i++) {
      final distance = _calculateDistance(point, _polylinePoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
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
          initialStores:
              ref.read(storesListProvider).value ??
              [], // Votre liste de magasins
          currentPosition: _currentPosition, // Position GPS
          moveMap: (latLng) {
            // Déplacer la carte vers la position
            _mapController.move(latLng, 17.0);
          },
          showShopDetails: (store) async {
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
            final distance =
                _currentPosition != null
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
              title: Text(store?.nom_enseigne ?? ''),
              subtitle: Text(store?.adresse ?? ''),
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

    _updateBottomSheetState(BottomSheetState.shopDetails);
  }

  void _updateBottomSheetState(BottomSheetState newState) {
    _safeSetState(() {
      _bottomSheetState = newState;
    });
  }

  Widget _buildPositionMarkerWithArrow(double? bearing) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Cercle extérieur avec effet de pulsation (seulement en navigation)
        if (_isNavigating && _orbitController != null)
          AnimatedBuilder(
            animation: _orbitController!,
            builder: (context, child) {
              return Container(
                width:
                    48 + (8 * math.sin(_orbitController!.value * 2 * math.pi)),
                height:
                    48 + (8 * math.sin(_orbitController!.value * 2 * math.pi)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _isNavigating
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                ),
              );
            },
          ),

        // Cercle de base (toujours visible)
        if (!_isNavigating)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),

        // Point central de position
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isNavigating ? AppColors.primary : Colors.blue.shade700,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: (_isNavigating ? AppColors.primary : Colors.blue)
                    .withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),

        // Flèche de navigation (seulement en navigation)
        if (_isNavigating && bearing != null && _orbitController != null)
          AnimatedBuilder(
            animation: _orbitController!,
            builder: (context, child) {
              return Transform.rotate(
                angle: bearing * (math.pi / 180),
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  LatLng _calculateArrowOrbitPosition(LatLng centerPosition, double bearing) {
    // Rayon orbital en degrés (ajustez selon le niveau de zoom)
    // 0.0001 = ~11 mètres, 0.0002 = ~22 mètres, etc.
    const double orbitRadius = 0.0002; // Environ 20-25 mètres

    // Convertir le bearing en radians pour les calculs trigonométriques
    final bearingRad = bearing * (math.pi / 180);

    // Calculer la nouvelle position (décalage en latitude et longitude)
    final double deltaLat = orbitRadius * math.cos(bearingRad);
    final double deltaLng = orbitRadius * math.sin(bearingRad);

    return LatLng(
      centerPosition.latitude + deltaLat,
      centerPosition.longitude + deltaLng,
    );
  }

  List<Marker> _buildNavigationMarkers() {
    if (_currentPosition == null || !_isNavigating || _orbitController == null)
      return [];

    final currentLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    // Calculer le bearing pour la direction de navigation
    double? navigationBearing = _calculateNavigationBearing(currentLatLng);
    if (navigationBearing == null) return [];

    // Créer la liste des marqueurs
    List<Marker> markers = [];

    // 1. Marqueur central de position (point bleu avec effet de pulsation)
    markers.add(
      Marker(
        point: currentLatLng,
        width: 60, // Augmenté pour laisser de l'espace à l'orbite
        height: 60,
        child: AnimatedBuilder(
          animation: _orbitController!,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Effet de pulsation (cercle extérieur)
                Container(
                  width:
                      48 +
                      (6 * math.sin(_orbitController!.value * 2 * math.pi)),
                  height:
                      48 +
                      (6 * math.sin(_orbitController!.value * 2 * math.pi)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromARGB(
                      255,
                      99,
                      165,
                      241,
                    ).withOpacity(0.2),
                  ),
                ),

                // Cercle de base
                // Container(
                //   width: 48,
                //   height: 48,
                //   decoration: BoxDecoration(
                //     shape: BoxShape.circle,
                //     color: const Color.fromARGB(255, 99, 165, 241).withOpacity(0.2),
                //   ),
                // ),

                // Point central de position
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromARGB(255, 35, 143, 252),
                    // border: Border.all(
                    //   color: Colors.white,
                    //   width: 3,
                    // ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 35, 143, 252),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                // FLÈCHE FIXE pointant vers la destination
                Transform.translate(
                  offset: Offset(
                    // Position fixe de la flèche (25 pixels vers le haut par rapport au centre)
                    25 *
                        math.cos(
                          navigationBearing * math.pi / 180 - math.pi / 2,
                        ), // -π/2 pour pointer vers le haut par défaut
                    25 *
                        math.sin(
                          navigationBearing * math.pi / 180 - math.pi / 2,
                        ),
                  ),
                  child: Transform.rotate(
                    angle:
                        navigationBearing *
                        (math.pi /
                            180), // Orienter la flèche vers la destination
                    child: Container(
                      decoration: BoxDecoration(
                        // Ombre subtile pour la visibilité
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: const Color.fromARGB(255, 35, 143, 252),
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    return markers;
  }

  double? _calculateNavigationBearing(LatLng currentPosition) {
    if (_selectedShop == null || _polylinePoints.isEmpty) return null;

    // Trouver le point le plus proche sur l'itinéraire
    int nearestIndex = _findNearestPointIndex(currentPosition);

    // Déterminer le point cible pour la direction
    LatLng targetPoint;

    // Prendre un point plus loin sur l'itinéraire pour une meilleure direction
    if (nearestIndex + 5 < _polylinePoints.length) {
      targetPoint = _polylinePoints[nearestIndex + 5]; // 5 points plus loin
    } else if (nearestIndex + 2 < _polylinePoints.length) {
      targetPoint = _polylinePoints[nearestIndex + 2];
    } else if (nearestIndex + 1 < _polylinePoints.length) {
      targetPoint = _polylinePoints[nearestIndex + 1];
    } else {
      // Pointer vers la destination finale
      targetPoint = LatLng(_selectedShop!.latitude, _selectedShop!.longitude);
    }

    return Geolocator.bearingBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      targetPoint.latitude,
      targetPoint.longitude,
    );
  }

  Widget _buildConnectivityCheckWidget(BuildContext context) {
    final L10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            L10n?.vereficationconnexion ?? 'Vérification de la connexion...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }
}
