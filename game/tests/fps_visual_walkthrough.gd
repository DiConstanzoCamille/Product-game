extends Node
## Recette rendue : visée, clics routés, redimensionnement et deux runs complets.
var out_dir := ""

func _ready() -> void:
	out_dir = OS.get_environment("SHOT_DIR")
	_run.call_deferred()


func _run() -> void:
	for comfort in [false, true]:
		SprintState.reset_run("agile-transformation", "meridia-corp")
		DeskViewController.comfort_preference = comfort
		var desk: DeskScreen = load("res://scenes/screens/desk_screen.tscn").instantiate()
		get_tree().root.add_child(desk)
		get_tree().current_scene = desk
		await frames(12)
		var mode := "confort" if comfort else "immersif"
		if not comfort:
			var view := desk.view_controller()
			var saved := desk.room().camera.global_transform
			desk.room().camera.look_at_from_position(Vector3(-0.87, 1.0, 0.72), Vector3(-0.87, 0.81, 0.43), Vector3.UP)
			await shot("asset_tasse")
			desk.room().camera.global_transform = saved
			view.capture_look()
			for sample in [{"name": "gauche", "angle": Vector2(42, 0)}, {"name": "droite", "angle": Vector2(-42, 0)}, {"name": "haut", "angle": Vector2(0, 24)}, {"name": "bas", "angle": Vector2(0, -32)}]:
				view.angles = sample["angle"]
				view.rotate_look(Vector2.ZERO)
				await shot("fps_" + sample["name"])
			view.angles = Vector2.ZERO
			view.rotate_look(Vector2.ZERO)
			view.release_look()
		for sprint in range(12):
			desk = get_tree().current_scene as DeskScreen
			if desk == null:
				fail("Le sprint doit commencer au bureau.")
				return
			await frames(12)
			# Entrer dans le laptop avec le rayon et le chemin réel d'entrée.
			var view := desk.view_controller()
			view.capture_look()
			var camera := desk.room().camera
			var original := camera.global_transform
			var desired := original.looking_at(desk.room().dalle_center(), Vector3.UP).basis.get_euler()
			var current := original.basis.get_euler()
			view.rotate_look(-Vector2(rad_to_deg(desired.y - current.y), rad_to_deg(desired.x - current.x)) / float(SprintState.get_desk_conf()["camera"]["sensitivity"]))
			await get_tree().physics_frame
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			desk._unhandled_input(click)
			await settle(desk)
			if view.focus_target != "laptop":
				fail("La visée n'a pas ouvert le laptop.")
				return
			desk.open_app("inbox")
			await frames(4)
			var inbox: Control = desk.workstation().hosted_app()
			if not inbox.choice_buttons.is_empty():
				await click_quad(desk, desk.room().get_node("Lid/Dalle"), inbox.choice_buttons[0].get_global_rect().get_center(), Vector2(DeskRoom.SCREEN_PIXELS))
				if inbox.next_button.disabled:
					fail("Le clic 3D n'atteint pas la réponse du courrier.")
					return
			await shot("run_%s_%d_inbox" % [mode, sprint + 1])
			desk.workstation().close_app()
			desk.open_app("roadmap")
			await frames(4)
			desk.workstation().hosted_app()._on_next_pressed()
			desk._close_focused_object()
			await settle(desk)
			desk.open_prop("shop")
			await settle(desk)
			await get_tree().create_timer(0.5).timeout
			await shot("run_%s_%d_boutique" % [mode, sprint + 1])
			desk._close_focused_object()
			await settle(desk)
			desk.open_prop("closing")
			await settle(desk)
			await get_tree().create_timer(0.5).timeout
			var closing: Node3D = desk.prop("closing")
			var sign: Button = closing.find_child("SignButton", true, false)
			await click_quad(desk, closing.get_node("PanelPivot/Panel"), sign.get_global_rect().get_center(), Vector2(closing.get_node("PanelPivot/PropViewport").size))
			await frames(12)
			var resolution := get_tree().current_scene
			if not resolution.has_method("_reveal_score_replay"):
				fail("SIGNER doit quitter le bureau par le clic 3D routé.")
				return
			resolution._reveal_score_replay()
			await shot("run_%s_%d_resolution" % [mode, sprint + 1])
			resolution.next_sprint_button.pressed.emit()
			await frames(12)
			if not (get_tree().current_scene is DeskScreen):
				await shot("run_%s_fin" % mode)
				print("RUN VISUEL %s : fin %s, sprint %d" % [mode, SprintState.ending_id, SprintState.sprint_number])
				break
		get_tree().current_scene.queue_free()
		await frames(2)
	# Redimensionner pendant la lecture : dalle à l'échelle et clic toujours routé.
	SprintState.reset_run("agile-transformation", "meridia-corp")
	var desk: DeskScreen = load("res://scenes/screens/desk_screen.tscn").instantiate()
	get_tree().root.add_child(desk)
	get_tree().current_scene = desk
	await frames(12)
	desk.open_app("inbox")
	await settle(desk)
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 900)
	await frames(12)
	var projected := desk.room().dalle_projected_size()
	if absf(projected.x / 880.0 - 1.0) > 0.06 or absf(projected.y / 495.0 - 1.0) > 0.06:
		fail("Le redimensionnement dégrade la taille de lecture : %s" % projected)
		return
	var inbox: Control = desk.workstation().hosted_app()
	await click_quad(desk, desk.room().get_node("Lid/Dalle"), inbox.choice_buttons[0].get_global_rect().get_center(), Vector2(DeskRoom.SCREEN_PIXELS))
	if inbox.next_button.disabled:
		fail("Le clic ne suit pas le redimensionnement.")
		return
	await shot("fps_redimensionne")
	DeskViewController.comfort_preference = false
	print("=== RECETTE FPS RENDUE : OK ===")
	get_tree().quit()


func click_quad(desk: DeskScreen, quad: MeshInstance3D, pixel: Vector2, dimensions: Vector2) -> void:
	var size: Vector2 = quad.mesh.size
	var local := Vector3((pixel.x / dimensions.x - 0.5) * size.x, (0.5 - pixel.y / dimensions.y) * size.y, 0)
	var point := desk.room().camera.unproject_position(quad.to_global(local))
	var motion := InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion, true)
	await get_tree().physics_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().physics_frame
		await get_tree().process_frame


func settle(desk: DeskScreen) -> void:
	if desk.view_controller().transitioning():
		await desk.view_controller().settled
	await frames(3)


func frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame


func shot(label: String) -> void:
	await frames(4)
	await RenderingServer.frame_post_draw
	if not out_dir.is_empty():
		get_viewport().get_texture().get_image().save_png(out_dir.path_join(label + ".png"))


func fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
