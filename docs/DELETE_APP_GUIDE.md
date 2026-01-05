# 🗑️ GUIDE: Comment supprimer l'ancienne app Mukhliss sur Play Console

## 📍 Navigation dans Play Console (English)

### ÉTAPE 1: Aller sur Play Console

1. Ouvrir: https://play.google.com/console
2. Se connecter
3. Vous verrez la liste de vos apps

### ÉTAPE 2: Identifier le statut de votre app

Click sur votre app "Mukhliss" et regardez en haut:

- **Draft** = Brouillon (jamais publiée)
- **In review** = En cours de review
- **Published** = Publiée sur le Play Store

---

## 🔍 CAS 1: App en DRAFT (Brouillon)

### Navigation exacte:

```
Left sidebar → Setup → Advanced settings → Scroll to bottom → Delete app
```

### Étapes détaillées:

1. **Click sur votre app "Mukhliss"** dans la liste
2. Dans le menu de gauche, scrollez vers le bas
3. Section **"Setup"** → Click pour expand si fermé
4. Click sur **"Advanced settings"**
5. Scrollez tout en bas de la page
6. Vous verrez une section rouge: **"Delete app"**
7. Click sur le bouton **"Delete app"**
8. Une popup apparaît → Confirmez en tapant le nom de l'app
9. Click **"Permanently delete"**

### Screenshot de quoi chercher:

```
┌─────────────────────────────────┐
│ Left Sidebar                    │
├─────────────────────────────────┤
│ Dashboard                       │
│ Releases                        │
│   ▶ Testing                     │
│   ▶ Production                  │
│ Grow                            │
│   ▶ Store presence              │
│ Setup ◀──── CHERCHEZ ICI        │
│   Dashboard                     │
│   App access                    │
│   Ads                           │
│   Content rating                │
│   Target audience               │
│   News apps                     │
│   Data safety                   │
│   App content                   │
│   Advanced settings ◀─── CLICK  │
│ Policy                          │
└─────────────────────────────────┘
```

Puis sur la page "Advanced settings":

```
Advanced settings
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Other settings...]

[Scroll tout en bas ↓]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Delete app
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Permanently delete this app from
   Play Console

Once you delete this app, you won't
be able to reuse its package name.

[Delete app] ◀─── CLICK ICI
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🔍 CAS 2: App PUBLISHED (Publiée)

Si votre app est déjà publiée, vous devez d'abord la retirer du Play Store:

### Option A: Unpublish l'app d'abord

```
Production → Countries/regions → Deselect all countries → Save
```

**Étapes:**

1. Left sidebar → **Production**
2. Dans la page, cherchez l'onglet **"Countries / regions"**
3. Click **"Edit countries"** ou équivalent
4. **Deselect all** (décocher tous les pays)
5. Click **"Save"**
6. Attendez quelques heures

Ensuite, allez dans:

```
Setup → Advanced settings → Delete app
```

### Option B: Suspend l'app

1. Left sidebar → **Grow** → **Store presence** → **Main store listing**
2. En haut ou dans les options, cherchez **"Suspend app"**
3. Confirmez la suspension
4. Attendez que Google la suspende (quelques heures)
5. Ensuite: **Setup → Advanced settings → Permanently delete app**

---

## 🔍 CAS 3: App en REVIEW

Si votre app est en cours de review:

1. Annulez la review d'abord:
   - **Production** → **Published releases**
   - Ou: **Testing** → selon où elle est
   - Cherchez **"Halt rollout"** ou **"Cancel review"**
2. Une fois annulée, suivez les étapes du CAS 1 (Draft)

---

## ⚠️ ALTERNATIVES si vous ne trouvez pas

### Si "Advanced settings" n'apparaît pas:

Essayez ces autres emplacements:

1. **Dans le dashboard de l'app:**

   - Click sur les 3 points ⋮ (en haut à droite)
   - Cherchez "Delete app" ou "App settings"

2. **Via App content:**

   - Left sidebar → **Setup** → **App content**
   - Scroll en bas
   - Parfois l'option "Delete" est là

3. **Via Dashboard:**
   - Click sur l'app
   - Première page (Dashboard)
   - En haut à droite: ⋮ menu
   - "Delete app"

---

## 📝 CHECKLIST AVANT DE SUPPRIMER

Avant de supprimer définitivement, vérifiez:

- [ ] Vous avez le nouveau keystore sauvegardé en 3 endroits
- [ ] Vous avez le nouveau AAB buildé (`app-release.aab`)
- [ ] Vous êtes prêt à créer une nouvelle app immédiatement
- [ ] Vous comprenez que vous ne pourrez PAS réutiliser le package name `com.nextgen.mukhliss` pendant ~quelque temps

---

## 🎯 SI VOUS NE TROUVEZ TOUJOURS PAS

### Dernière option: Contactez Google Support

1. Play Console → Help (point d'interrogation ?)
2. **Contact us** ou **Get support**
3. Sélectionnez le sujet: **"App management"** → **"Delete app"**
4. Expliquez que vous voulez supprimer l'app

**OU**

### Laissez l'app en Draft et créez une nouvelle

Si c'est trop compliqué de supprimer:

- Laissez l'ancienne app là (en Draft, elle ne coûte rien)
- Créez une **nouvelle app** avec:
  - Nom: "Mukhliss 2024" ou "Mukhliss App"
  - Même package: `com.nextgen.mukhliss` (si l'ancienne est supprimée)
  - OU nouveau package: `com.mukhliss.app`

---

## 🔑 MOTS-CLÉS À CHERCHER (English)

Dans la recherche de Play Console, essayez:

- "delete app"
- "remove app"
- "advanced settings"
- "permanently delete"

---

## ✅ UNE FOIS SUPPRIMÉE

Quand l'app est supprimée, vous verrez un message de confirmation.

**Ensuite, IMMÉDIATEMENT:**

1. Créer la nouvelle app
2. Activer Play App Signing
3. Uploader votre nouveau AAB

---

## 📞 BESOIN D'AIDE EN TEMPS RÉEL?

Si vous êtes bloqué, partagez-moi:

1. Une capture d'écran de votre Play Console
2. Le statut de l'app (Draft/Published/In review)
3. Ce que vous voyez dans le menu "Setup"

Et je vous guiderai exactement où aller!
