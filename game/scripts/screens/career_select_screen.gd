extends Control
## Choix du niveau de carrière (spec-scoring §13.4, issue #18) — première
## étape du lancement d'un mandat, avant le scénario. Le niveau fixe le
## nombre d'équipes sous responsabilité et les slots d'outillage de départ
## (data/careers.json, balance.json → toolSlots.careerLevels, quotas.json →
## careerLevels). Seul PM est toujours débloqué ; les autres se gagnent en
## franchissant un mandat complet au niveau précédent (déblocage strict,
## jamais de contournement) — mêmes pattern et lecture que `scenario_screen`
## (playableEras / "Bientôt disponible"), pas une nouvelle UI.
##
## À N=1 (niveau PM), cet écran ne change rien au run : career_level reste
## "pm" et SprintState.squads garde sa seule entrée historique.

const SCENARIO_SCENE := "res://scenes/screens/scenario_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var eyebrow_label: Label = $Margin/VBox/Eyebrow
@onready var title_label: Label = $Margin/VBox/Title
@onready var subtitle_label: Label = $Margin/VBox/Subtitle
@onready var cards_row: HBoxContainer = $Margin/VBox/Scroll/CardsRow


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	UIHelpers.apply_mono(eyebrow_label, 13, true)
	UIHelpers.apply_heading(title_label, 32, 700.0)
	UIHelpers.fade_in(self)
	UIHelpers.attach_device_frame(self)

	_build_cards()


func _build_cards() -> void:
	var order: Array = GameData.careers.get("order", [])
	var levels: Dictionary = GameData.careers.get("levels", {})
	for level_id in order:
		var level: Dictionary = levels.get(level_id, {})
		cards_row.add_child(_build_level_card(level_id, level, PlayerProfile.is_career_level_unlocked(level_id)))


func _build_level_card(level_id: String, level: Dictionary, is_unlocked: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 0)
	panel.modulate = Color(1, 1, 1, 1) if is_unlocked else Color(1, 1, 1, 0.55)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var icon_label := Label.new()
	icon_label.text = level.get("icon", "")
	icon_label.add_theme_font_size_override("font_size", 34)
	vbox.add_child(icon_label)

	var name_label := Label.new()
	name_label.text = level.get("label", level_id)
	UIHelpers.apply_heading(name_label, 22, 650.0)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	var squads_label := Label.new()
	var squads_min := int(level.get("squadsMin", 1))
	var squads_max := int(level.get("squadsMax", squads_min))
	squads_label.text = "%d équipe%s" % [squads_min, "s" if squads_min > 1 else ""] if squads_min == squads_max else "%d à %d équipes" % [squads_min, squads_max]
	squads_label.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	UIHelpers.apply_mono(squads_label, 12, true)
	vbox.add_child(squads_label)

	var appears_label := Label.new()
	appears_label.text = level.get("appears", "")
	appears_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	appears_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(appears_label)

	var action_btn := Button.new()
	if is_unlocked:
		action_btn.text = "Choisir ce niveau"
		action_btn.pressed.connect(_on_level_selected.bind(level_id))
	else:
		action_btn.text = "🔒 %s" % level.get("unlockLabel", "Verrouillé")
		action_btn.disabled = true
		action_btn.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(action_btn)

	return panel


func _on_level_selected(level_id: String) -> void:
	SprintState.pending_career_level = level_id
	get_tree().change_scene_to_file(SCENARIO_SCENE)
