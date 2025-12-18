/// ============================================================
/// Offer Card Widget - Presentation Layer
/// ============================================================
///
/// Widget réutilisable pour afficher une offre.
library;

import 'package:flutter/material.dart';
import '../../domain/entities/offer_entity.dart';

/// Carte d'affichage d'une offre
class OfferCard extends StatelessWidget {
  final OfferEntity offer;
  final VoidCallback? onTap;
  final bool showStore;

  const OfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.showStore = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône points
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${offer.pointsGiven.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'pts',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Détails
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gagnez ${offer.pointsGiven.toInt()} points',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pour ${offer.minAmount.toStringAsFixed(2)} DH d\'achat',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Badge actif
              if (offer.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Actif',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Liste d'offres
class OffersList extends StatelessWidget {
  final List<OfferEntity> offers;
  final void Function(OfferEntity)? onOfferTap;
  final Widget? emptyWidget;

  const OffersList({
    super.key,
    required this.offers,
    this.onOfferTap,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return emptyWidget ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Aucune offre disponible',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return OfferCard(
          offer: offer,
          onTap: onOfferTap != null ? () => onOfferTap!(offer) : null,
        );
      },
    );
  }
}
