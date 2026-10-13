extends SceneTree
## Planche de présentation rendue par Godot, avec les mêmes GLB que le jeu.
## SHOT_DIR=/chemin godot --path game -s res://tests/atelier_gallery.gd

const ITEMS := [
	["task_lamp", "01 / LAMPE ARTICULÉE", Vector3(-0.72, 0, -0.38)],
	["rubber_plant", "02 / PLANTE EN TERRE CUITE", Vector3(0, 0, -0.38)],
	["headphone_stand", "03 / CASQUE SUR SUPPORT", Vector3(0.72, 0, -0.38)],
	["pencil_cup", "04 / PAPETERIE", Vector3(-0.72, 0, 0.4)],
	["field_notebooks", "05 / CARNETS", Vector3(0, 0, 0.4)],
	["valet_tray", "06 / VIDE-POCHE", Vector3(0.72, 0, 0.4)],
]


func _initialize() -> void:
	_build.call_deferred()


func _build() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#d4d7d0")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#e8efe9")
	environment.ambient_light_energy = 0.30
	world.environment = environment
	stage.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-52, -28, 0)
	light.light_energy = 0.45
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 7.0
	stage.add_child(light)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.7
	camera.look_at_from_position(Vector3(0.4, 2.5, 3.5), Vector3(0, 0.12, 0), Vector3.UP)
	camera.current = true
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(200, 0.05, 200)
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = floor_mesh
	floor_node.position.y = -0.057
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color("#c4ccc4")
	paper.roughness = 1.0
	floor_node.material_override = paper
	stage.add_child(floor_node)
	for item in ITEMS:
		var model: Node3D = load("res://assets/atelier/%s.glb" % item[0]).instantiate()
		model.position = item[2]
		stage.add_child(model)
		var base := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.29
		mesh.bottom_radius = 0.29
		mesh.height = 0.025
		mesh.radial_segments = 64
		base.mesh = mesh
		base.position = item[2] - Vector3(0, 0.015, 0)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#e9e3d5")
		material.roughness = 0.9
		base.material_override = material
		stage.add_child(base)
		var label := Label3D.new()
		label.text = item[1]
		label.font_size = 36
		label.pixel_size = 0.0006
		label.modulate = Color("#2f4944")
		label.outline_size = 0
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = item[2] + Vector3(0, 0.02, 0.33)
		stage.add_child(label)
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var output := OS.get_environment("SHOT_DIR").path_join("atelier_collection.png")
	var result := root.get_texture().get_image().save_png(output)
	print("ATELIER GALLERY: ", output, " — ", error_string(result))
	quit(0 if result == OK else 1)
