extends RefCounted
## Asset procédural du portable. Les dimensions sont artistiques, sans règle de jeu.
## Le plan XY porte la silhouette ; Z porte l'épaisseur et les chanfreins.

static func part(parent: Node3D, label: String, at: Vector3, size: Vector3, color: Color, radius: float = 0.018) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.position = at
	node.mesh = rounded_mesh(size, radius)
	node.material_override = DeskRoom.toon_material(color)
	parent.add_child(node)
	return node


static func rounded_mesh(size: Vector3, radius: float) -> ArrayMesh:
	var r := minf(radius, minf(size.x, size.y) * 0.45)
	var bevel := minf(size.z * 0.22, r * 0.4)
	var rings: Array[PackedVector3Array] = []
	for layer in range(4):
		var inset := bevel if layer == 0 or layer == 3 else 0.0
		var z: float = [-size.z * 0.5, -size.z * 0.5 + bevel, size.z * 0.5 - bevel, size.z * 0.5][layer]
		var ring := PackedVector3Array()
		for corner in range(4):
			var angle := float(corner) * PI * 0.5
			var center := Vector2(1.0 if corner == 0 or corner == 3 else -1.0, 1.0 if corner < 2 else -1.0) * (Vector2(size.x, size.y) * 0.5 - Vector2.ONE * r)
			for step in range(7):
				var a := angle + float(step) / 6.0 * PI * 0.5
				var p := center + Vector2(cos(a), sin(a)) * (r - inset)
				ring.append(Vector3(p.x, p.y, z))
		rings.append(ring)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Les grandes faces restent planes ; lisser jusqu'au chanfrein y imprime
	# les triangles du maillage sous une lumière oblique.
	surface.set_smooth_group(-1)
	for layer in range(3):
		for i in range(rings[layer].size()):
			var j := (i + 1) % rings[layer].size()
			triangle(surface, rings[layer][i], rings[layer + 1][i], rings[layer + 1][j])
			triangle(surface, rings[layer][i], rings[layer + 1][j], rings[layer][j])
	for i in range(rings[0].size()):
		var j := (i + 1) % rings[0].size()
		triangle(surface, Vector3(0, 0, -size.z * 0.5), rings[0][i], rings[0][j])
		triangle(surface, Vector3(0, 0, size.z * 0.5), rings[3][j], rings[3][i])
	surface.generate_normals()
	surface.index()
	return surface.commit()


static func triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)


static func build_base(parent: Node3D, width: float) -> void:
	var base := Node3D.new()
	base.name = "LaptopBase"
	base.position = Vector3(0, 0.782, 0.30)
	base.rotation_degrees.x = -90
	parent.add_child(base)
	part(base, "LowerShell", Vector3(0, 0, -0.007), Vector3(width, 0.60, 0.030), Color("#424e5c"), 0.035)
	part(base, "PalmRest", Vector3(0, 0, 0.009), Vector3(width, 0.60, 0.012), Color("#acb7bc"), 0.035)
	part(base, "KeyboardRecess", Vector3(0, 0.075, 0.017), Vector3(width * 0.79, 0.255, 0.005), Color("#303943"))
	var pitch := width * 0.75 / 14.0
	for row in range(5):
		for col in range(14):
			if row == 4 and col > 3 and col < 10:
				continue
			var key_width := pitch * 6.8 if row == 4 and col == 3 else pitch * 0.85
			var x := (float(col) - 6.5) * pitch
			if row == 4 and col == 3:
				x += pitch * 3.0
			part(base, "Key_%d_%d" % [row, col], Vector3(x, 0.17 - row * 0.045, 0.022), Vector3(key_width, 0.036, 0.010), Color("#52616e") if col != 0 or row != 0 else Color("#bb7960"), 0.006)
	part(base, "TrackpadRim", Vector3(0, -0.17, 0.016), Vector3(width * 0.31, 0.145, 0.004), Color("#677782"), 0.012)
	part(base, "Trackpad", Vector3(0, -0.17, 0.019), Vector3(width * 0.31 - 0.007, 0.138, 0.003), Color("#bac3c5"), 0.010)
	for side in [-1.0, 1.0]:
		part(base, "Hinge", Vector3(side * width * 0.35, 0.285, 0.020), Vector3(width * 0.17, 0.043, 0.038), Color("#65747f"), 0.012)
		for line in range(12):
			part(base, "Speaker", Vector3(side * width * 0.445, 0.17 - line * 0.017, 0.017), Vector3(width * 0.055, 0.003, 0.002), Color("#65747f"), 0.001)
