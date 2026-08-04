extends SceneTree
## Cas deterministes du moteur de score.
## Lancer : Godot --headless --path game -s res://tests/score_resolver_cases.gd

const ScoreResolverScript = preload("res://scripts/score_resolver.gd")

var failures := 0
var scoring_data: Dictionary = {}
var hidden_traits_data: Dictionary = {}
var cards_data: Dictionary = {}
var candidates_data: Array = []
var companies_data: Array = []
var SprintStateModels: Dictionary = {}


func _initialize() -> void:
	scoring_data = _load_data("scoring.json")
	hidden_traits_data = _load_data("hidden-traits.json")
	cards_data = _load_data("cards.json")
	candidates_data = _load_data("candidates.json").get("candidates", [])
	companies_data = _load_data("companies.json").get("companies", [])
	SprintStateModels = _load_data("balance.json").get("businessModels", {})
	_test_feature_and_epic_traction()
	_test_hand_bonus_order()
	_test_quick_wins_are_one_hand_bonus()
	_test_recent_hires_and_notion()
	_test_notion_lever_by_company_roster()
	_test_shape_up_lever()
	_test_every_tool_card_has_a_lever()
	_test_lever_multipliers()
	_test_streak_and_friction_rules()
	_test_quarter_visible_board_and_technical_audit()
	_test_moral_cap_and_ops_snapshot()
	_test_client_economy()
	_test_no_revenue_comes_from_impact()
	_test_support_team_rates_differ_by_company()
	_test_multi_squad_contract()
	_test_visible_trait_integrity()
	if failures > 0:
		push_error("ScoreResolver: %d cas en erreur." % failures)
		quit(1)
		return
	print("ScoreResolver: tous les cas sont passes.")
	quit(0)


func _test_feature_and_epic_traction() -> void:
	var excel := {"id": "export-excel", "name": "Export Excel", "costPoints": 1, "clients": 4, "risk": 0, "quickWin": true, "tags": ["reporting"]}
	var report := _resolve([_squad("a", [excel])])
	_assert_equal(_first_local_traction(report), 4.0, "Depuis #42 la Traction ne vient que des points : 1 x 4 = 4, l'effet client n'y entre plus.")
	var big := {"id": "grosse", "name": "Grosse feature", "costPoints": 1, "clients": 0, "risk": 0, "quickWin": false, "tags": ["tech"]}
	_assert_equal(_first_local_traction(_resolve([_squad("a", [big])])), _first_local_traction(_resolve([_squad("a", [excel])])),
		"A points egaux, une feature qui paie et une feature qui ne paie pas doivent scorer pareil — c'est ce qui rend l'arbitrage possible.")

	var epic := {"id": "epic-test", "name": "Epic test", "epic": true, "costPoints": 10, "risk": 0}
	report = _resolve([_squad("a", [{"item": epic, "completed": false}])])
	_assert_equal(float(report["squads"][0]["traction"]), 0.0, "Un epic entame ne doit donner aucune Traction.")
	report = _resolve([_squad("a", [{"item": epic, "completed": true}])])
	_assert_equal(_first_local_traction(report), 60.0, "Un epic de 10 points doit exposer une ligne de Traction a 60 a sa completion.")


func _test_quick_wins_are_one_hand_bonus() -> void:
	var rules := _rules_without_streak()
	rules["traction"]["handBonuses"]["bundle"]["minimumDelivered"] = 99
	var quick_one := {"id": "quick-1", "name": "Quick 1", "costPoints": 1, "clients": 0, "quickWin": true, "tags": ["growth"]}
	var quick_two := {"id": "quick-2", "name": "Quick 2", "costPoints": 1, "clients": 0, "quickWin": true, "tags": ["growth"]}
	var report := _resolve([_squad("a", [quick_one, quick_two])], {}, rules)
	var wallet: Dictionary = report.get("conversion", {}).get("wallet", {})
	var expected_bonus := int(rules.get("traction", {}).get("handBonuses", {}).get("quickWins", {}).get("impactBonus", 0))
	_assert_equal(int(wallet.get("quick_win_bonus", 0)), expected_bonus, "Deux quick wins doivent donner un unique bonus d'Impact.")
	# 💥 Plus de racine carree ni d'allocation plancher : le portefeuille
	# encaisse l'Impact du sprint tel quel, plus le bonus de main.
	_assert_equal(int(wallet.get("gain", 0)), int(report.get("global", {}).get("impact", 0)) + expected_bonus,
		"Le portefeuille doit gagner exactement l'Impact du sprint plus le bonus Quick wins.")

	var focus_rules := _rules_without_streak()
	focus_rules["traction"]["handBonuses"]["focus"]["minimumDelivered"] = 2
	report = _resolve([_squad("a", [quick_one, quick_two])], {}, focus_rules)
	_assert_equal(_label_count(report["squads"][0]["lines"], "Focus"), 1, "Focus ne doit etre applique qu'une seule fois par main.")


func _test_hand_bonus_order() -> void:
	var rules: Dictionary = scoring_data.duplicate(true)
	rules["streak"]["leverPerSprint"] = 0.0
	var delivered: Array = []
	for index in 3:
		delivered.append({"id": "focus-%d" % index, "name": "Focus", "costPoints": 1, "clients": 0, "quickWin": false, "tags": ["growth"]})
	var report := _resolve([_squad("a", delivered, [], 3, 3)], {}, rules)
	var squad_report: Dictionary = report["squads"][0]
	_assert_equal(float(squad_report.get("traction", 0.0)), 29.5, "Les bonus doivent suivre 12 x 1.25 x 1.3 + 10 = 29.5.")
	var labels: Array = []
	for line in squad_report.get("lines", []):
		if int(line.get("step", 0)) == 2 and line.get("type", "") != "wallet_add":
			labels.append(line.get("label", ""))
	_assert_equal(labels, ["Sprint parfait", "Focus", "Livraison groupée"], "L'ordre anime des bonus de main doit rester fixe.")


func _test_recent_hires_and_notion() -> void:
	var feature := _traction_feature(25)
	var inherited := [{"id": "a", "role": "dev", "seniority": "junior", "hiredSprint": 0}, {"id": "b", "role": "designer", "seniority": "junior", "hiredSprint": 0}]
	var report := _resolve([_squad("a", [feature], inherited)], {"sprint": 3})
	_assert_false(_has_label(report["squads"][0]["lines"], "Sang neuf"), "Les membres herites (hiredSprint=0) ne sont pas des recrues recentes.")

	var recent := [{"id": "a", "role": "dev", "seniority": "junior", "hiredSprint": 1}, {"id": "b", "role": "designer", "seniority": "junior", "hiredSprint": 1}]
	report = _resolve([_squad("a", [feature], recent)], {"sprint": 3})
	_assert_true(_has_label(report["squads"][0]["lines"], "Sang neuf"), "Deux embauches recentes doivent declencher Sang neuf.")

	var notion_roster := [
		{"id": "junior", "role": "dev", "seniority": "junior", "hiredSprint": 0},
		{"id": "recent", "role": "dev", "seniority": "senior", "hiredSprint": 9},
	]
	report = _resolve([_squad("a", [feature], notion_roster)], {"sprint": 10, "active_tools": ["notion"]}, _rules_without_streak())
	_assert_equal(float(report.get("global", {}).get("lever", 0.0)), 1.32, "Notion doit compter les juniors OU les recrues de moins de 4 sprints.")

	var inherited_senior := [{"id": "senior", "role": "dev", "seniority": "senior", "hiredSprint": 0}]
	report = _resolve([_squad("a", [feature], inherited_senior)], {"sprint": 3, "active_tools": ["notion"]}, _rules_without_streak())
	_assert_equal(float(report.get("global", {}).get("lever", 0.0)), 1.0, "Un senior herite n'est jamais une recrue recente pour Notion.")
	_assert_true(_has_label_prefix(report.get("global", {}).get("lines", []), "Notion · 0 éligibles"), "Un outil actif a zero doit rester visible et expliquer son decompte.")

	var ghost_junior := [{"id": "ghost", "role": "dev", "seniority": "junior", "hiredSprint": 0, "hidden_trait": "fantome", "hiddenRevealed": true}]
	report = _resolve([_squad("a", [feature], ghost_junior)], {"sprint": 10, "active_tools": ["notion"]}, _rules_without_streak())
	_assert_equal(float(report.get("global", {}).get("lever", 0.0)), 1.08, "Le Fantome doit contribuer a moitie au levier de Notion, avant adoption x2.")


## Critère de recette de l'issue #16 : la MÊME carte Notion (un seul
## `eligibility`/`refractory` dans cards.json) donne un Levier positif sur
## le roster réel de Karavel (junior) et négatif sur celui de Meridia
## (senior, ancien) — sans aucune branche `company_id`/`if` dans le moteur.
## Assez de sprints (10) pour que l'ancienneté de l'équipe héritée de Meridia
## (hiredSprint=0) dépasse le seuil `hiredBeforeSprints: 8` du réfractaire.
func _test_notion_lever_by_company_roster() -> void:
	var feature := _traction_feature(1)
	var karavel := _company_roster("karavel-scaleup")
	var meridia := _company_roster("meridia-corp")
	_assert_false(karavel.is_empty(), "companies.json doit toujours déclarer karavel-scaleup pour ce cas.")
	_assert_false(meridia.is_empty(), "companies.json doit toujours déclarer meridia-corp pour ce cas.")

	var karavel_report := _resolve([_squad("a", [feature], karavel)], {"sprint": 10, "active_tools": ["notion"]}, _rules_without_streak())
	var meridia_report := _resolve([_squad("a", [feature], meridia)], {"sprint": 10, "active_tools": ["notion"]}, _rules_without_streak())
	var karavel_lever := float(karavel_report.get("global", {}).get("lever", 0.0))
	var meridia_lever := float(meridia_report.get("global", {}).get("lever", 0.0))
	_assert_true(karavel_lever > 1.0, "Notion doit rester un Levier positif sur le roster réel de Karavel (obtenu %s)." % karavel_lever)
	_assert_true(meridia_lever < 1.0, "Notion doit devenir un Levier négatif sur le roster réel de Meridia (obtenu %s)." % meridia_lever)


func _company_roster(company_id: String) -> Array:
	for company in companies_data:
		if company.get("id", "") == company_id:
			var roster: Array = []
			for member in company.get("startingRoster", []):
				roster.append({
					"id": member.get("id", ""),
					"role": member.get("role", ""),
					"seniority": member.get("seniority", "junior"),
					"hiredSprint": 0,
				})
			return roster
	return []


## « Passage en Shape Up » est une carte réelle (rare, prérequis 2 seniors) :
## sa suppression du Levier lors de la migration depuis scoring.json en
## aurait fait la seule carte payante et slottée du catalogue à ne rendre
## aucun Levier — un piège pur. Le Levier hérité de scoring.json (juniors en
## binôme) est reporté tel quel sur la carte, sous son vrai nom cette fois
## (scoring.json l'étiquetait à tort « Pair programming »).
func _test_shape_up_lever() -> void:
	var feature := _traction_feature(1)
	var two_junior_devs := [
		{"id": "a", "role": "dev", "seniority": "junior", "hiredSprint": 0},
		{"id": "b", "role": "dev", "seniority": "junior", "hiredSprint": 0},
	]
	var report := _resolve([_squad("a", [feature], two_junior_devs)], {"active_tools": ["shape-up"]}, _rules_without_streak())
	_assert_equal(float(report.get("global", {}).get("lever", 0.0)), 1.32, "Shape Up doit valoir 2 x 0.08 x 2 (adoption) = 0.32 de Levier avec deux devs juniors.")
	_assert_true(_has_label_prefix(report.get("global", {}).get("lines", []), "Passage en Shape Up"), "La ligne de score doit porter le vrai nom de la carte, pas « Pair programming ».")

	var one_senior_dev := [{"id": "c", "role": "dev", "seniority": "senior", "hiredSprint": 0}]
	report = _resolve([_squad("a", [feature], one_senior_dev)], {"active_tools": ["shape-up"]}, _rules_without_streak())
	_assert_equal(float(report.get("global", {}).get("lever", 0.0)), 1.0, "Shape Up ne doit rien apporter sans dev junior au binôme.")


## Garde-fou générique : toute carte outil-process/methodologie-orga coûte
## des pièces et un slot (§7.1.1). Sans Levier par employé déclaré
## (perEmployee ou cumulative), elle serait un piège pur — l'incident corrigé
## ci-dessus sur Shape Up ne doit plus pouvoir se reproduire silencieusement.
func _test_every_tool_card_has_a_lever() -> void:
	for card in cards_data.get("cards", []):
		if card.get("family", "") in ["outil-process", "methodologie-orga"]:
			_assert_true(
				card.has("perEmployee") or card.has("cumulative") or card.has("leverMultiplier"),
				"La carte « %s » (%s) coûte de l'Impact et un slot mais ne déclare ni additif ni multiplicateur de Levier." % [card.get("id", ""), card.get("name", "")]
			)


## Issue #37 : les additifs sont tous résolus avant les multiplicateurs, deux
## x1,5 composent x2,25, et un compteur déclaré dans les données peut scaler
## sans branche d'id dans ScoreResolver.
func _test_lever_multipliers() -> void:
	var rules := _rules_without_streak()
	rules["local"]["organizationCombos"] = [
		{"id": "complet", "label": "Equipe complète", "icon": "🛡️", "leverMultiplier": 1.5, "condition": {"roles": {"pm": 1, "dev": 1, "designer": 1, "ops": 1}}},
		{"id": "structure", "label": "Structure dense", "icon": "🎓", "leverMultiplier": 1.5, "condition": {"rosterMinimum": 4}},
	]
	rules["global"]["strategies"]["multiplicative-test"] = {"lever": 0.5, "leverMultiplier": 1.4, "icon": "🚀", "label": "Stratégie test"}
	var roster := [
		{"id": "pm", "role": "pm", "seniority": "senior", "hiredSprint": 0},
		{"id": "dev", "role": "dev", "seniority": "senior", "hiredSprint": 0},
		{"id": "design", "role": "designer", "seniority": "senior", "hiredSprint": 0},
		{"id": "ops", "role": "ops", "seniority": "senior", "hiredSprint": 0},
	]
	var report := _resolve([_squad("a", [_traction_feature(1)], roster)], {"strategy_ids": ["multiplicative-test"]}, rules)
	var local: Dictionary = report.get("squads", [])[0]
	_assert_equal(float(local.get("local_additive_lever", 0.0)), 1.05, "Le PM doit rester dans la base additive avant les combos.")
	_assert_equal(float(local.get("local_lever_multiplier", 0.0)), 2.25, "Deux multiplicateurs locaux x1,5 doivent composer x2,25.")
	_assert_equal(float(local.get("local_lever", 0.0)), 2.3625000000000003, "La base locale 1,05 doit ensuite recevoir x2,25.")
	_assert_equal(float(report.get("global", {}).get("additive_lever", 0.0)), 1.5, "L'additif de stratégie doit construire la base globale.")
	_assert_equal(float(report.get("global", {}).get("lever_multiplier", 0.0)), 1.4, "Le multiplicateur de stratégie doit rester une couche séparée.")
	_assert_equal(_line_type_count(local.get("lines", []), "lever_multiplier"), 2, "La chaîne locale doit exposer chaque multiplicateur séparément.")
	_assert_equal(_line_type_count(report.get("global", {}).get("lines", []), "lever_multiplier"), 1, "La chaîne globale doit exposer le multiplicateur de stratégie.")

	var snapshot := {
		"squads": [_squad("a", [_traction_feature(1)])],
		"resources": {"moral": 60, "cynisme": 0, "dette-organisationnelle": 0},
		"active_tools": ["socle-technique-commun", "notion", "jira"],
	}
	report = ScoreResolverScript.resolve(snapshot, {"scoring": _rules_without_streak(), "hidden_traits": hidden_traits_data, "cards": cards_data})
	_assert_equal(float(report.get("global", {}).get("lever_multiplier", 0.0)), pow(1.6, 3), "Le compteur active_tools doit appliquer x1,6 par outil depuis les données.")
	_assert_true(_has_label_prefix(report.get("global", {}).get("lines", []), "Socle technique commun · 3 outils actifs (3 max.)"), "Le rapport doit expliquer le compteur qui fait scaler le multiplicateur.")
	snapshot["active_tools"].append("rice")
	report = ScoreResolverScript.resolve(snapshot, {"scoring": _rules_without_streak(), "hidden_traits": hidden_traits_data, "cards": cards_data})
	_assert_equal(float(report.get("global", {}).get("lever_multiplier", 0.0)), pow(1.6, 3), "maxCount doit borner la courbe du Socle au degré 3.")


func _test_streak_and_friction_rules() -> void:
	var feature := _traction_feature(25)
	var report := _resolve([_squad("a", [feature])], {"streak": 0})
	_assert_true(_has_label(report["squads"][0]["lines"], "Série de livraisons"), "Le premier sprint livre doit compter dans la serie.")
	_assert_equal(_step_for_label(report["squads"][0]["lines"], "Série de livraisons"), 2, "La serie appartient a l'etape Bonus de main.")
	_assert_true(_label_index(report["squads"][0]["lines"], "Série de livraisons") < _label_index(report["squads"][0]["lines"], "Sous-total"), "Le rapport doit placer la serie avant le sous-total d'equipe.")
	_assert_equal(int(report.get("next_streak", -1)), 1, "Le premier sprint livre doit faire passer la serie a 1.")
	report = _resolve([_squad("a", [])], {"streak": 4})
	_assert_equal(int(report.get("next_streak", -1)), 0, "Un sprint vide doit casser la serie.")
	report = _resolve([_squad("a", [feature], [], 20, 21)], {"streak": 4})
	_assert_equal(int(report.get("next_streak", -1)), 0, "La surchauffe doit casser la serie.")

	var rules := _rules_without_streak()
	report = _resolve([_squad("a", [feature])], {"resources": {"cynisme": 70, "dette-organisationnelle": 70, "moral": 60}}, rules)
	_assert_equal(int(report.get("global", {}).get("impact", -1)), 60, "Dette 70 et Cynisme 70 doivent faire 100 x 0.8 x 0.75 = 60.")
	report = _resolve([_squad("a", [feature], [], 20, 21)], {"resources": {"cynisme": 70, "dette-organisationnelle": 70, "moral": 60}}, rules)
	_assert_equal(int(report.get("global", {}).get("impact", -1)), 36, "La surchauffe doit ensuite multiplier l'Impact par 0.6.")


func _test_quarter_visible_board_and_technical_audit() -> void:
	var rules := _rules_without_streak()
	var invisible_feature := {"id": "internal-cleanup", "name": "Nettoyage interne", "costPoints": 10, "clients": 0, "risk": 0, "quickWin": false, "tags": ["tech"]}
	var epic := {"id": "epic-visible", "name": "Epic utile", "epic": true, "costPoints": 10, "risk": 0}
	var report := _resolve([_squad("a", [invisible_feature, epic])], {"minimum_clients_for_traction": 1}, rules)
	_assert_equal(float(report.get("squads", [])[0].get("traction", -1.0)), 60.0, "Le board visible doit annuler la Traction des features qui n'amenent aucun client, jamais celle des epics.")

	var feature := _traction_feature(25)
	report = _resolve([_squad("a", [feature])], {"resources": {"cynisme": 0, "dette-organisationnelle": 70, "moral": 60}, "debt_friction_scale": 2.0}, rules)
	_assert_equal(int(report.get("global", {}).get("impact", -1)), 60, "L'audit technique doit doubler la pente de Dette : 100 x (1 - 2 x 30 / 150) = 60.")


func _test_moral_cap_and_ops_snapshot() -> void:
	var feature := _traction_feature(25)
	var rules := _rules_without_streak()
	var report := _resolve([_squad("a", [feature])], {"resources": {"moral": 20}, "strategy_ids": ["arreter-de-communiquer"], "product_tier": 5}, rules)
	_assert_equal(float(report.get("global", {}).get("effective_lever", 0.0)), 1.5, "Moral bas doit plafonner le Levier total effectif a 1.5 en N=1.")
	_assert_equal(int(report.get("global", {}).get("impact", -1)), 150, "Le plafond Moral doit etre applique a la formule complete, pas seulement au levier global.")

	var half_feature := _traction_feature(12)
	report = _resolve([_squad("a", [feature]), _squad("b", [half_feature])], {"resources": {"moral": 20}, "strategy_ids": ["arreter-de-communiquer"], "product_tier": 5}, rules)
	_assert_equal(int(report.get("global", {}).get("impact", -1)), 222, "Moral bas doit plafonner la moyenne ponderee des leviers a N=2.")

	var ops := [{"id": "ops", "role": "ops", "seniority": "senior", "hiredSprint": 0}]
	report = _resolve([_squad("a", [feature], ops)], {"resources": {"moral": 60, "dette-organisationnelle": 70}}, rules)
	_assert_equal(int(report.get("global", {}).get("impact", -1)), 80, "Le resolver ne doit pas reappliquer le relief Dette d'Ops deja refleche dans le snapshot.")


## 💰 L'economie client (docs/spec-clients-revenue.md §2). Les assertions
## portent sur la RELATION entre ce qui est livre et ce que la population
## devient — jamais sur un tirage.
func _test_client_economy() -> void:
	var rules := _rules_without_streak()
	var segments := [
		{"id": "gratuits", "role": "entry", "label": "gratuits", "start": 1000, "price": 0.0, "unitCost": 0.01, "churn": 0.1, "clientsPerPoint": 20},
		{"id": "payants", "role": "paying", "label": "payants", "start": 100, "price": 0.5, "unitCost": 0.04, "churn": 0.05, "clientsPerPoint": 2},
	]
	var base := {
		"segments": segments,
		"clients": {"gratuits": 1000.0, "payants": 100.0},
		"price_scale": 1.0,
		"wallet": 0,
		"resources": {"moral": 60, "dette-organisationnelle": 0},
		"support_teams": {"sales": 3, "pmm": 3, "csm": 3},
	}

	# Sans livraison : la population ne fait que churner.
	var idle := _resolve([_squad("a", [])], base, rules)
	var idle_clients: Dictionary = idle.get("conversion", {}).get("clients", {}).get("after", {})
	_assert_equal(float(idle_clients.get("gratuits", 0.0)), 900.0, "Sans livraison, 1000 gratuits a 10 % de churn doivent tomber a 900.")
	_assert_equal(float(idle_clients.get("payants", 0.0)), 95.0, "Sans livraison, 100 payants a 5 % de churn doivent tomber a 95.")
	_assert_equal(float(idle.get("conversion", {}).get("revenue", {}).get("in", 0.0)), 47.5, "Le Revenue encaisse est la population APRES mouvement x le prix du segment.")

	# Une livraison a effet client 3 amene 3 x clientsPerPoint par segment.
	var feature := {"id": "payante", "name": "Feature payante", "costPoints": 1, "clients": 3, "risk": 0, "quickWin": false, "tags": ["growth"]}
	var shipped := _resolve([_squad("a", [feature])], base, rules)
	var shipped_clients: Dictionary = shipped.get("conversion", {}).get("clients", {}).get("after", {})
	_assert_equal(float(shipped_clients.get("gratuits", 0.0)), 960.0, "Une feature a effet client 3 doit amener 3 x 20 = 60 gratuits.")
	_assert_equal(float(shipped_clients.get("payants", 0.0)), 101.0, "La meme feature doit amener 3 x 2 = 6 payants.")

	# Une feature a effet client negatif fait PARTIR des clients : la meme
	# regle dans l'autre sens (une regle a double consequence se teste dans
	# les deux sens — CLAUDE.md).
	var toxic := {"id": "toxique", "name": "Feature qui fait fuir", "costPoints": 1, "clients": -3, "risk": 0, "quickWin": false, "tags": ["growth"]}
	var lost: Dictionary = _resolve([_squad("a", [toxic])], base, rules).get("conversion", {}).get("clients", {}).get("after", {})
	_assert_equal(float(lost.get("gratuits", 0.0)), 840.0, "Une feature a effet client -3 doit faire partir 60 gratuits en plus du churn.")
	_assert_true(float(lost.get("payants", 0.0)) < float(idle_clients.get("payants", 0.0)),
		"Elle doit aussi coûter des payants, sinon l'effet client n'a qu'un sens.")

	# 💔 Le produit qui se degrade : churn plancher, tous segments confondus.
	var crisis_base := base.duplicate(true)
	crisis_base["resources"] = {"moral": 20, "dette-organisationnelle": 70}
	var crisis: Dictionary = _resolve([_squad("a", [])], crisis_base, rules).get("conversion", {}).get("clients", {}).get("after", {})
	_assert_equal(float(crisis.get("payants", 0.0)), 85.0, "Moral bas et Dette haute doivent monter le churn des payants au plancher de 15 %.")

	# 🎧 Le CSM agit sur le churn, 💼 le Sales sur les arrivees — chacun sur
	# son cote, jamais sur les deux.
	var weak_csm := base.duplicate(true)
	weak_csm["support_teams"] = {"sales": 3, "pmm": 3, "csm": 1}
	var weak: Dictionary = _resolve([_squad("a", [])], weak_csm, rules).get("conversion", {}).get("clients", {}).get("after", {})
	_assert_true(float(weak.get("gratuits", 0.0)) < float(idle_clients.get("gratuits", 0.0)),
		"Un CSM faible doit faire partir plus de clients.")
	var strong_sales := base.duplicate(true)
	strong_sales["support_teams"] = {"sales": 5, "pmm": 3, "csm": 3}
	var strong: Dictionary = _resolve([_squad("a", [feature])], strong_sales, rules).get("conversion", {}).get("clients", {}).get("after", {})
	_assert_true(float(strong.get("payants", 0.0)) > float(shipped_clients.get("payants", 0.0)),
		"Un Sales fort doit amener plus de clients a livraison identique.")

	# L'echelle de prix du scenario (§4.0.1) frappe le prix, jamais la
	# population : deux epoques, deux caisses, une seule courbe de clients.
	var rich_era := base.duplicate(true)
	rich_era["price_scale"] = 2.0
	var rich := _resolve([_squad("a", [])], rich_era, rules)
	_assert_equal(float(rich.get("conversion", {}).get("revenue", {}).get("in", 0.0)), 95.0, "priceScale 2 doit doubler ce que les clients paient.")
	_assert_equal(float(rich.get("conversion", {}).get("clients", {}).get("after", {}).get("gratuits", 0.0)), 900.0, "priceScale ne doit jamais toucher la population.")


## 🚨 Le critere de recette 5 de l'issue #42, verifie mecaniquement plutot que
## relu : AUCUNE regle ne doit fabriquer du 💰 Revenue a partir de l'Impact
## (spec-impact-monnaie.md §3.8). Le test fait varier l'Impact du simple au
## quadruple, a livraison et population IDENTIQUES, et exige que la caisse ne
## bouge pas. C'est le garde-fou qui manquait quand la fuite s'est installee.
func _test_no_revenue_comes_from_impact() -> void:
	var rules := _rules_without_streak()
	var segments := [{"id": "payants", "role": "paying", "label": "payants", "start": 100, "price": 0.5, "unitCost": 0.0, "churn": 0.0, "clientsPerPoint": 2}]
	var base := {
		"segments": segments,
		"clients": {"payants": 100.0},
		"price_scale": 1.0,
		"resources": {"moral": 60, "dette-organisationnelle": 0},
		"support_teams": {"sales": 3, "pmm": 3, "csm": 3},
	}
	var small := _resolve([_squad("a", [{"id": "f", "name": "f", "costPoints": 1, "clients": 1, "risk": 0, "quickWin": false, "tags": ["t"]}])], base, rules)
	var huge_base := base.duplicate(true)
	huge_base["product_tier"] = 5
	var huge := _resolve([_squad("a", [{"id": "f", "name": "f", "costPoints": 1, "clients": 1, "risk": 0, "quickWin": false, "tags": ["t"]}])], huge_base, rules)

	_assert_true(int(huge.get("global", {}).get("impact", 0)) > int(small.get("global", {}).get("impact", 0)),
		"Le cas de test doit bien produire deux Impacts differents, sinon il ne teste rien.")
	_assert_equal(float(huge.get("conversion", {}).get("revenue", {}).get("in", 0.0)),
		float(small.get("conversion", {}).get("revenue", {}).get("in", 0.0)),
		"Un Impact multiplie ne doit RIEN changer a ce que les clients paient (spec-impact-monnaie §3.8).")
	_assert_equal(float(huge.get("conversion", {}).get("clients", {}).get("after", {}).get("payants", 0.0)),
		float(small.get("conversion", {}).get("clients", {}).get("after", {}).get("payants", 0.0)),
		"Il ne doit rien changer non plus a la population : ce qui amene des clients, c'est ce qu'on livre.")
	_assert_true(not huge.get("conversion", {}).has("recurring_revenue"),
		"Le rapport ne doit plus exposer de base d'abonnements : le stock, ce sont les clients.")
	_assert_true(not huge.get("conversion", {}).get("resource_deltas", {}).has("reputation-produit"),
		"La Reputation produit ne doit plus etre alimentee par l'Impact (spec-clients-revenue §5.1.1).")


## Lot 4, spec §9.4 — critere de recette de l'issue #17 : deux runs sur la
## meme entreprise produisent deux organisations differentes, et Meridia /
## Karavel doivent diverger visiblement sur la conversion. Les taux
## eux-memes (salesMultipliers/pmmMultipliers/csmMultipliers) existaient
## deja avant ce lot ; ce test verifie que companies.json les alimente
## reellement, pas seulement que ScoreResolver sait les lire.
func _test_support_team_rates_differ_by_company() -> void:
	var meridia := _company("meridia-corp")
	var karavel := _company("karavel-scaleup")
	_assert_equal(meridia.get("supportTeams", {}), {"sales": 4.0, "pmm": 2.0, "csm": 3.0},
		"Meridia doit declarer supportTeams Sales 4 / PMM 2 / CSM 3 (spec 9.4).")
	_assert_equal(karavel.get("supportTeams", {}), {"sales": 2.0, "pmm": 4.0, "csm": 1.0},
		"Karavel doit declarer supportTeams Sales 2 / PMM 4 / CSM 1 (spec 9.4).")

	var feature := {"id": "f", "name": "f", "costPoints": 25, "clients": 3, "risk": 0, "quickWin": false, "tags": ["t"]}
	var rules := _rules_without_streak()
	var segments := [{"id": "payants", "role": "paying", "label": "payants", "start": 100, "price": 0.5, "unitCost": 0.0, "churn": 0.05, "clientsPerPoint": 2}]
	var economy := {"segments": segments, "clients": {"payants": 100.0}, "price_scale": 1.0}
	var meridia_snapshot := economy.duplicate(true)
	meridia_snapshot["support_teams"] = meridia.get("supportTeams", {})
	var karavel_snapshot := economy.duplicate(true)
	karavel_snapshot["support_teams"] = karavel.get("supportTeams", {})
	var meridia_report := _resolve([_squad("a", [feature])], meridia_snapshot, rules)
	var karavel_report := _resolve([_squad("a", [feature])], karavel_snapshot, rules)

	var meridia_rates: Dictionary = meridia_report.get("conversion", {}).get("teamRates", {})
	var karavel_rates: Dictionary = karavel_report.get("conversion", {}).get("teamRates", {})
	_assert_equal(float(meridia_rates.get("sales", {}).get("multiplier", 0.0)), 1.2, "Meridia (Sales niveau 4) doit amener 1.2x plus de clients.")
	_assert_equal(float(karavel_rates.get("sales", {}).get("multiplier", 0.0)), 0.8, "Karavel (Sales niveau 2) doit en amener 0.8x.")
	_assert_equal(float(meridia_rates.get("pmm", {}).get("multiplier", 0.0)), 0.8, "Meridia (PMM niveau 2) doit amplifier la Reputation produit a x0.8.")
	_assert_equal(float(karavel_rates.get("pmm", {}).get("multiplier", 0.0)), 1.2, "Karavel (PMM niveau 4) doit l'amplifier a x1.2.")
	_assert_equal(float(meridia_rates.get("csm", {}).get("multiplier", 0.0)), 1.0, "Meridia (CSM niveau 3) doit garder un churn neutre x1.0.")
	_assert_equal(float(karavel_rates.get("csm", {}).get("multiplier", 0.0)), 1.4, "Karavel (CSM niveau 1) doit subir un churn x1.4 (support faible).")

	var meridia_clients := float(meridia_report.get("conversion", {}).get("clients", {}).get("after", {}).get("payants", 0.0))
	var karavel_clients := float(karavel_report.get("conversion", {}).get("clients", {}).get("after", {}).get("payants", 0.0))
	_assert_true(meridia_clients > karavel_clients,
		"A livraison et population de depart identiques, Meridia (%s clients) doit finir devant Karavel (%s) — Sales fort et churn maitrise contre l'inverse. C'est le critere de recette de l'issue #17." % [meridia_clients, karavel_clients])
	_assert_true(SprintStateModels.has("grands-comptes") and SprintStateModels.has("freemium-volume"),
		"Les deux modeles economiques doivent exister dans balance.json.")
	_assert_true(_company("meridia-corp").get("businessModel", "") != _company("karavel-scaleup").get("businessModel", ""),
		"Meridia et Karavel doivent jouer deux modeles economiques differents : c'est la ou la divergence se voit en jeu.")


func _company(company_id: String) -> Dictionary:
	for company in companies_data:
		if company.get("id", "") == company_id:
			return company
	return {}


func _test_multi_squad_contract() -> void:
	var rules := _rules_without_streak()
	var excel := {"id": "excel", "name": "Export Excel", "costPoints": 1, "clients": 2, "risk": 0, "quickWin": false, "tags": ["reporting"]}
	var sso := {"id": "sso", "name": "SSO", "costPoints": 3, "clients": 3, "risk": 0, "quickWin": false, "tags": ["enterprise"]}
	var report := _resolve([_squad("alpha", [excel]), _squad("beta", [sso])], {}, rules)
	_assert_equal(report.get("squads", []).size(), 2, "Le resolver doit conserver un sous-rapport par equipe.")
	_assert_equal(int(report.get("global", {}).get("impact", -1)), 16, "Deux sous-totaux 4 et 12 doivent etre sommes, pas moyennes.")
	for squad_report in report.get("squads", []):
		_assert_true(_has_label(squad_report.get("lines", []), "Sous-total"), "Chaque equipe doit exposer son sous-total dans le rapport anime.")
		for line in squad_report.get("lines", []):
			_assert_true(line.get("scope", "") == "local" and line.has("squad_id"), "Chaque ligne locale doit porter son squad_id.")
			_assert_false("squad" in String(line.get("label", "")).to_lower(), "Le libelle joueur d'une ligne locale ne doit jamais contenir le mot squad.")


func _test_visible_trait_integrity() -> void:
	var rules: Dictionary = scoring_data.get("visibleTraitRules", {})
	var ids: Array = []
	var unique_ids: Dictionary = {}
	for candidate in candidates_data:
		ids.append(candidate.get("visible_trait_id", ""))
	for company in companies_data:
		for member in company.get("startingRoster", []):
			ids.append(member.get("visible_trait_id", ""))
	for trait_id in ids:
		_assert_true(trait_id != "" and rules.has(trait_id), "Le visible_trait_id '%s' doit avoir une regle de score." % trait_id)
		if trait_id != "":
			unique_ids[trait_id] = true
	for trait_id in rules.keys():
		_assert_true(unique_ids.has(trait_id), "La regle de trait visible '%s' ne doit pas etre orpheline." % trait_id)
	_assert_equal(unique_ids.size(), rules.size(), "Chaque trait visible unique du contenu doit correspondre a une seule regle data-driven.")


func _resolve(squads: Array, extra: Dictionary = {}, rules: Dictionary = {}) -> Dictionary:
	var snapshot := {
		"squads": squads,
		"resources": {"moral": 60, "cynisme": 0, "dette-organisationnelle": 0},
		"business_model_id": "saas-mrr",
		"support_teams": {"sales": 3, "pmm": 3, "csm": 3},
	}
	for key in extra.keys():
		snapshot[key] = extra[key]
	var scoring: Dictionary = scoring_data if rules.is_empty() else rules
	return ScoreResolverScript.resolve(snapshot, {"scoring": scoring, "hidden_traits": hidden_traits_data, "cards": cards_data})


func _rules_without_streak() -> Dictionary:
	var rules: Dictionary = scoring_data.duplicate(true)
	rules["streak"]["leverPerSprint"] = 0.0
	rules["traction"]["handBonuses"]["perfectSprint"]["capacityTolerance"] = -1
	rules["traction"]["handBonuses"]["focus"]["minimumDelivered"] = 99
	rules["traction"]["handBonuses"]["bundle"]["minimumDelivered"] = 99
	rules["traction"]["handBonuses"]["completedEpic"]["multiplier"] = 1.0
	return rules


func _squad(id: String, delivered: Array, roster: Array = [], capacity: int = 25, spent_points: int = 0) -> Dictionary:
	return {"id": id, "delivered": delivered, "roster": roster, "capacity": capacity, "spent_points": spent_points}


func _traction_feature(points: int) -> Dictionary:
	return {"id": "traction-%d" % points, "name": "Feature traction", "costPoints": points, "clients": 0, "risk": 0, "quickWin": false, "tags": ["test"]}


func _first_local_traction(report: Dictionary) -> float:
	for line in report.get("squads", [])[0].get("lines", []):
		if line.get("step", 0) == 1 and line.get("type", "") == "traction_add":
			return float(line.get("value", 0.0))
	return 0.0


func _has_label(lines: Array, label: String) -> bool:
	for line in lines:
		if line.get("label", "") == label:
			return true
	return false


func _has_label_prefix(lines: Array, prefix: String) -> bool:
	for line in lines:
		if String(line.get("label", "")).begins_with(prefix):
			return true
	return false


func _label_count(lines: Array, label: String) -> int:
	var count := 0
	for line in lines:
		if line.get("label", "") == label:
			count += 1
	return count


func _line_type_count(lines: Array, line_type: String) -> int:
	var count := 0
	for line in lines:
		if line.get("type", "") == line_type:
			count += 1
	return count


func _step_for_label(lines: Array, label: String) -> int:
	for line in lines:
		if line.get("label", "") == label:
			return int(line.get("step", 0))
	return -1


func _label_index(lines: Array, label: String) -> int:
	for index in lines.size():
		if lines[index].get("label", "") == label:
			return index
	return -1


func _load_data(file_name: String) -> Dictionary:
	var file := FileAccess.open("res://../data/" + file_name, FileAccess.READ)
	if file == null:
		_fail("Impossible de charger %s." % file_name)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("JSON invalide dans %s." % file_name)
		return {}
	return parsed


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_fail("%s (obtenu %s, attendu %s)" % [message, actual, expected])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)


func _assert_false(value: bool, message: String) -> void:
	if value:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error(message)
