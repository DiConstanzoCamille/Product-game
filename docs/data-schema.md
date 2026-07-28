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
- `cards[]` — `id`, `refId` (identifiant façon ticket), `family` (`outil-process` / `stack-technique` / `methodologie-orga`, voir §6.2), `category`, `name`, `tagline`, `effects.junior` / `effects.senior` (un objet par axe avec `value` signé et `note` explicative).

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

Les événements aléatoires de la phase Inbox (§3, phase 1) : `events[].id/from/sprint/status/subject/text`, et `choices[]` (`id`, `label`, `reveal` — l'effet réel montré après le choix).

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

## Ce qui reste hors JSON

Les hypothèses non tranchées et les archétypes de CPO non validés (§13 du carnet de règles) restent en markdown : ce sont des questions de conception ouvertes, pas encore des données de jeu.
