

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:mukhliss/models/clientmagazin.dart';
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/providers/clientmagazin_provider.dart';
import 'package:mukhliss/providers/langue_provider.dart';
import 'package:mukhliss/providers/store_provider.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/screen/layout/main_navigation_screen.dart';
import 'package:mukhliss/services/osrm_service.dart';
import 'package:mukhliss/providers/geolocator_provider.dart';
import 'package:mukhliss/providers/osrm_provider.dart';
import 'package:mukhliss/utils/category_helpers.dart';
import 'package:mukhliss/utils/geticategoriesbyicon.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mukhliss/providers/categories_provider.dart'; // Ajout du provider des catégories
import 'package:mukhliss/models/categories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Énumération pour les types de couches de carte
enum MapLayerType {
  plan,
  satellite,
  terrain,
  trafic
}

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> with TickerProviderStateMixin {
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
  int _visibleStoresCount = 3; // Nombre initial de magasins à afficher
  final int _storesPerPage = 3; // Nombre de magasins supplémentaires à charger
  bool _isLoadingMore = false; 
  int _visibleSearchResults = 10; // Nombre initial d'éléments à afficher
final int _searchResultsPerPage = 10; // Nombre d'éléments à charger à chaque fois
bool _isLoadingMoreSearch = false;
  // Énumérations et variables pour les couches de carte
  MapLayerType _selectedMapLayer = MapLayerType.plan;
  bool _showMapLayers = false;
  bool _categoriesBottomSheetShown = false; 
  // Données statiques des magasins - Région de San Francisco Bay Area
   

 @override
void initState() {
  super.initState();
  _getCurrentLocation();
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

  Future<void> _getCurrentLocation() async {
     if (!mounted) return; // Ajoutez cette ligne
    setState(() => _isLocationLoading = true);
    
    try {
      final geolocationService = ref.read(geolocationServiceProvider);
      final position = await geolocationService.determinePosition();
      
      setState(() {
        _currentPosition = position;
        _isLocationLoading = false;
      });

if (_currentPosition != null) {
  _mapController.move(
    LatLng(_currentPosition!.latitude.toDouble(), _currentPosition!.longitude.toDouble()),
    15.0,
  );
}
    } catch (e) {
      setState(() => _isLocationLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'obtenir votre position: ${e.toString()}'),
          action: SnackBarAction(
            label: 'Réessayer',
            onPressed: _getCurrentLocation,
          ),
        ),
      );
    }
  }

void _searchStores(String query) {
  final stores = ref.read(storesListProvider).value ?? [];
  
  setState(() {
    if (query.isEmpty) {
      _searchResults = stores; // Affiche tous les magasins si la recherche est vide
    } else {
      _searchResults = stores.where((store) =>
          store.nom_enseigne.toLowerCase().contains(query.toLowerCase()) ||
          store.adresse.toLowerCase().contains(query.toLowerCase()) ||
          (store.description.toLowerCase().contains(query.toLowerCase()) ?? false)
      ).toList();
    }
  });
}
  
  Future<void> _centerOnCurrentLocation() async {
    if (_currentPosition != null) {
   
     if (_currentPosition != null) {
  _mapController.move(
    LatLng(_currentPosition!.latitude.toDouble(), _currentPosition!.longitude.toDouble()),
    15.0,
  );
}
    } else {
      _getCurrentLocation();
    }
  }


void _showCategoriesBottomSheetAuto(List<Categories> categories) {
  if (_categoriesBottomSheetShown || !mounted) return;
  
  setState(() => _categoriesBottomSheetShown = true);
}


  void _initiateRouting(Store shop) {
    setState(() {
      _selectedShop = shop;
      _showTransportModes = true;
      _selectedMode = TransportMode.walking;
    });
    _calculateRoute(shop);
  }

  Future<void> _calculateRoute(Store shop) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Position actuelle non disponible')),
      );
      return;
    }

    setState(() {
      _isRouting = true;
    });

    try {
      final routingService = ref.read(routingServiceProvider);
    final start = LatLng(_currentPosition!.latitude.toDouble(), _currentPosition!.longitude.toDouble());
    final end = LatLng(shop.latitude.toDouble(), shop.longitude.toDouble()); // Utilisez les nouveaux getters

    final routeCoordinates = await routingService.getRouteCoordinates(start, end, _selectedMode);
    final routeInfo = await routingService.getRouteInfo(start, end, _selectedMode);
      setState(() {
        _polylinePoints = routeCoordinates;
        _routeInfo = routeInfo;
        _isRouting = false;
      });

      if (routeCoordinates.isNotEmpty) {
        _fitMapToRoute(routeCoordinates);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Itinéraire calculé vers ${shop.nom_enseigne} (${_getModeName(_selectedMode)})'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRouting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du calcul de l\'itinéraire: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getModeName(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving:
        return 'Voiture';
      case TransportMode.walking:
        return 'Marche';
      case TransportMode.cycling:
        return 'Vélo';
    }
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

  void _clearRoute() {
    setState(() {
      _polylinePoints = [];
      _selectedShop = null;
      _routeInfo = null;
      _showTransportModes = false;
    });
  }

  void _toggleMapLayers() {
    setState(() {
      _showMapLayers = !_showMapLayers;
    });
  }

  Widget _buildMapLayerButton(MapLayerType layer, IconData icon, String label) {
    final isSelected = _selectedMapLayer == layer;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMapLayer = layer;
          _showMapLayers = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, 
                size: 20, 
                color: isSelected ? Colors.white : Colors.blue.shade700),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.blue.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _getMapLayers() {
    switch (_selectedMapLayer) {
      case MapLayerType.plan:
        return [
          TileLayer(
           urlTemplate: 'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
        maxZoom: 20,
        subdomains:['mt0','mt1','mt2','mt3']
          ),
        ];
      case MapLayerType.satellite:
        return [
          TileLayer(
            urlTemplate: 'http://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
            userAgentPackageName: 'com.example.app',
            subdomains: ['mt0','mt1','mt2','mt3']
          ),
        ];
      case MapLayerType.terrain:
        return [
          TileLayer(
            urlTemplate: 'http://{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}',
            userAgentPackageName: 'com.example.app',
            subdomains: ['mt0','mt1','mt2','mt3']
          ),
        ];
      case MapLayerType.trafic:
        return [
          TileLayer(
            urlTemplate: 'http://{s}.google.com/vt/lyrs=s,h&x={x}&y={y}&z={z}',
            subdomains: ['mt0','mt1','mt2','mt3']
          ),
        ];
    }
  }

Widget _buildTransportModeButton(TransportMode mode, IconData icon, String label) {
  bool isSelected = _selectedMode == mode;
  
  return GestureDetector(
        onTap: () {
        setState(() {
          _selectedMode = mode;
        });
        if (_selectedShop != null) {
          _calculateRoute(_selectedShop!);
        }
      },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade700 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue.shade700 : Colors.blue.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: Colors.blue.shade700.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.blue.shade700,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.blue.shade700,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}



Widget _buildCategoriesBottomSheet(List<Categories> categories) {
  final l10n = AppLocalizations.of(context);
   final themeMode = ref.watch(themeProvider);
  final currentLocale = ref.watch(languageProvider); 
      final isDarkMode = themeMode == AppThemeMode.light;
  return WillPopScope(
    child: DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      snap: true,
      builder: (context, scrollController) {
        return Material(
          color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
        ),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            // Handle du BottomSheet
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            
            // Titre
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      l10n?.categories ?? 'Catégories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color:isDarkMode?AppColors.surface : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
         // Liste HORIZONTALE des catégories - MULTILINGUE
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final categoriesAsync = ref.watch(categoriesListProvider);
                  
                  return categoriesAsync.when(
                    data: (categories) {
                      return  SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                            children: [
                              // Bouton "Tous"
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _buildHorizontalCategoryItem(
                                  icon: Icons.all_inclusive,
                                  title: l10n?.tous ?? 'Tous',
                                  iconcolor: const Color.fromARGB(255, 145, 126, 126),
                                  isSelected: _selectedCategory == null,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = null;
                                    });
                                    setState(() => _categoriesBottomSheetShown = false);
                                  },
                                ),
                              ),
                              
                              // Autres catégories - AVEC TRADUCTION
                              ...categories.map((category) {
                                final isSelected = _selectedCategory?.id == category.id;
                                // UTILISATION DE LA MÉTHODE MULTILINGUE
                                final localizedName = category.getName(currentLocale.languageCode);
                                print('Localized name for  $localizedName');
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildHorizontalCategoryItem(
                                    icon: CategoryMarkers.getPinIcon(category.name), // Utilise le nom par défaut pour l'icône
                                    title: localizedName, // AFFICHE LE NOM TRADUIT
                                    isSelected: isSelected,
                                    
                                    iconcolor: CategoryMarkers.getPinColor(category.name), // Utilise le nom par défaut pour la couleur
                                    onTap: () {
                                      setState(() {
                                        if (_selectedCategory?.id == category.id) {
                                          _selectedCategory = null;
                                        } else {
                                          _selectedCategory = category;
                                        }
                                      });
                                      setState(() => _categoriesBottomSheetShown = false);
                                    },
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      
                    },
                    loading: () => SliverToBoxAdapter(
                      child: SizedBox(
                        height: 120,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (error, stack) => SliverToBoxAdapter(
                      child: SizedBox(
                        height: 120,
                        child: Center(
                          child: Text(
                            'Erreur: $error',
                            style: TextStyle(
                              color: isDarkMode ? AppColors.surface : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
              
            
            // Titre "Magasins les plus proches"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n?.tousmagasins ?? 'Magasins les plus proches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color:isDarkMode ? AppColors.surface: AppColors.darkSurface ,
                    ),
                  ),
                ),
              ),
            ),
            
            // Liste des magasins
            Consumer(
              builder: (context, ref, child) {
                if (_searchResults.isNotEmpty) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {

                        final store = _searchResults[index];
                        final distance = _currentPosition != null 
                          ? Geolocator.distanceBetween(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                              store.latitude,
                              store.longitude,
                            )
                          : 0.0;
                        
                        return _buildStoreItem(store, distance, index);
                      },
                      childCount: _searchResults.length,
                    ),
                  );
                }

                final storesAsync = ref.watch(storesListProvider);
                return storesAsync.when(
                  data: (stores) {
                    List<Store> filteredStores = stores;
                    if (_selectedCategory != null) {
                      filteredStores = stores.where((store) => 
                        store.Categorieid == _selectedCategory!.id
                      ).toList();
                    }
                    
                    filteredStores.sort((a, b) {
                      if (_currentPosition == null) return 0;
                      final distanceA = Geolocator.distanceBetween(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        a.latitude,
                        a.longitude,
                      );
                      final distanceB = Geolocator.distanceBetween(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        b.latitude,
                        b.longitude,
                      );
                      return distanceA.compareTo(distanceB);
                    });
                    
                    return SliverList(
  delegate: SliverChildBuilderDelegate(
    (context, index) {
      print('Building item $index / $_visibleStoresCount');
      // Si on atteint la fin de la liste visible +1 pour l'indicateur
      if (index == _visibleStoresCount) {
         print('Triggering load more...');
        if (_visibleStoresCount < filteredStores.length) {
          // Déclencher le chargement des éléments suivants
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isLoadingMore) {
                print('Loading more items...');
              setState(() {
                _isLoadingMore = true;
                _visibleStoresCount = (_visibleStoresCount + _storesPerPage)
                    .clamp(0, filteredStores.length);
                _isLoadingMore = false;
              });
            }
          });
        }
        
        // Afficher l'indicateur de chargement si plus d'éléments
        return _visibleStoresCount < filteredStores.length
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            : const SizedBox.shrink();
      }

      // Si index dépasse le nombre d'éléments
      if (index >= filteredStores.length || index >= _visibleStoresCount) {
        return const SizedBox.shrink();
      }

      final store = filteredStores[index];
      final distance = _currentPosition != null
          ? Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              store.latitude,
              store.longitude,
            )
          : 0.0;

      return _buildStoreItem(store, distance, index);
    },
    childCount: filteredStores.length + 1, // +1 pour l'indicateur
  ),
);
                  },
                  loading: () => SliverToBoxAdapter(
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => SliverToBoxAdapter(
                    child: Center(child: Text('Erreur: $error')),
                  ),
                );
              }
            ),
            
            // Espacement en bas
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ),
          ],
        ),
      );
    },
  ), onWillPop: () async {
    setState(() => _categoriesBottomSheetShown = false);
    return true;
  }) ;
}

Widget _buildHorizontalCategoryItem({
  IconData? icon,
  required String title,
  required bool isSelected,
  required VoidCallback onTap,
  required Color iconcolor,
}) {
  return SizedBox(
    width: 80, // Largeur fixe pour chaque item
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cercle contenant l'icône
        Container(
          height: 56, // Taille du cercle
          width: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle, // Forme circulaire
            border: Border.all(
              color: isSelected ? Colors.blue.shade700 :iconcolor,
              width: 1.5,
            ),
            color: isSelected ? Colors.blue.shade50 : Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28), // Moitié de la hauteur pour un cercle parfait
              onTap: onTap,
              child: Center(
                child: icon != null
                    ? Icon(
                        icon,
                        size: 30,
                        color: isSelected ? Colors.blue.shade700 :iconcolor,
                      )
                   
                        : const SizedBox(),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8), // Espace entre le cercle et le texte
        
        // Nom de la catégorie
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
            height: 1.2,
          ),
        ),
        
        // Indicateur de sélection (coche)
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.blue.shade700,
            ),
          ),
      ],
    ),
  );
}

Widget _buildStoreItem(Store store, double distance, int index) {
  final themeMode = ref.watch(themeProvider);
      final isDarkMode = themeMode == AppThemeMode.light;
  return Container(
    margin: const EdgeInsets.only(bottom: 1),
    decoration: BoxDecoration(
      color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
      border: Border(
        bottom: BorderSide(
          color: Colors.grey.shade200,
          width: 0.5,
        ),
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _navigateToStoreAndShowDetails(store);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Icône de navigation
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400,
                      Colors.blue.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informations du magasin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.nom_enseigne,
                            style:  TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? AppColors.surface :  AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                         color: isDarkMode ? AppColors.surface :  AppColors.textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            store.adresse,
                            style: TextStyle(
                              fontSize: 14,
                             color: isDarkMode ? AppColors.surface :  AppColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Badge de distance
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            distance < 1000
                              ? '${distance.toStringAsFixed(0)}m'
                              : '${(distance / 1000).toStringAsFixed(1)}km',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Flèche d'indication
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _navigateToStoreAndShowDetails(Store store) async {
  if (_categoriesBottomSheetShown) {
    setState(() => _categoriesBottomSheetShown = false);

    // Attendre la prochaine frame pour être sûr qu’il soit retiré
    await Future<void>.delayed(Duration.zero);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showShopDetails(store);
    });
  } else {
    _mapController.move(
      LatLng(store.latitude.toDouble(), store.longitude.toDouble()),
      17.0,
    );
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      _showShopDetails(store);
    }
  }
}

   @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesListProvider);
     final categoriesAsync = ref.watch(categoriesListProvider);
     final l10n = AppLocalizations.of(context);
     final themeMode = ref.watch(themeProvider);
      final isDarkMode = themeMode == AppThemeMode.light;
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
                    initialZoom: _currentPosition != null ? 15.0 : 13.0,
                  ),
                  children: [
                    // Map layers
                    ..._getMapLayers(),
                    
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
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
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
                            width: 24,
                            height: 24,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.withOpacity(0.2),
                                  ),
                                ),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.shade700,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),),
              // Map
               
              
          // Main content with AppBar and Map
           // AppBar
              // Container(
              //   height: 100,
              //   child: AppBarTypes.localisationAppBar(context),
              // ),

      
        
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
      // Bouton de recherche
      _showSearchBar 
          ? _buildSearchBar(context)
          : _buildSearchButton(context),
      const SizedBox(height: 12),
      
      // Boutons de contrôle
      _buildControlButton(
        icon: Icons.my_location,
        onPressed: _currentPosition != null ? _centerOnCurrentLocation : null,
        backgroundColor:isDarkMode ? AppColors.darkSurface : AppColors.accent ,
      ),
      const SizedBox(height: 12),
      _buildControlButton(
        icon: Icons.refresh,
        onPressed: _isLocationLoading ? null : _getCurrentLocation,
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.accent,
        isLoading: _isLocationLoading,
      ),
      const SizedBox(height: 12),
      _buildControlButton(
        icon: Icons.layers,
        onPressed: _toggleMapLayers,
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.accent,
      ),
    ],
  ),
),

          // Categories BottomSheet
        if (_categoriesBottomSheetShown && !_showTransportModes)
      _buildCategoriesBottomSheet(categoriesAsync.value ?? []),
    if (_showTransportModes)
      _buildBottomSheet(),

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
                    _buildMapLayerButton(MapLayerType.plan, Icons.map, 'Plan'),
                    _buildMapLayerButton(MapLayerType.satellite, Icons.satellite_alt, 'Satellite'),
                    _buildMapLayerButton(MapLayerType.terrain, Icons.terrain, 'Terrain'),
                    _buildMapLayerButton(MapLayerType.trafic, Icons.traffic, 'Trafic'),
                  ],
                ),
              ),
            ),
        ],
      ),
    
      // bottomSheet: _buildBottomSheet(),
    );
  }

  Color _getRouteColor(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving:
        return Colors.blue.shade600.withOpacity(0.8);
      case TransportMode.walking:
        return Colors.green.shade600.withOpacity(0.8);
      case TransportMode.cycling:
        return Colors.orange.shade600.withOpacity(0.8);
    }
  }

 Widget _buildBottomSheet() {
   final l10n = AppLocalizations.of(context);
   final themeMode = ref.watch(themeProvider);
      final isDarkMode = themeMode == AppThemeMode.light;
  if (_currentPosition == null) return SizedBox.shrink();

  // Vérifier s'il y a du contenu à afficher
  bool hasTransportModes = _showTransportModes;
  bool hasRouteInfo = _routeInfo != null && _selectedShop != null;
  
  // Si aucun contenu à afficher, ne pas montrer le bottom sheet
  if (!hasTransportModes && !hasRouteInfo) {
    return SizedBox.shrink();
  }

  return
   // Hauteur du bottom sheet
     SizedBox(
      height: MediaQuery.of(context).size.height * 1, // 60% de la hauteur de l'écran
       child: DraggableScrollableSheet(
        expand: false,
       initialChildSize: 0.5,
           minChildSize: 0.3,
           maxChildSize: 0.9,    // Taille maximale (60% de l'écran)
        snap: true,             // Snap aux positions définies
        snapSizes: const [0.3, 0.5, 0.7, 0.9], // Positions de snap
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                // Handle bar fixe en haut
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Handle bar pour indiquer qu'on peut faire glisser
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // Indicateur de statut (optionnel)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.grey.shade500,
                              size: 16,
                            ),
                            Text(

                            l10n?.glissez ??  'Glissez pour voir plus',
                              style: TextStyle(
                                color:isDarkMode ? AppColors.surface : AppColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.grey.shade500,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenu scrollable
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Section modes de transport
                      if (_showTransportModes) ...[
                        _buildTransportSection(),
                        if (hasRouteInfo) const SizedBox(height: 16),
                      ],
           
                      // Section informations de route
                      if (_routeInfo != null && _selectedShop != null) ...[
                        _buildRouteInfoSection(),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                      ],
                      
                      // Espace en bas pour éviter que le contenu soit coupé
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
           ),
     );
  
}

Widget _buildTransportSection() {
   final l10n = AppLocalizations.of(context);
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue.shade100),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.alt_route,
              color: Colors.blue.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
            l10n?.mode ??  'Mode de transport',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTransportModeButton(
                TransportMode.driving, 
                Icons.directions_car, 
               l10n?.voiture ?? 'Voiture'
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTransportModeButton(
                TransportMode.walking, 
                Icons.directions_walk, 
                'Marche'
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTransportModeButton(
                TransportMode.cycling, 
                Icons.directions_bike, 
               l10n?.velo ?? 'Vélo'
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildRouteInfoSection() {
  final l10n = AppLocalizations.of(context);
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.green.shade100),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec icône et destination
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getModeIcon(_selectedMode),
                color: Colors.green.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.vers ?? 'Itinéraire vers',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _selectedShop!.nom_enseigne,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Informations de distance et durée
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.straighten,
                l10n?.distance ??  'Distance',
                  OSRMRoutingService().formatDistance(_routeInfo!['distance'].toDouble()),
                  Colors.green.shade700,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.green.shade200,
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.access_time,
                 l10n?.duree ?? 'Durée',
                  OSRMRoutingService().formatDuration(_routeInfo!['duration'].toDouble()),
                  Colors.green.shade700,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.green.shade200,
              ),
              Expanded(
                child: _buildInfoItem(
                  _getModeIcon(_selectedMode),
                  l10n?.mode ?? 'Mode',
                  _getModeName(_selectedMode),
                  Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
  return Column(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          color: color.withOpacity(0.7),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

Widget _buildActionButtons() {
  final l10n = AppLocalizations.of(context);
  return Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            _centerOnCurrentLocation();
          },
          icon: const Icon(Icons.my_location, size: 18),
          label: Text(l10n?.recenter ?? 'Recentrer'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue.shade700,
            side: BorderSide(color: Colors.blue.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            _clearRoute();
            _centerOnCurrentLocation();
          },
          icon: const Icon(Icons.close, size: 18),
          label: Text(l10n?.cancel ?? 'Annuler'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red.shade700,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(color: Colors.red.shade200),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    ],
  );
}

  IconData _getModeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.driving:
        return Icons.directions_car;
      case TransportMode.walking:
        return Icons.directions_walk;
      case TransportMode.cycling:
        return Icons.directions_bike;
    }
  }



  double _calculateDistance(Store shop) {
    if (_currentPosition == null) return 0;
    
    return Geolocator.distanceBetween(
    _currentPosition!.latitude,
    _currentPosition!.longitude,
    shop.latitude,    // Utilisez les nouveaux getters
    shop.longitude,   // Utilisez les nouveaux getters
  );
  }


Future<void> _showShopDetails(Store shop) async {
  final l10n = AppLocalizations.of(context);
  final themeMode = ref.watch(themeProvider);
  final isDarkMode = themeMode == AppThemeMode.light; // Correction du dark mode
  final currentLocale = ref.watch(languageProvider);

  // Animation controller
  final animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  final curvedAnimation = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeOutQuint,
  );

  final distance = _calculateDistance(shop);
  final category = CategoryHelpers.getCategory(ref, shop.Categorieid);
  final localizedName = category.getName(currentLocale.languageCode);

  // Vérification connexion
  final currentUser = Supabase.instance.client.auth.currentUser;
  final clientId = currentUser?.id ?? ref.read(currentClientIdProvider);

  if (clientId == null && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.connectionRequired ?? 'Connectez-vous pour voir vos points'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return;
  }

  ClientMagazin? clientMagazin;
  try {
    if (clientId != null) {
      clientMagazin = await ref.read(clientMagazinServiceProvider)
          .getClientMagazinPoints(clientId, shop.id);
    }
  } catch (e) {
    debugPrint('Erreur récupération points: $e');
  }

  if (!mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      animationController.forward();
      
      return Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar stylisé
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec animation
                    ScaleTransition(
                      scale: Tween(begin: 0.9, end: 1.0).animate(curvedAnimation),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  CategoryMarkers.getPinColor(localizedName).withOpacity(0.2),
                                  CategoryMarkers.getPinColor(localizedName).withOpacity(0.4),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CategoryMarkers.getPinIcon(localizedName),
                              size: 28,
                              color: CategoryMarkers.getPinColor(localizedName),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop.nom_enseigne,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                      ? Colors.grey.shade800 
                                      : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    localizedName,
                                    style: TextStyle(
                                      color: CategoryMarkers.getPinColor(localizedName),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Carte d'informations avec animation
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(curvedAnimation),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                            ? Colors.grey.shade900.withOpacity(0.5)
                            : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDarkMode 
                              ? Colors.grey.shade800 
                              : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Distance
                            _buildInfoTile(
                              icon: Icons.straighten,
                              title: l10n?.distance ?? 'Distance',
                              value: distance < 1000
                                  ? '${distance.toStringAsFixed(0)} m'
                                  : '${(distance / 1000).toStringAsFixed(1)} km',
                              color: Colors.blue,
                              isDarkMode: isDarkMode,
                            ),

                            // Points de fidélité
                            if (clientMagazin != null && clientMagazin.cumulpoint > 0)
                              _buildInfoTile(
                                icon: Icons.loyalty,
                                title: l10n?.calcule ?? 'Points fidélité',
                                value: '${clientMagazin.cumulpoint} pts',
                                color: Colors.amber,
                                isDarkMode: isDarkMode,
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Boutons avec animation
                    FadeTransition(
                      opacity: curvedAnimation,
                      child: Row(
                        children: [
                          // Bouton Fermer
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                  color: isDarkMode 
                                    ? Colors.grey.shade700 
                                    : Colors.grey.shade400,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                l10n?.fermer ?? 'Fermer',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Bouton Itinéraire
                          if (_currentPosition != null)
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  gradient: _isRouting
                                      ? null
                                      : LinearGradient(
                                          colors: [
                                            Colors.blue.shade500,
                                            Colors.blue.shade700,
                                          ],
                                        ),
                                  color: _isRouting 
                                    ? Colors.grey.shade500 
                                    : null,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: _isRouting
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: Colors.blue.shade400.withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  onPressed: _isRouting
                                      ? null
                                      : () {
                                          Navigator.pop(context);
                                          _initiateRouting(shop);
                                        },
                                  child: _isRouting
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.directions, size: 22),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n?.iterinaire ?? 'Itinéraire',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(() => animationController.dispose());
}

Widget _buildInfoTile({
  required IconData icon,
  required String title,
  required String value,
  required Color color,
  required bool isDarkMode,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


 Widget _buildControlButton({
  required IconData icon,
  required VoidCallback? onPressed,
  required Color backgroundColor,
  bool isLoading = false,
}) {
  return Material(
    shape: const CircleBorder(),
    elevation: 2,
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: IconButton(
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    ),
  );
}
Widget _buildSearchButton(BuildContext context) {
   final themeMode = ref.watch(themeProvider);
      final isDarkMode = themeMode == AppThemeMode.light;
  return Material(
   shape: const CircleBorder(),
    elevation: 2,
    child: Material(
      shape: const CircleBorder(),
      elevation: 2,
      child: Container(
        decoration:  BoxDecoration(
          shape: BoxShape.circle,
          color:isDarkMode ? AppColors.darkSurface : AppColors.accent,
        ),
        child: IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            _showSearchBottomSheet();
          },
        ),
      ),
    ),
  );
}
void _showSearchBottomSheet() async {
   final themeMode = ref.watch(themeProvider);
      final isDarkMode = themeMode == AppThemeMode.light;
      final l10n = AppLocalizations.of(context);
  // Fermer le bottom sheet des catégories s'il est ouvert
  if (_categoriesBottomSheetShown) {
    setState(() => _categoriesBottomSheetShown = false);
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }

  // Initialise avec tous les magasins
  final initialStores = ref.read(storesListProvider).value ?? [];
   setState(() {
    _searchResults = initialStores;
    _visibleSearchResults = _searchResultsPerPage; // Réinitialiser à chaque ouverture
  });

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
     backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
    builder: (context) {
      return StatefulBuilder(
        
        builder: (context, setSheetState) {
          return Padding(
           
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText:l10n?.chercher ?? 'Rechercher un magasin...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? AppColors.surface :AppColors.primary,
                      ),
                      prefixIcon:  Icon(Icons.search , color: isDarkMode ? AppColors.surface : AppColors.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        color: isDarkMode ? AppColors.surface : AppColors.primary,
                        onPressed: () {
                          Navigator.pop(context);
                          _searchController.clear();
                          setState(() {
                            _searchResults = initialStores;
                            _visibleSearchResults = _searchResultsPerPage;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onChanged: (value) {
                      _searchStores(value);
                      setState(() => _visibleSearchResults = _searchResultsPerPage);
                      setSheetState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification && 
                          notification.metrics.pixels == notification.metrics.maxScrollExtent &&
                          !_isLoadingMoreSearch &&
                          _visibleSearchResults < _searchResults.length) {
                        setSheetState(() {
                          _isLoadingMoreSearch = true;
                          _visibleSearchResults = (_visibleSearchResults + _searchResultsPerPage)
                              .clamp(0, _searchResults.length);
                          _isLoadingMoreSearch = false;
                        });
                      }
                      return false;
                    },
                    child: ListView.builder(
                      itemCount: _visibleSearchResults < _searchResults.length 
                          ? _visibleSearchResults + 1 
                          : _visibleSearchResults,
                      itemBuilder: (context, index) {
                        if (index >= _visibleSearchResults) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (index >= _searchResults.length) {
                          return const SizedBox.shrink();
                        }

                        final store = _searchResults[index];
                        final distance = _currentPosition != null
                            ? Geolocator.distanceBetween(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                                store.latitude,
                                store.longitude,
                              )
                            : 0.0;

                        return _buildSearchResultItem(store, distance);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildSearchResultItem(Store store, double distance) {
  final themeMode = ref.watch(themeProvider);
      final isDarkMode = themeMode == AppThemeMode.light;
  return ListTile(
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: CategoryMarkers.getPinColor(
          CategoryHelpers.getCategoryName(ref, store.Categorieid),
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          CategoryMarkers.getPinIcon(
            CategoryHelpers.getCategoryName(ref, store.Categorieid),
          ),
          color: Colors.white,
          size: 20,
        ),
      ),
    ),
    title: Text(
      store.nom_enseigne,
      style:  TextStyle(fontWeight: FontWeight.bold , color: isDarkMode ? AppColors.surface : AppColors.darkSurface),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(store.adresse , style: TextStyle(color: isDarkMode ? AppColors.surface : AppColors.darkSurface),),

        const SizedBox(height: 4),
        Text(
          '${distance < 1000 ? distance.toStringAsFixed(0) : (distance / 1000).toStringAsFixed(1)} ${distance < 1000 ? 'm' : 'km'}',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
    onTap: () {
      Navigator.pop(context); // Ferme le bottom sheet
      _mapController.move(
        LatLng(store.latitude.toDouble(), store.longitude.toDouble()),
        15.0,
      );
      _showShopDetails(store);
    },
  );

}


Widget _buildSearchBar(BuildContext context) {
  return Container(
    width: MediaQuery.of(context).size.width - 32,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Rechercher...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _showSearchBar = false;
              _searchController.clear();
              _searchResults = [];
            });
          },
        ),
        border: InputBorder.none,
      ),
      onChanged: _searchStores,
    ),
  );
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
            onTap: () {
              setState(() {
                _showSearchBar = false;
                _searchController.clear();
                _searchResults = [];
              });
              _mapController.move(
                LatLng(store.latitude.toDouble(), store.longitude.toDouble()),
                15.0,
              );
              _showShopDetails(store);
            },
          );
        },
      ),
    ),
  );
}
 
}