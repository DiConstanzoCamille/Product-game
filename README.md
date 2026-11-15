# Product Tycoon

> Un roguelike où vous incarnez le·la CPO fraîchement nommé·e d'une organisation que vous n'avez pas construite. Contexte tiré au sort, équipe héritée, décisions rarement réversibles. Chaque bonne pratique promet une amélioration théorique — son effet réel dépend de qui la reçoit.

Ce dépôt rassemble les documents de conception du jeu. **C'est un document de travail** : rien n'est encore équilibré ni final, l'objectif est de garder une base de réflexion partagée sur le concept et le gameplay.

## Conception du prochain rework

**Entrée des prochains développements :** [contrat du rework](docs/contrat-rework-bureau.md)
et [plan d’intégration](docs/plan-integration-rework.md). Le parcours commence par
**R0 — socle visuel et interactions** ; le plan indique l’avancement et la reprise.
Les consignes de reprise sont
dans [AGENTS.md](AGENTS.md) et [CLAUDE.md](CLAUDE.md).

Le 15 novembre 2026, les essais ont conduit à une direction centrée sur un bureau
vu du dessus, des backlogs à plusieurs niveaux et une organisation qui fait
progresser les sujets produit. **Les prototypes HTML restent figés.** La direction
graphique et les assets validés deviennent la cible des prochains développements ;
les règles encore ouvertes sont traitées avant les lots qui en dépendent.

- [Vision du bureau et de l’organisation](docs/vision-bureau-organisation.md) :
  orientations retenues, limites et décisions encore ouvertes.
- [Journée, découpage et livraison](docs/spec-journee-travail-livraison.md) :
  proposition détaillée et cas à relire avant tout développement.
- [Historique des prototypes](docs/prototype-bureau-flux.md) : ce qui a été essayé,
  ce qui fonctionne et ce qui n’est pas repris comme règle finale.
- [Direction interface de jeu `.pen`](docs/maquettes/product-tycoon-jeu/README.md) :
  44 vues et états avec un bureau plein écran, des cartes de choix, des gestes
  directs et des détails à la demande. Le [premier pack de 16 vues](docs/maquettes/product-tycoon-ui/README.md)
  reste une exploration antérieure, jugée trop web. Les prototypes restent figés.

Cette conception ne décrit pas encore le jeu implémenté. Le
[carnet de règles](docs/carnet-de-regles.md) reste la référence sur son état actuel.

## Structure du dépôt

```
Product-game/
├── docs/
│   ├── carnet-de-regles.md   # les règles complètes, en prose (référence en cas de désaccord)
│   ├── data-schema.md        # description de chaque fichier JSON dans data/
│   └── tech-stack.md         # choix du moteur de jeu (Godot 4) et pourquoi
├── data/                     # données de jeu structurées, extraites du carnet de règles
│   ├── resources.json               # les 6 jauges + leurs tensions
│   ├── cards.json                   # cartes structurelles calibrées (RICE, Notion, Jira)
│   ├── eras.json                    # les 3 contextes de run
│   ├── endings.json                 # les 9 fins de mandat
│   ├── quotas.json                  # quotas trimestriels et exigences du board
│   ├── foundations.json             # effets persistants sur le plateau
│   ├── roadmap-features.json        # features proposables en phase Roadmap
│   ├── inbox-events.json            # événements aléatoires de la phase Inbox
│   ├── recruitment-archetypes.json  # archétypes génériques d'employés
│   ├── recruitment-demo.json        # cartes de shop d'exemple (landing page)
│   ├── hud-demo.json                # état d'exemple du HUD de résolution de sprint
│   └── structure.json               # mécanique de fond (phases, familles de cartes, modèle d'effet)
├── landing/                         # maquette de présentation interactive du concept
│   ├── index.html
│   ├── css/style.css
│   └── js/main.js                   # charge les JSON de data/ et rend le DOM dynamiquement
└── game/                            # projet Godot 4 — voir game/README.md
    ├── project.godot
    ├── assets/                       # polices, icônes, avatars — licences dans THIRD_PARTY_NOTICES.md
    ├── resources/
    │   ├── theme/main_theme.tres     # thème partagé (couleurs de marque)
    │   └── shaders/                  # fond quadrillé façon landing page
    ├── scenes/screens/               # accueil, choix de scénario/entreprise, les 4 phases de sprint, fondations, fin de mandat
    │   ├── start_screen.tscn
    │   ├── inbox_screen.tscn
    │   ├── roadmap_screen.tscn
    │   ├── investments_screen.tscn
    │   ├── resolution_screen.tscn
    │   └── foundations_screen.tscn
    └── scripts/
        ├── autoload/          # game_data.gd (charge data/*.json) + sprint_state.gd (état partagé)
        ├── ui_helpers.gd      # polices, icônes, avatars, animations, styles partagés
        └── screens/           # un script par écran
```

- [`docs/carnet-de-regles.md`](docs/carnet-de-regles.md) — le carnet de règles complet : structure temporelle, ressources, système de cartes, effets persistants, roadmap, recrutement, époques, fins de mandat, et les questions ouvertes encore à trancher.
- [`docs/data-schema.md`](docs/data-schema.md) — le détail du schéma de chaque fichier JSON.
- [`docs/tech-stack.md`](docs/tech-stack.md) — le choix du moteur de jeu (Godot 4) et les alternatives écartées (Three.js, Unity, Unreal, stack web).
- [`docs/spec-profondeur-gameplay.md`](docs/spec-profondeur-gameplay.md) — l’historique des phases de profondeur et des mécanismes existants. L’ordre des prochains lots est désormais celui du plan d’intégration du rework.
- [`docs/spec-scoring-sprint.md`](docs/spec-scoring-sprint.md) — le moteur actuel de score à combos (`📊 Traction × ⚙️ Levier = 💥 Impact`) et les invariants à préserver lors du raccord. Le calendrier futur et les interfaces suivent le contrat du rework ; le carnet décrit ce qui est déjà jouable.
- [`landing/index.html`](landing/index.html) — une page de présentation interactive du concept : cartes retournables, jauges de ressources, aperçu d'écrans de jeu (inbox, roadmap, recrutement), présentation des époques et des fins de mandat. Toutes ses données viennent de `data/`, pas de contenu codé en dur.
- [`game/`](game/README.md) — le projet Godot 4 : un mandat complet est jouable de bout en bout (Accueil → Inbox → Roadmap → Investissements → Résolution → sprint suivant → fin de mandat), avec une vraie simulation persistante des deux monnaies et des cinq jauges et les mêmes `data/*.json` que la landing page (plus `data/balance.json`, propre au jeu), une identité visuelle propre (polices de marque, icônes, portraits, fond quadrillé, animations légères — toutes licences libres, détail dans `game/assets/THIRD_PARTY_NOTICES.md`). Pas encore équilibré (tous les nombres sont dans `data/balance.json`, ajustables sans toucher au code) — voir `game/README.md` pour le détail et les limites connues.

## Voir la landing page

La page charge ses données via `fetch()` depuis `data/`, ce qui nécessite un serveur HTTP local (les navigateurs bloquent `fetch` sur `file://`) :

```bash
cd landing
python3 -m http.server 8000
# puis ouvrir http://localhost:8000
```

(ou tout autre serveur statique équivalent : `npx serve`, l'extension Live Server de VS Code, etc.)

## Concept en une phrase

Chaque bonne pratique a un prix. Le·la joueur·se le découvre en le payant : une carte de décision (méthodologie, outil, recrutement) affiche une promesse théorique, mais son effet réel dépend du profil de l'équipe qui la reçoit, de l'époque du run, et des décisions déjà prises.

## Structure temporelle du jeu existant

| Échelle | Durée fictive | Rôle |
|---|---|---|
| **Sprint** | ~2 semaines | Unité de jeu de base — un tour complet |
| **Trimestre** | 3 sprints | Quota d'Impact et exigence du board, événement "boss" |
| **Mandat** | 4 trimestres, puis optionnellement sans limite | Le run entier, de la nomination à la sortie ou au mandat long |

## Les deux monnaies

💥 **L'Impact** — ce que le joueur produit (`Traction × Levier`), et la **seule** monnaie d'achat. 💰 **Le Revenue** — ce qui paie les salaires et les licences à chaque sprint, et qui à zéro met l'entreprise en faillite.

> Un achat coûte de l'Impact maintenant, et engage du Revenue pour toujours.

Les deux ne se remplacent jamais : on peut mourir riche d'Impact et sans caisse. Détail dans [`docs/spec-impact-monnaie.md`](docs/spec-impact-monnaie.md).

## Les cinq jauges

🫶 Moral & confiance d'équipe · 🧱 Dette organisationnelle · 🎯 Capital politique · 📈 Valeur perçue · 🎭 Cynisme

Aucune ne s'optimise seule — voir le détail des tensions entre ressources dans le [carnet de règles](docs/carnet-de-regles.md#5-tensions-entre-ressources).

## Statut du projet

MVP jouable dans `game/` : un mandat complet se joue de bout en bout jusqu'à une vraie fin. Les valeurs numériques (coûts, gains, seuils de déclenchement des fins de mandat) sont indicatives et seront ajustées en playtest — voir [`data/balance.json`](data/balance.json) et la [section 14 du carnet de règles](docs/carnet-de-regles.md#14-décisions-de-conception-du-mvp-jouable) pour le détail des décisions prises. Plusieurs questions restent ouvertes au-delà du MVP (voir la [section 13](docs/carnet-de-regles.md#13-hypothèses-et-questions-ouvertes)).
