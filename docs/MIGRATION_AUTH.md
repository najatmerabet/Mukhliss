# 🔄 Guide de Migration Auth

> **Date**: 11 Décembre 2024
> **Objectif**: Migrer de AuthService vers IAuthClient

---

## ⚠️ Situation Actuelle

### Ancien Système (à supprimer)

```dart
// ❌ NE PLUS UTILISER
import 'package:mukhliss/services/auth_service.dart';
import 'package:mukhliss/providers/auth_provider.dart';

final authService = ref.watch(authProvider);
final user = authService.currentUser;  // Type: Supabase User
```

### Nouveau Système (à utiliser)

```dart
// ✅ UTILISER
import 'package:mukhliss/core/auth/auth_providers.dart';

final authClient = ref.watch(authClientProvider);
final user = authClient.currentUser;  // Type: AppUser
```

---

## 📁 Fichiers à Migrer

| Fichier                                            | Priorité | Statut     |
| -------------------------------------------------- | -------- | ---------- |
| `lib/screen/client/offres.dart`                    | Haute    | 🔲 À faire |
| `lib/screen/client/profile.dart`                   | Haute    | 🔲 À faire |
| `lib/screen/client/profile_new.dart`               | Haute    | 🔲 À faire |
| `lib/screen/client/profile/settings_screen.dart`   | Moyenne  | 🔲 À faire |
| `lib/widgets/buttons/ShopDetailsBottomSheet.dart`  | Basse    | 🔲 À faire |
| `lib/widgets/buttons/categories_bottom_sheet.dart` | Basse    | 🔲 À faire |

---

## 🔧 Comment Migrer Un Fichier

### Étape 1: Changer les imports

```dart
// AVANT
import 'package:mukhliss/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// APRÈS
import 'package:mukhliss/core/auth/auth_providers.dart';
import 'package:mukhliss/core/auth/auth_client.dart';
```

### Étape 2: Changer le provider

```dart
// AVANT
final authService = ref.watch(authProvider);
final user = authService.currentUser;

// APRÈS
final authClient = ref.watch(authClientProvider);
final user = authClient.currentUser;
```

### Étape 3: Changer les types

```dart
// AVANT
User? user;  // Supabase User
user.id
user.email
user.userMetadata  // Map<String, dynamic>

// APRÈS
AppUser? user;  // Notre type custom
user.id
user.email
user.firstName   // Directement accessible
user.lastName
user.phone
```

### Étape 4: Changer les méthodes

```dart
// AVANT
await authService.login(email, password);
await authService.logout();
await authService.signInWithGoogle();

// APRÈS
final result = await authClient.signInWithEmailPassword(
  email: email,
  password: password,
);
result.when(
  success: (user) => /* ... */,
  failure: (error) => /* ... */,
);

await authClient.signOut();
await authClient.signInWithGoogle();
```

---

## 📊 Différences de Types

### Supabase User (ancien)

```dart
class User {
  String id;
  String? email;
  Map<String, dynamic>? userMetadata;
  // ... plein d'autres champs Supabase
}
```

### AppUser (nouveau)

```dart
class AppUser {
  String id;
  String email;
  String? firstName;
  String? lastName;
  String? phone;
  String? photoUrl;
  // Champs personnalisés faciles à utiliser
}
```

---

## ✅ Avantages du Nouveau Système

| Ancien                                 | Nouveau                      |
| -------------------------------------- | ---------------------------- |
| Type Supabase complexe                 | Type simple et clair         |
| Accès via `userMetadata['first_name']` | Accès via `user.firstName`   |
| Exceptions à catch                     | Pattern `Result<T, Failure>` |
| Pas testable                           | Mockable via `IAuthClient`   |
| Couplé à Supabase                      | Interface abstraite          |

---

## 🚨 Fichiers à NE PAS Toucher

Ces fichiers utilisent déjà le nouveau système:

- `lib/core/auth/*` - Base du nouveau système
- `lib/screen/auth/login_page.dart` - Migré
- `lib/screen/auth/signup_page.dart` - Migré
- `lib/screen/auth/otp_verification_page.dart` - Migré
- `lib/screen/auth/password_reset_page.dart` - Migré

---

## 📅 Plan de Migration

### Phase 1: Compatibilité (Fait ✅)

- Créer le nouveau système dans `core/auth/`
- Garder l'ancien système fonctionnel
- Marquer AuthService comme deprecated

### Phase 2: Migration Progressive (En cours 🔄)

- Migrer fichier par fichier
- Commencer par les écrans principaux
- Tester après chaque migration

### Phase 3: Nettoyage (À faire)

- Supprimer `lib/services/auth_service.dart`
- Supprimer les exports deprecated de `auth_provider.dart`
- Mettre à jour la documentation

---

## 💡 Conseils

1. **Ne pas tout migrer d'un coup** - Faites fichier par fichier
2. **Testez après chaque migration** - Lancez l'app et vérifiez
3. **Utilisez le Result pattern** - Pour une meilleure gestion d'erreurs
4. **Gardez AppUser simple** - Ajoutez des champs si nécessaire

---

## 📞 Support

Si vous avez des questions sur la migration:

1. Consultez `lib/core/auth/auth_client.dart` pour l'interface
2. Consultez `lib/core/auth/supabase_auth_client.dart` pour l'implémentation
3. Consultez `test/core/auth/` pour les exemples de tests
