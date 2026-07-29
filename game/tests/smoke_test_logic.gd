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
		SprintState.roster.size(), SprintState.get_team_cap(),
		SprintState.get_effective_capacity(), SprintState.resource_values
	])

	var sprint_count := 0
	while not SprintState.is_mandate_over and sprint_count < 30:
		sprint_count += 1
		_play_sprint(strategy)

	if not SprintState.is_mandate_over:
		_fail("Run %d (%s, %s) n'a jamais atteint de fin après 30 sprints — probable bug de seuils." % [run_index, strategy, company_id])

	print("Run %d (%s, %s) terminé — sprint %d, fin='%s', 🪙 %d, ⚡ %d, 👥 %d, revue de board='%s', ressources finales=%s" % [
		run_index, strategy, company_id, SprintState.sprint_number, SprintState.ending_id,
		SprintState.pieces, SprintState.energy, SprintState.roster.size(), SprintState.board_review_state,
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
	if SprintState.roster.size() > SprintState.get_team_cap():
		_fail("Roster au-dessus du cap : %d/%d" % [SprintState.roster.size(), SprintState.get_team_cap()])

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
	# "stress" en active une au sprint 1 puis n'a plus la tête à ça — il faut
	# que la trésorerie survive assez longtemps pour que le burn-out arrive.
	var wants_card := (strategy == "stress" and SprintState.sprint_number == 1) or (strategy == "greedy" and SprintState.sprint_number in [2, 4])
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
		# Plus d'achats compulsifs : ce CPO-là compense tout de sa personne —
		# et licencie quelqu'un chaque sprint à partir du 2e (le chemin de
		# licenciement reste couvert, et le Moral en prend un coup de plus).
		if SprintState.sprint_number >= 2 and SprintState.roster.size() > 1:
			var last_employee: Dictionary = SprintState.roster[-1]
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

	# Phase 5 — Résolution.
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
