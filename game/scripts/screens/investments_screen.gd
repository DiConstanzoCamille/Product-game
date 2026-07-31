extends Control
## Phase 3 — Investissements (docs/proposition-ui-interface.md §3 ; carnet de
## règles §6.2, §21). L'écran unique de tout ce que l'organisation acquiert,
## en **un seul rayon où les trois types se mélangent** : candidats, pratiques
## et grandes décisions tirés dans le même pool, dans le même ordre d'affichage.
##
## La proposition prévoyait deux rayons empilés ; l'arbitrage a été poussé d'un
## cran. Deux rayons séparés garantissaient à chaque type sa place, donc
## supprimaient la question « qu'est-ce que le sprint m'a proposé ? ». Un rayon
## unique met vraiment les investissements en concurrence : la pièce gardée pour
## Lina est la même que celle qui paierait Discovery, et le slot dépensé sur
## Jira est celui qu'on n'aura pas pour Shape Up. Certains sprints proposent
## trois décisions et un seul candidat, d'autres l'inverse — avec un minimum
## garanti par type (SprintState, `guaranteedPerSprint`) pour qu'aucun sprint
## ne soit un tour perdu.
##
## Les trois types partagent le **même** composant, la carte d'Actif
## (scenes/components/asset_card.tscn) : seuls la pastille, la couleur du papier
## et le contenu des zones changent. Le coût, l'effectif, l'Énergie et le profil
## d'équipe ne sont pas affichés ici mais en continu dans le Panneau de bord.

const NEXT_SCENE := "res://scenes/screens/resolution_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

## Largeur de gouttière de la grille (doit suivre le `h_separation` de la
## scène) et plafond de colonnes : au-delà, le rayon devient un mur.
const GRID_SEPARATION := 14
const MAX_COLUMNS := 4

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var scroll: ScrollContainer = $Margin/VBox/Scroll
@onready var shelf_head: VBoxContainer = $Margin/VBox/Scroll/Pad/Shelves/ShelfHead
@onready var shelf_grid: GridContainer = $Margin/VBox/Scroll/Pad/Shelves/ShelfGrid
@onready var reroll_button: Button = $Margin/VBox/BottomBar/RerollButton
@onready var next_button: Button = $Margin/VBox/BottomBar/NextButton

var offer: Dictionary = {}
var side_panel: Control = null

# Chaque entrée garde son `placement` (angle, décalage du scotch) : une carte
# qui change de rang dans le rayon reste le même objet posé sur le tableau.
var _cards: Array = []  # [{node: AssetCard, kind, id, data, placement}]


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(func(): get_tree().change_scene_to_file(NEXT_SCENE))
	reroll_button.pressed.connect(_on_reroll_pressed)
	UIHelpers.style_primary_button(next_button)
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 3 : Investissements" % SprintState.sprint_number

	side_panel = UIHelpers.attach_side_panel(self)
	# Un 1:1, un licenciement ou une embauche faits depuis le panneau changent ce
	# que les cartes affichent (Énergie, effectif, traits révélés) et le profil
	# d'effet des décisions — mais le panneau, lui, s'est déjà rafraîchi : on ne
	# relit que le rayon.
	side_panel.state_changed.connect(_refresh_shelf)

	offer = SprintState.get_shop_offer()
	_build_shelf()
	_refresh_shelf_head()
	_refresh_reroll_button()

	# Le nombre de colonnes suit la largeur disponible. Sans ça, une grille à
	# nombre de colonnes fixe impose sa largeur minimale et sort une barre de
	# défilement horizontale dès que le Panneau de bord a pris sa place.
	scroll.resized.connect(_fit_columns)
	_fit_columns()


# ── Le rayon ──────────────────────────────────────────────────────────────
func _build_shelf() -> void:
	var slots: Array = offer.get("slots", []).duplicate()

	# Les cartes à prérequis punaisées par leur bail (🔒) s'ajoutent au tirage
	# au lieu de lui prendre une place : une carte gatée reste sous les yeux le
	# temps qu'on réunisse sa condition, sans rogner sur ce qu'on découvre.
	for leased_id in SprintState.get_leased_decision_ids():
		var already := false
		for slot in slots:
			if slot.get("kind", "") == "decision" and slot.get("id", "") == leased_id:
				already = true
		if not already:
			slots.append({"kind": "decision", "id": leased_id, "data": {}})

	for slot in slots:
		_add_card(slot.get("kind", ""), slot.get("id", ""), slot.get("data", {}))

	if _cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Le rayon est vide ce sprint — le marché a aussi ses pénuries."
		empty_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
		shelf_grid.add_child(empty_label)


func _add_card(kind: String, asset_id: String, data: Dictionary) -> void:
	var placement := _cards.size()
	var entry := {"kind": kind, "id": asset_id, "data": data, "placement": placement}
	var card := AssetCard.create(_descriptor(entry))
	card.pin_pressed.connect(_on_pin_pressed.bind(kind, asset_id, data))

	match kind:
		"candidate":
			card.primary_pressed.connect(_on_hire_pressed.bind(data))
			card.secondary_pressed.connect(_on_one_on_one_pressed.bind(data))
		"practice":
			card.primary_pressed.connect(_on_buy_practice_pressed.bind(asset_id))
		"decision":
			card.primary_pressed.connect(_on_card_activate.bind(asset_id))

	entry["node"] = card
	shelf_grid.add_child(card)
	_cards.append(entry)


## Le descripteur d'un emplacement, quel que soit son type. Les pratiques et les
## décisions sont relues dans les données à chaque fois (leur état vit dans
## SprintState) ; un candidat, lui, est une **instance** tirée — son trait caché
## a été roulé à l'apparition et ne doit pas être re-tiré.
func _descriptor(entry: Dictionary) -> Dictionary:
	var descriptor: Dictionary = {}
	match entry.get("kind", ""):
		"candidate":
			descriptor = AssetView.for_candidate(entry.get("data", {}))
		"practice":
			descriptor = AssetView.for_practice(SprintState.find_practice(entry.get("id", "")))
		"decision":
			descriptor = AssetView.for_decision(SprintState.find_card(entry.get("id", "")))
	return UIHelpers.apply_card_placement(descriptor, int(entry.get("placement", 0)))


## **Rien ne bouge dans le rayon.** Un premier jet reléguait en fin de rayon ce
## qui venait d'être acquis, pour mettre en avant ce qu'il restait à décider :
## c'était un mauvais échange. La carte qu'on vient d'acheter est précisément
## celle qu'on regarde, et la voir sauter ailleurs au moment du clic casse le
## lien entre le geste et son effet — on cherche des yeux ce qu'on tenait. Le
## feedback d'acquisition est le **tampon** posé sur place (§5.2), pas un
## déplacement. Une carte gagne sa place au tirage et la garde tout le sprint.
func _is_acquired(entry: Dictionary) -> bool:
	match entry.get("kind", ""):
		"candidate":
			return entry.get("data", {}).get("hired", false)
		"practice":
			return SprintState.has_practice(entry.get("id", ""))
		"decision":
			return SprintState.activated_cards.has(entry.get("id", ""))
	return false


func _refresh_shelf_head() -> void:
	UIHelpers.clear_children(shelf_head)

	var used: int = SprintState.activated_cards.size()
	var maximum := SprintState.get_tool_slot_capacity()
	var parts: Array = []
	if int(offer.get("rerolls", 0)) > 0:
		parts.append("re-tiré %d fois ce sprint" % int(offer.get("rerolls", 0)))
	else:
		parts.append("tiré une fois par sprint — revenir sur l'écran ne re-tire pas")
	if used >= maximum:
		parts.append("🃏 %d/%d — plus de slot de grande décision ce mandat" % [used, maximum])
	else:
		parts.append("🃏 %d/%d grandes décisions activées" % [used, maximum])
	if SprintState.next_hire_discount > 0:
		parts.append("réseau : −%d 🪙 de budget sur la prochaine embauche" % SprintState.next_hire_discount)

	shelf_head.add_child(UIHelpers.make_shelf_head("📦 L'étal du sprint", " · ".join(parts)))


# ── 🎲 Re-tirer l'offre ───────────────────────────────────────────────────
## Le prix monte à chaque re-tirage du sprint : le premier coup d'œil de plus
## est presque gratuit, s'acharner ne l'est pas. Ce qui est punaisé (📌) reste.
func _on_reroll_pressed() -> void:
	if SprintState.reroll_shop_offer() != "":
		return
	offer = SprintState.get_shop_offer()
	_rebuild_shelf()
	_refresh_all()


func _rebuild_shelf() -> void:
	for child in shelf_grid.get_children():
		shelf_grid.remove_child(child)
		child.queue_free()
	_cards.clear()
	_build_shelf()


func _refresh_reroll_button() -> void:
	var reroll_conf: Dictionary = GameData.balance.get("shopDraw", {}).get("reroll", {})
	var cost := SprintState.shop_reroll_cost()
	reroll_button.text = "🎲 Re-tirer l'offre — %d 🪙" % cost
	reroll_button.disabled = SprintState.pieces < cost
	reroll_button.tooltip_text = "Re-tire tout le rayon, sauf ce qui est punaisé 📌.\nLe prix monte à chaque re-tirage du sprint (le prochain coûtera %d 🪙) et repart à %d au sprint suivant.\nBudget d'investissement disponible : %d 🪙." % [
		cost + int(reroll_conf.get("costIncrement", 1)),
		int(reroll_conf.get("baseCost", 1)),
		SprintState.pieces,
	]


# ── Rafraîchissements ─────────────────────────────────────────────────────
## Un achat change l'état de *tout* le rayon : les pièces baissent pour les
## trois types, l'effectif monte, Entretiens structurés révèle les candidats
## déjà sur l'étal, un licenciement change le profil d'effet des décisions.
func _refresh_shelf() -> void:
	for entry in _cards:
		entry["node"].set_descriptor(_descriptor(entry))
	_refresh_shelf_head()
	_refresh_reroll_button()


func _refresh_all() -> void:
	_refresh_shelf()
	if side_panel != null:
		side_panel.refresh()


func _fit_columns() -> void:
	# Marges du Pad (16 + 16) et gouttière laissée à la barre de défilement
	# verticale, qui mord sur la largeur utile du ScrollContainer.
	var usable := scroll.size.x - 32.0 - 14.0
	var columns := int(floor((usable + GRID_SEPARATION) / float(AssetCard.MIN_WIDTH + GRID_SEPARATION)))
	shelf_grid.columns = clampi(columns, 1, MAX_COLUMNS)


# ── Gestes ────────────────────────────────────────────────────────────────
func _on_hire_pressed(candidate: Dictionary) -> void:
	SprintState.hire_candidate(candidate)
	_refresh_all()


func _on_one_on_one_pressed(candidate: Dictionary) -> void:
	SprintState.do_one_on_one(candidate)
	_refresh_all()


func _on_buy_practice_pressed(practice_id: String) -> void:
	SprintState.buy_practice(practice_id)
	_refresh_all()


func _on_card_activate(card_id: String) -> void:
	if SprintState.activate_decision(card_id) != "":
		return
	_refresh_all()


## 📌 Réserver / décoller : l'état vit dans SprintState, la carte se relit.
func _on_pin_pressed(kind: String, asset_id: String, data: Dictionary) -> void:
	if SprintState.toggle_reservation(kind, asset_id, data) != "":
		return
	_refresh_all()
