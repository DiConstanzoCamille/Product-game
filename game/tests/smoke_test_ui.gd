extends Node
## Test headless en deux temps :
##
##  1. instancie chaque écran du jeu et vérifie qu'il entre dans l'arbre sans
##     erreur (chemins @onready valides, pas de crash en _ready()) ;
##  2. **clique les vrais boutons** de l'écran Investissements — le seul qui se
##     reconstruise entièrement depuis ses propres boutons.
##
## Le second temps existe pour une classe de bug qu'aucune vérification d'état
## ne peut attraper : reconstruire un conteneur détruit le bouton **pendant
## l'émission de son signal**, et Godot log alors « Object was freed or
## unreferenced while a signal is being emitted from it » (voir
## UIHelpers.clear_children()). L'erreur vient du moteur, pas de GDScript : elle
## n'est pas rattrapable ici, elle apparaît sur **stderr**. Ce test la
## déclenche ; c'est la lecture de la sortie qui la constate. Les assertions
## ci-dessous couvrent, elles, l'effet attendu de chaque clic.
##
## Lancer : godot --headless --path game res://tests/smoke_test_ui.tscn

const SCREENS := [
	"res://scenes/screens/start_screen.tscn",
	"res://scenes/screens/scenario_screen.tscn",
	"res://scenes/screens/company_select_screen.tscn",
	"res://scenes/screens/inbox_screen.tscn",
	"res://scenes/screens/roadmap_screen.tscn",
	"res://scenes/screens/investments_screen.tscn",
	"res://scenes/screens/resolution_screen.tscn",
	"res://scenes/screens/foundations_screen.tscn",
	"res://scenes/screens/mandate_end_screen.tscn",
]


var failures: int = 0


func _ready() -> void:
	print("=== SMOKE TEST UI ===")
	SprintState.reset_run()
	SprintState.activated_cards.append("notion")
	SprintState.activated_card_sprints["notion"] = 1

	for path in SCREENS:
		await _instantiate_and_free(path)

	await _test_roadmap_interactions()
	await _test_investments_interactions()
	await _test_resolution_replay()
	await _test_resolution_multi_team_replay()

	if failures > 0:
		print("=== SMOKE TEST UI : ÉCHEC — %d assertion(s) en erreur ===" % failures)
		get_tree().quit(1)
		return
	print("=== SMOKE TEST UI : OK — %d écrans instanciés, gestes Roadmap/Investissements joués ===" % SCREENS.size())
	get_tree().quit()


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
	print("ASSERTION ÉCHOUÉE : %s" % message)


## Joue les deux gestes spécifiques à la Roadmap profonde : révéler une carte
## via Plonger puis ajouter une feature au panier. Le moteur teste les effets;
## ici on vérifie que les vrais contrôles portent bien le geste jusqu'à lui.
func _test_roadmap_interactions() -> void:
	print("  → gestes de l'écran Roadmap")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child(viewport)
	var screen: Control = load("res://scenes/screens/roadmap_screen.tscn").instantiate()
	viewport.add_child(screen)
	for i in 10:
		await get_tree().process_frame

	if screen.backlog_controls.is_empty():
		_fail("La Roadmap n'a affiché aucun item du backlog.")
	else:
		var control: Dictionary = screen.backlog_controls[0]
		var item: Dictionary = control["item"]
		var energy_before := SprintState.energy
		var dive: Button = control["dive"]
		dive.pressed.emit()
		await get_tree().process_frame
		if SprintState.energy != energy_before - SprintState.get_personal_action_cost("featureDive"):
			_fail("Le bouton Plonger de la Roadmap n'a pas dépensé l'Énergie configurée.")

		for candidate_control in screen.backlog_controls:
			if candidate_control.has("select"):
				var select: CheckButton = candidate_control["select"]
				select.button_pressed = true
				await get_tree().process_frame
				if screen._current_plan().is_empty():
					_fail("Le contrôle de sélection Roadmap ne produit aucun plan.")
				break

	screen.queue_free()
	viewport.queue_free()
	await get_tree().process_frame


## Joue les cinq gestes de l'écran Investissements en émettant depuis les
## boutons réels : adopter une pratique, embaucher, activer une décision,
## punaiser, replier le panneau. Chacun reconstruit la carte ou le panneau
## depuis le bouton qu'on vient de cliquer.
func _test_investments_interactions() -> void:
	print("  → gestes de l'écran Investissements")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.pieces = 30

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child(viewport)
	var screen: Control = load("res://scenes/screens/investments_screen.tscn").instantiate()
	viewport.add_child(screen)
	for i in 10:
		await get_tree().process_frame

	for kind in ["practice", "candidate", "decision"]:
		var target: Dictionary = {}
		for entry in screen._cards:
			if entry["kind"] == kind and not screen._is_acquired(entry):
				target = entry
				break
		if target.is_empty():
			continue  # ce type n'est pas sorti au tirage de ce sprint

		var button := _primary_button_of(target["node"])
		if button == null or button.disabled:
			continue
		button.pressed.emit()
		for i in 3:
			await get_tree().process_frame
		if not screen._is_acquired(target):
			_fail("Le bouton principal de %s:%s n'a pas produit l'acquisition." % [kind, target["id"]])

	# 📌 La punaise : elle reconstruit la carte depuis un bouton de la carte.
	for entry in screen._cards:
		if screen._is_acquired(entry):
			continue
		_pin_button_of(entry["node"]).pressed.emit()
		for i in 3:
			await get_tree().process_frame
		if not SprintState.is_reserved(entry["kind"], entry["id"]):
			_fail("La punaise de %s:%s n'a pas posé de réservation." % [entry["kind"], entry["id"]])
		break

	# Le repli du panneau : même schéma, le bouton vit dans ce qu'il reconstruit.
	var panel: Control = screen.side_panel
	panel.get_node("Margin/Scroll/VBox").get_child(0).pressed.emit()
	for i in 3:
		await get_tree().process_frame
	if not panel.collapsed:
		_fail("Le bouton de repli n'a pas replié le Panneau de bord.")
	if panel.size.x > UIHelpers.SIDE_PANEL_WIDTH / 2:
		_fail("Le panneau replié fait encore %d px de large." % int(panel.size.x))

	screen.queue_free()
	viewport.queue_free()
	await get_tree().process_frame


## La Résolution lit le rapport déjà calculé, et ses deux gestes globaux
## doivent accélérer puis révéler le flux sans attendre la durée réelle.
func _test_resolution_replay() -> void:
	print("  → lecture animee de la Resolution")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	var feature: Dictionary = GameData.backlog.get("features", [])[0]
	SprintState.current_backlog_draw = {"sprint": SprintState.sprint_number, "items": [feature]}
	SprintState.commit_backlog_plan([{"id": feature.get("id", ""), "points": feature.get("costPoints", 0)}])

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child(viewport)
	var screen: Control = load("res://scenes/screens/resolution_screen.tscn").instantiate()
	viewport.add_child(screen)
	for i in 3:
		await get_tree().process_frame
	if SprintState.last_score_report.is_empty() or screen._score_events.is_empty():
		_fail("La Resolution doit afficher le rapport de score deja resolu.")
	else:
		screen._accelerate_score_replay()
		if screen._score_replay_speed != 4.0:
			_fail("Le premier geste de Resolution n'accelere pas l'animation.")
		screen._reveal_score_replay()
		if not screen._score_finished or screen._score_event_index != screen._score_events.size():
			_fail("Le second geste de Resolution ne revele pas tout le rapport.")
		for child in screen.score_lines.get_children():
			if child is Label and child.visible and "squad" in child.text.to_lower():
				_fail("Le joueur ne doit jamais voir le mot squad en mode une equipe.")

	screen.queue_free()
	viewport.queue_free()
	await get_tree().process_frame


func _test_resolution_multi_team_replay() -> void:
	print("  → lecture multi-equipe de la Resolution")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	var feature: Dictionary = GameData.backlog.get("features", [])[0]
	SprintState.squads.append({
		"id": "equipe-plateforme-test",
		"name": "Equipe plateforme",
		"roster": [],
		"backlog_draw": {},
		"capacity": int(feature.get("costPoints", 0)),
		"delivered": [feature],
		"spent_points": int(feature.get("costPoints", 0)),
		"epic_progress": {},
	})

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child(viewport)
	var screen: Control = load("res://scenes/screens/resolution_screen.tscn").instantiate()
	viewport.add_child(screen)
	for i in 3:
		await get_tree().process_frame
	var divider_indexes: Array = []
	for index in screen._score_events.size():
		if screen._score_events[index].get("kind", "") == "divider":
			divider_indexes.append(index)
	if divider_indexes.size() != 2 or divider_indexes[0] != 0 or divider_indexes[1] <= 1:
		_fail("La lecture multi-equipe doit reveler chaque separateur dans sa propre sequence.")
	screen._reveal_score_replay()
	for child in screen.score_lines.get_children():
		if child is Label and child.visible and "squad" in child.text.to_lower():
			_fail("Les separateurs multi-equipe ne doivent pas exposer le terme technique squad.")

	screen.queue_free()
	viewport.queue_free()
	await get_tree().process_frame


func _primary_button_of(card: Control) -> Button:
	var buttons := _buttons_in(card.get_node("Margin/VBox"))
	return buttons[-1] if not buttons.is_empty() else null


func _pin_button_of(card: Control) -> Button:
	return _buttons_in(card.get_node("Margin/VBox"))[0]


func _buttons_in(node: Node) -> Array:
	var found: Array = []
	for child in node.get_children():
		if child is Button:
			found.append(child)
		found.append_array(_buttons_in(child))
	return found


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
