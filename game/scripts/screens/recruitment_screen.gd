extends Control
## Phase 4 — Recrutement (docs/carnet-de-regles.md §9, §16). Shop dont
## l'habillage est fixé par le scénario en cours (data/balance.json →
## eraRecruitmentSkin) — plus un choix libre du joueur à chaque sprint.

const NEXT_SCENE := "res://scenes/screens/resolution_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var skin_toggle: HBoxContainer = $Margin/VBox/SkinToggle
@onready var shop_grid: GridContainer = $Margin/VBox/Scroll/ShopGrid
@onready var next_button: Button = $Margin/VBox/BottomBar/NextButton

var skins: Array = []


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(func(): get_tree().change_scene_to_file(NEXT_SCENE))
	UIHelpers.add_hover_bounce(back_button)
	UIHelpers.add_hover_bounce(next_button)
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 4 : Recrutement" % SprintState.sprint_number

	var bar := UIHelpers.build_resource_bar()
	$Margin/VBox.add_child(bar)
	$Margin/VBox.move_child(bar, 1)
	UIHelpers.attach_company_menu(self)

	skin_toggle.visible = false
	skins = GameData.recruitment_demo.get("skins", [])
	var skin_id: String = GameData.balance.get("eraRecruitmentSkin", {}).get(SprintState.era_id, "")
	if skin_id == "" and not skins.is_empty():
		skin_id = skins[0].get("id", "")
	_show_skin(skin_id)


func _show_skin(skin_id: String) -> void:
	for child in shop_grid.get_children():
		child.queue_free()

	var skin: Dictionary = {}
	for s in skins:
		if s.get("id", "") == skin_id:
			skin = s
			break

	if skin.get("type", "") == "candidates":
		for c in skin.get("candidates", []):
			shop_grid.add_child(_build_candidate_card(c))
	else:
		for a in skin.get("ads", []):
			shop_grid.add_child(_build_ad_card(a))


func _build_candidate_card(candidate: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var candidate_name: String = candidate.get("name", "")
	var first_name := candidate_name.split(" — ")[0].strip_edges()
	vbox.add_child(UIHelpers.make_avatar(first_name, 48))

	var name_label := Label.new()
	name_label.text = candidate_name
	UIHelpers.apply_heading(name_label, 15, 600.0)
	vbox.add_child(name_label)

	var role_label := Label.new()
	role_label.text = candidate.get("role", "")
	role_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	vbox.add_child(role_label)

	var badges_label := Label.new()
	badges_label.text = " · ".join(candidate.get("badges", []))
	badges_label.add_theme_font_size_override("font_size", 11)
	badges_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(badges_label)

	var cost_label := Label.new()
	cost_label.text = candidate.get("cost", "")
	vbox.add_child(cost_label)

	var action_btn := Button.new()
	action_btn.text = candidate.get("action", "")
	action_btn.pressed.connect(_on_hire_pressed.bind(action_btn, candidate.get("id", ""), candidate_name))
	UIHelpers.add_hover_bounce(action_btn, 1.03)
	vbox.add_child(action_btn)

	return panel


func _build_ad_card(ad: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title_label := Label.new()
	title_label.text = ad.get("title", "")
	UIHelpers.apply_heading(title_label, 14, 600.0)
	vbox.add_child(title_label)

	var text_label := Label.new()
	text_label.text = ad.get("text", "")
	text_label.add_theme_font_size_override("font_size", 12)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(text_label)

	var action_btn := Button.new()
	action_btn.text = ad.get("action", "")
	action_btn.pressed.connect(_on_hire_pressed.bind(action_btn, ad.get("id", ""), ad.get("title", "")))
	UIHelpers.add_hover_bounce(action_btn, 1.03)
	vbox.add_child(action_btn)

	return panel


func _on_hire_pressed(btn: Button, item_id: String, display_name: String) -> void:
	btn.text = btn.text + " ✓"
	btn.disabled = true

	var result := EffectResolver.resolve_recruitment(item_id)
	SprintState.add_pending(result.get("deltas", {}), "Recrutement : %s" % display_name)
	SprintState.capacity_bonus += int(result.get("capacity_bonus", 0))
