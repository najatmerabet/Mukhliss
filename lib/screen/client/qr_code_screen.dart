import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/services/qrcode_service.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/widgets/Appbar/app_bar_types.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeScreen extends ConsumerStatefulWidget {
  const QRCodeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends ConsumerState<QRCodeScreen> {
  final QrcodeService _qrcodeService = QrcodeService();
  final Connectivity _connectivity = Connectivity();
  late Future<Map<String, dynamic>> _userDataFuture;
  bool _isOnline = true;
  bool _isRefreshing = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
    _initConnectivity();
    _startAutoRefresh();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    try {
      final qrData = await _qrcodeService.getQRDataString();
      int? userCode = await _qrcodeService.getCurrentUserCode();
      
      return {
        'qrData': qrData,
        'userCode': userCode,
        'error': null,
      };
    } catch (e) {
      return {
        'qrData': null,
        'userCode': null,
        'error': e.toString(),
      };
    }
  }

  Future<void> _initConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      setState(() {
        _isOnline = connectivityResult != ConnectivityResult.none;
      });

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (ConnectivityResult result) {
          final newOnlineStatus = result != ConnectivityResult.none;
          
          if (newOnlineStatus != _isOnline) {
            setState(() {
              _isOnline = newOnlineStatus;
            });
            
            if (_isOnline && !_isRefreshing) {
              _refreshData();
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isOnline && !_isRefreshing && mounted) {
        _refreshData();
      }
    });
  }

  void _refreshData() {
    if (mounted && !_isRefreshing) {
      setState(() {
        _isRefreshing = true;
        _userDataFuture = _loadUserData();
      });
      
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
    
    setState(() {
      _isRefreshing = true;
      _userDataFuture = _loadUserData();
    });
    
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

  // CARTE UNIFIÉE - QR Code + Code Unique
  Widget _buildUnifiedIdentificationCard(String qrData, int? userCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Code Unique
         
          
          // Section QR Code
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: MediaQuery.of(context).size.width * 0.65,
            height: MediaQuery.of(context).size.width * 0.65,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isRefreshing 
                    ? AppColors.primary.withOpacity(0.5) 
                    : AppColors.primary,
                width: 2,
              ),
            ),
            child: _isRefreshing
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: MediaQuery.of(context).size.width * 0.6,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.blue,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
          ),
          
          const SizedBox(height: 20),
         if (userCode != null) ...[
  Container(
   
    child: Column(
      children: [
       
        // Affichage avec cadres individuels
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildDigitBoxes(userCode.toString().padLeft(6, '0')),
        ),
      ],
    ),
  ),
  const SizedBox(height: 24),
],
       
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
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getUserFriendlyErrorMessage(error),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
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
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.light;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF0A0E27) : AppColors.lightSurface,
      body: CustomScrollView(
        slivers: [
          AppBarTypes.identificationAppBar(context),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _userDataFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }

                        if (snapshot.hasError || snapshot.data?['error'] != null) {
                          return _buildErrorContent(
                            snapshot.error?.toString() ?? snapshot.data?['error'] ?? 'Erreur inconnue'
                          );
                        }

                        final qrData = snapshot.data?['qrData'];
                        final userCode = snapshot.data?['userCode'];

                        if (qrData == null) {
                          return _buildErrorContent('Données QR code non disponibles');
                        }

                        return Center(
                          child: SingleChildScrollView(
                            child: _buildUnifiedIdentificationCard(qrData, userCode),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDigitBoxes(String code) {
  List<Widget> boxes = [];
  
  for (int i = 0; i < code.length; i++) {
    boxes.add(
      Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            code[i],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
    
    // Ajouter un espace entre les groupes de 3 chiffres
    if (i == 2) {
      boxes.add(const SizedBox(width: 5));
    }
  }
  
  return boxes;
}
}