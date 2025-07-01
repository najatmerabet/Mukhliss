// search_widget.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/screen/layout/main_navigation_screen.dart';
import 'package:mukhliss/utils/category_helpers.dart';
import 'package:mukhliss/utils/geticategoriesbyicon.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class SearchWidget extends ConsumerStatefulWidget {
  final List<Store> initialStores;
  final Position? currentPosition;
  final Function(LatLng) moveMap;
  final Function(Store) showShopDetails;
  final int searchResultsPerPage;
  
  const SearchWidget({
    super.key,
    required this.initialStores,
    required this.currentPosition,
    required this.moveMap,
    required this.showShopDetails,
    this.searchResultsPerPage = 10,
  });

  @override
  ConsumerState<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends ConsumerState<SearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final Duration _searchDebounceDelay = const Duration(milliseconds: 500);
  Timer? _searchDebounceTimer;
  bool _hasMore = true; // Ajoutez cette variable
  bool _isInitialLoad = true; // Pour le premier chargement
  List<Store> _searchResults = [];
  int _visibleSearchResults = 0;
  bool _isLoadingMoreSearch = false;

  @override
  void initState() {
    super.initState();
    _searchResults = widget.initialStores;
    _visibleSearchResults = widget.searchResultsPerPage;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

void _searchStores(String query) {
  if (query.isEmpty) {
    setState(() {
      _searchResults = widget.initialStores;
      _visibleSearchResults = widget.searchResultsPerPage;
      _hasMore = _searchResults.length > widget.searchResultsPerPage;
    });
    return;
  }

  _searchDebounceTimer?.cancel();

  _searchDebounceTimer = Timer(_searchDebounceDelay, () {
    if (!mounted) return;
    
    final results = widget.initialStores.where((store) {
      return store.nom_enseigne.toLowerCase().contains(query.toLowerCase()) ||
          store.adresse.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _searchResults = results;
      _visibleSearchResults = math.min(widget.searchResultsPerPage, results.length);
      _hasMore = _searchResults.length > _visibleSearchResults;
    });
  });
}

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.light;
    final l10n = AppLocalizations.of(context);

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
                hintText: l10n?.chercher ?? 'Rechercher un magasin...',
                hintStyle: TextStyle(
                  color: isDarkMode ? AppColors.surface : AppColors.primary,
                ),
                prefixIcon: Icon(Icons.search, color: isDarkMode ? AppColors.surface : AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  color: isDarkMode ? AppColors.surface : AppColors.primary,
                  onPressed: () {
                    Navigator.pop(context);
                    _searchController.clear();
                    _searchStores('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (value) {
                _searchDebounceTimer?.cancel();
                _searchDebounceTimer = Timer(_searchDebounceDelay, () {
                  if (mounted) {
                    _searchStores(value);
                  }
                });
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
                  setState(() {
                    _isLoadingMoreSearch = true;
                    _visibleSearchResults = (_visibleSearchResults + widget.searchResultsPerPage)
                        .clamp(0, _searchResults.length);
                    _isLoadingMoreSearch = false;
                  });
                }
                return false;
              },
              child: ListView.builder(
                 itemCount: math.min(
                     _hasMore ? _visibleSearchResults + 1 : _visibleSearchResults,
                    _searchResults.length,
                  ),
  itemBuilder: (context, index) {
        // If we're at the loading indicator
        if (_hasMore && index >= _visibleSearchResults) {
          return _buildLoader();
        }

        // Safety check
        if (index >= _searchResults.length) {
          return const SizedBox.shrink();
        }

        final store = _searchResults[index];
        final distance = widget.currentPosition != null
            ? Geolocator.distanceBetween(
                widget.currentPosition!.latitude,
                widget.currentPosition!.longitude,
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
  }


Widget _buildLoader() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Center(
      child: _isLoadingMoreSearch 
          ? const CircularProgressIndicator()
          : ElevatedButton(
              onPressed: _loadMoreStores,
              child: const Text('Charger plus'),
            ),
    ),
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? AppColors.surface : AppColors.darkSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.adresse,
            style: TextStyle(color: isDarkMode ? AppColors.surface : AppColors.darkSurface),
          ),
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
      onTap: ()async {
       debugPrint('Store selected from search: ${store.nom_enseigne}');
  
  // Fermer la feuille de recherche
  // if (Navigator.canPop(context)) {
  //   Navigator.pop(context);
  //   await Future.delayed(const Duration(milliseconds: 200));
  // }
  
  // Déclencher la navigation
  widget.showShopDetails(store);
  
  // Optionnel: déplacer la carte
  widget.moveMap(LatLng(store.latitude, store.longitude));
      },
    );
  }

Future<void> _loadMoreStores() async {
  if (_isLoadingMoreSearch || !_hasMore) return;

  setState(() => _isLoadingMoreSearch = true);
  
  await Future.delayed(const Duration(seconds: 1));
  
  if (!mounted) return;
  
  setState(() {
    _visibleSearchResults = math.min(
      _visibleSearchResults + widget.searchResultsPerPage,
      _searchResults.length,
    );
    _isLoadingMoreSearch = false;
    _hasMore = _visibleSearchResults < _searchResults.length;
  });
}

}
