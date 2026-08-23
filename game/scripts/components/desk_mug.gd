extends Node3D
## ⚡ La tasse — l'Énergie du CPO, posée sur le plateau (#54 §2, passée en
## volume par #59).
##
## L'Énergie échappe à la règle « trois valeurs et rien d'autre », et c'est
## voulu : c'est la seule ressource qui se dépense au clic, sprint après
## sprint. Une valeur qu'on dépense doit être lisible au moment où on la
## dépense — mais elle n'a rien à faire dans une zone de HUD : elle est un
## objet du monde, alors elle est une tasse.
##
## En volume, le café **descend vraiment** dans la tasse : ce n'est plus un
## rectangle dessiné par-dessus un aplat, c'est un cylindre qui perd de la
## hauteur et se retrouve au fond. Le chiffre, lui, reste en 2D — il se lit,
## donc il ne prend pas la perspective (`desk_screen` l'ancre sous la tasse).

signal hover_changed(entered: bool)

## La pièce, pour convertir l'épaisseur du trait de contour en unités monde.
var room: DeskRoom = null

const RADIUS_TOP := 0.049
const RADIUS_BOTTOM := 0.042
const HEIGHT := 0.108
const PORCELAIN := Color("#fbfaf6")
const COFFEE := Color("#5b3a22")

var _coffee: MeshInstance3D = null
var _level := -1.0


func _ready() -> void:
	build.call_deferred()


func build() -> void:
	if _coffee != null:
		return

	var body := MeshInstance3D.new()
	body.name = "Body"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = RADIUS_TOP
	cylinder.bottom_radius = RADIUS_BOTTOM
	cylinder.height = HEIGHT
	# Sans ouvrir le haut et sans dessiner l'intérieur, la tasse est un plot :
	# le café ne se voit pas, et c'est pourtant lui qui porte l'Énergie. La
	# caméra plonge de 22°, elle voit dedans — encore faut-il qu'il y ait un
	# dedans.
	cylinder.cap_top = false
	body.mesh = cylinder
	body.position = Vector3(0, HEIGHT * 0.5, 0)
	var porcelain := DeskRoom.toon_material(PORCELAIN)
	porcelain.cull_mode = BaseMaterial3D.CULL_DISABLED
	body.material_override = porcelain
	add_child(body)
	if room != null:
		room.outline_at(body, global_position, 2.6)

	var handle := MeshInstance3D.new()
	handle.name = "Handle"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.018
	torus.outer_radius = 0.030
	handle.mesh = torus
	handle.position = Vector3(RADIUS_TOP + 0.012, HEIGHT * 0.55, 0)
	handle.rotation_degrees = Vector3(0, 90, 0)
	handle.material_override = DeskRoom.toon_material(PORCELAIN)
	add_child(handle)
	if room != null:
		room.outline_at(handle, global_position, 2.6)

	_coffee = MeshInstance3D.new()
	_coffee.name = "Coffee"
	var liquid := CylinderMesh.new()
	liquid.top_radius = RADIUS_TOP - 0.006
	liquid.bottom_radius = RADIUS_BOTTOM - 0.006
	liquid.height = 1.0
	_coffee.mesh = liquid
	# Pas de contour sur le café : on anime sa `scale` pour le faire descendre,
	# et une coque inversée s'étirerait avec lui.
	_coffee.material_override = DeskRoom.toon_material(COFFEE)
	add_child(_coffee)

	var area := Area3D.new()
	area.name = "Area"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(RADIUS_TOP * 2.4, HEIGHT, RADIUS_TOP * 2.4)
	shape.shape = box
	shape.position = Vector3(0, HEIGHT * 0.5, 0)
	area.add_child(shape)
	# Un objet 3D n'a pas de survol gratuit : sans ces deux signaux, la tasse
	# est un décor muet là où sa version 2D avait un `tooltip_text`.
	area.mouse_entered.connect(func(): hover_changed.emit(true))
	area.mouse_exited.connect(func(): hover_changed.emit(false))
	add_child(area)

	refresh()


## Le niveau se relit à chaque `refresh()` du bureau — et aussi à chaque
## trame, parce que l'Énergie se dépense **pendant** qu'on regarde la tasse
## (un « Plonger » depuis la Roadmap hébergée dans la dalle).
func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	if _coffee == null:
		return
	var maximum := maxf(float(SprintState.get_energy_max()), 1.0)
	var level := clampf(float(SprintState.energy) / maximum, 0.0, 1.0)
	if is_equal_approx(level, _level):
		return
	_level = level
	var depth := maxf(level * (HEIGHT - 0.020), 0.001)
	_coffee.scale = Vector3(1, depth, 1)
	_coffee.position = Vector3(0, 0.008 + depth * 0.5, 0)
	_coffee.visible = level > 0.0
