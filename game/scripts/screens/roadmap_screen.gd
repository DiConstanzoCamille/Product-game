extends Control
## Vue de la Roadmap profonde (§6). Les règles vivent dans SprintState : cet
## écran affiche le tirage persistant et lui remet seulement un plan de points.

const NEXT_SCENE := "res://scenes/screens/investments_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var capacity_label: Label = $Margin/VBox/CapacityRow/CapacityLabel
@onready var capacity_bar: ProgressBar = $Margin/VBox/CapacityBar
@onready var warning_label: Label = $Margin/VBox/WarningLabel
@onready var feature_grid: GridContainer = $Margin/VBox/Scroll/FeatureGrid
@onready var next_button: Button = $Margin/VBox/BottomBar/NextButton

var effective_capacity: int = 0
var backlog_controls: Array = []
var side_panel: Control = null
var self_work_button: Button = null


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(_on_next_pressed)
	UIHelpers.style_primary_button(next_button)
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)
	sprint_label.text = "Sprint %d — Phase 2 : Roadmap" % SprintState.sprint_number

	side_panel = UIHelpers.attach_side_panel(self)
	side_panel.state_changed.connect(_on_roster_changed)
	capacity_bar.add_theme_stylebox_override("fill", UIHelpers.make_bar_fill_style(UIHelpers.COLOR_GOOD))
	capacity_bar.add_theme_stylebox_override("background", UIHelpers.make_bar_background_style())
	_setup_self_work_button()
	_load_backlog()
	_update_capacity()


func _load_backlog() -> void:
	var offer := SprintState.get_backlog_offer()
	effective_capacity = SprintState.get_effective_capacity()
	capacity_bar.max_value = max(effective_capacity, 1)
	for item in offer.get("items", []):
		_add_backlog_card(item)


func _add_backlog_card(item: Dictionary) -> void:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(250, 190)
	card.add_theme_constant_override("separation", 6)
	feature_grid.add_child(card)

	var title := Label.new()
	title.text = "%s %s" % [item.get("icon", "📌"), item.get("name", "")]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	UIHelpers.apply_heading(title, 16, 600.0)
	card.add_child(title)

	var description := Label.new()
	description.text = item.get("description", "")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD
	description.add_theme_font_size_override("font_size", 12)
	card.add_child(description)

	var attributes := Label.new()
	attributes.autowrap_mode = TextServer.AUTOWRAP_WORD
	attributes.add_theme_font_size_override("font_size", 13)
	attributes.text = _attribute_text(item)
	card.add_child(attributes)

	var dive := Button.new()
	dive.pressed.connect(func():
		if SprintState.do_feature_dive(item.get("id", "")) == "":
			attributes.text = _attribute_text(item)
			_refresh_action_buttons()
	)
	card.add_child(dive)

	var control: Dictionary = {"item": item, "dive": dive}
	if SprintState.is_backlog_epic(item):
		var remaining := SprintState.get_epic_remaining(item.get("id", ""))
		var progress := Label.new()
		var started_at := SprintState.get_epic_started_sprint(item.get("id", ""))
		if started_at > 0:
			progress.text = "En cours depuis %d sprints — reste %d points" % [SprintState.sprint_number - started_at, remaining]
		else:
			progress.text = "Epic : %d points au total" % int(item.get("costPoints", 0))
		card.add_child(progress)
		var spend := SpinBox.new()
		spend.min_value = 0
		spend.max_value = remaining
		spend.step = 1
		spend.prefix = "Investir "
		spend.suffix = " pts"
		spend.value_changed.connect(func(_value): _update_capacity())
		card.add_child(spend)
		control["spend"] = spend
		if started_at > 0:
			var abandon := Button.new()
			abandon.text = "Abandonner l'epic"
			abandon.tooltip_text = "Les points déjà investis sont perdus; l'epic pourra revenir plus tard."
			abandon.pressed.connect(func():
				if SprintState.abandon_epic(item.get("id", "")) == "":
					backlog_controls.erase(control)
					card.queue_free()
					_update_capacity()
			)
			card.add_child(abandon)
	else:
		var select := CheckButton.new()
		select.text = "Livrer — %d pts" % int(item.get("costPoints", 0))
		select.toggled.connect(func(_pressed): _update_capacity())
		card.add_child(select)
		control["select"] = select
	backlog_controls.append(control)
	_refresh_action_button(control)


func _attribute_text(item: Dictionary) -> String:
	var item_id: String = item.get("id", "")
	return "ROI : %s\nImpact client : %s\nRisque dette : %s" % [
		_attribute_value(item_id, "roi", "+%d MRR/sprint" % int(item.get("roi", 0))),
		_attribute_value(item_id, "clientImpact", "%+d Valeur percue" % int(item.get("clientImpact", 0))),
		_attribute_value(item_id, "risk", "%+d Dette" % int(item.get("risk", 0))),
	]


func _attribute_value(item_id: String, attribute: String, value: String) -> String:
	return value if SprintState.backlog_attribute_revealed(item_id, attribute) else "🔒 ?"


func _setup_self_work_button() -> void:
	self_work_button = Button.new()
	self_work_button.pressed.connect(_on_self_work_pressed)
	$Margin/VBox/CapacityRow.add_child(self_work_button)
	_refresh_self_work_button()


func _refresh_self_work_button() -> void:
	var conf: Dictionary = SprintState.get_personal_action_conf("selfWork")
	var refusal := SprintState.personal_action_refusal()
	self_work_button.text = "🔧 Faire le taf soi-même (+%d pts · %d ⚡)" % [int(conf.get("capacityBonus", 0)), int(conf.get("cost", 0))]
	self_work_button.disabled = refusal != ""


func _refresh_action_buttons() -> void:
	for control in backlog_controls:
		_refresh_action_button(control)


func _refresh_action_button(control: Dictionary) -> void:
	var dive: Button = control["dive"]
	var item: Dictionary = control["item"]
	var cost := SprintState.get_personal_action_cost("featureDive")
	dive.text = "🔬 Plonger (%d ⚡)" % cost
	dive.disabled = SprintState.personal_action_refusal() != "" or int(SprintState.revealed_backlog_sprint.get(item.get("id", ""), -1)) == SprintState.sprint_number


func _on_self_work_pressed() -> void:
	if SprintState.do_self_work() == "":
		_on_roster_changed()
		if side_panel != null:
			side_panel.refresh()


func _on_roster_changed() -> void:
	effective_capacity = SprintState.get_effective_capacity()
	capacity_bar.max_value = max(effective_capacity, 1)
	_update_capacity()
	_refresh_self_work_button()
	_refresh_action_buttons()


func _current_plan() -> Array:
	var plan: Array = []
	for control in backlog_controls:
		var item: Dictionary = control["item"]
		var points := 0
		if control.has("spend"):
			var spend: SpinBox = control["spend"]
			points = int(spend.value)
		else:
			var select: CheckButton = control["select"]
			if select.button_pressed:
				points = int(item.get("costPoints", 0))
		if points > 0:
			plan.append({"id": item.get("id", ""), "points": points})
	return plan


func _update_capacity() -> void:
	var selected := SprintState.backlog_plan_points(_current_plan())
	capacity_label.text = "Panier : %d pts / %d produits par l'équipe" % [selected, effective_capacity]
	capacity_bar.value = min(selected, capacity_bar.max_value)
	var over := selected > effective_capacity
	warning_label.visible = over
	capacity_bar.add_theme_stylebox_override("fill", UIHelpers.make_bar_fill_style(UIHelpers.COLOR_DANGER if over else UIHelpers.COLOR_GOOD))


func _on_next_pressed() -> void:
	SprintState.commit_backlog_plan(_current_plan())
	get_tree().change_scene_to_file(NEXT_SCENE)
