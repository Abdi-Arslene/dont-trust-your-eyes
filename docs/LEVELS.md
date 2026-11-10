# Créer un niveau

Tous les niveaux sont dans [levels/levels.json](../levels/levels.json), dans l'ordre de jeu. Pas besoin d'ouvrir l'éditeur Godot.

```json
{
  "id": "key",
  "chapter": "IV. Le sac à malices",
  "title": "Clé",
  "par": 16,
  "secret": true,
  "hints": ["La clé est posée près de la porte jaune.", "Ramasse la clé et la planche, puis avance contre la porte grise."],
  "say": {
    "start": "~Tu n'as pas de clé.",
    "pickup": ["Hé ! C'est ma clé !", "Et ma planche aussi !"],
    "locked": ["Verrouillée.", "Vraiment verrouillée."]
  },
  "rooms": {
    "main": [
      "#########",
      "#@..kd..#",
      "#.##X####",
      "#-._...L#",
      "#########"
    ]
  }
}
```

## Légende des cases

| Case | Sens |
|---|---|
| `#` | mur |
| `.` | sol |
| `_` | vide (on tombe, le niveau recommence) |
| `@` | départ (un seul par niveau, toutes pièces confondues) |
| `D` | porte (sortie) |
| `d` | porte peinte : identique à `D`, mais c'est un mur |
| `c` | porte à la craie : devient `D` quand on la touche |
| `L` | porte verrouillée : avancer contre elle avec la clé l'ouvre (elle devient `D`) |
| `-` | planche posée par terre : on la ramasse en marchant dessus. Avancer vers un trou avec la planche la pose dessus (au lieu de tomber) |
| `k` | clé posée par terre : on la ramasse en marchant dessus |
| `s` | interrupteur : marcher dessus fait basculer tous les blocs de la pièce |
| `y` | bloc jaune : debout (un mur) au départ, couché (du sol) après un nombre impair d'interrupteurs |
| `u` | bloc violet : l'inverse du jaune, couché au départ |
| `f` | sol fissuré : il tient une fois, puis s'effondre (devient `_`) dès qu'on le quitte. Derrière, une impasse devient un piège : seul le trou permet de recommencer |
| `X` | faux mur : identique à `#`, mais traversable (fissuré après la révélation) |
| `x` | mur fissuré : identique à `X` après la révélation, mais solide |
| `^ > v <` | escalier : ne se traverse que dans son sens, tourne quand on ne le regarde pas |
| `r` `b` `w` | peinture rouge (inverse), bleue (quart de tour), blanche (normal) |
| `1`–`9` | cabane : relie les deux pièces qui contiennent ce chiffre |
| `i` | glace : on glisse tout droit jusqu'à ce que quelque chose arrête (mur, caisse, case sans glace) |
| `o` | caisse (posée sur du sol) : on la pousse d'une case ; elle glisse sur la glace ; poussée dans un trou, elle le bouche |
| `p` | bouton : appuyé tant que Pico ou une caisse est dessus |
| `g` | grille : ouverte tant que **tous** les boutons de la pièce sont appuyés. On peut toujours sortir d'une grille, même fermée |

## Champs

| Champ | Rôle |
|---|---|
| `id` | identifiant stable (sert aux sauvegardes : ne pas le changer une fois publié) |
| `chapter` | titre de l'acte ; les niveaux consécutifs du même acte sont groupés |
| `title` | nom affiché |
| `rooms` | une ou plusieurs grilles. Lignes de longueurs libres (hors grille = mur). Largeur conseillée ≤ 9 |
| `items` | facultatif : objets déjà dans le sac au départ (`plank`, `key`). Les niveaux de l'histoire n'en ont pas : les objets sont à ramasser dans le niveau |
| `par` | objectif de coups = solution optimale sans faux mur. **Vérifié par les tests** |
| `secret` | `true` si un faux mur permet de faire moins que le par. **Vérifié par les tests** |
| `hints` | au moins 2 indices, du plus vague au plus précis |
| `say` | répliques du narrateur par événement (texte, ou liste jouée dans l'ordre, la dernière se répète) |
| `dark` | `true` : pièce dans le noir |
| `reveals_walls` | `true` : finir ce niveau révèle les faux murs partout |
| `ending` | `true` : la fin de l'histoire est jouée après ce niveau (les chapitres suivants sont la suite) |

**Événements du narrateur :** `start`, `win`, `bump`, `cracked`, `painted_door`, `locked`, `chalk_open`, `fake_wall`, `arrow_blocked`, `fall`, `tint`, `portal`, `drop`, `slide`, `push`, `crate_fill`, `crate_blocked`, `gate_closed`, `gates_open`, `gates_shut`, `pickup` (objet ramassé), `unlock` (porte ouverte avec la clé), `crumble` (le sol fissuré s'effondre), `stuck` (la porte n'est plus atteignable : Filou se moque), `toggle` (interrupteur), `block` (bloc debout). `drop` : la planche posée sur un trou. Dans une liste, une réplique vide `""` fait taire Filou pour les fois suivantes. Sans réplique définie, Filou dit celles par défaut de [src/game/game.gd](../src/game/game.gd).

**Mensonges :** une réplique qui commence par `~` fait grandir le nez de Filou. Par convention, ce sont ses mensonges… sauf quand on veut tromper le joueur sur la convention (niveaux 18 à 20). Textes courts et simples : le public a 8-9 ans.

## Workflow

1. Dessine la grille, mets `"par": 0`.
2. Lance `godot --headless -s tests/run_tests.gd` : le test échoue en donnant le vrai par, la solution optimale, et s'il existe un secret.
3. Recopie le par (et `"secret": true` si besoin). Si la solution affichée est trop courte ou contourne la mécanique visée, retouche la grille.
