extends Node3D
## Vue de contrôle du modèle entier, sans modifier la caméra du jeu.
## SHOT_DIR=/chemin godot --path game res://tests/laptop_asset_preview.tscn

func _ready() -> void:
	var room := DeskRoom.new()
	add_child(room)
	room.build()
	room.camera.look_at_from_position(Vector3(1.0, 2.05, 2.25), Vector3(0, 1.02, 0.12), Vector3.UP)
	var panel := ColorRect.new()
	panel.size = Vector2(DeskRoom.SCREEN_PIXELS)
	panel.color = Color("#172b3d")
	room.screen_viewport.add_child(panel)
	var title := Label.new()
	title.text = "PRODUCT\nTYCOON"
	title.position = Vector2(65, 100)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color("#e6eff2"))
	panel.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "POSTE DE TRAVAIL  /  01"
	subtitle.position = Vector2(70, 330)
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color("#98b9c8"))
	panel.add_child(subtitle)
	for frame in range(16):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output := OS.get_environment("SHOT_DIR")
	if not output.is_empty():
		var error := get_viewport().get_texture().get_image().save_png(output.path_join("laptop_detail.png"))
		if error != OK:
			push_error("Capture laptop impossible : %s" % error)
	get_tree().quit()
