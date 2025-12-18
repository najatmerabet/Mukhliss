/// ============================================================
/// Reward Card Widget - Presentation Layer
/// ============================================================
library;

import 'package:flutter/material.dart';
import '../../domain/entities/reward_entity.dart';

/// Carte d'affichage d'une récompense
class RewardCard extends StatelessWidget {
  final RewardEntity reward;
  final int? clientPoints;
  final VoidCallback? onTap;
  final VoidCallback? onRedeem;

  const RewardCard({
    super.key,
    required this.reward,
    this.clientPoints,
    this.onTap,
    this.onRedeem,
  });

  bool get _canRedeem =>
      clientPoints != null && reward.canRedeem(clientPoints!);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et badge nouveau
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reward.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (reward.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange, Colors.red],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NOUVEAU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  if (reward.description != null)
                    Text(
                      reward.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 12),

                  // Nom du magasin
                  if (reward.storeName != null)
                    Row(
                      children: [
                        Icon(Icons.store, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          reward.storeName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Points requis et bouton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Points requis
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 18,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${reward.pointsRequired} pts',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bouton échanger
                      if (onRedeem != null)
                        ElevatedButton(
                          onPressed: _canRedeem ? onRedeem : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _canRedeem
                                    ? theme.primaryColor
                                    : Colors.grey[300],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            _canRedeem ? 'Échanger' : 'Pts insuffisants',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Badge inactif
            if (!reward.isActive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'INDISPONIBLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Liste de récompenses
class RewardsList extends StatelessWidget {
  final List<RewardEntity> rewards;
  final int? clientPoints;
  final void Function(RewardEntity)? onRewardTap;
  final void Function(RewardEntity)? onRewardRedeem;
  final Widget? emptyWidget;

  const RewardsList({
    super.key,
    required this.rewards,
    this.clientPoints,
    this.onRewardTap,
    this.onRewardRedeem,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return emptyWidget ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Aucune récompense disponible',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        return RewardCard(
          reward: reward,
          clientPoints: clientPoints,
          onTap: onRewardTap != null ? () => onRewardTap!(reward) : null,
          onRedeem:
              onRewardRedeem != null ? () => onRewardRedeem!(reward) : null,
        );
      },
    );
  }
}
