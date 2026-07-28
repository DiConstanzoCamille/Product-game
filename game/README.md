# Product Tycoon — projet Godot

Projet [Godot 4.3+](https://godotengine.org/) (GDScript). Voir [`docs/tech-stack.md`](../docs/tech-stack.md) pour le choix du moteur et [`docs/data-schema.md`](../docs/data-schema.md) pour le contenu des données consommées ici.

La boucle complète d'un sprint est jouable de bout en bout (Accueil → Inbox → Roadmap → Grandes décisions → Recrutement → Résolution → sprint suivant), avec des données réelles issues de `data/*.json`. Ce n'est pas encore un jeu équilibré : aucune ressource ne s'accumule réellement d'un sprint à l'autre (voir "Limites connues" plus bas) — c'est un squelette d'écrans navigable, pas la simulation finale.

## Ouvrir le projet

1. Installer [Godot 4.3 ou supérieur](https://godotengine.org/download) (édition Standard, pas .NET — le projet utilise GDScript).
2. Dans Godot, "Importer", puis sélectionner `game/project.godot`.
3. Lancer le projet (F5) — l'écran d'accueil s'affiche. Cliquer "Nouvelle partie" pour parcourir un sprint complet.

## Structure

```
game/
├── project.godot                        # config du projet, autoloads, thème par défaut
├── icon.svg
├── resources/
│   └── theme/main_theme.tres             # thème partagé (couleurs de marque : navy-deep, ambre...)
├── scenes/screens/
│   ├── start_screen.tscn                 # écran d'accueil — run/main_scene
│   ├── inbox_screen.tscn                 # phase 1 — événement + choix
│   ├── roadmap_screen.tscn               # phase 2 — features & capacité
│   ├── decisions_screen.tscn             # phase 3 — cartes structurelles (RICE, Notion, Jira)
│   ├── recruitment_screen.tscn           # phase 4 — shop (habillage par époque)
│   ├── resolution_screen.tscn            # phase 5 — HUD (jauges, journal, alerte)
│   └── foundations_screen.tscn           # plateau des Fondations, accessible depuis la Résolution
└── scripts/
    ├── autoload/
    │   ├── game_data.gd                  # singleton : charge tous les data/*.json au démarrage
    │   └── sprint_state.gd               # singleton léger : n° de sprint, profil d'équipe courant
    ├── ui_helpers.gd                     # styles de barres de progression, couleurs d'état partagés
    └── screens/                          # un script par écran ci-dessus
```

## Les écrans

Chaque écran a un bouton **← Accueil** (retour au menu à tout moment) et un bouton d'avancée en bas à droite qui enchaîne vers la phase suivante. Tout le contenu (textes, valeurs, cartes) est généré au runtime depuis `GameData`, rien n'est codé en dur dans les scènes.

- **Accueil** (`start_screen`) — titre, tagline, panneau de règles scrollable, Nouvelle partie / Quitter.
- **Inbox** (`inbox_screen`) — un événement de `inbox_events.json` (actuellement un seul, tiré par index de sprint), 3 choix ; cliquer un choix révèle son effet et débloque "Suivant".
- **Roadmap** (`roadmap_screen`) — features de `roadmap-features.json` en boutons à bascule ; une barre de capacité passe au rouge et affiche un avertissement au-delà de `capacityMax`.
- **Grandes décisions** (`decisions_screen`) — les 3 cartes de `cards.json`, toggle Junior/Senior (radio via `ButtonGroup`) qui recalibre les 4 axes de chaque carte en direct ; "Voir l'effet" bascule tagline ↔ détail des axes.
- **Recrutement** (`recruitment_screen`) — habillages de `recruitment-demo.json` (candidats vs petites annonces), bouton d'action qui se désactive après clic.
- **Résolution** (`resolution_screen`) — jauges colorées par état (bon/attention/danger), journal du sprint, alerte, depuis `hud-demo.json`. "Sprint suivant" incrémente `SprintState.sprint_number` et boucle vers l'Inbox. Un bouton dédié ouvre le plateau des Fondations.
- **Fondations** (`foundations_screen`) — le plateau de `foundations.json` (statut en attente / actif), pas un compte à rebours.

Le thème visuel (`resources/theme/main_theme.tres`) est appliqué par défaut à tout le projet (`[gui] theme/custom`) — un nouvel écran hérite des couleurs de marque sans re-stylisation manuelle.

## Chargement des données

`GameData` (autoload) charge chaque fichier de `data/` au démarrage : `GameData.resources`, `GameData.cards`, `GameData.eras`, `GameData.endings`, `GameData.foundations`, `GameData.roadmap_features`, `GameData.inbox_events`, `GameData.recruitment_archetypes`, `GameData.recruitment_demo`, `GameData.hud_demo`, `GameData.structure`.

`SprintState` (autoload) porte l'état minimal partagé entre écrans : `sprint_number` (incrémenté à chaque boucle complète) et `team_profile` (choisi sur l'écran Grandes décisions).

## Limites connues

- **Pas de simulation persistante** : les choix faits sur un écran (feature sélectionnée, carte activée, employé recruté) ne modifient pas encore les ressources ni ne persistent au sprint suivant — chaque écran affiche les mêmes données d'exemple à chaque passage. Calculer et faire persister les 6 ressources (§4 du carnet de règles) à travers la boucle est la prochaine étape naturelle côté logique de jeu.
- **Export packagé** : le chemin de chargement des données (`res://../data/`) fonctionne depuis l'éditeur et en lancement debug, mais pas depuis un export `.pck` — à résoudre avant de distribuer une build (copier `data/` dans `res://data/` au moment du build, ou charger depuis un chemin à côté de l'exécutable).
- **Polices** : aucune police de marque embarquée (IBM Plex / Space Grotesk utilisées sur la landing page) — police par défaut de Godot pour l'instant.
- **Un seul événement Inbox** dans `data/inbox-events.json` — le code gère déjà un nombre arbitraire d'événements (tirage par index de sprint), il suffira d'en ajouter dans le JSON.

## Prochaines étapes possibles

- Faire persister et évoluer les 6 ressources à travers la boucle de sprint (le vrai cœur du jeu, cf. §4 et §11 du carnet de règles — modèle d'effet unifié).
- Ajouter des événements Inbox et des features Roadmap supplémentaires dans `data/`.
- Résoudre le chargement des données pour un export packagé (voir ci-dessus).
- Décider de la stratégie d'export (desktop prioritaire, ou aussi HTML5/Web).
