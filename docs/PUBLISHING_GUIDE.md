# 🚀 Guide de Publication - Mukhliss

## 📱 Publication sur Google Play Store

### Étape 1: Créer le Keystore (UNE SEULE FOIS)

Exécutez cette commande dans le terminal :

```bash
keytool -genkey -v -keystore android/keys/mukhliss-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mukhliss-key \
  -storepass VOTRE_MOT_DE_PASSE_FORT \
  -keypass VOTRE_MOT_DE_PASSE_FORT \
  -dname "CN=Mukhliss App, OU=Mobile, O=Mukhliss, L=Casablanca, ST=Grand Casablanca, C=MA"
```

⚠️ **IMPORTANT**:

- Remplacez `VOTRE_MOT_DE_PASSE_FORT` par un vrai mot de passe
- **SAUVEGARDEZ CE FICHIER** - vous en aurez besoin pour TOUTES les mises à jour
- Ne partagez JAMAIS ce fichier publiquement

### Étape 2: Créer le fichier key.properties

Créez le fichier `android/key.properties` :

```properties
storePassword=VOTRE_MOT_DE_PASSE_FORT
keyPassword=VOTRE_MOT_DE_PASSE_FORT
keyAlias=mukhliss-key
storeFile=keys/mukhliss-release.jks
```

### Étape 3: Ajouter aux .gitignore

Ces fichiers ne doivent JAMAIS être sur Git :

```
*.jks
*.keystore
key.properties
```

### Étape 4: Build l'App Bundle

```bash
flutter build appbundle --release
```

Le fichier sera dans : `build/app/outputs/bundle/release/app-release.aab`

### Étape 5: Publier sur Play Console

1. Aller sur https://play.google.com/console
2. Créer une application
3. Remplir la fiche Store
4. Upload l'AAB dans "Production" ou "Test interne"
5. Soumettre pour review

---

## 🍎 Publication sur Apple App Store

### Prérequis

1. **Compte Apple Developer** ($99/an) - https://developer.apple.com
2. **Mac avec Xcode** installé
3. **Certificats et Provisioning Profiles** configurés

### Étape 1: Configurer le projet iOS

Ouvrez Xcode :

```bash
open ios/Runner.xcworkspace
```

Dans Xcode :

1. Sélectionnez "Runner" dans le navigateur
2. Onglet "Signing & Capabilities"
3. Activez "Automatically manage signing"
4. Sélectionnez votre Team

### Étape 2: Configurer les infos de l'app

Dans Xcode → Runner → Info.plist :

- Bundle Identifier: `com.mukhliss.app`
- Bundle Display Name: `Mukhliss`
- Privacy descriptions (Location, Camera, etc.)

### Étape 3: Build l'Archive iOS

```bash
flutter build ios --release
```

Puis dans Xcode :

1. Product → Archive
2. Distribute App → App Store Connect
3. Upload

### Étape 4: Publier sur App Store Connect

1. Aller sur https://appstoreconnect.apple.com
2. Créer une app
3. Remplir les métadonnées
4. Ajouter screenshots
5. Soumettre pour review

---

## 🔐 Configuration CI/CD pour Release

### Pour GitHub Actions avec signatures :

1. **Encoder le keystore en base64** :

```bash
base64 -i android/keys/mukhliss-release.jks > keystore.txt
```

2. **Ajouter aux secrets GitHub** :

   - `ANDROID_KEYSTORE_BASE64` : contenu de keystore.txt
   - `ANDROID_KEY_ALIAS` : mukhliss-key
   - `ANDROID_KEY_PASSWORD` : votre mot de passe
   - `ANDROID_KEYSTORE_PASSWORD` : votre mot de passe

3. **Mettre à jour le workflow** (voir ci-dessous)

---

## 📋 Checklist Avant Publication

### Play Store

- [ ] Keystore créé et sauvegardé
- [ ] key.properties configuré
- [ ] App bundle généré (.aab)
- [ ] Fiche Store complète (description, screenshots)
- [ ] Privacy Policy URL
- [ ] Icône 512x512
- [ ] Feature graphic 1024x500

### App Store

- [ ] Certificats Apple configurés
- [ ] Provisioning Profile créé
- [ ] Archive Xcode uploadée
- [ ] Screenshots pour tous les devices
- [ ] Privacy Policy URL
- [ ] Support URL
- [ ] App Preview (optionnel)

---

## 💰 Coûts

| Store           | Coût | Durée    |
| --------------- | ---- | -------- |
| Google Play     | $25  | Une fois |
| Apple App Store | $99  | Par an   |
