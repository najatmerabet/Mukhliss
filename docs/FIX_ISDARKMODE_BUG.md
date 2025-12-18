# Script de correction du bug isDarkMode

## Le Bug

Dans 40+ fichiers, le code contient:

```dart
final isDarkMode = themeMode == AppThemeMode.light;  // ❌ INVERSÉ!
```

## La Correction

Remplacer par:

```dart
final isDarkMode = themeMode == AppThemeMode.dark;  // ✅ CORRECT
```

## Fichiers à Corriger (40+ occurrences)

### Widgets (8 fichiers)

- [ ] `lib/widgets/search.dart` - lignes 92, 206
- [ ] `lib/widgets/direction_arrow_widget.dart` - ligne 336
- [ ] `lib/widgets/buttons/route_bottom_sheet.dart` - lignes 41, 374
- [ ] `lib/widgets/buttons/categories_bottom_sheet.dart` - ligne 118
- [ ] `lib/widgets/buttons/ShopDetailsBottomSheet.dart` - ligne 157
- [ ] `lib/widgets/Appbar/custom_sliver_app_bar.dart` - ligne 62

### Screens Auth (2 fichiers)

- [x] `lib/screen/auth/login_page_new.dart` - ✅ Déjà corrigé
- [ ] `lib/screen/auth/Login_page.dart` - lignes 91, 236
- [ ] `lib/screen/auth/signup_page.dart` - ligne 145

### Screens Client (6 fichiers)

- [ ] `lib/screen/client/qr_code_screen.dart` - lignes 137, 338
- [ ] `lib/screen/client/SupportTicketFormScreen .dart` - lignes 97, 157, 209, 275, 347, 419, 473
- [ ] `lib/screen/client/offres.dart` - ligne 117
- [ ] `lib/screen/client/Location/location.dart` - lignes 764, 1573, 1608
- [ ] `lib/screen/client/profile_new.dart` - lignes 204, 243, 297, 386, 486, 765, 783, 865, 1162

### Screens Profile (2 fichiers)

- [ ] `lib/screen/client/profile/devices_screen.dart` - lignes 143, 245, 308, 343, 409
- [ ] `lib/screen/client/profile/settings_screen.dart` - lignes 236, 337, 442, 585, 648, 675, 735

### Autres (1 fichier)

- [ ] `lib/screen/slash_screen.dart` - ligne 104

## Commande de Correction Automatique

Pour corriger tous les fichiers en une seule commande:

```bash
cd /Users/prodmeat/MukhlissClient/Mukhliss

# Pour macOS/Linux
find lib -name "*.dart" -exec sed -i '' 's/themeMode == AppThemeMode.light/themeMode == AppThemeMode.dark/g' {} \;

# Vérifier les changements
git diff lib/
```

⚠️ NOTE: Cette commande remplacera TOUTES les occurrences. Vérifiez avec `git diff` avant de commit.

## Solution Long Terme

Utiliser `ThemeUtils.isDarkMode(ref)` au lieu d'écrire la condition manuellement:

```dart
// ❌ Avant (source de bugs)
final isDarkMode = themeMode == AppThemeMode.dark;

// ✅ Après (centralisé, sans bugs)
import 'package:mukhliss/core/theme/theme_utils.dart';
final isDarkMode = ThemeUtils.isDarkMode(ref);
```
