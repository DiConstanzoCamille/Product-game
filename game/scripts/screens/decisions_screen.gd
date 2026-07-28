extends Control
## Phase 3 — Grandes décisions (docs/carnet-de-regles.md §6.2). Menu permanent
## de cartes structurelles (RICE, Notion, Jira). L'effet réel dépend du
## profil d'équipe — bascule Junior/Senior pour recalibrer.

const NEXT_SCENE := "res://scenes/screens/recruitment_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var junior_button: Button = $Margin/VBox/TeamToggle/JuniorButton
@onready var senior_button: Button = $Margin/VBox/TeamToggle/SeniorButton
@onready var cards_grid: GridContainer = $Margin/VBox/Scroll/CardsGrid
@onready var next_button: Button = $Margin/VBox/BottomBar/NextButton

var team_group := ButtonGroup.new()
# card_id -> {"axis_rows": {axis_id -> {"value": Label, "note": Label}}, "tagline": Label, "axes_box": VBoxContainer, "toggle_btn": Button}
var card_refs: Dictionary = {}


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(func(): get_tree().change_scene_to_file(NEXT_SCENE))
	UIHelpers.add_hover_bounce(back_button)
	UIHelpers.add_hover_bounce(next_button)
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 3 : Grandes décisions" % SprintState.sprint_number

	junior_button.toggle_mode = true
	senior_button.toggle_mode = true
	junior_button.button_group = team_group
	senior_button.button_group = team_group
	junior_button.button_pressed = SprintState.team_profile == "junior"
	senior_button.button_pressed = SprintState.team_profile == "senior"
	junior_button.pressed.connect(_on_team_selected.bind("junior"))
	senior_button.pressed.connect(_on_team_selected.bind("senior"))
	junior_button.icon = UIHelpers.icon_texture("sprout")
	senior_button.icon = UIHelpers.icon_texture("landmark")
	junior_button.add_theme_constant_override("icon_max_width", 18)
	senior_button.add_theme_constant_override("icon_max_width", 18)
	UIHelpers.add_hover_bounce(junior_button, 1.02)
	UIHelpers.add_hover_bounce(senior_button, 1.02)

	_build_cards()
	_refresh_cards()


func _build_cards() -> void:
	var axes: Array = GameData.cards.get("axes", [])

	for card in GameData.cards.get("cards", []):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(280, 0)
		cards_grid.add_child(panel)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		panel.add_child(vbox)

		var category_label := Label.new()
		category_label.text = card.get("category", "")
		category_label.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
		UIHelpers.apply_mono(category_label, 11, true)
		vbox.add_child(category_label)

		var name_label := Label.new()
		name_label.text = card.get("name", "")
		UIHelpers.apply_heading(name_label, 21, 600.0)
		vbox.add_child(name_label)

		var tagline_label := Label.new()
		tagline_label.text = card.get("tagline", "")
		tagline_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(tagline_label)

		var axes_box := VBoxContainer.new()
		axes_box.visible = false
		axes_box.add_theme_constant_override("separation", 10)
		vbox.add_child(axes_box)

		var axis_rows: Dictionary = {}
		for axis in axes:
			var axis_id: String = axis.get("id", "")
			var row := HBoxContainer.new()
			axes_box.add_child(row)

			var axis_label := Label.new()
			axis_label.text = axis.get("label", "")
			axis_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(axis_label)

			var value_label := Label.new()
			row.add_child(value_label)

			var note_label := Label.new()
			note_label.add_theme_font_size_override("font_size", 11)
			note_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
			note_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			axes_box.add_child(note_label)

			axis_rows[axis_id] = {"value": value_label, "note": note_label}

		var toggle_btn := Button.new()
		toggle_btn.text = "Voir l'effet →"
		vbox.add_child(toggle_btn)
		toggle_btn.pressed.connect(_on_card_toggle.bind(card.get("id", "")))

		UIHelpers.add_hover_bounce(toggle_btn, 1.02)

		card_refs[card.get("id", "")] = {
			"panel": panel,
			"axis_rows": axis_rows,
			"tagline": tagline_label,
			"axes_box": axes_box,
			"toggle_btn": toggle_btn,
			"flipping": false,
		}


## Petit effet de "retournement" (scale.x 1 → 0 → 1) au moment où le contenu
## bascule tagline ↔ détail des axes — écho au flip 3D de la landing page.
func _on_card_toggle(card_id: String) -> void:
	var refs: Dictionary = card_refs[card_id]
	if refs.flipping:
		return
	refs.flipping = true

	var panel: PanelContainer = refs.panel
	panel.pivot_offset = panel.size / 2.0

	var tween := panel.create_tween()
	tween.tween_property(panel, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		var showing_axes: bool = refs.axes_box.visible
		refs.axes_box.visible = not showing_axes
		refs.tagline.visible = showing_axes
		refs.toggle_btn.text = "← Voir la carte" if not showing_axes else "Voir l'effet →"
	)
	tween.tween_property(panel, "scale:x", 1.0, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): refs.flipping = false)


func _on_team_selected(team: String) -> void:
	SprintState.team_profile = team
	_refresh_cards()


func _refresh_cards() -> void:
	for card in GameData.cards.get("cards", []):
		var card_id: String = card.get("id", "")
		var effects: Dictionary = card.get("effects", {}).get(SprintState.team_profile, {})
		var refs: Dictionary = card_refs[card_id]

		for axis_id in refs.axis_rows.keys():
			var d: Dictionary = effects.get(axis_id, {})
			var value: int = d.get("value", 0)
			var is_positive := value >= 0
			var value_label: Label = refs.axis_rows[axis_id].value
			value_label.text = "%s%d" % ["+" if is_positive else "−", abs(value)]
			value_label.add_theme_color_override(
				"font_color", UIHelpers.COLOR_GOOD if is_positive else UIHelpers.COLOR_DANGER
			)
			refs.axis_rows[axis_id].note.text = d.get("note", "")
