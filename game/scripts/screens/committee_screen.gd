extends Control
## Le Comité d'investissement (spec-scoring-sprint.md §12, Lot 4) — l'écran qui
## répare « pas de gestion d'équipe » : entre deux trimestres, jamais au fil de
## l'eau. L'étal du sprint (investments_screen) ne change pas — le Comité ne
## propose que ce qui ne s'y décide pas : décisions stratégiques, capacité
## d'outillage, cap d'effectif, promotions, paliers de produit, et les paris
## ponctuels (séminaire, remise à plat, rachat, chasseur de têtes, plan de
## redressement, avance sur trimestre).
##
## Toute la logique (coûts, effets, refus) vit dans SprintState — cet écran ne
## fait que lire ses fonctions et rejouer leurs refus (result != "" => refus).
## Inséré par resolution_screen.gd quand un trimestre vient de se clôturer et
## que le mandat continue (voir _quarter_just_closed()).

const NEXT_SCENE := "res://scenes/screens/inbox_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var budget_label: Label = $Margin/VBox/BudgetLabel
@onready var scroll: ScrollContainer = $Margin/VBox/Scroll
@onready var content: VBoxContainer = $Margin/VBox/Scroll/Content
@onready var continue_button: Button = $Margin/VBox/BottomBar/ContinueButton

var side_panel: Control = null


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	continue_button.pressed.connect(func(): get_tree().change_scene_to_file(NEXT_SCENE))
	UIHelpers.style_primary_button(continue_button)
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Comité d'investissement · Trimestre %d" % [
		SprintState.sprint_number, SprintState.quarter_index
	]

	side_panel = UIHelpers.attach_side_panel(self)
	side_panel.state_changed.connect(_refresh)

	_refresh()


# ── Rafraîchissement complet ──────────────────────────────────────────────
## Chaque achat change ce que d'autres postes peuvent proposer (pièces
## dépensées, slot pris, décision consommée, junior promu) : on reconstruit
## tout le contenu à chaque geste, comme le rayon des Investissements.
func _refresh() -> void:
	var charges: Dictionary = SprintState.get_recurring_charges()
	budget_label.text = "💥 Impact disponible : %d          💰 Revenue : %d  (−%d/sprint de charges)" % [
		SprintState.impact_wallet, int(round(SprintState.revenue)), int(charges.get("total", 0))
	]
	budget_label.tooltip_text = "Tout s'achète en 💥 Impact. Ce qui reste allumé après l'achat se paie en 💰 Revenue, à chaque sprint, jusqu'à la fin du mandat."
	UIHelpers.clear_children(content)

	_build_strategy_section()
	_build_tool_slot_section()
	_build_team_cap_section()
	_build_promotion_section()
	_build_product_tier_section()
	_build_flat_effect_section("team-seminar", "Séminaire d'équipe", SprintState.buy_team_seminar)
	_build_flat_effect_section("cleanup-sprint", "Sprint de remise à plat", SprintState.buy_cleanup_sprint)
	_build_flat_effect_section("acquire-competitor", "Rachat d'un concurrent", SprintState.buy_competitor_acquisition)
	_build_flat_effect_section("headhunter", "Chasseur de têtes", SprintState.buy_headhunter)
	_build_flat_effect_section("turnaround-plan", "Plan de redressement", SprintState.buy_turnaround_plan)
	_build_quarter_advance_section()

	if side_panel != null:
		side_panel.refresh()


# ── 🧭 Décision stratégique ───────────────────────────────────────────────
func _build_strategy_section() -> void:
	var item: Dictionary = SprintState.find_investment_item("strategic-decision")
	content.add_child(_section_title("%s Décision stratégique" % item.get("icon", "🧭")))
	content.add_child(_flavor_text(item.get("tagline", "")))

	if SprintState.quarter_strategy_chosen:
		content.add_child(_flavor_text("✅ Une décision stratégique a déjà été prise ce trimestre — irréversible pour le reste du mandat.", UIHelpers.COLOR_GOOD))
		return

	var cost := SprintState.strategy_purchase_cost()
	for strategy in SprintState.get_strategy_options(3):
		var strategy_id: String = strategy.get("id", "")
		content.add_child(_action_row(
			strategy.get("icon", "🧭"),
			strategy.get("name", strategy_id),
			strategy.get("description", strategy.get("tagline", "")),
			_price_text(cost, "strategy", strategy_id),
			"Adopter",
			SprintState.impact_wallet < cost,
			_on_strategy_pressed.bind(strategy_id)
		))


func _on_strategy_pressed(strategy_id: String) -> void:
	if SprintState.buy_strategy(strategy_id) != "":
		return
	_refresh()


# ── 🔧 Outillage : ouvrir ou libérer un slot ──────────────────────────────
func _build_tool_slot_section() -> void:
	var open_item: Dictionary = SprintState.find_investment_item("tool-slot")
	content.add_child(_section_title("%s Slots d'outillage — %d/%d" % [
		open_item.get("icon", "🔧"), SprintState.activated_cards.size(), SprintState.get_tool_slot_capacity()
	]))
	content.add_child(_flavor_text(open_item.get("tagline", "")))

	var open_cost := SprintState.tool_slot_purchase_cost()
	if open_cost < 0:
		content.add_child(_action_row(open_item.get("icon", "🔧"), "Ouvrir un slot d'outillage",
			open_item.get("description", ""), "—", "Plafond atteint", true, Callable()))
	else:
		content.add_child(_action_row(open_item.get("icon", "🔧"), "Ouvrir un slot d'outillage",
			open_item.get("description", ""), _price_text(open_cost, "committee", "tool-slot"), "Ouvrir",
			SprintState.impact_wallet < open_cost, _on_open_slot_pressed))

	var release_item: Dictionary = SprintState.find_investment_item("release-tool-slot")
	if SprintState.activated_cards.is_empty():
		content.add_child(_flavor_text("Aucun outil actif à libérer pour l'instant.", UIHelpers.COLOR_SOFT_TEXT))
		return

	var swap_cost := SprintState.swap_cynisme_penalty()
	for card_id in SprintState.activated_cards:
		var card := SprintState.find_card(card_id)
		if card.is_empty():
			continue
		content.add_child(_action_row(
			release_item.get("icon", "♻️"),
			"Libérer %s" % card.get("name", card_id),
			release_item.get("description", ""),
			"🎭 +%d" % swap_cost,
			"Libérer",
			false,
			_on_release_slot_pressed.bind(card_id)
		))


func _on_open_slot_pressed() -> void:
	if SprintState.buy_tool_slot() != "":
		return
	_refresh()


func _on_release_slot_pressed(card_id: String) -> void:
	if SprintState.release_tool_slot(card_id) != "":
		return
	_refresh()


# ── 🪑 Ouvrir un poste (cap d'effectif) ───────────────────────────────────
func _build_team_cap_section() -> void:
	var item: Dictionary = SprintState.find_investment_item("open-seat")
	content.add_child(_section_title("%s Cap d'effectif — %d/%d" % [
		item.get("icon", "🪑"), SprintState.get_roster().size(), SprintState.get_team_cap()
	]))
	content.add_child(_flavor_text(item.get("tagline", "")))

	var cost := SprintState.team_cap_purchase_cost()
	if cost < 0:
		content.add_child(_action_row(item.get("icon", "🪑"), "Ouvrir un poste",
			item.get("description", ""), "—", "Plafond atteint", true, Callable()))
	else:
		content.add_child(_action_row(item.get("icon", "🪑"), "Ouvrir un poste",
			item.get("description", ""), _price_text(cost, "committee", "open-seat"), "Ouvrir",
			SprintState.impact_wallet < cost, _on_team_cap_pressed))


func _on_team_cap_pressed() -> void:
	if SprintState.buy_team_cap_seat() != "":
		return
	_refresh()


# ── 📈 Promotion ──────────────────────────────────────────────────────────
func _build_promotion_section() -> void:
	var item: Dictionary = SprintState.find_investment_item("promotion")
	content.add_child(_section_title("%s Promotion" % item.get("icon", "📈")))
	content.add_child(_flavor_text(item.get("tagline", "")))

	var juniors: Array = []
	for employee in SprintState.get_roster():
		if employee.get("seniority", "junior") == "junior":
			juniors.append(employee)

	if juniors.is_empty():
		content.add_child(_flavor_text("Plus aucun junior à promouvoir pour l'instant.", UIHelpers.COLOR_SOFT_TEXT))
		return

	var cost := SprintState.promotion_cost()
	for employee in juniors:
		content.add_child(_action_row(
			item.get("icon", "📈"),
			"Promouvoir %s" % employee.get("name", employee.get("id", "")),
			"%s Un salaire senior au lieu d'un salaire junior : +%d 💰/sprint." % [
				item.get("description", ""),
				int(GameData.balance.get("salaries", {}).get("senior", 2)) - int(employee.get("salary", 1)),
			],
			_price_text(cost, "committee", "promotion"),
			"Promouvoir",
			SprintState.impact_wallet < cost,
			_on_promotion_pressed.bind(employee.get("id", ""))
		))


func _on_promotion_pressed(employee_id: String) -> void:
	if SprintState.promote_employee(employee_id) != "":
		return
	_refresh()


# ── 🚀 Palier de produit ──────────────────────────────────────────────────
func _build_product_tier_section() -> void:
	var item: Dictionary = SprintState.find_investment_item("product-tier")
	content.add_child(_section_title("%s Palier de produit — %d/%d" % [
		item.get("icon", "🚀"), SprintState.product_tier, item.get("costs", []).size()
	]))
	content.add_child(_flavor_text(item.get("tagline", "")))

	var cost := SprintState.product_tier_purchase_cost()
	if cost < 0:
		content.add_child(_action_row(item.get("icon", "🚀"), "Palier de produit",
			item.get("description", ""), "—", "Plafond atteint", true, Callable()))
	else:
		content.add_child(_action_row(item.get("icon", "🚀"), "Franchir un palier",
			item.get("description", ""), _price_text(cost, "committee", "product-tier"), "Investir",
			SprintState.impact_wallet < cost, _on_product_tier_pressed))


func _on_product_tier_pressed() -> void:
	if SprintState.buy_product_tier() != "":
		return
	_refresh()


# ── Postes à effet immédiat, rachetables sans limite (spec §12) ──────────
## Séminaire, remise à plat, rachat, chasseur de têtes, plan de
## redressement : même gabarit — un poste, un coût plat, une fonction
## SprintState qui porte tout le calcul et le refus.
func _build_flat_effect_section(item_id: String, action_label: String, callback: Callable) -> void:
	var item: Dictionary = SprintState.find_investment_item(item_id)
	content.add_child(_section_title("%s %s" % [item.get("icon", "•"), item.get("name", action_label)]))
	content.add_child(_flavor_text(item.get("tagline", "")))
	var cost := SprintState.resolved_price("committee", item_id)
	content.add_child(_action_row(item.get("icon", "•"), action_label,
		item.get("description", ""), _price_text(cost, "committee", item_id), "Acheter",
		SprintState.impact_wallet < cost, _on_flat_effect_pressed.bind(callback)))


func _on_flat_effect_pressed(callback: Callable) -> void:
	if callback.call() != "":
		return
	_refresh()


# ── 🎲 Avance sur trimestre ────────────────────────────────────────────────
## Le seul poste qui va dans l'autre sens : il vend de l'Impact contre du
## Revenue. Jamais désactivé — c'est un pari, pas un achat, et il peut creuser
## le portefeuille sous zéro.
func _build_quarter_advance_section() -> void:
	var item: Dictionary = SprintState.find_investment_item("quarter-advance")
	content.add_child(_section_title("%s Avance sur trimestre" % item.get("icon", "🎲")))
	content.add_child(_flavor_text(item.get("tagline", "")))
	content.add_child(_action_row(
		item.get("icon", "🎲"), "Prendre l'avance",
		item.get("description", ""),
		"+%d 💰" % int(item.get("revenueGain", 26)),
		"Parier",
		false,
		_on_quarter_advance_pressed
	))


func _on_quarter_advance_pressed() -> void:
	SprintState.buy_quarter_advance()
	_refresh()


# ── Construction des lignes ───────────────────────────────────────────────
## Les deux dimensions d'un poste, côte à côte : le prix payé maintenant et la
## charge engagée pour toujours. Le prix vient toujours de resolved_price() —
## l'écran ne lit jamais un coût brut dans investments.json.
func _price_text(cost: int, kind: String, item_id: String) -> String:
	var charge := SprintState.recurring_charge(kind, item_id)
	if charge <= 0:
		return "%d 💥" % cost
	return "%d 💥\n+%d 💰/sprint" % [cost, charge]


func _section_title(text: String) -> Control:
	var label := Label.new()
	label.text = text
	UIHelpers.apply_heading(label, 18, 600.0)
	return label


func _flavor_text(text: String, color: Color = UIHelpers.COLOR_SOFT_TEXT) -> Control:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	return label


func _action_row(icon: String, name_text: String, description: String, cost_text: String, button_text: String, disabled: bool, callback: Callable) -> Control:
	var panel := PanelContainer.new()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var icon_label := Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 22)
	row.add_child(icon_label)

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_vbox)

	var name_label := Label.new()
	name_label.text = name_text
	UIHelpers.apply_heading(name_label, 15, 600.0)
	text_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	text_vbox.add_child(desc_label)

	var cost_label := Label.new()
	cost_label.text = cost_text
	cost_label.custom_minimum_size = Vector2(110, 0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(cost_label)

	var button := Button.new()
	button.text = button_text
	button.disabled = disabled or not callback.is_valid()
	if callback.is_valid():
		button.pressed.connect(callback)
	row.add_child(button)

	return panel
