# 🚀 Guide High Traffic - Mukhliss

## Vue d'ensemble

Ce guide explique comment utiliser les outils de gestion du high traffic dans Mukhliss.

## Outils disponibles

| Outil               | Rôle                         | Quand l'utiliser                     |
| ------------------- | ---------------------------- | ------------------------------------ |
| **RateLimiter**     | Limite le débit des requêtes | Éviter de surcharger le serveur      |
| **RetryHandler**    | Re-tentatives intelligentes  | Réseau instable, erreurs temporaires |
| **CircuitBreaker**  | Coupe-circuit automatique    | Serveur surchargé ou en panne        |
| **RequestQueue**    | File d'attente priorisée     | Pages avec beaucoup de requêtes      |
| **ResilientClient** | Combine tout                 | Solution complète (recommandé)       |

---

## 1. ResilientClient (Recommandé)

Le `ResilientClient` combine tous les patterns. C'est la solution la plus simple.

### Usage basique

```dart
import 'package:mukhliss/core/network/network.dart';

// Utiliser l'instance globale
final result = await GlobalResilientClient.execute(
  name: 'get-stores',
  action: () => supabase.from('magasins').select(),
);

result.when(
  success: (data) => print('Success: $data'),
  failure: (error) => print('Error: ${error.message}'),
);
```

### Avec priorité

```dart
// Requête haute priorité (auth, paiement)
await GlobalResilientClient.execute(
  name: 'login',
  action: () => supabase.auth.signIn(...),
  priority: RequestPriority.high,
);

// Requête basse priorité (analytics, prefetch)
await GlobalResilientClient.execute(
  name: 'prefetch-categories',
  action: () => supabase.from('categories').select(),
  priority: RequestPriority.low,
);
```

### Configuration personnalisée

```dart
// Pour un écran spécifique avec plus de protection
final client = ResilientClient(
  config: ResilientClientConfig.strict,
  circuitName: 'offers-api',
);

final result = await client.execute(
  name: 'get-offers',
  action: () => supabase.from('offres').select(),
);
```

---

## 2. RetryHandler (Simple)

Pour ajouter juste le retry à une fonction existante.

```dart
import 'package:mukhliss/core/network/network.dart';

// Méthode 1: execute()
final users = await RetryHandler.execute(
  action: () => supabase.from('users').select(),
  config: RetryConfig.standard, // 3 tentatives
);

// Méthode 2: extension
final users = await (() => supabase.from('users').select()).withRetry();
```

---

## 3. CircuitBreaker (Protection serveur)

Protège quand le serveur a des problèmes répétés.

```dart
import 'package:mukhliss/core/network/network.dart';

// Utiliser un circuit global par service
final apiBreaker = CircuitBreakerManager.get('supabase-api');

try {
  final result = await apiBreaker.execute(() => apiCall());
} on CircuitOpenException catch (e) {
  // Le service est temporairement indisponible
  showSnackBar('Service indisponible. Réessayez dans ${e.nextRetryTime}');
}
```

---

## 4. RateLimiter (Limitation débit)

Évite d'envoyer trop de requêtes.

```dart
import 'package:mukhliss/core/network/network.dart';

final limiter = RateLimiter(
  maxRequests: 10,
  perDuration: Duration(seconds: 1),
);

// Attend automatiquement si nécessaire
await limiter.acquire();
final result = await apiCall();
```

---

## 5. RequestQueue (File d'attente)

Pour les pages avec beaucoup de requêtes simultanées.

```dart
import 'package:mukhliss/core/network/network.dart';

final queue = GlobalRequestQueue.instance;

// Les requêtes sont exécutées dans l'ordre, max 4 simultanées
final stores = await queue.add(() => getStores());
final categories = await queue.add(() => getCategories());
final offers = await queue.add(() => getOffers());

// Annuler des requêtes spécifiques
queue.cancelByTag('prefetch');

// Pause pendant un problème réseau
queue.pause();
// ... plus tard
queue.resume();
```

---

## Intégration Progressive

### Étape 1: Ajouter GlobalResilientClient (5 minutes)

Dans `main.dart`:

```dart
import 'package:mukhliss/core/network/network.dart';

void main() async {
  // ... existing code ...

  // Configurer le client résilient (optionnel)
  GlobalResilientClient.configure(ResilientClientConfig.standard);

  runApp(MyApp());
}
```

### Étape 2: Migrer un service (exemple)

Avant:

```dart
class StoresService {
  Future<List<Store>> getStores() async {
    final response = await supabase.from('magasins').select();
    return response.map((e) => Store.fromJson(e)).toList();
  }
}
```

Après:

```dart
class StoresService {
  Future<List<Store>> getStores() async {
    final result = await GlobalResilientClient.execute(
      name: 'get-stores',
      action: () => supabase.from('magasins').select(),
    );

    return result.when(
      success: (data) => data.map((e) => Store.fromJson(e)).toList(),
      failure: (error) => throw error,
    );
  }
}
```

---

## Monitoring

```dart
// Voir l'état actuel
print(GlobalResilientClient.instance.stats);
// {
//   circuitState: closed,
//   availableRequests: 28,
//   pendingRequests: 0,
//   runningRequests: 2,
//   isPaused: false
// }

// Voir tous les circuits
print(CircuitBreakerManager.allStates);
// {supabase: closed, auth: closed}
```

---

## Best Practices

1. **Utilisez `GlobalResilientClient`** pour la plupart des cas
2. **Haute priorité** pour: auth, paiement, actions utilisateur
3. **Basse priorité** pour: prefetch, analytics, sync background
4. **Ne pas modifier** le code existant qui fonctionne
5. **Migrer progressivement** service par service

---

## Support

Ces outils sont 100% optionnels. Le code existant continue de fonctionner normalement.
