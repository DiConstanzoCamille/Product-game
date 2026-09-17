extends Button
## Étiquette d'objet lisible et cliquable ; dimensions stables au survol.
const HUD := preload("res://scripts/components/hud_language.gd")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_size_override("font_size", 15)
	add_theme_color_override("font_color", HUD.INK)
	add_theme_color_override("font_hover_color", HUD.CHOICE)
	add_theme_color_override("font_pressed_color", HUD.CHOICE)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = HUD.CHOICE_PAPER if state == "pressed" else HUD.PAPER
		style.border_color = HUD.RULE if state == "normal" else HUD.CHOICE
		style.set_border_width_all(2)
		style.set_corner_radius_all(7)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 9
		style.content_margin_bottom = 9
		style.shadow_color = Color(0.07, 0.12, 0.16, 0.25)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 3)
		add_theme_stylebox_override(state, style)


func set_world_hover(value: bool) -> void:
	var style := get_theme_stylebox("hover").duplicate() as StyleBoxFlat
	style.border_color = HUD.CHOICE if value else HUD.RULE
	add_theme_stylebox_override("normal", style)
