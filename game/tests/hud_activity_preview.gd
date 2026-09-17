extends Node
var failures := 0

func _ready() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	seed(20260907)
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.committee_pending = true
	var original_report := SprintState.last_roadmap_report.duplicate(true)
	SprintState.last_roadmap_report = {"sprint": SprintState.sprint_number, "delivered": [{"id": "epic"}], "epicUpdates": [{"item": {"id": "epic"}}, {"item": {"id": "ongoing"}}], "plannedPoints": 5}
	check(SprintState.get_desk_activity()["tickets"] == 2, "Un epic terminé n'est pas compté deux fois.")
	SprintState.last_roadmap_report["sprint"] = SprintState.sprint_number - 1
	check(not SprintState.get_desk_activity()["saved"] and SprintState.get_desk_activity()["tickets"] == 0, "Un ancien rapport n'est pas le plan du sprint courant.")
	SprintState.last_roadmap_report = original_report
	var desk: DeskScreen = load("res://scenes/screens/desk_screen.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().create_timer(0.3).timeout
	var feed: VBoxContainer = desk.readable_layer().get_node("ResourceChanges")
	check(feed.get_child_count() == 0, "Pas de faux gains à l'entrée du bureau.")
	check(not SprintState.get_desk_activity()["saved"], "Le plan initial n'est pas enregistré.")
	await shot("01_etiquettes")
	desk.open_app("roadmap")
	await desk.view_controller().settled
	await get_tree().create_timer(0.2).timeout
	var app = desk.workstation().hosted_app()
	app._on_ticket_dropped(app.backlog_controls[0]["item"]["id"])
	check(not SprintState.get_desk_activity()["saved"], "Un brouillon ne se présente pas comme enregistré.")
	var wallet := SprintState.impact_wallet
	app._on_next_pressed()
	await get_tree().create_timer(0.3).timeout
	var activity := SprintState.get_desk_activity()
	check(activity["saved"] and activity["tickets"] == 1, "Le lanceur reprend le rapport enregistré.")
	check(SprintState.impact_wallet == wallet, "Enregistrer n'annonce aucun gain d'Impact fictif.")
	check("Plan enregistré" in desk.workstation()._app_status("roadmap")["text"], "L'accueil indique le plan enregistré.")
	await shot("02_accueil_enregistre")
	var energy_before := SprintState.energy
	var offer := SprintState.get_backlog_offer()
	SprintState.do_feature_dive(offer["items"][-1]["id"])
	await get_tree().create_timer(0.3).timeout
	check(SprintState.energy < energy_before and feed.shown_changes > 0, "La dépense réelle d'énergie produit un retour HUD.")
	var shown: int = feed.shown_changes
	desk.refresh()
	desk.refresh()
	check(feed.shown_changes == shown, "Rafraîchir ne rejoue pas la même variation.")
	await shot("03_variation_energie")
	await get_tree().create_timer(2.9).timeout
	check(feed.get_child_count() == 0, "Les retours disparaissent sans encombrer le HUD.")
	desk._close_focused_object()
	await desk.view_controller().settled
	await get_tree().create_timer(0.2).timeout
	await shot("04_bureau_enregistre")
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 900)
	await get_tree().create_timer(0.3).timeout
	await shot("05_etiquettes_1280")
	var closing: Button = desk.readable_layer().get_node("Hint_closing")
	var committee: Button = desk.readable_layer().get_node("Hint_committee")
	check(not closing.get_global_rect().intersects(committee.get_global_rect()), "Les étiquettes de droite ne se chevauchent pas en 1280×900.")
	var badge: Button = desk.readable_layer().get_node("Hint_shop")
	check(badge.visible and badge.mouse_filter == Control.MOUSE_FILTER_STOP, "L'étiquette Boutique est visible et cliquable.")
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = badge.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().process_frame
	await desk.view_controller().settled
	check(desk.prop("shop").is_open(), "L'étiquette ouvre le même objet Boutique.")
	print("=== HUD ACTIVITÉ : %s ===" % ("OK" if failures == 0 else "ÉCHEC"))
	get_tree().quit(0 if failures == 0 else 1)

func shot(label: String) -> void:
	var directory := OS.get_environment("SHOT_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	# Ne pas laisser le curseur physique du poste de recette masquer le sujet.
	var desk := get_tree().root.find_child("DeskScreen", true, false)
	if desk != null:
		desk.readable_layer().get_node("PaperTooltip").visible = false
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(label + ".png"))
