/// ============================================================
/// Reward Card Widget - Presentation Layer
/// ============================================================
///
/// Carte affichant une récompense avec style moderne.
/// Extrait de shop_details_bottom_sheet.dart pour respecter SRP.
library;

import 'package:flutter/material.dart';
import 'package:mukhliss/features/rewards/domain/entities/reward_entity.dart';
import 'package:mukhliss/l10n/app_localizations.dart';

/// Palette de dégradés colorés pour les cartes
class RewardCardGradients {
  static const List<List<Color>> gradients = [
    [Color(0xFF667eea), Color(0xFF764ba2)], // Violet-Purple
    [Color(0xFFf093fb), Color(0xFFF5576c)], // Rose-Rouge
    [Color(0xFF4facfe), Color(0xFF00f2fe)], // Bleu clair
    [Color(0xFF43e97b), Color(0xFF38f9d7)], // Vert-Cyan
    [Color(0xFFfa709a), Color(0xFFfee140)], // Rose-Jaune
    [Color(0xFFff9a56), Color(0xFFff6a88)], // Orange-Coral
    [Color(0xFF30cfd0), Color(0xFF330867)], // Cyan-Violet foncé
    [Color(0xFFa8edea), Color(0xFFfed6e3)], // Pastel multicolore
  ];

  static List<Color> getGradient(int index) {
    return gradients[index % gradients.length];
  }
}

/// Widget carte de récompense style "credit card"
class RewardCreditCard extends StatelessWidget {
  final RewardEntity reward;
  final int index;
  final bool isDarkMode;
  final VoidCallback? onTap;

  const RewardCreditCard({
    super.key,
    required this.reward,
    required this.index,
    required this.isDarkMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gradient = RewardCardGradients.getGradient(index);

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.only(bottom: 60),
      child: _buildCard(gradient, l10n),
    );
  }

  Widget _buildCard(List<Color> gradient, AppLocalizations? l10n) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: gradient[1].withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: reward.isActive ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Cercles décoratifs
              _buildDecorativeCircle(
                bottom: -20,
                left: -20,
                size: 80,
                opacity: 0.15,
              ),
              _buildDecorativeCircle(
                top: -15,
                right: -15,
                size: 60,
                opacity: 0.1,
              ),
              _buildDecorativeCircle(
                top: 40,
                right: 15,
                size: 25,
                opacity: 0.2,
              ),

              // Badge épuisé
              if (!reward.isActive) _buildExhaustedBadge(l10n),

              // Contenu principal
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildRewardName(),
                    const Spacer(),
                    _buildFooter(l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }

  Widget _buildExhaustedBadge(AppLocalizations? l10n) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              l10n?.inactifs ?? 'Épuisé',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Icône cadeau
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.card_giftcard_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        // Badge nouveau
        if (reward.isNew)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'NOUVEAU',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRewardName() {
    return Text(
      reward.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        height: 1.2,
        shadows: [
          Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations? l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Points requis
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stars_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${reward.pointsRequired}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        // Statut
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  reward.isActive
                      ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
                      : [const Color(0xFFeb3349), const Color(0xFFf45c43)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            reward.isActive
                ? (l10n?.disponible ?? 'Disponible')
                : (l10n?.inactifs ?? 'Épuisé'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Liste horizontale de cartes de récompenses
class RewardCardsList extends StatelessWidget {
  final List<RewardEntity> rewards;
  final bool isDarkMode;
  final void Function(RewardEntity)? onRewardTap;

  const RewardCardsList({
    super.key,
    required this.rewards,
    required this.isDarkMode,
    this.onRewardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: rewards.length,
        itemBuilder: (context, index) {
          final reward = rewards[index];
          return RewardCreditCard(
            reward: reward,
            index: index,
            isDarkMode: isDarkMode,
            onTap: onRewardTap != null ? () => onRewardTap!(reward) : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 48,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune récompense',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
