# 🏗️ Architecture MUKHLISS - Guide d'Utilisation

## Structure du Core

```
lib/core/
├── auth/
│   ├── auth.dart              # Barrel exports
│   ├── auth_client.dart       # Interface IAuthClient + AppUser
│   ├── auth_providers.dart    # Providers Riverpod
│   └── supabase_auth_client.dart  # Implémentation Supabase
│
├── errors/
│   ├── failures.dart          # Types d'erreurs
│   └── result.dart            # Pattern Result
│
├── logger/
│   └── app_logger.dart        # Logger centralisé
│
└── core.dart                  # Barrel principal
```

---

## 📦 Comment Utiliser

### 1. Importer le Core

```dart
// Import tout le core d'un coup
import 'package:mukhliss/core/core.dart';

// Ou juste l'authentification
import 'package:mukhliss/core/auth/auth.dart';
```

### 2. Authentification

#### Dans un Widget

```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écouter l'état d'auth
    final authState = ref.watch(authNotifierProvider);

    if (authState.isLoading) {
      return CircularProgressIndicator();
    }

    return ElevatedButton(
      onPressed: () {
        // Déclencher le login
        ref.read(authNotifierProvider.notifier).signIn(
          email,
          password,
        );
      },
      child: Text('Se connecter'),
    );
  }
}
```

#### Écouter les changements

```dart
// Dans initState ou build
ref.listen(authNotifierProvider, (previous, current) {
  if (current.isAuthenticated) {
    Navigator.pushReplacementNamed(context, '/home');
  }
  if (current.status == AuthStatus.error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(current.errorMessage!)),
    );
  }
});
```

### 3. Gestion des Erreurs avec Result

```dart
// Dans un service ou usecase
Future<Result<AppUser>> getUser() async {
  try {
    final user = await api.fetchUser();
    return Result.success(user);
  } catch (e) {
    return Result.failure(ServerFailure(e.toString()));
  }
}

// Utilisation
final result = await getUser();

result.when(
  success: (user) => print('User: ${user.email}'),
  failure: (error) => print('Error: ${error.message}'),
);

// Ou avec getOrElse
final user = result.getOrElse(defaultUser);
```

### 4. Logger

```dart
import 'package:mukhliss/core/logger/app_logger.dart';

// Logs simples
AppLogger.debug('Message de debug');
AppLogger.info('Information');
AppLogger.warning('Attention');
AppLogger.error('Erreur', error: exception, stackTrace: stack);

// Logs par domaine
AppLogger.auth('Utilisateur connecté');
AppLogger.network('Requête envoyée');
AppLogger.navigation('Navigation vers /home');
```

---

## 🔄 Comment Changer de Backend

Pour passer de Supabase à Firebase:

### Étape 1: Créer FirebaseAuthClient

```dart
// lib/core/auth/firebase_auth_client.dart
class FirebaseAuthClient implements IAuthClient {
  // Implémenter toutes les méthodes de IAuthClient
  // en utilisant Firebase
}
```

### Étape 2: Modifier auth_providers.dart

```dart
// Dans lib/core/auth/auth_providers.dart

// Changer cette ligne:
const AuthBackend _currentBackend = AuthBackend.supabase;

// En:
const AuthBackend _currentBackend = AuthBackend.firebase;
```

**C'est tout!** Le reste de l'application continuera de fonctionner.

---

## 🧪 Tests

### Mock pour les tests

```dart
class MockAuthClient implements IAuthClient {
  @override
  AppUser? get currentUser => AppUser(id: 'test-id', email: 'test@test.com');

  @override
  Future<Result<AppUser>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (password == 'correct') {
      return Result.success(AppUser(id: '1', email: email));
    }
    return Result.failure(InvalidCredentialsFailure());
  }

  // ... autres méthodes
}
```

### Dans les tests

```dart
testWidgets('Login test', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authClientProvider.overrideWithValue(MockAuthClient()),
      ],
      child: MyApp(),
    ),
  );

  // Le test utilisera MockAuthClient
});
```

---

## 📋 Types d'Erreurs Disponibles

| Classe                      | Code                | Utilisation            |
| --------------------------- | ------------------- | ---------------------- |
| `NetworkFailure`            | NETWORK_ERROR       | Pas de connexion       |
| `AuthFailure`               | AUTH_ERROR          | Erreur auth générale   |
| `InvalidCredentialsFailure` | INVALID_CREDENTIALS | Email/mdp incorrect    |
| `UserNotFoundFailure`       | USER_NOT_FOUND      | Utilisateur inexistant |
| `EmailAlreadyInUseFailure`  | EMAIL_IN_USE        | Email déjà pris        |
| `WeakPasswordFailure`       | WEAK_PASSWORD       | Mdp trop faible        |
| `SessionExpiredFailure`     | SESSION_EXPIRED     | Session expirée        |
| `ServerFailure`             | SERVER_ERROR        | Erreur serveur         |
| `ValidationFailure`         | VALIDATION_ERROR    | Données invalides      |
| `UnknownFailure`            | UNKNOWN             | Erreur inconnue        |

---

## ✅ Prochaines Étapes

1. [ ] Migrer progressivement les écrans pour utiliser `authNotifierProvider`
2. [ ] Remplacer tous les `print()` par `AppLogger`
3. [ ] Créer des tests pour `SupabaseAuthClient`
4. [ ] Appliquer le même pattern pour `StoreService`, `OffersService`
