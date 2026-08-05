extends Control
## Les pictogrammes des applications, dessinés.
##
## Première version : des caractères (✉, ▤). La capture de recette a montré des
## carrés vides — la police du jeu ne porte pas ces glyphes, et personne ne
## l'aurait vu sans l'image. Dessiner coûte vingt lignes et ne dépend d'aucune
## police (carnet : la capture attrape ce que le test ne voit pas).

@export var glyph: String = "mail"


func _draw() -> void:
	var c := UIHelpers.PANEL_FG
	match glyph:
		"mail":
			var r := Rect2(Vector2(4, 8), Vector2(48, 34))
			draw_rect(r, c, false, 3.0)
			draw_polyline(PackedVector2Array([Vector2(4, 12), Vector2(28, 30), Vector2(52, 12)]), c, 3.0, true)
		"road":
			draw_rect(Rect2(Vector2(6, 6), Vector2(18, 40)), c, false, 3.0)
			draw_rect(Rect2(Vector2(32, 6), Vector2(18, 24)), c, false, 3.0)
		_:
			draw_polyline(PackedVector2Array([
				Vector2(5, 42), Vector2(17, 33), Vector2(28, 24), Vector2(39, 16), Vector2(52, 7),
			]), UIHelpers.PANEL_GOOD, 4.0, true)
