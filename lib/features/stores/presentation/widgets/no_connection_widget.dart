/// ============================================================
/// No Connection Widget - Presentation Layer
/// ============================================================
///
/// Widget affiché quand il n'y a pas de connexion internet.
/// Extrait de location_screen.dart pour respecter SRP.
library;

import 'package:flutter/material.dart';
import 'package:mukhliss/core/theme/app_theme.dart';
import 'package:mukhliss/l10n/app_localizations.dart';

/// Widget affiché en cas d'absence de connexion
class NoConnectionWidget extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback? onRetry;
  final bool isRetrying;

  const NoConnectionWidget({
    super.key,
    required this.isDarkMode,
    this.onRetry,
    this.isRetrying = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.error.withValues(alpha: 0.1),
                    AppColors.warning.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: isDarkMode ? Colors.white70 : AppColors.error,
              ),
            ),
            const SizedBox(height: 32),

            // Titre
            Text(
              l10n?.errorNetworkNoConnection ?? 'Pas de connexion',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              l10n?.description ??
                  'Vérifiez votre connexion internet et réessayez.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    isDarkMode
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Bouton réessayer
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: isRetrying ? null : onRetry,
                icon:
                    isRetrying
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.refresh),
                label: Text(
                  isRetrying
                      ? 'Connexion en cours...'
                      : (l10n?.retry ?? 'Réessayer'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget de vérification de connexion (loading state)
class ConnectivityCheckWidget extends StatelessWidget {
  final bool isDarkMode;

  const ConnectivityCheckWidget({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Vérification de la connexion...',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
