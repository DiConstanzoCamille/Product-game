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
- `cards[]` — `id`, `costPieces` (prix d'activation en 🪙 — une décision se paie comme une embauche, §21 ; distinct de l'axe `financier`, qui est le coût d'exploitation), `refId` (identifiant façon ticket), `family` (`outil-process` / `stack-technique` / `methodologie-orga`, voir §6.2), `category`, `name`, `tagline`, `effects.junior` / `effects.senior` (un objet par axe avec `value` signé et `note` explicative — le feedback immédiat sur les jauges à l'activation), `eras[]` optionnel (§15 — réserve la carte aux scénarios listés ; absent = disponible partout), `rarity` et `eraWeights` optionnels (voir *Rareté et tirage* plus bas), et `requires` optionnel.
- **Le Levier par employé (spec scoring §7.1, Lot 3).** Un outil (`family` `outil-process` ou `methodologie-orga`) peut déclarer `icon` et tout ou partie de : `perEmployee` (bonus par employé éligible), `eligibility` (condition de matching sur le roster — même grammaire que `refractory.condition` et `adoptionCondition.condition` ci-dessous ; `{}` vide = tout le roster), `refractory` (`{condition, perEmployee}` — un malus par employé qui matche `condition`), `flatModifiers[]` (`{when, value}` — un bonus/malus fixe si `when` est vrai, ex. Jira sous 5 personnes), `cumulative` (`{perSprint}` — l'outil grandit tout seul depuis son activation, indépendamment du roster), `adoptionCondition` (`{condition, multiplier}` — un multiplicateur si l'équipe remplit un critère), `slotBonus` (l'outil rend un slot en s'installant, réservé aux outils cumulatifs, §7.1.1.b), `leverLabel` optionnel (nom affiché sur la ligne de score si différent de `name`, ex. Daily Standup → « Sprint planning »). Une carte sans `perEmployee` ni `cumulative` ne produirait aucun Levier par employé — cas géré par le moteur mais qu'aucune carte `outil-process`/`methodologie-orga` du catalogue actuel n'utilise, puisque toutes coûtent des pièces et un slot (`score_resolver_cases.gd → _test_every_tool_card_has_a_lever` le vérifie). `ScoreResolver` lit ces champs directement sur la carte (table `cards` passée à `ScoreResolver.resolve()`) — `scoring.json` ne les duplique plus, pour respecter la règle « un seul calcul » (CLAUDE.md). Le comportement par entreprise (Notion excellent chez Karavel, mauvais chez Meridia) émerge de la confrontation entre ces conditions et le roster réel : aucune branche par `company_id` nulle part.
- `requires` — le prérequis d'activation d'une carte gatée (§21), dans la **même grammaire de conditions** que `boardObjectives` de `companies.json` : `type` (`resource-min` / `resource-max` / `decisions-min` / `revenue-min` / `roster-seniority-min` / `practice-owned`), la clé qui va avec (`resource`, `seniority`, `practice`), `value` et `label` (la phrase montrée sur la carte). Une carte qui déclare `requires` prend automatiquement un bail de `shopDraw.lockedLeaseSprints` sprints quand elle est tirée.

## `eras.json`

Les 3 contextes de run (§10) : `id`, `icon`, `period`, `name`, `description`, `tension`, `boss`, `systemicEffects[]` (leviers systémiques : pool de cartes/employés, multiplicateurs, seuils).

## `endings.json`

Les 9 fins de mandat (§12) : `id`, `icon`, `label`, `note`. `remercie` est la fin immédiate d'un quota trimestriel manqué. Le fait que certaines fins soient propres à une seule époque reste une question ouverte (§13) — non tranché dans ce fichier.

## `quotas.json`

Le contrat du boss trimestriel (spec scoring §11), consommé par `SprintState` et les écrans de board.

- `version` — version du contrat ; `careerLevels` est une table indexée par identifiant de niveau de carrière (`pm`, `lead-pm`, `director`, `cpo`, `ceo` depuis le Lot 5, mêmes ids que `careers.json` → `order`) ; `quarterQuotas` est le tableau ordonné des quotas d'Impact brut T1 a T4. Chaque niveau recalibre grossièrement sa table sur son nombre moyen de squads (`careers.json` → `squadsMin`/`squadsMax`) — un Director ne joue pas avec les chiffres d'un PM (spec §13.4). Premier jet non équilibré, comme le reste des tables de ce fichier.
- `longMandate` — `quotaMultiplier` (multiplicateur appliqué à chaque trimestre T5+) et `requirementsAccumulate` (les exigences tirées restent actives dans ce mode).
- `requirements[]` — pool à tirage aléatoire, avec `id` stable, `icon`, `name`, `description` joueur et `effects` plat. Les clefs supportées sont `hiringFrozen`, `payrollMultiplier`, `minimumClientImpactForTraction`, `debtFrictionScale`, `quarterLength`, `quotaMultiplier`, `forcedStrategyPool` (tableau d'IDs de `scoring.json`), `practiceCynisme` et `toolsFrozen`.
- `qualitativeBonusBudget` — récompense en Budget si tous les objectifs qualitatifs de `companies.json` sont tenus en plus du quota. Le montant initial est volontairement conservateur : `8` par trimestre, à ajuster en playtest. `qualitativeBonus` documente sa condition, son texte et ses paramètres de mode long (`enabled`, `accumulates`).

## `careers.json`

La progression de carrière — le "stake" Balatro (spec §13.4, Lot 5, issue #18). Chargé dans `GameData.careers`, lu par `career_select_screen.gd`, `SprintState.reset_run()` et `mandate_end_screen.gd`.

- `order[]` — l'ordre de déblocage strict, ids `pm` → `lead-pm` → `director` → `cpo` → `ceo`. Aucun contournement : `SprintState._unlock_next_career_level()` ne débloque jamais que `order[i+1]` quand `order[i]` vient d'être gagné.
- `levels{}` — indexé par id : `icon`/`label` affichés, `squadsMin`/`squadsMax` (nombre d'équipes du niveau — `reset_run()` démarre toujours à `squadsMin`, déterministe, pas de tirage), `unlock` (`{type: "start"}` pour `pm`, `{type: "win-career-level", careerLevel: <id précédent>}` sinon — descriptif, la vérité du déblocage vit dans `PlayerProfile`), `unlockLabel` (le texte affiché sur la carte verrouillée, ex. *"Gagnez un mandat complet en PM (4 trimestres franchis)"*), `appears` (ce qui devient jouable à ce niveau, affiché sous la carte).
- Les slots d'outillage de base (`balance.json` → `toolSlots.careerLevels`) et les quotas (`quotas.json` → `careerLevels`) restent dans leurs tables historiques, indexées par le même id — jamais dupliqués ici.
- "Gagner" un niveau = franchir son 4e trimestre (`quarter_exit_choice_pending` devient vrai la première fois), qu'on choisisse ensuite de sortir ou de continuer en mandat long — la spec parle explicitement d'un mandat "complet" en 4 trimestres, avant la question de la sortie.

## `strategy.json`

La 4e famille de décisions (spec scoring §7.2, Lot 3) — la seule qui n'existait pas avant ce lot. `strategies[]` — `id` (partagé avec `scoring.json` → `global.strategies`, seule table qui porte les multiplicateurs), `icon`, `name`, `tagline`, `description` (texte joueur expliquant l'effet mécanique). Ce fichier est un catalogue d'affichage, pas une table de calcul : `ScoreResolver` ne lit que `scoring.json`. Choisie au Comité de fin de trimestre (écran du lot 4, pas encore construit), 1 par trimestre, irréversible — `SprintState.choose_strategy()` / `get_strategy_options()` / `find_strategy()` sont le point d'entrée que cet écran appellera ; en attendant, l'exigence trimestrielle `board-injunction` (`quotas.json`) est la seule à en choisir une, automatiquement.

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

Les événements aléatoires de la phase Inbox (§3, phase 1 ; §15 pour la pioche) : `events[].id/from/sprint/status/subject/text`, `eras[]` optionnel (réserve l'événement aux scénarios listés ; absent = disponible partout), et `choices[]` (`id`, `label`, `reveal` — le texte montré après le choix, `effects` — deltas structurés sur les 6 ressources, consommés par `game/` ; `reveal` et `effects` doivent rester cohérents mais ne sont pas générés l'un depuis l'autre). `effects` accepte aussi les pseudo-ressources `pieces` (🪙, budget d'action — Phase A) et `energie` (⚡, jauge personnelle du joueur — Phase B : les crises vous suivent à la maison) ; les deux sont réglées à la Résolution, hors des bornes 0-100 des 6 jauges. `sprint` est un vestige de la démo landing (premier événement affiché) — `game/` tire désormais par pioche "sac", indépendante de ce champ. `supportTeam` + `levelRange` (Lot 4, spec §9.4) réservent un événement à une équipe subie (`sales`/`pmm`/`csm`) dont le niveau (`companies.json → supportTeams`) tombe dans l'intervalle `[min, max]` — filtré par `SprintState._eligible_inbox_events()` comme une troisième couche après `eras[]` ; absent = éligible à tout niveau.

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
- `trimesterLengthSprints` — longueur nominale d'un trimestre (3 sprints). Le quota, ses exceptions et le point de contrôle trimestriel vivent dans `quotas.json`; la sortie après T4 ou le mandat long remplacent l'ancienne longueur fixe du mandat.
- `endingThresholds[]` — seuil par ressource déclenchant une fin négative (`resource`, `comparison`: `lte`/`gte`, `value`, `ending`) ; `endingThresholdOverrides` — ajustement de ces seuils par époque. La Valeur perçue n'y figure plus : elle reste une pression de marché, sans couper artificiellement le MRR. Depuis la Phase B, la pseudo-ressource `energie` y est acceptée (elle lit `SprintState.energy`, pas une jauge de `resources.json`) : le burn-out fondateur·rice se déclenche sur Énergie ≤ 0 (spec profondeur §8.3).
- `goodEnding` — comment calculer la fin positive (IPO vs Rachat) quand le mandat va à son terme sans fin négative.
- `cardAxisResourceMap` — comment les 4 axes de `cards.json` se convertissent en deltas sur les 6 ressources (`resource`, `invert`).
- `toolSlots` — capacité d'outillage (spec §7.1.1, Lot 3), qui remplace l'ancien plafond fixe `structuralDecisionMaxActivations` : `careerLevels` (table indexée par niveau de carrière, une seule ligne `pm.base` remplie avant le lot 5), `extraSlotCosts[]` (prix croissant des slots achetables au Comité, plafonnés à `.size()`), `swap` (`cynisme`/`cynismePerPreviousSwap` — le coût de bascule pour libérer un slot occupé, §7.1.2). La capacité effective (`SprintState.get_tool_slot_capacity()`) additionne la base, les achats et le `slotBonus` des outils cumulatifs actifs.
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
epics, bonus de main, série, rôles, huit combos d'organisation, stratégies,
pratiques, traits visibles, freins et conversion vers MRR, Budget
d'investissement, Valeur perçue et Capital politique. `ScoreResolver` lit cette
table sans accéder aux autoloads. Depuis le Lot 3, le Levier par outil ne vit
plus ici : il est déclaré directement sur la carte dans `cards.json` (voir
plus haut) — `ScoreResolver.resolve()` reçoit désormais une table `cards` en
plus de `scoring` et `hidden_traits`.

Depuis le Lot 4 : `global.productTier.leverPerTier` vaut `0.5` (corrigé de
`0.1`, hérité du Lot 1, pour matcher le "+0,5 Levier permanent" du Comité,
spec §12) ; `conversion.saas-mrr.salesMultipliers/pmmMultipliers/csmMultipliers`
(déjà là depuis le Lot 3) sont désormais réellement alimentés par
`companies.json → supportTeams`, transmis par le snapshot ; et
`global.strategies.*.supportTeamDeltas` (optionnel, `{sales, pmm, csm}` en
delta signé) déclare l'effet de bord d'une décision stratégique sur les
équipes subies (spec §9.4, dernier tiers) — appliqué par
`SprintState._apply_strategy_support_team_deltas()`, jamais un cas
particulier dans `ScoreResolver`.

## `companies.json`

Les "offres d'emploi" (§16, enrichies en §17) — le cadre RP d'une run, choisi sur `company_select_screen` après le scénario :

- `companies[]` — `id`, `era` (scénario auquel l'entreprise est rattachée), `icon`, `name`, `tagline` (accroche façon offre d'emploi), `description` (contexte de la boîte), `teamProfile` (`junior`/`senior` — fixe `SprintState.team_profile` pour tout le mandat, ce n'est plus un réglage modifiable en jeu), `teamCap` (cap d'effectif de départ — augmenté en jeu par 🪑 Ouvrir un poste au Comité, jamais réécrit ici), `startingPieces` (budget d'action initial), `supportTeams` (Lot 4, spec §9.4 — `{sales, pmm, csm}`, niveau 0-5 des trois équipes subies ; absent = neutre 3/3/3, lu par `SprintState.support_teams` puis transmis au score, jamais pilotable en jeu), `inheritedTools[]` optionnel (ids de `cards.json` — outillage déjà installé par quelqu'un d'autre, activé dès `reset_run` et occupant un slot dès le premier sprint, spec §7.1.3), `startingRoster[]` (`id`, `name`, `role`, `seniority`, `trait` — l'équipe héritée, salaires dérivés de `balance.json` → `salaries`, pas de trait caché : sa période d'essai est derrière elle), `boardObjectives` (`title` + `conditions[]` — `type`: `resource-max`/`resource-min`/`decisions-min`/`revenue-min`, `value`, `resource` éventuel, `label` affiché au joueur dès le choix du poste).

## `investments.json`

Le catalogue du Comité d'investissement (spec scoring §12, Lot 4) — entre
deux trimestres, jamais au fil de l'eau ; l'étal du sprint (`balance.json →
shopDraw`, `cards.json`, `practices.json`) ne change pas et n'est pas
dupliqué ici.

- `items[]` — `id`, `icon`, `name`, `tagline` (accroche courte), `description` (texte joueur), `kind` (dispatche vers la fonction `SprintState` qui applique l'effet : `strategy`, `tool-slot`, `tool-slot-release`, `team-cap`, `promotion`, `product-tier`, `seminar`, `cleanup-sprint`, `acquisition`, `headhunter`, `turnaround-plan`, `quarter-advance`). Les postes à échelle de prix (`open-seat`, `product-tier`) portent `costs[]`, consommé dans l'ordre (index = achats déjà faits ce mandat) — épuisé, le poste refuse `"plafond"`. Les postes à prix plat (`promotion`, `team-seminar`, `cleanup-sprint`, `acquire-competitor`, `headhunter`, `turnaround-plan`) portent `cost`. `strategic-decision` porte `costRange` (le prix est tiré une fois par trimestre, mémorisé par `SprintState.strategy_purchase_cost()`). `quarter-advance` porte `budgetGain`/`impactPenalty` (pas de prix : c'est un pari, pas un achat). Les magnitudes d'effet (`cynismeDelta`, `detteDelta`, `mrrDelta`, `capIncrement`, `nextShopCandidates`) vivent à côté du prix — jamais dans le script.
- Consommé uniquement par `game/` (`committee_screen.gd`) — `landing/` n'a pas de Comité.

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

Depuis le Lot 3 : `career_level` (index dans `careers.json`, `balance.json` →
`toolSlots.careerLevels` et `quotas.json` → `careerLevels` — `"pm"` par
défaut, et systématiquement retombé sur `"pm"` par `reset_run()` si le
niveau demandé n'est pas débloqué dans `PlayerProfile`), `tool_slots_purchased`
et `swap_count` (bascules d'outil déjà faites ce mandat, spec §7.1.2),
`chosen_strategy_ids[]` (décisions stratégiques permanentes du mandat) et
`quarter_strategy_chosen` (une seule par trimestre, imposée ou volontaire).

Depuis le Lot 5 : `pending_career_level` (étape transitoire entre
`career_select_screen` et `scenario_screen`, même rôle que `pending_era_id`)
et `newly_unlocked_career_level` (non vide uniquement le sprint où un niveau
vient de tomber — lu une fois par `mandate_end_screen.gd` puis ignoré, jamais
sérialisé). Au-delà de `pm`, `squads[]` contient une entrée par équipe du
niveau (`careers.json` → `squadsMin`) : la première reprend le roster hérité
de l'entreprise, les suivantes démarrent à vide (`_new_empty_squad()`) — à
staffer par recrutement, sans qu'aucune donnée d'entreprise n'ait besoin de
décrire un roster multi-équipe.

Depuis le Lot 4 : `support_teams` (`{sales, pmm, csm}`, initialisé à
`reset_run()` depuis `companies.json → supportTeams`, jamais réécrit par un
achat), `team_cap_purchased` et `product_tier` (échelles de prix du Comité,
spec §12), `cleanup_sprint_pending` (neutralise la Traction à la prochaine
Résolution), `headhunter_pending`/`headhunter_target_candidates` (consommés
au prochain `get_shop_offer()`), `turnaround_plans_available` (consommé
automatiquement par `_record_quarter_resolution()`), `current_committee_offer`
(cache le prix de la décision stratégique du trimestre, même principe que
le prix du re-tirage de l'étal).

## Persistance hors run : `PlayerProfile`

Premier et seul autoload à survivre à `reset_run()` (Lot 4, spec §12.1) —
un `ConfigFile` en `user://player_profile.cfg`, deux sections : les combos
du Compendium déjà déclenchés une fois (`mark_combo_discovered()` /
`is_combo_discovered()` / `get_combo_catalog()`, ce dernier reconstruit
depuis `scoring.json → local.organizationCombos` + `traction.handBonuses` +
`global.interSquadCombos`, jamais dupliqué), et un espace clé/valeur
générique (`set_value()` / `get_value()`). `record_score_report()` est le
seul point d'entrée qui écrit dans les combos : il scanne un rapport déjà
produit par `ScoreResolver.resolve()` et n'y ajoute aucune condition
supplémentaire. `clear_all()` est réservé aux tests headless (le fichier
`user://` survit sinon d'une exécution à l'autre) — ne jamais l'appeler
depuis le jeu.

Depuis le Lot 5, l'espace générique porte aussi la progression de carrière
(spec §13.4) : la clé `unlocked_career_levels` (tableau d'ids de
`careers.json`, `"pm"` toujours considéré débloqué même absent du fichier —
un profil neuf doit pouvoir lancer un run sans avoir jamais écrit sur le
disque) via `get_unlocked_career_levels()` / `is_career_level_unlocked()` /
`unlock_career_level()` — ce dernier idempotent et appelé uniquement par
`SprintState._unlock_next_career_level()`, jamais par un écran.
