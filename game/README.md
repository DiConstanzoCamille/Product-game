# Product Tycoon — projet Godot

Projet [Godot 4.3+](https://godotengine.org/) (GDScript). Voir [`docs/tech-stack.md`](../docs/tech-stack.md) pour le choix du moteur et [`docs/data-schema.md`](../docs/data-schema.md) pour le contenu des données consommées ici.

La boucle complète d'un sprint est jouable de bout en bout (Accueil → **choix du scénario** → **choix de l'entreprise** → Inbox → Roadmap → Investissements → Résolution → sprint suivant), avec des données réelles issues de `data/*.json`. Un mandat complet (12 sprints) se joue jusqu'à une vraie fin — faillite, exode d'équipe, IPO, etc. — les 6 ressources persistent et évoluent réellement d'un sprint à l'autre, avec un revenu récurrent selon le modèle économique du scénario. Ce n'est pas encore un jeu *équilibré* (voir `docs/carnet-de-regles.md` §14-16 pour les décisions de conception, et `data/balance.json` pour tous les nombres ajustables), mais la boucle cœur fonctionne de bout en bout.

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
│   └── shaders/grid_background*          # fond de papier réglé (lignes horizontales), clair
├── scenes/screens/
│   ├── start_screen.tscn                 # écran d'accueil — run/main_scene
│   ├── scenario_screen.tscn              # choix du scénario (1 jouable, 2 "Bientôt disponible")
│   ├── company_select_screen.tscn        # choix de l'entreprise ("offre d'emploi") — fixe le profil d'équipe
│   ├── inbox_screen.tscn                 # phase 1 — événement (pioche "sac") + choix
│   ├── roadmap_screen.tscn               # phase 2 — features & capacité
│   ├── investments_screen.tscn           # phase 3 — l'étal : candidats, pratiques et grandes décisions mélangés
│   ├── resolution_screen.tscn            # phase 4 — HUD (jauges, journal, alerte), applique les effets du sprint
│   ├── foundations_screen.tscn           # plateau des Fondations, accessible depuis la Résolution
│   └── mandate_end_screen.tscn           # fin de mandat (bonne ou mauvaise), retour à l'accueil ou nouveau mandat
├── scenes/components/
│   ├── asset_card.tscn                   # la carte d'Actif : décision, candidat ou pratique, six zones identiques
│   ├── device_frame.tscn                 # cadre d'ordinateur portable autour des écrans de choix (décoratif)
│   ├── side_panel.tscn                   # le Panneau de bord permanent (colonne droite des 3 écrans qui précèdent la Résolution)
│   └── company_panel.tscn                # overlay "Dossier entreprise" (lecture longue du contexte de la run)
├── scripts/
│   ├── autoload/
│   │   ├── game_data.gd                  # singleton : charge tous les data/*.json (+ balance.json) au démarrage
│   │   └── sprint_state.gd               # singleton : état du mandat en cours (ressources, panier d'effets, journal, fins)
│   ├── effect_resolver.gd                # classe statique : convertit les données brutes en deltas de ressources
│   ├── asset_view.gd                     # classe statique : données (cartes/candidats/pratiques) → descripteur de carte d'Actif
│   ├── ui_helpers.gd                     # polices, icônes, avatars, barres, tooltips, fade-in, hover (voir plus bas)
│   ├── components/asset_card.gd          # script de la carte d'Actif
│   ├── components/device_frame.gd        # script du cadre d'écran
│   ├── components/side_panel.gd          # script du Panneau de bord
│   ├── components/company_panel.gd       # script du "Dossier entreprise"
│   └── screens/                          # un script par écran ci-dessus
└── tests/
    ├── smoke_test_logic.gd/.tscn         # simule des mandats complets (stress/greedy/careful) sans UI
    └── smoke_test_ui.gd/.tscn            # instancie chaque écran, vérifie l'absence d'erreur au chargement
```

## Les écrans

Chaque écran a un bouton **← Accueil** (retour au menu à tout moment) et un bouton d'avancée en bas à droite qui enchaîne vers la phase suivante. Tout le contenu (textes, valeurs, cartes) est généré au runtime depuis `GameData`, rien n'est codé en dur dans les scènes.

- **Accueil** (`start_screen`) — titre, tagline, panneau de règles scrollable, Nouvelle partie (→ choix du scénario) / Quitter.
- **Scénario** (`scenario_screen`) — les 3 contextes de `eras.json` en cartes ; seuls ceux listés dans `balance.json` → `playableEras` sont cliquables (aujourd'hui : Transformation agile), les autres affichent "🔒 Bientôt disponible". Le choix stocke `SprintState.pending_era_id` et ouvre le choix d'entreprise.
- **Entreprise** (`company_select_screen`) — les entreprises de `companies.json` rattachées au scénario choisi (deux pour la Transformation agile), chacune avec sa propre accroche/description façon offre d'emploi et un profil d'équipe (junior/senior) qui sera fixé pour tout le mandat. Le choix appelle `SprintState.reset_run(era_id, company_id)` (réinitialise les 6 ressources, fixe l'entreprise, l'équipe et le modèle économique) puis ouvre l'Inbox.
- **Inbox** (`inbox_screen`) — un événement tiré par pioche "sac" (`SprintState.draw_inbox_event()`, 12 événements dont 2 propres à la Transformation agile), 3 choix ; cliquer un choix révèle son effet, l'ajoute au panier du sprint (`SprintState.add_pending`) et débloque "Suivant".
- **Roadmap** (`roadmap_screen`) — features de `roadmap-features.json` en boutons à bascule ; une barre de capacité (base + bonus de recrutement) passe au rouge et affiche un avertissement au-delà de la capacité effective. Au clic sur "Suivant", les effets des features sélectionnées (+ pénalité de surchauffe éventuelle) rejoignent le panier du sprint.
- **Investissements** (`investments_screen`) — l'écran unique de tout ce que l'organisation acquiert : **un seul rayon de 6 emplacements où les trois types se mélangent** (pas d'onglets, pas de rayons séparés — l'intérêt de la fusion est de mettre les investissements en concurrence dans le même champ de vision). Les trois servent la même **carte d'Actif** ; le nombre de colonnes est calculé sur la largeur disponible.
  - 👤 **Candidats** — embaucher coûte des pièces et ajoute une masse salariale récurrente ; 🤝 1:1 paie en Énergie la révélation d'un trait caché avant de signer.
  - ✨ **Pratiques** — permanentes pour le mandat, +2 Cynisme à l'achat.
  - 🃏 **Grandes décisions** — elles ont **deux** coûts : des pièces (`cards.json` → `costPieces`, 2 à 6 🪙 — le budget d'action, en concurrence directe avec une embauche) **et** 1 des 4 slots du mandat (la capacité d'encaissement de l'organisation). L'impact est affiché en ressources (🫶 −35, 🧱 −10…) avec la note d'axe comme texte de ligne, et non plus en axes abstraits. "Activer (4 🪙 + 1 slot)" convertit la carte en deltas réels (via `EffectResolver`, avec les multiplicateurs d'époque), la marque comme Fondation active et la sort du tirage pour de bon. Le compteur de slots vit dans le titre du rayon, le profil d'équipe dans l'en-tête du Panneau de bord.

  Ce qui est acquis (embauché, adopté, activé) est **tamponné sur place** — la carte ne bouge jamais de sa position, elle porte la marque. Toute l'offre est tirée **une fois par sprint** (`SprintState.get_shop_offer()`) — revenir sur l'écran ne re-tire pas. Le tirage est **pondéré à deux niveaux** : `typeWeights` répartit les emplacements entre types (avec un minimum garanti par type, `guaranteedPerSprint`, pour qu'aucun sprint ne soit un tour perdu), puis la **rareté** de chaque Actif (`commune`/`notable`/`rare`, poids dans `shopDraw.rarityWeights`, modulable par scénario via `eraWeights`) décide qui sort à l'intérieur du type. Pas de mémoire d'un sprint à l'autre : une carte peut revenir deux sprints de suite ou manquer six sprints. Trois leviers contre ce hasard :

  - 🎲 **Re-tirer l'offre** (bouton du bas) rejoue tout le rayon contre des pièces — sauf ce qui est punaisé : 1 🪙, puis +1 à chaque re-tirage du sprint, remis à sa base au sprint suivant.
  - 📌 **Réserver** (la punaise dans le coin d'une carte) garantit un Actif dans l'offre du sprint suivant pour 1 🪙 — et il **survit à un re-tirage**. Le bail est d'un sprint ; décoller la punaise dans le même sprint rembourse.
  - 🔒 Une carte qui déclare un `requires` reste **affichée mais inactivable** tant que sa condition est fausse, et prend un **bail d'un trimestre** (6 sprints) pendant lequel elle reste sur le rayon en plus du tirage — le temps de réunir la condition.
- **Résolution** (`resolution_screen`) — applique tout le panier d'effets accumulé pendant le sprint plus le revenu du modèle économique (`SprintState.apply_pending_and_check()`), anime chaque jauge de l'ancienne à la nouvelle valeur, affiche le revenu du sprint dans un bloc dédié (compteur animé) séparé du coût net des décisions, le journal cumulatif, une alerte sur la ressource la plus critique. Détecte les fins de mandat et route vers `mandate_end_screen` le cas échéant ; sinon "Sprint suivant" incrémente `SprintState.sprint_number` et boucle vers l'Inbox. Un bouton dédié ouvre le plateau des Fondations.
- **Fondations** (`foundations_screen`) — affiche les grandes décisions réellement activées ce mandat (état réel, pas une démo) ; message dédié si aucune n'est encore active.
- **Fin de mandat** (`mandate_end_screen`) — la fin atteinte (`endings.json`), le bilan des 6 ressources, l'époque et le profil d'équipe ; "Choisir un nouveau scénario" retourne à `scenario_screen`, "Accueil" retourne au menu.

Les 3 écrans de phase qui précèdent la Résolution (Inbox, Roadmap, Investissements) portent le **Panneau de bord** (`scenes/components/side_panel.tscn`, branché par `UIHelpers.attach_side_panel()`) : une colonne fixe à droite qui remplace l'ancienne barre de ressources horizontale. Elle affiche en continu les 6 jauges en barres (état d'après la dernière Résolution, sans preview des effets en attente ; tooltip par ressource), les pièces, le bloc « Vous » (Capital politique, Énergie), le roster condensé — un clic sur une ligne ouvre 🤝 1:1 / 🚪 Licencier —, les actifs possédés, et les conditions de la revue de board **évaluées en direct** (`SprintState.evaluate_board_objectives()`). Un clic sur « ◂ Replier » le réduit à un **rail de 62 px** qui garde les six jauges en vignette (barre + valeur, tooltips complets) et rend 260 px à l'écran de phase — sur les Investissements, une colonne de cartes entière.

Son bouton du bas ouvre le **Dossier entreprise** (`scenes/components/company_panel.tscn`) — overlay non-modal de lecture longue : contexte RP, modèle économique détaillé, objectifs commentés, roster détaillé, rallonge, Pilotage. Règle de partage : le panneau répond à « où j'en suis », le dossier à « dans quoi je joue ». La Résolution et les Fondations, qui n'ont pas de panneau, ouvrent le dossier depuis un bouton de leur barre du haut (`UIHelpers.attach_company_menu()`).

Le thème visuel (`resources/theme/main_theme.tres`) est appliqué par défaut à tout le projet (`[gui] theme/custom`) — un nouvel écran hérite des couleurs sans re-stylisation manuelle. Il est **clair** depuis le lot 1 de la refonte UI (fond `#f4f6f3`, encre `#2a2f38`, boutons « papier » à filet d'encre) : voir [`docs/proposition-ui-interface.md`](../docs/proposition-ui-interface.md) pour la direction artistique et [`docs/carnet-de-regles.md`](../docs/carnet-de-regles.md) §19 pour ce que le lot a livré.

## Habillage visuel

Tout ce qui n'est pas généré par shader vit dans `assets/`, avec les licences détaillées dans [`assets/THIRD_PARTY_NOTICES.md`](assets/THIRD_PARTY_NOTICES.md) (toutes libres d'usage commercial : OFL, ISC, CC0).

- **Polices** — Space Grotesk (titres) et IBM Plex Sans/Mono (corps, labels mono), les mêmes familles que `landing/`. Le poids des titres est piloté par code via `UIHelpers.apply_heading()` / `apply_mono()` (variation de police à la volée), pas par un thème pré-figé — un nouvel écran les récupère avec un seul appel.
- **Icônes** — set [Lucide](https://lucide.dev/) (trait, teintable via `modulate`) à la place des emoji pour les ressources, les profils d'équipe et le statut des Fondations. `UIHelpers.make_icon(nom, taille, couleur)`.
- **Avatars** — portraits [DiceBear](https://www.dicebear.com/) (style Notionists) générés une fois hors-ligne pour les personnages nommés (Priya, Sofia, Kevin...). `UIHelpers.make_person_badge(nom, taille)` affiche le portrait s'il existe, sinon une pastille d'initiale — le cas courant, et le badge d'accès de la carte candidat.
- **Icônes d'objets** — [Generic Items](https://kenney.nl/assets/generic-items) de Kenney (CC0) : une icône d'objet par Actif (calculatrice pour RICE, dossier suspendu pour Jira, presse-papiers pour Discovery…), le mapping vit dans `AssetView`. `UIHelpers.make_item_icon(index, taille)`.
- **Fond de papier réglé** — `resources/shaders/grid_background.gdshader` dessine le blanc cassé et les lignes réglées à peine visibles du tableau blanc, appliqué à tous les écrans (`vertical_rules = true` retrouve l'ancien quadrillage).
- **Animations** — `UIHelpers.fade_in()` (arrivée en fondu sur chaque écran). Le survol d'un **bouton** ne touche pas à sa géométrie : son ombre portée grossit (StyleBox `hover` du thème et de `style_primary_button()`), parce qu'un bouton large fait exactement la largeur de son conteneur et que tous les `ScrollContainer` ont `clip_contents = true` — un zoom se ferait couper sur les côtés. Le mouvement est réservé aux **objets** : une carte d'Actif est posée de travers (`UIHelpers.apply_card_placement()`) et se **redresse en se soulevant** au survol. Attention, un `Container` remet à zéro la rotation et l'échelle de ses enfants à chaque passe de layout : `asset_card.gd` se rebranche sur le signal `sort_children` du parent pour réappliquer son angle. La preview d'impact et l'impulsion animée à l'achat arrivent au lot 3 de la refonte.

Pas de dépendance/plugin externe : tout est construit avec les nœuds et l'API standard de Godot (`FontVariation`, `Tween`, `ShaderMaterial`, `TextureRect`).

## Chargement des données

`GameData` (autoload) charge chaque fichier de `data/` au démarrage : `GameData.resources`, `GameData.cards`, `GameData.eras`, `GameData.endings`, `GameData.foundations`, `GameData.roadmap_features`, `GameData.inbox_events`, `GameData.recruitment_archetypes`, `GameData.recruitment_demo`, `GameData.hud_demo`, `GameData.structure`, `GameData.companies`.

`SprintState` (autoload) porte l'état complet du mandat en cours : `sprint_number`, `team_profile`, `era_id`, `company_id` et `business_model_id` (fixés au choix du scénario + de l'entreprise), les 6 `resource_values`, le panier d'effets en attente, le journal, et les grandes décisions activées.

## Limites connues

- **Panneau "Pilotage" verrouillé** : le panneau Entreprise réserve une section pour des dashboards (burn down, répartition grands comptes / petits comptes) — l'intention est actée dans l'UI, mais aucune de ces données n'existe encore dans la simulation. Reste à concevoir avant de débloquer l'écran.
- **2 entreprises pour 1 seul scénario** : `companies.json` n'a d'entrées que pour la Transformation agile — Garage et Ère IA auront besoin des leurs quand ces scénarios s'ouvriront.
- **2 scénarios sur 3 verrouillés** : Garage (Silicon Valley) et Ère IA s'affichent en "Bientôt disponible" sur `scenario_screen` — il leur manque du contenu propre (cartes/événements tagués `eras`) et un modèle économique jouable avant de les ouvrir (`balance.json` → `playableEras`).
- **Un seul modèle économique actif** : `waterfall-release` (vente à la version, pour le scénario Garage) est déclaré dans `balance.json` mais désactivé (aucun revenu) — seul `saas-mrr` (Transformation agile) produit un vrai revenu pour l'instant.
- **Pas de pivot de business model en cours de run** : idée notée (§15 du carnet de règles) mais pas implémentée — demande au moins 2 modèles jouables pour avoir du sens.
- **Employés non persistants** : le recrutement a un effet immédiat + un bonus de capacité durable, mais il n'y a pas encore d'employé "vivant" dont le trait s'applique en continu sprint après sprint (voir §14 du carnet de règles). Les traits de `recruitment-archetypes.json` restent illustratifs.
- **Fondations sans prérequis** : le plateau affiche les grandes décisions activées, pas encore de Fondation "en attente" débloquée par une condition (le cas Shape Up de `foundations.json` reste un exemple de direction).
- **Catalogue de décisions trop court pour son tirage** : depuis que les grandes décisions sont tirées (carnet §21), la rareté ne se sent que si le catalogue dépasse largement ce qu'on en voit. Il n'y a que 6 cartes, et le rayon en propose ~2 par sprint. Le système vise 10-15 cartes — c'est du contenu à écrire, pas une mécanique à revoir : les poids se règlent dans `balance.json` sans toucher au code.
- **Une seule carte à prérequis** : `shape-up` est la seule à exercer le mécanisme `requires` + bail. Les autres types de conditions (`practice-owned`, `resource-min`…) sont implémentés et testés côté moteur, mais aucune carte ne s'en sert encore.
- **Pas de sauvegarde** : fermer le jeu perd la progression du mandat en cours — aucune persistance sur disque pour l'instant.
- **Portraits** : seuls 5 personnages ont un avatar dédié (voir `assets/THIRD_PARTY_NOTICES.md`) — les autres candidats retombent sur une icône générique, ce qui est voulu pour les profils anonymes des petites annonces mais mériterait des portraits dédiés si de nouveaux personnages nommés sont ajoutés aux données.
- **Export packagé** : `GameData` sait retomber sur un dossier `data/` placé à côté de l'exécutable quand `res://../data/` n'est pas accessible (cas d'un export `.pck`) — mais ce dossier doit être copié là manuellement au moment de la distribution, ce n'est pas encore automatisé dans le pipeline d'export.

## Tests

`game/tests/` contient deux scripts headless (aucune fenêtre requise) :

```bash
godot --headless --path game res://tests/smoke_test_logic.tscn  # simule des mandats complets, 3 profils de joueur
godot --headless --path game res://tests/smoke_test_ui.tscn     # instancie les 9 écrans + joue les gestes des Investissements
```

`smoke_test_logic` fait rejouer des mandats entiers avec trois stratégies (`stress`, `greedy`, `careful`) et vérifie que les ressources restent dans les bornes et qu'une fin est toujours atteinte. C'est le filet de sécurité à relancer après tout changement dans `EffectResolver`, `SprintState` ou `data/balance.json`.

## Prochaines étapes possibles

- Concevoir la donnée sous-jacente au panneau Pilotage (burn down, mix grands/petits comptes...) puis déverrouiller cette section.
- Pivot de business model en cours de run permet ensuite de raconter un changement de trajectoire de l'entreprise (voir plus bas).
- Ouvrir le scénario Garage (Silicon Valley) : contenu propre + entreprise(s) + modèle `waterfall-release` fonctionnel.
- Ouvrir le scénario Ère IA : contenu propre + entreprise(s) + son propre modèle économique.
- Pivot de business model en cours de run (événement Inbox rare), une fois 2 modèles jouables.
- Employés persistants avec effet continu (traits actifs sprint après sprint), au lieu du seul effet immédiat + bonus de capacité actuel.
- Fondations avec prérequis réels (méthodologie d'orga débloquée par une condition sur le plateau).
- Sauvegarde/reprise d'un mandat en cours.
- Automatiser la copie de `data/` à côté de l'exécutable dans le pipeline d'export.
- Rééquilibrage par playtest — tous les nombres sont dans `data/balance.json`, aucun n'est figé dans le code.
- Décider de la stratégie d'export (desktop prioritaire, ou aussi HTML5/Web).
