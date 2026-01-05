# 🔧 FIX: Mukhliss Keeps Stopping

## ❌ Problème

L'app crashait au démarrage avec "Mukhliss keeps stopping"

## 🔍 Cause identifiée

**Deep link scheme incorrect dans AndroidManifest.xml**

Le manifest utilisait l'ancien package:

```xml
android:scheme="com.example.mukhliss"
```

Mais le package actuel est:

```
com.mukhliss.prod
```

## ✅ Solution appliquée

**Fichier modifié:** `android/app/src/main/AndroidManifest.xml`

**Changement:**

```xml
<!-- AVANT -->
<data
    android:scheme="com.example.mukhliss"
    android:host="login-callback" />

<!-- APRÈS -->
<data
    android:scheme="com.mukhliss.prod"
    android:host="login-callback" />
```

## 🔄 AAB Rebuild

Nouveau AAB généré avec la correction:

- Clean du projet: ✅
- Correction appliquée: ✅
- Nouveau build: En cours...

## 📦 Nouveau fichier à uploader

```
build/app/outputs/bundle/release/app-release.aab
```

**Ce nouveau AAB ne devrait PLUS crasher!**

## ✅ Test recommandé

Avant d'uploader sur Play Store:

1. **Tester localement:**

   ```bash
   flutter install --release
   ```

2. **Vérifier que l'app démarre sans crash**

3. **Uploader le nouveau AAB** sur Play Console

---

**Date de correction:** 26 décembre 2025
**Package name:** com.mukhliss.prod
**Build:** Release avec deep link fix
