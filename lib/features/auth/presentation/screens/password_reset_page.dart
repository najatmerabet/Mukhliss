import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukhliss/core/routes/app_router.dart';
import 'package:mukhliss/core/utils/snackbar_helper.dart';
import 'package:mukhliss/core/core.dart'; // ✅ Nouveau système

class PasswordResetPage extends ConsumerStatefulWidget {
  final String email;

  const PasswordResetPage({super.key, required this.email});

  @override
  ConsumerState<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends ConsumerState<PasswordResetPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 6 caractères'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ✅ Utiliser le nouveau système d'auth
      final authClient = ref.read(authClientProvider);
      final result = await authClient.updatePassword(
        _newPasswordController.text,
      );

      result.when(
        success: (_) {
          // ✅ Désactiver le flag de reset password
          AuthFlowHelper.endPasswordResetFlow();

          if (mounted) {
            showSuccessSnackbar(
              context: context,
              message: "Mot de passe mis à jour avec succès",
            );
            Navigator.pushReplacementNamed(context, AppRouter.main);
          }
        },
        failure: (error) {
          AppLogger.auth(
            'Erreur update password',
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
      showErrorSnackbar(context: context, message: e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réinitialisation du mot de passe')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Réinitialisation pour ${widget.email}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(),
                hintText: 'Minimum 6 caractères',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Mettre à jour le mot de passe'),
            ),
          ],
        ),
      ),
    );
  }
}
