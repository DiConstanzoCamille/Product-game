extends Control
## Phase 4 — le Marché (spec profondeur §5). Un seul écran, un rayon : l'étal du
## sprint — 2 candidats (trait caché tiré à l'apparition, révélé si Entretiens
## structurés) + 2 pratiques non possédées. L'offre est tirée une fois par sprint
## et stockée dans SprintState — revenir sur l'écran ne retire pas.
##
## Depuis la refonte UI (docs/proposition-ui-interface.md §2), candidats et
## pratiques sont servis par le **même** composant que les grandes décisions : la
## carte d'Actif. Le coût, l'effectif et l'Énergie ne sont plus affichés en
## en-tête d'écran mais en continu dans le Panneau de bord, à droite.

const NEXT_SCENE := "res://scenes/screens/resolution_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var shelf_head: VBoxContainer = $Margin/VBox/ShelfHead
@onready var shop_grid: GridContainer = $Margin/VBox/Scroll/ShopGrid
@onready var next_button: Button = $Margin/VBox/BottomBar/NextButton

var offer: Dictionary = {}
var side_panel: Control = null

var _cards: Array = []  # [{node: AssetCard, kind: "candidate"|"practice", data: Dictionary}]


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(func(): get_tree().change_scene_to_file(NEXT_SCENE))
	UIHelpers.add_hover_bounce(back_button)
	UIHelpers.add_hover_bounce(next_button)
	UIHelpers.style_primary_button(next_button)
	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 4 : Marché" % SprintState.sprint_number

	side_panel = UIHelpers.attach_side_panel(self)
	# Un 1:1 ou un licenciement fait depuis le panneau change ce que les cartes
	# affichent (Énergie, effectif, traits révélés) — mais le panneau, lui, s'est
	# déjà rafraîchi : on ne relit que les cartes.
	side_panel.state_changed.connect(_refresh_cards)

	offer = SprintState.get_shop_offer()
	var index := 0
	for candidate in offer.get("candidates", []):
		var card := _add_card("candidate", candidate, index)
		card.primary_pressed.connect(_on_hire_pressed.bind(candidate))
		card.secondary_pressed.connect(_on_one_on_one_pressed.bind(candidate))
		index += 1
	for practice_id in offer.get("practices", []):
		var practice: Dictionary = SprintState.find_practice(practice_id)
		var card := _add_card("practice", practice, index)
		card.primary_pressed.connect(_on_buy_practice_pressed.bind(practice))
		index += 1

	if _cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "L'étal est vide ce sprint — le marché des talents a aussi ses pénuries."
		empty_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
		shop_grid.add_child(empty_label)

	_refresh_shelf_head()


func _add_card(kind: String, data: Dictionary, index: int) -> AssetCard:
	var card := AssetCard.create(_descriptor_for(kind, data, index))
	shop_grid.add_child(card)
	_cards.append({"node": card, "kind": kind, "data": data})
	return card


func _descriptor_for(kind: String, data: Dictionary, index: int) -> Dictionary:
	var descriptor: Dictionary = AssetView.for_candidate(data) if kind == "candidate" else AssetView.for_practice(data)
	descriptor["tilt"] = UIHelpers.card_tilt(index)
	return descriptor


## Une embauche, un 1:1 ou une pratique adoptée changent l'état de toutes les
## cartes (les pièces baissent, l'effectif monte, et Entretiens structurés
## révèle les candidats déjà sur l'étal) : on relit tout.
func _refresh_cards() -> void:
	var index := 0
	for entry in _cards:
		entry["node"].set_descriptor(_descriptor_for(entry["kind"], entry["data"], index))
		index += 1
	_refresh_shelf_head()


func _refresh_all() -> void:
	_refresh_cards()
	if side_panel != null:
		side_panel.refresh()


func _refresh_shelf_head() -> void:
	for child in shelf_head.get_children():
		child.free()

	var subtitle := "tiré une fois par sprint — revenir sur l'écran ne re-tire pas"
	if SprintState.next_hire_discount > 0:
		subtitle += " · réseau : −%d 🪙 sur la prochaine embauche" % SprintState.next_hire_discount
	shelf_head.add_child(UIHelpers.make_shelf_head("📦 L'étal du sprint", subtitle))


func _on_hire_pressed(candidate: Dictionary) -> void:
	SprintState.hire_candidate(candidate)
	_refresh_all()


func _on_one_on_one_pressed(candidate: Dictionary) -> void:
	SprintState.do_one_on_one(candidate)
	_refresh_all()


func _on_buy_practice_pressed(practice: Dictionary) -> void:
	SprintState.buy_practice(practice.get("id", ""))
	_refresh_all()
