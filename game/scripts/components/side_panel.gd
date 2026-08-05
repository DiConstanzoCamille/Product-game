extends PanelContainer
## Le **Panneau de bord** — l'entreprise toujours à l'écran
## (docs/proposition-ui-interface.md §4). Colonne fixe à droite des écrans de
## phase, il remplace la barre de ressources horizontale : ce qu'on consulte à
## chaque décision devient permanent, ce qu'on lit une fois par mandat reste
## derrière le bouton « Dossier entreprise ».
##
## Diégétiquement, c'est l'écran TV du standup accroché au tableau blanc : un
## îlot sombre dans un monde clair (palette UIHelpers.PANEL_*). Il garantit la
## lisibilité des chiffres là où le post-it échouerait.
##
## Trois choix structurants, tous visibles ici :
##  1. les jauges sont des **barres** et non des pourcentages — c'est la
##     géométrie sur laquelle la preview d'impact du Lot 3 viendra projeter son
##     segment fantôme ;
##  2. le roster est lisible d'un coup d'œil et **actionnable en un clic**
##     (🤝 1:1 · licencier, avec confirmation) ;
##  3. le quota et son bonus qualitatif sont **évalués en direct** — la cible
##     et les arbitrages du trimestre restent lisibles à chaque décision.
##
## Aucun état ne vit ici : tout est relu dans SprintState à chaque refresh().
## L'écran hôte appelle refresh() quand il modifie l'état, et écoute
## `state_changed` quand c'est le panneau qui l'a modifié (embauche annulée par
## un licenciement, 1:1 qui consomme de l'Énergie…).
##
## Piège Godot : une barre de jauge est un `Control` nu avec deux `Panel`
## enfants positionnés à la main. Un conteneur étirerait le remplissage sur
## toute la largeur et **toutes les jauges paraîtraient pleines**.

signal state_changed

const BAR_HEIGHT := 8

## Largeur du **rail replié** : de quoi garder les six jauges lisibles en
## vignette et rendre 260 px à l'écran de phase. Sur les Investissements, qui
## empilent deux rayons, ça vaut une colonne de cartes entière.
const RAIL_WIDTH := 62

var collapsed := false

var _dossier: Control = null
var _team_management: Control = null
var _fire_dialog: ConfirmationDialog = null
var _pending_fire_id: String = ""


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = UIHelpers.PANEL_BG
	style.border_color = UIHelpers.COLOR_INK
	style.border_width_left = 8
	add_theme_stylebox_override("panel", style)

	var host := get_parent()
	if host is Control:
		_dossier = UIHelpers.instantiate_company_dossier(host)

	_apply_width()
	_build()


## Le panneau est ancré à droite : sa largeur vient de son `offset_left`, pas
## d'un conteneur. `attach_side_panel()` recale la marge de l'écran hôte sur
## `resized`, donc la place rendue par le rail est immédiatement rendue aux
## cartes.
func _apply_width() -> void:
	var width := RAIL_WIDTH if collapsed else UIHelpers.SIDE_PANEL_WIDTH
	custom_minimum_size = Vector2(width, 0)
	offset_left = -float(width)

	var margin: MarginContainer = get_node("Margin")
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 8 if collapsed else 16)


func _toggle_collapsed() -> void:
	collapsed = not collapsed
	_apply_width()
	_build()


## À appeler après toute modification d'état faite par l'écran hôte (achat,
## embauche, action personnelle) : le panneau est reconstruit de zéro, comme la
## barre de ressources l'était avant lui.
func refresh() -> void:
	_build()
	if _dossier != null and _dossier.has_method("refresh"):
		_dossier.refresh()


func _build() -> void:
	var vbox: VBoxContainer = get_node("Margin/Scroll/VBox")
	# Le panneau se reconstruit depuis ses propres boutons (roster, repli,
	# dossier) : voir UIHelpers.clear_children() pour pourquoi pas de `free()`.
	UIHelpers.clear_children(vbox)

	if collapsed:
		_build_rail(vbox)
		return

	vbox.add_child(_collapse_button("◂  Replier", "Replier le panneau en rail : les six jauges restent lisibles et l'écran récupère %d px." % (UIHelpers.SIDE_PANEL_WIDTH - RAIL_WIDTH)))
	_build_header(vbox)
	vbox.add_child(_rule())

	vbox.add_child(_group_label("Entreprise"))
	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		if resource_id == "capital-politique":
			continue  # celle-là est à vous, pas à l'entreprise : bloc « Vous »
		vbox.add_child(_resource_gauge(resource))
	vbox.add_child(_wallet_row())
	vbox.add_child(_lever_chain_row())
	vbox.add_child(_revenue_row())
	vbox.add_child(_rule())

	vbox.add_child(_group_label("Vous"))
	for resource in GameData.resources:
		if resource.get("id", "") == "capital-politique":
			vbox.add_child(_resource_gauge(resource))
	vbox.add_child(_energy_gauge())
	vbox.add_child(_spaced(_rule(), 8, 0))

	_build_team(vbox)
	_build_assets(vbox)
	_build_quota(vbox)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	filler.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(filler)

	var dossier_button := Button.new()
	dossier_button.text = "🏢 Dossier entreprise"
	dossier_button.tooltip_text = "Le contexte long : scénario, modèle économique, objectifs commentés, roster détaillé, rallonge."
	dossier_button.add_theme_font_size_override("font_size", 13)
	dossier_button.pressed.connect(_on_dossier_pressed)
	vbox.add_child(_spaced(dossier_button, 12, 0))


# ── Le rail replié ───────────────────────────────────────────────────────
## Ce qui survit au repli : les six jauges en vignette (barre + valeur, pas de
## libellé — l'icône suffit une fois qu'on les connaît), les pièces et
## l'Énergie. Tout le reste — roster, actifs, détail du quota — se retrouve en
## dépliant. Les tooltips restent complets : le rail n'enlève pas
## l'information, il enlève la place qu'elle prend.
func _build_rail(vbox: VBoxContainer) -> void:
	vbox.add_child(_collapse_button("▸", "Déplier le Panneau de bord"))

	var sprint := _label("S%d\nT%d" % [SprintState.sprint_number, SprintState.quarter_index], 10, UIHelpers.PANEL_MUTED)
	UIHelpers.apply_mono(sprint, 10)
	sprint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sprint.tooltip_text = _quota_tooltip()
	vbox.add_child(_spaced(sprint, 2, 6))

	var quota := SprintState.get_quarter_progress()
	var quota_label := _label("%d/%d" % [int(quota.get("impact", 0)), int(quota.get("quota", 0))], 9, UIHelpers.PANEL_ACCENT)
	quota_label.name = "QuotaRail"
	quota_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quota_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quota_label.tooltip_text = _quota_tooltip()
	vbox.add_child(_spaced(quota_label, 0, 4))

	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		var value: float = SprintState.resource_values.get(resource_id, 0.0)
		var state := EffectResolver.gauge_state(resource_id, value)
		vbox.add_child(_rail_gauge(
			resource.get("icon", "•"), value, 100.0,
			UIHelpers.panel_state_color(state), UIHelpers.resource_tooltip(resource)
		))

	vbox.add_child(_spaced(_rule(), 6, 6))
	vbox.add_child(_rail_gauge("⚡", float(SprintState.energy), float(SprintState.get_energy_max()),
		UIHelpers.panel_state_color(EffectResolver.gauge_state("", float(SprintState.energy))),
		UIHelpers.energy_tooltip()))

	var wallet := _label("💥\n%d" % SprintState.impact_wallet, 12, UIHelpers.PANEL_FG)
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet.tooltip_text = _wallet_tooltip()
	wallet.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(_spaced(wallet, 8, 0))

	var lever := _label("⚙️\n%s" % _lever_number(_current_effective_lever()), 10, UIHelpers.PANEL_ACCENT)
	lever.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lever.tooltip_text = _lever_chain_tooltip()
	lever.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(_spaced(lever, 5, 0))

	var revenue := _label("💰\n%d" % int(round(SprintState.revenue)), 12, UIHelpers.PANEL_FG)
	revenue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	revenue.tooltip_text = _revenue_tooltip()
	revenue.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(_spaced(revenue, 6, 0))


func _rail_gauge(icon: String, value: float, maximum: float, color: Color, tooltip: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.tooltip_text = tooltip

	var head := _label("%s %d" % [icon, int(round(value))], 10, UIHelpers.PANEL_FG)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)

	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 5)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := Panel.new()
	track.add_theme_stylebox_override("panel", _flat(Color(1, 1, 1, 0.09), 3))
	bar.add_child(track)
	var fill := Panel.new()
	fill.add_theme_stylebox_override("panel", _flat(color, 3))
	bar.add_child(fill)
	var ratio: float = clampf(value / maxf(maximum, 1.0), 0.0, 1.0)
	var layout := func():
		track.position = Vector2.ZERO
		track.size = Vector2(bar.size.x, 5)
		fill.position = Vector2.ZERO
		fill.size = Vector2(round(bar.size.x * ratio), 5)
	layout.call()
	bar.resized.connect(layout)
	box.add_child(bar)

	return _spaced(box, 3, 3)


func _collapse_button(text: String, tooltip: String) -> Control:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", UIHelpers.PANEL_MUTED)
	button.add_theme_color_override("font_hover_color", UIHelpers.PANEL_ACCENT)
	button.pressed.connect(_toggle_collapsed)
	return button


# ── En-tête : qui joue, où on en est ─────────────────────────────────────
func _build_header(vbox: VBoxContainer) -> void:
	vbox.add_child(_label("● ÉCRAN DE STANDUP", 9, UIHelpers.PANEL_MUTED))

	var company: Dictionary = SprintState.get_company()
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 3)

	var top := HBoxContainer.new()
	# Le nom d'entreprise s'enroule : sans ça, un nom long impose sa largeur au
	# panneau entier (la ScrollContainer propage la taille minimale de son
	# contenu) et la colonne recouvre l'écran de phase.
	var name_label := _label("%s %s" % [company.get("icon", "🏢"), company.get("name", "Entreprise")],
		15, UIHelpers.PANEL_FG, true)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIHelpers.apply_heading(name_label, 15, 600.0)
	top.add_child(name_label)
	var sprint_label := _label("SPRINT %d · T%d · %d/%d" % [
		SprintState.sprint_number, SprintState.quarter_index,
		SprintState.quarter_sprint + 1, SprintState.get_quarter_length()
	], 11, UIHelpers.PANEL_MUTED)
	UIHelpers.apply_mono(sprint_label, 11)
	sprint_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(sprint_label)
	head.add_child(top)

	# Le badge de profil d'équipe vit ici depuis la refonte : c'est un trait de
	# la run, pas de la phase (proposition UI §3.3).
	head.add_child(_label("%s · %s" % [_team_profile_label(), SprintState.get_business_model().get("label", "—")],
		10, UIHelpers.PANEL_MUTED, true))
	vbox.add_child(_spaced(head, 10, 10))


# ── Jauges en barres ─────────────────────────────────────────────────────
func _resource_gauge(resource: Dictionary) -> Control:
	var resource_id: String = resource.get("id", "")
	var value: float = SprintState.resource_values.get(resource_id, 0.0)
	var state := EffectResolver.gauge_state(resource_id, value)
	return _gauge(
		"%s %s" % [resource.get("icon", ""), resource.get("name", "")],
		value, 100.0, UIHelpers.panel_state_color(state), UIHelpers.resource_tooltip(resource)
	)


func _energy_gauge() -> Control:
	var maximum := float(SprintState.get_energy_max())
	var state := EffectResolver.gauge_state("", float(SprintState.energy))
	var gauge := _gauge("⚡ Énergie", float(SprintState.energy), maximum,
		UIHelpers.panel_state_color(state), UIHelpers.energy_tooltip())
	if SprintState.breather_planned:
		var note := _label("🧘 Vous soufflez ce sprint : aucune action personnelle.", 9, UIHelpers.PANEL_ACCENT, true)
		var wrapper := VBoxContainer.new()
		wrapper.add_theme_constant_override("separation", 2)
		wrapper.add_child(gauge)
		wrapper.add_child(note)
		return wrapper
	return gauge


func _gauge(text: String, value: float, maximum: float, color: Color, tooltip: String) -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.tooltip_text = tooltip

	var top := HBoxContainer.new()
	top.add_child(_label(text, 11, UIHelpers.PANEL_FG))
	top.add_child(_spacer_h())
	var value_label := _label("%d" % int(round(value)), 11, UIHelpers.PANEL_FG)
	UIHelpers.apply_mono(value_label, 11, true)
	value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(value_label)
	vbox.add_child(top)

	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var track := Panel.new()
	track.add_theme_stylebox_override("panel", _flat(Color(1, 1, 1, 0.09), 4))
	bar.add_child(track)

	var fill := Panel.new()
	fill.add_theme_stylebox_override("panel", _flat(color, 4))
	bar.add_child(fill)

	var ratio: float = clampf(value / maxf(maximum, 1.0), 0.0, 1.0)
	var layout := func():
		track.position = Vector2.ZERO
		track.size = Vector2(bar.size.x, BAR_HEIGHT)
		fill.position = Vector2.ZERO
		fill.size = Vector2(round(bar.size.x * ratio), BAR_HEIGHT)
	layout.call()
	bar.resized.connect(layout)
	vbox.add_child(bar)

	return _spaced(vbox, 3, 3)


## 💥 Le portefeuille — la seule monnaie d'achat, et la valeur que le board
## regarde au verdict. Un seul nombre : c'est tout l'intérêt du modèle.
func _wallet_row() -> Control:
	return _currency_row("💥 Impact", "%d" % SprintState.impact_wallet, _wallet_tooltip(), 6)


## La chaîne reste visible entre deux Résolutions : elle raconte la dernière
## organisation réellement jouée, sans promettre le résultat du prochain
## sprint. Les facteurs viennent uniquement du rapport du resolver.
func _lever_chain_row() -> Control:
	var report: Dictionary = SprintState.last_score_report
	if report.is_empty():
		var waiting := _label("⚙️ Levier — révélé après le premier sprint", 10, UIHelpers.PANEL_MUTED, true)
		waiting.name = "LeverChain"
		waiting.tooltip_text = "Le Levier combine les fondations additives et les multiplicateurs de votre organisation."
		return _spaced(waiting, 2, 5)

	var factors := _lever_multiplier_lines(report)
	var total_factor := 1.0
	var factor_labels: Array = []
	for line in factors:
		var factor := float(line.get("value", 1.0))
		total_factor *= factor
		factor_labels.append("×%s %s" % [_lever_number(factor), line.get("icon", "✖️")])
	var uncapped := float(report.get("global", {}).get("uncapped_effective_lever", 0.0))
	var base := uncapped / total_factor if not is_zero_approx(total_factor) else uncapped
	var text := "⚙️ Levier  %s" % _lever_number(base)
	if not factor_labels.is_empty():
		text += "  %s" % "  ".join(factor_labels)
	text += "  →  %s" % _lever_number(_current_effective_lever())
	var chain := _label(text, 10, UIHelpers.PANEL_ACCENT, true)
	chain.name = "LeverChain"
	chain.tooltip_text = _lever_chain_tooltip()
	chain.mouse_filter = Control.MOUSE_FILTER_STOP
	UIHelpers.apply_mono(chain, 10, true)
	return _spaced(chain, 2, 5)


func _lever_multiplier_lines(report: Dictionary) -> Array:
	var lines: Array = []
	# À plusieurs équipes, les Leviers locaux sont agrégés par moyenne pondérée
	# dans le resolver : multiplier leurs facteurs entre eux mentirait. Le
	# panneau montre alors la chaîne globale ; la Résolution garde le détail de
	# chaque équipe. À N=1, la chaîne est complète et la couche équipe invisible.
	if report.get("squads", []).size() == 1:
		for squad_report in report.get("squads", []):
			for line in squad_report.get("lines", []):
				if line.get("type", "") == "lever_multiplier":
					lines.append(line)
	for line in report.get("global", {}).get("lines", []):
		if line.get("type", "") == "lever_multiplier":
			lines.append(line)
	return lines


func _current_effective_lever() -> float:
	return float(SprintState.last_score_report.get("global", {}).get("effective_lever", 0.0))


func _lever_chain_tooltip() -> String:
	var report: Dictionary = SprintState.last_score_report
	if report.is_empty():
		return "Le Levier sera calculé à la première Résolution."
	var lines: Array = ["⚙️ Levier du dernier sprint — les additifs construisent la base, puis les multiplicateurs la font décoller."]
	for line in _lever_multiplier_lines(report):
		lines.append("· %s %s ×%s" % [line.get("icon", "✖️"), line.get("label", "Multiplicateur"), _lever_number(float(line.get("value", 1.0)))])
	if _lever_multiplier_lines(report).is_empty():
		lines.append("· Aucun multiplicateur actif pour l'instant.")
	var uncapped := float(report.get("global", {}).get("uncapped_effective_lever", 0.0))
	var effective := _current_effective_lever()
	if not is_equal_approx(uncapped, effective):
		lines.append("· Le Moral plafonne le résultat à %s." % _lever_number(effective))
	lines.append("C'est le résultat constaté, jamais une promesse pour le prochain sprint.")
	return "\n".join(lines)


func _lever_number(value: float) -> String:
	return String.num(value, 2).trim_suffix("0").trim_suffix(".")


## 💰 Le Revenue — jamais un prix, seulement la survie : il encaisse les
## abonnements et paie les charges. La charge du sprint est affichée à côté du
## solde, sinon « ai-je les moyens de le garder ? » n'a pas de réponse lisible.
func _revenue_row() -> Control:
	var charges: Dictionary = SprintState.get_recurring_charges()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.add_child(_currency_row("💰 Revenue", "%d" % int(round(SprintState.revenue)), _revenue_tooltip(), 2))
	# 👥 Les clients n'AJOUTENT pas un compteur, ils EXPLIQUENT le solde
	# (spec-clients-revenue.md §2.1) : une ligne de composition sous la seule
	# valeur jugée, jamais une deuxième valeur à surveiller.
	var composition := SprintState.describe_clients(true)
	if composition != "aucun client":
		var clients_label := _label(composition, 10, UIHelpers.PANEL_MUTED)
		clients_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		clients_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		clients_label.tooltip_text = _revenue_tooltip()
		clients_label.mouse_filter = Control.MOUSE_FILTER_STOP
		box.add_child(clients_label)
	# La charge vit sur sa propre ligne : à trois chiffres de part et d'autre,
	# une seule ligne sortait du panneau en fin de mandat.
	var charge := _label("charges −%d/sprint" % int(charges.get("total", 0)), 10, UIHelpers.PANEL_MUTED)
	charge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	charge.tooltip_text = _revenue_tooltip()
	charge.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_child(charge)
	return box


func _currency_row(title: String, value_text: String, tooltip: String, top_margin: int) -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.tooltip_text = tooltip
	var label := _label(title, 12, UIHelpers.PANEL_FG, true)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(_spacer_h())
	var value := _label(value_text, 13, UIHelpers.PANEL_FG)
	UIHelpers.apply_mono(value, 13, true)
	value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(value)
	return _spaced(row, top_margin, 8)


func _wallet_tooltip() -> String:
	return "💥 Impact — la seule monnaie d'achat.\nSe gagne : Traction × Levier à chaque sprint.\nSe dépense : embauches, pratiques, décisions, tout le Comité.\nIl ne se remet jamais à zéro, et c'est son solde que le board compare au quota."


func _revenue_tooltip() -> String:
	var charges: Dictionary = SprintState.get_recurring_charges()
	var lines: Array = [
		"💰 Revenue — la survie de l'entreprise. Jamais un prix.",
		"Encaisse ce que vos clients paient : %s" % SprintState.describe_clients(),
		"soit +%d par sprint. Paie chaque sprint :" % int(round(SprintState.get_client_revenue())),
	]
	if charges.get("lines", []).is_empty():
		lines.append("· rien pour l'instant")
	for line in charges.get("lines", []):
		lines.append("· %s %s — %d" % [line.get("icon", ""), line.get("label", ""), int(line.get("amount", 0))])
	lines.append("Produire de l'Impact ne remplit pas la caisse : ce sont deux économies.")
	lines.append("À zéro, l'entreprise ne paie plus : faillite.")
	return "\n".join(lines)


# ── Équipe : le roster enfin permanent, et actionnable ───────────────────
func _build_team(vbox: VBoxContainer) -> void:
	var roster: Array = SprintState.get_roster()
	var head := HBoxContainer.new()
	var title := _label("ÉQUIPE", 10, UIHelpers.PANEL_ACCENT)
	UIHelpers.apply_mono(title, 10, true)
	head.add_child(title)
	head.add_child(_spacer_h())
	var stats := _label("%d/%d · %d pts · %d 💰/sprint" % [
		roster.size(), SprintState.get_team_cap(),
		SprintState.get_effective_capacity(), SprintState.get_payroll()
	], 10, UIHelpers.PANEL_MUTED)
	UIHelpers.apply_mono(stats, 10)
	stats.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(stats)
	vbox.add_child(_spaced(head, 10, 6))

	var manage := Button.new()
	manage.name = "OpenTeamManagement"
	manage.text = "👥  Gérer et faire grandir l'équipe"
	manage.tooltip_text = "Diagnostiquer Moral, Confiance, Énergie et Satisfaction salariale, puis agir personne par personne."
	manage.pressed.connect(_open_team_management)
	vbox.add_child(manage)

	if roster.is_empty():
		vbox.add_child(_label("Plus personne. Une organisation parfaitement silencieuse.", 10, UIHelpers.PANEL_MUTED, true))
		return

	for employee in roster:
		vbox.add_child(_team_row(employee))


func _team_row(employee: Dictionary) -> Control:
	var roles: Dictionary = GameData.balance.get("roles", {})
	var role_conf: Dictionary = roles.get(employee.get("role", ""), {})
	var revealed: bool = employee.get("hiddenRevealed", false)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.tooltip_text = _employee_tooltip(employee, role_conf)
	row.gui_input.connect(_on_team_row_input.bind(employee.get("id", "")))

	row.add_child(UIHelpers.make_person_badge(employee.get("name", ""), 22))

	var name_label := _label(employee.get("name", ""), 11, UIHelpers.PANEL_FG)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_label)
	var alert: Dictionary = SprintState.get_employee_alert(employee)
	if bool(alert.get("active", false)):
		var warning := _label("%s %d %s" % [
			_alert_icon(String(alert.get("criterion", ""))), int(alert.get("value", 0)), alert.get("label", "")
		], 9, UIHelpers.PANEL_WARN)
		warning.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(warning)
	else:
		var stable := _label("●", 10, UIHelpers.PANEL_GOOD)
		stable.tooltip_text = "Aucune alerte individuelle"
		stable.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(stable)

	var suffix := " 🔒" if not revealed else _hidden_trait_icon(employee)
	var role_label := _label("%s %s%s" % [
		role_conf.get("label", employee.get("role", "")), employee.get("seniority", ""), suffix
	], 10, UIHelpers.PANEL_MUTED)
	UIHelpers.apply_mono(role_label, 10)
	role_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(role_label)

	return _spaced(row, 3, 3)


func _hidden_trait_icon(employee: Dictionary) -> String:
	var hidden_trait: Dictionary = SprintState.get_hidden_trait(employee.get("hidden_trait", ""))
	if hidden_trait.is_empty():
		return ""
	return " %s" % hidden_trait.get("icon", "")


func _employee_tooltip(employee: Dictionary, role_conf: Dictionary) -> String:
	var lines: Array = ["%s %s — %s %s · salaire %d 💰/sprint" % [
		role_conf.get("icon", "👤"), employee.get("name", ""),
		role_conf.get("label", employee.get("role", "")), employee.get("seniority", ""),
		int(employee.get("salary", 0)),
	]]
	if employee.get("trait", "") != "":
		lines.append(employee.get("trait", ""))
	if employee.get("personalityRevealed", false):
		var personality: Dictionary = SprintState.get_personality(employee.get("personality", ""))
		if not personality.is_empty():
			lines.append("Caractère révélé : %s — %s" % [personality.get("name", ""), personality.get("trait", "")])
	else:
		lines.append("🤝 Un 1:1 peut révéler son caractère.")
	var wellbeing: Dictionary = SprintState.employee_wellbeing(employee)
	lines.append("🫶 Moral %d · 🤝 Confiance %d · ⚡ Énergie %d · 💸 Salaire %d" % [
		int(wellbeing.get("moral", 0)), int(wellbeing.get("confiance", 0)),
		int(wellbeing.get("energie", 0)), int(wellbeing.get("salaire", 0)),
	])
	if employee.get("hiddenRevealed", false):
		var hidden_trait: Dictionary = SprintState.get_hidden_trait(employee.get("hidden_trait", ""))
		if not hidden_trait.is_empty():
			lines.append("%s %s — %s" % [
				hidden_trait.get("icon", ""), hidden_trait.get("name", ""), hidden_trait.get("description", "")
			])
	else:
		lines.append("🔒 Période d'essai en cours — trait caché non révélé.")
	lines.append("Clic : actions (🤝 1:1 pour rétablir la confiance · licencier)")
	return "\n".join(lines)


func _alert_icon(criterion: String) -> String:
	match criterion:
		"moral": return "🫶"
		"confiance": return "🤝"
		"energie": return "⚡"
		"salaire": return "💸"
	return "!"


## La ligne ouvre directement la fiche correspondante dans le hub complet.
## Le bouton au-dessus reste le point d'entrée évident pour le premier usage.
func _on_team_row_input(event: InputEvent, employee_id: String) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	_open_team_management(employee_id)


func _open_team_management(employee_id: String = "") -> void:
	if _team_management != null and is_instance_valid(_team_management):
		_team_management.open_for(employee_id)
		return
	var scene: PackedScene = load("res://scenes/components/team_management_dialog.tscn")
	_team_management = scene.instantiate()
	var host := get_parent()
	host.add_child(_team_management)
	_team_management.open_for(employee_id)
	_team_management.state_changed.connect(func():
		refresh()
		state_changed.emit()
	)
	_team_management.tree_exited.connect(func(): _team_management = null)


func _on_one_on_one(employee_id: String) -> void:
	var employee := SprintState.find_employee(employee_id)
	if employee.is_empty():
		return
	if SprintState.do_one_on_one(employee) == "":
		refresh()
		state_changed.emit()


## Le licenciement garde sa confirmation : c'est irréversible, coûte des
## indemnités, de la Confiance à celles et ceux qui restent, et du Cynisme à
## partir du deuxième du mandat.
func _confirm_fire(employee_id: String) -> void:
	var employee := SprintState.find_employee(employee_id)
	if employee.is_empty():
		return
	var firing: Dictionary = GameData.balance.get("firing", {})
	_pending_fire_id = employee_id

	if _fire_dialog == null:
		_fire_dialog = ConfirmationDialog.new()
		_fire_dialog.title = "Licenciement"
		_fire_dialog.ok_button_text = "Licencier"
		_fire_dialog.cancel_button_text = "Annuler"
		_fire_dialog.confirmed.connect(_on_fire_confirmed)
		add_child(_fire_dialog)

	_fire_dialog.dialog_text = "Licencier %s ?\n\nIndemnités %d 💥 · 🤝 Confiance %d pour l'équipe · −%d 💰/sprint de salaire%s\nIrréversible." % [
		employee.get("name", ""),
		SprintState.resolved_price("severance"),
		int(firing.get("confiance", -8)),
		int(employee.get("salary", 1)),
		"\n🎭 Cynisme +%d — l'organisation y verra une politique." % int(firing.get("cynismePerExtraFiring", 3)) if SprintState.fired_count >= 1 else "",
	]
	_fire_dialog.popup_centered()


func _on_fire_confirmed() -> void:
	if _pending_fire_id == "":
		return
	if SprintState.fire_employee(_pending_fire_id) == "":
		_pending_fire_id = ""
		refresh()
		state_changed.emit()


# ── Actifs possédés ──────────────────────────────────────────────────────
func _build_assets(vbox: VBoxContainer) -> void:
	vbox.add_child(_spaced(_rule(), 10, 0))
	vbox.add_child(_group_label("Actifs"))

	var max_activations := SprintState.get_tool_slot_capacity()
	var names: Array = []
	for card_id in SprintState.activated_cards:
		for card in GameData.cards.get("cards", []):
			if card.get("id", "") == card_id:
				names.append(card.get("name", card_id))
	vbox.add_child(_label("🃏 Décisions %d/%d%s" % [
		SprintState.activated_cards.size(), max_activations,
		" : %s" % ", ".join(names) if not names.is_empty() else " — aucune activée"
	], 11, UIHelpers.PANEL_FG, true))

	var icons: Array = []
	var practice_tooltips: Array = []
	for practice_id in SprintState.owned_practices:
		var practice: Dictionary = SprintState.find_practice(practice_id)
		icons.append(practice.get("icon", "✨"))
		practice_tooltips.append("%s %s — %s" % [
			practice.get("icon", ""), practice.get("name", ""), practice.get("description", "")
		])
	var practices_label := _label("✨ Pratiques : %s" % (
		" ".join(icons) if not icons.is_empty() else "aucune adoptée"
	), 11, UIHelpers.PANEL_FG, true)
	if not practice_tooltips.is_empty():
		practices_label.mouse_filter = Control.MOUSE_FILTER_STOP
		practices_label.tooltip_text = "\n".join(practice_tooltips)
	vbox.add_child(practices_label)


# ── Quota trimestriel, évalué en direct ──────────────────────────────────
func _build_quota(vbox: VBoxContainer) -> void:
	var quota: Dictionary = SprintState.get_quarter_progress()
	var impact := int(quota.get("impact", 0))
	var target: int = max(1, int(quota.get("quota", 1)))

	vbox.add_child(_spaced(_rule(), 10, 0))
	var section := VBoxContainer.new()
	section.name = "QuotaSection"
	section.add_theme_constant_override("separation", 5)
	vbox.add_child(section)
	section.add_child(_group_label("Quota trimestriel · T%d" % int(quota.get("quarter", SprintState.quarter_index))))
	section.add_child(_label("Sprint %d/%d · portefeuille %d / %d 💥" % [
		int(quota.get("sprint", 0)) + 1, int(quota.get("length", 3)), impact, target
	], 11, UIHelpers.PANEL_FG, true))

	var bar := ProgressBar.new()
	bar.name = "QuotaProgress"
	bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	bar.max_value = target
	bar.value = clampi(impact, 0, target)
	bar.show_percentage = false
	bar.tooltip_text = _quota_tooltip()
	bar.add_theme_stylebox_override("fill", _flat(UIHelpers.PANEL_ACCENT, 3))
	bar.add_theme_stylebox_override("background", _flat(Color(1, 1, 1, 0.10), 3))
	section.add_child(bar)

	for requirement in SprintState.get_active_quarter_requirements():
		var requirement_label := _label("%s %s\n%s" % [
			requirement.get("icon", "!"), requirement.get("name", "Exigence"), requirement.get("description", "")
		], 10, UIHelpers.PANEL_FG, true)
		requirement_label.tooltip_text = "Exigence active ce trimestre"
		section.add_child(requirement_label)

	var objectives := SprintState.evaluate_board_objectives()
	if not objectives.is_empty():
		section.add_child(_label("Objectifs qualitatifs : bonus +%d 💥" % int(GameData.quotas.get("qualitativeBonusImpact", 0)), 10, UIHelpers.PANEL_ACCENT, true))
		for objective in objectives:
			var ok: bool = bool(objective.get("ok", false))
			section.add_child(_label("%s %s" % ["✓" if ok else "○", objective.get("label", "")], 10,
				UIHelpers.PANEL_GOOD if ok else UIHelpers.PANEL_MUTED, true))


func _quota_tooltip() -> String:
	var quota := SprintState.get_quarter_progress()
	return "T%d · sprint %d/%d\nPortefeuille : %d / %d 💥 — c'est le SOLDE qui est jugé, pas la production : dépenser fait reculer vers l'objectif.\n%s" % [
		int(quota.get("quarter", 1)), int(quota.get("sprint", 0)) + 1, int(quota.get("length", 3)),
		int(quota.get("impact", 0)), int(quota.get("quota", 0)), SprintState.get_quarter_requirement_text()
	]


# ── Petits constructeurs ─────────────────────────────────────────────────
func _on_dossier_pressed() -> void:
	if _dossier == null:
		return
	if _dossier.has_method("refresh"):
		_dossier.refresh()
	_dossier.visible = not _dossier.visible


func _label(text: String, size: int, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return label


func _group_label(text: String) -> Control:
	var label := _label(text.to_upper(), 10, UIHelpers.PANEL_ACCENT)
	UIHelpers.apply_mono(label, 10, true)
	return _spaced(label, 10, 7)


func _rule() -> Control:
	var rule := ColorRect.new()
	rule.color = UIHelpers.PANEL_RULE
	rule.custom_minimum_size = Vector2(0, 1)
	return rule


func _flat(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style


func _spaced(node: Control, top: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.add_child(node)
	return margin


func _spacer_h() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _team_profile_label() -> String:
	for profile in GameData.cards.get("teamProfiles", []):
		if profile.get("id", "") == SprintState.team_profile:
			return profile.get("label", SprintState.team_profile)
	return SprintState.team_profile
