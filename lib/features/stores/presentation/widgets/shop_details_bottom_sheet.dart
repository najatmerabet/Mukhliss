import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/features/rewards/rewards.dart';

import 'package:mukhliss/features/stores/domain/entities/category_entity.dart';
import 'package:mukhliss/features/stores/domain/entities/store_entity.dart';
import 'package:mukhliss/core/providers/auth_provider.dart';
import 'package:mukhliss/features/stores/stores.dart'
    show clientMagazinPointsProvider;

import 'package:mukhliss/core/providers/langue_provider.dart';

import 'package:mukhliss/features/stores/presentation/providers/stores_providers.dart';
import 'package:mukhliss/core/providers/theme_provider.dart';

import 'package:mukhliss/core/theme/app_theme.dart';

import 'package:mukhliss/core/utils/category_helpers.dart';
import 'package:mukhliss/core/utils/geticategoriesbyicon.dart';

import 'package:tuple/tuple.dart';
import 'shop_details_widgets.dart';

class ShopDetailsBottomSheet extends ConsumerStatefulWidget {
  final StoreEntity? shop;
  final Position? currentPosition;
  final WidgetRef ref;
  final TickerProvider vsync;
  final bool isRouting;
  final Function(StoreEntity?, CategoryEntity?)? onStoreSelected;
  final CategoryEntity? selectedCategory;
  final Function(StoreEntity) initiateRouting;
  final GlobalKey<NavigatorState> navigatorKey;
  // Nouveau paramètre
  final VoidCallback closeCategoriesSheet; // Nouveau paramètre
  final VoidCallback? onRefresh;
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
    this.onRefresh,
  });

  @override
  ConsumerState<ShopDetailsBottomSheet> createState() =>
      _ShopDetailsBottomSheetState();
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

  void refreshShopRewards() {
    final shopId = widget.shop?.id;
    if (shopId != null && shopId.isNotEmpty) {
      ref.invalidate(rewardsByMagasinProvider(shopId));

      // Appeler le callback parent si fourni
      widget.onRefresh?.call();

      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.active ?? 'Données actualisées'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientId = ref.watch(currentClientIdProvider);
    final pointsAsync = ref.watch(
      clientMagazinPointsProvider(Tuple2(clientId, widget.shop?.id)),
    );
    if (widget.shop == null) {
      return _buildEmptyState(true); // Return empty container if shop is null
    }
    final rewardsAsync = widget.ref.watch(
      rewardsByMagasinProvider(widget.shop?.id ?? ''),
    );

    // Early return if shop is null
    if (widget.shop == null) {
      return _buildEmptyState(true); // or some other placeholder
    }

    return DraggableScrollableSheet(
      controller: _draggableController, // Activé
      initialChildSize: 0.5,
      minChildSize: 0.1,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.1, 0.3, 0.5, 0.9],
      builder: (context, scrollController) {
        final l10n = AppLocalizations.of(context);
        final themeMode = widget.ref.watch(themeProvider);
        final isDarkMode = themeMode == AppThemeMode.dark;
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
          widget.shop?.categoryId,
        );
        final localizedName = category.getName(currentLocale.languageCode);

        return Material(
          color: isDarkMode ? const Color(0xFF0A0E27) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Handle avec geste de drag
              SliverToBoxAdapter(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    final delta = details.primaryDelta ?? 0;
                    final newSize = _draggableController.size - (delta / MediaQuery.of(context).size.height);
                    if (newSize >= 0.1 && newSize <= 0.9) {
                      _draggableController.jumpTo(newSize);
                    }
                  },
                  onVerticalDragEnd: (details) {
                    // Fermer si en dessous de 0.15
                    if (_draggableController.size < 0.15) {
                      widget.closeCategoriesSheet();
                    }
                  },
                  onTap: widget.closeCategoriesSheet,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                                      Colors.white.withValues(alpha: 0.25),
                                      Colors.white.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child:
                                      cleanLogoUrl != null
                                          ? CachedNetworkImage(
                                            imageUrl: cleanLogoUrl,
                                            fit: BoxFit.cover,
                                            placeholder:
                                                (_, __) =>
                                                    _buildShimmerPlaceholder(),
                                            errorWidget:
                                                (_, __, ___) =>
                                                    _buildPlaceholderIcon(),
                                          )
                                          : _buildPlaceholderIcon(),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Informations principale et badge
                              Flexible(
                                fit: FlexFit.loose,
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
                                            CategoryMarkers.getPinColor(
                                              localizedName,
                                            ).withValues(alpha: 0.25),
                                            CategoryMarkers.getPinColor(
                                              localizedName,
                                            ).withValues(alpha: 0.15),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CategoryMarkers.getPinIcon(
                                              localizedName,
                                            ),
                                            color: CategoryMarkers.getPinColor(
                                              localizedName,
                                            ),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              localizedName,
                                              style: TextStyle(
                                                color:
                                                    isDarkMode
                                                        ? AppColors.surface
                                                        : AppColors.darkSurface,
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
                                      widget.shop!.name,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color:
                                            isDarkMode
                                                ? AppColors.surface
                                                : AppColors.darkSurface,
                                        height: 1.1,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Première ligne - Adresse
                                _buildInfoRow(
                                  icon: Icons.location_on_rounded,
                                  iconColor: Colors.blue,
                                  title: l10n?.address ?? 'Adresse',
                                  value:
                                      widget.shop!.address != null
                                          ? widget.shop!.address!
                                              .split(',')
                                              .first
                                          : '',
                                  isDarkMode: isDarkMode,
                                ),

                                const SizedBox(height: 12),

                                // Deuxième ligne - Distance et Points (CORRIGÉ)
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Distance
                                      Flexible(
                                        flex: 1,
                                        child: _buildInfoRow(
                                          icon: Icons.near_me_rounded,
                                          iconColor: Colors.green,
                                          title: l10n?.distance ?? 'Distance',
                                          value:
                                              distance < 1000
                                                  ? '${distance.toStringAsFixed(0)} m'
                                                  : '${(distance / 1000).toStringAsFixed(1)} km',
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Points
                                      Flexible(
                                        flex: 1,
                                        child: pointsAsync.when(
                                          data:
                                              (clientMagazin) => _buildInfoRow(
                                                icon: Icons.loyalty_rounded,
                                                iconColor: Colors.amber,
                                                title: 'Points',
                                                value:
                                                    '${clientMagazin?.cumulpoint ?? 0}',
                                                isDarkMode: isDarkMode,
                                              ),
                                          loading:
                                              () =>
                                                  _buildLoadingRow(isDarkMode),
                                          error: (e, __) {
                                            if (e.toString().contains(
                                              'no_internet_connection',
                                            )) {
                                              return _buildNoInternetRow(
                                                isDarkMode,
                                              );
                                            }
                                            return _buildErrorRow(isDarkMode);
                                          },
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
                error:
                    (error, stack) =>
                        _buildErrorState(error, stack, isDarkMode),
                data:
                    (rewards) =>
                        rewards.isEmpty
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
                                          ).withValues(alpha: 0.3),
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
                                onTap:
                                    widget.isRouting
                                        ? null
                                        : () {
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
        color: isDarkMode ? Color.fromARGB(255, 10, 17, 65) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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

  Widget _buildLoadingRow(bool isDarkMode) =>
      ShopLoadingRow(isDarkMode: isDarkMode);

  Widget _buildErrorRow(bool isDarkMode) =>
      ShopErrorRow(isDarkMode: isDarkMode);

  Widget _buildNoInternetRow(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.orange.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Points',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hors ligne',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade400,
                  ),
                ),
              ],
            ),
          ),
          // Bouton de rafraîchissement optionnel
          InkWell(
            onTap: () {
              // Réessayer de charger les points
              final clientId = ref.read(currentClientIdProvider);
              ref.invalidate(
                clientMagazinPointsProvider(Tuple2(clientId, widget.shop?.id)),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstLoadState(bool isDarkMode) => SliverToBoxAdapter(
    child: Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Loading offers...',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildRegularLoadingState(bool isDarkMode) => SliverToBoxAdapter(
    child: Container(
      height: 100,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    ),
  );
  Widget _buildShimmerPlaceholder() => const ShopShimmerPlaceholder();

  // 🎫 DESIGN: Style Carte de Crédit avec gradients
  Widget _buildCreditCardStyle(RewardEntity offer, bool isDarkMode, int index) {
    // Palette de dégradés colorés variés
    final List<List<Color>> gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)], // Violet-Purple
      [const Color(0xFFf093fb), const Color(0xFFF5576c)], // Rose-Rouge
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Bleu clair
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // Vert-Cyan
      [const Color(0xFFfa709a), const Color(0xFFfee140)], // Rose-Jaune
      [const Color(0xFFff9a56), const Color(0xFFff6a88)], // Orange-Coral
      [const Color(0xFF30cfd0), const Color(0xFF330867)], // Cyan-Violet foncé
      [const Color(0xFFa8edea), const Color(0xFFfed6e3)], // Pastel multicolore
    ];
    final l10n = AppLocalizations.of(context);
    final selectedGradient = gradients[index % gradients.length];

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.only(bottom: 60),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selectedGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: selectedGradient[0].withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: selectedGradient[1].withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: offer.isActive ? () => _showRewardDetails(offer) : null,
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Cercles décoratifs
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                Positioned(
                  top: -15,
                  right: -15,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                // Badge "Épuisé"
                if (!offer.isActive)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 2,
                        ),
                      ),
                      child: const Text(
                        'ÉPUISÉ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                // Contenu principal
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête avec logo
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white.withValues(alpha: 0.9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.celebration_rounded,
                              size: 22,
                              color: selectedGradient[0],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  offer.description ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 10,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Barre de séparation
                      Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.6),
                              Colors.white.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Points requis
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              child: Icon(
                                Icons.stars_rounded,
                                color: Colors.amber.shade200,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${offer.pointsRequired}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              l10n?.points ?? 'pts',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }

  // Fonction helper pour formater la date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Fonction pour afficher les détails du reward
  void _showRewardDetails(RewardEntity offer) {
    // TODO: Implémenter la navigation vers les détails du reward
  }

  double _calculateDistance(Position? currentPosition, StoreEntity? shop) {
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
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: const Icon(Icons.store_rounded, color: Colors.white, size: 36),
    );
  }

  Widget _buildErrorState(Object error, StackTrace? stack, bool isDarkMode) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load offers',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
      );

  Widget _buildEmptyState(bool isDarkMode) {
    final l10n = AppLocalizations.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            l10n?.nooffre ?? 'No offers available',
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
              // ✅ FIX: Wrappez le texte dans Expanded pour éviter l'overflow
              Expanded(
                child: Text(
                  l10n?.offredisponible ?? 'Offres disponibles',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              // Badge du nombre d'offres
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
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
