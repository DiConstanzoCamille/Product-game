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
@onready var score_replay: VBoxContainer = $Margin/VBox/Scroll/Content/ScoreReplay
@onready var score_title: Label = $Margin/VBox/Scroll/Content/ScoreReplay/ScoreHeader/ScoreTitle
@onready var score_status: Label = $Margin/VBox/Scroll/Content/ScoreReplay/ScoreHeader/ScoreStatus
@onready var score_lines: VBoxContainer = $Margin/VBox/Scroll/Content/ScoreReplay/ScoreLines
@onready var gauges_grid: GridContainer = $Margin/VBox/Scroll/Content/GaugesGrid
@onready var journal_title: Label = $Margin/VBox/Scroll/Content/JournalTitle
@onready var journal_container: VBoxContainer = $Margin/VBox/Scroll/Content/JournalContainer
@onready var alert_label: Label = $Margin/VBox/Scroll/Content/AlertLabel
@onready var foundations_button: Button = $Margin/VBox/BottomBar/FoundationsButton
@onready var next_sprint_button: Button = $Margin/VBox/BottomBar/NextSprintButton
@onready var score_audio: AudioStreamPlayer = $ScoreAudio

var mandate_ending: String = ""
var _score_events: Array = []
var _score_event_index := 0
var _score_replay_delay := 0.25
var _score_replay_speed := 1.0
var _score_replay_token := 0
var _score_replay_clicks := 0
var _score_finished := false
var _score_tone_stream: AudioStreamWAV
var _score_last_audio_step := -1
var _score_audio_step_ticks := 0


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
	_setup_score_replay()

	if int(SprintState.board_review_result.get("sprint", -1)) == SprintState.sprint_number:
		_show_board_review_overlay()


func _exit_tree() -> void:
	_score_replay_token += 1
	_score_finished = true
	if is_instance_valid(score_audio):
		score_audio.stop()
		score_audio.stream = null
	_score_tone_stream = null


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


## La Résolution ne calcule jamais le score. Elle ne fait que rejouer, dans
## l'ordre contractuel du rapport, les lignes produites par ScoreResolver.
func _setup_score_replay() -> void:
	for child in score_lines.get_children():
		child.queue_free()
	_score_events.clear()
	_score_event_index = 0
	_score_replay_clicks = 0
	_score_finished = false

	var report: Dictionary = SprintState.last_score_report
	if report.is_empty():
		score_replay.visible = false
		return
	score_replay.visible = true
	score_title.text = "Traction × Levier = Impact"
	score_status.text = "Calcul en cours"
	var squad_reports: Array = report.get("squads", [])
	var many_teams := squad_reports.size() > 1
	for squad_report in squad_reports:
		if many_teams:
			_add_score_divider(squad_report.get("id", ""))
		for line in squad_report.get("lines", []):
			_add_score_event(line)
	for line in report.get("global", {}).get("lines", []):
		_add_score_event(line)

	if _score_events.is_empty():
		score_status.text = "Aucun score ce sprint"
		_score_finished = true
		return
	_setup_score_audio()
	_score_replay_token += 1
	_replay_score_report(_score_replay_token)


func _add_score_event(line: Dictionary) -> void:
	var label := Label.new()
	label.custom_minimum_size = Vector2(0, 26)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 14)
	label.visible = false
	score_lines.add_child(label)
	_score_events.append({"kind": "line", "line": line, "node": label})


func _add_score_divider(squad_id: String) -> void:
	var divider := Label.new()
	divider.text = _squad_display_name(squad_id)
	divider.custom_minimum_size = Vector2(0, 28)
	divider.autowrap_mode = TextServer.AUTOWRAP_WORD
	divider.add_theme_font_size_override("font_size", 15)
	divider.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	divider.visible = false
	score_lines.add_child(divider)
	_score_events.append({"kind": "divider", "node": divider})


func _replay_score_report(token: int) -> void:
	while _score_event_index < _score_events.size():
		if token != _score_replay_token or not is_inside_tree():
			return
		var wait_time := _score_replay_delay / _score_replay_speed
		await get_tree().create_timer(wait_time).timeout
		if token != _score_replay_token or _score_finished:
			return
		_reveal_next_score_event()
	if token == _score_replay_token:
		_finish_score_replay()


func _reveal_next_score_event() -> void:
	if _score_event_index >= _score_events.size():
		return
	var event: Dictionary = _score_events[_score_event_index]
	_score_event_index += 1
	var label: Label = event["node"]
	label.visible = true
	if event.get("kind", "line") == "divider":
		return
	var line: Dictionary = event["line"]
	_style_score_line(label, line)
	_animate_score_line(label, line)
	_play_score_tick(int(line.get("step", 0)))
	if _is_combo_line(line):
		_shake_score_replay()


func _animate_score_line(label: Label, line: Dictionary) -> void:
	var before := float(line.get("before", 0.0))
	var after := float(line.get("after", before))
	label.text = _format_score_line(line, before)
	var duration := 0.2 / _score_replay_speed
	var tween := create_tween()
	tween.tween_method(func(value: float):
		if is_instance_valid(label):
			label.text = _format_score_line(line, value), before, after, duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if line.get("type", "") == "impact":
		tween.tween_callback(func(): _flash_impact(label))


func _format_score_line(line: Dictionary, current: float) -> String:
	var label: String = line.get("label", "")
	var icon: String = line.get("icon", "")
	var type: String = line.get("type", "")
	var before := float(line.get("before", 0.0))
	if type == "impact":
		return "%s  %s  %d" % [icon, label, int(round(current))]
	if type == "traction_multiplier" or type == "impact_multiplier":
		return "%s  %s ×%s   %s -> %s" % [icon, label, String.num(float(line.get("value", 1.0)), 2), _score_number(before), _score_number(current)]
	if type == "total_lever_cap":
		return "%s  %s : plafond %s" % [icon, label, _score_number(current)]
	var value := float(line.get("value", 0.0))
	var prefix := "+" if value >= 0.0 else "-"
	return "%s  %s  %s%s   %s -> %s" % [icon, label, prefix, _score_number(abs(value)), _score_number(before), _score_number(current)]


func _score_number(value: float) -> String:
	return str(int(round(value))) if is_equal_approx(value, round(value)) else String.num(value, 2)


func _style_score_line(label: Label, line: Dictionary) -> void:
	var line_type: String = line.get("type", "")
	var friction := int(line.get("step", 0)) == 7
	if friction:
		label.add_theme_color_override("font_color", UIHelpers.COLOR_DANGER)
	elif line_type == "impact":
		var impact: int = abs(int(round(float(line.get("after", line.get("value", 0.0))))))
		var font_size: int = clampi(24 + int(round(sqrt(float(impact)) * 1.25)), 24, 38)
		label.custom_minimum_size = Vector2(0, 44)
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	elif _is_combo_line(line):
		var combo_color: Color = UIHelpers.COLOR_GOOD if float(line.get("value", 0.0)) >= 0.0 else UIHelpers.COLOR_DANGER
		var combo_background: Color = combo_color
		combo_background.a = 0.18
		var combo_style: StyleBoxFlat = StyleBoxFlat.new()
		combo_style.bg_color = combo_background
		combo_style.set_corner_radius_all(6)
		combo_style.content_margin_left = 8
		combo_style.content_margin_right = 8
		combo_style.content_margin_top = 4
		combo_style.content_margin_bottom = 4
		label.add_theme_stylebox_override("normal", combo_style)
		label.add_theme_color_override("font_color", combo_color)
	else:
		label.add_theme_color_override("font_color", UIHelpers.COLOR_INK)


func _is_combo_line(line: Dictionary) -> bool:
	if line.get("scope", "") != "local" or line.get("type", "") != "lever_add":
		return false
	for combo in GameData.scoring.get("local", {}).get("organizationCombos", []):
		if line.get("label", "") == combo.get("label", ""):
			return true
	return false


func _flash_impact(label: Label) -> void:
	if not is_instance_valid(label):
		return
	var tween := create_tween()
	tween.tween_property(label, "modulate", Color(1.0, 0.82, 0.24, 1.0), 0.08)
	tween.tween_property(label, "modulate", Color.WHITE, 0.22)


func _shake_score_replay() -> void:
	var origin := score_replay.position
	var tween := create_tween()
	tween.tween_property(score_replay, "position:x", origin.x + 4.0, 0.035)
	tween.tween_property(score_replay, "position:x", origin.x - 3.0, 0.045)
	tween.tween_property(score_replay, "position:x", origin.x, 0.05)


func _squad_display_name(squad_id: String) -> String:
	for squad in SprintState.squads:
		if squad.get("id", "") == squad_id:
			return squad.get("name", "Equipe produit")
	return "Equipe produit"


func _setup_score_audio() -> void:
	_score_tone_stream = AudioStreamWAV.new()
	_score_tone_stream.format = AudioStreamWAV.FORMAT_8_BITS
	_score_tone_stream.mix_rate = 22050
	_score_tone_stream.stereo = false
	var frames := 420
	var samples := PackedByteArray()
	samples.resize(frames)
	for frame in frames:
		var envelope := 1.0 - float(frame) / float(frames)
		var phase := TAU * float(frame) * 220.0 / float(_score_tone_stream.mix_rate)
		samples[frame] = clampi(int(round(128.0 + sin(phase) * 11.0 * envelope)), 0, 255)
	_score_tone_stream.data = samples
	score_audio.stream = _score_tone_stream


func _play_score_tick(step: int) -> void:
	if _score_tone_stream == null:
		return
	if step != _score_last_audio_step:
		_score_last_audio_step = step
		_score_audio_step_ticks = 0
	_score_audio_step_ticks += 1
	score_audio.pitch_scale = min(1.8, 0.9 + 0.08 * (_score_audio_step_ticks - 1))
	score_audio.stop()
	score_audio.play()


func _unhandled_input(event: InputEvent) -> void:
	if _score_finished or not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	_score_replay_clicks += 1
	if _score_replay_clicks == 1:
		_accelerate_score_replay()
	else:
		_reveal_score_replay()
	get_viewport().set_input_as_handled()


func _accelerate_score_replay() -> void:
	if _score_finished:
		return
	_score_replay_speed = 4.0
	score_status.text = "Rythme rapide"


func _reveal_score_replay() -> void:
	if _score_finished:
		return
	_score_replay_token += 1
	while _score_event_index < _score_events.size():
		_reveal_next_score_event()
	_finish_score_replay()


func _finish_score_replay() -> void:
	if _score_finished:
		return
	_score_finished = true
	score_status.text = "Score final"


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
			revenue_label.text = "💰 %s : +%d (dont ROI backlog +%d)  ·  👥 Masse salariale : −%d  ·  💸 Décisions : %s%d  ·  Net trésorerie : %s%d  ·  🪙 Budget %s%d (solde %d)" % [
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
		verdict.text = "Le comité applaudit poliment. +%d 🪙 de Budget d'investissement, 🎯 Capital politique +%d." % [
			int(review_conf.get("successPieces", 5)), int(review_conf.get("successCapitalPolitique", 8))
		]
		verdict.add_theme_color_override("font_color", UIHelpers.COLOR_GOOD)
	else:
		verdict.text = "Le comité « prend note ». 🎯 Capital politique %d, et l'allocation plancher tombe à %d 🪙/sprint pour le reste du mandat." % [
			int(review_conf.get("failCapitalPolitique", -12)),
			int(GameData.scoring.get("conversion", {}).get("budget", {}).get("failedReviewAllocation", 1))
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
			# La Valeur perçue ne déclenche plus de fin directe et ne coupe plus
			# artificiellement le MRR : elle reste une pression de marché.
			if worst_resource.get("id", "") == "valeur-percue":
				return "⚠️ 📈 Valeur perçue en zone critique — une livraison forte devient urgente."
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
