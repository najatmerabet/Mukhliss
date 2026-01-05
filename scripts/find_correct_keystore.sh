#!/bin/bash

EXPECTED_SHA1="8B:5C:FB:2C:39:DC:53:C5:C6:A6:67:59:76:01:DE:43:BA:F7:31:35"
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

echo "🔍 TEST DE TOUS LES KEYSTORES TROUVÉS"
echo "════════════════════════════════════════════════════════════"
echo "SHA1 recherché: $EXPECTED_SHA1"
echo ""

# TOUS les keystores trouvés sur le système
KEYSTORES=(
    "my-app-release.keystore"
    "android/keys/mukhliss-release.jks"
    "/Users/prodmeat/MukhlissMEechant2/MukhlissMerchant/android/app/mukhliss-release.jks"
    "/Users/prodmeat/Desktop/mukhliss/Mukhliss/android/app/my-app-release.keystore"
    "/Users/prodmeat/Desktop/mukhliss/Mukhliss/my-app-release.keystore"
    "/Users/prodmeat/Downloads/android/app/my-app-release.keystore"
)

# Tous les mots de passe possibles
PASSWORDS=(
    "Mukhliss2024!"
    "MukhlissSecure2024"
    "mukhliss"
    "Mukhliss"
    "Mukhliss2024"
    "MukhlissSecure"  
    "mukhliss2024"
    "mukhliss123"
    "Mukhliss123"
    "Mukhliss@2024"
    "android"
    ""
)

# Tous les alias possibles
ALIASES=(
    "mukhliss-key"
    "mukhliss"
    "upload"
    "key0"
    "my-key-alias"
    "androiddebugkey"
)

test_combination() {
    local keystore="$1"
    local pwd="$2"
    local alias="$3"
    
    local output=$("$JAVA_HOME/bin/keytool" -list -v -keystore "$keystore" -storepass "$pwd" -alias "$alias" 2>&1)
    
    if echo "$output" | grep -q "SHA1:"; then
        local sha1=$(echo "$output" | grep "SHA1:" | head -1 | sed 's/.*SHA1: //' | tr -d ' \t')
        
        echo "    ✓ Alias '$alias' found - SHA1: $sha1"
        
        if [ "$sha1" = "$EXPECTED_SHA1" ]; then
            echo ""
            echo "🎉🎉🎉 TROUVÉ LE BON KEYSTORE! 🎉🎉🎉"
            echo "════════════════════════════════════════════════════════════"
            echo "Fichier: $keystore"
            echo "Password: $pwd"
            echo "Alias: $alias"
            echo "SHA1: $sha1 ✅"
            echo ""
            echo "📝 CONFIGURATION À APPLIQUER:"
            echo "════════════════════════════════════════════════════════════"
            
            # Copier le keystore dans le projet
            local dest="android/keys/correct-mukhliss-release.jks"
            cp "$keystore" "$dest" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo "✅ Keystore copié vers: $dest"
                echo ""
                echo "Fichier: android/key.properties"
                echo "────────────────────────────────────────────────────────────"
                echo "storePassword=$pwd"
                echo "keyPassword=$pwd"
                echo "keyAlias=$alias"
                echo "storeFile=../keys/correct-mukhliss-release.jks"
            else
                echo "Copier manuellement:"
                echo "cp \"$keystore\" android/keys/correct-mukhliss-release.jks"
                echo ""
                echo "Puis dans android/key.properties:"
                echo "────────────────────────────────────────────────────────────"
                echo "storePassword=$pwd"
                echo "keyPassword=$pwd"
                echo "keyAlias=$alias"
                echo "storeFile=../keys/correct-mukhliss-release.jks"
            fi
            
            echo "════════════════════════════════════════════════════════════"
            return 0
        fi
    fi
    return 1
}

for keystore in "${KEYSTORES[@]}"; do
    if [ ! -f "$keystore" ]; then
        echo "⊘ Skipping (not found): $keystore"
        continue
    fi
    
    echo ""
    echo "📦 Testing: $keystore"
    echo "   Size: $(ls -lh "$keystore" | awk '{print $5}')"
    
    found_pwd=false
    for pwd in "${PASSWORDS[@]}"; do
        # Vérifier si le mot de passe fonctionne
        local test_output=$("$JAVA_HOME/bin/keytool" -list -keystore "$keystore" -storepass "$pwd" 2>&1)
        
        if ! echo "$test_output" | grep -q "password was incorrect\|Keystore was tampered"; then
            if [ "$found_pwd" = false ]; then
                echo "   🔓 Password works: '$pwd'"
                found_pwd=true
            fi
            
            # Tester tous les alias avec ce mot de passe
            for alias in "${ALIASES[@]}"; do
                if test_combination "$keystore" "$pwd" "$alias"; then
                    exit 0
                fi
            done
        fi
    done
    
    if [ "$found_pwd" = false ]; then
        echo "   ❌ No working password found"
    fi
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo "❌ AUCUN KEYSTORE NE CORRESPOND"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Le SHA1 attendu n'a été trouvé dans aucun keystore."
echo ""
echo "🎯 PROCHAINES ÉTAPES:"
echo "1. Vérifier Play App Signing (URGENT):"
echo "   → https://play.google.com/console"
echo "   → Configuration → Signature de l'application"
echo ""
echo "2. Chercher dans vos backups:"
echo "   → Time Machine"
echo "   → Google Drive / Dropbox / iCloud"
echo "   → Emails (cherchez 'keystore' ou 'SHA1')"
echo ""
echo "3. Contacter votre équipe pour le keystore original"
