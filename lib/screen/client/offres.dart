import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mukhliss/l10n/l10n.dart';
import 'package:mukhliss/models/clientoffre.dart';
import 'package:mukhliss/models/rewards.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/providers/clientoffre_provider.dart';
import 'package:mukhliss/providers/rewards_provider.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/widgets/Appbar/app_bar_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyOffersScreen extends ConsumerWidget  {
   MyOffersScreen({Key? key}) : super(key: key);
 

  @override
  Widget build(BuildContext context , WidgetRef ref) {
     final l10n = AppLocalizations.of(context);
     final themeMode = ref.watch(themeProvider);
      final isDarkMode = themeMode == AppThemeMode.light;
    final clientAsync = ref.watch(authProvider).currentUser;
        final clientoffreAsync = ref.watch(
             clientAsync?.id != null
               ? clientOffresProvider(clientAsync!.id)
                : FutureProvider((ref) => Future.value([])),
                   );
    
    // provider des recompences
    final rewardsAsync = ref.watch(recentRewardsProvider);
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.surface,
      body: CustomScrollView(
        slivers: [
         AppBarTypes.offersAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child:Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    
    
    // Le reste du contenu (scrollable via le parent CustomScrollView)
    rewardsAsync.when(
      data: (rewards) => rewards.isNotEmpty ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.offredisponible ?? 'Offres Disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.surface : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...rewards.map((offer) => _buildOfferCard(offer, context, ref)),
        ],
      ) : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
    ),
    
    const SizedBox(height: 24),
    
    clientoffreAsync.when(
      data: (clientoffre) => clientoffre.isNotEmpty ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            l10n?.offreutilise ?? 'Offres Utilisées',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.surface : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...clientoffre.map((offer) => _buildOfferCardutilise(offer, context)),
        ],
      ) : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
    ),
  ],
),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildLoadingStatCard() {
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
    child: const Center(
      child: CircularProgressIndicator(),
    ),
  );
}

Widget _buildErrorStatCard(dynamic error) {
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
    child: Center(
      child: Text(
        'Erreur\n${error.toString()}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
    ),
  );
}
  
Widget _buildStatCardPulse(String value, String label, IconData icon, Color color) {
  return Container(
    width: 160,
    height: 180, // Add explicit height constraint
    padding: const EdgeInsets.all(16), // Reduced padding
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Colors.grey.shade50,
          color.withOpacity(0.03),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: color.withOpacity(0.12),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Better spacing
      children: [
        // Conteneur pour l'icône avec effet de pulsation
        Flexible( // Use Flexible instead of SizedBox
          flex: 3,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 70), // Constrain height
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cercle de pulsation
                Container(
                  width: 50, // Reduced size
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                ),
                
                // Container principal de l'icône
                Container(
                  width: 40, // Reduced size
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.15),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20, // Reduced size
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Valeur avec effet métallique
        Flexible( // Use Flexible instead of SizedBox
          flex: 2,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 40), // Constrain height
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.grey.shade100,
                      Colors.white,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.8),
                      color,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18, // Explicit font size
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Label
        Flexible( // Use Flexible for label too
          flex: 1,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10, // Reduced font size
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
  
Widget _buildOfferCard(Rewards offer, BuildContext context , WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
     final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.light;
  return Container(
    margin: const EdgeInsets.only(bottom: 24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDarkMode ? [
          AppColors.darkSurface,
          AppColors.darkGrey50,
          Colors.blue.shade50.withOpacity(0.3),
        ] : [
          AppColors.surface,
           Colors.grey.shade50,
          Colors.blue.shade50.withOpacity(0.3),
        ],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 32,
          offset: const Offset(0, 16),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.blue.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ],
    ),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // Effet de brillance en arrière-plan
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.blue.shade200.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // Badge "Nouveau" avec animation
        if (_isNewOffer(offer.created_at))
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade400,
                    Colors.deepOrange.shade500,
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flash_on_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n?.neww ?? 'NOUVEAU',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        Padding(
          padding: EdgeInsets.only(
            left: 28,
            right: 28,
            bottom: 28,
            top: _isNewOffer(offer.created_at) ? 60 : 28, // Plus d'espace si badge "Nouveau"
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête moderne avec logo et informations
              Row(
                children: [
                  // Logo du magasin avec effet glassmorphisme
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.4),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 64,
                        height: 64,
                        child: offer.magasin.logoUrl != null
                            ? Image.network(
                                offer.magasin.logoUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackLogo(),
                              )
                            : _buildFallbackLogo(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // Informations du magasin avec typography moderne
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge magasin
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${l10n?.chez ?? 'Chez '} ${offer.magasin.nom_enseigne}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Nom de l'offre
                        Text(
                          '  ${offer.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        
                        // Points requis avec icône
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.stars_rounded,
                                color: Colors.amber.shade600,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${l10n?.partirede ?? 'À partir de'} ${offer.points_required} ${l10n?.points ?? 'points'}',
                              style: TextStyle(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Description avec design carte moderne
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.blue.shade50.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de la description
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.2),
                                AppColors.primary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_offer_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                              l10n?.detailsoffre ??  'Détails de l\'offre',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                              l10n?.profitez ??  'Profitez de cette opportunité',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      offer.description ?? 'Profitez de cette offre exclusive disponible dès maintenant !',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Informations en bas avec design moderne
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date avec style moderne
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(offer.created_at, context),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Statut avec design premium
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: offer.is_active 
                                  ? [Colors.green.shade400, Colors.green.shade500]
                                  : [Colors.grey.shade400, Colors.grey.shade500],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (offer.is_active ? Colors.green : Colors.grey)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                offer.is_active ? l10n?.active ?? 'Active' : 'Expirée',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
              
             
              
              
             
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildOfferCardutilise(ClientOffre offer, BuildContext context) {
     final l10n = AppLocalizations.of(context);
  return Container(
    margin: const EdgeInsets.only(bottom: 24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey.shade300,
          Colors.grey.shade400,
          Colors.grey.shade500.withOpacity(0.9),
        ],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ],
    ),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // Badge "Utilisé" en overlay
        Positioned(
          top: -8,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade600,
                  Colors.red.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n?.utilise ?? 'UTILISÉ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Effet de rayures diagonales pour montrer l'utilisation
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                ],
                stops: [0.0, 0.25, 0.5, 0.75],
              ),
            ),
          ),
        ),
        
        Padding(
          padding: EdgeInsets.only(
            left: 28,
            right: 28,
            bottom: 28,
            top: _isNewOffer(offer.created_at) ? 60 : 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec logo désaturé
              Row(
                children: [
                  // Logo du magasin avec effet désaturé
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade600.withOpacity(0.8),
                          Colors.grey.shade700.withOpacity(0.6),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.grey.shade500.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 64,
                        height: 64,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.grey.shade400,
                            BlendMode.saturation,
                          ),
                          child: offer.reward.magasin.logoUrl != null
                              ? Image.network(
                                  offer.reward.magasin.logoUrl!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackLogo(),
                                )
                              : _buildFallbackLogo(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // Informations du magasin avec couleurs sombres
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge magasin avec style sombre
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.shade500.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${l10n?.chez ?? 'Chez '} ${offer.reward.magasin.nom_enseigne} ${l10n?.beneicier ?? 'vous avez bénéficié de '} ',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Nom de l'offre avec effet barré
                        Stack(
                          children: [
                            Text(
                              '  ${offer.reward.name}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppColors.surface,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Ligne barrée pour montrer l'utilisation
                            Positioned(
                              top: 12,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2,
                                color: AppColors.error
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        // Points requis avec icône désaturée
                        Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), 
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade600.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.stars_rounded,
                                  color:AppColors.surface,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Description avec design carte sombre
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade500.withOpacity(0.8),
                      Colors.grey.shade600.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade400.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de la description avec icône sombre
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade400.withOpacity(0.4),
                                Colors.grey.shade500.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_offer_rounded,
                            color: AppColors.surface,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.offreutilise ?? 'Offre utilisée',
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                l10n?.consomeoffre ?? 'Cette offre a déjà été consommée',
                                style: TextStyle(
                                  color: AppColors.surface,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description avec opacité réduite
                    Opacity(
                      opacity: 0.7,
                      child: Text(
                        offer.reward.description ?? 'Cette offre exclusive a été utilisée avec succès !',
                        style:  TextStyle(
                          color:AppColors.surface,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Informations en bas avec design sombre
                 Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        constraints: BoxConstraints(maxWidth: 250), // Add max width constraint
        decoration: BoxDecoration(
          color: Colors.grey.shade400.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade400.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              color:AppColors.surface ,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
  DateFormat('dd/MM/yyyy').format(offer.created_at), // Format jour/mois/année
  style: TextStyle(
    color: AppColors.surface,
    fontSize: 10,
    fontWeight: FontWeight.w500,
  ),
  overflow: TextOverflow.ellipsis,
),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(width: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade600.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade400.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.green.shade400,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            l10n?.consomme ?? 'Consommé',
            style: TextStyle(
              color: Colors.green.shade400,
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
            ],
          ),
        ),
      ],
    ),
  );
}

// Widget pour le logo de fallback
Widget _buildFallbackLogo() {
  return Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.2),
          AppColors.primary.withOpacity(0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Icon(
      Icons.store_rounded,
      color: AppColors.primary,
      size: 32,
    ),
  );
}

// Widget de logo de fallback


// Méthode pour vérifier si l'offre est nouvelle (moins de 7 jours)
bool _isNewOffer(DateTime createdAt) {
  final now = DateTime.now();
  final difference = now.difference(createdAt).inDays;
  return difference <= 7;
}

// Méthode pour formater la date
String _formatDate(DateTime date , BuildContext context) {
    final l10n = AppLocalizations.of(context);
  final now = DateTime.now();
  final difference = now.difference(date).inDays;
  
  if (difference == 0) {
    return l10n?.aujour ?? 'aujourd\'hui';
  } else if (difference == 1) {
    return l10n?.hier ?? 'hier';
  } else if (difference < 7) {
    return 'il y a $difference jours';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}




}