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
import 'package:mukhliss/screen/rewardsexample.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/widgets/Appbar/app_bar_types.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyOffersScreen extends ConsumerStatefulWidget {
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
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
        result,
      ) {
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
              child: _buildContent(l10n, isDarkMode, clientAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    AppLocalizations? l10n,
    bool isDarkMode,
    User? clientAsync,
  ) {
    // Vérifier d'abord l'état de la connexion globale
    if (_isCheckingConnectivity) {
      return _buildConnectivityCheckWidget();
    }

    if (!_hasConnection) {
      return Column(
        children: [_buildNoConnectionHistoryWidget(l10n, isDarkMode)],
      );
    }

    // Si on a une connexion, afficher le contenu normal
    final clientoffreAsync = ref.watch(
      clientAsync?.id != null
          ? clientOffresProvider(clientAsync!.id)
          : FutureProvider((ref) => Future.value([])),
    );

    final rewardsAsync = ref.watch(recentRewardsProvider);

    return rewardsAsync.when(
      data:
          (rewards) => clientoffreAsync.when(
            data: (clientoffre) {
              // Cas où il n'y a AUCUNE donnée des deux côtés
              if (rewards.isEmpty && clientoffre.isEmpty) {
                return Center(
                  child: _buildNoRewardsWidget(l10n, isDarkMode, false),
                );
              }

              // Cas normal où on a au moins une des deux listes
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section des récompenses disponibles
                  if (rewards.isNotEmpty) ...[
                    Text(
                      l10n?.offredisponible ?? 'Offres Disponibles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode
                                ? AppColors.surface
                                : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...rewards.map(
                      (offer) => _buildRewardCard(offer),
                    ),
                    const SizedBox(height: 24),
                  ] else
                    const SizedBox(),

                  // Section des offres utilisées
                  if (clientoffre.isNotEmpty) ...[
                    Text(
                      l10n?.offreutilise ?? 'Offres Utilisées',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode
                                ? AppColors.surface
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...clientoffre.map(
                      (offer) => _buildRewardCardClaimed(offer),
                    ),
                  ] else
                    const SizedBox(),
                ],
              );
            },
            loading: () => _buildLoadingWidget(),
            error: (error, _) {
              if (error.toString().contains('no_internet_connection')) {
                return _buildNoConnectionHistoryWidget(l10n, isDarkMode);
              }
              return _buildNoConnectionHistoryWidget(l10n, isDarkMode);
            },
          ),
      loading: () => _buildLoadingWidget(),
      error: (error, _) => _buildNoConnectionHistoryWidget(l10n, isDarkMode),
    );
  }

  Widget _buildNoConnectionHistoryWidget(
    AppLocalizations? l10n,
    bool isDarkMode,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône d’avertissement
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.red.withOpacity(0.1),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),

              // Texte principal
              Text(
                l10n?.somethingwrong ?? "Something went wrong",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Bouton "Réessayer"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checkConnectivity,
                  label: Text(
                    l10n?.retry ?? 'Réessayer',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoRewardsWidget(
    AppLocalizations? l10n,
    bool isDarkMode,
    bool isUsed,
  ) {
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
                : l10n?.aucunoffreutilise ??
                    'Aucune récompense récemment disponible',
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

  Widget _buildConnectivityCheckWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
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

Widget _buildRewardCard(Rewards reward) {
  final isNew = reward.created_at.isAfter(DateTime.now().subtract(Duration(days: 7)));
  final daysAgo = DateTime.now().difference(reward.created_at).inDays;
  final L10n = AppLocalizations.of(context);
  
  return Container(
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        // En-tête avec image du magasin - CORRIGÉ
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Stack(
            children: [
              // Image de fond avec gestion d'erreur
              if (reward.magasin.logoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.network(
                    reward.magasin.logoUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback si l'image échoue
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.store,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                )
              else
                // Si pas d'URL d'image
                Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.store,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                  ),
                ),

              // Overlay gradient
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),

              // Badge Nouveau avec animation
              if (isNew)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.lightGreen],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.new_releases, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          L10n?.nouveau ?? 'NOUVEAU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Badge Points amélioré
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.amber,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${reward.points_required}',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 2),
                      Text(
                        L10n?.pts ?? 'pts',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Nom du magasin superposé sur l'image
              Positioned(
                left: 16,
                bottom: 12,
                right: 16,
                child: Row(
                  children: [
                    // Logo du magasin avec gestion d'erreur
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: reward.magasin.logoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                reward.magasin.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.store, size: 16, color: Colors.grey);
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Icon(Icons.store, size: 16, color: Colors.grey),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reward.magasin.nom_enseigne ?? 'Magasin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 4,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Contenu de la carte
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom de la récompense avec statut
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        // Description
                        if (reward.description != null)
                          Text(
                            reward.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  // Indicateur de statut
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: reward.is_active 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: reward.is_active ? Colors.green : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      reward.is_active ? L10n?.active ?? 'Actif' : L10n?.inactifs ?? 'Inactif',
                      style: TextStyle(
                        color: reward.is_active ? Colors.green : Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Barre d'informations supplémentaires
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Information date de création
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              L10n?.publier ?? 'Publié',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _formatDate(reward.created_at),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Information ancienneté
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isNew 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isNew ? Icons.flash_on : Icons.schedule,
                            size: 14,
                            color: isNew ? Colors.green : Colors.orange,
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              L10n?.ancien ?? 'Ancienneté',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              daysAgo == 0 
                                  ? L10n?.aujour ?? 'Aujourd\'hui'
                                  : daysAgo == 1
                                      ? L10n?.hier ?? 'Hier'
                                      : '${L10n?.ilYa ?? 'Il y a'} $daysAgo ${L10n?.days ?? 'jours'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isNew ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              

              // Information supplémentaire sous le bouton
              if (reward.is_active)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${reward.points_required} ${L10n?.pointsrequis ?? 'points requis'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
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

Widget _buildRewardCardClaimed(ClientOffre reward) {
  final isNew = reward.claimed_at.isAfter(DateTime.now().subtract(Duration(days: 7)));
  final daysAgo = DateTime.now().difference(reward.claimed_at).inDays;
  final L10n = AppLocalizations.of(context);
  
  return Container(
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
      border: Border.all(
        color: Colors.green.withOpacity(0.3),
        width: 1.5,
      ),
    ),
    child: Column(
      children: [
      Container(
  height: 140,
  width: double.infinity,
  decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    ),
  ),
  child: Stack(
    children: [
      // Image de fond avec gestion d'erreur
      if (reward.reward.magasin.logoUrl != null)
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Image.network(
            reward.reward.magasin.logoUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              // Si l'image échoue, afficher un placeholder
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Image non disponible',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              // Pendant le chargement
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        )
      else
        // Si pas d'URL, afficher un placeholder
        Container(
          color: Colors.grey[200],
          child: Center(
            child: Icon(
              Icons.store,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
        ),

      // Overlay gradient pour améliorer la lisibilité du texte
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.6),
            ],
          ),
        ),
      ),

      // Vos badges et autres éléments de la Stack
      Positioned(
        top: 12,
        left: 12,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'DÉJÀ UTILISÉ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),

      // Badge Points
      Positioned(
        top: 12,
        right: 12,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium,
                color: Colors.amber,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                '${reward.reward.points_required}',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 2),
              Text(
                'pts',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),

      // Nom du magasin
      Positioned(
        left: 16,
        bottom: 12,
        right: 16,
        child: Row(
          children: [
            // Logo du magasin avec gestion d'erreur
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: reward.reward.magasin.logoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        reward.reward.magasin.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.store, size: 16, color: Colors.grey);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          );
                        },
                      ),
                    )
                  : Icon(Icons.store, size: 16, color: Colors.grey),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                reward.reward.magasin.nom_enseigne ?? 'Magasin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
        
        // Contenu de la carte
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom de la récompense avec statut
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward.reward.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        // Description
                        if (reward.reward.description != null)
                          Text(
                            reward.reward.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  // Indicateur de statut consommé
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.verified, size: 16, color: Colors.green),
                        SizedBox(height: 2),
                        Text(
                          L10n?.utilise ?? 'Utilisé',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Barre d'informations de consommation
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.05),
                      Colors.lightGreen.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Date de consommation
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.event_available,
                            size: 18,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                           L10n?.utiliseLe??'Utilisé le',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _formatClaimedDate(reward.claimed_at),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    // Séparateur
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.green.withOpacity(0.3),
                    ),
                    
                    // Temps écoulé
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.access_time,
                            size: 18,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          L10n?.ilYa ?? 'Il y a',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _formatTimeAgo(reward.claimed_at),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    // Séparateur
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.green.withOpacity(0.3),
                    ),
                    
                    // Points économisés
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.savings,
                            size: 18,
                            color: Colors.orange,
                          ),
                        ),
                
                        SizedBox(height: 2),
                        Text(
                          '${reward.reward.points_required} pts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
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

// Fonctions de formatage pour les dates
String _formatClaimedDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String _formatTimeAgo(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  
  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      return '${difference.inMinutes} min';
    }
    return '${difference.inHours} h';
  } else if (difference.inDays == 1) {
    return '1 jour';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} jours';
  } else if (difference.inDays < 30) {
    return '${(difference.inDays / 7).floor()} sem';
  } else {
    return '${(difference.inDays / 30).floor()} mois';
  }
}

// Fonction pour formater la date
String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
 final L10n = AppLocalizations.of(context);
  if (difference.inDays == 0) {
    return L10n?.aujour ?? "Aujourd'hui";
  } else if (difference.inDays == 1) {
    return L10n?.hier ?? 'Hier';
  } else if (difference.inDays < 7) {
    return '${L10n?.ilYa ?? 'Il y a'} ${difference.inDays} ${L10n?.days ?? 'jours'}';
  } else {
    return '${L10n?.le ?? 'Le'} ${date.day}/${date.month}/${date.year}';
  }
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
                  colors: [Colors.red.shade600, Colors.red.shade700],
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
                            child:
                                offer.reward.magasin.logoUrl != null
                                    ? Image.network(
                                      offer.reward.magasin.logoUrl!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
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
                                  color: AppColors.error,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade600.withOpacity(
                                      0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.stars_rounded,
                                    color: AppColors.surface,
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
                                  l10n?.consomeoffre ??
                                      'Cette offre a déjà été consommée',
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
                          offer.reward.description ??
                              'Cette offre exclusive a été utilisée avec succès !',
                          style: TextStyle(
                            color: AppColors.surface,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              constraints: BoxConstraints(
                                maxWidth: 250,
                              ), // Add max width constraint
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
                                    color: AppColors.surface,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      DateFormat('dd/MM/yyyy').format(
                                        offer.claimed_at,
                                      ), // Format jour/mois/année
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
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
      child: Icon(Icons.store_rounded, color: AppColors.primary, size: 32),
    );
  }

  // Widget de logo de fallback

  // Méthode pour vérifier si l'offre est nouvelle (moins de 7 jours)
  bool _isNewOffer(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt).inDays;
    return difference <= 7;
  }




}
