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

class _MyOffersScreenState extends ConsumerState<MyOffersScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _hasConnection = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isCheckingConnectivity = true;
  late AnimationController _shimmerController;
  late AnimationController _fadeController;

  // Nouveaux états pour les onglets
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _shimmerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    )..forward();

    // Initialiser le contrôleur d'onglets
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _shimmerController.dispose();
    _fadeController.dispose();
    _tabController.dispose();
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
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.light;
    final clientAsync = ref.watch(authProvider).currentUser;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF0A0E27) : Color(0xFFF8F9FE),
      body: NestedScrollView(
        physics: BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            AppBarTypes.offersAppBar(context),
            _buildTabBar(l10n, isDarkMode),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAvailableOffers(l10n, isDarkMode, clientAsync),
            _buildUsedOffers(l10n, isDarkMode, clientAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations? l10n, bool isDarkMode) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      sliver: SliverToBoxAdapter(
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1A1F36) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF1A1F36) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor:
                  isDarkMode ? Colors.white70 : Colors.grey[700],
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.zero,
              labelPadding: EdgeInsets.symmetric(horizontal: 16),
              tabs: [
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      l10n?.offredisponible ?? 'Disponibles',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      l10n?.offreutilise ?? 'Utilisées',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableOffers(
    AppLocalizations? l10n,
    bool isDarkMode,
    User? clientAsync,
  ) {
    if (_isCheckingConnectivity) {
      return _buildConnectivityCheckWidget();
    }

    if (!_hasConnection) {
      return _buildNoConnectionHistoryWidget(l10n, isDarkMode);
    }

    final rewardsAsync = ref.watch(recentRewardsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recentRewardsProvider);
      },
      child: rewardsAsync.when(
        data: (rewards) {
          if (rewards.isEmpty) {
            return _buildNoRewardsWidget(l10n, isDarkMode, false);
          }

          return ListView.builder(
            padding: EdgeInsets.all(20),
            physics: BouncingScrollPhysics(),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder(
                duration: Duration(milliseconds: 400 + (index * 100)),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: _buildRewardCard(rewards[index], isDarkMode),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => _buildLoadingWidget(isDarkMode),
        error: (error, _) => _buildNoConnectionHistoryWidget(l10n, isDarkMode),
      ),
    );
  }

  Widget _buildUsedOffers(
    AppLocalizations? l10n,
    bool isDarkMode,
    User? clientAsync,
  ) {
    if (_isCheckingConnectivity) {
      return _buildConnectivityCheckWidget();
    }

    if (!_hasConnection) {
      return _buildNoConnectionHistoryWidget(l10n, isDarkMode);
    }

    final clientoffreAsync = ref.watch(
      clientAsync?.id != null
          ? clientOffresProvider(clientAsync!.id)
          : FutureProvider((ref) => Future.value([])),
    );

    return RefreshIndicator(
      onRefresh: () async {
        if (clientAsync?.id != null) {
          ref.invalidate(clientOffresProvider(clientAsync!.id));
        }
      },
      child: clientoffreAsync.when(
        data: (clientoffre) {
          if (clientoffre.isEmpty) {
            return _buildNoRewardsWidget(l10n, isDarkMode, true);
          }

          return ListView.builder(
            padding: EdgeInsets.all(20),
            physics: BouncingScrollPhysics(),
            itemCount: clientoffre.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder(
                duration: Duration(milliseconds: 400 + (index * 100)),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: _buildRewardCardClaimed(
                        clientoffre[index],
                        isDarkMode,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => _buildLoadingWidget(isDarkMode),
        error: (error, _) => _buildNoConnectionHistoryWidget(l10n, isDarkMode),
      ),
    );
  }

  // Les méthodes _buildNoConnectionHistoryWidget, _buildNoRewardsWidget,
  // _buildLoadingWidget, _buildConnectivityCheckWidget, _buildRewardCard,
  // _buildRewardCardClaimed, _buildInfoChip, _formatClaimedDate,
  // _formatTimeAgo, _formatDate, _isNewOffer restent identiques à votre code original

  Widget _buildNoConnectionHistoryWidget(
    AppLocalizations? l10n,
    bool isDarkMode,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDarkMode
                      ? [Color(0xFF1E2337), Color(0xFF0F1425)]
                      : [Colors.white, Color(0xFFF8F9FE)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF6B6B).withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Text(
                l10n?.somethingwrong ?? "Problème de connexion",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Color(0xFF1A1F36),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                "Vérifiez votre connexion internet",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF6B6B).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _checkConnectivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n?.retry ?? 'Réessayer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDarkMode
                    ? [Color(0xFF1E2337), Color(0xFF0F1425)]
                    : [Colors.white, Color(0xFFF8F9FE)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.primary.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUsed ? Icons.history_rounded : Icons.emoji_events_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 24),
            Text(
              isUsed
                  ? l10n?.aucunoffre ?? 'Aucune offre utilisée'
                  : l10n?.aucunoffreutilise ?? 'Aucune récompense disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Color(0xFF1A1F36),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "Revenez bientôt pour découvrir de nouvelles offres",
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(bool isDarkMode) {
    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDarkMode
                      ? [Color(0xFF1E2337), Color(0xFF0F1425)]
                      : [Colors.white, Color(0xFFF8F9FE)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    stops: [
                      _shimmerController.value - 0.3,
                      _shimmerController.value,
                      _shimmerController.value + 0.3,
                    ],
                  ).createShader(bounds);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildConnectivityCheckWidget() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(width: 16),
            Text(
              'Vérification de la connexion...',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(Rewards reward, bool isDarkMode) {
    final isNew = reward.created_at.isAfter(
      DateTime.now().subtract(Duration(days: 7)),
    );
    final daysAgo = DateTime.now().difference(reward.created_at).inDays;
    final L10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: reward.is_active ? () {} : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDarkMode
                    ? [Color(0xFF1E2337), Color(0xFF0F1425)]
                    : [Colors.white, Color(0xFFF8F9FE)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.black12,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  if (isNew)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF6B6B).withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            L10n?.nouveau ?? 'NOUVEAU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFB800), Color(0xFFFF8800)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFFB800).withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${reward.points_required}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.2),
                              AppColors.primary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child:
                            reward.magasin.logoUrl != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    reward.magasin.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.store_rounded,
                                        size: 24,
                                        color: AppColors.primary,
                                      );
                                    },
                                  ),
                                )
                                : Icon(
                                  Icons.store_rounded,
                                  size: 24,
                                  color: AppColors.primary,
                                ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reward.magasin.nom_enseigne ?? 'Magasin',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            // ✅ AJOUT: Adresse du magasin
                            if (reward.magasin.adresse != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 12,
                                    color:
                                        isDarkMode
                                            ? Colors.white54
                                            : Colors.black45,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      reward.magasin.adresse!.split(',').first,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            isDarkMode
                                                ? Colors.white54
                                                : Colors.black45,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Badge "Vérifié" si pas d'adresse
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Vérifiés',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),
                  Text(
                    reward.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Color(0xFF1A1F36),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (reward.description != null) ...[
                    SizedBox(height: 12),
                    Text(
                      reward.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            isDarkMode
                                ? [Color(0xFF252B47), Color(0xFF1A1F36)]
                                : [Color(0xFFF8F9FE), Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode ? Colors.white10 : Colors.black12,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoChip(
                          Icons.calendar_today_rounded,
                          _formatDate(reward.created_at),
                          isDarkMode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCardClaimed(ClientOffre reward, bool isDarkMode) {
    final daysAgo = DateTime.now().difference(reward.claimed_at).inDays;
    final L10n = AppLocalizations.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [Color(0xFF1E2337), Color(0xFF0F1425)]
                  : [Colors.white, Color(0xFFF8F9FE)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFF10B981).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF10B981).withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      reward.reward.magasin.logoUrl != null
                          ? ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.2),
                              BlendMode.darken,
                            ),
                            child: Image.network(
                              reward.reward.magasin.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey[300]!,
                                        Colors.grey[400]!,
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.store_rounded,
                                    size: 48,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            ),
                          )
                          : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey[300]!, Colors.grey[400]!],
                              ),
                            ),
                            child: Icon(
                              Icons.store_rounded,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                          ),
                      Container(
                        decoration: BoxDecoration(
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
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF10B981).withOpacity(0.5),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        L10n?.utilise ?? 'UTILISÉ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child:
                          reward.reward.magasin.logoUrl != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  reward.reward.magasin.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.store_rounded,
                                      size: 24,
                                      color: Colors.grey[600],
                                    );
                                  },
                                ),
                              )
                              : Icon(
                                Icons.store_rounded,
                                size: 24,
                                color: Colors.grey[600],
                              ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reward.reward.magasin.nom_enseigne ?? 'Magasin',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // ✅ AJOUT: Adresse du magasin
                          if (reward.reward.magasin.adresse != null) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 12,
                                  color:
                                      isDarkMode
                                          ? Colors.white54
                                          : Colors.black45,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    reward.reward.magasin.adresse!
                                        .split(',')
                                        .first,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          isDarkMode
                                              ? Colors.white54
                                              : Colors.black45,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),
                Text(
                  reward.reward.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Color(0xFF1A1F36),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (reward.reward.description != null) ...[
                  SizedBox(height: 12),
                  Text(
                    reward.reward.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF10B981).withOpacity(0.1),
                        Color(0xFF10B981).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFF10B981).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${L10n?.utiliseLe ?? 'Utilisé le'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        isDarkMode
                                            ? Colors.white60
                                            : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  _formatClaimedDate(reward.claimed_at),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Divider(
                        color: Color(0xFF10B981).withOpacity(0.2),
                        height: 1,
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color:
                                    isDarkMode
                                        ? Colors.white60
                                        : Colors.black54,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '${L10n?.ilYa ?? 'Il y a'} ${_formatTimeAgo(reward.claimed_at)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFB800), Color(0xFFFF8800)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.stars_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${reward.reward.points_required} ${L10n?.pts ?? 'pts'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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

  String _formatClaimedDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final l10n = AppLocalizations.of(context);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} ${l10n?.min ?? 'min'}';
      }
      return '${difference.inHours} ${l10n?.h ?? 'h'}';
    } else if (difference.inDays == 1) {
      return '1 ${l10n?.day ?? 'jour'}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${l10n?.days ?? 'jours'}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks > 1 ? (l10n?.week ?? 'semaines') : (l10n?.week ?? 'semaine')}';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${l10n?.mois ?? 'mois'}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final L10n = AppLocalizations.of(context);

    if (difference.inDays == 0) {
      return L10n?.aujour ?? "Aujourd'hui";
    } else if (difference.inDays == 1) {
      return L10n?.hier ?? 'Hier';
    } else if (difference.inDays < 7) {
      return '${L10n?.ilYa ?? 'Il y a'} ${difference.inDays} ${L10n?.days ?? 'j'}';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  bool _isNewOffer(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt).inDays;
    return difference <= 7;
  }
}
