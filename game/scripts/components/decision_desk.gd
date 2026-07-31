class_name DecisionDesk
extends Control
## Bureau vu de face derrière les écrans de décision. La dalle (papier réglé)
## est un Control séparé placé au-dessus ; ce nœud ne dessine que le mobilier.

var display_rect := Rect2()
var _elapsed := 0.0
var _redraw_elapsed := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	# 20 i/s suffit à une lumière d'ambiance et évite de faire redessiner l'UI
	# à la fréquence d'un jeu d'action.
	_redraw_elapsed += delta
	if _redraw_elapsed >= 0.05:
		_redraw_elapsed = 0.0
		queue_redraw()


func set_display_rect(rect: Rect2) -> void:
	display_rect = rect
	queue_redraw()


func _draw() -> void:
	if display_rect.size.x <= 0.0 or display_rect.size.y <= 0.0:
		return
	_draw_desk_ambience()

	# La dalle est volontairement sobre : c'est la surface claire qui porte les
	# décisions, l'aluminium sert seulement à rendre lisible l'objet ordinateur.
	var bezel := display_rect.grow_individual(24, 28, 24, 42)
	var body := StyleBoxFlat.new()
	body.bg_color = Color("#c9d0da")
	body.border_color = Color("#727d8c")
	body.set_border_width_all(3)
	body.set_corner_radius_all(16)
	body.shadow_color = Color(0.12, 0.15, 0.2, 0.32)
	body.shadow_size = 16
	body.shadow_offset = Vector2(0, 10)
	draw_style_box(body, bezel)

	# Liseré noir entre la dalle et le châssis, plus webcam et menton gravé.
	draw_rect(display_rect.grow(3), Color("#1e2733"), false, 3)
	var cam_center := Vector2(display_rect.get_center().x, bezel.position.y + 15)
	draw_circle(cam_center, 4.5, Color("#3c4858"))
	draw_circle(cam_center, 2.0, Color("#8da8bc"))
	draw_string(UIHelpers.FONT_MONO_SEMIBOLD,
		Vector2(display_rect.get_center().x - 46, display_rect.end.y + 27),
		"PRODUCT GAME", HORIZONTAL_ALIGNMENT_CENTER, 92, 9, Color("#697484"))

	# Une base très fine suffit à faire lire le portable sans recouvrir le bouton
	# de fin de phase ; elle reste hors de la dalle, donc hors des décisions.
	var base_top := bezel.end.y
	var base_points := PackedVector2Array([
		Vector2(bezel.position.x + 14, base_top),
		Vector2(bezel.end.x - 14, base_top),
		Vector2(bezel.end.x + 36, base_top + 24),
		Vector2(bezel.position.x - 36, base_top + 24),
	])
	draw_colored_polygon(base_points, Color("#b2bbc8"))
	draw_polyline(base_points, Color("#727d8c"), 2.0, true)
	var trackpad := Rect2(display_rect.get_center().x - 65, base_top + 4, 130, 10)
	draw_rect(trackpad, Color("#98a3b1"), false, 1.2)


## Vie du bureau, derrière l'ordinateur uniquement : le reflet de fenêtre met
## presque une minute à traverser la table et les poussières ne sont visibles
## qu'à l'arrêt. Ce mouvement lent raconte un espace habité sans attirer l'œil
## loin d'un ticket ou d'un bouton.
func _draw_desk_ambience() -> void:
	var y := 34.0
	while y < size.y:
		var wobble := sin(_elapsed * 0.12 + y * 0.03) * 4.0
		draw_line(Vector2(0, y + wobble), Vector2(size.x, y + 10 + wobble), Color(0.32, 0.22, 0.14, 0.11), 1.0)
		y += 58.0

	var drift := sin(_elapsed * 0.10) * 72.0
	var light := PackedVector2Array([
		Vector2(-220 + drift, -10),
		Vector2(40 + drift, -10),
		Vector2(460 + drift, size.y + 10),
		Vector2(185 + drift, size.y + 10),
	])
	draw_colored_polygon(light, Color(1.0, 0.91, 0.72, 0.055))

	for index in range(11):
		var x := fposmod(83.0 + index * 173.0 + _elapsed * (2.0 + index % 3), maxf(size.x, 1.0))
		var y_pos := fposmod(31.0 + index * 97.0 + sin(_elapsed * 0.34 + index) * 18.0, maxf(size.y, 1.0))
		var alpha := 0.10 + sin(_elapsed * 0.55 + index * 1.7) * 0.035
		draw_circle(Vector2(x, y_pos), 1.2 + float(index % 2) * 0.45, Color(1.0, 0.96, 0.82, alpha))
