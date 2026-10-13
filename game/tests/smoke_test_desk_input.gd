extends Node
## Événements de fenêtre projetés, jamais un appel direct au drop métier.
var failures := 0
var pointer := Vector2.ZERO
var down := false


func _ready() -> void:
	_run.call_deferred()


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func frames(count := 4) -> void:
	for i in range(count):
		await get_tree().process_frame


func move(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.relative = at - pointer
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	pointer = at
	get_viewport().push_input(event, true)
	await frames(2)


func button(pressed: bool) -> void:
	down = pressed
	var event := InputEventMouseButton.new()
	event.position = pointer
	event.global_position = pointer
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	get_viewport().push_input(event, true)
	await frames(3)


func point(desk: DeskScreen, pixel: Vector2) -> Vector2:
	var quad: MeshInstance3D = desk.room().get_node("Lid/Dalle")
	var dimensions := Vector2(DeskRoom.SCREEN_PIXELS)
	var size: Vector2 = quad.mesh.size
	return desk.room().camera.unproject_position(quad.to_global(Vector3((pixel.x / dimensions.x - 0.5) * size.x, (0.5 - pixel.y / dimensions.y) * size.y, 0)))


func _run() -> void:
	for comfort in [false, true]:
		SprintState.reset_run("agile-transformation", "meridia-corp")
		DeskViewController.comfort_preference = comfort
		var desk: DeskScreen = load("res://scenes/screens/desk_screen.tscn").instantiate()
		get_tree().root.add_child(desk)
		await frames(12)
		desk.view_controller().transition_seconds = 0
		desk.prop("closing").presentation_seconds = 0
		# Toute la planche, pas son étiquette : centre et quatre coins.
		for local in [Vector3.ZERO, Vector3(-0.08, -0.10, 0.012), Vector3(0.08, -0.10, 0.012), Vector3(-0.08, 0.10, 0.012), Vector3(0.08, 0.10, 0.012)]:
			await get_tree().physics_frame
			var at := desk.room().camera.unproject_position(desk.prop("closing").to_global(local))
			await move(at)
			await button(true)
			await button(false)
			check(desk.prop("closing").is_open(), "Le corps de Fin de sprint doit s'ouvrir au premier clic (%s)." % local)
			desk._close_focused_object()
			await frames()
		await get_tree().physics_frame
		await move(desk.room().camera.unproject_position(desk.room().get_node("LaptopBase").global_position))
		await button(true)
		await button(false)
		check(desk.view_controller().focus_target == "laptop", "Cliquer le clavier ouvre aussi l'ordinateur.")
		desk.open_app("roadmap")
		await frames(12)
		check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "L'ordinateur doit avoir un curseur libre et visible.")
		var fixed := desk.room().camera.global_transform
		var app = desk.workstation().hosted_app()
		var ticket: RoadmapTicket = app.backlog_controls[0]["ticket"]
		var source := point(desk, ticket.get_global_rect().position + Vector2(40, 15))
		await move(source)
		check(desk.room().screen_viewport.gui_get_hovered_control() != null, "Le survol est transmis à l'interface de l'ordinateur.")
		await button(true)
		await move(source + Vector2(26, 0))
		check(desk.room().screen_viewport.gui_is_dragging(), "Un déplacement réel doit démarrer le drag du ticket.")
		var destination := point(desk, app.sprint_drop_zone.get_global_rect().get_center())
		await move(destination)
		check(app.sprint_drop_zone.drop_highlight, "La destination du glissement est mise en évidence.")
		await shot("roadmap_drag_" + str(comfort))
		await button(false)
		check(desk.room().screen_viewport.gui_is_drag_successful(), "Le drop réel doit atteindre la colonne sprint.")
		check(ticket.get_parent() == app.sprint_list, "Le ticket déposé est réellement planifié dans la colonne sprint.")
		check(ticket.planned and ticket.get_theme_stylebox("panel").border_width_left == 6, "La sélection conserve son repère visuel après le drop.")
		check("PRÉVU CE SPRINT" in ticket.find_child("PlanState", true, false).text, "La carte sélectionnée porte un état textuel explicite.")
		check(desk.room().camera.global_transform.is_equal_approx(fixed), "La souris ne fait pas tourner la caméra sur l'ordinateur.")
		# Second geste : relâcher hors dalle, même au-dessus d'un Control parent.
		var remaining: Array = app.backlog_list.get_children()
		if not remaining.is_empty():
			ticket = remaining[0] as RoadmapTicket
			source = point(desk, ticket.get_global_rect().position + Vector2(40, 15))
			await move(source)
			await button(true)
			await move(source + Vector2(28, 0))
			await move(Vector2(30, 30))
			await button(false)
			check(not desk.room().screen_viewport.gui_is_dragging(), "Relâcher hors de l'écran termine le drag.")
			check(not desk.room().screen_viewport.gui_is_drag_successful(), "Relâcher hors écran ne planifie pas de ticket.")
			check(desk.workstation().is_open(), "Sortir pendant un drag ne ferme pas l'application.")
			# Échap annule seulement le geste, pas le logiciel en dessous.
			await move(source)
			await button(true)
			await move(source + Vector2(28, 0))
			var cancel := InputEventKey.new()
			cancel.keycode = KEY_ESCAPE
			cancel.pressed = true
			get_viewport().push_input(cancel, true)
			await frames()
			check(not desk.room().screen_viewport.gui_is_dragging() and desk.workstation().is_open(), "Échap annule le drag sans fermer la roadmap.")
			await button(false)
			await move(source)
			await button(true)
			await move(source + Vector2(28, 0))
			desk._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
			desk.view_controller().window_focus_lost()
			check(not desk.room().screen_viewport.gui_is_dragging() and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Alt-Tab annule le geste et rend la souris.")
			desk.view_controller()._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
			await button(false)
		# La molette doit agir dans le ScrollContainer de la dalle.
		var scroll: ScrollContainer = app.backlog_list.get_parent()
		# Le tirage peut ne laisser que deux tickets : imposer un débordement
		# dans ce fixture de test, sans modifier les données ou règles du jeu.
		var overflow := Control.new()
		overflow.custom_minimum_size = Vector2(1, 400)
		overflow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		app.backlog_list.add_child(overflow)
		await frames()
		await move(point(desk, scroll.get_global_rect().get_center()))
		var before := scroll.scroll_vertical
		for i in range(4):
			var wheel := InputEventMouseButton.new()
			wheel.position = pointer
			wheel.global_position = pointer
			wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
			wheel.pressed = true
			get_viewport().push_input(wheel, true)
			await frames()
		check(scroll.scroll_vertical > before, "La molette fait défiler le backlog dans l'ordinateur.")
		await shot("roadmap_scroll_" + str(comfort))
		desk.queue_free()
		await frames()
	DeskViewController.comfort_preference = false
	print("=== SMOKE INTERACTIONS BUREAU : %s ===" % ("OK" if failures == 0 else "%d ÉCHECS" % failures))
	get_tree().quit(0 if failures == 0 else 1)


func shot(label: String) -> void:
	var directory := OS.get_environment("SHOT_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(label + ".png"))
