extends Node
## Autoload : état complet d'un mandat (run) — les 6 ressources persistantes,
## l'époque tirée au sort, les grandes décisions activées, le journal, et
## le panier d'effets en attente pour le sprint en cours.
##
## Modèle d'application (§11 du carnet de règles) : chaque phase d'un sprint
## (Inbox, Roadmap, Grandes décisions, Recrutement) calcule son effet et
## l'ajoute au panier via add_pending(). L'écran de Résolution applique tout
## le panier d'un coup via apply_pending_and_check(), affiche le delta réel,
## et détecte une éventuelle fin de mandat. Voir docs/carnet-de-regles.md §14
## pour le détail des décisions de conception (seuils, mapping, longueur).

signal ending_reached(id: String)

var sprint_number: int = 1
var team_profile: String = "junior"
var era_id: String = ""

var resource_values: Dictionary = {}   # resource_id -> float (0..100)
var capacity_bonus: int = 0            # cumulé sur le mandat, via recrutement
var activated_cards: Array = []        # ids des grandes décisions activées ce mandat
var activated_card_sprints: Dictionary = {}  # card_id -> numéro de sprint d'activation
var journal: Array = []                # [{sprint, text, deltas}], le plus ancien en premier

var pending_deltas: Dictionary = {}    # resource_id -> float, accumulés sur le sprint en cours
var pending_journal_lines: Array = []  # texte des choix faits pendant le sprint en cours

var is_mandate_over: bool = false
var ending_id: String = ""


## À appeler au lancement d'un nouveau mandat (bouton "Nouvelle partie").
func reset_run() -> void:
	sprint_number = 1
	team_profile = "junior"
	era_id = _pick_random_era()
	capacity_bonus = 0
	activated_cards.clear()
	activated_card_sprints.clear()
	journal.clear()
	pending_deltas.clear()
	pending_journal_lines.clear()
	is_mandate_over = false
	ending_id = ""

	resource_values.clear()
	var starting: Dictionary = GameData.balance.get("startingResources", {})
	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		resource_values[resource_id] = float(starting.get(resource_id, 50))


func _pick_random_era() -> String:
	var eras: Array = GameData.eras
	if eras.is_empty():
		return ""
	return eras[randi() % eras.size()].get("id", "")


func get_era() -> Dictionary:
	for era in GameData.eras:
		if era.get("id", "") == era_id:
			return era
	return {}


## Capacité de roadmap effective ce sprint (base + bonus cumulé de recrutement).
func get_effective_capacity() -> int:
	var base: int = GameData.roadmap_features.get("capacityMax", 3)
	return base + capacity_bonus


## Ajoute des deltas de ressources au panier du sprint en cours (pas encore
## appliqués aux jauges) et, optionnellement, une ligne de journal décrivant
## la décision qui les a produits.
func add_pending(deltas: Dictionary, note: String = "") -> void:
	for resource_id in deltas.keys():
		var value: float = float(deltas[resource_id])
		pending_deltas[resource_id] = pending_deltas.get(resource_id, 0.0) + value
	if note != "":
		pending_journal_lines.append(note)


## Applique le panier d'effets aux ressources, journalise le sprint, puis
## vérifie les fins de mandat (seuils de ressources, ou longueur atteinte).
## Retourne l'id de la fin atteinte, ou "" si le mandat continue.
## À appeler une seule fois par sprint, depuis l'écran de Résolution.
func apply_pending_and_check() -> String:
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
