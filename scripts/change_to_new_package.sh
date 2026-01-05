#!/bin/bash

echo "🔄 Changement du package name vers un nouveau"
echo "════════════════════════════════════════════════════════════"

OLD_PACKAGE="com.mukhliss.app"
NEW_PACKAGE="com.mukhliss.client"  # Nouveau package

OLD_PATH="com/mukhliss/app"
NEW_PATH="com/mukhliss/client"

echo "📝 Modification du package name:"
echo "   Ancien: $OLD_PACKAGE"
echo "   Nouveau: $NEW_PACKAGE"
echo ""

# Backup
cp android/app/build.gradle.kts android/app/build.gradle.kts.backup.$(date +%Y%m%d_%H%M%S)
cp android/app/src/main/AndroidManifest.xml android/app/src/main/AndroidManifest.xml.backup.$(date +%Y%m%d_%H%M%S)

# Modifier build.gradle.kts
sed -i '' "s|namespace = \"$OLD_PACKAGE\"|namespace = \"$NEW_PACKAGE\"|g" android/app/build.gradle.kts
sed -i '' "s|applicationId = \"$OLD_PACKAGE\"|applicationId = \"$NEW_PACKAGE\"|g" android/app/build.gradle.kts

# Modifier AndroidManifest
sed -i '' "s|package=\"$OLD_PACKAGE\"|package=\"$NEW_PACKAGE\"|g" android/app/src/main/AndroidManifest.xml

echo "✅ Package name modifié!"
echo ""
echo "🔄 Nettoyage et rebuild..."
flutter clean

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ TERMINÉ!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 Nouveau package name: $NEW_PACKAGE"
echo ""
echo "🔄 PROCHAINES ÉTAPES:"
echo "1. flutter pub get"
echo "2. flutter build appbundle --release"
echo "3. Créer une NOUVELLE app sur Play Console avec package: $NEW_PACKAGE"
echo "4. Uploader le nouveau AAB"
echo ""
