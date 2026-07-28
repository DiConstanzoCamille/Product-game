# Product Tycoon — projet Godot

Projet [Godot 4.3+](https://godotengine.org/) (GDScript). Voir [`docs/tech-stack.md`](../docs/tech-stack.md) pour le choix du moteur et [`docs/data-schema.md`](../docs/data-schema.md) pour le contenu des données consommées ici.

La boucle complète d'un sprint est jouable de bout en bout (Accueil → Inbox → Roadmap → Grandes décisions → Recrutement → Résolution → sprint suivant), avec des données réelles issues de `data/*.json`. Ce n'est pas encore un jeu équilibré : aucune ressource ne s'accumule réellement d'un sprint à l'autre (voir "Limites connues" plus bas) — c'est un squelette d'écrans navigable, pas la simulation finale.

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
│   ├── resolution_screen.tscn            # phase 5 — HUD (jauges, journal, alerte)
│   └── foundations_screen.tscn           # plateau des Fondations, accessible depuis la Résolution
└── scripts/
    ├── autoload/
    │   ├── game_data.gd                  # singleton : charge tous les data/*.json au démarrage
    │   └── sprint_state.gd               # singleton léger : n° de sprint, profil d'équipe courant
    ├── ui_helpers.gd                     # polices, icônes, avatars, barres, fade-in, hover (voir plus bas)
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

- **Pas de simulation persistante** : les choix faits sur un écran (feature sélectionnée, carte activée, employé recruté) ne modifient pas encore les ressources ni ne persistent au sprint suivant — chaque écran affiche les mêmes données d'exemple à chaque passage. Calculer et faire persister les 6 ressources (§4 du carnet de règles) à travers la boucle est la prochaine étape naturelle côté logique de jeu.
- **Export packagé** : le chemin de chargement des données (`res://../data/`) fonctionne depuis l'éditeur et en lancement debug, mais pas depuis un export `.pck` — à résoudre avant de distribuer une build (copier `data/` dans `res://data/` au moment du build, ou charger depuis un chemin à côté de l'exécutable).
- **Un seul événement Inbox** dans `data/inbox-events.json` — le code gère déjà un nombre arbitraire d'événements (tirage par index de sprint), il suffira d'en ajouter dans le JSON.
- **Portraits** : seuls 5 personnages ont un avatar dédié (voir `assets/THIRD_PARTY_NOTICES.md`) — les autres candidats retombent sur une icône générique, ce qui est voulu pour les profils anonymes des petites annonces mais mériterait des portraits dédiés si de nouveaux personnages nommés sont ajoutés aux données.

## Prochaines étapes possibles

- Faire persister et évoluer les 6 ressources à travers la boucle de sprint (le vrai cœur du jeu, cf. §4 et §11 du carnet de règles — modèle d'effet unifié).
- Ajouter des événements Inbox et des features Roadmap supplémentaires dans `data/`.
- Résoudre le chargement des données pour un export packagé (voir ci-dessus).
- Décider de la stratégie d'export (desktop prioritaire, ou aussi HTML5/Web).
