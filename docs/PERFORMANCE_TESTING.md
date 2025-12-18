# 🧪 Guide de Test des Performances - Mukhliss

## Comment Tester les Performances

### Test 1 : Mode Stress Test dans l'App

#### Étape 1 : Activer le mode test

Modifier le fichier `lib/features/stores/presentation/providers/mock_stores_provider.dart` :

```dart
const bool useMockStores = true;  // ← Changer à TRUE
const int mockStoreCount = 50000; // ← Nombre de magasins fake
```

#### Étape 2 : Lancer l'app

```bash
cd /Users/prodmeat/MukhlissClient/Mukhliss
flutter run --profile  # Mode profile pour mesures précises
```

#### Étape 3 : Ouvrir DevTools

Dans un autre terminal :

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

#### Étape 4 : Observer les métriques

- **Timeline** : Voir les frames lents
- **Memory** : Voir l'utilisation mémoire
- **Performance** : FPS, jank

#### Critères de succès :

| Métrique       | Bon     | Mauvais |
| -------------- | ------- | ------- |
| FPS            | > 50    | < 30    |
| Temps de build | < 16ms  | > 32ms  |
| Mémoire        | < 300MB | > 500MB |

---

### Test 2 : Test de Charge sur Supabase

#### Étape 1 : Installer k6

```bash
# macOS
brew install k6

# Ou télécharger depuis https://k6.io
```

#### Étape 2 : Créer le script de test

Créer un fichier `tests/load_test.js` :

```javascript
import http from "k6/http";
import { check, sleep } from "k6";

// Configuration du test
export let options = {
  stages: [
    { duration: "30s", target: 10 }, // Monter à 10 utilisateurs
    { duration: "1m", target: 50 }, // Monter à 50 utilisateurs
    { duration: "1m", target: 100 }, // Monter à 100 utilisateurs
    { duration: "30s", target: 0 }, // Redescendre à 0
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% des requêtes < 500ms
    http_req_failed: ["rate<0.01"], // Moins de 1% d'erreurs
  },
};

const SUPABASE_URL = "https://cowhadlafnxrrwnfuwdi.supabase.co";
const SUPABASE_KEY = "VOTRE_ANON_KEY"; // Remplacer par votre clé

export default function () {
  // Test 1: Pagination des magasins
  let res1 = http.get(`${SUPABASE_URL}/rest/v1/magasins?limit=20&offset=0`, {
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
    },
  });

  check(res1, {
    "pagination status 200": (r) => r.status === 200,
    "pagination < 500ms": (r) => r.timings.duration < 500,
  });

  sleep(1);

  // Test 2: Recherche géographique
  let res2 = http.get(
    `${SUPABASE_URL}/rest/v1/magasins?latitude=gte.33.5&latitude=lte.33.7&limit=100`,
    {
      headers: {
        apikey: SUPABASE_KEY,
        Authorization: `Bearer ${SUPABASE_KEY}`,
      },
    }
  );

  check(res2, {
    "geo search status 200": (r) => r.status === 200,
    "geo search < 500ms": (r) => r.timings.duration < 500,
  });

  sleep(1);
}
```

#### Étape 3 : Lancer le test

```bash
k6 run tests/load_test.js
```

#### Étape 4 : Lire les résultats

```
     ✓ pagination status 200
     ✓ pagination < 500ms
     ✓ geo search status 200
     ✓ geo search < 500ms

     checks.........................: 100.00% ✓ 4000 ✗ 0
     http_req_duration..............: avg=45.23ms min=12ms max=234ms p(95)=120ms
     http_reqs......................: 2000    33.33/s
```

---

### Test 3 : Vérifier dans Supabase Dashboard

1. Aller sur https://supabase.com/dashboard
2. Sélectionner le projet **cowhadlafnxrrwnfuwdi**
3. Aller dans **Settings** → **Database**
4. Vérifier :

   - CPU Usage < 50%
   - Memory Usage < 50%
   - Connections < 50

5. Aller dans **Logs** → **Postgres logs**
6. Chercher les requêtes lentes (> 1s)

---

## 📊 Tableau de Décision : Quand Changer l'Architecture

| Symptôme               | Cause Probable        | Action                 | Coût       |
| ---------------------- | --------------------- | ---------------------- | ---------- |
| Latence > 500ms        | Requêtes non indexées | Ajouter des index      | 0€         |
| Latence > 1s           | Trop de données       | Optimiser les requêtes | 0€         |
| Erreurs timeout        | Limite de connexions  | Supabase Pro           | 25€/mois   |
| DB > 80% CPU           | Charge trop élevée    | Read Replica           | +50€/mois  |
| Bande passante épuisée | Trop d'images         | CDN externe            | 20€/mois   |
| > 50K utilisateurs     | Architecture limitée  | Upgrade complet        | 200€+/mois |

---

## 🔄 Comment Changer l'Architecture

### Niveau 1 : Optimisations (0€) ✅ FAIT

- [x] Index sur geometry (PostGIS)
- [x] Index sur latitude/longitude
- [x] Index sur Categorieid
- [x] Pagination côté serveur
- [x] Cache logos multi-niveau
- [x] Limite de résultats

### Niveau 2 : Supabase Pro (25€/mois)

```
QUAND :
- Plus de 5,000 utilisateurs actifs
- Bande passante > 50% de la limite
- Besoin de plus de 500MB de DB

COMMENT :
1. Aller sur supabase.com/dashboard
2. Settings → Billing
3. Upgrade to Pro
4. C'est tout ! Pas de migration nécessaire
```

### Niveau 3 : Ajouter Read Replica (75€/mois total)

```
QUAND :
- Plus de 20,000 utilisateurs actifs
- CPU de la DB > 70%
- Latence > 300ms

COMMENT :
1. Dashboard → Settings → Infrastructure
2. "Add Read Replica"
3. Choisir la région (proche des utilisateurs)
4. Modifier le code pour lire depuis le replica :

// Dans stores_remote_datasource.dart
final readReplicaClient = SupabaseClient(
  'https://replica-url.supabase.co',
  'anon-key',
);

// Utiliser pour les lectures uniquement
final stores = await readReplicaClient.from('magasins').select();
```

### Niveau 4 : CDN Externe / Cloudflare (20-50€/mois)

```
QUAND :
- Bande passante > 80%
- Images chargent lentement

COMMENT :
1. Créer compte Cloudflare
2. Ajouter votre domaine
3. Configurer DNS
4. Les images passent automatiquement par le CDN
```

### Niveau 5 : Microservices (1000€+/mois)

```
QUAND :
- Plus de 100,000 utilisateurs
- Équipe de plus de 5 développeurs
- Besoin de scaling indépendant

COMMENT :
1. Choisir un cloud (AWS/GCP/Azure)
2. Containeriser l'API (Docker)
3. Déployer sur Kubernetes
4. Migrer la DB vers un cluster PostgreSQL
5. Ajouter Redis pour le cache
6. Ajouter Load Balancer

⚠️ Nécessite 3-6 mois de travail et une équipe expérimentée
```

---

## ✅ Checklist Avant Chaque Niveau

### Avant Supabase Pro

- [ ] Vérifier l'utilisation actuelle (Settings → Usage)
- [ ] Confirmer que les index sont en place
- [ ] Valider que le cache fonctionne

### Avant Read Replica

- [ ] Identifier les requêtes les plus fréquentes
- [ ] Séparer lectures et écritures dans le code
- [ ] Tester en staging d'abord

### Avant Microservices

- [ ] Documenter l'architecture actuelle
- [ ] Identifier les bounded contexts
- [ ] Avoir au moins 50K utilisateurs payants
- [ ] Avoir le budget pour 6 mois de migration
- [ ] Avoir l'équipe technique
