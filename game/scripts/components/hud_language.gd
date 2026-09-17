extends RefCounted
## Prototype de langage visuel : choix bleu, résultat vert, risque ambre.
## Tokens artistiques uniquement ; aucune règle ni seuil de gameplay.
const CHOICE := Color("#285d94")
const CHOICE_PAPER := Color("#e4effa")
const PAPER := Color("#fffdf7")
const INK := Color("#263747")
const RULE := Color("#cbd4da")
const RISK := Color("#986012")


static func ticket_style(planned: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CHOICE_PAPER if planned else PAPER
	style.border_color = CHOICE if planned or hovered else RULE
	style.set_border_width_all(2 if planned or hovered else 1)
	style.border_width_left = 6 if planned else style.border_width_left
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.08, 0.16, 0.23, 0.18)
	style.shadow_size = 5 if hovered else 2
	style.shadow_offset = Vector2(0, 2)
	return style
