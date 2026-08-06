# Le bureau en volume — direction 3D

> Spec de direction (05/08/2026), validée avec Camille. Elle décrit **comment le
> bureau du Lot A (#54) passe en volume** sans que le jeu change de nature.
> La mise en œuvre est l'issue #59.
>
> Ce document tranche des questions de *forme*. Il ne touche à aucune règle : le
> gameplay, l'économie et le scoring restent ceux du `carnet-de-regles.md` et de
> `spec-scoring-sprint.md`.

---

## 1. Pourquoi la 3D, et ce qu'elle remplace

La version 2D du bureau simulait la profondeur avec trois ruses : un dégradé sur
le plateau, des ombres portées décalées, une vignette. Chacune approche ce qu'une
`Camera3D` donne **gratuitement**, et aucune ne suffit — un bureau *est* un objet
dans l'espace, et l'œil le sait.

Le spike (`prototype_3d/desk_3d_spike.gd`) a répondu à la seule question qui
comptait, et la réponse est oui : sans le moindre asset, avec des primitives et une
lumière, la tasse projette une ombre, le parapheur a une tranche, le plateau fuit
vers le fond. Ce que la 2D imitait, la caméra le fait.

**Ce que la 3D n'apporte pas** : de la beauté. Le spike est laid. La profondeur est
structurelle, l'habillage reste à faire — ne pas confondre les deux, c'est ce qui
évitera de déclarer le lot fini parce qu'il a de la perspective.

---

## 2. La règle de partage — 3D pour le monde, 2D pour ce qu'on lit

C'est la décision structurante de cette spec, et tout le reste en découle.

| | Quoi | Pourquoi |
|---|---|---|
| **3D** | La pièce, la table, le portable, les objets posés, les papiers du mur | Ils ont un volume, reçoivent la lumière, projettent une ombre |
| **2D** | Les zones de valeurs, les alertes, **tout le contenu des applications**, et toute information au survol | **Une interface qu'on lit ne gagne rien à la perspective — elle y perd** |

> **Critère de recette n°1 :** si le texte d'une phase devient flou ou incliné, le
> partage a été mal appliqué. Ce n'est pas un défaut esthétique, c'est le signe
> qu'on a basculé l'interface dans le monde.

### La dalle du portable est un `SubViewport`

C'est le point technique qui rend le lot tenable. La dalle n'est pas une texture
peinte : c'est un `SubViewport` rendu en direct, texturé sur un quad. Les écrans de
phase existants s'y affichent **sans être réécrits** et héritent de la perspective
de la pièce, pendant que leur contenu reste du `Control` net.

Corollaire : la caméra doit rester **quasi perpendiculaire à la dalle**. Un angle
plus marqué rendrait le texte illisible, et on aurait échangé de la lisibilité
contre de la profondeur — un mauvais échange dans un jeu qui se lit.

---

## 3. Les papiers du mur — 3D, révélés en 2D, levés au clic

Les papiers sont des **objets en volume** : une feuille a une épaisseur, elle se
décolle du mur par son ombre propre et non par une ombre dessinée.

Trois niveaux, et ils reprennent exactement le motif livré par #43
(`get_employee_alert()`) plutôt que d'en inventer un :

| Geste | Ce qu'on voit | Dimension |
|---|---|---|
| **Rien** | Le papier, et l'état synthétique dessus — le visage d'une personne, la congestion d'un board | 3D |
| **Survol** | Une info-bulle : le nom, la ligne qui résume, rien de plus | **2D**, de face, nette |
| **Clic** | Le poster **se lève**, et le détail apparaît dessous | 2D sous un geste 3D |

### La levée du poster

Le trombinoscope se soulève comme un paperboard géant, et **sous chaque tête** on
trouve le détail de la personne : ses quatre critères, ses actions possibles.

Ce que ça vaut, et pourquoi je le préfère à un menu qui s'ouvre :

- **Le geste raconte la mécanique.** Regarder l'équipe de près est un acte, pas une
  navigation. Un menu modal aurait dit « écran de gestion RH » ; la levée dit
  « je vais voir mes gens ».
- **Ça respecte la règle de consultation du Lot A** — *on consulte librement ce
  qu'on possède déjà*. Lever le poster ne coûte ni Énergie ni sprint : c'est de
  l'information qu'on détient.
- **Le détail reste en 2D**, à plat sous le poster levé. On lit des chiffres, pas
  une perspective.

**Le point à surveiller** : pendant que le poster est levé, la vue synthétique est
cachée. Il faut donc que la levée soit **rapide à annuler** (clic ailleurs, Échap),
et qu'aucune décision ne s'y prenne à l'aveugle — le bandeau et les alertes restent
visibles par-dessus, puisqu'ils sont en 2D dans un `CanvasLayer`.

---

## 4. L'interaction change de nature

En 2D, tout passait par `gui_input`. En volume, un objet cliquable a besoin d'un
`Area3D` avec sa `CollisionShape3D`, et le clic arrive par `input_event`. Ce n'est
pas une conversion mécanique : **un objet 3D n'a pas de « survol » gratuit**, il
faut `mouse_entered`/`mouse_exited` sur l'`Area3D`.

Conséquence sur les accessoires (`desk_prop.gd`) : la tablette, la planche et le
parapheur deviennent des nœuds 3D animés par `Tween` sur leur `position` et leur
`rotation`, et leur *contenu* reste un `SubViewport`. Un objet qui entre dans le
cadre en tournant légèrement est ce qu'aucune version 2D ne savait faire.

---

## 5. Décision de projet à trancher — le renderer

Le projet est en `gl_compatibility`. Le spike a rendu ses ombres avec, donc **rien
n'oblige à changer**.

| | `gl_compatibility` | `forward_plus` |
|---|---|---|
| Ombres directionnelles | Oui | Oui, meilleures |
| Ambiance, profondeur de champ, SSAO | Non | Oui |
| Cibles d'export | Les plus larges, web compris | Plus étroites |

**Décision (05/08/2026, Camille) : on reste en `gl_compatibility` pour l'issue #59.** Le lot doit
prouver que la profondeur sert le jeu ; changer de renderer en même temps
mélangerait deux variables et rendrait un éventuel échec illisible. Le passage à
`forward_plus` mérite sa propre décision, une fois qu'on saura ce qu'on veut de
l'ambiance.

Conséquence à accepter : pas de SSAO, pas de profondeur de champ, des ombres
correctes mais sans finesse. Si le rendu paraît pauvre à l'arrivée, **c'est le
premier levier à essayer avant de conclure que la 3D ne sert à rien** — et pas
l'inverse.

---

## 6. Pièges Godot rencontrés — tous silencieux

Les trois ont coûté du temps sur le spike, et aucun ne lève d'erreur GDScript.

- **`add_child()` sur un nœud « busy setting up children » est REJETÉ**, pas
  différé. Godot le signale sur `stderr` ; le script continue comme si de rien
  n'était et la scène reste vide. Trois écrans unis d'affilée avant de comprendre.
  → Construire une scène **une fois entré dans l'arbre** (`call_deferred`), jamais
  pendant `_ready()`.
- **`Camera3D.current` et `look_at()` n'ont d'effet qu'une fois le nœud dans
  l'arbre.** Les poser avant `add_child()` donne un écran uni, sans erreur.
- **Une scène claire a besoin de MOINS de lumière qu'une scène sombre.** Première
  passe à `light_energy = 1.15` : intégralement brûlée. 0,62 avec un ambiant à 0,32
  donne la lecture voulue.

À ajouter aux « Pièges Godot connus » du `CLAUDE.md` au moment du merge de #59.

---

## 7. Ce que cette spec ne tranche pas

- **L'habillage.** Matière, palette, mobilier, éclairage d'ambiance : c'est un lot
  d'art à part entière, et il vient après.
- **La caméra mobile.** Elle est fixe dans cette spec. Un léger parallaxe suivant la
  souris est tentant, mais il déplace le texte de la dalle — à évaluer seulement une
  fois la lisibilité acquise.
- **Le devenir du `side_panel`** (830 lignes, neutralisé mais présent) : c'est un
  point de l'issue #59, pas une question de direction.
