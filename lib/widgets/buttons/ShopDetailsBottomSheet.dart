import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mukhliss/l10n/l10n.dart';

import 'package:mukhliss/models/categories.dart';
import 'package:mukhliss/models/offers.dart';
import 'package:mukhliss/models/rewards.dart';
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/providers/clientmagazin_provider.dart';

import 'package:mukhliss/providers/langue_provider.dart';
import 'package:mukhliss/providers/offers_provider.dart';
import 'package:mukhliss/providers/rewards_provider.dart';
import 'package:mukhliss/providers/store_provider.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/screen/layout/main_navigation_screen.dart';
import 'package:mukhliss/theme/app_theme.dart';

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
     
     final clientAsync=ref.watch(authProvider).currentUser;
     final pointsAsync = ref.watch(clientMagazinPointsProvider(Tuple2(clientAsync?.id, widget.shop?.id)));
    if (widget.shop == null) {
      return _buildEmptyState(true); // Return empty container if shop is null
    }
final rewardsAsync = widget.ref.watch(rewardsByMagasinProvider(widget.shop?.id ?? ''));

print('Watching rewards for shopId: ${widget.shop?.id}');
print('Current rewardsAsync state: ${rewardsAsync.value}');
print('Has error: ${rewardsAsync.hasError}');
print('Is loading: ${rewardsAsync.isLoading}');
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
             SliverToBoxAdapter(
               child: Padding(
                 padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           // En-tête avec logo et badge catégorie
                           Row(
                             crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
           // Logo avec effet glassmorphism
                     Container(
                    width: 85,
                   height: 85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                     gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
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
          
          const SizedBox(width: 16),
          
          // Informations principale et badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge de catégorie redesigné
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CategoryMarkers.getPinColor(localizedName).withOpacity(0.25),
                        CategoryMarkers.getPinColor(localizedName).withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CategoryMarkers.getPinIcon(localizedName),
                        color: CategoryMarkers.getPinColor(localizedName),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          localizedName,
                          style:  TextStyle(
                            color: isDarkMode ? AppColors.surface : AppColors.darkSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Nom de l'enseigne avec effet
                Text(
                  widget.shop!.nom_enseigne,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ?  AppColors.surface : AppColors.darkSurface,
                    height: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 28),
      
      // Grille d'informations avec design moderne
 LayoutBuilder(
  builder: (context, constraints) {
    return SizedBox(
      height: 90, // Hauteur fixe pour la ligne
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _buildModernInfoCard(
            icon: Icons.location_on_rounded,
            title: l10n?.address ?? 'Adresse',
            value: widget.shop!.adresse,
            gradient: [
              AppColors.accent,
              AppColors.accent,
            ],
            isDarkMode: isDarkMode,
          ),
          const SizedBox(width: 8),
          _buildModernInfoCard(
            icon: Icons.near_me_rounded,
            title: l10n?.distance ??'Distance',
            value: distance < 1000 
                ? '${distance.toStringAsFixed(0)} m' 
                : '${(distance / 1000).toStringAsFixed(1)} km',
            gradient: [
              AppColors.success,
              AppColors.success.withOpacity(0.9),
            ],
            isDarkMode: isDarkMode,
          ),
          const SizedBox(width: 8),
          pointsAsync.when(
            data: (clientMagazin) => _buildModernInfoCard(
              icon: Icons.loyalty_rounded,
              title: 'Points',
              value: '${clientMagazin?.cumulpoint ?? 0}',
              gradient: [
                AppColors.secondary,
                  AppColors.secondary,
              ],
              isDarkMode: isDarkMode,
            ),
            loading: () => _buildLoadingInfoCard(isDarkMode),
            error: (error, stack) => _buildModernInfoCard(
              icon: Icons.error_outline_rounded,
              title: 'Points',
              value: 'Erreur',
              gradient: [
                Colors.red.shade400.withOpacity(0.8),
                Colors.red.shade600.withOpacity(0.9),
              ],
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  },
)
    ],
  ),

          ],
                  
        ),
      ),
             ),

            
            
rewardsAsync.when(
  loading: () {
    final isFirstLoad = !rewardsAsync.hasValue;
    return isFirstLoad
        ? _buildFirstLoadState(isDarkMode)
        : _buildRegularLoadingState(isDarkMode);
  },
  error: (error, stack) => _buildErrorState(error, stack, isDarkMode),
  data: (rewards) => rewards.isEmpty
      ? _buildEmptyState(isDarkMode)
      : _buildOffersList(rewards, isDarkMode, l10n),

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

  // Widget pour les cartes d'information modernes
Widget _buildModernInfoCard({
  required IconData icon,
  required String title,
  required String value,
  required List<Color> gradient,
  required bool isDarkMode,
}) {
  return ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: 80,  // Hauteur réduite
      minWidth: 110,  // Largeur réduite
      maxWidth: 120,  // Largeur maximale
    ),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Widget pour l'état de chargement des cartes d'info
Widget _buildLoadingInfoCard(bool isDarkMode) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey.shade400.withOpacity(0.6),
          Colors.grey.shade600.withOpacity(0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 50,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 70,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ),
    ),
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
 


  // 🎫 DESIGN 1: Style Ticket/Coupon
Widget _buildTicketStyle(Rewards offer, bool isDarkMode, int index) {
  final colors = [
    [Colors.purple.shade600, Colors.blue.shade600],
    [Colors.blue.shade600, Colors.cyan.shade400],
    [Colors.green.shade500, Colors.teal.shade400],
    [Colors.orange.shade600, Colors.red.shade500],
  ];
  final gradient = colors[index % colors.length];
  final l10n = AppLocalizations.of(context);
  final isRTL = Directionality.of(context) == TextDirection.rtl;

  return Padding(
    padding: EdgeInsets.only(
      right: isRTL ? 0 : 16,
      left: isRTL ? 16 : 0,
      top: 8,
      bottom: 8,
    ),
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 300,
        height: 170,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: isRTL 
              ? BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                 
                )
              : BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                 
                ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Section colorée - Adaptée pour RTL
            Positioned(
              left: isRTL ? null : 0,
              right: isRTL ? 0 : null,
              top: 0,
              bottom: 0,
              child: Container(
                width: 90,
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: isRTL
                      ? BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        )
                      : BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradient,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.white, size: 36),
                    SizedBox(height: 8),
                    RotatedBox(
                      quarterTurns: isRTL ? 1 : -1, // Inverser la rotation pour RTL
                      child: Text(
                        l10n?.offremagasin ?? 'REWARD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Séparateur pointillé - Adapté pour RTL
            Positioned(
              top: 0,
              bottom: 0,
              left: isRTL ? null : 90,
              right: isRTL ? 90 : null,
              width: 2,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boxCount = (constraints.maxHeight / 8).floor();
                  return Flex(
                    direction: Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(boxCount, (_) {
                      return Container(
                        width: 1,
                        height: 4,
                        color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.grey.shade400,
                      );
                    }),
                  );
                },
              ),
            ),

            // Zone de contenu principale - Adaptée pour RTL
            Positioned.fill(
              left: isRTL ? 0 : 100,
              right: isRTL ? 100 : 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom de l'offre
                    Text(
                      offer.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.grey.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isRTL ? TextAlign.right : TextAlign.left,
                    ),
                    SizedBox(height: 8),
                    
                    // Description
                    if (offer.description != null && offer.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          offer.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                    
                    // Points requis - Alignement adapté
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Text(
                          '${offer.points_required}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: gradient.first,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'PTS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Statut - Alignement adapté
                    Align(
                      alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: offer.is_active
                              ? (isDarkMode ? Colors.green.shade700.withOpacity(0.3) : Colors.green.shade100)
                              : (isDarkMode ? Colors.orange.shade800.withOpacity(0.3) : Colors.orange.shade100),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          offer.is_active
                              ? (l10n?.disponible ?? 'Disponible')
                              : (l10n?.limite ?? 'Limité'),
                          style: TextStyle(
                            fontSize: 11,
                            color: offer.is_active
                                ? (isDarkMode ? Colors.greenAccent.shade200 : Colors.green.shade700)
                                : (isDarkMode ? Colors.orangeAccent.shade100 : Colors.orange.shade700),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // Cercles supérieur et inférieur - Adaptés pour RTL
            Positioned(
              top: -10,
              left: isRTL ? null : 86,
              right: isRTL ? 86 : null,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade200,
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              left: isRTL ? null : 86,
              right: isRTL ? 86 : null,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade200,
                ),
              ),
            ),
          ],
        ),
      ),
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
                l10n?.offredisponible ?? 'Offres disponibles',
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
              return _buildTicketStyle(offer, isDarkMode, index);
            },
          ),
        ),
          const SizedBox(height: 16),
      ]),
       
    );
     
  }


  

}
