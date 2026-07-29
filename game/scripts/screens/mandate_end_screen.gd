extends Control
## Écran de fin de mandat — atteint quand SprintState.apply_pending_and_check()
## (appelé en Résolution) détecte un seuil de ressource franchi, ou que le
## mandat a atteint sa longueur (data/balance.json → mandateLengthSprints).

const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"
const INBOX_SCENE := "res://scenes/screens/inbox_screen.tscn"

const GOOD_ENDINGS := ["ipo", "rachat"]

@onready var eyebrow_label: Label = $CenterContainer/VBox/Eyebrow
@onready var ending_label: Label = $CenterContainer/VBox/EndingLabel
@onready var note_label: Label = $CenterContainer/VBox/NoteLabel
@onready var summary_grid: GridContainer = $CenterContainer/VBox/SummaryGrid
@onready var meta_label: Label = $CenterContainer/VBox/MetaLabel
@onready var replay_button: Button = $CenterContainer/VBox/Buttons/ReplayButton
@onready var home_button: Button = $CenterContainer/VBox/Buttons/HomeButton


func _ready() -> void:
	replay_button.pressed.connect(_on_replay_pressed)
	home_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	UIHelpers.add_hover_bounce(replay_button)
	UIHelpers.add_hover_bounce(home_button)
	UIHelpers.apply_mono(eyebrow_label, 13, true)
	UIHelpers.apply_heading(ending_label, 40, 700.0)
	UIHelpers.fade_in(self)

	_load_ending()


func _load_ending() -> void:
	var ending := _find_ending(SprintState.ending_id)
	var is_good: bool = SprintState.ending_id in GOOD_ENDINGS

	eyebrow_label.text = "FIN DE MANDAT — SPRINT %d" % SprintState.sprint_number
	ending_label.text = "%s %s" % [ending.get("icon", ""), ending.get("label", "")]
	ending_label.add_theme_color_override(
		"font_color", UIHelpers.COLOR_GOOD if is_good else UIHelpers.COLOR_DANGER
	)
	note_label.text = ending.get("note", "")

	for resource in GameData.resources:
		summary_grid.add_child(_build_summary_row(resource))

	var era: Dictionary = SprintState.get_era()
	meta_label.text = "Époque : %s %s · Profil d'équipe : %s" % [
		era.get("icon", ""), era.get("name", ""), SprintState.team_profile.capitalize()
	]


func _build_summary_row(resource: Dictionary) -> Control:
	var resource_id: String = resource.get("id", "")
	var value: float = SprintState.resource_values.get(resource_id, 0.0)
	var state := EffectResolver.gauge_state(resource_id, value)

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(240, 0)
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "%s %s" % [resource.get("icon", ""), resource.get("name", "")]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value_label := Label.new()
	value_label.text = "%d%%" % int(round(value))
	value_label.add_theme_color_override("font_color", UIHelpers.state_color(state))
	row.add_child(value_label)

	return row


func _find_ending(ending_id: String) -> Dictionary:
	for ending in GameData.endings:
		if ending.get("id", "") == ending_id:
			return ending
	return {}


func _on_replay_pressed() -> void:
	SprintState.reset_run()
	get_tree().change_scene_to_file(INBOX_SCENE)
