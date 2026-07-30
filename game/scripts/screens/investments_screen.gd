extends Control
## Phase 3 — Investissements (docs/proposition-ui-interface.md §3 ; carnet de
## règles §6.2, §17). L'écran unique de tout ce que l'organisation acquiert,
## en **deux rayons empilés dans un seul scroll** :
##
##   📦 L'étal du sprint — le périssable : 2 candidats (trait caché tiré à
##      l'apparition, révélé si Entretiens structurés) + 2 pratiques non
##      possédées, tirés une fois par sprint et stockés dans SprintState —
##      revenir sur l'écran ne re-tire pas.
##   🃏 Les grandes décisions — le catalogue permanent, activées reléguées en
##      fin de rayon, compteur de slots dans le titre.
##
## Pas d'onglets : tout l'intérêt de la fusion est de mettre les
## investissements en concurrence dans le même champ de vision (« cette pièce,
## je la garde pour Lina ou je prends Discovery ? — ou est-ce que ce sprint est
## celui où j'active Jira ? »). Les grandes décisions n'étant activées que 3-4
## fois par mandat, leur écran plein n'était qu'un péage à cliquer 8 à 9
## sprints sur 12.
##
## Les deux rayons servent le **même** composant, la carte d'Actif
## (scenes/components/asset_card.tscn) : seuls la couleur de pastille et le
## contenu des zones changent. Le coût, l'effectif, l'Énergie et le profil
## d'équipe ne sont pas affichés ici mais en continu dans le Panneau de bord.

const NEXT_SCENE := "res://scenes/screens/resolution_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

## Largeur de gouttière des deux grilles (doit suivre le `h_separation` de la
## scène) et plafond de colonnes : au-delà, les rayons deviennent des murs.
const GRID_SEPARATION := 14
const MAX_COLUMNS := 4

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var scroll: ScrollContainer = $Margin/VBox/Scroll
@onready var shop_head: VBoxContainer = $Margin/VBox/Scroll/Pad/Shelves/ShopHead
@onready var shop_grid: GridContainer = $Margin/VBox/Scroll/Pad/Shelves/ShopGrid
@onready var decisions_head: VBoxContainer = $Margin/VBox/Scroll/Pad/Shelves/DecisionsHead
@onready var decisions_grid: GridContainer = $Margin/VBox/Scroll/Pad/Shelves/DecisionsGrid
@onready var reroll_button: Button = $Margin/VBox/BottomBar/RerollButton
@onready var next_button: Button = $Margin/VBox/BottomBar/NextButton

var offer: Dictionary = {}
var side_panel: Control = null

# Chaque entrée garde son `placement` (angle, décalage du scotch) : une carte
# qui change de rang dans son rayon reste le même objet posé sur le tableau.
var _shop_cards: Array = []       # [{node: AssetCard, kind: "candidate"|"practice", data, placement}]
var _decision_cards: Array = []   # [{node: AssetCard, data: Dictionary, placement: int}]


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(func(): get_tree().change_scene_to_file(NEXT_SCENE))
	UIHelpers.style_primary_button(next_button)
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 3 : Investissements" % SprintState.sprint_number

	side_panel = UIHelpers.attach_side_panel(self)
	# Un 1:1, un licenciement ou une embauche faits depuis le panneau changent ce
	# que les cartes affichent (Énergie, effectif, traits révélés) et le profil
	# d'effet des décisions — mais le panneau, lui, s'est déjà rafraîchi : on ne
	# relit que les rayons.
	side_panel.state_changed.connect(_refresh_shelves)

	reroll_button.pressed.connect(_on_reroll_pressed)

	offer = SprintState.get_shop_offer()
	_build_shop_shelf()
	_build_decisions_shelf()
	_refresh_shop_head()
	_refresh_decisions_head()
	_refresh_reroll_button()

	# Le nombre de colonnes suit la largeur disponible, et il est **commun aux
	# deux rayons** pour qu'ils s'alignent. Sans ça, une grille à nombre de
	# colonnes fixe impose sa largeur minimale et sort une barre de défilement
	# horizontale dès que le Panneau de bord a pris sa place.
	scroll.resized.connect(_fit_columns)
	_fit_columns()


# ── 📦 L'étal du sprint ───────────────────────────────────────────────────
func _build_shop_shelf() -> void:
	for candidate in offer.get("candidates", []):
		var card := _add_shop_card("candidate", candidate)
		card.primary_pressed.connect(_on_hire_pressed.bind(candidate))
		card.secondary_pressed.connect(_on_one_on_one_pressed.bind(candidate))
	for practice_id in offer.get("practices", []):
		var practice: Dictionary = SprintState.find_practice(practice_id)
		var card := _add_shop_card("practice", practice)
		card.primary_pressed.connect(_on_buy_practice_pressed.bind(practice))

	if _shop_cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "L'étal est vide ce sprint — le marché des talents a aussi ses pénuries."
		empty_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
		shop_grid.add_child(empty_label)


func _add_shop_card(kind: String, data: Dictionary) -> AssetCard:
	var placement := _shop_cards.size()
	var card := AssetCard.create(_shop_descriptor(kind, data, placement))
	shop_grid.add_child(card)
	_shop_cards.append({"node": card, "kind": kind, "data": data, "placement": placement})
	return card


func _shop_descriptor(kind: String, data: Dictionary, placement: int) -> Dictionary:
	var descriptor: Dictionary = AssetView.for_candidate(data) if kind == "candidate" else AssetView.for_practice(data)
	return UIHelpers.apply_card_placement(descriptor, placement)


func _refresh_shop_head() -> void:
	for child in shop_head.get_children():
		child.free()

	var subtitle := "tiré une fois par sprint — revenir sur l'écran ne re-tire pas"
	if int(offer.get("rerolls", 0)) > 0:
		subtitle = "re-tiré %d fois ce sprint" % int(offer.get("rerolls", 0))
	if SprintState.next_hire_discount > 0:
		subtitle += " · réseau : −%d 🪙 sur la prochaine embauche" % SprintState.next_hire_discount
	shop_head.add_child(UIHelpers.make_shelf_head("📦 L'étal du sprint", subtitle))


# ── 🃏 Les grandes décisions ──────────────────────────────────────────────
func _build_decisions_shelf() -> void:
	# Le décalage de placement continue celui de l'étal : deux cartes voisines de
	# part et d'autre de la frontière des rayons ne prennent pas le même angle.
	var placement := _shop_cards.size()
	for card_id in offer.get("decisions", []):
		var card: Dictionary = SprintState.find_card(card_id)
		if card.is_empty():
			continue
		var asset_card := AssetCard.create(
			UIHelpers.apply_card_placement(AssetView.for_decision(card), placement)
		)
		asset_card.primary_pressed.connect(_on_card_activate.bind(card))
		decisions_grid.add_child(asset_card)
		_decision_cards.append({"node": asset_card, "data": card, "placement": placement})
		placement += 1

	if _decision_cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Aucune grande décision proposée ce sprint — le catalogue est épuisé pour ce mandat."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
		decisions_grid.add_child(empty_label)


## Une carte activée pendant le sprint reste sur l'étal jusqu'à la fin du tour
## (elle disparaît du sac, donc des sprints suivants), mais passe en fin de
## rayon : le rayon met en avant ce qu'il reste à décider.
func _reorder_decisions() -> void:
	var pending: Array = []
	var activated: Array = []
	for entry in _decision_cards:
		if SprintState.activated_cards.has(entry["data"].get("id", "")):
			activated.append(entry)
		else:
			pending.append(entry)

	_decision_cards = pending + activated
	for rank in _decision_cards.size():
		decisions_grid.move_child(_decision_cards[rank]["node"], rank)


## Le compteur de slots vit dans le titre du rayon (et une seconde fois dans la
## section Actifs du Panneau de bord — proposition UI §3.3). Le profil d'équipe,
## lui, a migré dans l'en-tête du panneau : c'est un trait de la run, pas de la
## phase.
func _refresh_decisions_head() -> void:
	for child in decisions_head.get_children():
		child.free()

	var used: int = SprintState.activated_cards.size()
	var maximum := int(GameData.balance.get("structuralDecisionMaxActivations", 4))
	var left := maximum - used
	var subtitle := ""
	if left <= 0:
		subtitle = "%d/%d activées — plus de slot ce mandat, le reste du catalogue est là pour vous narguer" % [used, maximum]
	else:
		subtitle = "%d activée%s · %d slot%s restant%s sur %d — tirées pour ce sprint, rien ne garantit de les revoir · effets calibrés pour votre %s" % [
			used, "s" if used > 1 else "",
			left, "s" if left > 1 else "", "s" if left > 1 else "", maximum,
			_team_profile_label(),
		]
	decisions_head.add_child(UIHelpers.make_shelf_head("🃏 Les grandes décisions", subtitle))


func _team_profile_label() -> String:
	for profile in GameData.cards.get("teamProfiles", []):
		if profile.get("id", "") == SprintState.team_profile:
			return profile.get("shortLabel", SprintState.team_profile)
	return SprintState.team_profile


# ── 🎲 Re-tirer l'offre ───────────────────────────────────────────────────
## Le prix monte à chaque re-tirage du sprint : le premier coup d'œil de plus
## est presque gratuit, s'acharner ne l'est pas. Il re-tire les **deux** rayons
## d'un coup — c'est l'offre du sprint qu'on rejoue, pas un rayon qu'on trie,
## et perdre un bon candidat pour voir une autre décision fait partie du pari.
func _on_reroll_pressed() -> void:
	if SprintState.reroll_shop_offer() != "":
		return
	offer = SprintState.get_shop_offer()
	_rebuild_shelves()
	_refresh_all()


func _rebuild_shelves() -> void:
	for grid in [shop_grid, decisions_grid]:
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
	_shop_cards.clear()
	_decision_cards.clear()

	_build_shop_shelf()
	_build_decisions_shelf()


func _refresh_reroll_button() -> void:
	var cost := SprintState.shop_reroll_cost()
	reroll_button.text = "🎲 Re-tirer l'offre — %d 🪙" % cost
	reroll_button.disabled = SprintState.pieces < cost
	reroll_button.tooltip_text = "Re-tire les deux rayons. Le prix monte à chaque re-tirage du sprint (le prochain coûtera %d 🪙) et repart à %d au sprint suivant.\nVous avez %d 🪙." % [
		cost + int(GameData.balance.get("shopDraw", {}).get("reroll", {}).get("costIncrement", 1)),
		int(GameData.balance.get("shopDraw", {}).get("reroll", {}).get("baseCost", 1)),
		SprintState.pieces,
	]


# ── Rafraîchissements ─────────────────────────────────────────────────────
## Un achat change l'état de *tout* l'écran : les pièces baissent pour les deux
## rayons, l'effectif monte, Entretiens structurés révèle les candidats déjà sur
## l'étal, un licenciement change le profil d'effet des décisions.
func _refresh_shelves() -> void:
	for entry in _shop_cards:
		entry["node"].set_descriptor(_shop_descriptor(entry["kind"], entry["data"], entry["placement"]))
	for entry in _decision_cards:
		entry["node"].set_descriptor(
			UIHelpers.apply_card_placement(AssetView.for_decision(entry["data"]), entry["placement"])
		)
	_reorder_decisions()
	_refresh_shop_head()
	_refresh_decisions_head()
	_refresh_reroll_button()


func _refresh_all() -> void:
	_refresh_shelves()
	if side_panel != null:
		side_panel.refresh()


func _fit_columns() -> void:
	# Marges du Pad (16 + 16) et gouttière laissée à la barre de défilement
	# verticale, qui mord sur la largeur utile du ScrollContainer.
	var usable := scroll.size.x - 32.0 - 14.0
	var columns := int(floor((usable + GRID_SEPARATION) / float(AssetCard.MIN_WIDTH + GRID_SEPARATION)))
	columns = clampi(columns, 1, MAX_COLUMNS)
	shop_grid.columns = columns
	decisions_grid.columns = columns


# ── Gestes ────────────────────────────────────────────────────────────────
func _on_hire_pressed(candidate: Dictionary) -> void:
	SprintState.hire_candidate(candidate)
	_refresh_all()


func _on_one_on_one_pressed(candidate: Dictionary) -> void:
	SprintState.do_one_on_one(candidate)
	_refresh_all()


func _on_buy_practice_pressed(practice: Dictionary) -> void:
	SprintState.buy_practice(practice.get("id", ""))
	_refresh_all()


func _on_card_activate(card: Dictionary) -> void:
	var card_id: String = card.get("id", "")
	if SprintState.activated_cards.has(card_id):
		return
	if SprintState.activated_cards.size() >= int(GameData.balance.get("structuralDecisionMaxActivations", 4)):
		return

	var deltas := EffectResolver.resolve_card_activation(card_id, SprintState.team_profile, SprintState.era_id)
	SprintState.add_pending(deltas, "Grande décision : %s activée (%s)" % [
		card.get("name", card_id), SprintState.team_profile
	])
	SprintState.activated_cards.append(card_id)
	SprintState.activated_card_sprints[card_id] = SprintState.sprint_number

	_refresh_all()
