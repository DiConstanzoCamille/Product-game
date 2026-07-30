class_name AssetCard
extends PanelContainer
## La carte d'**Actif** — le composant unique des trois objets que
## l'organisation acquiert : grande décision, candidat, pratique
## (docs/proposition-ui-interface.md §2.2). Six zones fixes, toujours à la même
## place, quel que soit le type :
##
##   ① pastille de type + référence de formulaire
##   ② identité : portrait/pastille d'initiale (candidat) ou icône d'objet
##   ③ accroche (tagline, trait, description) + badges
##   ④ IMPACT — lignes « ressource + delta + note », dont les inconnues 🔒/❓
##   ⑤ COÛT (bandeau bas, poussé contre les actions)
##   ⑥ ACTIONS — verbe spécifique + action personnelle secondaire
##
## La carte ne connaît ni les données du jeu ni les règles : elle affiche un
## descripteur produit par AssetView (scripts/asset_view.gd) et signale les
## clics. C'est l'écran qui décide ce que « Embaucher » veut dire.
##
## Pièges Godot du spike, tous évités ici : les décorations (scotch, trou de
## lanière) vivent dans un Control de surimpression — un PanelContainer étire
## TOUS ses enfants, donc un ColorRect posé directement sur la carte
## recouvrirait le contenu ; et les icônes d'objet passent par
## UIHelpers.make_item_icon(), qui force EXPAND_IGNORE_SIZE.

signal primary_pressed
signal secondary_pressed

const MIN_WIDTH := 236

var _descriptor: Dictionary = {}
var _tilt_degrees: float = 0.0


## Fabrique : instancie la scène et lui donne son descripteur. La carte se
## construit à son entrée dans l'arbre, donc `create()` puis `add_child()`
## fonctionne dans les deux ordres.
static func create(descriptor: Dictionary) -> AssetCard:
	var scene: PackedScene = load("res://scenes/components/asset_card.tscn")
	var card: AssetCard = scene.instantiate()
	card.set_descriptor(descriptor)
	return card


func set_descriptor(descriptor: Dictionary) -> void:
	_descriptor = descriptor
	if is_inside_tree():
		_rebuild()


func _ready() -> void:
	custom_minimum_size = Vector2(MIN_WIDTH, 0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resized.connect(_on_resized)
	if not _descriptor.is_empty():
		_rebuild()


func _on_resized() -> void:
	pivot_offset = size / 2.0
	rotation_degrees = _tilt_degrees


func _rebuild() -> void:
	var vbox: VBoxContainer = get_node("Margin/VBox")
	for child in vbox.get_children():
		child.free()

	_tilt_degrees = float(_descriptor.get("tilt", 0.0))
	pivot_offset = size / 2.0
	rotation_degrees = _tilt_degrees

	_apply_paper_style()
	_build_decorations()

	_zone_type(vbox)
	_zone_identity(vbox)
	_zone_flavor(vbox)
	_zone_impact(vbox)
	_zone_cost(vbox)
	_zone_actions(vbox)


## Le papier de la carte : blanc pour le badge candidat, jaune post-it pour une
## pratique, crème cartonné pour une décision — plus l'ombre portée qui la fait
## flotter au-dessus du tableau blanc.
func _apply_paper_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = _descriptor.get("bg_color", UIHelpers.COLOR_CARD_CANDIDATE)
	style.set_corner_radius_all(int(_descriptor.get("corner_radius", 3)))
	style.border_color = Color(0, 0, 0, 0.08)
	style.set_border_width_all(1)
	style.shadow_color = Color(0.156863, 0.196078, 0.27451, 0.22)
	style.shadow_size = 7
	style.shadow_offset = Vector2(2, 4)
	if _descriptor.get("dimmed", false):
		style.bg_color = style.bg_color.lerp(UIHelpers.COLOR_SCREEN_BG, 0.45)
		style.shadow_size = 3
	add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = get_node("Margin")
	# Le badge d'accès garde de la place pour son trou de lanière.
	margin.add_theme_constant_override(
		"margin_top", 21 if _descriptor.get("decoration", "") == "lanyard" else 13
	)


## Scotch translucide (pratiques, décisions) ou trou de lanière (candidats).
## Posés dans le Control "Decorations", que le PanelContainer étire à la taille
## de la carte : leurs positions sont donc locales et suivent le défilement,
## contrairement au `top_level` du spike.
func _build_decorations() -> void:
	var layer: Control = get_node("Decorations")
	for child in layer.get_children():
		child.free()
	# La carte se reconstruit à chaque changement d'état : sans ça, le callable
	# de placement de la décoration précédente reste branché sur `resized` et
	# référence un nœud déjà libéré.
	for connection in layer.resized.get_connections():
		layer.resized.disconnect(connection["callable"])

	var kind: String = _descriptor.get("decoration", "")
	if kind == "":
		return

	var piece := ColorRect.new()
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "lanyard":
		piece.color = Color("#e2e6ec")
		piece.size = Vector2(34, 8)
	else:
		piece.color = Color(1, 1, 1, 0.55)
		piece.size = Vector2(64, 16)
		piece.pivot_offset = Vector2(32, 8)
		piece.rotation_degrees = -2.0
	layer.add_child(piece)

	var place := func():
		piece.position = Vector2(
			round(layer.size.x / 2.0 - piece.size.x / 2.0),
			7.0 if kind == "lanyard" else -5.0
		)
	place.call()
	layer.resized.connect(place)


# ── ① Type + référence ────────────────────────────────────────────────────
func _zone_type(vbox: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	vbox.add_child(row)

	var pill_color: Color = _descriptor.get("pill_color", UIHelpers.PILL_DECISION)
	var pill := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = pill_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", style)
	pill.add_child(_label(_descriptor.get("pill_text", "").to_upper(), 9, pill_color))
	row.add_child(pill)

	row.add_child(_spacer_h())

	var ref_label := _label(_descriptor.get("ref", ""), 10, UIHelpers.COLOR_SOFT_TEXT)
	UIHelpers.apply_mono(ref_label, 10)
	ref_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ref_label)


# ── ② Identité ───────────────────────────────────────────────────────────
func _zone_identity(vbox: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	vbox.add_child(row)

	var person: String = _descriptor.get("person_name", "")
	var item_icon: int = int(_descriptor.get("item_icon", 0))
	if person != "":
		row.add_child(UIHelpers.make_person_badge(person, 36, _descriptor.get("pill_color", UIHelpers.PILL_CANDIDATE)))
	elif item_icon > 0:
		row.add_child(UIHelpers.make_item_icon(item_icon, 34))

	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)

	var title := _label(_descriptor.get("title", ""), 16, UIHelpers.COLOR_INK, true)
	UIHelpers.apply_heading(title, 16, 600.0)
	texts.add_child(title)

	if _descriptor.get("subtitle", "") != "":
		texts.add_child(_label(_descriptor.get("subtitle", ""), 11, UIHelpers.COLOR_SOFT_TEXT, true))


# ── ③ Accroche + badges ──────────────────────────────────────────────────
func _zone_flavor(vbox: VBoxContainer) -> void:
	if _descriptor.get("tagline", "") != "":
		vbox.add_child(_label(_descriptor.get("tagline", ""), 12, UIHelpers.COLOR_FLAVOR, true))
	if _descriptor.get("badges", "") != "":
		vbox.add_child(_label(_descriptor.get("badges", ""), 10, UIHelpers.COLOR_SOFT_TEXT, true))


# ── ④ Impact : en ressources, inconnues comprises ────────────────────────
func _zone_impact(vbox: VBoxContainer) -> void:
	var impacts: Array = _descriptor.get("impacts", [])
	if impacts.is_empty():
		return

	vbox.add_child(_dashed_rule())

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	vbox.add_child(list)

	for impact in impacts:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		if impact.get("tooltip", "") != "":
			row.mouse_filter = Control.MOUSE_FILTER_STOP
			row.tooltip_text = impact.get("tooltip", "")
		list.add_child(row)

		var locked: bool = impact.get("locked", false)
		var label := _label(
			impact.get("label", ""), 11,
			UIHelpers.COLOR_SOFT_TEXT if locked else UIHelpers.COLOR_INK, true
		)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var delta_color := UIHelpers.COLOR_GOOD if impact.get("good", true) else UIHelpers.COLOR_DANGER
		if impact.get("unknown", false):
			delta_color = UIHelpers.COLOR_UNKNOWN
		var delta := _label(impact.get("delta", ""), 11, delta_color)
		UIHelpers.apply_mono(delta, 11, true)
		delta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(delta)


# ── ⑤ Coût ───────────────────────────────────────────────────────────────
func _zone_cost(vbox: VBoxContainer) -> void:
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(filler)

	if _descriptor.get("cost", "") == "":
		return
	vbox.add_child(_dashed_rule())
	vbox.add_child(_label(_descriptor.get("cost", ""), 11, UIHelpers.COLOR_INK, true))


# ── ⑥ Actions ────────────────────────────────────────────────────────────
func _zone_actions(vbox: VBoxContainer) -> void:
	var primary: Dictionary = _descriptor.get("primary", {})
	var secondary: Dictionary = _descriptor.get("secondary", {})
	if primary.is_empty() and secondary.is_empty():
		return

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	vbox.add_child(row)

	if not secondary.is_empty():
		row.add_child(_action_button(secondary, false, secondary_pressed))
	if not primary.is_empty():
		var button := _action_button(primary, true, primary_pressed)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)


func _action_button(action: Dictionary, primary: bool, pressed_signal: Signal) -> Button:
	var button := Button.new()
	button.text = action.get("text", "")
	button.disabled = action.get("disabled", false)
	button.tooltip_text = action.get("tooltip", "")
	button.add_theme_font_size_override("font_size", 12)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD
	if primary and not button.disabled:
		UIHelpers.style_primary_button(button)
	if not button.disabled:
		UIHelpers.add_hover_bounce(button, 1.03)
		button.pressed.connect(func(): pressed_signal.emit())
	return button


# ── Petits constructeurs ─────────────────────────────────────────────────
func _label(text: String, size: int, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return label


func _dashed_rule() -> Control:
	var rule := UIHelpers.DashedRule.new()
	rule.rule_color = UIHelpers.COLOR_RULE
	return rule


func _spacer_h() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer
