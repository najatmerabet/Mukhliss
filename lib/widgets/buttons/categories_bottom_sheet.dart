import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mukhliss/models/categories.dart';
import 'package:mukhliss/models/offers.dart';
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/providers/categories_provider.dart';
import 'package:mukhliss/providers/clientmagazin_provider.dart';
import 'package:mukhliss/providers/langue_provider.dart';
import 'package:mukhliss/providers/store_provider.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mukhliss/screen/layout/main_navigation_screen.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/utils/geticategoriesbyicon.dart';
import 'package:tuple/tuple.dart';


class CategoriesBottomSheet extends ConsumerStatefulWidget  {

  final Categories? initialCategory;
  final Position? currentPosition;
final List<Store>? searchResults;
final MapController mapController; 
final GlobalKey<NavigatorState> navigatorKey;
final Function(Store?, Categories?)? onStoreSelected;
final Function(Categories?, Store?) onCategorySelected;
final VoidCallback onClose;

 // Nouveau paramètre
CategoriesBottomSheet({
  super.key,
  required this.initialCategory,
  required this.currentPosition,
  required this.mapController, 
  required this.navigatorKey,
  required this.onStoreSelected,
  this.searchResults,
  required this.onCategorySelected,
  required this.onClose,
});

  
 @override
  ConsumerState<CategoriesBottomSheet> createState() => _CategoriesBottomSheetState();



}

class _CategoriesBottomSheetState extends ConsumerState<CategoriesBottomSheet> 
    with TickerProviderStateMixin {
 
  
 final int _storesPerPage = 5; // Nombre de magasins à charger à chaque fois
  int _visibleStoresCount = 5; // Nombre actuel de magasins visibles
  bool _isLoadingMore = false; // Indicateur de chargement
  final ScrollController _scrollController = ScrollController();
  final DraggableScrollableController _draggableController = DraggableScrollableController();
   Categories? _selectedCategory;
   @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreStores);
    _selectedCategory=widget.initialCategory;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
    void _loadMoreStores() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent && 
        !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _visibleStoresCount += _storesPerPage;
        _isLoadingMore = false;
      });
    }
  }
 Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _isLoadingMore 
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      ),
    );
  }
  @override
  Widget build(BuildContext context){
     final l10n = AppLocalizations.of(context);
      final themeMode = ref.watch(themeProvider);
      final currentLocale = ref.watch(languageProvider); 
     
      final isDarkMode = themeMode == AppThemeMode.light;
     return  DraggableScrollableSheet(
      controller: _draggableController,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      snap: true,
       snapSizes: [0.3, 0.5, 0.9],
      builder: (context, scrollController) {
        return Material(
          color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
        ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // SliverToBoxAdapter(
            //   child: Row(
            //     children: [
            //       IconButton(
            //         icon: const Icon(Icons.close),
            //         onPressed:widget. onClose,
            //       ),
            //     ],
            //   ),
            //  ),
            
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
                      l10n?.categories ?? 'Mes Catégories',
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
                            children: [
                              // Bouton "Tous"
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _buildHorizontalCategoryItem(
                                  context: context,
                                  icon: Icons.all_inclusive,
                                  title: l10n?.tous ?? 'Tous',
                                  isDarkMode: isDarkMode,
                                  iconcolor: const Color.fromARGB(255, 145, 126, 126),
                                  isSelected:_selectedCategory?.id==null,
                                  onTap: () {
                                     setState(() {
                                      _selectedCategory = null;
                                      _visibleStoresCount = _storesPerPage; // Réinitialiser le compteur
                                    });
                                    widget.onCategorySelected(null,null);
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
                                    context: context,
                                    icon: CategoryMarkers.getPinIcon(category.name), // Utilise le nom par défaut pour l'icône
                                    title: localizedName, // AFFICHE LE NOM TRADUIT
                                    isSelected: isSelected,
                                    isDarkMode: isDarkMode,
                                    iconcolor: CategoryMarkers.getPinColor(category.name), // Utilise le nom par défaut pour la couleur
                                    onTap: () {
                                      setState(() {
                                      _selectedCategory = category;
                                      _visibleStoresCount = _storesPerPage; // Réinitialiser le compteur
                                    });
                                   widget. onCategorySelected(category,null);
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
                if (widget. searchResults?.isNotEmpty == true) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {

                        final store =widget. searchResults![index];
                        final distance =widget. currentPosition != null 
                          ? Geolocator.distanceBetween(
                            widget.  currentPosition!.latitude,
                            widget.  currentPosition!.longitude,
                              store.latitude,
                              store.longitude,
                            )
                          : 0.0;
                        
                        return _buildStoreItem(
                          context: context,
                          store: store,
                          distance: distance,
                          isDarkMode: isDarkMode,
                          currentPosition: widget.currentPosition,
                          onStoreSelected:widget.onStoreSelected,
                        );
                      },
                      childCount:widget. searchResults?.length ?? 0,
                    ),
                  );
                }

                final storesAsync = ref.watch(storesListProvider);
                return storesAsync.when(
                  data: (stores) {
                    List<Store> filteredStores = stores;
                     if (widget.initialCategory != null) {
                           filteredStores = stores.where((store) => 
                           store.Categorieid == widget.initialCategory!.id
                         ).toList();
                     }
                    
                    filteredStores.sort((a, b) {
                      if (widget.currentPosition == null) return 0;
                      final distanceA = Geolocator.distanceBetween(
                      widget.  currentPosition!.latitude,
                      widget.  currentPosition!.longitude,
                        a.latitude,
                        a.longitude,
                      );
                      final distanceB = Geolocator.distanceBetween(
                       widget. currentPosition!.latitude,
                      widget.  currentPosition!.longitude,
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
                     // Afficher l'indicateur de chargement si plus d'éléments
                              return _visibleStoresCount < filteredStores.length
                                  ? _buildLoadingIndicator()
                                  : const SizedBox.shrink();
                  }

      // Si index dépasse le nombre d'éléments
      if (index >= filteredStores.length || index >= _visibleStoresCount) {
        return const SizedBox.shrink();
      }

      final store = filteredStores[index];
      final distance =widget. currentPosition != null
          ? Geolocator.distanceBetween(
             widget. currentPosition!.latitude,
             widget. currentPosition!.longitude,
              store.latitude,
              store.longitude,
            )
          : 0.0;

      return _buildStoreItem(context:context ,store: store,distance:  distance, isDarkMode: isDarkMode ,currentPosition: widget.currentPosition,onStoreSelected: widget.onStoreSelected);
       },
      childCount: filteredStores.length > _visibleStoresCount 
                              ? _visibleStoresCount + 1 
                              : filteredStores.length, // +1 pour l'indicateur
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
        );
    }
  
Widget _buildHorizontalCategoryItem({
  required BuildContext context,
  IconData? icon,
  required String title,
  required bool isSelected,
  required VoidCallback onTap,
  required Color iconcolor,
   required bool isDarkMode,
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
              onTap:  () {
                onTap(); // Appel du callback parent
                setState(() {}); // Force le rebuild pour mettre à jour l'UI
              },
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
            color:isDarkMode ? (isSelected ? Colors.blue.shade700 :Colors.white) : (isSelected ? Colors.blue.shade700 : Colors.grey.shade800),
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

Widget _buildStoreItem({ required BuildContext context,
    required Store store,
    required double distance,
    required bool isDarkMode,
    required Position? currentPosition,
    final Function(Store?, Categories?)? onStoreSelected,
      }) {
        final clientAsync=ref.watch(authProvider).currentUser;
  final pointsAsync = ref.watch(clientMagazinPointsProvider(Tuple2(clientAsync?.id, store.id)));
  return   Container(
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
        onTap: ()  {
      if (onStoreSelected != null) {
          onStoreSelected(store, _selectedCategory);
        }
      
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child:Row(
  children: [
    // Logo du magasin
    Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: store.logoUrl != null && store.logoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: store.logoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholderIcon(),
                errorWidget: (context, url, error) => _buildPlaceholderIcon(),
              )
            : _buildPlaceholderIcon(),
      ),
    ),
    
    const SizedBox(width: 16),
    
    // Contenu principal
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom de l'enseigne
          Text(
            store.nom_enseigne,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.surface : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Ligne d'informations (adresse)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: isDarkMode ? AppColors.surface : AppColors.textPrimary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  store.adresse,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? AppColors.surface : AppColors.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Ligne des badges (distance + points)
          Row(
  children: [
    // Badge de distance
   Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: isDarkMode ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade200,
      width: 0.5,
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.near_me_outlined,  // Icône de localisation/distance
        size: 14,
        color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
      ),
      const SizedBox(width: 4),
      Text(
        distance < 1000 
          ? '${distance.toStringAsFixed(0)}m' 
          : '${(distance / 1000).toStringAsFixed(1)}km',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
        ),
      ),
    ],
  ),
),
    
    // Espace augmenté entre les badges (passé de 8 à 12)
    const SizedBox(width: 50),
    
    // Badge de points
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.green.shade900.withOpacity(0.2) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.green.shade700 : Colors.green.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 14,
            color: isDarkMode ? Colors.green.shade200 : Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          pointsAsync.when(
            data: (data) => Text(
              '${data?.cumulpoint ?? 0} pts',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.green.shade200 : Colors.green.shade700,
              ),
            ),
            error: (_, __) => Text(
              '0 pts',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.green.shade200 : Colors.green.shade700,
              ),
            ),
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    ),
  ],
),
        ],
      ),
    ),
    
    // Flèche indicative
    Icon(
      Icons.chevron_right,
      color: Colors.grey.shade400,
      size: 20,
    ),
  ],
)
        ),
      ),
    ),
  ) ;


}

Widget _buildPlaceholderIcon() {
 
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      color: Colors.white.withOpacity(0.1),
    ),
    child: const Icon(Icons.store_rounded, color: Colors.white, size: 36),
  );
}



  double _calculateDistance(Store shop) {
    if (widget.currentPosition == null) return 0;
    
    return Geolocator.distanceBetween(
   widget. currentPosition!.latitude,
   widget. currentPosition!.longitude,
    shop.latitude,    // Utilisez les nouveaux getters
    shop.longitude,   // Utilisez les nouveaux getters
  );
  }

// Future<void> _showShopDetails({ required BuildContext context,
//   required WidgetRef ref,
//   required Store shop,
//   required TickerProvider vsync,
//   required Position? currentPosition,
//   required bool isRouting,
//   required Function(Store) initiateRouting,} )
//    async {
//   final l10n = AppLocalizations.of(context);
//   final themeMode = ref.watch(themeProvider);
//   final isDarkMode = themeMode == AppThemeMode.light;
//   final currentLocale = ref.watch(languageProvider);
//   final offersRepo = ref.watch(offersProvider);
//   String? cleanLogoUrl = ref.read(storeLogoUrlProvider(shop.logoUrl ?? ''));
//   List<Offers>? storeOffers;
  
//   try {
//     storeOffers = await offersRepo.getOffresByMagasin(shop.id);
//   } catch (e) {
//     debugPrint('Erreur récupération offres: $e');
//   }

//   // Animations améliorées
//   final animationController = AnimationController(
//     vsync: vsync,
//     duration: const Duration(milliseconds: 800),
//   );
  
//   final slideAnimation = Tween<Offset>(
//     begin: const Offset(0, 1),
//     end: Offset.zero,
//   ).animate(CurvedAnimation(
//     parent: animationController,
//     curve: Curves.easeOutQuart,
//   ));

//   final fadeAnimation = Tween<double>(
//     begin: 0,
//     end: 1,
//   ).animate(CurvedAnimation(
//     parent: animationController,
//     curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
//   ));

//   final scaleAnimation = Tween<double>(
//     begin: 0.95,
//     end: 1.0,
//   ).animate(CurvedAnimation(
//     parent: animationController,
//     curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
//   ));

//   final distance = _calculateDistance(shop);
//   final category = CategoryHelpers.getCategory(ref, shop.Categorieid);
//   final localizedName = category.getName(currentLocale.languageCode);

//   await showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     isDismissible: true,
//     enableDrag: true,
//     useSafeArea: true,
//     builder: (context) {
//       animationController.forward();
      
//       return SlideTransition(
//         position: slideAnimation,
//         child: Container(
//           height: MediaQuery.of(context).size.height * 0.92,
//           decoration: BoxDecoration(
//             color: isDarkMode ? const Color(0xFF121212) : Colors.white,
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.3),
//                 blurRadius: 40,
//                 offset: const Offset(0, -20),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               // Handle bar élégant
//               Container(
//                 margin: const EdgeInsets.only(top: 12, bottom: 8),
//                 child: Container(
//                   width: 60,
//                   height: 5,
//                   decoration: BoxDecoration(
//                     color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                 ),
//               ),
              
//               Expanded(
//                 child: SingleChildScrollView(
//                   physics: const BouncingScrollPhysics(),
//                   child: FadeTransition(
//                     opacity: fadeAnimation,
//                     child: ScaleTransition(
//                       scale: scaleAnimation,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Hero Section avec morphisme moderne
//                           Container(
//                             margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(28),
//                               gradient: LinearGradient(
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                                 colors: [
//                                   CategoryMarkers.getPinColor(localizedName).withOpacity(0.9),
//                                   CategoryMarkers.getPinColor(localizedName),
//                                 ],
//                               ),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: CategoryMarkers.getPinColor(localizedName).withOpacity(0.3),
//                                   blurRadius: 30,
//                                   offset: const Offset(0, 15),
//                                 ),
//                               ],
//                             ),
//                             child: Stack(
//                               children: [
//                                 // Effet de profondeur
//                                 Positioned.fill(
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(28),
//                                       gradient: LinearGradient(
//                                         begin: Alignment.topCenter,
//                                         end: Alignment.bottomCenter,
//                                         colors: [
//                                           Colors.transparent,
//                                           Colors.black.withOpacity(0.15),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 ),
                                
//                                 Padding(
//                                   padding: const EdgeInsets.all(24),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       // En-tête avec logo et badge
//                                       Row(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           // Logo avec effet de verre
//                                           Container(
//                                             width: 80,
//                                             height: 80,
//                                             decoration: BoxDecoration(
//                                               borderRadius: BorderRadius.circular(24),
//                                               color: Colors.white.withOpacity(0.15),
//                                               border: Border.all(
//                                                 color: Colors.white.withOpacity(0.25),
//                                                 width: 1.5,
//                                               ),
//                                             ),
//                                             child: ClipRRect(
//                                               borderRadius: BorderRadius.circular(24),
//                                               child: cleanLogoUrl != null 
//                                                 ? CachedNetworkImage(
//                                                     imageUrl: cleanLogoUrl,
//                                                     fit: BoxFit.cover,
//                                                     placeholder: (_, __) => _buildPlaceholderIcon(),
//                                                     errorWidget: (_, __, ___) => _buildPlaceholderIcon(),
//                                                   )
//                                                 : _buildPlaceholderIcon(),
//                                             ),
//                                           ),
                                          
//                                           const Spacer(),
                                          
//                                           // Badge catégorie
//                                           Container(
//                                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                                             decoration: BoxDecoration(
//                                               color: Colors.white.withOpacity(0.15),
//                                               borderRadius: BorderRadius.circular(20),
//                                               border: Border.all(color: Colors.white.withOpacity(0.25)),
//                                             ),
//                                             child: Row(
//                                               mainAxisSize: MainAxisSize.min,
//                                               children: [
//                                                 Icon(
//                                                   CategoryMarkers.getPinIcon(localizedName),
//                                                   color: Colors.white,
//                                                   size: 16,
//                                                 ),
//                                                 const SizedBox(width: 8),
//                                                 Text(
//                                                   localizedName,
//                                                   style: const TextStyle(
//                                                     color: Colors.white,
//                                                     fontSize: 14,
//                                                     fontWeight: FontWeight.w600,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
                                      
//                                       const SizedBox(height: 24),
                                      
//                                       // Nom du magasin
//                                       Text(
//                                         shop.nom_enseigne,
//                                         style: const TextStyle(
//                                           fontSize: 28,
//                                           fontWeight: FontWeight.w800,
//                                           color: Colors.white,
//                                           height: 1.1,
//                                         ),
//                                       ),
                                      
//                                       const SizedBox(height: 16),
                                      
//                                       // Informations pratiques
//                                       Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           _buildInfoChip(
//                                             icon: Icons.location_on_rounded,
//                                             text: shop.adresse,
//                                             isDarkMode: isDarkMode,
//                                           ),
//                                               SizedBox(height: 12), // Espacement vertical

//                                           _buildInfoChip(
//                                             icon: Icons.near_me_rounded,
//                                             text: '${distance < 1000 ? '${distance.toStringAsFixed(0)} m' : '${(distance / 1000).toStringAsFixed(1)} km'}',
//                                             isDarkMode: isDarkMode,
//                                           ),
                                         
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           // Section Offres
//                           if (storeOffers != null && storeOffers.isNotEmpty) ...[
//                             const SizedBox(height: 32),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 24),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.local_offer_rounded,
//                                     color: Colors.orange.shade400,
//                                     size: 28,
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Text(
//                                     l10n?.offredisponible ?? 'Offres spéciales',
//                                     style: TextStyle(
//                                       fontSize: 22,
//                                       fontWeight: FontWeight.w700,
//                                       color: isDarkMode ? Colors.white : Colors.black87,
//                                     ),
//                                   ),
//                                   const Spacer(),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                                     decoration: BoxDecoration(
//                                       color: Colors.orange.withOpacity(0.1),
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: Text(
//                                       '${storeOffers.length}',
//                                       style: TextStyle(
//                                         color: Colors.orange.shade400,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
                            
//                             const SizedBox(height: 16),
                            
//                             SizedBox(
//                               height: 220,
//                               child: ListView.builder(
//                                 scrollDirection: Axis.horizontal,
//                                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                                 physics: const BouncingScrollPhysics(),
//                                 itemCount: storeOffers.length,
//                                 itemBuilder: (context, index) {
//                                   final offer = storeOffers![index];
//                                   return _buildModernOfferCard(offer, isDarkMode, index);
//                                 },
//                               ),
//                             ),
//                           ],

//                           const SizedBox(height: 32),

//                           // Boutons d'action
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 24),
//                             child: Row(
//                               children: [
//                                 // Bouton Fermer
//                                 Expanded(
//                                   child: OutlinedButton(
//                                     onPressed: () => Navigator.pop(context),
//                                     style: OutlinedButton.styleFrom(
//                                       padding: const EdgeInsets.symmetric(vertical: 16),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(16),
//                                       ),
//                                       side: BorderSide(
//                                         color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
//                                         width: 1.5,
//                                       ),
//                                     ),
//                                     child: Text(
//                                       l10n?.fermer ?? 'Fermer',
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w600,
//                                         color: isDarkMode ? Colors.white70 : Colors.black87,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
                                
//                                 if (currentPosition != null) ...[
//                                   const SizedBox(width: 16),
                                  
//                                   // Bouton Itinéraire
//                                   Expanded(
//                                     child: AnimatedContainer(
//                                       duration: const Duration(milliseconds: 300),
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(16),
//                                         gradient: isRouting 
//                                           ? null 
//                                           : const LinearGradient(
//                                               colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
//                                               begin: Alignment.topLeft,
//                                               end: Alignment.bottomRight,
//                                             ),
//                                         color: isRouting ? Colors.grey.shade600 : null,
//                                         boxShadow: isRouting
//                                           ? null
//                                           : [
//                                               BoxShadow(
//                                                 color: const Color(0xFF6366F1).withOpacity(0.3),
//                                                 blurRadius: 15,
//                                                 offset: const Offset(0, 8),
//                                               ),
//                                             ],
//                                       ),
//                                       child: Material(
//                                         color: Colors.transparent,
//                                         borderRadius: BorderRadius.circular(16),
//                                         child: InkWell(
//                                           borderRadius: BorderRadius.circular(16),
//                                           onTap: isRouting
//                                             ? null
//                                             : () {
//                                                 Navigator.pop(context);
//                                                 if (widget.onStoreSelected != null) {
//                                                     // Utilisez le callback pour déclencher la navigation
//                                                     widget.onStoreSelected!(shop,_selectedCategory);
//                                                  }
//                                               },
//                                           child: Padding(
//                                             padding: const EdgeInsets.symmetric(vertical: 16),
//                                             child: Center(
//                                               child: isRouting
//                                                 ? const SizedBox(
//                                                     width: 24,
//                                                     height: 24,
//                                                     child: CircularProgressIndicator(
//                                                       strokeWidth: 3,
//                                                       color: Colors.white,
//                                                     ),
//                                                   )
//                                                 : Row(
//                                                     mainAxisAlignment: MainAxisAlignment.center,
//                                                     children: [
//                                                       const Icon(
//                                                         Icons.directions_rounded,
//                                                         color: Colors.white,
//                                                         size: 22,
//                                                       ),
//                                                       const SizedBox(width: 8),
//                                                       Text(
//                                                         l10n?.iterinaire ?? 'Itinéraire',
//                                                         style: const TextStyle(
//                                                           color: Colors.white,
//                                                           fontWeight: FontWeight.w600,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ],
//                             ),
//                           ),

//                           SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   ).whenComplete(() => animationController.dispose());
// }

Widget _buildInfoChip({
  required IconData icon,
  required String text,
  required bool isDarkMode,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.95),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget _buildModernOfferCard(Offers offer, bool isDarkMode, int index) {
  final gradients = [
    [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)], // Rouge/Orange
    [const Color(0xFF4ECDC4), const Color(0xFF44A08D)], // Turquoise/Vert
    [const Color(0xFF45B7D1), const Color(0xFF96C93D)], // Bleu/Vert
    [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4)], // Rose/Pêche
  ];
  
  final gradient = gradients[index % gradients.length];
  
  return Container(
    width: 280,
    margin: const EdgeInsets.only(right: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradient,
      ),
      boxShadow: [
        BoxShadow(
          color: gradient[0].withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Stack(
      children: [
        // Badge
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Text(
              'OFFRE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Montant minimum
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Dépensez ${offer.min_amount}€',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Points à gagner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${offer.points_given}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'points à gagner',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
    }

