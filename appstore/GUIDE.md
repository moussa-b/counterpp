# Publier Counter++ sur l'App Store

État au 24/10/2026 : l'IPA signée **Apple Distribution (34AFV4S7Z8)** de la version
**1.3.0 (build 15)** est dans `build/ios/ipa/counterpp.ipa`, l'archive Xcode dans
`build/ios/archive/Runner.xcarchive`. Les captures sont dans `appstore/screenshots/`.

## À régler avant de soumettre (risques de rejet)

1. **Politique de confidentialité** : réglé. URL `https://bdzapps.com/counter/privacy/`, à
   reporter aussi dans App Store Connect.
2. **Lien « Partager l'app »** : réglé. Sur iOS, l'entrée reste masquée tant que
   `AppConfig.appStoreUrl` est vide. Après création de la fiche (étape 1), y mettre
   `https://apps.apple.com/app/id<APPLE_ID>` dans une version suivante pour la réactiver.
3. **Tutoriel** : ses images montrent un téléphone Android (barre ◀ ● ■). Même règle 2.3.10.
   Ça passe parfois, mais c'est le motif de rejet le plus probable.

## 1. Créer la fiche dans App Store Connect

<https://appstoreconnect.apple.com> → Apps → **+** → Nouvelle app

| Champ | Valeur |
|---|---|
| Plateformes | iOS |
| Nom | Counter++ (s'il est pris : « Counter++ Compteur ») |
| Langue principale | Français (France) |
| Identifiant de lot | `com.bdzapps.counter.counter` (déjà créé par la signature auto) |
| SKU | `counterpp-ios` |
| Accès utilisateur | Accès complet |

Ajoute ensuite la localisation **Anglais (U.S.)** (menu langue en haut à droite de la fiche).

## 2. Envoyer le build

Option la plus simple, par Xcode :

```bash
open build/ios/archive/Runner.xcarchive
```

Organizer → **Distribute App** → **App Store Connect** → **Upload**. Les options par défaut conviennent.

Autre option : l'app **Transporter** (Mac App Store), glisser `build/ios/ipa/counterpp.ipa`.

Le build apparaît dans l'onglet TestFlight après 5 à 30 min de traitement. La question sur le
chiffrement ne sera pas posée : `ITSAppUsesNonExemptEncryption = false` est déjà dans `Info.plist`.

Pour les prochaines versions : incrémenter `version:` dans `pubspec.yaml` (le numéro de build
doit toujours augmenter), puis `fvm flutter build ipa --release --export-method app-store`.

## 3. Remplir la version 1.3.0

### Captures

Glisser les fichiers dans l'ordre 01 → 05 :

- **iPhone 6,9"** : `appstore/screenshots/iphone-6.9/{fr,en}/` (1320×2868). Apple les réduit
  pour les autres tailles d'iPhone.

L'app est **iPhone uniquement** (`TARGETED_DEVICE_FAMILY = 1`), donc aucune capture iPad n'est
demandée. Elle reste installable sur iPad en mode compatibilité iPhone. On pourra ajouter le
support iPad plus tard ; l'inverse est impossible, Apple refuse de retirer l'iPad une fois publié.

### Textes (FR)

- **Sous-titre** (30 car.) : `Compteur pour mémoriser`
- **Mots-clés** (100 car.) : `compteur,répétition,mémorisation,tally,révision,habitude,dhikr,tasbih,statistiques,dossier,clicker`
- **Texte promotionnel** : `Comptez vos répétitions, organisez-les en dossiers et suivez vos progrès.`
- **Description** :

```
Counter++ vous aide à suivre tout ce qui se répète : révisions, vocabulaire, prières, séries de sport, habitudes.

• Un compteur infini sur l'écran d'accueil : un tap pour compter.
• Des compteurs illimités, avec objectif, pas d'incrémentation, couleur et notes.
• Des dossiers pour organiser vos compteurs.
• Des statistiques par jour, semaine, mois et année, par compteur ou par dossier.
• Vos données restent sur votre téléphone. Pas de compte, pas de publicité.
• Synchronisation optionnelle vers votre propre serveur.
```

### Texts (EN)

- **Subtitle**: `Repetition counter`
- **Keywords**: `counter,tally,repetition,memorize,habit,dhikr,tasbih,clicker,statistics,folders,revision`
- **Promotional text**: `Count repetitions, organise them in folders and track your progress.`
- **Description**:

```
Counter++ helps you track anything you repeat: revision, vocabulary, prayers, workout sets, habits.

• An infinite counter on the home screen: one tap to count.
• Unlimited counters with a goal, step, colour and notes.
• Folders to organise your counters.
• Statistics by day, week, month and year, per counter or per folder.
• Your data stays on your phone. No account, no ads.
• Optional synchronisation to your own server.
```

### Autres champs

| Champ | Valeur |
|---|---|
| URL d'assistance | une page web ou `mailto:` qui renvoie vers boudamouzm@gmail.com |
| URL de politique de confidentialité | `https://bdzapps.com/counter/privacy/` |
| Copyright | `2026 Moussa Boudamouz` |
| Catégorie | Productivité (secondaire : Éducation) |
| Prix | Gratuit (onglet Tarifs et disponibilité) |
| Build | sélectionner 1.3.0 (15) |
| Connexion requise | Non (pas de compte de démo à fournir) |

### Confidentialité de l'app

Choisir **« Aucune donnée collectée »**. Par défaut rien ne quitte l'appareil. La synchro et
l'envoi des logs par e-mail ne s'activent que si l'utilisateur configure lui-même son serveur ou
ses clés Mailgun.

### Classification par âge

Répondre « Aucun » ou « Non » partout → **4+**.

## 4. Soumettre

**Ajouter pour vérification** → **Soumettre**. Délai habituel : 24 à 48 h. Pour un premier envoi,
choisir la publication manuelle afin de pouvoir corriger la fiche avant la sortie.
