extends RefCounted
## Relais unique d'une surface 3D : conserve le geste même hors du quad.
var viewport: SubViewport
var quad: MeshInstance3D
var inside := false
var held := false
var previous := Vector2.ZERO


func bind(surface: MeshInstance3D, target: SubViewport) -> void:
	if viewport == target and quad == surface:
		return
	reset()
	quad = surface
	viewport = target


func reset() -> void:
	if is_instance_valid(viewport) and viewport.is_inside_tree():
		viewport.gui_cancel_drag()
		if held:
			var release := InputEventMouseButton.new()
			release.button_index = MOUSE_BUTTON_LEFT
			release.position = Vector2(-100, -100)
			release.global_position = release.position
			viewport.push_input(release, true)
		if inside:
			viewport.notify_mouse_exited()
	viewport = null
	quad = null
	inside = false
	held = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func pixel_at(camera: Camera3D, at: Vector2) -> Vector2:
	var inverse := quad.global_transform.affine_inverse()
	var origin := inverse * camera.project_ray_origin(at)
	var direction := inverse.basis * camera.project_ray_normal(at)
	if absf(direction.z) < 0.00001:
		return Vector2(-10000, -10000)
	var local := origin - direction * (origin.z / direction.z)
	var dimensions: Vector2 = quad.mesh.size
	return Vector2(local.x / dimensions.x + 0.5, 0.5 - local.y / dimensions.y) * Vector2(viewport.size)


func route(camera: Camera3D, event: InputEvent) -> bool:
	if not is_instance_valid(viewport) or viewport.gui_disable_input or not (event is InputEventMouse):
		return false
	var pixel := pixel_at(camera, event.position)
	var was_inside := inside
	inside = Rect2(Vector2.ZERO, Vector2(viewport.size)).has_point(pixel)
	if inside and not was_inside:
		viewport.notify_mouse_entered()
	elif not inside and was_inside:
		viewport.notify_mouse_exited()
	var owned := held
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and inside:
			held = true
		elif not event.pressed:
			held = false
	if not inside and not owned:
		return false
	var routed: InputEventMouse = event.duplicate()
	routed.position = pixel
	routed.global_position = pixel
	if routed is InputEventMouseMotion:
		routed.relative = pixel - previous if was_inside or owned else pixel - pixel_at(camera, event.position - event.relative)
	previous = pixel
	viewport.push_input(routed, true)
	return true
