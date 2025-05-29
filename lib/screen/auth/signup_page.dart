

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:mukhliss/screen/auth/Otp_Verification_page.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:mukhliss/utils/validators.dart';


import 'package:mukhliss/utils/form_field_helpers.dart';
import 'package:mukhliss/utils/snackbar_helper.dart';


class ClientSignup extends ConsumerStatefulWidget {
  const ClientSignup({Key? key}) : super(key: key);

  @override
  ConsumerState<ClientSignup> createState() => _SignUpClientState();
}

class _SignUpClientState extends ConsumerState<ClientSignup>
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

  @override
  void initState() {
    super.initState();
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

 Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final authService = ref.read(authProvider);
    
    // 1. Envoyer l'OTP d'abord
    await authService.sendSignupOtp(_emailController.text.trim());

    // 2. Naviguer vers la page de vérification OTP
    if (mounted) {
      Navigator.pushNamed(
        context,
        AppRouter.otpVerification,
        arguments: {
          'email': _emailController.text.trim(),
          'type': OtpVerificationType.signup,
          // Passer les autres données nécessaires pour la création du compte
          'password': _passwordController.text,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
        },
      );
    }
  } catch (e) {
    if (mounted) {
      print('Erreur lors de l\'envoi du code: ${e.toString()}');
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.purpleDark.withOpacity(0.20),
              AppColors.purpleDark.withOpacity(0.10),
              AppColors.purpleDark.withOpacity(0.02),
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
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  child:
                                  // Fully circular for logo
                                  Image.asset(
                                    'images/withoutbg.png', // Path to your logo asset
                                    width:
                                        250, // Same size as the previous icon
                                    height: 250,
                                    fit:
                                        BoxFit.contain, // Preserve aspect ratio
                                  ),
                                ),

                                Text(
                                  l10n?.creecompte ??
                                  'Créer un compte',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.purpleDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                l10n?.regoinez??
                                  'Rejoignez notre communauté',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 50),
                              ],
                            ),
                          ),

                          // Form Fields - No white background
                          Form(
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
                                        label:l10n?.prenom ?? 'Prénom',
                                        icon: Icons.person_outline_rounded,
                                        validator:
                                            (value) =>Validators.validateRequired(value,context)
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppFormFields.buildModernTextField(
                                        context: context,
                                        controller: _lastNameController,
                                        label:l10n?.nom ?? 'Nom',
                                        icon: Icons.badge_outlined,
                                        validator:
                                            (value) => Validators.validateRequired(value,context)
                                                
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Email
                                AppFormFields.buildModernTextField(
                                  context: context,
                                  controller: _emailController,
                                  label:l10n?.adresseemail ?? 'Adresse email',
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                 validator: (value) {
                                 final requiredError = Validators.validateRequired(value, context);
                                 if (requiredError != null) return requiredError; // Affiche l'erreur si vide

                                 final emailError = Validators.validateEmail(value, context);
                                 if (emailError != null) return emailError; // Affiche l'erreur si email invalide

                                     return null; // ✅ Valide
                                    },
                                ),

                                const SizedBox(height: 24),

                                // Phone
                                AppFormFields.buildModernTextField(
                                  context: context,
                                  controller: _phoneController,
                                  label:l10n?.numphone ?? 'Numéro de téléphone',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (value) {
                                  final requiredError=  Validators.validateRequired(value,context);
                                   if (requiredError != null) return requiredError;
                                  final phoneError = Validators.validatePhone(value,context);
                                    if (phoneError != null) return phoneError;
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Address
                                AppFormFields.buildModernTextField(
                                  context: context,
                                  controller: _addressController,
                                  label:l10n?.adressecomplet ?? 'Adresse complète',
                                  icon: Icons.location_on_outlined,
                                  maxLines: 2,
                                  validator:
                                      (value){final requirederror=Validators.validateRequired(value,context);
                                        if (requirederror != null) return requirederror;
                                    return null;} 
                                ),

                                const SizedBox(height: 24),

                                // Password
                                AppFormFields.buildModernPasswordField(
                                  context: context,
                                  controller: _passwordController,
                                  label:l10n?.password ?? 'Mot de passe',
                                  isObscure: _obscurePassword,
                                  onToggleVisibility:
                                      () => setState(
                                        () =>
                                            _obscurePassword =
                                                !_obscurePassword,
                                      ),
                                  validator: (value) {
                           final  errorrequired= Validators.validateRequired(value,context);
                           if(errorrequired!=null)return errorrequired;
                                final errorpassword=    Validators.validatePassword(value,context);
                                if(errorpassword !=null) return errorpassword;
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Confirm Password
                                AppFormFields.buildModernPasswordField(
                                  context: context,
                                  controller: _confirmPasswordController,
                                  label:l10n?.confirmepassword ??  'Confirmer le mot de passe',
                                  isObscure: _obscureConfirmPassword,
                                  onToggleVisibility:
                                      () => setState(
                                        () =>
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword,
                                      ),
                                  validator: (value) {
                                final errorvalidatepassword=    Validators.validateConfirmPassword(value, _passwordController.text,context);
                                if(errorvalidatepassword !=null)return errorvalidatepassword;
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Submit Button
                          SizedBox(
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeWidth: 2.5,
                                      )
                                      : Text(
                                       l10n?.creecompte ?? 'Créer mon compte',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),

                          const SizedBox(height: 32),
                          // Lien vers la connexion
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                             l10n?.vousavezcompte ??   'Vous avez déjà un compte ?',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.pushReplacementNamed(
                                      context,
                                      AppRouter.login,
                                    ),
                                child: Text(
                              l10n?.connecter ??    'Se connecter',
                                  style: TextStyle(
                                    color: AppColors.purpleDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}
