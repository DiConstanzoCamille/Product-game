extends Node
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func _ready() -> void:
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.committee_pending = true
	var desk: DeskScreen = load("res://scenes/screens/desk_screen.tscn").instantiate()
	get_tree().root.add_child.call_deferred(desk)
	for i in range(10):
		await get_tree().process_frame
	var view := desk.view_controller()
	check(view.state == DeskViewController.State.FREE, "Entrer au bureau ne capture pas la souris.")
	var base := desk.room().camera.global_transform
	view.capture_look()
	view.rotate_look(Vector2(100000, 100000))
	check(view.angles.x == -42.0 and view.angles.y == -32.0, "Le regard respecte ses bornes.")
	check(desk.room().camera.global_position.is_equal_approx(base.origin), "Regarder ne déplace pas le fauteuil.")
	view.angles = Vector2.ZERO
	view.rotate_look(Vector2.ZERO)
	# Chaque cible doit être atteignable par une rotation autorisée et le vrai rayon.
	for area in desk.room().find_children("*", "Area3D", true, false):
		if not area.has_meta("desk_target"):
			continue
		view.angles = Vector2.ZERO
		view.rotate_look(Vector2.ZERO)
		var center: Vector3 = area.get_child(0).global_position
		var desired := base.looking_at(center, Vector3.UP).basis.get_euler()
		var initial := base.basis.get_euler()
		var relative := Vector2(rad_to_deg(desired.y - initial.y), rad_to_deg(desired.x - initial.x))
		view.rotate_look(-relative / float(SprintState.get_desk_conf()["camera"]["sensitivity"]))
		await get_tree().physics_frame
		var hit := view.hit_at(get_viewport().get_visible_rect().size * 0.5)
		check(hit.get("collider") == area, "La visée doit atteindre " + String(area.get_meta("desk_target")))
	view.angles = Vector2(10, -4)
	view.rotate_look(Vector2.ZERO)
	var previous := desk.room().camera.global_transform
	desk.open_app("roadmap")
	check(view.state == DeskViewController.State.TO_FOCUS, "Ouvrir démarre une transition explicite.")
	check(desk.room().screen_viewport.gui_disable_input, "La transition bloque l'UI du laptop.")
	await view.settled
	check(view.state == DeskViewController.State.FOCUS, "La fin de transition donne le focus.")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Passer du regard capturé à l'ordinateur rend le curseur visible.")
	check(not desk.room().screen_viewport.gui_disable_input, "Le logiciel devient interactif à l'arrivée.")
	var projected := desk.room().dalle_projected_size()
	check(absf(projected.x / 880.0 - 1.0) < 0.06 and absf(projected.y / 495.0 - 1.0) < 0.06, "Le laptop retrouve sa taille de lecture.")
	desk._unhandled_input(escape())
	check(not desk.workstation().is_open() and view.state == DeskViewController.State.FOCUS, "Premier Échap : application vers lanceur, sans caméra.")
	desk._unhandled_input(escape())
	await view.settled
	check(desk.room().camera.global_transform.is_equal_approx(previous), "Le retour retrouve le regard précédent.")
	check(view.state == DeskViewController.State.LOOK, "Le mode immersif retrouve la capture précédente.")
	# Interrompre une entrée ne doit jamais ouvrir tardivement l'application.
	desk.open_app("inbox")
	desk._unhandled_input(escape())
	await view.settled
	check(not desk.workstation().is_open(), "Une entrée annulée n'exécute pas son callback tardivement.")
	view.transition_seconds = 0
	view.capture_look()
	for i in range(100):
		desk._activate_target("laptop")
		desk._close_focused_object()
	check(view.state == DeskViewController.State.LOOK, "100 alternances convergent vers l'observation.")
	view.window_focus_lost()
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and view.state == DeskViewController.State.FREE, "Perdre le focus libère le curseur.")
	view._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	view.set_comfort(true)
	view.capture_look()
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	view._input(release)
	check(view.state == DeskViewController.State.FREE and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Relâcher le clic droit rend le curseur en confort.")
	desk.open_prop("shop")
	check(desk.prop("shop").is_open(), "La boutique s'ouvre aussi en confort.")
	check(desk.prop("shop").get_node("PanelPivot/PropViewport").gui_disable_input, "Le panneau en mouvement bloque ses entrées.")
	await get_tree().create_timer(0.50).timeout
	check(not desk.prop("shop").get_node("PanelPivot/PropViewport").gui_disable_input, "Le panneau posé accepte ses entrées.")
	desk._close_focused_object()
	check(view.state == DeskViewController.State.FREE, "Quitter la boutique ne capture pas en confort.")
	view.set_comfort(false)
	desk.queue_free()
	await get_tree().process_frame
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Quitter la scène rend le curseur.")
	print("=== SMOKE FPS : %s ===" % ("OK" if failures == 0 else "%d ÉCHECS" % failures))
	get_tree().quit(0 if failures == 0 else 1)


func escape() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	return event
