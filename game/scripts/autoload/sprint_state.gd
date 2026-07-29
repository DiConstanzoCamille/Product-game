extends Node
## Autoload : état complet d'un mandat (run) — les 6 ressources persistantes,
## le scénario choisi, les grandes décisions activées, le journal, et le
## panier d'effets en attente pour le sprint en cours.
##
## Modèle d'application (§11 du carnet de règles) : chaque phase d'un sprint
## (Inbox, Roadmap, Grandes décisions, Recrutement) calcule son effet et
## l'ajoute au panier via add_pending(). L'écran de Résolution applique tout
## le panier d'un coup via apply_pending_and_check() — plus le revenu du
## modèle économique du scénario — affiche le delta réel, et détecte une
## éventuelle fin de mandat. Voir docs/carnet-de-regles.md §14-15 pour le
## détail des décisions de conception (seuils, mapping, scénarios, revenu).

signal ending_reached(id: String)

var sprint_number: int = 1
var team_profile: String = "junior"
var era_id: String = ""
var business_model_id: String = ""
var company_id: String = ""
var pending_era_id: String = ""  # étape transitoire entre scenario_screen et company_select_screen

var resource_values: Dictionary = {}   # resource_id -> float (0..100)
var capacity_bonus: int = 0            # cumulé sur le mandat, via recrutement
var activated_cards: Array = []        # ids des grandes décisions activées ce mandat
var activated_card_sprints: Dictionary = {}  # card_id -> numéro de sprint d'activation
var journal: Array = []                # [{sprint, text, deltas}], le plus ancien en premier

var pending_deltas: Dictionary = {}    # resource_id -> float, accumulés sur le sprint en cours
var pending_journal_lines: Array = []  # texte des choix faits pendant le sprint en cours

var is_mandate_over: bool = false
var ending_id: String = ""

var last_revenue: int = 0              # revenu du modèle économique au dernier sprint résolu
var last_tresorerie_cost: int = 0      # somme des coûts/gains de décisions sur la trésorerie (hors revenu)

var _inbox_event_bag: Array = []       # ids restants à tirer dans le "sac" courant
var _last_inbox_event_id: String = ""  # évite une répétition immédiate entre deux sacs


## À appeler au lancement d'un nouveau mandat, une fois le scénario et
## l'entreprise choisis (scenario_screen puis company_select_screen). Vide =
## tirage aléatoire parmi les options jouables (utile pour les tests headless).
func reset_run(chosen_era_id: String = "", chosen_company_id: String = "") -> void:
	sprint_number = 1
	era_id = chosen_era_id if chosen_era_id != "" else _pick_random_playable_era()
	company_id = chosen_company_id if chosen_company_id != "" else _pick_random_company(era_id)
	team_profile = get_company().get("teamProfile", "junior")
	business_model_id = GameData.balance.get("eraBusinessModel", {}).get(era_id, "")
	capacity_bonus = 0
	activated_cards.clear()
	activated_card_sprints.clear()
	journal.clear()
	pending_deltas.clear()
	pending_journal_lines.clear()
	is_mandate_over = false
	ending_id = ""
	last_revenue = 0
	last_tresorerie_cost = 0
	_inbox_event_bag.clear()
	_last_inbox_event_id = ""

	resource_values.clear()
	var starting: Dictionary = GameData.balance.get("startingResources", {})
	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		resource_values[resource_id] = float(starting.get(resource_id, 50))


func _pick_random_playable_era() -> String:
	var playable: Array = GameData.balance.get("playableEras", [])
	if playable.is_empty():
		return ""
	return playable[randi() % playable.size()]


func _pick_random_company(for_era_id: String) -> String:
	var candidates: Array = []
	for company in GameData.companies:
		if company.get("era", "") == for_era_id:
			candidates.append(company.get("id", ""))
	if candidates.is_empty():
		return ""
	return candidates[randi() % candidates.size()]


func get_era() -> Dictionary:
	for era in GameData.eras:
		if era.get("id", "") == era_id:
			return era
	return {}


func get_company() -> Dictionary:
	for company in GameData.companies:
		if company.get("id", "") == company_id:
			return company
	return {}


func get_companies_for_era(target_era_id: String) -> Array:
	var result: Array = []
	for company in GameData.companies:
		if company.get("era", "") == target_era_id:
			result.append(company)
	return result


func get_business_model() -> Dictionary:
	return GameData.balance.get("businessModels", {}).get(business_model_id, {})


## Capacité de roadmap effective ce sprint (base + bonus cumulé de recrutement).
func get_effective_capacity() -> int:
	var base: int = GameData.roadmap_features.get("capacityMax", 3)
	return base + capacity_bonus


## Tire le prochain événement Inbox par pioche "sac" (bag shuffle) : tous les
## événements éligibles au scénario en cours sont mélangés puis consommés un
## par un ; le sac est remélangé une fois vide. Évite les répétitions
## immédiates d'un sac à l'autre. Consomme une pioche — à appeler une seule
## fois par sprint, depuis l'écran Inbox.
func draw_inbox_event() -> Dictionary:
	var eligible: Array = _eligible_inbox_events()
	if eligible.is_empty():
		return {}

	if _inbox_event_bag.is_empty():
		for event in eligible:
			_inbox_event_bag.append(event.get("id", ""))
		_inbox_event_bag.shuffle()
		if _inbox_event_bag.size() > 1 and _inbox_event_bag[-1] == _last_inbox_event_id:
			var swap_index := randi() % (_inbox_event_bag.size() - 1)
			var tmp = _inbox_event_bag[-1]
			_inbox_event_bag[-1] = _inbox_event_bag[swap_index]
			_inbox_event_bag[swap_index] = tmp

	var event_id: String = _inbox_event_bag.pop_back()
	_last_inbox_event_id = event_id
	return _find_inbox_event(event_id)


func _eligible_inbox_events() -> Array:
	var result: Array = []
	for event in GameData.inbox_events:
		var eras: Array = event.get("eras", [])
		if eras.is_empty() or eras.has(era_id):
			result.append(event)
	return result


func _find_inbox_event(event_id: String) -> Dictionary:
	for event in GameData.inbox_events:
		if event.get("id", "") == event_id:
			return event
	return {}


## Ajoute des deltas de ressources au panier du sprint en cours (pas encore
## appliqués aux jauges) et, optionnellement, une ligne de journal décrivant
## la décision qui les a produits.
func add_pending(deltas: Dictionary, note: String = "") -> void:
	for resource_id in deltas.keys():
		var value: float = float(deltas[resource_id])
		pending_deltas[resource_id] = pending_deltas.get(resource_id, 0.0) + value
	if note != "":
		pending_journal_lines.append(note)


## Revenu du sprint selon le modèle économique du scénario (§15) — proportionnel
## à la Valeur perçue, érodé par un Moral bas (churn). Pas de modèle = 0.
func compute_revenue() -> int:
	var model: Dictionary = get_business_model()
	if model.is_empty():
		return 0

	var valeur: float = resource_values.get("valeur-percue", 0.0)
	var moral: float = resource_values.get("moral", 0.0)
	var per_point: float = model.get("revenuePerValeurPercuePoint", 0.0)
	var floor_factor: float = model.get("moralChurnFloor", 0.4)
	var ceiling_factor: float = model.get("moralChurnCeiling", 1.2)
	var moral_factor: float = clamp(moral / 100.0, floor_factor, ceiling_factor)

	return int(round(valeur * per_point * moral_factor))


## Applique le panier d'effets aux ressources (+ le revenu du sprint),
## journalise, puis vérifie les fins de mandat (seuils de ressources, ou
## longueur atteinte). Retourne l'id de la fin atteinte, ou "" si le mandat
## continue. À appeler une seule fois par sprint, depuis l'écran de Résolution.
func apply_pending_and_check() -> String:
	last_tresorerie_cost = int(round(pending_deltas.get("tresorerie", 0.0)))
	last_revenue = compute_revenue()
	if last_revenue != 0:
		pending_deltas["tresorerie"] = pending_deltas.get("tresorerie", 0.0) + last_revenue
		var model_label: String = get_business_model().get("label", "revenu")
		pending_journal_lines.append("Revenus (%s) : %s%d" % [
			model_label, "+" if last_revenue >= 0 else "−", abs(last_revenue)
		])

	var bounds: Dictionary = GameData.balance.get("resourceBounds", {"min": 0, "max": 100})
	var min_value: float = bounds.get("min", 0)
	var max_value: float = bounds.get("max", 100)

	var applied: Dictionary = {}
	for resource_id in pending_deltas.keys():
		if not resource_values.has(resource_id):
			continue
		var delta: float = pending_deltas[resource_id]
		var new_value: float = clamp(resource_values[resource_id] + delta, min_value, max_value)
		applied[resource_id] = new_value - resource_values[resource_id]
		resource_values[resource_id] = new_value

	journal.append({
		"sprint": sprint_number,
		"text": " · ".join(pending_journal_lines) if not pending_journal_lines.is_empty() else "Sprint calme — aucune décision marquante.",
		"deltas": EffectResolver.format_deltas(applied),
	})

	pending_deltas.clear()
	pending_journal_lines.clear()

	var bad_ending := _check_bad_endings()
	if bad_ending != "":
		is_mandate_over = true
		ending_id = bad_ending
		ending_reached.emit(bad_ending)
		return bad_ending

	if sprint_number >= int(GameData.balance.get("mandateLengthSprints", 12)):
		var good_ending := _resolve_good_ending()
		is_mandate_over = true
		ending_id = good_ending
		ending_reached.emit(good_ending)
		return good_ending

	return ""


func _check_bad_endings() -> String:
	var thresholds: Array = GameData.balance.get("endingThresholds", [])
	var overrides: Dictionary = GameData.balance.get("endingThresholdOverrides", {}).get(era_id, {})

	for threshold in thresholds:
		var resource_id: String = threshold.get("resource", "")
		if not resource_values.has(resource_id):
			continue
		var value: float = resource_values[resource_id]
		var limit: float = overrides.get(resource_id, threshold.get("value", 0))
		var comparison: String = threshold.get("comparison", "lte")
		var triggered := (comparison == "lte" and value <= limit) or (comparison == "gte" and value >= limit)
		if triggered:
			return threshold.get("ending", "")
	return ""


func _resolve_good_ending() -> String:
	var config: Dictionary = GameData.balance.get("goodEnding", {})
	var score_resources: Array = config.get("scoreResources", [])
	var total := 0.0
	for resource_id in score_resources:
		total += resource_values.get(resource_id, 0.0)
	var average := total / float(max(score_resources.size(), 1))
	if average >= float(config.get("ipoThreshold", 60)):
		return config.get("highEnding", "ipo")
	return config.get("lowEnding", "rachat")
