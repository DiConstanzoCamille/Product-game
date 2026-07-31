# Product Tycoon — instructions de travail

Roguelike de gestion produit sous **Godot 4.7 (GDScript)**. Ce dépôt contient
les documents de conception (`docs/`), les données de jeu (`data/`), le jeu
(`game/`) et une landing page de présentation (`landing/`).

---

## Où est la vérité

Trois documents, trois rôles — en cas de contradiction, cet ordre tranche :

| Document | Ce qu'il décrit |
|---|---|
| [`docs/carnet-de-regles.md`](docs/carnet-de-regles.md) | **L'état actuel** du jeu. Référence en cas de désaccord sur ce qui existe. |
| [`docs/spec-scoring-sprint.md`](docs/spec-scoring-sprint.md) | **La cible de gameplay validée** (31/07/2026) : Traction × Levier = Impact. C'est la direction du produit. |
| [`docs/spec-profondeur-gameplay.md`](docs/spec-profondeur-gameplay.md) | Les phases A→D. **Sa phase D est remplacée** par la spec de scoring. Sa phase C (roadmap profonde) reste valide et devient le prérequis du chantier scoring. |

`docs/data-schema.md` décrit le schéma de chaque JSON de `data/`.

---

## La direction de gameplay (résumé)

Le jeu passe de « survivre 12 sprints » à **un moteur de score à combos**.
Le détail est dans [`docs/spec-scoring-sprint.md`](docs/spec-scoring-sprint.md) ;
ce qui suit est le minimum à avoir en tête avant de toucher au gameplay.

- **`📊 Traction × ⚙️ Levier = 💥 Impact`** — *ce que j'ai produit* ×
  *l'organisation que j'ai construite*. La Traction vient des features
  livrées, le Levier de l'équipe, des outils, de la stratégie et du produit.
- **L'Impact est la monnaie** : `Budget = floor(√Impact)`. Bien jouer un
  sprint paie immédiatement en pouvoir d'achat.
- **Le MRR est un stock cumulatif**, pas un flux recalculé — c'est la
  composition qui crée l'envie de continuer.
- **Quota trimestriel tous les 3 sprints**, escaladé ×2, **manqué = fin de
  run**. La difficulté se durcit franchement après T4.
- **Trois familles de décisions** (§7 de la spec) : outils internes (Levier
  *par employé éligible*, bornés par des **slots**), décisions stratégiques
  (1 par trimestre, irréversibles), stack technique. Tout s'achète au
  **Comité de fin de trimestre**.
- **Le modèle doit tenir de 1 squad à 10+** :
  `Impact = Σ(Traction_squad × Levier_local) × Levier_global`. Voir le
  contrat d'architecture ci-dessous — **il est non négociable**.

### Contrat d'architecture — à honorer dès le premier lot de code

Même tant qu'on n'implémente que N=1 squad :

1. `SprintState.squads: Array` — un **tableau**, avec une seule entrée
   aujourd'hui. Le roster global est une vue calculée sur l'union des squads.
2. `ScoreResolver` **itère toujours sur les squads** et produit un sous-total
   par squad, même quand il n'y en a qu'une.
3. Le rapport de score distingue explicitement **local** et **global**.
4. À N=1, **l'UI masque entièrement la couche squad** — le mot « squad » ne
   doit jamais apparaître dans un premier run.
5. Quotas et coûts vivent dans des tables **indexées par niveau de carrière**,
   avec une seule ligne remplie aujourd'hui.

Coût aujourd'hui : quasi nul. Coût si on l'ignore : réécriture du moteur de
score et de tous les écrans de phase.

---

## Conventions de code

- **Aucune valeur d'équilibrage en dur.** Tout vit dans `data/balance.json`
  (ou les autres JSON de `data/`). Rééquilibrer ne doit demander aucune
  modification de script.
- **Séparation données de jeu / données de démo.** `landing/` et `game/`
  partagent certains JSON, mais les pools de démo de la landing sont des
  fichiers distincts (pattern `recruitment-demo.json` vs `candidates.json`,
  `roadmap-features.json` vs `backlog.json`). Ne jamais faire consommer un
  fichier de démo par le jeu, ni l'inverse.
- **La logique de jeu ne vit pas dans l'UI.** Les écrans lisent un état ou
  rejouent un rapport ; ils ne calculent pas de règles. C'est ce qui rend le
  jeu testable en headless.
- **Un seul calcul, deux usages.** Quand une règle est affichée *et*
  appliquée (les objectifs de board, l'impact d'une carte), une seule
  fonction sert les deux — voir `SprintState.evaluate_board_objectives()` et
  `EffectResolver.card_impact_lines()`.
- Commits **en français, à l'impératif** (« Ajoute… », « Corrige… »).

## Pièges Godot connus

- Les conteneurs (`HBoxContainer`, `GridContainer`…) **écrasent `rotation` et
  `scale`** de leurs enfants à chaque tri. Pour animer une carte, passer par
  un nœud intermédiaire hors conteneur ou utiliser `pivot_offset` avec
  précaution.
- `mouse_exited` se déclenche quand le curseur entre sur un **enfant** du
  nœud survolé. Vérifier la position réelle avant de replier une carte.

## Recette — obligatoire à la fin de chaque lot

1. Les **deux smoke tests headless** passent (`game/tests/smoke_test_logic.gd`
   et `smoke_test_ui.gd`).
2. Un **run visuel complet** de tous les écrans.
3. Le **carnet de règles est mis à jour** avec les décisions prises (les
   §14-19 documentent l'historique des arbitrages — continuer la série).

Critères de recette permanents, à ne jamais casser :

- La stratégie `careful` (ne rien livrer, ne rien acheter, ne rien recruter)
  **doit perdre** avant la fin du mandat.
- La spirale de burn-out reste atteignable (la stratégie `stress` la
  déclenche).

---

## Travailler avec Camille

- **Échanges en français.**
- **Forte autonomie sur la technique** : enchaîner les lots sans multiplier
  les questions d'arbitrage technique.
- **Le game design se relit avant d'être implémenté** : écrire une spec dans
  `docs/`, la résumer avec les points discutables, attendre le retour.
- Exigences de fond répétées : le jeu doit être **difficile** (« il ne doit
  pas être simple de faire une entreprise qui fonctionne »), **fun**
  (surprises, paris, informations cachées), **RP** (les réglages libres
  doivent devenir des traits du contexte de run), et **aléatoire** — c'est un
  roguelike, ce n'est pas négociable.
