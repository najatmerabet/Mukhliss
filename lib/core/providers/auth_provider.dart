/// ============================================================
/// DEPRECATED - Auth Provider
/// ============================================================
///
/// @deprecated Utiliser features/auth/auth.dart à la place
///
/// Migration:
/// ```dart
/// // Ancien
/// import 'package:mukhliss/core/providers/auth_provider.dart';
///
/// // Nouveau
/// import 'package:mukhliss/features/auth/auth.dart';
/// ```
library;

// Réexporter depuis features/auth pour compatibilité
export 'package:mukhliss/features/auth/presentation/providers/auth_providers.dart'
    show
        authClientProvider,
        currentUserProvider,
        currentClientIdProvider,
        authStateProvider,
        isAuthenticatedProvider,
        isPasswordResetFlowProvider,
        AuthFlowHelper,
        AuthState,
        AuthNotifier,
        authNotifierProvider;
