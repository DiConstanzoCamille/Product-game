extends RefCounted
## Mobilier et accessoires du bureau : géométrie pure, sans interaction métier.
const Model := preload("res://scripts/components/laptop_model.gd")


static func flat_part(parent: Node3D, label: String, at: Vector3, size: Vector3, color: Color, radius: float = 0.02) -> MeshInstance3D:
	var mesh := Model.part(parent, label, at, Vector3(size.x, size.z, size.y), color, radius)
	mesh.rotation_degrees.x = -90
	return mesh


static func cylinder(parent: Node3D, label: String, at: Vector3, height: float, bottom: float, top: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.position = at
	var mesh := CylinderMesh.new()
	mesh.height = height
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.radial_segments = 32
	node.mesh = mesh
	node.material_override = DeskRoom.toon_material(color)
	parent.add_child(node)
	return node


static func build_room(parent: Node3D) -> void:
	var wood := Color("#927052")
	# Des surfaces mates à lumière continue évitent de brûler les grands aplats.
	var wall := Model.part(parent, "SageWall", Vector3(0, 2.25, -1.39), Vector3(9, 4.5, 0.08), Color("#82968a"))
	wall.material_override = matte(Color("#82968a"))
	for side in [-1.0, 1.0]:
		var side_wall := Model.part(parent, "SideWall", Vector3(side * 4.5, 2.25, 1.0), Vector3(0.08, 4.5, 4.85), Color("#82968a"))
		side_wall.material_override = matte(Color("#82968a"))
		side_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ceiling := flat_part(parent, "Ceiling", Vector3(0, 4.5, 1.0), Vector3(9, 0.08, 4.85), Color("#ccc6b3"))
	ceiling.material_override = matte(Color("#ccc6b3"))
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var floor := flat_part(parent, "Floor", Vector3(0, -0.02, 0), Vector3(9, 0.04, 7), Color("#847968"))
	floor.material_override = matte(Color("#847968"))
	Model.part(parent, "LowerWall", Vector3(0, 0.43, -1.335), Vector3(9, 0.86, 0.02), Color("#465e58"))
	Model.part(parent, "WallRail", Vector3(0, 0.87, -1.31), Vector3(9, 0.04, 0.06), Color("#596f62"))
	for i in range(19):
		Model.part(parent, "WallPanel", Vector3(-4.5 + i * 0.5, 0.43, -1.312), Vector3(0.013, 0.80, 0.018), Color("#536960"), 0.003)
	var top := flat_part(parent, "OakDesktop", Vector3(0, 0.72, 0.10), Vector3(3.6, 0.07, 1.6), wood, 0.075)
	top.material_override = matte(wood)
	for i in range(20):
		var z := -0.65 + float(i) * 0.075
		flat_part(parent, "WoodGrain", Vector3(sin(i * 3.1) * 0.04, 0.7552, z), Vector3(3.43, 0.0005, 0.0014), Color("#8a684d"), 0.0005)
	for x in [-1.62, 1.62]:
		flat_part(parent, "SteelLeg", Vector3(x, 0.35, 0.10), Vector3(0.045, 0.70, 1.35), Color("#34464a"))
	flat_part(parent, "DeskMat", Vector3(0, 0.758, 0.34), Vector3(1.64, 0.006, 0.87), Color("#354c53"), 0.055)
	flat_part(parent, "MatInset", Vector3(0, 0.762, 0.34), Vector3(1.60, 0.002, 0.83), Color("#405b61"), 0.045)
	# Fenêtre en retrait à gauche, rideaux et traverse : une source de jour lisible.
	Model.part(parent, "WindowFrame", Vector3(-2.55, 1.85, -1.30), Vector3(1.36, 1.68, 0.10), Color("#d4cbb7"), 0.035)
	var glass := Model.part(parent, "Daylight", Vector3(-2.55, 1.85, -1.239), Vector3(1.22, 1.54, 0.008), Color("#b3d4d3"))
	glass.material_override = matte(Color("#b3d4d3"))
	Model.part(parent, "WindowMullion", Vector3(-2.55, 1.85, -1.22), Vector3(0.035, 1.54, 0.025), Color("#dfd7c3"))
	Model.part(parent, "WindowTransom", Vector3(-2.55, 1.72, -1.22), Vector3(1.23, 0.035, 0.025), Color("#dfd7c3"))
	flat_part(parent, "WindowSill", Vector3(-2.55, 1.01, -1.18), Vector3(1.5, 0.055, 0.25), Color("#b8ac95"))
	for x in [-3.28, -1.82]:
		for fold in range(5):
			Model.part(parent, "Curtain", Vector3(x + fold * 0.032, 1.83, -1.16), Vector3(0.055, 1.79, 0.055), Color("#a29c84") if fold % 2 else Color("#b9b29c"))
	build_lamp(parent, Vector3(1.53, 0.755, -0.52))
	build_plant(parent, Vector3(-1.48, 0.755, -0.44))
	for index in range(3):
		var book := Node3D.new()
		book.name = "Book"
		book.position = Vector3(1.39, 0.775 + index * 0.041, 0.39)
		book.rotation_degrees.y = -8 + index * 8
		parent.add_child(book)
		var cover_color: Color = [Color("#3b6469"), Color("#a67855"), Color("#afbdad")][index]
		flat_part(book, "BackCover", Vector3(0, -0.018, 0), Vector3(0.32, 0.004, 0.24), cover_color)
		flat_part(book, "FrontCover", Vector3(0, 0.018, 0), Vector3(0.32, 0.004, 0.24), cover_color)
		flat_part(book, "Spine", Vector3(-0.155, 0, 0), Vector3(0.010, 0.036, 0.23), cover_color, 0.004)
		flat_part(book, "Pages", Vector3(0.003, 0, 0), Vector3(0.296, 0.029, 0.219), Color("#dfd8c4"), 0.004)
	var pen := cylinder(parent, "DeskPen", Vector3(0.94, 0.77, 0.53), 0.23, 0.006, 0.006, Color("#253d4b"))
	pen.rotation_degrees = Vector3(90, 0, 24)


static func matte(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


static func build_lamp(parent: Node3D, at: Vector3) -> void:
	var lamp := Node3D.new()
	lamp.name = "DeskLamp"
	lamp.position = at
	parent.add_child(lamp)
	cylinder(lamp, "Foot", Vector3(0, 0.018, 0), 0.036, 0.12, 0.11, Color("#3a5156"))
	cylinder(lamp, "Stem", Vector3(0, 0.28, 0), 0.53, 0.013, 0.013, Color("#ad9160"))
	var shade := cylinder(lamp, "Shade", Vector3(-0.055, 0.55, 0), 0.13, 0.14, 0.075, Color("#496963"))
	shade.rotation_degrees.z = -16
	cylinder(lamp, "Diffuser", Vector3(-0.055, 0.491, 0), 0.006, 0.13, 0.13, Color("#f1d8a0"))
	var glow := OmniLight3D.new()
	glow.position = Vector3(-0.055, 0.42, 0)
	glow.light_color = Color("#ffcf8a")
	glow.light_energy = 0.35
	glow.omni_range = 0.95
	lamp.add_child(glow)


static func build_plant(parent: Node3D, at: Vector3) -> void:
	var plant := Node3D.new()
	plant.name = "Plant"
	plant.position = at
	parent.add_child(plant)
	cylinder(plant, "Saucer", Vector3(0, 0.009, 0), 0.018, 0.105, 0.105, Color("#915e47"))
	cylinder(plant, "Terracotta", Vector3(0, 0.085, 0), 0.15, 0.07, 0.095, Color("#ad7657"))
	cylinder(plant, "Soil", Vector3(0, 0.16, 0), 0.006, 0.086, 0.086, Color("#403c30"))
	for index in range(9):
		var a := index * TAU / 9.0
		var leaf := MeshInstance3D.new()
		leaf.name = "Leaf"
		var mesh := SphereMesh.new()
		mesh.radius = 0.047
		mesh.height = 0.094
		mesh.radial_segments = 12
		mesh.rings = 8
		leaf.mesh = mesh
		leaf.position = Vector3(cos(a) * 0.07, 0.27 + (index % 3) * 0.045, sin(a) * 0.07)
		leaf.scale = Vector3(0.65, 2.7, 0.30)
		leaf.rotation = Vector3(sin(a) * 0.5, a, cos(a) * 0.65)
		leaf.material_override = DeskRoom.toon_material(Color("#446950") if index % 2 else Color("#65815a"))
		plant.add_child(leaf)


static func dress_prop(cover: MeshInstance3D, kind: String, size: Vector3) -> void:
	var front := size.z * 0.5
	if kind == "shop":
		Model.part(cover, "Glass", Vector3(0, 0, front + 0.001), Vector3(size.x - 0.020, size.y - 0.025, 0.002), Color("#172e3d"), 0.014)
		Model.part(cover, "Camera", Vector3(0, size.y * 0.5 - 0.008, front + 0.003), Vector3(0.018, 0.003, 0.002), Color("#637e89"), 0.001)
		for i in range(3):
			Model.part(cover, "AppTile", Vector3((i - 1) * 0.07, 0.035, front + 0.004), Vector3(0.052, 0.062, 0.003), [Color("#c59760"), Color("#4f7c83"), Color("#9eaa94")][i], 0.007)
		for i in range(3):
			Model.part(cover, "ScreenLine", Vector3(-0.015, -0.04 - i * 0.014, front + 0.004), Vector3(0.17 - i * 0.025, 0.003, 0.001), Color("#557782"), 0.001)
		Model.part(cover, "HomeBar", Vector3(0, -size.y * 0.5 + 0.015, front + 0.004), Vector3(0.065, 0.003, 0.002), Color("#a3b6b9"), 0.001)
	elif kind == "closing":
		Model.part(cover, "PaperStack", Vector3(0, -0.002, front + 0.003), Vector3(size.x - 0.022, size.y - 0.027, 0.006), Color("#f2ead6"), 0.004)
		Model.part(cover, "SteelClip", Vector3(0, size.y * 0.40, front + 0.012), Vector3(size.x * 0.48, 0.029, 0.014), Color("#8c9c9c"), 0.006)
		Model.part(cover, "ClipSlot", Vector3(0, size.y * 0.41, front + 0.020), Vector3(size.x * 0.32, 0.007, 0.002), Color("#465557"), 0.002)
		for i in range(6):
			Model.part(cover, "PrintedLine", Vector3(0, 0.05 - i * 0.024, front + 0.007), Vector3(size.x * 0.68, 0.0015, 0.001), Color("#bcb59e"), 0.0005)
	else:
		Model.part(cover, "Spine", Vector3(-size.x * 0.43, 0, front + 0.003), Vector3(0.029, size.y - 0.009, 0.007), Color("#593b3b"), 0.005)
		Model.part(cover, "BrassLabel", Vector3(0.018, 0.03, front + 0.005), Vector3(0.13, 0.06, 0.003), Color("#bd9b61"), 0.004)
		Model.part(cover, "LabelInset", Vector3(0.018, 0.03, front + 0.007), Vector3(0.113, 0.044, 0.002), Color("#eee1be"), 0.002)
		for y in [-1.0, 1.0]:
			Model.part(cover, "CoverStitch", Vector3(0, y * (size.y * 0.5 - 0.012), front + 0.001), Vector3(size.x - 0.035, 0.001, 0.001), Color("#bd9980"), 0.0003)


static func mug_body() -> ArrayMesh:
	# Profil fermé : pied, ventre, lèvre arrondie et vraie paroi intérieure.
	var profile := [Vector2(0.0, 0.005), Vector2(0.037, 0.005), Vector2(0.042, 0.012), Vector2(0.048, 0.094), Vector2(0.049, 0.105), Vector2(0.047, 0.110), Vector2(0.043, 0.110), Vector2(0.042, 0.104), Vector2(0.036, 0.016), Vector2(0.0, 0.016)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(profile.size() - 1):
		for i in range(48):
			var a := i * TAU / 48.0
			var b := (i + 1) * TAU / 48.0
			var p: Vector2 = profile[row]
			var q: Vector2 = profile[row + 1]
			var v0 := Vector3(cos(a) * p.x, p.y, sin(a) * p.x)
			var v1 := Vector3(cos(b) * p.x, p.y, sin(b) * p.x)
			var v2 := Vector3(cos(b) * q.x, q.y, sin(b) * q.x)
			var v3 := Vector3(cos(a) * q.x, q.y, sin(a) * q.x)
			Model.triangle(surface, v0, v1, v2)
			Model.triangle(surface, v0, v2, v3)
	surface.generate_normals()
	surface.index()
	return surface.commit()
