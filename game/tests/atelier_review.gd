extends SceneTree
## Captures ciblées du décor importé et des interfaces dans leur cadre réel.
## SHOT_DIR=/chemin godot --path game -s res://tests/atelier_review.gd

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("SprintState")
	for alert in [false, true]:
		state.reset_run("agile-transformation", "meridia-corp")
		if alert:
			var employee: Dictionary = state.get_roster()[0]
			state.employee_wellbeing(employee)["confiance"] = 12
			state.employee_wellbeing(employee)["salaire"] = 20
			state._inspect_team_crises()
			state._refresh_team_moral()
		var desk: Node = load("res://scenes/screens/desk_screen.tscn").instantiate()
		root.add_child(desk)
		await create_timer(0.5).timeout
		await _shot("desk_alert" if alert else "desk_nominal")
		if not alert:
			var view: Node = desk.view_controller()
			view.capture_look()
			for sample in [["fps_left", Vector2(42, 0)], ["fps_right", Vector2(-42, 0)]]:
				view.angles = sample[1]
				view.rotate_look(Vector2.ZERO)
				await _shot(sample[0])
			view.angles = Vector2.ZERO
			view.rotate_look(Vector2.ZERO)
			view.release_look()
			desk.open_app("inbox")
			if view.transitioning():
				await view.settled
			await _shot("desk_reading")
		desk.queue_free()
		await process_frame
	print("ATELIER REVIEW: OK")
	quit()


func _shot(label: String) -> void:
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var output := OS.get_environment("SHOT_DIR").path_join(label + ".png")
	var result := root.get_texture().get_image().save_png(output)
	if result != OK:
		push_error("Capture impossible : " + output)
		quit(1)
	print("CAPTURE: ", label)
