extends Control
## Hub de gestion d'équipe : une vue dédiée pour diagnostiquer une personne,
## comprendre ses quatre critères et agir sans quitter la phase courante.

signal state_changed

var selected_employee_id: String = ""
var _fire_dialog: ConfirmationDialog = null
var _pending_fire_id: String = ""

const CRITERIA := {
	"moral": {"icon": "🫶", "label": "Moral", "low": "Le travail n'a plus de sens ou le rythme abîme l'équipe.", "remedy": "Sprints tenus, écoute, repos et réussites collectives."},
	"confiance": {"icon": "🤝", "label": "Confiance", "low": "La personne ne croit plus que vos décisions seront tenues.", "remedy": "1:1, périmètre clair et décisions cohérentes."},
	"energie": {"icon": "⚡", "label": "Énergie", "low": "La charge accumulée approche du burn-out.", "remedy": "Sous-charge, repos et garde-fous de capacité."},
	"salaire": {"icon": "💸", "label": "Salaire", "low": "La reconnaissance financière ne suit plus la contribution.", "remedy": "Augmentation, promotion et trajectoire de progression."},
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	if selected_employee_id == "" and not SprintState.get_roster().is_empty():
		selected_employee_id = String(SprintState.get_roster()[0].get("id", ""))
	_build()


func open_for(employee_id: String = "") -> void:
	if employee_id != "":
		selected_employee_id = employee_id
	elif selected_employee_id == "" and not SprintState.get_roster().is_empty():
		selected_employee_id = String(SprintState.get_roster()[0].get("id", ""))
	if is_node_ready():
		_build()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _build() -> void:
	UIHelpers.clear_children(self)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.04, 0.06, 0.09, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var paper := PanelContainer.new()
	paper.name = "TeamManagementPanel"
	paper.set_anchors_preset(Control.PRESET_CENTER)
	paper.offset_left = -510
	paper.offset_top = -350
	paper.offset_right = 510
	paper.offset_bottom = 350
	var paper_style := StyleBoxFlat.new()
	paper_style.bg_color = UIHelpers.COLOR_SCREEN_BG
	paper_style.border_color = UIHelpers.COLOR_INK
	paper_style.set_border_width_all(3)
	paper_style.set_corner_radius_all(10)
	paper_style.shadow_color = UIHelpers.SHADOW_COLOR
	paper_style.shadow_size = 16
	paper.add_theme_stylebox_override("panel", paper_style)
	add_child(paper)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	paper.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	_build_header(layout)
	_build_summary(layout)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	layout.add_child(body)
	_build_roster(body)
	_build_detail(body)


func _build_header(layout: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var eyebrow := _label("GESTION D'ÉQUIPE · SPRINT %d" % SprintState.sprint_number, 11, UIHelpers.COLOR_AMBER)
	UIHelpers.apply_mono(eyebrow, 11, true)
	title_box.add_child(eyebrow)
	var title := _label("Les personnes derrière la capacité", 25, UIHelpers.COLOR_INK)
	UIHelpers.apply_heading(title, 25, 650.0)
	title_box.add_child(title)
	row.add_child(title_box)
	var close := Button.new()
	close.name = "CloseTeamManagement"
	close.text = "Fermer  ×"
	close.pressed.connect(_close)
	row.add_child(close)
	layout.add_child(row)


func _build_summary(layout: VBoxContainer) -> void:
	var roster := SprintState.get_roster()
	var alerts := 0
	for employee in roster:
		if bool(SprintState.get_employee_alert(employee).get("active", false)):
			alerts += 1
	var summary := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff7db") if alerts > 0 else Color("e9f7ef")
	style.border_color = UIHelpers.COLOR_WARN if alerts > 0 else UIHelpers.COLOR_GOOD
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	summary.add_theme_stylebox_override("panel", style)
	var queued := SprintState.pending_team_event_count()
	var copy := "👥 %d personnes · %d alerte%s · %d demande%s prévue%s pour la prochaine Inbox" % [
		roster.size(), alerts, "s" if alerts != 1 else "", queued,
		"s" if queued != 1 else "", "s" if queued != 1 else "",
	]
	summary.add_child(_label(copy, 13, UIHelpers.COLOR_INK, true))
	layout.add_child(summary)


func _build_roster(body: HBoxContainer) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(280, 0)
	column.add_theme_constant_override("separation", 7)
	body.add_child(column)
	var heading := _label("PERSONNES", 11, UIHelpers.COLOR_SHELF)
	UIHelpers.apply_mono(heading, 11, true)
	column.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for employee in SprintState.get_roster():
		var employee_id := String(employee.get("id", ""))
		var alert := SprintState.get_employee_alert(employee)
		var button := Button.new()
		button.name = "TeamMember_%s" % employee_id
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 54)
		button.text = "%s  %s\n     %s" % [
			"⚠" if alert.get("active", false) else "●", employee.get("name", ""),
			"%s %d — %s" % [_criterion_icon(String(alert.get("criterion", ""))), int(alert.get("value", 0)), alert.get("label", "stable")],
		]
		button.tooltip_text = "Ouvrir la fiche de %s" % employee.get("name", "")
		if employee_id == selected_employee_id:
			button.disabled = true
		button.pressed.connect(_select_employee.bind(employee_id))
		list.add_child(button)


func _build_detail(body: HBoxContainer) -> void:
	var employee := SprintState.find_employee(selected_employee_id)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 12)
	scroll.add_child(detail)
	if employee.is_empty():
		detail.add_child(_label("Sélectionnez une personne.", 15, UIHelpers.COLOR_SOFT_TEXT))
		return
	_build_identity(detail, employee)
	for criterion in SprintState.get_individual_team_conf().get("criteria", []):
		detail.add_child(_criterion_card(employee, String(criterion)))
	_build_personality(detail, employee)
	_build_actions(detail, employee)


func _build_identity(detail: VBoxContainer, employee: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(UIHelpers.make_person_badge(employee.get("name", ""), 42))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name := _label(employee.get("name", ""), 22, UIHelpers.COLOR_INK)
	UIHelpers.apply_heading(name, 22, 650.0)
	text.add_child(name)
	var role: String = String(GameData.balance.get("roles", {}).get(employee.get("role", ""), {}).get("label", employee.get("role", "")))
	text.add_child(_label("%s · %s · %d 💰/sprint" % [role, employee.get("seniority", ""), int(employee.get("salary", 0))], 13, UIHelpers.COLOR_SOFT_TEXT))
	row.add_child(text)
	var contribution := "EN REPOS" if int(employee.get("timeOffSprint", -1)) == SprintState.sprint_number else ("EN RUPTURE" if employee.get("contributionBlocked", false) else "CONTRIBUE")
	var state := _label(contribution, 11, UIHelpers.COLOR_WARN if contribution != "CONTRIBUE" else UIHelpers.COLOR_GOOD)
	UIHelpers.apply_mono(state, 11, true)
	row.add_child(state)
	detail.add_child(row)


func _criterion_card(employee: Dictionary, criterion: String) -> Control:
	var conf: Dictionary = CRITERIA.get(criterion, {})
	var value := int(SprintState.employee_wellbeing(employee).get(criterion, 0))
	var alert_at := int(SprintState.get_individual_team_conf().get("alertAt", 25))
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = UIHelpers.COLOR_DANGER if value <= 0 else (UIHelpers.COLOR_WARN if value <= alert_at else UIHelpers.COLOR_RULE)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	panel.add_theme_stylebox_override("panel", style)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 5)
	panel.add_child(copy)
	var head := HBoxContainer.new()
	var label := _label("%s %s" % [conf.get("icon", "•"), conf.get("label", criterion)], 14, UIHelpers.COLOR_INK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(label)
	var number := _label("%d / 100" % value, 14, UIHelpers.COLOR_DANGER if value <= 0 else (UIHelpers.COLOR_WARN if value <= alert_at else UIHelpers.COLOR_INK))
	UIHelpers.apply_mono(number, 14, true)
	head.add_child(number)
	copy.add_child(head)
	var bar := ProgressBar.new()
	bar.name = "Wellbeing_%s" % criterion
	bar.max_value = 100
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 9)
	var gauge_state := "danger" if value <= alert_at else ("good" if value >= 60 else "warn")
	bar.add_theme_stylebox_override("fill", UIHelpers.make_bar_fill_style(UIHelpers.state_color(gauge_state)))
	bar.add_theme_stylebox_override("background", UIHelpers.make_bar_background_style())
	copy.add_child(bar)
	var explanation: String = String(conf.get("low", "") if value <= alert_at else conf.get("remedy", ""))
	copy.add_child(_label(explanation, 11, UIHelpers.COLOR_FLAVOR, true))
	return panel


func _build_personality(detail: VBoxContainer, employee: Dictionary) -> void:
	var box := VBoxContainer.new()
	var heading := _label("CARACTÈRE ET SIGNAUX", 11, UIHelpers.COLOR_SHELF)
	UIHelpers.apply_mono(heading, 11, true)
	box.add_child(heading)
	if employee.get("personalityRevealed", false):
		var personality := SprintState.get_personality(String(employee.get("personality", "")))
		box.add_child(_label("%s — %s" % [personality.get("name", "Caractère inconnu"), personality.get("trait", "")], 12, UIHelpers.COLOR_FLAVOR, true))
	else:
		box.add_child(_label("🔒 Un 1:1 révèle la façon dont cette personne réagit aux décisions.", 12, UIHelpers.COLOR_SOFT_TEXT, true))
	var pending: Array = employee.get("pendingConcerns", []) + employee.get("pendingCrises", [])
	if not pending.is_empty():
		box.add_child(_label("📨 Prochaine Inbox : %s" % ", ".join(pending), 12, UIHelpers.COLOR_WARN, true))
	detail.add_child(box)


func _build_actions(detail: VBoxContainer, employee: Dictionary) -> void:
	var heading := _label("AGIR MAINTENANT", 11, UIHelpers.COLOR_SHELF)
	UIHelpers.apply_mono(heading, 11, true)
	detail.add_child(heading)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	detail.add_child(grid)
	var employee_id := String(employee.get("id", ""))
	var one_cost := SprintState.get_personal_action_cost("oneOnOne")
	var one_refusal := SprintState.personal_action_refusal()
	if one_refusal == "":
		one_refusal = SprintState.employee_management_refusal(employee, "one-on-one")
	grid.add_child(_action_button("🤝 Faire un 1:1 · %d ⚡" % one_cost, one_refusal, _one_on_one.bind(employee_id), "OneOnOneAction"))
	var ownership_cost := int(SprintState.get_individual_team_conf().get("managementActions", {}).get("ownership", {}).get("cpoEnergyCost", 0))
	grid.add_child(_action_button("🧭 Confier un périmètre · %d ⚡" % ownership_cost, SprintState.employee_management_refusal(employee, "ownership"), _ownership.bind(employee_id), "OwnershipAction"))
	grid.add_child(_action_button("⚡ Donner le sprint de repos", SprintState.employee_management_refusal(employee, "time-off"), _time_off.bind(employee_id), "TimeOffAction"))
	grid.add_child(_action_button("💸 Augmenter · +1 💰/sprint", SprintState.employee_management_refusal(employee, "salary-raise"), _salary_raise.bind(employee_id), "SalaryRaiseAction"))
	if employee.get("seniority", "junior") == "junior":
		var promote_refusal := "impact" if SprintState.impact_wallet < SprintState.promotion_cost() else ""
		grid.add_child(_action_button("📈 Promouvoir · %d 💥" % SprintState.promotion_cost(), promote_refusal, _promote.bind(employee_id), "PromoteAction"))
	grid.add_child(_action_button("🚪 Se séparer · %d 💥" % SprintState.resolved_price("severance"), "impact" if SprintState.impact_wallet < SprintState.resolved_price("severance") else "", _confirm_fire.bind(employee_id), "FireAction"))


func _action_button(text: String, refusal: String, callback: Callable, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(0, 42)
	button.disabled = refusal != ""
	button.tooltip_text = _refusal_label(refusal) if refusal != "" else text
	button.pressed.connect(callback)
	return button


func _refusal_label(refusal: String) -> String:
	match refusal:
		"deja-ce-sprint": return "Cette action a déjà été utilisée avec cette personne ce sprint."
		"impact": return "Pas assez d'Impact disponible."
		"epuise": return "Votre Énergie est trop basse."
	return "Action indisponible pour l'instant."


func _select_employee(employee_id: String) -> void:
	selected_employee_id = employee_id
	_build()


func _one_on_one(employee_id: String) -> void:
	var employee := SprintState.find_employee(employee_id)
	if not employee.is_empty() and SprintState.do_one_on_one(employee) == "":
		_after_action()


func _ownership(employee_id: String) -> void:
	if SprintState.grant_ownership(employee_id) == "":
		_after_action()


func _time_off(employee_id: String) -> void:
	if SprintState.grant_time_off(employee_id) == "":
		_after_action()


func _salary_raise(employee_id: String) -> void:
	if SprintState.grant_salary_raise(employee_id) == "":
		_after_action()


func _promote(employee_id: String) -> void:
	if SprintState.promote_employee(employee_id) == "":
		_after_action()


func _confirm_fire(employee_id: String) -> void:
	_pending_fire_id = employee_id
	var employee := SprintState.find_employee(employee_id)
	_fire_dialog = ConfirmationDialog.new()
	_fire_dialog.title = "Se séparer de %s" % employee.get("name", "cette personne")
	_fire_dialog.dialog_text = "Cette décision est irréversible. Elle réduit la masse salariale et la Confiance de celles et ceux qui restent."
	_fire_dialog.ok_button_text = "Confirmer le départ"
	_fire_dialog.cancel_button_text = "Annuler"
	_fire_dialog.confirmed.connect(_fire_confirmed)
	_fire_dialog.canceled.connect(_fire_dialog.queue_free)
	add_child(_fire_dialog)
	_fire_dialog.popup_centered()


func _fire_confirmed() -> void:
	if SprintState.fire_employee(_pending_fire_id) != "":
		return
	_pending_fire_id = ""
	selected_employee_id = String(SprintState.get_roster()[0].get("id", "")) if not SprintState.get_roster().is_empty() else ""
	_after_action()


func _after_action() -> void:
	_build()
	state_changed.emit()


func _close() -> void:
	queue_free()


func _criterion_icon(criterion: String) -> String:
	return String(CRITERIA.get(criterion, {}).get("icon", "•"))


func _label(text: String, size: int, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return label
