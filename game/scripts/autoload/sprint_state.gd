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
## perçue, le revenu du modèle économique, le flux de pièces et la
## régénération d'Énergie du joueur — affiche le delta réel, joue la revue
## de board au sprint 6, et détecte une éventuelle fin de mandat. Voir
## docs/carnet-de-regles.md §14-18 pour le détail des décisions de conception.

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
var last_roi_revenue_bonus: int = 0    # part MRR du revenu du sprint résolu

# --- Phase A : l'entreprise ---
var pieces: int = 0                    # 🪙 budget d'action de l'entreprise (jamais négatif)
var roster: Array = []                 # employés {id, name, role, seniority, salary, trait, hidden_trait, hiddenRevealed, hiredSprint}
var owned_practices: Array = []        # ids de pratiques achetées (permanentes pour le mandat)
var fired_count: int = 0               # licenciements prononcés ce mandat (le cynisme monte à partir du 2e)
var next_hire_discount: int = 0        # remise 🪙 sur le prochain recrutement (trait caché Réseau)
var current_backlog_draw: Dictionary = {}  # {sprint, items} — tirage Roadmap persistant
var epic_progress: Dictionary = {}         # epic_id -> {invested, startedSprint}
var completed_backlog_ids: Array = []      # livraisons définitives, hors du sac
var revealed_backlog_sprint: Dictionary = {}  # feature_id -> sprint du Plonger temporaire
var recurring_roi: int = 0                 # bonus de MRR permanent acquis par les livraisons
var last_roadmap_report: Dictionary = {}   # livraison réelle affichée à la Résolution
var board_review_state: String = "pending"  # "pending" | "passed" | "failed"
var board_review_result: Dictionary = {}    # {sprint, passed, title, conditions:[{label, ok}]} — pour l'overlay de verdict
var current_shop_offer: Dictionary = {}     # {sprint, candidates:[...], practices:[ids], decisions:[ids], leased:[ids], rerolls} — tirage des Investissements
var reserved_assets: Array = []             # 📌 [{kind, id, data, sprint, paid}] — punaisés, réinjectés dans l'offre suivante
var leased_decisions: Dictionary = {}       # 🔒 card_id -> sprint d'expiration du bail d'une carte à prérequis

# --- Phase B : l'économie du joueur (spec profondeur §7) ---
var energy: int = 70                   # ⚡ jauge personnelle du CPO (0..energy.max), côté jeu uniquement
var energy_spent_this_sprint: int = 0  # ⚡ réellement dépensés en actions personnelles depuis la dernière Résolution
var self_work_capacity: int = 0        # points de capacité ajoutés par "Faire le taf soi-même" ce sprint
var breather_planned: bool = false     # Souffler pris à la dernière Résolution : actions bloquées ce sprint, bonus de régén à la prochaine
var last_energy_report: Dictionary = {}  # détail du delta Énergie de la dernière Résolution (pour l'affichage)

var _inbox_event_bag: Array = []       # ids restants à tirer dans le "sac" courant
var _last_inbox_event_id: String = ""  # évite une répétition immédiate entre deux sacs
var _hired_candidate_ids: Array = []   # candidats déjà embauchés ce mandat (ne reviennent pas au tirage)
var _backlog_bag: Array = []           # sac des propositions de Roadmap, filtré par ère


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
	last_roi_revenue_bonus = 0
	_inbox_event_bag.clear()
	_last_inbox_event_id = ""
	_hired_candidate_ids.clear()
	_backlog_bag.clear()
	reserved_assets.clear()
	leased_decisions.clear()
	owned_practices.clear()
	fired_count = 0
	next_hire_discount = 0
	current_backlog_draw.clear()
	epic_progress.clear()
	completed_backlog_ids.clear()
	revealed_backlog_sprint.clear()
	recurring_roi = 0
	last_roadmap_report.clear()
	board_review_state = "pending"
	board_review_result.clear()
	current_shop_offer.clear()
	energy = int(get_energy_conf().get("start", 70))
	energy_spent_this_sprint = 0
	self_work_capacity = 0
	breather_planned = false
	last_energy_report.clear()

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
## de cumul de leur rôle), les Pépites révélées ajoutent leur bonus, et
## "Faire le taf soi-même" (§7.2) ajoute les points payés en Énergie.
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

	return int(floor(max(total, 0.0))) + self_work_capacity


## Masse salariale du sprint — prélevée à chaque Résolution (spec §4.3).
func get_payroll() -> int:
	var total := 0
	for employee in roster:
		total += int(employee.get("salary", 0))
	return total


## Contexte de roster passé à EffectResolver.resolve_backlog() — poids des
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


# --- L'économie du joueur : Énergie ⚡ et actions personnelles (spec §7) ---

func get_energy_conf() -> Dictionary:
	return GameData.balance.get("energy", {})


func get_energy_max() -> int:
	return int(get_energy_conf().get("max", 100))


func get_personal_action_conf(action_id: String) -> Dictionary:
	return get_energy_conf().get("actions", {}).get(action_id, {})


func get_personal_action_cost(action_id: String) -> int:
	return int(get_personal_action_conf(action_id).get("cost", 0))


## Facteur de régénération d'Énergie selon le Moral de l'équipe (§7.1) —
## une équipe qui va mal vous épuise. Paliers dans balance.json →
## energy.moralRegenTiers (×1 si Moral ≥ 60, ×0.5 si 30-60, ×0 sous 30).
func get_energy_regen_factor() -> float:
	var moral: float = resource_values.get("moral", 0.0)
	for tier in get_energy_conf().get("moralRegenTiers", []):
		if moral >= float(tier.get("moralMin", 0)):
			return float(tier.get("factor", 1.0))
	return 0.0


## Une action personnelle payante est-elle jouable ? "" si oui, sinon la
## raison du refus : "souffler" (retrait annoncé à la dernière Résolution)
## ou "epuise" (jauge à zéro). Une seule ressource limite les actions —
## l'Énergie — et on peut puiser dans la réserve jusqu'à 0 (et le payer).
func personal_action_refusal() -> String:
	if breather_planned:
		return "souffler"
	if energy <= 0:
		return "epuise"
	return ""


## Dépense l'Énergie d'une action (plancher 0 — on ne paie que ce qui
## reste dans la jauge ; le burn-out, lui, se joue à la Résolution).
func _spend_energy(cost: int) -> void:
	var spent: int = min(cost, energy)
	energy -= spent
	energy_spent_this_sprint += spent


## 🤝 1:1 (§7.2) — révèle le trait caché d'un candidat du Marché (avant
## embauche) ou d'un employé du roster. Sur un employé, les traits à
## déclencheur (Négociateur, Réseau) tombent immédiatement : la
## conversation met le sujet sur la table. Retourne "" si l'action a eu lieu.
func do_one_on_one(person: Dictionary) -> String:
	var refusal := personal_action_refusal()
	if refusal != "":
		return refusal
	if person.get("hiddenRevealed", false):
		return "deja-revele"

	var cost := get_personal_action_cost("oneOnOne")
	_spend_energy(cost)
	person["hiddenRevealed"] = true

	var hidden_trait := get_hidden_trait(person.get("hidden_trait", ""))
	var verdict := ""
	if hidden_trait.is_empty():
		verdict = "rien à signaler. Vraiment."
	else:
		verdict = "%s %s — %s" % [
			hidden_trait.get("icon", ""), hidden_trait.get("name", ""), hidden_trait.get("description", "")
		]
	var extra := ""
	if person.has("hiredSprint"):  # employé du roster (un candidat n'a pas encore de sprint d'embauche)
		extra = _apply_trait_triggers(person)
	pending_journal_lines.append("🤝 1:1 avec %s (−%d ⚡) : %s%s" % [
		person.get("name", ""), cost, verdict, extra
	])
	return ""


## 🔧 Faire le taf soi-même (§7.2) — +N points de capacité ce sprint,
## payés en Énergie. Cumulable tant qu'il reste de l'Énergie.
func do_self_work() -> String:
	var refusal := personal_action_refusal()
	if refusal != "":
		return refusal
	var conf := get_personal_action_conf("selfWork")
	var bonus := int(conf.get("capacityBonus", 2))
	_spend_energy(int(conf.get("cost", 25)))
	self_work_capacity += bonus
	pending_journal_lines.append("🔧 Vous faites le taf vous-même (−%d ⚡) : +%d points de capacité ce sprint. Le CPO code, l'équipe regarde ailleurs." % [
		int(conf.get("cost", 25)), bonus
	])
	return ""


## 🏛️ Négocier une rallonge (§7.2) — votre Capital politique contre des
## Pièces pour l'entreprise. Les pièces tombent immédiatement (le Marché du
## sprint en profite) ; le Capital politique se règle à la Résolution,
## comme tous les effets de ressources.
func do_negotiate_extension() -> String:
	var refusal := personal_action_refusal()
	if refusal != "":
		return refusal
	var conf := get_personal_action_conf("extension")
	var gained := int(conf.get("pieces", 4))
	var capital := int(conf.get("capitalPolitique", -8))
	_spend_energy(int(conf.get("cost", 10)))
	pieces += gained
	add_pending({"capital-politique": float(capital)},
		"🏛️ Rallonge négociée au board (−%d ⚡) : +%d 🪙 immédiats, 🎯 Capital politique %d — tout le monde a noté que vous êtes venu·e quémander" % [
			int(conf.get("cost", 10)), gained, capital
		])
	return ""


## 🧘 Souffler (§7.2) — pris à la Résolution : renoncer aux actions
## personnelles du prochain sprint contre un bonus de régénération à la
## prochaine Résolution. Gratuit — ça coûte du temps, pas de l'énergie.
func plan_breather() -> String:
	if breather_planned:
		return "deja-planifie"
	breather_planned = true
	journal.append({
		"sprint": sprint_number,
		"text": "🧘 Vous soufflez : aucune action personnelle au prochain sprint, +%d de régénération d'Énergie à la clé. Le téléphone dort dans l'entrée." % int(get_energy_conf().get("breatherRegenBonus", 10)),
		"deltas": "",
	})
	return ""


# --- Roadmap profonde : backlog, epics et informations révélées (spec §6) ---

func get_backlog_offer() -> Dictionary:
	if int(current_backlog_draw.get("sprint", -1)) == sprint_number:
		return current_backlog_draw
	current_backlog_draw = _draw_backlog_offer()
	return current_backlog_draw


func find_backlog_item(item_id: String) -> Dictionary:
	for feature in GameData.backlog.get("features", []):
		if feature.get("id", "") == item_id:
			return feature
	for epic in GameData.backlog.get("epics", []):
		if epic.get("id", "") == item_id:
			return epic
	return {}


func is_backlog_epic(item: Dictionary) -> bool:
	return bool(item.get("epic", false))


func get_epic_invested(item_id: String) -> int:
	return int(epic_progress.get(item_id, {}).get("invested", 0))


func get_epic_remaining(item_id: String) -> int:
	var item := find_backlog_item(item_id)
	return max(0, int(item.get("costPoints", 0)) - get_epic_invested(item_id))


func get_epic_started_sprint(item_id: String) -> int:
	return int(epic_progress.get(item_id, {}).get("startedSprint", 0))


## Abandonne un epic entamé : les points engagés sont perdus, le chantier
## quitte l'offre actuelle et redevient éligible à un futur cycle du sac.
func abandon_epic(item_id: String) -> String:
	if not epic_progress.has(item_id):
		return "pas-en-cours"
	var item := find_backlog_item(item_id)
	if item.is_empty() or not is_backlog_epic(item):
		return "introuvable"
	var lost_points := get_epic_invested(item_id)
	epic_progress.erase(item_id)
	var retained: Array = []
	for offered_item in get_backlog_offer().get("items", []):
		if offered_item.get("id", "") != item_id:
			retained.append(offered_item)
	current_backlog_draw["items"] = retained
	pending_journal_lines.append("Abandon de l'epic %s : %d points engagés sont perdus. Le chantier retournera peut-être un jour sur la table." % [
		item.get("name", item_id), lost_points
	])
	return ""


func backlog_attribute_revealed(item_id: String, attribute: String) -> bool:
	for practice_id in owned_practices:
		if find_practice(practice_id).get("unlocks", "") == attribute:
			return true
	return int(revealed_backlog_sprint.get(item_id, -1)) == sprint_number


func do_feature_dive(item_id: String) -> String:
	var refusal := personal_action_refusal()
	if refusal != "":
		return refusal
	if find_backlog_item(item_id).is_empty() or not _backlog_offer_contains(item_id):
		return "introuvable"
	if int(revealed_backlog_sprint.get(item_id, -1)) == sprint_number:
		return "deja-revele"

	var cost := get_personal_action_cost("featureDive")
	_spend_energy(cost)
	revealed_backlog_sprint[item_id] = sprint_number
	pending_journal_lines.append("🔬 Plongée dans %s (−%d ⚡) : les vrais chiffres sortent enfin du tableur." % [
		find_backlog_item(item_id).get("name", item_id), cost
	])
	return ""


func backlog_plan_points(plan: Array) -> int:
	var total := 0
	for entry in plan:
		total += max(0, int(entry.get("points", 0)))
	return total


## Enregistre le choix de Roadmap. L'UI ne fait que construire `plan`; ici les
## points sont consommés, les epics progressent, et seuls les items terminés
## produisent leurs attributs réels.
func commit_backlog_plan(plan: Array) -> Dictionary:
	var offer := get_backlog_offer()
	var available: Dictionary = {}
	for item in offer.get("items", []):
		available[item.get("id", "")] = item

	var spent := 0
	var delivered: Array = []
	var epic_updates: Array = []
	var seen: Dictionary = {}
	for entry in plan:
		var item_id: String = entry.get("id", "")
		if seen.has(item_id) or completed_backlog_ids.has(item_id) or not available.has(item_id):
			continue
		seen[item_id] = true
		var item: Dictionary = available[item_id]
		if is_backlog_epic(item):
			var invested: int = min(max(0, int(entry.get("points", 0))), get_epic_remaining(item_id))
			if invested <= 0:
				continue
			var progress: Dictionary = epic_progress.get(item_id, {"invested": 0, "startedSprint": sprint_number})
			progress["invested"] = int(progress.get("invested", 0)) + invested
			epic_progress[item_id] = progress
			spent += invested
			if int(progress["invested"]) >= int(item.get("costPoints", 0)):
				epic_progress.erase(item_id)
				completed_backlog_ids.append(item_id)
				delivered.append(item)
				epic_updates.append({"item": item, "invested": invested, "completed": true})
			else:
				epic_updates.append({"item": item, "invested": invested, "completed": false})
		else:
			var cost := int(item.get("costPoints", 0))
			if cost <= 0:
				continue
			spent += cost
			delivered.append(item)
			completed_backlog_ids.append(item_id)

	var capacity := get_effective_capacity()
	var deltas := EffectResolver.resolve_backlog(delivered, spent, capacity, get_roster_context(), has_practice("okr"))
	var roi_gain := 0
	for item in delivered:
		roi_gain += int(item.get("roi", 0))
	recurring_roi += roi_gain

	if not deltas.is_empty():
		add_pending(deltas)
	last_roadmap_report = {
		"sprint": sprint_number,
		"plannedPoints": spent,
		"capacity": capacity,
		"delivered": delivered,
		"epicUpdates": epic_updates,
		"roiGain": roi_gain,
		"deltas": deltas,
	}
	pending_journal_lines.append("Roadmap : %d pts / %d capacité%s" % [
		spent, capacity, " · %d livraison(s)" % delivered.size() if not delivered.is_empty() else ""
	])
	return last_roadmap_report


func _draw_backlog_offer() -> Dictionary:
	var conf: Dictionary = GameData.balance.get("backlogDraw", {})
	var minimum := int(conf.get("itemsPerSprintMin", 0))
	var maximum: int = max(minimum, int(conf.get("itemsPerSprintMax", minimum)))
	var items: Array = _active_epic_items()
	var target_total: int = randi_range(minimum, maximum)
	var regular_count: int = max(0, target_total - items.size())
	while regular_count > 0 and items.size() < maximum:
		var item := _draw_backlog_item(items)
		if item.is_empty():
			break
		items.append(item)
		regular_count -= 1
	return {"sprint": sprint_number, "items": items}


func _active_epic_items() -> Array:
	var result: Array = []
	for item_id in epic_progress.keys():
		var item := find_backlog_item(item_id)
		if not item.is_empty() and get_epic_remaining(item_id) > 0:
			result.append(item)
	return result


func _draw_backlog_item(already_drawn: Array) -> Dictionary:
	var excluded: Dictionary = {}
	for item in already_drawn:
		excluded[item.get("id", "")] = true
	var attempts := 0
	var max_attempts: int = max(1, GameData.backlog.get("features", []).size() + GameData.backlog.get("epics", []).size()) * 2
	while attempts < max_attempts:
		if _backlog_bag.is_empty():
			_refill_backlog_bag()
		if _backlog_bag.is_empty():
			return {}
		var item_id: String = _backlog_bag.pop_back()
		var item := find_backlog_item(item_id)
		attempts += 1
		if item.is_empty() or excluded.has(item_id) or completed_backlog_ids.has(item_id):
			continue
		return item
	return {}


func _refill_backlog_bag() -> void:
	for feature in GameData.backlog.get("features", []):
		if _available_for_era(feature) and not completed_backlog_ids.has(feature.get("id", "")):
			_backlog_bag.append(feature.get("id", ""))
	for epic in GameData.backlog.get("epics", []):
		if _available_for_era(epic) and not completed_backlog_ids.has(epic.get("id", "")):
			_backlog_bag.append(epic.get("id", ""))
	_backlog_bag.shuffle()


func _backlog_offer_contains(item_id: String) -> bool:
	for item in get_backlog_offer().get("items", []):
		if item.get("id", "") == item_id:
			return true
	return false


# --- Les Investissements : tirage du sprint (spec profondeur §5) ---

## Offre du sprint en cours — **un seul rayon, trois types mélangés**.
## `slotsPerSprint` emplacements tirés dans un pool commun (candidats,
## pratiques, grandes décisions), avec un minimum garanti par type
## (`guaranteedPerSprint`) pour qu'aucun sprint ne soit totalement inutile, et
## le reste au hasard entre types (`typeWeights`). Certains sprints proposent
## donc trois décisions et un seul candidat, d'autres l'inverse.
##
## Tirée une seule fois par sprint puis stockée — revenir sur l'écran ne
## re-tire pas ; seul 🎲 Re-tirer l'offre, qui se paie, change la donne.
##
## `slots` porte l'ordre d'affichage (mélangé : c'est tout l'intérêt de mettre
## les trois types en concurrence) ; `candidates`/`practices`/`decisions` sont
## les mêmes Actifs regroupés par type, pour le reste du code.
func get_shop_offer() -> Dictionary:
	if int(current_shop_offer.get("sprint", -1)) == sprint_number:
		return current_shop_offer
	current_shop_offer = _draw_shop_offer(0)
	return current_shop_offer


const ASSET_KINDS := ["candidate", "practice", "decision"]


func _draw_shop_offer(rerolls: int) -> Dictionary:
	var draw_conf: Dictionary = GameData.balance.get("shopDraw", {})
	_expire_reservations()
	_expire_leases()

	var slots: Array = []  # [{kind, id, data}]

	# 1. 📌 Ce qui a été réservé prend sa place avant tout tirage — y compris
	#    quand on re-tire : payer pour garder doit résister au hasard qu'on paie
	#    pour rejouer. Une réservation compte dans le minimum garanti de son type.
	for kind in ASSET_KINDS:
		for entry in _reservations_for(kind):
			slots.append({"kind": kind, "id": entry.get("id", ""), "data": entry.get("data", {})})

	# 2. Les minimums garantis : le garde-fou qui empêche un sprint sans aucune
	#    décision ni aucun candidat. C'est la seule entorse au hasard pur.
	var total := int(draw_conf.get("slotsPerSprint", 6))
	var guaranteed: Dictionary = draw_conf.get("guaranteedPerSprint", {})
	for kind in ASSET_KINDS:
		var missing := int(guaranteed.get(kind, 0)) - _count_slots_of_kind(slots, kind)
		while missing > 0 and slots.size() < total:
			var slot := _draw_slot(kind, slots)
			if slot.is_empty():
				break
			slots.append(slot)
			missing -= 1

	# 3. Le reste au hasard entre les trois types.
	var exhausted: Array = []
	while slots.size() < total and exhausted.size() < ASSET_KINDS.size():
		var kind := _pick_asset_kind(exhausted)
		if kind == "":
			break
		var slot := _draw_slot(kind, slots)
		if slot.is_empty():
			exhausted.append(kind)
			continue
		slots.append(slot)

	# 4. L'ordre d'affichage est mélangé : un rayon trié par type redeviendrait
	#    trois rayons, et la mise en concurrence disparaîtrait.
	slots.shuffle()

	# Une carte à prérequis prend un **bail** dès qu'elle sort : elle reste
	# affichée le trimestre entier, en plus du tirage, pour qu'on ait le temps
	# de réunir sa condition. Sans ça, une carte gatée tirée un sprint où la
	# condition n'est pas remplie serait une carte perdue.
	for slot in slots:
		if slot.get("kind", "") == "decision":
			_open_lease_if_gated(slot.get("id", ""))

	var offer := {
		"sprint": sprint_number,
		"slots": slots,
		"candidates": [],
		"practices": [],
		"decisions": [],
		"leased": get_leased_decision_ids(),
		"rerolls": rerolls,
	}
	for slot in slots:
		match slot.get("kind", ""):
			"candidate":
				offer["candidates"].append(slot.get("data", {}))
			"practice":
				offer["practices"].append(slot.get("id", ""))
			"decision":
				offer["decisions"].append(slot.get("id", ""))
	return offer


func _count_slots_of_kind(slots: Array, kind: String) -> int:
	var count := 0
	for slot in slots:
		if slot.get("kind", "") == kind:
			count += 1
	return count


## Quel type occupe le prochain emplacement libre. Pondéré par `typeWeights` —
## et non par la taille des pools : sans ça, les 12 candidats écraseraient les
## 6 décisions par simple effet de nombre.
func _pick_asset_kind(exhausted: Array) -> String:
	var weights: Dictionary = GameData.balance.get("shopDraw", {}).get("typeWeights", {})
	var total := 0.0
	for kind in ASSET_KINDS:
		if not exhausted.has(kind):
			total += float(weights.get(kind, 1))
	if total <= 0.0:
		return ""

	var roll := randf() * total
	for kind in ASSET_KINDS:
		if exhausted.has(kind):
			continue
		roll -= float(weights.get(kind, 1))
		if roll <= 0.0:
			return kind
	return ""


## Tire un Actif du type demandé, en évitant ce qui est déjà dans l'offre.
## Retourne {} si le pool de ce type est épuisé.
func _draw_slot(kind: String, slots: Array) -> Dictionary:
	var taken: Array = []
	for slot in slots:
		if slot.get("kind", "") == kind:
			taken.append(slot.get("id", ""))

	match kind:
		"candidate":
			var candidate := _draw_candidate(taken)
			if candidate.is_empty():
				return {}
			return {"kind": kind, "id": candidate.get("id", ""), "data": candidate}
		"practice":
			var practice_id := _draw_practice(taken)
			if practice_id == "":
				return {}
			return {"kind": kind, "id": practice_id, "data": {}}
		"decision":
			var card_id := _draw_decision(taken)
			if card_id == "":
				return {}
			return {"kind": kind, "id": card_id, "data": {}}
	return {}


# --- Le tirage pondéré : des taux d'apparition, pas un sac ---

## Rareté d'un Actif (`commune` par défaut) — commune à `cards.json`,
## `practices.json` et `candidates.json` : un seul vocabulaire pour les trois
## rayons.
func asset_rarity(data: Dictionary) -> String:
	return data.get("rarity", "commune")


## Poids de tirage : le poids de sa rareté (balance.json →
## `shopDraw.rarityWeights`), multiplié par le coefficient d'époque que l'Actif
## déclare éventuellement (`eraWeights`). C'est là que le scénario colore
## l'offre — Jira sort deux fois plus souvent en pleine Transformation agile.
func asset_draw_weight(data: Dictionary) -> float:
	var weights: Dictionary = GameData.balance.get("shopDraw", {}).get("rarityWeights", {})
	var weight := float(weights.get(asset_rarity(data), 100))
	return maxf(0.0, weight * float(data.get("eraWeights", {}).get(era_id, 1.0)))


## Tirage pondéré sans remise **dans une même offre** : rien ne mémorise ce qui
## est déjà sorti d'un sprint à l'autre. Une carte peut donc revenir deux
## sprints de suite ou manquer six sprints — c'est le prix de l'aléatoire
## assumé, et le 🎲 re-tirage est là pour ça.
func _weighted_pick(pool: Array) -> Dictionary:
	var total := 0.0
	for data in pool:
		total += asset_draw_weight(data)
	if total <= 0.0:
		return {}

	var roll := randf() * total
	for data in pool:
		roll -= asset_draw_weight(data)
		if roll <= 0.0:
			return data
	return pool[-1]


func _available_for_era(data: Dictionary) -> bool:
	var eras: Array = data.get("eras", [])
	return eras.is_empty() or eras.has(era_id)


func _draw_decision(already_drawn: Array) -> String:
	var pool: Array = []
	for card in GameData.cards.get("cards", []):
		var card_id: String = card.get("id", "")
		if not _available_for_era(card):
			continue
		if activated_cards.has(card_id) or already_drawn.has(card_id):
			continue
		if get_leased_decision_ids().has(card_id):
			continue  # déjà punaisée sur le rayon, inutile de la retirer
		pool.append(card)
	return _weighted_pick(pool).get("id", "")


func _draw_practice(already_drawn: Array) -> String:
	var pool: Array = []
	for practice in GameData.practices:
		var practice_id: String = practice.get("id", "")
		if not _available_for_era(practice):
			continue
		if owned_practices.has(practice_id) or already_drawn.has(practice_id):
			continue
		pool.append(practice)
	return _weighted_pick(pool).get("id", "")


func find_card(card_id: String) -> Dictionary:
	for card in GameData.cards.get("cards", []):
		if card.get("id", "") == card_id:
			return card
	return {}


## Prix d'activation d'une grande décision, en 🪙. Une décision se paie comme
## une embauche ou une pratique — c'est la condition pour que les trois types
## soient vraiment en concurrence sur le même rayon (carnet §21). Les pièces
## sont le budget d'**action** : ce qu'il faut dépenser pour faire passer la
## bascule. C'est distinct de l'axe `financier` de la carte, qui frappe la
## Trésorerie sprint après sprint — le prix d'achat n'est pas le coût
## d'exploitation.
func decision_cost(card_id: String) -> int:
	return int(find_card(card_id).get("costPieces", 0))


## Active une grande décision : les pièces tombent immédiatement, ses effets
## rejoignent le panier du sprint, elle devient une Fondation et quitte
## définitivement l'offre. Retourne "" si l'activation a eu lieu, sinon la
## raison du refus.
func activate_decision(card_id: String) -> String:
	if activated_cards.has(card_id):
		return "deja-activee"
	if activated_cards.size() >= int(GameData.balance.get("structuralDecisionMaxActivations", 4)):
		return "plus-de-slot"
	var card := find_card(card_id)
	if card.is_empty():
		return "introuvable"
	if not card_requirement_state(card).get("ok", true):
		return "prerequis"
	var cost := decision_cost(card_id)
	if pieces < cost:
		return "pieces"

	pieces -= cost
	var deltas := EffectResolver.resolve_card_activation(card_id, team_profile, era_id)
	add_pending(deltas, "Grande décision : %s activée (%d 🪙, %s)" % [
		card.get("name", card_id), cost, team_profile
	])
	activated_cards.append(card_id)
	activated_card_sprints[card_id] = sprint_number
	release_reservation("decision", card_id)
	leased_decisions.erase(card_id)
	return ""


# --- 🔒 Les cartes à prérequis et leur bail ---

## Une carte qui déclare `requires` ne s'active que si sa condition est vraie.
## Retourne {gated, ok, label, current} — `gated` false pour une carte ordinaire.
func card_requirement_state(card: Dictionary) -> Dictionary:
	var requirement: Dictionary = card.get("requires", {})
	if requirement.is_empty():
		return {"gated": false, "ok": true, "label": "", "current": ""}
	var evaluated := evaluate_condition(requirement)
	return {
		"gated": true,
		"ok": evaluated.get("ok", false),
		"label": requirement.get("label", ""),
		"current": evaluated.get("current", ""),
	}


func _open_lease_if_gated(card_id: String) -> void:
	if leased_decisions.has(card_id) or activated_cards.has(card_id):
		return
	if find_card(card_id).get("requires", {}).is_empty():
		return
	var lease := int(GameData.balance.get("shopDraw", {}).get("lockedLeaseSprints", 6))
	leased_decisions[card_id] = sprint_number + lease


## Les cartes punaisées encore valables : ni activées, ni périmées. Elles
## s'ajoutent au tirage du rayon au lieu de lui prendre une place.
func get_leased_decision_ids() -> Array:
	var ids: Array = []
	for card_id in leased_decisions.keys():
		if activated_cards.has(card_id):
			continue
		if sprint_number > int(leased_decisions[card_id]):
			continue
		ids.append(card_id)
	return ids


func get_lease_expiry(card_id: String) -> int:
	return int(leased_decisions.get(card_id, 0))


## Un bail échu est effacé, pas seulement ignoré : la carte retourne dans le
## pool et pourra ressortir plus tard — avec un bail tout neuf.
func _expire_leases() -> void:
	for card_id in leased_decisions.keys():
		if activated_cards.has(card_id) or sprint_number > int(leased_decisions[card_id]):
			leased_decisions.erase(card_id)


# --- 📌 Réserver un Actif pour le sprint suivant ---

func reserve_cost() -> int:
	return int(GameData.balance.get("shopDraw", {}).get("reserveCostPieces", 1))


func is_reserved(kind: String, asset_id: String) -> bool:
	for entry in reserved_assets:
		if entry.get("kind", "") == kind and entry.get("id", "") == asset_id:
			return true
	return false


## Punaise un Actif de l'offre : il sera encore là au sprint suivant, et un
## 🎲 re-tirage ne l'emporte pas. Le bail est **d'un sprint** — le garder plus
## longtemps se re-paie, sinon une pièce suffirait à annuler toute la rareté.
## Deuxième appel = on décolle la punaise et la pièce revient (même sprint).
## Retourne "" si l'état a changé, sinon la raison du refus.
func toggle_reservation(kind: String, asset_id: String, data: Dictionary) -> String:
	for entry in reserved_assets:
		if entry.get("kind", "") == kind and entry.get("id", "") == asset_id:
			reserved_assets.erase(entry)
			pieces += int(entry.get("paid", 0))
			return ""

	var cost := reserve_cost()
	if pieces < cost:
		return "pieces"
	pieces -= cost
	reserved_assets.append({
		"kind": kind,
		"id": asset_id,
		"data": data.duplicate(true) if kind == "candidate" else {},
		"sprint": sprint_number,
		"paid": cost,
	})
	return ""


func release_reservation(kind: String, asset_id: String) -> void:
	for entry in reserved_assets:
		if entry.get("kind", "") == kind and entry.get("id", "") == asset_id:
			reserved_assets.erase(entry)
			return


## Une réservation vaut pour le sprint où elle est posée et le suivant.
func _expire_reservations() -> void:
	var kept: Array = []
	for entry in reserved_assets:
		if sprint_number - int(entry.get("sprint", 0)) <= 1:
			kept.append(entry)
	reserved_assets = kept


func _reservations_for(kind: String) -> Array:
	var entries: Array = []
	for entry in reserved_assets:
		if entry.get("kind", "") != kind:
			continue
		var asset_id: String = entry.get("id", "")
		if kind == "practice" and owned_practices.has(asset_id):
			continue
		if kind == "decision" and (activated_cards.has(asset_id) or not _available_for_era(find_card(asset_id))):
			continue
		if kind == "candidate" and _hired_candidate_ids.has(asset_id):
			continue
		entries.append(entry)
	return entries


## 🎲 Re-tirer l'offre — le prix monte à chaque usage **dans le sprint** et
## repart à sa base au sprint suivant (le compteur vit dans l'offre, qui est
## elle-même datée). Payer pour revoir le hasard est le contrepoids du tirage :
## sans lui, un sprint sans rien d'intéressant est subi ; avec lui, c'est un
## arbitrage de plus contre les pièces qu'on aurait mises dans une embauche.
func shop_reroll_cost() -> int:
	var conf: Dictionary = GameData.balance.get("shopDraw", {}).get("reroll", {})
	var base := int(conf.get("baseCost", 1))
	var increment := int(conf.get("costIncrement", 1))
	return base + increment * int(get_shop_offer().get("rerolls", 0))


## Retourne "" si le re-tirage a eu lieu, sinon la raison du refus.
func reroll_shop_offer() -> String:
	var cost := shop_reroll_cost()
	if pieces < cost:
		return "pieces"

	var rerolls := int(get_shop_offer().get("rerolls", 0)) + 1
	pieces -= cost
	current_shop_offer = _draw_shop_offer(rerolls)
	pending_journal_lines.append("🎲 Offre re-tirée (%d 🪙) — %s" % [
		cost, "le marché a d'autres idées" if rerolls == 1 else "encore une fois (%d ce sprint)" % rerolls
	])
	return ""


## Même tirage pondéré que les deux autres rayons. Un candidat déjà embauché ne
## revient pas ; les autres peuvent réapparaître d'un sprint à l'autre — le
## marché du travail ne se vide pas parce qu'on a regardé une annonce.
func _draw_candidate(already_drawn: Array) -> Dictionary:
	var pool: Array = []
	for candidate in GameData.candidates:
		var candidate_id: String = candidate.get("id", "")
		if not _available_for_era(candidate):
			continue
		if _hired_candidate_ids.has(candidate_id) or already_drawn.has(candidate_id):
			continue
		pool.append(candidate)

	var picked := _weighted_pick(pool)
	if picked.is_empty():
		return {}

	var instance: Dictionary = picked.duplicate(true)
	instance["hidden_trait"] = _roll_hidden_trait()
	instance["hiddenRevealed"] = has_practice("entretiens-structures")
	instance["hired"] = false
	return instance


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
	release_reservation("candidate", candidate.get("id", ""))
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
	release_reservation("practice", practice_id)
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
	last_roi_revenue_bonus = recurring_roi

	var valeur: float = resource_values.get("valeur-percue", 0.0)
	var cutoff: float = float(GameData.balance.get("pressure", {}).get("revenueCutoffValeurPercue", 5))
	if valeur <= cutoff:
		return recurring_roi

	var moral: float = resource_values.get("moral", 0.0)
	var per_point: float = model.get("revenuePerValeurPercuePoint", 0.0)
	var offset: float = model.get("revenueValeurPercueOffset", 0.0)
	var floor_factor: float = model.get("moralChurnFloor", 0.4)
	var ceiling_factor: float = model.get("moralChurnCeiling", 1.2)
	var moral_factor: float = clamp(moral / 100.0, floor_factor, ceiling_factor)

	return int(round(max(valeur - offset, 0.0) * per_point * moral_factor)) + recurring_roi


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

	_apply_energy_flow()
	var energy_sprint_delta := int(last_energy_report.get("sprintDelta", 0))
	if energy_sprint_delta != 0:
		applied["energie"] = energy_sprint_delta

	journal.append({
		"sprint": sprint_number,
		"text": " · ".join(pending_journal_lines) if not pending_journal_lines.is_empty() else "Sprint calme — aucune décision marquante.",
		"deltas": EffectResolver.format_deltas(applied),
	})

	pending_deltas.clear()
	pending_journal_lines.clear()
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


## Flux d'Énergie de la Résolution (§7.1) : régénération modulée par le
## Moral — lu après application des effets du sprint, l'état dans lequel
## l'équipe le termine —, bonus de Souffler, deltas d'événements Inbox
## (pseudo-ressource "energie"), le tout borné 0..max. Les dépenses
## d'actions personnelles ont déjà été prélevées en direct pendant le sprint.
func _apply_energy_flow() -> void:
	var conf := get_energy_conf()
	var base := int(conf.get("regenPerSprint", 12))
	var factor := get_energy_regen_factor()
	var regen := int(round(base * factor))

	var bonus := 0
	if breather_planned:
		bonus = int(conf.get("breatherRegenBonus", 10))
		breather_planned = false

	var events := int(round(pending_deltas.get("energie", 0.0)))
	pending_deltas.erase("energie")

	var before := energy
	energy = clampi(energy + regen + bonus + events, 0, get_energy_max())

	last_energy_report = {
		"spent": energy_spent_this_sprint,
		"regenBase": base,
		"factor": factor,
		"regen": regen,
		"breatherBonus": bonus,
		"events": events,
		"sprintDelta": (energy - before) - energy_spent_this_sprint,
		"value": energy,
	}

	var parts: Array = ["régén +%d (%d %s Moral)" % [regen, base, energy_factor_label(factor)]]
	if bonus > 0:
		parts.append("Souffler +%d" % bonus)
	if events != 0:
		parts.append("événements %s%d" % ["+" if events > 0 else "−", abs(events)])
	if energy_spent_this_sprint > 0:
		parts.append("actions personnelles −%d" % energy_spent_this_sprint)
	pending_journal_lines.append("⚡ Énergie : %s (jauge %d/%d)" % [" · ".join(parts), energy, get_energy_max()])

	energy_spent_this_sprint = 0
	self_work_capacity = 0


func energy_factor_label(factor: float) -> String:
	if factor == 1.0:
		return "×1"
	if factor == 0.0:
		return "×0"
	return "×%s" % String.num(factor, 2)


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
		var extra := _apply_trait_triggers(employee)

		journal.append({
			"sprint": sprint_number,
			"text": "Fin de période d'essai : %s est un·e %s %s — %s%s" % [
				employee.get("name", ""), hidden_trait.get("name", ""), hidden_trait.get("icon", ""),
				hidden_trait.get("description", ""), extra
			],
			"deltas": "",
		})


## Traits cachés à déclencheur (Négociateur, Réseau) — appliqués au moment
## où le trait d'un employé se révèle : fin de période d'essai, ou 1:1
## anticipé (§7.2). Retourne le complément de phrase pour le journal.
func _apply_trait_triggers(employee: Dictionary) -> String:
	var hidden_trait := get_hidden_trait(employee.get("hidden_trait", ""))
	var effects: Dictionary = hidden_trait.get("effects", {})
	var extra := ""
	if effects.has("salaryRaiseAtTrialEnd"):
		var raise_amount := int(effects.get("salaryRaiseAtTrialEnd", 1))
		employee["salary"] = int(employee.get("salary", 1)) + raise_amount
		extra = " Une offre concurrente sur la table : +%d de salaire, ou un départ." % raise_amount
	if effects.has("nextHireDiscountPieces"):
		next_hire_discount += int(effects.get("nextHireDiscountPieces", 0))
		extra = " Son carnet d'adresses vaut %d 🪙 sur le prochain recrutement." % int(effects.get("nextHireDiscountPieces", 0))
	return extra


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


## Confronte les conditions de la revue de board (companies.json →
## boardObjectives) à l'état courant, sans rien modifier. Appelée deux fois :
## par _run_board_review() au sprint de mi-mandat, qui en tire le verdict, et
## par le Panneau de bord, qui les affiche cochées **en direct** — comprendre
## ce qu'il faut prioriser ne devrait pas demander d'attendre le sprint 6
## (docs/proposition-ui-interface.md §4.2).
## Retourne [{label, ok, current}] ; `current` est la valeur lue, pour
## l'affichage « ✗ (47) ».
func evaluate_board_objectives() -> Array:
	var conditions: Array = []
	for condition in get_company().get("boardObjectives", {}).get("conditions", []):
		var evaluated := evaluate_condition(condition)
		conditions.append({
			"label": condition.get("label", ""),
			"ok": evaluated.get("ok", false),
			"current": evaluated.get("current", ""),
		})
	return conditions


## Une seule grammaire de condition pour les objectifs de board **et** les
## prérequis des cartes (`requires`) : `type` + `value` (+ `resource` ou
## `seniority`). Retourne {ok, current} — `current` est la valeur lue, pour
## afficher « ✗ (47) » plutôt qu'un simple non.
func evaluate_condition(condition: Dictionary) -> Dictionary:
	var ok := false
	var current := ""
	match condition.get("type", ""):
		"resource-max":
			var max_value: float = resource_values.get(condition.get("resource", ""), 0.0)
			ok = max_value <= float(condition.get("value", 0))
			current = "%d" % int(round(max_value))
		"resource-min":
			var min_value: float = resource_values.get(condition.get("resource", ""), 0.0)
			ok = min_value >= float(condition.get("value", 0))
			current = "%d" % int(round(min_value))
		"decisions-min":
			ok = activated_cards.size() >= int(condition.get("value", 1))
			current = "%d" % activated_cards.size()
		"revenue-min":
			ok = last_revenue >= int(condition.get("value", 0))
			current = "%d" % last_revenue
		"roster-seniority-min":
			var count := 0
			for member in roster:
				if member.get("seniority", "") == condition.get("seniority", "senior"):
					count += 1
			ok = count >= int(condition.get("value", 1))
			current = "%d/%d" % [count, int(condition.get("value", 1))]
		"practice-owned":
			ok = owned_practices.has(condition.get("practice", ""))
			current = "oui" if ok else "non"
	return {"ok": ok, "current": current}


## La revue de board (§8.2) — le "boss" de mi-mandat : l'état de la boîte
## est comparé aux objectifs fixés par l'entreprise à l'embauche.
func _run_board_review() -> void:
	var objectives: Dictionary = get_company().get("boardObjectives", {})
	var review_conf: Dictionary = GameData.balance.get("pressure", {}).get("boardReview", {})
	var conditions: Array = evaluate_board_objectives()
	var all_ok := true
	for condition in conditions:
		if not condition.get("ok", false):
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


## Fins négatives par seuil (balance.json → endingThresholds). La
## pseudo-ressource "energie" y est acceptée : elle lit la jauge personnelle
## du joueur — le burn-out fondateur·rice se déclenche sur Énergie ≤ 0
## (spec §8.3, remappé en Phase B ; l'ancien couperet Valeur perçue a
## disparu en Phase A).
func _check_bad_endings() -> String:
	var thresholds: Array = GameData.balance.get("endingThresholds", [])
	var overrides: Dictionary = GameData.balance.get("endingThresholdOverrides", {}).get(era_id, {})

	for threshold in thresholds:
		var resource_id: String = threshold.get("resource", "")
		var value: float = 0.0
		if resource_id == "energie":
			value = float(energy)
		elif resource_values.has(resource_id):
			value = resource_values[resource_id]
		else:
			continue
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
