extends Control
## Phase 4 — le Marché (spec profondeur §5). Un seul écran, deux rayons :
## 2 candidats (trait caché tiré à l'apparition, révélé si Entretiens
## structurés) + 2 pratiques non possédées. L'offre est tirée une fois par
## sprint et stockée dans SprintState — revenir sur l'écran ne retire pas.
## Tout se paie en pièces 🪙, le cap d'effectif est indiqué. Le 1:1 (§7.2)
## permet de payer en Énergie ⚡ la révélation du trait caché d'un candidat
## avant de signer quoi que ce soit.

const NEXT_SCENE := "res://scenes/screens/resolution_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var pieces_label: Label = $Margin/VBox/InfoRow/PiecesLabel
@onready var cap_label: Label = $Margin/VBox/InfoRow/CapLabel
@onready var shop_grid: GridContainer = $Margin/VBox/Scroll/ShopGrid
@onready var next_button: Button = $Margin/VBox/BottomBar/NextButton

var offer: Dictionary = {}
var refresh_callbacks: Array = []  # boutons/labels à rafraîchir après un achat
var resource_bar: Control = null


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(func(): get_tree().change_scene_to_file(NEXT_SCENE))
	UIHelpers.add_hover_bounce(back_button)
	UIHelpers.add_hover_bounce(next_button)
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 4 : Marché" % SprintState.sprint_number

	resource_bar = UIHelpers.build_resource_bar()
	$Margin/VBox.add_child(resource_bar)
	$Margin/VBox.move_child(resource_bar, 1)
	UIHelpers.attach_company_menu(self)

	offer = SprintState.get_shop_offer()
	for candidate in offer.get("candidates", []):
		shop_grid.add_child(_build_candidate_card(candidate))
	for practice_id in offer.get("practices", []):
		shop_grid.add_child(_build_practice_card(SprintState.find_practice(practice_id)))

	if offer.get("candidates", []).is_empty() and offer.get("practices", []).is_empty():
		var empty_label := Label.new()
		empty_label.text = "L'étal est vide ce sprint — le marché des talents a aussi ses pénuries."
		empty_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
		shop_grid.add_child(empty_label)

	_refresh_all()


func _refresh_all() -> void:
	pieces_label.text = "🪙 %d pièce%s · ⚡ %d" % [
		SprintState.pieces, "s" if SprintState.pieces > 1 else "", SprintState.energy
	]
	if SprintState.next_hire_discount > 0:
		pieces_label.text += "  (réseau : −%d 🪙 sur la prochaine embauche)" % SprintState.next_hire_discount
	cap_label.text = "👥 Effectif : %d/%d" % [SprintState.roster.size(), SprintState.get_team_cap()]
	for callback in refresh_callbacks:
		callback.call()
	_rebuild_resource_bar()


## L'Énergie et les pièces bougent en direct sur cet écran (1:1, embauches) —
## on reconstruit la barre compacte plutôt que de suivre chaque label.
func _rebuild_resource_bar() -> void:
	if resource_bar == null:
		return
	var parent := resource_bar.get_parent()
	var index := resource_bar.get_index()
	resource_bar.queue_free()
	resource_bar = UIHelpers.build_resource_bar()
	parent.add_child(resource_bar)
	parent.move_child(resource_bar, index)


func _seniority_label(seniority: String) -> String:
	return "senior" if seniority == "senior" else "junior"


func _role_label(role_id: String) -> String:
	var role_conf: Dictionary = GameData.balance.get("roles", {}).get(role_id, {})
	return "%s %s" % [role_conf.get("icon", ""), role_conf.get("label", role_id)]


func _build_candidate_card(candidate: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var rayon_label := Label.new()
	rayon_label.text = "RAYON CANDIDATS"
	rayon_label.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	UIHelpers.apply_mono(rayon_label, 10, true)
	vbox.add_child(rayon_label)

	vbox.add_child(UIHelpers.make_avatar(candidate.get("name", "").to_lower(), 48))

	var name_label := Label.new()
	name_label.text = "%s — %s %s" % [
		candidate.get("name", ""), _role_label(candidate.get("role", "")),
		_seniority_label(candidate.get("seniority", ""))
	]
	UIHelpers.apply_heading(name_label, 15, 600.0)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	var trait_label := Label.new()
	trait_label.text = candidate.get("trait", "")
	trait_label.add_theme_font_size_override("font_size", 12)
	trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(trait_label)

	var badges_label := Label.new()
	badges_label.text = " · ".join(candidate.get("badges", []))
	badges_label.add_theme_font_size_override("font_size", 11)
	badges_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	badges_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(badges_label)

	var hidden_label := Label.new()
	hidden_label.add_theme_font_size_override("font_size", 12)
	hidden_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(hidden_label)

	var cost_label := Label.new()
	cost_label.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	vbox.add_child(cost_label)

	var one_on_one_btn := Button.new()
	one_on_one_btn.pressed.connect(_on_one_on_one_pressed.bind(candidate))
	one_on_one_btn.tooltip_text = "Action personnelle (⚡) : un vrai entretien, pas un pitch — révèle le trait caché avant embauche."
	UIHelpers.add_hover_bounce(one_on_one_btn, 1.03)
	vbox.add_child(one_on_one_btn)

	var action_btn := Button.new()
	action_btn.pressed.connect(_on_hire_pressed.bind(candidate))
	UIHelpers.add_hover_bounce(action_btn, 1.03)
	vbox.add_child(action_btn)

	var refresh := func():
		if candidate.get("hiddenRevealed", false):
			var hidden_trait: Dictionary = SprintState.get_hidden_trait(candidate.get("hidden_trait", ""))
			if hidden_trait.is_empty():
				hidden_label.text = "🗂️ Entretien structuré : rien à signaler. Vraiment."
			else:
				hidden_label.text = "%s %s — %s" % [
					hidden_trait.get("icon", ""), hidden_trait.get("name", ""), hidden_trait.get("description", "")
				]
		else:
			hidden_label.text = "🔒 Trait caché — révélé en fin de période d'essai."
			hidden_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)

		var cost: int = max(0, int(candidate.get("costPieces", 0)) - SprintState.next_hire_discount)
		cost_label.text = "%d 🪙 · salaire %d 💰/sprint" % [cost, int(candidate.get("salary", 1))]

		var one_on_one_cost := SprintState.get_personal_action_cost("oneOnOne")
		if candidate.get("hiddenRevealed", false) or candidate.get("hired", false):
			one_on_one_btn.visible = false
		else:
			one_on_one_btn.visible = true
			match SprintState.personal_action_refusal():
				"souffler":
					one_on_one_btn.text = "🤝 1:1 — 🧘 vous soufflez ce sprint"
					one_on_one_btn.disabled = true
				"epuise":
					one_on_one_btn.text = "🤝 1:1 (%d ⚡ — épuisé·e)" % one_on_one_cost
					one_on_one_btn.disabled = true
				_:
					one_on_one_btn.text = "🤝 1:1 (%d ⚡)" % one_on_one_cost
					one_on_one_btn.disabled = false

		if candidate.get("hired", false):
			action_btn.text = "Embauché·e ✓"
			action_btn.disabled = true
		elif SprintState.roster.size() >= SprintState.get_team_cap():
			action_btn.text = "Cap d'effectif atteint (%d/%d)" % [SprintState.roster.size(), SprintState.get_team_cap()]
			action_btn.disabled = true
		elif SprintState.pieces < cost:
			action_btn.text = "Embaucher (%d 🪙 — insuffisant)" % cost
			action_btn.disabled = true
		else:
			action_btn.text = "Embaucher (%d 🪙)" % cost
			action_btn.disabled = false
	refresh_callbacks.append(refresh)

	return panel


func _build_practice_card(practice: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var rayon_label := Label.new()
	rayon_label.text = "RAYON PRATIQUES"
	rayon_label.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	UIHelpers.apply_mono(rayon_label, 10, true)
	vbox.add_child(rayon_label)

	var icon_label := Label.new()
	icon_label.text = practice.get("icon", "✨")
	icon_label.add_theme_font_size_override("font_size", 30)
	vbox.add_child(icon_label)

	var name_label := Label.new()
	name_label.text = practice.get("name", "")
	UIHelpers.apply_heading(name_label, 15, 600.0)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	var description_label := Label.new()
	description_label.text = practice.get("description", "")
	description_label.add_theme_font_size_override("font_size", 12)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(description_label)

	var cynisme_label := Label.new()
	cynisme_label.text = "Permanente pour le mandat · 🎭 Cynisme +%d à l'achat" % int(GameData.balance.get("shopDraw", {}).get("practiceCynisme", 2))
	cynisme_label.add_theme_font_size_override("font_size", 11)
	cynisme_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	cynisme_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(cynisme_label)

	var action_btn := Button.new()
	action_btn.pressed.connect(_on_buy_practice_pressed.bind(practice))
	UIHelpers.add_hover_bounce(action_btn, 1.03)
	vbox.add_child(action_btn)

	var refresh := func():
		var cost := int(practice.get("costPieces", 0))
		if SprintState.has_practice(practice.get("id", "")):
			action_btn.text = "Adoptée ✓"
			action_btn.disabled = true
		elif SprintState.pieces < cost:
			action_btn.text = "Adopter (%d 🪙 — insuffisant)" % cost
			action_btn.disabled = true
		else:
			action_btn.text = "Adopter (%d 🪙)" % cost
			action_btn.disabled = false
	refresh_callbacks.append(refresh)

	return panel


func _on_hire_pressed(candidate: Dictionary) -> void:
	SprintState.hire_candidate(candidate)
	_refresh_all()


func _on_one_on_one_pressed(candidate: Dictionary) -> void:
	SprintState.do_one_on_one(candidate)
	_refresh_all()


func _on_buy_practice_pressed(practice: Dictionary) -> void:
	SprintState.buy_practice(practice.get("id", ""))
	_refresh_all()
