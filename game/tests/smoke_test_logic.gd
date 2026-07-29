extends Node
## Test headless : simule des mandats complets en pilotant SprintState +
## EffectResolver directement (sans UI), pour valider la logique de
## simulation et la détection de fin de mandat.
##
## Lancer : godot --headless --path game res://tests/smoke_test_logic.tscn

## Stratégies simulées :
##  - "stress"  : sur-sollicite tout, chaque sprint (toutes les features,
##                recrutement systématique, activation dès que possible) —
##                doit provoquer une fin rapidement, ça valide la détection.
##  - "greedy"  : proche d'un joueur pressé mais pas absurde (features par
##                défaut, recrute et active quand même beaucoup).
##  - "careful" : joueur prudent — choisit l'option Inbox la moins coûteuse,
##                ne sélectionne aucune feature, ne recrute pas, n'active
##                aucune carte. Doit pouvoir tenir tout le mandat : sert à
##                vérifier que le jeu n'est pas perdable par construction.
func _ready() -> void:
	for strategy in ["stress", "greedy", "careful"]:
		print("\n=== SMOKE TEST LOGIQUE — %s ===" % strategy.to_upper())
		for run_index in range(4):
			_play_one_mandate(run_index, strategy)

	print("\n=== SMOKE TEST LOGIQUE : OK ===")
	get_tree().quit()


func _play_one_mandate(run_index: int, strategy: String) -> void:
	SprintState.reset_run()
	print("\n--- Run %d (%s) — Époque : %s — Départ : %s ---" % [run_index, strategy, SprintState.era_id, SprintState.resource_values])

	var sprint_count := 0
	while not SprintState.is_mandate_over and sprint_count < 30:
		sprint_count += 1
		_play_sprint(sprint_count, strategy)

	if not SprintState.is_mandate_over:
		push_error("Run %d (%s) n'a jamais atteint de fin après 30 sprints — probable bug de seuils." % [run_index, strategy])

	print("Run %d (%s) terminé — sprint %d, fin='%s', ressources finales=%s" % [
		run_index, strategy, SprintState.sprint_number, SprintState.ending_id, SprintState.resource_values
	])

	for resource_id in SprintState.resource_values.keys():
		var value: float = SprintState.resource_values[resource_id]
		if value < -0.001 or value > 100.001:
			push_error("Ressource %s hors bornes : %f" % [resource_id, value])


func _play_sprint(sprint_num: int, strategy: String) -> void:
	var events: Array = GameData.inbox_events
	var event: Dictionary = events[(SprintState.sprint_number - 1) % events.size()]
	var choices: Array = event.get("choices", [])
	var choice: Dictionary = choices[0] if strategy != "careful" else _least_costly_choice(choices)
	SprintState.add_pending(choice.get("effects", {}), "%s → %s" % [event.get("subject", ""), choice.get("label", "")])

	var feature_ids: Array = []
	if strategy == "stress":
		for feature in GameData.roadmap_features.get("features", []):
			feature_ids.append(feature.get("id", ""))
	elif strategy == "greedy":
		for feature in GameData.roadmap_features.get("features", []):
			if feature.get("selectedByDefault", false):
				feature_ids.append(feature.get("id", ""))
	var effective_capacity := SprintState.get_effective_capacity()
	var roadmap_deltas := EffectResolver.resolve_roadmap(feature_ids, effective_capacity)
	SprintState.add_pending(roadmap_deltas, "Roadmap : %d features" % feature_ids.size())

	if strategy != "careful" and SprintState.activated_cards.size() < int(GameData.balance.get("structuralDecisionMaxActivations", 4)):
		for card in GameData.cards.get("cards", []):
			var card_id: String = card.get("id", "")
			if not SprintState.activated_cards.has(card_id):
				var card_deltas := EffectResolver.resolve_card_activation(card_id, SprintState.team_profile, SprintState.era_id)
				SprintState.add_pending(card_deltas, "Grande décision : %s" % card.get("name", card_id))
				SprintState.activated_cards.append(card_id)
				SprintState.activated_card_sprints[card_id] = SprintState.sprint_number
				break

	if strategy != "careful":
		var item_ids: Array = GameData.balance.get("recruitment", {}).get("itemEffects", {}).keys()
		if not item_ids.is_empty():
			var item_id: String = item_ids[(sprint_num - 1) % item_ids.size()]
			var recruitment_result := EffectResolver.resolve_recruitment(item_id)
			SprintState.add_pending(recruitment_result.get("deltas", {}), "Recrutement : %s" % item_id)
			SprintState.capacity_bonus += int(recruitment_result.get("capacity_bonus", 0))

	var ending := SprintState.apply_pending_and_check()
	if ending != "":
		return
	SprintState.sprint_number += 1


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
