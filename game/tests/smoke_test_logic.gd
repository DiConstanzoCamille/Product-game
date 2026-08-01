extends Node
## Test headless : simule des mandats complets en pilotant SprintState +
## EffectResolver directement (sans UI), pour valider la logique de
## simulation Phase A (roster, pièces, Marché, pression) + Phase B
## (Énergie, actions personnelles, burn-out) et la détection de fin de
## mandat.
##
## Lancer : godot --headless --path game res://tests/smoke_test_logic.tscn
## Sort avec un code non nul si une assertion échoue — en particulier les
## critères de recette : "careful" DOIT perdre (Phase A) et la spirale
## burn-out DOIT rester atteignable par "stress" (Phase B).

## Stratégies simulées :
##  - "stress"  : le·la CPO qui compense tout de sa personne — toutes les
##                features en surchauffe, choix Inbox les plus toxiques
##                pour le Moral, un licenciement par sprint, et "Faire le
##                taf soi-même" tant qu'il reste de l'Énergie. La spirale
##                attendue : Moral effondré → régén nulle → Énergie 0 →
##                burn-out fondateur·rice.
##  - "greedy"  : proche d'un joueur pressé mais pas absurde — remplit la
##                capacité sans la dépasser, achète ~1 item de Marché par
##                sprint, active des grandes décisions, et joue les actions
##                personnelles avec discernement (1:1 avant embauche,
##                rallonge quand le budget est à sec, Souffler quand la
##                jauge est basse).
##  - "careful" : joueur immobile — choix Inbox le moins coûteux, aucune
##                feature livrée, aucune embauche, aucun achat, aucune
##                action personnelle. Depuis la Phase A ("la pression"),
##                ne rien faire DOIT perdre avant la fin du mandat.
const GOOD_ENDINGS := ["ipo", "rachat"]

var failures: int = 0


func _ready() -> void:
	_test_energy_rules()
	_test_multi_squad_roster()
	_test_inbox_channels()
	_test_backlog_rules()
	_test_investment_draw_rules()
	_test_score_resolution_integration()
	_test_tool_families_and_strategy_lot3()
	_test_quarter_runtime()
	_test_committee_lot4()
	_test_support_teams_and_compendium_lot4()

	for strategy in ["stress", "greedy", "careful"]:
		print("\n=== SMOKE TEST LOGIQUE — %s ===" % strategy.to_upper())
		var endings: Array = []
		var run_index := 0
		for company_id in ["meridia-corp", "karavel-scaleup"]:
			for repeat in range(2):
				_play_one_mandate(run_index, strategy, company_id)
				endings.append(SprintState.ending_id)
				run_index += 1

		# Critère de recette Phase B : la spirale burn-out (Moral effondré →
		# régén nulle → Taf soi-même répété → Énergie ≤ 0) doit rester
		# atteignable — "stress" est construite pour la déclencher.
		if strategy == "stress" and not endings.has("burnout-fondateur"):
			_fail("Aucun run stress ne s'est terminé en burn-out (fins : %s) — la spirale Énergie est devenue inatteignable." % [endings])

	if failures > 0:
		print("\n=== SMOKE TEST LOGIQUE : ÉCHEC — %d assertion(s) en erreur ===" % failures)
		get_tree().quit(1)
		return
	print("\n=== SMOKE TEST LOGIQUE : OK ===")
	get_tree().quit()


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
	print("ASSERTION ÉCHOUÉE : %s" % message)


func _test_inbox_channels() -> void:
	for event in GameData.inbox_events:
		if String(event.get("channel", "")).strip_edges() == "":
			_fail("L'événement Inbox '%s' n'a pas de canal." % event.get("id", ""))


func _test_multi_squad_roster() -> void:
	print("=== SMOKE TEST LOGIQUE — ROSTER MULTI-EQUIPE ===")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	var primary: Dictionary = SprintState.get_primary_squad()
	var primary_roster: Array = primary.get("roster", [])
	var primary_count := primary_roster.size()
	for employee in primary_roster:
		if String(employee.get("visible_trait_id", "")) == "":
			_fail("Le trait visible de %s a ete perdu lors de la creation du roster runtime." % employee.get("name", ""))
	var secondary_roster: Array = [{
		"id": "test-squad-secondaire",
		"name": "Test secondaire",
		"role": "dev",
		"seniority": "junior",
		"salary": 1,
		"trait": "",
		"hidden_trait": "",
		"hiddenRevealed": true,
		"hiredSprint": 1,
	}]
	SprintState.squads.append({
		"id": "squad-secondaire",
		"name": "Equipe plateforme",
		"roster": secondary_roster,
		"backlog_draw": {},
		"capacity": 0,
		"delivered": [],
		"epic_progress": {},
	})

	if SprintState.get_roster().size() != primary_count + 1:
		_fail("get_roster() n'agrège pas le roster de la seconde équipe.")
	if SprintState.find_employee("test-squad-secondaire").is_empty():
		_fail("Un employé de la seconde équipe est introuvable.")

	SprintState.pieces = 100
	if SprintState.fire_employee("test-squad-secondaire") != "":
		_fail("Le licenciement de la seconde équipe a été refusé.")
	if primary_roster.size() != primary_count:
		_fail("Le licenciement de la seconde équipe a modifié le roster principal.")
	if not secondary_roster.is_empty() or SprintState.get_roster().size() != primary_count:
		_fail("Le licenciement n'a pas retiré l'employé de son roster propriétaire.")


func _test_backlog_rules() -> void:
	print("=== SMOKE TEST LOGIQUE — BACKLOG PROFOND ===")
	var conf: Dictionary = GameData.balance.get("backlogDraw", {})
	SprintState.reset_run("agile-transformation", "meridia-corp")
	var offer := SprintState.get_backlog_offer()
	var items: Array = offer.get("items", [])
	var minimum := int(conf.get("itemsPerSprintMin", 0))
	var maximum := int(conf.get("itemsPerSprintMax", 0))
	if items.size() < minimum or items.size() > maximum:
		_fail("Le backlog propose %d items au lieu de %d-%d." % [items.size(), minimum, maximum])
	if SprintState.get_backlog_offer() != offer:
		_fail("Le backlog a été re-tiré en revisitant la Roadmap.")

	var feature: Dictionary = GameData.backlog.get("features", [])[0]
	SprintState.current_backlog_draw = {"sprint": SprintState.sprint_number, "items": [feature]}
	if SprintState.backlog_attribute_revealed(feature.get("id", ""), "roi"):
		_fail("Le ROI est révélé sans pratique ni plongée.")
	var energy_before := SprintState.energy
	if SprintState.do_feature_dive(feature.get("id", "")) != "":
		_fail("Plonger dans une feature a été refusé sans raison.")
	if not SprintState.backlog_attribute_revealed(feature.get("id", ""), "risk"):
		_fail("Plonger n'a pas révélé tous les attributs de la feature.")
	if SprintState.energy != energy_before - SprintState.get_personal_action_cost("featureDive"):
		_fail("Plonger n'a pas débité le coût configuré en énergie.")
	var report := SprintState.commit_backlog_plan([{"id": feature.get("id", ""), "points": feature.get("costPoints", 0)}])
	if report.get("delivered", []).size() != 1 or SprintState.recurring_roi != int(feature.get("roi", 0)):
		_fail("La livraison n'a pas appliqué le ROI permanent du backlog.")
	if not SprintState.completed_backlog_ids.has(feature.get("id", "")):
		_fail("Une feature livrée n'a pas quitté le sac du backlog.")
	var roi_after_delivery := SprintState.recurring_roi
	report = SprintState.commit_backlog_plan([{"id": feature.get("id", ""), "points": feature.get("costPoints", 0)}])
	if not report.get("delivered", []).is_empty() or SprintState.recurring_roi != roi_after_delivery:
		_fail("Une feature déjà livrée a pu être encaissée deux fois.")

	SprintState.reset_run("agile-transformation", "meridia-corp")
	var epic: Dictionary = GameData.backlog.get("epics", [])[0]
	SprintState.current_backlog_draw = {"sprint": SprintState.sprint_number, "items": [epic]}
	var first_investment: int = min(3, int(epic.get("costPoints", 0)) - 1)
	report = SprintState.commit_backlog_plan([{"id": epic.get("id", ""), "points": first_investment}])
	if SprintState.get_epic_invested(epic.get("id", "")) != first_investment or not report.get("delivered", []).is_empty():
		_fail("L'epic a livré avant sa complétion ou perdu sa progression.")
	SprintState.sprint_number += 1
	SprintState.current_backlog_draw.clear()
	offer = SprintState.get_backlog_offer()
	items = offer.get("items", [])
	if items.size() > maximum or not _offer_has_item(items, epic.get("id", "")):
		_fail("Un epic actif doit rester dans une offre plafonnée à %d items." % maximum)
	if SprintState.abandon_epic(epic.get("id", "")) != "" or SprintState.get_epic_invested(epic.get("id", "")) != 0:
		_fail("Abandonner un epic doit perdre sa progression sans remboursement.")
	SprintState._backlog_bag.clear()
	SprintState._refill_backlog_bag()
	if not SprintState._backlog_bag.has(epic.get("id", "")):
		_fail("Un epic abandonné n'est plus éligible au retour dans le sac.")
	SprintState.current_backlog_draw = {"sprint": SprintState.sprint_number, "items": [epic]}
	report = SprintState.commit_backlog_plan([{"id": epic.get("id", ""), "points": SprintState.get_epic_remaining(epic.get("id", ""))}])
	if not SprintState.completed_backlog_ids.has(epic.get("id", "")) or report.get("delivered", []).size() != 1:
		_fail("L'epic n'a pas livré ses effets à la complétion.")


## Le rapport de score est la source unique de l'économie : les quick wins
## n'ajoutent plus leur ancien +1 individuel, et le MRR récurrent n'est jamais
## versé deux fois dans la trésorerie.
func _test_score_resolution_integration() -> void:
	print("=== SMOKE TEST LOGIQUE — INTEGRATION SCORE ===")
	SprintState.reset_run("agile-transformation", "meridia-corp")
	# Isole l'economie ScoreResolver du tirage aleatoire d'une exigence.
	SprintState.quarter_requirement_ids = ["hiring-freeze"]
	SprintState.quarter_requirement_id = "hiring-freeze"
	SprintState.quarter_forced_strategy_id = ""
	var quick_wins: Array = []
	for feature in GameData.backlog.get("features", []):
		if bool(feature.get("quickWin", false)):
			quick_wins.append(feature)
			if quick_wins.size() == 2:
				break
	if quick_wins.size() != 2:
		_fail("Le test d'integration a besoin de deux quick wins dans le backlog.")
		return

	SprintState.current_backlog_draw = {"sprint": SprintState.sprint_number, "items": quick_wins}
	var plan: Array = []
	for feature in quick_wins:
		plan.append({"id": feature.get("id", ""), "points": feature.get("costPoints", 0)})
	SprintState.commit_backlog_plan(plan)
	SprintState.add_pending({"pieces": 3}, "Inbox test : budget ponctuel")
	var pieces_before := SprintState.pieces
	var treasury_before := float(SprintState.resource_values.get("tresorerie", 0.0))
	var payroll := SprintState.get_payroll()
	SprintState.apply_pending_and_check()

	var report: Dictionary = SprintState.last_score_report
	var conversion: Dictionary = report.get("conversion", {})
	var budget: Dictionary = conversion.get("budget", {})
	var mrr_report: Dictionary = conversion.get("mrr", {})
	if report.is_empty() or int(report.get("next_streak", 0)) != 1 or SprintState.streak != 1:
		_fail("Un sprint avec livraisons doit produire un rapport et commencer la serie.")
	if int(budget.get("quick_win_bonus", 0)) != 2:
		_fail("Le rapport doit attribuer exactement +2 de budget aux deux quick wins.")
	var expected_pieces := pieces_before + 3 + int(budget.get("gain", 0))
	if SprintState.pieces != expected_pieces or SprintState.last_pieces_delta != expected_pieces - pieces_before:
		_fail("Les quick wins historiques ont ete comptes deux fois dans les pieces (%d au lieu de %d)." % [SprintState.pieces, expected_pieces])
	if int(round(SprintState.mrr)) != SprintState.last_revenue or int(round(float(mrr_report.get("after", 0.0)))) != SprintState.last_revenue:
		_fail("Le revenu applique doit etre exactement le MRR final du rapport.")
	if int(round(float(mrr_report.get("recurring_roi_gain", 0.0)))) != SprintState.last_roi_revenue_bonus:
		_fail("Le bonus recurring_roi du rapport n'est pas expose a l'UI.")
	var expected_treasury: float = clamp(treasury_before - payroll + SprintState.last_revenue, 0.0, 100.0)
	if not is_equal_approx(float(SprintState.resource_values.get("tresorerie", 0.0)), expected_treasury):
		_fail("La tresorerie doit recevoir le MRR une seule fois (%s au lieu de %s)." % [SprintState.resource_values.get("tresorerie", 0.0), expected_treasury])

	SprintState.sprint_number += 1
	SprintState.apply_pending_and_check()
	if int(SprintState.last_score_report.get("next_streak", -1)) != 0 or SprintState.streak != 0:
		_fail("Un sprint vide doit remettre la serie a zero.")
	SprintState.activated_cards = ["sprint-retro"]
	SprintState.activated_card_sprints = {"sprint-retro": 1}
	SprintState.sprint_number = 3
	var snapshot := SprintState._build_score_snapshot()
	var tools: Array = snapshot.get("active_tools", [])
	if tools.is_empty() or tools[0].get("id", "") != "sprint-retro" or int(tools[0].get("active_sprints", 0)) != 3:
		_fail("Le snapshot doit transmettre active_sprints pour les outils cumulatifs.")


## Levier par employé de la ligne de score dont le libellé commence par
## `label_prefix` (ex. "Notion") — 0.0 si l'outil n'a laissé aucune ligne.
func _tool_lever_value(report: Dictionary, label_prefix: String) -> float:
	for line in report.get("global", {}).get("lines", []):
		if line.get("type", "") == "lever_add" and String(line.get("label", "")).begins_with(label_prefix):
			return float(line.get("value", 0.0))
	return 0.0


## Lot 3 : Levier par employé (§7.1), slots d'outillage (§7.1.1/§7.1.2),
## outillage hérité (§7.1.3) et décisions stratégiques (§7.2). Critère de
## recette de l'issue #16 : la MÊME carte Notion doit donner un Levier
## positif chez Karavel et négatif chez Meridia sans qu'aucune ligne du
## moteur ne teste un `company_id` — seul le roster réel change le résultat.
func _test_tool_families_and_strategy_lot3() -> void:
	print("=== SMOKE TEST LOGIQUE — LOT 3 : FAMILLES DE DECISIONS ===")

	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	if not SprintState.activated_cards.has("notion"):
		_fail("Karavel doit hériter de Notion dès reset_run (companies.json → inheritedTools).")
	SprintState.sprint_number = 10
	var karavel_report := ScoreResolver.resolve(SprintState._build_score_snapshot(), {
		"scoring": GameData.scoring, "hidden_traits": GameData.hidden_traits, "cards": GameData.cards,
	})
	var karavel_notion := _tool_lever_value(karavel_report, "Notion")
	if karavel_notion <= 0.0:
		_fail("Notion doit rester un Levier positif chez Karavel, équipe junior (obtenu %s)." % karavel_notion)

	SprintState.reset_run("agile-transformation", "meridia-corp")
	if not SprintState.activated_cards.has("jira"):
		_fail("Meridia doit hériter de Jira dès reset_run.")
	if SprintState.activated_cards.has("notion"):
		_fail("Meridia ne doit pas hériter de Notion.")
	SprintState.activated_cards.append("notion")
	SprintState.activated_card_sprints["notion"] = 1
	SprintState.sprint_number = 10
	var meridia_report := ScoreResolver.resolve(SprintState._build_score_snapshot(), {
		"scoring": GameData.scoring, "hidden_traits": GameData.hidden_traits, "cards": GameData.cards,
	})
	var meridia_notion := _tool_lever_value(meridia_report, "Notion")
	if meridia_notion >= 0.0:
		_fail("Notion doit devenir un Levier négatif chez Meridia, équipe senior ancienne (obtenu %s)." % meridia_notion)

	# Les slots : la base vient du niveau de carrière, +2 achetables à prix croissant.
	SprintState.reset_run("agile-transformation", "meridia-corp")
	if SprintState.get_tool_slot_base() != 3:
		_fail("La base de slots au niveau PM doit être 3 (spec §7.1.1).")
	if SprintState.activated_cards.size() != 1 or SprintState.get_tool_slot_capacity() != 3:
		_fail("Un run de PM démarre avec l'outillage hérité (1 slot pris) sur une base de 3.")
	SprintState.pieces = 100
	if SprintState.buy_tool_slot() != "" or SprintState.get_tool_slot_capacity() != 4:
		_fail("Le premier slot supplémentaire doit coûter 12 💶 et porter la capacité à 4.")
	if SprintState.buy_tool_slot() != "" or SprintState.get_tool_slot_capacity() != 5:
		_fail("Le second slot supplémentaire doit coûter 20 💶 et porter la capacité à 5.")
	if SprintState.buy_tool_slot() != "plafond":
		_fail("Un troisième achat de slot doit être refusé (plafond de +2, spec §7.1.1).")

	# Le coût de bascule (§7.1.2) : Cynisme +4 puis +7, Levier perdu tout de
	# suite, compteur cumulatif remis à zéro, carte de retour dans le pool.
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.activated_cards.append("sprint-retro")
	SprintState.activated_card_sprints["sprint-retro"] = 1
	SprintState.sprint_number = 5
	SprintState.resource_values["cynisme"] = 0.0
	if SprintState.release_tool_slot("sprint-retro") != "":
		_fail("La bascule sur un outil actif doit être acceptée.")
	if SprintState.activated_cards.has("sprint-retro") or SprintState.activated_card_sprints.has("sprint-retro"):
		_fail("Un outil libéré doit quitter activated_cards et perdre son compteur cumulatif.")
	if int(SprintState.pending_deltas.get("cynisme", 0.0)) != 4:
		_fail("La première bascule du mandat doit coûter 4 de Cynisme.")
	SprintState.pending_deltas.clear()
	if SprintState.release_tool_slot("jira") != "":
		_fail("Libérer l'outillage hérité doit être une bascule comme une autre.")
	if int(SprintState.pending_deltas.get("cynisme", 0.0)) != 7:
		_fail("La deuxième bascule du mandat doit coûter 4 + 3 = 7 de Cynisme.")
	if SprintState.swap_count != 2:
		_fail("Le compteur de bascules doit suivre chaque libération de slot.")
	if not GameData.cards.get("cards", []).map(func(c): return c.get("id", "")).has("sprint-retro") \
			or SprintState.activated_cards.has("sprint-retro"):
		_fail("Une carte libérée doit rester dans le catalogue et pouvoir revenir au tirage.")

	# Décisions stratégiques (§7.2) : 1 par trimestre, permanente, jamais
	# mélangée aux outils.
	#
	# Cas à couvrir sans dépendre de la chance : le tirage d'exigence T1 peut
	# légitimement tomber sur board-injunction (1/8 des exigences de
	# quotas.json), qui force une décision dès reset_run() et consomme le
	# trimestre avant qu'on ait rien choisi soi-même — get_strategy_options()
	# renvoie alors un catalogue vide, correctement. Un catalogue vide n'est
	# accepté QUE dans ce cas précis (injonction déjà tranchée) ; toute autre
	# raison reste un échec de test — c'était le bug avant ce lot : le test
	# exigeait un catalogue non vide à 100 %, alors que la spec en autorise
	# 7/8 (voir carnet §29, "le test était faux, pas le moteur").
	SprintState.reset_run("agile-transformation", "meridia-corp")
	var options := SprintState.get_strategy_options(3)
	var first_id: String
	if options.is_empty():
		if not SprintState.quarter_strategy_chosen or SprintState.quarter_forced_strategy_id == "":
			_fail("Un catalogue de décisions stratégiques vide au premier trimestre ne doit venir que d'une injonction du board déjà consommée, jamais d'autre chose.")
		first_id = SprintState.quarter_forced_strategy_id
		if not SprintState.chosen_strategy_ids.has(first_id):
			_fail("Une décision imposée par injonction doit rejoindre chosen_strategy_ids comme un choix volontaire.")
	else:
		first_id = options[0].get("id", "")
		if SprintState.choose_strategy(first_id) != "":
			_fail("Le premier choix stratégique du trimestre doit être accepté.")
		if not SprintState.chosen_strategy_ids.has(first_id) or SprintState.activated_cards.has(first_id):
			_fail("Une décision stratégique doit rejoindre chosen_strategy_ids, jamais activated_cards.")
	if SprintState.choose_strategy(first_id) == "":
		_fail("Une deuxième décision stratégique ne doit pas être acceptée dans le même trimestre.")
	# Simule le passage au trimestre suivant sans dépendre du tirage aléatoire
	# d'exigence (board-injunction en forcerait une seconde et rendrait le test friable).
	SprintState.quarter_strategy_chosen = false
	if not SprintState.chosen_strategy_ids.has(first_id):
		_fail("Une décision stratégique choisie doit rester active au trimestre suivant (irréversible).")
	var expected_remaining: int = GameData.strategy.get("strategies", []).size() - SprintState.chosen_strategy_ids.size()
	if SprintState.get_strategy_options(10).size() != expected_remaining:
		_fail("Le trimestre suivant doit reproposer tout le catalogue sauf ce qui est déjà choisi.")


func _test_quarter_runtime() -> void:
	print("=== SMOKE TEST LOGIQUE — QUOTAS TRIMESTRIELS ===")
	# T1 : le compteur progresse une fois par Resolution et un run qui livre
	# uniquement du travail interne visible par personne est remercie au T3.
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.quarter_requirement_ids = ["visibility-mandate"]
	SprintState.quarter_requirement_id = "visibility-mandate"
	for sprint in range(3):
		SprintState.last_roadmap_report = {
			"sprint": SprintState.sprint_number,
			"plannedPoints": 1,
			"capacity": 1,
			"delivered": [{"id": "internal-%d" % sprint, "name": "Travail interne", "costPoints": 1, "clientImpact": 0, "risk": 0, "quickWin": false, "tags": ["tech"]}],
		}
		var ending := SprintState.apply_pending_and_check()
		if sprint < 2:
			if SprintState.quarter_sprint != sprint + 1 or ending != "":
				_fail("La progression T1 doit rester ouverte apres le sprint %d." % (sprint + 1))
			SprintState.sprint_number += 1
		elif ending != "remercie" or not SprintState.is_mandate_over:
			_fail("Un trimestre de livraisons sans Traction doit mener a 'remercie' au plus tard au T3.")

	# Les exigences runtime modifient les actions et le snapshot, sans UI.
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.quarter_requirement_ids = ["short-quarter"]
	if SprintState.get_quarter_length() != 2 or SprintState.get_current_quota() != 90:
		_fail("Le trimestre court doit valoir 2 sprints et 75 %% du quota T1 (90).")
	SprintState.quarter_requirement_ids = ["finance-watch"]
	var base_payroll := SprintState.get_payroll()
	SprintState._apply_payroll()
	if SprintState.last_payroll != base_payroll * 2:
		_fail("L'exigence masse salariale doit doubler le prelevement.")
	SprintState.pending_deltas.clear()
	SprintState.quarter_requirement_ids = ["hiring-freeze"]
	if SprintState.hire_candidate(GameData.candidates[0]) != "quarter-requirement":
		_fail("Le gel des embauches doit refuser hire_candidate.")
	SprintState.quarter_requirement_ids = ["tool-freeze"]
	if SprintState.activate_decision("rice") != "quarter-requirement":
		_fail("Le gel des outils doit refuser les cartes outil/process.")
	SprintState.quarter_requirement_ids = ["steering-committee"]
	SprintState.pieces = 20
	var practice_id: String = GameData.practices[0].get("id", "")
	SprintState.buy_practice(practice_id)
	if int(SprintState.pending_deltas.get("cynisme", 0.0)) != 4:
		_fail("Le comite de pilotage doit faire monter le Cynisme de 4 par pratique.")
	SprintState.quarter_requirement_ids = ["board-injunction"]
	SprintState._assign_forced_strategy()
	var forced_snapshot := SprintState._build_score_snapshot()
	if SprintState.quarter_forced_strategy_id == "" or not forced_snapshot.get("strategy_ids", []).has(SprintState.quarter_forced_strategy_id) or SprintState.activated_cards.has(SprintState.quarter_forced_strategy_id):
		_fail("L'injonction doit injecter une strategie au score sans activer de carte.")

	# Bonus qualitatif : une seule fois a la revue, en plus du gain ScoreResolver.
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.quarter_requirement_ids = ["hiring-freeze"]
	SprintState.activated_cards = ["rice"]
	for sprint in range(3):
		SprintState.last_roadmap_report = {
			"sprint": SprintState.sprint_number,
			"plannedPoints": 40,
			"capacity": 40,
			"delivered": [{"id": "quota-%d" % sprint, "name": "Livraison quota", "costPoints": 40, "clientImpact": 1, "risk": 0, "quickWin": false, "tags": ["growth"]}],
		}
		SprintState.apply_pending_and_check()
		if sprint < 2:
			SprintState.sprint_number += 1
	if int(SprintState.quarter_result.get("qualitativeBonus", 0)) != 8:
		_fail("Les objectifs qualitatifs tenus doivent accorder exactement 8 pieces une fois.")
	if SprintState.quarter_index != 2 or int(SprintState.quarter_result.get("quarter", 0)) != 1:
		_fail("Le resultat T1 doit rester disponible pendant que T2 est deja prepare.")
	var bonus_delta := int(SprintState.last_score_report.get("conversion", {}).get("budget", {}).get("gain", 0)) + 8
	if SprintState.last_pieces_delta != bonus_delta:
		_fail("Le bonus qualitatif doit etre ajoute une seule fois au dernier flux de pieces.")
	SprintState.sprint_number += 1
	SprintState.last_roadmap_report.clear()
	SprintState.apply_pending_and_check()
	if SprintState.last_pieces_delta != int(SprintState.last_score_report.get("conversion", {}).get("budget", {}).get("gain", 0)):
		_fail("Un sprint hors revue ne doit pas rejouer le bonus qualitatif.")
	var review_entries := 0
	for entry in SprintState.journal:
		if String(entry.get("text", "")).contains("Revue trimestrielle"):
			review_entries += 1
	if review_entries != 1:
		_fail("Le journal ne doit inscrire le bonus qualitatif qu'a sa revue unique.")

	# T4 ne tranche plus seul la fin : rester ouvre T5 avec le quota long.
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.quarter_index = 4
	SprintState.quarter_requirement_ids = ["hiring-freeze"]
	SprintState.quarter_requirement_id = "hiring-freeze"
	SprintState.quarter_sprint = SprintState.get_quarter_length() - 1
	SprintState.quarter_impact = SprintState.get_current_quota()
	SprintState.activated_cards = ["rice"]
	SprintState.last_roadmap_report.clear()
	SprintState.apply_pending_and_check()
	if not SprintState.quarter_exit_choice_pending or SprintState.is_mandate_over or int(SprintState.quarter_result.get("quarter", 0)) != 4:
		_fail("La reussite T4 doit attendre explicitement le choix de mandat.")
	if SprintState.choose_mandate_path(true) != "" or not SprintState.long_mandate or SprintState.quarter_index != 5:
		_fail("Le choix de rester doit ouvrir le mandat long au T5.")
	if int(SprintState.quarter_result.get("quarter", 0)) != 4:
		_fail("Le resultat T4 doit rester lisible apres la preparation du T5.")
	if SprintState.quarter_requirement_ids.size() < 2:
		_fail("Le mandat long doit ajouter une exigence au lieu d'ecraser celle du T4.")
	SprintState.quarter_requirement_ids = ["hiring-freeze", "tool-freeze"]
	if SprintState.get_current_quota() != 2310 or SprintState.quarter_requirement_ids.size() < 2:
		_fail("Le T5 long doit partir a 2310 et conserver les exigences accumulees.")

	# La revue de quota a la priorite sur un seuil fatal : une seule fin est emise.
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.quarter_sprint = 2
	SprintState.quarter_impact = 0
	SprintState.quarter_requirement_ids = ["hiring-freeze"]
	SprintState.resource_values["tresorerie"] = 0.0
	var endings: Array = []
	var on_ending := func(ending_id: String): endings.append(ending_id)
	SprintState.ending_reached.connect(on_ending)
	var quota_ending := SprintState.apply_pending_and_check()
	SprintState.ending_reached.disconnect(on_ending)
	if quota_ending != "remercie" or SprintState.ending_id != "remercie" or endings != ["remercie"]:
		_fail("Un echec de quota concurrent d'un seuil fatal doit emettre une seule fin 'remercie'.")


## Lot 4 (spec scoring §12) : chaque poste du Comité — achat accepté avec
## budget, refus 'pieces' à sec, plafonds des tables de prix. `committee_screen`
## ne fait que lire ces fonctions ; c'est donc ici, pas dans un test UI, que
## la logique doit être couverte.
func _test_committee_lot4() -> void:
	print("=== SMOKE TEST LOGIQUE — LOT 4 : COMITE D'INVESTISSEMENT ===")

	# 🧭 Décision stratégique payante : refus à sec, achat au prix affiché,
	# une seule par trimestre. On neutralise une éventuelle injonction du
	# board tirée à T1 (déjà couverte ailleurs) pour rester déterministe.
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	SprintState.chosen_strategy_ids.clear()
	SprintState.quarter_strategy_chosen = false
	var strategy_options := SprintState.get_strategy_options(3)
	if strategy_options.is_empty():
		_fail("Un trimestre sans décision déjà choisie doit proposer un catalogue non vide.")
	else:
		var strategy_id: String = strategy_options[0].get("id", "")
		SprintState.pieces = 0
		if SprintState.buy_strategy(strategy_id) != "pieces":
			_fail("Sans budget, buy_strategy() doit refuser 'pieces'.")
		SprintState.pieces = 100
		var strategy_cost := SprintState.strategy_purchase_cost()
		if SprintState.buy_strategy(strategy_id) != "":
			_fail("Avec assez de budget, buy_strategy() doit accepter.")
		if SprintState.pieces != 100 - strategy_cost:
			_fail("buy_strategy() doit prélever exactement le coût affiché (%d)." % strategy_cost)
		var second_id: String = strategy_options[1].get("id", "") if strategy_options.size() > 1 else strategy_id
		if SprintState.buy_strategy(second_id) == "":
			_fail("Une deuxième décision stratégique ne doit pas être acceptée au Comité dans le même trimestre.")

	# 🪑 Ouvrir un poste : échelle de prix (investments.json → open-seat),
	# plafond une fois la table épuisée.
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	var base_cap := SprintState.get_team_cap()
	SprintState.pieces = 0
	if SprintState.buy_team_cap_seat() != "pieces":
		_fail("Sans budget, l'ouverture d'un poste doit refuser 'pieces'.")
	SprintState.pieces = 1000
	var seat_costs: Array = SprintState.find_investment_item("open-seat").get("costs", [])
	for i in seat_costs.size():
		if SprintState.buy_team_cap_seat() != "":
			_fail("L'achat du poste n°%d doit être accepté avec assez de budget." % (i + 1))
	if SprintState.get_team_cap() != base_cap + seat_costs.size():
		_fail("Le cap d'effectif doit avoir gagné %d poste(s)." % seat_costs.size())
	if SprintState.buy_team_cap_seat() != "plafond":
		_fail("Au-delà de la table de prix, l'ouverture d'un poste doit refuser 'plafond'.")

	# 📈 Promotion : refus 'introuvable' / 'deja-senior' / 'pieces', effet réel
	# sur la séniorité et le salaire.
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	var junior_id := ""
	for employee in SprintState.get_roster():
		if employee.get("seniority", "junior") == "junior":
			junior_id = employee.get("id", "")
			break
	if junior_id == "":
		_fail("Le roster de départ de Karavel doit compter au moins un junior à promouvoir.")
	SprintState.pieces = 0
	if SprintState.promote_employee(junior_id) != "pieces":
		_fail("Sans budget, promote_employee() doit refuser 'pieces'.")
	SprintState.pieces = 100
	if SprintState.promote_employee(junior_id) != "":
		_fail("Avec budget, promote_employee() doit accepter un junior existant.")
	var promoted := SprintState.find_employee(junior_id)
	var senior_salary := int(GameData.balance.get("salaries", {}).get("senior", 2))
	if promoted.get("seniority", "") != "senior" or int(promoted.get("salary", 0)) != senior_salary:
		_fail("Une promotion doit passer la personne senior et aligner son salaire sur balance.json → salaries.senior.")
	if SprintState.promote_employee(junior_id) != "deja-senior":
		_fail("Promouvoir une personne déjà senior doit être refusé ('deja-senior').")
	if SprintState.promote_employee("introuvable-xyz") != "introuvable":
		_fail("Promouvoir un id inconnu doit être refusé ('introuvable').")

	# 🚀 Palier de produit : échelle de prix, plafond, +1 feature proposée
	# par sprint et par palier (_draw_backlog_offer).
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	SprintState.pieces = 0
	if SprintState.buy_product_tier() != "pieces":
		_fail("Sans budget, le palier de produit doit refuser 'pieces'.")
	SprintState.pieces = 1000
	var tier_costs: Array = SprintState.find_investment_item("product-tier").get("costs", [])
	for i in tier_costs.size():
		if SprintState.buy_product_tier() != "":
			_fail("L'achat du palier n°%d doit être accepté avec assez de budget." % (i + 1))
	if SprintState.product_tier != tier_costs.size():
		_fail("product_tier doit valoir %d après avoir acheté tous les paliers." % tier_costs.size())
	if SprintState.buy_product_tier() != "plafond":
		_fail("Au-delà de la table de prix, le palier de produit doit refuser 'plafond'.")

	# 🏝️ Séminaire d'équipe : Cynisme -15 posé en attente de Résolution.
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	SprintState.pieces = 0
	if SprintState.buy_team_seminar() != "pieces":
		_fail("Sans budget, le séminaire d'équipe doit refuser 'pieces'.")
	SprintState.pieces = 100
	if SprintState.buy_team_seminar() != "":
		_fail("Avec budget, le séminaire d'équipe doit être accepté.")
	if int(SprintState.pending_deltas.get("cynisme", 0.0)) != -15:
		_fail("Le séminaire d'équipe doit poser -15 de Cynisme en attente de Résolution.")

	# 🧹 Sprint de remise à plat : Dette -20 en attente, 0 Traction à la
	# Résolution qui suit — même si le roster livre réellement quelque chose.
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	SprintState.pieces = 100
	if SprintState.buy_cleanup_sprint() != "":
		_fail("Avec budget, le sprint de remise à plat doit être accepté.")
	if int(SprintState.pending_deltas.get("dette-organisationnelle", 0.0)) != -20:
		_fail("Le sprint de remise à plat doit poser -20 de Dette en attente de Résolution.")
	if not SprintState.cleanup_sprint_pending:
		_fail("cleanup_sprint_pending doit rester vrai jusqu'à la prochaine Résolution.")
	var feature: Dictionary = GameData.backlog.get("features", [])[0]
	SprintState.last_roadmap_report = {
		"sprint": SprintState.sprint_number,
		"plannedPoints": int(feature.get("costPoints", 1)),
		"capacity": int(feature.get("costPoints", 1)),
		"delivered": [feature],
	}
	SprintState.apply_pending_and_check()
	if int(SprintState.last_score_report.get("global", {}).get("impact", -1)) != 0:
		_fail("Le sprint de remise à plat doit neutraliser toute Traction, même avec une livraison réelle.")
	if SprintState.cleanup_sprint_pending:
		_fail("cleanup_sprint_pending doit être consommé après la Résolution qui suit l'achat.")

	# 🤝 Rachat d'un concurrent : +12 MRR immédiat, +1 employé immédiat,
	# +8 Dette en attente de Résolution.
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	var roster_before := SprintState.get_roster().size()
	var mrr_before := SprintState.mrr
	SprintState.pieces = 0
	if SprintState.buy_competitor_acquisition() != "pieces":
		_fail("Sans budget, le rachat d'un concurrent doit refuser 'pieces'.")
	SprintState.pieces = 100
	if SprintState.buy_competitor_acquisition() != "":
		_fail("Avec budget, le rachat d'un concurrent doit être accepté.")
	if not is_equal_approx(SprintState.mrr, mrr_before + 12.0):
		_fail("Le rachat d'un concurrent doit ajouter 12 MRR immédiatement (stock, pas un flux).")
	if SprintState.get_roster().size() != roster_before + 1:
		_fail("Le rachat d'un concurrent doit ajouter un employé au roster immédiatement.")
	if int(SprintState.pending_deltas.get("dette-organisationnelle", 0.0)) != 8:
		_fail("Le rachat d'un concurrent doit poser +8 de Dette en attente de Résolution.")

	# 🎯 Chasseur de têtes : le prochain étal force au moins 4 candidats,
	# traits cachés révélés — puis se consomme.
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	SprintState.pieces = 0
	if SprintState.buy_headhunter() != "pieces":
		_fail("Sans budget, le chasseur de têtes doit refuser 'pieces'.")
	SprintState.pieces = 100
	if SprintState.buy_headhunter() != "":
		_fail("Avec budget, le chasseur de têtes doit être accepté.")
	var offer := SprintState.get_shop_offer()
	var forced_candidates: Array = offer.get("candidates", [])
	if forced_candidates.size() < 4:
		_fail("Le chasseur de têtes doit forcer au moins 4 candidats au prochain étal (obtenu %d)." % forced_candidates.size())
	for candidate in forced_candidates:
		if not bool(candidate.get("hiddenRevealed", false)):
			_fail("Le chasseur de têtes doit révéler le trait caché de chaque candidat forcé.")
	if SprintState.headhunter_pending:
		_fail("Le pari du chasseur de têtes doit se consommer dès le premier tirage d'étal.")

	# 🏛️ Plan de redressement : rattrapage automatique d'un quota manqué,
	# consommé une seule fois.
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	SprintState.pieces = 0
	if SprintState.buy_turnaround_plan() != "pieces":
		_fail("Sans budget, le plan de redressement doit refuser 'pieces'.")
	SprintState.pieces = 100
	if SprintState.buy_turnaround_plan() != "":
		_fail("Avec budget, le plan de redressement doit être accepté.")
	SprintState.quarter_sprint = SprintState.get_quarter_length() - 1
	SprintState.quarter_impact = 0
	SprintState.last_score_report = {"global": {"impact": 0}}
	SprintState._record_quarter_resolution()
	if not bool(SprintState.quarter_result.get("passed", false)) or not bool(SprintState.quarter_result.get("turnaroundUsed", false)):
		_fail("Un plan de redressement acheté doit rattraper automatiquement un quota manqué (0 très sous le quota T1).")
	if SprintState.turnaround_plans_available != 0:
		_fail("Le plan de redressement doit être consommé après avoir servi.")

	# 🎲 Avance sur trimestre : +10 budget immédiat, débit direct sur le
	# cumul trimestriel — jamais clampé à zéro ici (lot dédié à venir).
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	SprintState.pieces = 0
	SprintState.quarter_impact = 10
	SprintState.buy_quarter_advance()
	if SprintState.pieces != 10:
		_fail("L'avance sur trimestre doit donner +10 de budget immédiatement.")
	if SprintState.quarter_impact != -70:
		_fail("L'avance sur trimestre doit débiter 80 sur le cumul trimestriel, y compris sous zéro (10 - 80 = -70).")


## Lot 4 (spec §9.4) : les équipes subies sont fixées par l'entreprise,
## jamais pilotables, transmises au score et à l'éligibilité des événements
## Inbox ; plus le Compendium des synergies (spec §12.1), qui ne fait que
## lire un rapport déjà résolu.
func _test_support_teams_and_compendium_lot4() -> void:
	print("=== SMOKE TEST LOGIQUE — LOT 4 : EQUIPES SUBIES ET COMPENDIUM ===")

	SprintState.reset_run("agile-transformation", "meridia-corp")
	if SprintState.support_teams != {"sales": 4.0, "pmm": 2.0, "csm": 3.0}:
		_fail("Meridia doit démarrer avec les équipes subies Sales 4 / PMM 2 / CSM 3.")
	var meridia_snapshot := SprintState._build_score_snapshot()
	if meridia_snapshot.get("support_teams", {}) != SprintState.support_teams:
		_fail("Le snapshot de score doit transmettre support_teams tel quel — c'est ce qui débloquait le critère de recette de l'issue #17.")

	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	if SprintState.support_teams != {"sales": 2.0, "pmm": 4.0, "csm": 1.0}:
		_fail("Karavel doit démarrer avec les équipes subies Sales 2 / PMM 4 / CSM 1.")

	# Un niveau bas génère des crises, un niveau haut de la pression — jamais
	# l'inverse (spec §9.4). On force les deux extrêmes sans passer par une
	# entreprise réelle, pour ne dépendre d'aucun tirage.
	SprintState.support_teams["sales"] = 0
	var low_sales_ids: Array = []
	for event in SprintState._eligible_inbox_events():
		low_sales_ids.append(event.get("id", ""))
	if not low_sales_ids.has("sales-deal-bloque") or low_sales_ids.has("sales-survente"):
		_fail("Sales niveau 0 doit rendre éligible l'événement de crise, jamais celui de pression.")
	SprintState.support_teams["sales"] = 5
	var high_sales_ids: Array = []
	for event in SprintState._eligible_inbox_events():
		high_sales_ids.append(event.get("id", ""))
	if not high_sales_ids.has("sales-survente") or high_sales_ids.has("sales-deal-bloque"):
		_fail("Sales niveau 5 doit rendre éligible l'événement de pression, jamais celui de crise.")

	# Effet de bord déclaratif d'une décision stratégique (dernier tiers du
	# §9.4) : Open source -> PMM +1 / Sales -1. On ne les pilote toujours
	# pas — la décision change le monde autour d'elles.
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	SprintState.chosen_strategy_ids.clear()
	SprintState.quarter_strategy_chosen = false
	var pmm_before := int(SprintState.support_teams.get("pmm", 3))
	var sales_before := int(SprintState.support_teams.get("sales", 3))
	if SprintState.choose_strategy("open-source") != "":
		_fail("La stratégie open-source doit pouvoir être choisie dans ce test isolé.")
	if int(SprintState.support_teams.get("pmm", 3)) != pmm_before + 1:
		_fail("Open source doit faire +1 PMM en effet de bord (spec §9.4).")
	if int(SprintState.support_teams.get("sales", 3)) != sales_before - 1:
		_fail("Open source doit faire -1 Sales en effet de bord (spec §9.4).")

	# 🧩 Compendium des synergies : la détection lit un rapport déjà résolu,
	# elle ne retente aucune condition.
	PlayerProfile.clear_all()
	var catalog := PlayerProfile.get_combo_catalog()
	if catalog.size() != 15:
		_fail("Le Compendium doit lister exactement 15 combos (8 composition + 5 main + 2 inter-squad), obtenu %d." % catalog.size())
	for entry in catalog:
		if entry.get("discovered", false):
			_fail("Un profil vidé ne doit révéler aucun combo au départ.")
	var fake_report := {"squads": [{"lines": [{"icon": "🔺", "label": "Trio produit"}]}], "global": {"lines": []}}
	PlayerProfile.record_score_report(fake_report)
	if not PlayerProfile.is_combo_discovered("trio-produit"):
		_fail("Une ligne de rapport correspondant à un combo doit le marquer découvert dans le Compendium.")
	if PlayerProfile.is_combo_discovered("chaos-organise"):
		_fail("Un combo absent du rapport ne doit pas être marqué découvert.")
	PlayerProfile.clear_all()


func _offer_has_item(items: Array, item_id: String) -> bool:
	for item in items:
		if item.get("id", "") == item_id:
			return true
	return false


## Vérifications déterministes du tirage des Investissements (carnet §21) :
## les grandes décisions sont tirées comme le reste de l'offre, une carte
## activée ne revient jamais, et le re-tirage se paie de plus en plus cher.
func _test_investment_draw_rules() -> void:
	print("=== SMOKE TEST LOGIQUE — TIRAGE DES INVESTISSEMENTS ===")
	var draw_conf: Dictionary = GameData.balance.get("shopDraw", {})
	var reroll_conf: Dictionary = draw_conf.get("reroll", {})
	var base_cost := int(reroll_conf.get("baseCost", 1))
	var increment := int(reroll_conf.get("costIncrement", 1))
	SprintState.reset_run("agile-transformation", "meridia-corp")
	# Isole les activations de décision du tirage aléatoire d'exigence (§21) —
	# sinon un "Outillage gelé" tiré par malchance refuse toute activation et
	# rend ce test friable, comme _test_score_resolution_integration le fait déjà.
	SprintState.quarter_requirement_ids = ["hiring-freeze"]
	SprintState.quarter_requirement_id = "hiring-freeze"

	var offer := SprintState.get_shop_offer()
	var decisions: Array = offer.get("decisions", [])
	if decisions.is_empty():
		_fail("L'offre du sprint 1 ne propose aucune grande décision.")
	if _has_duplicate(decisions):
		_fail("L'offre propose deux fois la même grande décision : %s." % [decisions])
	if SprintState.get_shop_offer().get("decisions", []) != decisions:
		_fail("Le rayon des décisions a été re-tiré en revisitant l'écran.")

	# Le prix du re-tirage part de sa base et monte à chaque usage du sprint.
	if SprintState.shop_reroll_cost() != base_cost:
		_fail("Premier re-tirage à %d 🪙 au lieu de %d." % [SprintState.shop_reroll_cost(), base_cost])
	SprintState.pieces = 20
	var pieces_before := SprintState.pieces
	if SprintState.reroll_shop_offer() != "":
		_fail("Re-tirage refusé alors que les pièces suffisent.")
	if SprintState.pieces != pieces_before - base_cost:
		_fail("Le re-tirage a coûté %d 🪙 au lieu de %d." % [pieces_before - SprintState.pieces, base_cost])
	if SprintState.shop_reroll_cost() != base_cost + increment:
		_fail("Deuxième re-tirage à %d 🪙 au lieu de %d." % [SprintState.shop_reroll_cost(), base_cost + increment])
	SprintState.reroll_shop_offer()
	if SprintState.shop_reroll_cost() != base_cost + 2 * increment:
		_fail("Troisième re-tirage à %d 🪙 au lieu de %d." % [SprintState.shop_reroll_cost(), base_cost + 2 * increment])

	# À sec, on ne re-tire pas.
	SprintState.pieces = 0
	if SprintState.reroll_shop_offer() != "pieces":
		_fail("Re-tirage accepté sans pièces.")

	# Le prix repart à sa base au sprint suivant.
	SprintState.sprint_number += 1
	if SprintState.shop_reroll_cost() != base_cost:
		_fail("Le prix du re-tirage n'est pas reparti à %d au sprint suivant (%d)." % [base_cost, SprintState.shop_reroll_cost()])

	# Une grande décision se paie comme le reste du rayon.
	var priced_id: String = SprintState.get_shop_offer().get("decisions", [""])[0]
	var price := SprintState.decision_cost(priced_id)
	if price <= 0:
		_fail("La décision « %s » ne coûte rien — elle est hors du modèle du shop." % priced_id)
	SprintState.pieces = max(0, price - 1)
	if SprintState.activate_decision(priced_id) != "pieces":
		_fail("« %s » s'est activée avec %d 🪙 pour un prix de %d." % [priced_id, SprintState.pieces, price])
	if SprintState.activated_cards.has(priced_id):
		_fail("« %s » a été marquée activée malgré le refus pour pièces insuffisantes." % priced_id)

	# Une décision activée sort du tirage : elle ne doit plus jamais reparaître.
	SprintState.pieces = 20
	var activated_id: String = SprintState.get_shop_offer().get("decisions", [""])[0]
	var pieces_at_activation := SprintState.pieces
	var activation_cost := SprintState.decision_cost(activated_id)
	if SprintState.activate_decision(activated_id) != "":
		_fail("Activation refusée pour « %s » alors qu'un slot est libre." % activated_id)
	if SprintState.pieces != pieces_at_activation - activation_cost:
		_fail("L'activation de « %s » a coûté %d 🪙 au lieu de %d." % [
			activated_id, pieces_at_activation - SprintState.pieces, activation_cost])
	for sprint in range(30):
		SprintState.sprint_number += 1
		if SprintState.get_shop_offer().get("decisions", []).has(activated_id):
			_fail("La décision activée « %s » est ressortie au tirage du sprint %d." % [activated_id, SprintState.sprint_number])
			break

	_test_mixed_shelf()
	_test_rarity_weights()
	_test_reservation()
	_test_gated_card_lease()

	print("Tirage des Investissements : OK (%d emplacements par sprint, re-tirage %d 🪙 +%d)" % [
		int(draw_conf.get("slotsPerSprint", 6)), base_cost, increment])


## Le rayon unique : les trois types se partagent `slotsPerSprint`
## emplacements, avec un minimum garanti par type. C'est le garde-fou qui
## empêche un sprint entièrement inutile — et la seule entorse au hasard pur.
func _test_mixed_shelf() -> void:
	var conf: Dictionary = GameData.balance.get("shopDraw", {})
	var total := int(conf.get("slotsPerSprint", 6))
	var guaranteed: Dictionary = conf.get("guaranteedPerSprint", {})
	SprintState.reset_run("agile-transformation", "meridia-corp")

	var seen_mix := {}
	for sprint in range(200):
		SprintState.sprint_number = sprint + 1
		var offer := SprintState.get_shop_offer()
		var slots: Array = offer.get("slots", [])
		if slots.size() != total:
			_fail("Le rayon propose %d emplacements au lieu de %d au sprint %d." % [
				slots.size(), total, SprintState.sprint_number])
			return

		var counts := {"candidate": 0, "practice": 0, "decision": 0}
		for slot in slots:
			counts[slot.get("kind", "")] = int(counts.get(slot.get("kind", ""), 0)) + 1
		for kind in counts.keys():
			if counts[kind] < int(guaranteed.get(kind, 0)):
				_fail("Minimum garanti non tenu au sprint %d : %d %s pour %d attendu(s)." % [
					SprintState.sprint_number, counts[kind], kind, int(guaranteed.get(kind, 0))])
				return

		# Les trois listes par type doivent rester le reflet exact des slots.
		if offer.get("candidates", []).size() != counts["candidate"] \
				or offer.get("practices", []).size() != counts["practice"] \
				or offer.get("decisions", []).size() != counts["decision"]:
			_fail("Les listes par type ne correspondent pas aux emplacements au sprint %d." % SprintState.sprint_number)
			return

		seen_mix["%d-%d-%d" % [counts["candidate"], counts["practice"], counts["decision"]]] = true

	# Le mélange doit vraiment varier : si un seul dosage sort sur 200 sprints,
	# le "hasard entre types" n'en est pas un.
	if seen_mix.size() < 4:
		_fail("Seulement %d dosages de rayon différents sur 200 sprints — le tirage entre types ne varie pas assez." % seen_mix.size())
	print("  dosages de rayon observés sur 200 sprints (candidats-pratiques-décisions) : %d combinaisons" % seen_mix.size())


## Les taux d'apparition : une carte `rare` doit sortir nettement moins souvent
## qu'une `commune`, et le coefficient d'époque doit peser. Test statistique —
## la marge est large exprès, il vérifie un ordre de grandeur, pas une valeur.
func _test_rarity_weights() -> void:
	# Karavel (pas Meridia) : Meridia hérite de Jira dès le départ (§7.1.3),
	# qui ne rejoint donc plus jamais le tirage — ce test mesure justement la
	# fréquence de sortie de Jira, il lui faut une entreprise qui ne l'a pas déjà.
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	var weights: Dictionary = GameData.balance.get("shopDraw", {}).get("rarityWeights", {})

	var counts: Dictionary = {}
	for sprint in range(600):
		SprintState.sprint_number = sprint + 1
		for card_id in SprintState.get_shop_offer().get("decisions", []):
			counts[card_id] = int(counts.get(card_id, 0)) + 1

	# rice (commune, poids 100) contre shape-up (rare, poids 12).
	var commune := int(counts.get("rice", 0))
	var rare := int(counts.get("shape-up", 0))
	if commune <= rare:
		_fail("La carte rare « shape-up » (%d sorties) n'est pas plus rare que « rice » (%d) sur 600 sprints." % [rare, commune])
	if rare == 0:
		_fail("La carte rare « shape-up » n'est jamais sortie sur 600 sprints — poids nul ?")

	# jira est `notable` (poids 40) mais double son poids en Transformation
	# agile (eraWeights) : il doit sortir plus qu'une notable sans coefficient.
	if int(counts.get("jira", 0)) <= int(counts.get("sprint-retro", 0)):
		_fail("Le coefficient d'époque de « jira » (%d sorties) ne pèse pas face à « sprint-retro » (%d)." % [
			int(counts.get("jira", 0)), int(counts.get("sprint-retro", 0))])
	print("  taux observés sur 600 sprints (poids %s) : %s" % [weights, counts])


## 📌 Réserver : l'Actif punaisé traverse un re-tirage et le sprint suivant,
## puis la punaise tombe. Décoller rembourse la pièce.
func _test_reservation() -> void:
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.pieces = 20
	var cost := SprintState.reserve_cost()
	var offer := SprintState.get_shop_offer()
	var pinned_id: String = offer.get("decisions", [""])[0]

	var pieces_before := SprintState.pieces
	if SprintState.toggle_reservation("decision", pinned_id, SprintState.find_card(pinned_id)) != "":
		_fail("Réservation refusée alors que les pièces suffisent.")
	if SprintState.pieces != pieces_before - cost:
		_fail("La réservation a coûté %d 🪙 au lieu de %d." % [pieces_before - SprintState.pieces, cost])
	if not SprintState.is_reserved("decision", pinned_id):
		_fail("« %s » n'est pas marquée réservée après la punaise." % pinned_id)

	# Un re-tirage ne doit pas emporter ce qu'on a payé pour garder.
	SprintState.reroll_shop_offer()
	if not SprintState.get_shop_offer().get("decisions", []).has(pinned_id):
		_fail("Le re-tirage a emporté la carte réservée « %s »." % pinned_id)

	# Elle traverse le sprint suivant...
	SprintState.sprint_number += 1
	if not SprintState.get_shop_offer().get("decisions", []).has(pinned_id):
		_fail("La carte réservée « %s » a disparu au sprint suivant." % pinned_id)

	# ...puis la punaise tombe : elle n'est plus garantie.
	SprintState.sprint_number += 1
	SprintState.get_shop_offer()
	if SprintState.is_reserved("decision", pinned_id):
		_fail("La réservation de « %s » a survécu deux sprints — elle doit tenir un sprint." % pinned_id)

	# Décoller la punaise rembourse.
	var other_id: String = SprintState.get_shop_offer().get("decisions", [""])[0]
	pieces_before = SprintState.pieces
	SprintState.toggle_reservation("decision", other_id, SprintState.find_card(other_id))
	SprintState.toggle_reservation("decision", other_id, SprintState.find_card(other_id))
	if SprintState.pieces != pieces_before:
		_fail("Décoller la punaise n'a pas remboursé la pièce (%d → %d)." % [pieces_before, SprintState.pieces])
	if SprintState.is_reserved("decision", other_id):
		_fail("« %s » est restée réservée après avoir décollé la punaise." % other_id)


## 🔒 Une carte à prérequis prend un bail dès qu'elle sort : elle reste sur le
## rayon le trimestre entier, verrouillée tant que la condition est fausse.
func _test_gated_card_lease() -> void:
	# Karavel : équipe 100 % junior, donc le prérequis « 2 seniors » de
	# Shape Up est faux au départ — c'est tout l'intérêt de la carte gatée.
	SprintState.reset_run("agile-transformation", "karavel-scaleup")
	SprintState.quarter_requirement_ids = ["hiring-freeze"]
	SprintState.quarter_requirement_id = "hiring-freeze"
	var lease := int(GameData.balance.get("shopDraw", {}).get("lockedLeaseSprints", 6))
	var gated := SprintState.find_card("shape-up")
	if gated.get("requires", {}).is_empty():
		_fail("La carte « shape-up » n'a plus de prérequis — le test du bail ne vaut plus rien.")
		return

	# On force sa sortie en tirant jusqu'à ce qu'elle tombe.
	var drawn_at := 0
	for sprint in range(400):
		SprintState.sprint_number = sprint + 1
		if SprintState.get_shop_offer().get("decisions", []).has("shape-up"):
			drawn_at = SprintState.sprint_number
			break
	if drawn_at == 0:
		_fail("« shape-up » n'est jamais sortie en 400 sprints.")
		return

	if SprintState.get_lease_expiry("shape-up") != drawn_at + lease:
		_fail("Bail de « shape-up » jusqu'au sprint %d au lieu de %d." % [
			SprintState.get_lease_expiry("shape-up"), drawn_at + lease])

	# Verrouillée : le roster de départ n'a pas 2 seniors.
	if SprintState.card_requirement_state(gated).get("ok", true):
		_fail("« shape-up » est activable alors que le prérequis n'est pas rempli.")
	if SprintState.activate_decision("shape-up") != "prerequis":
		_fail("« shape-up » s'est activée malgré son prérequis non rempli.")

	# Elle reste punaisée sur toute la durée du bail, même sans être tirée.
	for sprint in range(lease):
		SprintState.sprint_number = drawn_at + sprint
		if not SprintState.get_leased_decision_ids().has("shape-up"):
			_fail("« shape-up » a quitté le rayon au sprint %d, avant la fin de son bail." % SprintState.sprint_number)
			break

	# Le prérequis rempli — et les pièces en poche, une décision s'achète — elle
	# s'active.
	SprintState.sprint_number = drawn_at + 1
	SprintState.pieces = 20
	SprintState.get_primary_squad().get("roster", []).append({"id": "t1", "name": "Test", "role": "dev", "seniority": "senior", "salary": 2, "trait": "", "hidden_trait": "", "hiddenRevealed": true, "hiredSprint": 1})
	SprintState.get_primary_squad().get("roster", []).append({"id": "t2", "name": "Test2", "role": "dev", "seniority": "senior", "salary": 2, "trait": "", "hidden_trait": "", "hiddenRevealed": true, "hiredSprint": 1})
	if not SprintState.card_requirement_state(gated).get("ok", false):
		_fail("« shape-up » reste verrouillée avec 2 seniors au roster.")
	if SprintState.activate_decision("shape-up") != "":
		_fail("« shape-up » refuse de s'activer alors que son prérequis est rempli.")
	if SprintState.get_leased_decision_ids().has("shape-up"):
		_fail("« shape-up » reste punaisée après activation.")

	# Le bail expire : au-delà, la carte n'est plus garantie sur le rayon.
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.quarter_requirement_ids = ["hiring-freeze"]
	SprintState.quarter_requirement_id = "hiring-freeze"
	SprintState.leased_decisions["shape-up"] = 4
	SprintState.sprint_number = 5
	if SprintState.get_leased_decision_ids().has("shape-up"):
		_fail("Le bail de « shape-up » n'a pas expiré au sprint 5 (échéance 4).")


func _has_duplicate(ids: Array) -> bool:
	var seen: Array = []
	for id in ids:
		if seen.has(id):
			return true
		seen.append(id)
	return false


## Vérifications déterministes des règles d'Énergie (spec profondeur §7) :
## départ, modulation de la régén par le Moral, coûts et effets des quatre
## actions personnelles, blocage par Souffler, remap du burn-out.
func _test_energy_rules() -> void:
	print("=== SMOKE TEST LOGIQUE — RÈGLES D'ÉNERGIE (Phase B) ===")
	var conf: Dictionary = GameData.balance.get("energy", {})
	SprintState.reset_run("agile-transformation", "meridia-corp")

	if SprintState.energy != int(conf.get("start", 70)):
		_fail("Énergie de départ %d au lieu de %d." % [SprintState.energy, int(conf.get("start", 70))])

	# Modulation de la régénération par le Moral (×1 / ×0.5 / ×0).
	SprintState.resource_values["moral"] = 80.0
	if SprintState.get_energy_regen_factor() != 1.0:
		_fail("Facteur de régén attendu ×1 à Moral 80, obtenu ×%s." % SprintState.get_energy_regen_factor())
	SprintState.resource_values["moral"] = 45.0
	if SprintState.get_energy_regen_factor() != 0.5:
		_fail("Facteur de régén attendu ×0.5 à Moral 45, obtenu ×%s." % SprintState.get_energy_regen_factor())
	SprintState.resource_values["moral"] = 10.0
	if SprintState.get_energy_regen_factor() != 0.0:
		_fail("Facteur de régén attendu ×0 à Moral 10, obtenu ×%s." % SprintState.get_energy_regen_factor())
	SprintState.resource_values["moral"] = 60.0

	# 🔧 Faire le taf soi-même : capacité en plus, Énergie en moins.
	var self_conf: Dictionary = conf.get("actions", {}).get("selfWork", {})
	var capacity_before := SprintState.get_effective_capacity()
	var energy_expected := SprintState.energy - int(self_conf.get("cost", 25))
	if SprintState.do_self_work() != "":
		_fail("do_self_work() refusé alors que l'Énergie est pleine.")
	if SprintState.get_effective_capacity() != capacity_before + int(self_conf.get("capacityBonus", 2)):
		_fail("Le taf soi-même n'a pas ajouté %d points de capacité." % int(self_conf.get("capacityBonus", 2)))
	if SprintState.energy != energy_expected:
		_fail("Le taf soi-même a laissé l'Énergie à %d au lieu de %d." % [SprintState.energy, energy_expected])

	# 🏛️ Rallonge : pièces immédiates, Capital politique au panier du sprint.
	var ext_conf: Dictionary = conf.get("actions", {}).get("extension", {})
	var pieces_before := SprintState.pieces
	energy_expected = SprintState.energy - int(ext_conf.get("cost", 10))
	if SprintState.do_negotiate_extension() != "":
		_fail("do_negotiate_extension() refusé alors que l'Énergie le permet.")
	if SprintState.pieces != pieces_before + int(ext_conf.get("pieces", 4)):
		_fail("La rallonge n'a pas versé %d pièces immédiates." % int(ext_conf.get("pieces", 4)))
	if int(SprintState.pending_deltas.get("capital-politique", 0.0)) != int(ext_conf.get("capitalPolitique", -8)):
		_fail("La rallonge n'a pas mis %d de Capital politique au panier." % int(ext_conf.get("capitalPolitique", -8)))
	if SprintState.energy != energy_expected:
		_fail("La rallonge a laissé l'Énergie à %d au lieu de %d." % [SprintState.energy, energy_expected])

	# 🤝 1:1 sur un candidat du Marché : révélation avant embauche.
	var offer := SprintState.get_shop_offer()
	var offer_candidates: Array = offer.get("candidates", [])
	if offer_candidates.is_empty():
		_fail("Le Marché n'a proposé aucun candidat pour le test du 1:1.")
	else:
		var candidate: Dictionary = offer_candidates[0]
		energy_expected = SprintState.energy - int(conf.get("actions", {}).get("oneOnOne", {}).get("cost", 10))
		if SprintState.do_one_on_one(candidate) != "":
			_fail("do_one_on_one() refusé sur un candidat non révélé.")
		if not candidate.get("hiddenRevealed", false):
			_fail("Le 1:1 n'a pas révélé le trait caché du candidat.")
		if SprintState.energy != energy_expected:
			_fail("Le 1:1 a laissé l'Énergie à %d au lieu de %d." % [SprintState.energy, energy_expected])
		if SprintState.do_one_on_one(candidate) != "deja-revele":
			_fail("Un second 1:1 sur le même candidat aurait dû être refusé (deja-revele).")

	# 🧘 Souffler : bloque les actions, bonus de régén à la Résolution
	# suivante — même quand le Moral effondré annule la régén de base.
	if SprintState.plan_breather() != "":
		_fail("plan_breather() refusé au premier appel.")
	if SprintState.plan_breather() != "deja-planifie":
		_fail("plan_breather() devrait refuser un second appel (deja-planifie).")
	if SprintState.do_self_work() != "souffler":
		_fail("Souffler doit bloquer les actions personnelles jusqu'à la prochaine Résolution.")
	SprintState.resource_values["moral"] = 10.0
	SprintState.apply_pending_and_check()
	var report: Dictionary = SprintState.last_energy_report
	if int(report.get("regen", -1)) != 0:
		_fail("Régén attendue nulle sous Moral 30, obtenue %d." % int(report.get("regen", -1)))
	if int(report.get("breatherBonus", 0)) != int(conf.get("breatherRegenBonus", 10)):
		_fail("Le bonus de Souffler (%d) n'a pas été versé à la Résolution." % int(conf.get("breatherRegenBonus", 10)))
	if SprintState.breather_planned:
		_fail("Le flag Souffler doit être consommé à la Résolution.")
	if SprintState.personal_action_refusal() != "":
		_fail("Les actions personnelles doivent être de nouveau jouables après la Résolution du sprint de Souffler.")

	# 🔥 Burn-out remappé (spec §8.3) : Énergie ≤ 0 à la Résolution = fin.
	SprintState.reset_run("agile-transformation", "meridia-corp")
	SprintState.resource_values["moral"] = 10.0  # régén nulle
	SprintState.energy = 3
	SprintState.do_self_work()  # puise les 3 derniers points : jauge à 0
	if SprintState.energy != 0:
		_fail("La dépense d'Énergie devrait plancher à 0, obtenu %d." % SprintState.energy)
	var ending := SprintState.apply_pending_and_check()
	if ending != "burnout-fondateur":
		_fail("Énergie 0 + régén nulle devrait finir en burn-out, obtenu '%s'." % ending)
	print("Règles d'Énergie : %s" % ("OK" if failures == 0 else "ÉCHEC"))


func _play_one_mandate(run_index: int, strategy: String, company_id: String) -> void:
	SprintState.reset_run("agile-transformation", company_id)
	print("\n--- Run %d (%s) — %s — 🪙 %d, 👥 %d/%d, capacité %d — Départ : %s ---" % [
		run_index, strategy, company_id, SprintState.pieces,
		SprintState.get_roster().size(), SprintState.get_team_cap(),
		SprintState.get_effective_capacity(), SprintState.resource_values
	])

	var sprint_count := 0
	while not SprintState.is_mandate_over and sprint_count < 30:
		sprint_count += 1
		_play_sprint(strategy)
		if SprintState.quarter_exit_choice_pending:
			SprintState.choose_mandate_path(false)

	if not SprintState.is_mandate_over:
		_fail("Run %d (%s, %s) n'a jamais atteint de fin après 30 sprints — probable bug de seuils." % [run_index, strategy, company_id])

	print("Run %d (%s, %s) terminé — sprint %d, fin='%s', 🪙 %d, ⚡ %d, 👥 %d, revue de board='%s', ressources finales=%s" % [
		run_index, strategy, company_id, SprintState.sprint_number, SprintState.ending_id,
		SprintState.pieces, SprintState.energy, SprintState.get_roster().size(), SprintState.board_review_state,
		SprintState.resource_values
	])

	for resource_id in SprintState.resource_values.keys():
		var value: float = SprintState.resource_values[resource_id]
		if value < -0.001 or value > 100.001:
			_fail("Ressource %s hors bornes : %f" % [resource_id, value])
	if SprintState.pieces < 0:
		_fail("Pièces négatives : %d" % SprintState.pieces)
	if SprintState.energy < 0 or SprintState.energy > SprintState.get_energy_max():
		_fail("Énergie hors bornes : %d" % SprintState.energy)
	if SprintState.get_roster().size() > SprintState.get_team_cap():
		_fail("Roster au-dessus du cap : %d/%d" % [SprintState.get_roster().size(), SprintState.get_team_cap()])

	# Critère de recette Phase A : "careful" (ne rien faire) doit perdre
	# avant la fin du mandat — pas de fin positive, pas de survie.
	if strategy == "careful" and SprintState.ending_id in GOOD_ENDINGS:
		_fail("Run %d (careful, %s) a survécu au mandat (fin '%s' au sprint %d) — 'ne rien faire' doit perdre." % [
			run_index, company_id, SprintState.ending_id, SprintState.sprint_number
		])


func _play_sprint(strategy: String) -> void:
	# Phase 1 — Inbox (pioche sac réelle). "stress" prend systématiquement
	# le choix le plus toxique pour le Moral — la spirale commence là.
	var event: Dictionary = SprintState.draw_inbox_event()
	if not event.is_empty():
		var choices: Array = event.get("choices", [])
		var choice: Dictionary = choices[0]
		if strategy == "careful":
			choice = _least_costly_choice(choices)
		elif strategy == "stress":
			choice = _worst_moral_choice(choices)
		SprintState.add_pending(choice.get("effects", {}), "%s → %s" % [event.get("subject", ""), choice.get("label", "")])

	# Actions personnelles Roadmap (Phase B) : "stress" fait le taf soi-même
	# tant qu'il reste de l'Énergie (la réserve part avant la capacité) ;
	# "greedy" ne puise que quand la jauge est confortable.
	if strategy == "stress":
		var guard := 0
		while SprintState.personal_action_refusal() == "" and guard < 4:
			SprintState.do_self_work()
			guard += 1
	elif strategy == "greedy" and SprintState.energy >= 50 and SprintState.personal_action_refusal() == "":
		SprintState.do_self_work()

	# Phase 2 — Roadmap : le vrai tirage persistant du backlog remplace les
	# données de démo. Greedy reste sous la capacité; stress pousse tout.
	var capacity := SprintState.get_effective_capacity()
	var plan: Array = []
	var roadmap_offer := SprintState.get_backlog_offer()
	var used := 0
	for item in roadmap_offer.get("items", []):
		var points := SprintState.get_epic_remaining(item.get("id", "")) if SprintState.is_backlog_epic(item) else int(item.get("costPoints", 0))
		if strategy == "stress" or (strategy == "greedy" and used + points <= capacity):
			plan.append({"id": item.get("id", ""), "points": points})
			used += points
	if strategy != "careful":
		SprintState.commit_backlog_plan(plan)

	# Phase 3 — Investissements : une seule offre pour les deux rayons, tirée
	# une fois par sprint (revisiter l'écran ne re-tire pas).
	var offer := SprintState.get_shop_offer()
	var offer_again := SprintState.get_shop_offer()
	if not _same_offer(offer, offer_again):
		_fail("L'offre a été re-tirée deux fois au sprint %d — elle doit être stockée." % SprintState.sprint_number)

	# 🎲 Re-tirage : "greedy" retente sa chance au sprint 3 s'il a les moyens —
	# le chemin payant du re-tirage reste couvert, prix croissant compris.
	if strategy == "greedy" and SprintState.sprint_number == 3 and SprintState.pieces >= SprintState.shop_reroll_cost() + 3:
		SprintState.reroll_shop_offer()
		offer = SprintState.get_shop_offer()

	# Rayon 🃏 — on ne peut activer que ce qui a été **tiré** : depuis que les
	# décisions sortent au hasard, aucune stratégie ne peut plus compter sur une
	# carte précise, et les deux profils ont dû apprendre à faire avec l'offre.
	#  · "greedy" prend ce qui passe aux sprints 2 et 4 (pressé, mais pas au
	#    point de brûler la trésorerie en cartes) ;
	#  · "stress" cherche la carte qui abîme le plus le Moral et n'en active
	#    qu'une — la spirale du burn-out a besoin d'un Moral cassé tôt (régén
	#    ×0), et la trésorerie doit survivre assez longtemps pour y arriver.
	#    Il ré-essaie chaque sprint tant qu'il n'a rien trouvé.
	if strategy == "stress" and SprintState.activated_cards.is_empty():
		var worst := _worst_moral_decision(offer)
		if worst != "":
			SprintState.activate_decision(worst)
	elif strategy == "greedy" and SprintState.sprint_number in [2, 4]:
		for card_id in offer.get("decisions", []):
			if SprintState.activate_decision(card_id) == "":
				break

	# 📌 "greedy" punaise ce qu'il ne peut pas encore payer : au sprint 5, s'il
	# reste un candidat trop cher sur l'étal, il le réserve pour le sprint
	# suivant plutôt que de le perdre au tirage.
	if strategy == "greedy" and SprintState.sprint_number == 5 and SprintState.pieces >= SprintState.reserve_cost():
		for candidate in offer.get("candidates", []):
			if int(candidate.get("costPieces", 0)) > SprintState.pieces:
				SprintState.toggle_reservation("candidate", candidate.get("id", ""), candidate)
				break

	if strategy == "stress":
		# Plus d'achats compulsifs : ce CPO-là compense tout de sa personne —
		# et licencie quelqu'un chaque sprint à partir du 2e (le chemin de
		# licenciement reste couvert, et le Moral en prend un coup de plus).
		if SprintState.sprint_number >= 2 and SprintState.get_roster().size() > 1:
			var last_employee: Dictionary = SprintState.get_roster()[-1]
			SprintState.fire_employee(last_employee.get("id", ""))
	elif strategy == "greedy":
		# ~1 achat par sprint : une pratique les sprints pairs, sinon une
		# embauche — précédée d'un 1:1 quand l'Énergie le permet : on ne
		# signe pas un pari les yeux fermés.
		if SprintState.sprint_number % 2 == 0:
			var practices: Array = offer.get("practices", [])
			if not practices.is_empty():
				SprintState.buy_practice(practices[0])
		else:
			var candidates: Array = offer.get("candidates", [])
			if not candidates.is_empty():
				var candidate: Dictionary = candidates[0]
				if not candidate.get("hiddenRevealed", false) and SprintState.energy >= 30 and SprintState.personal_action_refusal() == "":
					SprintState.do_one_on_one(candidate)
				var polarity: String = SprintState.get_hidden_trait(candidate.get("hidden_trait", "")).get("polarity", "")
				if not (candidate.get("hiddenRevealed", false) and polarity == "negative"):
					SprintState.hire_candidate(candidate)
		# Rallonge si le budget d'action est à sec et que le crédit au board le permet.
		if SprintState.pieces < 2 and SprintState.resource_values.get("capital-politique", 0.0) > 40.0 and SprintState.personal_action_refusal() == "":
			SprintState.do_negotiate_extension()

	# Phase 4 — Résolution.
	var ending := SprintState.apply_pending_and_check()
	if ending != "":
		return
	# 🧘 Souffler se décide à la Résolution : "greedy" lève le pied quand la
	# jauge est basse (le prochain sprint se jouera sans action personnelle).
	if strategy == "greedy" and SprintState.energy < 30:
		SprintState.plan_breather()
	SprintState.sprint_number += 1


func _same_offer(a: Dictionary, b: Dictionary) -> bool:
	if a.get("practices", []) != b.get("practices", []):
		return false
	var ids_a: Array = []
	var ids_b: Array = []
	for candidate in a.get("candidates", []):
		ids_a.append(candidate.get("id", ""))
	for candidate in b.get("candidates", []):
		ids_b.append(candidate.get("id", ""))
	return ids_a == ids_b


## Le choix le plus destructeur pour le Moral (celui d'un CPO en pilotage
## automatique qui sacrifie l'équipe à chaque arbitrage).
func _worst_moral_choice(choices: Array) -> Dictionary:
	var worst: Dictionary = choices[0]
	var worst_moral := INF
	for choice in choices:
		var moral := float(choice.get("effects", {}).get("moral", 0))
		if moral < worst_moral:
			worst_moral = moral
			worst = choice
	return worst


## La décision tirée qui abîme le plus le Moral, cartes verrouillées écartées.
## Le pendant de _worst_moral_choice() pour le rayon 🃏 : "stress" ne choisit
## plus une carte connue d'avance, il prend la pire de ce que l'offre propose.
func _worst_moral_decision(offer: Dictionary) -> String:
	var worst_id := ""
	var worst_moral := INF
	for card_id in offer.get("decisions", []):
		if SprintState.activated_cards.has(card_id):
			continue
		if not SprintState.card_requirement_state(SprintState.find_card(card_id)).get("ok", true):
			continue
		var deltas := EffectResolver.resolve_card_activation(card_id, SprintState.team_profile, SprintState.era_id)
		var moral := float(deltas.get("moral", 0.0))
		if moral < worst_moral:
			worst_moral = moral
			worst_id = card_id
	return worst_id


## Heuristique simple : la somme des deltas négatifs la moins pénalisante
## (ignore les gains, ne compare que "combien ça fait mal").
func _least_costly_choice(choices: Array) -> Dictionary:
	var best: Dictionary = choices[0]
	var best_penalty := INF
	for choice in choices:
		var penalty := 0.0
		for value in choice.get("effects", {}).values():
			if value < 0:
				penalty += -value
		if penalty < best_penalty:
			best_penalty = penalty
			best = choice
	return best
