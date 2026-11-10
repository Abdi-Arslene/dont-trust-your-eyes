# Publier sur Google Play

Tout ce qu'il faut pour mettre le jeu sur le Play Store : le build, la fiche, et les réponses aux questionnaires de la Play Console.

## 1. Le build signé

```powershell
powershell -ExecutionPolicy Bypass -File tools/export_release.ps1
```

Le script produit `build/dont-trust-your-eyes.aab` : le préréglage « Android Play », avec compilation Gradle, cible API 36 (Android 16, exigée par Google Play depuis le 31 août 2026), les architectures arm 32/64 bits et x86_64, et les icônes adaptatives.

- **Clé d'envoi (upload key)** : `%USERPROFILE%\dtye-signing\upload.jks`. Le mot de passe est dans `signing.env`, dans le même dossier. **Ce dossier ne va jamais dans Git.** Sauvegarde-le (gestionnaire de mots de passe + clé USB). Avec la signature d'application Play (activée par défaut), Google garde la vraie clé de l'app. Si la clé d'envoi est perdue, on peut la faire réinitialiser depuis la Play Console, mais cela prend quelques jours.
- **Nouvelle version** : avant chaque nouvel envoi, augmente `version/code` (1, 2, 3…) et `version/name` dans `export_presets.cfg`, dans les trois préréglages.
- **APK à partager** (hors Play Store, vrais téléphones uniquement) : `powershell -ExecutionPolicy Bypass -File tools/export_release.ps1 -Preset "Android APK" -Output build/DontTrustYourEyes.apk`
- **Identifiant de l'app** : `com.donttrustyoureyes.game`. Il ne pourra **plus jamais changer** après le premier envoi.
- **Modèle Gradle** : le dossier `android/` est généré par le script (option `--install-android-build-template`). Il n'est pas versionné.
- **Images** : `tools/store_art.gd` redessine les icônes et la bannière avec le code du jeu :
  ```
  godot --path . --script res://tools/store_art.gd
  ```

## 2. Le compte développeur

1. Va sur https://play.google.com/console/signup. Choisis un compte **personnel**. Les frais d'inscription sont de 25 $, payés une seule fois.
2. Vérifie ton identité (pièce d'identité) et ton téléphone Android, via l'app Play Console.
3. Les adresses e-mail et postales de contact du développeur sont affichées publiquement sur la fiche.

**Règle importante pour les comptes personnels récents** : avant de pouvoir publier pour tout le monde, il faut un **test fermé** avec **au moins 12 testeurs** inscrits pendant **14 jours d'affilée**. Prévois une liste de 12 adresses Gmail (famille, amis, parents d'élèves). Les testeurs installent le jeu depuis un lien et le gardent installé pendant les 14 jours. Google demande ensuite quelques réponses sur le test (ce que les testeurs ont remonté, ce qui a changé) avant d'ouvrir la production.

## 3. Créer l'app dans la Play Console

| Champ | Réponse |
|---|---|
| Nom de l'app | Don't Trust Your Eyes |
| Langue par défaut | Français (France) – fr-FR |
| App ou jeu | Jeu |
| Gratuit ou payant | Gratuit (définitif : une app gratuite ne peut pas devenir payante) |

## 4. Contenu de l'app (questionnaires)

| Section | Réponse |
|---|---|
| Règles de confidentialité | https://github.com/Abdi-Arslene/dont-trust-your-eyes/blob/main/docs/PRIVACY.md |
| Accès à l'app | Toutes les fonctionnalités sont disponibles sans restriction (pas de compte) |
| Annonces | Non, l'app ne contient pas d'annonces |
| Classification du contenu | Catégorie « Jeu ». Violence, peur, sexualité, langage, drogues, jeux d'argent : **Non** partout. Interaction entre utilisateurs, partage de position, achats numériques : **Non**. Résultat attendu : PEGI 3 / Tout public. |
| Public cible | **6 à 8 ans** et **9 à 12 ans**. Le jeu doit alors respecter le règlement **Familles**. C'est déjà le cas : pas de pub, pas de données, pas d'achat, pas de lien sortant. « L'app pourrait-elle attirer involontairement les enfants ? » ne s'applique pas, puisqu'elle les vise. |
| Sécurité des données | « Votre app collecte-t-elle ou partage-t-elle des données ? » → **Non**. Aucune donnée ne quitte l'appareil, et le jeu n'a pas l'autorisation Internet. |
| Applications gouvernementales, fonctionnalités financières, santé, actualités | Non |
| Programme Familles / « Approuvé par les enseignants » | Facultatif, on pourra le demander plus tard |

## 5. Fiche du Play Store

**Catégorie** : Jeux › Réflexion. **Tags** : Puzzle, Labyrinthe, Enfants. **E-mail de contact** : obligatoire et public.

**Description courte** (80 caractères max) :

> Aide Pico à fuir la maison des farces de Filou. Ne crois pas tes yeux !

**Description complète** :

> Pico est coincé dans la maison des farces de Filou, un petit lutin qui adore mentir. Quand il ment, son nez grandit… enfin, presque toujours !
>
> Glisse ton doigt pour guider Pico jusqu'à la vraie porte. Mais attention : dans cette maison, rien n'est comme il en a l'air.
> • Des portes dessinées sur les murs
> • Des flaques de couleur qui mélangent les commandes
> • Des escaliers qui tournent dès que tu ne les regardes pas
> • Des petites maisons plus grandes dedans que dehors
> • Un lac gelé où l'on glisse, des caisses à pousser, des boutons qui ouvrent des grilles
> • Un sol qui s'effondre derrière toi : attention aux impasses !
> • Des interrupteurs qui font bouger les murs
> • Et des murs… qui ne disent pas toujours la vérité
>
> 53 NIVEAUX D'AVENTURE
> Une histoire en 15 chapitres, du plus facile au plus malin. Chaque niveau se joue en une ou deux minutes, et fait vraiment réfléchir.
>
> ENCORE PLUS DE JEU
> • Défi du jour : un nouveau niveau chaque jour
> • Rêves sans fin : des niveaux à l'infini, avec 3 cœurs
> • Survie : chaque pas use ton énergie. Jusqu'où iras-tu ?
> • 14 costumes rigolos à débloquer pour Pico
>
> FAIT POUR LES ENFANTS
> • Pour les enfants à partir de 8 ans
> • Pas de publicité, pas d'achat, pas de compte
> • Aucune donnée collectée, fonctionne sans Internet
> • Une ampoule d'aide quand on est bloqué
> • On apprend à observer, à réfléchir… et à repérer les menteurs !

**Images** (dans [docs/store/](store/)) :

| Image | Fichier |
|---|---|
| Icône 512 × 512 | `icon-512.png` |
| Bannière 1024 × 500 | `feature-graphic.png` |
| Captures téléphone (2 à 8, format 9:16) | `screenshot-*.png` |

## 6. Envoyer le jeu

1. **Tests › Test fermé** : crée une liste de testeurs (les 12 adresses), puis « Créer une release ».
2. Accepte la **signature d'application par Google Play** et envoie `build/dont-trust-your-eyes.aab`.
3. Notes de version : « Première version : 53 niveaux, défi du jour, rêves sans fin, survie et 14 costumes. »
4. Envoie la release en examen. Le premier examen prend de quelques jours à une semaine, parfois plus pour une app destinée aux enfants.
5. Partage le lien d'inscription aux testeurs. Au bout de 14 jours avec 12 testeurs inscrits : **Tableau de bord › Demander l'accès à la production**.
6. Une fois l'accès accordé, envoie la même release (ou une nouvelle) en **Production**.

## 7. Publication automatique (GitHub Actions)

Deux pipelines sont dans [.github/workflows/](../.github/workflows/) :

- **Tests** (`tests.yml`) : à chaque push sur `main`, les tests des règles et la partie complète de tous les niveaux.
- **Publier sur Google Play** (`release.yml`) : à chaque tag `v1.2.3`, il teste le jeu, fabrique le `.aab` signé (version `1.2.3`, code `10203`) et l'APK, envoie le `.aab` sur la piste de **test fermé** (`alpha`), et joint l'APK à une release GitHub. Si un test échoue, rien n'est publié.

### Mise en place (une seule fois)

1. **Compte de service Google** (ce qui autorise GitHub à envoyer le jeu) :
   1. Sur https://console.cloud.google.com, crée un projet, puis active l'API **Google Play Android Developer API**.
   2. **IAM et administration › Comptes de service › Créer un compte de service** (aucun rôle n'est nécessaire). Dans le compte créé : **Clés › Ajouter une clé › JSON**. Un fichier `.json` se télécharge : c'est un secret, ne le mets jamais dans Git.
   3. Dans la Play Console : **Utilisateurs et autorisations › Inviter un utilisateur**, avec l'adresse e-mail du compte de service (elle finit par `iam.gserviceaccount.com`). Dans **Autorisations de l'application**, ajoute *Don't Trust Your Eyes* avec les droits **Publier dans les canaux de test** et **Gérer les canaux de test et modifier les listes de testeurs** (plus **Publier en production** le jour où tu veux publier en production depuis le pipeline). L'accès peut mettre jusqu'à 24 h à s'activer.
2. **Secrets GitHub** : sur GitHub, **Settings › Secrets and variables › Actions › New repository secret**, quatre secrets :

   | Nom | Valeur |
   |---|---|
   | `PLAY_SERVICE_ACCOUNT_JSON` | tout le contenu du fichier `.json` du compte de service |
   | `ANDROID_KEYSTORE_BASE64` | tout le contenu de `%USERPROFILE%\dtye-signing\upload.jks.b64` (la clé d'envoi, encodée) |
   | `ANDROID_KEY_ALIAS` | `upload` |
   | `ANDROID_KEYSTORE_PASSWORD` | le mot de passe écrit dans `%USERPROFILE%\dtye-signing\signing.env` |

   Pour refaire le fichier encodé : `base64 -w0 upload.jks > upload.jks.b64` (Git Bash), dans le dossier de la clé.

### Publier une nouvelle version

1. Écris les nouveautés dans [distribution/whatsnew/whatsnew-fr-FR](../distribution/whatsnew/whatsnew-fr-FR) (500 caractères au plus).
2. Choisis un numéro plus grand que le précédent, puis :
   ```
   git tag v1.1.0
   git push origin v1.1.0
   ```
3. Suis l'avancement dans l'onglet **Actions** du dépôt GitHub. La nouvelle version arrive dans **Test fermé** de la Play Console, puis passe l'examen de Google.

Pour une autre piste (`internal`, `beta`, `production`), lance le pipeline à la main : **Actions › Publier sur Google Play › Run workflow**, avec la version et la piste.

Le numéro de version vient uniquement du tag : `export_presets.cfg` garde `1.0.0` pour les builds faits sur le PC. Tant que la toute première version n'a pas fini son examen chez Google, l'API peut refuser l'envoi (« only releases with status draft may be created on draft app ») : attends la fin de l'examen.

## 8. Avant d'envoyer (vérifications)

- [ ] L'e-mail de contact du développeur est renseigné dans la Play Console : la politique de confidentialité y renvoie.
- [ ] Le build release a été installé et testé sur un vrai téléphone (le plus ancien possible).
- [ ] `version/code` est plus grand que celui de la dernière version envoyée.
