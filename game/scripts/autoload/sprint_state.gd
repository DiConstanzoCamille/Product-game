extends Node
## Autoload : état complet d'un mandat (run) — les 5 ressources persistantes,
## les **deux monnaies** (💥 le portefeuille d'Impact et 💰 le Revenue), le
## scénario choisi, les squads (une seule aujourd'hui), les pratiques, les
## grandes décisions activées, le journal, et le panier d'effets en attente
## pour le sprint en cours.
##
## Les deux monnaies ne se remplacent jamais (docs/spec-impact-monnaie.md §3) :
## **un achat coûte de l'Impact maintenant, et engage du Revenue pour
## toujours**. L'Impact est la seule monnaie d'achat ; le Revenue ne sert
## jamais de prix, il paie chaque sprint les salaires et les licences. On peut
## donc mourir riche d'Impact et sans Revenue.
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
var pending_career_level: String = "pm"  # étape transitoire entre career_select_screen et scenario_screen

var resource_values: Dictionary = {}   # resource_id -> float (0..100)
var activated_cards: Array = []        # ids des grandes décisions activées ce mandat
var activated_card_sprints: Dictionary = {}  # card_id -> numéro de sprint d'activation
var journal: Array = []                # [{sprint, text, deltas}], le plus ancien en premier

var pending_deltas: Dictionary = {}    # resource_id -> float, accumulés sur le sprint en cours
var pending_people_effects: Array = [] # [{target, deltas, note}] — effets individuels, résolus avant le score
var pending_journal_lines: Array = []  # texte des choix faits pendant le sprint en cours

var is_mandate_over: bool = false
var ending_id: String = ""

var last_revenue: int = 0              # 💰 ce que les clients ont payé au dernier sprint résolu
var last_revenue_cost: int = 0         # somme des coûts/gains de décisions sur le Revenue (hors clients et charges)
var last_payroll: int = 0              # masse salariale prélevée au dernier sprint résolu
var last_licenses: int = 0             # licences et coûts récurrents prélevés au dernier sprint résolu
var last_client_cost: int = 0          # 🧾 support et infra des clients, prélevés au dernier sprint résolu
var last_wallet_delta: int = 0         # flux net du portefeuille d'Impact au dernier sprint résolu
var last_client_report: Dictionary = {}  # 👥 mouvements de population du dernier sprint (arrivées, départs, par segment)
var last_score_report: Dictionary = {} # rapport immuable produit par ScoreResolver
var streak: int = 0                    # sprints livrés consécutifs, réservé au score

# --- Phase A : l'entreprise ---
## 💥 Le portefeuille d'Impact — la monnaie unique. Sans plafond, **jamais
## remis à zéro** (ni entre les sprints, ni entre les trimestres), alimenté par
## Traction × Levier et débité par tous les achats. C'est aussi la valeur que
## le board regarde à chaque verdict : un seul nombre, pas un « produit » et un
## « disponible » (spec-impact-monnaie.md §4). Il peut passer sous zéro —
## l'avance sur trimestre le vend contre du Revenue, et c'est un pari assumé.
var impact_wallet: int = 0
## 💰 Le Revenue — la survie de l'entreprise. Fusion de l'ancienne Trésorerie
## (bornée 0..100) et du stock de MRR : sans plafond, jamais une jauge. Il
## encaisse les abonnements et paie chaque sprint salaires et licences. À zéro,
## l'entreprise ne paie plus : faillite.
var revenue: float = 0.0
## 👥 La population qui paie — segment_id → nombre de clients (docs/spec-clients-revenue.md
## §2). **Le Revenue n'est pas un stock : c'est ceci qui l'est.** Les clients
## arrivent parce qu'on a livré, partent au churn, et paient chaque sprint le
## prix de leur segment. Ils coûtent aussi du support à chaque sprint, ce qui
## rend une base gratuite dangereuse (§5.3). Jamais un compteur de plus à
## l'écran : c'est la ligne de composition sous le solde, pas une jauge.
var clients: Dictionary = {}
## 💳 Le prix d'un segment est une **constante du run** (§5.2). Ce dictionnaire
## est le seul endroit qui puisse le faire mentir, et seule une décision
## stratégique explicite y écrit (§4.2 — « Fin du gratuit »).
var segment_price_multipliers: Dictionary = {}
## 🚪 Ce qu'un segment accepte encore comme arrivées. Vider une population une
## fois ne suffit pas à la faire disparaître : sans ce multiplicateur, la
## livraison du sprint suivant la repeuple, et « Fin du gratuit » promet une
## fermeture qu'elle ne tient pas. À 0, le segment est fermé pour de bon.
var segment_arrival_multipliers: Dictionary = {}
var squads: Array = []                 # [{id, name, roster, backlog_draw, capacity, delivered, epic_progress}]
var piloted_squads: Dictionary = {}    # 🎯 {sprint, ids} — les équipes pilotées ce sprint (Lot 5 §13.3) ; les autres jouent seules
var owned_practices: Array = []        # ids de pratiques achetées (permanentes pour le mandat)
var fired_count: int = 0               # licenciements prononcés ce mandat (le cynisme monte à partir du 2e)
var next_hire_discount: int = 0        # remise 💥 sur le prochain recrutement (trait caché Réseau)
var current_backlog_draw: Dictionary = {}  # {sprint, items} — tirage Roadmap persistant
var epic_progress: Dictionary = {}         # epic_id -> {invested, startedSprint}
var completed_backlog_ids: Array = []      # livraisons définitives, hors du sac
var revealed_backlog_sprint: Dictionary = {}  # feature_id -> sprint du Plonger temporaire
var last_roadmap_report: Dictionary = {}   # livraison réelle affichée à la Résolution
var board_review_state: String = "pending"  # "pending" | "passed" | "failed"
var board_review_result: Dictionary = {}    # {sprint, passed, title, conditions:[{label, ok}]} — pour l'overlay de verdict
var quarter_index: int = 1
var quarter_requirement_id: String = ""
var quarter_requirement_ids: Array = []
var quarter_sprint: int = 0
var quarter_result: Dictionary = {}
var quarter_exit_choice_pending: bool = false
var long_mandate: bool = false
var quarter_forced_strategy_id: String = ""
var career_level: String = "pm"        # index dans careers.json / balance.json → toolSlots.careerLevels / quotas.json → careerLevels
var newly_unlocked_career_level: String = ""  # non vide juste après le sprint où un niveau vient de tomber (spec §13.4) — lu une fois par mandate_end_screen
var tool_slots_purchased: int = 0      # +1/+2 achetés au Comité, à prix croissant (spec §7.1.1)
var swap_count: int = 0                # bascules d'outil déjà faites ce mandat (spec §7.1.2) — chaque nouvelle coûte plus de Cynisme
var chosen_strategy_ids: Array = []    # décisions stratégiques choisies ce mandat — permanentes, 1 par trimestre (spec §7.2)
var strategy_activation_quarters: Dictionary = {}  # strategy_id -> trimestre d'adoption ; un effet ne réécrit jamais un verdict passé
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
var cpo_wellbeing: Dictionary = {}     # mêmes niveaux que le roster ; sa Confiance envers soi n'est pas jouée
var energy_spent_this_sprint: int = 0  # ⚡ réellement dépensés en actions personnelles depuis la dernière Résolution
var self_work_capacity: int = 0        # points de capacité ajoutés par "Faire le taf soi-même" ce sprint
# 🖥️ Le bureau (#54) : l'événement du sprint est tiré une fois et reste
# consultable jusqu'à la clôture ; s'il n'a pas été traité, il se paie.
var _sprint_event: Dictionary = {}
var _sprint_event_sprint: int = -1
var _sprint_event_answered: bool = false
var _sprint_event_resolution: Dictionary = {}
var last_journal: Array = []           # les lignes du dernier sprint clos, punaisées au mur
# 🏛 Le Comité n'est plus un écran qu'on traverse : c'est un parapheur déposé
# sur la table. Il ne se déduit donc pas d'un numéro de sprint — le trimestre
# vient d'être clos, le dossier attend, et il attend jusqu'à ce qu'on l'ouvre.
var committee_pending: bool = false

var breather_planned: bool = false     # Souffler pris à la dernière Résolution : actions bloquées ce sprint, bonus de régén à la prochaine
var last_energy_report: Dictionary = {}  # détail du delta Énergie de la dernière Résolution (pour l'affichage)

var _inbox_event_bag: Array = []       # ids restants à tirer dans le "sac" courant
var _last_inbox_event_id: String = ""  # évite une répétition immédiate entre deux sacs
var _hired_candidate_ids: Array = []   # candidats déjà embauchés ce mandat (ne reviennent pas au tirage)
var _backlog_bag: Array = []           # sac des propositions de Roadmap, filtré par ère
var _quarter_requirement_bag: Array = []
var _last_quarter_requirement_id: String = ""
var pending_team_crises: Array = []    # [{employee_id, criterion}] — priorité Inbox au sprint suivant
var pending_team_concerns: Array = []  # mêmes entrées, au seuil d'alerte avant la rupture


## À appeler au lancement d'un nouveau mandat, une fois le niveau de carrière,
## le scénario et l'entreprise choisis (career_select_screen, scenario_screen
## puis company_select_screen). era/company vides = tirage aléatoire parmi
## les options jouables (utile pour les tests headless). `chosen_career_level`
## vide ou non débloqué retombe silencieusement sur "pm" — le déblocage
## strict (spec §13.4) se garantit ici, pas seulement dans l'écran de choix.
func reset_run(chosen_era_id: String = "", chosen_company_id: String = "", chosen_career_level: String = "") -> void:
	sprint_number = 1
	era_id = chosen_era_id if chosen_era_id != "" else _pick_random_playable_era()
	company_id = chosen_company_id if chosen_company_id != "" else _pick_random_company(era_id)
	team_profile = get_company().get("teamProfile", "junior")
	# 💰 Le scénario choisit le modèle par défaut et surtout l'échelle de prix
	# (spec-clients-revenue.md §4.0.1) ; l'entreprise peut imposer le sien —
	# Meridia vend à des grands comptes, Karavel a une base grand public, et
	# elles jouent la même époque.
	business_model_id = str(get_company().get("businessModel", get_era().get("businessModel", "")))
	activated_cards.clear()
	activated_card_sprints.clear()
	journal.clear()
	# 🖥️ L'état du bureau appartient au run : sans ce nettoyage, un nouveau
	# mandat commençait avec le parapheur du Comité déjà posé sur la table et
	# le courrier du run précédent. Vu sur une capture, invisible autrement.
	last_journal.clear()
	committee_pending = false
	_sprint_event = {}
	_sprint_event_sprint = -1
	_sprint_event_answered = false
	_sprint_event_resolution = {}
	pending_deltas.clear()
	pending_people_effects.clear()
	pending_journal_lines.clear()
	is_mandate_over = false
	ending_id = ""
	last_revenue = 0
	last_revenue_cost = 0
	last_payroll = 0
	last_licenses = 0
	last_client_cost = 0
	last_wallet_delta = 0
	last_client_report.clear()
	last_score_report.clear()
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
	last_roadmap_report.clear()
	board_review_state = "pending"
	board_review_result.clear()
	quarter_index = 1
	quarter_requirement_id = ""
	quarter_requirement_ids.clear()
	quarter_sprint = 0
	quarter_result.clear()
	quarter_exit_choice_pending = false
	long_mandate = false
	quarter_forced_strategy_id = ""
	career_level = chosen_career_level if PlayerProfile.is_career_level_unlocked(chosen_career_level) else "pm"
	newly_unlocked_career_level = ""
	tool_slots_purchased = 0
	swap_count = 0
	chosen_strategy_ids.clear()
	strategy_activation_quarters.clear()
	quarter_strategy_chosen = false
	_quarter_requirement_bag.clear()
	_last_quarter_requirement_id = ""
	pending_team_crises.clear()
	pending_team_concerns.clear()
	current_shop_offer.clear()
	energy = int(get_energy_conf().get("start", 70))
	cpo_wellbeing = get_individual_team_conf().get("cpoStart", {}).duplicate(true)
	cpo_wellbeing["energie"] = energy
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
	# 💥 Le portefeuille démarre à zéro : **le premier sprint n'achète rien**,
	# et c'est assumé (spec §3.4). `startingImpact` existe pour les scénarios
	# qui démarreront un jour avec une avance — un trait de contexte de run,
	# pas une règle générale : la valeur vaut 0 partout aujourd'hui.
	impact_wallet = int(company.get("startingImpact", 0))
	var revenue_conf: Dictionary = GameData.balance.get("revenue", {})
	revenue = float(revenue_conf.get("startOverrides", {}).get(company_id, revenue_conf.get("start", 50)))
	# 👥 On n'hérite pas d'une caisse, on hérite de clients : la population de
	# départ est celle du modèle économique, et c'est elle qui fait le premier
	# revenu du premier sprint.
	clients.clear()
	segment_price_multipliers.clear()
	segment_arrival_multipliers.clear()
	for segment in get_segments():
		clients[segment.get("id", "")] = float(segment.get("start", 0))
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
		primary_roster.append(_employee_from_source(member, 0, true))
	piloted_squads = {}
	squads = [{
		"id": "squad-principale",
		"name": "Equipe produit",
		"roster": primary_roster,
		"backlog_draw": {},
		"capacity": 0,
		"delivered": [],
		"epic_progress": {},
	}]
	# 👥 Lot 5 (spec §13.4) : au-dessus de PM, le kit de carrière ajoute des
	# équipes neuves — à staffer par recrutement, l'équipe héritée de
	# l'entreprise reste seule à démarrer garnie. squadsMin est déterministe
	# (pas de tirage) : deux runs du même niveau démarrent avec le même nombre
	# d'équipes, seule leur composition varie.
	var level_conf: Dictionary = GameData.careers.get("levels", {}).get(career_level, {})
	var extra_squad_count: int = max(0, int(level_conf.get("squadsMin", 1)) - 1)
	for extra_index in range(extra_squad_count):
		squads.append(_new_empty_squad(extra_index + 2))

	resource_values.clear()
	var starting: Dictionary = GameData.balance.get("startingResources", {})
	var overrides: Dictionary = GameData.balance.get("startingResourceOverrides", {}).get(company_id, {})
	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		resource_values[resource_id] = float(overrides.get(resource_id, starting.get(resource_id, 50)))
	_refresh_team_moral()
	_prepare_quarter(1)
	get_effective_capacity()


## Équipe neuve du kit de carrière (Lead PM et au-delà) : aucun héritage,
## roster vide, à staffer par recrutement (spec §13.3-13.4). `display_index`
## sert uniquement au nom affiché ("Équipe B", "Équipe C"...) — jamais le mot
## "squad" dans une chaîne visible (CLAUDE.md, contrat d'architecture §4).
func _new_empty_squad(display_index: int) -> Dictionary:
	return {
		"id": "squad-%d" % display_index,
		"name": "Équipe %s" % char(64 + display_index),  # 2 -> "B", 3 -> "C"...
		"roster": [],
		"backlog_draw": {},
		"capacity": 0,
		"delivered": [],
		"epic_progress": {},
		"spent_points": 0,
		"bag": [],
		"completed_ids": [],
	}


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
	# L'exigence tirée pour CE trimestre est la seule couche qui ne vaut que
	# maintenant : elle s'ajoute au barème structurel, elle ne le déplace pas.
	return int(round(_structural_quota(quarter_index) * float(_active_quarter_effects().get("quotaMultiplier", 1.0))))


## Le barème d'un trimestre donné, exigence ponctuelle exclue. C'est la courbe
## que le joueur doit rattraper sur tout son mandat, et c'est elle — pas le
## quota du moment, qui bouge avec un tirage — qui sert de référence aux prix
## (§3.3) et à l'affichage des quatre objectifs du mandat.
func get_quota_for_quarter(index: int) -> int:
	return int(round(_structural_quota(index)))


## Les objectifs du mandat, du premier au dernier, tels qu'ils sont connus dès
## le sprint 1 : la donnée existe dans quotas.json, la cacher n'ajoutait aucune
## tension, elle empêchait seulement de préparer un plan.
func get_mandate_quotas() -> Array:
	var quotas: Array = []
	for index in range(1, _mandate_quarter_count() + 1):
		quotas.append({
			"quarter": index,
			"quota": get_quota_for_quarter(index),
			"reached": quarter_index > index,
			"current": quarter_index == index,
		})
	return quotas


func _mandate_quarter_count() -> int:
	var levels: Dictionary = GameData.quotas.get("careerLevels", {})
	var level: Dictionary = levels.get(career_level, levels.get("pm", {}))
	var configured: Variant = level.get("quarterQuotas", [])
	var table_size: int = configured.size() if configured is Array else 4
	return maxi(table_size, quarter_index)


func _structural_quota(index: int) -> float:
	var levels: Dictionary = GameData.quotas.get("careerLevels", {})
	var level: Dictionary = levels.get(career_level, levels.get("pm", {}))
	var configured: Variant = level.get("quarterQuotas", [])
	var base_quota := 0.0
	if configured is Array and not configured.is_empty():
		# Au-delà de la table (mandat long), on repart de sa dernière ligne :
		# jamais d'une valeur écrite ici. Un quota en dur dans un script rend le
		# rééquilibrage impossible sans un dev — et celui qui vivait là a
		# silencieusement figé le T5 sur l'ancien barème.
		base_quota = float(configured[mini(index, configured.size()) - 1])
	elif configured is Dictionary:
		base_quota = float(configured.get(str(min(index, 4)), 0))

	var long_conf: Dictionary = GameData.quotas.get("longMandate", {})
	if index >= int(long_conf.get("fromQuarter", 5)):
		var multiplier := float(long_conf.get("quotaMultiplier", 2.2))
		base_quota *= pow(multiplier, index - 4)
	# 🧭 Une décision stratégique peut relever la barre à partir du trimestre
	# où elle est prise (Expansion internationale : plus de marché, plus
	# d'attentes). Elle ne réécrit jamais un quota déjà jugé : l'historique et
	# le verdict restent donc cohérents dans le panneau latéral.
	var strategy_quota := 1.0
	for strategy_id in chosen_strategy_ids:
		if int(strategy_activation_quarters.get(strategy_id, 1)) > index:
			continue
		strategy_quota *= float(GameData.scoring.get("global", {}).get("strategies", {}).get(strategy_id, {}).get("quotaMultiplier", 1.0))
	return base_quota * strategy_quota


func get_quarter_length() -> int:
	return max(1, int(_active_quarter_effects().get("quarterLength", 3)))


# --- 💥 Les prix, 💰 les charges : les deux seules portes d'entrée ---
## Tout ce qui s'achète a **deux dimensions** et une seule monnaie : un prix en
## Impact, payé maintenant, et une charge en Revenue, payée à chaque sprint
## jusqu'à la fin du mandat (spec-impact-monnaie.md §3.1). Les écrans lisent
## ces deux fonctions et jamais un nombre brut d'un JSON — c'est la condition
## pour que le lot B (#36) puisse indexer les prix sur l'escalade des objectifs
## sans rouvrir un seul écran.

## Prix d'un poste, en 💥 Impact. `kind` : "candidate" | "practice" |
## "decision" | "committee" | "reroll" | "reserve" | "severance". Retourne -1
## quand la table de prix d'un poste est épuisée (le poste refusera
## « plafond »), jamais un prix négatif.
func resolved_price(kind: String, item_id: String = "", data: Dictionary = {}) -> int:
	var base := _base_price(kind, item_id, data)
	if base < 0.0:
		return -1
	var price := base * price_index()
	# 🕸️ Réseau : la remise du trait caché s'applique ici et nulle part
	# ailleurs — un écran qui recalculerait le prix l'oublierait.
	if kind == "candidate":
		price -= float(next_hire_discount)
	return maxi(0, int(round(price)))


## Indexation des prix sur l'escalade des objectifs (spec §3.3) :
## `(objectif_du_trimestre / objectif_T1) ^ k`, k dans balance.json.
##
## Sans elle, un objectif à 4600 face à des outils à 25 rend tout le late game
## gratuit — le joueur achète le catalogue sans réfléchir au moment précis où
## la décision devrait être la plus tendue. Avec `k = 1`, le défaut inverse :
## le pouvoir d'achat relatif ne bouge jamais et chaque trimestre est le
## précédent avec plus de zéros.
##
## Deux choix de mise en œuvre, tous deux volontaires :
##
##  · la référence est le barème **structurel** (`_structural_quota`), pas le
##    quota du moment. Une exigence tirée au sort qui relève la barre d'un
##    trimestre ne doit pas faire bondir l'étal avec elle : le prix suivrait un
##    tirage, et le joueur ne pourrait plus rien anticiper ;
##  · une décision stratégique qui relève la barre **pour toujours**, elle, est
##    dans la référence. Sinon la stratégie qui durcit le mandat rendrait
##    mécaniquement le catalogue bon marché.
##
## Au Comité, `quarter_index` pointe déjà le trimestre qui s'ouvre (le verdict
## appelle `_prepare_quarter` avant) : on y achète donc au prix du trimestre
## dans lequel on entre, ce qui est la lecture voulue.
func price_index() -> float:
	var exponent := float(GameData.balance.get("prices", {}).get("quotaIndexExponent", 0.7))
	var reference := _structural_quota(1)
	if reference <= 0.0:
		return 1.0
	return pow(_structural_quota(quarter_index) / reference, exponent)


func _base_price(kind: String, item_id: String, data: Dictionary) -> float:
	match kind:
		"candidate":
			return float(data.get("costImpact", find_candidate(item_id).get("costImpact", 0)))
		"practice":
			return float(find_practice(item_id).get("costImpact", 0))
		"decision":
			return float(find_card(item_id).get("costImpact", 0))
		"reroll":
			var reroll_conf: Dictionary = GameData.balance.get("shopDraw", {}).get("reroll", {})
			var used := int(current_shop_offer.get("rerolls", 0)) if int(current_shop_offer.get("sprint", -1)) == sprint_number else 0
			return float(reroll_conf.get("baseCost", 8)) + float(reroll_conf.get("costIncrement", 8)) * used
		"reserve":
			return float(GameData.balance.get("shopDraw", {}).get("reserveCostImpact", 10))
		"severance":
			return float(GameData.balance.get("firing", {}).get("severanceImpact", 18))
		"committee":
			return _committee_base_price(item_id)
	return 0.0


## Les postes du Comité : prix plat, échelle croissante consommée dans l'ordre,
## ou fourchette tirée une fois par trimestre. -1 = table épuisée.
func _committee_base_price(item_id: String) -> float:
	var item := find_investment_item(item_id)
	match item_id:
		"strategic-decision":
			if int(current_committee_offer.get("quarter", -1)) != quarter_index:
				var range_conf: Array = item.get("costRange", [150, 300])
				var low := int(range_conf[0]) if range_conf.size() > 0 else 150
				var high := int(range_conf[1]) if range_conf.size() > 1 else 300
				current_committee_offer = {"quarter": quarter_index, "strategy_cost": randi_range(low, high)}
			return float(current_committee_offer.get("strategy_cost", 150))
		"tool-slot":
			var slot_costs: Array = GameData.balance.get("toolSlots", {}).get("extraSlotCosts", [])
			if tool_slots_purchased >= slot_costs.size():
				return -1.0
			return float(slot_costs[tool_slots_purchased])
		"open-seat":
			var seat_costs: Array = item.get("costs", [])
			if team_cap_purchased >= seat_costs.size():
				return -1.0
			return float(seat_costs[team_cap_purchased])
		"product-tier":
			var tier_costs: Array = item.get("costs", [])
			if product_tier >= tier_costs.size():
				return -1.0
			return float(tier_costs[product_tier])
	return float(item.get("cost", 0))


## 💰 Charge récurrente qu'un poste engage, en Revenue **par sprint**. Comptée
## par siège pour tout ce qui s'utilise (spec §3.6) : grandir n'augmente jamais
## seulement la production, ça augmente aussi la facture. Lue avec le roster
## d'aujourd'hui — c'est ce qu'il faut afficher sur une carte : « voilà ce que
## ça vous coûterait maintenant ».
func recurring_charge(kind: String, item_id: String, data: Dictionary = {}) -> int:
	var seats := get_roster().size()
	match kind:
		"candidate":
			var candidate := data if not data.is_empty() else find_candidate(item_id)
			var seniority: String = candidate.get("seniority", "junior")
			return int(candidate.get("salary", GameData.balance.get("salaries", {}).get(seniority, 1)))
		"practice":
			return _seat_charge(find_practice(item_id), seats, "defaultPracticePerSeat")
		"decision":
			var card := find_card(item_id)
			if not _card_occupies_a_slot(card):
				return 0
			return _seat_charge(card, seats, "defaultToolPerSeat")
		"strategy":
			return int(find_strategy(item_id).get("licenseFlat",
				GameData.balance.get("licenses", {}).get("defaultStrategyFlat", 0)))
		"committee":
			if item_id == "product-tier":
				return int(find_investment_item(item_id).get("licenseFlatPerTier", 0))
	return 0


## Une licence par siège arrondie au plus proche : `licensePerSeat × effectif`,
## avec le défaut de balance.json quand le poste n'en déclare pas. Un poste qui
## déclare 0 ne coûte rien — c'est une valeur, pas un oubli.
func _seat_charge(item: Dictionary, seats: int, default_key: String) -> int:
	var per_seat := float(item.get("licensePerSeat",
		GameData.balance.get("licenses", {}).get(default_key, 0.0)))
	return int(round(per_seat * float(seats)))


## Un outil n'occupe un slot — et donc ne se paie une licence — que s'il est de
## la famille outillage. Les autres grandes décisions sont des bascules
## ponctuelles : elles coûtent à l'activation, pas tous les mois.
func _card_occupies_a_slot(card: Dictionary) -> bool:
	return card.get("family", "") in ["outil-process", "methodologie-orga"]


## Ce que l'organisation paie **chaque sprint**, ligne par ligne. Affiché par
## les écrans et appliqué par la Résolution : une seule fonction pour les deux
## usages (CLAUDE.md), sinon l'addition affichée finit par mentir.
## Retourne {total, payroll, licenses, lines:[{icon, label, amount}]}.
func get_recurring_charges() -> Dictionary:
	var lines: Array = []
	var payroll := get_payroll()
	if payroll > 0:
		lines.append({"icon": "👥", "label": "Masse salariale (%d personnes)" % get_roster().size(), "amount": payroll})

	var licenses := 0
	for card_id in activated_cards:
		var charge := recurring_charge("decision", card_id)
		if charge > 0:
			licenses += charge
			lines.append({"icon": find_card(card_id).get("icon", "🛠️"), "label": "Licence %s" % find_card(card_id).get("name", card_id), "amount": charge})
	for practice_id in owned_practices:
		var practice_charge := recurring_charge("practice", practice_id)
		if practice_charge > 0:
			licenses += practice_charge
			lines.append({"icon": find_practice(practice_id).get("icon", "✨"), "label": "Licence %s" % find_practice(practice_id).get("name", practice_id), "amount": practice_charge})
	for strategy_id in chosen_strategy_ids:
		var strategy_charge := recurring_charge("strategy", strategy_id)
		if strategy_charge > 0:
			licenses += strategy_charge
			lines.append({"icon": find_strategy(strategy_id).get("icon", "🧭"), "label": find_strategy(strategy_id).get("name", strategy_id), "amount": strategy_charge})
	var tier_charge := recurring_charge("committee", "product-tier") * product_tier
	if tier_charge > 0:
		licenses += tier_charge
		lines.append({"icon": "🚀", "label": "Infrastructure produit (palier %d)" % product_tier, "amount": tier_charge})

	# 🧾 Ce que la population coûte : au même titre qu'une licence par siège,
	# mais par client (spec-clients-revenue.md §5.3). Sans cette ligne, une base
	# gratuite n'a aucun inconvénient et le freemium n'est plus un pari.
	var client_cost := int(round(get_client_support_cost()))
	if client_cost > 0:
		lines.append({"icon": "🧾", "label": "Support et infra (%d clients)" % int(round(get_client_total())), "amount": client_cost})

	return {
		"total": payroll + licenses + client_cost,
		"payroll": payroll,
		"licenses": licenses,
		"clients": client_cost,
		"lines": lines,
	}


## Texte court de la charge d'un poste, pour la zone « coût » d'une carte :
## l'achat doit annoncer sa facture, sinon le joueur qui découvre le salaire
## après avoir recruté a été piégé, pas mis au défi (issue #35).
func recurring_charge_text(kind: String, item_id: String, data: Dictionary = {}) -> String:
	var charge := recurring_charge(kind, item_id, data)
	if charge <= 0:
		return "aucune charge récurrente"
	return "%d 💰/sprint, pour toujours" % charge


func find_candidate(candidate_id: String) -> Dictionary:
	for candidate in GameData.candidates:
		if candidate.get("id", "") == candidate_id:
			return candidate
	return {}


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
		# Le board regarde le **solde** du portefeuille, pas la production du
		# trimestre : un seul nombre (spec §4).
		"impact": impact_wallet,
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


## Le portefeuille d'Impact n'est **pas** remis à zéro ici : il se garde d'un
## trimestre à l'autre (spec §2). Le cliquet est assumé — c'est l'escalade des
## quotas, désormais cumulatifs, qui le compense (quotas.json).
func _prepare_quarter(next_quarter: int) -> void:
	quarter_index = next_quarter
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
			elif key == "minimumClientsForTraction":
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
		result["minimumClientsForTraction"] = int(raw.get("featureTraction", {}).get("clientsMax", 0)) + 1
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
	strategy_activation_quarters[strategy_id] = quarter_index
	quarter_strategy_chosen = true
	pending_journal_lines.append("🧭 Décision stratégique : %s %s adoptée — irréversible pour le reste du mandat." % [
		strategy.get("icon", ""), strategy.get("name", strategy_id)
	])
	_apply_strategy_support_team_deltas(strategy_id)
	_apply_strategy_on_choice(strategy_id)
	return ""


## 🔒 Le pivot de modèle économique (spec-clients-revenue.md §4.2) — le seul
## endroit du jeu qui change le prix d'un segment, et il ne s'exécute qu'une
## fois : à la décision. La fraction qui bascule est **tirée** dans une
## fourchette déclarée sur la carte. Le joueur sait qu'il ferme la porte, il ne
## sait pas combien le suivront — c'est un pari, pas un calcul (question 4 de
## la vision). Rien n'est en dur ici : sans `onChoice`, la décision ne touche
## pas la population.
func _apply_strategy_on_choice(strategy_id: String) -> void:
	var strategy: Dictionary = GameData.scoring.get("global", {}).get("strategies", {}).get(strategy_id, {})
	var parts: Array = []

	# 💳 Une décision qui change le prix l'écrit dans `segment_price_multipliers`
	# et nulle part ailleurs : c'est la table que `resolved_segment_price()` lit
	# pour l'affichage ET que le rapport de score lit pour encaisser. Deux
	# chemins de calcul pour un même prix, et la composition affichée sous le
	# solde se met à mentir dès la première décision.
	var global_price := float(strategy.get("priceMultiplier", 1.0))
	if not is_equal_approx(global_price, 1.0):
		for segment in get_segments():
			var id: String = segment.get("id", "")
			segment_price_multipliers[id] = float(segment_price_multipliers.get(id, 1.0)) * global_price
		parts.append("prix ×%s" % String.num(global_price, 2).trim_suffix("0").trim_suffix("."))

	var rules: Dictionary = strategy.get("onChoice", {})
	if rules.is_empty():
		if not parts.is_empty():
			pending_journal_lines.append("👥 %s" % " · ".join(parts))
		return

	var conversion: Dictionary = rules.get("convertRoleRange", {})
	if not conversion.is_empty():
		var ratio := randf_range(float(conversion.get("minRatio", 0.0)), float(conversion.get("maxRatio", 0.0)))
		var moved := convert_clients(str(conversion.get("from", "")), str(conversion.get("to", "")), ratio)
		if moved > 0.0:
			parts.append("%d clients basculent" % int(round(moved)))

	for role in rules.get("roleMultipliers", {}).keys():
		var multiplier := float(rules["roleMultipliers"][role])
		var lost := 0.0
		for segment in get_segments():
			if str(segment.get("role", "")) != str(role):
				continue
			var segment_id: String = segment.get("id", "")
			lost += get_client_count(segment_id) * (1.0 - multiplier)
			clients[segment_id] = get_client_count(segment_id) * multiplier
		if lost > 0.0:
			parts.append("%d partent" % int(round(lost)))

	for role in rules.get("roleArrivalMultipliers", {}).keys():
		var arrival_multiplier := float(rules["roleArrivalMultipliers"][role])
		for segment in get_segments():
			if str(segment.get("role", "")) != str(role):
				continue
			var closed_id: String = segment.get("id", "")
			segment_arrival_multipliers[closed_id] = float(segment_arrival_multipliers.get(closed_id, 1.0)) * arrival_multiplier
		if is_zero_approx(arrival_multiplier):
			parts.append("la porte d'entrée se referme")

	for role in rules.get("rolePriceMultipliers", {}).keys():
		var price_multiplier := float(rules["rolePriceMultipliers"][role])
		for segment in get_segments():
			if str(segment.get("role", "")) != str(role):
				continue
			var segment_id: String = segment.get("id", "")
			segment_price_multipliers[segment_id] = float(segment_price_multipliers.get(segment_id, 1.0)) * price_multiplier
		parts.append("prix ×%s" % String.num(price_multiplier, 2).trim_suffix("0").trim_suffix("."))

	if not parts.is_empty():
		pending_journal_lines.append("👥 %s" % " · ".join(parts))


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

## Débite le portefeuille d'Impact. Retourne "" si le paiement a eu lieu,
## sinon "impact" — le refus que tous les écrans rejouent tel quel. Un achat ne
## fait jamais passer le portefeuille sous zéro : on ne s'endette que par un
## pari explicite (🎲 Avance sur trimestre), jamais par mégarde.
func _pay_impact(cost: int) -> String:
	if impact_wallet < cost:
		return "impact"
	impact_wallet -= cost
	return ""


func find_investment_item(item_id: String) -> Dictionary:
	for item in GameData.investments.get("items", []):
		if item.get("id", "") == item_id:
			return item
	return {}


## Le prix de la décision stratégique varie par trimestre (spec §12) — tiré
## une fois et mémorisé pour ne pas changer entre deux rafraîchissements du
## Comité, comme le tirage de l'étal du sprint.
func strategy_purchase_cost() -> int:
	return resolved_price("committee", "strategic-decision")


## Version payante de choose_strategy() — la seule que le Comité expose ;
## _assign_forced_strategy() continue d'appeler choose_strategy() directement,
## sans coût, puisqu'une injonction du board ne se négocie pas.
func buy_strategy(strategy_id: String) -> String:
	if quarter_strategy_chosen:
		return "deja-choisie-ce-trimestre"
	var cost := strategy_purchase_cost()
	if impact_wallet < cost:
		return "impact"
	var refusal := choose_strategy(strategy_id)
	if refusal != "":
		return refusal
	impact_wallet -= cost
	var charge := recurring_charge("strategy", strategy_id)
	pending_journal_lines.append("💥 Comité : −%d d'Impact%s." % [
		cost, " · %d 💰/sprint engagés" % charge if charge > 0 else ""
	])
	return ""


## 🪑 Ouvrir un poste : +1 au cap d'effectif, aujourd'hui figé par
## l'entreprise (companies.json → teamCap). Échelle de prix croissante,
## comme les slots d'outillage ; -1 une fois la table épuisée.
func team_cap_purchase_cost() -> int:
	return resolved_price("committee", "open-seat")


func buy_team_cap_seat() -> String:
	var cost := team_cap_purchase_cost()
	if cost < 0:
		return "plafond"
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal
	team_cap_purchased += 1
	pending_journal_lines.append("🪑 Poste ouvert (%d 💥) — cap d'effectif porté à %d." % [cost, get_team_cap()])
	return ""


## 📈 Promotion : un junior nommé devient senior (salaire +1, contribution
## senior). Retourne "" si la promotion a eu lieu, sinon la raison du refus.
func promotion_cost() -> int:
	return resolved_price("committee", "promotion")


func promote_employee(employee_id: String) -> String:
	var owner := _find_employee_owner(employee_id)
	if owner.is_empty():
		return "introuvable"
	var employee: Dictionary = owner.get("employee", {})
	if employee.get("seniority", "junior") != "junior":
		return "deja-senior"
	var cost := promotion_cost()
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal
	employee["seniority"] = "senior"
	var raise_amount := int(GameData.balance.get("salaries", {}).get("senior", 2)) - int(employee.get("salary", 1))
	employee["salary"] = int(GameData.balance.get("salaries", {}).get("senior", 2))
	apply_people_effect_for_employee(employee, {"salaire": float(get_individual_team_conf().get("promotionSalaire", 0))})
	pending_journal_lines.append("📈 Promotion (%d 💥) : %s passe senior — %+d 💰/sprint de salaire." % [cost, employee.get("name", employee_id), raise_amount])
	return ""


## 🚀 Palier de produit : +0,5 Levier permanent (scoring.json →
## global.productTier), +1 feature proposée par sprint (_draw_backlog_offer).
## 3 paliers maximum par run — la table de prix fait foi.
func product_tier_purchase_cost() -> int:
	return resolved_price("committee", "product-tier")


func buy_product_tier() -> String:
	var cost := product_tier_purchase_cost()
	if cost < 0:
		return "plafond"
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal
	product_tier += 1
	pending_journal_lines.append("🚀 Palier de produit %d atteint (%d 💥) — %d 💰/sprint d'infrastructure." % [
		product_tier, cost, recurring_charge("committee", "product-tier") * product_tier
	])
	return ""


## 🏝️ Séminaire d'équipe : Cynisme -15, appliqué à la prochaine Résolution
## comme tout achat du Comité.
func buy_team_seminar() -> String:
	var item := find_investment_item("team-seminar")
	var cost := resolved_price("committee", "team-seminar")
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal
	add_pending({"cynisme": float(item.get("cynismeDelta", -15))},
		"🏝️ Séminaire d'équipe (%d 💥) : 🎭 Cynisme %d." % [cost, int(item.get("cynismeDelta", -15))])
	queue_people_effect("tous", {"moral": float(get_individual_team_conf().get("seminarMoral", 0))})
	return ""


## 🧹 Sprint de remise à plat : Dette -20, mais 0 Traction le sprint qui suit
## (consommé dans _build_score_snapshot() / apply_pending_and_check()).
func buy_cleanup_sprint() -> String:
	var item := find_investment_item("cleanup-sprint")
	var cost := resolved_price("committee", "cleanup-sprint")
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal
	cleanup_sprint_pending = true
	add_pending({"dette-organisationnelle": float(item.get("detteDelta", -20))},
		"🧹 Sprint de remise à plat acheté (%d 💥) : 🧱 Dette %d, 0 Traction au prochain sprint." % [cost, int(item.get("detteDelta", -20))])
	return ""


## 🤝 Rachat d'un concurrent : on n'achète pas du cash mais des clients — les
## abonnements repris tombent à chaque sprint et subissent le churn comme les
## vôtres. +1 employé aléatoire (avec son salaire), +8 Dette à la Résolution.
func buy_competitor_acquisition() -> String:
	var item := find_investment_item("acquire-competitor")
	var cost := resolved_price("committee", "acquire-competitor")
	if impact_wallet < cost:
		return "impact"
	var recruit := _draw_candidate([])
	impact_wallet -= cost
	var gained := add_clients_from_points(float(item.get("clientsGained", 7)))
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
		"🤝 Rachat d'un concurrent (%d 💥) : +%d clients repris%s, 🧱 Dette +%d." % [
			cost, int(round(gained)),
			" · +1 employé (%s)" % recruit.get("name", "") if not recruit.is_empty() else "",
			int(item.get("detteDelta", 8)),
		])
	return ""


## 🎯 Chasseur de têtes : le prochain tirage de l'étal force des candidats et
## révèle leurs traits cachés (voir get_shop_offer() / _apply_headhunter_boost()).
func buy_headhunter() -> String:
	var item := find_investment_item("headhunter")
	var cost := resolved_price("committee", "headhunter")
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal
	headhunter_pending = true
	headhunter_target_candidates = int(item.get("nextShopCandidates", 4))
	pending_journal_lines.append("🎯 Chasseur de têtes engagé (%d 💥) : le prochain étal forcera %d candidats, traits révélés." % [
		cost, headhunter_target_candidates
	])
	return ""


## 🏛️ Plan de redressement : un rattrapage de quota, consommé automatiquement
## par _record_quarter_resolution() la première fois qu'un trimestre
## manquerait son quota. Rachetable pour empiler les rattrapages.
func buy_turnaround_plan() -> String:
	var cost := resolved_price("committee", "turnaround-plan")
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal
	turnaround_plans_available += 1
	pending_journal_lines.append("🏛️ Plan de redressement acheté (%d 💥) — %d rattrapage(s) de quota en réserve." % [
		cost, turnaround_plans_available
	])
	return ""


## 🎲 Avance sur trimestre : le seul poste qui va dans l'autre sens — il vend
## de l'Impact contre du Revenue immédiat. Le portefeuille **peut passer sous
## zéro** : un solde négatif est une information de jeu (le pari coûte cher),
## jamais un état silencieusement corrigé — et il faudra l'avoir reconstitué à
## l'heure du verdict, pas en chemin (spec §3.5). Répétable, et chaque avance
## creuse davantage.
func buy_quarter_advance() -> String:
	var item := find_investment_item("quarter-advance")
	var gain := int(item.get("revenueGain", 26))
	var penalty := int(item.get("impactPenalty", 95))
	revenue += float(gain)
	impact_wallet -= penalty
	pending_journal_lines.append("🎲 Avance sur trimestre : +%d 💰 de Revenue contre −%d 💥 (portefeuille désormais %d)." % [
		gain, penalty, impact_wallet
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


# --- 👥 La population qui paie (docs/spec-clients-revenue.md) ---
## Toutes les grandeurs client passent par ces fonctions, jamais par une
## lecture brute de balance.json depuis un écran (CLAUDE.md) : le prix d'un
## segment est indexé par le scénario **et** par les décisions stratégiques,
## et un écran qui lirait `segments[].price` court-circuiterait les deux.

func get_segments() -> Array:
	return get_business_model().get("segments", [])


func find_segment(segment_id: String) -> Dictionary:
	for segment in get_segments():
		if segment.get("id", "") == segment_id:
			return segment
	return {}


## L'échelle de prix du scénario (eras.json → priceScale) : le logiciel des
## années garage ne se vend pas au prix d'un SaaS de l'ère IA.
func get_price_scale() -> float:
	return float(get_era().get("priceScale", 1.0))


## 💳 Le prix effectif d'un client de ce segment, ce sprint. Seul point de
## lecture — c'est ici que s'appliquent l'échelle d'époque et le pivot de §4.2.
func resolved_segment_price(segment_id: String) -> float:
	return (float(find_segment(segment_id).get("price", 0.0))
		* get_price_scale()
		* float(segment_price_multipliers.get(segment_id, 1.0)))


func get_client_count(segment_id: String) -> float:
	return float(clients.get(segment_id, 0.0))


func get_client_total() -> float:
	var total := 0.0
	for value in clients.values():
		total += float(value)
	return total


## 💰 Ce que la population paierait au prochain sprint si elle ne bougeait pas.
## Sert à l'affichage — le vrai encaissement passe par le rapport de score.
func get_client_revenue() -> float:
	var total := 0.0
	for segment in get_segments():
		total += get_client_count(segment.get("id", "")) * resolved_segment_price(segment.get("id", ""))
	return total


## 🧾 Ce que la population coûte à chaque sprint en support et en infra. C'est
## ce terme qui rend une base gratuite dangereuse (§5.3) : elle grossit, elle
## ne paie pas, et elle se facture quand même.
func get_client_support_cost() -> float:
	var total := 0.0
	for segment in get_segments():
		total += get_client_count(segment.get("id", "")) * float(segment.get("unitCost", 0.0))
	return total


## La ligne de composition sous le solde — jamais des compteurs (§2.1) :
## « 8 400 gratuits · 240 abonnés × 0,6 ». `compact` prend le libellé court des
## segments : le panneau latéral est étroit, et une composition tronquée ne
## raconte plus rien.
func describe_clients(compact: bool = false) -> String:
	var parts: Array = []
	for segment in get_segments():
		var segment_id: String = segment.get("id", "")
		var count := get_client_count(segment_id)
		if count <= 0.0:
			continue
		var price := resolved_segment_price(segment_id)
		var label: String = segment.get("shortLabel", segment.get("label", segment_id)) if compact else segment.get("label", segment_id)
		var text := "%d %s" % [int(round(count)), label]
		if price > 0.0:
			text += " × %s" % String.num(price, 2).trim_suffix("0").trim_suffix(".")
		parts.append(text)
	return " · ".join(parts) if not parts.is_empty() else "aucun client"


## 👥 Combien de clients une valeur d'effet client vaut, dans CE modèle. Une
## feature à `clients: 3` amène 72 inscrits en freemium et 0,9 compte signé en
## grands comptes — la Roadmap annonce le nombre réel, pas la valeur brute.
func clients_for_points(points: float) -> float:
	var total := 0.0
	for segment in get_segments():
		total += points * segment_yield_per_point(segment)
	return total


## Ce qu'un point d'effet client rapporte à CE segment aujourd'hui — zéro si le
## segment a été fermé par une décision (§4.2). Lu par l'affichage comme par le
## moteur : une Roadmap qui annoncerait encore « +72 gratuits » après la fin du
## gratuit mentirait au joueur.
func segment_yield_per_point(segment: Dictionary) -> float:
	return (float(segment.get("clientsPerPoint", 0.0))
		* float(segment_arrival_multipliers.get(segment.get("id", ""), 1.0)))


## Détail par segment du même calcul (révélé par la pratique UX research).
func clients_for_points_by_segment(points: float) -> Array:
	var rows: Array = []
	for segment in get_segments():
		rows.append({
			"id": segment.get("id", ""),
			"icon": segment.get("icon", "👥"),
			"label": segment.get("label", ""),
			"value": points * segment_yield_per_point(segment),
		})
	return rows


## Fait basculer une fraction d'un rôle de segment vers un autre. Utilisé par
## les événements et les décisions — jamais par le moteur de sprint, qui ne
## connaît que les arrivées et les départs.
func convert_clients(from_role: String, to_role: String, ratio: float) -> float:
	var moved := 0.0
	for segment in get_segments():
		if str(segment.get("role", "")) != from_role:
			continue
		var taken: float = max(0.0, get_client_count(segment.get("id", "")) * ratio)
		if is_zero_approx(taken):
			continue
		clients[segment.get("id", "")] = get_client_count(segment.get("id", "")) - taken
		moved += taken
	if moved <= 0.0:
		return 0.0
	for segment in get_segments():
		if str(segment.get("role", "")) == to_role:
			clients[segment.get("id", "")] = get_client_count(segment.get("id", "")) + moved
			return moved
	return moved


## Ajoute (ou retire) des clients à partir d'un effet en points — le vocabulaire
## partagé par les features, les événements et les postes du Comité.
func add_clients_from_points(points: float) -> float:
	var gained := 0.0
	for segment in get_segments():
		var segment_id: String = segment.get("id", "")
		var delta := points * segment_yield_per_point(segment)
		clients[segment_id] = max(0.0, get_client_count(segment_id) + delta)
		gained += delta
	return gained


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


## Roster où faire atterrir une recrue (spec §13.2). `squad_id` explicite en
## priorité ; à N=1 il n'y a de toute façon qu'un roster possible. Au-delà,
## sans squad précisée, l'équipe la moins fournie — jamais un tirage, pour
## rester déterministe et lisible.
func _target_roster(squad_id: String) -> Array:
	if squad_id != "":
		for squad in squads:
			if squad.get("id", "") == squad_id:
				return squad.get("roster", [])
	if squads.size() <= 1:
		return _get_primary_roster()
	var smallest: Dictionary = squads[0]
	for squad in squads:
		if squad.get("roster", []).size() < smallest.get("roster", []).size():
			smallest = squad
	return smallest.get("roster", [])

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


# --- Équipe individuelle (spec-equipe-individuelle.md) ---

## Le Moral n'est plus une valeur possédée par l'entreprise. Chaque employé
## porte ses quatre critères ; `resource_values.moral` est seulement le miroir
## calculé maintenu pour les systèmes historiques de score et de fin de mandat.
func get_individual_team_conf() -> Dictionary:
	return GameData.balance.get("individualTeam", {})


func get_personality(personality_id: String) -> Dictionary:
	for personality in GameData.recruitment_archetypes.get("archetypes", []):
		if String(personality.get("id", "")) == personality_id:
			return personality
	return {}


func _employee_from_source(source: Dictionary, hired_sprint: int, trait_revealed: bool = false) -> Dictionary:
	var seniority: String = String(source.get("seniority", "junior"))
	var defaults: Dictionary = get_individual_team_conf().get("defaultPersonalityBySeniority", {})
	var personality_id: String = String(source.get("personality", defaults.get(seniority, "junior-ambitieux")))
	var personality := get_personality(personality_id)
	var wellbeing: Dictionary = personality.get("depart", {}).duplicate(true)
	for criterion in get_individual_team_conf().get("criteria", []):
		var key := String(criterion)
		wellbeing[key] = clampi(int(wellbeing.get(key, 60)), 0, 100)
	return {
		"id": source.get("id", ""),
		"name": source.get("name", ""),
		"role": source.get("role", ""),
		"seniority": seniority,
		"salary": int(source.get("salary", GameData.balance.get("salaries", {}).get(seniority, 1))),
		"trait": source.get("trait", ""),
		"visible_trait_id": source.get("visible_trait_id", ""),
		"hidden_trait": source.get("hidden_trait", ""),
		"hiddenRevealed": source.get("hiddenRevealed", trait_revealed),
		"hiredSprint": hired_sprint,
		"personality": personality_id,
		"personalityRevealed": bool(source.get("personalityRevealed", false)),
		"wellbeing": wellbeing,
		"contributionBlocked": false,
		"timeOffSprint": -1,
		"managementActions": {},
		"pendingConcerns": [],
		"pendingCrises": [],
	}


func employee_wellbeing(employee: Dictionary) -> Dictionary:
	if not employee.has("wellbeing"):
		var fallback := _employee_from_source(employee, int(employee.get("hiredSprint", 0)), bool(employee.get("hiddenRevealed", false)))
		employee["personality"] = fallback.get("personality", "")
		employee["wellbeing"] = fallback.get("wellbeing", {})
	return employee.get("wellbeing", {})


func get_team_moral() -> float:
	var weighted_total := 0.0
	var weights := 0.0
	for employee in get_roster():
		var weight := employee_contribution_factor(employee)
		if weight <= 0.0:
			continue
		weighted_total += float(employee_wellbeing(employee).get("moral", 0)) * weight
		weights += weight
	if weights > 0.0:
		return weighted_total / weights
	# Même une équipe en rupture doit rester lisible : le minimum s'affiche
	# par les alertes, la moyenne simple conserve une valeur pour les fins.
	var roster := get_roster()
	if roster.is_empty():
		return 0.0
	var total := 0.0
	for employee in roster:
		total += float(employee_wellbeing(employee).get("moral", 0))
	return total / roster.size()


func _refresh_team_moral() -> void:
	if resource_values.has("moral"):
		resource_values["moral"] = get_team_moral()


## 👥 Le Moral n'est pas une jauge stockée : c'est une vue sur le roster, et
## `resource_values.moral` n'en est que le miroir. Des facteurs le déplacent
## sans le moindre effet de bien-être — un repos qui expire au sprint suivant,
## un licenciement, une démission silencieuse — et le miroir mentirait alors
## pendant tout le sprint. Les consommateurs passent donc par cette fonction
## de résolution, jamais par la valeur brute (CLAUDE.md : aucune valeur
## dérivée ne se lit brute).
func get_resource_value(resource_id: String) -> float:
	if resource_id == "moral":
		_refresh_team_moral()
		return get_team_moral()
	return float(resource_values.get(resource_id, 0.0))


## Copie des jauges pour un affichage, une comparaison avant/après ou un
## snapshot : les valeurs dérivées y sont resynchronisées d'abord.
func get_resource_snapshot() -> Dictionary:
	_refresh_team_moral()
	return resource_values.duplicate()


## Passage au sprint suivant. La règle vit ici et pas dans l'écran de
## Résolution : changer de sprint périme des facteurs individuels (un repos ne
## vaut que pour le sprint où il est accordé), et le miroir du Moral doit
## suivre dans la foulée.
func advance_to_next_sprint() -> void:
	sprint_number += 1
	_sprint_event = {}
	_sprint_event_sprint = -1
	_sprint_event_answered = false
	_sprint_event_resolution = {}
	_refresh_team_moral()


## L'état synthétique est la seule chose visible par défaut dans le roster.
## Les quatre chiffres restent dans le tooltip/détail au clic, jamais en grille.
func get_employee_alert(employee: Dictionary) -> Dictionary:
	var wellbeing := employee_wellbeing(employee)
	var alert_at := int(get_individual_team_conf().get("alertAt", 25))
	var lowest_key := ""
	var lowest_value := 101
	for criterion in get_individual_team_conf().get("criteria", []):
		var key := String(criterion)
		var value := int(wellbeing.get(key, 100))
		if value < lowest_value:
			lowest_key = key
			lowest_value = value
	if lowest_value > alert_at:
		return {"active": false, "criterion": lowest_key, "value": lowest_value, "label": ""}
	var labels := {
		"moral": "décroche",
		"confiance": "cherche ailleurs",
		"energie": "en surchauffe",
		"salaire": "regarde le marché",
	}
	return {"active": true, "criterion": lowest_key, "value": lowest_value, "label": labels.get(lowest_key, "fragile")}


func _select_people(target: String) -> Array:
	var roster := get_roster()
	if target == "vous":
		return []
	if target == "un-au-hasard":
		return [roster[randi() % roster.size()]] if not roster.is_empty() else []
	if target.begins_with("role:"):
		var role := target.trim_prefix("role:")
		return roster.filter(func(employee): return String(employee.get("role", "")) == role)
	if target.begins_with("seniorite:"):
		var seniority := target.trim_prefix("seniorite:")
		return roster.filter(func(employee): return String(employee.get("seniority", "")) == seniority)
	if target == "le-plus-ancien":
		if roster.is_empty():
			return []
		var oldest: Dictionary = roster[0]
		for employee in roster:
			if int(employee.get("hiredSprint", 0)) < int(oldest.get("hiredSprint", 0)):
				oldest = employee
		return [oldest]
	if target == "le-mieux-paye":
		if roster.is_empty():
			return []
		var highest_paid: Dictionary = roster[0]
		for employee in roster:
			if int(employee.get("salary", 0)) > int(highest_paid.get("salary", 0)):
				highest_paid = employee
		return [highest_paid]
	if target.begins_with("squad:"):
		# Ciblage interne, jamais affiché : ce qu'une équipe produit ne se
		# ressent que chez elle (contrat d'architecture §2). À N=1 il désigne
		# exactement le roster complet, donc rien ne change à l'écran.
		var squad_id := target.trim_prefix("squad:")
		for squad in squads:
			if String(squad.get("id", "")) == squad_id:
				return squad.get("roster", []).duplicate()
		return []
	if target == "le-plus-fragile":
		if roster.is_empty():
			return []
		var most_fragile: Dictionary = roster[0]
		for employee in roster:
			if int(get_employee_alert(employee).get("value", 100)) < int(get_employee_alert(most_fragile).get("value", 100)):
				most_fragile = employee
		return [most_fragile]
	return roster


func _people_target_or_default(target: String) -> String:
	if target != "":
		return target
	return String(get_individual_team_conf().get("defaultPeopleTarget", "tous"))


func queue_people_effect(target: String, deltas: Dictionary, note: String = "") -> void:
	if deltas.is_empty():
		return
	pending_people_effects.append({"target": target, "deltas": deltas.duplicate(), "note": note})


func apply_people_effect(target: String, deltas: Dictionary) -> void:
	var criteria: Array = get_individual_team_conf().get("criteria", [])
	if target == "vous":
		for criterion in deltas:
			var self_key := String(criterion)
			if not criteria.has(self_key):
				continue
			cpo_wellbeing[self_key] = clampi(int(round(float(cpo_wellbeing.get(self_key, 0)) + float(deltas[criterion]))), 0, 100)
		if deltas.has("energie"):
			energy = int(cpo_wellbeing.get("energie", energy))
		return
	for employee in _select_people(target):
		var wellbeing := employee_wellbeing(employee)
		var personality := get_personality(String(employee.get("personality", "")))
		var influence: Dictionary = personality.get("influence", {})
		for criterion in deltas:
			var key := String(criterion)
			if not criteria.has(key):
				continue
			var moved := float(deltas[key]) * float(influence.get(key, 1.0))
			wellbeing[key] = clampi(int(round(float(wellbeing.get(key, 0)) + moved)), 0, 100)
	_refresh_team_moral()


func apply_people_effect_for_employee(employee: Dictionary, deltas: Dictionary) -> void:
	var criteria: Array = get_individual_team_conf().get("criteria", [])
	var wellbeing := employee_wellbeing(employee)
	var personality := get_personality(String(employee.get("personality", "")))
	var influence: Dictionary = personality.get("influence", {})
	for criterion in deltas:
		var key := String(criterion)
		if not criteria.has(key):
			continue
		var moved := float(deltas[key]) * float(influence.get(key, 1.0))
		wellbeing[key] = clampi(int(round(float(wellbeing.get(key, 0)) + moved)), 0, 100)
	_refresh_team_moral()


func employee_management_refusal(employee: Dictionary, action: String) -> String:
	if employee.is_empty() or find_employee(String(employee.get("id", ""))).is_empty():
		return "introuvable"
	if bool(get_individual_team_conf().get("managementActions", {}).get("oncePerSprint", true)):
		if int(employee.get("managementActions", {}).get(action, -1)) == sprint_number:
			return "deja-ce-sprint"
	if action == "ownership":
		var ownership_cost := int(get_individual_team_conf().get("managementActions", {}).get("ownership", {}).get("cpoEnergyCost", 0))
		if energy < ownership_cost:
			return "epuise"
	return ""


func _record_management_action(employee: Dictionary, action: String) -> void:
	var actions: Dictionary = employee.get("managementActions", {}).duplicate()
	actions[action] = sprint_number
	employee["managementActions"] = actions


func grant_time_off(employee_id: String) -> String:
	var employee := find_employee(employee_id)
	var refusal := employee_management_refusal(employee, "time-off")
	if refusal != "":
		return refusal
	_apply_time_off(employee)
	_record_management_action(employee, "time-off")
	pending_journal_lines.append("⚡ %s prend le sprint pour récupérer — sa contribution est indisponible ce sprint." % employee.get("name", employee_id))
	return ""


func _apply_time_off(employee: Dictionary) -> void:
	employee["timeOffSprint"] = sprint_number
	apply_people_effect_for_employee(employee, get_individual_team_conf().get("managementActions", {}).get("timeOff", {}))


func grant_salary_raise(employee_id: String) -> String:
	var employee := find_employee(employee_id)
	var refusal := employee_management_refusal(employee, "salary-raise")
	if refusal != "":
		return refusal
	_apply_salary_raise(employee)
	_record_management_action(employee, "salary-raise")
	pending_journal_lines.append("💸 Augmentation : %s gagne désormais %d 💰/sprint." % [employee.get("name", employee_id), int(employee.get("salary", 0))])
	return ""


func _apply_salary_raise(employee: Dictionary) -> void:
	var conf: Dictionary = get_individual_team_conf().get("managementActions", {}).get("salaryRaise", {})
	employee["salary"] = int(employee.get("salary", 0)) + int(conf.get("salaryStep", 1))
	apply_people_effect_for_employee(employee, {
		"salaire": float(conf.get("salaire", 0)),
		"confiance": float(conf.get("confiance", 0)),
	})


func grant_ownership(employee_id: String) -> String:
	var employee := find_employee(employee_id)
	var refusal := employee_management_refusal(employee, "ownership")
	if refusal != "":
		return refusal
	_apply_ownership(employee)
	_record_management_action(employee, "ownership")
	pending_journal_lines.append("🧭 %s reçoit un périmètre clair et la responsabilité qui va avec." % employee.get("name", employee_id))
	return ""


func _apply_ownership(employee: Dictionary) -> void:
	var conf: Dictionary = get_individual_team_conf().get("managementActions", {}).get("ownership", {})
	apply_people_effect_for_employee(employee, conf)
	apply_people_effect("vous", {"energie": -float(conf.get("cpoEnergyCost", 0))})


func _apply_pending_people_effects() -> void:
	for effect in pending_people_effects:
		apply_people_effect(String(effect.get("target", "tous")), effect.get("deltas", {}))
	pending_people_effects.clear()


func _sync_cpo_energy() -> void:
	cpo_wellbeing["energie"] = energy


## Le seuil de départ ne retire jamais quelqu'un dans le dos du joueur. Il
## prépare une scène Inbox prioritaire ; seule la Confiance à zéro coupe la
## contribution tout de suite, parce que la rupture est déjà visible au travail.
func _inspect_team_crises() -> void:
	var leave_at := int(get_individual_team_conf().get("leaveAt", 0))
	var alert_at := int(get_individual_team_conf().get("alertAt", 25))
	for employee in get_roster():
		var wellbeing := employee_wellbeing(employee)
		var employee_crises: Array = employee.get("pendingCrises", []).duplicate()
		var employee_concerns: Array = employee.get("pendingConcerns", []).duplicate()
		for criterion in get_individual_team_conf().get("criteria", []):
			var key := String(criterion)
			var value := int(wellbeing.get(key, 100))
			if key == "confiance" and value <= leave_at:
				employee["contributionBlocked"] = true
			if value <= leave_at:
				if not employee_crises.has(key):
					employee_crises.append(key)
					pending_team_crises.append({"employee_id": employee.get("id", ""), "criterion": key})
				continue
			if value <= alert_at and not employee_concerns.has(key):
				employee_concerns.append(key)
				pending_team_concerns.append({"employee_id": employee.get("id", ""), "criterion": key})
		employee["pendingCrises"] = employee_crises
		employee["pendingConcerns"] = employee_concerns


func _team_crisis_event(crisis: Dictionary) -> Dictionary:
	var employee := find_employee(String(crisis.get("employee_id", "")))
	if employee.is_empty():
		return {}
	var criterion := String(crisis.get("criterion", "moral"))
	if int(employee_wellbeing(employee).get(criterion, 100)) > int(get_individual_team_conf().get("leaveAt", 0)):
		_remove_employee_pending(employee, "pendingCrises", criterion)
		return {}
	var conf: Dictionary = get_individual_team_conf().get("crises", {}).get(criterion, {})
	var name := String(employee.get("name", "Cette personne"))
	return {
		"id": "team-crisis-%s-%s" % [employee.get("id", ""), criterion],
		"from": "Équipe produit",
		"channel": "#equipe-produit",
		"status": "urgent",
		"subject": "%s %s" % [name, conf.get("subject", "a besoin de vous")],
		"text": "%s est à zéro en %s. Ce n'est plus une alerte : vous devez choisir ce qui se passe maintenant." % [
			name, {"moral": "Moral", "confiance": "Confiance", "energie": "Énergie", "salaire": "satisfaction salariale"}.get(criterion, criterion)
		],
		"choices": [
			{
				"id": "restaurer-%s" % criterion,
				"label": conf.get("restoreLabel", "Réparer la situation"),
				"reveal": "%s reste. Le sujet ne disparaît pas, mais vous lui rendez une marge de manœuvre." % name,
				"personEffect": {"employee_id": employee.get("id", ""), "deltas": conf.get("restore", {})},
				"teamCrisis": {
					"employee_id": employee.get("id", ""),
					"criterion": criterion,
					"action": "restore",
					"restoreActions": conf.get("restoreActions", []),
				},
			},
			{
				"id": "laisser-partir-%s" % criterion,
				"label": conf.get("leaveLabel", "Le laisser partir"),
				"reveal": "%s quitte l'équipe. Les autres voient très bien pourquoi." % name,
				"teamCrisis": {"employee_id": employee.get("id", ""), "criterion": criterion, "action": "leave", "teamAfterLeave": conf.get("teamAfterLeave", {})},
			},
		],
	}


func _resolve_team_crisis(choice: Dictionary) -> void:
	var crisis: Dictionary = choice.get("teamCrisis", {})
	if crisis.is_empty():
		return
	var employee := find_employee(String(crisis.get("employee_id", "")))
	if employee.is_empty():
		return
	var action := String(crisis.get("action", ""))
	if action == "restore":
		# Le libellé d'une réparation promet un acte de management, pas
		# seulement une remontée de jauge : il se paie donc là où le joueur
		# le sent (capacité du sprint, masse salariale, Énergie du CPO).
		_apply_management_actions(employee, crisis.get("restoreActions", []))
		_remove_employee_pending(employee, "pendingCrises", String(crisis.get("criterion", "")))
		if String(crisis.get("criterion", "")) == "confiance":
			employee["contributionBlocked"] = false
		return
	if action != "leave":
		return
	var owner := _find_employee_owner(String(employee.get("id", "")))
	var owner_roster: Array = owner.get("squad", {}).get("roster", [])
	owner_roster.erase(employee)
	queue_people_effect("tous", crisis.get("teamAfterLeave", {}))
	pending_journal_lines.append("🚪 %s quitte l'équipe. Personne ne fait semblant de ne pas comprendre." % employee.get("name", "Une personne"))
	_refresh_team_moral()


## Exécute les actes de management déclarés par un contenu (une demande, une
## réparation de crise). Un seul chemin d'exécution pour les trois actions :
## l'Inbox ne peut pas promettre un repos ou une augmentation que le hub
## facturerait autrement.
func _apply_management_actions(employee: Dictionary, actions: Array) -> void:
	for raw_action in actions:
		var action := String(raw_action)
		match action:
			"time-off":
				_apply_time_off(employee)
			"salary-raise":
				_apply_salary_raise(employee)
			"ownership":
				_apply_ownership(employee)
			_:
				continue
		_record_management_action(employee, action)


func _remove_employee_pending(employee: Dictionary, field: String, criterion: String) -> void:
	var entries: Array = employee.get(field, []).duplicate()
	entries.erase(criterion)
	employee[field] = entries


func _team_concern_event(concern: Dictionary) -> Dictionary:
	var employee := find_employee(String(concern.get("employee_id", "")))
	if employee.is_empty():
		return {}
	var criterion := String(concern.get("criterion", "moral"))
	var value := int(employee_wellbeing(employee).get(criterion, 100))
	var alert_at := int(get_individual_team_conf().get("alertAt", 25))
	var leave_at := int(get_individual_team_conf().get("leaveAt", 0))
	if value > alert_at or value <= leave_at:
		_remove_employee_pending(employee, "pendingConcerns", criterion)
		return {}
	var conf: Dictionary = get_individual_team_conf().get("concerns", {}).get(criterion, {})
	var choices: Array = []
	for template in conf.get("choices", []):
		choices.append({
			"id": "team-concern-%s-%s-%s" % [employee.get("id", ""), criterion, template.get("id", "choix")],
			"label": template.get("label", "Répondre"),
			"reveal": template.get("reveal", "La demande reçoit une réponse."),
			"teamConcern": {
				"employee_id": employee.get("id", ""),
				"criterion": criterion,
				"action": template.get("action", ""),
				"employeeDeltas": template.get("employeeDeltas", {}),
				"cpoDeltas": template.get("cpoDeltas", {}),
			},
		})
	return {
		"id": "team-concern-%s-%s" % [employee.get("id", ""), criterion],
		"from": employee.get("name", "Équipe produit"),
		"channel": "#equipe-produit",
		"status": "urgent",
		"subject": "%s %s" % [employee.get("name", "Cette personne"), conf.get("subject", "demande à vous parler")],
		"text": "%s\n\n%s est à %d/100 en %s : c'est encore une alerte, pas une rupture." % [
			conf.get("body", "Le sujet ne peut plus attendre."), employee.get("name", "Cette personne"), value,
			{"moral": "Moral", "confiance": "Confiance", "energie": "Énergie", "salaire": "satisfaction salariale"}.get(criterion, criterion),
		],
		"choices": choices,
	}


func _resolve_team_concern(choice: Dictionary) -> void:
	var concern: Dictionary = choice.get("teamConcern", {})
	if concern.is_empty():
		return
	var employee := find_employee(String(concern.get("employee_id", "")))
	if employee.is_empty():
		return
	_apply_management_actions(employee, [concern.get("action", "")])
	apply_people_effect_for_employee(employee, concern.get("employeeDeltas", {}))
	apply_people_effect("vous", concern.get("cpoDeltas", {}))
	_remove_employee_pending(employee, "pendingConcerns", String(concern.get("criterion", "")))
	pending_journal_lines.append("👥 Demande de %s traitée : %s." % [employee.get("name", "une personne"), choice.get("label", "réponse")])


func has_pending_team_events() -> bool:
	return not pending_team_crises.is_empty() or not pending_team_concerns.is_empty()


func pending_team_event_count() -> int:
	return pending_team_crises.size() + pending_team_concerns.size()


## Facteur de contribution d'un employé : 1.0 par défaut, réduit par un
## trait caché révélé de type Fantôme (contributionFactor).
func employee_contribution_factor(employee: Dictionary) -> float:
	if bool(employee.get("contributionBlocked", false)):
		return 0.0
	if int(employee.get("timeOffSprint", -1)) == sprint_number:
		return 0.0
	if not employee.get("hiddenRevealed", false):
		return 1.0
	var hidden_trait: Dictionary = get_hidden_trait(employee.get("hidden_trait", ""))
	return float(hidden_trait.get("effects", {}).get("contributionFactor", 1.0))


## Poids effectif d'un rôle dans le roster (nombre d'employés pondéré par
## leur facteur de contribution) — sert aux pénalités d'absence et aux caps.
func get_role_weight(role_id: String) -> float:
	return _role_weight_in(get_roster(), role_id)


func _role_weight_in(roster: Array, role_id: String) -> float:
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
	return get_roster_context_for(get_roster())


## Même contexte, mais scopé à un roster précis (spec §13.2) : le backlog
## d'une équipe additionnelle n'est modulé que par sa propre composition,
## pas par celle du reste de l'organisation.
func get_roster_context_for(roster: Array) -> Dictionary:
	return {
		"pm_weight": _role_weight_in(roster, "pm"),
		"designer_weight": _role_weight_in(roster, "designer"),
		# 📣 Le Product marketing n'amplifie plus l'Impact : il amplifie ce que
		# les livraisons font à la réputation du produit (spec-clients-revenue.md
		# §5.1.1). Même table qu'avant, autre entrée.
		"reputation_multiplier": support_team_multiplier("pmm"),
	}


## Le taux d'une équipe subie, lu une seule fois dans scoring.json → conversion
## .teams. ScoreResolver lit la même table pour le Sales et le CSM : deux
## usages, un seul chiffre.
func support_team_multiplier(team_id: String) -> float:
	var team: Dictionary = GameData.scoring.get("conversion", {}).get("teams", {}).get(team_id, {})
	var table: Dictionary = team.get("multipliers", {})
	var level := int(support_teams.get(team_id, 3))
	return float(table.get(str(level), 1.0))


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
	var moral := get_team_moral()
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
	_sync_cpo_energy()
	energy_spent_this_sprint += spent


## 🤝 1:1 (§7.2) — révèle le trait caché d'un candidat du Marché (avant
## embauche) ou d'un employé du roster. Sur un employé, les traits à
## déclencheur (Négociateur, Réseau) tombent immédiatement : la
## conversation met le sujet sur la table. Retourne "" si l'action a eu lieu.
func do_one_on_one(person: Dictionary) -> String:
	var refusal := personal_action_refusal()
	if refusal != "":
		return refusal
	var is_employee := person.has("hiredSprint")
	var was_revealed := bool(person.get("hiddenRevealed", false))
	if not is_employee and person.get("hiddenRevealed", false):
		return "deja-revele"
	if is_employee:
		var management_refusal := employee_management_refusal(person, "one-on-one")
		if management_refusal != "":
			return management_refusal

	var cost := get_personal_action_cost("oneOnOne")
	_spend_energy(cost)
	person["hiddenRevealed"] = true
	person["personalityRevealed"] = true

	var hidden_trait := get_hidden_trait(person.get("hidden_trait", ""))
	var verdict := ""
	if hidden_trait.is_empty():
		verdict = "rien à signaler. Vraiment."
	else:
		verdict = "%s %s — %s" % [
			hidden_trait.get("icon", ""), hidden_trait.get("name", ""), hidden_trait.get("description", "")
		]
	var personality := get_personality(String(person.get("personality", get_individual_team_conf().get("defaultPersonalityBySeniority", {}).get(person.get("seniority", "junior"), ""))))
	if not personality.is_empty():
		verdict += " · %s" % personality.get("name", "")
	var extra := ""
	if is_employee:  # employé du roster (un candidat n'a pas encore de sprint d'embauche)
		apply_people_effect_for_employee(person, {"confiance": float(get_individual_team_conf().get("oneOnOneConfiance", 0))})
		_record_management_action(person, "one-on-one")
		if not was_revealed:
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


## 🏛️ Négocier une rallonge (§7.2) — votre Capital politique contre du
## Revenue pour l'entreprise. C'est le seul geste qui remplit la caisse sans
## produire : il ne donne jamais d'Impact, seulement de quoi tenir un sprint de
## plus. Le cash tombe immédiatement ; le Capital politique se règle à la
## Résolution, comme tous les effets de ressources.
func do_negotiate_extension() -> String:
	var refusal := personal_action_refusal()
	if refusal != "":
		return refusal
	var conf := get_personal_action_conf("extension")
	var gained := int(conf.get("revenue", 14))
	var capital := int(conf.get("capitalPolitique", -8))
	_spend_energy(int(conf.get("cost", 10)))
	revenue += float(gained)
	add_pending({"capital-politique": float(capital)},
		"🏛️ Rallonge négociée au board (−%d ⚡) : +%d 💰 de Revenue immédiats, 🎯 Capital politique %d — tout le monde a noté que vous êtes venu·e quémander" % [
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
	# 👥 L'effet client des livraisons n'est PAS appliqué ici : il est lu par
	# ScoreResolver dans `squads[].delivered` à la Résolution, au même endroit
	# et au même moment que la Traction. Le report ne fait que l'annoncer.
	var client_points := 0
	for item in delivered:
		client_points += int(item.get("clients", 0))

	if not deltas.is_empty():
		# Ce qu'une équipe livre se ressent d'abord chez elle : la livraison
		# porte donc l'équipe qui l'a produite, pas le roster entier.
		add_pending(deltas, "", "squad:%s" % squads[0].get("id", ""))
	last_roadmap_report = {
		"sprint": sprint_number,
		"plannedPoints": spent,
		"capacity": capacity,
		"delivered": delivered,
		"epicUpdates": epic_updates,
		"clientPoints": client_points,
		"clientsGained": clients_for_points(float(client_points)),
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


# --- Backlog des équipes additionnelles (Lot 5, palier 2, spec §13.2) ---
# L'équipe historique garde intact le chemin ci-dessus (current_backlog_draw,
# epic_progress, completed_backlog_ids, _backlog_bag) : zéro risque de
# régression sur un run PM, qui ne passe jamais par ces fonctions (le seul
# appelant, roadmap_screen, redirige l'équipe principale vers get_backlog_offer()
# / commit_backlog_plan() ci-dessus). Les équipes ajoutées par la carrière
# portent leur propre sac (squad["bag"]), leur propre progression d'epics
# (squad["epic_progress"]) et leur propre liste de tickets déjà livrés
# (squad["completed_ids"]) — jamais de transfert de points entre équipes.

func _find_squad(squad_id: String) -> Dictionary:
	for squad in squads:
		if squad.get("id", "") == squad_id:
			return squad
	return {}


## Capacité de roadmap d'une équipe précise — s'assure d'abord que
## get_effective_capacity() a tourné (elle écrit squad["capacity"] pour
## toutes les équipes au passage), puis relit la valeur de celle-ci.
func get_squad_capacity(squad_id: String) -> int:
	get_effective_capacity()
	return int(_find_squad(squad_id).get("capacity", 0))


func get_backlog_offer_for_squad(squad_id: String) -> Dictionary:
	if squad_id == get_primary_squad().get("id", ""):
		return get_backlog_offer()
	var squad := _find_squad(squad_id)
	if squad.is_empty():
		return {"sprint": sprint_number, "items": []}
	var draw: Dictionary = squad.get("backlog_draw", {})
	if int(draw.get("sprint", -1)) == sprint_number:
		return draw
	draw = _draw_squad_backlog_offer(squad)
	squad["backlog_draw"] = draw
	return draw


func _draw_squad_backlog_offer(squad: Dictionary) -> Dictionary:
	var conf: Dictionary = GameData.balance.get("backlogDraw", {})
	var minimum := int(conf.get("itemsPerSprintMin", 0))
	var maximum: int = max(minimum, int(conf.get("itemsPerSprintMax", minimum))) + product_tier
	var items: Array = _active_squad_epic_items(squad)
	var target_total: int = randi_range(minimum, maximum)
	var regular_count: int = max(0, target_total - items.size())
	var bag: Array = squad.get("bag", [])
	var completed_ids: Array = squad.get("completed_ids", [])
	while regular_count > 0 and items.size() < maximum:
		var item := _draw_squad_backlog_item(items, bag, completed_ids)
		if item.is_empty():
			break
		items.append(item)
		regular_count -= 1
	squad["bag"] = bag
	return {"sprint": sprint_number, "items": items}


func _active_squad_epic_items(squad: Dictionary) -> Array:
	var result: Array = []
	var epic_progress_table: Dictionary = squad.get("epic_progress", {})
	for item_id in epic_progress_table.keys():
		var item := find_backlog_item(item_id)
		if not item.is_empty() and _squad_epic_remaining(squad, item_id) > 0:
			result.append(item)
	return result


func _squad_epic_remaining(squad: Dictionary, item_id: String) -> int:
	var item := find_backlog_item(item_id)
	var epic_progress_table: Dictionary = squad.get("epic_progress", {})
	var invested := int(epic_progress_table.get(item_id, {}).get("invested", 0))
	return max(0, int(item.get("costPoints", 0)) - invested)


func _draw_squad_backlog_item(already_drawn: Array, bag: Array, completed_ids: Array) -> Dictionary:
	var excluded: Dictionary = {}
	for item in already_drawn:
		excluded[item.get("id", "")] = true
	var attempts := 0
	var max_attempts: int = max(1, GameData.backlog.get("features", []).size() + GameData.backlog.get("epics", []).size()) * 2
	while attempts < max_attempts:
		if bag.is_empty():
			_refill_squad_backlog_bag(bag, completed_ids)
		if bag.is_empty():
			return {}
		var item_id: String = bag.pop_back()
		var item := find_backlog_item(item_id)
		attempts += 1
		if item.is_empty() or excluded.has(item_id) or completed_ids.has(item_id):
			continue
		return item
	return {}


func _refill_squad_backlog_bag(bag: Array, completed_ids: Array) -> void:
	for feature in GameData.backlog.get("features", []):
		if _available_for_era(feature) and not completed_ids.has(feature.get("id", "")):
			bag.append(feature.get("id", ""))
	for epic in GameData.backlog.get("epics", []):
		if _available_for_era(epic) and not completed_ids.has(epic.get("id", "")):
			bag.append(epic.get("id", ""))
	bag.shuffle()


## Symétrique de commit_backlog_plan() pour une équipe additionnelle — même
## algorithme (consommer les points, faire avancer les epics, ne révéler les
## attributs réels qu'à la livraison), mais lu et écrit uniquement sur l'état
## propre à cette équipe. Les effets de bord globaux (deltas de ressources,
## ROI récurrent) restent appliqués tels quels : la spec ne les scope pas par
## équipe, seuls le backlog et la capacité le sont (§13.2).
func commit_backlog_plan_for_squad(squad_id: String, plan: Array) -> Dictionary:
	if squad_id == get_primary_squad().get("id", ""):
		return commit_backlog_plan(plan)
	var squad := _find_squad(squad_id)
	if squad.is_empty():
		return {}
	var offer := get_backlog_offer_for_squad(squad_id)
	var available: Dictionary = {}
	for item in offer.get("items", []):
		available[item.get("id", "")] = item

	var epic_progress_table: Dictionary = squad.get("epic_progress", {})
	var completed_ids: Array = squad.get("completed_ids", [])
	var spent := 0
	var delivered: Array = []
	var epic_updates: Array = []
	var seen: Dictionary = {}
	for entry in plan:
		var item_id: String = entry.get("id", "")
		if seen.has(item_id) or completed_ids.has(item_id) or not available.has(item_id):
			continue
		seen[item_id] = true
		var item: Dictionary = available[item_id]
		if is_backlog_epic(item):
			var invested: int = min(max(0, int(entry.get("points", 0))), _squad_epic_remaining(squad, item_id))
			if invested <= 0:
				continue
			var progress: Dictionary = epic_progress_table.get(item_id, {"invested": 0, "startedSprint": sprint_number})
			progress["invested"] = int(progress.get("invested", 0)) + invested
			epic_progress_table[item_id] = progress
			spent += invested
			if int(progress["invested"]) >= int(item.get("costPoints", 0)):
				epic_progress_table.erase(item_id)
				completed_ids.append(item_id)
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
			completed_ids.append(item_id)

	squad["epic_progress"] = epic_progress_table
	squad["completed_ids"] = completed_ids
	var capacity := get_squad_capacity(squad_id)
	var deltas := EffectResolver.resolve_backlog(delivered, spent, capacity, get_roster_context_for(squad.get("roster", [])), has_practice("okr"))
	var client_points := 0
	for item in delivered:
		client_points += int(item.get("clients", 0))
	if not deltas.is_empty():
		add_pending(deltas, "", "squad:%s" % squad_id)

	var report := {
		"sprint": sprint_number,
		"plannedPoints": spent,
		"capacity": capacity,
		"delivered": delivered,
		"epicUpdates": epic_updates,
		"clientPoints": client_points,
		"clientsGained": clients_for_points(float(client_points)),
		"deltas": deltas,
	}
	squad["delivered"] = delivered
	squad["spent_points"] = spent
	squad["last_report"] = report
	pending_journal_lines.append("Roadmap (%s) : %d pts / %d capacité%s" % [
		squad.get("name", "Équipe"), spent, capacity, " · %d livraison(s)" % delivered.size() if not delivered.is_empty() else ""
	])
	return report


# --- 🎯 L'attention : on ne pilote pas tout (Lot 5 palier 3, spec §13.3) ---

## Nombre d'équipes que le joueur pilote lui-même sur un sprint. Table indexée
## par niveau de carrière (`careers.json → attention.slotsByLevel`), jamais un
## `if career_level == ...`. Le défaut retombe sur « tout est pilotable », ce
## qui rend l'absence de la table inoffensive plutôt que bloquante.
func get_attention_slots() -> int:
	var slots: Dictionary = GameData.careers.get("attention", {}).get("slotsByLevel", {})
	return int(slots.get(career_level, squads.size()))


## Les équipes pilotées ce sprint. Le choix vit dans `piloted_squads`, validé
## par numéro de sprint comme `backlog_draw` — pas d'état à réinitialiser à la
## main quand le sprint avance. Par défaut, les premières équipes de la liste.
func get_piloted_squad_ids() -> Array:
	var slots := get_attention_slots()
	if slots >= squads.size():
		var everything: Array = []
		for squad in squads:
			everything.append(squad.get("id", ""))
		return everything
	if int(piloted_squads.get("sprint", -1)) == sprint_number:
		return piloted_squads.get("ids", [])
	var defaults: Array = []
	for squad in squads:
		if defaults.size() >= slots:
			break
		defaults.append(squad.get("id", ""))
	piloted_squads = {"sprint": sprint_number, "ids": defaults}
	return defaults


## Retourne "" si le choix est accepté, sinon un code de refus rejoué tel quel
## par l'UI — même contrat que `buy_strategy()` et le reste du Comité.
func set_piloted_squads(ids: Array) -> String:
	var slots := get_attention_slots()
	if ids.size() > slots:
		return "slots"
	for squad_id in ids:
		if _find_squad(squad_id).is_empty():
			return "inconnue"
	piloted_squads = {"sprint": sprint_number, "ids": ids.duplicate()}
	return ""


func is_squad_piloted(squad_id: String) -> bool:
	return get_piloted_squad_ids().has(squad_id)


## Le profil d'auto-pilotage d'une équipe = son meilleur PM. Un PM senior
## raisonne en rendement, un junior en valeur brute, personne ne réfléchit du
## tout sans PM — c'est la traduction mécanique de « pondérée par la
## composition » (issue #18).
func auto_pilot_profile_id(squad: Dictionary) -> String:
	var best := "none"
	for member in squad.get("roster", []):
		if member.get("role", "") != "pm":
			continue
		if member.get("seniority", "junior") == "senior":
			return "senior"
		best = "junior"
	return best


## Le plan qu'une équipe non pilotée se donne toute seule. **Affiché et
## appliqué par cette seule fonction** (CLAUDE.md : un seul calcul, deux
## usages) — l'écran prévisualise exactement ce qui sera joué.
func build_auto_plan_for_squad(squad_id: String) -> Array:
	var squad := _find_squad(squad_id)
	if squad.is_empty():
		return []
	var profile_id := auto_pilot_profile_id(squad)
	var profiles: Dictionary = GameData.careers.get("attention", {}).get("autoPilotProfiles", {})
	var profile: Dictionary = profiles.get(profile_id, {})
	var offer := get_backlog_offer_for_squad(squad_id)
	var items: Array = (offer.get("items", []) as Array).duplicate()

	if profile.get("sort", "backlog-order") == "weighted":
		var weights: Dictionary = profile.get("weights", {})
		var per_point: bool = bool(profile.get("perPoint", false))
		var scored: Array = []
		for item in items:
			var score := float(item.get("clients", 0)) * float(weights.get("clients", 0.0))
			score += float(item.get("costPoints", 0)) * float(weights.get("points", 0.0))
			score -= float(item.get("risk", 0)) * float(weights.get("risk", 0.0))
			if per_point:
				score /= max(1.0, float(item.get("costPoints", 1)))
			scored.append({"item": item, "score": score})
		scored.sort_custom(func(a, b): return a["score"] > b["score"])
		items = []
		for entry in scored:
			items.append(entry["item"])

	var remaining := get_squad_capacity(squad_id)
	var epic_ratio: float = float(profile.get("epicPointsRatio", 0.5))
	var plan: Array = []
	for item in items:
		if remaining <= 0:
			break
		var item_id: String = item.get("id", "")
		if is_backlog_epic(item):
			var invested: int = min(int(round(remaining * epic_ratio)), _squad_epic_remaining(squad, item_id))
			if invested <= 0:
				continue
			plan.append({"id": item_id, "points": invested})
			remaining -= invested
		else:
			var cost := int(item.get("costPoints", 0))
			if cost <= 0 or cost > remaining:
				continue
			# Même format que `roadmap_screen._current_plan()` — `points` est
			# toujours renseigné, ce qui rend `backlog_plan_points()` utilisable
			# tel quel pour prévisualiser le panier d'une équipe auto-pilotée.
			plan.append({"id": item_id, "points": cost})
			remaining -= cost
	return plan


## Joue le sprint des équipes que le joueur n'a pas pilotées. À N=1 la boucle
## ne trouve jamais rien (1 équipe, 1 slot) : le déroulé d'un run PM est
## strictement celui d'avant le multi-équipe.
func resolve_unpiloted_squads() -> Array:
	var piloted := get_piloted_squad_ids()
	var reports: Array = []
	for squad in squads:
		var squad_id: String = squad.get("id", "")
		if piloted.has(squad_id):
			continue
		var report := commit_backlog_plan_for_squad(squad_id, build_auto_plan_for_squad(squad_id))
		if not report.is_empty():
			report["autoPiloted"] = true
			report["autoPilotProfile"] = auto_pilot_profile_id(squad)
			reports.append(report)
	return reports


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


## Prix d'activation d'une grande décision, en 💥 Impact. Une décision se paie
## comme une embauche ou une pratique — c'est la condition pour que les trois
## types soient vraiment en concurrence sur le même rayon (carnet §21). Le prix
## d'achat n'est pas le coût d'exploitation : celui-là est la licence par
## siège, prélevée sur le 💰 Revenue à chaque sprint (recurring_charge()).
func decision_cost(card_id: String) -> int:
	return resolved_price("decision", card_id)


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
	return resolved_price("committee", "tool-slot")


## Achète un slot supplémentaire au Comité. Retourne "" si l'achat a eu lieu,
## sinon la raison du refus ("plafond" ou "impact").
func buy_tool_slot() -> String:
	var cost := tool_slot_purchase_cost()
	if cost < 0:
		return "plafond"
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal
	tool_slots_purchased += 1
	pending_journal_lines.append("🔧 Slot d'outillage supplémentaire acheté (%d 💥) — %d/%d." % [
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


## Active une grande décision : l'Impact tombe immédiatement, ses effets
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
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal

	var deltas := EffectResolver.resolve_card_activation(card_id, team_profile, era_id)
	var charge := recurring_charge("decision", card_id)
	add_pending(deltas, "Grande décision : %s activée (%d 💥%s, %s)" % [
		card.get("name", card_id), cost,
		" · %d 💰/sprint de licence" % charge if charge > 0 else "", team_profile
	], String(card.get("peopleTarget", "")))
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
	return resolved_price("reserve")


func is_reserved(kind: String, asset_id: String) -> bool:
	for entry in reserved_assets:
		if entry.get("kind", "") == kind and entry.get("id", "") == asset_id:
			return true
	return false


## Punaise un Actif de l'offre : il sera encore là au sprint suivant, et un
## 🎲 re-tirage ne l'emporte pas. Le bail est **d'un sprint** — le garder plus
## longtemps se re-paie, sinon quelques Impacts suffiraient à annuler toute la
## rareté. Deuxième appel = on décolle la punaise et l'Impact revient (même sprint).
## Retourne "" si l'état a changé, sinon la raison du refus.
func toggle_reservation(kind: String, asset_id: String, data: Dictionary) -> String:
	for entry in reserved_assets:
		if entry.get("kind", "") == kind and entry.get("id", "") == asset_id:
			reserved_assets.erase(entry)
			impact_wallet += int(entry.get("paid", 0))
			return ""

	var cost := reserve_cost()
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal
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
## arbitrage de plus contre l'Impact qu'on aurait mis dans une embauche.
func shop_reroll_cost() -> int:
	get_shop_offer()  # le prix dépend du nombre de re-tirages déjà faits ce sprint
	return resolved_price("reroll")


## Retourne "" si le re-tirage a eu lieu, sinon la raison du refus.
func reroll_shop_offer() -> String:
	var cost := shop_reroll_cost()
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal

	var rerolls := int(get_shop_offer().get("rerolls", 0)) + 1
	current_shop_offer = _draw_shop_offer(rerolls)
	pending_journal_lines.append("🎲 Offre re-tirée (%d 💥) — %s" % [
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


## Embauche un candidat de l'offre du sprint, dans `target_squad_id` s'il est
## fourni et existe, sinon dans l'équipe principale (comportement historique,
## inchangé à N=1). Au-delà de PM et sans équipe précisée (aucun sélecteur
## dédié pour l'instant, spec §13.2 — voir carnet §30), la recrue rejoint
## l'équipe la moins fournie : un équilibrage simple plutôt qu'un empilement
## systématique sur l'équipe historique. Retourne "" si l'embauche a eu lieu,
## sinon la raison du refus ("impact" ou "cap").
## Un recrutement engage les **deux** monnaies : un prix d'embauche en Impact
## et un salaire en Revenue à chaque sprint jusqu'à la fin du mandat — c'est ce
## qui supprime la réponse « recruter est toujours bon » (spec §3).
func hire_candidate(candidate: Dictionary, target_squad_id: String = "") -> String:
	if is_quarter_requirement_active("hiringFrozen"):
		return "quarter-requirement"
	if get_roster().size() >= get_team_cap():
		return "cap"
	var cost := resolved_price("candidate", candidate.get("id", ""), candidate)
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal

	var discount_note := ""
	if next_hire_discount > 0:
		discount_note = " (réseau : −%d 💥)" % next_hire_discount
		next_hire_discount = 0

	var target_roster := _target_roster(target_squad_id)
	var newcomer := _employee_from_source(candidate, sprint_number, bool(candidate.get("hiddenRevealed", false)))
	var newcomer_salary := int(newcomer.get("salary", 0))
	var newcomer_effect := float(get_individual_team_conf().get("systemicEffects", {}).get("betterPaidNewcomer", 0))
	for existing_employee in target_roster:
		if int(existing_employee.get("salary", 0)) < newcomer_salary:
			apply_people_effect_for_employee(existing_employee, {"salaire": newcomer_effect})
	target_roster.append(newcomer)
	_refresh_team_moral()
	_hired_candidate_ids.append(candidate.get("id", ""))
	release_reservation("candidate", candidate.get("id", ""))
	candidate["hired"] = true
	pending_journal_lines.append("Embauche : %s (%s, %d 💥 · %d 💰/sprint de salaire)%s" % [
		candidate.get("name", ""), _role_label(candidate.get("role", "")), cost,
		recurring_charge("candidate", candidate.get("id", ""), candidate), discount_note
	])
	return ""


## Licencie un employé du roster (spec §4.4) : indemnités en Impact, Moral en
## baisse, et Cynisme en hausse à partir du 2e licenciement du mandat. Le
## salaire, lui, quitte la facture du sprint suivant — licencier est bien la
## seule façon de faire baisser la masse salariale.
## Retourne "" si le licenciement a eu lieu, sinon la raison du refus.
func fire_employee(employee_id: String) -> String:
	var owner := _find_employee_owner(employee_id)
	if owner.is_empty():
		return "introuvable"
	var employee: Dictionary = owner.get("employee", {})
	var firing: Dictionary = GameData.balance.get("firing", {})
	var severance := resolved_price("severance")
	var refusal := _pay_impact(severance)
	if refusal != "":
		return refusal

	fired_count += 1
	var deltas: Dictionary = {}
	var note := "Licenciement : %s — indemnités %d 💥, −%d 💰/sprint de salaire" % [
		employee.get("name", ""), severance, int(employee.get("salary", 1))
	]
	if fired_count >= 2:
		deltas["cynisme"] = float(firing.get("cynismePerExtraFiring", 3))
		note += " (l'organisation commence à y voir une politique)"
	add_pending(deltas, note)
	queue_people_effect("tous", {"confiance": float(firing.get("confiance", -8))})
	var owner_squad: Dictionary = owner.get("squad", {})
	var owner_roster: Array = owner_squad.get("roster", [])
	owner_roster.erase(employee)
	_refresh_team_moral()
	return ""


## Achète une pratique de l'offre du sprint (+2 Cynisme — un process de
## plus). Retourne "" si l'achat a eu lieu, sinon la raison du refus.
func buy_practice(practice_id: String) -> String:
	if owned_practices.has(practice_id):
		return "possedee"
	var practice := find_practice(practice_id)
	if practice.is_empty():
		return "introuvable"
	var cost := resolved_price("practice", practice_id)
	var refusal := _pay_impact(cost)
	if refusal != "":
		return refusal

	owned_practices.append(practice_id)
	release_reservation("practice", practice_id)
	var cynisme := float(_active_quarter_effects().get("practiceCynisme", GameData.balance.get("shopDraw", {}).get("practiceCynisme", 2)))
	var charge := recurring_charge("practice", practice_id)
	add_pending({"cynisme": cynisme}, "Nouvelle pratique : %s %s (%d 💥%s) — un process de plus, l'organisation lève les yeux au ciel" % [
		practice.get("icon", ""), practice.get("name", ""), cost,
		" · %d 💰/sprint de licence" % charge if charge > 0 else ""
	])
	var purchase_people: Dictionary = practice.get("onPurchasePeopleEffects", {})
	if not purchase_people.is_empty():
		queue_people_effect(String(purchase_people.get("target", "tous")), purchase_people.get("deltas", {}))

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
	while not pending_team_crises.is_empty():
		var crisis_event := _team_crisis_event(pending_team_crises.pop_front())
		if not crisis_event.is_empty():
			return crisis_event
	while not pending_team_concerns.is_empty():
		var concern_event := _team_concern_event(pending_team_concerns.pop_front())
		if not concern_event.is_empty():
			return concern_event
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
## la décision qui les a produits. Trois pseudo-ressources sont acceptées en
## plus des 5 jauges : "impact" (crédité au portefeuille), "revenue" (encaissé
## ou prélevé sur le Revenue) et "clients" (un **effet client en points**, du
## même vocabulaire que celui d'une feature, converti en clients réels par le
## modèle économique du run). Aucune des trois n'est bornée.
## Applique le choix d'un événement Inbox. Les deltas ordinaires vont au
## panier ; une bascule de segment (`clientConversion`) s'applique tout de
## suite, comme le pivot du Comité — c'est un mouvement de population, pas un
## delta de jauge. La fraction est **tirée** dans la fourchette de la carte :
## le joueur choisit d'y consacrer le sprint, il ne sait pas combien suivront.
func apply_inbox_choice(choice: Dictionary, note: String = "") -> void:
	var effects: Dictionary = choice.get("effects", {}).duplicate()
	if effects.has("moral"):
		var target := String(choice.get("peopleTarget", "tous"))
		queue_people_effect(target, {"moral": float(effects.get("moral", 0))})
		effects.erase("moral")
	add_pending(effects, note)
	var person_effect: Dictionary = choice.get("personEffect", {})
	if not person_effect.is_empty():
		var person := find_employee(String(person_effect.get("employee_id", "")))
		if not person.is_empty():
			apply_people_effect_for_employee(person, person_effect.get("deltas", {}))
	var people_effect: Dictionary = choice.get("peopleEffects", {})
	if not people_effect.is_empty():
		queue_people_effect(String(people_effect.get("target", "tous")), people_effect.get("deltas", {}))
	_resolve_team_concern(choice)
	_resolve_team_crisis(choice)
	var conversion: Dictionary = choice.get("clientConversion", {})
	if conversion.is_empty():
		return
	var ratio := randf_range(float(conversion.get("minRatio", 0.0)), float(conversion.get("maxRatio", 0.0)))
	var moved := convert_clients(str(conversion.get("from", "")), str(conversion.get("to", "")), ratio)
	if moved > 0.0:
		pending_journal_lines.append("👥 %d clients basculent vers l'offre payante." % int(round(moved)))


## `people_target` est la cible du seul delta qui n'est pas une jauge : le
## Moral, qui n'existe que chez des personnes. Chaque famille de contenu la
## déclare — l'Inbox par `peopleTarget`, une livraison par l'équipe qui l'a
## produite (`squad:<id>`), une carte ou une pratique par son propre
## `peopleTarget`. Sans cible déclarée, la valeur par défaut vient des données
## (`individualTeam.defaultPeopleTarget`) et jamais d'un littéral de script :
## c'est ce qui empêche qu'à N>1 une livraison d'une seule équipe se mette à
## remuer le Moral de tout le monde sans que rien ne casse.
func add_pending(deltas: Dictionary, note: String = "", people_target: String = "") -> void:
	for resource_id in deltas.keys():
		var value: float = float(deltas[resource_id])
		if resource_id == "moral":
			queue_people_effect(_people_target_or_default(people_target), {"moral": value})
			continue
		pending_deltas[resource_id] = pending_deltas.get(resource_id, 0.0) + value
	if note != "":
		pending_journal_lines.append(note)


## Applique le panier d'effets aux 5 jauges (+ charges récurrentes, effets de
## roster et de pratiques, décroissance de la Réputation produit, conversion
## Traction × Levier × Impact, flux des deux monnaies), journalise, puis
## vérifie les fins et la revue trimestrielle. Retourne l'id de la fin
## atteinte, ou "" si le mandat continue.
## À appeler une seule fois par sprint, depuis l'écran de Résolution.
func apply_pending_and_check() -> String:
	if quarter_exit_choice_pending:
		return ""
	last_revenue_cost = int(round(pending_deltas.get("revenue", 0.0)))

	_apply_per_sprint_effects()
	_apply_pending_people_effects()
	_apply_team_sprint_energy()
	_inspect_team_crises()
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
	# 🧩 Compendium des synergies (spec §12.1) : la persistance vit dans
	# PlayerProfile, pas ici — un seul calcul (celui du resolver), une seule
	# lecture (celle du rapport déjà produit).
	PlayerProfile.record_score_report(last_score_report)
	# L'ordre compte : la conversion résout la population du sprint, les
	# charges la facturent. L'inverse encaisserait sur la nouvelle base et
	# facturerait le support sur l'ancienne — un sprint de support gratuit pour
	# toute acquisition, et des clients partis facturés un sprint de trop.
	_apply_score_conversion()
	_apply_recurring_charges()

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

	# 💰 Le Revenue n'est pas une jauge : il encaisse son delta sans borne, et
	# c'est ce qui permet de mourir riche d'Impact et sans caisse.
	var revenue_delta := float(pending_deltas.get("revenue", 0.0))
	if not is_zero_approx(revenue_delta):
		revenue += revenue_delta
		applied["revenue"] = revenue_delta

	_apply_energy_flow()
	var energy_sprint_delta := int(last_energy_report.get("sprintDelta", 0))
	if energy_sprint_delta != 0:
		applied["energie"] = energy_sprint_delta

	var quarter_ending := _record_quarter_resolution()
	if last_wallet_delta != 0:
		applied["impact"] = last_wallet_delta

	journal.append({
		"sprint": sprint_number,
		"text": " · ".join(pending_journal_lines) if not pending_journal_lines.is_empty() else "Sprint calme — aucune décision marquante.",
		"deltas": EffectResolver.format_deltas(applied),
	})
	_record_desk_journal(applied)

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
## par sprint, et décroissance naturelle de la Réputation produit (§8.1).
func _apply_per_sprint_effects() -> void:
	var people_systems: Dictionary = get_individual_team_conf().get("systemicEffects", {})
	var projected_debt := float(resource_values.get("dette-organisationnelle", 0.0)) + float(pending_deltas.get("dette-organisationnelle", 0.0))
	if projected_debt >= float(people_systems.get("debtMoralAt", 101)):
		queue_people_effect("tous", {"moral": float(people_systems.get("debtMoralPerSprint", 0))})
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

	for employee in get_roster():
		if sprint_number - int(employee.get("hiredSprint", sprint_number)) >= int(people_systems.get("salaryDriftAfterSprints", 99)):
			apply_people_effect_for_employee(employee, {"salaire": float(people_systems.get("salaryDriftPerSprint", 0))})
		if not employee.get("hiddenRevealed", false):
			continue
		var hidden_trait := get_hidden_trait(employee.get("hidden_trait", ""))
		var trait_moral := float(hidden_trait.get("effects", {}).get("moralPerSprint", 0))
		if trait_moral != 0.0:
			apply_people_effect_for_employee(employee, {"moral": trait_moral})

	for practice_id in owned_practices:
		var practice := find_practice(practice_id)
		var per_sprint: Dictionary = practice.get("perSprint", {})
		if not per_sprint.is_empty():
			add_pending(per_sprint, "", String(practice.get("peopleTarget", "")))
		var people_per_sprint: Dictionary = practice.get("perSprintPeopleEffects", {})
		if not people_per_sprint.is_empty():
			queue_people_effect(String(people_per_sprint.get("target", "tous")), people_per_sprint.get("deltas", {}))

	var decay := float(GameData.balance.get("pressure", {}).get("reputationDecayPerSprint", 2))
	if decay != 0.0:
		add_pending({"reputation-produit": -decay},
			"📈 Le marché avance sans vous attendre : Réputation produit −%d" % int(decay))


## L'énergie devient aussi l'état des personnes : une équipe qui utilise toute
## sa capacité finit le sprint entamée, une équipe sous-chargée récupère. Le
## CPO garde sa propre jauge, dont la régénération lit la moyenne de Moral.
func _apply_team_sprint_energy() -> void:
	var energy_conf: Dictionary = get_individual_team_conf().get("sprintEnergy", {})
	for squad_index in squads.size():
		var squad: Dictionary = squads[squad_index]
		var capacity := int(squad.get("capacity", 0))
		var spent := int(squad.get("spent_points", 0))
		if squad_index == 0 and int(last_roadmap_report.get("sprint", -1)) == sprint_number:
			capacity = int(last_roadmap_report.get("capacity", capacity))
			spent = int(last_roadmap_report.get("plannedPoints", spent))
		if capacity <= 0:
			continue
		var delta: float = float(energy_conf.get("underCapacity", 0))
		if spent > capacity:
			delta = float(energy_conf.get("overCapacity", 0))
		elif spent >= capacity:
			delta = float(energy_conf.get("atCapacity", 0))
		for employee in squad.get("roster", []):
			apply_people_effect_for_employee(employee, {"energie": delta})
		if spent > 0 and spent <= capacity:
			for employee in squad.get("roster", []):
				apply_people_effect_for_employee(employee, {"moral": float(energy_conf.get("successfulDeliveryMoral", 0))})


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
		"wallet": impact_wallet,
		"business_model_id": business_model_id,
		# 👥 L'économie du sprint : la population d'avant, la forme du modèle,
		# l'échelle de prix du scénario, et l'effet client des décisions déjà
		# prises ce sprint (événements, Comité). Les livraisons, elles, sont
		# lues par le resolver dans `squads[].delivered` — comme la Traction.
		"clients": clients.duplicate(),
		"segments": get_segments(),
		"price_scale": get_price_scale(),
		"segment_price_multipliers": segment_price_multipliers.duplicate(),
		"segment_arrival_multipliers": segment_arrival_multipliers.duplicate(),
		"pending_client_points": float(pending_deltas.get("clients", 0.0)),
		"support_teams": support_teams.duplicate(),
		"product_tier": product_tier,
		"active_tools": _active_tool_entries(),
		"owned_practices": owned_practices,
		"strategy_ids": _score_strategy_ids(),
		"minimum_clients_for_traction": int(_active_quarter_effects().get("minimumClientsForTraction", 0)),
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
	var projected := get_resource_snapshot()
	for resource_id in pending_deltas.keys():
		if not projected.has(resource_id):
			continue
		projected[resource_id] = clamp(float(projected[resource_id]) + float(pending_deltas[resource_id]), minimum, maximum)
	return projected


## 💰 Ce que l'organisation paie chaque sprint : salaires **et** licences. La
## facture est celle que get_recurring_charges() affiche sur les écrans — une
## seule fonction pour l'affichage et le prélèvement, sinon l'addition montrée
## au joueur finit par mentir.
func _apply_recurring_charges() -> void:
	var charges := get_recurring_charges()
	var payroll_multiplier := float(_active_quarter_effects().get("payrollMultiplier", 1.0))
	last_payroll = int(round(float(charges.get("payroll", 0)) * payroll_multiplier))
	last_licenses = int(charges.get("licenses", 0))
	last_client_cost = int(charges.get("clients", 0))
	var total := last_payroll + last_licenses + last_client_cost
	if total <= 0:
		return
	pending_deltas["revenue"] = pending_deltas.get("revenue", 0.0) - float(total)
	pending_journal_lines.append("Charges du sprint : −%d 💰 (salaires %d · licences %d · clients %d)" % [
		total, last_payroll, last_licenses, last_client_cost
	])


## Convertit le rapport du ScoreResolver en état de jeu. Aucun calcul de
## score ne vit ici : le rapport est la seule source de vérité de l'économie.
func _apply_score_conversion() -> void:
	var conversion: Dictionary = last_score_report.get("conversion", {})
	var client_report: Dictionary = conversion.get("clients", {})
	var wallet_report: Dictionary = conversion.get("wallet", {})

	# 👥 La population du sprint remplace le stock d'abonnements. Le joueur ne
	# voit toujours qu'une ligne — « ce que vos clients ont payé ce sprint » —
	# mais elle est enfin racontable : 38 clients gagnés, 12 partis.
	pending_deltas.erase("clients")
	if client_report.has("after"):
		clients = client_report.get("after", clients).duplicate()
	last_client_report = client_report.duplicate(true)
	streak = int(last_score_report.get("next_streak", 0))
	last_revenue = int(round(float(conversion.get("revenue", {}).get("in", 0.0))))
	if last_revenue != 0:
		pending_deltas["revenue"] = pending_deltas.get("revenue", 0.0) + float(last_revenue)
		pending_journal_lines.append("Clients : +%d 💰 (%d arrivés, %d partis)" % [
			last_revenue,
			int(round(float(client_report.get("joined", 0.0)))),
			int(round(float(client_report.get("left", 0.0)))),
		])

	for resource_id in conversion.get("resource_deltas", {}).keys():
		var delta: float = float(conversion["resource_deltas"][resource_id])
		if not is_zero_approx(delta):
			pending_deltas[resource_id] = pending_deltas.get(resource_id, 0.0) + delta

	# 💥 Le portefeuille encaisse l'Impact du sprint, sans conversion ni
	# plancher. Il n'est pas ramené à zéro s'il est négatif : ce qui tue, c'est
	# de ne pas l'avoir reconstitué à l'heure du verdict (spec §3.5).
	var pending_impact := int(round(pending_deltas.get("impact", 0.0)))
	pending_deltas.erase("impact")
	var wallet_gain := int(wallet_report.get("gain", 0))
	var before := impact_wallet
	impact_wallet += pending_impact + wallet_gain
	last_wallet_delta = impact_wallet - before

	var parts: Array = ["sprint +%d" % wallet_gain]
	if pending_impact != 0:
		parts.append("décisions %s%d" % ["+" if pending_impact >= 0 else "−", abs(pending_impact)])
	pending_journal_lines.append("💥 Portefeuille : %s (solde %d)" % [" · ".join(parts), impact_wallet])


## Le verdict porte sur le **solde du portefeuille**, pas sur la production du
## trimestre : dépenser fait donc reculer vers l'objectif en cours, et c'est
## exactement le rythme voulu — investir tôt dans le trimestre, sécuriser à la
## fin (spec §3.2 et §4).
func _record_quarter_resolution() -> String:
	quarter_sprint += 1
	if quarter_sprint < get_quarter_length():
		return ""

	var objectives := evaluate_board_objectives()
	var qualitative_ok := true
	for objective in objectives:
		if not bool(objective.get("ok", false)):
			qualitative_ok = false
	var passed := impact_wallet >= get_current_quota()
	# 🏛️ Plan de redressement (spec §12) : un rattrapage de quota consommé
	# automatiquement, la première fois où il sert — jamais un choix manuel,
	# sinon on ne le "raterait" jamais.
	var turnaround_used := false
	if not passed and turnaround_plans_available > 0:
		turnaround_plans_available -= 1
		passed = true
		turnaround_used = true
		var missed_quarter: Dictionary = get_individual_team_conf().get("systemicEffects", {}).get("missedQuarter", {})
		apply_people_effect("tous", missed_quarter)
		pending_journal_lines.append("🏛️ Le plan sauve le quota, pas la fatigue de l'équipe.")
	var qualitative_bonus := 0
	if passed and qualitative_ok:
		qualitative_bonus = int(GameData.quotas.get("qualitativeBonusImpact", 0))
		impact_wallet += qualitative_bonus
		last_wallet_delta += qualitative_bonus

	quarter_result = {
		"sprint": sprint_number,
		"quarter": quarter_index,
		"length": get_quarter_length(),
		"quota": get_current_quota(),
		"impact": impact_wallet,
		"passed": passed,
		"turnaroundUsed": turnaround_used,
		"qualitativeBonus": qualitative_bonus,
		"objectives": objectives,
		"requirementIds": quarter_requirement_ids.duplicate(),
	}
	board_review_state = "passed" if qualitative_ok else "failed"
	board_review_result = quarter_result.duplicate(true)
	pending_journal_lines.append("Revue trimestrielle : %d / %d 💥 au portefeuille%s" % [
		impact_wallet, get_current_quota(), " · bonus qualitatif +%d 💥" % qualitative_bonus if qualitative_bonus > 0 else ""
	])
	if not passed:
		is_mandate_over = true
		ending_id = "remercie"
		ending_reached.emit(ending_id)
		return ending_id
	if quarter_index == 4 and not long_mandate:
		quarter_exit_choice_pending = true
		_unlock_next_career_level()
		return ""
	_prepare_quarter(quarter_index + 1)
	return ""


## Déblocage strict (spec §13.4) : "gagner un niveau" = franchir son 4e
## trimestre, quel que soit le choix fait ensuite (rester en mandat long ou
## sortir) — la spec parle explicitement d'un mandat "complet" en 4
## trimestres, avant même la question de la sortie. Idempotent par
## construction (PlayerProfile.unlock_career_level l'est) : rejouer plusieurs
## mandats au même niveau ne redéclenche rien après le premier.
func _unlock_next_career_level() -> void:
	var order: Array = GameData.careers.get("order", [])
	var current_index := order.find(career_level)
	if current_index == -1 or current_index + 1 >= order.size():
		return
	var next_level: String = order[current_index + 1]
	if PlayerProfile.is_career_level_unlocked(next_level):
		return
	PlayerProfile.unlock_career_level(next_level)
	newly_unlocked_career_level = next_level


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
	_sync_cpo_energy()

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
	if effects.has("nextHireDiscountImpact"):
		next_hire_discount += int(effects.get("nextHireDiscountImpact", 0))
		extra = " Son carnet d'adresses vaut %d 💥 sur le prochain recrutement." % int(effects.get("nextHireDiscountImpact", 0))
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
	if not leavers.is_empty():
		_refresh_team_moral()


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
			var max_value := _condition_value(condition.get("resource", ""))
			ok = max_value <= float(condition.get("value", 0))
			current = "%d" % int(round(max_value))
		"resource-min":
			var min_value := _condition_value(condition.get("resource", ""))
			ok = min_value >= float(condition.get("value", 0))
			current = "%d" % int(round(min_value))
		"decisions-min":
			ok = activated_cards.size() >= int(condition.get("value", 1))
			current = "%d" % activated_cards.size()
		"revenue-min":
			ok = last_revenue >= int(condition.get("value", 0))
			current = "%d" % last_revenue
		"wallet-min":
			ok = impact_wallet >= int(condition.get("value", 0))
			current = "%d" % impact_wallet
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


## Une condition peut porter sur une jauge **ou** sur une des deux valeurs non
## bornées, qui ne vivent pas dans resource_values : le Revenue et le
## portefeuille d'Impact. Un seul point de lecture pour les trois familles.
func _condition_value(resource_id: String) -> float:
	match resource_id:
		"revenue":
			return revenue
		"impact":
			return float(impact_wallet)
		"energie":
			return float(energy)
	return get_resource_value(resource_id)


## Fins négatives par seuil (balance.json → endingThresholds). Les
## pseudo-ressources "energie", "revenue" et "impact" y sont acceptées : elles
## lisent respectivement la jauge personnelle du joueur (burn-out sur ⚡ ≤ 0),
## le Revenue non borné (faillite sur 💰 ≤ 0) et le portefeuille — ce dernier
## n'a aucun seuil de fin aujourd'hui, et c'est voulu : une bourse vide n'est
## pas une défaite (spec §3.5).
func _check_bad_endings() -> String:
	var thresholds: Array = GameData.balance.get("endingThresholds", [])
	var overrides: Dictionary = GameData.balance.get("endingThresholdOverrides", {}).get(era_id, {})

	for threshold in thresholds:
		var resource_id: String = threshold.get("resource", "")
		if not (resource_values.has(resource_id) or resource_id in ["energie", "revenue", "impact"]):
			continue
		var value := _condition_value(resource_id)
		var limit: float = overrides.get(resource_id, threshold.get("value", 0))
		var comparison: String = threshold.get("comparison", "lte")
		var triggered := (comparison == "lte" and value <= limit) or (comparison == "gte" and value >= limit)
		if triggered:
			return threshold.get("ending", "")
	return ""


## 🚀 L'IPO ou 🤝 le rachat ? On ne moyenne plus une perception produit et une
## perception joueur (spec-clients-revenue.md §5.1.1) : ce sont deux unités
## différentes. L'IPO se gagne sur **ce que vaut le produit** — une 📈
## Réputation produit haute ET une population qui paie au moins ses charges.
## Le rachat est le reste : quelqu'un vous achète, ce qui n'exige rien du
## produit et ne dit donc rien de lui.
func _resolve_good_ending() -> String:
	var config: Dictionary = GameData.balance.get("goodEnding", {})
	var ipo: Dictionary = config.get("ipo", {})
	var reputation := float(resource_values.get(ipo.get("resource", "reputation-produit"), 0.0))
	if reputation < float(ipo.get("threshold", 60)):
		return config.get("lowEnding", "rachat")
	var charges := float(get_recurring_charges().get("total", 0))
	var ratio := float(ipo.get("clientRevenueAtLeastCharges", 1.0))
	if charges > 0.0 and get_client_revenue() < charges * ratio:
		return config.get("lowEnding", "rachat")
	return config.get("highEnding", "ipo")


# --- Le bureau : la remontée par exception (issue #54) ---

## Le HUD n'affiche que trois chiffres. Tout le reste — les jauges, l'Énergie,
## la caisse, l'écart au quota — **vient chercher le joueur quand ça va mal**,
## et se tait le reste du temps. C'est le même motif que
## `get_employee_alert()` livré par #43, généralisé à l'entreprise.
##
## Deux règles portées ici et pas dans l'écran :
##  1. les seuils vivent dans `balance.json → desk.alerts`, jamais en dur ;
##  2. une alerte doit prévenir **avec de la marge**. Arrivée au moment où
##     c'est perdu, elle punit au lieu d'informer — `alerts.marginPerSprint`
##     est le contrat, et le banc le vérifie jauge par jauge.
func get_desk_conf() -> Dictionary:
	return GameData.balance.get("desk", {})


func get_alerts_conf() -> Dictionary:
	return get_desk_conf().get("alerts", {})


## Les alertes actives, dans l'ordre où elles doivent s'afficher : la plus
## grave d'abord. Chaque entrée porte `id`, `label` et `severity`
## (`danger`/`warn`), jamais de mise en forme — l'écran décide de la couleur.
func get_active_alerts() -> Array:
	var conf := get_alerts_conf()
	var alerts: Array = []

	for gauge in conf.get("gauges", []):
		var gauge_id := String(gauge.get("id", ""))
		if gauge_id == "":
			continue
		var value := get_resource_value(gauge_id)
		var at := float(gauge.get("at", 0))
		var below := String(gauge.get("direction", "below")) == "below"
		if (below and value <= at) or (not below and value >= at):
			# La sévérité se déduit de la distance restante au mur : à
			# mi-chemin de la marge, ce n'est plus un avertissement.
			var margin := float(conf.get("marginPerSprint", 12))
			var remaining: float = absf(float(gauge.get("bound", 0)) - value)
			alerts.append({
				"id": gauge_id,
				"label": String(gauge.get("label", gauge_id)),
				"severity": "danger" if remaining <= margin else "warn",
			})

	var energy_at := float(conf.get("energyBelow", 0))
	if energy_at > 0.0 and float(energy) <= energy_at:
		alerts.append({"id": "energie", "label": String(conf.get("energyLabel", "Énergie basse")),
			"severity": "danger" if float(energy) <= energy_at * 0.5 else "warn"})

	# 💰 La caisse ne se juge pas dans l'absolu : elle se juge en sprints de
	# survie. Vingt mille en banque ne veulent rien dire sans les charges.
	var charges := float(get_recurring_charges().get("total", 0))
	var sprints_covered := float(conf.get("cashBelowSprintsOfCharges", 0.0))
	if charges > 0.0 and sprints_covered > 0.0 and revenue <= charges * sprints_covered:
		alerts.append({"id": "revenue", "label": String(conf.get("cashLabel", "Caisse basse")),
			"severity": "danger"})

	# 🎯 L'écart au quota ne devient une alerte qu'au **dernier sprint** du
	# trimestre : avant, il reste du temps, et prévenir trop tôt transforme
	# un pari en calcul (question de vision n°4).
	var progress := get_quarter_progress()
	var length := int(progress.get("length", 1))
	var quota := float(progress.get("quota", 0))
	var ratio := float(conf.get("quotaShortfallRatio", 0.0))
	if quota > 0.0 and ratio > 0.0 and int(progress.get("sprint", 0)) >= length - 1 \
			and float(progress.get("impact", 0)) < quota * ratio:
		alerts.append({"id": "quota", "label": String(conf.get("quotaLabel", "Quota menacé")),
			"severity": "danger"})

	alerts.sort_custom(func(a, b): return a.get("severity", "") == "danger" and b.get("severity", "") != "danger")
	return alerts


## Les trois valeurs permanentes du bureau, et elles seules. L'Impact sort
## avec sa progression vers le quota : l'objectif est présent **par la forme**,
## pas par un deuxième chiffre à surveiller (issue #54 §4).
func get_desk_vitals() -> Dictionary:
	var progress := get_quarter_progress()
	var quota := float(progress.get("quota", 0))
	return {
		"impact": impact_wallet,
		"quota": int(quota),
		"quotaRatio": clampf(float(impact_wallet) / maxf(quota, 1.0), 0.0, 1.0),
		"revenue": int(round(revenue)),
		"users": int(round(get_client_total())),
	}


## 📬 Le courrier **du bureau** est collant sur le sprint. Dans le tunnel
## d'écrans, l'Inbox n'était traversée qu'une fois : tirer à l'ouverture
## suffisait. Dans un hub libre on ouvre et ferme le courrier autant qu'on
## veut — retirer à chaque ouverture offrirait un re-roll gratuit et infini,
## ce qui supprime le pari (issue #54 §1).
##
## `draw_inbox_event()` garde sa sémantique de file (crises, inquiétudes, pool)
## pour tout le reste du jeu : c'est ici, et seulement ici, qu'on retient le
## tirage.
func get_sprint_event() -> Dictionary:
	if _sprint_event_sprint == sprint_number:
		return _sprint_event
	_sprint_event = draw_inbox_event()
	_sprint_event_sprint = sprint_number
	_sprint_event_answered = false
	_sprint_event_resolution = {}
	return _sprint_event


## Combien de courrier attend encore une réponse. La tuile de l'application
## le porte **avant** qu'on l'ouvre : dans un hub libre, ce qui ne se rappelle
## pas au joueur ne sera jamais ouvert.
func pending_inbox_count() -> int:
	if _sprint_event_answered:
		return 0
	return 1 if not get_sprint_event().is_empty() else 0


func mark_sprint_event_answered(resolution: Dictionary = {}) -> void:
	_sprint_event_answered = true
	_sprint_event_resolution = resolution.duplicate(true)


func is_sprint_event_answered() -> bool:
	return _sprint_event_sprint == sprint_number and _sprint_event_answered


func get_sprint_event_resolution() -> Dictionary:
	return _sprint_event_resolution.duplicate(true)


## 🏁 Ce qu'on emporte en signant. La feuille dit ce qui a été fait **et ce qui
## a été ignoré** : découvrir à la Résolution qu'un événement non traité s'est
## résolu au pire serait un piège, pas un pari (question de vision n°4).
func get_closing_summary() -> Array:
	var pending := pending_inbox_count()
	var capacity := get_effective_capacity()
	return [
		{"label": "Capacité du sprint", "value": "%d points" % capacity, "warn": false},
		{"label": "Courrier non traité", "value": str(pending), "warn": pending > 0},
		{"label": "Énergie restante", "value": "⚡ %d" % energy, "warn": energy <= int(get_alerts_conf().get("energyBelow", 0))},
		{"label": "Portefeuille", "value": "💥 %d" % impact_wallet, "warn": false},
	]


## Skipper coûte, toujours. Sans ça, ignorer le jeu devient la stratégie
## dominante — et le banc l'asserte au même titre que « ne rien faire perd ».
## La valeur du malus vit dans `balance.json → desk.skip`, jamais ici.
func resolve_unanswered_events() -> int:
	if _sprint_event_answered or _sprint_event.is_empty():
		return 0
	var skip: Dictionary = get_desk_conf().get("skip", {})
	var penalty := int(skip.get("unansweredEventCapitalPolitique", 0))
	if penalty != 0:
		add_pending({"capital-politique": penalty},
			"Un message est resté sans réponse : le board l'a remarqué.")
	_sprint_event_answered = true
	return penalty


## Le journal du dernier sprint clos, punaisé au mur. C'est le germe du Lot D
## (#55) : la Résolution deviendra ce flux de lignes, ici on ne fait que garder
## les dernières pour qu'elles restent lisibles pendant le sprint suivant.
func get_last_journal() -> Array:
	return last_journal.duplicate(true)


func record_journal(lines: Array) -> void:
	last_journal = lines.duplicate(true)


## Le papier du mur, rempli à la clôture du sprint. Il vivait vide depuis le
## Lot A : `record_journal()` existait, personne ne l'appelait.
##
## La règle est ici et pas dans l'écran de Résolution pour deux raisons. La
## première est la convention du dépôt — la logique de jeu ne vit pas dans
## l'UI, sinon rien de tout ça n'est testable en headless. La seconde est
## qu'un `applied` complet n'existe qu'ici : c'est le seul endroit du sprint où
## l'on connaît le delta **réellement appliqué** de chaque grandeur, bornes et
## charges comprises. Le calculer ailleurs, ce serait le recalculer.
##
## On garde les mouvements les plus gros — un mur ne se lit pas, il se
## survole — et le nombre de lignes est un réglage, donc il vit dans
## `balance.json → desk.journal.maxLines`.
func _record_desk_journal(applied: Dictionary) -> void:
	var labels: Dictionary = {}
	for resource in GameData.resources:
		labels[String(resource.get("id", ""))] = "%s %s" % [
			resource.get("icon", ""), resource.get("name", "")]
	labels["impact"] = "💥 Impact"
	labels["revenue"] = "💰 Revenue"
	labels["energie"] = "⚡ Énergie"

	var lines: Array = []
	for resource_id in applied.keys():
		var amount := int(round(float(applied[resource_id])))
		if amount == 0:
			continue
		lines.append({
			"id": resource_id,
			"label": String(labels.get(resource_id, String(resource_id).capitalize())),
			"amount": amount,
		})
	lines.sort_custom(func(a, b): return absi(int(a["amount"])) > absi(int(b["amount"])))

	var maximum := int(get_desk_conf().get("journal", {}).get("maxLines", 4))
	record_journal(lines.slice(0, maxi(maximum, 1)))
