extends Control
## Choix de l'entreprise (docs/carnet-de-regles.md §16) — deuxième étape du
## lancement d'un mandat, après le scénario. Chaque entreprise est une
## "offre d'emploi" (data/companies.json) qui fixe le profil d'équipe hérité
## (junior/senior) — ce n'est plus un bouton à bascule sur l'écran des
## Grandes décisions, mais un trait du contexte de la run, choisi ici.

const INBOX_SCENE := "res://scenes/screens/inbox_screen.tscn"
const SCENARIO_SCENE := "res://scenes/screens/scenario_screen.tscn"

@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var eyebrow_label: Label = $Margin/VBox/Eyebrow
@onready var title_label: Label = $Margin/VBox/Title
@onready var cards_row: HBoxContainer = $Margin/VBox/Scroll/CardsRow


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(SCENARIO_SCENE))
	UIHelpers.add_hover_bounce(back_button)
	UIHelpers.apply_mono(eyebrow_label, 13, true)
	UIHelpers.apply_heading(title_label, 32, 700.0)
	UIHelpers.fade_in(self)

	_build_cards()


func _build_cards() -> void:
	var companies := SprintState.get_companies_for_era(SprintState.pending_era_id)
	for company in companies:
		cards_row.add_child(_build_company_card(company))


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
	team_label.text = "Équipe héritée : %s" % _team_profile_label(company.get("teamProfile", ""))
	team_label.add_theme_font_size_override("font_size", 12)
	team_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	team_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(team_label)

	var action_btn := Button.new()
	action_btn.text = "Accepter le poste"
	action_btn.pressed.connect(_on_company_selected.bind(company.get("id", "")))
	UIHelpers.add_hover_bounce(action_btn, 1.03)
	vbox.add_child(action_btn)

	return panel


func _on_company_selected(company_id: String) -> void:
	SprintState.reset_run(SprintState.pending_era_id, company_id)
	get_tree().change_scene_to_file(INBOX_SCENE)
