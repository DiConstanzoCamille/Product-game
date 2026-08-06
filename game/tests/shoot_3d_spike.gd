extends Node
## Rend le spike 3D et sauve une capture, pour comparer avec le rendu 2D.
func _ready() -> void:
	var out := OS.get_environment("SHOT_DIR")
	# `root` est encore en train d'installer ses enfants pendant notre _ready() :
	# un add_child() direct y est REJETÉ, et Godot le dit sur stderr sans lever
	# d'erreur GDScript — la scène n'existait pas, d'où un écran uni.
	await get_tree().process_frame
	var spike: Node = load("res://scenes/prototype_3d/desk_3d_spike.tscn").instantiate()
	get_tree().root.add_child(spike)
	for _i in range(20):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_tree().root.get_texture().get_image()
	image.save_png("%s/spike_3d.png" % out)
	print("  ✓ spike_3d (%dx%d)" % [image.get_width(), image.get_height()])
	get_tree().quit()
