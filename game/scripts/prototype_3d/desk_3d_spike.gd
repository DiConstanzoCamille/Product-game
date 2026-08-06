extends Node3D
## SPIKE DE PROFONDEUR — pas du code de production, aucun écran du jeu ne
## l'utilise. Même statut que `prototype_2d/market_screen_proto.gd`.
##
## Question posée : le bureau gagne-t-il assez à être une vraie scène 3D pour
## qu'on remplace la couche décor du Lot A ? Tout ce que la version 2D fait
## pour simuler la profondeur — dégradé sur le plateau, ombres décalées,
## vignette — sont des ruses qui approchent ce qu'une caméra donne gratuitement.
##
## Ce que le spike doit prouver ou infirmer, et rien d'autre :
##  1. la perspective et la lumière valent mieux que les ruses 2D ;
##  2. **la dalle du portable peut être un `SubViewport` texturé sur un quad** —
##     c'est le point décisif : les phases existantes s'afficheraient alors en
##     perspective, avec la lumière de la pièce dessus, ce qu'aucune ruse 2D ne
##     sait faire ;
##  3. tout ça tient en `gl_compatibility`, le renderer du projet, sans imposer
##     un changement de cible d'export.
##
## Volontairement sans assets : primitives, palette courte, une lumière. Si la
## profondeur ne se voit pas ainsi, elle ne viendra pas d'un modeleur.

const WALL := Color("#e6e8e3")
const WOOD := Color("#b99e7e")
const WOOD_DARK := Color("#8d7358")
const PAPER := Color("#fbfaf6")
const ALU := Color("#c8ced8")
const INK := Color("#20252e")

## La caméra est fixe et légèrement plongeante : assez pour lire le plateau,
## pas assez pour que le portable devienne un losange illisible. C'est tout
## l'équilibre du parti pris.
const CAMERA_AT := Vector3(0.0, 1.52, 2.35)
const CAMERA_LOOK := Vector3(0.0, 1.00, -0.30)

var screen_viewport: SubViewport = null


## Construire depuis `_ready()` échouait en silence utile : Godot refuse
## `add_child()` sur un nœud « busy setting up children », et **chaque appel
## était rejeté** — la pièce n'existait tout simplement pas, d'où un écran gris
## sans la moindre erreur de script. On construit donc une fois entré dans
## l'arbre, jamais pendant.
func _ready() -> void:
	build.call_deferred()


func build() -> void:
	_build_environment()
	_build_room()
	_build_desk()
	_build_laptop()
	_build_props()
	_build_camera()


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = WALL
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#dfe3e8")
	env.ambient_light_energy = 0.32
	world.environment = env
	add_child(world)

	# Une seule source, rasante : c'est l'ombre portée qui fait la profondeur,
	# pas le nombre de lampes.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, -38, 0)
	# Première passe à 1,15 : tout était brûlé. Une scène claire a besoin de
	# MOINS de lumière qu'une scène sombre, pas plus — l'erreur classique.
	sun.light_energy = 0.62
	sun.shadow_enabled = true
	add_child(sun)


func _build_room() -> void:
	_box(Vector3(0, 1.6, -1.25), Vector3(6.0, 3.2, 0.08), WALL)      # mur du fond
	_box(Vector3(0, -0.02, 0), Vector3(6.0, 0.04, 4.0), Color("#cfc7ba"))  # sol


func _build_desk() -> void:
	_box(Vector3(0, 0.74, 0.05), Vector3(3.1, 0.06, 1.25), WOOD)     # plateau
	_box(Vector3(0, 0.70, -0.56), Vector3(3.1, 0.03, 0.06), WOOD_DARK)
	for x in [-1.42, 1.42]:
		_box(Vector3(x, 0.36, 0.05), Vector3(0.08, 0.72, 1.15), WOOD_DARK)


## Le point décisif du spike : la dalle n'est pas une texture peinte, c'est un
## `SubViewport` rendu en direct sur un quad. Tout ce qui vit dedans est de
## l'UI 2D ordinaire — donc les écrans de phase existants pourraient s'y
## afficher sans être réécrits, et prendraient la perspective et la lumière.
func _build_laptop() -> void:
	_box(Vector3(0, 0.785, 0.22), Vector3(0.92, 0.02, 0.62), ALU)     # base
	_box(Vector3(0, 0.79, 0.30), Vector3(0.62, 0.006, 0.24), Color("#aab2bd"))  # clavier

	var lid := Node3D.new()
	lid.position = Vector3(0, 0.795, -0.09)
	lid.rotation_degrees = Vector3(-14, 0, 0)
	add_child(lid)

	var shell := MeshInstance3D.new()
	var shell_mesh := BoxMesh.new()
	shell_mesh.size = Vector3(0.92, 0.60, 0.014)
	shell.mesh = shell_mesh
	shell.position = Vector3(0, 0.30, 0)
	shell.material_override = _material(ALU)
	lid.add_child(shell)

	screen_viewport = SubViewport.new()
	screen_viewport.size = Vector2i(1328, 860)
	screen_viewport.transparent_bg = false
	screen_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	lid.add_child(screen_viewport)
	screen_viewport.add_child(_screen_ui())

	var dalle := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.86, 0.55)
	dalle.mesh = quad
	dalle.position = Vector3(0, 0.30, 0.008)
	var screen_material := StandardMaterial3D.new()
	screen_material.albedo_texture = screen_viewport.get_texture()
	# La dalle s'éclaire elle-même : un écran n'est pas une surface qui reçoit
	# la lumière, c'est une surface qui en émet.
	screen_material.emission_enabled = true
	screen_material.emission_texture = screen_viewport.get_texture()
	screen_material.emission_energy_multiplier = 1.0
	screen_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dalle.material_override = screen_material
	lid.add_child(dalle)


## L'UI de la dalle : du Control 2D tout à fait ordinaire. C'est le but — si
## le spike convainc, ce nœud est remplacé par les écrans de phase existants.
func _screen_ui() -> Control:
	var root := ColorRect.new()
	root.color = Color("#141a26")
	root.size = Vector2(1328, 860)

	var title := Label.new()
	title.text = "POSTE DE TRAVAIL"
	title.position = Vector2(48, 38)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#8b97b0"))
	root.add_child(title)

	var apps := ["Boîte mail", "Roadmap", "Tableau de bord"]
	for i in apps.size():
		var tile := ColorRect.new()
		tile.color = Color(1, 1, 1, 0.07)
		tile.position = Vector2(76 + i * 400, 240)
		tile.size = Vector2(348, 380)
		root.add_child(tile)

		var label := Label.new()
		label.text = apps[i]
		label.position = Vector2(0, 300)
		label.size = Vector2(348, 40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 34)
		label.add_theme_color_override("font_color", Color("#e8ecf5"))
		tile.add_child(label)
	return root


func _build_props() -> void:
	# La tasse : un cylindre suffit à prouver qu'un objet posé projette une
	# ombre et occupe un volume — ce qu'aucun aplat ne fait.
	var mug := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.045
	cylinder.bottom_radius = 0.038
	cylinder.height = 0.10
	mug.mesh = cylinder
	mug.position = Vector3(-0.78, 0.82, 0.28)
	mug.material_override = _material(PAPER)
	add_child(mug)

	# Les papiers du mur : à peine épais, mais l'épaisseur suffit à les
	# décoller — c'est ce que l'ombre portée 2D essayait d'imiter.
	_box(Vector3(-1.02, 1.62, -1.19), Vector3(0.62, 0.44, 0.012), PAPER)
	_box(Vector3(-0.30, 1.66, -1.19), Vector3(0.40, 0.30, 0.012), Color("#fdf7e4"))
	_box(Vector3(1.06, 1.68, -1.19), Vector3(0.38, 0.34, 0.012), PAPER)

	# Le parapheur du Comité, posé à plat : en 3D il a une tranche, donc on
	# voit que c'est un dossier fermé et pas une carte imprimée sur la table.
	_box(Vector3(0.86, 0.79, 0.34), Vector3(0.44, 0.035, 0.30), Color("#7b3f3f"))


func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.fov = 42.0
	add_child(camera)
	# `current` et `look_at` n'ont d'effet qu'une fois le nœud dans l'arbre —
	# les poser avant donnait un écran gris, sans la moindre erreur.
	camera.look_at_from_position(CAMERA_AT, CAMERA_LOOK, Vector3.UP)
	camera.current = true


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
