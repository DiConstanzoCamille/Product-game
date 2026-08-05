extends Control
## Choix de l'entreprise (docs/carnet-de-regles.md §16) — deuxième étape du
## lancement d'un mandat, après le scénario. Chaque entreprise est une
## "offre d'emploi" (data/companies.json) qui fixe le profil d'équipe hérité
## (junior/senior) — ce n'est plus un bouton à bascule sur l'écran des
## Grandes décisions, mais un trait du contexte de la run, choisi ici.

## Fin de la mise en place : on n'entre plus dans un tunnel de phases, on
## s'assoit au bureau (issue #54). Tout le sprint se joue depuis là.
const DESK_SCENE := "res://scenes/screens/desk_screen.tscn"
const SCENARIO_SCENE := "res://scenes/screens/scenario_screen.tscn"

@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var eyebrow_label: Label = $Margin/VBox/Eyebrow
@onready var title_label: Label = $Margin/VBox/Title
@onready var cards_row: HBoxContainer = $Margin/VBox/Scroll/CardsRow


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(SCENARIO_SCENE))
	UIHelpers.apply_mono(eyebrow_label, 13, true)
	UIHelpers.apply_heading(title_label, 32, 700.0)
	UIHelpers.fade_in(self)
	UIHelpers.attach_device_frame(self)

	_build_cards()


func _build_cards() -> void:
	var companies := SprintState.get_companies_for_era(SprintState.pending_era_id)
	for company in companies:
		cards_row.add_child(_build_company_card(company))


## Résumé du roster de départ par rôle, ex. "1 📋 PM · 2 💻 Devs · 1 🛠️ Ops".
func _roster_summary(roster: Array) -> String:
	var roles: Dictionary = GameData.balance.get("roles", {})
	var counts: Dictionary = {}
	for member in roster:
		var role_id: String = member.get("role", "")
		counts[role_id] = int(counts.get(role_id, 0)) + 1
	var parts: Array = []
	for role_id in ["pm", "dev", "designer", "ops"]:
		var count := int(counts.get(role_id, 0))
		if count == 0:
			continue
		var role_conf: Dictionary = roles.get(role_id, {})
		parts.append("%d %s %s" % [count, role_conf.get("icon", ""), role_conf.get("label", role_id)])
	var missing: Array = []
	for role_id in ["pm", "dev", "designer", "ops"]:
		if int(counts.get(role_id, 0)) == 0:
			var role_conf: Dictionary = roles.get(role_id, {})
			missing.append("%s %s" % [role_conf.get("icon", ""), role_conf.get("label", role_id)])
	var text := " · ".join(parts)
	if not missing.is_empty():
		text += " · aucun %s !" % " ni ".join(missing)
	return text


func _team_profile_label(team_profile: String) -> String:
	for profile in GameData.cards.get("teamProfiles", []):
		if profile.get("id", "") == team_profile:
			return profile.get("label", team_profile)
	return team_profile


func _build_company_card(company: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var icon_label := Label.new()
	icon_label.text = company.get("icon", "🏢")
	icon_label.add_theme_font_size_override("font_size", 34)
	vbox.add_child(icon_label)

	var tagline_label := Label.new()
	tagline_label.text = company.get("tagline", "")
	tagline_label.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	UIHelpers.apply_mono(tagline_label, 11, true)
	tagline_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(tagline_label)

	var name_label := Label.new()
	name_label.text = company.get("name", "")
	UIHelpers.apply_heading(name_label, 19, 600.0)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	var description_label := Label.new()
	description_label.text = company.get("description", "")
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	description_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(description_label)

	var team_label := Label.new()
	var roster: Array = company.get("startingRoster", [])
	team_label.text = "Équipe héritée : %s — %d personne%s (cap %d) · %s" % [
		_team_profile_label(company.get("teamProfile", "")),
		roster.size(), "s" if roster.size() > 1 else "",
		int(company.get("teamCap", 0)),
		_roster_summary(roster),
	]
	team_label.add_theme_font_size_override("font_size", 12)
	team_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	team_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(team_label)

	var wallet_label := Label.new()
	var starting_impact := int(company.get("startingImpact", 0))
	wallet_label.text = "💥 Impact de départ : %d — le premier sprint sert à livrer avec ce dont on hérite." % starting_impact \
		if starting_impact <= 0 else "💥 Impact de départ : %d" % starting_impact
	wallet_label.add_theme_font_size_override("font_size", 12)
	wallet_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	wallet_label.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	vbox.add_child(wallet_label)

	var objectives: Dictionary = company.get("boardObjectives", {})
	if not objectives.is_empty():
		var objectives_label := Label.new()
		var lines: Array = ["🏛️ Bonus qualitatif à chaque quota (+%d 💥) : %s" % [
			int(GameData.quotas.get("qualitativeBonusImpact", 0)), objectives.get("title", "")
		]]
		for condition in objectives.get("conditions", []):
			lines.append("   • %s" % condition.get("label", ""))
		objectives_label.text = "\n".join(lines)
		objectives_label.add_theme_font_size_override("font_size", 12)
		objectives_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(objectives_label)

	var action_btn := Button.new()
	action_btn.text = "Accepter le poste"
	action_btn.pressed.connect(_on_company_selected.bind(company.get("id", "")))
	vbox.add_child(action_btn)

	return panel


func _on_company_selected(company_id: String) -> void:
	SprintState.reset_run(SprintState.pending_era_id, company_id, SprintState.pending_career_level)
	get_tree().change_scene_to_file(DESK_SCENE)
