// lib/screens/qr_code_screen.dart
import 'package:flutter/material.dart';
import 'package:mukhliss/services/qrcode_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/widgets/Appbar/app_bar_types.dart'; 
class QRCodeScreen extends ConsumerStatefulWidget  {
  const QRCodeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends ConsumerState<QRCodeScreen> {
  final QrcodeService _qrcodeService = QrcodeService();
  late Future<Widget> _qrCodeFuture;

  @override
  void initState() {
    super.initState();
    _qrCodeFuture = _qrcodeService.generateUserQR();
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = screenWidth * 0.8; // Prend 80% de la largeur de l'écran
    final l10n = AppLocalizations.of(context);
     final themeMode = ref.watch(themeProvider);
      final isDarkMode = themeMode == AppThemeMode.light;
    return Scaffold(
      backgroundColor:isDarkMode? AppColors.darkSurface:AppColors.lightSurface,
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
                  // Carte QR Code principale
                  Container(
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
                        // Conteneur du QR Code
                        Container(
                          width: qrSize,
                          height: qrSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary, 
                              width: 2,
                            ),
                          ),
                          child: FutureBuilder<Widget>(
                            future: _qrCodeFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                );
                              }
                              return snapshot.data ?? const SizedBox();
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n?.qrCodeInstructions?? 
                          'Montrez ce QR code pour bénéficier de vos offres',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
}