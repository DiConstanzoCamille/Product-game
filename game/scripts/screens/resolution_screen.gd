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
const COMMITTEE_SCENE := "res://scenes/screens/committee_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var era_label: Label = $Margin/VBox/Scroll/Content/HeroCard/Margin/HeaderVBox/HeaderRow/EraLabel
@onready var cpo_label: Label = $Margin/VBox/Scroll/Content/HeroCard/Margin/HeaderVBox/HeaderRow/CpoLabel
@onready var revenue_label: Label = $Margin/VBox/Scroll/Content/HeroCard/Margin/HeaderVBox/RevenueLabel
@onready var economics_detail: Label = $Margin/VBox/Scroll/Content/HeroCard/Margin/HeaderVBox/EconomicsDetail
@onready var impact_card: PanelContainer = $Margin/VBox/Scroll/Content/ImpactCard
@onready var impact_eyebrow: Label = $Margin/VBox/Scroll/Content/ImpactCard/Margin/VBox/ImpactEyebrow
@onready var impact_value: Label = $Margin/VBox/Scroll/Content/ImpactCard/Margin/VBox/ImpactValue
@onready var impact_progress: ProgressBar = $Margin/VBox/Scroll/Content/ImpactCard/Margin/VBox/ImpactProgress
@onready var impact_context: Label = $Margin/VBox/Scroll/Content/ImpactCard/Margin/VBox/ImpactContext
@onready var score_replay: VBoxContainer = $Margin/VBox/Scroll/Content/ScoreCard/Margin/ScoreReplay
@onready var score_title: Label = $Margin/VBox/Scroll/Content/ScoreCard/Margin/ScoreReplay/ScoreHeader/ScoreTitle
@onready var score_status: Label = $Margin/VBox/Scroll/Content/ScoreCard/Margin/ScoreReplay/ScoreHeader/ScoreStatus
@onready var score_lines: VBoxContainer = $Margin/VBox/Scroll/Content/ScoreCard/Margin/ScoreReplay/ScoreLines
@onready var quota_card: PanelContainer = $Margin/VBox/Scroll/Content/QuotaCard
@onready var quota_replay: VBoxContainer = $Margin/VBox/Scroll/Content/QuotaCard/Margin/QuotaReplay
@onready var quota_title: Label = $Margin/VBox/Scroll/Content/QuotaCard/Margin/QuotaReplay/QuotaHeader/QuotaTitle
@onready var quota_status: Label = $Margin/VBox/Scroll/Content/QuotaCard/Margin/QuotaReplay/QuotaHeader/QuotaStatus
@onready var quota_progress: ProgressBar = $Margin/VBox/Scroll/Content/QuotaCard/Margin/QuotaReplay/QuotaProgress
@onready var quota_label: Label = $Margin/VBox/Scroll/Content/QuotaCard/Margin/QuotaReplay/QuotaLabel
@onready var quota_verdict: Label = $Margin/VBox/Scroll/Content/QuotaCard/Margin/QuotaReplay/QuotaVerdict
@onready var gauges_grid: GridContainer = $Margin/VBox/Scroll/Content/ResourcesCard/Margin/VBox/GaugesGrid
@onready var journal_title: Label = $Margin/VBox/Scroll/Content/JournalCard/Margin/VBox/JournalTitle
@onready var journal_container: VBoxContainer = $Margin/VBox/Scroll/Content/JournalCard/Margin/VBox/JournalContainer
@onready var alert_label: Label = $Margin/VBox/Scroll/Content/JournalCard/Margin/VBox/AlertLabel
@onready var resources_card: PanelContainer = $Margin/VBox/Scroll/Content/ResourcesCard
@onready var journal_card: PanelContainer = $Margin/VBox/Scroll/Content/JournalCard
@onready var stat_strip: PanelContainer = $Margin/VBox/StatStrip
@onready var stats: HBoxContainer = $Margin/VBox/StatStrip/Margin/Stats
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
var _impact_total := 0
var _impact_event_count := 0
var _impact_revealed_count := 0
var _impact_tween: Tween
var _strip_stat_tweens: Array[Tween] = []
var _quota_data: Dictionary = {}
var _quota_before := 0
var _quota_started := false
var _quota_finished := false
var _quota_replay_token := 0
var _quota_tween: Tween


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	foundations_button.pressed.connect(func(): get_tree().change_scene_to_file(FOUNDATIONS_SCENE))
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 4 : Résolution" % SprintState.sprint_number

	var old_values: Dictionary = SprintState.resource_values.duplicate()
	mandate_ending = SprintState.apply_pending_and_check()
	UIHelpers.attach_company_menu(self)
	_style_resolution_sections()

	_load_hud(old_values)
	_setup_next_button()
	_setup_breather_button()
	_setup_quota_replay()
	_setup_score_replay()


func _exit_tree() -> void:
	_score_replay_token += 1
	_quota_replay_token += 1
	_score_finished = true
	if is_instance_valid(score_audio):
		score_audio.stop()
		score_audio.stream = null
	_score_tone_stream = null


func _style_resolution_sections() -> void:
	_style_section($Margin/VBox/Scroll/Content/HeroCard, UIHelpers.PANEL_BG, UIHelpers.COLOR_INK, 2)
	_style_section(impact_card, Color("#173b70"), UIHelpers.COLOR_SHELF, 2)
	_style_section($Margin/VBox/Scroll/Content/ScoreCard, Color("#ffffff"), UIHelpers.COLOR_SHELF, 2)
	_style_section($Margin/VBox/Scroll/Content/QuotaCard, Color("#fff7de"), UIHelpers.COLOR_AMBER, 1)
	_style_section($Margin/VBox/Scroll/Content/ResourcesCard, Color("#ffffff"), UIHelpers.COLOR_RULE, 1)
	_style_section($Margin/VBox/Scroll/Content/JournalCard, Color("#eef1f4"), UIHelpers.COLOR_RULE, 1)
	_style_section(stat_strip, UIHelpers.PANEL_BG, UIHelpers.COLOR_INK, 2)
	if era_label != null:
		era_label.add_theme_color_override("font_color", UIHelpers.PANEL_FG)
	if cpo_label != null:
		cpo_label.add_theme_color_override("font_color", UIHelpers.PANEL_MUTED)
	if economics_detail != null:
		economics_detail.add_theme_color_override("font_color", UIHelpers.PANEL_MUTED)
	if score_title != null:
		UIHelpers.apply_heading(score_title, 20, 650.0)
	UIHelpers.apply_mono(impact_eyebrow, 12, true)
	impact_eyebrow.add_theme_color_override("font_color", Color("#b7cef8"))
	impact_value.add_theme_color_override("font_color", Color("#ffffff"))
	impact_context.add_theme_color_override("font_color", Color("#d7e5ff"))
	impact_progress.add_theme_stylebox_override("fill", UIHelpers.make_bar_fill_style(UIHelpers.COLOR_AMBER))
	impact_progress.add_theme_stylebox_override("background", UIHelpers.make_bar_background_style())
	var resources_title := get_node_or_null("Margin/VBox/Scroll/Content/ResourcesCard/Margin/VBox/ResourcesTitle") as Label
	if resources_title != null:
		UIHelpers.apply_mono(resources_title, 12, true)


func _style_section(panel: PanelContainer, background: Color, border: Color, border_width: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(12)
	style.shadow_color = UIHelpers.SHADOW_COLOR
	style.shadow_size = 6
	style.shadow_offset = Vector2(2, 3)
	panel.add_theme_stylebox_override("panel", style)


func _load_hud(old_values: Dictionary) -> void:
	var era: Dictionary = SprintState.get_era()
	UIHelpers.apply_heading(era_label, 17, 650.0)
	era_label.text = "%s %s — Sprint %d" % [era.get("icon", ""), era.get("name", ""), SprintState.sprint_number]
	cpo_label.text = "CPO : Vous · profil %s" % SprintState.team_profile.capitalize()
	cpo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	revenue_label.text = "VOS CHOIX ENTRENT EN JEU"
	revenue_label.add_theme_color_override("font_color", UIHelpers.PANEL_FG)
	economics_detail.text = "Chaque décision est expliquée ici, puis son effet fait monter l'impact du sprint."

	resources_card.visible = false
	journal_card.visible = false
	for index in GameData.resources.size():
		stats.add_child(_build_strip_stat(GameData.resources[index], old_values, index))

	journal_title.text = "JOURNAL DU SPRINT"
	UIHelpers.apply_mono(journal_title, 12, true)
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
	_impact_total = 0
	_impact_event_count = 0
	_impact_revealed_count = 0

	var report: Dictionary = SprintState.last_score_report
	if report.is_empty():
		score_replay.visible = false
		_finish_score_replay()
		return
	score_replay.visible = true
	score_title.text = "VOS CHOIX CE SPRINT"
	score_status.text = "Ils vont se combiner"
	var squad_reports: Array = report.get("squads", [])
	for squad_report in squad_reports:
		var delivery_lines: Array = []
		for line in squad_report.get("lines", []):
			if line.get("type", "") == "traction_add" and int(line.get("step", 0)) == 1:
				delivery_lines.append(line)
		if not delivery_lines.is_empty():
			_add_score_divider("LIVRAISONS PRODUIT")
			for line in delivery_lines:
				_add_score_event(line, _choice_copy_for_delivery(line))

	var team_choices := _team_choice_lines(squad_reports)
	if not team_choices.is_empty():
		_add_score_divider("ÉQUIPE MOBILISÉE")
		for choice in team_choices:
			_add_score_event(choice.get("line", {}), choice)

	var factor_lines: Array = _external_factor_lines(report.get("global", {}).get("lines", []))
	if not factor_lines.is_empty():
		_add_score_divider("LEVIERS & FRICTIONS")
		var factor_choice := _external_factor_choice(factor_lines)
		_add_score_event(factor_choice.get("line", {}), factor_choice)

	for line in report.get("global", {}).get("lines", []):
		if line.get("type", "") == "impact":
			_add_score_event(line, _choice_copy_for_impact(line))
			_impact_total = int(round(float(line.get("after", line.get("value", 0.0)))))

	# 💼📣🎧 Équipes subies (spec §9.4) : leur taux de conversion, visible à
	# l'étape ⑨ — après l'Impact, puisqu'elles convertissent l'Impact déjà
	# résolu, jamais un levier ou une friction dessus.
	var conversion_rate_lines := _conversion_rate_lines(report.get("global", {}).get("lines", []))
	if not conversion_rate_lines.is_empty():
		_add_score_divider("CONVERSION — ÉQUIPES SUBIES")
		for line in conversion_rate_lines:
			_add_score_event(line, _choice_copy_for_conversion_rate(line))

	_set_impact_quarter_display(_quota_before, false)

	if _score_events.is_empty():
		score_status.text = "Aucun score ce sprint"
		_finish_score_replay()
		return
	_setup_score_audio()
	_score_replay_token += 1
	_replay_score_report(_score_replay_token)


func _add_score_event(line: Dictionary, choice: Dictionary = {}) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 34)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 14)
	button.visible = false
	var display: String = choice.get("display", _format_choice_line(line))
	var detail: String = choice.get("detail", _technical_detail(line))
	button.text = display
	button.tooltip_text = "Plus d'info"
	button.pressed.connect(func(): _open_choice_details(display, detail))
	score_lines.add_child(button)
	_score_events.append({"kind": "line", "line": line, "node": button, "display": display, "detail": detail})
	_impact_event_count += 1


func _add_score_divider(squad_id: String) -> void:
	var divider := Label.new()
	divider.text = _squad_display_name(squad_id)
	if squad_id == "LIVRAISONS PRODUIT" or squad_id == "ÉQUIPE MOBILISÉE" or squad_id == "LEVIERS & FRICTIONS":
		divider.text = squad_id
	divider.custom_minimum_size = Vector2(0, 20)
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
	var node: Control = event["node"]
	node.visible = true
	if event.get("kind", "line") == "divider":
		return
	var line: Dictionary = event["line"]
	var button := node as Button
	_style_choice_line(button, line)
	_animate_choice_line(button, event)
	_update_impact_projection(line)
	_update_strip_stats()
	_play_score_tick(int(line.get("step", 0)))
	if _is_combo_line(line):
		_shake_score_replay()


func _animate_choice_line(button: Button, event: Dictionary) -> void:
	button.modulate.a = 0.0
	button.position.x -= 14.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "modulate:a", 1.0, 0.16 / _score_replay_speed)
	tween.tween_property(button, "position:x", button.position.x + 14.0, 0.16 / _score_replay_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if event.get("line", {}).get("type", "") == "impact":
		tween.chain().tween_callback(func(): _flash_impact(button))


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
	if type == "conversion_rate":
		return "%s  %s  ×%s" % [icon, label, String.num(float(line.get("value", 1.0)), 2)]
	var value := float(line.get("value", 0.0))
	var prefix := "+" if value >= 0.0 else "-"
	return "%s  %s  %s%s   %s -> %s" % [icon, label, prefix, _score_number(abs(value)), _score_number(before), _score_number(current)]


func _format_choice_line(line: Dictionary) -> String:
	var icon: String = line.get("icon", "•")
	var label: String = line.get("label", "Facteur")
	var line_type: String = line.get("type", "")
	var value := float(line.get("value", 0.0))
	if line_type == "traction_add":
		return "%s %s  ·  +%s traction" % [icon, label, _score_number(value)]
	if line_type == "lever_add":
		return "%s %s  ·  %s%s levier" % [icon, label, "+" if value >= 0.0 else "", _score_number(value)]
	if line_type == "traction_multiplier" or line_type == "impact_multiplier":
		return "%s %s  ·  ×%s impact" % [icon, label, String.num(value, 2)]
	if line_type == "budget_add":
		return "%s %s  ·  +%s budget" % [icon, label, _score_number(value)]
	if line_type == "impact":
		return "%s Impact final  ·  %s" % [icon, _score_number(float(line.get("after", value)))]
	if line_type == "conversion_rate":
		return "%s %s  ·  ×%s" % [icon, label, String.num(value, 2)]
	return "%s %s" % [icon, label]


func _choice_copy_for_delivery(line: Dictionary) -> Dictionary:
	return {
		"display": _format_choice_line(line),
		"detail": "Cette feature a été réellement livrée ce sprint. Elle apporte de la traction avant que l'équipe et les leviers de l'organisation ne la transforment en impact.\n\nCalcul : %s" % _format_score_line(line, float(line.get("after", 0.0))),
	}


func _choice_copy_for_factor(line: Dictionary) -> Dictionary:
	var detail := "Ce facteur vient de votre organisation : outil, pratique, stratégie ou contrainte actuelle.\n\nCalcul : %s" % _format_score_line(line, float(line.get("after", 0.0)))
	if int(line.get("step", 0)) == 7:
		detail = "C'est un frein issu de l'état de l'entreprise. Il réduit l'impact potentiel du sprint.\n\nCalcul : %s" % _format_score_line(line, float(line.get("after", 0.0)))
	return {"display": _format_choice_line(line), "detail": detail}


func _choice_copy_for_impact(line: Dictionary) -> Dictionary:
	return {
		"display": _format_choice_line(line),
		"detail": "L'impact final combine les livraisons, les bonus de l'équipe, vos investissements et les freins de l'organisation. Il alimente ensuite le quota trimestriel.\n\nCalcul : %s" % _format_score_line(line, float(line.get("after", 0.0))),
	}


func _team_choice_lines(squad_reports: Array) -> Array:
	var choices: Array = []
	for squad_report in squad_reports:
		var squad_id: String = squad_report.get("id", "")
		var roster: Array = []
		for squad in SprintState.squads:
			if squad.get("id", "") == squad_id:
				roster = squad.get("roster", [])
				break
		var delivered_count := int(squad_report.get("delivered_count", 0))
		var role_lines: Array = squad_report.get("lines", [])
		for role_id in ["dev", "designer", "pm", "ops"]:
			var members: Array = _members_with_role(roster, role_id)
			if members.is_empty():
				continue
			var role_conf: Dictionary = GameData.balance.get("roles", {}).get(role_id, {})
			var role_label: String = role_conf.get("label", role_id.capitalize())
			var icon: String = role_conf.get("icon", "👤")
			var names := ", ".join(members)
			var score_line := _matching_role_score_line(role_lines, role_label)
			var display := ""
			var detail := ""
			if not score_line.is_empty():
				display = "%s %s  ·  %s" % [icon, names, _format_choice_line(score_line).split("·", false, 1)[1].strip_edges()]
				detail = "%s mobilise son rôle de %s pour ce sprint.\n\nCalcul : %s" % [names, role_label, _format_score_line(score_line, float(score_line.get("after", 0.0)))]
			else:
				var capacity: int = 0
				for member in roster:
					if member.get("role", "") == role_id:
						capacity += int(role_conf.get("capacityPerEmployee", {}).get(member.get("seniority", "junior"), 0))
				if role_id == "dev":
					display = "%s %s  ·  capacité de livraison %d pts" % [icon, names, capacity]
					detail = "%s portent la réalisation des features. Leur capacité a permis de planifier les livraisons de ce sprint." % names
				elif role_id == "ops":
					display = "%s %s  ·  stabilise la dette de l'organisation" % [icon, names]
					detail = "%s assure l'Ops : la dette organisationnelle est contenue à chaque Résolution." % names
				else:
					display = "%s %s  ·  mobilisé%s sur %d livraison%s" % [icon, names, "s" if members.size() > 1 else "", delivered_count, "s" if delivered_count > 1 else ""]
					detail = "%s sont mobilisés comme %s. Leur bonus ne s'active que lorsque les conditions du sprint sont réunies." % [names, role_label]
			var synthetic_line := score_line.duplicate(true)
			if synthetic_line.is_empty():
				synthetic_line = {"icon": icon, "label": role_label, "type": "team", "value": 0.0, "after": 0.0, "step": 3}
			choices.append({"line": synthetic_line, "display": display, "detail": detail})
	if choices.size() <= 1:
		return choices
	var names: Array = []
	var summaries: Array = []
	var details: Array = []
	var representative: Dictionary = choices[0].get("line", {})
	for choice in choices:
		var display: String = choice.get("display", "")
		var before_effect := display.split("·", false, 1)[0].strip_edges()
		var effect := display.split("·", false, 1)[1].strip_edges() if display.contains("·") else display
		if before_effect != "":
			names.append(before_effect)
		summaries.append(effect)
		details.append(choice.get("detail", ""))
	return [{
		"line": representative,
		"display": "👥 %s  ·  %s" % [", ".join(names), " · ".join(summaries)],
		"detail": "Voici les personnes mobilisées et leur effet dans ce sprint :\n\n%s" % "\n\n".join(details),
	}]


func _members_with_role(roster: Array, role_id: String) -> Array:
	var names: Array = []
	for member in roster:
		if member.get("role", "") == role_id:
			names.append(str(member.get("name", role_id.capitalize())))
	return names


func _matching_role_score_line(lines: Array, role_label: String) -> Dictionary:
	for line in lines:
		if int(line.get("step", 0)) == 3 and line.get("label", "") == role_label:
			return line
	return {}


## 💼📣🎧 Équipes subies (spec §9.4) : jamais pilotables, jamais dans le
## roster — seul leur taux de conversion, fixé par l'entreprise, se voit ici.
func _conversion_rate_lines(lines: Array) -> Array:
	var rates: Array = []
	for line in lines:
		if line.get("type", "") == "conversion_rate":
			rates.append(line)
	return rates


func _choice_copy_for_conversion_rate(line: Dictionary) -> Dictionary:
	return {
		"display": _format_choice_line(line),
		"detail": "Équipe subie : elle n'est pas dans votre roster et n'est pilotable d'aucune façon. Son niveau est fixé par l'entreprise au début du run.\n\nCalcul : %s" % _format_score_line(line, float(line.get("value", 1.0))),
	}


func _external_factor_lines(lines: Array) -> Array:
	var factors: Array = []
	for line in lines:
		var line_type: String = line.get("type", "")
		if line_type == "impact" or line_type == "mrr" or line_type == "budget" or line_type == "resource_delta":
			continue
		if line_type == "lever_add" or line_type == "traction_multiplier" or line_type == "impact_multiplier" or line_type == "total_lever_cap":
			factors.append(line)
	return factors


func _external_factor_choice(lines: Array) -> Dictionary:
	var labels: Array = []
	var details: Array = []
	var representative: Dictionary = lines[0]
	for line in lines:
		labels.append(_format_choice_line(line))
		details.append(_choice_copy_for_factor(line).get("detail", ""))
	var preview := " · ".join(labels.slice(0, 2))
	if labels.size() > 2:
		preview += " · +%d autre%s" % [labels.size() - 2, "s" if labels.size() > 3 else ""]
	return {
		"line": representative,
		"display": "🧰 Fondations & contexte  ·  %s" % preview,
		"detail": "Ces choix et contraintes modulent le résultat de la livraison :\n\n%s" % "\n\n".join(details),
	}


func _style_choice_line(button: Button, line: Dictionary) -> void:
	var positive := float(line.get("value", 0.0)) >= 0.0
	var is_friction := int(line.get("step", 0)) == 7
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f7f9fc") if not is_friction else Color("#fff2ef")
	style.border_color = UIHelpers.COLOR_RULE if not is_friction else UIHelpers.COLOR_DANGER
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#eaf1fc")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_color_override("font_color", UIHelpers.COLOR_DANGER if is_friction else (UIHelpers.COLOR_INK if positive else UIHelpers.COLOR_DANGER))


func _update_impact_projection(line: Dictionary) -> void:
	_impact_revealed_count += 1
	var sprint_projection := 0
	if line.get("type", "") == "impact":
		sprint_projection = _impact_total
	else:
		var ratio := float(_impact_revealed_count) / float(max(1, _impact_event_count))
		sprint_projection = int(round(float(_impact_total) * ratio))
	var target := _quota_before + sprint_projection
	if is_instance_valid(_impact_tween):
		_impact_tween.kill()
	var from := float(impact_progress.value)
	_impact_tween = create_tween()
	_impact_tween.tween_method(func(value: float):
		if is_instance_valid(impact_value):
			_set_impact_quarter_display(int(round(value)), line.get("type", "") == "impact")
	, from, float(target), 0.22 / _score_replay_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_impact_quarter_display(value: int, final: bool) -> void:
	var quota: int = maxi(1, int(_quota_data.get("quota", 1)))
	var quarter: int = int(_quota_data.get("quarter", SprintState.quarter_index))
	var clamped: int = clampi(value, 0, quota)
	impact_eyebrow.text = "IMPACT TRIMESTRIEL · T%d" % quarter
	impact_progress.max_value = quota
	impact_progress.value = clamped
	impact_value.text = "%d / %d" % [clamped, quota]
	var sprint_gain: int = maxi(0, clamped - _quota_before)
	if final:
		impact_context.text = "Objectif trimestriel : %d · ce sprint +%d" % [quota, sprint_gain]
	else:
		impact_context.text = "Objectif trimestriel : %d · ce sprint +%d en cours" % [quota, sprint_gain]


func _update_strip_stats() -> void:
	var ratio := float(_impact_revealed_count) / float(max(1, _impact_event_count))
	for child in stats.get_children():
		var box := child as Control
		if box == null or not box.has_meta("strip_old"):
			continue
		var old_value: float = float(box.get_meta("strip_old"))
		var new_value: float = float(box.get_meta("strip_new"))
		var bar := box.get_meta("strip_bar") as ProgressBar
		var value_label := box.get_meta("strip_value") as Label
		if bar == null or value_label == null:
			continue
		var target := lerpf(old_value, new_value, ratio)
		var tween := create_tween()
		tween.tween_method(func(current: float):
			if is_instance_valid(bar) and is_instance_valid(value_label):
				bar.value = current
				value_label.text = "%d" % int(round(current))
		, float(bar.value), target, 0.18 / _score_replay_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_strip_stat_tweens.append(tween)


func _technical_detail(line: Dictionary) -> String:
	return "Détail du calcul appliqué à ce choix :\n\n%s" % _format_score_line(line, float(line.get("after", 0.0)))


func _open_choice_details(title_text: String, detail_text: String) -> void:
	var overlay := ColorRect.new()
	overlay.name = "ChoiceDetailsOverlay"
	overlay.color = Color(0.02, 0.05, 0.1, 0.64)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	_style_section(panel, Color("#ffffff"), UIHelpers.COLOR_SHELF, 2)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	var eyebrow := Label.new()
	eyebrow.text = "PLUS D'INFO"
	UIHelpers.apply_mono(eyebrow, 12, true)
	eyebrow.add_theme_color_override("font_color", UIHelpers.COLOR_SHELF)
	vbox.add_child(eyebrow)
	var title := Label.new()
	title.text = title_text
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIHelpers.apply_heading(title, 21, 650.0)
	vbox.add_child(title)
	var detail := Label.new()
	detail.text = detail_text
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 14)
	vbox.add_child(detail)
	var close := Button.new()
	close.text = "Fermer"
	close.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(close)


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


func _flash_impact(control: Control) -> void:
	if not is_instance_valid(control):
		return
	var tween := create_tween()
	tween.tween_property(control, "modulate", Color(1.0, 0.82, 0.24, 1.0), 0.08)
	tween.tween_property(control, "modulate", Color.WHITE, 0.22)


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
	if _quota_started:
		quota_status.text = "Rythme rapide"
		if is_instance_valid(_quota_tween):
			_quota_tween.set_speed_scale(_score_replay_speed)
	else:
		score_status.text = "Rythme rapide"


func _reveal_score_replay() -> void:
	if _score_finished:
		return
	_score_replay_token += 1
	while _score_event_index < _score_events.size():
		_reveal_next_score_event()
	if _quota_started:
		_reveal_quota_replay()
		return
	_finish_score_replay()
	if _quota_started and not _quota_finished:
		_reveal_quota_replay()


func _finish_score_replay() -> void:
	if _score_finished:
		return
	if not _quota_started and not _quota_data.is_empty():
		_start_quota_replay()
		return
	_score_finished = true
	score_status.text = "Score final"


## Le quota est volontairement hors de la sequence ScoreResolver : le score
## explique le sprint, puis son Impact vient s'inscrire dans la course du
## trimestre. C'est le dernier temps du replay, y compris lors de la
## revelation instantanee au second clic.
func _setup_quota_replay() -> void:
	quota_card.visible = false
	quota_replay.visible = false
	quota_verdict.text = ""
	_quota_started = false
	_quota_finished = false
	var result: Dictionary = SprintState.quarter_result
	if int(result.get("sprint", -1)) == SprintState.sprint_number:
		_quota_data = result.duplicate(true)
	else:
		_quota_data = SprintState.get_quarter_progress()
	var impact := int(_quota_data.get("impact", 0))
	var sprint_impact := int(SprintState.last_score_report.get("global", {}).get("impact", 0))
	_quota_before = max(0, impact - sprint_impact)
	quota_title.text = "Impact trimestriel · T%d" % int(_quota_data.get("quarter", SprintState.quarter_index))
	quota_progress.max_value = max(1, int(_quota_data.get("quota", 1)))
	quota_progress.value = _quota_before
	quota_progress.show_percentage = false
	quota_progress.add_theme_stylebox_override("fill", UIHelpers.make_bar_fill_style(UIHelpers.COLOR_AMBER))
	quota_progress.add_theme_stylebox_override("background", UIHelpers.make_bar_background_style())


func _start_quota_replay() -> void:
	_quota_started = true
	quota_card.visible = false
	quota_replay.visible = false
	_finish_quota_replay()


func _set_quota_display(value: int, final: bool) -> void:
	var quota := int(_quota_data.get("quota", 0))
	quota_progress.value = clampi(value, 0, max(1, quota))
	quota_label.text = "Impact brut %d / %d" % [value, quota]
	_set_impact_quarter_display(value, final)
	if final and _quota_data.has("passed"):
		var passed := bool(_quota_data.get("passed", false))
		quota_status.text = "Quota atteint" if passed else "Quota manqué"
		quota_verdict.text = _quota_verdict_text(_quota_data)
		quota_verdict.add_theme_color_override("font_color", UIHelpers.COLOR_GOOD if passed else UIHelpers.COLOR_DANGER)
	else:
		quota_status.text = "Impact du sprint"


func _reveal_quota_replay() -> void:
	if _quota_data.is_empty():
		_finish_quota_replay()
		return
	_quota_replay_token += 1
	if is_instance_valid(_quota_tween):
		_quota_tween.kill()
	quota_card.visible = false
	quota_replay.visible = false
	_set_quota_display(int(_quota_data.get("impact", 0)), true)
	_finish_quota_replay()


func _finish_quota_replay() -> void:
	if _quota_finished:
		return
	_quota_finished = true
	_quota_tween = null
	_set_quota_display(int(_quota_data.get("impact", 0)), true)
	_score_finished = true
	score_status.text = "Score final"
	if _quota_data.has("passed"):
		_show_quarter_verdict_overlay.call_deferred()


func _quota_verdict_text(result: Dictionary) -> String:
	var bonus := int(result.get("qualitativeBonus", 0))
	if bool(result.get("passed", false)):
		return "Quota atteint.%s" % (" Objectifs qualitatifs tenus : +%d Budget." % bonus if bonus > 0 else " Les objectifs qualitatifs restent un bonus de +8 Budget.")
	return "Quota non atteint : la mission s'arrête ici."


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
	var net: int = revenue - payroll + cost
	var model_label: String = model.get("label", "Revenu")

	revenue_label.add_theme_color_override("font_color", UIHelpers.COLOR_GOOD if net >= 0 else UIHelpers.COLOR_DANGER)
	economics_detail.text = "%s +%d  ·  Masse salariale −%d  ·  Décisions %s%d  ·  Budget %s%d (solde %d)" % [
		model_label, revenue, payroll,
		"+" if cost >= 0 else "−", abs(cost),
		"+" if pieces_delta >= 0 else "−", abs(pieces_delta), SprintState.pieces,
	]

	var tween := create_tween()
	tween.tween_method(
		func(v: float):
			revenue_label.text = "NET TRÉSORERIE  %s%d" % ["+" if int(round(v)) - payroll + cost >= 0 else "−", abs(int(round(v)) - payroll + cost)],
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

	var content: Node = $Margin/VBox/Scroll/Content/HeroCard/Margin/HeaderVBox
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
	var content: Node = $Margin/VBox/Scroll/Content/HeroCard/Margin/HeaderVBox
	content.add_child(label)
	content.move_child(label, economics_detail.get_index() + 1)


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


## Le verdict trimestriel ferme le replay. Il ne mélange jamais le quota et les
## objectifs qualitatifs : ces derniers ne peuvent donner qu'un bonus Budget.
func _show_quarter_verdict_overlay() -> void:
	if int(_quota_data.get("sprint", -1)) != SprintState.sprint_number:
		return
	var result: Dictionary = _quota_data
	var passed: bool = bool(result.get("passed", false))

	var dim := ColorRect.new()
	dim.name = "QuarterVerdictOverlay"
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
	eyebrow.text = "TRIMESTRE %d — VERDICT DU QUOTA" % int(result.get("quarter", 0))
	UIHelpers.apply_mono(eyebrow, 12, true)
	eyebrow.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	vbox.add_child(eyebrow)

	var title := Label.new()
	title.text = "Quota atteint" if passed else "Quota manqué"
	UIHelpers.apply_heading(title, 24, 700.0)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title)

	var impact := Label.new()
	impact.text = "Impact brut %d / %d" % [int(result.get("impact", 0)), int(result.get("quota", 0))]
	impact.add_theme_font_size_override("font_size", 18)
	vbox.add_child(impact)

	for condition in result.get("objectives", []):
		var line := Label.new()
		line.text = "%s  %s" % ["✓" if condition.get("ok", false) else "○", condition.get("label", "")]
		line.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(line)

	var verdict := Label.new()
	if passed:
		var bonus := int(result.get("qualitativeBonus", 0))
		verdict.text = "Le quota porte le trimestre. %s" % ("Les objectifs qualitatifs ajoutent +%d Budget." % bonus if bonus > 0 else "Les objectifs qualitatifs sont un bonus, jamais une condition de passage.")
		verdict.add_theme_color_override("font_color", UIHelpers.COLOR_GOOD)
	else:
		verdict.text = "Le quota n'est pas atteint. Le mandat se termine."
		verdict.add_theme_color_override("font_color", UIHelpers.COLOR_DANGER)
	verdict.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(verdict)

	if not passed:
		var end_btn := Button.new()
		end_btn.text = "Voir le résultat du mandat →"
		UIHelpers.style_primary_button(end_btn)
		end_btn.pressed.connect(func(): get_tree().change_scene_to_file(MANDATE_END_SCENE))
		vbox.add_child(end_btn)
		return

	if SprintState.quarter_exit_choice_pending:
		var exit_btn := Button.new()
		exit_btn.name = "ExitMandateButton"
		exit_btn.text = "Quitter sur cette victoire"
		exit_btn.pressed.connect(_on_exit_mandate_pressed)
		vbox.add_child(exit_btn)
		var stay_btn := Button.new()
		stay_btn.name = "StayLongMandateButton"
		stay_btn.text = "Rester pour le mandat long"
		UIHelpers.style_primary_button(stay_btn)
		stay_btn.pressed.connect(_on_stay_long_mandate_pressed.bind(dim))
		vbox.add_child(stay_btn)
		return

	var close_btn := Button.new()
	close_btn.text = "Reprendre le sprint →"
	close_btn.pressed.connect(func(): dim.queue_free())
	vbox.add_child(close_btn)


func _on_exit_mandate_pressed() -> void:
	SprintState.choose_mandate_path(false)
	get_tree().change_scene_to_file(MANDATE_END_SCENE)


func _on_stay_long_mandate_pressed(dim: Control) -> void:
	if SprintState.choose_mandate_path(true) != "":
		return
	if is_instance_valid(dim):
		dim.queue_free()
	next_sprint_button.disabled = false
	next_sprint_button.text = "Voir le Comité d'investissement →" if _quarter_just_closed() else "Sprint suivant →"
	next_sprint_button.pressed.connect(_on_next_sprint_pressed)


## Bandeau fixe : le résultat de la run reste sous les yeux pendant que la
## partie haute rejoue les choix et le calcul de l'Impact.
func _build_strip_stat(resource: Dictionary, old_values: Dictionary, index: int) -> Control:
	var resource_id: String = resource.get("id", "")
	var old_value: float = old_values.get(resource_id, 0.0)
	var new_value: float = SprintState.resource_values.get(resource_id, 0.0)
	var delta: int = int(round(new_value - old_value))
	var state: String = EffectResolver.gauge_state(resource_id, new_value)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	var header := HBoxContainer.new()
	box.add_child(header)
	var icon := Label.new()
	icon.text = resource.get("icon", "•")
	icon.add_theme_font_size_override("font_size", 13)
	header.add_child(icon)
	var value := Label.new()
	value.text = "%d" % int(round(old_value))
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.add_theme_font_size_override("font_size", 13)
	value.add_theme_color_override("font_color", UIHelpers.PANEL_FG)
	header.add_child(value)
	var delta_label := Label.new()
	delta_label.text = "%+d" % delta if delta != 0 else "—"
	delta_label.add_theme_font_size_override("font_size", 12)
	delta_label.add_theme_color_override("font_color", UIHelpers.panel_state_color(state))
	header.add_child(delta_label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 6)
	bar.max_value = 100
	bar.value = old_value
	bar.show_percentage = false
	bar.add_theme_stylebox_override("fill", UIHelpers.make_bar_fill_style(UIHelpers.panel_state_color(state)))
	bar.add_theme_stylebox_override("background", UIHelpers.make_bar_background_style())
	box.add_child(bar)
	box.set_meta("strip_old", old_value)
	box.set_meta("strip_new", new_value)
	box.set_meta("strip_bar", bar)
	box.set_meta("strip_value", value)
	return box


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
	elif SprintState.quarter_exit_choice_pending:
		next_sprint_button.text = "Choisissez la suite du mandat"
		next_sprint_button.disabled = true
	else:
		next_sprint_button.text = "Voir le Comité d'investissement →" if _quarter_just_closed() else "Sprint suivant →"
		next_sprint_button.pressed.connect(_on_next_sprint_pressed)


## Un trimestre vient de se clôturer sur cette Résolution et le mandat
## continue (quota atteint, mandat long inclus) : `quarter_result.sprint` a
## été enregistré par SprintState._record_quarter_resolution() avec le
## sprint_number *avant* son incrément par _on_next_sprint_pressed — c'est ce
## qui distingue « le trimestre vient de se clore ici » de « il s'est clos il
## y a un sprint ou plus » (voir _test_quarter_result_uses_global_sprint).
func _quarter_just_closed() -> bool:
	var result: Dictionary = SprintState.quarter_result
	return int(result.get("sprint", -1)) == SprintState.sprint_number and bool(result.get("passed", false))


## Le Comité d'investissement (spec §12, Lot 4) s'insère ici, entre la
## Résolution qui clôture un trimestre et l'Inbox du trimestre suivant —
## jamais quand le trimestre continue au fil de l'eau, jamais quand le
## mandat s'arrête (mandate_ending le court-circuite plus haut).
func _on_next_sprint_pressed() -> void:
	var go_to_committee := _quarter_just_closed()
	SprintState.sprint_number += 1
	get_tree().change_scene_to_file(COMMITTEE_SCENE if go_to_committee else INBOX_SCENE)
