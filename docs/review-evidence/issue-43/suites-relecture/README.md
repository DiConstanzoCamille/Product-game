# Preuves visuelles — suites de la relecture de #52

Captures régénérées **après** les trois corrections de relecture et le merge de
`main`, à 1600×900, par le même harnais que les preuves de l'issue #43.

```sh
SHOT_DIR="$(pwd)/docs/review-evidence/issue-43/suites-relecture/nominal" \
  xvfb-run -a godot --path game --display-driver x11 --resolution 1600x900 \
  res://tests/screenshot_screens.tscn
TEAM_ALERT_CAPTURE=1 \
  SHOT_DIR="$(pwd)/docs/review-evidence/issue-43/suites-relecture/alerte" \
  xvfb-run -a godot --path game --display-driver x11 --resolution 1600x900 \
  res://tests/screenshot_screens.tscn
```

Ce que chaque image vérifie :

| Image | Ce qu'elle prouve |
|---|---|
| `nominal/team_management_screen.png` | Le hub sans alerte : « 0 alerte · 0 demande prévue », quatre diagnostics au vert ou à l'ambre, actions à leur prix. Les corrections n'ont rien déplacé à l'écran. |
| `alerte/team_management_screen.png` | Hervé à 12 de Confiance et 20 de satisfaction salariale : « 1 alerte · 2 demandes prévues », le motif « cherche ailleurs » sur la liste compacte, et les deux critères en rouge avec leur cause. |
| `alerte/inbox_screen.png` | Une alerte devient une conversation à trois arbitrages avant la rupture, et non une jauge qui bouge toute seule. |
| `nominal/resolution_screen.png` et `alerte/resolution_screen.png` | Le bandeau des jauges après le passage du Moral par `get_resource_value()` : la valeur affichée et son delta restent lisibles, sans troncature. |

**Ce que ces captures ne couvrent pas**, et il faut le dire : le harnais
instancie chaque écran isolément, donc la scène de **crise** (un critère à
zéro, réparation ou départ) — celle que la correction P1 modifie le plus — n'y
apparaît pas. Elle est couverte mécaniquement par le smoke logique, qui vérifie
que réparer augmente réellement le salaire et retire réellement la capacité, et
par le test de mutation qui fait tomber cette assertion quand on retire les
`restoreActions`.
