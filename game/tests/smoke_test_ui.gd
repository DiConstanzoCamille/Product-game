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
	_test_embedded_icon_coverage()
	_test_icon_font_matches_manifest()
	SprintState.reset_run()
	SprintState.activated_cards.append("notion")
	SprintState.activated_card_sprints["notion"] = 1

	for path in SCREENS:
		await _instantiate_and_free(path)

	await _test_roadmap_interactions()
	await _test_investments_interactions()
	await _test_team_management_interactions()
	await _test_multiple_team_requests_inbox()
	await _test_resolution_replay()
	await _test_resolution_multi_team_replay()
	await _test_quarter_result_uses_global_sprint()
	await _test_quota_sidebar_and_freezes()
	await _test_t4_mandate_choice()
	await _test_committee_screen_interactions()
	await _test_compendium_tab()
	await _test_desk_reads_as_a_room()
	await _test_desk_hosted_contracts()
	await _test_desk_paper_lift()

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


## Le jeu n'a plus le droit de demander un glyphe au système : les six polices
## importées coupent `allow_system_fallback`. Tout caractère affiché qu'aucune
## d'elles ne sait dessiner devient donc un carré — sur la machine du joueur
## comme dans les captures.
##
## Ce contrôle refuse la liste blanche : elle avait laissé passer ▸ ◂ ○ ● ✗,
## que personne n'avait pensé à déclarer « pictogrammes ». Il prend le problème
## par l'autre bout — **tout** caractère non-ASCII écrit dans une chaîne de
## `game/` ou de `data/` doit être couvert par au moins une police embarquée —
## et ne peut donc plus rater un signe qu'on n'avait pas anticipé.
const EMBEDDED_FONTS := [
	preload("res://assets/fonts/IBMPlexSans-Variable.ttf"),
	preload("res://assets/fonts/SpaceGrotesk-Variable.ttf"),
	preload("res://assets/fonts/IBMPlexMono-Regular.ttf"),
	preload("res://assets/fonts/IBMPlexMono-Medium.ttf"),
	preload("res://assets/fonts/IBMPlexMono-SemiBold.ttf"),
	preload("res://assets/fonts/ProductIcons.ttf"),
]


func _test_embedded_icon_coverage() -> void:
	var missing: Dictionary = {}
	var game_dir := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var data_dir := game_dir.get_base_dir().path_join("data")
	for root in ["res://", data_dir]:
		_scan_displayed_codepoints(root, missing)
	if missing.is_empty():
		return
	var labels: Array = []
	for codepoint in missing.keys():
		labels.append("U+%04X (%s, %s)" % [
			int(codepoint), String.chr(int(codepoint)), missing[codepoint]
		])
	labels.sort()
	_fail("Aucune police embarquée ne dessine : %s" % ", ".join(labels))


## Le manifeste `tools/icons/manifest.json` est la source de l'asset : c'est lui
## qui dit quel tracé Lucide dessine quel caractère. Le binaire, lui, ne se
## relit pas. Si les deux divergent — un caractère ajouté au manifeste sans
## régénérer la police — le jeu affiche un carré que rien d'autre ne signale.
func _test_icon_font_matches_manifest() -> void:
	var repo_dir := ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()
	var manifest_path := repo_dir.path_join("tools/icons/manifest.json")
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		_fail("Le manifeste des icônes est introuvable : %s" % manifest_path)
		return
	var manifest: Variant = JSON.parse_string(file.get_as_text())
	if typeof(manifest) != TYPE_DICTIONARY or not manifest.has("glyphs"):
		_fail("Le manifeste des icônes est illisible : %s" % manifest_path)
		return
	var absents: Array = []
	for entry in manifest["glyphs"]:
		var codepoint := int(String(entry.get("codepoint", "U+0")).substr(2).hex_to_int())
		if not UIHelpers.FONT_PRODUCT_ICONS.has_char(codepoint):
			absents.append("U+%04X" % codepoint)
	if not absents.is_empty():
		_fail("ProductIcons.ttf ne suit plus son manifeste (%s) — régénérer avec tools/icons/build_product_icons.py" % ", ".join(absents))


func _scan_displayed_codepoints(directory: String, missing: Dictionary) -> void:
	for child in DirAccess.get_directories_at(directory):
		if child.begins_with("."):
			continue
		_scan_displayed_codepoints(directory.path_join(child), missing)
	for file_name in DirAccess.get_files_at(directory):
		var extension := file_name.get_extension()
		if not extension in ["gd", "tscn", "json"]:
			continue
		var path := directory.path_join(file_name)
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		for codepoint in _string_literal_codepoints(file.get_as_text(), extension == "gd"):
			if _is_drawable(int(codepoint)):
				continue
			if not missing.has(codepoint):
				missing[codepoint] = path.get_file()


## Seul le contenu des chaînes finit à l'écran. Les commentaires, eux, ont le
## droit d'employer des caractères que les polices ignorent (les ① ② ③ qui
## découpent les zones d'une carte, les filets ─ des séparateurs) : les scanner
## produirait un échec pour du texte que personne ne verra jamais.
func _string_literal_codepoints(text: String, has_hash_comments: bool) -> Array:
	var codepoints: Array = []
	var quote := 0
	var index := 0
	while index < text.length():
		var codepoint := text.unicode_at(index)
		if quote == 0:
			if has_hash_comments and codepoint == 0x23:  # '#'
				while index < text.length() and text.unicode_at(index) != 0x0A:
					index += 1
			elif codepoint == 0x22 or codepoint == 0x27:  # '"' ou "'"
				quote = codepoint
		elif codepoint == 0x5C:  # '\' : l'échappement neutralise le caractère suivant
			index += 1
		elif codepoint == quote or codepoint == 0x0A:
			quote = 0
		elif codepoint >= 0x80:
			codepoints.append(codepoint)
		index += 1
	return codepoints


func _is_drawable(codepoint: int) -> bool:
	for font in EMBEDDED_FONTS:
		if font.has_char(codepoint):
			return true
	return false


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

	screen.queue_free()
	viewport.queue_free()
	await get_tree().process_frame


## Ouvre le vrai hub d'équipe depuis le trombinoscope levé — son entrée vivait
## dans le Panneau de bord permanent jusqu'à #59 — puis vérifie les quatre
## diagnostics et joue une augmentation depuis la fiche d'une personne.
func _test_team_management_interactions() -> void:
	print("  → gestion d'équipe de bout en bout")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	var employee: Dictionary = SprintState.get_roster()[0]
	SprintState.employee_wellbeing(employee)["salaire"] = 20
	SprintState._refresh_team_moral()

	var desk := await _open_desk()
	desk.lift_paper("team")
	for i in 3:
		await get_tree().process_frame

	var open_button: Button = desk.readable_layer().find_child("OpenTeamManagement", true, false)
	if open_button == null:
		_fail("Le trombinoscope levé n'expose pas l'entrée de la fiche complète.")
	else:
		open_button.pressed.emit()
		for i in 4:
			await get_tree().process_frame
		var dialog: Control = desk.readable_layer().find_child("TeamManagementDialog", true, false)
		if dialog == null:
			_fail("Le bouton de fiche complète n'ouvre pas le hub dédié.")
		else:
			for criterion in ["moral", "confiance", "energie", "salaire"]:
				if dialog.find_child("Wellbeing_%s" % criterion, true, false) == null:
					_fail("La fiche d'équipe n'affiche pas la jauge '%s'." % criterion)
			var salary_before := int(employee.get("salary", 0))
			var salary_action: Button = dialog.find_child("SalaryRaiseAction", true, false)
			if salary_action == null or salary_action.disabled:
				_fail("L'augmentation salariale doit être une action jouable depuis la fiche.")
			else:
				salary_action.pressed.emit()
				for i in 3:
					await get_tree().process_frame
				if int(employee.get("salary", 0)) != salary_before + 1:
					_fail("Le bouton d'augmentation n'a pas modifié la charge salariale récurrente.")
				if int(SprintState.employee_wellbeing(employee).get("salaire", 0)) <= 20:
					_fail("L'augmentation n'a pas restauré la satisfaction salariale.")

	desk.queue_free()
	await get_tree().process_frame


## Une Inbox ne doit pas sacrifier la deuxième alerte au premier choix : le
## bouton Suivant recharge la conversation suivante avant la Roadmap.
func _test_multiple_team_requests_inbox() -> void:
	print("  → demandes d'équipe successives dans l'Inbox")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.employee_wellbeing(SprintState.get_roster()[0])["salaire"] = 20
	SprintState.employee_wellbeing(SprintState.get_roster()[1])["energie"] = 18
	SprintState._inspect_team_crises()

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child(viewport)
	var screen: Control = load("res://scenes/screens/inbox_screen.tscn").instantiate()
	viewport.add_child(screen)
	for i in 6:
		await get_tree().process_frame
	var first_event_id := String(screen.event.get("id", ""))
	if screen.choice_buttons.is_empty():
		_fail("La première demande d'équipe n'affiche aucun arbitrage dans l'Inbox.")
	else:
		screen.choice_buttons[0].pressed.emit()
		await get_tree().process_frame
		if not String(screen.next_button.text).begins_with("Traiter la demande suivante"):
			_fail("Après une première alerte, l'Inbox ne signale pas la demande suivante.")
		screen.next_button.pressed.emit()
		for i in 3:
			await get_tree().process_frame
		if String(screen.event.get("id", "")) == first_event_id or screen.choice_buttons.is_empty():
			_fail("Le bouton suivant n'a pas chargé la deuxième demande d'équipe.")

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
		# La chaîne de Levier a quitté le Panneau de bord avec #59 : elle vit
		# désormais sous le poster « Objectif » du bureau, et c'est
		# `_test_desk_paper_lift()` qui la vérifie.
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
	print("  → gels d'investissement")
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


func _labels_of(node: Node) -> Array:
	var labels: Array = []
	for child in node.get_children():
		if child is Label:
			labels.append(child)
		labels.append_array(_labels_of(child))
	return labels


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


## Le bureau n'avait **aucune** assertion au Lot A : les trois règles qui le
## définissent tenaient sur la bonne volonté du relecteur (#59). Les voici
## mécanisées, plus la seule qui protège le critère de recette n°1.
func _test_desk_reads_as_a_room() -> void:
	print("  → le bureau se lit comme une pièce")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.committee_pending = false

	var desk := await _open_desk()

	# ① Trois valeurs permanentes, et pas une de plus. C'est TOUT le lot A :
	# quinze valeurs à surveiller en permanence sont devenues trois plus une
	# remontée par exception.
	var vitals: Node = desk.readable_layer().get_node_or_null("Vitals")
	if vitals == null:
		_fail("Le bureau doit porter sa zone de valeurs permanentes.")
	else:
		var permanent := 0
		for node in _descendants_of(vitals):
			if String(node.name).begins_with("Vital_"):
				permanent += 1
		if permanent > 3:
			_fail("Le bureau affiche %d valeurs permanentes : la règle est trois au maximum." % permanent)
		if permanent == 0:
			_fail("Le bureau n'affiche aucune valeur permanente — le compteur ne compte rien.")

	# ② Le parapheur n'existe pas hors franchissement de trimestre. Objet
	# absent, pas objet grisé : c'est ce qui fait qu'un sprint sur trois ne
	# ressemble pas aux deux autres.
	var folder: Node3D = desk.prop("committee")
	if folder == null:
		_fail("Le bureau doit porter le parapheur du Comité.")
	else:
		if folder.visible:
			_fail("Hors fin de trimestre, le parapheur ne doit pas être posé sur la table.")
		SprintState.committee_pending = true
		desk.refresh()
		if not folder.visible:
			_fail("Au franchissement d'un trimestre, le parapheur doit être déposé sur la table.")
		SprintState.committee_pending = false
		desk.refresh()

	# ③ Aucun élément ne prend la largeur ni la hauteur entière : une barre
	# pleine fait interface web sur une scène de jeu.
	_check_nothing_spans_the_frame(desk, "au repos")

	# ④ Le critère de recette n°1, mécanisé. La dalle est un `SubViewport` :
	# si sa taille en pixels et sa taille projetée divergent, tout le contenu
	# des phases est rendu à l'échelle — c'est-à-dire flou — et **aucun autre
	# test ne le dirait**. C'est le garde-fou que la relecture ne sait pas
	# faire et qu'une capture ne prouve qu'à l'œil.
	var projected: Vector2 = desk.room().dalle_projected_size()
	var declared := Vector2(DeskRoom.SCREEN_PIXELS)
	var drift: float = maxf(absf(projected.x - declared.x) / declared.x,
		absf(projected.y - declared.y) / declared.y)
	if drift > 0.06:
		_fail("La dalle est rendue à %.0f×%.0f px pour un SubViewport de %.0f×%.0f (%.0f %% d'écart) : le texte des phases est redimensionné." % [
			projected.x, projected.y, declared.x, declared.y, drift * 100.0])

	# ⑤ Garde-fou de vision n°8 : à N=1, le mot « squad » ne doit apparaître
	# nulle part — y compris dans ce qui est peint sur les papiers du mur.
	for label in _labels_of(desk):
		if "squad" in String(label.text).to_lower():
			_fail("Le mot « squad » apparaît sur le bureau en mode une équipe : « %s »." % label.text)

	desk.queue_free()
	await get_tree().process_frame


## Régressions de l'intégration 3D : une phase hébergée doit conserver son
## action métier, solder le badge courrier et rafraîchir le bureau en direct.
func _test_desk_hosted_contracts() -> void:
	print("  → les apps hébergées conservent leurs contrats")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.pending_team_crises.clear()
	SprintState.pending_team_concerns.clear()
	var desk := await _open_desk()

	desk.open_app("inbox")
	for i in 3:
		await get_tree().process_frame
	var workstation: Control = desk.workstation()
	var inbox: Control = workstation.hosted_app()
	if inbox == null:
		_fail("Le courrier doit s'ouvrir dans le poste de travail.")
	else:
		if inbox.get_node("Margin/VBox/TopBar").visible:
			_fail("L'application hébergée ne doit pas redessiner une barre Retour dans le laptop.")
		var event: Dictionary = inbox.event
		var choices: Array = event.get("choices", [])
		if choices.is_empty():
			_fail("Le courrier du sprint doit proposer au moins une réponse.")
		else:
			inbox._on_choice_pressed(choices[0])
			if SprintState.pending_inbox_count() != 0:
				_fail("Répondre au courrier doit solder immédiatement le badge de messagerie.")
			inbox._on_next_pressed()
			await get_tree().process_frame
			if workstation.hosted_app() != null:
				_fail("Terminer le courrier hébergé doit revenir au bureau.")
			desk.open_app("inbox")
			await get_tree().process_frame
			var reopened: Control = workstation.hosted_app()
			if reopened == null or not reopened.choice_buttons.is_empty():
				_fail("Rouvrir le courrier traité doit montrer la réponse, sans reproposer le choix.")

	workstation.close_app()
	desk.open_app("roadmap")
	for i in 3:
		await get_tree().process_frame
	var roadmap: Control = workstation.hosted_app()
	if roadmap == null:
		_fail("La Roadmap doit s'ouvrir dans le poste de travail.")
	else:
		if roadmap.backlog_controls.is_empty():
			_fail("La Roadmap hébergée doit afficher ses tickets.")
		else:
			var first_ticket: Control = roadmap.backlog_controls[0]["ticket"]
			if first_ticket.custom_minimum_size.y > 100.0:
				_fail("Un ticket Roadmap hébergé doit rester compact pour en montrer plusieurs.")
		if roadmap.get_node("Margin/VBox/Board/BacklogPanel/Margin/VBox/Subtitle").visible:
			_fail("Le sous-titre redondant du Backlog doit disparaître dans le laptop.")
		roadmap._on_next_pressed()
		await get_tree().process_frame
		if SprintState.last_roadmap_report.is_empty():
			_fail("Le bouton Terminé de la Roadmap hébergée doit valider le plan.")
		if workstation.hosted_app() != null:
			_fail("La Roadmap ne doit se fermer qu'après validation du plan.")

	# Échap appartient au chrome du laptop, pas à l'application.
	desk.open_app("inbox")
	await get_tree().process_frame
	desk._unhandled_input(_escape_event())
	await get_tree().process_frame
	if workstation.hosted_app() != null:
		_fail("Échap doit fermer l'application du laptop et revenir à son lanceur.")

	# Une mutation économique dans un accessoire hébergé remonte jusqu'aux
	# trois valeurs du bureau, sans exiger de le reposer.
	var refreshed := [0]
	var shop: Node3D = desk.prop("shop")
	var shop_rest_position: Vector3 = shop.position
	shop._set_hovered(true, false)
	if not shop.is_hovered() or shop.position == shop_rest_position:
		_fail("Survoler un accessoire 3D doit produire un retour visuel sans clic.")
	shop._set_hovered(false, false)
	if shop.position != shop_rest_position:
		_fail("Quitter un accessoire 3D doit le remettre exactement à sa place.")
	shop.state_changed.connect(func(): refreshed[0] += 1)
	desk.open_prop("shop")
	for i in 3:
		await get_tree().process_frame
	var investments: Control = shop.hosted_screen()
	if investments != null:
		investments._refresh_all()
	if refreshed[0] == 0:
		_fail("Une mutation hébergée doit demander le rafraîchissement immédiat du bureau.")

	# La sortie vit dans le CanvasLayer du bureau. La texture de l'accessoire
	# ne doit porter ni bouton Reposer ni navigation héritée.
	var global_close: Button = desk.readable_layer().get_node_or_null("PropClose")
	if global_close == null or not global_close.visible:
		_fail("Un accessoire ouvert doit exposer une commande Reposer hors de sa texture.")
	if shop.find_child("RestButton", true, false) != null:
		_fail("Le bouton Reposer ne doit plus être peint dans le SubViewport de l'accessoire.")
	if investments != null:
		if investments.get_node("Margin/VBox/TopBar").visible:
			_fail("La Boutique hébergée ne doit pas afficher sa navigation Accueil historique.")
		if investments.next_button.visible:
			_fail("La Boutique hébergée ne doit pas afficher le bouton de tunnel Suivant.")

	# Un clic dans l'accessoire est réclamé par lui et ne le repose pas ; un
	# clic réellement extérieur, à la frame suivante, le fait.
	desk._on_prop_interacted()
	desk._unhandled_input(_left_click_event())
	await get_tree().process_frame
	if not shop.is_open():
		_fail("Un clic dans le contenu d'un accessoire ne doit pas le fermer.")
	await get_tree().process_frame
	desk._unhandled_input(_left_click_event())
	await get_tree().process_frame
	if shop.is_open():
		_fail("Un clic extérieur doit reposer l'accessoire ouvert.")

	# Le même contrat est garanti au clavier.
	desk.open_prop("shop")
	await get_tree().process_frame
	desk._unhandled_input(_escape_event())
	await get_tree().process_frame
	if shop.is_open():
		_fail("Échap doit reposer l'accessoire ouvert.")

	SprintState.committee_pending = true
	desk.refresh()
	var committee: Node3D = desk.prop("committee")
	desk.open_prop("committee")
	for i in 3:
		await get_tree().process_frame
	var committee_screen: Control = committee.hosted_screen()
	if committee_screen == null:
		_fail("Le Comité doit s'ouvrir dans son accessoire.")
	else:
		if committee_screen.get_node("Margin/VBox/TopBar").visible:
			_fail("Le Comité hébergé ne doit pas afficher sa navigation Accueil historique.")
		if committee_screen.continue_button.is_visible_in_tree():
			_fail("Le Comité hébergé ne doit pas afficher le bouton de tunnel Continuer.")
	if desk.readable_layer().get_node("PropClose").get_parent() != desk.readable_layer():
		_fail("La commande Reposer doit appartenir au CanvasLayer du bureau.")
	desk._unhandled_input(_escape_event())
	await get_tree().process_frame
	if committee.is_open():
		_fail("Échap doit reposer le Comité.")

	desk.queue_free()
	await get_tree().process_frame


## La levée du poster (#59, spec §3) : le geste doit donner le détail SANS
## cacher ce qui permet de décider. C'est le point de vigilance écrit dans la
## spec, et c'est celui qu'une capture ne prouve pas.
func _test_desk_paper_lift() -> void:
	print("  → la levée d'un poster du mur")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	var desk := await _open_desk()

	desk.lift_paper("team")
	for i in 3:
		await get_tree().process_frame
	if desk.lifted_paper() == null:
		_fail("Cliquer un papier du mur doit lever le poster.")
	var detail: Control = desk.readable_layer().get_node_or_null("PaperDetail")
	if detail == null or not detail.visible:
		_fail("Le poster levé doit découvrir son détail à plat, en 2D.")
	else:
		# Les quatre critères par personne : c'est ce que le survol refuse de
		# montrer, et donc précisément ce que la levée doit apporter.
		var employee: Dictionary = SprintState.get_roster()[0]
		if detail.find_child("PersonCard_%s" % employee.get("id", ""), true, false) == null:
			_fail("Le trombinoscope levé doit porter la fiche de chaque personne.")
		var read := ""
		for label in _labels_of(detail):
			read += String(label.text).to_lower() + " "
		for criterion in SprintState.get_individual_team_conf().get("criteria", []):
			if String(criterion).to_lower() not in read:
				_fail("Le trombinoscope levé doit afficher le critère « %s »." % criterion)
		if detail.find_child("SalaryRaiseAction", true, false) == null:
			_fail("Le trombinoscope levé doit porter les actions jouables sur une personne.")

	# Le bandeau et les alertes restent visibles par-dessus : aucune décision
	# ne doit se prendre à l'aveugle pendant qu'un poster est levé.
	var vitals: Control = desk.readable_layer().get_node_or_null("Vitals")
	if vitals == null or not vitals.visible:
		_fail("Les valeurs permanentes doivent rester visibles sous un poster levé.")
	_check_nothing_spans_the_frame(desk, "poster levé")

	# Annulation rapide : Échap referme, et rien ne reste levé.
	desk._unhandled_input(_escape_event())
	for i in 3:
		await get_tree().process_frame
	if desk.lifted_paper() != null or detail.visible:
		_fail("Échap doit reposer la feuille immédiatement.")

	# Le poster « Objectif » a hérité de ce que portait le Panneau de bord
	# supprimé : les quatre objectifs du mandat, et la chaîne de Levier.
	desk.lift_paper("goal")
	for i in 3:
		await get_tree().process_frame
	var goal_detail: Control = desk.readable_layer().get_node_or_null("PaperDetail")
	var mandate: Node = goal_detail.find_child("MandateLine", true, false) if goal_detail != null else null
	if mandate == null:
		_fail("L'objectif levé doit annoncer les objectifs des quatre trimestres dès le premier sprint.")
	else:
		for entry in SprintState.get_mandate_quotas():
			# Le trimestre en cours porte la barre réelle (exigence comprise),
			# les autres leur barème : afficher le barème pour le trimestre
			# courant donnerait deux nombres pour la même échéance.
			var expected: int = SprintState.get_current_quota() if bool(entry.get("current", false)) else int(entry.get("quota", 0))
			if not String(mandate.text).contains(str(expected)):
				_fail("Le mandat est annoncé sans l'objectif du T%d (attendu %d, lu « %s »)." % [
					int(entry.get("quarter", 0)), expected, mandate.text])
	if goal_detail == null or goal_detail.find_child("LeverChain", true, false) == null:
		_fail("L'objectif levé doit porter la chaîne de Levier réellement jouée.")

	desk.queue_free()
	await get_tree().process_frame


func _open_desk() -> DeskScreen:
	var desk: DeskScreen = load("res://scenes/screens/desk_screen.tscn").instantiate()
	get_tree().root.add_child(desk)
	# Le bureau se construit en `call_deferred` — un `add_child()` pendant
	# `_ready()` est rejeté par Godot **sans erreur GDScript**. Attendre une
	# seule trame donnerait un arbre vide et des assertions qui passent.
	for i in 8:
		await get_tree().process_frame
	return desk


func _check_nothing_spans_the_frame(desk: DeskScreen, state: String) -> void:
	for node in _descendants_of(desk.readable_layer()):
		if not (node is Control) or not node.visible:
			continue
		var control: Control = node
		if control.size.x >= 1600.0 or control.size.y >= 900.0:
			_fail("Bureau (%s) : « %s » fait %d×%d et prend le cadre entier — une barre pleine fait interface web sur une scène de jeu." % [
				state, control.name, int(control.size.x), int(control.size.y)])


func _descendants_of(node: Node) -> Array:
	var found: Array = []
	for child in node.get_children():
		found.append(child)
		found.append_array(_descendants_of(child))
	return found


func _escape_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	return event


func _left_click_event() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event


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
