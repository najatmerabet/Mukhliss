#!/bin/bash

echo "🔄 CHANGEMENT DU PACKAGE NAME: com.nextgen.mukhliss → com.mukhliss.app"
echo "════════════════════════════════════════════════════════════"
echo ""

# Ancien et nouveau package
OLD_PACKAGE="com.nextgen.mukhliss"
NEW_PACKAGE="com.mukhliss.app"

OLD_PATH="com/nextgen/mukhliss"
NEW_PATH="com/mukhliss/app"

echo "📝 ÉTAPE 1: Modification du build.gradle.kts Android"
echo "────────────────────────────────────────────────────────────"

# Backup
cp android/app/build.gradle.kts android/app/build.gradle.kts.backup

# Modifier le package dans build.gradle.kts
sed -i '' "s|namespace = \"$OLD_PACKAGE\"|namespace = \"$NEW_PACKAGE\"|g" android/app/build.gradle.kts
sed -i '' "s|applicationId = \"$OLD_PACKAGE\"|applicationId = \"$NEW_PACKAGE\"|g" android/app/build.gradle.kts

echo "✅ build.gradle.kts modifié"
echo ""

echo "📝 ÉTAPE 2: Modification du AndroidManifest.xml"
echo "────────────────────────────────────────────────────────────"

# Backup
cp android/app/src/main/AndroidManifest.xml android/app/src/main/AndroidManifest.xml.backup

# Modifier le package dans AndroidManifest
sed -i '' "s|package=\"$OLD_PACKAGE\"|package=\"$NEW_PACKAGE\"|g" android/app/src/main/AndroidManifest.xml

echo "✅ AndroidManifest.xml modifié"
echo ""

echo "📝 ÉTAPE 3: Déplacement des fichiers Kotlin/Java (si ils existent)"
echo "────────────────────────────────────────────────────────────"

# Vérifier si le dossier source existe
if [ -d "android/app/src/main/kotlin/$OLD_PATH" ]; then
    echo "Déplacement des fichiers Kotlin..."
    mkdir -p "android/app/src/main/kotlin/$NEW_PATH"
    mv android/app/src/main/kotlin/$OLD_PATH/* android/app/src/main/kotlin/$NEW_PATH/ 2>/dev/null || echo "Aucun fichier à déplacer"
    
    # Modifier le package dans MainActivity.kt
    if [ -f "android/app/src/main/kotlin/$NEW_PATH/MainActivity.kt" ]; then
        sed -i '' "s|package $OLD_PACKAGE|package $NEW_PACKAGE|g" "android/app/src/main/kotlin/$NEW_PATH/MainActivity.kt"
        echo "✅ MainActivity.kt modifié"
    fi
else
    echo "⚠️  Pas de fichiers Kotlin trouvés (c'est OK si vous utilisez Java)"
fi

if [ -d "android/app/src/main/java/$OLD_PATH" ]; then
    echo "Déplacement des fichiers Java..."
    mkdir -p "android/app/src/main/java/$NEW_PATH"
    mv android/app/src/main/java/$OLD_PATH/* android/app/src/main/java/$NEW_PATH/ 2>/dev/null || echo "Aucun fichier à déplacer"
    
    # Modifier le package dans MainActivity.java
    if [ -f "android/app/src/main/java/$NEW_PATH/MainActivity.java" ]; then
        sed -i '' "s|package $OLD_PACKAGE|package $NEW_PACKAGE|g" "android/app/src/main/java/$NEW_PATH/MainActivity.java"
        echo "✅ MainActivity.java modifié"
    fi
else
    echo "⚠️  Pas de fichiers Java trouvés (c'est OK si vous utilisez Kotlin)"
fi

echo ""
echo "📝 ÉTAPE 4: Clean du projet"
echo "────────────────────────────────────────────────────────────"
flutter clean
echo "✅ Projet nettoyé"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "✅ CHANGEMENT DU PACKAGE NAME TERMINÉ!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 RÉSUMÉ:"
echo "   Ancien package: $OLD_PACKAGE"
echo "   Nouveau package: $NEW_PACKAGE"
echo ""
echo "🔄 PROCHAINES ÉTAPES:"
echo ""
echo "1. Vérifier les changements:"
echo "   cat android/app/build.gradle.kts | grep applicationId"
echo ""
echo "2. Rebuild l'app:"
echo "   flutter pub get"
echo "   flutter build appbundle --release"
echo ""
echo "3. L'AAB sera dans:"
echo "   build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "4. Sur Play Console:"
echo "   - Créer une nouvelle app avec le package: $NEW_PACKAGE"
echo "   - Uploader le nouveau AAB"
echo ""
echo "════════════════════════════════════════════════════════════"
