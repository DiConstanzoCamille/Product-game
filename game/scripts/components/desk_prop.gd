extends Node3D
## Un accessoire qui entre dans le cadre (#54 §3, passé en volume par #59).
##
## Aucune mécanique n'ouvre un écran de plus : elle fait entrer un objet, et
## **la forme de l'objet dit ce qu'est la mécanique**.
##
##  · 🛒 `shop` — une tablette dressée **à gauche** du plateau. Ça se feuillette
##    et ça se repousse : l'étal du sprint est ouvert en permanence.
##  · 🏁 `closing` — une planche à pince, **à droite**. On signe debout, une
##    fois : c'est le seul point de non-retour du sprint.
##  · 🏛 `committee` — un parapheur, **déposé sur la table** un sprint sur
##    trois. Il n'arrive pas du bord : le board pose le dossier du trimestre
##    devant vous, il ne vous le tend pas.
##
## Le sens de lecture n'est pas un détail de mise en page : on achète avant de
## clore, et l'œil va de gauche à droite. La première version plaçait l'étal à
## droite et la clôture à gauche, ce qui demandait de traverser l'écran à
## rebours pour finir son sprint.
##
## En volume, l'objet au repos a une tranche et une ombre — ce que les ombres
## décalées de la version 2D essayaient d'imiter. Ouvert, il **vient se
## présenter de face** : sa dalle est un `SubViewport` qui héberge l'écran de
## phase existant, sans que celui-ci soit réécrit.
##
## L'inclinaison appartient à l'animation d'entrée, **jamais à l'état posé** :
## un panneau qui reste de biais donne du texte de biais, et c'est l'échec du
## critère de recette n°1. On tourne pendant les 0,42 s du `Tween`, on se cale
## droit à l'arrivée.

signal state_changed
signal interacted

const SLIDE_SECONDS := 0.42
## Assez près pour occulter le portable — un dossier qu'on ouvre passe devant
## l'écran, il ne s'affiche pas à côté.
const PRESENT_DISTANCE := 0.95

## Géométrie de repos par nature, en unités monde, et taille de présentation en
## **pixels** (la taille du quad s'en déduit : cf. `DeskRoom`).
const SHAPES := {
	"shop": {
		"rest_position": Vector3(-0.98, 0.98, -0.38),
		"rest_rotation": Vector3(-6, 19, 0),
		"rest_size": Vector3(0.27, 0.38, 0.020),
		"body": Color("#2f3a4d"), "frame": Color("#57657d"),
		"pixels": Vector2i(1120, 690),
		"entry_rotation": Vector3(0, 26, -4),
		# Au-dessus, et pas dessous : la tablette est presque noire, et sous
		# elle il y a la tasse.
		"hint": "Boutique", "hint_offset": Vector3(0, 0.27, 0.08),
	},
	"closing": {
		"rest_position": Vector3(0.78, 0.79, -0.30),
		"rest_rotation": Vector3(-78, -8, 0),
		"rest_size": Vector3(0.23, 0.30, 0.016),
		"body": Color("#f3ead2"), "frame": Color("#7d5735"),
		"pixels": Vector2i(760, 640),
		"entry_rotation": Vector3(0, -22, 5),
		"hint": "Fin de sprint", "hint_offset": Vector3(0, 0.05, 0.24),
	},
	"committee": {
		"rest_position": Vector3(0.56, 0.79, -0.28),
		"rest_rotation": Vector3(-84, 7, 0),
		"rest_size": Vector3(0.36, 0.26, 0.028),
		"body": Color("#a8434a"), "frame": Color("#6d262c"),
		"pixels": Vector2i(1120, 690),
		"entry_rotation": Vector3(6, -14, 3),
		"hint": "Comité du trimestre", "hint_offset": Vector3(0, 0.05, 0.24),
	},
}

const HOSTED := {
	"shop": "res://scenes/screens/investments_screen.tscn",
	"committee": "res://scenes/screens/committee_screen.tscn",
}

@export var kind: String = "shop"

var room: DeskRoom = null

var _cover: MeshInstance3D = null
var _panel: MeshInstance3D = null
var _panel_pivot: Node3D = null
var _viewport: SubViewport = null
var _body: Control = null
var _open := false
var _tween: Tween = null


func _ready() -> void:
	build.call_deferred()


func build() -> void:
	if _cover != null:
		return
	var shape := _shape()
	position = shape.get("rest_position", Vector3.ZERO)
	rotation_degrees = shape.get("rest_rotation", Vector3.ZERO)

	_cover = MeshInstance3D.new()
	_cover.name = "Cover"
	var mesh := BoxMesh.new()
	mesh.size = shape.get("rest_size", Vector3(0.3, 0.4, 0.02))
	_cover.mesh = mesh
	_cover.material_override = DeskRoom.toon_material(shape.get("body", Color.GRAY))
	add_child(_cover)
	if room != null:
		room.outline_at(_cover, global_position)

	var trim := MeshInstance3D.new()
	trim.name = "Trim"
	var trim_mesh := BoxMesh.new()
	var rest_size: Vector3 = shape.get("rest_size", Vector3(0.3, 0.4, 0.02))
	trim_mesh.size = Vector3(rest_size.x * 1.06, rest_size.y * 1.06, rest_size.z * 0.6)
	trim.mesh = trim_mesh
	trim.position = Vector3(0, 0, -rest_size.z * 0.4)
	trim.material_override = DeskRoom.toon_material(shape.get("frame", Color.BLACK))
	add_child(trim)

	var area := Area3D.new()
	area.name = "Area"
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = rest_size * 1.2
	collision.shape = box
	area.add_child(collision)
	area.input_event.connect(_on_cover_input)
	add_child(area)

	_build_panel()
	refresh()


## Le panneau de présentation vit **hors de l'accessoire** : il doit arriver de
## face devant la caméra, or l'objet au repos est couché sur la table. Le
## laisser enfant de l'accessoire lui ferait hériter d'une rotation de 82°.
func _build_panel() -> void:
	var shape := _shape()
	var pixels: Vector2i = shape.get("pixels", Vector2i(1000, 640))

	_panel_pivot = Node3D.new()
	_panel_pivot.name = "PanelPivot"
	_panel_pivot.top_level = true
	_panel_pivot.visible = false
	add_child(_panel_pivot)

	_viewport = SubViewport.new()
	_viewport.name = "PropViewport"
	_viewport.size = pixels
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.handle_input_locally = true
	_viewport.gui_embed_subwindows = true
	_panel_pivot.add_child(_viewport)

	_panel = MeshInstance3D.new()
	_panel.name = "Panel"
	var quad := QuadMesh.new()
	quad.size = Vector2(pixels) / _pixels_per_unit()
	_panel.mesh = quad
	var material := StandardMaterial3D.new()
	material.albedo_texture = _viewport.get_texture()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_panel.material_override = material
	_panel_pivot.add_child(_panel)

	var frame := MeshInstance3D.new()
	frame.name = "PanelFrame"
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(quad.size.x + 0.022, quad.size.y + 0.022, 0.012)
	frame.mesh = frame_mesh
	frame.position = Vector3(0, 0, -0.008)
	frame.material_override = DeskRoom.toon_material(shape.get("frame", Color.BLACK))
	_panel_pivot.add_child(frame)
	# Le pivot est animé en `scale` à l'ouverture : le trait grossit donc avec
	# le cadre pendant l'entrée, et se cale juste à l'arrivée. C'est le seul
	# endroit du lot où un contour est posé sur un nœud animé en échelle.
	if room != null:
		var placement: Dictionary = room.presentation_placement(Vector2i.ONE, PRESENT_DISTANCE)
		room.outline_at(frame, placement["position"])

	var area := Area3D.new()
	area.name = "PanelArea"
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(quad.size.x, quad.size.y, 0.01)
	collision.shape = box
	collision.position = Vector3(0, 0, 0.004)
	area.add_child(collision)
	area.input_event.connect(_on_panel_input)
	_panel_pivot.add_child(area)


func _pixels_per_unit() -> float:
	if room == null:
		return 1200.0
	var placement: Dictionary = room.presentation_placement(Vector2i.ONE, PRESENT_DISTANCE)
	return maxf(room.design_pixels_per_unit_at(placement["position"]), 1.0)


func _shape() -> Dictionary:
	return SHAPES.get(kind, SHAPES["shop"])


func hint_text() -> String:
	return String(_shape().get("hint", ""))


## Le point du monde auquel accrocher l'étiquette 2D de l'accessoire — **jamais
## dessus** : la tablette est presque noire, et un libellé posé dessus s'y
## perdait. Le décalage est déclaré par nature parce que le bon côté dépend de
## la pose : sous la tablette dressée, devant les objets couchés à plat, qui
## sinon poussent leur étiquette hors du cadre par le bas. Le texte reste de
## face et net, seul l'objet est en perspective.
func hint_anchor() -> Vector3:
	return global_position + _shape().get("hint_offset", Vector3(0, 0.05, 0.2))


## Le parapheur du Comité **n'existe pas** hors fin de trimestre : ce n'est pas
## un objet grisé, c'est un objet absent. C'est ce qui fait qu'un sprint sur
## trois ne ressemble pas aux deux autres.
func refresh() -> void:
	if kind == "committee":
		var available := SprintState.committee_pending
		visible = available
		if _panel_pivot != null:
			_panel_pivot.visible = available and _open
		if not available and _open:
			collapse()


func is_open() -> bool:
	return _open


func _on_cover_input(_camera: Node, event: InputEvent, _at: Vector3, _normal: Vector3, _index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interacted.emit()
		expand()


func _on_panel_input(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3, _index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interacted.emit()
	DeskRoom.route_to_viewport(_panel, _viewport, event, event_position)


# ── Entrer, sortir ───────────────────────────────────────────────────────
func expand() -> void:
	if _open or room == null:
		return
	_open = true
	var placement: Dictionary = room.presentation_placement(
		Vector2i(_shape().get("pixels", Vector2i(1000, 640))), PRESENT_DISTANCE)

	_cover.visible = false
	get_node("Trim").visible = false
	_panel_pivot.visible = true
	# L'objet part de sa place sur la table, de biais, et se redresse : c'est
	# ce redressement qu'on lit comme « un objet entre », là où un panneau qui
	# s'affiche n'a aucune matière.
	_panel_pivot.global_position = global_position
	_panel_pivot.global_basis = placement["basis"] * Basis.from_euler(
		Vector3(deg_to_rad(_shape().get("entry_rotation", Vector3.ZERO).x),
			deg_to_rad(_shape().get("entry_rotation", Vector3.ZERO).y),
			deg_to_rad(_shape().get("entry_rotation", Vector3.ZERO).z)))
	_panel_pivot.scale = Vector3.ONE * 0.35

	_fill_open()
	_slide_to(placement["position"], placement["basis"], Vector3.ONE)
	# Le bureau doit rafraîchir ses étiquettes 2D : celle de cet accessoire
	# nomme un objet qui vient de quitter la table.
	state_changed.emit()


func collapse() -> void:
	if not _open:
		return
	# Le dossier a été ouvert : il quitte la table. C'est ce qui fait qu'un
	# sprint sur trois ne ressemble pas aux deux autres — pas un compteur.
	if kind == "committee":
		SprintState.committee_pending = false
	_open = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	UIHelpers.clear_children(_viewport)
	_panel_pivot.visible = false
	_cover.visible = true
	get_node("Trim").visible = true
	refresh()
	state_changed.emit()


func _slide_to(target_position: Vector3, target_basis: Basis, target_scale: Vector3) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	# L'accessoire dépasse sa position puis se cale : un objet qu'on pousse a
	# de l'inertie, un panneau qui s'affiche n'en a pas. C'est tout l'écart.
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_panel_pivot, "global_position", target_position, SLIDE_SECONDS)
	_tween.tween_property(_panel_pivot, "quaternion", target_basis.get_rotation_quaternion(), SLIDE_SECONDS)
	_tween.tween_property(_panel_pivot, "scale", target_scale, SLIDE_SECONDS)


# ── Ce qu'on voit ouvert ─────────────────────────────────────────────────
func _fill_open() -> void:
	UIHelpers.clear_children(_viewport)
	var pixels := Vector2(_viewport.size)

	_body = Control.new()
	_body.name = "Body"
	_body.size = pixels
	_viewport.add_child(_body)

	var background := ColorRect.new()
	background.color = UIHelpers.COLOR_SCREEN_BG
	background.size = pixels
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(background)

	var host := Control.new()
	host.name = "Host"
	host.position = Vector2.ZERO
	host.size = pixels
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
	if screen.has_method("configure_for_host"):
		screen.call("configure_for_host", {"kind": kind, "size": host.size})
	if screen.has_signal("desk_state_changed"):
		screen.connect("desk_state_changed", _on_hosted_state_changed)


func hosted_screen() -> Control:
	if _body == null:
		return null
	var host := _body.get_node_or_null("Host")
	if host == null or host.get_child_count() == 0:
		return null
	return host.get_child(0) as Control

func _on_hosted_state_changed() -> void:
	state_changed.emit()


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


