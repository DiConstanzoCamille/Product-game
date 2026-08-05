extends Control
## Un accessoire qui entre dans le cadre (#54 §3).
##
## Aucune mécanique n'ouvre un écran de plus : elle fait entrer un objet, et
## **la forme de l'objet dit ce qu'est la mécanique**.
##
##  · 🛒 `shop` — une tablette, à droite. Ça se feuillette et ça se repousse :
##    l'étal du sprint est ouvert en permanence.
##  · 🏁 `closing` — une planche à pince, à gauche. On signe debout, une fois :
##    c'est le seul point de non-retour du sprint.
##  · 🏛 `committee` — un parapheur, **déposé sur la table** un sprint sur
##    trois. Il n'arrive pas du bord : le board pose le dossier du trimestre
##    devant vous, il ne vous le tend pas.
##
## Au repos, l'objet affleure le bord — assez pour qu'on sache qu'il est là,
## pas assez pour encombrer. Ouvert, il occupe une grande dalle : les écrans
## hébergés (Investissements, Comité) sont ceux du jeu actuel et ont besoin de
## place. C'est un nœud de la scène animé par `Tween`, jamais un `Popup` — un
## popup Godot ne sait pas glisser depuis le bord.

signal state_changed

const SLIDE_SECONDS := 0.34

## Géométrie par nature : repos (affleurant), ouvert (grande dalle), matière.
const SHAPES := {
	"shop": {
		"rest": Rect2(Vector2(1560, 300), Vector2(334, 456)),
		"open": Rect2(Vector2(420, 96), Vector2(1120, 760)),
		"body": Color("#2b3240"), "frame": Color("#454d5c"), "radius": 22,
		"hint": "◂ Boutique", "hint_at": Vector2(-104, 168),
	},
	"closing": {
		"rest": Rect2(Vector2(-266, 380), Vector2(306, 426)),
		"open": Rect2(Vector2(120, 120), Vector2(560, 690)),
		"body": Color("#8a6a45"), "frame": Color("#5e4830"), "radius": 8,
		"hint": "Fin de sprint ▸", "hint_at": Vector2(48, 154),
	},
	"committee": {
		"rest": Rect2(Vector2(1150, 660), Vector2(274, 186)),
		"open": Rect2(Vector2(300, 96), Vector2(1000, 760)),
		"body": Color("#7b3f3f"), "frame": Color("#4e2727"), "radius": 8,
		"hint": "Déposé sur votre table", "hint_at": Vector2(6, -26),
	},
}

const HOSTED := {
	"shop": "res://scenes/screens/investments_screen.tscn",
	"committee": "res://scenes/screens/committee_screen.tscn",
}

@export var kind: String = "shop"

var _open := false
var _rect := Rect2()
var _body: Control = null
var _hint: Label = null
var _tween: Tween = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = Vector2(1600, 900)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_rect = _shape().get("rest", Rect2())

	_body = Control.new()
	_body.name = "Body"
	_body.clip_contents = true
	_body.mouse_filter = Control.MOUSE_FILTER_STOP
	_body.gui_input.connect(_on_body_input)
	add_child(_body)

	_hint = Label.new()
	_hint.text = String(_shape().get("hint", ""))
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.add_theme_color_override("font_color", Color("#6b5a45"))
	UIHelpers.apply_mono(_hint, 11, true)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)

	_apply(_rect)
	refresh()


func _shape() -> Dictionary:
	return SHAPES.get(kind, SHAPES["shop"])


## Le parapheur du Comité **n'existe pas** hors fin de trimestre : ce n'est pas
## un objet grisé, c'est un objet absent. C'est ce qui fait qu'un sprint sur
## trois ne ressemble pas aux deux autres.
func refresh() -> void:
	if kind == "committee":
		var available := _committee_open()
		visible = available
		if not available and _open:
			collapse()
	if not _open:
		_fill_rest()
	queue_redraw()


func _committee_open() -> bool:
	return SprintState.committee_pending


func _on_body_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _open:
			return
		expand()


# ── Entrer, sortir ───────────────────────────────────────────────────────
func expand() -> void:
	if _open:
		return
	_open = true
	_slide_to(_shape().get("open", Rect2()), _fill_open)


func collapse() -> void:
	if not _open:
		return
	# Le dossier a été ouvert : il quitte la table. C'est ce qui fait qu'un
	# sprint sur trois ne ressemble pas aux deux autres — pas un compteur.
	if kind == "committee":
		SprintState.committee_pending = false
	_open = false
	_slide_to(_shape().get("rest", Rect2()), _fill_rest)
	state_changed.emit()


func _slide_to(target: Rect2, then: Callable) -> void:
	UIHelpers.clear_children(_body)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_apply_interpolated.bind(_rect, target), 0.0, 1.0, SLIDE_SECONDS)
	_tween.finished.connect(func():
		_rect = target
		_apply(target)
		then.call())


func _apply_interpolated(t: float, from: Rect2, to: Rect2) -> void:
	_apply(Rect2(from.position.lerp(to.position, t), from.size.lerp(to.size, t)))


func _apply(rect: Rect2) -> void:
	_rect = rect
	_body.position = rect.position + Vector2(12, 12)
	_body.size = rect.size - Vector2(24, 24)
	_hint.position = rect.position + Vector2(_shape().get("hint_at", Vector2.ZERO))
	_hint.visible = not _open
	queue_redraw()


func _draw() -> void:
	var shape := _shape()
	var radius := float(shape.get("radius", 8))
	draw_rect_rounded(_rect, shape.get("frame", Color.BLACK), radius)
	draw_rect_rounded(Rect2(_rect.position + Vector2(10, 10), _rect.size - Vector2(20, 20)),
		shape.get("body", Color.GRAY), maxf(radius - 4.0, 2.0))
	if kind == "closing":
		# La pince : c'est elle qui fait lire « planche » plutôt que « panneau ».
		var clip := Rect2(Vector2(_rect.position.x + _rect.size.x * 0.5 - 52, _rect.position.y - 13),
			Vector2(104, 26))
		draw_rect(clip, Color("#b9bec6"))
		draw_rect(clip, shape.get("frame", Color.BLACK), false, 3.0)


func draw_rect_rounded(rect: Rect2, color: Color, radius: float) -> void:
	# Godot ne dessine pas de rectangle arrondi en immédiat : trois rectangles
	# et quatre disques suffisent, et restent nets à toute échelle.
	draw_rect(Rect2(rect.position + Vector2(radius, 0), rect.size - Vector2(radius * 2.0, 0)), color)
	draw_rect(Rect2(rect.position + Vector2(0, radius), Vector2(radius, rect.size.y - radius * 2.0)), color)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x - radius, radius), Vector2(radius, rect.size.y - radius * 2.0)), color)
	for corner in [Vector2(radius, radius), Vector2(rect.size.x - radius, radius),
			Vector2(radius, rect.size.y - radius), Vector2(rect.size.x - radius, rect.size.y - radius)]:
		draw_circle(rect.position + corner, radius, color)


# ── Ce qu'on voit au repos ───────────────────────────────────────────────
func _fill_rest() -> void:
	UIHelpers.clear_children(_body)
	var label := Label.new()
	label.text = {"shop": "ÉTAL", "closing": "CLORE", "committee": "COMITÉ D'INVESTISSEMENT"}.get(kind, "")
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("#f3e4e4") if kind == "committee" else UIHelpers.PANEL_FG)
	UIHelpers.apply_mono(label, 13, true)
	label.position = Vector2(14, 14)
	_body.add_child(label)

	if kind == "committee":
		var sub := Label.new()
		sub.text = "Trimestre %d franchi · 💥 %d à engager" % [
			SprintState.quarter_index, SprintState.impact_wallet]
		sub.position = Vector2(14, 44)
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.custom_minimum_size = Vector2(220, 0)
		sub.size = Vector2(220, 90)
		sub.add_theme_font_size_override("font_size", 12)
		sub.add_theme_color_override("font_color", Color("#f3e4e4", 0.82))
		_body.add_child(sub)


# ── Ce qu'on voit ouvert ─────────────────────────────────────────────────
func _fill_open() -> void:
	UIHelpers.clear_children(_body)

	var bar := Button.new()
	bar.text = "Reposer"
	bar.flat = true
	bar.position = Vector2(_body.size.x - 150, 6)
	bar.custom_minimum_size = Vector2(140, 30)
	bar.add_theme_font_size_override("font_size", 12)
	bar.add_theme_color_override("font_color", UIHelpers.PANEL_ACCENT)
	bar.pressed.connect(collapse)
	_body.add_child(bar)

	var host := Control.new()
	host.position = Vector2(0, 40)
	host.size = _body.size - Vector2(0, 40)
	host.clip_contents = true
	_body.add_child(host)

	if kind == "closing":
		host.add_child(_closing_sheet(host.size))
		return

	var path := String(HOSTED.get(kind, ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	UIHelpers.hosted_in_desk = true
	var screen: Control = load(path).instantiate()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(screen)
	UIHelpers.hosted_in_desk = false
	_rewire(screen, "Margin/VBox/TopBar/BackButton")
	_rewire(screen, "Margin/VBox/BottomBar/NextButton")
	_rewire(screen, "Margin/VBox/BottomBar/ContinueButton")


func _rewire(screen: Control, path: String) -> void:
	var button: Node = screen.get_node_or_null(NodePath(path))
	if button == null or not (button is BaseButton):
		return
	for connection in button.pressed.get_connections():
		button.pressed.disconnect(connection.get("callable"))
	button.pressed.connect(collapse)


## La feuille de clôture. Elle dit **ce qu'on emporte**, y compris ce qu'on a
## choisi d'ignorer : un événement non traité se paie, et le joueur doit le
## voir avant de signer, pas le découvrir à la Résolution.
func _closing_sheet(area: Vector2) -> Control:
	var sheet := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fffdf6")
	style.border_color = Color("#d8d2c2")
	style.set_border_width_all(1)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	sheet.add_theme_stylebox_override("panel", style)
	sheet.position = Vector2(16, 8)
	sheet.size = area - Vector2(32, 24)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "CLÔTURE DU SPRINT %d" % SprintState.sprint_number
	title.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	UIHelpers.apply_mono(title, 11, true)
	box.add_child(title)

	for line in SprintState.get_closing_summary():
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = String(line.get("label", ""))
		label.add_theme_font_size_override("font_size", 13)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var value := Label.new()
		value.text = String(line.get("value", ""))
		value.add_theme_font_size_override("font_size", 13)
		if bool(line.get("warn", false)):
			value.add_theme_color_override("font_color", UIHelpers.COLOR_DANGER)
		UIHelpers.apply_mono(value, 13, true)
		row.add_child(value)
		box.add_child(row)

	var note := Label.new()
	note.text = "Après signature, plus rien n'est modifiable."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	box.add_child(note)

	var sign := Button.new()
	sign.name = "SignButton"
	sign.text = "SIGNER ET LANCER"
	sign.custom_minimum_size = Vector2(0, 44)
	UIHelpers.style_primary_button(sign)
	sign.pressed.connect(_on_sign_pressed)
	box.add_child(sign)

	sheet.add_child(box)
	return sheet


func _on_sign_pressed() -> void:
	SprintState.resolve_unanswered_events()
	collapse()
	get_tree().change_scene_to_file("res://scenes/screens/resolution_screen.tscn")
