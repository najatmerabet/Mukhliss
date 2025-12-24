#!/bin/bash

echo "🔐 CRÉATION D'UN NOUVEAU KEYSTORE POUR MUKHLISS"
echo "════════════════════════════════════════════════════════════"
echo ""

JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
KEYSTORE_DIR="android/keys"
KEYSTORE_NAME="mukhliss-production-2024.jks"
KEYSTORE_PATH="$KEYSTORE_DIR/$KEYSTORE_NAME"

# Créer le dossier si nécessaire
mkdir -p "$KEYSTORE_DIR"

# Paramètres du keystore
echo "📋 Configuration du nouveau keystore:"
echo "   Fichier: $KEYSTORE_PATH"
echo "   Alias: mukhliss"
echo "   Algorithme: RSA 2048 bits"
echo "   Validité: 10000 jours (~27 ans)"
echo ""

# Générer le keystore
echo "🔨 Génération du keystore..."
echo ""

"$JAVA_HOME/bin/keytool" -genkeypair \
  -v \
  -keystore "$KEYSTORE_PATH" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias mukhliss \
  -storetype JKS \
  -dname "CN=Mukhliss, OU=Engineering, O=Mukhliss, L=Casablanca, ST=Casablanca, C=MA" \
  -storepass "MukhlissSecure2024!" \
  -keypass "MukhlissSecure2024!"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ KEYSTORE CRÉÉ AVEC SUCCÈS!"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    # Afficher les détails du keystore
    echo "📊 Détails du keystore:"
    "$JAVA_HOME/bin/keytool" -list -v -keystore "$KEYSTORE_PATH" -storepass "MukhlissSecure2024!" -alias mukhliss | head -30
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    # Créer le fichier key.properties
    echo "📝 Création de android/key.properties..."
    cat > android/key.properties << EOF
## Keystore configuration for release builds
## IMPORTANT: Ne JAMAIS commiter ce fichier dans git!

storePassword=MukhlissSecure2024!
keyPassword=MukhlissSecure2024!
keyAlias=mukhliss
storeFile=../keys/$KEYSTORE_NAME
EOF
    
    echo "✅ Fichier key.properties créé"
    echo ""
    
    # Créer un fichier de backup des credentials
    echo "💾 Création du fichier de backup des credentials..."
    cat > KEYSTORE_CREDENTIALS_BACKUP.txt << EOF
════════════════════════════════════════════════════════════
🔐 MUKHLISS - CREDENTIALS DU KEYSTORE DE PRODUCTION
════════════════════════════════════════════════════════════

⚠️  IMPORTANT: Ce fichier contient des informations sensibles!
    - NE PAS commiter dans Git
    - Sauvegarder dans un gestionnaire de mots de passe
    - Stocker des copies hors ligne sécurisées

Date de création: $(date)

────────────────────────────────────────────────────────────
KEYSTORE INFORMATION
────────────────────────────────────────────────────────────
Fichier: $KEYSTORE_PATH
Store Password: MukhlissSecure2024!
Key Alias: mukhliss
Key Password: MukhlissSecure2024!

────────────────────────────────────────────────────────────
EMPREINTE SHA-1 (pour Google Play Console)
────────────────────────────────────────────────────────────
EOF
    
    "$JAVA_HOME/bin/keytool" -list -v -keystore "$KEYSTORE_PATH" -storepass "MukhlissSecure2024!" -alias mukhliss | grep "SHA1:" >> KEYSTORE_CREDENTIALS_BACKUP.txt
    
    cat >> KEYSTORE_CREDENTIALS_BACKUP.txt << EOF

────────────────────────────────────────────────────────────
SAUVEGARDES À FAIRE IMMÉDIATEMENT
────────────────────────────────────────────────────────────
1. Copier ce fichier dans un gestionnaire de mots de passe
2. Copier le keystore ($KEYSTORE_PATH) vers:
   - Un disque dur externe
   - Un cloud privé (Google Drive, iCloud, Dropbox)
   - Un autre ordinateur
3. NE JAMAIS perdre ce keystore!

────────────────────────────────────────────────────────────
POUR BUILDER L'APP
────────────────────────────────────────────────────────────
flutter clean
flutter pub get
flutter build appbundle --release

Le fichier sera généré dans:
build/app/outputs/bundle/release/app-release.aab

════════════════════════════════════════════════════════════
EOF
    
    echo "✅ Fichier de backup créé: KEYSTORE_CREDENTIALS_BACKUP.txt"
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "🎉 TOUT EST PRÊT!"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "📋 PROCHAINES ÉTAPES:"
    echo ""
    echo "1. ⚠️  SAUVEGARDEZ LE KEYSTORE MAINTENANT:"
    echo "   cp $KEYSTORE_PATH ~/Desktop/mukhliss-keystore-BACKUP.jks"
    echo "   # Puis copiez vers un disque externe/cloud"
    echo ""
    echo "2. 📖 LISEZ le fichier: KEYSTORE_CREDENTIALS_BACKUP.txt"
    echo "   # Et sauvegardez les credentials dans un gestionnaire de mots de passe"
    echo ""
    echo "3. 🏗️  BUILD l'app:"
    echo "   flutter clean"
    echo "   flutter build appbundle --release"
    echo ""
    echo "4. 🗑️  SUPPRIMER l'ancienne app sur Play Console"
    echo "   # Puis créer une nouvelle app"
    echo ""
    echo "5. 📤 UPLOADER le nouveau .aab sur Play Console"
    echo ""
    echo "════════════════════════════════════════════════════════════"
    
else
    echo "❌ ERREUR lors de la création du keystore"
    exit 1
fi
