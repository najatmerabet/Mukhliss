/// ============================================================
/// Loading States Widgets - Presentation Layer
/// ============================================================
///
/// Widgets pour afficher les différents états de chargement.
/// Extrait de shop_details_bottom_sheet.dart pour respecter SRP.
library;

import 'package:flutter/material.dart';
import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer pour le chargement des cartes
class ShimmerCardPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final bool isDarkMode;

  const ShimmerCardPlaceholder({
    super.key,
    this.width = 200,
    this.height = 120,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Liste de shimmer pour le chargement
class ShimmerLoadingList extends StatelessWidget {
  final int count;
  final bool isDarkMode;
  final Axis scrollDirection;

  const ShimmerLoadingList({
    super.key,
    this.count = 3,
    this.isDarkMode = false,
    this.scrollDirection = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    if (scrollDirection == Axis.horizontal) {
      return SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: count,
          itemBuilder:
              (context, index) =>
                  ShimmerCardPlaceholder(isDarkMode: isDarkMode),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder:
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerCardPlaceholder(
              width: double.infinity,
              height: 80,
              isDarkMode: isDarkMode,
            ),
          ),
    );
  }
}

/// État d'erreur générique
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isDarkMode;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.message = 'Une erreur est survenue',
    this.onRetry,
    this.isDarkMode = false,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isDarkMode ? Colors.white38 : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// État vide générique
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final bool isDarkMode;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    this.message = 'Aucun élément',
    this.subtitle,
    this.isDarkMode = false,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isDarkMode ? Colors.white38 : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// État de premier chargement (loading initial)
class FirstLoadState extends StatelessWidget {
  final bool isDarkMode;
  final String message;

  const FirstLoadState({
    super.key,
    this.isDarkMode = false,
    this.message = 'Chargement...',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ShimmerLoadingList(
        count: 3,
        isDarkMode: isDarkMode,
        scrollDirection: Axis.horizontal,
      ),
    );
  }
}

/// État de pas d'internet
class NoInternetStateWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final bool isDarkMode;

  const NoInternetStateWidget({
    super.key,
    this.onRetry,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pas de connexion',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vérifiez votre connexion internet',
                  style: TextStyle(
                    color:
                        isDarkMode ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: Icon(
                Icons.refresh,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
