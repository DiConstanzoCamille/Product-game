extends Node
## Test headless : instancie chaque écran du jeu et vérifie qu'il entre
## dans l'arbre sans erreur (chemins @onready valides, pas de crash en
## _ready()). Ne simule pas de clics — complète smoke_test_logic.gd, qui
## couvre la logique de simulation.
##
## Lancer : godot --headless --path game res://tests/smoke_test_ui.tscn

const SCREENS := [
	"res://scenes/screens/start_screen.tscn",
	"res://scenes/screens/scenario_screen.tscn",
	"res://scenes/screens/company_select_screen.tscn",
	"res://scenes/screens/inbox_screen.tscn",
	"res://scenes/screens/roadmap_screen.tscn",
	"res://scenes/screens/decisions_screen.tscn",
	"res://scenes/screens/recruitment_screen.tscn",
	"res://scenes/screens/resolution_screen.tscn",
	"res://scenes/screens/foundations_screen.tscn",
	"res://scenes/screens/mandate_end_screen.tscn",
]


func _ready() -> void:
	print("=== SMOKE TEST UI ===")
	SprintState.reset_run()
	SprintState.activated_cards.append("notion")
	SprintState.activated_card_sprints["notion"] = 1

	for path in SCREENS:
		await _instantiate_and_free(path)

	print("=== SMOKE TEST UI : OK — %d écrans instanciés sans erreur ===" % SCREENS.size())
	get_tree().quit()


func _instantiate_and_free(path: String) -> void:
	print("  → %s" % path)

	if path == "res://scenes/screens/mandate_end_screen.tscn":
		SprintState.is_mandate_over = true
		SprintState.ending_id = "ipo"

	if path == "res://scenes/screens/company_select_screen.tscn":
		SprintState.pending_era_id = SprintState.era_id

	var packed: PackedScene = load(path)
	if packed == null:
		push_error("Impossible de charger %s" % path)
		return

	var instance := packed.instantiate()

	# Un script qui ne compile pas n'empêche pas la scène de s'instancier : Godot
	# la charge sans lui. Sans cette vérification, une erreur de parse passait le
	# test au vert — et l'écran arrivait muet en jeu.
	if instance.get_script() == null:
		push_error("%s s'instancie sans son script — erreur de compilation ?" % path)

	get_tree().root.add_child.call_deferred(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	instance.queue_free()
	await get_tree().process_frame
