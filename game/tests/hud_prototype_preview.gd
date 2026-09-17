extends Node
## Trois états du vrai prototype, sans modifier les données de production.
func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	seed(20260907)
	SprintState.reset_run("agile-transformation", "meridia-corp")
	var desk: DeskScreen = load("res://scenes/screens/desk_screen.tscn").instantiate()
	get_tree().root.add_child(desk)
	for i in range(16):
		await get_tree().process_frame
	await shot("01_bureau")
	desk.open_app("roadmap")
	await desk.view_controller().settled
	await get_tree().create_timer(0.4).timeout
	await shot("02_roadmap_disponible")
	var app = desk.workstation().hosted_app()
	app._on_ticket_dropped(app.backlog_controls[0]["item"]["id"])
	await get_tree().create_timer(0.5).timeout
	await shot("03_roadmap_selection")
	var original_size := get_window().size
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 900)
	await get_tree().create_timer(0.4).timeout
	await shot("05_roadmap_1280")
	get_window().size = original_size
	await get_tree().create_timer(0.4).timeout
	for control in app.backlog_controls:
		app._on_ticket_dropped(control["item"]["id"])
	await get_tree().create_timer(0.5).timeout
	await shot("04_roadmap_surcharge")
	print("=== PROTOTYPE HUD : CAPTURES OK ===")
	get_tree().quit()


func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var directory := OS.get_environment("SHOT_DIR")
	if not directory.is_empty():
		get_viewport().get_texture().get_image().save_png(directory.path_join(label + ".png"))
