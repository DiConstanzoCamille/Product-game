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

Les événements aléatoires de la phase Inbox (§3, phase 1 ; §15 pour la pioche) : `events[].id/from/sprint/status/subject/text`, `eras[]` optionnel (réserve l'événement aux scénarios listés ; absent = disponible partout), et `choices[]` (`id`, `label`, `reveal` — le texte montré après le choix, `effects` — deltas structurés sur les 6 ressources, consommés par `game/` ; `reveal` et `effects` doivent rester cohérents mais ne sont pas générés l'un depuis l'autre). `sprint` est un vestige de la démo landing (premier événement affiché) — `game/` tire désormais par pioche "sac", indépendante de ce champ.

## `recruitment-archetypes.json`

Les archétypes génériques d'employés (§9.2), indépendants de toute instance de shop : `archetypes[]` (`id`, `name`, `cost`, `capacity`, `trait`). Complété par `eraSkins[]` (§9.3) qui documente l'habillage du shop par époque.

## `recruitment-demo.json`

Les cartes concrètes affichées dans le shop de démo sur la landing page, par habillage (`skins[]` — `id`, `label`, `type`: `candidates` ou `ads`, puis `candidates[]` ou `ads[]` selon le type). À distinguer de `recruitment-archetypes.json` : ce fichier contient des instances d'exemple, pas la table de design générique.

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

- `startingResources` — valeur de départ des 6 ressources ; `resourceBounds` (min/max, 0-100) ; `resourceDirection` (`high-good` / `low-good`, pour savoir quel sens est "bon") ; `stateThresholds` (`goodMin`/`dangerMax`, pour l'affichage bon/attention/danger).
- `mandateLengthSprints`, `trimesterLengthSprints` — durée du mandat et du point de contrôle trimestriel.
- `endingThresholds[]` — seuil par ressource déclenchant une fin négative (`resource`, `comparison`: `lte`/`gte`, `value`, `ending`) ; `endingThresholdOverrides` — ajustement de ces seuils par époque.
- `goodEnding` — comment calculer la fin positive (IPO vs Rachat) quand le mandat va à son terme sans fin négative.
- `cardAxisResourceMap` — comment les 4 axes de `cards.json` se convertissent en deltas sur les 6 ressources (`resource`, `invert`).
- `structuralDecisionMaxActivations` — limite de grandes décisions activées par mandat.
- `eraCardEffectMultipliers` — multiplicateurs par époque sur les deltas produits par l'activation d'une grande décision.
- `roadmap` — `featureEffects` (deltas par feature de `roadmap-features.json`) et `overCapacityPenalty` (pénalité de surchauffe).
- `recruitment.itemEffects` — coût d'embauche, effet immédiat et bonus de capacité par entrée de `recruitment-demo.json`.
- `playableEras[]` — sous-ensemble de `eras.json` réellement jouable depuis `scenario_screen` (§15) ; les autres s'affichent verrouillés.
- `eraBusinessModel` — scénario → id de modèle économique (`businessModels`).
- `businessModels` — un modèle par id : `label`, `description`, `revenuePerValeurPercuePoint`, `moralChurnFloor`/`moralChurnCeiling` (bornes du facteur de churn appliqué au revenu selon le Moral). Voir §15 pour la formule complète (`SprintState.compute_revenue()`).
- `eraRecruitmentSkin` — scénario → id de skin de `recruitment-demo.json` (§16) ; remplace le choix libre du joueur.

## `companies.json`

Les "offres d'emploi" (§16) — le cadre RP d'une run, choisi sur `company_select_screen` après le scénario :

- `companies[]` — `id`, `era` (scénario auquel l'entreprise est rattachée), `icon`, `name`, `tagline` (accroche façon offre d'emploi), `description` (contexte de la boîte), `teamProfile` (`junior`/`senior` — fixe `SprintState.team_profile` pour tout le mandat, ce n'est plus un réglage modifiable en jeu).

## Ce qui reste hors JSON

Les hypothèses non tranchées et les archétypes de CPO non validés (§13 du carnet de règles) restent en markdown : ce sont des questions de conception ouvertes, pas encore des données de jeu.
