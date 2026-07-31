# Schéma des données de jeu

Toutes les données de conception factuelles (ressources, cartes, époques, fins de mandat, etc.) vivent en JSON dans [`data/`](../data/), séparées du texte narratif du [carnet de règles](carnet-de-regles.md). Le carnet reste la référence en cas de désaccord ; ces fichiers en sont une extraction structurée, utilisée notamment par [`landing/index.html`](../landing/index.html).

Toutes les valeurs numériques (coûts, seuils, pourcentages) sont **indicatives** et non équilibrées — voir §13 du carnet de règles pour les questions encore ouvertes.

## `resources.json`

Les 6 jauges du jeu (§4) et leurs tensions croisées (§5).

- `resources[]` — `id`, `icon`, `name`, `definition`, `rises[]` (ce qui la fait monter), `falls[]` (ce qui la fait descendre), `extreme` (`condition` + `outcome` : la fin de mandat déclenchée à l'extrême).
- `tensions[]` — `id`, `resources[]` (2 ids de ressources concernées), `description`.

## `cards.json`

Le système de cartes structurelles calibrées (§6.2) : RICE, Notion, Jira.

- `axes[]` — les 4 axes affichés sur le dos d'une carte (`id`, `label`) : coût humain, coût financier, time-to-market, productivité.
- `teamProfiles[]` — les 2 profils d'équipe possibles (`id`, `label`, `shortLabel`) utilisés pour recalibrer les cartes.
- `cards[]` — `id`, `costPieces` (prix d'activation en 🪙 — une décision se paie comme une embauche, §21 ; distinct de l'axe `financier`, qui est le coût d'exploitation), `refId` (identifiant façon ticket), `family` (`outil-process` / `stack-technique` / `methodologie-orga`, voir §6.2), `category`, `name`, `tagline`, `effects.junior` / `effects.senior` (un objet par axe avec `value` signé et `note` explicative), `eras[]` optionnel (§15 — réserve la carte aux scénarios listés ; absent = disponible partout), `rarity` et `eraWeights` optionnels (voir *Rareté et tirage* plus bas), et `requires` optionnel.
- `requires` — le prérequis d'activation d'une carte gatée (§21), dans la **même grammaire de conditions** que `boardObjectives` de `companies.json` : `type` (`resource-min` / `resource-max` / `decisions-min` / `revenue-min` / `roster-seniority-min` / `practice-owned`), la clé qui va avec (`resource`, `seniority`, `practice`), `value` et `label` (la phrase montrée sur la carte). Une carte qui déclare `requires` prend automatiquement un bail de `shopDraw.lockedLeaseSprints` sprints quand elle est tirée.

## `eras.json`

Les 3 contextes de run (§10) : `id`, `icon`, `period`, `name`, `description`, `tension`, `boss`, `systemicEffects[]` (leviers systémiques : pool de cartes/employés, multiplicateurs, seuils).

## `endings.json`

Les 8 fins de mandat (§12) : `id`, `icon`, `label`, `note`. Le fait que certaines fins soient propres à une seule époque reste une question ouverte (§13) — non tranché dans ce fichier.

## `foundations.json`

Les Fondations — effets persistants sur le plateau (§7).

- `families[]` — les 3 familles de grandes décisions (`outil-process`, `stack-technique`, `methodologie-orga`) et ce qu'elles affectent.
- `demoBoard[]` — l'état d'exemple montré sur la landing page : `id`, `family`, `name`, `status` (`waiting` / `active`), `activeSinceSprint`, `detail`, `prerequisite`.

## `roadmap-features.json`

Les features proposables en phase Roadmap (§8), exemple d'un sprint : `capacityMax` (capacité de l'équipe), `features[]` (`id`, `name`, `promise` — la promesse affichée au joueur, `icons[]`, `selectedByDefault`).

## `backlog.json`

Le backlog de la Roadmap profonde (§6 de la [spec profondeur de gameplay](spec-profondeur-gameplay.md)) — le successeur de `roadmap-features.json` côté `game/`, qui reste la démo landing. Il est consommé par `GameData.backlog` et tiré par `SprintState`.

- `features[]` — `id`, `name`, `icon` (emoji), `description` (le pitch satirique affiché au joueur), `costPoints` (1-5, **toujours visible**, se paie en capacité produite par le roster), `roi` (0-3, bonus permanent de MRR une fois livrée), `clientImpact` (−2 à +6, delta de Valeur perçue à la livraison et source de Traction), `risk` (−3 à +8, delta de Dette à la livraison), `quickWin` (booléen — deux quick wins dans la même main donnent +2 de Budget d'investissement), `tags[]` (catégories utilisées par le combo Focus), `eras[]` (mêmes ids que `eras.json`, filtre du tirage par sac). `roi`, `clientImpact` et `risk` sont **cachés par défaut** ("🔒 ?") et révélés par les pratiques ou l'action Plonger dans une feature (§6.3) — d'où les features pièges dont la description flatteuse cache un `clientImpact` négatif.
- `epics[]` — mêmes champs que `features[]`, plus `epic: true`, `costPoints` (8-12, investissement libre étalé sur plusieurs sprints) et `completionEffects` (deltas structurés par ressource, même format que `effects` dans `inbox-events.json`, `pieces` inclus — appliqués **uniquement à la complétion**, en plus des `roi`/`clientImpact`/`risk` de l'epic ; abandonner remet la progression à zéro sans remboursement et rend l'epic éligible à un futur tirage, §6.4).

## `inbox-events.json`

Les événements aléatoires de la phase Inbox (§3, phase 1 ; §15 pour la pioche) : `events[].id/from/sprint/status/subject/text`, `eras[]` optionnel (réserve l'événement aux scénarios listés ; absent = disponible partout), et `choices[]` (`id`, `label`, `reveal` — le texte montré après le choix, `effects` — deltas structurés sur les 6 ressources, consommés par `game/` ; `reveal` et `effects` doivent rester cohérents mais ne sont pas générés l'un depuis l'autre). `effects` accepte aussi les pseudo-ressources `pieces` (🪙, budget d'action — Phase A) et `energie` (⚡, jauge personnelle du joueur — Phase B : les crises vous suivent à la maison) ; les deux sont réglées à la Résolution, hors des bornes 0-100 des 6 jauges. `sprint` est un vestige de la démo landing (premier événement affiché) — `game/` tire désormais par pioche "sac", indépendante de ce champ.

## `recruitment-archetypes.json`

Les archétypes génériques d'employés (§9.2), indépendants de toute instance de shop : `archetypes[]` (`id`, `name`, `cost`, `capacity`, `trait`). Complété par `eraSkins[]` (§9.3) qui documente l'habillage du shop par époque.

## `recruitment-demo.json`

Les cartes concrètes affichées dans le shop de démo sur la landing page, par habillage (`skins[]` — `id`, `label`, `type`: `candidates` ou `ads`, puis `candidates[]` ou `ads[]` selon le type). À distinguer de `recruitment-archetypes.json` : ce fichier contient des instances d'exemple, pas la table de design générique. Depuis la Phase A, `game/` ne le consomme plus (le Marché tire dans `candidates.json`) — il reste la démo de la landing page.

## `candidates.json`

Le pool de candidats du Marché (spec profondeur §5.1, carnet §17) : `candidates[]` — `id`, `name`, `role` (`dev`/`pm`/`designer`/`ops`), `seniority` (`junior`/`senior`), `costPieces` (prix d'embauche en Budget d'investissement), `salary` (ponction Trésorerie par sprint, cohérent avec `balance.json` → `salaries`), `trait` (texte affiché), `visible_trait_id` (règle de Levier dans `scoring.json`), `badges[]`, `eras[]` optionnel. Le trait caché n'est **pas** dans ce fichier : il est tiré dans `hidden-traits.json` au moment où le candidat apparaît au Marché.

## `practices.json`

Le pool de pratiques du Marché (spec profondeur §5.2, carnet §17) : `practices[]` — `id`, `icon`, `name`, `costPieces`, `description`, `unlocks` (flag consommé par le système concerné : `hiddenTraits` révèle les traits cachés au Marché ; `roi`/`clientImpact`/`risk` révèlent définitivement la colonne correspondante du backlog ; `okrBonus` donne le bonus de Capital politique aux livraisons à fort ROI ; `burndown`/`accounts` déverrouillent leurs sections du Pilotage), `perSprint` optionnel (deltas de ressources appliqués à chaque Résolution tant que la pratique est possédée), `rarity` et `eraWeights` optionnels (voir *Rareté et tirage* ci-dessous), `eras[]` optionnel.

### Rareté et tirage — commun à `cards.json`, `practices.json` et `candidates.json`

Depuis le carnet §21, les trois pools sont tirés **au poids**, sans mémoire d'un sprint à l'autre. Deux champs facultatifs, de même sens partout :

- `rarity` — `commune` (défaut), `notable` ou `rare`. Le poids de chaque palier vit dans `balance.json` → `shopDraw.rarityWeights` : la donnée dit *à quel point c'est rare*, l'équilibrage dit *combien ça pèse*.
- `eraWeights` — coefficient multiplicateur par époque, ex. `{ "agile-transformation": 2.0 }`. C'est là qu'un scénario **colore** l'offre ; `eras[]` reste, lui, un filtre binaire de disponibilité.

## `hidden-traits.json`

Le pool de traits cachés des candidats (spec profondeur §4.5, carnet §17) : `distribution` (poids relatifs `none`/`negative`/`positive` du tirage — ~50/30/20), `traits[]` — `id`, `icon`, `name`, `polarity`, `description`, `effects` (une clé par mécanique : `moralPerSprint`, `contributionFactor` — divise les contributions de rôle, `capacityBonus`, `salaryRaiseAtTrialEnd`, `quitsAtHiredPlus` — départ sans préavis au sprint d'embauche + N, `nextHireDiscountPieces`). Les effets ne s'appliquent qu'une fois le trait révélé (fin de période d'essai).

## `hud-demo.json`

L'état d'exemple du HUD de résolution de sprint montré sur la landing page : `era`, `cpo`, `gauges[]` (`id`, `label`, `display`, `percent`, `state`: `good`/`warn`/`danger`), `journal[]` (`sprint`, `text`, `deltas`), `alert`.

## `structure.json`

La mécanique de fond, hors contenu chiffré (§2, §3, §6.1/6.2, §7, §11) :

- `temporalScales[]` — sprint / trimestre / mandat.
- `sprintPhases[]` — les 5 phases d'un sprint, dans l'ordre.
- `cardSystem` — la distinction cartes tactiques (pioche) vs grandes décisions structurelles (menu + familles).
- `persistentEffectsRules` — les 4 règles régissant les effets persistants (délai par défaut, friction contextuelle, prérequis, stacks transverses).
- `unifiedEffectModel` — le modèle d'effet unifié (ressource + magnitude + condition + durée) avec l'exemple chiffré du carnet (RICE × Transformation Agile × Ex-consultant McKinsey × senior).

## `balance.json`

Toutes les valeurs numériques nécessaires à la simulation persistante du MVP jouable (§14 du carnet de règles) — consommé uniquement par `game/`, jamais par `landing/`, pour garder la maquette de présentation indépendante de l'équilibrage :

- `startingResources` — valeur de départ des 6 ressources ; `startingResourceOverrides` — surcharges par entreprise (ex. la trésorerie tendue de Karavel) ; `resourceBounds` (min/max, 0-100) ; `resourceDirection` (`high-good` / `low-good`, pour savoir quel sens est "bon") ; `stateThresholds` (`goodMin`/`dangerMax`, pour l'affichage bon/attention/danger).
- `mandateLengthSprints`, `trimesterLengthSprints` — durée du mandat et du point de contrôle trimestriel (la revue de board tombe à la fin du sprint `trimesterLengthSprints`).
- `endingThresholds[]` — seuil par ressource déclenchant une fin négative (`resource`, `comparison`: `lte`/`gte`, `value`, `ending`) ; `endingThresholdOverrides` — ajustement de ces seuils par époque. La Valeur perçue n'y figure plus : elle reste une pression de marché, sans couper artificiellement le MRR. Depuis la Phase B, la pseudo-ressource `energie` y est acceptée (elle lit `SprintState.energy`, pas une jauge de `resources.json`) : le burn-out fondateur·rice se déclenche sur Énergie ≤ 0 (spec profondeur §8.3).
- `goodEnding` — comment calculer la fin positive (IPO vs Rachat) quand le mandat va à son terme sans fin négative.
- `cardAxisResourceMap` — comment les 4 axes de `cards.json` se convertissent en deltas sur les 6 ressources (`resource`, `invert`).
- `structuralDecisionMaxActivations` — limite de grandes décisions activées par mandat.
- `eraCardEffectMultipliers` — multiplicateurs par époque sur les deltas produits par l'activation d'une grande décision.
- `salaries` — salaire par sprint selon la séniorité (`junior`/`senior`), prélevé en Trésorerie à chaque Résolution (ligne "masse salariale").
- `roles` — production et pénalités par rôle (spec profondeur §4.2) : `label`, `icon`, `capacityPerEmployee` (points par séniorité), `fullYieldCount`/`extraYieldFactor` (rendements décroissants au-delà du cap de cumul), et les spécificités : PM `overloadReductionPerPm`/`overloadReductionMax` (modulation de la surchauffe), Designer `valeurPerFeatureDelivered`/`valeurPerFeatureDeliveredMax`/`valeurEffectsDivisorIfAbsent`, Ops `dettePerOps`/`detteReliefMax`/`dettePerSprintIfAbsent`.
- `firing` — licenciement (§4.4) : `severancePieces`, `moral`, `cynismePerExtraFiring` (à partir du 2e licenciement du mandat).
- `trialPeriodSprints` — durée de la période d'essai avant révélation du trait caché.
- `pieces` — anciens paramètres de flux conservés pour compatibilité de contenu. La formule active du Budget d'investissement vit dans `scoring.json` (`floor(sqrt(Impact))`, allocation plancher et combo Quick wins).
- `shopDraw` — tout le tirage des Investissements (carnet §21), qui sert **un seul rayon où les trois types se mélangent** : `slotsPerSprint` (nombre d'emplacements du rayon), `guaranteedPerSprint` (minimum garanti par type — le garde-fou qui empêche un sprint vide), `typeWeights` (répartition des emplacements restants entre `candidate`/`practice`/`decision` — pondérée par type et non par la taille des pools), `rarityWeights` (poids de tirage par palier de rareté, à l'intérieur d'un type), `practiceCynisme` (+Cynisme par achat de pratique), `reroll` (`baseCost`, `costIncrement` — prix du 🎲 re-tirage, qui monte de `costIncrement` à chaque usage dans le sprint et repart à `baseCost` au sprint suivant), `reserveCostPieces` (prix de la 📌 punaise, qui garantit l'Actif au sprint suivant) et `lockedLeaseSprints` (durée du bail d'une carte à prérequis).
- `energy` — l'économie du joueur (spec profondeur §7, carnet §18) : `start`/`max` (jauge ⚡, côté jeu uniquement — jamais dans `resources.json`, partagé avec la landing), `regenPerSprint` (régénération à la Résolution), `moralRegenTiers[]` (paliers `moralMin`/`factor` de modulation par le Moral, du plus haut au plus bas : ×1 si Moral ≥ 60, ×0.5 entre 30 et 60, ×0 sous 30), `breatherRegenBonus` (bonus de 🧘 Souffler), `actions` (coûts et effets des actions personnelles : `oneOnOne.cost`, `selfWork.cost`/`capacityBonus`, `featureDive.cost`, `extension.cost`/`capitalPolitique`/`pieces`, `breather.cost`).
- `pressure` — la pression (§8) : `valeurPercueDecayPerSprint` (décroissance naturelle) et `boardReview` (`successPieces`, `successCapitalPolitique`, `failCapitalPolitique`). `revenueCutoffValeurPercue` est un paramètre historique, sans effet sur la conversion MRR actuelle.
- `roadmap` — `overCapacityPenalty` (pénalité de surchauffe, modulée par les PM). Les coûts et effets propres aux items vivent exclusivement dans `backlog.json`.
- `backlogDraw` — tirage de la Roadmap profonde : `itemsPerSprintMin`/`itemsPerSprintMax`, `strongRoiThreshold` et `okrCapitalPolitiqueBonus`. `quickWinPieces` est conservé comme donnée historique mais n'est plus lu ; le bonus actif vient de la main complète dans `scoring.json`.
- `playableEras[]` — sous-ensemble de `eras.json` réellement jouable depuis `scenario_screen` (§15) ; les autres s'affichent verrouillés.
- `eraBusinessModel` — scénario → id de modèle économique (`businessModels`).
- `businessModels` conserve les métadonnées des modèles et les paramètres des scénarios non encore migrés. Pour `saas-mrr`, la formule active vit dans `scoring.json` : stock de MRR, churn, conversion de l'Impact et multiplicateurs des équipes support.

## `scoring.json`

Source de vérité de Traction × Levier = Impact : formules des features et
epics, bonus de main, série, rôles, huit combos d'organisation, outils,
stratégies, pratiques, traits visibles, freins et conversion vers MRR, Budget
d'investissement, Valeur perçue et Capital politique. `ScoreResolver` lit cette
table sans accéder aux autoloads.

## `companies.json`

Les "offres d'emploi" (§16, enrichies en §17) — le cadre RP d'une run, choisi sur `company_select_screen` après le scénario :

- `companies[]` — `id`, `era` (scénario auquel l'entreprise est rattachée), `icon`, `name`, `tagline` (accroche façon offre d'emploi), `description` (contexte de la boîte), `teamProfile` (`junior`/`senior` — fixe `SprintState.team_profile` pour tout le mandat, ce n'est plus un réglage modifiable en jeu), `teamCap` (cap d'effectif), `startingPieces` (budget d'action initial), `startingRoster[]` (`id`, `name`, `role`, `seniority`, `trait` — l'équipe héritée, salaires dérivés de `balance.json` → `salaries`, pas de trait caché : sa période d'essai est derrière elle), `boardObjectives` (`title` + `conditions[]` — `type`: `resource-max`/`resource-min`/`decisions-min`/`revenue-min`, `value`, `resource` éventuel, `label` affiché au joueur dès le choix du poste).

## Ce qui reste hors JSON

Les hypothèses non tranchées et les archétypes de CPO non validés (§13 du carnet de règles) restent en markdown : ce sont des questions de conception ouvertes, pas encore des données de jeu.

## État de run `SprintState`

L'état runtime n'est pas sérialisé en JSON, mais son contrat prépare l'échelle
multi-équipe du score : `squads[]` contient aujourd'hui une seule entrée
`{id, name, roster[], backlog_draw, capacity, delivered[], epic_progress}`.
`get_roster()` est uniquement une vue aplatie de lecture sur les rosters des
squads ; les mutations de l'expérience PM actuelle ciblent le roster de la
squad principale. `last_score_report` est le rapport immuable appliqué puis
rejoué par la Résolution ; `mrr` est un stock et `streak` mémorise les sprints
livrés sans surchauffe.
