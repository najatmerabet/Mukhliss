// ignore_for_file: unrelated_type_equality_checks

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/l10n/app_localizations.dart';
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:mukhliss/routes/app_router.dart';
import 'package:mukhliss/utils/error_handler.dart';
import 'package:mukhliss/utils/snackbar_helper.dart';


enum OtpVerificationType { signup, passwordReset }

class OtpVerificationPage extends ConsumerStatefulWidget {
  final String email;
  final OtpVerificationType type;

  const OtpVerificationPage({Key? key, required this.email, required this.type})
    : super(key: key);

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _remainingMinutes = 1;
  int _remainingSeconds = 0;
  late Timer _timer;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startTimer();

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();

    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (timer) {
      if (_remainingMinutes == 0 && _remainingSeconds == 0) {
        setState(() => timer.cancel());
      } else {
        setState(() {
          if (_remainingSeconds == 0) {
            _remainingMinutes--;
            _remainingSeconds = 59;
          } else {
            _remainingSeconds--;
          }
        });
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

// dans votre widget… 

Future<void> _verifyOtp() async {
  final l10n = AppLocalizations.of(context);
  if (_otpCode.length != 6) {
    _showErrorSnackbar('Le code doit contenir 6 chiffres');
    return;
  }

  setState(() => _isLoading = true);
  HapticFeedback.lightImpact();


  try {
    if (widget.type == OtpVerificationType.passwordReset) {
      await ref.read(authProvider)
        .verifyPasswordResetOtp(email: widget.email, token: _otpCode);
      
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRouter.passwordReset,
          arguments: widget.email,
        );
      }

    } else {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      await ref.read(authProvider)
        .verifySignupOtp(email: widget.email, token: _otpCode);

      await ref.read(authProvider)
        .completeSignupAfterOtpVerification(
          email: widget.email,
          password: args['password'],
          firstName: args['firstName'],
          lastName: args['lastName'],
          phone: args['phone'],
          address: args['address'],
        );

      if (mounted) {
        showSuccessSnackbar(
          context: context,
          message: l10n!.signupSuccess, // ou string direct
        );
        Navigator.pushReplacementNamed(context, AppRouter.main);
      }
    }

  } catch (e) {
        final errorMessage = AuthErrorHandler(context).handle(e);

    // Qu’importe le type d’erreur, tout passe par votre handler
    _showErrorSnackbar(errorMessage);
    debugPrint('Erreur OTP: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _resendOtp() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _remainingMinutes = 1;
      _remainingSeconds = 0;
      _startTimer();
      _isLoading = true;
    });

    // Clear existing OTP
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();

    HapticFeedback.mediumImpact();

    try {
      if (widget.type == OtpVerificationType.passwordReset) {
        await ref.read(authProvider).sendPasswordResetOtp(widget.email);
      } else {
        await ref.read(authProvider).sendSignupOtpWithRetry(widget.email);
      }

      if (mounted) {
        _showSuccessSnackbar(l10n?.nouveaucodeenvoye ??'Nouveau code envoyé');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erreur: ${e.toString()}');
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
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

Widget _buildOtpField(int index) {
  return Directionality(
    textDirection: TextDirection.ltr, // Force LTR pour chaque champ
    child: Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? Theme.of(context).primaryColor
              : _controllers[index].text.isNotEmpty
              ? Colors.green.shade400
              : Colors.grey.shade300,
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
        color: _controllers[index].text.isNotEmpty
            ? Colors.green.shade50
            : Colors.grey.shade50,
        boxShadow: _focusNodes[index].hasFocus
            ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr, // Force la direction du texte
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }

          // Auto-verify when all fields are filled
          if (_otpCode.length == 6) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_otpCode.length == 6) _verifyOtp();
            });
          }

          setState(() {});
        },
        onTap: () {
          if (_controllers[index].text.isNotEmpty) {
            _controllers[index].selection = TextSelection.fromPosition(
              TextPosition(offset: _controllers[index].text.length),
            );
          }
        },
      ),
    ),
  );
}

  Widget _buildTimerDisplay() {
    final bool isExpired = _remainingMinutes == 0 && _remainingSeconds == 0;
    final l10n = AppLocalizations.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isExpired
                  ? [Colors.red.shade100, Colors.red.shade50]
                  : [Colors.blue.shade100, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired ? Colors.red.shade200 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExpired ? Icons.timer_off : Icons.timer,
                color: isExpired ? Colors.red.shade600 : Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isExpired ? l10n?.codeexpire??'Code expiré' : l10n?.codeexpiredans ??'Code expire dans',
                style: TextStyle(
                  color: isExpired ? Colors.red.shade700 : Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (!isExpired) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTimeUnit(
                  _remainingMinutes.toString().padLeft(2, '0'),
                  'min',
                ),
                const SizedBox(width: 4),
                Text(
                  ':',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 4),
                _buildTimeUnit(
                  _remainingSeconds.toString().padLeft(2, '0'),
                  'sec',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.blue.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bool isTimerFinished =
        _remainingMinutes == 0 && _remainingSeconds == 0;
    final title =
        widget.type == OtpVerificationType.passwordReset
            ? (l10n?.renitialisation ?? l10n?.verification ?? 'Vérification')
            : (l10n?.verification ?? 'Vérification');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Animated Icon
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title and Description
                  Text(
                    l10n?.codeverifecation ?? 'Code de vérification',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(text: l10n?.envoyerunode ?? 'Nous avons envoyé un code à '),
                        TextSpan(
                          text: widget.email,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Timer Display
                  _buildTimerDisplay(),

                  const SizedBox(height: 40),

                  // OTP Input Fields
                 Directionality(
  textDirection: TextDirection.ltr,
  child: Column(
    children: [
      // Titre optionnel en respectant la langue
      Directionality(
        textDirection: Directionality.of(context),
        child: Text(
          l10n?.entrercode ?? 'Entrez le code',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      SizedBox(height: 20),
      // Champs OTP toujours LTR
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          6,
          (index) => _buildOtpField(index),
        ),
      ),
    ],
  ),
),


                  const SizedBox(height: 40),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading || _otpCode.length != 6
                              ? null
                              : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _otpCode.length == 6 ? 4 : 0,
                        shadowColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.3),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                              :  Text(
                               l10n?.verifier ?? 'VÉRIFIER',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Resend Button
                  AnimatedOpacity(
                    opacity: isTimerFinished && !_isLoading ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: TextButton.icon(
                      onPressed:
                          isTimerFinished && !_isLoading ? _resendOtp : null,
                      icon: const Icon(Icons.refresh),
                      label:  Text(
                      l10n?.renvoyercode ??  'Renvoyer le code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
