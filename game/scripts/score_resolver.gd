class_name ScoreResolver
extends RefCounted
## Moteur de score pur. Le snapshot et les tables de donnees sont ses seules
## entrees; ni SprintState ni GameData ne sont lus ou modifies ici.


static func resolve(snapshot: Dictionary, tables: Dictionary = {}) -> Dictionary:
	var rules: Dictionary = tables.get("scoring", snapshot.get("scoring", {}))
	var hidden_traits: Dictionary = tables.get("hidden_traits", snapshot.get("hidden_traits", {}))
	var cards: Dictionary = tables.get("cards", snapshot.get("cards", {}))
	var resources: Dictionary = snapshot.get("resources", snapshot.get("resource_values", {}))
	var squads: Array = snapshot.get("squads", [])
	if squads.is_empty():
		squads = [{
			"id": "equipe-principale",
			"roster": snapshot.get("roster", []),
			"delivered": snapshot.get("delivered", []),
			"capacity": snapshot.get("capacity", 0),
			"spent_points": snapshot.get("spent_points", 0),
		}]

	var strategy_ids := _ids_from(snapshot.get("strategy_ids", snapshot.get("strategies", [])))
	var global_rules: Dictionary = rules.get("global", {})
	var strategy_rules: Dictionary = global_rules.get("strategies", {})
	var overheated := _is_overheated(snapshot, squads)
	var squad_reports: Array = []
	var all_roster: Array = []
	var local_total := 0.0
	var delivered_count := 0
	var traction_total := 0.0

	for squad in squads:
		var squad_report := _resolve_squad(squad, snapshot, rules, hidden_traits, strategy_ids, strategy_rules, overheated)
		squad_reports.append(squad_report)
		local_total += float(squad_report.get("subtotal", 0.0))
		delivered_count += int(squad_report.get("delivered_count", 0))
		traction_total += float(squad_report.get("traction", 0.0))
		for member in squad.get("roster", []):
			all_roster.append(member)

	var global_lines: Array = []
	var global_lever := float(global_rules.get("baseLever", 1.0))
	var global_traction_multiplier := 1.0
	var step := 4

	var active_tools := _active_tool_entries(snapshot)
	for tool_entry in active_tools:
		var tool_id: String = tool_entry.get("id", "")
		var card := _find_card(cards, tool_id)
		if not _card_has_lever(card):
			continue
		var tool_value := _tool_lever(card, tool_entry, all_roster, snapshot, resources, hidden_traits)
		var tool_before := global_lever
		global_lever += tool_value
		global_lines.append(_line(step, "global", card.get("icon", "🛠️"), _tool_label(card, tool_entry, all_roster, snapshot, hidden_traits), "lever_add", tool_value, tool_before, global_lever))

	step = 5
	for strategy_id in strategy_ids:
		var strategy: Dictionary = strategy_rules.get(strategy_id, {})
		if strategy.is_empty():
			continue
		var strategy_label: String = strategy.get("label", strategy_id)
		var strategy_icon: String = strategy.get("icon", "🧭")
		var traction_multiplier := float(strategy.get("tractionMultiplier", 1.0))
		if not is_equal_approx(traction_multiplier, 1.0):
			var traction_before := global_traction_multiplier
			global_traction_multiplier *= traction_multiplier
			global_lines.append(_line(step, "global", strategy_icon, strategy_label, "traction_multiplier", traction_multiplier, traction_before, global_traction_multiplier))
		var strategy_lever := float(strategy.get("lever", 0.0))
		if not is_zero_approx(strategy_lever):
			var strategy_before := global_lever
			global_lever += strategy_lever
			global_lines.append(_line(step, "global", strategy_icon, strategy_label, "lever_add", strategy_lever, strategy_before, global_lever))
		var tier_lever := float(strategy.get("leverPerProductTier", 0.0)) * float(snapshot.get("product_tier", 0))
		if not is_zero_approx(tier_lever):
			var tier_before := global_lever
			global_lever += tier_lever
			global_lines.append(_line(step, "global", strategy_icon, strategy_label, "lever_add", tier_lever, tier_before, global_lever))

	step = 6
	for practice_id in _ids_from(snapshot.get("owned_practices", snapshot.get("practices", []))):
		var practice: Dictionary = global_rules.get("practices", {}).get(practice_id, {})
		if practice.is_empty():
			continue
		var practice_lever := float(practice.get("lever", 0.0))
		if is_zero_approx(practice_lever):
			continue
		var practice_before := global_lever
		global_lever += practice_lever
		global_lines.append(_line(step, "global", practice.get("icon", "🧠"), practice.get("label", practice_id), "lever_add", practice_lever, practice_before, global_lever))

	var tier_rule: Dictionary = global_rules.get("productTier", {})
	var product_tier := int(snapshot.get("product_tier", 0))
	var product_tier_lever := float(tier_rule.get("leverPerTier", 0.0)) * product_tier
	if not is_zero_approx(product_tier_lever):
		var product_tier_before := global_lever
		global_lever += product_tier_lever
		global_lines.append(_line(step, "global", tier_rule.get("icon", "🏗️"), tier_rule.get("label", "Palier produit"), "lever_add", product_tier_lever, product_tier_before, global_lever))

	var inter_squad := _inter_squad_lever(squads, active_tools, global_rules.get("interSquadCombos", {}))
	if not inter_squad.is_empty():
		var inter_before := global_lever
		global_lever += float(inter_squad.get("lever", 0.0))
		global_lines.append(_line(step, "global", inter_squad.get("icon", "🏛️"), inter_squad.get("label", "Organisation"), "lever_add", inter_squad.get("lever", 0.0), inter_before, global_lever))

	var friction_rules: Dictionary = rules.get("frictions", {})
	var moral_cap: Dictionary = friction_rules.get("moralCap", {})
	var moral: float = float(resources.get(moral_cap.get("resource", "moral"), 100.0))
	var weighted_local_lever: float = local_total / traction_total if traction_total > 0.0 else 0.0
	var effective_lever: float = weighted_local_lever * global_lever
	var moral_factor: float = 1.0
	if not moral_cap.is_empty() and moral < float(moral_cap.get("threshold", 0)):
		var capped_lever: float = min(effective_lever, float(moral_cap.get("maxLever", effective_lever)))
		if not is_equal_approx(capped_lever, effective_lever):
			moral_factor = capped_lever / effective_lever
			global_lines.append(_line(7, "global", moral_cap.get("icon", "💔"), moral_cap.get("label", "Moral au plancher"), "total_lever_cap", capped_lever, effective_lever, capped_lever))
			effective_lever = capped_lever

	var before_frictions := local_total * global_traction_multiplier * global_lever * moral_factor
	var resolved_impact := before_frictions
	resolved_impact = _apply_resource_friction(resolved_impact, global_lines, friction_rules.get("cynisme", {}), resources)
	resolved_impact = _apply_resource_friction(resolved_impact, global_lines, friction_rules.get("dette", {}), resources, float(snapshot.get("debt_friction_scale", 1.0)))
	var overheat_rule: Dictionary = friction_rules.get("overheat", {})
	if overheated and not overheat_rule.is_empty():
		var overheat_before := resolved_impact
		var overheat_multiplier := float(overheat_rule.get("multiplier", 1.0))
		resolved_impact *= overheat_multiplier
		global_lines.append(_line(7, "global", overheat_rule.get("icon", "🔥"), overheat_rule.get("label", "Surchauffe"), "impact_multiplier", overheat_multiplier, overheat_before, resolved_impact))

	var impact := int(floor(max(0.0, resolved_impact)))
	global_lines.append(_line(8, "global", "💥", "Impact", "impact", impact, resolved_impact, impact))
	var conversion := _resolve_conversion(snapshot, rules, resources, impact, strategy_ids, strategy_rules, _quick_win_budget(squad_reports))
	for conversion_line in conversion.get("lines", []):
		global_lines.append(conversion_line)

	var next_streak := 0
	if delivered_count > 0 and not overheated:
		next_streak = int(snapshot.get("streak", 0)) + 1

	return {
		"version": int(rules.get("version", 1)),
		"squads": squad_reports,
		"global": {
			"lines": global_lines,
			"pre_friction": before_frictions,
			"lever": global_lever,
			"effective_lever": effective_lever,
			"impact": impact,
			"unrounded_impact": resolved_impact,
		},
		"conversion": conversion,
		"next_streak": next_streak,
	}


static func _resolve_squad(squad: Dictionary, snapshot: Dictionary, rules: Dictionary, hidden_traits: Dictionary, strategy_ids: Array, strategy_rules: Dictionary, overheated: bool) -> Dictionary:
	var squad_id: String = squad.get("id", "equipe-principale")
	var lines: Array = []
	var delivered := _completed_deliveries(squad.get("delivered", squad.get("delivered_items", [])))
	var traction := 0.0
	var feature_rule: Dictionary = rules.get("traction", {}).get("feature", {})
	var epic_rule: Dictionary = rules.get("traction", {}).get("epic", {})

	for item in delivered:
		var before := traction
		var item_traction := _item_traction(item, feature_rule, epic_rule, strategy_ids, strategy_rules, snapshot)
		traction += item_traction
		var item_icon: String = item.get("icon", "📦" if bool(item.get("epic", false)) else "📊")
		lines.append(_line(1, "local", item_icon, item.get("name", item.get("id", "Livraison")), "traction_add", item_traction, before, traction, squad_id))

	var bonuses: Dictionary = rules.get("traction", {}).get("handBonuses", {})
	var spent_points := int(squad.get("spent_points", squad.get("planned_points", _items_points(delivered))))
	var capacity := int(squad.get("capacity", 0))
	if _is_perfect_sprint(spent_points, capacity, bonuses.get("perfectSprint", {})):
		traction = _multiply_hand_bonus(lines, squad_id, traction, bonuses.get("perfectSprint", {}))
	if _has_focus(delivered, bonuses.get("focus", {})):
		traction = _multiply_hand_bonus(lines, squad_id, traction, bonuses.get("focus", {}))
	if delivered.size() >= int(bonuses.get("bundle", {}).get("minimumDelivered", 9999)):
		traction = _add_hand_bonus(lines, squad_id, traction, bonuses.get("bundle", {}), "tractionBonus")
	if _has_completed_epic(delivered):
		traction = _multiply_hand_bonus(lines, squad_id, traction, bonuses.get("completedEpic", {}))
	var quick_win_budget := 0
	var quick_wins: Dictionary = bonuses.get("quickWins", {})
	if _quick_win_count(delivered) >= int(quick_wins.get("minimumDelivered", 9999)):
		quick_win_budget = int(quick_wins.get("budgetBonus", 0))
		lines.append(_line(2, "local", quick_wins.get("icon", "⚡"), quick_wins.get("label", "Quick wins"), "budget_add", quick_win_budget, 0, quick_win_budget, squad_id))

	var roster: Array = squad.get("roster", [])
	var local_rule: Dictionary = rules.get("local", {})
	var local_lever := float(local_rule.get("baseLever", 1.0))
	var streak_rule: Dictionary = rules.get("streak", {})
	var streak_lever := 0.0
	if not delivered.is_empty() and not overheated:
		streak_lever = min((float(snapshot.get("streak", 0)) + 1.0) * float(streak_rule.get("leverPerSprint", 0.0)), float(streak_rule.get("maxLever", 0.0)))
	if not is_zero_approx(streak_lever):
		var streak_before := local_lever
		local_lever += streak_lever
		lines.append(_line(2, "local", streak_rule.get("icon", "🔥"), streak_rule.get("label", "Série de livraisons"), "lever_add", streak_lever, streak_before, local_lever, squad_id))

	var role_rules: Dictionary = local_rule.get("roles", {})
	var designer_weight := _role_weight(roster, "designer", hidden_traits)
	var designer_rule: Dictionary = role_rules.get("designer", {})
	var designer_traction := designer_weight * delivered.size() * float(designer_rule.get("tractionPerDelivered", 0.0))
	if not is_zero_approx(designer_traction):
		var designer_before := traction
		traction += designer_traction
		lines.append(_line(3, "local", designer_rule.get("icon", "🎨"), designer_rule.get("label", "Designer"), "traction_add", designer_traction, designer_before, traction, squad_id))

	var pm_rule: Dictionary = role_rules.get("pm", {})
	var pm_lever: float = min(_role_weight(roster, "pm", hidden_traits) * float(pm_rule.get("leverPerMember", 0.0)), float(pm_rule.get("maxLever", 0.0)))
	if not is_zero_approx(pm_lever):
		var pm_before := local_lever
		local_lever += pm_lever
		lines.append(_line(3, "local", pm_rule.get("icon", "📋"), pm_rule.get("label", "PM"), "lever_add", pm_lever, pm_before, local_lever, squad_id))

	for combo in _active_local_combos(roster, snapshot, local_rule.get("organizationCombos", []), hidden_traits):
		var combo_before := local_lever
		var combo_lever := float(combo.get("lever", 0.0))
		local_lever += combo_lever
		lines.append(_line(3, "local", combo.get("icon", "✨"), combo.get("label", combo.get("id", "Combo")), "lever_add", combo_lever, combo_before, local_lever, squad_id))

	var visible_rules: Dictionary = rules.get("visibleTraitRules", {})
	for member in roster:
		var visible_rule: Dictionary = visible_rules.get(member.get("visible_trait_id", ""), {})
		if visible_rule.is_empty():
			continue
		var visible_effect := _visible_trait_effect(visible_rule, delivered)
		if visible_effect.is_empty():
			continue
		var visible_before := local_lever
		var visible_lever := float(visible_effect.get("lever", 0.0))
		local_lever += visible_lever
		lines.append(_line(3, "local", visible_rule.get("icon", "✨"), visible_effect.get("label", "Trait visible"), "lever_add", visible_lever, visible_before, local_lever, squad_id))

	for member in roster:
		var hidden_rule := _hidden_trait(member, hidden_traits)
		var score: Dictionary = hidden_rule.get("score", {})
		if score.get("kind", "") != "local_lever":
			continue
		var hidden_lever := float(score.get("value", 0.0))
		if is_zero_approx(hidden_lever):
			continue
		var hidden_before := local_lever
		local_lever += hidden_lever
		lines.append(_line(3, "local", hidden_rule.get("icon", "✨"), hidden_rule.get("name", "Trait caché"), "lever_add", hidden_lever, hidden_before, local_lever, squad_id))

	var subtotal := traction * local_lever
	lines.append(_line(3, "local", "📌", "Sous-total", "subtotal", subtotal, 0.0, subtotal, squad_id))

	return {
		"id": squad_id,
		"lines": lines,
		"traction": traction,
		"local_lever": local_lever,
		"subtotal": subtotal,
		"delivered_count": delivered.size(),
		"quick_win_budget": quick_win_budget,
	}


static func _item_traction(item: Dictionary, feature_rule: Dictionary, epic_rule: Dictionary, strategy_ids: Array, strategy_rules: Dictionary, snapshot: Dictionary) -> float:
	var result := 0.0
	if bool(item.get("epic", false)):
		result = float(item.get("costPoints", 0)) * float(epic_rule.get("pointsMultiplier", 0.0))
	else:
		if int(item.get("clientImpact", 0)) < int(snapshot.get("minimum_client_impact_for_traction", 0)):
			return 0.0
		result = float(item.get("costPoints", 0)) * float(feature_rule.get("pointsMultiplier", 0.0))
		result += float(item.get("clientImpact", 0)) * float(feature_rule.get("clientImpactMultiplier", 0.0))
	for strategy_id in strategy_ids:
		var strategy: Dictionary = strategy_rules.get(strategy_id, {})
		if strategy.is_empty():
			continue
		if bool(item.get("quickWin", false)) and strategy.has("quickWinTractionMultiplier"):
			result *= float(strategy.get("quickWinTractionMultiplier", 1.0))
		var condition: Dictionary = strategy.get("featureCondition", {})
		if not condition.is_empty() and float(item.get("roi", 0)) >= float(condition.get("roiMinimum", INF)):
			result *= float(strategy.get("featureTractionMultiplier", 1.0))
	return result


static func _completed_deliveries(entries: Array) -> Array:
	var completed: Array = []
	for entry in entries:
		if not entry is Dictionary:
			continue
		var item: Dictionary = entry.get("item", entry)
		if bool(item.get("epic", false)) and not bool(entry.get("completed", item.get("completed", true))):
			continue
		completed.append(item)
	return completed


static func _add_hand_bonus(lines: Array, squad_id: String, traction: float, bonus: Dictionary, key: String) -> float:
	var value := float(bonus.get(key, 0.0))
	var after := traction + value
	lines.append(_line(2, "local", bonus.get("icon", "✨"), bonus.get("label", "Bonus"), "traction_add", value, traction, after, squad_id))
	return after


static func _multiply_hand_bonus(lines: Array, squad_id: String, traction: float, bonus: Dictionary) -> float:
	var value := float(bonus.get("multiplier", 1.0))
	var after := traction * value
	lines.append(_line(2, "local", bonus.get("icon", "✨"), bonus.get("label", "Bonus"), "traction_multiplier", value, traction, after, squad_id))
	return after


static func _is_perfect_sprint(spent: int, capacity: int, bonus: Dictionary) -> bool:
	if spent <= 0 or capacity <= 0:
		return false
	return abs(spent - capacity) <= int(bonus.get("capacityTolerance", 0))


static func _has_focus(delivered: Array, bonus: Dictionary) -> bool:
	if delivered.size() < int(bonus.get("minimumDelivered", 2)):
		return false
	var shared: Dictionary = {}
	for tag in delivered[0].get("tags", []):
		shared[tag] = true
	for item_index in range(1, delivered.size()):
		var tags: Dictionary = {}
		for tag in delivered[item_index].get("tags", []):
			tags[tag] = true
		for tag in shared.keys():
			if not tags.has(tag):
				shared.erase(tag)
	return not shared.is_empty()


static func _has_completed_epic(delivered: Array) -> bool:
	for item in delivered:
		if bool(item.get("epic", false)):
			return true
	return false


static func _active_local_combos(roster: Array, snapshot: Dictionary, combos: Array, hidden_traits: Dictionary) -> Array:
	var active: Dictionary = {}
	for combo in combos:
		if _matches_combo(roster, snapshot, combo.get("condition", {}), hidden_traits):
			active[combo.get("id", "")] = combo
	for combo_id in active.keys():
		var replacement: String = active[combo_id].get("replaces", "")
		if replacement != "":
			active.erase(replacement)
	var ordered: Array = []
	for combo in combos:
		if active.has(combo.get("id", "")):
			ordered.append(combo)
	return ordered


static func _matches_combo(roster: Array, snapshot: Dictionary, condition: Dictionary, hidden_traits: Dictionary) -> bool:
	if roster.size() < int(condition.get("rosterMinimum", 0)):
		return false
	for role_id in condition.get("roles", {}).keys():
		var expected := float(condition["roles"][role_id])
		var actual := _role_weight(roster, role_id, hidden_traits)
		if expected == 0.0 and not is_zero_approx(actual):
			return false
		if expected > 0.0 and actual < expected:
			return false
	var same_role: Dictionary = condition.get("sameRoleSeniority", {})
	if not same_role.is_empty() and not _has_same_role_seniority(roster, same_role, hidden_traits):
		return false
	var recent: Dictionary = condition.get("recentHires", {})
	if not recent.is_empty() and _recent_hire_count(roster, snapshot, recent, hidden_traits) < float(recent.get("minimum", 0)):
		return false
	var old: Dictionary = condition.get("hiredAtOrBefore", {})
	if not old.is_empty() and _hired_at_or_before_count(roster, old, hidden_traits) < float(old.get("minimum", 0)):
		return false
	return true


static func _has_same_role_seniority(roster: Array, condition: Dictionary, hidden_traits: Dictionary) -> bool:
	var counts: Dictionary = {}
	for member in roster:
		if member.get("seniority", "") != condition.get("seniority", ""):
			continue
		var role_id: String = member.get("role", "")
		counts[role_id] = float(counts.get(role_id, 0.0)) + _employee_weight(member, hidden_traits)
	for count in counts.values():
		if float(count) >= float(condition.get("minimum", 0)):
			return true
	return false


static func _recent_hire_count(roster: Array, snapshot: Dictionary, condition: Dictionary, hidden_traits: Dictionary) -> float:
	var count := 0.0
	var sprint := int(snapshot.get("sprint", snapshot.get("sprint_number", 1)))
	for member in roster:
		var hired_sprint := int(member.get("hiredSprint", member.get("hired_sprint", 0)))
		if hired_sprint > 0 and sprint - hired_sprint < int(condition.get("withinSprints", 0)):
			count += _employee_weight(member, hidden_traits)
	return count


static func _hired_at_or_before_count(roster: Array, condition: Dictionary, hidden_traits: Dictionary) -> float:
	var count := 0.0
	for member in roster:
		if int(member.get("hiredSprint", member.get("hired_sprint", 0))) <= int(condition.get("sprint", 0)):
			count += _employee_weight(member, hidden_traits)
	return count


static func _visible_trait_effect(rule: Dictionary, delivered: Array) -> Dictionary:
	if rule.get("kind", "") == "always_local_lever":
		return {"lever": float(rule.get("lever", 0.0)), "label": rule.get("label", "Trait visible")}
	if rule.get("kind", "") != "risk_threshold_local_lever":
		return {}
	for item in delivered:
		if float(item.get("risk", 0)) >= float(rule.get("riskThreshold", INF)):
			return {"lever": float(rule.get("riskyLever", 0.0)), "label": rule.get("riskyLabel", "Trait visible")}
	return {"lever": float(rule.get("safeLever", 0.0)), "label": rule.get("safeLabel", "Trait visible")}


static func _hidden_trait(member: Dictionary, hidden_traits: Dictionary) -> Dictionary:
	if not bool(member.get("hiddenRevealed", member.get("hidden_revealed", true))):
		return {}
	var trait_id: String = member.get("hidden_trait", member.get("hidden_trait_id", ""))
	for hidden_trait in hidden_traits.get("traits", []):
		if hidden_trait.get("id", "") == trait_id:
			return hidden_trait
	return {}


static func _employee_weight(member: Dictionary, hidden_traits: Dictionary) -> float:
	var hidden_data: Dictionary = _hidden_trait(member, hidden_traits)
	var score: Dictionary = hidden_data.get("score", {})
	if score.get("kind", "") == "contribution_factor":
		return float(score.get("value", 1.0))
	return float(member.get("contribution_factor", 1.0))


static func _role_weight(roster: Array, role_id: String, hidden_traits: Dictionary) -> float:
	var total := 0.0
	for member in roster:
		if member.get("role", "") == role_id:
			total += _employee_weight(member, hidden_traits)
	return total


static func _active_tool_entries(snapshot: Dictionary) -> Array:
	var source: Variant = snapshot.get("active_tools", snapshot.get("tool_ids", []))
	var entries: Array = []
	if source is Dictionary:
		for tool_id in source.keys():
			var value: Variant = source[tool_id]
			var entry: Dictionary = value if value is Dictionary else {}
			entry = entry.duplicate()
			entry["id"] = entry.get("id", tool_id)
			entries.append(entry)
	elif source is Array:
		for value in source:
			if value is Dictionary:
				entries.append(value)
			else:
				entries.append({"id": value})
	return entries


static func _ids_from(source: Variant) -> Array:
	var ids: Array = []
	if source is Dictionary:
		for key in source.keys():
			ids.append(str(key))
	elif source is Array:
		for value in source:
			if value is Dictionary:
				ids.append(str(value.get("id", "")))
			else:
				ids.append(str(value))
	return ids.filter(func(id): return id != "")


## Un outil (family outil-process/methodologie-orga de cards.json) décrit son
## propre Levier — spec §7.1. Une carte sans `perEmployee` ni `cumulative`
## n'a pas de Levier par employé : elle ne pèse que via les combos de
## composition (local.organizationCombos) — un cas prévu par le moteur pour
## une carte future, mais qu'aucune carte du catalogue actuel n'utilise
## (score_resolver_cases.gd → _test_every_tool_card_has_a_lever le garantit).
## C'est la même carte, junior ou senior, tirée sur n'importe quelle
## entreprise : rien ici ne branche sur un id d'entreprise, seul le roster
## réel change le résultat (§7.1, "Notion sur Karavel / Notion sur Meridia").
static func _card_has_lever(card: Dictionary) -> bool:
	return card.has("perEmployee") or card.has("cumulative")


static func _tool_lever(card: Dictionary, entry: Dictionary, roster: Array, snapshot: Dictionary, resources: Dictionary, hidden_traits: Dictionary) -> float:
	var eligible := _matching_employee_count(roster, card.get("eligibility", {}), snapshot, hidden_traits)
	var result := eligible * float(card.get("perEmployee", 0.0))
	var refractory_rule: Dictionary = card.get("refractory", {})
	if not refractory_rule.is_empty():
		var refractory := _matching_employee_count(roster, refractory_rule.get("condition", {}), snapshot, hidden_traits)
		result += refractory * float(refractory_rule.get("perEmployee", 0.0))
	var cumulative: Dictionary = card.get("cumulative", {})
	if not cumulative.is_empty():
		result += float(entry.get("active_sprints", entry.get("activeSprints", 0))) * float(cumulative.get("perSprint", 0.0))
	for modifier in card.get("flatModifiers", []):
		if _matches_global_condition(modifier.get("when", {}), roster, snapshot, resources, hidden_traits):
			result += float(modifier.get("value", 0.0))
	var adoption: Dictionary = card.get("adoptionCondition", {})
	if not adoption.is_empty() and _matches_global_condition(adoption.get("condition", {}), roster, snapshot, resources, hidden_traits):
		result *= float(adoption.get("multiplier", 1.0))
	return result


static func _tool_label(card: Dictionary, entry: Dictionary, roster: Array, snapshot: Dictionary, hidden_traits: Dictionary) -> String:
	var name: String = card.get("leverLabel", card.get("name", "Outil"))
	if card.has("cumulative"):
		var active_sprints := int(entry.get("active_sprints", entry.get("activeSprints", 0)))
		return "%s · %d sprint%s actif%s" % [name, active_sprints, "s" if active_sprints > 1 else "", "s" if active_sprints > 1 else ""]
	var eligible := _matching_employee_count(roster, card.get("eligibility", {}), snapshot, hidden_traits)
	var refractory := 0.0
	if card.has("refractory"):
		refractory = _matching_employee_count(roster, card.get("refractory", {}).get("condition", {}), snapshot, hidden_traits)
	return "%s · %s éligibles, %s réfractaires" % [name, _count_label(eligible), _count_label(refractory)]


static func _find_card(cards: Dictionary, card_id: String) -> Dictionary:
	for card in cards.get("cards", []):
		if card.get("id", "") == card_id:
			return card
	return {}


static func _matching_employee_count(roster: Array, condition: Dictionary, snapshot: Dictionary, hidden_traits: Dictionary = {}) -> float:
	if condition.is_empty():
		var all_weight := 0.0
		for member in roster:
			all_weight += _employee_weight(member, hidden_traits)
		return all_weight
	var count := 0.0
	for member in roster:
		if _employee_matches(member, condition, snapshot):
			count += _employee_weight(member, hidden_traits)
	return count


static func _employee_matches(member: Dictionary, condition: Dictionary, snapshot: Dictionary) -> bool:
	var any_of: Array = condition.get("anyOf", [])
	if not any_of.is_empty():
		var matched_any := false
		for option in any_of:
			if _employee_matches(member, option, snapshot):
				matched_any = true
				break
		if not matched_any:
			return false
	var roles: Array = condition.get("roles", [])
	if not roles.is_empty() and not roles.has(member.get("role", "")):
		return false
	if condition.has("seniority") and member.get("seniority", "") != condition.get("seniority", ""):
		return false
	var visible_trait_ids: Array = condition.get("visibleTraitIds", [])
	if not visible_trait_ids.is_empty() and not visible_trait_ids.has(member.get("visible_trait_id", "")):
		return false
	var sprint := int(snapshot.get("sprint", snapshot.get("sprint_number", 1)))
	var hired := int(member.get("hiredSprint", member.get("hired_sprint", 0)))
	if condition.has("hiredWithinSprints"):
		if hired <= 0 or sprint - hired >= int(condition.get("hiredWithinSprints", 0)):
			return false
	if condition.has("hiredBeforeSprints") and sprint - hired < int(condition.get("hiredBeforeSprints", 0)):
		return false
	return true


static func _matches_global_condition(condition: Dictionary, roster: Array, snapshot: Dictionary, resources: Dictionary, hidden_traits: Dictionary = {}) -> bool:
	if condition.is_empty():
		return false
	if condition.has("rosterMinimum") and roster.size() < int(condition.get("rosterMinimum", 0)):
		return false
	if condition.has("rosterMaximum") and roster.size() > int(condition.get("rosterMaximum", 0)):
		return false
	if condition.has("rejectedFeaturesMinimum") and int(snapshot.get("rejected_features", 0)) < int(condition.get("rejectedFeaturesMinimum", 0)):
		return false
	if condition.has("previousPerfectSprint") and bool(snapshot.get("previous_perfect_sprint", false)) != bool(condition.get("previousPerfectSprint", false)):
		return false
	for resource_id in condition.get("resourceMaximum", {}).keys():
		if float(resources.get(resource_id, 0.0)) > float(condition["resourceMaximum"][resource_id]):
			return false
	var no_match: Dictionary = condition.get("noMatch", {})
	if not no_match.is_empty() and _matching_employee_count(roster, no_match, snapshot, hidden_traits) > 0.0:
		return false
	var role_seniority: Dictionary = condition.get("roleSeniorityMinimum", {})
	if not role_seniority.is_empty():
		var matches := 0
		for member in roster:
			if member.get("role", "") == role_seniority.get("role", "") and member.get("seniority", "") == role_seniority.get("seniority", ""):
				matches += 1
		if matches < int(role_seniority.get("minimum", 0)):
			return false
	return true


static func _count_label(value: float) -> String:
	return str(int(round(value))) if is_equal_approx(value, round(value)) else String.num(value, 1)


static func _inter_squad_lever(squads: Array, active_tools: Array, rules: Dictionary) -> Dictionary:
	if squads.size() < int(rules.get("standardisation", {}).get("minimumSquads", INF)):
		return {}
	var signatures: Dictionary = {}
	for squad in squads:
		var signature := _composition_signature(squad.get("roster", []))
		signatures[signature] = int(signatures.get(signature, 0)) + 1
	for count in signatures.values():
		if int(count) >= int(rules.get("standardisation", {}).get("minimumSquads", INF)):
			return rules.get("standardisation", {})
	if signatures.size() == squads.size():
		var chaos: Dictionary = rules.get("chaos-organise", {})
		var cancelled_by: Array = chaos.get("cancelledByTools", [])
		for tool in active_tools:
			if cancelled_by.has(tool.get("id", "")):
				return {}
		return chaos
	return {}


static func _composition_signature(roster: Array) -> String:
	var counts: Dictionary = {}
	for member in roster:
		var role_id: String = member.get("role", "")
		counts[role_id] = int(counts.get(role_id, 0)) + 1
	var roles: Array = counts.keys()
	roles.sort()
	var parts: Array = []
	for role_id in roles:
		parts.append("%s:%d" % [role_id, counts[role_id]])
	return ",".join(parts)


static func _apply_resource_friction(impact: float, lines: Array, rule: Dictionary, resources: Dictionary, scale: float = 1.0) -> float:
	if rule.is_empty():
		return impact
	var resource_value := float(resources.get(rule.get("resource", ""), 0.0))
	var threshold := float(rule.get("threshold", INF))
	if resource_value <= threshold:
		return impact
	var multiplier: float = max(0.0, 1.0 - scale * (resource_value - threshold) / float(rule.get("divisor", 1.0)))
	var after: float = impact * multiplier
	lines.append(_line(7, "global", rule.get("icon", "✂️"), "%s %d" % [rule.get("label", "Frein"), int(resource_value)], "impact_multiplier", multiplier, impact, after))
	return after


static func _resolve_conversion(snapshot: Dictionary, rules: Dictionary, resources: Dictionary, impact: int, strategy_ids: Array, strategy_rules: Dictionary, quick_win_budget: int) -> Dictionary:
	var conversion_rules: Dictionary = rules.get("conversion", {})
	var model_id: String = snapshot.get("business_model_id", "saas-mrr")
	var model: Dictionary = conversion_rules.get(model_id, {})
	var support_teams: Dictionary = snapshot.get("support_teams", snapshot.get("supportTeams", {}))
	var sales_level := int(support_teams.get("sales", 3))
	var pmm_level := int(support_teams.get("pmm", support_teams.get("product_marketing", 3)))
	var csm_level := int(support_teams.get("csm", 3))
	var churn_multiplier := 1.0
	var mrr_multiplier := 1.0
	var mrr_stock_multiplier := 1.0
	for strategy_id in strategy_ids:
		var strategy: Dictionary = strategy_rules.get(strategy_id, {})
		churn_multiplier *= float(strategy.get("churnMultiplier", 1.0))
		mrr_multiplier *= float(strategy.get("mrrMultiplier", 1.0))
		mrr_stock_multiplier *= float(strategy.get("mrrStockMultiplier", 1.0))

	var mrr_before := float(snapshot.get("mrr", 0.0))
	var churn := float(model.get("baseChurn", 0.0)) * _team_multiplier(model.get("csmMultipliers", {}), csm_level) * churn_multiplier
	var low_moral_debt: Dictionary = model.get("lowMoralDebt", {})
	if not low_moral_debt.is_empty() and float(resources.get("moral", 100.0)) < float(low_moral_debt.get("moralBelow", -INF)) and float(resources.get("dette-organisationnelle", 0.0)) >= float(low_moral_debt.get("debtAtLeast", INF)):
		churn = max(churn, float(low_moral_debt.get("maxChurn", churn)))
	var impact_mrr := float(impact) * float(model.get("impactToMrr", 0.0)) * _team_multiplier(model.get("salesMultipliers", {}), sales_level) * mrr_multiplier
	var recurring_roi := float(snapshot.get("recurring_roi", 0.0)) * float(model.get("recurringRoiMultiplier", 1.0))
	var mrr_after := mrr_before * mrr_stock_multiplier * (1.0 - churn) + impact_mrr + recurring_roi

	var budget_rules: Dictionary = conversion_rules.get("budget", {})
	var allocation := int(budget_rules.get("failedReviewAllocation", 0)) if bool(snapshot.get("board_review_failed", false)) else int(budget_rules.get("boardAllocation", 0))
	var budget_gain := int(floor(sqrt(float(impact)))) + allocation + quick_win_budget
	var budget_before := int(snapshot.get("budget", 0))
	var perceived_rule: Dictionary = conversion_rules.get("perceivedValue", {})
	var perceived_delta: float = min(int(floor(float(impact) / float(perceived_rule.get("impactPerPoint", INF)))) * _team_multiplier(model.get("pmmMultipliers", {}), pmm_level), float(perceived_rule.get("maxPerSprint", 0)))
	var capital_rule: Dictionary = conversion_rules.get("politicalCapital", {})
	var capital_delta := int(floor(float(impact) / float(capital_rule.get("impactPerPoint", INF))))

	# 💼📣🎧 Équipes subies (spec §9.4) : le taux de chaque équipe, visible à
	# l'étape ⑨ de la Résolution comme les autres lignes de conversion —
	# calculé une seule fois ici, jamais recalculé côté UI.
	var sales_multiplier := _team_multiplier(model.get("salesMultipliers", {}), sales_level)
	var pmm_multiplier := _team_multiplier(model.get("pmmMultipliers", {}), pmm_level)
	var csm_multiplier := _team_multiplier(model.get("csmMultipliers", {}), csm_level)
	var team_rates := {
		"sales": {"level": sales_level, "multiplier": sales_multiplier},
		"pmm": {"level": pmm_level, "multiplier": pmm_multiplier},
		"csm": {"level": csm_level, "multiplier": csm_multiplier},
	}

	var lines: Array = [
		_line(9, "global", "💼", "Sales — Impact → MRR (niveau %d)" % sales_level, "conversion_rate", sales_multiplier, 0.0, sales_multiplier),
		_line(9, "global", "📣", "Product marketing — Impact → Valeur perçue (niveau %d)" % pmm_level, "conversion_rate", pmm_multiplier, 0.0, pmm_multiplier),
		_line(9, "global", "🎧", "CSM / Support — churn (niveau %d)" % csm_level, "conversion_rate", csm_multiplier, 0.0, csm_multiplier),
		_line(9, "global", "💵", "MRR", "mrr", mrr_after - mrr_before, mrr_before, mrr_after),
		_line(9, "global", "💶", "Budget", "budget", budget_gain, budget_before, budget_before + budget_gain),
	]
	if not is_zero_approx(perceived_delta):
		lines.append(_line(9, "global", perceived_rule.get("icon", "📈"), perceived_rule.get("label", "Valeur perçue"), "resource_delta", perceived_delta, 0, perceived_delta))
	if capital_delta != 0:
		lines.append(_line(9, "global", capital_rule.get("icon", "🎯"), capital_rule.get("label", "Capital politique"), "resource_delta", capital_delta, 0, capital_delta))
	return {
		"lines": lines,
		"mrr": { "before": mrr_before, "after": mrr_after, "gain": mrr_after - mrr_before, "impact_gain": impact_mrr, "recurring_roi_gain": recurring_roi, "churn": churn },
		"budget": { "before": budget_before, "after": budget_before + budget_gain, "gain": budget_gain, "allocation": allocation, "quick_win_bonus": quick_win_budget },
		"resource_deltas": { "valeur-percue": perceived_delta, "capital-politique": capital_delta },
		"teamRates": team_rates,
	}


static func _team_multiplier(table: Dictionary, level: int) -> float:
	return float(table.get(str(level), table.get("0", 1.0)))


static func _quick_win_budget(squad_reports: Array) -> int:
	var total := 0
	for report in squad_reports:
		total += int(report.get("quick_win_budget", 0))
	return total


static func _quick_win_count(delivered: Array) -> int:
	var count := 0
	for item in delivered:
		if bool(item.get("quickWin", false)):
			count += 1
	return count


static func _items_points(items: Array) -> int:
	var total := 0
	for item in items:
		total += int(item.get("costPoints", 0))
	return total


static func _is_overheated(snapshot: Dictionary, squads: Array) -> bool:
	if bool(snapshot.get("overheated", false)):
		return true
	for squad in squads:
		if int(squad.get("spent_points", squad.get("planned_points", 0))) > int(squad.get("capacity", 0)):
			return true
	return false


static func _line(step: int, scope: String, icon: String, label: String, type: String, value: Variant, before: Variant, after: Variant, squad_id: String = "") -> Dictionary:
	var line := { "step": step, "scope": scope, "icon": icon, "label": label, "type": type, "value": value, "before": before, "after": after }
	if scope == "local":
		line["squad_id"] = squad_id
	return line
