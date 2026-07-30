extends Control
## Phase 2 — Roadmap (docs/carnet-de-regles.md §3, §8 ; spec profondeur §4.2,
## §6.2). Les features coûtent des points de capacité ; la capacité est
## produite par le roster (Devs, PM). Dépasser la capacité = surchauffe
## (data/balance.json → roadmap.overCapacityPenalty), modulée par les PM.
## Les quick wins rapportent des pièces à la livraison.

const NEXT_SCENE := "res://scenes/screens/decisions_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var capacity_label: Label = $Margin/VBox/CapacityRow/CapacityLabel
@onready var capacity_bar: ProgressBar = $Margin/VBox/CapacityBar
@onready var warning_label: Label = $Margin/VBox/WarningLabel
@onready var feature_grid: GridContainer = $Margin/VBox/Scroll/FeatureGrid
@onready var next_button: Button = $Margin/VBox/BottomBar/NextButton

var effective_capacity: int = 0
var feature_buttons: Array[Button] = []


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(_on_next_pressed)
	UIHelpers.add_hover_bounce(back_button)
	UIHelpers.add_hover_bounce(next_button)
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 2 : Roadmap" % SprintState.sprint_number

	var bar := UIHelpers.build_resource_bar()
	$Margin/VBox.add_child(bar)
	$Margin/VBox.move_child(bar, 1)
	UIHelpers.attach_company_menu(self)

	capacity_bar.add_theme_stylebox_override("fill", UIHelpers.make_bar_fill_style(UIHelpers.COLOR_GOOD))
	capacity_bar.add_theme_stylebox_override("background", UIHelpers.make_bar_background_style())

	_load_features()
	_update_capacity()


func _load_features() -> void:
	var data: Dictionary = GameData.roadmap_features
	var cost_points: Dictionary = GameData.balance.get("roadmap", {}).get("featureCostPoints", {})
	var quick_wins: Dictionary = GameData.balance.get("roadmap", {}).get("quickWinPieces", {})
	effective_capacity = SprintState.get_effective_capacity()
	capacity_bar.max_value = max(effective_capacity, 1)

	for feature in data.get("features", []):
		var feature_id: String = feature.get("id", "")
		var points := int(cost_points.get(feature_id, 1))
		var quick_win := int(quick_wins.get(feature_id, 0))

		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_pressed = feature.get("selectedByDefault", false)
		btn.custom_minimum_size = Vector2(220, 120)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.set_meta("feature_id", feature_id)
		btn.set_meta("feature_name", feature.get("name", ""))
		btn.set_meta("cost_points", points)
		var quick_win_text := "  ·  ⚡ quick win 🪙+%d" % quick_win if quick_win > 0 else ""
		btn.text = "%s — %d pt%s%s\n\n%s\n\n%s" % [
			feature.get("name", ""),
			points, "s" if points > 1 else "",
			quick_win_text,
			feature.get("promise", ""),
			" ".join(feature.get("icons", [])),
		]
		btn.pressed.connect(_update_capacity)
		UIHelpers.add_hover_bounce(btn, 1.02)
		feature_grid.add_child(btn)
		feature_buttons.append(btn)


func _selected_points() -> int:
	var total := 0
	for btn in feature_buttons:
		if btn.button_pressed:
			total += int(btn.get_meta("cost_points"))
	return total


func _update_capacity() -> void:
	var selected := _selected_points()
	capacity_label.text = "Panier : %d pts / %d produits par l'équipe" % [selected, effective_capacity]
	capacity_bar.value = min(selected, capacity_bar.max_value)

	var over := selected > effective_capacity
	warning_label.visible = over
	capacity_bar.add_theme_stylebox_override(
		"fill",
		UIHelpers.make_bar_fill_style(UIHelpers.COLOR_DANGER if over else UIHelpers.COLOR_GOOD)
	)


func _on_next_pressed() -> void:
	var selected_ids: Array = []
	var selected_names: Array = []
	for btn in feature_buttons:
		if btn.button_pressed:
			selected_ids.append(btn.get_meta("feature_id"))
			selected_names.append(btn.get_meta("feature_name"))

	var deltas := EffectResolver.resolve_roadmap(selected_ids, effective_capacity, SprintState.get_roster_context())
	var note := "Roadmap : %s" % (", ".join(selected_names) if not selected_names.is_empty() else "aucune feature retenue")
	SprintState.add_pending(deltas, note)
	SprintState.delivered_feature_ids = selected_ids.duplicate()

	get_tree().change_scene_to_file(NEXT_SCENE)
