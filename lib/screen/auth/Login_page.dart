import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/screen/auth/Otp_Verification_page.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:mukhliss/utils/error_handler.dart';
import 'package:mukhliss/utils/form_field_helpers.dart';
import 'package:mukhliss/utils/snackbar_helper.dart';
import 'package:mukhliss/utils/validators.dart';

import 'package:mukhliss/providers/langue_provider.dart';
import 'package:mukhliss/providers/theme_provider.dart';
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);
  try {
    await ref
      .read(authProvider)
      .login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.main);
    }
  } catch (e) {
    // Delegate *all* errors (AuthException, PostgrestException,
    // SocketException, TimeoutException, anything else) to your handler:
    // ignore: use_build_context_synchronously
    final errorMessage = AuthErrorHandler(context).handle(e);
    if (mounted) {
      showErrorSnackbar(
        context: context,
        message: errorMessage,
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
Widget _buildLanguageDropdown(BuildContext context) {
  final currentLanguage = ref.watch(languageProvider.notifier).currentLanguageOption;

  return PopupMenuButton<LanguageOption>(
    icon: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        currentLanguage.flag,
        style: const TextStyle(fontSize: 20),
      ),
    ),
    onSelected: (LanguageOption option) {
      ref.read(languageProvider.notifier).changeLanguage(option.locale);
    },
    itemBuilder: (BuildContext context) {
      return LanguageNotifier.supportedLanguages.map((LanguageOption option) {
        return PopupMenuItem<LanguageOption>(
          value: option,
          child: Row(
            children: [
              Text(option.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(option.name),
            ],
          ),
        );
      }).toList();
    },
  );
}
  void _showEmailResetDialog() {
    final emailController = TextEditingController(text: _emailController.text);
  final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
   final isDarkMode = themeMode == AppThemeMode.light;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
             backgroundColor:isDarkMode ? AppColors.darkPrimary :AppColors.surface,
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
                    labelText:l10n?.email ?? 'Email',
                    hintText: 'votre@email.com',
                    prefixIcon: Icon(Icons.email, color: AppColors.purpleDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.purpleDark),
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
                  validator: (value) {
                    Validators.validateEmaillogin(value,context);
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.purpleDark.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Un code OTP vous sera envoyé par email',
                        style: TextStyle(
                          fontSize: 14,
                          color:isDarkMode ? AppColors.surface: Colors.grey.shade700,
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
                  style: TextStyle(color:isDarkMode ? AppColors.surface : Colors.grey.shade700),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (emailController.text.trim().isEmpty ||
                      !emailController.text.contains('@')) {
                    Navigator.pop(context);
                    showErrorSnackbar(
                      context: context,
                      message:l10n?.emailinvalide ?? 'Veuillez entrer un email valide',
                    );
                    return;
                  }

                  Navigator.pop(context);
                  await _sendResetOtpEmail(emailController.text.trim());
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
                child:  Text(
                 l10n?.envoiencours ?? 'Envoyer le code',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

Future<void> _sendResetOtpEmail(String email) async {
  setState(() => _isLoading = true);
  try {
    await ref.read(authProvider).sendPasswordResetOtp(email);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationPage(
            email: email,
            type: OtpVerificationType.passwordReset, // Add this parameter
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      showErrorSnackbar(context: context, message: 'Erreur: ${e.toString()}');
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  @override
  Widget build(BuildContext context) {
     final l10n = AppLocalizations.of(context);
      final themeMode = ref.watch(themeProvider);
   final isDarkMode = themeMode == AppThemeMode.light;
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode ? [AppColors.darkWhite,AppColors.darkGrey50 , AppColors.darkPurpleDark]: [
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
                  Padding(
                   padding: const EdgeInsets.only(top: 16.0),
                     child: Align(
                 alignment: Alignment.topRight,
                     child: _buildLanguageDropdown(context),
                    ),
                    ),
                  const SizedBox(height: 40),

                  // Logo et titre
                  Center(
                    child: Column(
                      children: [
                        Container(
                          child:
                          // Fully circular for logo
                          Image.asset(
                            'images/withoutbg.png', // Path to your logo asset
                            width: 250, // Same size as the previous icon
                            height: 250,
                            fit: BoxFit.contain, // Preserve aspect ratio
                          ),
                        ),

                        Text(
                          l10n?.welcome ??
                          'Bienvenue',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.purpleDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n?.connectezvous ??
                          'Connectez-vous pour continuer',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Formulaire de connexion
                  Form(
                    key: _formKey,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label Email

                        AppFormFields.buildModernTextField(
                          context: context,
                          controller: _emailController,
                          label:l10n?.email ?? 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator:
                              (value) => Validators.validateEmaillogin(value,context),
                          hintText: 'votre@email.com',
                        ),
                        const SizedBox(height: 24),

                        AppFormFields.buildModernPasswordField(
                          context: context,
                          controller: _passwordController,
                          label:l10n?.password ?? 'Mot de passe',
                          isObscure: _obscurePassword,
                          onToggleVisibility:
                              () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                          validator:
                              (value) => Validators.validatePassword(value,context),
                          hintText: '••••••••',

                        ),
                        // Mot de passe oublié
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                _isLoading ? null : _showEmailResetDialog,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(top: 4, bottom: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              l10n?.forgetpassword ??
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                color: AppColors.purpleDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Bouton de connexion
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purpleDark,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              shadowColor: AppColors.purpleDark.withOpacity(
                                0.4,
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                    :  Text(
                                      l10n?.connecter ??
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Séparateur
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                l10n?.ou ??
                                'ou',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Boutons de connexion sociale
                        Center(
                          child: _buildSocialButton(
                            imagePath: 'images/google_logo.png',
                            label:l10n?.connecteravecgoogle ?? 'Se connecter avec Google',
                            onPressed: () async {
                              setState(() => _isLoading = true);
                              try {
                                await ref.read(authProvider).signInWithGoogle();
                                if (mounted) {
                                  Navigator.pushReplacementNamed(
                                    // ignore: use_build_context_synchronously
                                    context,
                                    AppRouter.main,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  showErrorSnackbar(
                                    // ignore: use_build_context_synchronously
                                    context: context,
                                    message:
                                        'Erreur de connexion: ${e.toString()}',
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Inscription
                       Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Expanded(  // Add this
      child: Text(
        l10n?.pasdecompte ?? 'Pas encore de compte ?',
        style: TextStyle(
          color:isDarkMode? AppColors.lightGrey50 :AppColors.darkGrey50,
          fontSize: 15,
        ),
        textAlign: TextAlign.center,  // Add this to center the text
      ),
    ),
    TextButton(
      onPressed: () {
        Navigator.pushNamed(
          context,
          AppRouter.signupClient,
        );
      },
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        l10n?.creecompte ?? 'Créer un compte',
        style: TextStyle(
          color:isDarkMode ? AppColors.lightPrimary:AppColors.darkPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    ),
  ],
),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
      ),
    );
  }

  Widget _buildSocialButton({
    required String imagePath,
    required String label,
    required Function() onPressed, // Accepts both sync and async functions
    Color? backgroundColor,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
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
