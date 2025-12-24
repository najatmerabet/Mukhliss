# 🔧 Configuration Google Sign-In pour iOS

## Prérequis

Votre app utilise déjà Google Sign-In. Pour que cela fonctionne sur l'App Store, vous devez :

1. Créer un Client OAuth **iOS** dans Google Cloud Console
2. Ajouter le fichier `GoogleService-Info.plist` au projet
3. Configurer le URL Scheme correctement

## Étape par Étape

### 1. Google Cloud Console

1. Aller sur https://console.cloud.google.com/apis/credentials
2. Sélectionner votre projet
3. **+ CREATE CREDENTIALS** → **OAuth client ID**
4. Type d'application: **iOS**
5. Bundle ID: `com.mukhliss.app`
6. Cliquer **CREATE**
7. **TÉLÉCHARGER** le fichier `.plist`

### 2. Ajouter le fichier au projet

```bash
cp ~/Downloads/GoogleService-Info.plist ios/Runner/
```

Puis dans Xcode :

- Clic droit sur "Runner" → "Add Files to Runner..."
- Sélectionner le fichier
- ✅ Cocher "Copy items if needed"
- ✅ Cocher "Runner" dans targets

### 3. Mettre à jour Info.plist

Ouvrir le fichier `GoogleService-Info.plist` et copier la valeur de `REVERSED_CLIENT_ID`.

Mettre cette valeur dans `ios/Runner/Info.plist` :

```xml
<key>CFBundleURLTypes</key>
<array>
    <!-- ... autres schemes ... -->
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Remplacer par votre REVERSED_CLIENT_ID -->
            <string>com.googleusercontent.apps.VOTRE_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 4. Configurer Supabase

Dans le dashboard Supabase :

1. **Authentication** → **Providers** → **Google**
2. Activer Google
3. Ajouter le **iOS Client ID** (pas le reversed, le normal)
4. Sauvegarder

### 5. Tester

```bash
flutter clean
cd ios && pod install && cd ..
flutter run
```

## Vérification

Pour vérifier que tout est correct :

1. Le `GoogleService-Info.plist` existe dans `ios/Runner/`
2. Le `REVERSED_CLIENT_ID` dans Info.plist correspond
3. Le Bundle ID est `com.mukhliss.app` partout
4. Google OAuth est configuré avec le bon Client ID iOS dans Supabase

## Erreurs Courantes

| Erreur              | Solution                                       |
| ------------------- | ---------------------------------------------- |
| "Sign in cancelled" | URL Scheme incorrect                           |
| "Invalid client"    | Bundle ID ne correspond pas                    |
| "Error 400"         | Client ID non autorisé dans Google Console     |
| "Error 10"          | GoogleService-Info.plist manquant ou incorrect |
