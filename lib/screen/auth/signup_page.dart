import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:mukhliss/theme/app_theme.dart';

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
      await authService.signUpClient(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        adr: _addressController.text.trim(),
      );

      if (mounted) {
        _showSuccessSnackbar('Inscription réussie!');
        Navigator.pushReplacementNamed(context, AppRouter.main);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erreur d\'inscription: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authProvider);
      await authService.signUpWithGoogle();
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, AppRouter.main);
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erreur lors de la connexion Google: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authProvider);
      await authService.signUpWithFacebook();
      Navigator.pushReplacementNamed(context, AppRouter.main);
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erreur Facebook: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade600,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade600,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                                      child: _buildModernTextField(
                                        controller: _firstNameController,
                                        label: 'Prénom',
                                        icon: Icons.person_outline_rounded,
                                        validator:
                                            (value) =>
                                                value?.isEmpty ?? true
                                                    ? 'Requis'
                                                    : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildModernTextField(
                                        controller: _lastNameController,
                                        label: 'Nom',
                                        icon: Icons.badge_outlined,
                                        validator:
                                            (value) =>
                                                value?.isEmpty ?? true
                                                    ? 'Requis'
                                                    : null,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Email
                                _buildModernTextField(
                                  controller: _emailController,
                                  label: 'Adresse email',
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Requis';
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value!)) {
                                      return 'Email invalide';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Phone
                                _buildModernTextField(
                                  controller: _phoneController,
                                  label: 'Numéro de téléphone',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Requis';
                                    if (value!.length < 10)
                                      return 'Numéro invalide';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Address
                                _buildModernTextField(
                                  controller: _addressController,
                                  label: 'Adresse complète',
                                  icon: Icons.location_on_outlined,
                                  maxLines: 2,
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Requis'
                                              : null,
                                ),

                                const SizedBox(height: 24),

                                // Password
                                _buildModernPasswordField(
                                  controller: _passwordController,
                                  label: 'Mot de passe',
                                  isObscure: _obscurePassword,
                                  onToggleVisibility:
                                      () => setState(
                                        () =>
                                            _obscurePassword =
                                                !_obscurePassword,
                                      ),
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Requis';
                                    if (value!.length < 6)
                                      return 'Minimum 6 caractères';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Confirm Password
                                _buildModernPasswordField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirmer le mot de passe',
                                  isObscure: _obscureConfirmPassword,
                                  onToggleVisibility:
                                      () => setState(
                                        () =>
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword,
                                      ),
                                  validator: (value) {
                                    if (value != _passwordController.text) {
                                      return 'Les mots de passe ne correspondent pas';
                                    }
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
                                        'Créer mon compte',
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

                          // Divider with "ou"
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

                          // Google Sign-In Button
                          _buildSocialButton(
                            imagePath: 'images/google_logo.png',
                            label: 'Continuer avec Google',
                            onPressed:  _handleGoogleSignIn,
                          ),

                          const SizedBox(height: 16),

                          // Facebook Sign-In Button (optionnel)
                    

                          const SizedBox(height: 24),

                          // Lien vers la connexion
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Vous avez déjà un compte ?',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.pushReplacementNamed(
                                      context,
                                      AppRouter.login,
                                    ),
                                child: Text(
                                  'Se connecter',
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
          Image.asset(
            imagePath,
            width: 24,
            height: 24,
          ),
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
  
  
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade900,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: AppColors.purpleDark.withOpacity(0.7),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            errorStyle: TextStyle(color: Colors.red.shade600, fontSize: 13),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildModernPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade900,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_outline,
              color: AppColors.purpleDark.withOpacity(0.7),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed: onToggleVisibility,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            errorStyle: TextStyle(color: Colors.red.shade600, fontSize: 13),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildFloatingTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textCapitalization:
          maxLines == 1 ? TextCapitalization.words : TextCapitalization.none,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          child: Icon(icon, color: AppColors.purpleDark, size: 22),
        ),
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: AppColors.purpleDark,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.purpleDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildFloatingPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          child: Icon(
            Icons.lock_outline_rounded,
            color: AppColors.purpleDark,
            size: 22,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.grey.shade600,
            size: 22,
          ),
          onPressed: onToggleVisibility,
        ),
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: AppColors.purpleDark,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.purpleDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _modernSocialButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
