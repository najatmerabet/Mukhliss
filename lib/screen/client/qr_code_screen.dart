import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/services/qrcode_service.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/widgets/Appbar/app_bar_types.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class QRCodeScreen extends ConsumerStatefulWidget {
  const QRCodeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends ConsumerState<QRCodeScreen> {
  final QrcodeService _qrcodeService = QrcodeService();
  final Connectivity _connectivity = Connectivity();
  late Future<Widget> _qrCodeFuture;
  bool _isOnline = true;
  bool _isRefreshing = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _refreshTimer;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _qrCodeFuture = _generateQRWithErrorHandling();
    _startAutoRefresh();
  }

  // Wrapper pour gérer les erreurs de génération QR
  Future<Widget> _generateQRWithErrorHandling() async {
    try {
      setState(() {
        _lastError = null;
      });
      return await _qrcodeService.generateUserQR();
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
      rethrow;
    }
  }

  Future<void> _initConnectivity() async {
    try {
      // Vérifier l'état initial de la connexion
      final connectivityResult = await _connectivity.checkConnectivity();
      setState(() {
        _isOnline = connectivityResult != ConnectivityResult.none;
      });

      // Écouter les changements de connexion
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (ConnectivityResult result) {
          final newOnlineStatus = result != ConnectivityResult.none;
          
          if (newOnlineStatus != _isOnline) {
            setState(() {
              _isOnline = newOnlineStatus;
            });
            
            // Rafraîchir automatiquement quand la connexion revient
            if (_isOnline && !_isRefreshing) {
              _refreshQRCode();
            }
          }
        },
        onError: (error) {
          print('Connectivity error: $error');
        },
      );
    } catch (e) {
      print('Failed to initialize connectivity: $e');
    }
  }

  void _startAutoRefresh() {
    // Rafraîchir le QR code toutes les 30 secondes quand en ligne et non en cours de rafraîchissement
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isOnline && !_isRefreshing && mounted) {
        _refreshQRCode();
      }
    });
  }

  void _refreshQRCode() {
    if (mounted && !_isRefreshing) {
      setState(() {
        _isRefreshing = true;
        _qrCodeFuture = _generateQRWithErrorHandling();
      });
      
      // Reset refresh flag après un délai
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      });
    }
  }

  Future<void> _manualRefresh() async {
    if (_isRefreshing) return;
    
    // Animation de rafraîchissement
    setState(() {
      _isRefreshing = true;
      _qrCodeFuture = _generateQRWithErrorHandling();
    });
    
    // Délai minimum pour l'animation
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  
  Widget _buildQRContent(Widget qrWidget) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Conteneur du QR Code avec animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isRefreshing ? AppColors.primary.withOpacity(0.5) : AppColors.primary,
                width: 2,
              ),
            ),
            child: _isRefreshing
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : qrWidget,
          ),
          const SizedBox(height: 24),
          
          // Instructions
          Text(
            AppLocalizations.of(context)?.qrCodeInstructions ?? 
            'Montrez ce QR code pour bénéficier de vos offres',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          
    
          // Bouton de rafraîchissement avec état
         
        ],
      ),
    );
  }

  Widget _buildErrorContent(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon(
                //   _isOnline ? Icons.error : Icons.wifi_off,
                //   color: _isOnline ? Colors.red : Colors.orange,
                //   size: 48,
                // ),
                const SizedBox(height: 16),
                // Text(
                //   _isOnline ? 'Erreur de chargement' : 'Hors ligne',
                //   textAlign: TextAlign.center,
                //   style: TextStyle(
                //     fontSize: 18,
                //     fontWeight: FontWeight.bold,
                //     color: _isOnline ? Colors.red : Colors.orange,
                //   ),
                // ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _getUserFriendlyErrorMessage(error),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Impossible de charger le QR code pour le moment',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isRefreshing ? null : _manualRefresh,
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 20),
            label: Text(_isRefreshing ? 'Tentative...' : 'Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(_isRefreshing ? 0.5 : 1),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('No internet connection')) {
      return 'Vérifiez votre connexion internet';
    } else if (error.contains('timeout')) {
      return 'Connexion trop lente, veuillez réessayer';
    } else if (error.contains('Authentication')) {
      return 'Session expirée, veuillez vous reconnecter';
    } else if (error.contains('no cached data')) {
      return 'Aucune donnée disponible hors ligne';
    } else {
      return 'Une erreur inattendue s\'est produite';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.light;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
      body: CustomScrollView(
        slivers: [
          AppBarTypes.identificationAppBar(context),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Indicateur de statut de connexion
                  // _buildConnectionStatus(),

                  // Carte QR Code principale avec gestion d'état améliorée
                  FutureBuilder<Widget>(
                    future: _qrCodeFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildQRContent(
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return _buildErrorContent(snapshot.error.toString());
                      }
                      
                      return _buildQRContent(snapshot.data ?? const SizedBox());
                    },
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