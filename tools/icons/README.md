# La police d'icônes du jeu

`game/assets/fonts/ProductIcons.ttf` dessine tous les pictogrammes de
l'interface. C'est un binaire : sans ce dossier, personne ne peut savoir quel
tracé dessine quel caractère, ni ajouter un pictogramme sans repartir de zéro.

La source de vérité est donc ici, et l'asset s'en déduit :

| Fichier | Rôle |
|---|---|
| `manifest.json` | **La source.** Un caractère affiché → le tracé qui le dessine. |
| `lucide/*.svg` | Les tracés [Lucide](https://lucide.dev/) 0.469.0, licence ISC, figés dans le dépôt. |
| `extra/*.svg` | Deux tracés écrits pour le jeu (`○` et `●`), sur la même grille 24×24 que Lucide. |
| `build_product_icons.py` | Le générateur. |

## Régénérer

```sh
pip install fonttools picosvg
python3 tools/icons/build_product_icons.py           # écrit la police
python3 tools/icons/build_product_icons.py --check   # vérifie sans écrire
python3 tools/icons/build_product_icons.py --fetch   # récupère un SVG Lucide absent
```

La sortie est déterministe : régénérer sans avoir rien changé laisse
`git status` propre. C'est ce qui rend `--check` utile — il dit si l'asset
versionné correspond encore à son manifeste.

## Ajouter un pictogramme

1. Choisir un nom d'icône sur [lucide.dev](https://lucide.dev/icons/) ;
2. ajouter une ligne à `manifest.json` (`codepoint`, `char`, `source`, `icon`) ;
3. `python3 tools/icons/build_product_icons.py --fetch` ;
4. `godot --headless --path game --import` pour que Godot réimporte la police ;
5. relancer le smoke UI.

Sauter l'étape 3 ou 4 se voit : le smoke UI compare la police à son manifeste
et échoue si un caractère déclaré n'est pas dessiné.

## Pourquoi une police et pas des `TextureRect`

Les pictogrammes vivent **dans les chaînes** (`"💥 %d"`, `data/*.json →
icon`), et souvent au milieu d'une phrase. Les remplacer par des nœuds image
demanderait de découper chaque libellé du jeu. Une police les laisse là où ils
sont : ils héritent de la taille et de la couleur du texte, et les données ne
changent pas.

## Les deux garde-fous

Rien ici ne dépend du sérieux d'un relecteur :

- `build_product_icons.py --check` refuse un asset qui ne correspond plus au
  manifeste ;
- `smoke_test_ui.gd → _test_embedded_icon_coverage()` parcourt **les chaînes**
  de `game/` et `data/` et échoue si un caractère n'est dessiné par aucune des
  six polices embarquées. Il ne connaît aucune liste de pictogrammes : c'est ce
  qui lui permet d'attraper un signe que personne n'avait anticipé.
