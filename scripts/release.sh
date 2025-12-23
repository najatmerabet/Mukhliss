#!/bin/bash
# 🚀 Script de Release pour Mukhliss
# Usage: ./scripts/release.sh [patch|minor|major]

set -e

VERSION_TYPE=${1:-patch}

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Mukhliss Release Script${NC}"
echo "================================"

# Vérifier que nous sommes sur master/main
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" != "master" && "$BRANCH" != "main" ]]; then
    echo -e "${YELLOW}⚠️  Vous n'êtes pas sur master/main. Continuer? (y/n)${NC}"
    read -r response
    if [[ "$response" != "y" ]]; then
        exit 1
    fi
fi

# Obtenir la version actuelle du pubspec.yaml
CURRENT_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
echo -e "Version actuelle: ${GREEN}$CURRENT_VERSION${NC}"

# Calculer la nouvelle version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

case $VERSION_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Usage: $0 [patch|minor|major]"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
BUILD_NUMBER=$(date +%Y%m%d%H%M)

echo -e "Nouvelle version: ${GREEN}$NEW_VERSION+$BUILD_NUMBER${NC}"

# Confirmation
echo -e "${YELLOW}Créer release v$NEW_VERSION? (y/n)${NC}"
read -r confirm
if [[ "$confirm" != "y" ]]; then
    echo "Annulé."
    exit 0
fi

# 1. Mettre à jour pubspec.yaml
echo -e "${BLUE}📝 Mise à jour pubspec.yaml...${NC}"
sed -i '' "s/version: .*/version: $NEW_VERSION+$BUILD_NUMBER/" pubspec.yaml

# 2. Exécuter les tests
echo -e "${BLUE}🧪 Exécution des tests...${NC}"
flutter test

# 3. Build Android
echo -e "${BLUE}🤖 Build Android App Bundle...${NC}"
flutter build appbundle --release

# 4. Commit
echo -e "${BLUE}📦 Commit des changements...${NC}"
git add pubspec.yaml
git commit -m "chore: release v$NEW_VERSION"

# 5. Créer le tag
echo -e "${BLUE}🏷️  Création du tag v$NEW_VERSION...${NC}"
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"

# 6. Push
echo -e "${BLUE}🚀 Push vers GitHub...${NC}"
git push origin $BRANCH
git push origin "v$NEW_VERSION"

echo ""
echo -e "${GREEN}✅ Release v$NEW_VERSION créée avec succès!${NC}"
echo ""
echo "Actions suivantes:"
echo "1. Le CI/CD va automatiquement builder et tester"
echo "2. Si configuré, déploiement automatique vers les stores"
echo ""
echo "Fichiers de build:"
echo "  - Android: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "Pour déployer manuellement:"
echo "  - Play Console: https://play.google.com/console"
echo "  - App Store Connect: https://appstoreconnect.apple.com"
