extends Node3D
## Le bureau, en volume — la couche décor du hub (issue #54, Lot A).
##
## Remplace le décor 2D de `desk_screen.gd`. Le spike l'a tranché : la
## profondeur vient gratuitement d'une caméra, alors que la simuler en 2D
## demandait un dégradé de plateau, des ombres décalées et une vignette — trois
## ruses pour approcher ce qu'un `Camera3D` donne sans rien.
##
## **Le partage est net, et c'est lui qui rend le lot tenable :**
##
##  · **En 3D** — la pièce, la table, le portable, les objets posés. Tout ce
##    qui a un volume et reçoit de la lumière.
##  · **En 2D** — les zones de valeurs, les alertes, les papiers du mur, et
##    **tout le contenu des applications**. Une interface qu'on lit ne gagne
##    rien à être en perspective, elle y perd en lisibilité.
##
## La dalle du portable est un `SubViewport` texturé sur un quad : le poste de
## travail et les écrans de phase existants s'y affichent **sans être
## réécrits**, et prennent la perspective de la pièce. C'est ce qui permet de
## changer de dimension sans toucher au gameplay.

const SCREEN_PIXELS := Vector2i(1328, 830)

const WALL := Color("#e8eae5")
const PAPER := Color("#fbfaf6")
const ALU := Color("#ccd2db")

## Caméra fixe, légèrement plongeante : assez pour lire le plateau, pas assez
## pour que la dalle devienne un losange illisible. Le spike a montré que c'est
## tout l'équilibre du parti pris.
const CAMERA_AT := Vector3(0.0, 1.50, 2.30)
const CAMERA_LOOK := Vector3(0.0, 1.00, -0.30)

var screen_viewport: SubViewport = null


## Godot rejette `add_child()` sur un nœud encore en train d'installer ses
## enfants — **sans lever d'erreur GDScript**. Le spike a donné trois écrans
## unis avant qu'on le comprenne : on construit donc une fois entré dans
## l'arbre, jamais pendant.
func _ready() -> void:
	build.call_deferred()


func build() -> void:
	_build_environment()
	_build_room()
	_build_laptop()
	_build_props()
	_build_camera()


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = WALL
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e2e6ec")
	env.ambient_light_energy = 0.32
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, -38, 0)
	# Une scène claire a besoin de MOINS de lumière qu'une scène sombre : la
	# première passe du spike, à 1,15, était intégralement brûlée.
	sun.light_energy = 0.62
	sun.shadow_enabled = true
	add_child(sun)


func _build_room() -> void:
	_box(Vector3(0, 1.6, -1.25), Vector3(7.0, 3.2, 0.08), WALL)
	_box(Vector3(0, -0.02, 0), Vector3(7.0, 0.04, 4.0), Color("#cfc7ba"))
	_box(Vector3(0, 0.74, 0.05), Vector3(3.3, 0.06, 1.30), Color("#c6ab88"))
	_box(Vector3(0, 0.70, -0.58), Vector3(3.3, 0.03, 0.06), Color("#8d7358"))
	for x in [-1.52, 1.52]:
		_box(Vector3(x, 0.36, 0.05), Vector3(0.08, 0.72, 1.18), Color("#8d7358"))


func _build_laptop() -> void:
	_box(Vector3(0, 0.785, 0.24), Vector3(0.94, 0.02, 0.62), ALU)
	_box(Vector3(0, 0.792, 0.32), Vector3(0.64, 0.006, 0.24), Color("#aab2bd"))

	var lid := Node3D.new()
	lid.name = "Lid"
	lid.position = Vector3(0, 0.795, -0.07)
	lid.rotation_degrees = Vector3(-13, 0, 0)
	add_child(lid)

	var shell := MeshInstance3D.new()
	var shell_mesh := BoxMesh.new()
	shell_mesh.size = Vector3(0.94, 0.61, 0.014)
	shell.mesh = shell_mesh
	shell.position = Vector3(0, 0.305, 0)
	shell.material_override = _material(ALU)
	lid.add_child(shell)

	screen_viewport = SubViewport.new()
	screen_viewport.name = "ScreenViewport"
	screen_viewport.size = SCREEN_PIXELS
	screen_viewport.transparent_bg = false
	screen_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	lid.add_child(screen_viewport)

	var dalle := MeshInstance3D.new()
	dalle.name = "Dalle"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.88, 0.55)
	dalle.mesh = quad
	dalle.position = Vector3(0, 0.305, 0.008)
	var screen_material := StandardMaterial3D.new()
	screen_material.albedo_texture = screen_viewport.get_texture()
	# Un écran n'est pas une surface qui reçoit la lumière, c'est une surface
	# qui en émet : sans ça, la dalle s'assombrit avec la pièce.
	screen_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dalle.material_override = screen_material
	lid.add_child(dalle)


## Les objets posés. En volume, ils projettent une ombre et ont une tranche —
## c'est ce que les ombres décalées de la version 2D essayaient d'imiter.
func _build_props() -> void:
	var mug := MeshInstance3D.new()
	mug.name = "Mug"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.047
	cylinder.bottom_radius = 0.040
	cylinder.height = 0.105
	mug.mesh = cylinder
	mug.position = Vector3(-0.86, 0.823, 0.30)
	mug.material_override = _material(PAPER)
	add_child(mug)

	var folder := _box(Vector3(0.92, 0.79, 0.34), Vector3(0.46, 0.035, 0.31), Color("#7b3f3f"))
	folder.name = "CommitteeFolder"


func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.fov = 42.0
	add_child(camera)
	# `look_at` et `current` n'ont d'effet qu'une fois le nœud dans l'arbre.
	camera.look_at_from_position(CAMERA_AT, CAMERA_LOOK, Vector3.UP)
	camera.current = true


## Le parapheur n'existe pas hors fin de trimestre : en volume comme en 2D,
## c'est un objet absent, pas un objet grisé.
func refresh() -> void:
	var folder := get_node_or_null("CommitteeFolder")
	if folder != null:
		folder.visible = SprintState.committee_pending


func _box(at: Vector3, box_size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	node.mesh = mesh
	node.position = at
	node.material_override = _material(color)
	add_child(node)
	return node


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	material.metallic = 0.0
	return material
