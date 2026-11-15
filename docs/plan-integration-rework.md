# Plan d’intégration du rework

15 novembre 2026. **Ordre de travail recommandé ; aucun lot de code lancé ici.**
Lire le [contrat](contrat-rework-bureau.md) avant de choisir un lot. Les états
`Jxx` sont des références visuelles et de parcours, pas une liste de scènes à
coder une par une.

## 1. Première demande de développement : R0

**Expérience visée :** retrouver dans Godot la présence et la lisibilité des
cartes, de l’Impact et des objets validés dans le `.pen`.

Périmètre concret :

- Intégrer les quatre atlas marqués `candidat_runtime` du
  [manifeste d’assets](maquettes/product-tycoon-jeu/assets-manifest.json), leurs
  régions et les polices de la cible. Le décor reste une référence artistique.
  Documenter leur provenance
  dans les notices du jeu lors de cette intégration.
- Construire un thème et des composants partagés : carte illustrée, emblème,
  compteur Impact/quota, caisse, calendrier, commande, contexte et fermeture.
- Garder nombres, coûts, états et sélection indépendants des illustrations.
- Raccorder une lecture aux données / résolveurs existants, avec une fixture
  distincte pour les cas de revue. Aucun coût de maquette en dur dans l’UI.
- Identifier le sens et la fréquence des valeurs affichées : un revenu
  récurrent n’est pas un solde de caisse, et un sprint n’est pas une journée.
- Prévoir sélection, survol, appui, indisponibilité, manque de ressources et
  animations réduites. Réutiliser ces états dans les lots suivants.

Références : **J01, J02, J14, J16, J21, J32, J43** et planche des emblèmes.

Sortie attendue : captures Godot du HUD, d’une carte choisie et indisponible,
d’un prix résolu et d’un gain lisible ; comparaison avec les maquettes et
vérification des composants / de leur raccord aux valeurs existantes.
Le socle prépare le rework : il ne doit pas prétendre qu’un sprint existant
est déjà devenu une journée ou qu’un fond fixe simule un bureau.

## 2. Lots suivants

**État de reprise :** R0 prêt à démarrer ; R1 à R5 non commencés. À la clôture
d’un lot, remplacer cette ligne par l’avancement réel, les preuves de recette
et le prochain lot. `AGENTS.md` demande de relire cet avancement à la reprise.
Les maquettes ne comptent pas
comme des lots runtime livrés.

| Lot | Expérience du joueur | Références | Dépendances et décisions | Critère de sortie |
|---|---|---|---|---|
| **R0 — Socle visuel et interactions** | Reconnaître les ressources, lire une carte et sentir la sélection | J01, J02, J14–J16, J21, J32, J43 | Direction graphique déjà retenue ; pas d’arbitrage d’équilibrage nécessaire | Composants partagés, données réelles en lecture, états nominal / indisponible lisibles |
| **R1 — Première boucle du bureau** | Choisir et ordonner, confier, observer, comprendre une sortie et préparer la suite | J01–J06, J19–J23, J41, J44 | R0 ; A01, A02, A03, A06 et périmètre A08 pour un petit cas ; cadrage du rendu et sauvegardes | Une boucle complète avec état persistant, personne et ticket visibles ; aucune livraison inventée par l’animation |
| **R2 — Organisation et couches de travail** | Comprendre une attente et modifier un fonctionnement pour la réduire | J07–J10, J18, J36 | R1 ; A03 / A04 ; règles d’effort, dépendances et effets futurs | Cas A, B, D et E de la spec ; découpage automatique et parents conservés |
| **R3 — Investissements et équipe** | Acheter, placer, recruter et adapter le travail aux personnes | J03, J11–J17, J23, J32, J37–J38, J40, J42 | R2 ; A04 / A05 / A06 pour les coûts, disponibilités et moments d’effet | Achat débité une fois, coût monétaire visible, absence sans perte silencieuse de progression ; cas C et F |
| **R4 — Produit, économie et progression** | Voir les capacités utiles, leurs combos et la conséquence d’un trimestre | J21–J28, J34–J35, J39, J43 | R1–R3 ; A02 / A06 / A07 ; raccord au score et aux clients | Aucun double paiement, deux économies distinctes, réussite / échec explicables ; tests de score et relecture économique |
| **R5 — Parcours complet et finition** | Commencer, reprendre et terminer un mandat avec la même qualité | J29–J31, J33 et toutes les transitions restantes | R0–R4 ; décisions encore ouvertes des parcours concernés | Run visuel complet, reprise, réglages, raccourcis, mouvements et états difficiles cohérents |

R1 livre un petit parcours complet avant d’étendre la simulation et le catalogue.
Le bureau s’appuie sur les assets 3D réutilisables et le code existant lorsque
cela convient ; le décor illustré du `.pen` sert de référence artistique.

Une amélioration isolée peut rejoindre un lot ultérieur sans attendre tout le
plan si ses dépendances sont satisfaites. Ne pas remplacer ces lots par une
suite de 44 reskins déconnectés du parcours et de l’état du jeu.

## 3. Points de raccord à inspecter au démarrage

| Zone existante | Rôle dans la migration |
|---|---|
| `game/scripts/ui_helpers.gd`, thème et composants | Introduire le socle partagé et migrer les écrans touchés |
| `desk_screen.gd`, `desk_room.gd`, contrôleurs du bureau | Cadrer vue du dessus, sélection et déplacements sans supprimer aveuglément les acquis 3D |
| `SprintState`, `GameData` | Conserver une source d’état ; définir l’adaptation sujets / lots / tickets et le calendrier avant de la coder |
| `SprintState.resolved_price()` / `get_current_quota()` | Fournir prix et quotas résolus à l’affichage ; pas de lecture brute ou de second calcul dans la carte |
| `ScoreResolver`, `EffectResolver` et leurs rapports | Donner les résultats aux présentations ; compter / rejouer n’attribue pas une deuxième fois |
| Sauvegardes (`RunSave` existe sur la branche mobile, pas sur le `main` de départ) | Inventorier la branche cible, puis définir version, reprise et compatibilité ; ne pas importer le chantier mobile implicitement |

Ces points sont des repères d’inspection, pas une obligation de conserver chaque
classe ou de renommer tout le moteur dès R0.

## 4. Recette d’un lot

Chaque lot annonce le problème joueur, ses vues cibles et les règles qu’il
remplace éventuellement. Il fournit ensuite :

- Un parcours vérifié avec données cohérentes, incluant un cas nominal et un
  cas d’alerte / indisponibilité pertinent.
- Des captures du **jeu rendu**, comparées aux maquettes. Pas de PNG complet
  posé en guise d’écran ; les nombres et interactions restent réels.
- Une vérification du focus, de la fermeture, de la sélection et du traitement
  des animations. Une seule action ne doit pas déclencher deux achats ou gains.
- Les tests adaptés et la recette de `CLAUDE.md` pour les changements de code.
  Le runtime garde ses garanties pendant la migration.
- Une mise à jour du carnet pour les comportements réellement implémentés,
  ainsi que du contrat / de la spec si une décision a été tranchée.

Un changement de règles de score, d’économie ou de progression déclenche la
relecture critique prévue par les consignes du projet. Un lot purement
documentaire n’exige pas de relancer des tests de simulation sans rapport.

## 5. Intégration Git à garder séparée

La première PR doit apporter **le contrat, les consignes, les maquettes, les
assets et les références de revue**, sans changement de logique Godot.
Les lots R0 à R5 arrivent ensuite en PRs de développement vérifiables.

La branche de travail observée est `codex/mobile-quality` : elle contient déjà
deux commits au-dessus de `origin/main` (`412110e`, `539590c`). Cette situation
est un constat local, à revérifier avant publication. Ne pas fusionner ces
changements de code par inadvertance pour publier seulement la cible de design.

Préparer la PR de conception depuis le `main` à jour, en y appliquant la liste
de fichiers du [périmètre de merge](rework-merge-files.txt). Garder les nouveaux
liens documentaires lors d’une éventuelle résolution de conflit. Les prototypes
HTML, le premier pack web et les doubles exports ne font pas partie de cette PR.

Les images JPEG de revue sont versionnables. Les PNG natifs, ZIP et anciens
exports sont conservés localement comme sorties régénérables. Le `.pen` et les
assets actifs restent les sources de référence.
