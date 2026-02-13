import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/features/stores/domain/entities/category_entity.dart';

import 'package:mukhliss/features/stores/domain/entities/store_entity.dart';
import 'package:mukhliss/features/stores/presentation/providers/stores_provider.dart';
import 'package:mukhliss/core/providers/auth_provider.dart';
import 'package:mukhliss/features/stores/presentation/providers/categories_provider.dart';
import 'package:mukhliss/features/stores/presentation/providers/clientmagazin_provider.dart';
import 'package:mukhliss/core/providers/langue_provider.dart';
import 'package:mukhliss/core/providers/theme_provider.dart';

import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/core/utils/geticategoriesbyicon.dart';
import 'package:tuple/tuple.dart';

class CategoryEntityBottomSheet extends ConsumerStatefulWidget {
  final CategoryEntity? initialCategory;
  final Position? currentPosition;
  final List<StoreEntity>? searchResults;
  final MapController mapController;
  final GlobalKey<NavigatorState> navigatorKey;
  final Function(StoreEntity?, CategoryEntity?)? onStoreEntitySelected;
  final Function(CategoryEntity?, StoreEntity?) onCategorySelected;
  final VoidCallback onClose;
  final bool isMinimized;
  // Nouveau paramètre
  const CategoryEntityBottomSheet({
    super.key,
    required this.initialCategory,
    required this.currentPosition,
    required this.mapController,
    required this.navigatorKey,
    required this.onStoreEntitySelected,
    this.searchResults,
    required this.onCategorySelected,
    required this.onClose,
    this.isMinimized = false, // Par défaut, non minimisé
  });

  @override
  ConsumerState<CategoryEntityBottomSheet> createState() =>
      _CategoryEntityBottomSheetState();
}

class _CategoryEntityBottomSheetState
    extends ConsumerState<CategoryEntityBottomSheet>
    with TickerProviderStateMixin {
  final int _storesPerPage = 5;
  int _visibleStoreEntitysCount = 5;
  final ScrollController _scrollController = ScrollController();
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  CategoryEntity? _selectedCategory;
  bool _hasAddedDragListener = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreStoreEntitys);
    _selectedCategory = widget.initialCategory;
  }

  void _onDragChanged() {
    if (_draggableController.size <= 0.12) {
      widget.onClose();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_hasAddedDragListener) {
      _draggableController.removeListener(_onDragChanged);
    }
    super.dispose();
  }

  void _loadMoreStoreEntitys() {
    // Pagination not supported with FutureProvider
    // final storesNotifier = ref.read(storesProvider);

    // if (_scrollController.position.pixels >=
    //         _scrollController.position.maxScrollExtent -
    //             100 && // 100px avant la fin
    //     !storesNotifier.isLoadingMore &&
    //     storesNotifier.hasMore) {
    //   // storesNotifier.loadMoreStoreEntitys();
    // }
  }

  void _refreshStoreEntityPoints(StoreEntity store) {
    final clientId = ref.watch(currentClientIdProvider);
    if (clientId != null) {
      // Invalider le cache pour forcer le rechargement
      ref.invalidate(clientMagazinPointsProvider(Tuple2(clientId, store.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(languageProvider);

    final isDarkMode = themeMode == AppThemeMode.dark;
    return DraggableScrollableSheet(
      controller: _draggableController,
      initialChildSize: widget.isMinimized ? 0.3 : 0.5,
      minChildSize: 0.1, // Réduire à 0.1 pour permettre de fermer
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.1, 0.3, 0.5, 0.9], // Ajouter 0.1 pour fermer
      builder: (context, scrollController) {
        // Ajouter listener une seule fois
        if (!_hasAddedDragListener) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasAddedDragListener) {
              _draggableController.addListener(_onDragChanged);
              _hasAddedDragListener = true;
            }
          });
        }
        
        return Material(
          color: isDarkMode ? const Color(0xFF0A0E27) : AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: CustomScrollView(
            controller: scrollController, // IMPORTANT: utiliser scrollController du builder!
            slivers: [
              // Handle du BottomSheet - Zone de drag agrandie
              SliverToBoxAdapter(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    // Faire glisser le sheet manuellement
                    final delta = details.primaryDelta ?? 0;
                    final newSize = _draggableController.size - (delta / MediaQuery.of(context).size.height);
                    if (newSize >= 0.1 && newSize <= 0.9) {
                      _draggableController.jumpTo(newSize);
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
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
              ),

              // Titre
       SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    child: Row(
      children: [
        // Flèche retour ← qui ferme le BottomSheet
        IconButton(
          onPressed: widget.onClose,
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? AppColors.surface : AppColors.textPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          l10n?.categories ?? 'Mes Catégories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.surface : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  ),
),

              // Liste HORIZONTALE des catégories - MULTILINGUE - FIXED VERSION
              Consumer(
                builder: (context, ref, child) {
                  final categoriesAsync = ref.watch(categoriesProvider);

                  return SliverToBoxAdapter(
                    child: categoriesAsync.when(
                      data: (categories) {
                        return SizedBox(
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
                                  iconcolor: AppColors.lightPrimary,
                                  isSelected: _selectedCategory?.id == null,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = null;
                                      _visibleStoreEntitysCount =
                                          _storesPerPage; // Réinitialiser le compteur
                                    });
                                    widget.onCategorySelected(null, null);
                                  },
                                ),
                              ),

                              // Autres catégories - AVEC TRADUCTION
                              ...categories.map((category) {
                                final isSelected =
                                    _selectedCategory?.id == category.id;
                                // UTILISATION DE LA MÉTHODE MULTILINGUE
                                final localizedName = category.getName(
                                  currentLocale.languageCode,
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildHorizontalCategoryItem(
                                    context: context,
                                    icon: CategoryMarkers.getPinIcon(
                                      category.name,
                                    ), // Utilise le nom par défaut pour l'icône
                                    title:
                                        localizedName, // AFFICHE LE NOM TRADUIT
                                    isSelected: isSelected,
                                    isDarkMode: isDarkMode,
                                    iconcolor: CategoryMarkers.getPinColor(
                                      category.name,
                                    ), // Utilise le nom par défaut pour la couleur
                                    onTap: () {
                                      final entity = CategoryEntity(
                                        id: category.id,
                                        name: category.name,
                                        nameFr: category.nameFr,
                                        nameAr: category.nameAr,
                                        nameEn: category.nameEn,
                                      );
                                      setState(() {
                                        _selectedCategory = entity;
                                        _visibleStoreEntitysCount =
                                            _storesPerPage; // Réinitialiser le compteur
                                      });
                                      widget.onCategorySelected(entity, null);
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                      loading:
                          () => SizedBox(
                            height: 120,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      error:
                          (error, stack) => SizedBox(
                            height: 120,
                            child: Center(
                              child: Text(
                                'Erreur: $error',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? AppColors.surface
                                          : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                    ),
                  );
                },
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
                        color:
                            isDarkMode
                                ? AppColors.surface
                                : AppColors.darkSurface,
                      ),
                    ),
                  ),
                ),
              ),

              // Liste des magasins
              Consumer(
                builder: (context, ref, child) {
                  if (widget.searchResults?.isNotEmpty == true) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final store = widget.searchResults![index];
                        final distance =
                            widget.currentPosition != null
                                ? Geolocator.distanceBetween(
                                  widget.currentPosition!.latitude,
                                  widget.currentPosition!.longitude,
                                  store.latitude,
                                  store.longitude,
                                )
                                : 0.0;

                        return _buildStoreEntityItem(
                          context: context,
                          store: store,
                          distance: distance,
                          isDarkMode: isDarkMode,
                          currentPosition: widget.currentPosition,
                          onStoreSelected: widget.onStoreEntitySelected,
                        );
                      }, childCount: widget.searchResults?.length ?? 0),
                    );
                  }

                  final storesAsync = ref.watch(storesProvider);
                  return storesAsync.when(
                    data: (stores) {
                      List<StoreEntity> filteredStoreEntitys = stores;
                      if (widget.initialCategory != null) {
                        filteredStoreEntitys =
                            stores
                                .where(
                                  (store) =>
                                      store.categoryId ==
                                      widget.initialCategory!.id.toString(),
                                )
                                .toList();
                      }

                      filteredStoreEntitys.sort((a, b) {
                        if (widget.currentPosition == null) return 0;
                        final distanceA = Geolocator.distanceBetween(
                          widget.currentPosition!.latitude,
                          widget.currentPosition!.longitude,
                          a.latitude,
                          a.longitude,
                        );
                        final distanceB = Geolocator.distanceBetween(
                          widget.currentPosition!.latitude,
                          widget.currentPosition!.longitude,
                          b.latitude,
                          b.longitude,
                        );
                        return distanceA.compareTo(distanceB);
                      });
                      // final storesNotifier = ref.read(storesProvider.notifier);
                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          // Check bounds
                          if (index >= filteredStoreEntitys.length) {
                            return SizedBox.shrink();
                          }

                          final store = filteredStoreEntitys[index];
                          final distance =
                              widget.currentPosition != null
                                  ? Geolocator.distanceBetween(
                                    widget.currentPosition!.latitude,
                                    widget.currentPosition!.longitude,
                                    store.latitude,
                                    store.longitude,
                                  )
                                  : 0.0;

                          return _buildStoreEntityItem(
                            context: context,
                            store: store,
                            distance: distance,
                            isDarkMode: isDarkMode,
                            currentPosition: widget.currentPosition,
                            onStoreSelected: widget.onStoreEntitySelected,
                          );
                        }, childCount: filteredStoreEntitys.length),
                      );
                    },
                    loading:
                        () => SliverToBoxAdapter(
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    error:
                        (error, stack) => SliverToBoxAdapter(
                          child: Center(child: Text('Erreur: $error')),
                        ),
                  );
                },
              ),

              // Espacement en bas
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 20,
                ),
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
                color: isSelected ? AppColors.primary : iconcolor,
                width: 1.5,
              ),
              color:
                  isSelected
                      ? const Color.fromARGB(255, 234, 234, 247)
                      : Colors.white,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  28,
                ), // Moitié de la hauteur pour un cercle parfait
                onTap: () {
                  onTap(); // Appel du callback parent
                  setState(() {}); // Force le rebuild pour mettre à jour l'UI
                },
                child: Center(
                  child:
                      icon != null
                          ? Icon(
                            icon,
                            size: 30,
                            color: isSelected ? AppColors.primary : iconcolor,
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
              color:
                  isDarkMode
                      ? (isSelected ? AppColors.primary : Colors.white)
                      : (isSelected ? AppColors.primary : Colors.grey.shade800),
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
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreEntityItem({
    required BuildContext context,
    required StoreEntity store,
    required double distance,
    required bool isDarkMode,
    required Position? currentPosition,
    final Function(StoreEntity?, CategoryEntity?)? onStoreSelected,
  }) {
    final clientId = ref.watch(currentClientIdProvider);
    final pointsAsync = ref.watch(
      clientMagazinPointsProvider(Tuple2(clientId, store.id)),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF0A0E27) : AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _refreshStoreEntityPoints(
              store,
            ); // Rafraîchir les points avant de sélectionner le magasin

            if (onStoreSelected != null) {
              onStoreSelected(store, _selectedCategory);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Logo du magasin
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color:
                        isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        store.logoUrl != null && store.logoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: store.logoUrl!,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => _buildPlaceholderIcon(),
                              errorWidget:
                                  (context, url, error) =>
                                      _buildPlaceholderIcon(),
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
                        store.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isDarkMode
                                  ? AppColors.surface
                                  : AppColors.textPrimary,
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
                            color:
                                isDarkMode
                                    ? AppColors.surface
                                    : AppColors.textPrimary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              store.address ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDarkMode
                                        ? AppColors.surface
                                        : AppColors.textPrimary,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? Colors.blue.shade900.withValues(
                                        alpha: 0.2,
                                      )
                                      : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? Colors.blue.shade700
                                        : Colors.blue.shade200,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons
                                      .near_me_outlined, // Icône de localisation/distance
                                  size: 14,
                                  color:
                                      isDarkMode
                                          ? Colors.blue.shade200
                                          : Colors.blue.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  distance < 1000
                                      ? '${distance.toStringAsFixed(0)}m'
                                      : '${(distance / 1000).toStringAsFixed(1)}km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDarkMode
                                            ? Colors.blue.shade200
                                            : Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Espace augmenté entre les badges (passé de 8 à 12)
                          const SizedBox(width: 50),

                          // Badge de points
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? Colors.green.shade900.withValues(
                                        alpha: 0.2,
                                      )
                                      : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? Colors.green.shade700
                                        : Colors.green.shade200,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 14,
                                  color:
                                      isDarkMode
                                          ? Colors.green.shade200
                                          : Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                pointsAsync.when(
                                  data:
                                      (data) => Text(
                                        '${data?.cumulpoint ?? 0} pts',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDarkMode
                                                  ? Colors.green.shade200
                                                  : Colors.green.shade700,
                                        ),
                                      ),
                                  error:
                                      (_, __) => Text(
                                        '0 pts',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDarkMode
                                                  ? Colors.green.shade200
                                                  : Colors.green.shade700,
                                        ),
                                      ),
                                  loading:
                                      () => const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
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
            ),
          ),
        ),
      ),
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
}
