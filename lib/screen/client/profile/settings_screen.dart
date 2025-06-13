// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/screen/client/profile/devices_screen.dart';
import 'package:mukhliss/utils/snackbar_helper.dart';
import 'package:mukhliss/providers/langue_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isDarkMode = false;
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
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simule le nettoyage du cache
    setState(() => _isLoading = false);
    
    if (mounted) {
      showSuccessSnackbar(
        context: context,
        message: 'Cache nettoyé avec succès',
      );
    }
  }



  @override
  Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF6366F1),
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title:  Text(
                l10n?.parametre ??
               'Paramètres',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                ),
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
          ),
          
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
                    _buildSectionHeader('APPLICATION', Icons.settings_outlined),
                    const SizedBox(height: 12),
                    _buildModernSettingCard(
                      children: [
                        _buildModernSettingTile(
                          icon: Icons.language_outlined,
                          title: 'Langue',
                          subtitle: 'Français',
                          onTap: () => _showLanguageDialog(context),
                          iconColor: const Color(0xFF10B981),
                          iconBgColor: const Color(0xFF10B981).withOpacity(0.1),
                        ),
                        _buildModernDivider(),
                        _buildModernSettingTile(
                          icon: Icons.dark_mode_outlined,
                          title: 'Thème sombre',
                          subtitle: _isDarkMode ? 'Activé' : 'Désactivé',
                          trailing: Switch.adaptive(
                            value: _isDarkMode,
                            onChanged: (value) {
                              setState(() => _isDarkMode = value);
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
                          title: 'Nettoyer le cache',
                          onTap: _clearCache,
                          iconColor: const Color(0xFFF59E0B),
                          // ignore: deprecated_member_use
                          iconBgColor: const Color(0xFFF59E0B).withOpacity(0.1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    // Security & Privacy Section
                    _buildSectionHeader('SÉCURITÉ & CONFIDENTIALITÉ', Icons.security_outlined),
                    const SizedBox(height: 12),
                    _buildModernSettingCard(
                      children: [
                        _buildModernSettingTile(
                          icon: Icons.devices_outlined,
                          title: 'Gestion des appareils ',
                          subtitle: 'Appareils connectés',
                          onTap: () => _showDeviceManagement(context),
                          iconColor: const Color(0xFF3B82F6),
                          // ignore: deprecated_member_use
                          iconBgColor: const Color(0xFF3B82F6).withOpacity(0.1),
                        ),
                        _buildModernDivider(),
                        _buildModernSettingTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Politique de confidentialité',
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFC),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.privacy_tip,
                      color: Color(0xFFEC4899),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Politique de confidentialité',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Dernière mise à jour: 15/06/2023',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
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
                padding: const EdgeInsets.all(20),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Collecte des informations',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nous collectons des informations lorsque vous vous inscrivez sur notre site, vous connectez à votre compte, passez une commande, participez à un concours, et/ou lorsque vous vous déconnectez. Les informations collectées incluent votre nom, votre adresse e-mail, numéro de téléphone, et/ou carte de crédit.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    Text(
                      '2. Utilisation des informations',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Toutes les informations que nous recueillons auprès de vous peuvent être utilisées pour :\n- Personnaliser votre expérience et répondre à vos besoins individuels\n- Fournir un contenu publicitaire personnalisé\n- Améliorer notre site Web\n- Améliorer le service client et vos besoins de prise en charge\n- Vous contacter par e-mail\n- Administrer un concours, une promotion, ou une enquête',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    Text(
                      '3. Confidentialité du commerce en ligne',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nous sommes les seuls propriétaires des informations recueillies sur ce site. Vos informations personnelles ne seront pas vendues, échangées, transférées, ou données à une autre société pour n\'importe quelle raison, sans votre consentement, en dehors de ce qui est nécessaire pour répondre à une demande et/ou une transaction, comme par exemple pour expédier une commande.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: Text(
                  'J\'ai compris',
                  style: TextStyle(
                    color: Colors.grey.shade700,
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6366F1),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6366F1),
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
        color: Theme.of(context).cardColor,
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
                color: Colors.grey.shade300,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        localizations.languageSubtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
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
                color: Theme.of(context).colorScheme.surface,
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
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: Text(
                localizations.cancel,
                style: TextStyle(
                  color: Colors.grey.shade700,
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
  final l10n = AppLocalizations.of(context);
  
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    onTap: () {
      // Change the language immediately
      ref.read(languageProvider.notifier).changeLanguage(locale);
      
           
      // Close the dialog
      Navigator.of(context).pop();
      
      // Show confirmation message
      if (!selected) {
        // Use the stored localizations reference
        showSuccessSnackbar(
          context: context,
          message: l10n?.languageChanged ?? 'Language changed',
        );
      }
    },
    leading: Text(
      flag,
      style: const TextStyle(fontSize: 24),
    ),
    title: Text(
      language,
      style: TextStyle(
        color: selected ? const Color(0xFF6366F1) : const Color(0xFF1F2937),
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        fontSize: 16,
      ),
    ),
    trailing: selected
        ? const Icon(
            Icons.check_circle,
            color: Color(0xFF6366F1),
            size: 20,
          )
        : null,
  );
}
}