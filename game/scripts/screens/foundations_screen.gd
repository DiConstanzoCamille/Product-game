extends Control
## Plateau des Fondations (docs/carnet-de-regles.md §7) : effets persistants,
## pas un compte à rebours — soit une décision est déjà active, soit elle
## attend une condition précise. Accessible depuis l'écran de Résolution.
##
## Affiche l'état réel du mandat en cours (SprintState.activated_cards),
## pas les données de démo — une grande décision activée en phase 3 devient
## une Fondation active ici. MVP : pas encore de Fondation "en attente"
## avec prérequis (voir docs/carnet-de-regles.md §14, limites connues).

const RESOLUTION_SCENE := "res://scenes/screens/resolution_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var home_button: Button = $Margin/VBox/TopBar/HomeButton
@onready var title_label: Label = $Margin/VBox/Title
@onready var board_grid: GridContainer = $Margin/VBox/Scroll/BoardGrid


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(RESOLUTION_SCENE))
	home_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	UIHelpers.add_hover_bounce(back_button)
	UIHelpers.add_hover_bounce(home_button)
	UIHelpers.apply_heading(title_label, 22, 600.0)
	UIHelpers.attach_company_menu(self)
	UIHelpers.fade_in(self)
	_load_board()


func _load_board() -> void:
	var families: Array = GameData.foundations.get("families", [])

	if SprintState.activated_cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Aucune fondation active pour l'instant — activez une grande décision en phase 3 pour qu'elle apparaisse ici."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_label.custom_minimum_size = Vector2(520, 0)
		empty_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
		board_grid.add_child(empty_label)
		return

	for card_id in SprintState.activated_cards:
		var card := _find_card(card_id)
		if card.is_empty():
			continue
		var foundation := {
			"status": "active",
			"activeSinceSprint": SprintState.activated_card_sprints.get(card_id, 0),
			"family": card.get("family", ""),
			"name": card.get("name", ""),
			"detail": card.get("tagline", ""),
		}
		board_grid.add_child(_build_foundation_card(foundation, families))


func _find_card(card_id: String) -> Dictionary:
	for card in GameData.cards.get("cards", []):
		if card.get("id", "") == card_id:
			return card
	return {}


func _family_label(family_id: String, families: Array) -> String:
	for family in families:
		if family.get("id", "") == family_id:
			return family.get("label", family_id)
	return family_id


func _build_foundation_card(foundation: Dictionary, families: Array) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var is_waiting: bool = foundation.get("status", "") == "waiting"
	var status_color := UIHelpers.COLOR_WARN if is_waiting else UIHelpers.COLOR_GOOD

	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 6)
	vbox.add_child(status_row)
	status_row.add_child(UIHelpers.make_icon("clock" if is_waiting else "circle-check", 15, status_color))

	var status_label := Label.new()
	if is_waiting:
		status_label.text = "En attente"
	else:
		status_label.text = "Actif depuis le sprint %d" % foundation.get("activeSinceSprint", 0)
	status_label.add_theme_color_override("font_color", status_color)
	UIHelpers.apply_mono(status_label, 11, true)
	status_row.add_child(status_label)

	var family_label := Label.new()
	family_label.text = _family_label(foundation.get("family", ""), families)
	family_label.add_theme_font_size_override("font_size", 11)
	family_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	vbox.add_child(family_label)

	var name_label := Label.new()
	name_label.text = foundation.get("name", "")
	UIHelpers.apply_heading(name_label, 17, 600.0)
	vbox.add_child(name_label)

	var detail_label := Label.new()
	detail_label.text = foundation.get("detail", "")
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(detail_label)

	return panel
