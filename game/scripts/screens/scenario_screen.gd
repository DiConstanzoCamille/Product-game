extends Control
## Choix du scénario (docs/carnet-de-regles.md §10, §15) — première vraie
## décision du roguelike : le contexte tiré au sort/choisi conditionne les
## cartes, événements et le modèle économique disponibles pendant le run.
## Seule la Transformation Agile est jouable pour l'instant (data/balance.json
## → playableEras) ; les 2 autres scénarios s'affichent en "Bientôt disponible".

const COMPANY_SELECT_SCENE := "res://scenes/screens/company_select_screen.tscn"
const CAREER_SELECT_SCENE := "res://scenes/screens/career_select_screen.tscn"

@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var eyebrow_label: Label = $Margin/VBox/Eyebrow
@onready var title_label: Label = $Margin/VBox/Title
@onready var subtitle_label: Label = $Margin/VBox/Subtitle
@onready var cards_row: HBoxContainer = $Margin/VBox/Scroll/CardsRow


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(CAREER_SELECT_SCENE))
	UIHelpers.apply_mono(eyebrow_label, 13, true)
	UIHelpers.apply_heading(title_label, 32, 700.0)
	UIHelpers.fade_in(self)
	UIHelpers.attach_device_frame(self)

	_build_cards()


func _build_cards() -> void:
	var playable: Array = GameData.balance.get("playableEras", [])
	for era in GameData.eras:
		cards_row.add_child(_build_era_card(era, playable.has(era.get("id", ""))))


func _build_era_card(era: Dictionary, is_playable: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	panel.modulate = Color(1, 1, 1, 1) if is_playable else Color(1, 1, 1, 0.55)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var icon_label := Label.new()
	icon_label.text = era.get("icon", "")
	icon_label.add_theme_font_size_override("font_size", 34)
	vbox.add_child(icon_label)

	var period_label := Label.new()
	period_label.text = era.get("period", "")
	period_label.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	UIHelpers.apply_mono(period_label, 11, true)
	vbox.add_child(period_label)

	var name_label := Label.new()
	name_label.text = era.get("name", "")
	UIHelpers.apply_heading(name_label, 20, 600.0)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	var description_label := Label.new()
	description_label.text = era.get("description", "")
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	description_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(description_label)

	var tension_label := Label.new()
	tension_label.text = "Tension : %s" % era.get("tension", "")
	tension_label.add_theme_font_size_override("font_size", 12)
	tension_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	tension_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(tension_label)

	var boss_label := Label.new()
	boss_label.text = "Épreuve : %s" % era.get("boss", "")
	boss_label.add_theme_font_size_override("font_size", 12)
	boss_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	boss_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(boss_label)

	var action_btn := Button.new()
	if is_playable:
		action_btn.text = "Choisir ce scénario"
		action_btn.pressed.connect(_on_era_selected.bind(era.get("id", "")))
	else:
		action_btn.text = "🔒 Bientôt disponible"
		action_btn.disabled = true
	vbox.add_child(action_btn)

	return panel


func _on_era_selected(era_id: String) -> void:
	SprintState.pending_era_id = era_id
	get_tree().change_scene_to_file(COMPANY_SELECT_SCENE)
