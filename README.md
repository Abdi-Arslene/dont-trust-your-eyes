# Don't Trust Your Eyes

> Ne crois pas tes yeux ! Un jeu de réflexion pour enfants (8-9 ans et plus).

Puzzle mobile (Android + iOS) : Pico doit sortir de la maison de Filou, un lutin farceur qui change les règles, dessine de fausses portes, éteint la lumière… et ment (son nez grandit). 22 niveaux en 7 actes, puis un défi par jour, des rêves à l'infini, un mode survie où chaque pas use l'énergie, et 12 costumes à collectionner.

- Mécaniques et progression : [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md)
- Créer un niveau : [docs/LEVELS.md](docs/LEVELS.md)
- Recommandations pour la suite (tests joueurs, store, monétisation…) : [docs/RECOMMANDATIONS.md](docs/RECOMMANDATIONS.md)

Moteur : **Godot 4.5** (GDScript), renderer *Compatibility* (OpenGL ES 3, le plus compatible en 2D mobile). **Un seul asset** : la police Fredoka (licence OFL, `assets/fonts/`). Tout le reste est dessiné en code, sons et musique synthétisés au démarrage.

## Structure

```
project.godot            config (portrait 720×1280, autoloads Save + Sfx)
scenes/main.tscn         scène unique, point d'entrée
levels/levels.json       les 22 niveaux (format : docs/LEVELS.md)
src/
  core/                  logique pure, sans affichage (testable)
    board.gd             RÈGLES du jeu — le cœur
    generator.gd         niveaux générés (défi du jour, rêves), prouvés par le solveur
    solver.gd            BFS : solvabilité, objectif (par), « prochain coup » de l'ampoule
    levels.gd            chargement des niveaux, étoiles, chapitres
  game/                  un niveau en cours
    game.gd              chef d'orchestre : input → règles → vue, sons, narrateur, score, aide (modes histoire / défi / rêve)
    dream_run.gd         partie infinie (rêves : vies, survie : énergie), génération du niveau suivant en fond
    board_view.gd        dessin + animations (particules, noir, escaliers qui tournent…)
    swipe_area.gd        glissements de doigt + dépôt d'objets
  ui/                    look (couleurs, police), Pico et ses costumes (skins), Filou, barre du haut, bulle, victoire, cartes du menu, réglages…
  screens/               main (navigation + fondus), menu, choix des niveaux, costumes, attente de génération, fin
  autoload/
    save.gd              progression + réglages (Save)
    sfx.gd               sons/musique synthétisés + vibrations (Sfx)
tests/
  run_tests.gd           règles + chaque niveau faisable, par/secret du JSON vérifiés
  smoke_test.gd          joue les 22 niveaux via la vraie interface, l'ampoule, le défi du jour, une partie de rêves, les costumes
```

Principe : `Board` ne connaît ni l'écran ni le doigt. Tout le reste lit `Board` et lui envoie des actions.
Ajouter une mécanique = une case dans `board.gd`, son dessin dans `board_view.gd`, un test.

## Lancer le jeu

1. Installer [Godot 4.5](https://godotengine.org/download) (version standard, pas .NET).
2. Ouvrir Godot → **Importer** → `project.godot` → **F5**.
3. Souris : glisser pour marcher, glisser une icône de la barre du haut vers le niveau. Clavier : flèches.

## Tests

```sh
godot --headless --import                # une fois (enregistre les classes)
godot --headless -s tests/run_tests.gd   # règles, solvabilité, par et secrets du JSON, générateur
godot --headless -s tests/smoke_test.gd  # 22 niveaux, l'ampoule, défi du jour, rêves, costumes
```

Après avoir modifié un niveau, `run_tests` dit si son `par` (objectif) ou son `secret` ne correspondent plus, et donne la bonne valeur.

## Exporter

**Android** (depuis Windows) — preset prêt dans [export_presets.cfg](export_presets.cfg).
1. Prérequis : JDK 17, SDK Android (platform-tools, build-tools 35, platform 35), modèles d'export Godot 4.5.1.
2. **Éditeur → Paramètres de l'éditeur → Export → Android** : chemins du SDK et du JDK.
3. APK de test :
   ```sh
   godot --headless --export-debug "Android" build/dont-trust-your-eyes.apk
   adb install -r build/dont-trust-your-eyes.apk
   ```
   L'export Godot relance le serveur adb : si `adb` dit « device offline », faire `adb kill-server && adb start-server`.
4. Émulateur : lancer avec `-gpu host` (le GPU logiciel par défaut ne compile pas les shaders de Godot → écran noir).
5. Play Store : clé de release (`keytool`) dans le preset, *Gradle build* activé, export `.aab`, arm64 uniquement.

**iOS** (Mac obligatoire, imposé par Apple) : Xcode + compte Apple Developer, preset iOS avec *Team ID* et identifiant, puis archive Xcode.
