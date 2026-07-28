extends Control
## Phase 5 — Résolution (docs/carnet-de-regles.md §3). Les effets du sprint
## s'appliquent, le delta s'affiche. HUD d'exemple depuis data/hud-demo.json.
## "Sprint suivant" boucle vers l'Inbox — pas encore de calcul persistant
## des ressources d'un sprint à l'autre (voir docs/tech-stack.md).

const INBOX_SCENE := "res://scenes/screens/inbox_screen.tscn"
const FOUNDATIONS_SCENE := "res://scenes/screens/foundations_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var era_label: Label = $Margin/VBox/Scroll/Content/HeaderRow/EraLabel
@onready var cpo_label: Label = $Margin/VBox/Scroll/Content/HeaderRow/CpoLabel
@onready var gauges_grid: GridContainer = $Margin/VBox/Scroll/Content/GaugesGrid
@onready var journal_title: Label = $Margin/VBox/Scroll/Content/JournalTitle
@onready var journal_container: VBoxContainer = $Margin/VBox/Scroll/Content/JournalContainer
@onready var alert_label: Label = $Margin/VBox/Scroll/Content/AlertLabel
@onready var foundations_button: Button = $Margin/VBox/BottomBar/FoundationsButton
@onready var next_sprint_button: Button = $Margin/VBox/BottomBar/NextSprintButton


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	foundations_button.pressed.connect(func(): get_tree().change_scene_to_file(FOUNDATIONS_SCENE))
	next_sprint_button.pressed.connect(_on_next_sprint_pressed)

	sprint_label.text = "Sprint %d — Phase 5 : Résolution" % SprintState.sprint_number
	_load_hud()


func _load_hud() -> void:
	var hud: Dictionary = GameData.hud_demo

	era_label.text = hud.get("era", "")
	cpo_label.text = "CPO : %s" % hud.get("cpo", "")

	for gauge in hud.get("gauges", []):
		gauges_grid.add_child(_build_gauge(gauge))

	journal_title.text = "Journal du sprint"
	for entry in hud.get("journal", []):
		var entry_label := Label.new()
		entry_label.text = "Sprint %d — %s\n%s" % [
			entry.get("sprint", 0), entry.get("text", ""), entry.get("deltas", "")
		]
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		entry_label.add_theme_font_size_override("font_size", 13)
		journal_container.add_child(entry_label)

	alert_label.text = hud.get("alert", "")


func _build_gauge(gauge: Dictionary) -> Control:
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(230, 0)
	vbox.add_theme_constant_override("separation", 4)

	var top := HBoxContainer.new()
	vbox.add_child(top)

	var label := Label.new()
	label.text = gauge.get("label", "")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(label)

	var value_label := Label.new()
	value_label.text = gauge.get("display", "")
	value_label.add_theme_color_override("font_color", UIHelpers.state_color(gauge.get("state", "warn")))
	top.add_child(value_label)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 8)
	bar.max_value = 100
	bar.value = gauge.get("percent", 0)
	bar.show_percentage = false
	bar.add_theme_stylebox_override(
		"fill", UIHelpers.make_bar_fill_style(UIHelpers.state_color(gauge.get("state", "warn")))
	)
	bar.add_theme_stylebox_override("background", UIHelpers.make_bar_background_style())
	vbox.add_child(bar)

	return vbox


func _on_next_sprint_pressed() -> void:
	SprintState.sprint_number += 1
	get_tree().change_scene_to_file(INBOX_SCENE)
