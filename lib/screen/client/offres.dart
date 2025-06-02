import 'package:flutter/material.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/widgets/Appbar/app_bar_types.dart';

class MyOffersScreen extends StatelessWidget {
   MyOffersScreen({Key? key}) : super(key: key);
  final List<Map<String, dynamic>> receivedOffers = [
    {
      'title': 'Réduction Été 2024',
      'store': 'SuperMart Plus',
      'discount': '50% OFF',
      'description': 'Sur tous les produits électroniques',
      'validUntil': '31 Juillet 2024',
      'status': 'En cours',
      'color': AppColors.success,
      'icon': Icons.wb_sunny,
      'used': false,
    },
    {
      'title': 'Cadeau Gratuit',
      'store': 'Fashion Store',
      'discount': 'GRATUIT',
      'description': 'T-shirt gratuit pour tout achat > 100€',
      'validUntil': '15 Août 2024',
      'status': 'Disponible',
      'color': AppColors.warning,
      'icon': Icons.card_giftcard,
      'used': false,
    },
    {
      'title': 'Loyalty Bonus',
      'store': 'Tech World',
      'discount': '25% OFF',
      'description': 'Réduction sur accessoires smartphone',
      'validUntil': '20 Juin 2024',
      'status': 'Utilisée',
      'color': AppColors.textSecondary,
      'icon': Icons.loyalty,
      'used': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeOffers = receivedOffers.where((offer) => !offer['used']).toList();
    final usedOffers = receivedOffers.where((offer) => offer['used']).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
         AppBarTypes.offersAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistiques des offres
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          activeOffers.length.toString(),
                          'Offres Actives',
                          Icons.local_offer,
                          AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          usedOffers.length.toString(),
                          'Offres Utilisées',
                          Icons.check_circle,
                          AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Offres en cours
                  if (activeOffers.isNotEmpty) ...[
                    const Text(
                      'Offres Disponibles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...activeOffers.map((offer) => _buildOfferCard(offer, context)),
                  ],
                  const SizedBox(height: 24),
                  // Offres utilisées
                  if (usedOffers.isNotEmpty) ...[
                    const Text(
                      'Offres Utilisées',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...usedOffers.map((offer) => _buildOfferCard(offer, context)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: offer['color'].withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        offer['color'].withOpacity(0.1),
                        offer['color'].withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    offer['icon'],
                    color: offer['color'],
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: offer['used'] ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer['store'],
                        style: TextStyle(
                          color: offer['used'] ? AppColors.textSecondary : AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: offer['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    offer['discount'],
                    style: TextStyle(
                      color: offer['color'],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer['description'],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Valide jusqu\'au ${offer['validUntil']}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: offer['used'] 
                              ? AppColors.textSecondary.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          offer['status'],
                          style: TextStyle(
                            color: offer['used'] ? AppColors.textSecondary : AppColors.success,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!offer['used']) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Offre "${offer['title']}" utilisée !'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: offer['color'],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Utiliser cette offre',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}