extends Control
## Phase 5 — Résolution (docs/carnet-de-regles.md §3, §14-15). Applique le
## panier d'effets accumulé pendant le sprint (coûts des décisions + revenu
## du modèle économique du scénario), anime le passage de l'ancienne à la
## nouvelle valeur de chaque jauge, affiche le revenu séparément des coûts,
## le journal cumulatif, une alerte contextuelle, et route vers l'écran de
## fin de mandat si une fin est atteinte ou si le mandat arrive à son terme.

const INBOX_SCENE := "res://scenes/screens/inbox_screen.tscn"
const FOUNDATIONS_SCENE := "res://scenes/screens/foundations_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"
const MANDATE_END_SCENE := "res://scenes/screens/mandate_end_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var era_label: Label = $Margin/VBox/Scroll/Content/HeaderRow/EraLabel
@onready var cpo_label: Label = $Margin/VBox/Scroll/Content/HeaderRow/CpoLabel
@onready var revenue_label: Label = $Margin/VBox/Scroll/Content/RevenueLabel
@onready var gauges_grid: GridContainer = $Margin/VBox/Scroll/Content/GaugesGrid
@onready var journal_title: Label = $Margin/VBox/Scroll/Content/JournalTitle
@onready var journal_container: VBoxContainer = $Margin/VBox/Scroll/Content/JournalContainer
@onready var alert_label: Label = $Margin/VBox/Scroll/Content/AlertLabel
@onready var foundations_button: Button = $Margin/VBox/BottomBar/FoundationsButton
@onready var next_sprint_button: Button = $Margin/VBox/BottomBar/NextSprintButton

var mandate_ending: String = ""


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	foundations_button.pressed.connect(func(): get_tree().change_scene_to_file(FOUNDATIONS_SCENE))
	UIHelpers.add_hover_bounce(back_button)
	UIHelpers.add_hover_bounce(foundations_button)
	UIHelpers.add_hover_bounce(next_sprint_button)
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 5 : Résolution" % SprintState.sprint_number

	var old_values: Dictionary = SprintState.resource_values.duplicate()
	mandate_ending = SprintState.apply_pending_and_check()
	UIHelpers.attach_company_menu(self)

	_load_hud(old_values)
	_setup_next_button()


func _load_hud(old_values: Dictionary) -> void:
	var era: Dictionary = SprintState.get_era()
	UIHelpers.apply_heading(era_label, 17, 600.0)
	era_label.text = "%s %s — Sprint %d" % [era.get("icon", ""), era.get("name", ""), SprintState.sprint_number]
	cpo_label.text = "CPO : Vous · profil %s" % SprintState.team_profile.capitalize()

	_animate_revenue_callout()

	var index := 0
	for resource in GameData.resources:
		gauges_grid.add_child(_build_gauge(resource, old_values, index))
		index += 1

	journal_title.text = "Journal du sprint"
	var recent: Array = SprintState.journal.slice(max(0, SprintState.journal.size() - 6), SprintState.journal.size())
	recent.reverse()
	for entry in recent:
		var entry_label := Label.new()
		entry_label.text = "Sprint %d — %s\n%s" % [
			entry.get("sprint", 0), entry.get("text", ""), entry.get("deltas", "")
		]
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		entry_label.add_theme_font_size_override("font_size", 13)
		journal_container.add_child(entry_label)

	alert_label.text = _build_alert_text()


## Bloc "Revenus" mis en avant, séparé des coûts de décisions — répond au
## besoin de rendre le ROI visible : un compteur défile de 0 jusqu'au revenu
## réel du sprint, à côté du coût net des décisions et du solde.
func _animate_revenue_callout() -> void:
	var model: Dictionary = SprintState.get_business_model()
	if model.is_empty():
		revenue_label.visible = false
		return

	revenue_label.visible = true
	var revenue: int = SprintState.last_revenue
	var cost: int = SprintState.last_tresorerie_cost
	var net: int = revenue + cost
	var model_label: String = model.get("label", "Revenu")

	revenue_label.add_theme_color_override("font_color", UIHelpers.COLOR_GOOD if net >= 0 else UIHelpers.COLOR_DANGER)

	var tween := create_tween()
	tween.tween_method(
		func(v: float):
			revenue_label.text = "🪙 %s : +%d  ·  💸 Décisions du sprint : %s%d  ·  Net trésorerie : %s%d" % [
				model_label, int(round(v)),
				"+" if cost >= 0 else "−", abs(cost),
				"+" if net >= 0 else "−", abs(net),
			],
		0.0, float(revenue), 0.7
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _build_gauge(resource: Dictionary, old_values: Dictionary, index: int) -> Control:
	var resource_id: String = resource.get("id", "")
	var old_value: float = old_values.get(resource_id, 0.0)
	var new_value: float = SprintState.resource_values.get(resource_id, 0.0)
	var delta := int(round(new_value - old_value))
	var state := EffectResolver.gauge_state(resource_id, new_value)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(230, 0)
	vbox.add_theme_constant_override("separation", 4)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	vbox.add_child(top)

	var icon_name: String = UIHelpers.GAUGE_ICONS.get(resource_id, "target")
	top.add_child(UIHelpers.make_icon(icon_name, 18, UIHelpers.state_color(state)))

	var label := Label.new()
	label.text = resource.get("name", "")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(label)

	var value_label := Label.new()
	value_label.text = "%d%%" % int(round(old_value))
	value_label.add_theme_color_override("font_color", UIHelpers.state_color(state))
	top.add_child(value_label)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 8)
	bar.max_value = 100
	bar.value = old_value
	bar.show_percentage = false
	bar.add_theme_stylebox_override("fill", UIHelpers.make_bar_fill_style(UIHelpers.state_color(state)))
	bar.add_theme_stylebox_override("background", UIHelpers.make_bar_background_style())
	vbox.add_child(bar)

	var delta_suffix := " (%s%d)" % ["+" if delta >= 0 else "−", abs(delta)] if delta != 0 else ""
	var tween := create_tween()
	tween.tween_interval(0.15 + index * 0.08)
	tween.tween_method(
		func(v: float):
			bar.value = v
			value_label.text = "%d%%%s" % [int(round(v)), delta_suffix],
		old_value, new_value, 0.5
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	return vbox


## Alerte contextuelle : signale la ressource la plus critique, avec le
## texte de menace tiré de resources.json → extreme (condition/outcome).
func _build_alert_text() -> String:
	var worst_resource: Dictionary = {}
	var worst_state := "good"
	var worst_normalized := 999.0

	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		var value: float = SprintState.resource_values.get(resource_id, 50.0)
		var direction: String = GameData.balance.get("resourceDirection", {}).get(resource_id, "high-good")
		var normalized := value if direction == "high-good" else (100.0 - value)
		if normalized < worst_normalized:
			worst_normalized = normalized
			worst_resource = resource
			worst_state = EffectResolver.gauge_state(resource_id, value)

	if worst_resource.is_empty():
		return ""

	var extreme: Dictionary = worst_resource.get("extreme", {})
	match worst_state:
		"danger":
			return "⚠️ %s %s en zone critique — encore un peu et : %s" % [
				worst_resource.get("icon", ""), worst_resource.get("name", ""), extreme.get("outcome", "")
			]
		"warn":
			return "🟡 %s %s sous tension — à surveiller." % [worst_resource.get("icon", ""), worst_resource.get("name", "")]
		_:
			return "Toutes les jauges sont sous contrôle, pour l'instant."


func _setup_next_button() -> void:
	if mandate_ending != "":
		next_sprint_button.text = "Voir le résultat du mandat →"
		next_sprint_button.pressed.connect(func(): get_tree().change_scene_to_file(MANDATE_END_SCENE))
	else:
		next_sprint_button.text = "Sprint suivant →"
		next_sprint_button.pressed.connect(_on_next_sprint_pressed)


func _on_next_sprint_pressed() -> void:
	SprintState.sprint_number += 1
	get_tree().change_scene_to_file(INBOX_SCENE)
