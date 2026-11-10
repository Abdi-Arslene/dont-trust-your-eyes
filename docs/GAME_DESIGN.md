# Game design — Don't Trust Your Eyes

**Pour qui :** les enfants à partir de 8-9 ans (et leurs parents).
**Pitch :** Pico doit sortir de la maison des farces de **Filou**, un lutin farceur qui ment. Quand il ment, son nez grandit… presque toujours.
Le jeu ne fait pas que des puzzles : il apprend à l'enfant à **repérer les mensonges**, puis le surprend en trichant avec ses propres règles.

**Format :** puzzle sur grille, vue de dessus, portrait, niveaux courts (30 s à 2 min).
**Contrôles :** un glissement = un pas. **Garder le doigt appuyé** après le glissement fait avancer tout seul (s'arrête au premier mur ou changement de couleur). Marcher sur un objet le ramasse (il s'affiche dans le sac, en haut) ; avancer vers un trou avec la planche la pose, avancer contre la porte grise avec la clé l'ouvre.

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
| Aller chercher ce qui manque | **Le sac.** La planche et la clé traînent dans le niveau, souvent loin du chemin : on les ramasse en marchant dessus. Avec la planche, avancer vers un trou la pose (un seul trou par planche : lequel ?) ; avec la clé, avancer contre la porte grise l'ouvre. | `-` `k` |
| Les commandes changent selon la couleur | **Les flaques.** Rouge : à l'envers. Bleu : quart de tour. Blanc : normal. | `r b w` |
| Plus grand dedans que dehors | **La petite maison.** Une case mène à une pièce entière ; elles peuvent s'emboîter. | `1`–`9` |
| Le tutoriel ment | **Filou** commente tout et ment souvent. Son nez le trahit… presque toujours. | `say` |
| Les murs qui bougent | **Les interrupteurs.** Marcher sur un interrupteur couche les blocs jaunes et lève les violets (ou l'inverse). Il faut prévoir dans quel état seront les blocs en arrivant devant : un aller-retour sur l'interrupteur ne sert à rien. | `s` `y` `u` |
| Le sol qui ment | **Le sol fissuré.** Il tient une fois, puis s'effondre derrière toi. Placé à l'entrée des impasses du noir, il enferme pour toujours celui qui s'y trompe : le seul moyen de repartir est de sauter dans le trou. Le jeu voit quand la porte n'est plus atteignable et Filou se moque. Il y en a aussi sur le bon chemin, pour que les fissures ne trahissent pas la route. | `f` |
| (nouveau) | **Dans le noir.** Seuls le regard et les cases voisines sont éclairés. Ce que tu as vu reste en pâle — mais le souvenir ne bouge pas, alors que les escaliers tournent. | `dark` |
| **Le moment fort** | **Les passages secrets.** « Les murs ne mentent jamais » : faux. Le niveau 19 n'a aucune sortie sans ça, et le passage est au même endroit qu'au niveau 1. Ensuite, les faux murs apparaissent fissurés partout. | `X` |
| (après la révélation) | **Les murs fissurés.** Certaines fissures sont solides. | `x` |
| (la revanche) | **La glace.** On glisse tout droit jusqu'à un obstacle : les rochers deviennent des freins. | `i` |
| (la revanche) | **Les caisses.** On les pousse d'une case (jamais deux à la fois). Dans un trou, elles font un pont ; sur la glace, elles glissent ; dans un coin, elles sont coincées. Elles cachent aussi ce qu'il y a derrière (le regard s'y arrête). | `o` |
| (la revanche) | **Boutons et grilles.** Les grilles s'ouvrent tant que tous les boutons de la pièce sont appuyés, par Pico ou par une caisse. On entre dans une grille ouverte, et on en ressort même fermée. | `p` `g` |

Règle commune : **une action = un tic du monde** (pas, choc, objet posé ou porte ouverte).

## Le mensonge en couches

1. **Le monde ment** : portes dessinées, faux murs, maisons plus grandes dedans.
2. **Filou ment**, et son nez grandit : l'enfant apprend à le repérer.
3. **Le jeu triche avec cette règle** : au niveau 18, le nez grandit sur une phrase vraie ; aux niveaux 19 et 20, les plus gros mensonges sont dits sans que le nez bouge.
4. **La mémoire ment** (le noir) : ce dont tu te souviens a changé.

## Aide (l'ampoule)

1. **Deux indices écrits** par niveau, du plus vague au plus précis.
2. **Le chemin** : depuis la situation *actuelle*, une flèche rose et un doigt animé montrent le prochain glissement. Chaque appui donne le coup suivant.
3. **Aide proactive** : après 3 échecs, l'ampoule clignote et le jeu la propose.
4. Utiliser le chemin plafonne le niveau à 2 étoiles. Les rêves se jouent sans ampoule.
5. **Tutoriel** du niveau 1 : la flèche et le doigt montrent le premier geste.

## Score

- On compte les **pas** (pas, chocs, objets posés, portes ouvertes). L'**objectif** affiché laisse de la marge : solution parfaite + 20 % (au moins +2).
- **Étoiles** : 3 dans l'objectif, 2 jusqu'au double de la solution parfaite, 1 sinon. Total au menu (159).
- **Secrets** : 4 niveaux cachent un raccourci par un faux mur ; faire moins que la solution parfaite le révèle.

## Après l'histoire : de quoi revenir chaque jour

Les trois modes s'ouvrent après le niveau 6, quand l'enfant connaît portes et couleurs.

- **Défi du jour** : un niveau généré par jour, gardé toute la journée. Le finir prolonge la **série** de jours d'affilée.
- **Rêves sans fin** : des niveaux générés à l'infini, de plus en plus grands. **3 cœurs** : tomber ou recommencer un rêve entamé en coûte un ; finir dans l'objectif en rend un. Record au menu.
- **Survie** : des niveaux générés à l'infini, avec une **jauge d'énergie** qui passe d'un niveau à l'autre. Chaque action (pas, choc, objet posé) coûte 1, une chute coûte 3. Chaque nouveau niveau rend de quoi faire son chemin parfait, plus une marge : 6 au début, puis de moins en moins (jusqu'à 1). Les pas gaspillés s'accumulent : jauge vide avant la porte = partie perdue. Au plus 15 points d'énergie sont gardés d'un niveau à l'autre (pas de réserve infinie). Recommencer un niveau est gratuit, mais l'énergie dépensée ne revient pas. Filou prévient quand il reste 5 points, et la jauge clignote en rouge. Pas d'ampoule. Record au menu. Réglages dans `src/game/dream_run.gd`.
- **Le générateur** (`src/core/generator.gd`) : labyrinthe + boucles, sortie au plus loin, puis mécaniques posées *sur le chemin évident* (flaques, escaliers, trous et planche à aller chercher, craie ou clé, glace, caisses, portes dessinées en leurre, noir). Il n'utilise **que ce que l'enfant a déjà rencontré**. Le solveur prouve chaque niveau ; un niveau qui contourne ses mécaniques est rejeté. Le rêve suivant se prépare pendant qu'on joue.

## Costumes

14 costumes pour Pico (couleur + chapeau : casquette, oreilles de chat, couronne, chapeau de magicien, bonnet de nuit, bandeau de ninja, casque de chantier, cache-oreilles…), chacun débloqué par un objectif : étoiles, chutes (« Fantôme »), portes dessinées crues (« Bouffon »), passage secret (« Robot »), séries du défi, rêves d'affilée, histoire finie, caisses poussées (« Déménageur »), revanche finie (« Esquimau »), toutes les étoiles. Les échecs rapportent aussi quelque chose. Un bandeau « Nouveau costume ! » apparaît au moment où l'objectif est atteint.

## Progression (53 niveaux)

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
| 9 | IV. Le sac à malices | Le sac | Aller chercher la planche, la poser |
| 10 | | Clé | Clé + planche à ramasser (secret) |
| 11 | | Le bon trou | Une planche, deux trous |
| 12 | V. Les maisons magiques | Petite maison | Plus grand dedans (gros secret) |
| 13 | | Poupées russes | Maisons emboîtées |
| 14 | | Tout à la fois | Rouge + escalier + planche |
| 15 | | Le balcon | Le casse-tête le plus dur, placé tard exprès |
| 16 | VI. Dans le noir | Lampe de poche | Le regard éclaire, labyrinthe plein d'impasses (secret) |
| 17 | | Souvenirs | La mémoire des escaliers ment, impasses |
| 18 | | Portes closes | Le nez grandit sur une vérité ; chaque impasse finit sur une porte dessinée |
| 19 | VII. Le grand secret | Pas de porte | **La révélation** : les passages secrets |
| 20 | | Fissures | Une fissure ne prouve rien |
| 21 | | Le mur du fond | Passage dans le noir |
| 22 | | La dernière farce | Tout ensemble, puis la fin de l'histoire |
| 23 | VIII. Le lac gelé | Patinoire | Glisser d'un arrêt à l'autre |
| 24 | | Les rochers | Les rochers sont des freins |
| 25 | | Lac rouge | Glisser à l'envers |
| 26 | | Lac de nuit | La glace dans le noir |
| 27 | IX. Les caisses | Pousse ! | Une caisse dans un trou fait un pont |
| 28 | | Le coin | Ne pas coincer une caisse, l'ordre compte |
| 29 | | Le frein | Une caisse sur la glace sert de frein |
| 30 | | L'entrepôt | Trois trous, deux caisses : lesquels boucher ? |
| 31 | X. Les boutons | Le bouton | Une caisse garde le bouton appuyé |
| 32 | | Bouton gelé | La caisse glisse jusqu'au bouton |
| 33 | | Deux boutons | Toi sur un bouton, la caisse sur l'autre |
| 34 | | Grilles gelées | Entrer dans une grille ouverte, en sortir fermée |
| 35 | XI. Le sol qui ment | Aller simple | Le sol fissuré : on ne passe qu'une fois |
| 36 | | Planche de secours | Ramasser la planche avant de se couper la route |
| 37 | | Le parquet qui craque | Tout le sol est fissuré : tracer son chemin avant de bouger |
| 38 | | La clé piégée | L'aller n'est pas le retour |
| 39 | XII. Les pièges de Filou | Glissade fatale | Glace + sol fissuré |
| 40 | | Escalier traître | Attendre l'escalier sans reculer |
| 41 | | Caisse de secours | Une caisse pour réparer le chemin |
| 42 | | La grille piégée | Bouton, grilles et sol fissuré |
| 43 | XIII. Les interrupteurs | Interrupteur | Les blocs jaunes et violets basculent |
| 44 | | Patinoire à bascule | Un bloc debout arrête la glissade |
| 45 | | Deux leviers | Compter les bascules |
| 46 | | Le labyrinthe qui bouge | Prévoir l'état des blocs avant de basculer |
| 47 | XIV. Le grand mélange | Bascule piégée | Blocs + sol fissuré |
| 48 | | Caisse à bascule | Une caisse ne passe pas sur un bloc |
| 49 | | Grilles et fissures | Bouton, caisse et sol fissuré |
| 50 | | Le grand mélange | Rouge, planche, blocs et trous |
| 51 | XV. La revanche de Filou | Le grand lac | Le lac le plus long |
| 52 | | Caisses à l'envers | Pousser des caisses en rouge |
| 53 | | La toute dernière farce | Tout ensemble, à l'envers, puis la vraie fin |

Après le niveau 22, l'histoire se termine (Filou annonce sa revanche) ; les chapitres VIII à XV sont la suite, avec une seconde fin. Les niveaux de la revanche ont été trouvés en générant des milliers de grilles, puis gardés quand le solveur prouve que la solution la plus courte utilise vraiment la mécanique (sans elle, le niveau devient impossible). Les rêves et le défi du jour utilisent aussi la glace et les caisses, une fois rencontrées.

## Style

Couleurs vives, une ambiance par acte (maison, jardin, château, grenier, forêt, nuit, palais, glace, atelier, machines, fissures, pièges, bascule, mélange, revanche), murs en relief, police ronde (Fredoka, licence OFL dans `assets/fonts/`). Le reste est dessiné en code. Confettis et étoiles à la victoire, Pico qui saute, étoiles qui flottent dans les menus, musique en majeur, rire de Filou (« hi hi hi »), « boing » de Pico.
