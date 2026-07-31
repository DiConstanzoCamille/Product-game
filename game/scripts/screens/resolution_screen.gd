extends Control
## Phase 4 — Résolution (docs/carnet-de-regles.md §3, §14-15). Applique le
## panier d'effets accumulé pendant le sprint (coûts des décisions + revenu
## du modèle économique du scénario), anime le passage de l'ancienne à la
## nouvelle valeur de chaque jauge, affiche le revenu séparément des coûts,
## le journal cumulatif, une alerte contextuelle, et route vers l'écran de
## fin de mandat si une fin est atteinte ou si le mandat arrive à son terme.
## Depuis la Phase B : ligne de delta d'Énergie ⚡ (régénération modulée par
## le Moral, dépenses d'actions personnelles) et option 🧘 Souffler.

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
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 4 : Résolution" % SprintState.sprint_number

	var old_values: Dictionary = SprintState.resource_values.duplicate()
	mandate_ending = SprintState.apply_pending_and_check()
	UIHelpers.attach_company_menu(self)

	_load_hud(old_values)
	_setup_next_button()
	_setup_breather_button()

	if int(SprintState.board_review_result.get("sprint", -1)) == SprintState.sprint_number:
		_show_board_review_overlay()


func _load_hud(old_values: Dictionary) -> void:
	var era: Dictionary = SprintState.get_era()
	UIHelpers.apply_heading(era_label, 17, 600.0)
	era_label.text = "%s %s — Sprint %d" % [era.get("icon", ""), era.get("name", ""), SprintState.sprint_number]
	cpo_label.text = "CPO : Vous · profil %s" % SprintState.team_profile.capitalize()

	_animate_revenue_callout()
	_add_energy_line()
	_add_roadmap_delivery_line()

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


## Bloc "Revenus" mis en avant, séparé des coûts — répond au besoin de rendre
## le ROI visible : un compteur défile de 0 jusqu'au revenu réel du sprint,
## à côté de la masse salariale, du coût net des décisions, du solde
## trésorerie et du flux de pièces du sprint.
func _animate_revenue_callout() -> void:
	var model: Dictionary = SprintState.get_business_model()
	if model.is_empty():
		revenue_label.visible = false
		return

	revenue_label.visible = true
	var revenue: int = SprintState.last_revenue
	var payroll: int = SprintState.last_payroll
	var cost: int = SprintState.last_tresorerie_cost
	var pieces_delta: int = SprintState.last_pieces_delta
	var roi_bonus: int = SprintState.last_roi_revenue_bonus
	var net: int = revenue - payroll + cost
	var model_label: String = model.get("label", "Revenu")

	revenue_label.add_theme_color_override("font_color", UIHelpers.COLOR_GOOD if net >= 0 else UIHelpers.COLOR_DANGER)

	var tween := create_tween()
	tween.tween_method(
		func(v: float):
			revenue_label.text = "💰 %s : +%d (dont ROI backlog +%d)  ·  👥 Masse salariale : −%d  ·  💸 Décisions : %s%d  ·  Net trésorerie : %s%d  ·  🪙 Pièces %s%d (solde %d)" % [
				model_label, int(round(v)), roi_bonus,
				payroll,
				"+" if cost >= 0 else "−", abs(cost),
				"+" if net >= 0 else "−", abs(net),
				"+" if pieces_delta >= 0 else "−", abs(pieces_delta), SprintState.pieces,
			],
		0.0, float(revenue), 0.7
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Ligne de delta d'Énergie ⚡ (spec profondeur §6.5, §7.1) : régénération
## avec la modulation par le Moral rendue visible, bonus de Souffler,
## événements Inbox, dépenses d'actions personnelles du sprint — le pont
## entre l'économie de l'entreprise et la vôtre, chiffré sous vos yeux.
func _add_energy_line() -> void:
	var report: Dictionary = SprintState.last_energy_report
	if report.is_empty():
		return

	var parts: Array = ["régén +%d (%d %s Moral)" % [
		int(report.get("regen", 0)), int(report.get("regenBase", 12)),
		SprintState.energy_factor_label(float(report.get("factor", 1.0)))
	]]
	if int(report.get("breatherBonus", 0)) > 0:
		parts.append("🧘 Souffler +%d" % int(report.get("breatherBonus", 0)))
	var events := int(report.get("events", 0))
	if events != 0:
		parts.append("événements %s%d" % ["+" if events > 0 else "−", abs(events)])
	var spent := int(report.get("spent", 0))
	if spent > 0:
		parts.append("actions personnelles −%d" % spent)

	var energy_label := Label.new()
	var sprint_delta := int(report.get("sprintDelta", 0))
	energy_label.text = "⚡ Énergie : %s  →  %d/%d (%s%d ce sprint)" % [
		" · ".join(parts), int(report.get("value", 0)), SprintState.get_energy_max(),
		"+" if sprint_delta >= 0 else "−", abs(sprint_delta)
	]
	energy_label.add_theme_font_size_override("font_size", 15)
	energy_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	energy_label.add_theme_color_override(
		"font_color", UIHelpers.COLOR_GOOD if sprint_delta >= 0 else UIHelpers.COLOR_DANGER)
	energy_label.tooltip_text = UIHelpers.energy_tooltip()

	var content: Node = $Margin/VBox/Scroll/Content
	content.add_child(energy_label)
	content.move_child(energy_label, revenue_label.get_index() + 1)


## Ce sont les chiffres réels qui étaient masqués sur la Roadmap. La
## Résolution est volontairement le seul endroit qui les révèle sans pratique.
func _add_roadmap_delivery_line() -> void:
	var report: Dictionary = SprintState.last_roadmap_report
	if int(report.get("sprint", -1)) != SprintState.sprint_number:
		return
	var delivered: Array = report.get("delivered", [])
	var progress: Array = report.get("epicUpdates", [])
	if delivered.is_empty() and progress.is_empty():
		return

	var lines: Array = []
	for item in delivered:
		lines.append("%s %s : ROI +%d MRR/sprint · Impact client %+d · Risque dette %+d" % [
			item.get("icon", "📌"), item.get("name", ""), int(item.get("roi", 0)),
			int(item.get("clientImpact", 0)), int(item.get("risk", 0))
		])
	for update in progress:
		if not update.get("completed", false):
			var item: Dictionary = update.get("item", {})
			lines.append("%s %s : +%d pts investis, %d pts restants" % [
				item.get("icon", "📌"), item.get("name", ""), int(update.get("invested", 0)),
				SprintState.get_epic_remaining(item.get("id", ""))
			])

	var label := Label.new()
	label.text = "Livraisons Roadmap\n%s" % "\n".join(lines)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 14)
	var content: Node = $Margin/VBox/Scroll/Content
	content.add_child(label)
	content.move_child(label, revenue_label.get_index() + 2)


## 🧘 Souffler (spec §7.2) — proposé à la Résolution : renoncer aux actions
## personnelles du prochain sprint contre un bonus de régénération.
func _setup_breather_button() -> void:
	if mandate_ending != "":
		return
	var bonus := int(GameData.balance.get("energy", {}).get("breatherRegenBonus", 10))
	var breather_btn := Button.new()
	breather_btn.text = "🧘 Souffler — sprint suivant sans action personnelle (+%d régén)" % bonus
	breather_btn.tooltip_text = "Le luxe ultime : un sprint où vous ne faites que votre travail."
	breather_btn.pressed.connect(func():
		if SprintState.plan_breather() == "":
			breather_btn.text = "🧘 Vous soufflerez au prochain sprint ✓"
			breather_btn.disabled = true
	)
	var bottom_bar: Node = $Margin/VBox/BottomBar
	bottom_bar.add_child(breather_btn)
	bottom_bar.move_child(breather_btn, 1)


## Overlay de verdict de la revue de board (spec profondeur §8.2) — affiché
## à la Résolution du sprint de mi-mandat, par-dessus le HUD.
func _show_board_review_overlay() -> void:
	var result: Dictionary = SprintState.board_review_result
	var passed: bool = result.get("passed", false)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var eyebrow := Label.new()
	eyebrow.text = "SPRINT %d — LA REVUE DE BOARD" % int(result.get("sprint", 0))
	UIHelpers.apply_mono(eyebrow, 12, true)
	eyebrow.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	vbox.add_child(eyebrow)

	var title := Label.new()
	title.text = result.get("title", "")
	UIHelpers.apply_heading(title, 24, 700.0)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title)

	for condition in result.get("conditions", []):
		var line := Label.new()
		line.text = "%s  %s" % ["✅" if condition.get("ok", false) else "❌", condition.get("label", "")]
		line.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(line)

	var verdict := Label.new()
	var review_conf: Dictionary = GameData.balance.get("pressure", {}).get("boardReview", {})
	if passed:
		verdict.text = "Le comité applaudit poliment. +%d 🪙 de budget d'action, 🎯 Capital politique +%d." % [
			int(review_conf.get("successPieces", 5)), int(review_conf.get("successCapitalPolitique", 8))
		]
		verdict.add_theme_color_override("font_color", UIHelpers.COLOR_GOOD)
	else:
		verdict.text = "Le comité « prend note ». 🎯 Capital politique %d, et l'allocation tombe à %d 🪙/sprint pour le reste du mandat." % [
			int(review_conf.get("failCapitalPolitique", -12)),
			int(GameData.balance.get("pieces", {}).get("boardAllocationIfReviewFailed", 1))
		]
		verdict.add_theme_color_override("font_color", UIHelpers.COLOR_DANGER)
	verdict.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(verdict)

	var close_btn := Button.new()
	close_btn.text = "Reprendre le sprint →"
	close_btn.pressed.connect(func(): dim.queue_free())
	vbox.add_child(close_btn)


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
			# Depuis la Phase A, la Valeur perçue ne déclenche plus de fin
			# directe : sous le seuil de décrochage, c'est le revenu qui meurt.
			if worst_resource.get("id", "") == "valeur-percue":
				return "⚠️ 📈 Valeur perçue en zone critique — sous %d, plus aucun revenu ne tombera." % int(
					GameData.balance.get("pressure", {}).get("revenueCutoffValeurPercue", 5)
				)
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
