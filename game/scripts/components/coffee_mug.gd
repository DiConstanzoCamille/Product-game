extends Control
## ⚡ La tasse — l'Énergie du CPO, posée sur le plateau (#54 §2).
##
## L'Énergie échappe à la règle « trois valeurs et rien d'autre », et c'est
## voulu : c'est la seule ressource qui se dépense au clic, sprint après
## sprint. Une valeur qu'on dépense doit être lisible au moment où on la
## dépense — mais elle n'a rien à faire dans une zone de HUD : elle est un
## objet du monde, alors elle est une tasse.
##
## Elle se vide visuellement : c'est ce que le joueur voit avant de lire le
## chiffre.

const EMPTY_TINT := Color("#f2e2dd")


func _ready() -> void:
	custom_minimum_size = Vector2(118, 98)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = UIHelpers.energy_tooltip()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var ink := UIHelpers.COLOR_INK
	var maximum := maxf(float(SprintState.get_energy_max()), 1.0)
	var level := clampf(float(SprintState.energy) / maximum, 0.0, 1.0)

	# L'anse d'abord : elle passe derrière le corps.
	draw_arc(Vector2(92, 46), 17, -PI * 0.5, PI * 0.5, 16, ink, 4.0, true)

	var body := PackedVector2Array([
		Vector2(10, 12), Vector2(86, 12), Vector2(86, 58),
		Vector2(78, 76), Vector2(48, 84), Vector2(18, 76), Vector2(10, 58),
	])
	draw_colored_polygon(body, Color.WHITE if level > 0.25 else EMPTY_TINT)

	# Le café restant : un remplissage qui descend. C'est lui qu'on voit en
	# premier, le chiffre n'est qu'une confirmation.
	if level > 0.0:
		var top := lerpf(80.0, 20.0, level)
		draw_rect(Rect2(Vector2(14, top), Vector2(68, 80.0 - top)), Color("#6b4a2f", 0.34))

	draw_polyline(body + PackedVector2Array([Vector2(10, 12)]), ink, 3.0, true)

	var font := get_theme_default_font()
	var text := str(SprintState.energy)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 27).x
	draw_string(font, Vector2(48 - width * 0.5, 58), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 27, ink)
