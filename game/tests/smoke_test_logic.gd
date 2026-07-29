extends Node
## Test headless : simule des mandats complets en pilotant SprintState +
## EffectResolver directement (sans UI), pour valider la logique de
## simulation Phase A (roster, pièces, Marché, pression) et la détection
## de fin de mandat.
##
## Lancer : godot --headless --path game res://tests/smoke_test_logic.tscn
## Sort avec un code non nul si une assertion échoue — en particulier le
## critère de recette Phase A : la stratégie "careful" DOIT perdre.

## Stratégies simulées :
##  - "stress"  : sur-sollicite tout, chaque sprint (toutes les features en
##                surchauffe, embauche et achète tout ce qui est payable,
##                licencie régulièrement) — doit provoquer une fin rapide,
##                ça valide la détection et le chemin de licenciement.
##  - "greedy"  : proche d'un joueur pressé mais pas absurde — remplit la
##                capacité sans la dépasser, achète ~1 item de Marché par
##                sprint, active des grandes décisions.
##  - "careful" : joueur immobile — choix Inbox le moins coûteux, aucune
##                feature livrée, aucune embauche, aucun achat. Depuis la
##                Phase A ("la pression"), ne rien faire DOIT perdre avant
##                la fin du mandat : décroissance de la Valeur perçue,
##                spirale de revenu, masse salariale.
const GOOD_ENDINGS := ["ipo", "rachat"]

var failures: int = 0


func _ready() -> void:
	for strategy in ["stress", "greedy", "careful"]:
		print("\n=== SMOKE TEST LOGIQUE — %s ===" % strategy.to_upper())
		var run_index := 0
		for company_id in ["meridia-corp", "karavel-scaleup"]:
			for repeat in range(2):
				_play_one_mandate(run_index, strategy, company_id)
				run_index += 1

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


func _play_one_mandate(run_index: int, strategy: String, company_id: String) -> void:
	SprintState.reset_run("agile-transformation", company_id)
	print("\n--- Run %d (%s) — %s — 🪙 %d, 👥 %d/%d, capacité %d — Départ : %s ---" % [
		run_index, strategy, company_id, SprintState.pieces,
		SprintState.roster.size(), SprintState.get_team_cap(),
		SprintState.get_effective_capacity(), SprintState.resource_values
	])

	var sprint_count := 0
	while not SprintState.is_mandate_over and sprint_count < 30:
		sprint_count += 1
		_play_sprint(strategy)

	if not SprintState.is_mandate_over:
		_fail("Run %d (%s, %s) n'a jamais atteint de fin après 30 sprints — probable bug de seuils." % [run_index, strategy, company_id])

	print("Run %d (%s, %s) terminé — sprint %d, fin='%s', 🪙 %d, 👥 %d, revue de board='%s', ressources finales=%s" % [
		run_index, strategy, company_id, SprintState.sprint_number, SprintState.ending_id,
		SprintState.pieces, SprintState.roster.size(), SprintState.board_review_state,
		SprintState.resource_values
	])

	for resource_id in SprintState.resource_values.keys():
		var value: float = SprintState.resource_values[resource_id]
		if value < -0.001 or value > 100.001:
			_fail("Ressource %s hors bornes : %f" % [resource_id, value])
	if SprintState.pieces < 0:
		_fail("Pièces négatives : %d" % SprintState.pieces)
	if SprintState.roster.size() > SprintState.get_team_cap():
		_fail("Roster au-dessus du cap : %d/%d" % [SprintState.roster.size(), SprintState.get_team_cap()])

	# Critère de recette Phase A : "careful" (ne rien faire) doit perdre
	# avant la fin du mandat — pas de fin positive, pas de survie.
	if strategy == "careful" and SprintState.ending_id in GOOD_ENDINGS:
		_fail("Run %d (careful, %s) a survécu au mandat (fin '%s' au sprint %d) — 'ne rien faire' doit perdre." % [
			run_index, company_id, SprintState.ending_id, SprintState.sprint_number
		])


func _play_sprint(strategy: String) -> void:
	# Phase 1 — Inbox (pioche sac réelle).
	var event: Dictionary = SprintState.draw_inbox_event()
	if not event.is_empty():
		var choices: Array = event.get("choices", [])
		var choice: Dictionary = choices[0] if strategy != "careful" else _least_costly_choice(choices)
		SprintState.add_pending(choice.get("effects", {}), "%s → %s" % [event.get("subject", ""), choice.get("label", "")])

	# Phase 2 — Roadmap : sélection en points contre la capacité du roster.
	var capacity := SprintState.get_effective_capacity()
	var feature_ids: Array = []
	var cost_points: Dictionary = GameData.balance.get("roadmap", {}).get("featureCostPoints", {})
	if strategy == "stress":
		for feature in GameData.roadmap_features.get("features", []):
			feature_ids.append(feature.get("id", ""))
	elif strategy == "greedy":
		# Remplit la capacité par coût croissant (le plus de features possible,
		# quick wins compris) sans jamais déclencher la surchauffe.
		var by_cost: Array = []
		for feature in GameData.roadmap_features.get("features", []):
			by_cost.append(feature.get("id", ""))
		by_cost.sort_custom(func(a, b): return int(cost_points.get(a, 1)) < int(cost_points.get(b, 1)))
		var used := 0
		for feature_id in by_cost:
			var points := int(cost_points.get(feature_id, 1))
			if used + points <= capacity:
				feature_ids.append(feature_id)
				used += points
	if not feature_ids.is_empty() or strategy != "careful":
		var roadmap_deltas := EffectResolver.resolve_roadmap(feature_ids, capacity, SprintState.get_roster_context())
		SprintState.add_pending(roadmap_deltas, "Roadmap : %d features (%d pts / %d)" % [
			feature_ids.size(), EffectResolver.roadmap_points_cost(feature_ids), capacity
		])
		SprintState.delivered_feature_ids = feature_ids.duplicate()

	# Phase 3 — Grandes décisions. "greedy" en active deux, aux sprints 2 et 4
	# (un joueur pressé mais pas au point de brûler la trésorerie en cartes) ;
	# "stress" enchaîne jusqu'à la limite.
	var wants_card := (strategy == "stress") or (strategy == "greedy" and SprintState.sprint_number in [2, 4])
	if wants_card and SprintState.activated_cards.size() < int(GameData.balance.get("structuralDecisionMaxActivations", 4)):
		for card in GameData.cards.get("cards", []):
			var card_id: String = card.get("id", "")
			if not SprintState.activated_cards.has(card_id):
				var card_deltas := EffectResolver.resolve_card_activation(card_id, SprintState.team_profile, SprintState.era_id)
				SprintState.add_pending(card_deltas, "Grande décision : %s" % card.get("name", card_id))
				SprintState.activated_cards.append(card_id)
				SprintState.activated_card_sprints[card_id] = SprintState.sprint_number
				break

	# Phase 4 — Marché : tirage stocké (pas de re-tirage en revisitant).
	var offer := SprintState.get_shop_offer()
	var offer_again := SprintState.get_shop_offer()
	if not _same_offer(offer, offer_again):
		_fail("Le Marché a été retiré deux fois au sprint %d — l'offre doit être stockée." % SprintState.sprint_number)

	if strategy == "stress":
		for practice_id in offer.get("practices", []):
			SprintState.buy_practice(practice_id)
		for candidate in offer.get("candidates", []):
			SprintState.hire_candidate(candidate)
		if SprintState.sprint_number >= 2 and SprintState.roster.size() > 1:
			var last_employee: Dictionary = SprintState.roster[-1]
			SprintState.fire_employee(last_employee.get("id", ""))
	elif strategy == "greedy":
		# ~1 achat par sprint : une pratique les sprints pairs, sinon une embauche.
		if SprintState.sprint_number % 2 == 0:
			var practices: Array = offer.get("practices", [])
			if not practices.is_empty():
				SprintState.buy_practice(practices[0])
		else:
			var candidates: Array = offer.get("candidates", [])
			if not candidates.is_empty():
				SprintState.hire_candidate(candidates[0])

	# Phase 5 — Résolution.
	var ending := SprintState.apply_pending_and_check()
	if ending != "":
		return
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
