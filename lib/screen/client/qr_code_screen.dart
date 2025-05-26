// lib/screens/qr_code_screen.dart
import 'package:flutter/material.dart';
import 'package:mukhliss/widgets/cards/info_card.dart';
import 'package:mukhliss/theme/app_theme.dart';

class QRCodeScreen extends StatelessWidget {
  const QRCodeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
            SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
              ),
            ),
            title: const Text(
              'Mon Identification',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
     
     
     
     
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Carte QR Code principale
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFF8FAFC)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // QR Code simulé
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Motif QR Code simulé
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 8,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2,
                                  ),
                                  itemBuilder: (context, index) {
                                    final isColored = (index % 3 == 0) || (index % 5 == 0) || (index % 7 == 0);
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: isColored ? AppColors.textPrimary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    );
                                  },
                                  itemCount: 64,
                                ),
                              ),
                              // Logo au centre
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'John Doe',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ID: #MUK-2024-001',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Montrez ce QR code pour bénéficier de vos offres',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Informations du compte
                  Row(
                    children: [
                      Expanded(
                        child: InfoCard(value:'1,270',label: 'Points Totaux',icon: Icons.stars,color: AppColors.warning),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InfoCard(value: '15',label:  'Offres Utilisées',icon:  Icons.local_offer,color:  AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InfoCard(value: 'Premium',label:  'Statut',icon:  Icons.workspace_premium,color:  AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InfoCard(value: '8',label:  'Magasins Visités',icon:  Icons.store,color:  AppColors.accent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}