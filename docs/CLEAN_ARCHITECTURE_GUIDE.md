# 🏗️ Guide Clean Architecture & SOLID - Mukhliss

## Vue d'ensemble

Ce document décrit les principes d'architecture et de design utilisés dans le projet Mukhliss.

---

## 📐 Principes SOLID

### S - Single Responsibility Principle (SRP)

> Une classe ne doit avoir qu'une seule raison de changer.

**Applications dans Mukhliss:**

```dart
// ✅ BON - Chaque classe a une responsabilité unique
class StoresRemoteDataSource {
  // Responsabilité: Récupérer les données depuis l'API
  Future<List<StoreModel>> getStores();
}

class StoresRepositoryImpl {
  // Responsabilité: Orchestrer les sources de données
  Future<List<StoreEntity>> getStores();
}

class StoresStateNotifier {
  // Responsabilité: Gérer l'état UI des magasins
  void loadStores();
  void searchStores(String query);
}
```

```dart
// ❌ MAUVAIS - Classe avec plusieurs responsabilités
class StoreManager {
  void fetchFromApi();      // Réseau
  void saveToCache();       // Cache
  void updateUI();          // Présentation
  void validateData();      // Validation
}
```

### O - Open/Closed Principle (OCP)

> Les classes doivent être ouvertes à l'extension, fermées à la modification.

**Applications dans Mukhliss:**

```dart
// Interface de base
abstract class StoresRepository {
  Future<List<StoreEntity>> getStores();
}

// Extension sans modification de l'original
class CachedStoresRepository implements StoresRepository {
  final StoresRepository _remote;
  final CacheService _cache;

  @override
  Future<List<StoreEntity>> getStores() async {
    final cached = await _cache.get('stores');
    if (cached != null) return cached;

    final stores = await _remote.getStores();
    await _cache.set('stores', stores);
    return stores;
  }
}
```

### L - Liskov Substitution Principle (LSP)

> Les sous-types doivent être substituables à leurs types de base.

**Applications dans Mukhliss:**

```dart
// Les implémentations respectent le contrat de l'interface
abstract class AuthClient {
  Future<AppUser?> signIn(String email, String password);
}

class SupabaseAuthClient implements AuthClient {
  @override
  Future<AppUser?> signIn(String email, String password) {
    // Implémentation Supabase - respecte le contrat
  }
}

class MockAuthClient implements AuthClient {
  @override
  Future<AppUser?> signIn(String email, String password) {
    // Implémentation Mock - respecte le contrat
  }
}
```

### I - Interface Segregation Principle (ISP)

> Les clients ne doivent pas dépendre d'interfaces qu'ils n'utilisent pas.

**Applications dans Mukhliss:**

```dart
// ✅ BON - Interfaces segregées
abstract class StoreReader {
  Future<List<StoreEntity>> getStores();
  Future<StoreEntity?> getById(String id);
}

abstract class StoreWriter {
  Future<void> create(StoreEntity store);
  Future<void> update(StoreEntity store);
}

// ❌ MAUVAIS - Interface trop large
abstract class StoreRepository {
  Future<List<StoreEntity>> getStores();
  Future<StoreEntity?> getById(String id);
  Future<void> create(StoreEntity store);
  Future<void> update(StoreEntity store);
  Future<void> delete(String id);
  Future<void> syncWithServer();
  Future<void> clearCache();
  // ... trop de méthodes
}
```

### D - Dependency Inversion Principle (DIP)

> Les modules de haut niveau ne doivent pas dépendre des modules de bas niveau.

**Applications dans Mukhliss:**

```dart
// Le Repository (haut niveau) dépend d'une abstraction
class StoresRepositoryImpl implements StoresRepository {
  final StoresRemoteDataSource _remoteDataSource;  // Interface, pas implémentation

  StoresRepositoryImpl({required StoresRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;
}

// Injection via Riverpod
final storesRepositoryProvider = Provider<StoresRepository>((ref) {
  return StoresRepositoryImpl(
    remoteDataSource: ref.read(storesRemoteDataSourceProvider),
  );
});
```

---

## 🎯 Clean Architecture

### Structure des couches

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────┐ │
│  │   Screens   │  │   Widgets   │  │   Providers/State    │ │
│  │  (UI/Views) │  │ (Components)│  │  (Riverpod/Notifier) │ │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬───────────┘ │
│         │                │                     │             │
│         └────────────────┴─────────────────────┘             │
│                          │                                   │
│                          ▼                                   │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────┐ │
│  │  Entities   │  │  Use Cases  │  │ Repository Interfaces│ │
│  │ (Pure Data) │  │(Business    │  │   (Abstractions)     │ │
│  │             │  │   Logic)    │  │                      │ │
│  └─────────────┘  └──────┬──────┘  └──────────────────────┘ │
│                          │                                   │
│                          ▼                                   │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                             │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────┐ │
│  │   Models    │  │ DataSources │  │ Repository Impls     │ │
│  │(DTOs/JSON)  │  │(API/Local)  │  │(Concrete Classes)    │ │
│  └─────────────┘  └─────────────┘  └──────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Structure des dossiers par feature

```
lib/features/stores/
├── data/
│   ├── datasources/
│   │   └── stores_remote_datasource.dart    # Appels API Supabase
│   ├── models/
│   │   └── store_model.dart                 # DTO avec fromJson/toJson
│   └── repositories/
│       └── stores_repository_impl.dart      # Implémentation du repo
│
├── domain/
│   ├── entities/
│   │   └── store_entity.dart                # Entité pure (logique métier)
│   ├── repositories/
│   │   └── stores_repository.dart           # Interface/contrat
│   └── usecases/
│       └── stores_usecases.dart             # Cas d'utilisation
│
├── presentation/
│   ├── controllers/
│   │   └── location_controller.dart         # Logique de contrôle
│   ├── providers/
│   │   └── stores_providers.dart            # Providers Riverpod
│   ├── screens/
│   │   └── location_screen.dart             # Pages/écrans
│   └── widgets/
│       └── shop_details_bottom_sheet.dart   # Composants UI
│
└── stores.dart                              # Barrel export
```

---

## 📁 Conventions de nommage

### Fichiers

| Type            | Convention              | Exemple                         |
| --------------- | ----------------------- | ------------------------------- |
| Entities        | `{nom}_entity.dart`     | `store_entity.dart`             |
| Models          | `{nom}_model.dart`      | `store_model.dart`              |
| Repositories    | `{nom}_repository.dart` | `stores_repository.dart`        |
| Implementations | `{nom}_impl.dart`       | `stores_repository_impl.dart`   |
| DataSources     | `{nom}_datasource.dart` | `stores_remote_datasource.dart` |
| Providers       | `{nom}_providers.dart`  | `stores_providers.dart`         |
| Screens         | `{nom}_screen.dart`     | `location_screen.dart`          |
| Widgets         | `{nom}_widget.dart`     | `search_widget.dart`            |

### Classes et variables

| Type       | Convention                       | Exemple                           |
| ---------- | -------------------------------- | --------------------------------- |
| Classes    | UpperCamelCase                   | `StoreEntity`, `StoresRepository` |
| Variables  | lowerCamelCase                   | `storeId`, `isActive`             |
| Constantes | lowerCamelCase ou SCREAMING_CAPS | `maxLength`, `API_URL`            |
| Providers  | lowerCamelCase + Provider        | `storesRepositoryProvider`        |

---

## ✅ Checklist Clean Code

### Avant chaque commit, vérifier:

- [ ] **Pas de fichier > 300 lignes** (sauf exceptions documentées)
- [ ] **Chaque classe a une seule responsabilité**
- [ ] **Les dépendances sont injectées, pas créées**
- [ ] **Les modèles/entities sont immutables (final)**
- [ ] **Pas de TODO/FIXME sans issue associée**
- [ ] **Les méthodes publiques sont documentées**
- [ ] **Les noms sont explicites et en anglais**
- [ ] **flutter analyze passe sans erreurs**

### Métriques de qualité

| Métrique              | Cible | Actuel |
| --------------------- | ----- | ------ |
| Erreurs analyse       | 0     | ✅ 0   |
| Warnings              | < 50  | ⚠️ 76  |
| Fichiers > 500 lignes | 0     | ⚠️ 6   |
| Couverture tests      | > 30% | 🔴 0%  |

---

## 🔄 Migration en cours

### Fichiers à refactorer (trop longs)

1. `location_screen.dart` (1826 lignes) → Splitter en composants
2. `shop_details_bottom_sheet.dart` (1418 lignes) → Extraire widgets
3. `profile_new_screen.dart` (1337 lignes) → Créer sous-composants
4. `device_management_service.dart` (1127 lignes) → Diviser en services

### Prochaines améliorations

1. Ajouter les Use Cases manquants
2. Implémenter le caching local
3. Ajouter les tests unitaires
4. Réduire les fichiers trop longs

---

_Document mis à jour le 15/12/2024_
