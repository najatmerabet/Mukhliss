// lib/screens/profile_screen.dart - Design moderne avec édition
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/l10n.dart';

import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:mukhliss/screen/client/SupportTicketFormScreen%20.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/utils/form_field_helpers.dart';
import 'package:mukhliss/utils/snackbar_helper.dart';
import 'package:mukhliss/widgets/Appbar/app_bar_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenstate();
}

class _ProfileScreenstate extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      final authService = ref.read(authProvider);
      final user = authService.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pushNamed(context, AppRouter.login);
        }
        return;
      }

      final response =
          await authService.client
              .from("clients")
              .select()
              .eq('id', user.id)
              .single();

      if (mounted) {
        setState(() {
          _userData = response;
          _firstNameController.text = response['prenom'] ?? '';
          _lastNameController.text = response['nom'] ?? '';
          _emailController.text = response['email'] ?? '';
          _phoneController.text = response['telephone'] ?? '';
          _addressController.text = response['adresse'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final authService = ref.read(authProvider);
      final user = authService.currentUser;

      if (user == null) return;

      final updatedData = {
        'prenom': _firstNameController.text.trim(),
        'nom': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'telephone': _phoneController.text.trim(),
        'adresse': _addressController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await authService.client
          .from("clients")
          .update(updatedData)
          .eq('id', user.id);

      // Reload user data to reflect changes
      await _loadUserData();

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        showSuccessSnackbar(
          context: context, // N'oubliez pas le contexte
          message: 'Informations mises à jour avec succès!',
        );
        // Close the modal
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
   final isDarkMode = themeMode == AppThemeMode.light;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildProfileSection(),
                  const SizedBox(height: 30),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                  _buildMenuItems(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AppBarTypes.profileAppBar(context);
  }

  Widget _buildProfileSection() {
    final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
   final isDarkMode = themeMode == AppThemeMode.light;
    return Column(
      children: [
        // Photo de profil avec bouton play
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 60),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Nom
        Text(
          '${_userData?['prenom'] ?? ""} ${_userData?['nom'] ?? ''}',
          style:  TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.surface : AppColors.darkSurface,
          ),
        ),
        const SizedBox(height: 8),
        // Sous-titre
        Text(
          _userData?['email'] ?? '',
          style:  TextStyle(
            fontSize: 16,
            color: isDarkMode ? AppColors.surface : AppColors.darkSurface,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.person_outline,
            title:l10n?.info ?? 'Informations',
            subtitle: l10n?.voir ??'Voir et modifier',
            buttonText: l10n?.gerer ?? 'Gérer',
            onPressed: () => _showUserInfo(),
          ),
        ),
      
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
     final l10n = AppLocalizations.of(context);
    return Column(
      children: [
    
     
        _buildMenuItem(
          icon: Icons.settings_outlined,

          title:l10n?.parametre ?? 'Paramètres',
          onTap: () => _showNotificationSettings(),
        ),
        _buildMenuItem(
          icon: Icons.help_outline,
          title: l10n?.aide ??'Aide et Support',
          onTap: () => _showSupport(),
        ),
        _buildMenuItem(
          icon: Icons.info_outline,
          title:l10n?.apropos ?? 'À propos',
          onTap: () => _showAbout(),
        ),
        const SizedBox(height: 10),
        _buildMenuItem(
          icon: Icons.logout,
          title: l10n?.deconection ?? 'Se Déconnecter',
          isLogout: true,
          onTap: () => _showLogoutDialog(context, ref),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isLogout
                  ? Colors.red.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isLogout
                    ? Colors.red.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red : Colors.grey[700],
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Méthodes pour afficher les informations avec possibilité d'édition
  void _showUserInfo() {
      final l10n = AppLocalizations.of(context);
    setState(() => _isEditing = false); // Reset editing state

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header avec boutons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isEditing
                                  ? l10n?.mesinformation ?? 'Modifier mes informations'
                                  : l10n?.modifiermesinformation ?? 'Mes Informations',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                if (!_isEditing)
                                  IconButton(
                                    onPressed: () {
                                      setModalState(() => _isEditing = true);
                                    },
                                    icon: const Icon(
                                      Icons.edit,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                if (_isEditing) ...[
                                  IconButton(
                                    onPressed: () {
                                      setModalState(() => _isEditing = false);
                                      // Reset controllers to original values
                                      _firstNameController.text =
                                          _userData?['prenom'] ?? '';
                                      _lastNameController.text =
                                          _userData?['nom'] ?? '';
                                      _emailController.text =
                                          _userData?['email'] ?? '';
                                      _phoneController.text =
                                          _userData?['telephone'] ?? '';
                                      _addressController.text =
                                          _userData?['adresse'] ?? '';
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Form fields
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                if (_isEditing) ...[
                               
                                  AppFormFields.buildModernTextField(
                                    context: context,
                                    controller: _firstNameController,
                                    label:l10n?.prenom ?? 'Prénom',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return l10n?.requis ??'Le prénom est requis';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  AppFormFields.buildModernTextField(
                                    context: context,
                                    controller: _lastNameController,
                                    label:l10n?.nom ?? 'Nom',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Le nom est requis';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  AppFormFields.buildModernTextField(
                                    context: context,
                                    controller: _emailController,
                                    label:l10n?.email ?? 'Email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'L\'email est requis';
                                      }
                                      if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      ).hasMatch(value!)) {
                                        return 'Format d\'email invalide';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  AppFormFields.buildModernTextField(
                                    context: context,
                                    controller: _phoneController,
                                    label:l10n?.phone ?? 'Téléphone',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 16),
                                  AppFormFields.buildModernTextField(
                                    context: context,
                                    controller: _addressController,
                                    label:l10n?.address ?? 'Adresse',
                                    icon: Icons.location_on_outlined,
                                    maxLines: 2,
                                  ),
                                ] else ...[
                                  _buildInfoRow(
                                    Icons.person_outline,
                                 l10n?.prenom ??   'Prénom',
                                    _userData?['prenom'] ?? '',
                                  ),
                                  _buildInfoRow(
                                    Icons.person_outline,
                                   l10n?.nom ?? 'Nom',
                                    _userData?['nom'] ?? '',
                                  ),
                                  _buildInfoRow(
                                    Icons.email_outlined,
                                   l10n?.email ?? 'Email',
                                    _userData?['email'] ?? '',
                                  ),
                                  _buildInfoRow(
                                    Icons.phone_outlined,
                                    l10n?.phone ?? 'Téléphone',
                                    _userData?['telephone'] ?? '',
                                  ),
                                  _buildInfoRow(
                                    Icons.location_on_outlined,
                                    l10n?.address ?? 'Adresse',
                                    _userData?['adresse'] ?? '',
                                  ),
                                  _buildInfoRow(
                                    Icons.calendar_today_outlined,
                                    l10n?.membredepuis ?? 'Membre depuis',
                                    _userData?['created_at'] != null
                                        ? DateTime.parse(
                                          _userData!['created_at'],
                                        ).toLocal().toString().split(' ')[0]
                                        : '',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Save button when editing
                        if (_isEditing) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateUserData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      :  Text(
                                     l10n?.sauvgarder ??   'Sauvegarder',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Non renseigné' : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: value.isEmpty ? Colors.grey[400] : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showNotificationSettings() {
    Navigator.pushNamed(context, AppRouter.setting);
  }

void _showSupport() async {
  if (!mounted) return;
  
  // Ouvrir directement le formulaire de ticket
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SupportTicketFormScreen(),
    ),
  );

  if (result == true && mounted) {
    _showSuccessSnackbar("Votre demande a été envoyée avec succès");
  }
}







void _showSuccessSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ),
  );
}

void _showAbout() {
  final themeMode = ref.watch(themeProvider);
  final l10n = AppLocalizations.of(context);
  final isDarkMode = themeMode == AppThemeMode.light;
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          slivers: [
            AppBarTypes.AboutAppBar(context),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.darkSurface,
                            AppColors.darkSurface.withOpacity(0.9),
                            Color(0xFF1A1A2E),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.surface,
                            Color(0xFFF8F9FA),
                            Color(0xFFE8F4FD),
                          ],
                        ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header avec icône modernisé
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDarkMode
                                        ? [
                                            Color(0xFF4A90E2),
                                            Color(0xFF357ABD),
                                            Color(0xFF2E5B8A),
                                          ]
                                        : [
                                            Color(0xFF6C5CE7),
                                            Color(0xFF5A4FCF),
                                            Color(0xFF4834D4),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDarkMode
                                          ? Colors.black.withOpacity(0.3)
                                          : Colors.grey.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.asset(
                                    'images/withoutbg.png',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.star_rounded,
                                        size: 60,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "MUKHLISS",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: isDarkMode ? Colors.white : Color(0xFF2D3748),
                                  letterSpacing: 2.0,
                                  shadows: [
                                    Shadow(
                                      color: isDarkMode
                                          ? Colors.black.withOpacity(0.5)
                                          : Colors.grey.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDarkMode
                                        ? [
                                            Color(0xFF4A90E2).withOpacity(0.3),
                                            Color(0xFF357ABD).withOpacity(0.3),
                                          ]
                                        : [
                                            Color(0xFF6C5CE7).withOpacity(0.2),
                                            Color(0xFF5A4FCF).withOpacity(0.2),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Color(0xFF4A90E2).withOpacity(0.5)
                                        : Color(0xFF6C5CE7).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  l10n?.version ?? "Version 1.0.0",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white : Color(0xFF2D3748),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Cartes d'information modernisées
                        _buildInfoCard(
                          icon: Icons.description_outlined,
                          title: l10n?.desc ?? "Description",
                          content: l10n?.content ?? "Mukhliss – Votre carte de fidélité intelligente et connectée\n\nMukhliss est l'application mobile de fidélité nouvelle génération, conçue pour récompenser vos achats et vous faire profiter des meilleures offres autour de vous.Avec Mukhliss, chaque achat effectué dans un magasin partenaire vous fait gagner des points, selon les offres proposées par le commerçant. Cumulez vos points et échangez-les contre des cadeaux exclusifs dans vos boutiques préférées. Plus vous êtes fidèle, plus vous êtes récompensé !",
                          isDarkMode: isDarkMode,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildInfoCard(
                          icon: Icons.contact_support_outlined,
                          title: l10n?.support ?? "Contact & Support",
                          content: "mukhlissfidelite@gmail.com",
                          isContact: true,
                          isDarkMode: isDarkMode,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildInfoCard(
                          icon: Icons.code_outlined,
                          title: l10n?.technologies ?? "Technologies",
                          content: "Flutter • Supabase • Dart",
                          isDarkMode: isDarkMode,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Footer décoratif
                  
                      ],
                    ),
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

// Fonction helper pour créer les cartes d'information
Widget _buildInfoCard({
  required IconData icon,
  required String title,
  required String content,
  bool isContact = false,
  required bool isDarkMode,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      gradient: isDarkMode
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A2A4A).withOpacity(0.8),
                Color(0xFF1F1F3A).withOpacity(0.6),
              ],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Color(0xFFF8F9FA).withOpacity(0.8),
              ],
            ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.withOpacity(0.2),
        width: 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                            Color(0xFF4A90E2),
                            Color(0xFF357ABD),
                          ]
                        : [
                            Color(0xFF6C5CE7),
                            Color(0xFF5A4FCF),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Color(0xFF4A90E2).withOpacity(0.3)
                          : Color(0xFF6C5CE7).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.8)
                  : Color(0xFF4A5568),
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (isContact) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Color(0xFF4A90E2).withOpacity(0.2)
                    : Color(0xFF6C5CE7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Contactez-nous",
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Color(0xFF4A90E2) : Color(0xFF6C5CE7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// Widget helper pour les cartes d'information

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 12),
              Text(
                'Déconnexion',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(authProvider).logout();
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(context, '/');
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Déconnecter',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
