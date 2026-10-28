# Créer un niveau

Tous les niveaux sont dans [levels/levels.json](../levels/levels.json), dans l'ordre de jeu. Pas besoin d'ouvrir l'éditeur Godot.

```json
{
  "id": "key",
  "chapter": "IV. L'interface",
  "title": "Clé",
  "items": ["plank", "key"],
  "par": 10,
  "secret": true,
  "hints": ["Regarde ce que tu as en haut de l'écran.", "La planche va dans le trou, la clé sur la porte grise."],
  "say": {
    "start": "~Tu n'as pas de clé.",
    "locked": ["Verrouillée.", "Vraiment verrouillée."]
  },
  "rooms": {
    "main": [
      "#########",
      "#@...d..#",
      "#.##X####",
      "#.._...L#",
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
| `L` | porte verrouillée : devient `D` si on y glisse une clé |
| `X` | faux mur : identique à `#`, mais traversable (fissuré après la révélation) |
| `x` | mur fissuré : identique à `X` après la révélation, mais solide |
| `^ > v <` | escalier : ne se traverse que dans son sens, tourne quand on ne le regarde pas |
| `r` `b` `w` | peinture rouge (inverse), bleue (quart de tour), blanche (normal) |
| `1`–`9` | cabane : relie les deux pièces qui contiennent ce chiffre |

## Champs

| Champ | Rôle |
|---|---|
| `id` | identifiant stable (sert aux sauvegardes : ne pas le changer une fois publié) |
| `chapter` | titre de l'acte ; les niveaux consécutifs du même acte sont groupés |
| `title` | nom affiché |
| `rooms` | une ou plusieurs grilles. Lignes de longueurs libres (hors grille = mur). Largeur conseillée ≤ 9 |
| `items` | objets de la barre du haut : `plank` (sur `_`), `key` (sur `L`) |
| `par` | objectif de coups = solution optimale sans faux mur. **Vérifié par les tests** |
| `secret` | `true` si un faux mur permet de faire moins que le par. **Vérifié par les tests** |
| `hints` | au moins 2 indices, du plus vague au plus précis |
| `say` | répliques du narrateur par événement (texte, ou liste jouée dans l'ordre, la dernière se répète) |
| `dark` | `true` : pièce dans le noir |
| `reveals_walls` | `true` : finir ce niveau révèle les faux murs partout |

**Événements du narrateur :** `start`, `win`, `bump`, `cracked`, `painted_door`, `locked`, `chalk_open`, `fake_wall`, `arrow_blocked`, `fall`, `tint`, `portal`, `drop`. Sans réplique définie, Filou dit celles par défaut de [src/game/game.gd](../src/game/game.gd).

**Mensonges :** une réplique qui commence par `~` fait grandir le nez de Filou. Par convention, ce sont ses mensonges… sauf quand on veut tromper le joueur sur la convention (niveaux 18 à 20). Textes courts et simples : le public a 8-9 ans.

## Workflow

1. Dessine la grille, mets `"par": 0`.
2. Lance `godot --headless -s tests/run_tests.gd` : le test échoue en donnant le vrai par, la solution optimale, et s'il existe un secret.
3. Recopie le par (et `"secret": true` si besoin). Si la solution affichée est trop courte ou contourne la mécanique visée, retouche la grille.
