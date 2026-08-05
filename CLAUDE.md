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

Deux specs descendaient d'un cran là où une grandeur abstraite ne raconte rien.
[`spec-clients-revenue.md`](docs/spec-clients-revenue.md) (le Revenue cache des
clients qui paient) est **implémentée** — issue #42, carnet §32.
La couche multiplicative du Levier de
[`spec-impact-monnaie.md`](docs/spec-impact-monnaie.md) §5 est également
**implémentée** — issue #37, carnet §33 :
`Levier final = (base + Σ additifs) × Π multiplicateurs`.
[`spec-equipe-individuelle.md`](docs/spec-equipe-individuelle.md) (le Moral
cache des personnes avec un caractère) est **implémentée** — issue #43,
carnet §36.

Un principe en sort, à ne jamais remélanger : **trois entités perçoivent
quelque chose**, et chacune a sa grandeur. Les *utilisateurs* jugent le produit
(📈 Réputation produit) ; le *board* juge le joueur (🎯 Capital politique) ;
l'*équipe* juge le joueur (🤝 Confiance). C'est un mot employé pour deux choses
qui avait laissé s'installer la fuite `Impact → Valeur perçue → Revenue` ; la
grandeur produit s'appelle désormais `reputation-produit` dans les données, et
plus aucune règle ne l'alimente depuis l'Impact.

`docs/data-schema.md` décrit le schéma de chaque JSON de `data/`.

---

## La direction de gameplay (résumé)

Le jeu passe de « survivre 12 sprints » à **un moteur de score à combos**.
Le détail est dans [`docs/spec-scoring-sprint.md`](docs/spec-scoring-sprint.md) ;
ce qui suit est le minimum à avoir en tête avant de toucher au gameplay.

- **`📊 Traction × ⚙️ Levier = 💥 Impact`** — *ce que j'ai produit* ×
  *l'organisation que j'ai construite*. La Traction vient des features
  livrées, le Levier de l'équipe, des outils, de la stratégie et du produit.
- **L'Impact est la monnaie**, et la seule : un achat le débite, un sprint
  bien joué le remplit. Il ne se remet jamais à zéro, et c'est son **solde**
  que le board compare au quota.
- **💰 Le Revenue est l'autre économie**, et elle vit indépendamment — voir
  le principe ci-dessous, c'est le point de game design le plus facile à
  casser sans s'en apercevoir.
- **Le revenu récurrent est un stock cumulatif**, pas un flux recalculé —
  c'est la composition qui crée l'envie de continuer.
- **Quota trimestriel tous les 3 sprints**, escaladé ×2, **manqué = fin de
  run**. La difficulté se durcit franchement après T4.
- **Trois familles de décisions** (§7 de la spec) : outils internes (Levier
  *par employé éligible*, bornés par des **slots**), décisions stratégiques
  (1 par trimestre, irréversibles), stack technique. Tout s'achète au
  **Comité de fin de trimestre**.
- **Le modèle doit tenir de 1 squad à 10+** :
  `Impact = Σ(Traction_squad × Levier_local) × Levier_global`. Voir le
  contrat d'architecture ci-dessous — **il est non négociable**.

### L'économie de l'entreprise n'est pas l'économie de l'Impact

Deux économies, deux moteurs, **aucune conversion automatique de l'une vers
l'autre**. Le détail est dans
[`docs/spec-impact-monnaie.md`](docs/spec-impact-monnaie.md) §3.8, sa mise en
œuvre est l'issue #42 ; le minimum à avoir en tête :

| | 💥 L'Impact | 💰 Le Revenue |
|---|---|---|
| D'où ça vient | `Traction × Levier` | **Une population de clients qui paie chaque sprint** — elle grandit par les livraisons, les primes, les événements et le Sales, elle s'érode au churn |
| À quoi ça sert | **Acheter** | **Payer** — salaires, licences, et le support des clients eux-mêmes |
| Ce qui la juge | Le quota | La faillite |

**Produire de l'Impact ne remplit pas la caisse.** Le lien entre les deux
existe, mais il va dans un seul sens et passe par l'organisation : une bonne
économie *permet* l'Impact (elle paie l'équipe et les outils qui font le
Levier), elle ne le produit pas. Et ce n'est pas le seul chemin — on doit
pouvoir faire un gros Impact avec une économie seulement correcte, en jouant
le Moral, le Levier ou un combo. Symétriquement, un choix économique se paie
ailleurs : la feature qui finance les salaires coûte du Moral ou de la Dette.

**Le piège**, et il a été introduit une fois puis démonté (#42) : toute règle du type
« l'Impact du sprint alimente le revenu » — à n'importe quel taux — fusionne
les deux monnaies en une seule grandeur à deux noms et supprime l'arbitrage
*nourrir la boîte ou nourrir la performance*. Ce n'est pas un problème de
calibrage : c'est le mauvais sens de dépendance.

Quatre garde-fous le vérifient mécaniquement, et aucun ne dépend du sérieux
d'un relecteur : `score_resolver_cases.gd → _test_no_revenue_comes_from_impact`
fait varier l'Impact du simple au quadruple à livraison identique et exige que
la caisse ne bouge pas ; le rapport `Revenue final / charges par sprint` ne
décolle pas au banc (3,0× sur `greedy`, mesuré sur 40 runs) ; les trajectoires
`economie` et `levier` du banc franchissent toutes deux le mandat ; **mourir
riche** (faillite avec un gros portefeuille, ou quota manqué avec une caisse
pleine) reste atteignable des deux côtés.

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

- **Les features n'ont qu'UN effet client.** `backlog.json → clients`, de −6 à
  +6. Ce n'est pas un nombre de clients : c'est un effet, converti en clients
  réels par le modèle économique du run (`businessModels.segments.clientsPerPoint`),
  pour que le même backlog se joue en freemium comme en grands comptes. **La
  Traction ne lit pas cette colonne** — sinon « ce qui score » et « ce qui
  paie » redeviennent la même chose et l'arbitrage disparaît (carnet §32.4).
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
- **Aucune valeur dérivée ne se lit brute depuis le JSON.** Un prix, un coût,
  un quota passent par une **fonction de résolution** (`resolved_price()`,
  `get_current_quota()`…) — jamais `investments.json → cost` lu directement
  par un écran. Cette fonction est le seul endroit où s'appliquent les
  modificateurs : remise, indexation sur le trimestre, effet de carte, palier
  de carrière. Un écran qui lit la valeur brute court-circuite silencieusement
  tous les modificateurs, **y compris ceux qui n'existent pas encore** — et le
  jour où on en ajoute un, il faut rouvrir tous les écrans. Le coût
  aujourd'hui est d'une ligne ; le coût plus tard est un lot entier.
- Commits **en français, à l'impératif** (« Ajoute… », « Corrige… »).
- **Checkpoints WIP automatiques.** Un hook `Stop` (`.claude/hooks/wip-checkpoint.sh`)
  commit et push le travail en cours à chaque fin de tour, sur la branche de
  feature courante uniquement (jamais `main`/`master`) — pour ne rien perdre
  en cas de coupure de crédits ou de session. Ces commits sont préfixés `WIP
  checkpoint:` et n'ont pas vocation à survivre : les squasher (ou les
  réécrire en commits impératifs propres) avant merge, jamais les laisser
  tels quels dans l'historique de `main`. Le dépôt étant public, ce hook a
  deux garde-fous : il n'ajoute jamais de fichier à nom sensible (`.env`,
  clés privées…) et scanne le diff stagé pour des motifs de secret avant de
  committer (annule le checkpoint plutôt que de committer, si trouvé) ; il ne
  pousse jamais sur une branche déjà supprimée côté remote (typiquement après
  un merge) pour éviter de la ressusciter, et gère une divergence de push par
  un merge propre, jamais par un push forcé.

## Pièges Godot connus

- Les conteneurs (`HBoxContainer`, `GridContainer`…) **écrasent `rotation` et
  `scale`** de leurs enfants à chaque tri. Pour animer une carte, passer par
  un nœud intermédiaire hors conteneur ou utiliser `pivot_offset` avec
  précaution.
- `mouse_exited` se déclenche quand le curseur entre sur un **enfant** du
  nœud survolé. Vérifier la position réelle avant de replier une carte.
- **Ne jamais libérer un nœud par `free()` direct pendant l'émission de son
  signal** — passer par `UIHelpers.clear_children()` (`remove_child` puis
  `queue_free`). Sinon Godot log « Object was freed or unreferenced while a
  signal is being emitted from it », sur **stderr** et sans lever d'erreur
  GDScript : le test passe et le bug reste (carnet §21).
- **Les `.uid` ne sont pas générés en `--headless`.** Tout nouveau `.gd` ou
  `.tscn` doit avoir son `.uid` versionné, mais un run headless ne le crée
  pas : il faut un `godot --headless --path game --import` explicite, puis
  vérifier que `git status` ne laisse rien en `??`. Oublié quatre fois sur ce
  dépôt — c'est le piège le plus répétitif de la liste.
- **Un cache `game/.godot` périmé ment.** Après l'ajout d'un script avec un
  `class_name` global, des erreurs du type `Nonexistent function … in base
  'Nil'` ou un autoload qui échoue au chargement **ressemblent** à une
  régression alors que c'est le cache. Faire `rm -rf game/.godot` et relancer
  (10-15 min de réimport) *avant* de conclure à une régression, jamais après
  avoir passé une heure à lire du code sain.

## Ce qu'on livre : une expérience, pas des fonctionnalités

On travaille sur **un jeu**. À la fin, seule l'expérience du joueur compte — pas
le nombre de lots livrés, pas la conformité à la spec, pas la couleur des
bancs. Les tests et les captures sont des garde-fous contre la régression ; ce
ne sont pas des objectifs, et les confondre est le travers naturel d'un agent
qui optimise ce qui se mesure.

Ce que ça change, concrètement :

- **Un lot énonce l'expérience visée avant sa liste de tâches.** « Le joueur
  doit ressentir un dilemme au moment de dépenser », pas « ajouter l'écran
  Comité ». Si cette phrase ne s'écrit pas, le lot n'a pas de raison d'être et
  il faut le dire plutôt que de le coder.
- **Un lot n'est pas fini parce que le code marche.** La question de clôture est
  *« qu'est-ce qui est meilleur à jouer maintenant ? »*. « La fonctionnalité X
  existe » n'est pas une réponse — c'est la reformulation de la tâche.
- **Livrer la feature n'est pas la mission.** Un lot conforme à sa spec qui rend
  le jeu moins bon est un échec, et ça se dit dans la PR. Cocher les cases en
  sachant que le résultat est tiède est le pire service à rendre.
- **Le doute se signale, il ne se tait pas.** Un dev qui pense que ce qu'on lui
  demande n'améliorera pas l'expérience doit l'écrire, avec son argument, et
  livrer quand même si Camille maintient. Livrer en silence ce qu'on croit
  mauvais est le seul comportement vraiment inacceptable.
- **La feature factory guette aussi les agents.** Enchaîner les lots parce
  qu'il y a des issues ouvertes, c'est produire de l'output. Le nombre de lots
  livrés dans une nuit ne dit rien de la qualité du jeu au matin.

## La vision — les questions qui invalident un lot

Un lot peut avoir ses trois bancs au vert et **quand même être à refuser**. Les
tests protègent le code ; rien ne protège la direction du jeu, sauf ces
questions. Se les poser **avant** de déclarer un lot fini, et répondre
honnêtement dans la PR quand la réponse est gênante.

1. **Ne rien faire peut-il gagner ?** Si une stratégie passive franchit un
   quota, la difficulté est cassée. C'est un critère de recette permanent, pas
   une opinion — le banc l'asserte (`careful` doit perdre).
2. **Le joueur sait-il encore quelle valeur regarder ?** Une seule grandeur est
   au centre (l'Impact). Ajouter un compteur que le joueur doit surveiller en
   permanence, c'est revenir au défaut qu'on corrige.
3. **Existe-t-il un chemin qui fait décoller une partie ?** Un moteur qui
   plafonne n'est pas un roguelike à combos. Et il en faut **plusieurs**, dont
   aucun ne domine.
4. **A-t-on promis quelque chose ?** Le jeu montre ce qu'un achat *aurait*
   rapporté, jamais ce qu'il *va* rapporter. Un écran qui annonce un gain futur
   a transformé un pari en calcul, et tué l'intérêt du pari.
5. **A-t-on réduit l'aléatoire ?** C'est un roguelike : l'aléa n'est pas une
   gêne à lisser, c'est la matière. Rendre un tirage déterministe « pour que ce
   soit plus juste » est un défaut, pas une amélioration.
6. **Un réglage est-il devenu un trait de contexte ?** Les libertés qu'on donne
   au joueur doivent teinter le run (l'entreprise, l'époque, le niveau), pas
   rester des options neutres.
7. **Reste-t-il une valeur d'équilibrage dans un script ?** `grep` le dit. Une
   seule suffit à rendre le rééquilibrage impossible sans un dev.
8. **À N=1, la couche multi-équipe est-elle invisible ?** Vérifier sur `.gd`,
   `.tscn` **et** `data/*.json` — c'est par les JSON que le mot a déjà fui
   jusqu'à l'écran.
9. **L'économie de l'entreprise s'est-elle remise à dépendre de l'Impact ?**
   Un gain de 💰 Revenue calculé à partir de l'Impact du sprint fusionne les
   deux monnaies sans que rien ne casse. Le banc le dit : si
   `Revenue final / charges` décolle, la caisse a cessé de contraindre.

### Quand demander une relecture par un agent tiers

**Obligatoire** quand un lot touche l'économie, le moteur de score, ou une règle
de progression — c'est-à-dire quand une erreur ne casse aucun test mais se paie
à la troisième heure de jeu.

Deux règles pour que ça serve à quelque chose :

- **Donner un mandat écrit et vérifiable** : « vérifie ces cinq propriétés »,
  jamais « dis-moi si c'est bien ». Un relecteur sans mandat approuve — c'est le
  résultat par défaut, et il ne vaut rien.
- **Lui dire explicitement d'être critique**, et pourquoi : celui qui a écrit le
  lot a discuté des heures avec Camille et est trop investi dans ses propres
  choix.

**Et connaître la limite.** Un agent qui relit partage les biais de celui qui a
écrit : même documentation, même raisonnement, mêmes angles morts. Il attrape
les incohérences internes, les oublis, les contradictions entre documents. Il
n'attrape **pas** les erreurs de vision, ni ce qui ne se voit qu'à l'écran. Une
relecture d'agent avait validé le Lot 5 sans voir que le mot « squad »
s'affichait dans un premier run ; c'est une capture d'écran qui l'a trouvé.

Les garde-fous qui ont réellement attrapé des défauts sur ce dépôt sont
mécaniques : la boucle de 40 runs, le `grep` sur les trois familles de fichiers,
la capture d'écran. **Préférer toujours un garde-fou qu'une machine peut vérifier
à une relecture qui dépend du sérieux du relecteur.**

## Recette — obligatoire à la fin de chaque lot

1. Les **deux smoke tests headless** passent (`game/tests/smoke_test_logic.gd`
   et `smoke_test_ui.gd`), plus `score_resolver_cases.gd`.
2. Les **captures d'écran** sont relues (voir ci-dessous), et un **run visuel
   complet** est fait par un humain pour ce que les captures ne couvrent pas.
3. Le **carnet de règles est mis à jour** avec les décisions prises (les
   §14-19 documentent l'historique des arbitrages — continuer la série).
4. La PR répond à **« qu'est-ce qui est meilleur à jouer maintenant ? »** en une
   phrase qui ne soit pas la reformulation de la tâche.
5. La PR contient un commentaire **« Revue de lot »**, publié avant de la
   déclarer prête : mandat de relecture lié à l'issue, verdict explicite
   (bloqueur ou non), propriétés vérifiées et résultats exacts des commandes.
   Une simple liste de tests sans ce qui a été relu ne vaut pas preuve.
6. Ce commentaire joint les **captures réellement relues** qui concernent le
   changement (au minimum un état nominal et un état d'alerte, si la règle a
   une UI), avec une légende qui dit ce que chaque image vérifie. Il inclut
   aussi le compte du banc aléatoire (`40/40`, ou le nombre d'échecs et leur
   cause). Les chemins temporaires et la formule « captures faites » ne sont
   pas des preuves : les images doivent être visibles dans la conversation de
   la PR.

### Voir le jeu sans écran

`--headless` ne dessine rien, mais `xvfb` est disponible et Godot accepte le
driver `x11` : sous un serveur X virtuel, le rendu a réellement lieu et on
peut sauver des PNG.

```
SHOT_DIR=/chemin xvfb-run -a godot --path game --display-driver x11 \
    --resolution 1600x900 res://tests/screenshot_screens.tscn
```

1600×900 est la résolution réelle du viewport (`project.godot`) — capturer
plus petit invente des troncatures qui n'existent pas.

Ça attrape les fautes de texte, les débordements et les troncatures ; **pas**
les enchaînements, les transitions, ni ce qui dépend d'un état de jeu avancé,
puisque chaque écran est instancié isolément. Quatre lots ont été livrés sans
qu'un seul pixel soit vu ; la toute première capture a trouvé deux défauts
dans du code déjà mergé. À lancer avant de déclarer un lot fini.

### Écrire un test sur un jeu aléatoire

- **Ne jamais asserter sur le résultat d'un tirage.** Asserter sur la
  *relation* entre le tirage et la décision qui en découle. Pas « le plan
  n'est pas vide », mais « le plan n'est vide que si rien n'était abordable ».
  Trois tests d'affilée s'y sont fait piéger (carnet §29 et §30.4), à chaque
  fois avec un code parfaitement sain.
- **Une règle à double conséquence se teste dans les deux sens.** Quand une
  règle produit deux effets opposés attendus, asserter les deux — un seul des
  deux passe aussi bien avec une implémentation fausse. Exemple : indexer les
  prix sur l'escalade des objectifs doit faire *monter* le prix d'un item d'un
  trimestre au suivant **et** faire *baisser* son coût relatif à l'objectif.
  Tester seulement « le prix monte » ne distingue pas une indexation correcte
  d'une inflation pure, qui est précisément le défaut qu'on cherche à éviter.
- **Un run unique ne prouve rien.** `smoke_test_logic` coûte 0,8 s : un flaky
  à 10-20 % passe inaperçu sur un run et coûte une heure trois jours plus
  tard. Mesurer par **boucle de 40 runs** en comptant les `OK`, et comparer à
  la même mesure sur `main` avant de conclure qu'on a cassé quelque chose —
  c'est ce qui distingue « ma régression » de « défaut préexistant ».

### Vérifier une règle d'affichage

Une interdiction qui porte sur du **texte affiché** (« le mot *squad* ne doit
jamais apparaître dans un premier run ») se vérifie sur `.gd`, `.tscn` **et
`data/*.json`**. Le mot a fui par les JSON, après un grep qui ne couvrait que
les deux premiers — et n'a été vu que sur une capture d'écran.

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
