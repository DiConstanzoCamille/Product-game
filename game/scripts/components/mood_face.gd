extends Control
## Un visage, pas une barre — la lecture du 🫶 Moral au trombinoscope (#54 §5).
##
## Le Moral n'est plus une jauge de l'entreprise depuis #43 : chaque personne
## porte le sien. L'afficher en chiffre remettrait une quinzième valeur à
## surveiller ; l'afficher en visage le rend lisible sans le compter.
##
## Dessiné plutôt qu'emoji : sans police à emoji couleur, 🙂 et 😖 rendent deux
## cercles au trait quasi identiques — or c'est exactement la nuance à porter.

const CALM := Color("#dfe6ea")
const TIRED := Color("#efe6d5")
const BAD := Color("#f6dcd4")

@export var moral: int = 100:
	set(value):
		moral = value
		queue_redraw()

@export var alerting: bool = false:
	set(value):
		alerting = value
		queue_redraw()


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.46
	var c := size * 0.5
	var ink := UIHelpers.COLOR_INK

	draw_circle(c, r, _skin())
	draw_arc(c, r, 0.0, TAU, 32, ink, 2.0, true)
	draw_circle(c + Vector2(-r * 0.34, -r * 0.14), 1.9, ink)
	draw_circle(c + Vector2(r * 0.34, -r * 0.14), 1.9, ink)

	# Trois bouches, et la troisième porte des sourcils : c'est le sourcil qui
	# fait lire « ça ne va pas » plutôt que « ça va moyennement ».
	if moral >= 60 and not alerting:
		_draw_smile(c, r, 1.0, ink)
	elif moral >= 35 and not alerting:
		draw_line(c + Vector2(-r * 0.44, r * 0.34), c + Vector2(r * 0.44, r * 0.34), ink, 2.0)
	else:
		_draw_smile(c, r, -1.0, ink)
		draw_line(c + Vector2(-r * 0.6, -r * 0.46), c + Vector2(-r * 0.16, -r * 0.26), ink, 2.0)
		draw_line(c + Vector2(r * 0.6, -r * 0.46), c + Vector2(r * 0.16, -r * 0.26), ink, 2.0)


func _skin() -> Color:
	if alerting or moral < 35:
		return BAD
	return CALM if moral >= 60 else TIRED


func _draw_smile(c: Vector2, r: float, direction: float, ink: Color) -> void:
	var points := PackedVector2Array()
	for i in range(9):
		var t := float(i) / 8.0
		var x := lerpf(-r * 0.44, r * 0.44, t)
		var y := r * 0.3 - direction * sin(t * PI) * r * 0.26
		points.append(c + Vector2(x, y))
	draw_polyline(points, ink, 2.0, true)
