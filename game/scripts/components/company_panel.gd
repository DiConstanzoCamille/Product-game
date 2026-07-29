extends PanelContainer
## Panneau "Entreprise" (docs/carnet-de-regles.md §16, spec profondeur §10) —
## contexte complet de la run en cours : entreprise, scénario, ressources,
## roster détaillé (avec licenciement et 1:1), pratiques adoptées, objectifs
## de la revue de board, action personnelle Rallonge, sections Pilotage
## déverrouillables par les pratiques.
## Overlay non-modal, jamais un changement de scène (branché par
## UIHelpers.attach_company_menu() sur chaque écran de phase).

@onready var title_label: Label = $VBox/TopRow/TitleLabel
@onready var close_button: Button = $VBox/TopRow/CloseButton
@onready var content: VBoxContainer = $VBox/Scroll/Content


func _ready() -> void:
	close_button.pressed.connect(func(): visible = false)
	UIHelpers.apply_heading(title_label, 22, 600.0)
	UIHelpers.add_hover_bounce(close_button)
	_populate()


func _populate() -> void:
	for child in content.get_children():
		child.queue_free()

	var company: Dictionary = SprintState.get_company()
	var era: Dictionary = SprintState.get_era()
	var model: Dictionary = SprintState.get_business_model()

	title_label.text = "%s %s" % [company.get("icon", "🏢"), company.get("name", "Entreprise")]

	_add_text(company.get("tagline", ""), 14, UIHelpers.COLOR_AMBER)
	_add_text(company.get("description", ""), 13, Color.WHITE)

	_add_section_title("Contexte de la run")
	_add_row("Scénario", "%s %s" % [era.get("icon", ""), era.get("name", "")])
	_add_row("Profil d'équipe", SprintState.team_profile.capitalize())
	_add_row("Modèle économique", model.get("label", "—"))
	_add_row("Sprint en cours", "%d / %d" % [SprintState.sprint_number, int(GameData.balance.get("mandateLengthSprints", 12))])
	_add_row("Grandes décisions activées", "%d / %d" % [
		SprintState.activated_cards.size(), int(GameData.balance.get("structuralDecisionMaxActivations", 4))
	])
	_add_row("🪙 Pièces (budget d'action)", "%d" % SprintState.pieces, UIHelpers.COLOR_AMBER)
	_add_row("👥 Effectif", "%d / %d" % [SprintState.roster.size(), SprintState.get_team_cap()])
	_add_row("⚡ Énergie (vous)", "%d / %d" % [SprintState.energy, SprintState.get_energy_max()], UIHelpers.COLOR_AMBER)

	_add_section_title("Ressources")
	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		var value: float = SprintState.resource_values.get(resource_id, 0.0)
		var state := EffectResolver.gauge_state(resource_id, value)
		_add_row(
			"%s %s" % [resource.get("icon", ""), resource.get("name", "")],
			"%d%%" % int(round(value)),
			UIHelpers.state_color(state)
		)

	_add_section_title("Équipe — capacité produite : %d pts · masse salariale : %d 💰/sprint" % [
		SprintState.get_effective_capacity(), SprintState.get_payroll()
	])
	if SprintState.roster.is_empty():
		_add_text("Plus personne. Une organisation parfaitement silencieuse.", 12, UIHelpers.COLOR_SOFT_TEXT)
	for employee in SprintState.roster:
		content.add_child(_build_employee_row(employee))

	_add_section_title("Pratiques adoptées")
	if SprintState.owned_practices.is_empty():
		_add_text("Aucune pour l'instant — le Marché en propose deux par sprint.", 12, UIHelpers.COLOR_SOFT_TEXT)
	for practice_id in SprintState.owned_practices:
		var practice: Dictionary = SprintState.find_practice(practice_id)
		_add_text("%s %s — %s" % [practice.get("icon", ""), practice.get("name", ""), practice.get("description", "")], 12, Color.WHITE)

	var objectives: Dictionary = company.get("boardObjectives", {})
	if not objectives.is_empty():
		_add_section_title("Revue de board — sprint %d" % int(GameData.balance.get("trimesterLengthSprints", 6)))
		_add_text(objectives.get("title", ""), 13, UIHelpers.COLOR_AMBER)
		for condition in objectives.get("conditions", []):
			_add_text("• %s" % condition.get("label", ""), 12, Color.WHITE)
		match SprintState.board_review_state:
			"passed":
				_add_text("✅ Revue réussie — le board a débloqué du budget d'action.", 12, UIHelpers.COLOR_GOOD)
			"failed":
				_add_text("❌ Revue ratée — allocation de pièces réduite pour le reste du mandat.", 12, UIHelpers.COLOR_DANGER)
			_:
				_add_text("⏳ À venir — l'état de la boîte sera comparé à ces objectifs.", 12, UIHelpers.COLOR_SOFT_TEXT)

	_add_section_title("Actions personnelles — ⚡ %d / %d" % [SprintState.energy, SprintState.get_energy_max()])
	content.add_child(_build_extension_row())

	_add_section_title("Pilotage")
	_add_pilotage_row("📊 Burn down & métriques post-livraison", "product-analytics")
	_add_pilotage_row("💼 Grands comptes / petits comptes", "segmentation-clients")


## 🏛️ Négocier une rallonge (spec §7.2) : votre Capital politique contre
## des pièces immédiates pour l'entreprise.
func _build_extension_row() -> Control:
	var conf: Dictionary = SprintState.get_personal_action_conf("extension")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.text = "🏛️ Négocier une rallonge — 🎯 %d contre +%d 🪙 immédiats." % [
		int(conf.get("capitalPolitique", -8)), int(conf.get("pieces", 4))
	]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 12)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var btn := Button.new()
	btn.tooltip_text = "Action personnelle (⚡) : retourner voir le board, la casquette à la main. Ça marche, et ça se paie."
	match SprintState.personal_action_refusal():
		"souffler":
			btn.text = "🧘 Vous soufflez ce sprint"
			btn.disabled = true
		"epuise":
			btn.text = "Négocier (%d ⚡ — épuisé·e)" % int(conf.get("cost", 10))
			btn.disabled = true
		_:
			btn.text = "Négocier (%d ⚡)" % int(conf.get("cost", 10))
			btn.disabled = false
	btn.pressed.connect(_on_extension_pressed)
	row.add_child(btn)
	return row


func _on_extension_pressed() -> void:
	if SprintState.do_negotiate_extension() == "":
		_populate()


func _build_employee_row(employee: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var roles: Dictionary = GameData.balance.get("roles", {})
	var role_conf: Dictionary = roles.get(employee.get("role", ""), {})

	var label := Label.new()
	var hidden_text := ""
	if employee.get("hiddenRevealed", false):
		var hidden_trait: Dictionary = SprintState.get_hidden_trait(employee.get("hidden_trait", ""))
		if not hidden_trait.is_empty():
			hidden_text = " · %s %s" % [hidden_trait.get("icon", ""), hidden_trait.get("name", "")]
	else:
		hidden_text = " · 🔒 période d'essai en cours"
	label.text = "%s %s — %s %s · salaire %d 💰%s" % [
		role_conf.get("icon", "👤"), employee.get("name", ""),
		role_conf.get("label", employee.get("role", "")), employee.get("seniority", ""),
		int(employee.get("salary", 0)), hidden_text
	]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 12)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.tooltip_text = employee.get("trait", "")
	row.add_child(label)

	if not employee.get("hiddenRevealed", false):
		var one_on_one_btn := Button.new()
		var one_on_one_cost := SprintState.get_personal_action_cost("oneOnOne")
		one_on_one_btn.tooltip_text = "Action personnelle (⚡) : une vraie conversation — révèle le trait caché sans attendre la fin de la période d'essai."
		match SprintState.personal_action_refusal():
			"souffler":
				one_on_one_btn.text = "🤝 1:1 — 🧘 vous soufflez"
				one_on_one_btn.disabled = true
			"epuise":
				one_on_one_btn.text = "🤝 1:1 (%d ⚡ — épuisé·e)" % one_on_one_cost
				one_on_one_btn.disabled = true
			_:
				one_on_one_btn.text = "🤝 1:1 (%d ⚡)" % one_on_one_cost
				one_on_one_btn.disabled = false
		one_on_one_btn.pressed.connect(_on_one_on_one_pressed.bind(employee.get("id", "")))
		row.add_child(one_on_one_btn)

	var severance := int(GameData.balance.get("firing", {}).get("severancePieces", 2))
	var fire_btn := Button.new()
	fire_btn.text = "Licencier (%d 🪙)" % severance
	fire_btn.disabled = SprintState.pieces < severance
	fire_btn.tooltip_text = "Indemnités %d 🪙 · 🫶 Moral %d · 🎭 Cynisme +%d à partir du 2e licenciement du mandat" % [
		severance,
		int(GameData.balance.get("firing", {}).get("moral", -4)),
		int(GameData.balance.get("firing", {}).get("cynismePerExtraFiring", 3)),
	]
	fire_btn.pressed.connect(_on_fire_pressed.bind(employee.get("id", "")))
	row.add_child(fire_btn)

	return row


func _on_fire_pressed(employee_id: String) -> void:
	if SprintState.fire_employee(employee_id) == "":
		_populate()


func _on_one_on_one_pressed(employee_id: String) -> void:
	var employee := SprintState.find_employee(employee_id)
	if employee.is_empty():
		return
	if SprintState.do_one_on_one(employee) == "":
		_populate()


func _add_pilotage_row(label_text: String, practice_id: String) -> void:
	if SprintState.has_practice(practice_id):
		_add_text("%s — ✅ déverrouillé par %s (tableaux détaillés à venir)." % [
			label_text, SprintState.find_practice(practice_id).get("name", practice_id)
		], 12, UIHelpers.COLOR_GOOD)
	else:
		_add_text("%s — 🔒 s'achète au Marché (%s)." % [
			label_text, SprintState.find_practice(practice_id).get("name", practice_id)
		], 12, UIHelpers.COLOR_SOFT_TEXT)


func _add_section_title(text: String) -> void:
	var label := Label.new()
	label.text = text
	UIHelpers.apply_mono(label, 12, true)
	label.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	content.add_child(label)


func _add_text(text: String, size: int, color: Color) -> void:
	if text == "":
		return
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	content.add_child(label)


func _add_row(label_text: String, value_text: String, value_color: Color = Color.WHITE) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value_label := Label.new()
	value_label.text = value_text
	value_label.add_theme_color_override("font_color", value_color)
	row.add_child(value_label)
	content.add_child(row)
