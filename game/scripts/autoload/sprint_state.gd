extends Node
## Autoload : état complet d'un mandat (run) — les 6 ressources persistantes,
## le scénario choisi, les squads (une seule aujourd'hui), les pièces, les pratiques, les
## grandes décisions activées, le journal, et le panier d'effets en attente
## pour le sprint en cours.
##
## Modèle d'application (§11 du carnet de règles) : chaque phase d'un sprint
## (Inbox, Roadmap, Grandes décisions, Marché) calcule son effet et
## l'ajoute au panier via add_pending(). L'écran de Résolution applique tout
## le panier d'un coup via apply_pending_and_check() — plus la masse
## salariale, les effets de roster/pratiques, la décroissance de la Valeur
## perçue, le revenu du modèle économique, le flux de pièces et la
## régénération d'Énergie du joueur — affiche le delta réel, résout le quota
## trimestriel, et détecte une éventuelle fin de mandat. Voir
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
var last_score_report: Dictionary = {} # rapport immuable réservé au futur ScoreResolver
var mrr: float = 0.0                   # stock de MRR réservé à la conversion du score
var streak: int = 0                    # sprints livrés consécutifs, réservé au score

# --- Phase A : l'entreprise ---
var pieces: int = 0                    # 🪙 budget d'action de l'entreprise (jamais négatif)
var squads: Array = []                 # [{id, name, roster, backlog_draw, capacity, delivered, epic_progress}]
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
var quarter_impact: int = 0
var quarter_index: int = 1
var quarter_requirement_id: String = ""
var quarter_requirement_ids: Array = []
var quarter_sprint: int = 0
var quarter_result: Dictionary = {}
var quarter_exit_choice_pending: bool = false
var long_mandate: bool = false
var quarter_forced_strategy_id: String = ""
var career_level: String = "pm"        # index dans balance.json → toolSlots.careerLevels (une seule ligne remplie avant le lot 5)
var tool_slots_purchased: int = 0      # +1/+2 achetés au Comité, à prix croissant (spec §7.1.1)
var swap_count: int = 0                # bascules d'outil déjà faites ce mandat (spec §7.1.2) — chaque nouvelle coûte plus de Cynisme
var chosen_strategy_ids: Array = []    # décisions stratégiques choisies ce mandat — permanentes, 1 par trimestre (spec §7.2)
var quarter_strategy_chosen: bool = false  # une décision stratégique a déjà été prise ce trimestre (imposée ou volontaire)
var current_shop_offer: Dictionary = {}     # {sprint, candidates:[...], practices:[ids], decisions:[ids], leased:[ids], rerolls} — tirage des Investissements
var reserved_assets: Array = []             # 📌 [{kind, id, data, sprint, paid}] — punaisés, réinjectés dans l'offre suivante
var leased_decisions: Dictionary = {}       # 🔒 card_id -> sprint d'expiration du bail d'une carte à prérequis

# --- 🏛️ Le Comité d'investissement (spec scoring §12, Lot 4) ---
var support_teams: Dictionary = {}          # {sales, pmm, csm} -> niveau 0-5, fixé par companies.json → supportTeams, jamais pilotable (spec §9.4)
var team_cap_purchased: int = 0             # postes ouverts au Comité, en plus de companies.json → teamCap
var product_tier: int = 0                   # paliers de produit achetés (max = investments.json → product-tier.costs.size())
var headhunter_pending: bool = false        # 🎯 Chasseur de têtes acheté : le prochain get_shop_offer() force des candidats et révèle leurs traits
var headhunter_target_candidates: int = 0   # nombre de candidats forcés par le Chasseur de têtes en cours
var cleanup_sprint_pending: bool = false    # 🧹 Sprint de remise à plat acheté : la prochaine Résolution neutralise la Traction
var turnaround_plans_available: int = 0     # 🏛️ Plans de redressement achetés, consommés automatiquement au premier quota manqué
var current_committee_offer: Dictionary = {}  # {quarter, strategy_cost} — le prix de la décision stratégique, tiré une fois par trimestre

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
var _quarter_requirement_bag: Array = []
var _last_quarter_requirement_id: String = ""


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
	last_score_report.clear()
	mrr = 0.0
	streak = 0
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
	quarter_impact = 0
	quarter_index = 1
	quarter_requirement_id = ""
	quarter_requirement_ids.clear()
	quarter_sprint = 0
	quarter_result.clear()
	quarter_exit_choice_pending = false
	long_mandate = false
	quarter_forced_strategy_id = ""
	career_level = "pm"
	tool_slots_purchased = 0
	swap_count = 0
	chosen_strategy_ids.clear()
	quarter_strategy_chosen = false
	_quarter_requirement_bag.clear()
	_last_quarter_requirement_id = ""
	current_shop_offer.clear()
	energy = int(get_energy_conf().get("start", 70))
	energy_spent_this_sprint = 0
	self_work_capacity = 0
	breather_planned = false
	last_energy_report.clear()
	team_cap_purchased = 0
	product_tier = 0
	headhunter_pending = false
	headhunter_target_candidates = 0
	cleanup_sprint_pending = false
	turnaround_plans_available = 0
	current_committee_offer.clear()

	var company: Dictionary = get_company()
	pieces = int(company.get("startingPieces", 0))
	# 💼📣🎧 Équipes subies (spec §9.4) : niveau 0-5 fixé par l'entreprise,
	# jamais pilotable en jeu. Défaut 3/3/3 (neutre) si l'entreprise ne le
	# déclare pas — compatibilité des scénarios qui ne l'ont pas encore.
	var default_support_teams: Dictionary = {"sales": 3, "pmm": 3, "csm": 3}
	support_teams = company.get("supportTeams", default_support_teams).duplicate()

	# 🎁 Outillage hérité (spec §7.1.3) : l'entreprise arrive avec 1-2 outils
	# déjà installés par quelqu'un d'autre, qui occupent un slot dès le
	# premier sprint. Aucune branche par entreprise ici — inheritedTools[]
	# est une donnée de companies.json, le mécanisme est générique.
	for tool_id in company.get("inheritedTools", []):
		var inherited_card: String = str(tool_id)
		if find_card(inherited_card).is_empty() or activated_cards.has(inherited_card):
			continue
		activated_cards.append(inherited_card)
		activated_card_sprints[inherited_card] = 0

	var primary_roster: Array = []
	var salaries: Dictionary = GameData.balance.get("salaries", {})
	for member in company.get("startingRoster", []):
		var seniority: String = member.get("seniority", "junior")
		primary_roster.append({
			"id": member.get("id", ""),
			"name": member.get("name", ""),
			"role": member.get("role", ""),
			"seniority": seniority,
			"salary": int(salaries.get(seniority, 1)),
			"trait": member.get("trait", ""),
			"visible_trait_id": member.get("visible_trait_id", ""),
			"hidden_trait": "",
			"hiddenRevealed": true,  # l'équipe héritée a déjà fait sa période d'essai
			"hiredSprint": 0,
		})
	squads = [{
		"id": "squad-principale",
		"name": "Equipe produit",
		"roster": primary_roster,
		"backlog_draw": {},
		"capacity": 0,
		"delivered": [],
		"epic_progress": {},
	}]

	resource_values.clear()
	var starting: Dictionary = GameData.balance.get("startingResources", {})
	var overrides: Dictionary = GameData.balance.get("startingResourceOverrides", {}).get(company_id, {})
	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		resource_values[resource_id] = float(overrides.get(resource_id, starting.get(resource_id, 50)))
	_prepare_quarter(1)
	get_effective_capacity()


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


## Contrat public de la couche UI des quotas. Le runtime accepte aussi la
## premiere version du JSON, afin que les sauvegardes de developpement ne
## dependent pas de la migration de donnees.
func get_current_quota() -> int:
	var level: Dictionary = GameData.quotas.get("careerLevels", {}).get("pm", {})
	var configured: Variant = level.get("quarterQuotas", [])
	var base_quota := 0.0
	if configured is Array and quarter_index <= configured.size():
		base_quota = float(configured[quarter_index - 1])
	elif configured is Dictionary:
		base_quota = float(configured.get(str(min(quarter_index, 4)), 0))
	if base_quota <= 0.0:
		base_quota = 1050.0

	var long_conf: Dictionary = GameData.quotas.get("longMandate", {})
	if quarter_index >= int(long_conf.get("fromQuarter", 5)):
		var multiplier := float(long_conf.get("quotaMultiplier", 2.2))
		base_quota *= pow(multiplier, quarter_index - 4)
	return int(round(base_quota * float(_active_quarter_effects().get("quotaMultiplier", 1.0))))


func get_quarter_length() -> int:
	return max(1, int(_active_quarter_effects().get("quarterLength", 3)))


func get_active_quarter_requirements() -> Array:
	var requirements: Array = []
	for requirement_id in quarter_requirement_ids:
		var requirement := _quarter_requirement_by_id(requirement_id)
		if not requirement.is_empty():
			requirements.append(requirement)
	return requirements


func get_quarter_requirement_text() -> String:
	var parts: Array = []
	for requirement in get_active_quarter_requirements():
		parts.append("%s %s — %s" % [requirement.get("icon", ""), requirement.get("name", ""), requirement.get("description", "")])
	return "\n".join(parts)


func get_quarter_requirement_effects() -> Dictionary:
	return _active_quarter_effects().duplicate(true)


func get_quarter_progress() -> Dictionary:
	return {
		"quarter": quarter_index,
		"impact": quarter_impact,
		"quota": get_current_quota(),
		"sprint": quarter_sprint,
		"length": get_quarter_length(),
		"requirementIds": quarter_requirement_ids.duplicate(),
	}


func is_quarter_requirement_active(effect: String) -> bool:
	var value: Variant = _active_quarter_effects().get(effect, false)
	return value == true or (value is float and value != 0.0) or (value is int and value != 0) or (value is Array and not value.is_empty())


func choose_mandate_path(stay: bool) -> String:
	if not quarter_exit_choice_pending:
		return "no-choice"
	quarter_exit_choice_pending = false
	if stay:
		long_mandate = true
		_prepare_quarter(quarter_index + 1)
		return ""
	var ending := _resolve_good_ending()
	is_mandate_over = true
	ending_id = ending
	ending_reached.emit(ending)
	return ending


func _quarter_requirement_by_id(requirement_id: String) -> Dictionary:
	for requirement in GameData.quotas.get("requirements", []):
		if requirement.get("id", "") == requirement_id:
			return requirement
	return {}


func _draw_quarter_requirement_id(excluded: Array = []) -> String:
	var attempts := 0
	var max_attempts: int = max(1, GameData.quotas.get("requirements", []).size() * 2)
	while attempts < max_attempts:
		if _quarter_requirement_bag.is_empty():
			for requirement in GameData.quotas.get("requirements", []):
				var refill_id: String = requirement.get("id", "")
				if refill_id != "" and not excluded.has(refill_id):
					_quarter_requirement_bag.append(refill_id)
			_quarter_requirement_bag.shuffle()
			if _quarter_requirement_bag.size() > 1 and _quarter_requirement_bag[-1] == _last_quarter_requirement_id:
				var swap_index := randi() % (_quarter_requirement_bag.size() - 1)
				var swap_value: String = _quarter_requirement_bag[-1]
				_quarter_requirement_bag[-1] = _quarter_requirement_bag[swap_index]
				_quarter_requirement_bag[swap_index] = swap_value
		if _quarter_requirement_bag.is_empty():
			return ""
		var requirement_id: String = _quarter_requirement_bag.pop_back()
		attempts += 1
		if excluded.has(requirement_id):
			continue
		_last_quarter_requirement_id = requirement_id
		return requirement_id
	return ""


func _prepare_quarter(next_quarter: int) -> void:
	quarter_index = next_quarter
	quarter_impact = 0
	quarter_sprint = 0
	quarter_forced_strategy_id = ""
	quarter_strategy_chosen = false
	var long_conf: Dictionary = GameData.quotas.get("longMandate", {})
	var accumulate := quarter_index >= int(long_conf.get("fromQuarter", 5)) and bool(long_conf.get("requirementsAccumulate", true))
	var requirement_id := _draw_quarter_requirement_id(quarter_requirement_ids if accumulate else [])
	if accumulate:
		if requirement_id != "" and not quarter_requirement_ids.has(requirement_id):
			quarter_requirement_ids.append(requirement_id)
	else:
		quarter_requirement_ids = [requirement_id] if requirement_id != "" else []
	quarter_requirement_id = requirement_id
	_assign_forced_strategy()


func _active_quarter_effects() -> Dictionary:
	var result: Dictionary = {}
	for requirement in get_active_quarter_requirements():
		var raw: Dictionary = requirement.get("effects", {})
		var normalized := _normalize_quarter_effects(raw)
		for key in normalized.keys():
			var value: Variant = normalized[key]
			if key in ["payrollMultiplier", "debtFrictionScale", "quotaMultiplier"]:
				result[key] = float(result.get(key, 1.0)) * float(value)
			elif key == "minimumClientImpactForTraction":
				result[key] = max(int(result.get(key, 0)), int(value))
			elif key == "quarterLength":
				result[key] = min(int(result.get(key, value)), int(value))
			elif key == "forcedStrategyPool":
				var pool: Array = result.get(key, [])
				for strategy_id in value:
					if not pool.has(strategy_id):
						pool.append(strategy_id)
				result[key] = pool
			else:
				result[key] = value
	return result


func _normalize_quarter_effects(raw: Dictionary) -> Dictionary:
	var result := raw.duplicate(true)
	# Compatibilite de la premiere ecriture de quotas.json avec le contrat final.
	if raw.has("salaryMultiplier"):
		result["payrollMultiplier"] = raw.get("salaryMultiplier", 1.0)
	if raw.has("featureTraction"):
		result["minimumClientImpactForTraction"] = int(raw.get("featureTraction", {}).get("clientImpactMax", 0)) + 1
	if raw.has("friction"):
		result["debtFrictionScale"] = raw.get("friction", {}).get("debtMultiplier", 1.0)
	if raw.has("trimester"):
		result["quarterLength"] = raw.get("trimester", {}).get("sprintLength", 3)
		result["quotaMultiplier"] = raw.get("trimester", {}).get("quotaMultiplier", 1.0)
	if raw.has("strategy") and bool(raw.get("strategy", {}).get("forced", false)):
		result["forcedStrategyPool"] = GameData.scoring.get("global", {}).get("strategies", {}).keys()
	return result


## 🗣️ Injonction du board (spec §7.2, §11.2) : le trimestre impose une
## décision stratégique sans laisser le choix. Elle consomme l'unique
## décision stratégique du trimestre, comme un choix volontaire l'aurait
## fait — d'où l'appel à choose_strategy() plutôt qu'une simple affectation.
func _assign_forced_strategy() -> void:
	if quarter_strategy_chosen:
		return
	var pool: Array = _active_quarter_effects().get("forcedStrategyPool", [])
	var available: Array = []
	for strategy_id in pool:
		if not chosen_strategy_ids.has(str(strategy_id)):
			available.append(str(strategy_id))
	if available.is_empty():
		return
	available.shuffle()
	var candidate: String = available[0]
	if choose_strategy(candidate) == "":
		quarter_forced_strategy_id = candidate


# --- 🧭 Décisions stratégiques — la 4e famille (spec §7.2) ---
## Elles ne touchent pas l'équipe : elles redéfinissent ce que le produit est
## pour le marché. Une par trimestre, irréversible. Le Comité qui les
## présente est le Lot 4 (écran non construit) ; ces fonctions sont le point
## d'entrée qu'il appellera, branché ici sur la fin de trimestre déjà
## existante (_prepare_quarter / _record_quarter_resolution).

## Catalogue proposé ce trimestre — tout ce qui n'a pas déjà été choisi.
## Vide si une décision a déjà été prise ce trimestre (imposée ou non).
func get_strategy_options(count: int = 3) -> Array:
	if quarter_strategy_chosen:
		return []
	var pool: Array = []
	for strategy in GameData.strategy.get("strategies", []):
		var strategy_id: String = strategy.get("id", "")
		if strategy_id != "" and not chosen_strategy_ids.has(strategy_id):
			pool.append(strategy)
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))


func find_strategy(strategy_id: String) -> Dictionary:
	for strategy in GameData.strategy.get("strategies", []):
		if strategy.get("id", "") == strategy_id:
			return strategy
	return {}


## Choix volontaire (ou forcé, via _assign_forced_strategy) d'une décision
## stratégique — irréversible pour le reste du mandat. Retourne "" si le
## choix a eu lieu, sinon la raison du refus.
func choose_strategy(strategy_id: String) -> String:
	if quarter_strategy_chosen:
		return "deja-choisie-ce-trimestre"
	if chosen_strategy_ids.has(strategy_id):
		return "deja-active"
	var strategy := find_strategy(strategy_id)
	if strategy.is_empty():
		return "introuvable"
	chosen_strategy_ids.append(strategy_id)
	quarter_strategy_chosen = true
	pending_journal_lines.append("🧭 Décision stratégique : %s %s adoptée — irréversible pour le reste du mandat." % [
		strategy.get("icon", ""), strategy.get("name", strategy_id)
	])
	_apply_strategy_support_team_deltas(strategy_id)
	return ""


## Effet de bord déclaratif (spec §9.4, dernier tiers) : une décision
## stratégique peut faire bouger une équipe subie (Open source → PMM +1,
## Sales −1). On ne les pilote toujours pas — on change le monde autour
## d'elles. `supportTeamDeltas` vit dans scoring.json → global.strategies,
## jamais un cas particulier ici : sans cette clé sur la stratégie, rien ne
## bouge.
func _apply_strategy_support_team_deltas(strategy_id: String) -> void:
	var rules: Dictionary = GameData.scoring.get("global", {}).get("strategies", {}).get(strategy_id, {})
	var deltas: Dictionary = rules.get("supportTeamDeltas", {})
	if deltas.is_empty():
		return
	var parts: Array = []
	for team_id in deltas.keys():
		var delta := int(deltas[team_id])
		var before := int(support_teams.get(team_id, 3))
		support_teams[team_id] = clampi(before + delta, 0, 5)
		parts.append("%s %s%d" % [team_id, "+" if delta >= 0 else "", delta])
	pending_journal_lines.append("↳ Effet de bord sur les équipes subies : %s (on ne les pilote pas, le monde change autour d'elles)." % ", ".join(parts))


# --- 🏛️ Le Comité d'investissement (spec scoring §12, Lot 4) ---
## Entre deux trimestres, jamais au fil de l'eau (l'étal du sprint ne change
## pas). Tous les coûts et magnitudes vivent dans data/investments.json ;
## chaque fonction lit sa propre entrée et n'écrit jamais un nombre en dur.
## `committee_screen.gd` n'est qu'une lecture de ces fonctions.

func find_investment_item(item_id: String) -> Dictionary:
	for item in GameData.investments.get("items", []):
		if item.get("id", "") == item_id:
			return item
	return {}


## Le prix de la décision stratégique varie par trimestre (15-30, spec §12) —
## tiré une fois et mémorisé pour ne pas changer entre deux rafraîchissements
## du Comité, comme le tirage de l'étal du sprint.
func strategy_purchase_cost() -> int:
	if int(current_committee_offer.get("quarter", -1)) != quarter_index:
		var range_conf: Array = find_investment_item("strategic-decision").get("costRange", [15, 30])
		var low := int(range_conf[0]) if range_conf.size() > 0 else 15
		var high := int(range_conf[1]) if range_conf.size() > 1 else 30
		current_committee_offer = {"quarter": quarter_index, "strategy_cost": randi_range(low, high)}
	return int(current_committee_offer.get("strategy_cost", 15))


## Version payante de choose_strategy() — la seule que le Comité expose ;
## _assign_forced_strategy() continue d'appeler choose_strategy() directement,
## sans coût, puisqu'une injonction du board ne se négocie pas.
func buy_strategy(strategy_id: String) -> String:
	if quarter_strategy_chosen:
		return "deja-choisie-ce-trimestre"
	var cost := strategy_purchase_cost()
	if pieces < cost:
		return "pieces"
	var refusal := choose_strategy(strategy_id)
	if refusal != "":
		return refusal
	pieces -= cost
	pending_journal_lines.append("🪙 Coût du Comité : %d." % cost)
	return ""


## 🪑 Ouvrir un poste : +1 au cap d'effectif, aujourd'hui figé par
## l'entreprise (companies.json → teamCap). Échelle de prix croissante,
## comme les slots d'outillage ; -1 une fois la table épuisée.
func team_cap_purchase_cost() -> int:
	var costs: Array = find_investment_item("open-seat").get("costs", [])
	if team_cap_purchased >= costs.size():
		return -1
	return int(costs[team_cap_purchased])


func buy_team_cap_seat() -> String:
	var cost := team_cap_purchase_cost()
	if cost < 0:
		return "plafond"
	if pieces < cost:
		return "pieces"
	pieces -= cost
	team_cap_purchased += 1
	pending_journal_lines.append("🪑 Poste ouvert (%d 🪙) — cap d'effectif porté à %d." % [cost, get_team_cap()])
	return ""


## 📈 Promotion : un junior nommé devient senior (salaire +1, contribution
## senior). Retourne "" si la promotion a eu lieu, sinon la raison du refus.
func promotion_cost() -> int:
	return int(find_investment_item("promotion").get("cost", 5))


func promote_employee(employee_id: String) -> String:
	var owner := _find_employee_owner(employee_id)
	if owner.is_empty():
		return "introuvable"
	var employee: Dictionary = owner.get("employee", {})
	if employee.get("seniority", "junior") != "junior":
		return "deja-senior"
	var cost := promotion_cost()
	if pieces < cost:
		return "pieces"
	pieces -= cost
	employee["seniority"] = "senior"
	employee["salary"] = int(GameData.balance.get("salaries", {}).get("senior", 2))
	pending_journal_lines.append("📈 Promotion (%d 🪙) : %s passe senior." % [cost, employee.get("name", employee_id)])
	return ""


## 🚀 Palier de produit : +0,5 Levier permanent (scoring.json →
## global.productTier), +1 feature proposée par sprint (_draw_backlog_offer).
## 3 paliers maximum par run — la table de prix fait foi.
func product_tier_purchase_cost() -> int:
	var costs: Array = find_investment_item("product-tier").get("costs", [])
	if product_tier >= costs.size():
		return -1
	return int(costs[product_tier])


func buy_product_tier() -> String:
	var cost := product_tier_purchase_cost()
	if cost < 0:
		return "plafond"
	if pieces < cost:
		return "pieces"
	pieces -= cost
	product_tier += 1
	pending_journal_lines.append("🚀 Palier de produit %d atteint (%d 🪙)." % [product_tier, cost])
	return ""


## 🏝️ Séminaire d'équipe : Cynisme -15, appliqué à la prochaine Résolution
## comme tout achat du Comité.
func buy_team_seminar() -> String:
	var item := find_investment_item("team-seminar")
	var cost := int(item.get("cost", 8))
	if pieces < cost:
		return "pieces"
	pieces -= cost
	add_pending({"cynisme": float(item.get("cynismeDelta", -15))},
		"🏝️ Séminaire d'équipe (%d 🪙) : 🎭 Cynisme %d." % [cost, int(item.get("cynismeDelta", -15))])
	return ""


## 🧹 Sprint de remise à plat : Dette -20, mais 0 Traction le sprint qui suit
## (consommé dans _build_score_snapshot() / apply_pending_and_check()).
func buy_cleanup_sprint() -> String:
	var item := find_investment_item("cleanup-sprint")
	var cost := int(item.get("cost", 6))
	if pieces < cost:
		return "pieces"
	pieces -= cost
	cleanup_sprint_pending = true
	add_pending({"dette-organisationnelle": float(item.get("detteDelta", -20))},
		"🧹 Sprint de remise à plat acheté (%d 🪙) : 🧱 Dette %d, 0 Traction au prochain sprint." % [cost, int(item.get("detteDelta", -20))])
	return ""


## 🤝 Rachat d'un concurrent : +12 MRR (stock, immédiat), +1 employé
## aléatoire (rejoint le roster tout de suite, hors étal), +8 Dette (à la
## prochaine Résolution, comme tout ce qui pèse sur les jauges).
func buy_competitor_acquisition() -> String:
	var item := find_investment_item("acquire-competitor")
	var cost := int(item.get("cost", 30))
	if pieces < cost:
		return "pieces"
	var recruit := _draw_candidate([])
	pieces -= cost
	mrr += float(item.get("mrrDelta", 12))
	if not recruit.is_empty():
		_get_primary_roster().append({
			"id": recruit.get("id", "") + "-rachat-%d" % sprint_number,
			"name": recruit.get("name", ""),
			"role": recruit.get("role", ""),
			"seniority": recruit.get("seniority", "junior"),
			"salary": int(recruit.get("salary", GameData.balance.get("salaries", {}).get(recruit.get("seniority", "junior"), 1))),
			"trait": recruit.get("trait", ""),
			"visible_trait_id": recruit.get("visible_trait_id", ""),
			"hidden_trait": recruit.get("hidden_trait", ""),
			"hiddenRevealed": recruit.get("hiddenRevealed", false),
			"hiredSprint": sprint_number,
		})
	add_pending({"dette-organisationnelle": float(item.get("detteDelta", 8))},
		"🤝 Rachat d'un concurrent (%d 🪙) : +%d MRR%s, 🧱 Dette +%d." % [
			cost, int(item.get("mrrDelta", 12)),
			" · +1 employé (%s)" % recruit.get("name", "") if not recruit.is_empty() else "",
			int(item.get("detteDelta", 8)),
		])
	return ""


## 🎯 Chasseur de têtes : le prochain tirage de l'étal force des candidats et
## révèle leurs traits cachés (voir get_shop_offer() / _apply_headhunter_boost()).
func buy_headhunter() -> String:
	var item := find_investment_item("headhunter")
	var cost := int(item.get("cost", 8))
	if pieces < cost:
		return "pieces"
	pieces -= cost
	headhunter_pending = true
	headhunter_target_candidates = int(item.get("nextShopCandidates", 4))
	pending_journal_lines.append("🎯 Chasseur de têtes engagé (%d 🪙) : le prochain étal forcera %d candidats, traits révélés." % [
		cost, headhunter_target_candidates
	])
	return ""


## 🏛️ Plan de redressement : un rattrapage de quota, consommé automatiquement
## par _record_quarter_resolution() la première fois qu'un trimestre
## manquerait son quota. Rachetable pour empiler les rattrapages.
func buy_turnaround_plan() -> String:
	var item := find_investment_item("turnaround-plan")
	var cost := int(item.get("cost", 20))
	if pieces < cost:
		return "pieces"
	pieces -= cost
	turnaround_plans_available += 1
	pending_journal_lines.append("🏛️ Plan de redressement acheté (%d 🪙) — %d rattrapage(s) de quota en réserve." % [
		cost, turnaround_plans_available
	])
	return ""


## 🎲 Avance sur trimestre : +10 💶 immédiats contre -80 d'Impact sur le
## cumul du trimestre qui vient. Un débit assumé sur quarter_impact, pas un
## abaissement du quota : un cumul qui passe sous zéro est une information de
## jeu (le pari coûte cher), jamais silencieusement remis à zéro ici — la
## remise à zéro trimestrielle reste la seule de _prepare_quarter().
## Répétable : chaque avance alourdit encore le trimestre en cours.
func buy_quarter_advance() -> String:
	var item := find_investment_item("quarter-advance")
	var gain := int(item.get("budgetGain", 10))
	var penalty := int(item.get("impactPenalty", 80))
	pieces += gain
	quarter_impact -= penalty
	pending_journal_lines.append("🎲 Avance sur trimestre : +%d 🪙 contre −%d d'Impact sur le quota en cours (cumul désormais %d)." % [
		gain, penalty, quarter_impact
	])
	return ""


func get_companies_for_era(target_era_id: String) -> Array:
	var result: Array = []
	for company in GameData.companies:
		if company.get("era", "") == target_era_id:
			result.append(company)
	return result


func get_business_model() -> Dictionary:
	return GameData.balance.get("businessModels", {}).get(business_model_id, {})


# --- Roster, rôles et capacité (spec profondeur §4) ---

## Vue de lecture aplatie du personnel de toutes les squads. Les dictionnaires
## employés restent les objets de l'état local ; ne jamais ajouter ou retirer
## un membre à cette vue.
func get_roster() -> Array:
	var flattened: Array = []
	for squad in squads:
		flattened.append_array(squad.get("roster", []))
	return flattened


## La première run n'a qu'une équipe. Ce point d'entrée évite que les actions
## actuelles écrivent par erreur dans la vue aplatie pendant la transition.
func get_primary_squad() -> Dictionary:
	if squads.is_empty():
		return {}
	return squads[0]


func _get_primary_roster() -> Array:
	return get_primary_squad().get("roster", [])

## Cap d'effectif : figé par l'entreprise à l'origine (companies.json →
## teamCap), désormais un objet de jeu — 🪑 Ouvrir un poste au Comité
## l'augmente (spec §12) sans jamais réécrire la donnée de départ.
func get_team_cap() -> int:
	return int(get_company().get("teamCap", 6)) + team_cap_purchased


func find_employee(employee_id: String) -> Dictionary:
	var owner := _find_employee_owner(employee_id)
	if not owner.is_empty():
		return owner.get("employee", {})
	return {}


func _find_employee_owner(employee_id: String) -> Dictionary:
	for squad in squads:
		for employee in squad.get("roster", []):
			if employee.get("id", "") == employee_id:
				return {"squad": squad, "employee": employee}
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
	for employee in get_roster():
		if employee.get("role", "") == role_id:
			total += employee_contribution_factor(employee)
	return total


## Capacité de roadmap produite par le roster ce sprint (spec §4.2) :
## Devs et PM produisent des points (rendements décroissants au-delà du cap
## de cumul de leur rôle), les Pépites révélées ajoutent leur bonus, et
## "Faire le taf soi-même" (§7.2) ajoute les points payés en Énergie.
func get_effective_capacity() -> int:
	var total := 0
	for squad_index in squads.size():
		var squad: Dictionary = squads[squad_index]
		var capacity := _calculate_squad_capacity(squad, squad_index == 0)
		squad["capacity"] = capacity
		total += capacity
	return total


func _calculate_squad_capacity(squad: Dictionary, include_self_work: bool) -> int:
	var roles: Dictionary = GameData.balance.get("roles", {})
	var total := 0.0
	var role_counts: Dictionary = {}

	for employee in squad.get("roster", []):
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

	return int(floor(max(total, 0.0))) + (self_work_capacity if include_self_work else 0)


## Masse salariale du sprint — prélevée à chaque Résolution (spec §4.3).
func get_payroll() -> int:
	var total := 0
	for employee in get_roster():
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
	# 🚀 Palier de produit (spec §12) : +1 feature proposée par sprint et par
	# palier acheté au Comité — un plafond de tirage plus haut, pas un minimum
	# garanti supplémentaire.
	var maximum: int = max(minimum, int(conf.get("itemsPerSprintMax", minimum))) + product_tier
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
	_apply_headhunter_boost(current_shop_offer)
	return current_shop_offer


## 🎯 Chasseur de têtes (spec §12) : consomme le pari acheté au Comité pour
## forcer le prochain étal à afficher au moins N candidats, traits cachés
## déjà révélés. Complète l'offre déjà tirée plutôt que de la refaire, pour
## ne pas perturber ce que `_draw_shop_offer` a déjà décidé pour les deux
## autres types.
func _apply_headhunter_boost(offer: Dictionary) -> void:
	if not headhunter_pending:
		return
	headhunter_pending = false
	var slots: Array = offer.get("slots", [])
	while _count_slots_of_kind(slots, "candidate") < headhunter_target_candidates:
		var slot := _draw_slot("candidate", slots)
		if slot.is_empty():
			break
		slots.append(slot)
	offer["candidates"] = []
	for slot in slots:
		if slot.get("kind", "") == "candidate":
			slot.get("data", {})["hiddenRevealed"] = true
			offer["candidates"].append(slot.get("data", {}))
	offer["slots"] = slots


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


# --- 🔧 Les slots d'outillage — la vraie limite de fin de mandat (spec §7.1.1) ---

## Base de slots du kit de départ, indexée par niveau de carrière — table à
## une seule ligne remplie avant le lot 5 (contrat d'architecture, CLAUDE.md).
func get_tool_slot_base() -> int:
	var levels: Dictionary = GameData.balance.get("toolSlots", {}).get("careerLevels", {})
	var level: Dictionary = levels.get(career_level, levels.get("pm", {}))
	return int(level.get("base", 3))


## Les outils cumulatifs rendent leur place (`slotBonus`, §7.1.1.b) : sans
## ça, un outil qu'on ne peut jamais retirer gèlerait un tiers d'un build de PM.
func get_tool_slot_bonus() -> int:
	var bonus := 0
	for card_id in activated_cards:
		bonus += int(find_card(card_id).get("slotBonus", 0))
	return bonus


func get_tool_slot_capacity() -> int:
	return get_tool_slot_base() + tool_slots_purchased + get_tool_slot_bonus()


## Prix du prochain slot supplémentaire (12 puis 20 💶, §7.1.1) ; -1 une fois
## le plafond de +2 atteint.
func tool_slot_purchase_cost() -> int:
	var costs: Array = GameData.balance.get("toolSlots", {}).get("extraSlotCosts", [])
	if tool_slots_purchased >= costs.size():
		return -1
	return int(costs[tool_slots_purchased])


## Achète un slot supplémentaire au Comité. Retourne "" si l'achat a eu lieu,
## sinon la raison du refus ("plafond" ou "pieces").
func buy_tool_slot() -> String:
	var cost := tool_slot_purchase_cost()
	if cost < 0:
		return "plafond"
	if pieces < cost:
		return "pieces"
	pieces -= cost
	tool_slots_purchased += 1
	pending_journal_lines.append("🔧 Slot d'outillage supplémentaire acheté (%d 🪙) — %d/%d." % [
		cost, get_tool_slot_capacity(), get_tool_slot_capacity()
	])
	return ""


## 🎭 Le coût de bascule (spec §7.1.2, carnet §7 jamais implémenté avant ce
## lot) : Cynisme +4, +3 par bascule déjà faite ce mandat.
func swap_cynisme_penalty() -> int:
	var conf: Dictionary = GameData.balance.get("toolSlots", {}).get("swap", {})
	return int(conf.get("cynisme", 4)) + int(conf.get("cynismePerPreviousSwap", 3)) * swap_count


## Libère le slot d'un outil actif : son Levier disparaît immédiatement, son
## compteur cumulatif (Sprint rétro) repart de zéro s'il est un jour
## rechoisi, et la carte retourne au pool de tirage. Retourne "" si la
## bascule a eu lieu, sinon la raison du refus.
func release_tool_slot(card_id: String) -> String:
	if not activated_cards.has(card_id):
		return "pas-active"
	var card := find_card(card_id)
	var penalty := swap_cynisme_penalty()
	add_pending({"cynisme": float(penalty)}, "🔁 %s libéré : Levier perdu immédiatement, 🎭 Cynisme +%d (bascule n°%d ce mandat)." % [
		card.get("name", card_id), penalty, swap_count + 1
	])
	activated_cards.erase(card_id)
	activated_card_sprints.erase(card_id)
	swap_count += 1
	return ""


## Active une grande décision : les pièces tombent immédiatement, ses effets
## rejoignent le panier du sprint, elle devient une Fondation et quitte
## définitivement l'offre. Retourne "" si l'activation a eu lieu, sinon la
## raison du refus.
func activate_decision(card_id: String) -> String:
	if activated_cards.has(card_id):
		return "deja-activee"
	if activated_cards.size() >= get_tool_slot_capacity():
		return "plus-de-slot"
	var card := find_card(card_id)
	if card.is_empty():
		return "introuvable"
	if is_quarter_requirement_active("toolsFrozen") and card.get("family", "") in ["outil-process", "methodologie-orga"]:
		return "quarter-requirement"
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
	if is_quarter_requirement_active("hiringFrozen"):
		return "quarter-requirement"
	if get_roster().size() >= get_team_cap():
		return "cap"
	var cost: int = max(0, int(candidate.get("costPieces", 0)) - next_hire_discount)
	if pieces < cost:
		return "pieces"

	pieces -= cost
	var discount_note := ""
	if next_hire_discount > 0:
		discount_note = " (réseau : −%d 🪙)" % next_hire_discount
		next_hire_discount = 0

	_get_primary_roster().append({
		"id": candidate.get("id", ""),
		"name": candidate.get("name", ""),
		"role": candidate.get("role", ""),
		"seniority": candidate.get("seniority", "junior"),
		"salary": int(candidate.get("salary", GameData.balance.get("salaries", {}).get(candidate.get("seniority", "junior"), 1))),
		"trait": candidate.get("trait", ""),
		"visible_trait_id": candidate.get("visible_trait_id", ""),
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
	var owner := _find_employee_owner(employee_id)
	if owner.is_empty():
		return "introuvable"
	var employee: Dictionary = owner.get("employee", {})
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
	var owner_squad: Dictionary = owner.get("squad", {})
	var owner_roster: Array = owner_squad.get("roster", [])
	owner_roster.erase(employee)
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
	var cynisme := float(_active_quarter_effects().get("practiceCynisme", GameData.balance.get("shopDraw", {}).get("practiceCynisme", 2)))
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


## Les événements des équipes subies (spec §9.4) se déclarent `supportTeam`
## + `levelRange` : un niveau bas génère des crises, un niveau haut de la
## pression — le niveau lui-même reste fixé par l'entreprise, jamais changé
## ici. Un événement sans `supportTeam` reste éligible en toutes circonstances.
func _eligible_inbox_events() -> Array:
	var result: Array = []
	for event in GameData.inbox_events:
		var eras: Array = event.get("eras", [])
		if not (eras.is_empty() or eras.has(era_id)):
			continue
		var support_team: String = event.get("supportTeam", "")
		if support_team != "":
			var level := int(support_teams.get(support_team, 3))
			var level_range: Array = event.get("levelRange", [0, 5])
			var low := int(level_range[0]) if level_range.size() > 0 else 0
			var high := int(level_range[1]) if level_range.size() > 1 else 5
			if level < low or level > high:
				continue
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


## Applique le panier d'effets aux ressources (+ masse salariale, effets de
## roster et de pratiques, décroissance de la Valeur perçue, conversion
## Traction × Levier × Impact, flux de pièces), journalise, puis vérifie les
## fins de ressources et la revue trimestrielle. Retourne l'id de la fin
## atteinte, ou "" si le mandat continue.
## À appeler une seule fois par sprint, depuis l'écran de Résolution.
func apply_pending_and_check() -> String:
	if quarter_exit_choice_pending:
		return ""
	last_tresorerie_cost = int(round(pending_deltas.get("tresorerie", 0.0)))

	_apply_per_sprint_effects()
	var was_cleanup_sprint := cleanup_sprint_pending
	last_score_report = ScoreResolver.resolve(_build_score_snapshot(), {
		"scoring": GameData.scoring,
		"hidden_traits": GameData.hidden_traits,
		"cards": GameData.cards,
	})
	# 🧹 Consommé après avoir servi au snapshot : le sprint qui suit l'achat
	# est le seul à neutraliser la Traction (spec §12).
	if was_cleanup_sprint:
		cleanup_sprint_pending = false
		pending_journal_lines.append("🧹 Sprint de remise à plat : Traction neutralisée ce sprint, quoi que le roster ait livré.")
	_apply_payroll()
	_apply_score_conversion()

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

	_apply_energy_flow()
	var energy_sprint_delta := int(last_energy_report.get("sprintDelta", 0))
	if energy_sprint_delta != 0:
		applied["energie"] = energy_sprint_delta

	var quarter_ending := _record_quarter_resolution()
	if last_pieces_delta != 0:
		applied["pieces"] = last_pieces_delta

	journal.append({
		"sprint": sprint_number,
		"text": " · ".join(pending_journal_lines) if not pending_journal_lines.is_empty() else "Sprint calme — aucune décision marquante.",
		"deltas": EffectResolver.format_deltas(applied),
	})

	pending_deltas.clear()
	pending_journal_lines.clear()
	_resolve_trial_periods()
	_resolve_silent_quits()

	if quarter_ending != "":
		return quarter_ending

	var bad_ending := _check_bad_endings()
	if bad_ending != "":
		is_mandate_over = true
		ending_id = bad_ending
		ending_reached.emit(bad_ending)
		return bad_ending

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
	for employee in get_roster():
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


## Snapshot immuable du sprint. Les deltas de contenu et de pratiques ont
## déjà été accumulés ; le score lit donc les ressources telles qu'elles
## seront après Résolution, sans les appliquer une seconde fois.
func _build_score_snapshot() -> Dictionary:
	var score_squads: Array = []
	var primary_report: Dictionary = last_roadmap_report if int(last_roadmap_report.get("sprint", -1)) == sprint_number else {}
	for squad_index in squads.size():
		var squad: Dictionary = squads[squad_index]
		var delivered: Array = []
		var spent_points := 0
		var capacity := int(squad.get("capacity", get_effective_capacity()))
		if squad_index == 0:
			delivered = primary_report.get("delivered", [])
			spent_points = int(primary_report.get("plannedPoints", 0))
			capacity = int(primary_report.get("capacity", get_effective_capacity()))
			squad["delivered"] = delivered
			squad["capacity"] = capacity
			squad["spent_points"] = spent_points
			squads[squad_index] = squad
		else:
			delivered = squad.get("delivered", [])
			spent_points = int(squad.get("spent_points", squad.get("planned_points", 0)))
		score_squads.append({
			"id": squad.get("id", "equipe-%d" % squad_index),
			"roster": squad.get("roster", []),
			"capacity": capacity,
			# 🧹 Sprint de remise à plat (spec §12) : la Traction du sprint est
			# neutralisée, quoi que le roster ait livré — `squads[]` et
			# `last_roadmap_report` gardent la vraie livraison pour l'affichage,
			# seule la vue lue par le score est vidée.
			"delivered": [] if cleanup_sprint_pending else delivered,
			"spent_points": spent_points,
		})

	return {
		"sprint": sprint_number,
		"squads": score_squads,
		"resources": _projected_score_resources(),
		"mrr": mrr,
		"recurring_roi": recurring_roi,
		"budget": pieces,
		"business_model_id": business_model_id,
		"support_teams": support_teams.duplicate(),
		"product_tier": product_tier,
		"active_tools": _active_tool_entries(),
		"owned_practices": owned_practices,
		"strategy_ids": _score_strategy_ids(),
		"minimum_client_impact_for_traction": int(_active_quarter_effects().get("minimumClientImpactForTraction", 0)),
		"debt_friction_scale": float(_active_quarter_effects().get("debtFrictionScale", 1.0)),
		"streak": streak,
	}


## Les décisions stratégiques sont permanentes une fois choisies (spec §7.2)
## — à distinguer des outils (`activated_cards`), qui restent une famille à
## part et peuvent être libérés (§7.1.2).
func _score_strategy_ids() -> Array:
	return chosen_strategy_ids.duplicate()


func _active_tool_entries() -> Array:
	var entries: Array = []
	for card_id in activated_cards:
		var activated_sprint := int(activated_card_sprints.get(card_id, sprint_number))
		entries.append({
			"id": card_id,
			"active_sprints": max(0, sprint_number - activated_sprint + 1),
		})
	return entries


func _projected_score_resources() -> Dictionary:
	var bounds: Dictionary = GameData.balance.get("resourceBounds", {"min": 0, "max": 100})
	var minimum: float = bounds.get("min", 0)
	var maximum: float = bounds.get("max", 100)
	var projected := resource_values.duplicate()
	for resource_id in pending_deltas.keys():
		if not projected.has(resource_id):
			continue
		projected[resource_id] = clamp(float(projected[resource_id]) + float(pending_deltas[resource_id]), minimum, maximum)
	return projected


func _apply_payroll() -> void:
	last_payroll = int(round(float(get_payroll()) * float(_active_quarter_effects().get("payrollMultiplier", 1.0))))
	if last_payroll > 0:
		pending_deltas["tresorerie"] = pending_deltas.get("tresorerie", 0.0) - last_payroll
		pending_journal_lines.append("Masse salariale : −%d 💰 (%d personnes)" % [last_payroll, get_roster().size()])


## Convertit le rapport du ScoreResolver en état de jeu. Aucun calcul de
## score ne vit ici : le rapport est la seule source de vérité de l'économie.
func _apply_score_conversion() -> void:
	var conversion: Dictionary = last_score_report.get("conversion", {})
	var mrr_report: Dictionary = conversion.get("mrr", {})
	var budget_report: Dictionary = conversion.get("budget", {})

	mrr = float(mrr_report.get("after", mrr))
	streak = int(last_score_report.get("next_streak", 0))
	last_revenue = int(round(mrr))
	last_roi_revenue_bonus = int(round(float(mrr_report.get("recurring_roi_gain", 0.0))))
	if last_revenue != 0:
		pending_deltas["tresorerie"] = pending_deltas.get("tresorerie", 0.0) + last_revenue
		pending_journal_lines.append("MRR : +%d (dont backlog +%d)" % [last_revenue, last_roi_revenue_bonus])

	for resource_id in conversion.get("resource_deltas", {}).keys():
		var delta: float = float(conversion["resource_deltas"][resource_id])
		if not is_zero_approx(delta):
			pending_deltas[resource_id] = pending_deltas.get(resource_id, 0.0) + delta

	var pending_pieces := int(round(pending_deltas.get("pieces", 0.0)))
	pending_deltas.erase("pieces")
	var score_budget_gain := int(budget_report.get("gain", 0))
	var before := pieces
	pieces = max(0, pieces + pending_pieces + score_budget_gain)
	last_pieces_delta = pieces - before

	var parts: Array = ["rapport +%d" % score_budget_gain]
	if pending_pieces != 0:
		parts.append("décisions %s%d" % ["+" if pending_pieces >= 0 else "−", abs(pending_pieces)])
	pending_journal_lines.append("🪙 Budget d'investissement : %s (solde %d)" % [" · ".join(parts), pieces])


func _record_quarter_resolution() -> String:
	quarter_impact += int(last_score_report.get("global", {}).get("impact", 0))
	quarter_sprint += 1
	if quarter_sprint < get_quarter_length():
		return ""

	var objectives := evaluate_board_objectives()
	var qualitative_ok := true
	for objective in objectives:
		if not bool(objective.get("ok", false)):
			qualitative_ok = false
	var passed := quarter_impact >= get_current_quota()
	# 🏛️ Plan de redressement (spec §12) : un rattrapage de quota consommé
	# automatiquement, la première fois où il sert — jamais un choix manuel,
	# sinon on ne le "raterait" jamais.
	var turnaround_used := false
	if not passed and turnaround_plans_available > 0:
		turnaround_plans_available -= 1
		passed = true
		turnaround_used = true
	var qualitative_bonus := 0
	if passed and qualitative_ok:
		qualitative_bonus = int(GameData.quotas.get("qualitativeBonusBudget", GameData.quotas.get("qualitativeBonus", {}).get("budget", 8)))
		pieces += qualitative_bonus
		last_pieces_delta += qualitative_bonus

	quarter_result = {
		"sprint": sprint_number,
		"quarter": quarter_index,
		"length": get_quarter_length(),
		"quota": get_current_quota(),
		"impact": quarter_impact,
		"passed": passed,
		"turnaroundUsed": turnaround_used,
		"qualitativeBonus": qualitative_bonus,
		"objectives": objectives,
		"requirementIds": quarter_requirement_ids.duplicate(),
	}
	board_review_state = "passed" if qualitative_ok else "failed"
	board_review_result = quarter_result.duplicate(true)
	pending_journal_lines.append("Revue trimestrielle : %d / %d Impact%s" % [
		quarter_impact, get_current_quota(), " · bonus qualitatif +%d 🪙" % qualitative_bonus if qualitative_bonus > 0 else ""
	])
	if not passed:
		is_mandate_over = true
		ending_id = "remercie"
		ending_reached.emit(ending_id)
		return ending_id
	if quarter_index == 4 and not long_mandate:
		quarter_exit_choice_pending = true
		return ""
	_prepare_quarter(quarter_index + 1)
	return ""


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
	for squad in squads:
		for employee in squad.get("roster", []):
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
	for squad in squads:
		for employee in squad.get("roster", []):
			if not employee.get("hiddenRevealed", false):
				continue
			var hidden_trait := get_hidden_trait(employee.get("hidden_trait", ""))
			var quits_at := int(hidden_trait.get("effects", {}).get("quitsAtHiredPlus", 0))
			if quits_at > 0 and sprint_number >= int(employee.get("hiredSprint", 0)) + quits_at:
				leavers.append({"squad": squad, "employee": employee})
	for leaver in leavers:
		var owner_squad: Dictionary = leaver.get("squad", {})
		var owner_roster: Array = owner_squad.get("roster", [])
		var employee: Dictionary = leaver.get("employee", {})
		owner_roster.erase(employee)
		journal.append({
			"sprint": sprint_number,
			"text": "🧨 %s a démissionné sans prévenir. Le badge est resté sur le bureau, le Slack est déjà désactivé." % employee.get("name", ""),
			"deltas": "",
		})


## Confronte les objectifs qualitatifs de l'entreprise à l'état courant, sans
## rien modifier. Le runtime les relit lors de chaque revue trimestrielle et
## l'UI peut les afficher en direct.
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
			for member in get_roster():
				if member.get("seniority", "") == condition.get("seniority", "senior"):
					count += 1
			ok = count >= int(condition.get("value", 1))
			current = "%d/%d" % [count, int(condition.get("value", 1))]
		"practice-owned":
			ok = owned_practices.has(condition.get("practice", ""))
			current = "oui" if ok else "non"
	return {"ok": ok, "current": current}


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
