/// LocationScreen - Version Optimisée avec Mixins
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mukhliss/core/providers/theme_provider.dart';
import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/core/utils/map_layer_utils.dart';
import 'package:mukhliss/core/widgets/buttons/buildmaplayerbutton.dart';
import 'package:mukhliss/features/stores/stores.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import '../widgets/location_widgets.dart';
import '../widgets/optimized_map_cluster.dart';
import '../widgets/navigation_bar_widget.dart';
import '../widgets/route_preview_sheet.dart';
import '../providers/mock_stores_provider.dart';
import 'location_state.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});
  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen>
    with
        TickerProviderStateMixin,
        ConnectivityMixin,
        NavigationMixin,
        SearchMixin,
        MapUIMixin,
        BottomSheetMixin,
        ErrorHandlerMixin {
  final MapController _mapController = MapController();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late LocationController _controller;
  AnimationController? _animController;
  Position? _currentPosition;
  CategoryEntity? _selectedCategory;
  MapLayerType _selectedLayer = MapLayerType.plan;
  bool _isLoading = false;
  bool _disposed = false;
  ViewportBounds? _currentViewportBounds;
  bool _isAnimatingToStore = false; // Empêche le reload pendant l'animation

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _controller = LocationController(
      ref,
      context,
      _mapController,
      (p) {
        _safeSetState(() => _currentPosition = p);
        // Afficher le bottom sheet des catégories quand la position est disponible
       
      },
      (l) => _safeSetState(() => _isLoading = l),
      updateRoute,
      (n) => n ? startNavigation() : stopNavigation(),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
  if (mounted) showCategoriesSheet();
});
    checkConnectivity();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _controller.getCurrentLocation();
    });
  }

  /// Met à jour les bounds du viewport et la position utilisateur
  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    // Ignorer les changements pendant l'animation vers un magasin
    if (_isAnimatingToStore) return;

    // Mettre à jour la position utilisateur pour le tri par distance
    if (_currentPosition != null) {
      ref.read(currentUserPositionProvider.notifier).state = UserPosition(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
    }

    // Mettre à jour les bounds du viewport
    final bounds = camera.visibleBounds;
    final newBounds = ViewportBounds(
      minLat: bounds.southWest.latitude,
      maxLat: bounds.northEast.latitude,
      minLng: bounds.southWest.longitude,
      maxLng: bounds.northEast.longitude,
    );

    // Ne recharger que si les bounds ont changé significativement
    if (_currentViewportBounds == null ||
        _boundsChangedSignificantly(_currentViewportBounds!, newBounds)) {
      _currentViewportBounds = newBounds;
      // Invalidate le provider pour recharger les magasins
      ref.invalidate(storesInBoundsProvider(newBounds));
    }
  }

  /// Vérifie si les bounds ont changé de manière significative (>10%)
  bool _boundsChangedSignificantly(ViewportBounds old, ViewportBounds newB) {
    const threshold = 0.1; // 10%
    final latDiff = (old.maxLat - old.minLat).abs();
    final lngDiff = (old.maxLng - old.minLng).abs();

    return (old.minLat - newB.minLat).abs() > latDiff * threshold ||
        (old.maxLat - newB.maxLat).abs() > latDiff * threshold ||
        (old.minLng - newB.minLng).abs() > lngDiff * threshold ||
        (old.maxLng - newB.maxLng).abs() > lngDiff * threshold;
  }

  @override
  void dispose() {
    _disposed = true;
    _animController?.dispose();
    disposeConnectivity();
    disposeNavigation();
    disposeSearch();
    _controller.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_disposed) setState(fn);
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    // Utiliser mock stores pour les tests de charge ou Supabase pour production
    final useMock = ref.watch(mockModeProvider);
    final storesAsync =
        useMock ? ref.watch(mockStoresProvider) : ref.watch(storesProvider);

    final isDark = ref.watch(themeProvider) == AppThemeMode.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.surface;

    if (isCheckingConnectivity) {
      return Scaffold(
        backgroundColor: bgColor,
        body: buildConnectivityCheckWidget(context),
      );
    }
    if (!hasConnection) {
      return Scaffold(
        backgroundColor: bgColor,
        body: buildNoConnectionWidget(context, checkConnectivityWithRetry),
      );
    }

    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(34.0209, -6.8416);

    return Scaffold(
      body: Stack(
        children: [
          // Carte
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              onMapReady: _controller.markMapAsReady,
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              ...MapLayerUtils.getMapLayers(_selectedLayer),
              if (polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      color: getRouteColor(selectedMode),
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(markers: _buildPositionMarkers()),
              // Clustering des magasins
              storesAsync.when(
                data: (stores) {
                  debugPrint(
                      '📍 LocationScreen: ${stores.length} magasins chargés');
                  if (stores.isEmpty) {
                    debugPrint('⚠️ Aucun magasin retourné par le provider!');
                    return const SizedBox.shrink();
                  }
                  return OptimizedStoreClusterLayer(
                    stores: stores,
                    selectedCategory: _selectedCategory,
                    onStoreSelected: (store) => _onSelectStore(store, null),
                    mapController: _mapController,
                  );
                },
                loading: () {
                  debugPrint('⏳ Chargement des magasins...');
                  return const SizedBox.shrink();
                },
                error: (error, stack) {
                  debugPrint('❌ Erreur chargement magasins: $error');
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),

          // Contrôles
          MapControlPanel(
            isNavigating: isNavigating,
            isLocationLoading: _isLoading,
            hasPosition: _currentPosition != null,
            isDarkMode: isDark,
            onStopNavigation: _onStopNavigation,
            onCenterLocation: _centerOnPosition,
            onRefresh: _controller.getCurrentLocation,
            onToggleLayers: toggleMapLayers,
            searchButton: _buildSearchButton(),
          ),

          // Barre de navigation en haut (style Google Maps)
          if (isNavigating && selectedShop != null)
            MapNavigationBar(
              isNavigating: isNavigating,
              destination: selectedShop?.name,
              estimatedTime: routeInfo?['duration'] != null
                  ? _formatDuration(routeInfo!['duration'] as double)
                  : null,
              distanceToNext: routeInfo?['distance'] != null
                  ? _formatDistance(routeInfo!['distance'] as double)
                  : null,
              onClose: _onStopNavigation,
            ),

          // Mini barre de navigation en bas (quand navigation active)
          if (isNavigating && selectedShop != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: ActiveNavigationBar(
                destination: selectedShop!.name,
                eta: routeInfo?['duration'] != null
                    ? _formatDuration(routeInfo!['duration'] as double)
                    : null,
                distance: routeInfo?['distance'] != null
                    ? _formatDistance(routeInfo!['distance'] as double)
                    : null,
                onTap: () {
                  // Afficher les détails de navigation
                  showRouteSheet();
                },
                onClose: _onStopNavigation,
              ),
            ),

          // Barre de recherche avec TextField
          if (showSearchBar)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Champ de recherche
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return TextField(
                          controller: searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: l10n?.rechercherMagasin ??
                                'Rechercher un magasin...',
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: clearSearch,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          onChanged: (query) => _performSearch(query),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Résultats de recherche
                  if (searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final store = searchResults[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.store,
                                  color: Colors.blue.shade600),
                            ),
                            title: Text(
                              store.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return Text(
                                  store.address ??
                                      l10n?.adresseNonDisponible ??
                                      'Adresse non disponible',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12),
                                );
                              },
                            ),
                            onTap: () => _onSearchSelect(store),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

          // Layer selector
          if (showMapLayers)
            Positioned(
              top: 100,
              right: 20,
              child: MapLayerSelectorPanel(
                selectedLayer: _selectedLayer,
                onLayerSelected: (layer) => _safeSetState(() {
                  _selectedLayer = layer;
                  hideMapLayers();
                }),
                onClose: hideMapLayers,
              ),
            ),

          // Zone de swipe up en bas (pour afficher les catégories quand fermé)
          if (bottomSheetState == BottomSheetState.none &&
              _currentPosition != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  debugPrint('📱 Tap sur zone de swipe - ouverture catégories');
                  showCategoriesSheet();
                },
                onVerticalDragStart: (_) {
                  debugPrint('📱 Swipe détecté - ouverture catégories');
                  showCategoriesSheet();
                },
                child: Container(
                  height: 60, // Plus grand pour faciliter le geste
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(
                            l10n?.glisserCategories ??
                                'Glisser pour voir les catégories',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom sheets
          ..._buildBottomSheets(),
        ],
      ),
    );
  }

  // ============ MARKERS ============
  List<Marker> _buildPositionMarkers() {
    if (_currentPosition == null) return [];
    final point = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    if (isNavigating && polylinePoints.isNotEmpty) {
      return [
        Marker(
          point: point,
          width: 60,
          height: 60,
          child: AnimatedBuilder(
            animation: _animController!,
            builder: (_, __) => PulsatingNavigationMarker(
              bearing: calculateNavigationBearing(
                    currentPosition: point,
                    polylinePoints: polylinePoints,
                  ) ??
                  0,
              pulseValue: _animController!.value,
            ),
          ),
        ),
      ];
    }

    return [
      Marker(
        point: point,
        width: 48,
        height: 48,
        child: const StaticPositionMarker(),
      ),
    ];
  }

  // ============ BOTTOM SHEETS ============ _currentPosition != null
  List<Widget> _buildBottomSheets() {
    debugPrint(
      '🟢 Building sheets: state=$bottomSheetState, shop=${selectedShop?.name}',
    );
    return [
      if (bottomSheetState == BottomSheetState.categories 
          )
        _wrapSheet(
          CategoryEntityBottomSheet(
            navigatorKey: _navigatorKey,
            initialCategory: _selectedCategory,
            currentPosition: _currentPosition,
            mapController: _mapController,
            onStoreEntitySelected: _onSelectStore,
            onCategorySelected: (c, _) =>
                _safeSetState(() => _selectedCategory = c),
            onClose: closeAllSheets,
          ),
        ),
      if (bottomSheetState == BottomSheetState.shopDetails &&
          selectedShop != null)
        _wrapSheet(
          ShopDetailsBottomSheet(
            navigatorKey: _navigatorKey,
            shop: selectedShop!,
            currentPosition: _currentPosition,
            ref: ref,
            vsync: this,
            isRouting: isNavigating,
            onStoreSelected: _onSelectStore,
            selectedCategory: _selectedCategory,
            initiateRouting: _onInitiateRouting,
            closeCategoriesSheet: _onCloseShopDetails, // Retour à la liste
            onRefresh: () {},
          ),
        ),
      if (bottomSheetState == BottomSheetState.route && selectedShop != null)
        _wrapSheet(
          RoutePreviewSheet(
            destination: selectedShop!,
            routeInfo: routeInfo,
            selectedMode: selectedMode,
            onModeChanged: (mode) {
              setTransportMode(mode);
              _onInitiateRouting(selectedShop!);
            },
            onStartNavigation: () {
              startNavigation();
              // Fermer le sheet de prévisualisation et passer en mode navigation
              closeAllSheets();
            },
            onClose: () {
              updateRoute([]);
              closeAllSheets();
            },
          ),
        ),
    ];
  }

  // Wrapper - Positioned.fill pour donner les bonnes contraintes
  Widget _wrapSheet(Widget child) => Positioned.fill(
        child: child,
      );

  Widget _buildSearchButton() => GestureDetector(
        onTap: toggleSearchBar,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(
            showSearchBar ? Icons.close : Icons.search,
            color: Colors.blue.shade700,
          ),
        ),
      );

  // ============ FORMATAGE ============
  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}min';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  // ============ CALLBACKS ============
  void _centerOnPosition() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16,
      );
    }
  }

  void _onSelectStore(StoreEntity? store, CategoryEntity? category) {
    debugPrint('🔵 _onSelectStore: store=${store?.name}');
    if (store != null) {
      selectShop(store);
      _safeSetState(() => _selectedCategory = category);

      // Déplacer la carte vers le magasin avec animation
      _animateToStore(store);

      showShopDetailsSheet();
      debugPrint(
        '🔵 After: selectedShop=${selectedShop?.name}, state=$bottomSheetState',
      );
    }
  }

  /// Anime la carte vers un magasin
  void _animateToStore(StoreEntity store) {
    // Bloquer le reload pendant l'animation
    _isAnimatingToStore = true;

    final targetLatLng = LatLng(store.latitude, store.longitude);
    final currentZoom = _mapController.camera.zoom;

    // Zoom minimum de 16 pour bien voir le magasin
    final targetZoom = currentZoom < 16 ? 16.0 : currentZoom;

    // Animation fluide vers le magasin
    _mapController.move(targetLatLng, targetZoom);

    debugPrint(
        '🗺️ Carte déplacée vers: ${store.name} (${store.latitude}, ${store.longitude})');

    // Débloquer après un court délai pour laisser l'animation se terminer
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _isAnimatingToStore = false;
      }
    });
  }

  void _onInitiateRouting(StoreEntity shop) {
    initiateRouting(shop, _currentPosition, (points, info) {
      updateRoute(points);
      setRouteInfo(info);
      fitMapToRoute(points, _mapController);
      showRouteSheet();
    }, (error) => showErrorSnackbar(error, Colors.red));
  }

  void _onStopNavigation() {
    stopNavigation();
    closeAllSheets();
  }

  void _onCloseShopDetails() {
    // Retour à la liste des magasins au lieu de tout fermer
    selectShop(null);
    showCategoriesSheet();
  }

  void _onSearchSelect(StoreEntity store) {
    clearSearch();
    _mapController.move(LatLng(store.latitude, store.longitude), 17);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _onSelectStore(store, null);
    });
  }

  /// Effectue la recherche de magasins avec debounce
  void _performSearch(String query) {
    // Annuler la recherche précédente
    searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      updateSearchResults([]);
      return;
    }

    // Debounce de 300ms pour éviter trop de requêtes
    searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final repository = ref.read(storesRepositoryProvider);
        final results = await repository.searchStores(query);
        if (mounted) {
          updateSearchResults(results);
        }
      } catch (e) {
        debugPrint('❌ Erreur recherche: $e');
      }
    });
  }
}
