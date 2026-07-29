class_name EffectResolver
extends RefCounted
## Fonctions pures de résolution d'effets — convertit les données brutes de
## data/*.json + data/balance.json en deltas sur les 6 ressources, selon le
## modèle d'effet unifié (carnet de règles §11) : carte → époque → arrondi.
## Rien ici ne modifie l'état ; l'appelant décide quand appliquer le
## résultat via SprintState.add_pending().


## Convertit les 4 axes d'une carte structurelle (cards.json) en deltas sur
## les 6 ressources pour le profil d'équipe donné, avec les multiplicateurs
## d'époque de balance.json → eraCardEffectMultipliers.
static func resolve_card_activation(card_id: String, team_profile: String, era_id: String) -> Dictionary:
	var card := _find_card(card_id)
	if card.is_empty():
		return {}

	var effects: Dictionary = card.get("effects", {}).get(team_profile, {})
	var axis_map: Dictionary = GameData.balance.get("cardAxisResourceMap", {})
	var era_multipliers: Dictionary = GameData.balance.get("eraCardEffectMultipliers", {}).get(era_id, {})

	var deltas: Dictionary = {}
	for axis_id in effects.keys():
		var mapping: Dictionary = axis_map.get(axis_id, {})
		var resource_id: String = mapping.get("resource", "")
		if resource_id == "":
			continue
		var raw_value: float = float(effects[axis_id].get("value", 0))
		if mapping.get("invert", false):
			raw_value = -raw_value
		deltas[resource_id] = deltas.get(resource_id, 0.0) + raw_value

	for resource_id in deltas.keys():
		if era_multipliers.has(resource_id):
			deltas[resource_id] *= float(era_multipliers[resource_id])

	return round_deltas(deltas)


## Deltas de la Roadmap : somme des effets des features sélectionnées, plus
## la pénalité de surchauffe si la sélection dépasse la capacité effective.
static func resolve_roadmap(selected_feature_ids: Array, effective_capacity: int) -> Dictionary:
	var feature_effects: Dictionary = GameData.balance.get("roadmap", {}).get("featureEffects", {})
	var deltas: Dictionary = {}

	for feature_id in selected_feature_ids:
		var effect: Dictionary = feature_effects.get(feature_id, {})
		for resource_id in effect.keys():
			deltas[resource_id] = deltas.get(resource_id, 0.0) + float(effect[resource_id])

	if selected_feature_ids.size() > effective_capacity:
		var penalty: Dictionary = GameData.balance.get("roadmap", {}).get("overCapacityPenalty", {})
		for resource_id in penalty.keys():
			deltas[resource_id] = deltas.get(resource_id, 0.0) + float(penalty[resource_id])

	return round_deltas(deltas)


## Effet d'une embauche : coût + effet immédiat (balance.json →
## recruitment.itemEffects). Le bonus de capacité est retourné à part —
## il persiste au-delà du sprint, l'appelant l'ajoute directement à
## SprintState.capacity_bonus plutôt qu'au panier d'un sprint.
static func resolve_recruitment(item_id: String) -> Dictionary:
	var item_effects: Dictionary = GameData.balance.get("recruitment", {}).get("itemEffects", {})
	var config: Dictionary = item_effects.get(item_id, {})

	var deltas: Dictionary = {}
	var hire_cost: Dictionary = config.get("hireCost", {})
	var immediate: Dictionary = config.get("immediate", {})
	for resource_id in hire_cost.keys():
		deltas[resource_id] = deltas.get(resource_id, 0.0) + float(hire_cost[resource_id])
	for resource_id in immediate.keys():
		deltas[resource_id] = deltas.get(resource_id, 0.0) + float(immediate[resource_id])

	return {
		"deltas": round_deltas(deltas),
		"capacity_bonus": int(config.get("capacityBonus", 0)),
	}


static func round_deltas(deltas: Dictionary) -> Dictionary:
	var rounded: Dictionary = {}
	for resource_id in deltas.keys():
		var value := int(round(deltas[resource_id]))
		if value != 0:
			rounded[resource_id] = value
	return rounded


## État qualitatif d'une jauge ("good" / "warn" / "danger"), en tenant
## compte du sens de la ressource (dette et cynisme : plus bas = mieux).
static func gauge_state(resource_id: String, value: float) -> String:
	var direction: String = GameData.balance.get("resourceDirection", {}).get(resource_id, "high-good")
	var normalized := value if direction == "high-good" else (100.0 - value)
	var thresholds: Dictionary = GameData.balance.get("stateThresholds", {"goodMin": 60, "dangerMax": 25})

	if normalized >= float(thresholds.get("goodMin", 60)):
		return "good"
	if normalized <= float(thresholds.get("dangerMax", 25)):
		return "danger"
	return "warn"


## Formate un dictionnaire de deltas en texte façon journal de sprint, ex.
## "💰 Trésorerie −4 · 🫶 Moral +6". Ignore les deltas nuls, ordre stable
## (celui de resources.json).
static func format_deltas(deltas: Dictionary) -> String:
	var parts: Array = []
	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		if not deltas.has(resource_id):
			continue
		var value := int(round(deltas[resource_id]))
		if value == 0:
			continue
		var sign := "+" if value > 0 else "−"
		parts.append("%s %s %s%d" % [resource.get("icon", ""), resource.get("name", ""), sign, abs(value)])
	if parts.is_empty():
		return "Aucun changement mesurable."
	return " · ".join(parts)


static func resource_label(resource_id: String) -> String:
	for resource in GameData.resources:
		if resource.get("id", "") == resource_id:
			return "%s %s" % [resource.get("icon", ""), resource.get("name", "")]
	return resource_id


static func _find_card(card_id: String) -> Dictionary:
	for card in GameData.cards.get("cards", []):
		if card.get("id", "") == card_id:
			return card
	return {}
