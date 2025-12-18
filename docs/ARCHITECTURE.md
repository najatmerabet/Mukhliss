# 🏗️ Architecture & System Design - Mukhliss App

## Vue d'Ensemble du Système

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           UTILISATEURS MOBILES                               │
│                    (Flutter App - iOS/Android)                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COUCHE CLIENT (Flutter)                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Cache Logos │  │ Cache Hive  │  │  Riverpod   │  │ Geolocator  │        │
│  │   (LRU)     │  │  (Offline)  │  │  (State)    │  │  (GPS)      │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼ HTTPS
┌─────────────────────────────────────────────────────────────────────────────┐
│                      SUPABASE (Backend as a Service)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Auth      │  │  Database   │  │   Storage   │  │  Realtime   │        │
│  │  (JWT)      │  │ (PostgreSQL)│  │   (S3)      │  │ (WebSocket) │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│                          │                                                   │
│                          ▼                                                   │
│              ┌─────────────────────────┐                                    │
│              │      PostGIS            │                                    │
│              │  (Requêtes Géo)         │                                    │
│              └─────────────────────────┘                                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Analyse des Risques par Scénario

### Scénario 1: 1,000 Utilisateurs Actifs

| Métrique            | Valeur Estimée | Status               |
| ------------------- | -------------- | -------------------- |
| Requêtes/minute     | ~500           | ✅ OK                |
| Bande passante/jour | ~2 GB          | ✅ OK (Plan gratuit) |
| Latence moyenne     | 50-100ms       | ✅ Excellent         |

### Scénario 2: 10,000 Utilisateurs Actifs

| Métrique            | Valeur Estimée | Status             |
| ------------------- | -------------- | ------------------ |
| Requêtes/minute     | ~5,000         | ⚠️ Limite gratuit  |
| Bande passante/jour | ~20 GB         | ❌ Dépasse gratuit |
| Latence moyenne     | 100-200ms      | ⚠️ Acceptable      |

### Scénario 3: 100,000 Utilisateurs Actifs

| Métrique            | Valeur Estimée | Status                  |
| ------------------- | -------------- | ----------------------- |
| Requêtes/minute     | ~50,000        | ❌ Nécessite Pro        |
| Bande passante/jour | ~200 GB        | ❌ Nécessite Pro        |
| Latence moyenne     | 200-500ms      | ⚠️ Optimisation requise |

---

## 🛡️ Points de Défaillance Potentiels

### 1. Base de Données (PostgreSQL)

**Risque**: Requêtes lentes avec beaucoup de données
**Solutions Implémentées**:

- ✅ Index GiST sur geometrie
- ✅ Index sur latitude/longitude
- ✅ Index sur categorie_id
- ✅ Limites de résultats (50-150 max)

**Solutions Additionnelles Recommandées**:

- [ ] Connection pooling (PgBouncer)
- [ ] Read replicas pour les requêtes de lecture
- [ ] Partitionnement de table si > 100,000 magasins

### 2. Stockage Images (Logos)

**Risque**: Bande passante élevée, chargement lent
**Solutions Implémentées**:

- ✅ Cache mémoire LRU (100 images)
- ✅ Cache disque Hive (1000 images)
- ✅ Transformation WebP côté serveur

**Solutions Additionnelles Recommandées**:

- [ ] CDN externe (Cloudflare) pour les images
- [ ] Compression des logos avant upload (max 50KB)
- [ ] Lazy loading avec placeholder

### 3. API/Network

**Risque**: Timeout, échecs réseau
**Solutions Implémentées**:

- ✅ Retry automatique (3 tentatives)
- ✅ Timeout configuré (10-15s)
- ✅ Fallback vers données locales

**Solutions Additionnelles Recommandées**:

- [ ] Rate limiting côté client
- [ ] Circuit breaker pattern
- [ ] Queue de requêtes hors-ligne

### 4. Mémoire Mobile

**Risque**: OOM (Out of Memory) sur appareils anciens
**Solutions Implémentées**:

- ✅ LRU cache avec limite
- ✅ Pagination (20 items max)
- ✅ Dispose des ressources

**Solutions Additionnelles Recommandées**:

- [ ] Memory profiling régulier
- [ ] Libération agressive du cache en background

---

## 🚀 Recommandations d'Architecture

### Phase 1: Actuel (0 - 5,000 utilisateurs)

```
[App Flutter] → [Supabase Free Tier]
```

**Coût**: 0€/mois
**Suffisant pour**: MVP, beta testing

### Phase 2: Croissance (5,000 - 50,000 utilisateurs)

```
[App Flutter] → [Supabase Pro] → [CDN Images]
                      ↓
              [Read Replica]
```

**Coût**: ~50-100€/mois
**Ajouts nécessaires**:

- Upgrade Supabase Pro ($25/mois)
- CDN pour images (Cloudflare gratuit ou $20/mois)
- Monitoring (Sentry gratuit)

### Phase 3: Scale (50,000+ utilisateurs)

```
[App Flutter] → [Load Balancer] → [Supabase Team]
                      ↓                   ↓
              [CDN Global]        [Read Replicas x3]
                      ↓
              [Redis Cache]
```

**Coût**: ~200-500€/mois
**Ajouts nécessaires**:

- Supabase Team ($599/mois) ou Enterprise
- Redis pour cache requêtes fréquentes
- Multiple régions

---

## 📋 Checklist de Production

### Sécurité

- [ ] Row Level Security (RLS) activé sur toutes les tables
- [ ] Validation des entrées côté serveur
- [ ] Rate limiting API
- [ ] HTTPS obligatoire
- [ ] Tokens JWT avec expiration courte

### Performance

- [x] Index de base de données
- [x] Pagination côté serveur
- [x] Cache client multi-niveau
- [ ] Compression gzip des réponses API
- [ ] Lazy loading des images

### Monitoring

- [ ] Logs centralisés (Supabase Logs)
- [ ] Alertes sur erreurs
- [ ] Métriques de performance
- [ ] Tracking des requêtes lentes

### Résilience

- [x] Retry automatique
- [x] Fallback vers dernières données connues
- [ ] Mode hors-ligne complet
- [ ] Sync automatique au retour réseau

---

## 🔧 Optimisations Immédiates Recommandées

### 1. Activer les Logs Supabase

```sql
-- Voir les requêtes lentes
SELECT * FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

### 2. Configurer RLS (Row Level Security)

```sql
-- Exemple pour la table magasins
ALTER TABLE magasins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Les magasins sont visibles par tous"
ON magasins FOR SELECT
USING (true);
```

### 3. Ajouter Rate Limiting (Edge Function)

```typescript
// Limiter à 100 requêtes/minute par IP
const rateLimit = new Map();

Deno.serve(async (req) => {
  const ip = req.headers.get("x-forwarded-for");
  const count = rateLimit.get(ip) || 0;

  if (count > 100) {
    return new Response("Too many requests", { status: 429 });
  }

  rateLimit.set(ip, count + 1);
  // ... suite de la logique
});
```

---

## 📈 Métriques à Surveiller

| Métrique       | Seuil d'Alerte | Action             |
| -------------- | -------------- | ------------------ |
| Latence P95    | > 500ms        | Optimiser requêtes |
| Erreurs 5xx    | > 1%           | Vérifier logs      |
| Utilisation DB | > 80%          | Upgrade plan       |
| Cache hit rate | < 70%          | Augmenter cache    |
| Bande passante | > 80% limite   | Upgrade ou CDN     |

---

## 💡 Conclusion

Votre application est **prête pour 5,000 utilisateurs** avec l'architecture actuelle.

Pour aller au-delà:

1. **Court terme**: Activer monitoring + RLS
2. **Moyen terme**: Upgrade Supabase Pro + CDN
3. **Long terme**: Architecture distribuée avec replicas

**Le point critique**: La bande passante des images. Priorisez la compression des logos.
