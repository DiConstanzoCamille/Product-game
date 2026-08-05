extends Control
## Vue de la Roadmap profonde (§6). Les règles vivent dans SprintState : cet
## écran affiche le tirage persistant et lui remet seulement un plan de points.

const NEXT_SCENE := "res://scenes/screens/desk_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var capacity_label: Label = $Margin/VBox/CapacityRow/CapacityLabel
@onready var capacity_bar: ProgressBar = $Margin/VBox/CapacityBar
@onready var warning_label: Label = $Margin/VBox/WarningLabel
@onready var backlog_list: VBoxContainer = $Margin/VBox/Board/BacklogPanel/Margin/VBox/Scroll/BacklogList
@onready var sprint_drop_zone: RoadmapSprintDropZone = $Margin/VBox/Board/SprintDropZone
@onready var sprint_list: VBoxContainer = $Margin/VBox/Board/SprintDropZone/Margin/VBox/PlanScroll/SprintList
@onready var next_button: Button = $Margin/VBox/BottomBar/NextButton

var effective_capacity: int = 0
var backlog_controls: Array = []
var side_panel: Control = null
var self_work_button: Button = null
var ticket_dialog: Control = null
var ticket_detail_content: VBoxContainer = null


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(_on_next_pressed)
	UIHelpers.style_primary_button(next_button)
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)
	sprint_label.text = "Sprint %d — Phase 2 : Roadmap" % SprintState.sprint_number

	side_panel = UIHelpers.attach_side_panel(self)
	UIHelpers.attach_decision_workspace(self, NodePath("Margin/VBox"))
	side_panel.state_changed.connect(_on_roster_changed)
	sprint_drop_zone.ticket_dropped.connect(_on_ticket_dropped)
	capacity_bar.add_theme_stylebox_override("fill", UIHelpers.make_bar_fill_style(UIHelpers.COLOR_GOOD))
	capacity_bar.add_theme_stylebox_override("background", UIHelpers.make_bar_background_style())
	_style_board()
	_setup_ticket_dialog()
	_setup_self_work_button()
	_load_backlog()
	_update_capacity()


func _load_backlog() -> void:
	var offer := SprintState.get_backlog_offer()
	effective_capacity = SprintState.get_effective_capacity()
	capacity_bar.max_value = max(effective_capacity, 1)
	for item in offer.get("items", []):
		_add_backlog_card(item)


func _style_board() -> void:
	var backlog_panel: PanelContainer = $Margin/VBox/Board/BacklogPanel
	backlog_panel.add_theme_stylebox_override("panel", _panel_style(Color("#ffffff"), UIHelpers.COLOR_RULE))
	sprint_drop_zone.add_theme_stylebox_override("panel", _panel_style(Color("#edf3ff"), UIHelpers.COLOR_SHELF, 2))
	for title_path in [
		"Margin/VBox/Board/BacklogPanel/Margin/VBox/Title",
		"Margin/VBox/Board/SprintDropZone/Margin/VBox/Title",
	]:
		var title: Label = get_node(title_path)
		UIHelpers.apply_mono(title, 13, true)
		title.add_theme_color_override("font_color", UIHelpers.COLOR_SHELF)
	for subtitle_path in [
		"Margin/VBox/Board/BacklogPanel/Margin/VBox/Subtitle",
		"Margin/VBox/Board/SprintDropZone/Margin/VBox/Subtitle",
	]:
		var subtitle: Label = get_node(subtitle_path)
		subtitle.add_theme_font_size_override("font_size", 12)
		subtitle.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)


func _panel_style(background: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(10)
	style.shadow_color = UIHelpers.SHADOW_COLOR
	style.shadow_size = 3
	style.shadow_offset = Vector2(1, 2)
	return style


func _ticket_style(item: Dictionary) -> StyleBoxFlat:
	var background := UIHelpers.COLOR_CARD_DECISION if SprintState.is_backlog_epic(item) else Color("#ffffff")
	var border := UIHelpers.PILL_DECISION if SprintState.is_backlog_epic(item) else UIHelpers.COLOR_RULE
	return _panel_style(background, border, 2 if SprintState.is_backlog_epic(item) else 1)


func _setup_ticket_dialog() -> void:
	ticket_dialog = Control.new()
	ticket_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ticket_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	ticket_dialog.visible = false
	add_child(ticket_dialog)
	var scrim := ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.06, 0.08, 0.12, 0.55)
	scrim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			ticket_dialog.visible = false
	)
	ticket_dialog.add_child(scrim)
	var sheet := PanelContainer.new()
	sheet.set_anchors_preset(Control.PRESET_CENTER)
	sheet.offset_left = -285
	sheet.offset_top = -230
	sheet.offset_right = 285
	sheet.offset_bottom = 230
	sheet.add_theme_stylebox_override("panel", _panel_style(Color("#fffdf5"), UIHelpers.COLOR_INK, 2))
	ticket_dialog.add_child(sheet)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	sheet.add_child(margin)
	ticket_detail_content = VBoxContainer.new()
	ticket_detail_content.add_theme_constant_override("separation", 12)
	margin.add_child(ticket_detail_content)


func _open_ticket(ticket_id: String) -> void:
	var item := SprintState.find_backlog_item(ticket_id)
	if item.is_empty() or ticket_dialog == null:
		return
	UIHelpers.clear_children(ticket_detail_content)
	var top_line := HBoxContainer.new()
	ticket_detail_content.add_child(top_line)
	var eyebrow := Label.new()
	eyebrow.text = "DOSSIER %s" % ("EPIC" if SprintState.is_backlog_epic(item) else "FEATURE")
	UIHelpers.apply_mono(eyebrow, 12, true)
	eyebrow.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	top_line.add_child(eyebrow)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_line.add_child(spacer)
	var close := Button.new()
	close.text = "× Fermer"
	close.pressed.connect(func(): ticket_dialog.visible = false)
	top_line.add_child(close)

	var title := Label.new()
	title.text = "%s  %s" % [item.get("icon", "📌"), item.get("name", "")]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	UIHelpers.apply_heading(title, 22, 650.0)
	ticket_detail_content.add_child(title)
	var duration := Label.new()
	duration.text = _duration_badge_text(item)
	duration.add_theme_font_size_override("font_size", 15)
	duration.add_theme_color_override("font_color", UIHelpers.COLOR_SHELF)
	ticket_detail_content.add_child(duration)
	var description := Label.new()
	description.text = item.get("description", "")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD
	description.add_theme_font_size_override("font_size", 14)
	ticket_detail_content.add_child(description)
	var rule := UIHelpers.DashedRule.new()
	ticket_detail_content.add_child(rule)
	var details := Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD
	details.add_theme_font_size_override("font_size", 14)
	details.text = "%s\n\n%s\n\n%s" % [_schedule_text(item, _planned_points(ticket_id)), _attribute_text(item), _ticket_completion_text(item)]
	ticket_detail_content.add_child(details)
	ticket_dialog.visible = true


func _ticket_completion_text(item: Dictionary) -> String:
	if not SprintState.is_backlog_epic(item):
		return "Livraison : terminée à la Résolution de ce sprint si le ticket est planifié."
	var item_id: String = item.get("id", "")
	var remaining := SprintState.get_epic_remaining(item_id)
	var total := int(item.get("costPoints", 0))
	var stage_count := _epic_stages(item).size()
	var completed_stages := _epic_completed_stage_count(item)
	return "Progression : étape %d / %d · %d / %d pts réalisés.\nChaque étape est fixe : le plan de ce sprint ne peut pas en prendre une fraction." % [
		completed_stages + 1, stage_count, total - remaining, total
	]


func _add_backlog_card(item: Dictionary) -> void:
	var card := RoadmapTicket.new()
	card.ticket_id = item.get("id", "")
	card.ticket_title = item.get("name", "")
	# Le board est un index, pas la fiche complete : cette hauteur garantit que
	# toutes les actions restent visibles, sans transformer le board en fiche.
	card.custom_minimum_size = Vector2(0, 202)
	card.add_theme_stylebox_override("panel", _ticket_style(item))
	card.opened.connect(_open_ticket)
	backlog_list.add_child(card)

	var content := MarginContainer.new()
	content.add_theme_constant_override("margin_left", 14)
	content.add_theme_constant_override("margin_top", 12)
	content.add_theme_constant_override("margin_right", 14)
	content.add_theme_constant_override("margin_bottom", 12)
	card.add_child(content)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	content.add_child(body)

	var title := Label.new()
	title.text = "%s  %s" % [item.get("icon", "📌"), item.get("name", "")]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	UIHelpers.apply_heading(title, 16, 600.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(title)

	var schedule_band := PanelContainer.new()
	schedule_band.custom_minimum_size = Vector2(0, 38)
	var schedule_style := StyleBoxFlat.new()
	schedule_style.bg_color = UIHelpers.COLOR_SHELF
	schedule_style.set_corner_radius_all(5)
	schedule_style.content_margin_left = 10
	schedule_style.content_margin_right = 10
	schedule_band.add_theme_stylebox_override("panel", schedule_style)
	body.add_child(schedule_band)
	var schedule := Label.new()
	schedule.autowrap_mode = TextServer.AUTOWRAP_WORD
	schedule.add_theme_font_size_override("font_size", 14)
	schedule.add_theme_color_override("font_color", Color.WHITE)
	schedule.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	schedule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	schedule_band.add_child(schedule)

	var attributes := Label.new()
	attributes.autowrap_mode = TextServer.AUTOWRAP_WORD
	attributes.add_theme_font_size_override("font_size", 12)
	attributes.text = _attribute_summary(item)
	attributes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(attributes)

	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 6)
	body.add_child(status_row)
	var planned_stamp := UIHelpers.make_stamp("validated", 92)
	planned_stamp.visible = false
	status_row.add_child(planned_stamp)
	var risk_stamp := UIHelpers.make_stamp("risk", 82)
	risk_stamp.visible = false
	status_row.add_child(risk_stamp)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	body.add_child(actions)
	var dive := Button.new()
	dive.pressed.connect(func():
		if SprintState.do_feature_dive(item.get("id", "")) == "":
			attributes.text = _attribute_summary(item)
			_refresh_action_buttons()
	)
	actions.add_child(dive)
	var open_button := Button.new()
	open_button.text = "Ouvrir"
	open_button.tooltip_text = "Ouvrir le dossier complet du ticket. Double-cliquer sur le ticket fait la même chose."
	open_button.pressed.connect(func(): _open_ticket(item.get("id", "")))
	actions.add_child(open_button)
	dive.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var control: Dictionary = {"item": item, "ticket": card, "schedule": schedule, "dive": dive, "planned_stamp": planned_stamp, "risk_stamp": risk_stamp}
	control["open"] = open_button
	if SprintState.is_backlog_epic(item):
		var started_at := SprintState.get_epic_started_sprint(item.get("id", ""))
		var plan_button := Button.new()
		plan_button.pressed.connect(func(): _toggle_epic(control))
		body.add_child(plan_button)
		control["plan_button"] = plan_button
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
			body.add_child(abandon)
	else:
		var select := Button.new()
		select.pressed.connect(func(): _toggle_feature(control))
		body.add_child(select)
		control["select"] = select
	backlog_controls.append(control)
	_refresh_ticket_control(control)
	_refresh_action_button(control)


## 👥 Une feature n'annonce plus « ROI +3 » mais « +72 utilisateurs gratuits ».
## Le chiffre est celui du modèle économique du run, résolu par SprintState :
## le même ticket dit « +2 comptes signés » chez Meridia. Le masquage n'a pas
## bougé — Discovery révèle le total, UX research sa ventilation par segment.
func _attribute_text(item: Dictionary) -> String:
	var item_id: String = item.get("id", "")
	var lines: Array = ["Clients : %s" % _attribute_value(item_id, "clients", _clients_text(item))]
	if SprintState.backlog_attribute_revealed(item_id, "clientSegments"):
		for row in SprintState.clients_for_points_by_segment(float(item.get("clients", 0))):
			lines.append("  %s %s : %+d" % [row.get("icon", "👥"), row.get("label", ""), int(round(float(row.get("value", 0.0))))])
	lines.append("Risque dette : %s" % _attribute_value(item_id, "risk", "%+d Dette" % int(item.get("risk", 0))))
	return "\n".join(lines)


## Les deux signaux tiennent sur une ligne dans le board. Les chiffres et
## leur unité complète restent dans le dossier afin de ne pas tasser le ticket.
func _attribute_summary(item: Dictionary) -> String:
	var item_id: String = item.get("id", "")
	return "Clients %s  ·  Dette %s" % [
		_attribute_value(item_id, "clients", "%+d" % int(round(SprintState.clients_for_points(float(item.get("clients", 0)))))),
		_attribute_value(item_id, "risk", "%+d" % int(item.get("risk", 0))),
	]


func _clients_text(item: Dictionary) -> String:
	var gained := SprintState.clients_for_points(float(item.get("clients", 0)))
	if is_zero_approx(gained):
		return "aucun mouvement"
	return "%+d" % int(round(gained))


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
		_refresh_ticket_control(control)


func _refresh_action_button(control: Dictionary) -> void:
	var dive: Button = control["dive"]
	var item: Dictionary = control["item"]
	var cost := SprintState.get_personal_action_cost("featureDive")
	dive.text = "🔬 Plonger (%d ⚡)" % cost
	dive.disabled = SprintState.personal_action_refusal() != "" or int(SprintState.revealed_backlog_sprint.get(item.get("id", ""), -1)) == SprintState.sprint_number


func _toggle_feature(control: Dictionary) -> void:
	var select: Button = control["select"]
	select.set_meta("planned", not bool(select.get_meta("planned", false)))
	_refresh_ticket_control(control)
	_update_capacity()


func _toggle_epic(control: Dictionary) -> void:
	var plan_button: Button = control["plan_button"]
	plan_button.set_meta("planned", not bool(plan_button.get_meta("planned", false)))
	_refresh_ticket_control(control)
	_update_capacity()


func _on_ticket_dropped(ticket_id: String) -> void:
	for control in backlog_controls:
		if control["item"].get("id", "") != ticket_id:
			continue
		if control.has("plan_button"):
			var plan_button: Button = control["plan_button"]
			plan_button.set_meta("planned", true)
		else:
			var select: Button = control["select"]
			select.set_meta("planned", true)
		_refresh_ticket_control(control)
		_update_capacity()
		return


func _refresh_ticket_control(control: Dictionary) -> void:
	var item: Dictionary = control["item"]
	var ticket: RoadmapTicket = control["ticket"]
	var selected: bool = false
	var scheduled_points: int = 0
	if control.has("plan_button"):
		var plan_button: Button = control["plan_button"]
		selected = bool(plan_button.get_meta("planned", false))
		scheduled_points = _epic_next_stage_points(item) if selected else 0
		plan_button.text = "Retirer du sprint" if selected else "Planifier étape %d/%d · %d pts" % [
			_epic_completed_stage_count(item) + 1, _epic_stages(item).size(), _epic_next_stage_points(item)
		]
	else:
		var select: Button = control["select"]
		selected = bool(select.get_meta("planned", false))
		scheduled_points = int(item.get("costPoints", 0)) if selected else 0
		select.text = "Retirer du sprint" if selected else "Ajouter au sprint · %d pts" % int(item.get("costPoints", 0))

	var schedule: Label = control["schedule"]
	schedule.text = _schedule_text(item, scheduled_points)
	var planned_stamp: TextureRect = control["planned_stamp"]
	var was_planned_visible := planned_stamp.visible
	planned_stamp.visible = selected
	if selected and not was_planned_visible:
		_punch_small_stamp(planned_stamp)
	var risk_stamp: TextureRect = control["risk_stamp"]
	risk_stamp.visible = SprintState.backlog_attribute_revealed(item.get("id", ""), "risk") and int(item.get("risk", 0)) >= 6
	var destination: VBoxContainer = sprint_list if selected else backlog_list
	if ticket.get_parent() != destination:
		var source_rect: Rect2 = ticket.get_global_rect()
		ticket.modulate.a = 0.0
		ticket.reparent(destination)
		if selected:
			sprint_list.move_child(ticket, 0)
		_animate_ticket_move(item, source_rect, destination, ticket)
	_refresh_empty_hint()


func _punch_small_stamp(stamp: Control) -> void:
	stamp.pivot_offset = stamp.size / 2.0
	stamp.scale = Vector2(1.45, 1.45)
	stamp.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(stamp, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(stamp, "modulate:a", 1.0, 0.12)


func _schedule_text(item: Dictionary, scheduled_points: int) -> String:
	if not SprintState.is_backlog_epic(item):
		return "COÛT  ·  %d PTS%s" % [int(item.get("costPoints", 0)), "  ·  PLANIFIÉ" if scheduled_points > 0 else ""]
	var completed: int = _epic_completed_stage_count(item)
	var stages: Array = _epic_stages(item)
	var next_cost: int = _epic_next_stage_points(item)
	return "ÉTAPE %d/%d  ·  COÛT %d PTS%s" % [
		completed + 1, stages.size(), next_cost, "  ·  PLANIFIÉ" if scheduled_points > 0 else ""
	]


## L'objet-fiche se déplace d'une colonne à l'autre avant de réapparaître à
## son nouvel emplacement. Le plan garde ainsi un geste physique, même quand
## le joueur utilise le bouton plutôt que le glisser-déposer.
func _animate_ticket_move(item: Dictionary, source_rect: Rect2, destination: VBoxContainer, ticket: RoadmapTicket) -> void:
	var ghost: PanelContainer = PanelContainer.new()
	ghost.position = source_rect.position
	ghost.size = source_rect.size
	ghost.z_index = 20
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.add_theme_stylebox_override("panel", _ticket_style(item))
	add_child(ghost)
	var label: Label = Label.new()
	label.text = "%s  %s" % [item.get("icon", "📌"), item.get("name", "")]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.add_child(label)

	var target_panel: Control = sprint_drop_zone if destination == sprint_list else $Margin/VBox/Board/BacklogPanel
	var target_rect: Rect2 = target_panel.get_global_rect()
	var target_position: Vector2 = target_rect.get_center() - source_rect.size / 2.0
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "global_position", target_position, 0.24)
	tween.parallel().tween_property(ghost, "modulate:a", 0.12, 0.24)
	tween.tween_callback(func():
		ghost.queue_free()
		if is_instance_valid(ticket):
			ticket.modulate.a = 1.0
	)


func _duration_badge_text(item: Dictionary) -> String:
	if not SprintState.is_backlog_epic(item):
		return "DURÉE ESTIMÉE  ·  1 SPRINT"
	return "DURÉE ESTIMÉE  ·  %d SPRINTS  ·  %d ÉTAPES FIXES" % [_epic_stages(item).size(), _epic_stages(item).size()]


func _epic_stages(item: Dictionary) -> Array:
	var configured: Array = item.get("sprintStages", [])
	if not configured.is_empty():
		return configured
	# Compatibilité avec les anciennes sauvegardes/données : trois jalons égaux
	# sont préférables à un curseur libre, même sans la donnée éditoriale.
	var total: int = int(item.get("costPoints", 0))
	var first: int = ceili(float(total) / 3.0)
	var second: int = ceili(float(total - first) / 2.0)
	return [first, second, max(1, total - first - second)]


func _epic_completed_stage_count(item: Dictionary) -> int:
	var invested: int = SprintState.get_epic_invested(item.get("id", ""))
	var complete := 0
	var cumulative := 0
	for stage_value in _epic_stages(item):
		cumulative += int(stage_value)
		if invested >= cumulative:
			complete += 1
		else:
			break
	return min(complete, _epic_stages(item).size() - 1)


func _epic_next_stage_points(item: Dictionary) -> int:
	var stages: Array = _epic_stages(item)
	var next_index: int = _epic_completed_stage_count(item)
	var remaining: int = SprintState.get_epic_remaining(item.get("id", ""))
	return min(remaining, int(stages[next_index]))


func _refresh_empty_hint() -> void:
	var hint: Label = sprint_list.get_node_or_null("EmptyHint")
	if hint != null:
		hint.visible = sprint_list.get_child_count() == 1


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
		if control.has("plan_button"):
			var plan_button: Button = control["plan_button"]
			if bool(plan_button.get_meta("planned", false)):
				points = _epic_next_stage_points(item)
		else:
			var select: Button = control["select"]
			if bool(select.get_meta("planned", false)):
				points = int(item.get("costPoints", 0))
		if points > 0:
			plan.append({"id": item.get("id", ""), "points": points})
	return plan


func _planned_points(item_id: String) -> int:
	for control in backlog_controls:
		if control["item"].get("id", "") != item_id:
			continue
		if control.has("plan_button"):
			return _epic_next_stage_points(control["item"]) if bool((control["plan_button"] as Button).get_meta("planned", false)) else 0
		return int(control["item"].get("costPoints", 0)) if bool((control["select"] as Button).get_meta("planned", false)) else 0
	return 0


func _update_capacity() -> void:
	var selected := SprintState.backlog_plan_points(_current_plan())
	capacity_label.text = "Panier : %d pts / %d produits par l'équipe" % [selected, effective_capacity]
	capacity_bar.value = min(selected, capacity_bar.max_value)
	var over := selected > effective_capacity
	warning_label.visible = over
	capacity_bar.add_theme_stylebox_override("fill", UIHelpers.make_bar_fill_style(UIHelpers.COLOR_DANGER if over else UIHelpers.COLOR_GOOD))


func _on_next_pressed() -> void:
	# 🎯 Tant que cet écran ne sait piloter qu'une équipe, il déclare ne piloter
	# que celle-là : toutes les autres passent en auto-pilotage plutôt que de
	# perdre leur sprint faute d'être exposées. Le jour où le sélecteur
	# d'équipe arrive, seule cette ligne change. À N=1 l'appel est neutre.
	SprintState.set_piloted_squads([SprintState.get_primary_squad().get("id", "")])
	SprintState.commit_backlog_plan(_current_plan())
	SprintState.resolve_unpiloted_squads()
	get_tree().change_scene_to_file(NEXT_SCENE)
