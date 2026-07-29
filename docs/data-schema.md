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
- `cards[]` — `id`, `refId` (identifiant façon ticket), `family` (`outil-process` / `stack-technique` / `methodologie-orga`, voir §6.2), `category`, `name`, `tagline`, `effects.junior` / `effects.senior` (un objet par axe avec `value` signé et `note` explicative), `eras[]` optionnel (§15 — réserve la carte aux scénarios listés ; absent = disponible partout).

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

## `inbox-events.json`

Les événements aléatoires de la phase Inbox (§3, phase 1 ; §15 pour la pioche) : `events[].id/from/sprint/status/subject/text`, `eras[]` optionnel (réserve l'événement aux scénarios listés ; absent = disponible partout), et `choices[]` (`id`, `label`, `reveal` — le texte montré après le choix, `effects` — deltas structurés sur les 6 ressources, consommés par `game/` ; `reveal` et `effects` doivent rester cohérents mais ne sont pas générés l'un depuis l'autre). `effects` accepte aussi les pseudo-ressources `pieces` (🪙, budget d'action — Phase A) et `energie` (⚡, jauge personnelle du joueur — Phase B : les crises vous suivent à la maison) ; les deux sont réglées à la Résolution, hors des bornes 0-100 des 6 jauges. `sprint` est un vestige de la démo landing (premier événement affiché) — `game/` tire désormais par pioche "sac", indépendante de ce champ.

## `recruitment-archetypes.json`

Les archétypes génériques d'employés (§9.2), indépendants de toute instance de shop : `archetypes[]` (`id`, `name`, `cost`, `capacity`, `trait`). Complété par `eraSkins[]` (§9.3) qui documente l'habillage du shop par époque.

## `recruitment-demo.json`

Les cartes concrètes affichées dans le shop de démo sur la landing page, par habillage (`skins[]` — `id`, `label`, `type`: `candidates` ou `ads`, puis `candidates[]` ou `ads[]` selon le type). À distinguer de `recruitment-archetypes.json` : ce fichier contient des instances d'exemple, pas la table de design générique. Depuis la Phase A, `game/` ne le consomme plus (le Marché tire dans `candidates.json`) — il reste la démo de la landing page.

## `candidates.json`

Le pool de candidats du Marché (spec profondeur §5.1, carnet §17) : `candidates[]` — `id`, `name`, `role` (`dev`/`pm`/`designer`/`ops`), `seniority` (`junior`/`senior`), `costPieces` (prix d'embauche en pièces), `salary` (ponction Trésorerie par sprint, cohérent avec `balance.json` → `salaries`), `trait` (trait visible, illustratif jusqu'à la Phase C), `badges[]`, `eras[]` optionnel. Le trait caché n'est **pas** dans ce fichier : il est tiré dans `hidden-traits.json` au moment où le candidat apparaît au Marché.

## `practices.json`

Le pool de pratiques du Marché (spec profondeur §5.2, carnet §17) : `practices[]` — `id`, `icon`, `name`, `costPieces`, `description`, `unlocks` (flag consommé par le système concerné : `hiddenTraits` révèle les traits cachés au Marché dès la Phase A ; `roi`/`clientImpact`/`risk`/`okrBonus` attendent la roadmap profonde de la Phase C ; `burndown`/`accounts` déverrouillent leurs sections du Pilotage), `perSprint` optionnel (deltas de ressources appliqués à chaque Résolution tant que la pratique est possédée), `eras[]` optionnel.

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
- `endingThresholds[]` — seuil par ressource déclenchant une fin négative (`resource`, `comparison`: `lte`/`gte`, `value`, `ending`) ; `endingThresholdOverrides` — ajustement de ces seuils par époque. Depuis la Phase A, la Valeur perçue n'y figure plus : sous le seuil de décrochage, c'est le revenu qui tombe à zéro (`pressure.revenueCutoffValeurPercue`). Depuis la Phase B, la pseudo-ressource `energie` y est acceptée (elle lit `SprintState.energy`, pas une jauge de `resources.json`) : le burn-out fondateur·rice se déclenche sur Énergie ≤ 0 (spec profondeur §8.3).
- `goodEnding` — comment calculer la fin positive (IPO vs Rachat) quand le mandat va à son terme sans fin négative.
- `cardAxisResourceMap` — comment les 4 axes de `cards.json` se convertissent en deltas sur les 6 ressources (`resource`, `invert`).
- `structuralDecisionMaxActivations` — limite de grandes décisions activées par mandat.
- `eraCardEffectMultipliers` — multiplicateurs par époque sur les deltas produits par l'activation d'une grande décision.
- `salaries` — salaire par sprint selon la séniorité (`junior`/`senior`), prélevé en Trésorerie à chaque Résolution (ligne "masse salariale").
- `roles` — production et pénalités par rôle (spec profondeur §4.2) : `label`, `icon`, `capacityPerEmployee` (points par séniorité), `fullYieldCount`/`extraYieldFactor` (rendements décroissants au-delà du cap de cumul), et les spécificités : PM `overloadReductionPerPm`/`overloadReductionMax` (modulation de la surchauffe), Designer `valeurPerFeatureDelivered`/`valeurPerFeatureDeliveredMax`/`valeurEffectsDivisorIfAbsent`, Ops `dettePerOps`/`detteReliefMax`/`dettePerSprintIfAbsent`.
- `firing` — licenciement (§4.4) : `severancePieces`, `moral`, `cynismePerExtraFiring` (à partir du 2e licenciement du mandat).
- `trialPeriodSprints` — durée de la période d'essai avant révélation du trait caché.
- `pieces` — flux du budget d'action (§3) : `boardAllocationPerSprint`, `boardAllocationIfReviewFailed`, `revenuePerformanceDivider` (prime = `floor(revenu / divider)`).
- `shopDraw` — taille du tirage du Marché (`candidatesPerSprint`, `practicesPerSprint`) et `practiceCynisme` (+Cynisme par achat de pratique).
- `energy` — l'économie du joueur (spec profondeur §7, carnet §18) : `start`/`max` (jauge ⚡, côté jeu uniquement — jamais dans `resources.json`, partagé avec la landing), `regenPerSprint` (régénération à la Résolution), `moralRegenTiers[]` (paliers `moralMin`/`factor` de modulation par le Moral, du plus haut au plus bas : ×1 si Moral ≥ 60, ×0.5 entre 30 et 60, ×0 sous 30), `breatherRegenBonus` (bonus de 🧘 Souffler), `actions` (coûts et effets des actions personnelles : `oneOnOne.cost`, `selfWork.cost`/`capacityBonus`, `extension.cost`/`capitalPolitique`/`pieces`, `breather.cost`).
- `pressure` — la pression (§8) : `valeurPercueDecayPerSprint` (décroissance naturelle), `revenueCutoffValeurPercue` (seuil de décrochage du revenu), `boardReview` (`successPieces`, `successCapitalPolitique`, `failCapitalPolitique`).
- `roadmap` — `featureEffects` (deltas par feature de `roadmap-features.json`), `featureCostPoints` (coût en points de capacité par feature), `quickWinPieces` (pièces gagnées à la livraison des quick wins) et `overCapacityPenalty` (pénalité de surchauffe, modulée par les PM).
- `playableEras[]` — sous-ensemble de `eras.json` réellement jouable depuis `scenario_screen` (§15) ; les autres s'affichent verrouillés.
- `eraBusinessModel` — scénario → id de modèle économique (`businessModels`).
- `businessModels` — un modèle par id : `label`, `description`, `revenuePerValeurPercuePoint`, `revenueValeurPercueOffset` (seuil de notoriété : seuls les points de Valeur perçue au-dessus produisent du revenu), `moralChurnFloor`/`moralChurnCeiling` (bornes du facteur de churn appliqué au revenu selon le Moral). Voir §15 et §17 pour la formule complète (`SprintState.compute_revenue()`).

## `companies.json`

Les "offres d'emploi" (§16, enrichies en §17) — le cadre RP d'une run, choisi sur `company_select_screen` après le scénario :

- `companies[]` — `id`, `era` (scénario auquel l'entreprise est rattachée), `icon`, `name`, `tagline` (accroche façon offre d'emploi), `description` (contexte de la boîte), `teamProfile` (`junior`/`senior` — fixe `SprintState.team_profile` pour tout le mandat, ce n'est plus un réglage modifiable en jeu), `teamCap` (cap d'effectif), `startingPieces` (budget d'action initial), `startingRoster[]` (`id`, `name`, `role`, `seniority`, `trait` — l'équipe héritée, salaires dérivés de `balance.json` → `salaries`, pas de trait caché : sa période d'essai est derrière elle), `boardObjectives` (`title` + `conditions[]` — `type`: `resource-max`/`resource-min`/`decisions-min`/`revenue-min`, `value`, `resource` éventuel, `label` affiché au joueur dès le choix du poste).

## Ce qui reste hors JSON

Les hypothèses non tranchées et les archétypes de CPO non validés (§13 du carnet de règles) restent en markdown : ce sont des questions de conception ouvertes, pas encore des données de jeu.
