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
  child: GestureDetector(
    behavior: HitTestBehavior.opaque, // Important pour que toute la zone soit cliquable
    onTap: widget.closeCategoriesSheet,
    child: Container(
      width: double.infinity, // Prend toute la largeur
      padding: const EdgeInsets.only(top: 12, bottom: 12), // Zone de touche plus grande
      alignment: Alignment.center,
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  ),
),
             SliverToBoxAdapter(
               child: Padding(
                 padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                 child: ConstrainedBox(
                       constraints: BoxConstraints(
                       maxHeight: MediaQuery.of(context).size.height * 0.8,
                         ),
                     child: SingleChildScrollView(
                       child: Column(
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
          Flexible(
            fit:FlexFit.loose,
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
// Dans votre méthode build, remplacez la partie concernée par :

// Grille d'informations avec design moderne
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Première ligne - Adresse
      _buildInfoRow(
        icon: Icons.location_on_rounded,
        iconColor: Colors.blue,
        title: l10n?.address ?? 'Adresse',
        value: widget.shop!.adresse.split(',').first,
        isDarkMode: isDarkMode,
      ),
      
      const SizedBox(height: 12),
      
      // Deuxième ligne - Distance et Points
      Row(
        children: [
          Expanded(
            child: _buildInfoRow(
              icon: Icons.near_me_rounded,
              iconColor: Colors.green,
              title: l10n?.distance ?? 'Distance',
              value: distance < 1000 
                  ? '${distance.toStringAsFixed(0)} m' 
                  : '${(distance / 1000).toStringAsFixed(1)} km',
              isDarkMode: isDarkMode,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: pointsAsync.when(
              data: (clientMagazin) => _buildInfoRow(
                icon: Icons.loyalty_rounded,
                iconColor: Colors.amber,
                title: 'Points',
                value: '${clientMagazin?.cumulpoint ?? 0}',
                isDarkMode: isDarkMode,
              ),
              loading: () => _buildLoadingRow(isDarkMode),
              error: (_, __) => _buildErrorRow(isDarkMode),
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

Widget _buildInfoRow({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String value,
  required bool isDarkMode,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildLoadingRow(bool isDarkMode) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(
          'Chargement...',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

Widget _buildErrorRow(bool isDarkMode) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          'Erreur',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
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
Widget _buildCreditCardStyle(Rewards offer, bool isDarkMode, int index) {
  final l10n = AppLocalizations.of(context);
  final isRTL = Directionality.of(context) == TextDirection.rtl;

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    height: 240,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: isRTL ? Alignment.topRight : Alignment.topLeft,
        end: isRTL ? Alignment.topLeft : Alignment.topRight,
        colors: AppColors.lightGradient,
        stops: [0.0, 1.0],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.lightGradient[0].withOpacity(0.3),
          blurRadius: 25,
          spreadRadius: 0,
          offset: Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 15,
          spreadRadius: 0,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Arrière-plan décoratif - positionnement RTL-aware
          Positioned(
            right: isRTL ? null : -30,
            left: isRTL ? -30 : null,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: isRTL ? null : 20,
            left: isRTL ? 20 : null,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          // Effet de lueur - positionnement RTL-aware
          Positioned(
            right: isRTL ? null : 0,
            left: isRTL ? 0 : null,
            top: 0,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.amber.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          
          // Icône étoile - positionnement RTL-aware
          Positioned(
            right: isRTL ? null : 16,
            left: isRTL ? 16 : null,
            top: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.star_rounded,
                size: 22,
                color: AppColors.amber,
              ),
            ),
          ),
          
          // Contenu principal
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section en-tête avec badges - direction RTL-aware
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    // Badge d'état
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: offer.is_active ? AppColors.success : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            offer.is_active ? l10n?.exclusifs ?? 'EXCLUSIF' : l10n?.limite ?? 'LIMITÉ',
                            style: TextStyle(
                              color: AppColors.darkSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Indicateur de popularité
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Icon(Icons.local_fire_department, 
                              color: AppColors.amber, 
                              size: 14),
                          SizedBox(width: 4),
                          Text(
                            'HOT',
                            style: TextStyle(
                              color: AppColors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Titre principal - alignement RTL-aware
                Text(
                  offer.name,
                  style: TextStyle(
                    color: AppColors.darkSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isRTL ? TextAlign.right : TextAlign.left,
                ),
                
                SizedBox(height: 8),
                
                // Description - alignement RTL-aware (CORRIGÉ)
                Expanded(
                  child: Text(
                    offer.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.darkSurface,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Section points compacte - CORRIGÉ
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      // Points section compacte
                      Row(
                        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icône étoile compacte
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.amber,
                                  AppColors.amber.withOpacity(0.8),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          
                          SizedBox(width: 8),
                          
                          // Informations des points compactes
                          Column(
                            crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n?.pointsrequis ?? 'POINTS REQUIS',
                                style: TextStyle(
                                  color: AppColors.amber.withOpacity(0.9),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${offer.points_required}',
                                    style: TextStyle(
                                      color: AppColors.darkSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      height: 1.0,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                  l10n?.points ??  'pts',
                                    style: TextStyle(
                                      color: AppColors.darkSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Bouton d'action
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Votre logique ici
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            l10n?.benificier ?? 'À bénéficier',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
              return _buildCreditCardStyle(offer, isDarkMode, index);
            },
          ),
        ),
          const SizedBox(height: 16),
      ]),
       
    );
     
  }


  

}
