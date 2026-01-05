/// ============================================================
/// Auth Providers - Presentation Layer
/// ============================================================
///
/// Providers Riverpod pour l'authentification.
/// C'est le point d'entrée unique pour accéder à l'auth dans l'app.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/auth_types.dart';

// ============================================================
// CONFIGURATION
// ============================================================

/// Quel backend d'authentification utiliser?
enum AuthBackend {
  supabase,
  firebase, // Pour le futur
}

/// Configuration du backend actuel
const AuthBackend _currentBackend = AuthBackend.supabase;

// ============================================================
// PROVIDERS PRINCIPAUX
// ============================================================

/// Provider principal pour le client d'authentification
///
/// Usage:
/// ```dart
/// final authClient = ref.read(authClientProvider);
/// final result = await authClient.signInWithEmailPassword(...);
/// ```
final authClientProvider = Provider<IAuthClient>((ref) {
  switch (_currentBackend) {
    case AuthBackend.supabase:
      return SupabaseAuthClient();
    case AuthBackend.firebase:
      throw UnimplementedError('Firebase non implémenté');
  }
});

/// Provider pour l'utilisateur actuellement connecté
///
/// ⚠️ IMPORTANT: Ce provider dépend de authStateProvider pour être réactif
/// aux changements d'authentification (connexion/déconnexion/changement de compte)
///
/// Usage:
/// ```dart
/// final user = ref.watch(currentUserProvider);
/// if (user != null) {
///   print('Connecté: ${user.email}');
/// }
/// ```
final currentUserProvider = Provider<AppUser?>((ref) {
  // Écouter le stream d'authentification pour être réactif aux changements
  // Cela force le provider à se réévaluer quand l'utilisateur change
  final authStateAsync = ref.watch(authStateProvider);
  
  // Utiliser la valeur du stream si disponible, sinon fallback sur currentUser synchrone
  return authStateAsync.when(
    data: (user) => user,
    loading: () => ref.read(authClientProvider).currentUser,
    error: (_, __) => ref.read(authClientProvider).currentUser,
  );
});

/// Provider pour l'ID de l'utilisateur actuel
/// Réactif - se met à jour automatiquement lors du changement de compte
final currentClientIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});

/// Stream de l'état d'authentification
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authClientProvider).authStateChanges;
});

/// Provider pour savoir si l'utilisateur est connecté
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authClientProvider).isAuthenticated;
});

/// Provider pour le flow de reset password
final isPasswordResetFlowProvider = StateProvider<bool>((ref) => false);

// ============================================================
// AUTH FLOW HELPER
// ============================================================

/// Helper statique pour gérer les flags du flux d'authentification
///
/// Utilisé par les widgets qui n'ont pas accès facile aux providers.
class AuthFlowHelper {
  static bool isPasswordResetInProgress = false;

  /// Marquer le début du flux de reset password
  static void startPasswordResetFlow() {
    isPasswordResetInProgress = true;
  }

  /// Marquer la fin du flux de reset password
  static void endPasswordResetFlow() {
    isPasswordResetInProgress = false;
  }
}

// ============================================================
// AUTH STATE NOTIFIER
// ============================================================

/// État complet de l'authentification
class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated(AppUser user)
      : this(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.error(String message)
      : this(status: AuthStatus.error, errorMessage: message);

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get hasError => status == AuthStatus.error;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier pour gérer l'état d'authentification
class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthClient _authClient;

  AuthNotifier(this._authClient) : super(const AuthState.initial()) {
    _init();
  }

  void _init() {
    // Écouter les changements d'état
    _authClient.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    });

    // Vérifier l'état initial
    final currentUser = _authClient.currentUser;
    if (currentUser != null) {
      state = AuthState.authenticated(currentUser);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  /// Connexion avec email/password
  Future<void> signIn(String email, String password) async {
    state = const AuthState.loading();

    final result = await _authClient.signInWithEmailPassword(
      email: email,
      password: password,
    );

    result.when(
      success: (user) => state = AuthState.authenticated(user),
      failure: (error) => state = AuthState.error(error.message),
    );
  }

  /// Connexion avec Google
  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();

    final result = await _authClient.signInWithGoogle();

    result.when(
      success: (user) => state = AuthState.authenticated(user),
      failure: (error) => state = AuthState.error(error.message),
    );
  }

  /// Connexion avec Apple (obligatoire pour iOS)
  Future<void> signInWithApple() async {
    state = const AuthState.loading();

    final result = await _authClient.signInWithApple();

    result.when(
      success: (user) => state = AuthState.authenticated(user),
      failure: (error) => state = AuthState.error(error.message),
    );
  }

  /// Inscription
  Future<void> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    state = const AuthState.loading();

    final result = await _authClient.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );

    result.when(
      success: (user) => state = AuthState.authenticated(user),
      failure: (error) => state = AuthState.error(error.message),
    );
  }

  /// Déconnexion
  Future<void> signOut() async {
    state = const AuthState.loading();

    final result = await _authClient.signOut();

    result.when(
      success: (_) => state = const AuthState.unauthenticated(),
      failure: (error) => state = AuthState.error(error.message),
    );
  }

  /// Supprimer le compte (obligatoire App Store)
  Future<bool> deleteAccount() async {
    state = const AuthState.loading();

    final result = await _authClient.deleteAccount();

    return result.when(
      success: (_) {
        state = const AuthState.unauthenticated();
        return true;
      },
      failure: (error) {
        state = AuthState.error(error.message);
        return false;
      },
    );
  }

  /// Effacer l'erreur
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = const AuthState.unauthenticated();
    }
  }
}

/// Provider pour le notifier d'authentification
///
/// Usage:
/// ```dart
/// // Lire l'état
/// final authState = ref.watch(authNotifierProvider);
/// if (authState.isLoading) showLoading();
///
/// // Déclencher une action
/// ref.read(authNotifierProvider.notifier).signIn(email, password);
/// ```
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref.read(authClientProvider));
});
