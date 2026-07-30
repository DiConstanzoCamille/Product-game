extends Control
## Le **cadre d'écran** — les écrans de choix (accueil, scénario, entreprise, fin
## de mandat) sont vus *à travers* l'ordinateur portable posé sur le bureau du
## CPO : biseau aluminium, webcam, menton de marque, reflet oblique.
##
## Pourquoi seulement ces écrans : ce sont ceux qui parlent à travers un outil —
## une offre d'emploi qu'on lit, un dossier qu'on consulte, un bilan de mandat.
## Les écrans de phase, eux, sont le monde physique de l'openspace (tableau
## blanc, fiches, post-it) : les enfermer dans un écran contredirait la
## direction « Post-it & Feutre » au lieu de la servir.
##
## Le cadre est purement décoratif — `mouse_filter = IGNORE` sur toute la
## hiérarchie, aucun clic ne peut se perdre dedans. UIHelpers.attach_device_frame()
## l'ajoute et repousse les marges de l'écran hôte pour qu'il tienne dedans.

const BEZEL := 20      # biseau gauche/droite/haut
const CHIN := 34       # menton du bas, plus épais, comme sur un portable
const RADIUS := 18

const ALUMINIUM := Color("#d2d7de")
const ALUMINIUM_EDGE := Color("#aab0ba")
const CHIN_MARK := Color("#7c8492")
const OUTER_EDGE := 4  # liseré sombre du chant : deux tons, et l'alu se lit métal


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	# Le biseau est dessiné comme la *bordure* d'un panneau au centre
	# transparent : le contenu de l'écran reste visible au travers, sans avoir à
	# découper quoi que ce soit.
	var chant := Panel.new()
	chant.set_anchors_preset(Control.PRESET_FULL_RECT)
	chant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chant_style := StyleBoxFlat.new()
	chant_style.bg_color = Color(0, 0, 0, 0)
	chant_style.border_color = ALUMINIUM_EDGE
	chant_style.set_border_width_all(OUTER_EDGE)
	chant_style.set_corner_radius_all(RADIUS)
	chant.add_theme_stylebox_override("panel", chant_style)
	add_child(chant)

	var bezel := Panel.new()
	bezel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bezel.offset_left = OUTER_EDGE
	bezel.offset_top = OUTER_EDGE
	bezel.offset_right = -OUTER_EDGE
	bezel.offset_bottom = -OUTER_EDGE
	bezel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = ALUMINIUM
	style.border_width_left = BEZEL - OUTER_EDGE
	style.border_width_right = BEZEL - OUTER_EDGE
	style.border_width_top = BEZEL - OUTER_EDGE
	style.border_width_bottom = CHIN - OUTER_EDGE
	style.set_corner_radius_all(RADIUS - OUTER_EDGE)
	bezel.add_theme_stylebox_override("panel", style)
	add_child(bezel)

	# Filet sombre côté dalle : sans lui, l'aluminium et le papier se touchent
	# sans transition et le cadre ne se lit plus comme une profondeur.
	var inner := Panel.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = BEZEL
	inner.offset_top = BEZEL
	inner.offset_right = -BEZEL
	inner.offset_bottom = -CHIN
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color(0, 0, 0, 0)
	inner_style.border_color = Color(UIHelpers.COLOR_INK.r, UIHelpers.COLOR_INK.g, UIHelpers.COLOR_INK.b, 0.35)
	inner_style.set_border_width_all(2)
	inner_style.set_corner_radius_all(4)
	inner.add_theme_stylebox_override("panel", inner_style)
	add_child(inner)

	add_child(_webcam())
	add_child(_brand())
	add_child(_glare())


## La pastille de webcam, centrée dans le biseau du haut.
func _webcam() -> Control:
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(7, 7)
	dot.size = Vector2(7, 7)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#3b4250")
	style.border_color = Color("#8c93a0")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	dot.add_theme_stylebox_override("panel", style)

	var place := func():
		dot.position = Vector2(round(size.x / 2.0 - 3.5), (BEZEL - 7) / 2.0)
	place.call()
	resized.connect(place)
	return dot


## La marque gravée dans le menton — le jeu parodie les outils, il peut bien
## parodier le matériel.
func _brand() -> Control:
	var label := Label.new()
	label.text = "PRODUCTIVITY™"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIHelpers.apply_mono(label, 9, true)
	label.add_theme_color_override("font_color", CHIN_MARK)

	var place := func():
		var width := label.get_combined_minimum_size().x
		label.position = Vector2(round(size.x / 2.0 - width / 2.0), round(size.y - CHIN / 2.0 - 7))
	place.call()
	resized.connect(place)
	label.resized.connect(place)
	return label


## Reflet oblique sur la dalle : deux bandes très pâles en haut à gauche. Assez
## discret pour ne jamais gêner la lecture d'un texte long.
func _glare() -> Control:
	var glare := ScreenGlare.new()
	glare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glare.set_anchors_preset(Control.PRESET_FULL_RECT)
	glare.bezel = BEZEL
	return glare


## Le reflet est dessiné à la main : un `Polygon2D` ne se laisse pas ancrer comme
## un Control, et un dégradé en texture serait un asset de plus à maintenir.
class ScreenGlare extends Control:
	var bezel: int = 20

	func _init() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w := size.x - bezel * 2.0
		var h := size.y - bezel * 2.0
		if w <= 0.0 or h <= 0.0:
			return
		var origin := Vector2(bezel, bezel)
		# Reflet en gris **froid** et non en blanc : sur une dalle claire, un voile
		# blanc ne se voit pas — c'est la pièce qui se reflète, donc plus sombre.
		_band(origin, w, h, 0.06, 0.34, Color(0.42, 0.48, 0.58, 0.055))
		_band(origin, w, h, 0.40, 0.50, Color(0.42, 0.48, 0.58, 0.03))

	func _band(origin: Vector2, w: float, h: float, from_ratio: float, to_ratio: float, tint: Color) -> void:
		# Bande oblique qui part du bord haut et sort par le bord gauche.
		var points := PackedVector2Array([
			origin + Vector2(w * from_ratio, 0),
			origin + Vector2(w * to_ratio, 0),
			origin + Vector2(0, h * to_ratio * 1.6),
			origin + Vector2(0, h * from_ratio * 1.6),
		])
		draw_colored_polygon(points, tint)
