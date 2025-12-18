/// Page d'inscription migrée vers Clean Architecture.
library;

import 'package:mukhliss/core/logger/app_logger.dart';

// ============================================================
// MUKHLISS - Page d'Inscription (Migrée)
// ============================================================
//
// Cette version utilise:
// - authNotifierProvider (nouveau système)
// - AppLogger (au lieu de print)
// - ref.listen pour la navigation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/core/routes/app_router.dart';
import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/core/utils/validators.dart';
import 'package:mukhliss/core/utils/form_field_helpers.dart';
import 'package:mukhliss/core/utils/snackbar_helper.dart';

// ✅ Nouveau système (inclut OtpVerificationType)
import 'package:mukhliss/core/core.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    AppLogger.navigation('SignupPage initialisée');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImage();
  }

  Future<void> _precacheImage() async {
    try {
      await precacheImage(const AssetImage('images/mukhlislogo1.png'), context);
      if (mounted) {
        setState(() => _isImageLoaded = true);
      }
    } catch (e) {
      AppLogger.warning('Erreur chargement image', tag: 'SignupPage', error: e);
      if (mounted) {
        setState(() => _isImageLoaded = true);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// ✅ Soumettre le formulaire avec le nouveau système
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      AppLogger.auth('Envoi OTP pour: ${_emailController.text.trim()}');

      final authClient = ref.read(authClientProvider);
      final result = await authClient.sendOtp(_emailController.text.trim());

      result.when(
        success: (_) {
          AppLogger.auth('OTP envoyé avec succès');
          if (mounted) {
            Navigator.pushNamed(
              context,
              AppRouter.otpVerification,
              arguments: {
                'email': _emailController.text.trim(),
                'type': OtpVerificationType.signup,
                'password': _passwordController.text,
                'firstName': _firstNameController.text.trim(),
                'lastName': _lastNameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'address': _addressController.text.trim(),
              },
            );
          }
        },
        failure: (error) {
          AppLogger.auth(
            'Échec envoi OTP',
            level: LogLevel.error,
            error: error,
          );
          if (mounted) {
            showErrorSnackbar(context: context, message: error.message);
          }
        },
      );
    } catch (e) {
      AppLogger.auth('Erreur inattendue', level: LogLevel.error, error: e);
      if (mounted) {
        showErrorSnackbar(
          context: context,
          message: 'Erreur lors de l\'envoi du code: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDarkMode = ThemeUtils.isDarkMode(ref); // ✅ Utilise ThemeUtils

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
            physics: const BouncingScrollPhysics(),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Back Button
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: AppColors.purpleDark,
                              size: 20,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Header
                          _buildHeader(l10n),

                          // Form
                          _buildForm(l10n),

                          const SizedBox(height: 32),

                          // Submit Button
                          _buildSubmitButton(l10n),

                          const SizedBox(height: 32),

                          // Login Link
                          _buildLoginLink(l10n),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
          AnimatedOpacity(
            opacity: _isImageLoaded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Image.asset(
              'images/mukhlislogo1.png',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
          ),
          Text(
            l10n?.creecompte ?? 'Créer un compte',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.purpleDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.regoinez ?? 'Rejoignez notre communauté',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildForm(AppLocalizations? l10n) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name Fields
          Row(
            children: [
              Expanded(
                child: AppFormFields.buildModernTextField(
                  context: context,
                  controller: _firstNameController,
                  label: l10n?.prenom ?? 'Prénom',
                  icon: Icons.person_outline_rounded,
                  validator:
                      (value) => Validators.validateRequired(value, context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppFormFields.buildModernTextField(
                  context: context,
                  controller: _lastNameController,
                  label: l10n?.nom ?? 'Nom',
                  icon: Icons.badge_outlined,
                  validator:
                      (value) => Validators.validateRequired(value, context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Email
          AppFormFields.buildModernTextField(
            context: context,
            controller: _emailController,
            label: l10n?.adresseemail ?? 'Adresse email',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final requiredError = Validators.validateRequired(value, context);
              if (requiredError != null) return requiredError;
              final emailError = Validators.validateEmail(value, context);
              if (emailError != null) return emailError;
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Phone
          AppFormFields.buildModernTextField(
            context: context,
            controller: _phoneController,
            label: l10n?.numphone ?? 'Numéro de téléphone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              final requiredError = Validators.validateRequired(value, context);
              if (requiredError != null) return requiredError;
              final phoneError = Validators.validatePhone(value, context);
              if (phoneError != null) return phoneError;
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Address
          AppFormFields.buildModernTextField(
            context: context,
            controller: _addressController,
            label: l10n?.adressecomplet ?? 'Adresse complète',
            icon: Icons.location_on_outlined,
            maxLines: 2,
            validator: (value) {
              final requiredError = Validators.validateRequired(value, context);
              if (requiredError != null) return requiredError;
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Password
          AppFormFields.buildModernPasswordField(
            context: context,
            controller: _passwordController,
            label: l10n?.password ?? 'Mot de passe',
            isObscure: _obscurePassword,
            onToggleVisibility:
                () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              final errorRequired = Validators.validateRequired(value, context);
              if (errorRequired != null) return errorRequired;
              final errorPassword = Validators.validatePassword(value, context);
              if (errorPassword != null) return errorPassword;
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Confirm Password
          AppFormFields.buildModernPasswordField(
            context: context,
            controller: _confirmPasswordController,
            label: l10n?.confirmepassword ?? 'Confirmer le mot de passe',
            isObscure: _obscureConfirmPassword,
            onToggleVisibility:
                () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
            validator: (value) {
              final error = Validators.validateConfirmPassword(
                value,
                _passwordController.text,
                context,
              );
              if (error != null) return error;
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppLocalizations? l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purpleDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child:
            _isLoading
                ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                )
                : Text(
                  l10n?.creecompte ?? 'Créer mon compte',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  Widget _buildLoginLink(AppLocalizations? l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n?.vousavezcompte ?? 'Vous avez déjà un compte ?',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        TextButton(
          onPressed:
              () => Navigator.pushReplacementNamed(context, AppRouter.login),
          child: Text(
            l10n?.connecter ?? 'Se connecter',
            style: TextStyle(
              color: AppColors.purpleDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
