extends PanelContainer
## Le **Dossier entreprise** (docs/carnet-de-regles.md §16 ; refonte UI §4.4) —
## la lecture longue et les actions rares : dans quoi je joue.
##
## Depuis la refonte UI, tout ce qui répond à « où j'en suis » a migré dans le
## Panneau de bord permanent (scenes/components/side_panel.tscn) : ressources,
## pièces, effectif, roster condensé avec 1:1 et licenciement, actifs possédés,
## rappel des conditions de board. Le Dossier garde ce qu'on lit une fois par
## mandat — contexte RP, modèle économique détaillé, objectifs commentés,
## roster détaillé, Pilotage — et la seule action rare qui y reste : la
## rallonge négociée au board.
##
## Overlay non-modal, jamais un changement de scène : ouvert depuis le bouton
## du Panneau de bord sur les écrans de phase, depuis la TopBar à la Résolution
## (UIHelpers.attach_company_menu).

@onready var title_label: Label = $VBox/TopRow/TitleLabel
@onready var close_button: Button = $VBox/TopRow/CloseButton
@onready var content: VBoxContainer = $VBox/Scroll/Content


func _ready() -> void:
	close_button.pressed.connect(func(): visible = false)
	UIHelpers.apply_heading(title_label, 22, 600.0)
	UIHelpers.add_hover_bounce(close_button)
	_populate()


## Reconstruit le dossier — appelé par le Panneau de bord quand l'état a bougé.
func refresh() -> void:
	_populate()


func _populate() -> void:
	for child in content.get_children():
		child.free()

	var company: Dictionary = SprintState.get_company()
	var era: Dictionary = SprintState.get_era()
	var model: Dictionary = SprintState.get_business_model()

	title_label.text = "🏢 Dossier — %s %s" % [company.get("icon", ""), company.get("name", "Entreprise")]

	_add_text(company.get("tagline", ""), 14, UIHelpers.COLOR_AMBER)
	_add_text(company.get("description", ""), 13, UIHelpers.COLOR_INK)

	_add_section_title("Le mandat")
	_add_row("Scénario", "%s %s" % [era.get("icon", ""), era.get("name", "")])
	_add_row("Profil d'équipe", _team_profile_label())
	_add_row("Sprint en cours", "%d / %d" % [
		SprintState.sprint_number, int(GameData.balance.get("mandateLengthSprints", 12))
	])
	_add_text(era.get("description", ""), 12, UIHelpers.COLOR_SOFT_TEXT)

	_add_section_title("Modèle économique — %s" % model.get("label", "—"))
	_add_text(model.get("description", ""), 12, UIHelpers.COLOR_SOFT_TEXT)
	if SprintState.last_revenue > 0 or SprintState.last_payroll > 0:
		_add_row("Dernier sprint résolu", "revenu +%d 💰 · masse salariale −%d 💰" % [
			SprintState.last_revenue, SprintState.last_payroll
		])

	var objectives: Dictionary = company.get("boardObjectives", {})
	if not objectives.is_empty():
		_add_section_title("Objectifs de board — verdict au sprint %d" % int(GameData.balance.get("trimesterLengthSprints", 6)))
		_add_text(objectives.get("title", ""), 13, UIHelpers.COLOR_AMBER)
		for condition in objectives.get("conditions", []):
			_add_text("• %s" % condition.get("label", ""), 12, UIHelpers.COLOR_INK)
		match SprintState.board_review_state:
			"passed":
				_add_text("✅ Revue réussie — le board a débloqué du budget d'action.", 12, UIHelpers.COLOR_GOOD)
			"failed":
				_add_text("❌ Revue ratée — allocation de pièces réduite pour le reste du mandat.", 12, UIHelpers.COLOR_DANGER)
			_:
				_add_text("⏳ À venir — le Panneau de bord suit ces conditions en direct.", 12, UIHelpers.COLOR_SOFT_TEXT)

	_add_section_title("L'équipe en détail — %d pts produits · %d 💰/sprint" % [
		SprintState.get_effective_capacity(), SprintState.get_payroll()
	])
	if SprintState.roster.is_empty():
		_add_text("Plus personne. Une organisation parfaitement silencieuse.", 12, UIHelpers.COLOR_SOFT_TEXT)
	_add_text("Les actions (🤝 1:1 · licencier) sont dans le Panneau de bord, sur la ligne de la personne.",
		11, UIHelpers.COLOR_SOFT_TEXT)
	for employee in SprintState.roster:
		_add_employee(employee)

	_add_section_title("Pratiques adoptées")
	if SprintState.owned_practices.is_empty():
		_add_text("Aucune pour l'instant — l'étal en propose deux par sprint.", 12, UIHelpers.COLOR_SOFT_TEXT)
	for practice_id in SprintState.owned_practices:
		var practice: Dictionary = SprintState.find_practice(practice_id)
		_add_text("%s %s — %s" % [
			practice.get("icon", ""), practice.get("name", ""), practice.get("description", "")
		], 12, UIHelpers.COLOR_INK)

	_add_section_title("Action rare — ⚡ %d / %d" % [SprintState.energy, SprintState.get_energy_max()])
	content.add_child(_build_extension_row())

	_add_section_title("Pilotage")
	_add_pilotage_row("📊 Burn down & métriques post-livraison", "product-analytics")
	_add_pilotage_row("💼 Grands comptes / petits comptes", "segmentation-clients")


## 🏛️ Négocier une rallonge (spec §7.2) : votre Capital politique contre
## des pièces immédiates pour l'entreprise. Reste ici, et pas dans le Panneau
## de bord : plus elle est visible, plus elle est tentante — arbitrage laissé
## ouvert dans la proposition UI §7.
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


## Fiche détaillée d'une personne : tout ce que la ligne condensée du Panneau
## de bord ne peut pas montrer — trait visible complet, trait caché, sprint
## d'embauche.
func _add_employee(employee: Dictionary) -> void:
	var roles: Dictionary = GameData.balance.get("roles", {})
	var role_conf: Dictionary = roles.get(employee.get("role", ""), {})

	_add_text("%s %s — %s %s · salaire %d 💰/sprint · arrivé·e au sprint %d" % [
		role_conf.get("icon", "👤"), employee.get("name", ""),
		role_conf.get("label", employee.get("role", "")), employee.get("seniority", ""),
		int(employee.get("salary", 0)), int(employee.get("hiredSprint", 0)),
	], 12, UIHelpers.COLOR_INK)

	if employee.get("trait", "") != "":
		_add_text("   « %s »" % employee.get("trait", ""), 11, UIHelpers.COLOR_FLAVOR)

	if employee.get("hiddenRevealed", false):
		var hidden_trait: Dictionary = SprintState.get_hidden_trait(employee.get("hidden_trait", ""))
		if hidden_trait.is_empty():
			_add_text("   🔓 Rien à signaler. Vraiment.", 11, UIHelpers.COLOR_SOFT_TEXT)
		else:
			_add_text("   %s %s — %s" % [
				hidden_trait.get("icon", ""), hidden_trait.get("name", ""), hidden_trait.get("description", "")
			], 11, UIHelpers.COLOR_GOOD if hidden_trait.get("polarity", "") == "positive" else UIHelpers.COLOR_DANGER)
	else:
		_add_text("   🔒 Période d'essai en cours — le trait caché tombera au sprint %d." % (
			int(employee.get("hiredSprint", 0)) + int(GameData.balance.get("trialPeriodSprints", 2))
		), 11, UIHelpers.COLOR_SOFT_TEXT)


func _add_pilotage_row(label_text: String, practice_id: String) -> void:
	if SprintState.has_practice(practice_id):
		_add_text("%s — ✅ déverrouillé par %s (tableaux détaillés à venir)." % [
			label_text, SprintState.find_practice(practice_id).get("name", practice_id)
		], 12, UIHelpers.COLOR_GOOD)
	else:
		_add_text("%s — 🔒 s'adopte à l'étal du sprint (%s)." % [
			label_text, SprintState.find_practice(practice_id).get("name", practice_id)
		], 12, UIHelpers.COLOR_SOFT_TEXT)


func _team_profile_label() -> String:
	for profile in GameData.cards.get("teamProfiles", []):
		if profile.get("id", "") == SprintState.team_profile:
			return profile.get("label", SprintState.team_profile)
	return SprintState.team_profile.capitalize()


func _add_section_title(text: String) -> void:
	var label := Label.new()
	label.text = text
	UIHelpers.apply_mono(label, 12, true)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
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


func _add_row(label_text: String, value_text: String, value_color: Color = UIHelpers.COLOR_INK) -> void:
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
