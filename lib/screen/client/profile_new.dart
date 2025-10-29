// lib/screens/profile_screen.dart - Design moderne avec édition
// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/l10n/l10n.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/providers/theme_provider.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:mukhliss/screen/client/SupportTicketFormScreen%20.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/utils/form_field_helpers.dart';
import 'package:mukhliss/utils/snackbar_helper.dart';
import 'package:mukhliss/widgets/Appbar/app_bar_types.dart';


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
      WidgetsBinding.instance.addPostFrameCallback((_) {
    precacheImage(AssetImage('images/mukhlislogo1.png'), context);
  });

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
    
    // Vérification de connexion plus robuste
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userData = null;
        });
        // showErrorSnackbar(context: context, message: 'Pas de connexion internet');
      }
      return;
    }

    final authService = ref.read(authProvider);
    final user = authService.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushNamed(context, AppRouter.login);
      }
      return;
    }

    // Debug: Ajoutez des logs pour suivre le flux
    debugPrint('Tentative de chargement des données utilisateur...');

    final response = await authService.client
        .from("clients")
        .select()
        .eq('id', user.id)
        .single()
        .timeout(const Duration(seconds: 10)); // Timeout pour éviter l'attente infinie

    debugPrint('Données reçues: ${response.toString()}');

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
  } on TimeoutException {
    if (mounted) {
      setState(() => _isLoading = false);
     
    }
  } catch (e) {
    debugPrint('Erreur lors du chargement: ${e.toString()}');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _userData = null;
      });
      showErrorSnackbar(
        context: context,
        message: 'Erreur lors du chargement des données',
      );
    }
  }
}

  Future<void> _updateUserData() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    setState(() => _isLoading = true);
    
    // Vérifier la connexion internet
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        setState(() => _isLoading = false);
        showErrorSnackbar(
          context: context,
          message: 'Pas de connexion internet. Impossible de sauvegarder.',
        );
      }
      return;
    }

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
        context: context,
        message: 'Informations mises à jour avec succès!',
      );
      // Close the modal
      Navigator.of(context).pop();
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      showErrorSnackbar(
        context: context,
        message: 'Erreur lors de la mise à jour: ${e.toString()}',
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
                  // const SizedBox(height: 30),
                  //  _buildActionButtons(),
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
          icon: Icons.person_outline,

          title:l10n?.info ?? 'Informations ',
          onTap: () => _showUserInfo(),
        ),
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
   final themeMode = ref.watch(themeProvider);
  final l10n = AppLocalizations.of(context);
  final isDarkMode = themeMode == AppThemeMode.light;
   if (_userData == null) {
    _showNoConnectionSnackbar();
    return;
  }
  setState(() => _isEditing = false);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        if (_userData == null) {
          return Container(
            height: 300,
            child: Center(
              child: Text('Données utilisateur non disponibles'),
            ),
          );
        }
        return StreamBuilder<ConnectivityResult>(
          stream: Connectivity().onConnectivityChanged,
          initialData: ConnectivityResult.none,
          builder: (context, connectivitySnapshot) {
             final isOffline = connectivitySnapshot.data == ConnectivityResult.none;
            final hasData = connectivitySnapshot.hasData;
          final isInitialData = connectivitySnapshot.connectionState == ConnectionState.waiting;
          // Ne pas afficher la bannière pendant le chargement initial
          final shouldShowBanner = hasData && !isInitialData && isOffline;
           debugPrint('''
Connectivity status: 
- State: ${connectivitySnapshot.connectionState}
- Data: ${connectivitySnapshot.data}
- HasData: $hasData
- IsInitial: $isInitialData
- IsOffline: $isOffline
- ShouldShowBanner: $shouldShowBanner
''');
            final canEdit = !isOffline; // Édition possible seulement en ligne
          if (_userData == null) {
                return _buildNoConnectionWidget(); // Widget personnalisé pour "pas de connexion"
             }
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkSurface : AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle de fermeture
                  Center(
                    child: GestureDetector(
                      onTap: Navigator.of(context).pop,
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  
                  // En-tête avec statut connexion
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEditing 
                            ? l10n?.mesinformation ?? 'Modifier mes informations'
                            : l10n?.modifiermesinformation ?? 'Mes Informations',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.surface : AppColors.darkSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isEditing)
                        IconButton(
                          icon: Icon(Icons.edit),
                          color: canEdit ? AppColors.surface : Colors.grey,
                          onPressed: () async {
                            // Vérification active de la connexion
                          //   final result = await Connectivity().checkConnectivity();
                          //   if (result == ConnectivityResult.none) {
                          //     _showNoConnectionSnackbar();
                          //     return;
                          //   }
                          //   setModalState(() => _isEditing = true);
                          // },
                          // tooltip: canEdit 
                          //     ? 'Modifier les informations'
                          //     : 'Connexion requise pour modifier',
                           setModalState(() { _isEditing = true ; });
                          }

                        ),
                    ],
                  ),
                  
                  // Bannière d'alerte si hors ligne
                  if (shouldShowBanner) ...[
                    const SizedBox(height: 12),
                    _buildConnectionAlertBanner(l10n),
                    const SizedBox(height: 12),
                  ],

                  // Contenu principal
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _isEditing 
                            ? _buildEditableFields(l10n, context)
                            : _buildReadOnlyFields(l10n),
                      ),
                    ),
                  ),

                  // Bouton de sauvegarde (seulement si édition ET en ligne)
                  if (_isEditing) 
                    _buildSaveButton(l10n),
                ],
              ),
            ),
          );
        },
      );
    
      }
    )
  );

  }

Widget _buildNoConnectionWidget() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wifi_off, size: 64, color: Colors.orange),
        SizedBox(height: 20),
        Text(
          'Connexion Internet requise',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'Veuillez vous connecter à Internet pour afficher vos informations',
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loadUserData,
          child: Text('Réessayer'),
        ),
      ],
    ),
  );
}
// Méthodes auxiliaires
Widget _buildConnectionAlertBanner(AppLocalizations? l10n) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.wifi_off, color: Colors.orange.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.pasconnexioninternet ?? 'Pas de connexion Internet',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
              Text(
               
                'Connectez-vous pour modifier vos informations',
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _showNoConnectionSnackbar() {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n?.verificationinternet ?? 'Veuillez vérifier votre connexion internet'),
      backgroundColor: AppColors.error,
    ),
  );
}

List<Widget> _buildEditableFields(AppLocalizations? l10n, BuildContext context) {
  return [
    AppFormFields.buildModernTextField(
      controller: _firstNameController,
      label: l10n?.prenom ?? 'Prénom',
      icon: Icons.person_outline,
      validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
      context: context,
    ),
    const SizedBox(height: 16),
   AppFormFields.buildModernTextField(
      controller: _lastNameController,
      label: l10n?.nom ?? 'Nom',
      icon: Icons.person_outline,
      validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
      context: context,
    ),
       const SizedBox(height: 16),
    AppFormFields.buildModernTextField(
      controller: _emailController,
      label: l10n?.email ?? 'Email',
      icon: Icons.email_outlined,
      validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
      context: context,
    ),
           const SizedBox(height: 16),
    AppFormFields.buildModernTextField(
      controller: _addressController,
      label: l10n?.address ?? 'Adresse',
      icon: Icons.location_on_outlined,
      validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
      context: context,
    ),
           const SizedBox(height: 16),
    AppFormFields.buildModernTextField(
      controller: _phoneController,
      label: l10n?.phone ?? 'Téléphone',
      icon: Icons.phone_outlined,
      validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
      context: context,
    ),
    
  ];
}

List<Widget> _buildReadOnlyFields(AppLocalizations? l10n) {
  return [
    _buildInfoRow(Icons.person_outline, 'Prénom', _userData?['prenom'] ?? ''),
    _buildInfoRow(Icons.person_outline, 'Nom', _userData?['nom'] ?? ''),
    _buildInfoRow(Icons.email_outlined, 'Email', _userData?['email'] ?? ''),
    _buildInfoRow(Icons.location_on_outlined, 'Adresse', _userData?['adresse'] ?? ''),
    _buildInfoRow(Icons.phone_outlined, 'Téléphone', _userData?['telephone'] ?? ''),
  ];
}

Widget _buildSaveButton(AppLocalizations? l10n) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isLoading ? null : _updateUserData,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const CircularProgressIndicator()
          : Text(l10n?.sauvgarder ?? 'Sauvegarder'),
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
   precacheImage(AssetImage('images/mukhlislogo1.png'), context);
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
                                width: 220,
                                height: 220,
                               
                               child: Image.asset(
  isDarkMode ? 'images/mukhlislogo1.png' : 'images/mukhlislogo1.png',
  width: 240,
  height: 240,
  fit: BoxFit.cover,
  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
    if (wasSynchronouslyLoaded) return child;
    return AnimatedOpacity(
      child: child,
      opacity: frame == null ? 0 : 1,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  },
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
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.light;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title:  Row(
            children: [
              Icon(Icons.logout, color: AppColors.error),
              SizedBox(width: 12),
              Text(
               l10n?.deconection ??  'Déconnexion',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18 ,color: isDarkMode ? AppColors.surface : AppColors.darkSurface),
              ),
            ],
          ),
          content:  Text(
          l10n?.etresur ??  'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(fontSize: 16 , color: isDarkMode ? AppColors.surface : AppColors.darkSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:  Text(
               l10n?.cancel ?? 'Annuler',
                style: TextStyle(color: AppColors.surface),
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
              child:  Text(
               l10n?.deconection ?? 'Déconnecter',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
