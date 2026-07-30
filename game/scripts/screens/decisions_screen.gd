extends Control
## Phase 3 — Grandes décisions (docs/carnet-de-regles.md §6.2, §16). Rayon
## permanent de cartes structurelles. L'effet réel dépend du profil d'équipe —
## fixé pour tout le mandat par l'entreprise choisie au départ.
##
## Depuis la refonte UI (docs/proposition-ui-interface.md), l'écran ne dessine
## plus ses cartes lui-même : il produit un descripteur par AssetView et laisse
## la carte d'Actif (scenes/components/asset_card.tscn) l'afficher — même
## anatomie que les candidats et les pratiques, et **impact exprimé en
## ressources** (🫶 −35, 🧱 +10…) et non plus en axes abstraits. Le badge de
## profil d'équipe a migré dans l'en-tête du Panneau de bord : c'est un trait de
## la run, pas de la phase.

const NEXT_SCENE := "res://scenes/screens/recruitment_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var shelf_head: VBoxContainer = $Margin/VBox/ShelfHead
@onready var cards_grid: GridContainer = $Margin/VBox/Scroll/CardsGrid
@onready var next_button: Button = $Margin/VBox/BottomBar/NextButton

var available_cards: Array = []  # cartes de GameData.cards filtrées par scénario en cours
var side_panel: Control = null

var _cards: Array = []  # [{node: AssetCard, data: Dictionary}]


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(func(): get_tree().change_scene_to_file(NEXT_SCENE))
	UIHelpers.add_hover_bounce(back_button)
	UIHelpers.add_hover_bounce(next_button)
	UIHelpers.style_primary_button(next_button)
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 3 : Grandes décisions" % SprintState.sprint_number

	side_panel = UIHelpers.attach_side_panel(self)
	# Un licenciement depuis le panneau change le profil d'effet des cartes :
	# elles se relisent, mais c'est le panneau qui s'est déjà rafraîchi.
	side_panel.state_changed.connect(_refresh_cards)

	for card in GameData.cards.get("cards", []):
		var eras: Array = card.get("eras", [])
		if eras.is_empty() or eras.has(SprintState.era_id):
			available_cards.append(card)

	_build_cards()
	_refresh_shelf_head()


func _build_cards() -> void:
	var index := 0
	for card in available_cards:
		var descriptor := AssetView.for_decision(card)
		descriptor["tilt"] = UIHelpers.card_tilt(index)
		var asset_card := AssetCard.create(descriptor)
		asset_card.primary_pressed.connect(_on_card_activate.bind(card))
		cards_grid.add_child(asset_card)
		_cards.append({"node": asset_card, "data": card})
		index += 1


func _refresh_cards() -> void:
	var index := 0
	for entry in _cards:
		var descriptor := AssetView.for_decision(entry["data"])
		descriptor["tilt"] = UIHelpers.card_tilt(index)
		entry["node"].set_descriptor(descriptor)
		index += 1
	_refresh_shelf_head()


func _refresh_all() -> void:
	_refresh_cards()
	if side_panel != null:
		side_panel.refresh()


## Le compteur de slots vit dans le titre du rayon (et une seconde fois dans la
## section Actifs du Panneau de bord — proposition UI §3.3).
func _refresh_shelf_head() -> void:
	for child in shelf_head.get_children():
		child.free()

	var used: int = SprintState.activated_cards.size()
	var maximum := int(GameData.balance.get("structuralDecisionMaxActivations", 4))
	var subtitle := "%d activée%s · %d slot%s restant%s sur %d — effets calibrés pour votre %s" % [
		used, "s" if used > 1 else "",
		maximum - used, "s" if maximum - used > 1 else "", "s" if maximum - used > 1 else "",
		maximum, _team_profile_label(),
	]
	shelf_head.add_child(UIHelpers.make_shelf_head("🃏 Les grandes décisions", subtitle))


func _team_profile_label() -> String:
	for profile in GameData.cards.get("teamProfiles", []):
		if profile.get("id", "") == SprintState.team_profile:
			return profile.get("shortLabel", SprintState.team_profile)
	return SprintState.team_profile


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
