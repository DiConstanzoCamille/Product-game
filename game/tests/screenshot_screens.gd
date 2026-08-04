extends Node
## Outil de diagnostic : instancie chaque écran et en sauve une capture PNG.
## Nécessite un vrai serveur d'affichage — lancer sous xvfb :
##   xvfb-run -a godot --path game --display-driver x11 res://tests/screenshot_screens.tscn

const SCREENS := [
	"res://scenes/screens/start_screen.tscn",
	"res://scenes/screens/career_select_screen.tscn",
	"res://scenes/screens/scenario_screen.tscn",
	"res://scenes/screens/company_select_screen.tscn",
	"res://scenes/screens/inbox_screen.tscn",
	"res://scenes/screens/roadmap_screen.tscn",
	"res://scenes/screens/investments_screen.tscn",
	"res://scenes/screens/resolution_screen.tscn",
	"res://scenes/screens/foundations_screen.tscn",
	"res://scenes/screens/mandate_end_screen.tscn",
	"res://scenes/screens/committee_screen.tscn",
]

var out_dir: String = ""


func _ready() -> void:
	out_dir = OS.get_environment("SHOT_DIR")
	print("=== CAPTURES — sortie : %s ===" % out_dir)
	SprintState.reset_run("agile-transformation", "meridia-corp")
	await _shoot_all()
	print("=== CAPTURES : TERMINÉ ===")
	get_tree().quit()


func _shoot_all() -> void:
	for path in SCREENS:
		var packed: PackedScene = load(path)
		if packed == null:
			print("  ✗ introuvable : %s" % path)
			continue
		var screen: Node = packed.instantiate()
		add_child(screen)
		# Laisser le temps aux @onready, aux tweens d'entrée et au tri des
		# conteneurs de se poser avant de photographier.
		for i in range(12):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image: Image = get_viewport().get_texture().get_image()
		var name: String = path.get_file().replace(".tscn", "")
		var target: String = "%s/%s.png" % [out_dir, name]
		var err: int = image.save_png(target)
		print("  %s %s (%dx%d)" % ["✓" if err == OK else "✗", name, image.get_width(), image.get_height()])
		screen.queue_free()
		await get_tree().process_frame
