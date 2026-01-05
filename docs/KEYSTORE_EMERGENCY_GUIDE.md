# 🔴 GUIDE URGENT: Résoudre le problème de signature Android

## ⚠️ SITUATION CRITIQUE

Votre upload sur Play Store échoue à cause d'un mauvais keystore.

**SHA1 attendu par Google Play:**

```
8B:5C:FB:2C:39:DC:53:C5:C6:A6:67:59:76:01:DE:43:BA:F7:31:35
```

**SHA1 actuellement utilisé:**

```
0B:75:E1:60:BA:20:81:8D:9C:9D:A0:62:4C:DE:F0:DE:A2:50:62:64
```

---

## 📦 Keystores trouvés

1. `/Users/prodmeat/MukhlissClient/Mukhliss/my-app-release.keystore`
2. `/Users/prodmeat/MukhlissClient/Mukhliss/android/keys/mukhliss-release.jks` ← **Actuellement utilisé**
3. `/Users/prodmeat/MukhlissMEechant2/MukhlissMerchant/android/app/mukhliss-release.jks`

---

## 🔍 ÉTAPE 1: Trouver les mots de passe

### Vérifier le fichier `.env`:

```bash
cat .env | grep -i password
```

### Vérifier dans l'autre projet:

```bash
cat /Users/prodmeat/MukhlissMEechant2/MukhlissMerchant/android/key.properties 2>/dev/null || echo "Fichier non trouvé"
```

---

## 🧪 ÉTAPE 2: Tester manuellement chaque keystore

Utilisez cette commande pour vérifier le SHA1 (remplacez MOTDEPASSE):

### Keystore 1: my-app-release.keystore

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
$JAVA_HOME/bin/keytool -list -v -keystore my-app-release.keystore -storepass MOTDEPASSE
```

Cherchez dans l'output:

- `Alias name:` → Notez l'alias
- `SHA1: XX:XX...` → Comparez avec le SHA1 attendu

### Keystore 2: android/keys/mukhliss-release.jks

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
$JAVA_HOME/bin/keytool -list -v -keystore android/keys/mukhliss-release.jks -storepass MOTDEPASSE
```

### Keystore 3: De l'autre projet

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
$JAVA_HOME/bin/keytool -list -v -keystore /Users/prodmeat/MukhlissMEechant2/MukhlissMerchant/android/app/mukhliss-release.jks -storepass MOTDEPASSE
```

---

## 🎯 ÉTAPE 3: Si vous trouvez le bon keystore

### A. Si c'est `my-app-release.keystore`:

1. Copier dans le bon dossier:

```bash
cp my-app-release.keystore android/keys/correct-mukhliss.jks
```

2. Mettre à jour `android/key.properties`:

```properties
storePassword=VOTRE_MOT_DE_PASSE
keyPassword=VOTRE_MOT_DE_PASSE
keyAlias=VOTRE_ALIAS
storeFile=../keys/correct-mukhliss.jks
```

### B. Si c'est le keystore de l'autre projet:

1. Copier vers ce projet:

```bash
cp /Users/prodmeat/MukhlissMEechant2/MukhlissMerchant/android/app/mukhliss-release.jks android/keys/correct-mukhliss.jks
```

2. Mettre à jour `android/key.properties`:

```properties
storePassword=VOTRE_MOT_DE_PASSE
keyPassword=VOTRE_MOT_DE_PASSE
keyAlias=VOTRE_ALIAS
storeFile=../keys/correct-mukhliss.jks
```

### C. Rebuild:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

---

## ❌ ÉTAPE 4: Si AUCUN keystore ne correspond

### Option 1: Vérifier Play App Signing

1. Aller sur https://play.google.com/console
2. Sélectionner votre app "Mukhliss"
3. Menu → **Configuration** → **Signature de l'application**
4. Vérifier si "Play App Signing" est **activé**

#### Si Play App Signing EST activé (✅ BONNE NOUVELLE):

Vous pouvez créer une nouvelle clé d'upload:

```bash
# Créer une nouvelle clé d'upload
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
$JAVA_HOME/bin/keytool -genkeypair \
  -v \
  -keystore android/keys/new-upload-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -storetype JKS
```

Puis suivre les instructions dans Play Console pour télécharger le certificat.

#### Si Play App Signing N'EST PAS activé (❌ PROBLÈME):

Vous DEVEZ absolument trouver le keystore original, sinon:

- Impossiblede mettre à jour l'app existante
- Vous devrez créer une nouvelle app avec un nouveau package name

### Option 2: Chercher dans d'autres emplacements

```bash
# Chercher dans les backups Time Machine
# Chercher dans Google Drive / Dropbox
# Chercher dans vos emails avec "keystore" ou "mukhliss"
# Demander aux autres développeurs
```

---

## 📋 CHECKLIST

- [ ] J'ai trouvé le mot de passe des keystores
- [ ] J'ai vérifié le SHA1 de chaque keystore
- [ ] J'ai identifié le bon keystore
- [ ] J'ai mis à jour `android/key.properties`
- [ ] J'ai rebuild l'app
- [ ] J'ai vérifié si Play App Signing est activé
- [ ] Si rien ne marche: J'ai contacté Google Play Support

---

## 🆘 Commandes utiles

### Lister tous les alias d'un keystore:

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
$JAVA_HOME/bin/keytool -list -keystore CHEMIN_KEYSTORE -storepass MOTDEPASSE
```

### Voir tous les détails:

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
$JAVA_HOME/bin/keytool -list -v -keystore CHEMIN_KEYSTORE -storepass MOTDEPASSE
```

### Vérifier le build actuel:

```bash
flutter build appbundle --release --verbose
```

###

Vérifier le SHA1 d'un AAB déjà généré:

```bash
# Faire un unzip de l'AAB et trouver le certificat
unzip -l build/app/outputs/bundle/release/app-release.aab | grep RSA
```

---

## 📞 PROCHAINES ÉTAPES IMMÉDIATES

1. **MAINTENANT**: Essayer de retrouver le mot de passe du keystore

   - Vérifier vos notes/emails
   - Vérifier le fichier`.env` ou autres fichiers de config
   - Demander à votre équipe

2. **Si mot de passe trouvé**: Tester les 3 keystores pour trouver le bon SHA1

3. **Si bon keystore trouvé**: Mettre à jour la config et rebuild

4. **Si rien ne marche**: Vérifier Play App Signing et créer une nouvelle clé d'upload

---

## 💡 ASTUCE

Le mot de passe pourrait être dans:

- Le fichier `.env` à la racine du projet
- Un fichier `local.properties` dans `android/`
- Vos notes / gestionnaire de mots de passe
- Un email que vous vous êtes envoyé
- Le projet `MukhlissMerchant` (l'ancien projet)
- Les commits Git de l'autre projet

Essayez:

```bash
cd /Users/prodmeat/MukhlissMEechant2/MukhlissMerchant
cat android/key.properties 2>/dev/null
cat .env 2>/dev/null | grep -i pass
git log --all --grep keystore
```
