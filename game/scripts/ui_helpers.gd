class_name UIHelpers
extends RefCounted
## Petits utilitaires de style partagés entre les écrans de sprint.

const COLOR_GOOD := Color(0.498039, 0.890196, 0.647059)   # #7FE3A5
const COLOR_WARN := Color(0.941176, 0.705882, 0.290196)   # #F0B44A
const COLOR_DANGER := Color(0.952941, 0.537255, 0.498039) # #F3897F
const COLOR_SOFT_TEXT := Color(0.666667, 0.713725, 0.8)   # #AAB6CC


static func state_color(state: String) -> Color:
	match state:
		"good":
			return COLOR_GOOD
		"danger":
			return COLOR_DANGER
		_:
			return COLOR_WARN


static func make_bar_fill_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style


static func make_bar_background_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.12)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style
