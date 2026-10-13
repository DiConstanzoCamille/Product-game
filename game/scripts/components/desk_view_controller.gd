class_name DeskViewController
extends Node
## Unique propriétaire du curseur et de la caméra. Aucun effet métier.

signal state_changed
signal pose_changed
signal target_requested(id: String)
signal settled

enum State { FREE, LOOK, TO_FOCUS, FOCUS, RETURN }
static var comfort_preference := false
var state: State = State.FREE
var focus_target := ""
var angles := Vector2.ZERO
var transition_seconds := 0.32
var comfort := false
var _camera: Camera3D
var _conf: Dictionary
var _observation: Transform3D
var _tween: Tween
var _resume_capture := false
var _window_active := true
var _serial := 0


func setup(camera: Camera3D, conf: Dictionary) -> void:
	_camera = camera
	_conf = conf
	transition_seconds = float(conf["transitionSeconds"])
	comfort = comfort_preference
	var p: Array = conf["position"]
	var a: Array = conf["aim"]
	_camera.look_at_from_position(Vector3(p[0], p[1], p[2]), Vector3(a[0], a[1], a[2]), Vector3.UP)
	_observation = _camera.global_transform
	_camera.fov = float(conf["fov"])
	_mouse(false)


func observing() -> bool:
	return state == State.FREE or state == State.LOOK


func transitioning() -> bool:
	return state == State.TO_FOCUS or state == State.RETURN


func set_comfort(value: bool) -> void:
	comfort = value
	comfort_preference = value
	release_look()


func capture_look() -> void:
	if not observing() or not _window_active:
		return
	state = State.LOOK
	_mouse(true)
	state_changed.emit()


func release_look() -> void:
	if state == State.LOOK:
		state = State.FREE
	_resume_capture = false
	_mouse(false)
	state_changed.emit()


func rotate_look(relative: Vector2) -> void:
	if state != State.LOOK:
		return
	var sensitivity := float(_conf["sensitivity"])
	angles.x = clampf(angles.x - relative.x * sensitivity, -float(_conf["yawLimit"]), float(_conf["yawLimit"]))
	var sign_y := -1.0 if bool(_conf["invertY"]) else 1.0
	angles.y = clampf(angles.y - relative.y * sensitivity * sign_y, -float(_conf["pitchDownLimit"]), float(_conf["pitchUpLimit"]))
	_camera.global_transform = observation_pose()
	pose_changed.emit()


func observation_pose() -> Transform3D:
	var rotation := Basis(Vector3.UP, deg_to_rad(angles.x)) * _observation.basis * Basis(Vector3.RIGHT, deg_to_rad(angles.y))
	return Transform3D(rotation, _observation.origin)


func begin_focus(id: String, pose: Dictionary, on_arrival: Callable) -> void:
	if observing():
		_resume_capture = state == State.LOOK and not comfort
	focus_target = id
	state = State.TO_FOCUS
	_mouse(false)
	_move_to(pose["transform"], float(pose["fov"]), func():
		state = State.FOCUS
		_mouse(false)
		on_arrival.call()
		state_changed.emit())


func return_to_observation() -> void:
	focus_target = ""
	state = State.RETURN
	_mouse(false)
	_move_to(observation_pose(), float(_conf["fov"]), func():
		state = State.LOOK if _resume_capture and _window_active and not comfort else State.FREE
		_mouse(state == State.LOOK)
		state_changed.emit())


func _move_to(pose: Transform3D, fov: float, on_arrival: Callable) -> void:
	_serial += 1
	var serial := _serial
	if _tween != null and _tween.is_valid():
		_tween.kill()
	state_changed.emit()
	if transition_seconds <= 0.0:
		_camera.global_transform = pose
		_camera.fov = fov
		pose_changed.emit()
		on_arrival.call()
		settled.emit()
		return
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_camera, "global_position", pose.origin, transition_seconds)
	_tween.tween_property(_camera, "quaternion", pose.basis.get_rotation_quaternion(), transition_seconds)
	_tween.tween_property(_camera, "fov", fov, transition_seconds)
	_tween.chain().tween_callback(func():
		if serial != _serial:
			return
		_camera.global_transform = pose
		pose_changed.emit()
		on_arrival.call()
		settled.emit())


func _process(_delta: float) -> void:
	if transitioning():
		pose_changed.emit()


func _input(event: InputEvent) -> void:
	if state == State.LOOK and event is InputEventMouseMotion:
		rotate_look(event.relative)
		get_viewport().set_input_as_handled()
	if comfort and state == State.LOOK and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		release_look()
		get_viewport().set_input_as_handled()


func handle_observation(event: InputEvent) -> bool:
	if not observing():
		return false
	if event.is_action_pressed("ui_cancel"):
		release_look()
		return true
	if event is InputEventMouseButton and event.pressed:
		if comfort and event.button_index == MOUSE_BUTTON_RIGHT:
			capture_look()
			return true
		if event.button_index == MOUSE_BUTTON_LEFT:
			var at: Vector2 = event.position if state == State.FREE else get_viewport().get_visible_rect().size * 0.5
			var hit := hit_at(at)
			if not hit.is_empty():
				target_requested.emit(String(hit["collider"].get_meta("desk_target", "")))
			elif state == State.FREE and not comfort:
				capture_look()
			return true
	return false


func hit_at(at: Vector2) -> Dictionary:
	var origin := _camera.project_ray_origin(at)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + _camera.project_ray_normal(at) * float(_conf["rayLength"]), 1)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	return _camera.get_world_3d().direct_space_state.intersect_ray(query)


func window_focus_lost() -> void:
	_window_active = false
	release_look()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		window_focus_lost()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_window_active = true
		_mouse(state == State.LOOK)


func _mouse(captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	_serial += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_mouse(false)
