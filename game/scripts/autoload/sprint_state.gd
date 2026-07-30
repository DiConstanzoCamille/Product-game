extends Node
## Autoload : état complet d'un mandat (run) — les 6 ressources persistantes,
## le scénario choisi, le roster (Phase A), les pièces, les pratiques, les
## grandes décisions activées, le journal, et le panier d'effets en attente
## pour le sprint en cours.
##
## Modèle d'application (§11 du carnet de règles) : chaque phase d'un sprint
## (Inbox, Roadmap, Grandes décisions, Marché) calcule son effet et
## l'ajoute au panier via add_pending(). L'écran de Résolution applique tout
## le panier d'un coup via apply_pending_and_check() — plus la masse
## salariale, les effets de roster/pratiques, la décroissance de la Valeur
## perçue, le revenu du modèle économique et le flux de pièces — affiche le
## delta réel, joue la revue de board au sprint 6, et détecte une éventuelle
## fin de mandat. Voir docs/carnet-de-regles.md §14-17 pour le détail des
## décisions de conception.

signal ending_reached(id: String)

var sprint_number: int = 1
var team_profile: String = "junior"
var era_id: String = ""
var business_model_id: String = ""
var company_id: String = ""
var pending_era_id: String = ""  # étape transitoire entre scenario_screen et company_select_screen

var resource_values: Dictionary = {}   # resource_id -> float (0..100)
var activated_cards: Array = []        # ids des grandes décisions activées ce mandat
var activated_card_sprints: Dictionary = {}  # card_id -> numéro de sprint d'activation
var journal: Array = []                # [{sprint, text, deltas}], le plus ancien en premier

var pending_deltas: Dictionary = {}    # resource_id -> float, accumulés sur le sprint en cours
var pending_journal_lines: Array = []  # texte des choix faits pendant le sprint en cours

var is_mandate_over: bool = false
var ending_id: String = ""

var last_revenue: int = 0              # revenu du modèle économique au dernier sprint résolu
var last_tresorerie_cost: int = 0      # somme des coûts/gains de décisions sur la trésorerie (hors revenu et masse salariale)
var last_payroll: int = 0              # masse salariale prélevée au dernier sprint résolu
var last_pieces_delta: int = 0         # flux net de pièces au dernier sprint résolu

# --- Phase A : l'entreprise ---
var pieces: int = 0                    # 🪙 budget d'action de l'entreprise (jamais négatif)
var roster: Array = []                 # employés {id, name, role, seniority, salary, trait, hidden_trait, hiddenRevealed, hiredSprint}
var owned_practices: Array = []        # ids de pratiques achetées (permanentes pour le mandat)
var fired_count: int = 0               # licenciements prononcés ce mandat (le cynisme monte à partir du 2e)
var next_hire_discount: int = 0        # remise 🪙 sur le prochain recrutement (trait caché Réseau)
var delivered_feature_ids: Array = []  # features livrées ce sprint (posées par l'écran Roadmap)
var board_review_state: String = "pending"  # "pending" | "passed" | "failed"
var board_review_result: Dictionary = {}    # {sprint, passed, title, conditions:[{label, ok}]} — pour l'overlay de verdict
var current_shop_offer: Dictionary = {}     # {sprint, candidates:[...], practices:[ids]} — tirage du Marché, pas de re-tirage

var _inbox_event_bag: Array = []       # ids restants à tirer dans le "sac" courant
var _last_inbox_event_id: String = ""  # évite une répétition immédiate entre deux sacs
var _candidate_bag: Array = []         # ids de candidats restants dans le "sac" du Marché
var _hired_candidate_ids: Array = []   # candidats déjà embauchés ce mandat (ne reviennent pas au tirage)


## À appeler au lancement d'un nouveau mandat, une fois le scénario et
## l'entreprise choisis (scenario_screen puis company_select_screen). Vide =
## tirage aléatoire parmi les options jouables (utile pour les tests headless).
func reset_run(chosen_era_id: String = "", chosen_company_id: String = "") -> void:
	sprint_number = 1
	era_id = chosen_era_id if chosen_era_id != "" else _pick_random_playable_era()
	company_id = chosen_company_id if chosen_company_id != "" else _pick_random_company(era_id)
	team_profile = get_company().get("teamProfile", "junior")
	business_model_id = GameData.balance.get("eraBusinessModel", {}).get(era_id, "")
	activated_cards.clear()
	activated_card_sprints.clear()
	journal.clear()
	pending_deltas.clear()
	pending_journal_lines.clear()
	is_mandate_over = false
	ending_id = ""
	last_revenue = 0
	last_tresorerie_cost = 0
	last_payroll = 0
	last_pieces_delta = 0
	_inbox_event_bag.clear()
	_last_inbox_event_id = ""
	_candidate_bag.clear()
	_hired_candidate_ids.clear()
	owned_practices.clear()
	fired_count = 0
	next_hire_discount = 0
	delivered_feature_ids.clear()
	board_review_state = "pending"
	board_review_result.clear()
	current_shop_offer.clear()

	var company: Dictionary = get_company()
	pieces = int(company.get("startingPieces", 0))
	roster.clear()
	var salaries: Dictionary = GameData.balance.get("salaries", {})
	for member in company.get("startingRoster", []):
		var seniority: String = member.get("seniority", "junior")
		roster.append({
			"id": member.get("id", ""),
			"name": member.get("name", ""),
			"role": member.get("role", ""),
			"seniority": seniority,
			"salary": int(salaries.get(seniority, 1)),
			"trait": member.get("trait", ""),
			"hidden_trait": "",
			"hiddenRevealed": true,  # l'équipe héritée a déjà fait sa période d'essai
			"hiredSprint": 0,
		})

	resource_values.clear()
	var starting: Dictionary = GameData.balance.get("startingResources", {})
	var overrides: Dictionary = GameData.balance.get("startingResourceOverrides", {}).get(company_id, {})
	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		resource_values[resource_id] = float(overrides.get(resource_id, starting.get(resource_id, 50)))


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


# --- Roster, rôles et capacité (spec profondeur §4) ---

func get_team_cap() -> int:
	return int(get_company().get("teamCap", 6))


func find_employee(employee_id: String) -> Dictionary:
	for employee in roster:
		if employee.get("id", "") == employee_id:
			return employee
	return {}


func get_hidden_trait(trait_id: String) -> Dictionary:
	for hidden_trait in GameData.hidden_traits.get("traits", []):
		if hidden_trait.get("id", "") == trait_id:
			return hidden_trait
	return {}


## Facteur de contribution d'un employé : 1.0 par défaut, réduit par un
## trait caché révélé de type Fantôme (contributionFactor).
func employee_contribution_factor(employee: Dictionary) -> float:
	if not employee.get("hiddenRevealed", false):
		return 1.0
	var hidden_trait: Dictionary = get_hidden_trait(employee.get("hidden_trait", ""))
	return float(hidden_trait.get("effects", {}).get("contributionFactor", 1.0))


## Poids effectif d'un rôle dans le roster (nombre d'employés pondéré par
## leur facteur de contribution) — sert aux pénalités d'absence et aux caps.
func get_role_weight(role_id: String) -> float:
	var total := 0.0
	for employee in roster:
		if employee.get("role", "") == role_id:
			total += employee_contribution_factor(employee)
	return total


## Capacité de roadmap produite par le roster ce sprint (spec §4.2) :
## Devs et PM produisent des points (rendements décroissants au-delà du cap
## de cumul de leur rôle), les Pépites révélées ajoutent leur bonus.
func get_effective_capacity() -> int:
	var roles: Dictionary = GameData.balance.get("roles", {})
	var total := 0.0
	var role_counts: Dictionary = {}

	for employee in roster:
		var role_id: String = employee.get("role", "")
		var role_conf: Dictionary = roles.get(role_id, {})
		var per_employee: float = float(role_conf.get("capacityPerEmployee", {}).get(employee.get("seniority", "junior"), 0))
		if per_employee > 0.0:
			var index: int = int(role_counts.get(role_id, 0))
			role_counts[role_id] = index + 1
			var yield_factor := 1.0
			if index >= int(role_conf.get("fullYieldCount", 99)):
				yield_factor = float(role_conf.get("extraYieldFactor", 0.5))
			total += per_employee * yield_factor * employee_contribution_factor(employee)

		if employee.get("hiddenRevealed", false):
			var hidden_trait: Dictionary = get_hidden_trait(employee.get("hidden_trait", ""))
			total += float(hidden_trait.get("effects", {}).get("capacityBonus", 0))

	return int(floor(max(total, 0.0)))


## Masse salariale du sprint — prélevée à chaque Résolution (spec §4.3).
func get_payroll() -> int:
	var total := 0
	for employee in roster:
		total += int(employee.get("salary", 0))
	return total


## Contexte de roster passé à EffectResolver.resolve_roadmap() — poids des
## rôles qui modulent les effets de la Roadmap (PM, Designer).
func get_roster_context() -> Dictionary:
	return {
		"pm_weight": get_role_weight("pm"),
		"designer_weight": get_role_weight("designer"),
	}


func has_practice(practice_id: String) -> bool:
	return owned_practices.has(practice_id)


func find_practice(practice_id: String) -> Dictionary:
	for practice in GameData.practices:
		if practice.get("id", "") == practice_id:
			return practice
	return {}


# --- Le Marché : tirage du sprint (spec profondeur §5) ---

## Offre du Marché pour le sprint en cours : 2 candidats (pioche sac, trait
## caché tiré à l'apparition) + 2 pratiques non possédées. Tirée une seule
## fois par sprint puis stockée — revenir sur l'écran ne retire pas.
func get_shop_offer() -> Dictionary:
	if int(current_shop_offer.get("sprint", -1)) == sprint_number:
		return current_shop_offer

	var draw_conf: Dictionary = GameData.balance.get("shopDraw", {})
	var candidate_count := int(draw_conf.get("candidatesPerSprint", 2))
	var practice_count := int(draw_conf.get("practicesPerSprint", 2))

	var drawn_candidates: Array = []
	for i in range(candidate_count):
		var candidate := _draw_candidate()
		if not candidate.is_empty():
			drawn_candidates.append(candidate)

	var practice_pool: Array = []
	for practice in GameData.practices:
		var eras: Array = practice.get("eras", [])
		if not eras.is_empty() and not eras.has(era_id):
			continue
		if owned_practices.has(practice.get("id", "")):
			continue
		practice_pool.append(practice.get("id", ""))
	practice_pool.shuffle()
	var drawn_practices: Array = practice_pool.slice(0, min(practice_count, practice_pool.size()))

	current_shop_offer = {
		"sprint": sprint_number,
		"candidates": drawn_candidates,
		"practices": drawn_practices,
	}
	return current_shop_offer


func _draw_candidate() -> Dictionary:
	if _candidate_bag.is_empty():
		for candidate in GameData.candidates:
			var eras: Array = candidate.get("eras", [])
			if not eras.is_empty() and not eras.has(era_id):
				continue
			if _hired_candidate_ids.has(candidate.get("id", "")):
				continue
			_candidate_bag.append(candidate.get("id", ""))
		_candidate_bag.shuffle()
	if _candidate_bag.is_empty():
		return {}

	var candidate_id: String = _candidate_bag.pop_back()
	if _hired_candidate_ids.has(candidate_id):
		return _draw_candidate()

	for candidate in GameData.candidates:
		if candidate.get("id", "") == candidate_id:
			var instance: Dictionary = candidate.duplicate(true)
			instance["hidden_trait"] = _roll_hidden_trait()
			instance["hiddenRevealed"] = has_practice("entretiens-structures")
			instance["hired"] = false
			return instance
	return {}


## Tirage du trait caché à l'apparition du candidat (spec §4.5) — le même
## nom peut cacher autre chose dans une autre run. "" = aucun trait caché.
func _roll_hidden_trait() -> String:
	var distribution: Dictionary = GameData.hidden_traits.get("distribution", {})
	var none_weight := float(distribution.get("none", 50))
	var negative_weight := float(distribution.get("negative", 30))
	var positive_weight := float(distribution.get("positive", 20))
	var roll := randf() * (none_weight + negative_weight + positive_weight)

	var polarity := ""
	if roll < none_weight:
		return ""
	elif roll < none_weight + negative_weight:
		polarity = "negative"
	else:
		polarity = "positive"

	var pool: Array = []
	for hidden_trait in GameData.hidden_traits.get("traits", []):
		if hidden_trait.get("polarity", "") == polarity:
			pool.append(hidden_trait.get("id", ""))
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]


## Embauche un candidat de l'offre du sprint. Retourne "" si l'embauche a eu
## lieu, sinon la raison du refus ("pieces" ou "cap").
func hire_candidate(candidate: Dictionary) -> String:
	if roster.size() >= get_team_cap():
		return "cap"
	var cost: int = max(0, int(candidate.get("costPieces", 0)) - next_hire_discount)
	if pieces < cost:
		return "pieces"

	pieces -= cost
	var discount_note := ""
	if next_hire_discount > 0:
		discount_note = " (réseau : −%d 🪙)" % next_hire_discount
		next_hire_discount = 0

	roster.append({
		"id": candidate.get("id", ""),
		"name": candidate.get("name", ""),
		"role": candidate.get("role", ""),
		"seniority": candidate.get("seniority", "junior"),
		"salary": int(candidate.get("salary", GameData.balance.get("salaries", {}).get(candidate.get("seniority", "junior"), 1))),
		"trait": candidate.get("trait", ""),
		"hidden_trait": candidate.get("hidden_trait", ""),
		"hiddenRevealed": candidate.get("hiddenRevealed", false),
		"hiredSprint": sprint_number,
	})
	_hired_candidate_ids.append(candidate.get("id", ""))
	candidate["hired"] = true
	pending_journal_lines.append("Embauche : %s (%s, %d 🪙)%s" % [
		candidate.get("name", ""), _role_label(candidate.get("role", "")), cost, discount_note
	])
	return ""


## Licencie un employé du roster (spec §4.4) : indemnités en pièces, Moral en
## baisse, et Cynisme en hausse à partir du 2e licenciement du mandat.
## Retourne "" si le licenciement a eu lieu, sinon la raison du refus.
func fire_employee(employee_id: String) -> String:
	var employee := find_employee(employee_id)
	if employee.is_empty():
		return "introuvable"
	var firing: Dictionary = GameData.balance.get("firing", {})
	var severance := int(firing.get("severancePieces", 2))
	if pieces < severance:
		return "pieces"

	pieces -= severance
	fired_count += 1
	var deltas: Dictionary = {"moral": float(firing.get("moral", -4))}
	var note := "Licenciement : %s — indemnités %d 🪙" % [employee.get("name", ""), severance]
	if fired_count >= 2:
		deltas["cynisme"] = float(firing.get("cynismePerExtraFiring", 3))
		note += " (l'organisation commence à y voir une politique)"
	add_pending(deltas, note)
	roster.erase(employee)
	return ""


## Achète une pratique de l'offre du sprint (+2 Cynisme — un process de
## plus). Retourne "" si l'achat a eu lieu, sinon la raison du refus.
func buy_practice(practice_id: String) -> String:
	if owned_practices.has(practice_id):
		return "possedee"
	var practice := find_practice(practice_id)
	if practice.is_empty():
		return "introuvable"
	var cost := int(practice.get("costPieces", 0))
	if pieces < cost:
		return "pieces"

	pieces -= cost
	owned_practices.append(practice_id)
	var cynisme := float(GameData.balance.get("shopDraw", {}).get("practiceCynisme", 2))
	add_pending({"cynisme": cynisme}, "Nouvelle pratique : %s %s (%d 🪙) — un process de plus, l'organisation lève les yeux au ciel" % [
		practice.get("icon", ""), practice.get("name", ""), cost
	])

	# Entretiens structurés : les candidats déjà sur l'étal arrivent révélés aussi.
	if practice_id == "entretiens-structures":
		for candidate in current_shop_offer.get("candidates", []):
			candidate["hiddenRevealed"] = true
	return ""


func _role_label(role_id: String) -> String:
	var role_conf: Dictionary = GameData.balance.get("roles", {}).get(role_id, {})
	return role_conf.get("label", role_id)


# --- Inbox ---

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
## la décision qui les a produits. La clé "pieces" est acceptée comme
## pseudo-ressource : appliquée au budget d'action à la Résolution.
func add_pending(deltas: Dictionary, note: String = "") -> void:
	for resource_id in deltas.keys():
		var value: float = float(deltas[resource_id])
		pending_deltas[resource_id] = pending_deltas.get(resource_id, 0.0) + value
	if note != "":
		pending_journal_lines.append(note)


## Revenu du sprint selon le modèle économique du scénario (§15, remanié en
## Phase A) — proportionnel à la Valeur perçue au-dessus du seuil de
## notoriété (offset), érodé par un Moral bas (churn). Sous le seuil de
## décrochage (pressure.revenueCutoffValeurPercue), plus aucun revenu :
## la mort passe par la spirale économique, plus de couperet direct (§8.3).
func compute_revenue() -> int:
	var model: Dictionary = get_business_model()
	if model.is_empty():
		return 0

	var valeur: float = resource_values.get("valeur-percue", 0.0)
	var cutoff: float = float(GameData.balance.get("pressure", {}).get("revenueCutoffValeurPercue", 5))
	if valeur <= cutoff:
		return 0

	var moral: float = resource_values.get("moral", 0.0)
	var per_point: float = model.get("revenuePerValeurPercuePoint", 0.0)
	var offset: float = model.get("revenueValeurPercueOffset", 0.0)
	var floor_factor: float = model.get("moralChurnFloor", 0.4)
	var ceiling_factor: float = model.get("moralChurnCeiling", 1.2)
	var moral_factor: float = clamp(moral / 100.0, floor_factor, ceiling_factor)

	return int(round(max(valeur - offset, 0.0) * per_point * moral_factor))


## Applique le panier d'effets aux ressources (+ masse salariale, effets de
## roster et de pratiques, décroissance de la Valeur perçue, revenu du
## sprint et flux de pièces), journalise, joue la revue de board au sprint 6,
## puis vérifie les fins de mandat (seuils de ressources, ou longueur
## atteinte). Retourne l'id de la fin atteinte, ou "" si le mandat continue.
## À appeler une seule fois par sprint, depuis l'écran de Résolution.
func apply_pending_and_check() -> String:
	last_tresorerie_cost = int(round(pending_deltas.get("tresorerie", 0.0)))

	_apply_per_sprint_effects()
	_apply_payroll()
	_apply_revenue()
	_apply_pieces_flow()

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

	if last_pieces_delta != 0:
		applied["pieces"] = last_pieces_delta

	journal.append({
		"sprint": sprint_number,
		"text": " · ".join(pending_journal_lines) if not pending_journal_lines.is_empty() else "Sprint calme — aucune décision marquante.",
		"deltas": EffectResolver.format_deltas(applied),
	})

	pending_deltas.clear()
	pending_journal_lines.clear()
	delivered_feature_ids.clear()

	_resolve_trial_periods()
	_resolve_silent_quits()

	if sprint_number == int(GameData.balance.get("trimesterLengthSprints", 6)) and board_review_state == "pending":
		_run_board_review()

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


## Effets automatiques du sprint : entretien Ops (ou dérive de dette en leur
## absence), traits cachés révélés à effet continu, pratiques à effet
## par sprint, et décroissance naturelle de la Valeur perçue (§8.1).
func _apply_per_sprint_effects() -> void:
	var roles: Dictionary = GameData.balance.get("roles", {})
	var ops_conf: Dictionary = roles.get("ops", {})
	var ops_weight := get_role_weight("ops")
	if ops_weight <= 0.0:
		var drift := float(ops_conf.get("dettePerSprintIfAbsent", 2))
		if drift != 0.0:
			add_pending({"dette-organisationnelle": drift},
				"🛠️ Personne aux manettes Ops — la dette monte toute seule (+%d)" % int(drift))
	else:
		var relief: float = max(ops_weight * float(ops_conf.get("dettePerOps", -1)), float(ops_conf.get("detteReliefMax", -2)))
		if relief != 0.0:
			add_pending({"dette-organisationnelle": relief})

	var moral_from_traits := 0.0
	for employee in roster:
		if not employee.get("hiddenRevealed", false):
			continue
		var hidden_trait := get_hidden_trait(employee.get("hidden_trait", ""))
		moral_from_traits += float(hidden_trait.get("effects", {}).get("moralPerSprint", 0))
	if moral_from_traits != 0.0:
		add_pending({"moral": moral_from_traits})

	for practice_id in owned_practices:
		var practice := find_practice(practice_id)
		var per_sprint: Dictionary = practice.get("perSprint", {})
		if not per_sprint.is_empty():
			add_pending(per_sprint)

	var decay := float(GameData.balance.get("pressure", {}).get("valeurPercueDecayPerSprint", 2))
	if decay != 0.0:
		add_pending({"valeur-percue": -decay},
			"📈 Le marché avance sans vous attendre : Valeur perçue −%d" % int(decay))


func _apply_payroll() -> void:
	last_payroll = get_payroll()
	if last_payroll > 0:
		pending_deltas["tresorerie"] = pending_deltas.get("tresorerie", 0.0) - last_payroll
		pending_journal_lines.append("Masse salariale : −%d 💰 (%d personnes)" % [last_payroll, roster.size()])


func _apply_revenue() -> void:
	last_revenue = compute_revenue()
	if last_revenue != 0:
		pending_deltas["tresorerie"] = pending_deltas.get("tresorerie", 0.0) + last_revenue
		var model_label: String = get_business_model().get("label", "revenu")
		pending_journal_lines.append("Revenus (%s) : %s%d" % [
			model_label, "+" if last_revenue >= 0 else "−", abs(last_revenue)
		])
	elif resource_values.get("valeur-percue", 100.0) <= float(GameData.balance.get("pressure", {}).get("revenueCutoffValeurPercue", 5)):
		pending_journal_lines.append("📉 Valeur perçue en décrochage — plus aucun revenu ce sprint.")


## Flux de pièces de la Résolution (§3) : allocation du board (réduite si la
## revue a été ratée), prime de performance sur le revenu, et deltas de
## pièces accumulés pendant le sprint (quick wins, événements Inbox).
func _apply_pieces_flow() -> void:
	var pieces_conf: Dictionary = GameData.balance.get("pieces", {})
	var allocation := int(pieces_conf.get("boardAllocationPerSprint", 2))
	if board_review_state == "failed":
		allocation = int(pieces_conf.get("boardAllocationIfReviewFailed", 1))
	var divider := int(pieces_conf.get("revenuePerformanceDivider", 4))
	var performance := 0
	if divider > 0 and last_revenue > 0:
		performance = int(floor(float(last_revenue) / float(divider)))

	var pending_pieces := int(round(pending_deltas.get("pieces", 0.0)))
	pending_deltas.erase("pieces")

	var total := allocation + performance + pending_pieces
	var before := pieces
	pieces = max(0, pieces + total)
	last_pieces_delta = pieces - before

	var parts: Array = ["allocation +%d" % allocation]
	if performance > 0:
		parts.append("performance +%d" % performance)
	if pending_pieces != 0:
		parts.append("décisions %s%d" % ["+" if pending_pieces >= 0 else "−", abs(pending_pieces)])
	pending_journal_lines.append("🪙 Pièces : %s (solde %d)" % [" · ".join(parts), pieces])


## Fin de période d'essai (§4.5) : embauche + trialPeriodSprints sprints —
## le trait caché se révèle, ses effets s'appliquent désormais, et les
## traits à déclencheur (Négociateur, Réseau) tombent maintenant.
func _resolve_trial_periods() -> void:
	var trial := int(GameData.balance.get("trialPeriodSprints", 2))
	for employee in roster:
		if employee.get("hiddenRevealed", false):
			continue
		if sprint_number < int(employee.get("hiredSprint", 0)) + trial:
			continue
		employee["hiddenRevealed"] = true

		var trait_id: String = employee.get("hidden_trait", "")
		if trait_id == "":
			journal.append({
				"sprint": sprint_number,
				"text": "Fin de période d'essai : %s est exactement ce que le CV promettait. Ça arrive." % employee.get("name", ""),
				"deltas": "",
			})
			continue

		var hidden_trait := get_hidden_trait(trait_id)
		var extra := ""
		var effects: Dictionary = hidden_trait.get("effects", {})
		if effects.has("salaryRaiseAtTrialEnd"):
			var raise_amount := int(effects.get("salaryRaiseAtTrialEnd", 1))
			employee["salary"] = int(employee.get("salary", 1)) + raise_amount
			extra = " Une offre concurrente sur la table : +%d de salaire, ou un départ." % raise_amount
		if effects.has("nextHireDiscountPieces"):
			next_hire_discount += int(effects.get("nextHireDiscountPieces", 0))
			extra = " Son carnet d'adresses vaut %d 🪙 sur le prochain recrutement." % int(effects.get("nextHireDiscountPieces", 0))

		journal.append({
			"sprint": sprint_number,
			"text": "Fin de période d'essai : %s est un·e %s %s — %s%s" % [
				employee.get("name", ""), hidden_trait.get("name", ""), hidden_trait.get("icon", ""),
				hidden_trait.get("description", ""), extra
			],
			"deltas": "",
		})


## Démissions silencieuses (§4.5) : l'employé au trait révélé part sans
## prévenir au sprint d'embauche + N.
func _resolve_silent_quits() -> void:
	var leavers: Array = []
	for employee in roster:
		if not employee.get("hiddenRevealed", false):
			continue
		var hidden_trait := get_hidden_trait(employee.get("hidden_trait", ""))
		var quits_at := int(hidden_trait.get("effects", {}).get("quitsAtHiredPlus", 0))
		if quits_at > 0 and sprint_number >= int(employee.get("hiredSprint", 0)) + quits_at:
			leavers.append(employee)
	for employee in leavers:
		roster.erase(employee)
		journal.append({
			"sprint": sprint_number,
			"text": "🧨 %s a démissionné sans prévenir. Le badge est resté sur le bureau, le Slack est déjà désactivé." % employee.get("name", ""),
			"deltas": "",
		})


## La revue de board (§8.2) — le "boss" de mi-mandat : l'état de la boîte
## est comparé aux objectifs fixés par l'entreprise à l'embauche.
func _run_board_review() -> void:
	var objectives: Dictionary = get_company().get("boardObjectives", {})
	var review_conf: Dictionary = GameData.balance.get("pressure", {}).get("boardReview", {})
	var conditions: Array = []
	var all_ok := true

	for condition in objectives.get("conditions", []):
		var ok := false
		match condition.get("type", ""):
			"resource-max":
				ok = resource_values.get(condition.get("resource", ""), 0.0) <= float(condition.get("value", 0))
			"resource-min":
				ok = resource_values.get(condition.get("resource", ""), 0.0) >= float(condition.get("value", 0))
			"decisions-min":
				ok = activated_cards.size() >= int(condition.get("value", 1))
			"revenue-min":
				ok = last_revenue >= int(condition.get("value", 0))
		conditions.append({"label": condition.get("label", ""), "ok": ok})
		if not ok:
			all_ok = false

	var bounds: Dictionary = GameData.balance.get("resourceBounds", {"min": 0, "max": 100})
	if all_ok:
		board_review_state = "passed"
		pieces += int(review_conf.get("successPieces", 5))
		var gain := float(review_conf.get("successCapitalPolitique", 8))
		resource_values["capital-politique"] = clamp(
			resource_values.get("capital-politique", 0.0) + gain, float(bounds.get("min", 0)), float(bounds.get("max", 100)))
		journal.append({
			"sprint": sprint_number,
			"text": "🏛️ Revue de board : objectifs tenus. Le comité applaudit poliment et débloque du budget d'action (+%d 🪙, 🎯 +%d)." % [
				int(review_conf.get("successPieces", 5)), int(gain)
			],
			"deltas": "",
		})
	else:
		board_review_state = "failed"
		var loss := float(review_conf.get("failCapitalPolitique", -12))
		resource_values["capital-politique"] = clamp(
			resource_values.get("capital-politique", 0.0) + loss, float(bounds.get("min", 0)), float(bounds.get("max", 100)))
		journal.append({
			"sprint": sprint_number,
			"text": "🏛️ Revue de board : objectifs manqués. Le comité « prend note » (🎯 %d), et l'allocation de pièces est réduite pour le reste du mandat." % int(loss),
			"deltas": "",
		})

	board_review_result = {
		"sprint": sprint_number,
		"passed": all_ok,
		"title": objectives.get("title", ""),
		"conditions": conditions,
	}


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
