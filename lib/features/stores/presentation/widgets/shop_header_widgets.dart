/// ============================================================
/// Shop Header Widget - Presentation Layer
/// ============================================================
///
/// Widget d'en-tête pour afficher les informations d'un magasin.
/// Extrait de shop_details_bottom_sheet.dart pour respecter SRP.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/core/utils/geticategoriesbyicon.dart';
import 'package:mukhliss/features/stores/domain/entities/store_entity.dart';

/// Widget affichant le logo du magasin avec effet glassmorphism
class ShopLogoWidget extends StatelessWidget {
  final String? logoUrl;
  final double size;

  const ShopLogoWidget({super.key, this.logoUrl, this.size = 85});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child:
            logoUrl != null && logoUrl!.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: logoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildPlaceholder(),
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                )
                : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Icon(
        Icons.store_rounded,
        color: AppColors.primary,
        size: 40,
      ),
    );
  }
}

/// Badge de catégorie avec icône
class CategoryBadge extends StatelessWidget {
  final String categoryName;
  final bool isDarkMode;

  const CategoryBadge({
    super.key,
    required this.categoryName,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CategoryMarkers.getPinIcon(categoryName),
            size: 16,
            color: CategoryMarkers.getPinColor(categoryName),
          ),
          const SizedBox(width: 6),
          Text(
            categoryName,
            style: TextStyle(
              color: isDarkMode ? Colors.white : AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher la distance
class DistanceBadge extends StatelessWidget {
  final String distance;
  final bool isDarkMode;

  const DistanceBadge({
    super.key,
    required this.distance,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.near_me_rounded,
            size: 14,
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            distance,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget ligne d'information (icône + titre + valeur)
class InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool isDarkMode;

  const InfoRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        isDarkMode ? Colors.white54 : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

/// En-tête complet du magasin
class ShopHeader extends StatelessWidget {
  final StoreEntity shop;
  final String? logoUrl;
  final String categoryName;
  final String distance;
  final bool isDarkMode;

  const ShopHeader({
    super.key,
    required this.shop,
    this.logoUrl,
    required this.categoryName,
    required this.distance,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShopLogoWidget(logoUrl: logoUrl),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom du magasin
              Text(
                shop.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Badge catégorie
              CategoryBadge(categoryName: categoryName, isDarkMode: isDarkMode),
              const SizedBox(height: 8),
              // Distance
              DistanceBadge(distance: distance, isDarkMode: isDarkMode),
            ],
          ),
        ),
      ],
    );
  }
}
