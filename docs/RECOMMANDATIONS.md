# Recommandations pour la suite

Classées par impact. Les premières sont rapides et décident de la suite.

Public visé : **enfants de 8-9 ans et plus**. Ça change plusieurs choses (tests, store, argent) : voir surtout 1, 5 et 6.

## 1. Faire tester par des enfants avant d'ajouter quoi que ce soit

Le jeu repose sur des « aha ». Seuls de vrais enfants disent s'ils arrivent, et quand.

- **3 à 5 enfants de 8-10 ans**, sur téléphone, sans rien expliquer (avec l'accord des parents). Regarde par-dessus l'épaule : où ils bloquent, rient, abandonnent, s'ils lisent les bulles de Filou, s'ils comprennent le nez qui grandit.
- Signes que ça marche : ils rient quand Filou ment, ils crient « il ment ! », ils veulent un costume précis, ils demandent à rejouer demain.
- Signes à corriger : ils ne lisent pas la bulle (raccourcir encore), ils tapent partout au lieu de glisser (tutoriel plus visible), ils abandonnent un niveau (le déplacer ou l'adoucir).
- Questions à trancher :
  - Le niveau 15 (*Le balcon*) est-il trop dur, même placé tard ? C'est le casse-tête le plus difficile.
  - La révélation du niveau 19 marche-t-elle ? Le joueur pense-t-il de lui-même au niveau 1 ?
  - Comprennent-ils seuls que le sac en haut de l'écran se glisse dans le niveau (niveau 9) ?
  - Le noir (16–18) est-il frustrant ou intrigant ?
- Mesure simple : temps par niveau, nombre de chutes, utilisation de l'ampoule. **Pas d'analytics tiers** dans un jeu pour enfants sans vérifier qu'ils respectent les règles enfants des stores (voir 6) : le plus simple est de ne rien collecter.

## 2. Rendre la révélation partageable

C'est le moteur viral du jeu : « ce mur était traversable depuis le niveau 1 ».

- **Bouton « Partager »** après le niveau 19 et à chaque secret : une image générée (la grille, le mur fissuré, le texte « J'ai trouvé le mur »). Sur Android/iOS, il faut un petit plugin de partage natif.
- **Vidéos courtes** (TikTok, Reels, Shorts) : filmer des réactions de joueurs au niveau 19 et à la porte peinte du niveau 2. Ne jamais montrer la solution, seulement la surprise.
- Un **mot-clé** reconnaissable : *« Ne crois rien. »*

## 3. Accessibilité (rapide et important)

- **Daltonisme** : rouge et bleu ne sont distingués que par la couleur. Ajoute un symbole dans un coin de l'écran (⇄ pour inversé, ↻ pour quart de tour), et sur les taches de peinture.
- **Réduire les animations** : un réglage qui coupe tremblements et particules (certains joueurs sont sensibles).
- **Taille du texte** du narrateur : réglable.
- **Annuler le dernier coup** : moins frustrant que tout recommencer. Attention, ça change la difficulté des escaliers ; à tester avant de l'activer partout.

## 4. Langues

Le marché francophone est petit. **L'anglais d'abord**, puis espagnol et portugais (Brésil, gros marché mobile).
Le texte est déjà regroupé (JSON + quelques constantes) : passe par le système de traduction de Godot (CSV + `tr()`). Le titre est déjà en anglais, c'est un atout.

## 5. Modèle économique

Pour un jeu d'enfants, **pas de publicité** : les stores l'encadrent très strictement pour les moins de 13 ans, et les parents fuient les jeux à pub. Le modèle **premium** marche bien (Monument Valley, Toca Boca).

| Option | Pour | Contre |
|---|---|---|
| **Gratuit + déblocage unique** (actes I à III gratuits, reste ~2,99 €) | Essai sans risque, le meilleur compromis | Achat intégré à intégrer |
| Payant d'emblée (1,99–3,99 €) | Le plus simple | Peu de téléchargements sans visibilité |
| Gratuit avec pubs | Volume | Abîme l'expérience, mauvaises notes |

Recommandé : **gratuit + déblocage unique**, acheté par un parent, derrière un **contrôle parental** (une question qu'un enfant ne sait pas résoudre, obligatoire sur iOS dans la catégorie Enfants). Jamais d'achats répétés ni de « gemmes ».

## 6. Publication

- **Android** : compte Google Play Console (25 $ une fois), clé de release, `.aab` en arm64 seulement (plus léger), API cible 35. Commence par un **test fermé** : Google exige 12 testeurs pendant 14 jours pour les nouveaux comptes personnels.
- **iOS** : compte Apple Developer (99 $/an), un Mac (ou un Mac de location dans le cloud, ou un service de build) pour Xcode.
- **Fiche store** : 5 captures en portrait (Pico et Filou au menu, une porte dessinée, l'écran rouge, les costumes, les confettis), une courte vidéo, et une phrase d'accroche : *« Filou ment. Son nez aussi ? »*
- **Mots-clés** : puzzle, énigme, illusion, casse-tête, logique, minimaliste, escape.
- **Âge et règles enfants** : sur Google Play, déclarer la cible « enfants » fait entrer l'app dans le programme **Familles** (règles sur les données, les pubs, les liens externes). Sur l'App Store, la **catégorie Enfants** (9-11 ans) impose : pas de pub ni d'analytics tiers, contrôle parental devant les achats et les liens. Le jeu actuel ne collecte rien et n'a aucun lien : il est déjà dans les clous.
- **Fiche store pour les parents** : « sans pub, sans données collectées, apprend à repérer les mensonges », avec des captures de Pico et Filou.

## 7. Contenu : où aller ensuite

Le format JSON et le solveur permettent d'ajouter des niveaux vite. Idées de mécaniques qui gardent le thème :

- **Le reflet** : un double qui bouge en miroir. Lequel est toi ?
- **Le menu est un niveau** : le menu pause se met à avoir des murs.
- **Le faux bouton** : « Rejouer » qui ne recommence pas, ou recommence un autre niveau.
- **La porte qui fuit** : la porte s'éloigne quand tu la regardes (l'inverse des escaliers).
- **Le niveau quotidien** : un niveau généré chaque jour, et le solveur garantit qu'il est faisable.
- **Éditeur de niveaux** pour la communauté : le format est déjà assez simple pour ça, il suffit d'un écran pour dessiner la grille.

## 8. Technique

- Le solveur tient bien aujourd'hui (moins d'une seconde par niveau). Si un futur niveau a beaucoup d'escaliers et de pièces, surveille le temps de l'ampoule ; un **A\*** remplacerait facilement le BFS.
- **Sauvegarde cloud** (Google Play Games / Game Center) : utile une fois le jeu publié.
- Garde la règle : **tout niveau ajouté passe les tests** (`run_tests` + `smoke_test`) avant d'être publié.
