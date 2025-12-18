/// ============================================================
/// Shop Details Widgets - Widgets extraits du ShopDetailsBottomSheet
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ============================================================
// WIDGETS D'ÉTAT (Loading, Error, Empty)
// ============================================================

/// Widget de ligne d'information
class ShopInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool isDarkMode;

  const ShopInfoRow({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
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
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de chargement
class ShopLoadingRow extends StatelessWidget {
  final bool isDarkMode;

  const ShopLoadingRow({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: Text(
              'Chargement...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget d'erreur
class ShopErrorRow extends StatelessWidget {
  final bool isDarkMode;

  const ShopErrorRow({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
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
}

/// Widget pas de connexion internet
class ShopNoInternetRow extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onRetry;

  const ShopNoInternetRow({
    super.key,
    required this.isDarkMode,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.orange.shade900 : Colors.orange.shade100,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pas de connexion',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vérifiez votre connexion internet',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                backgroundColor:
                    isDarkMode
                        ? Colors.orange.shade900.withValues(alpha: 0.3)
                        : Colors.orange.shade50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget shimmer placeholder
class ShopShimmerPlaceholder extends StatelessWidget {
  const ShopShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget état vide
class ShopEmptyState extends StatelessWidget {
  final bool isDarkMode;

  const ShopEmptyState({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_mall_directory_outlined,
              size: 64,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sélectionnez un magasin',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget état d'erreur complet
class ShopErrorState extends StatelessWidget {
  final Object error;
  final bool isDarkMode;
  final VoidCallback? onRetry;

  const ShopErrorState({
    super.key,
    required this.error,
    required this.isDarkMode,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CARD GRADIENT (pour les récompenses)
// ============================================================

/// Palette de dégradés colorés
const List<List<Color>> rewardGradients = [
  [Color(0xFF667eea), Color(0xFF764ba2)], // Violet-Purple
  [Color(0xFFf093fb), Color(0xFFF5576c)], // Rose-Rouge
  [Color(0xFF4facfe), Color(0xFF00f2fe)], // Bleu clair
  [Color(0xFF43e97b), Color(0xFF38f9d7)], // Vert-Cyan
  [Color(0xFFfa709a), Color(0xFFfee140)], // Rose-Jaune
  [Color(0xFFff9a56), Color(0xFFff6a88)], // Orange-Coral
  [Color(0xFF30cfd0), Color(0xFF330867)], // Cyan-Violet foncé
  [Color(0xFFa8edea), Color(0xFFfed6e3)], // Pastel multicolore
];

/// Formater une date
String formatRewardDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

/// Widget placeholder pour logo
class ShopLogoPlaceholder extends StatelessWidget {
  const ShopLogoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.store_mall_directory_outlined,
        color: Colors.grey[400],
        size: 30,
      ),
    );
  }
}
