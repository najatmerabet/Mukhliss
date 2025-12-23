# 🔐 Guide de Configuration CI/CD - Mukhliss

## Vue d'ensemble

Ce guide explique comment configurer le déploiement automatique vers **Google Play Store** et **Apple App Store**.

## 🤖 Configuration Android (Play Store)

### Étape 1: Encoder le Keystore en Base64

```bash
# Générer le base64 du keystore
base64 -i android/keys/mukhliss-release.jks | tr -d '\n' > keystore_base64.txt

# Afficher le contenu (copier pour GitHub Secret)
cat keystore_base64.txt
```

### Étape 2: Créer un Service Account Google Play

1. Aller sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créer un projet ou sélectionner un existant
3. Activer l'API **Google Play Android Developer API**
4. Aller dans **IAM & Admin > Service Accounts**
5. Créer un compte de service:
   - Nom: `mukhliss-cd-deploy`
   - Rôle: aucun (on va le lier à Play Console)
6. Créer une clé JSON pour ce compte
7. Télécharger le fichier JSON

### Étape 3: Lier le Service Account à Play Console

1. Aller sur [Google Play Console](https://play.google.com/console)
2. **Paramètres > Accès API**
3. Cliquer sur **Lier** à côté de votre projet Cloud
4. **Gérer les comptes de service**
5. Ajouter le service account créé avec les permissions:
   - ✅ Voir les informations sur l'application
   - ✅ Créer et modifier des versions préliminaires
   - ✅ Publier des versions

### Étape 4: Ajouter les Secrets GitHub

Aller sur GitHub > Settings > Secrets and variables > Actions

| Secret Name                        | Valeur                             |
| ---------------------------------- | ---------------------------------- |
| `ANDROID_KEYSTORE_BASE64`          | Contenu de keystore_base64.txt     |
| `ANDROID_KEYSTORE_PASSWORD`        | Mukhliss2024!                      |
| `ANDROID_KEY_ALIAS`                | mukhliss-key                       |
| `ANDROID_KEY_PASSWORD`             | Mukhliss2024!                      |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Contenu du fichier JSON téléchargé |

---

## 🍎 Configuration iOS (App Store)

### Étape 1: Créer une Clé API App Store Connect

1. Aller sur [App Store Connect](https://appstoreconnect.apple.com)
2. **Utilisateurs et accès > Clés**
3. Créer une nouvelle clé avec:
   - Nom: `CI-CD-Key`
   - Accès: **Admin** ou **App Manager**
4. Télécharger le fichier `.p8`
5. Noter:
   - **Key ID**: ex. `ABC123DEF4`
   - **Issuer ID**: ex. `12345678-1234-1234-1234-123456789012`

### Étape 2: Encoder la Clé API en Base64

```bash
base64 -i AuthKey_ABC123DEF4.p8 | tr -d '\n' > api_key_base64.txt
cat api_key_base64.txt
```

### Étape 3: Ajouter les Secrets GitHub

| Secret Name                        | Valeur                                           |
| ---------------------------------- | ------------------------------------------------ |
| `APP_STORE_CONNECT_API_KEY_ID`     | ABC123DEF4                                       |
| `APP_STORE_CONNECT_ISSUER_ID`      | 12345678-1234-1234-1234-123456789012             |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Contenu de api_key_base64.txt                    |
| `APPLE_TEAM_ID`                    | Votre Team ID (visible dans developer.apple.com) |

---

## 🚀 Utilisation du CI/CD

### Déploiement Automatique

Le pipeline se déclenche automatiquement:

| Événement                | Action                                      |
| ------------------------ | ------------------------------------------- |
| **Push sur PR**          | Tests + Build Debug                         |
| **Push sur main/master** | Tests + Build Release + Artifacts           |
| **Tag v\***              | Tests + Build + Déploiement vers les Stores |

### Créer une Release

```bash
# Release patch (1.0.0 → 1.0.1)
./scripts/release.sh patch

# Release minor (1.0.0 → 1.1.0)
./scripts/release.sh minor

# Release major (1.0.0 → 2.0.0)
./scripts/release.sh major
```

### Déploiement Manuel

Si le déploiement automatique n'est pas configuré:

1. **Play Store**:

   ```bash
   flutter build appbundle --release
   # Upload: build/app/outputs/bundle/release/app-release.aab
   ```

2. **App Store**:
   ```bash
   flutter build ios --release
   open ios/Runner.xcworkspace
   # Product → Archive → Distribute App
   ```

---

## 📊 Vérification du Pipeline

1. Aller sur GitHub > **Actions**
2. Vérifier les logs de chaque job
3. Télécharger les artifacts (APK/AAB)

### Troubleshooting

| Problème                     | Solution                          |
| ---------------------------- | --------------------------------- |
| Keystore invalide            | Vérifier l'encodage base64        |
| Permission denied Play Store | Vérifier le Service Account       |
| Build iOS échoue             | Vérifier CocoaPods et certificats |
| Tag non reconnu              | Format: `v1.0.0` (avec le v)      |

---

## 🔄 Workflow Recommandé

```
1. Développer sur branche feature/*
2. Créer PR vers main/master
3. CI teste automatiquement
4. Merger la PR
5. Quand prêt pour release:
   ./scripts/release.sh patch
6. Le tag déclenche le déploiement
```
