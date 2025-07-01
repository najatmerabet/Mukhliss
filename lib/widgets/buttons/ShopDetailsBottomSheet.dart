import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mukhliss/l10n/l10n.dart';

import 'package:mukhliss/models/categories.dart';
import 'package:mukhliss/models/offers.dart';
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/providers/clientmagazin_provider.dart';

import 'package:mukhliss/providers/langue_provider.dart';
import 'package:mukhliss/providers/offers_provider.dart';
import 'package:mukhliss/providers/store_provider.dart';
import 'package:mukhliss/providers/theme_provider.dart';

import 'package:mukhliss/utils/category_helpers.dart';
import 'package:mukhliss/utils/geticategoriesbyicon.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tuple/tuple.dart';
import 'package:shimmer/shimmer.dart';


class ShopDetailsBottomSheet extends ConsumerStatefulWidget {
  final Store? shop;
  final Position? currentPosition;
  final WidgetRef ref;
  final TickerProvider vsync;
  final bool isRouting;
  final Function(Store?, Categories?)? onStoreSelected;
  final Categories? selectedCategory;
  final Function(Store) initiateRouting;
  final GlobalKey<NavigatorState> navigatorKey;
  // Nouveau paramètre
  final VoidCallback closeCategoriesSheet; // Nouveau paramètre

  const ShopDetailsBottomSheet({
    super.key,
    required this.shop,
    required this.currentPosition,
    required this.ref,
    required this.vsync,
    required this.isRouting,
    this.onStoreSelected,
    this.selectedCategory,
    required this.initiateRouting,
    required this.navigatorKey,
    required this.closeCategoriesSheet, 
  });

  @override
  ConsumerState<ShopDetailsBottomSheet> createState() => _ShopDetailsBottomSheetState();
}

class _ShopDetailsBottomSheetState extends ConsumerState<ShopDetailsBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();

    print('Shop ID dans initState: ${widget.shop?.id}');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
      ),
    );

    scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _draggableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     final bool categoriesBottomSheetShown=false;
     final clientAsync=ref.watch(authProvider).currentUser;
     final pointsAsync = ref.watch(clientMagazinPointsProvider(Tuple2(clientAsync?.id, widget.shop?.id)));
     print("la respponse====================>"+pointsAsync.toString());
    if (widget.shop == null) {
      return _buildEmptyState(true); // Return empty container if shop is null
    }
final offersAsync = widget.ref.watch(offersByStoreProvider(widget.shop?.id ?? ''));

print('Watching offers for shopId: ${widget.shop?.id}');
print('Current offersAsync state: ${offersAsync.value}');
print('Has error: ${offersAsync.hasError}');
print('Is loading: ${offersAsync.isLoading}');
    // Early return if shop is null
    if (widget.shop == null) {
      return _buildEmptyState(true); // or some other placeholder
    }

    return DraggableScrollableSheet(
      // controller: _draggableController,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.3, 0.5, 0.9],
      builder: (context, scrollController) {
        final l10n = AppLocalizations.of(context);
        final themeMode = widget.ref.watch(themeProvider);
        final isDarkMode = themeMode == AppThemeMode.light;
        final currentLocale = widget.ref.watch(languageProvider);
        String? cleanLogoUrl = widget.ref.read(
          storeLogoUrlProvider(widget.shop?.logoUrl ?? ''),
        );

        final distance = _calculateDistance(
          widget.currentPosition,
          widget.shop,
        );
        final category = CategoryHelpers.getCategory(
          widget.ref,
          widget.shop?.Categorieid,
        );
        final localizedName = category.getName(currentLocale.languageCode);

        return Material(
          color: isDarkMode ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                      color:
                          isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Contenu principal
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            CategoryMarkers.getPinColor(
                              localizedName,
                            ).withOpacity(0.9),
                            CategoryMarkers.getPinColor(localizedName),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CategoryMarkers.getPinColor(
                              localizedName,
                            ).withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.15),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
  padding: const EdgeInsets.all(24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // En-tête avec logo et catégorie
      Row(
        children: [
          // Logo avec effet de placeholder amélioré
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: cleanLogoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: cleanLogoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildShimmerPlaceholder(),
                      errorWidget: (_, __, ___) => _buildPlaceholderIcon(),
                    )
                  : _buildPlaceholderIcon(),
            ),
          ),
          
          const Spacer(),
          
          // Badge de catégorie avec animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CategoryMarkers.getPinIcon(localizedName),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  localizedName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 24),
      
      // Nom de l'enseigne avec effet de dégradé possible
      Text(
        widget.shop!.nom_enseigne,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.1,
          // Option: ajouter un dégradé si pertinent pour votre design
          // foreground: Paint()..shader = gradient.createShader(...),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      
      const SizedBox(height: 16),
      
      // Informations sous forme de liste
      ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return _buildInfoChip(
                icon: Icons.location_on_rounded,
                text: widget.shop!.adresse,
                isDarkMode: isDarkMode,
              );
            case 1:
              return _buildInfoChip(
                icon: Icons.near_me_rounded,
                text: distance < 1000 
                  ? '${distance.toStringAsFixed(0)} m' 
                  : '${(distance / 1000).toStringAsFixed(1)} km',
                isDarkMode: isDarkMode,
              );
            case 2:
              return pointsAsync.when(
                data: (clientMagazin) => _buildInfoChip(
                  icon: Icons.loyalty_rounded,
                  text: '${clientMagazin?.cumulpoint ?? 0} pts',
                  isDarkMode: isDarkMode,
                 // Paramètre supplémentaire pour styliser différemment
                ),
                loading: () => _buildShimmerChip(isDarkMode: isDarkMode),
                error: (error, stack) => _buildInfoChip(
                  icon: Icons.error_outline_rounded,
                  text: 'Erreur de chargement',
                  isDarkMode: isDarkMode,
                ),
              );
            default:
              return const SizedBox();
          }
        },
      ),
                    ],
                ),
                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Section Offres
            
            
            
offersAsync.when(
  loading: () {
    final isFirstLoad = !offersAsync.hasValue;
    return isFirstLoad 
        ? _buildFirstLoadState(isDarkMode)
        : _buildRegularLoadingState(isDarkMode);
  },
  error: (error, stack) => _buildErrorState(error, stack, isDarkMode),
  data: (offers) => offers.isEmpty
      ? _buildEmptyState(isDarkMode)
      : _buildOffersList(offers, isDarkMode, l10n),
       
),
// ajouter un espace 
    
              // Boutons d'action
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                         onPressed: () {
                           // 1. Fermer le bottom sheet
                           widget.closeCategoriesSheet();
      
                          // 2. Recentrer la carte sur la position actuelle
  
                              },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color:
                                  isDarkMode
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            l10n?.fermer ?? 'Fermer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      if (widget.currentPosition != null) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient:
                                  widget.isRouting
                                      ? null
                                      : const LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFF8B5CF6),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                              color:
                                  widget.isRouting
                                      ? Colors.grey.shade600
                                      : null,
                              boxShadow:
                                  widget.isRouting
                                      ? null
                                      : [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF6366F1,
                                          ).withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                             borderRadius: BorderRadius.circular(16),
                             onTap: widget.isRouting
                                          ? null
                                          : ()  {
                                            widget.initiateRouting(widget.shop!);
                                          },
                                        
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Center(
                                    child:
                                        widget.isRouting
                                            ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: Colors.white,
                                              ),
                                            )
                                            : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.directions_rounded,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  l10n?.iterinaire ??
                                                      'Itinéraire',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Espacement en bas
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
Widget _buildFirstLoadState(bool isDarkMode) {
  return SliverToBoxAdapter(
    child: Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Loading offers for the first time...',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildRegularLoadingState(bool isDarkMode) {
  return SliverToBoxAdapter(
    child: Container(
      height: 100,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    ),
  );
}
  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
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
Widget _buildShimmerPlaceholder() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[800]!,
    highlightColor: Colors.grey[600]!,
    child: Center(
      child: Icon(
        Icons.store_rounded,
        size: 40,
        color: Colors.white.withOpacity(0.5),
      ),
    ),
  );
}
 

Widget _buildShimmerChip({required bool isDarkMode}) {
  return Shimmer.fromColors(
    baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
    highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDarkMode ? 0.15 : 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(isDarkMode ? 0.25 : 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 80,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildModernOfferCard(Offers offer, bool isDarkMode, int index) {
    final gradients = [
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
      [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
      [const Color(0xFF45B7D1), const Color(0xFF96C93D)],
      [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4)],
    ];
 final l10n = AppLocalizations.of(context);
    final gradient = gradients[index % gradients.length];
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    return Container(
      width: 280,
     margin: EdgeInsets.only(
      right: isRTL ? 0 : 16,
      left: isRTL ? 16 : 0,
    ),
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
          Positioned(
            top: 16,
            right: isRTL ? null : 16,
            left: isRTL ? 16 : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child:  Text(
               l10n?.offremagasin ?? 'OFFRE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  constraints: BoxConstraints(
                     minWidth: 120, // Ajustez selon vos besoins
                    ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                     (l10n?.depensez != null 
                        ? '${l10n!.depensez} ${offer.min_amount}€' 
                        : 'Dépensez ${offer.min_amount}€'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                     textDirection: TextDirection.ltr,
                  ),
                ),
                const SizedBox(height: 16),
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
                           l10n?.pointsagagner ?? 'points à gagner',
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

  double _calculateDistance(Position? currentPosition, Store? shop) {
    if (currentPosition == null) return 0;

    return Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      shop!.latitude,
      shop.longitude,
    );
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

  Widget _buildLoadingState(bool isDarkMode) {
    return SliverToBoxAdapter(
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorState(Object error, StackTrace? stack, bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Failed to load offers: $error',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
     final l10n = AppLocalizations.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
          l10n?.nooffre ??   'No offers available',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

 
  Widget _buildOffersList(
    List<dynamic> offers,
    bool isDarkMode,
    AppLocalizations? l10n,
  ) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: Colors.orange.shade400,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                l10n?.offredisponible ?? 'Offres spéciales',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${offers.length}',
                  style: TextStyle(
                    color: Colors.orange.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return _buildModernOfferCard(offer, isDarkMode, index);
            },
          ),
        ),
          const SizedBox(height: 16),
      ]),
       
    );
     
  }


  

}
