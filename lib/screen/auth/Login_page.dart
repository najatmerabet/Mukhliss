import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/screen/auth/Otp_Verification_page.dart';
import 'package:mukhliss/theme/app_theme.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:mukhliss/utils/validators.dart';

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
      await ref.read(authProvider).login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.clientHome);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erreur de connexion: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent.shade200,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showEmailResetDialog() {
    final emailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                labelText: 'Email',
                hintText: 'votre@email.com',
                prefixIcon: Icon(Icons.email, color: AppColors.purpleDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.purpleDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.purpleDark, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>Validators.validateEmaillogin(value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.purpleDark.withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Un code OTP vous sera envoyé par email',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
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
              'Annuler',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty || 
                  !emailController.text.contains('@')) {
                Navigator.pop(context);
                _showErrorSnackbar('Veuillez entrer un email valide');
                return;
              }

              Navigator.pop(context);
              await _sendResetOtpEmail(emailController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purpleDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Envoyer le code',
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
      await ref.read(authProvider).sendPasswordResetOtpEmail(email);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(email: email),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
              Colors.grey.shade100,
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
                  const SizedBox(height: 40),
                  
                  // Logo et titre
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.purpleDark.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_open_rounded,
                            size: 60,
                            color: AppColors.purpleDark,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Bienvenue',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.purpleDark,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connectez-vous pour continuer',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey.shade600,
                              ),
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
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Email',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        // Champ Email
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'votre@email.com',
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.purpleDark),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.purpleDark, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.redAccent.shade200),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value)=>Validators.validateEmaillogin(value),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Label Mot de passe
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Mot de passe',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        // Champ Mot de passe
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: Icon(Icons.lock_outline, color: AppColors.purpleDark),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.purpleDark, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.redAccent.shade200),
                            ),
                          ),
                          validator:(value)=> Validators.validatePassword(value)
                        ),
                        
                        // Mot de passe oublié
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _showEmailResetDialog,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(top: 4, bottom: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
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
                              shadowColor: AppColors.purpleDark.withOpacity(0.4),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
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
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'ou',
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
                        
                        // Boutons de connexion sociale
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialButton(
                              icon: Icons.g_mobiledata_rounded,
                              iconColor: Colors.red,
                              backgroundColor: Colors.white,
                              onTap: () {
                                // Implémenter la connexion avec Google
                              },
                            ),
                            const SizedBox(width: 16),
                            _socialButton(
                              icon: Icons.facebook_rounded,
                              iconColor: Colors.blue.shade800,
                              backgroundColor: Colors.white,
                              onTap: () {
                                // Implémenter la connexion avec Facebook
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Inscription
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Pas encore de compte ?',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 15,
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
                                'Créer un compte',
                                style: TextStyle(
                                  color: AppColors.purpleDark,
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
  
  Widget _socialButton({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.grey.shade200,
          //     blurRadius: 8,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}