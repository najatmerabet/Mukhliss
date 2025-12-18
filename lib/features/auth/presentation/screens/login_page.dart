/// ============================================================
/// MUKHLISS - Page de Connexion (Migrée vers Clean Architecture)
/// ============================================================
///
/// Cette version utilise:
/// - authNotifierProvider (nouveau système)
/// - AppLogger (au lieu de print/debugPrint)
/// - ref.listen pour la navigation (meilleure pratique)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/core/routes/app_router.dart';
import 'package:mukhliss/core/utils/form_field_helpers.dart';
import 'package:mukhliss/core/utils/snackbar_helper.dart';
import 'package:mukhliss/core/utils/validators.dart';

// ✅ Core inclut: AppLogger, themeProvider, OtpVerificationType, OtpVerificationPage
import 'package:mukhliss/core/core.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isImageLoaded = false;
  bool _hasStartedLoading = false;

  @override
  void initState() {
    super.initState();
    AppLogger.navigation('LoginPage initialisée');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStartedLoading) {
      _hasStartedLoading = true;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      await precacheImage(const AssetImage('images/mukhlislogo1.png'), context);
      if (mounted) {
        setState(() => _isImageLoaded = true);
      }
    } catch (e) {
      AppLogger.warning('Erreur chargement image', tag: 'LoginPage', error: e);
      if (mounted) {
        setState(() => _isImageLoaded = true);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ✅ Login utilisant le nouveau système
  void _login() {
    if (!_formKey.currentState!.validate()) return;

    AppLogger.auth('Tentative de connexion: ${_emailController.text.trim()}');

    // ✅ Utilise le nouveau provider
    ref
        .read(authNotifierProvider.notifier)
        .signIn(_emailController.text.trim(), _passwordController.text.trim());
  }

  /// ✅ Connexion Google utilisant le nouveau système
  void _loginWithGoogle() {
    AppLogger.auth('Tentative connexion Google');
    ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  void _showEmailResetDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = themeMode == AppThemeMode.dark; // ✅ Correction du bug

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDarkMode ? AppColors.darkPrimary : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Réinitialisation par email',
              style: TextStyle(
                color: AppColors.purpleDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: l10n?.email ?? 'Email',
                    hintText: 'votre@email.com',
                    prefixIcon: Icon(Icons.email, color: AppColors.purpleDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.purpleDark,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.purpleDark.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Un code OTP vous sera envoyé par email',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode
                                  ? AppColors.surface
                                  : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n?.cancel ?? 'Annuler',
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.surface : Colors.grey.shade700,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (emailController.text.trim().isEmpty ||
                      !emailController.text.contains('@')) {
                    Navigator.pop(context);
                    showErrorSnackbar(
                      context: context,
                      message:
                          l10n?.emailinvalide ??
                          'Veuillez entrer un email valide',
                    );
                    return;
                  }

                  Navigator.pop(context);
                  _sendResetOtp(emailController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n?.envoiencours ?? 'Envoyer le code',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _sendResetOtp(String email) async {
    AppLogger.auth('Envoi OTP reset pour: $email');

    final authClient = ref.read(authClientProvider);
    final result = await authClient.sendOtp(email, isRecovery: true);

    result.when(
      success: (_) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OtpVerificationPage(
                    email: email,
                    type: OtpVerificationType.passwordReset,
                  ),
            ),
          );
        }
      },
      failure: (error) {
        AppLogger.auth('Échec envoi OTP', level: LogLevel.error, error: error);
        if (mounted) {
          showErrorSnackbar(context: context, message: error.message);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == AppThemeMode.dark; // ✅ Correction du bug

    // ✅ Écouter l'état d'auth pour la navigation et les erreurs
    final authState = ref.watch(authNotifierProvider);

    // ✅ Écouter les changements d'état pour navigation/erreurs
    ref.listen<AuthState>(authNotifierProvider, (previous, current) {
      // Si authentifié, naviguer vers l'écran principal
      if (current.isAuthenticated) {
        AppLogger.auth('Connexion réussie, navigation vers home');
        Navigator.pushReplacementNamed(context, AppRouter.main);
      }

      // Si erreur, afficher le snackbar
      if (current.status == AuthStatus.error && current.errorMessage != null) {
        AppLogger.auth(
          'Erreur auth: ${current.errorMessage}',
          level: LogLevel.error,
        );
        showErrorSnackbar(context: context, message: current.errorMessage!);
        // Effacer l'erreur après affichage
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDarkMode
                    ? [
                      AppColors.darkWhite,
                      AppColors.darkGrey50,
                      AppColors.darkPurpleDark,
                    ]
                    : [
                      AppColors.lightWhite,
                      AppColors.lightGrey50,
                      AppColors.lightPurpleDark,
                    ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Align(alignment: Alignment.topRight),
                  ),
                  const SizedBox(height: 40),

                  // Logo et titre
                  _buildHeader(l10n),

                  const SizedBox(height: 40),

                  // Formulaire
                  _buildLoginForm(l10n, authState, isDarkMode),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations? l10n) {
    return Center(
      child: Column(
        children: [
          // Logo
          SizedBox(
            width: 250,
            height: 250,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child:
                  _isImageLoaded
                      ? TweenAnimationBuilder<double>(
                        key: const ValueKey('logo-loaded'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.7 + (0.3 * value.clamp(0.0, 1.0)),
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: Image.asset(
                          'images/mukhlislogo1.png',
                          width: 250,
                          height: 250,
                          fit: BoxFit.contain,
                        ),
                      )
                      : Center(
                        key: const ValueKey('logo-loading'),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: AppColors.purpleDark.withValues(alpha: 0.6),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 16),

          // Texte de bienvenue
          AnimatedOpacity(
            opacity: _isImageLoaded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: Column(
              children: [
                Text(
                  l10n?.welcome ?? 'Bienvenue',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.purpleDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.connectezvous ?? 'Connectez-vous pour continuer',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(
    AppLocalizations? l10n,
    AuthState authState,
    bool isDarkMode,
  ) {
    final isLoading = authState.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email
          AppFormFields.buildModernTextField(
            context: context,
            controller: _emailController,
            label: l10n?.email ?? 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => Validators.validateEmaillogin(value, context),
            hintText: 'votre@email.com',
          ),
          const SizedBox(height: 24),

          // Mot de passe
          AppFormFields.buildModernPasswordField(
            context: context,
            controller: _passwordController,
            label: l10n?.password ?? 'Mot de passe',
            isObscure: _obscurePassword,
            onToggleVisibility:
                () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) => Validators.validatePassword(value, context),
            hintText: '••••••••',
          ),

          // Mot de passe oublié
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : _showEmailResetDialog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                l10n?.forgetpassword ?? 'Mot de passe oublié ?',
                style: TextStyle(
                  color: AppColors.purpleDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Bouton Se connecter
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2.5,
                        ),
                      )
                      : Text(
                        l10n?.connecter ?? 'Se connecter',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),

          const SizedBox(height: 24),

          // Séparateur "ou"
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n?.ou ?? 'ou',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),

          const SizedBox(height: 24),

          // Bouton Google
          Center(
            child: _buildSocialButton(
              imagePath: 'images/google_logo.png',
              label: l10n?.connecteravecgoogle ?? 'Se connecter avec Google',
              onPressed: isLoading ? null : _loginWithGoogle,
            ),
          ),

          const SizedBox(height: 32),

          // Créer un compte
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  l10n?.pasdecompte ?? 'Pas encore de compte ?',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.lightGrey50
                            : AppColors.darkGrey50,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.signupClient);
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  l10n?.creecompte ?? 'Créer un compte',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.lightPrimary
                            : AppColors.darkPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String imagePath,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade800,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
