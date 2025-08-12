// lib/screens/settings_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/l10n/l10n.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/screen/client/profile/devices_screen.dart';

import 'package:mukhliss/theme/app_theme.dart';
// import 'package:mukhliss/screen/layout/main_navigation_screen.dart';

import 'package:mukhliss/utils/snackbar_helper.dart';
import 'package:mukhliss/providers/langue_provider.dart';

import 'package:mukhliss/providers/theme_provider.dart';

import 'package:mukhliss/widgets/Appbar/app_bar_types.dart';
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      showErrorSnackbar(context: context, message: 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(authProvider);
      await authService.updatePasswordWithVerify(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        showSuccessSnackbar(
          context: context,
          message: 'Mot de passe changé avec succès',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(
          context: context,
          message: 'Erreur lors du changement de mot de passe: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearCache() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simule le nettoyage du cache
    setState(() => _isLoading = false);
    
    if (mounted) {
      showSuccessSnackbar(
        context: context,
        message: l10n?.cachenettoye ?? 'Cache nettoyé avec succès',
      );
    }
  }



  @override
  Widget build(BuildContext context) {
      final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
   final isDarkMode = themeMode == AppThemeMode.light;
    
    return Scaffold(
      backgroundColor:isDarkMode ? AppColors.darkSurface :AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar
         AppBarTypes.ParametreAppBar(context),
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [                 
             
                    // App Settings Section
                    _buildSectionHeader(l10n?.application ?? 'APPLICATION', Icons.settings_outlined),
                    const SizedBox(height: 12),
                    _buildModernSettingCard(
                      children: [
                        _buildModernSettingTile(
                          icon: Icons.language_outlined,
                          title:l10n?.language ?? 'Langue',
                          subtitle:l10n?.currentLanguage ?? 'Français',
                          onTap: () => _showLanguageDialog(context),
                          iconColor: const Color(0xFF10B981),
                          iconBgColor: const Color(0xFF10B981).withOpacity(0.1),
                        ),
                        _buildModernDivider(),
                        _buildModernSettingTile(
                          icon: Icons.dark_mode_outlined,
                          title: l10n?.theme ?? 'Thème sombre',
                          subtitle: isDarkMode ? l10n?.active ?? 'Activé' :  'Désactivé',
                          trailing: Switch.adaptive(
                            value: isDarkMode,
                            onChanged: (value) {
                            ref.read(themeProvider.notifier).toggleTheme();
                            },
                            activeColor: const Color(0xFF6366F1),
                          ),
                          iconColor: const Color(0xFF8B5CF6),
                          // ignore: deprecated_member_use
                          iconBgColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                        ),
                        _buildModernDivider(),
                        _buildModernSettingTile(
                          icon: Icons.storage_outlined,
                          title: l10n?.netoyercacha ?? 'Nettoyer le cache',
                          onTap: _clearCache,
                          iconColor: const Color(0xFFF59E0B),
                          // ignore: deprecated_member_use
                          iconBgColor: const Color(0xFFF59E0B).withOpacity(0.1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    // Security & Privacy Section
                    _buildSectionHeader(l10n?.securite ??'SÉCURITÉ & CONFIDENTIALITÉ', Icons.security_outlined),
                    const SizedBox(height: 12),
                    _buildModernSettingCard(
                      children: [
                        _buildModernSettingTile(
                          icon: Icons.devices_outlined,
                          title:l10n?.gestionappariels ?? 'Gestion des appareils ',
                          subtitle:l10n?.apparielsconnecte ?? 'Appareils connectés',
                          onTap: () => _showDeviceManagement(context),
                          iconColor: const Color(0xFF3B82F6),
                          // ignore: deprecated_member_use
                          iconBgColor: const Color(0xFF3B82F6).withOpacity(0.1),
                        ),
                        _buildModernDivider(),
                        _buildModernSettingTile(
                          icon: Icons.privacy_tip_outlined,
                          title: l10n?.politiques ??'Politique de confidentialité',
                          onTap: () => _showPrivacyPolicy(context),
                          iconColor: const Color(0xFFEC4899),
                          // ignore: deprecated_member_use
                          iconBgColor: const Color(0xFFEC4899).withOpacity(0.1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

 void _showDeviceManagement(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const DevicesScreen(),
    ),
  );
}

void _showPrivacyPolicy(BuildContext context) {
  final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
   final isDarkMode = themeMode == AppThemeMode.light;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color:isDarkMode ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.security, color: Colors.pink, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.politiques ?? 'Politique de confidentialité',
                        style:  TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ?AppColors.surface : AppColors.darkGrey50,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n?.datemiseajour ?? 'Dernière mise à jour: 15/06/2023',
                        style: TextStyle(
                          fontSize: 14,
                          color:isDarkMode ?AppColors.surface : AppColors.darkGrey50,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content with uniform padding
            _buildPrivacySection(
              title: l10n?.premierstep ?? '1. Collecte des données',
              content: l10n?.contentstepone ?? 
                'Mukhliss collecte les données suivantes pour fournir le service de carte de fidélité :\n\n'
                '- Informations personnelles (nom, prénom, email, téléphone)\n'
                '- Données de localisation (pour trouver les magasins partenaires)\n'
                '- Historique des achats et points accumulés\n'
                '- Données de paiement (pour les offres premium)',
            ),

            _buildPrivacySection(
              title: l10n?.deusiemestep ?? '2. Utilisation des données',
              content: l10n?.contentsteptwo ?? 
                'Vos données sont utilisées pour :\n\n'
                '- Gérer votre compte et carte de fidélité\n'
                '- Vous informer des offres personnalisées\n'
                '- Analyser les tendances d\'achat\n'
                '- Améliorer notre service\n'
                '- Prévenir les fraudes',
            ),

            _buildPrivacySection(
              title: l10n?.troisemestep ?? '3. Partage des données',
              content: l10n?.contentstepthre ?? 
                'Vos données peuvent être partagées avec :\n\n'
                '- Les magasins partenaires où vous utilisez votre carte\n'
                '- Les prestataires de paiement\n'
                '- Les services d\'analyse (de manière anonyme)\n\n'
                'Nous ne vendons jamais vos données personnelles.',
            ),

            _buildPrivacySection(
              title: l10n?.quatriemestep ?? '4. Sécurité des données',
              content: l10n?.contentstepfor ?? 
                'Nous protégeons vos données par :\n\n'
                '- Chiffrement AES-256\n'
                '- Authentification à deux facteurs\n'
                '- Audits de sécurité réguliers\n'
                '- Stockage sécurisé conforme RGPD',
            ),

            _buildPrivacySection(
              title: l10n?.cinquemestep ?? '5. Vos droits',
              content: l10n?.contentstepfive ?? 
                'Vous avez le droit de :\n\n'
                '- Accéder à vos données\n'
                '- Demander leur correction\n'
                '- Supprimer votre compte\n'
                '- Exporter vos données\n'
                '- Vous opposer au traitement\n\n'
                'Contactez-nous à mukhlissfidelite@gmail.com pour toute demande.',
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                backgroundColor:isDarkMode ? AppColors.surface : AppColors.darkGrey50,
              ),
              child: Text(
                l10n?.compris ?? 'J\'ai compris',
                style:  TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color:isDarkMode ? AppColors.darkPrimary : AppColors.surface,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    ),
  );
}

Widget _buildPrivacySection({required String title, required String content}) {
 final themeMode = ref.watch(themeProvider);
    
   final isDarkMode = themeMode == AppThemeMode.light;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.surface.withOpacity(0.1),
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:  TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color:isDarkMode ? AppColors.primary : Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.darkSurface,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildModernSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildModernSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            )
          : null,
      trailing: trailing ?? const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9CA3AF),
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildModernDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade100,
      ),
    );
  }

 void _showLanguageDialog(BuildContext context) {
  final currentLanguage = ref.read(languageProvider.notifier).currentLanguageOption;
  final localizations = AppLocalizations.of(context)!;
final themeMode = ref.read(themeProvider);
  final isDarkMode = themeMode == AppThemeMode.light;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    isScrollControlled: true,
    builder: (context) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color:isDarkMode ? AppColors.darkPrimary :AppColors. surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkGrey50,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.selectLanguage,
                        style:  TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:  isDarkMode ? AppColors.surface : AppColors.darkSurface,
                        ),
                      ),
                      Text(
                        localizations.languageSubtitle,
                        style:  TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? AppColors.surface : AppColors.darkSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
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
                children: LanguageNotifier.supportedLanguages.map((lang) {
                  final isSelected = lang.locale.languageCode == currentLanguage.locale.languageCode;
                  return Column(
                    children: [
                      _buildLanguageOption(
                         context,
                        language: lang.name,
                        flag: lang.flag,
                        selected: isSelected,
                        locale: lang.locale,
                      ),
                      if (lang != LanguageNotifier.supportedLanguages.last)
                        _buildModernDivider(),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.darkGrey50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: Text(
                localizations.cancel,
                style: TextStyle(
                  color: isDarkMode ? AppColors.surface : AppColors.darkSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    ),
  );
}


 Widget _buildLanguageOption(
  BuildContext context, {
  required String language,
  required String flag,
  bool selected = false,
  required Locale locale,
}) {
  // Get the localizations before any async operations
  AppLocalizations.of(context);
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    onTap: () {
      if (!selected) {
        // Close the dialog first
        Navigator.of(context).pop();
        
        // Change the language
        ref.read(languageProvider.notifier).changeLanguage(locale);
        
        // Show success message immediately with current localizations
        // The UI will rebuild with the new language automatically
        if (mounted) {
          showSuccessSnackbar(
            context: this.context, // Use the settings screen context
            message: 'Language changed successfully', // Fallback message
          );
        }
      } else {
        // Just close if the same language is selected
        Navigator.of(context).pop();
      }
    },
    leading: Text(
      flag,
      style: const TextStyle(fontSize: 24),
    ),
    title: Text(
      language,
      style: TextStyle(
        color: selected ? AppColors.primary : AppColors.darkGrey50,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        fontSize: 16,
      ),
    ),
    trailing: selected
        ? const Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: 20,
          )
        : null,
  );
}
}