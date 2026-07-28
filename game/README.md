# Product Tycoon — projet Godot

Projet de base [Godot 4.3+](https://godotengine.org/) (GDScript). Voir [`docs/tech-stack.md`](../docs/tech-stack.md) pour le choix du moteur et [`docs/data-schema.md`](../docs/data-schema.md) pour le contenu des données consommées ici.

Ce dossier a un premier écran jouable (l'accueil), mais n'est pas encore un jeu complet : les écrans de sprint (Inbox, Roadmap, Recrutement, Fondations, HUD) décrits dans le [carnet de règles](../docs/carnet-de-regles.md) restent à construire.

## Ouvrir le projet

1. Installer [Godot 4.3 ou supérieur](https://godotengine.org/download) (édition Standard, pas .NET — le projet utilise GDScript).
2. Dans Godot, "Importer", puis sélectionner `game/project.godot`.
3. Lancer le projet (F5) — l'écran d'accueil s'affiche : titre, tagline, boutons "Nouvelle partie" / "Règles du jeu" / "Quitter".

## Structure

```
game/
├── project.godot                        # configuration du projet, autoload GameData, thème par défaut
├── icon.svg
├── resources/
│   └── theme/main_theme.tres             # thème partagé (couleurs de marque : navy-deep, ambre...)
├── scenes/
│   └── screens/
│       ├── start_screen.tscn             # écran d'accueil — run/main_scene
│       └── placeholder_sprint.tscn       # écran de transition ("Nouvelle partie"), à remplacer par l'Inbox
└── scripts/
    ├── autoload/
    │   └── game_data.gd                  # singleton : charge tous les data/*.json au démarrage
    └── screens/
        ├── start_screen.gd
        └── placeholder_sprint.gd
```

## Écran d'accueil

`start_screen.tscn` est le point d'entrée (`run/main_scene`). Il affiche le titre, la tagline du concept, et trois actions :

- **Nouvelle partie** — mène à `placeholder_sprint.tscn`, un écran de transition qui confirme que les données sont chargées et sert de point d'ancrage pour le premier vrai écran de sprint (l'Inbox, à construire).
- **Règles du jeu** — ouvre un panneau scrollable avec un résumé condensé du concept et de la boucle de sprint. Le texte est écrit en dur dans `start_screen.gd` (`_populate_rules_text`) : c'est un raccourci pour l'écran-titre, pas une source de vérité — en cas de désaccord, le [carnet de règles](../docs/carnet-de-regles.md) fait foi.
- **Quitter** — ferme l'application.

Le thème visuel (`resources/theme/main_theme.tres`) reprend la palette de la landing page (navy-deep en fond, ambre pour les accents, texte clair) et s'applique par défaut à tout le projet (`[gui] theme/custom` dans `project.godot`) — les prochains écrans en hériteront automatiquement, pas besoin de re-styliser bouton par bouton.

**Limite connue** : aucune police de marque n'est encore embarquée (IBM Plex / Space Grotesk utilisées sur la landing page) — l'écran utilise la police par défaut de Godot. À bundler plus tard si la fidélité visuelle avec la landing page devient importante.

## Chargement des données

`GameData` (autoload, disponible partout via `GameData.xxx`) charge chaque fichier de `data/` au démarrage et expose son contenu parsé : `GameData.resources`, `GameData.cards`, `GameData.eras`, `GameData.endings`, `GameData.foundations`, `GameData.roadmap_features`, `GameData.inbox_events`, `GameData.recruitment_archetypes`, `GameData.recruitment_demo`, `GameData.hud_demo`, `GameData.structure`.

**Limite connue** : le chemin utilisé (`res://../data/`) fonctionne depuis l'éditeur et en build debug non empaqueté, mais pas depuis un export packagé (.pck) — Godot n'inclut pas les fichiers hors de `res://` dans un export. Avant de packager une build distribuable, il faudra soit copier `data/` dans `res://data/` au moment du build, soit charger les JSON depuis un chemin à côté de l'exécutable. Non résolu pour l'instant — voir les questions ouvertes dans `docs/tech-stack.md`.

## Prochaines étapes possibles

- Construire les scènes des 5 phases de sprint (`docs/data-schema.md` → `structure.json` → `sprintPhases`) : Inbox, Roadmap, Grandes décisions, Recrutement, Résolution.
- Décider de la stratégie d'export (desktop prioritaire, ou aussi HTML5/Web) avant de complexifier l'architecture des scènes.
- Résoudre le chargement des données pour un export packagé (voir ci-dessus).
