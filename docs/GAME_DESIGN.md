# Game design — Don't Trust Your Eyes

**Pour qui :** les enfants à partir de 8-9 ans (et leurs parents).
**Pitch :** Pico doit sortir de la maison des farces de **Filou**, un lutin farceur qui ment. Quand il ment, son nez grandit… presque toujours.
Le jeu ne fait pas que des puzzles : il apprend à l'enfant à **repérer les mensonges**, puis le surprend en trichant avec ses propres règles.

**Format :** puzzle sur grille, vue de dessus, portrait, niveaux courts (30 s à 2 min).
**Contrôles :** un glissement = un pas. **Garder le doigt appuyé** après le glissement fait avancer tout seul (s'arrête au premier mur ou changement de couleur). Glisser un objet du haut de l'écran = le poser dans le niveau.

## Personnages

- **Pico** (le joueur) : une petite boule ronde aux grands yeux. Il sursaute quand il se cogne, crie quand il tombe, saute de joie à la porte. Ses yeux regardent là où il va.
- **Filou** (le narrateur) : lutin vert au chapeau violet, en bas de l'écran avec une bulle de BD. Il rit quand Pico tombe dans un piège, boude quand Pico gagne, est surpris quand on découvre un passage.
- **Le nez de Filou** : il grandit pendant ses mensonges (répliques marquées `~` dans les niveaux). C'est la règle que tout enfant comprend (Pinocchio)… et que le jeu retourne à la fin.
- **Les indices** viennent de l'**ampoule**, jamais de Filou : ils s'affichent en bleu et ne mentent jamais (Filou boude quand on les utilise).

## Les mécaniques

| Idée | Règle dans le jeu | Case |
|---|---|---|
| Les escaliers changent quand tu ne les regardes pas | **Le regard.** Pico éclaire ce qu'il regarde (rayon jaune). Après chaque action, chaque escalier **hors du regard** tourne d'un quart. Un escalier ne se traverse que dans le sens de ses flèches. Se cogner = attendre. | `^ > v <` |
| Une porte dessinée devient réelle | **La craie.** Toucher un contour à la craie le rend réel. | `c` |
| (corollaire) | **La porte dessinée.** Identique à la vraie, mais c'est un mur. | `d` |
| Les objets du menu apparaissent dans le niveau | **Le sac.** Ce qui est en haut de l'écran se pose dans le niveau : la planche comble un trou, la clé ouvre la porte grise. | `items` |
| Les commandes changent selon la couleur | **Les flaques.** Rouge : à l'envers. Bleu : quart de tour. Blanc : normal. | `r b w` |
| Plus grand dedans que dehors | **La petite maison.** Une case mène à une pièce entière ; elles peuvent s'emboîter. | `1`–`9` |
| Le tutoriel ment | **Filou** commente tout et ment souvent. Son nez le trahit… presque toujours. | `say` |
| (nouveau) | **Dans le noir.** Seuls le regard et les cases voisines sont éclairés. Ce que tu as vu reste en pâle — mais le souvenir ne bouge pas, alors que les escaliers tournent. | `dark` |
| **Le moment fort** | **Les passages secrets.** « Les murs ne mentent jamais » : faux. Le niveau 19 n'a aucune sortie sans ça, et le passage est au même endroit qu'au niveau 1. Ensuite, les faux murs apparaissent fissurés partout. | `X` |
| (après la révélation) | **Les murs fissurés.** Certaines fissures sont solides. | `x` |

Règle commune : **une action = un tic du monde** (pas, choc, ou objet posé).

## Le mensonge en couches

1. **Le monde ment** : portes dessinées, faux murs, maisons plus grandes dedans.
2. **Filou ment**, et son nez grandit : l'enfant apprend à le repérer.
3. **Le jeu triche avec cette règle** : au niveau 18, le nez grandit sur une phrase vraie ; aux niveaux 19 et 20, les plus gros mensonges sont dits sans que le nez bouge.
4. **La mémoire ment** (le noir) : ce dont tu te souviens a changé.

## Aide (l'ampoule)

1. **Deux indices écrits** par niveau, du plus vague au plus précis.
2. **Le chemin** : depuis la situation *actuelle*, une flèche rose et un doigt animé montrent le prochain glissement (ou la case où poser l'objet). Chaque appui donne le coup suivant.
3. **Aide proactive** : après 3 échecs, l'ampoule clignote et le jeu la propose.
4. Utiliser le chemin plafonne le niveau à 2 étoiles. Les rêves se jouent sans ampoule.
5. **Tutoriel** du niveau 1 : la flèche et le doigt montrent le premier geste.

## Score

- On compte les **pas** (pas, chocs, objets posés). L'**objectif** affiché laisse de la marge : solution parfaite + 20 % (au moins +2).
- **Étoiles** : 3 dans l'objectif, 2 jusqu'au double de la solution parfaite, 1 sinon. Total au menu (66).
- **Secrets** : 4 niveaux cachent un raccourci par un faux mur ; faire moins que la solution parfaite le révèle.

## Après l'histoire : de quoi revenir chaque jour

Les trois modes s'ouvrent après le niveau 6, quand l'enfant connaît portes et couleurs.

- **Défi du jour** : un niveau généré par jour, gardé toute la journée. Le finir prolonge la **série** de jours d'affilée.
- **Rêves sans fin** : des niveaux générés à l'infini, de plus en plus grands. **3 cœurs** : tomber ou recommencer un rêve entamé en coûte un ; finir dans l'objectif en rend un. Record au menu.
- **Survie** : des niveaux générés à l'infini, avec une **jauge d'énergie** qui passe d'un niveau à l'autre. Chaque action (pas, choc, objet posé) coûte 1, une chute coûte 3. Chaque nouveau niveau rend de quoi faire son chemin parfait, plus une marge : 6 au début, puis de moins en moins (jusqu'à 1). Les pas gaspillés s'accumulent : jauge vide avant la porte = partie perdue. Au plus 15 points d'énergie sont gardés d'un niveau à l'autre (pas de réserve infinie). Recommencer un niveau est gratuit, mais l'énergie dépensée ne revient pas. Filou prévient quand il reste 5 points, et la jauge clignote en rouge. Pas d'ampoule. Record au menu. Réglages dans `src/game/dream_run.gd`.
- **Le générateur** (`src/core/generator.gd`) : labyrinthe + boucles, sortie au plus loin, puis mécaniques posées *sur le chemin évident* (flaques, escaliers, trous et planche, craie ou clé, portes dessinées en leurre, noir). Il n'utilise **que ce que l'enfant a déjà rencontré**. Le solveur prouve chaque niveau ; un niveau qui contourne ses mécaniques est rejeté. Le rêve suivant se prépare pendant qu'on joue.

## Costumes

12 costumes pour Pico (couleur + chapeau : casquette, oreilles de chat, couronne, chapeau de magicien, bonnet de nuit, bandeau de ninja…), chacun débloqué par un objectif : étoiles, chutes (« Fantôme »), portes dessinées crues (« Bouffon »), passage secret (« Robot »), séries du défi, rêves d'affilée, histoire finie, toutes les étoiles. Les échecs rapportent aussi quelque chose. Un bandeau « Nouveau costume ! » apparaît au moment où l'objectif est atteint.

## Progression (22 niveaux)

| # | Acte | Titre | Apprend |
|---|---|---|---|
| 1 | I. Les fausses portes | Une porte | Marcher, garder le doigt appuyé (secret caché) |
| 2 | | Juste là | Porte dessinée |
| 3 | | Craie | Porte à la craie |
| 4 | II. Les flaques de couleur | Rouge | Commandes à l'envers |
| 5 | | Bleu | Quart de tour + blanc |
| 6 | | Arc-en-ciel | Enchaîner les trois couleurs |
| 7 | III. Les escaliers farceurs | Escalier | Ils tournent quand on ne les regarde pas |
| 8 | | Ne cligne pas | Figer du regard, attendre en se cognant |
| 9 | IV. Le sac à malices | Le sac | Glisser la planche |
| 10 | | Clé | Clé + planche (secret) |
| 11 | | Le bon trou | Une planche, deux trous |
| 12 | V. Les maisons magiques | Petite maison | Plus grand dedans (gros secret) |
| 13 | | Poupées russes | Maisons emboîtées |
| 14 | | Tout à la fois | Rouge + escalier + planche |
| 15 | | Le balcon | Le casse-tête le plus dur, placé tard exprès |
| 16 | VI. Dans le noir | Lampe de poche | Le regard éclaire (secret) |
| 17 | | Souvenirs | La mémoire des escaliers ment |
| 18 | | Portes closes | Le nez grandit sur une vérité |
| 19 | VII. Le grand secret | Pas de porte | **La révélation** : les passages secrets |
| 20 | | Fissures | Une fissure ne prouve rien |
| 21 | | Le mur du fond | Passage dans le noir |
| 22 | | La dernière farce | Tout ensemble, puis la fin |

## Style

Couleurs vives, une ambiance par acte (maison, jardin, château, grenier, forêt, nuit, palais), murs en relief, police ronde (Fredoka, licence OFL dans `assets/fonts/`). Le reste est dessiné en code. Confettis et étoiles à la victoire, Pico qui saute, étoiles qui flottent dans les menus, musique en majeur, rire de Filou (« hi hi hi »), « boing » de Pico.
