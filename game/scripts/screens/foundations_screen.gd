extends Control
## Plateau des Fondations (docs/carnet-de-regles.md §7) : effets persistants,
## pas un compte à rebours — soit une décision est déjà active, soit elle
## attend une condition précise. Accessible depuis l'écran de Résolution.

const RESOLUTION_SCENE := "res://scenes/screens/resolution_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var home_button: Button = $Margin/VBox/TopBar/HomeButton
@onready var board_grid: GridContainer = $Margin/VBox/Scroll/BoardGrid


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(RESOLUTION_SCENE))
	home_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	_load_board()


func _load_board() -> void:
	var data: Dictionary = GameData.foundations
	var families: Array = data.get("families", [])

	for foundation in data.get("demoBoard", []):
		board_grid.add_child(_build_foundation_card(foundation, families))


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

	var status_label := Label.new()
	if is_waiting:
		status_label.text = "🕐 En attente"
		status_label.add_theme_color_override("font_color", UIHelpers.COLOR_WARN)
	else:
		status_label.text = "✅ Actif depuis le sprint %d" % foundation.get("activeSinceSprint", 0)
		status_label.add_theme_color_override("font_color", UIHelpers.COLOR_GOOD)
	vbox.add_child(status_label)

	var family_label := Label.new()
	family_label.text = _family_label(foundation.get("family", ""), families)
	family_label.add_theme_font_size_override("font_size", 11)
	family_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	vbox.add_child(family_label)

	var name_label := Label.new()
	name_label.text = foundation.get("name", "")
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	var detail_label := Label.new()
	detail_label.text = foundation.get("detail", "")
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(detail_label)

	return panel
