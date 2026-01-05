# 📱 Guide de Configuration du Signing iOS

## 🎯 Pourquoi le build actuel utilise `--no-codesign`?

Le pipeline GitHub Actions actuel (`.github/workflows/ci.yml` ligne 189) build iOS sans signature pour ces raisons:

### ❌ Problèmes sans `--no-codesign`:

- **Certificats manquants**: Apple exige des certificats de développement/distribution
- **Profils de provisionnement**: Nécessaires pour chaque app
- **Apple Developer Account**: Compte payant ($99/an) obligatoire
- **Configuration complexe**: Gestion des secrets dans GitHub Actions

### ✅ Avantages de `--no-codesign` (actuel):

- Compile et vérifie le code Flutter
- Valide qu'il n'y a pas d'erreurs de compilation
- Génère les assets et ressources
- Ne nécessite pas de certificats Apple
- Pipeline fonctionne pour tous les développeurs

### ⚠️ Limitations:

- L'app générée n'est **PAS installable** sur un appareil réel
- Ne peut **PAS être déployée** sur TestFlight ou App Store
- Seulement pour vérification de build

---

## 🚀 Solution: Configurer le Code Signing (Fastlane Match)

### Option 1: Fastlane Match (Recommandé pour CI/CD)

#### Étape 1: Installer Fastlane

```bash
cd ios
gem install fastlane
fastlane init
```

#### Étape 2: Configurer Match

```bash
fastlane match init
```

Choisir le stockage (git, Google Cloud, S3):

```
git → Recommandé pour petites équipes
```

#### Étape 3: Créer un repo privé pour les certificats

```bash
# Créer un repo GitHub privé nommé: certificates-mukhliss
# Ne JAMAIS le rendre public!
```

#### Étape 4: Générer les certificats

```bash
# Development
fastlane match development

# App Store
fastlane match appstore
```

#### Étape 5: Configurer les secrets GitHub

Dans GitHub Settings → Secrets and variables → Actions, ajouter:

```
MATCH_PASSWORD=votre_mot_de_passe_fort
MATCH_GIT_URL=https://github.com/votre-org/certificates-mukhliss
APPLE_TEAM_ID=XXXXXXXXXX
APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX
APP_STORE_CONNECT_ISSUER_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
APP_STORE_CONNECT_API_KEY_BASE64=base64_de_votre_cle_p8
```

#### Étape 6: Créer le Matchfile

**Fichier: `ios/Matchfile`**

```ruby
git_url(ENV["MATCH_GIT_URL"])
storage_mode("git")
type("appstore")
app_identifier(["com.mukhliss.app"])
username("votre.email@apple.com")
team_id(ENV["APPLE_TEAM_ID"])
```

#### Étape 7: Modifier le pipeline

**Fichier: `.github/workflows/ci.yml`** (remplacer lignes 188-190)

```yaml
- name: 🔐 Setup Code Signing
  run: |
    cd ios
    fastlane match appstore --readonly
  env:
    MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
    MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
    APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}

- name: 🏗️ Build iOS (with signing)
  run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

#### Étape 8: Créer ExportOptions.plist

**Fichier: `ios/ExportOptions.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>VOTRE_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.mukhliss.app</key>
        <string>match AppStore com.mukhliss.app</string>
    </dict>
</dict>
</plist>
```

---

### Option 2: Manual Signing (Plus simple, moins sécurisé)

#### Étape 1: Exporter les certificats depuis Xcode

1. Ouvrir Xcode → Preferences → Accounts
2. Sélectionner votre compte Apple Developer
3. Manage Certificates → Download All
4. Export les certificats (.p12)

#### Étape 2: Encoder en base64

```bash
base64 -i certificate.p12 | pbcopy
```

#### Étape 3: Ajouter aux secrets GitHub

```
IOS_CERTIFICATE_BASE64=le_contenu_copié
IOS_CERTIFICATE_PASSWORD=mot_de_passe_du_p12
IOS_PROVISIONING_PROFILE_BASE64=base64_du_profil
```

#### Étape 4: Modifier le pipeline

```yaml
- name: 🔐 Import Certificates
  run: |
    # Créer keychain temporaire
    security create-keychain -p "" build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p "" build.keychain
    security set-keychain-settings -t 3600 -l build.keychain

    # Importer certificat
    echo "${{ secrets.IOS_CERTIFICATE_BASE64 }}" | base64 --decode > certificate.p12
    security import certificate.p12 -k build.keychain -P "${{ secrets.IOS_CERTIFICATE_PASSWORD }}" -T /usr/bin/codesign

    # Installer profil de provisionnement
    echo "${{ secrets.IOS_PROVISIONING_PROFILE_BASE64 }}" | base64 --decode > profile.mobileprovision
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/

- name: 🏗️ Build iOS (with signing)
  run: flutter build ipa --release
```

---

## 📊 Comparaison des options

| Critère         | No Codesign (Actuel) | Fastlane Match      | Manual Signing         |
| --------------- | -------------------- | ------------------- | ---------------------- |
| **Difficulté**  | ✅ Facile            | ⚠️ Moyen            | ⚠️ Moyen               |
| **Sécurité**    | ✅ Aucun secret      | ✅ Très sécurisé    | ⚠️ Secrets dans GitHub |
| **Équipe**      | ✅ Partageable       | ✅ Excellente       | ❌ Complexe            |
| **Déploiement** | ❌ Impossible        | ✅ Automatisé       | ⚠️ Possible            |
| **Coût**        | ✅ Gratuit           | 💰 $99/an Apple     | 💰 $99/an Apple        |
| **CI/CD**       | ⚠️ Test only         | ✅ Production ready | ⚠️ Fragile             |

---

## 🎯 Recommandations

### Pour le développement actuel (MAINTENANT):

✅ **Garder `--no-codesign`**

- Le pipeline vérifie que le code compile
- Pas de configuration complexe nécessaire
- Fonctionne pour toute l'équipe

### Quand passer au signing (FUTUR):

🚀 **Utiliser Fastlane Match** quand vous serez prêt à:

- Déployer sur TestFlight
- Publier sur App Store
- Avoir un workflow de release automatisé

---

## 🛠️ Checklist pour activer le signing

- [ ] Avoir un Apple Developer Account actif ($99/an)
- [ ] Créer l'App ID sur developer.apple.com
- [ ] Configurer Fastlane Match
- [ ] Créer un repo privé pour les certificats
- [ ] Générer les certificats et profils
- [ ] Ajouter les secrets dans GitHub
- [ ] Créer la clé App Store Connect API
- [ ] Tester le build en local d'abord
- [ ] Modifier le pipeline CI/CD
- [ ] Retirer le `&& false` de la ligne 206

---

## 📚 Ressources

- [Fastlane Match Documentation](https://docs.fastlane.tools/actions/match/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [GitHub Actions for Flutter](https://github.com/marketplace/actions/flutter-action)
