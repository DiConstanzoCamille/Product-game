# Product Tycoon — projet Godot

Projet [Godot 4.3+](https://godotengine.org/) (GDScript). Voir [`docs/tech-stack.md`](../docs/tech-stack.md) pour le choix du moteur et [`docs/data-schema.md`](../docs/data-schema.md) pour le contenu des données consommées ici.

La boucle complète d'un sprint est jouable de bout en bout (Accueil → Inbox → Roadmap → Grandes décisions → Recrutement → Résolution → sprint suivant), avec des données réelles issues de `data/*.json`. Un mandat complet (12 sprints) se joue jusqu'à une vraie fin — faillite, exode d'équipe, IPO, etc. — les 6 ressources persistent et évoluent réellement d'un sprint à l'autre. Ce n'est pas encore un jeu *équilibré* (voir `docs/carnet-de-regles.md` §14 pour les décisions de conception du MVP, et `data/balance.json` pour tous les nombres ajustables), mais la boucle cœur fonctionne de bout en bout.

## Ouvrir le projet

1. Installer [Godot 4.3 ou supérieur](https://godotengine.org/download) (édition Standard, pas .NET — le projet utilise GDScript).
2. Dans Godot, "Importer", puis sélectionner `game/project.godot`.
3. Lancer le projet (F5) — l'écran d'accueil s'affiche. Cliquer "Nouvelle partie" pour parcourir un sprint complet.

**Première ouverture** : Godot doit importer les polices avant de pouvoir charger le thème qui les référence. Si le premier lancement affiche des erreurs `Parse Error` sur `main_theme.tres`, c'est cet ordre d'import qui n'a pas encore eu lieu — rouvrez simplement le projet une seconde fois (ou relancez F5), l'erreur ne se reproduit pas ensuite.

## Structure

```
game/
├── project.godot                        # config du projet, autoloads, thème par défaut
├── icon.svg
├── assets/
│   ├── THIRD_PARTY_NOTICES.md            # licences de tout ce qui suit
│   ├── fonts/                            # Space Grotesk, IBM Plex Sans/Mono (OFL)
│   ├── icons/                            # set Lucide, trait blanc teintable (ISC)
│   └── avatars/                          # portraits DiceBear générés localement (CC0)
├── resources/
│   ├── theme/main_theme.tres             # thème partagé (couleurs de marque : navy-deep, ambre...)
│   └── shaders/grid_background*          # fond quadrillé façon landing page
├── scenes/screens/
│   ├── start_screen.tscn                 # écran d'accueil — run/main_scene
│   ├── inbox_screen.tscn                 # phase 1 — événement + choix
│   ├── roadmap_screen.tscn               # phase 2 — features & capacité
│   ├── decisions_screen.tscn             # phase 3 — cartes structurelles (RICE, Notion, Jira)
│   ├── recruitment_screen.tscn           # phase 4 — shop (habillage par époque)
│   ├── resolution_screen.tscn            # phase 5 — HUD (jauges, journal, alerte), applique les effets du sprint
│   ├── foundations_screen.tscn           # plateau des Fondations, accessible depuis la Résolution
│   └── mandate_end_screen.tscn           # fin de mandat (bonne ou mauvaise), retour à l'accueil ou nouveau mandat
├── scripts/
│   ├── autoload/
│   │   ├── game_data.gd                  # singleton : charge tous les data/*.json (+ balance.json) au démarrage
│   │   └── sprint_state.gd               # singleton : état du mandat en cours (ressources, panier d'effets, journal, fins)
│   ├── effect_resolver.gd                # classe statique : convertit les données brutes en deltas de ressources
│   ├── ui_helpers.gd                     # polices, icônes, avatars, barres, fade-in, hover (voir plus bas)
│   └── screens/                          # un script par écran ci-dessus
└── tests/
    ├── smoke_test_logic.gd/.tscn         # simule des mandats complets (stress/greedy/careful) sans UI
    └── smoke_test_ui.gd/.tscn            # instancie chaque écran, vérifie l'absence d'erreur au chargement
```

## Les écrans

Chaque écran a un bouton **← Accueil** (retour au menu à tout moment) et un bouton d'avancée en bas à droite qui enchaîne vers la phase suivante. Tout le contenu (textes, valeurs, cartes) est généré au runtime depuis `GameData`, rien n'est codé en dur dans les scènes.

- **Accueil** (`start_screen`) — titre, tagline, panneau de règles scrollable, Nouvelle partie (appelle `SprintState.reset_run()` : tire une époque, réinitialise les 6 ressources) / Quitter.
- **Inbox** (`inbox_screen`) — un événement de `inbox_events.json` (5 disponibles, tiré par index de sprint), 3 choix ; cliquer un choix révèle son effet, l'ajoute au panier du sprint (`SprintState.add_pending`) et débloque "Suivant".
- **Roadmap** (`roadmap_screen`) — features de `roadmap-features.json` en boutons à bascule ; une barre de capacité (base + bonus de recrutement) passe au rouge et affiche un avertissement au-delà de la capacité effective. Au clic sur "Suivant", les effets des features sélectionnées (+ pénalité de surchauffe éventuelle) rejoignent le panier du sprint.
- **Grandes décisions** (`decisions_screen`) — les 3 cartes de `cards.json`, toggle Junior/Senior qui recalibre les 4 axes en direct ; "Voir l'effet" bascule tagline ↔ détail des axes ; "Activer cette grande décision" convertit la carte en deltas réels (via `EffectResolver`, avec les multiplicateurs d'époque) et la marque comme Fondation active, jusqu'à la limite du mandat.
- **Recrutement** (`recruitment_screen`) — habillages de `recruitment-demo.json` (candidats vs petites annonces) ; embaucher coûte de la trésorerie, produit un effet immédiat et augmente durablement la capacité de roadmap (`SprintState.capacity_bonus`).
- **Résolution** (`resolution_screen`) — applique tout le panier d'effets accumulé pendant le sprint (`SprintState.apply_pending_and_check()`), affiche les 6 jauges réelles (état bon/attention/danger, delta du sprint), le journal cumulatif, une alerte sur la ressource la plus critique. Détecte les fins de mandat et route vers `mandate_end_screen` le cas échéant ; sinon "Sprint suivant" incrémente `SprintState.sprint_number` et boucle vers l'Inbox. Un bouton dédié ouvre le plateau des Fondations.
- **Fondations** (`foundations_screen`) — affiche les grandes décisions réellement activées ce mandat (état réel, pas une démo) ; message dédié si aucune n'est encore active.
- **Fin de mandat** (`mandate_end_screen`) — la fin atteinte (`endings.json`), le bilan des 6 ressources, l'époque et le profil d'équipe ; "Nouveau mandat" relance directement (`reset_run()` + Inbox), "Accueil" retourne au menu.

Le thème visuel (`resources/theme/main_theme.tres`) est appliqué par défaut à tout le projet (`[gui] theme/custom`) — un nouvel écran hérite des couleurs de marque sans re-stylisation manuelle.

## Habillage visuel

Tout ce qui n'est pas généré par shader vit dans `assets/`, avec les licences détaillées dans [`assets/THIRD_PARTY_NOTICES.md`](assets/THIRD_PARTY_NOTICES.md) (toutes libres d'usage commercial : OFL, ISC, CC0).

- **Polices** — Space Grotesk (titres) et IBM Plex Sans/Mono (corps, labels mono), les mêmes familles que `landing/`. Le poids des titres est piloté par code via `UIHelpers.apply_heading()` / `apply_mono()` (variation de police à la volée), pas par un thème pré-figé — un nouvel écran les récupère avec un seul appel.
- **Icônes** — set [Lucide](https://lucide.dev/) (trait, teintable via `modulate`) à la place des emoji pour les ressources, les profils d'équipe et le statut des Fondations. `UIHelpers.make_icon(nom, taille, couleur)`.
- **Avatars** — portraits [DiceBear](https://www.dicebear.com/) (style Notionists) générés une fois hors-ligne pour les personnages nommés (Priya, Sofia, Kevin...), affichés sur l'Inbox et le Recrutement. `UIHelpers.make_avatar(seed, taille)` retombe sur une icône générique si aucun portrait ne correspond au nom (ex. les candidats des petites annonces, anonymes par nature).
- **Fond quadrillé** — `resources/shaders/grid_background.gdshader` reproduit en shader le fond à grille de `landing/css/style.css`, appliqué à tous les écrans.
- **Animations** — `UIHelpers.fade_in()` (arrivée en fondu sur chaque écran), `UIHelpers.add_hover_bounce()` (léger zoom au survol des boutons), et un flip `scale.x` sur les cartes de Grandes décisions qui fait écho au retournement de carte de la landing page.

Pas de dépendance/plugin externe : tout est construit avec les nœuds et l'API standard de Godot (`FontVariation`, `Tween`, `ShaderMaterial`, `TextureRect`).

## Chargement des données

`GameData` (autoload) charge chaque fichier de `data/` au démarrage : `GameData.resources`, `GameData.cards`, `GameData.eras`, `GameData.endings`, `GameData.foundations`, `GameData.roadmap_features`, `GameData.inbox_events`, `GameData.recruitment_archetypes`, `GameData.recruitment_demo`, `GameData.hud_demo`, `GameData.structure`.

`SprintState` (autoload) porte l'état minimal partagé entre écrans : `sprint_number` (incrémenté à chaque boucle complète) et `team_profile` (choisi sur l'écran Grandes décisions).

## Limites connues

- **Employés non persistants** : le recrutement a un effet immédiat + un bonus de capacité durable, mais il n'y a pas encore d'employé "vivant" dont le trait s'applique en continu sprint après sprint (voir §14 du carnet de règles). Les traits de `recruitment-archetypes.json` restent illustratifs.
- **Fondations sans prérequis** : le plateau affiche les grandes décisions activées, pas encore de Fondation "en attente" débloquée par une condition (le cas Shape Up de `foundations.json` reste un exemple de direction).
- **Pas de sauvegarde** : fermer le jeu perd la progression du mandat en cours — aucune persistance sur disque pour l'instant.
- **Portraits** : seuls 5 personnages ont un avatar dédié (voir `assets/THIRD_PARTY_NOTICES.md`) — les autres candidats retombent sur une icône générique, ce qui est voulu pour les profils anonymes des petites annonces mais mériterait des portraits dédiés si de nouveaux personnages nommés sont ajoutés aux données.
- **Export packagé** : `GameData` sait retomber sur un dossier `data/` placé à côté de l'exécutable quand `res://../data/` n'est pas accessible (cas d'un export `.pck`) — mais ce dossier doit être copié là manuellement au moment de la distribution, ce n'est pas encore automatisé dans le pipeline d'export.

## Tests

`game/tests/` contient deux scripts headless (aucune fenêtre requise) :

```bash
godot --headless --path game res://tests/smoke_test_logic.tscn  # simule des mandats complets, 3 profils de joueur
godot --headless --path game res://tests/smoke_test_ui.tscn     # instancie chaque écran, détecte les erreurs de chargement
```

`smoke_test_logic` fait rejouer des mandats entiers avec trois stratégies (`stress`, `greedy`, `careful`) et vérifie que les ressources restent dans les bornes et qu'une fin est toujours atteinte. C'est le filet de sécurité à relancer après tout changement dans `EffectResolver`, `SprintState` ou `data/balance.json`.

## Prochaines étapes possibles

- Employés persistants avec effet continu (traits actifs sprint après sprint), au lieu du seul effet immédiat + bonus de capacité actuel.
- Fondations avec prérequis réels (méthodologie d'orga débloquée par une condition sur le plateau).
- Sauvegarde/reprise d'un mandat en cours.
- Automatiser la copie de `data/` à côté de l'exécutable dans le pipeline d'export.
- Rééquilibrage par playtest — tous les nombres sont dans `data/balance.json`, aucun n'est figé dans le code.
- Décider de la stratégie d'export (desktop prioritaire, ou aussi HTML5/Web).
