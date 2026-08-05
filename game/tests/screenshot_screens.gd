extends Node
## Outil de diagnostic : instancie chaque écran et en sauve une capture PNG.
## Nécessite un vrai serveur d'affichage — lancer sous xvfb :
##   xvfb-run -a godot --path game --display-driver x11 res://tests/screenshot_screens.tscn

const SCREENS := [
	"res://scenes/screens/desk_screen.tscn",
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
	_prepare_team_state()
	await _shoot_all()
	_prepare_team_state()
	await _shoot_team_management()
	await _shoot_desk_states()
	print("=== CAPTURES : TERMINÉ ===")
	get_tree().quit()


func _prepare_team_state() -> void:
	SprintState.reset_run("agile-transformation", "meridia-corp")
	# La capture de recette peut rendre visible le cas d'alerte sans bricoler les
	# scènes. Sans variable, elle conserve l'état nominal du premier sprint.
	if OS.get_environment("TEAM_ALERT_CAPTURE") == "1":
		var roster := SprintState.get_roster()
		if not roster.is_empty():
			SprintState.employee_wellbeing(roster[0])["confiance"] = 12
			SprintState.employee_wellbeing(roster[0])["salaire"] = 20
			SprintState._inspect_team_crises()
			SprintState._refresh_team_moral()


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


func _shoot_team_management() -> void:
	var screen: Control = load("res://scenes/screens/roadmap_screen.tscn").instantiate()
	add_child(screen)
	for i in range(12):
		await get_tree().process_frame
	var open_button: Button = screen.find_child("OpenTeamManagement", true, false)
	if open_button == null:
		print("  ✗ bouton Gérer l'équipe introuvable")
	else:
		open_button.pressed.emit()
		for i in range(12):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image: Image = get_viewport().get_texture().get_image()
		var target: String = "%s/team_management_screen.png" % out_dir
		var err: int = image.save_png(target)
		print("  %s team_management_screen (%dx%d)" % ["✓" if err == OK else "✗", image.get_width(), image.get_height()])
	screen.queue_free()
	await get_tree().process_frame


## Le bureau ne se juge pas au repos : ce qui pouvait casser, c'est une phase
## existante hébergée dans le moniteur et un accessoire ouvert. Les deux se
## capturent ici, sinon le lot serait déclaré fini sans que personne ne les ait
## vus (CLAUDE.md : quatre lots livrés sans un pixel regardé).
func _shoot_desk_states() -> void:
	for state in ["app", "shop", "committee"]:
		_prepare_team_state()
		if state == "committee":
			SprintState.committee_pending = true
		var desk: Node = load("res://scenes/screens/desk_screen.tscn").instantiate()
		get_tree().root.add_child(desk)
		await get_tree().process_frame
		await get_tree().process_frame

		match state:
			"app":
				desk.get_node("Workstation").open_app("inbox")
			"shop":
				desk.get_node("shop").expand()
			"committee":
				desk.get_node("committee").expand()
		# Les accessoires glissent en 0,34 s : capturer avant la fin du Tween
		# montrerait un objet à mi-course, ce qui ne prouve rien.
		for _i in range(40):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw

		var image := get_tree().root.get_texture().get_image()
		image.save_png("%s/desk_%s.png" % [out_dir, state])
		print("  ✓ desk_%s (%dx%d)" % [state, image.get_width(), image.get_height()])
		desk.queue_free()
		await get_tree().process_frame
