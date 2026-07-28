# Product Tycoon — projet Godot

Projet de base [Godot 4.3+](https://godotengine.org/) (GDScript). Voir [`docs/tech-stack.md`](../docs/tech-stack.md) pour le choix du moteur et [`docs/data-schema.md`](../docs/data-schema.md) pour le contenu des données consommées ici.

Ce dossier est un squelette de départ, pas un jeu jouable : il valide que le chargement des données fonctionne et sert de point d'ancrage pour construire les écrans (Inbox, Roadmap, Recrutement, Fondations, HUD) décrits dans le [carnet de règles](../docs/carnet-de-regles.md).

## Ouvrir le projet

1. Installer [Godot 4.3 ou supérieur](https://godotengine.org/download) (édition Standard, pas .NET — le projet utilise GDScript).
2. Dans Godot, "Importer", puis sélectionner `game/project.godot`.
3. Lancer la scène principale (F5) — un écran minimal affiche le nombre de ressources/cartes/époques/fins de mandat chargées depuis `data/`, ce qui confirme que le pont JSON → Godot fonctionne.

## Structure

```
game/
├── project.godot            # configuration du projet, déclare l'autoload GameData
├── icon.svg
├── scenes/
│   └── Main.tscn             # écran de démarrage minimal
└── scripts/
    ├── main.gd                # logique de Main.tscn
    └── autoload/
        └── game_data.gd       # singleton : charge tous les data/*.json au démarrage
```

## Chargement des données

`GameData` (autoload, disponible partout via `GameData.xxx`) charge chaque fichier de `data/` au démarrage et expose son contenu parsé : `GameData.resources`, `GameData.cards`, `GameData.eras`, `GameData.endings`, `GameData.foundations`, `GameData.roadmap_features`, `GameData.inbox_events`, `GameData.recruitment_archetypes`, `GameData.recruitment_demo`, `GameData.hud_demo`, `GameData.structure`.

**Limite connue** : le chemin utilisé (`res://../data/`) fonctionne depuis l'éditeur et en build debug non empaqueté, mais pas depuis un export packagé (.pck) — Godot n'inclut pas les fichiers hors de `res://` dans un export. Avant de packager une build distribuable, il faudra soit copier `data/` dans `res://data/` au moment du build, soit charger les JSON depuis un chemin à côté de l'exécutable. Non résolu pour l'instant — voir les questions ouvertes dans `docs/tech-stack.md`.

## Prochaines étapes possibles

- Construire les scènes des 5 phases de sprint (`docs/data-schema.md` → `structure.json` → `sprintPhases`) : Inbox, Roadmap, Grandes décisions, Recrutement, Résolution.
- Décider de la stratégie d'export (desktop prioritaire, ou aussi HTML5/Web) avant de complexifier l'architecture des scènes.
- Résoudre le chargement des données pour un export packagé (voir ci-dessus).
