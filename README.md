# Product Tycoon

> Un roguelike où vous incarnez le·la CPO fraîchement nommé·e d'une organisation que vous n'avez pas construite. Contexte tiré au sort, équipe héritée, décisions rarement réversibles. Chaque bonne pratique promet une amélioration théorique — son effet réel dépend de qui la reçoit.

Ce dépôt rassemble les documents de conception du jeu. **C'est un document de travail** : rien n'est encore équilibré ni final, l'objectif est de garder une base de réflexion partagée sur le concept et le gameplay.

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
│   ├── endings.json                 # les 8 fins de mandat
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
    ├── resources/theme/main_theme.tres  # thème partagé (couleurs de marque)
    ├── scenes/screens/
    │   ├── start_screen.tscn         # écran d'accueil — run/main_scene
    │   └── placeholder_sprint.tscn   # écran de transition ("Nouvelle partie")
    └── scripts/
        ├── autoload/game_data.gd    # charge tous les data/*.json au démarrage
        └── screens/                 # logique des écrans (start_screen.gd, ...)
```

- [`docs/carnet-de-regles.md`](docs/carnet-de-regles.md) — le carnet de règles complet : structure temporelle, ressources, système de cartes, effets persistants, roadmap, recrutement, époques, fins de mandat, et les questions ouvertes encore à trancher.
- [`docs/data-schema.md`](docs/data-schema.md) — le détail du schéma de chaque fichier JSON.
- [`docs/tech-stack.md`](docs/tech-stack.md) — le choix du moteur de jeu (Godot 4) et les alternatives écartées (Three.js, Unity, Unreal, stack web).
- [`landing/index.html`](landing/index.html) — une page de présentation interactive du concept : cartes retournables, jauges de ressources, aperçu d'écrans de jeu (inbox, roadmap, recrutement), présentation des époques et des fins de mandat. Toutes ses données viennent de `data/`, pas de contenu codé en dur.
- [`game/`](game/README.md) — le projet Godot 4 : un autoload `GameData` charge les mêmes `data/*.json` que la landing page, et un écran d'accueil (titre, règles, nouvelle partie) est en place. Les écrans de sprint restent à construire — voir `game/README.md` pour les prochaines étapes.

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

## Structure temporelle

| Échelle | Durée fictive | Rôle |
|---|---|---|
| **Sprint** | ~2 semaines | Unité de jeu de base — un tour complet |
| **Trimestre** | ~6 sprints | Point de contrôle : revue de board, événement "boss" |
| **Mandat** | Variable | Le run entier, de la nomination à la sortie |

## Les six ressources

💰 Trésorerie · 🫶 Moral & confiance d'équipe · 🧱 Dette organisationnelle · 🎯 Capital politique · 📈 Valeur perçue · 🎭 Cynisme

Aucune ne s'optimise seule — voir le détail des tensions entre ressources dans le [carnet de règles](docs/carnet-de-regles.md#5-tensions-entre-ressources).

## Statut du projet

Phase de conception. Les valeurs numériques (coûts, gains, seuils de déclenchement des fins de mandat) sont indicatives et seront ajustées en playtest. Plusieurs questions restent ouvertes (voir la [section 13 du carnet de règles](docs/carnet-de-regles.md#13-hypothèses-et-questions-ouvertes)).
