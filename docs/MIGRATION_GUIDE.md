# 📦 Guide de Migration: Ancienne Structure → Nouvelle Architecture

## 🎯 Objectif

Migrer progressivement de l'ancienne structure (models/providers/services/screen) vers la nouvelle architecture Feature-First + Clean Architecture.

---

## 📊 État Actuel du Projet

### Ancienne Structure (À migrer)

```
lib/
├── models/          # 11 fichiers - Modèles de données
├── providers/       # 13 fichiers - Providers Riverpod
├── services/        # 15 fichiers - Logique métier
├── screen/          # 21 fichiers - Écrans UI
├── widgets/         # Widgets partagés
├── utils/           # Utilitaires
├── constants/       # Constantes
├── theme/           # Thème
└── routes/          # Routes
```

### Nouvelle Structure (Cible)

```
lib/
├── core/            # ✅ Déjà en place
├── features/        # ✅ 48 fichiers créés
│   ├── auth/        # ✅ Migré
│   ├── offers/      # ✅ Migré
│   ├── rewards/     # ✅ Migré
│   ├── profile/     # ✅ Migré
│   ├── stores/      # ✅ Migré
│   └── location/    # 🔄 À faire
└── shared/          # Widgets partagés
```

---

## 📋 Mapping: Ancien → Nouveau

### Feature OFFERS

| Ancien Fichier                        | Nouveau Fichier                                                  | Action       |
| ------------------------------------- | ---------------------------------------------------------------- | ------------ |
| `models/offers.dart`                  | `features/offers/data/models/offer_model.dart`                   | ✅ Créé      |
| `models/clientoffre.dart`             | `features/offers/domain/entities/claimed_offer_entity.dart`      | ✅ Créé      |
| `services/offres_service.dart`        | `features/offers/data/datasources/offers_remote_datasource.dart` | ✅ Créé      |
| `services/clientoffre_service.dart`   | Intégré dans `offers_repository_impl.dart`                       | ✅ Créé      |
| `providers/offers_provider.dart`      | `features/offers/presentation/providers/offers_provider.dart`    | ✅ Créé      |
| `providers/clientoffre_provider.dart` | Intégré dans `offers_provider.dart`                              | ✅ Créé      |
| `screen/client/offres.dart`           | `features/offers/presentation/screens/offers_screen.dart`        | ⏳ Référence |

### Feature REWARDS

| Ancien Fichier                    | Nouveau Fichier                                                    | Action       |
| --------------------------------- | ------------------------------------------------------------------ | ------------ |
| `models/rewards.dart`             | `features/rewards/data/models/reward_model.dart`                   | ✅ Créé      |
| `services/rewards_service.dart`   | `features/rewards/data/datasources/rewards_remote_datasource.dart` | ✅ Créé      |
| `providers/rewards_provider.dart` | `features/rewards/presentation/providers/rewards_provider.dart`    | ✅ Créé      |
| `screen/rewardsexample.dart`      | `features/rewards/presentation/screens/`                           | ⏳ Référence |

### Feature PROFILE

| Ancien Fichier                   | Nouveau Fichier                                                    | Action       |
| -------------------------------- | ------------------------------------------------------------------ | ------------ |
| `models/client.dart`             | `features/profile/domain/entities/profile_entity.dart`             | ✅ Créé      |
| `services/client_service.dart`   | `features/profile/data/datasources/profile_remote_datasource.dart` | ✅ Créé      |
| `providers/client_provider.dart` | `features/profile/presentation/providers/profile_provider.dart`    | ✅ Créé      |
| `screen/client/profile.dart`     | `features/profile/presentation/screens/`                           | ⏳ Référence |
| `screen/client/profile_new.dart` | `features/profile/presentation/screens/`                           | ⏳ Référence |

### Feature STORES

| Ancien Fichier                  | Nouveau Fichier                                                  | Action  |
| ------------------------------- | ---------------------------------------------------------------- | ------- |
| `models/store.dart`             | `features/stores/data/models/store_model.dart`                   | ✅ Créé |
| `services/store_service.dart`   | `features/stores/data/datasources/stores_remote_datasource.dart` | ✅ Créé |
| `providers/store_provider.dart` | `features/stores/presentation/providers/stores_provider.dart`    | ✅ Créé |

### Feature AUTH

| Ancien Fichier                 | Nouveau Fichier                                           | Action       |
| ------------------------------ | --------------------------------------------------------- | ------------ |
| `core/auth/*`                  | `features/auth/` (réexporte)                              | ✅ Créé      |
| `providers/auth_provider.dart` | `features/auth/presentation/providers/auth_provider.dart` | ✅ Créé      |
| `screen/auth/*.dart`           | `features/auth/presentation/screens/auth_screens.dart`    | ✅ Référence |

### Feature LOCATION (À faire)

| Ancien Fichier                         | Nouveau Fichier                             | Action     |
| -------------------------------------- | ------------------------------------------- | ---------- |
| `services/geolocator_service.dart`     | `features/location/data/datasources/`       | ❌ À créer |
| `services/osrm_service.dart`           | `features/location/data/datasources/`       | ❌ À créer |
| `providers/geolocator_provider.dart`   | `features/location/presentation/providers/` | ❌ À créer |
| `providers/osrm_provider.dart`         | `features/location/presentation/providers/` | ❌ À créer |
| `screen/client/Location/location.dart` | `features/location/presentation/screens/`   | ❌ À créer |

### Autres fichiers (À évaluer)

| Fichier                          | Destination suggérée            |
| -------------------------------- | ------------------------------- |
| `models/categories.dart`         | `features/stores/` ou `shared/` |
| `models/bonus.dart`              | `features/rewards/`             |
| `models/supportticket.dart`      | Nouvelle feature `support/`     |
| `providers/theme_provider.dart`  | `core/theme/`                   |
| `providers/langue_provider.dart` | `core/l10n/`                    |

---

## 🔄 Étapes de Migration (Par Fichier)

### Étape 1: Identifier le fichier à migrer

Exemple: `lib/services/store_service.dart`

### Étape 2: Déterminer sa feature

- Store → `features/stores/`

### Étape 3: Créer les fichiers dans la nouvelle structure

```
features/stores/
├── domain/
│   ├── entities/store_entity.dart      ← Copier le modèle SANS fromJson
│   ├── repositories/stores_repository.dart  ← Créer l'interface
│   └── usecases/get_stores.dart        ← Créer les use cases
├── data/
│   ├── models/store_model.dart         ← Copier le modèle AVEC fromJson
│   ├── datasources/stores_remote_datasource.dart  ← Copier le service
│   └── repositories/stores_repository_impl.dart   ← Créer l'impl
└── presentation/
    ├── providers/stores_provider.dart  ← Adapter le provider
    ├── screens/                        ← Référencer les écrans
    └── widgets/                        ← Extraire les widgets
```

### Étape 4: Mettre à jour les imports

**AVANT (ancien import):**

```dart
import 'package:mukhliss/models/store.dart';
import 'package:mukhliss/providers/store_provider.dart';
import 'package:mukhliss/services/store_service.dart';
```

**APRÈS (nouveau import):**

```dart
import 'package:mukhliss/features/stores/stores.dart';
```

### Étape 5: Marquer l'ancien fichier comme deprecated

```dart
/// @deprecated Utiliser features/stores/stores.dart à la place
library;

// Réexporter pour compatibilité temporaire
export 'package:mukhliss/features/stores/stores.dart';
```

### Étape 6: Mettre à jour les fichiers qui utilisent l'ancien

```bash
# Trouver tous les fichiers qui importent l'ancien
grep -rn "import.*models/store.dart" lib/ --include="*.dart"
```

### Étape 7: Tester

```bash
flutter analyze
flutter test
```

### Étape 8: Supprimer l'ancien fichier (après validation)

Une fois que plus rien n'utilise l'ancien fichier, le supprimer.

---

## 📝 Checklist de Migration Par Feature

### ✅ Feature: Offers

- [x] Entity créée
- [x] Repository interface créée
- [x] Use cases créés
- [x] Model (DTO) créé
- [x] DataSource créé
- [x] Repository impl créé
- [x] Provider créé
- [x] Widgets créés
- [x] Screen référencé
- [x] Barrel export créé
- [ ] Anciens fichiers marqués deprecated
- [ ] Imports mis à jour dans tout le projet
- [ ] Anciens fichiers supprimés

### ✅ Feature: Rewards

- [x] Entity créée
- [x] Repository interface créée
- [x] Use cases créés
- [x] Model (DTO) créé
- [x] DataSource créé
- [x] Repository impl créé
- [x] Provider créé
- [x] Widgets créés
- [x] Screen référencé
- [x] Barrel export créé
- [ ] Anciens fichiers marqués deprecated
- [ ] Imports mis à jour dans tout le projet
- [ ] Anciens fichiers supprimés

### ✅ Feature: Profile

- [x] Entity créée
- [x] Repository interface créée
- [x] Use cases créés
- [x] Model (DTO) créé
- [x] DataSource créé
- [x] Repository impl créé
- [x] Provider créé
- [x] Widgets créés
- [x] Screen référencé
- [x] Barrel export créé
- [ ] Anciens fichiers marqués deprecated
- [ ] Imports mis à jour dans tout le projet
- [ ] Anciens fichiers supprimés

### ✅ Feature: Auth

- [x] Entity créée (réexporte AppUser)
- [x] Repository interface créée (réexporte IAuthClient)
- [x] Use cases créés
- [x] Provider créé (réexporte)
- [x] Widgets créés
- [x] Screen référencé
- [x] Barrel export créé
- [ ] Imports mis à jour dans tout le projet

### ✅ Feature: Stores

- [x] Entity créée
- [x] Repository interface créée
- [x] Use cases créés
- [x] Model (DTO) créé
- [x] DataSource créé
- [x] Repository impl créé
- [x] Provider créé
- [ ] Widgets à créer
- [ ] Screen à créer
- [x] Barrel export créé
- [ ] Anciens fichiers marqués deprecated

### ❌ Feature: Location

- [ ] Entity à créer
- [ ] Repository interface à créer
- [ ] Use cases à créer
- [ ] Model (DTO) à créer
- [ ] DataSource à créer
- [ ] Repository impl à créer
- [ ] Provider à créer
- [ ] Widgets à créer
- [ ] Screen à référencer
- [ ] Barrel export à mettre à jour

---

## 🚀 Ordre Recommandé de Migration

### Phase 1: Features DÉJÀ Migrées ✅

1. ~~Auth~~ → Fait
2. ~~Offers~~ → Fait
3. ~~Rewards~~ → Fait
4. ~~Profile~~ → Fait
5. ~~Stores~~ → Fait

### Phase 2: Mettre à Jour les Imports (PRIORITÉ)

```bash
# Pour chaque feature, trouver et mettre à jour les imports
grep -rn "import.*models/offers.dart" lib/ --include="*.dart"
grep -rn "import.*services/offres_service.dart" lib/ --include="*.dart"
grep -rn "import.*providers/offers_provider.dart" lib/ --include="*.dart"
```

### Phase 3: Features Restantes

1. Location (la plus complexe - 2000+ lignes)
2. Categories (peut aller dans Stores)
3. Support (nouvelle feature)

### Phase 4: Nettoyage

1. Marquer tous les anciens fichiers comme deprecated
2. Mettre à jour tous les imports
3. Supprimer les anciens fichiers
4. Supprimer les dossiers vides

---

## 💡 Commandes Utiles

```bash
# Analyser le projet
flutter analyze

# Trouver les imports d'un fichier ancien
grep -rn "import.*models/offers" lib/ --include="*.dart"

# Compter les fichiers par dossier
find lib/models -name "*.dart" | wc -l
find lib/features -name "*.dart" | wc -l

# Voir la structure
find lib/features -type f -name "*.dart" | sort

# Vérifier la compilation
flutter build apk --debug 2>&1 | head -20
```

---

## ⚠️ Points d'Attention

1. **Ne pas casser le code existant** - Utiliser les réexports pour la compatibilité
2. **Migrer progressivement** - Une feature à la fois
3. **Tester après chaque étape** - `flutter analyze` et tests
4. **Garder les anciens fichiers** - Jusqu'à ce que tout soit migré
5. **Documenter les changements** - Mettre à jour ce fichier

---

## 📈 Progrès Global

- **Features créées:** 5/6 (83%)
- **Fichiers dans features/:** 48
- **Anciens fichiers models/:** 11 (à migrer)
- **Anciens fichiers services/:** 15 (à migrer)
- **Anciens fichiers providers/:** 13 (à migrer)

**Prochaine étape:** Mettre à jour les imports dans les fichiers existants pour utiliser les nouvelles features.
