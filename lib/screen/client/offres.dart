import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/l10n/l10n.dart';
import 'package:mukhliss/models/clientoffre.dart';
import 'package:mukhliss/models/rewards.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/providers/clientoffre_provider.dart';
import 'package:mukhliss/providers/rewards_provider.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/widgets/Appbar/app_bar_types.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class MyOffersScreen extends ConsumerStatefulWidget   {
   MyOffersScreen({Key? key}) : super(key: key);
 
  @override
  ConsumerState<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends ConsumerState<MyOffersScreen> {
    bool _hasConnection = true;
    StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isCheckingConnectivity = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

Future<void> _checkConnectivity() async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _hasConnection = connectivityResult != ConnectivityResult.none;
        _isCheckingConnectivity = false;
      });
    }

    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) {
        setState(() {
          _hasConnection = result != ConnectivityResult.none;
        });
        // Rafraîchir les données si la connexion revient
        if (_hasConnection) {
          ref.invalidate(clientOffresProvider);
          ref.invalidate(recentRewardsProvider);
        }
      }
    });
  } catch (e) {
    if (mounted) {
      setState(() {
        _hasConnection = false;
        _isCheckingConnectivity = false;
      });
    }
    debugPrint('Erreur de vérification de connectivité: $e');
  }
}

  
  @override
  Widget build(BuildContext context) {
     final l10n = AppLocalizations.of(context);
     final themeMode = ref.watch(themeProvider);
      final isDarkMode = themeMode == AppThemeMode.light;
    final clientAsync = ref.watch(authProvider).currentUser;
        // final clientoffreAsync = ref.watch(
        //      clientAsync?.id != null
        //        ? clientOffresProvider(clientAsync!.id)
        //         : FutureProvider((ref) => Future.value([])),
        //            );
    
    // provider des recompences
    // final rewardsAsync = ref.watch(recentRewardsProvider);
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.surface,
      body: CustomScrollView(
        slivers: [
         AppBarTypes.offersAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildContent(l10n, isDarkMode, clientAsync)
            ),
          ),
        ],
      ),
    );
  }
Widget _buildContent(AppLocalizations? l10n, bool isDarkMode, User? clientAsync) {
  // Vérifier d'abord l'état de la connexion globale
  if (_isCheckingConnectivity) {
    return _buildConnectivityCheckWidget();
  }

  if (!_hasConnection) {
    return Column(
      children: [
        // Section Récompenses sans connexion
        _buildNoConnectionRewardsWidget(l10n, isDarkMode),
        const SizedBox(height: 24),
        // Section Historique sans connexion
        _buildNoConnectionHistoryWidget(l10n, isDarkMode),
      ],
    );
  }
  // Si on a une connexion, afficher le contenu normal
  final clientoffreAsync = ref.watch(
    clientAsync?.id != null
      ? clientOffresProvider(clientAsync!.id)
      : FutureProvider((ref) => Future.value([])),
  );
  
  final rewardsAsync = ref.watch(recentRewardsProvider);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Section des récompenses disponibles
      rewardsAsync.when(
        data: (rewards) => rewards.isNotEmpty 
          ? Column(
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
            )
          : _buildNoRewardsWidget(l10n, isDarkMode, false),
        loading: () => _buildLoadingWidget(),
        error: (error, _) => _buildErrorWidget(error, l10n, isDarkMode, true),
      ),
      
      const SizedBox(height: 24),
      
      // Section des offres utilisées avec gestion spéciale de la connectivité
      clientoffreAsync.when(
        data: (clientoffre) => clientoffre.isNotEmpty 
          ? Column(
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
            )
          : _buildNoRewardsWidget(l10n, isDarkMode, true),
        loading: () => _buildLoadingWidget(),
        error: (error, _) {
          // Vérifier si l'erreur est liée à la connexion
          if (error.toString().contains('no_internet_connection')) {
            return _buildUsedOffersNoConnectionWidget(l10n, isDarkMode);
          }
          return _buildErrorWidget(error, l10n, isDarkMode, false);
        },
      ),
    ],
  );
}

Widget _buildNoConnectionRewardsWidget(AppLocalizations? l10n, bool isDarkMode) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.blue.shade50,
          Colors.blue.shade100.withOpacity(0.5),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.blue.shade200,
        width: 1.5,
      ),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade100.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.emoji_events_rounded,
            size: 40,
            color: Colors.blue.shade600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Récompenses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
       'Une connexion est nécessaire pour afficher vos récompenses disponibles',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _checkConnectivity(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n?.retry ?? 'Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showRewardsConnectionInfoDialog();
                },
                icon: Icon(Icons.help_outline, size: 18, color: Colors.blue.shade600),
                label: Text(l10n?.aide ?? 'Aide'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildNoConnectionHistoryWidget(AppLocalizations? l10n, bool isDarkMode) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.amber.shade50,
          Colors.amber.shade100.withOpacity(0.5),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.amber.shade200,
        width: 1.5,
      ),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade100.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.history_rounded,
            size: 40,
            color: Colors.amber.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
        'Historique',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Connectez-vous pour voir votre historique des récompenses utilisées',
          style: TextStyle(
            fontSize: 14,
            color: Colors.amber.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _checkConnectivity(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n?.retry ?? 'Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showHistoryConnectionInfoDialog();
                },
                icon: Icon(Icons.info_outline, size: 18, color: Colors.amber.shade700),
                label: Text(l10n?.info ?? 'Info'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.amber.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
void _showRewardsConnectionInfoDialog() {
  final l10n = AppLocalizations.of(context);
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.blue),
            const SizedBox(width: 8),
            Text( 'Récompenses'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
            'Pourquoi une connexion est nécessaire ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
            
              '• Vos récompenses sont stockées en ligne\n'
              '• Nous devons vérifier votre solde de points\n'
              '• Cela permet d\'afficher les offres disponibles'),
            const SizedBox(height: 16),
            Text(
               'Que faire ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              
              '• Vérifiez votre connexion Internet\n'
              '• Réessayez plus tard\n'
              '• Contactez le support si le problème persiste'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.compris ?? 'Compris'),
          ),
        ],
      );
    },
  );
}

void _showHistoryConnectionInfoDialog() {
  final l10n = AppLocalizations.of(context);
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.history_rounded, color: Colors.amber),
            const SizedBox(width: 8),
            Text( 'Historique'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
        'Pourquoi une connexion est nécessaire ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
          
              '• Votre historique est synchronisé en ligne\n'
              '• Nous devons accéder à vos données sécurisées\n'
              '• Cela permet de protéger vos informations'),
            const SizedBox(height: 16),
            Text(
            'Que faire ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
             
              '• Vérifiez votre connexion Internet\n'
              '• Réessayez plus tard\n'
              '• Contactez le support si le problème persiste'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.compris ?? 'Compris'),
          ),
        ],
      );
    },
  );
}
// Nouveau widget spécifique pour les offres utilisées sans connexion
Widget _buildUsedOffersNoConnectionWidget(AppLocalizations? l10n, bool isDarkMode) {
  final primaryColor = isDarkMode ? AppColors.error : Colors.orange.shade600;
  final bgColor = isDarkMode 
    ? AppColors.error.withOpacity(0.08) 
    : Colors.orange.shade50.withOpacity(0.7);
  final borderColor = isDarkMode 
    ? AppColors.error.withOpacity(0.3) 
    : Colors.orange.shade200;
  final iconBgColor = isDarkMode 
    ? AppColors.darkGrey50.withOpacity(0.8) 
    : Colors.white;
  final textColor = isDarkMode 
    ? AppColors.surface 
    : AppColors.textPrimary.withOpacity(0.8);

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: borderColor,
        width: 1.5,
      ),
      boxShadow: [
        if (!isDarkMode) ...[
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ] else ...[
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icône avec animation implicite
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.15),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.wifi_off_rounded,
            size: 36,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 28),
        
        // Titre avec meilleure typographie
        Text(
          'Connexion requise',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        // Description avec meilleur contraste
        Text(
          'Votre historique d\'offres nécessite une connexion Internet active pour être consulté.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textColor,
            height: 1.5,
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Boutons redesignés
        Column(
          children: [
            // Bouton principal - Réessayer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkConnectivity,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  l10n?.retry ?? 'Réessayer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Bouton secondaire - Info
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _showConnectionInfoDialog,
                icon: Icon(
                  Icons.info_outline_rounded, 
                  size: 20,
                  color: primaryColor,
                ),
                label: Text(
                  l10n?.info ?? 'Plus d\'informations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                    letterSpacing: 0.1,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
// Dialogue d'information sur la connexion
void _showConnectionInfoDialog() {
  final l10n = AppLocalizations.of(context);
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text( 'Connexion requise'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
             'Pourquoi une connexion est nécessaire ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '• Vos offres utilisées sont stockées en ligne\n'
              '• Nous devons synchroniser vos données\n'
              '• Cela garantit que vos informations sont à jour'),
            const SizedBox(height: 16),
            Text(
               'Que faire ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '• Vérifiez votre connexion WiFi\n'
              '• Activez vos données mobiles\n'
              '• Réessayez dans quelques instants'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.compris ?? 'Compris'),
          ),
        ],
      );
    },
  );
}

Widget _buildNoRewardsWidget(AppLocalizations? l10n, bool isDarkMode, bool isUsed) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
    decoration: BoxDecoration(
      color: isDarkMode ? AppColors.darkGrey50 : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        if (!isDarkMode)
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkGrey50 : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            isUsed ? Icons.history_rounded : Icons.emoji_events_rounded,
            size: 36,
            color: isDarkMode ? AppColors.surface : AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isUsed 
            ? l10n?.aucunoffre ?? 'Aucune offre utilisée' 
            :l10n?.aucunoffreutilise ?? 'Aucune récompense récemment disponible',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.surface : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
       
      ],
    ),
  );
}

Widget _buildLoadingWidget() {
  return const Center(
    child: Padding(
      padding: EdgeInsets.all(20.0),
      child: CircularProgressIndicator(),
    ),
  );
}

Widget _buildErrorWidget(dynamic error, AppLocalizations? l10n, bool isDarkMode, bool isRewards) {
  final errorColor = isDarkMode ? AppColors.error : Colors.red.shade700;
  final bgColor = isDarkMode ? AppColors.error.withOpacity(0.1) : Colors.red.shade50;
  final borderColor = isDarkMode ? AppColors.error : Colors.red.shade300;
  final textColor = isDarkMode ? AppColors.surface : AppColors.textPrimary;

  return Container(
    margin: const EdgeInsets.all(20),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: borderColor,
        width: 2,
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icône principale
        Icon(
          Icons.error_outline_rounded,
          size: 64,
          color: errorColor,
        ),
        const SizedBox(height: 24),
        
        // Titre principal
        Text(
          isRewards
            ? 'Erreur de chargement'
            : 'Données indisponibles',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: errorColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        
        // Description
        Text(
          isRewards
            ? 'Impossible de charger vos récompenses pour le moment'
            : 'Impossible de charger votre historique d\'offres',
          style: TextStyle(
            fontSize: 16,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Message d'erreur technique (si disponible)
        if (error != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode 
                ? Colors.black.withOpacity(0.2) 
                : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Text(
              error.toString(),
              style: TextStyle(
                color: isDarkMode 
                  ? AppColors.surface.withOpacity(0.7) 
                  : Colors.grey.shade600,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        
        const SizedBox(height: 24),
        
        // Bouton principal
        ElevatedButton.icon(
          onPressed: () {
            // Recharger les données
            if (isRewards) {
              ref.invalidate(recentRewardsProvider);
            } else {
              final client = ref.read(authProvider).currentUser;
              if (client?.id != null) {
                ref.invalidate(clientOffresProvider(client!.id));
              }
            }
          },
          icon: const Icon(Icons.refresh),
          label: Text(l10n?.retry ?? 'Réessayer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: errorColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}




Widget _buildNoConnectionWidget(BuildContext context, AppLocalizations? l10n, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade100,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade200.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.pasconnexioninternet ?? 'Pas de connexion Internet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.veuillezvzrifier ?? 'Veuillez vérifier votre connexion pour voir vos offres',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _checkConnectivity(),
            icon: const Icon(Icons.refresh),
            label: Text(l10n?.retry ?? 'Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

   // Widget pour le message de pas de connexion
Widget _buildMainContent(AppLocalizations? l10n, bool isDarkMode) {
  // 1. Vérifier l'état de la connexion d'abord
  if (_isCheckingConnectivity) {
    return _buildConnectivityCheckWidget();
  }

  if (!_hasConnection) {
    return _buildNoConnectionWidget(context, l10n, isDarkMode);
  }

  // 2. Si on a une connexion, charger les données
  final clientAsync = ref.watch(authProvider).currentUser;
  final clientoffreAsync = ref.watch(
    clientAsync?.id != null
      ? clientOffresProvider(clientAsync!.id)
      : FutureProvider((ref) => Future.value([])),
  );
  
  final rewardsAsync = ref.watch(recentRewardsProvider);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Section des récompenses disponibles
      rewardsAsync.when(
        data: (rewards) => rewards.isNotEmpty 
          ? Column(
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
            )
          : _buildNoRewardsWidget(l10n, isDarkMode, false),
        loading: () => _buildLoadingWidget(),
        error: (error, _) => _buildErrorWidget(error, l10n, isDarkMode, true),
      ),
      
      const SizedBox(height: 24),
      
      // Section des offres utilisées
      clientoffreAsync.when(
        data: (clientoffre) => clientoffre.isNotEmpty 
          ? Column(
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
            )
          : _buildNoRewardsWidget(l10n, isDarkMode, true),
        loading: () => _buildLoadingWidget(),
        error: (error, _) => _buildErrorWidget(error, l10n, isDarkMode, false),
      ),
    ],
  );
}

  Widget _buildConnectivityCheckWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Vérification de la connexion...',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
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
            top: _isNewOffer(offer.claimed_at) ? 60 : 28,
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
  DateFormat('dd/MM/yyyy').format(offer.claimed_at), // Format jour/mois/année
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