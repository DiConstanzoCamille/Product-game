extends PanelContainer
## Panneau "Entreprise" (docs/carnet-de-regles.md §16) — contexte complet de
## la run en cours : entreprise, scénario, profil d'équipe, modèle
## économique, état du mandat. Overlay non-modal, jamais un changement de
## scène (branché par UIHelpers.attach_company_menu() sur chaque écran de
## phase). Section "Pilotage" verrouillée : dashboards prévus, pas encore
## construits — voir "Prochaines étapes" dans game/README.md.

@onready var title_label: Label = $VBox/TopRow/TitleLabel
@onready var close_button: Button = $VBox/TopRow/CloseButton
@onready var content: VBoxContainer = $VBox/Scroll/Content


func _ready() -> void:
	close_button.pressed.connect(func(): visible = false)
	UIHelpers.apply_heading(title_label, 22, 600.0)
	UIHelpers.add_hover_bounce(close_button)
	_populate()


func _populate() -> void:
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

	_add_section_title("Pilotage")
	var locked_label := Label.new()
	locked_label.text = "🔒 Bientôt disponible — burn down, répartition grands comptes / petits comptes, et d'autres tableaux de pilotage classiques."
	locked_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	locked_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	content.add_child(locked_label)


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
