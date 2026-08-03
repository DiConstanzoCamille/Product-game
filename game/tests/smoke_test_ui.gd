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


var failures: int = 0


func _ready() -> void:
	print("=== SMOKE TEST UI ===")
	_test_ui_scale_settings()
	SprintState.reset_run()
	SprintState.activated_cards.append("notion")
	SprintState.activated_card_sprints["notion"] = 1

	for path in SCREENS:
		await _instantiate_and_free(path)

	await _test_roadmap_interactions()
	await _test_investments_interactions()
	await _test_resolution_replay()
	await _test_resolution_multi_team_replay()
	await _test_quarter_result_uses_global_sprint()
	await _test_quota_sidebar_and_freezes()
	await _test_t4_mandate_choice()
	await _test_committee_screen_interactions()
	await _test_compendium_tab()

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


func _test_ui_scale_settings() -> void:
	var viewport := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	)
	var window := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/window_width_override", 0)),
		int(ProjectSettings.get_setting("display/window/size/window_height_override", 0))
	)
	if viewport != Vector2i(1600, 900) or window != Vector2i(1920, 1080):
		_fail("L'UI doit etre rendue de 1600x900 vers une fenetre 1920x1080.")
	if ProjectSettings.get_setting("display/window/stretch/mode", "") != "canvas_items":
		_fail("Le mode canvas_items doit garder l'interface lisible au redimensionnement.")


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
				var select: Button = candidate_control["select"]
				select.pressed.emit()
				await get_tree().process_frame
				if screen._current_plan().is_empty():
					_fail("Le bouton Ajouter au sprint ne produit aucun plan.")
				break

		# Le geste secondaire offre le meme resultat : deposer un ticket planifie
		# le place dans la colonne « Ce sprint » sans contourner les regles.
		for candidate_control in screen.backlog_controls:
			if candidate_control.has("select"):
				screen._on_ticket_dropped(candidate_control["item"].get("id", ""))
				await get_tree().process_frame
				var ticket: Control = candidate_control["ticket"]
				if ticket.get_parent() != screen.sprint_list:
					_fail("Le depot d'un ticket ne le place pas dans la colonne Ce sprint.")
				break

		# Le ticket reste consultable depuis le board : ses détails ne doivent pas
		# être réservés à une carte séparée ou à une information cachée.
		if not screen.backlog_controls.is_empty():
			var open_button: Button = screen.backlog_controls[0]["open"]
			open_button.pressed.emit()
			await get_tree().process_frame
			if screen.ticket_dialog == null or not screen.ticket_dialog.visible:
				_fail("Le bouton Ouvrir de la Roadmap n'affiche pas le dossier ticket.")

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
	SprintState.impact_wallet = 300

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
	SprintState.activated_cards.append_array(["socle-technique-commun", "notion"])
	SprintState.activated_card_sprints["socle-technique-commun"] = 1
	SprintState.activated_card_sprints["notion"] = 1
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
		if float(SprintState.last_score_report.get("global", {}).get("lever_multiplier", 1.0)) <= 1.0:
			_fail("Le rapport UI doit conserver la couche multiplicative du Socle technique.")
		var has_multiplier_event := false
		var multiplier_is_visible := false
		for event in screen._score_events:
			if "Socle technique commun" in str(event.get("detail", "")) and "×" in str(event.get("detail", "")):
				has_multiplier_event = true
			if "Socle technique commun" in str(event.get("display", "")) and "×" in str(event.get("display", "")):
				multiplier_is_visible = true
		if not has_multiplier_event:
			_fail("La Resolution doit rejouer les multiplicateurs comme une etape visible.")
		if not multiplier_is_visible:
			_fail("Le multiplicateur principal ne doit pas etre masque derriere « +N autres ».")
		var panel: Control = load("res://scenes/components/side_panel.tscn").instantiate()
		viewport.add_child(panel)
		await get_tree().process_frame
		if panel.find_child("LeverChain", true, false) == null:
			_fail("Le panneau lateral doit afficher en permanence la chaine de Levier.")
		panel.queue_free()
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
	if divider_indexes.is_empty() or divider_indexes[0] != 0:
		_fail("La lecture multi-equipe doit commencer par une section de choix lisible.")
	screen._reveal_score_replay()
	for child in screen.score_lines.get_children():
		if child is Label and child.visible and "squad" in child.text.to_lower():
			_fail("Les separateurs multi-equipe ne doivent pas exposer le terme technique squad.")

	screen.queue_free()
	viewport.queue_free()
	await get_tree().process_frame


## `quarter_result.sprint` est le sprint global de cloture, pas le numero de
## sprint dans le trimestre. Le verdict de T2 se produit donc bien au sprint 6
## et ne doit pas disparaitre a cause d'une confusion entre ces deux horloges.
func _test_quarter_result_uses_global_sprint() -> void:
	print("  → verdict trimestriel au sprint global 6")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.sprint_number = 6
	SprintState.quarter_index = 2
	SprintState.quarter_sprint = 3
	SprintState.quarter_exit_choice_pending = true  # evite une nouvelle resolution runtime dans _ready
	SprintState.quarter_result = {
		"sprint": 6,
		"quarter": 2,
		"quota": 270,
		"impact": 302,
		"length": 2,
		"passed": true,
		"qualitativeBonus": 8,
		"objectives": [],
		"requirementIds": [],
	}

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child(viewport)
	var screen: Control = load("res://scenes/screens/resolution_screen.tscn").instantiate()
	viewport.add_child(screen)
	for i in 3:
		await get_tree().process_frame
	screen._reveal_score_replay()
	for i in 3:
		await get_tree().process_frame
	if int(screen._quota_data.get("sprint", -1)) != 6:
		_fail("Le verdict T2 doit conserver son sprint global de cloture (6).")
	if int(screen._quota_data.get("length", -1)) != 2:
		_fail("Le verdict d'un trimestre court doit conserver sa longueur cloturee.")
	if screen.find_child("QuarterVerdictOverlay", true, false) == null:
		_fail("Le verdict T2 au sprint global 6 doit ouvrir son overlay trimestriel.")

	screen.queue_free()
	viewport.queue_free()
	await get_tree().process_frame

	# Au sprint suivant, le resultat conserve est historique : la Resolution
	# doit afficher le progres du trimestre en cours, pas rejouer ce verdict.
	SprintState.sprint_number = 7
	SprintState.quarter_index = 3
	SprintState.quarter_sprint = 1
	SprintState.impact_wallet = 45
	SprintState.quarter_exit_choice_pending = true
	var current_viewport := SubViewport.new()
	current_viewport.size = Vector2i(1600, 900)
	add_child(current_viewport)
	var current_screen: Control = load("res://scenes/screens/resolution_screen.tscn").instantiate()
	current_viewport.add_child(current_screen)
	for i in 3:
		await get_tree().process_frame
	if int(current_screen._quota_data.get("quarter", -1)) != 3:
		_fail("Un ancien quarter_result ne doit pas etre reutilise au sprint suivant.")
	if current_screen._quota_data.has("passed"):
		_fail("Le progres d'un trimestre ouvert ne doit pas declencher de verdict.")
	current_screen.queue_free()
	current_viewport.queue_free()
	await get_tree().process_frame


func _test_quota_sidebar_and_freezes() -> void:
	print("  → panneau quota et gels d'investissement")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.quarter_requirement_ids = ["hiring-freeze", "tool-freeze"]
	SprintState.quarter_requirement_id = "tool-freeze"

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child(viewport)
	var screen: Control = load("res://scenes/screens/investments_screen.tscn").instantiate()
	viewport.add_child(screen)
	for i in 4:
		await get_tree().process_frame
	if screen.side_panel.find_child("QuotaSection", true, false) == null:
		_fail("Le panneau latéral doit afficher en permanence la section de quota.")

	var candidate: Dictionary = GameData.candidates[0]
	var candidate_view: Dictionary = AssetView.for_candidate(candidate)
	if not bool(candidate_view.get("primary", {}).get("disabled", false)):
		_fail("Un gel des embauches doit desactiver la carte candidat avant le clic.")
	if "gel" not in str(candidate_view.get("primary", {}).get("text", "")).to_lower():
		_fail("La carte candidat gelee doit expliquer la raison du refus.")

	var tool_card: Dictionary = {}
	for card in GameData.cards.get("cards", []):
		if card.get("family", "") == "outil-process":
			tool_card = card
			break
	var tool_view: Dictionary = AssetView.for_decision(tool_card)
	if not bool(tool_view.get("primary", {}).get("disabled", false)):
		_fail("Un gel des outils doit desactiver la carte decision avant le clic.")
	if "outillage" not in str(tool_view.get("primary", {}).get("text", "")).to_lower():
		_fail("La carte outil gelee doit expliquer la raison du refus.")

	var practice_view: Dictionary = AssetView.for_practice(GameData.practices[0])
	if "gele" in str(practice_view.get("primary", {}).get("text", "")).to_lower():
		_fail("Le gel des outils ne doit pas empecher l'achat des pratiques.")

	screen.queue_free()
	viewport.queue_free()
	await get_tree().process_frame


func _test_t4_mandate_choice() -> void:
	print("  → choix T4 sortie ou mandat long")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.sprint_number = 12
	SprintState.quarter_index = 4
	SprintState.quarter_sprint = 3
	SprintState.quarter_exit_choice_pending = true
	SprintState.quarter_result = {
		"sprint": 12,
		"quarter": 4,
		"quota": 1050,
		"impact": 1180,
		"passed": true,
		"qualitativeBonus": 0,
		"objectives": [],
		"requirementIds": [],
	}

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child(viewport)
	var screen: Control = load("res://scenes/screens/resolution_screen.tscn").instantiate()
	viewport.add_child(screen)
	for i in 3:
		await get_tree().process_frame
	screen._reveal_score_replay()
	for i in 3:
		await get_tree().process_frame
	var overlay := screen.find_child("QuarterVerdictOverlay", true, false)
	var exit_button := overlay.find_child("ExitMandateButton", true, false) if overlay != null else null
	var stay_button := overlay.find_child("StayLongMandateButton", true, false) if overlay != null else null
	if exit_button == null or stay_button == null:
		_fail("Le verdict T4 doit proposer les deux chemins de mandat.")
	elif not screen.next_sprint_button.disabled:
		_fail("Le sprint suivant doit rester bloque tant que le choix T4 n'est pas fait.")
	else:
		stay_button.pressed.emit()
		await get_tree().process_frame
		if not SprintState.long_mandate or SprintState.quarter_index != 5:
			_fail("Rester a T4 doit ouvrir le mandat long et preparer T5.")
		if screen.next_sprint_button.disabled:
			_fail("Rester a T4 doit debloquer le sprint suivant.")

	screen.queue_free()
	viewport.queue_free()
	await get_tree().process_frame

	# Le chemin de sortie est isole du clic UI (qui change volontairement de
	# scene) mais verifie le meme contrat que le bouton "Quitter".
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.sprint_number = 12
	SprintState.quarter_index = 4
	SprintState.quarter_exit_choice_pending = true
	var exit_ending: String = SprintState.choose_mandate_path(false)
	if exit_ending not in ["ipo", "rachat"] or not SprintState.is_mandate_over or SprintState.ending_id != exit_ending:
		_fail("Quitter sur la victoire T4 doit conduire a une fin positive et au routage de fin de mandat.")


## Lot 4 : le Comité d'investissement se reconstruit entièrement à chaque
## achat (comme l'étal des Investissements) — le vrai clic est le seul test
## qui attrape le bug "libéré pendant l'émission de son signal" (carnet §21).
func _test_committee_screen_interactions() -> void:
	print("  → gestes de l'écran Comité d'investissement")
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	SprintState.chosen_strategy_ids.clear()
	SprintState.quarter_strategy_chosen = false
	SprintState.impact_wallet = 2000

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child(viewport)
	var screen: Control = load("res://scenes/screens/committee_screen.tscn").instantiate()
	viewport.add_child(screen)
	for i in 3:
		await get_tree().process_frame

	var slots_before := SprintState.tool_slots_purchased
	var open_slot_button := _find_action_button(screen.content, "Ouvrir un slot d'outillage")
	if open_slot_button == null:
		_fail("Le Comité doit afficher un poste 'Ouvrir un slot d'outillage'.")
	else:
		open_slot_button.pressed.emit()
		await get_tree().process_frame
		if SprintState.tool_slots_purchased != slots_before + 1:
			_fail("Cliquer sur 'Ouvrir un slot d'outillage' doit appeler SprintState.buy_tool_slot().")

	var seats_before := SprintState.team_cap_purchased
	var seat_button := _find_action_button(screen.content, "Ouvrir un poste")
	if seat_button == null:
		_fail("Le Comité doit afficher un poste 'Ouvrir un poste'.")
	else:
		seat_button.pressed.emit()
		await get_tree().process_frame
		if SprintState.team_cap_purchased != seats_before + 1:
			_fail("Cliquer sur 'Ouvrir un poste' doit appeler SprintState.buy_team_cap_seat().")

	screen.queue_free()
	viewport.queue_free()
	await get_tree().process_frame


## Cherche, dans le contenu du Comité, la ligne dont le libellé exact
## correspond à `row_title` (structure posée par committee_screen._action_row :
## PanelContainer > HBoxContainer[icone, VBoxContainer[nom, description],
## coût, bouton]) et retourne son bouton d'action.
func _find_action_button(container: Node, row_title: String) -> Button:
	for child in container.get_children():
		if not child is PanelContainer:
			continue
		var row: Node = child.get_child(0) if child.get_child_count() > 0 else null
		if row == null:
			continue
		var has_title := false
		var button: Button = null
		for sub in row.get_children():
			if sub is Button:
				button = sub
			elif sub is VBoxContainer:
				for label in sub.get_children():
					if label is Label and label.text == row_title:
						has_title = true
		if has_title and button != null:
			return button
	return null


## Lot 4 (spec §12.1) : l'onglet Compendium du Dossier entreprise liste tous
## les combos, les non-découverts en ???.
func _test_compendium_tab() -> void:
	print("  → onglet Compendium du Dossier entreprise")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	PlayerProfile.clear_all()

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child(viewport)
	var screen: Control = load("res://scenes/screens/roadmap_screen.tscn").instantiate()
	viewport.add_child(screen)
	for i in 3:
		await get_tree().process_frame

	var dossier: Control = UIHelpers.instantiate_company_dossier(screen)
	var compendium_content: Node = dossier.get_node_or_null("VBox/Tabs/🧩 Compendium/CompendiumContent")
	if compendium_content == null:
		_fail("Le Dossier entreprise doit exposer un onglet Compendium avec son conteneur de contenu.")
	elif compendium_content.get_child_count() == 0:
		_fail("Le Compendium doit afficher au moins un combo, découvert ou non.")

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
