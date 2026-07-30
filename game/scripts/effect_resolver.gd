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


## Coût total en points d'une sélection de features (balance.json →
## roadmap.featureCostPoints ; 1 point par défaut).
static func roadmap_points_cost(selected_feature_ids: Array) -> int:
	var cost_points: Dictionary = GameData.balance.get("roadmap", {}).get("featureCostPoints", {})
	var total := 0
	for feature_id in selected_feature_ids:
		total += int(cost_points.get(feature_id, 1))
	return total


## Deltas de la Roadmap (Phase A) : somme des effets des features
## sélectionnées — effets Valeur perçue divisés si aucun Designer au roster,
## bonus Designer par feature livrée (plafonné), pièces des quick wins — plus
## la pénalité de surchauffe si le panier dépasse la capacité en points,
## modulée par les PM présents (spec profondeur §4.2, §6.2). Le contexte de
## roster vient de SprintState.get_roster_context().
static func resolve_roadmap(selected_feature_ids: Array, capacity_points: int, roster_context: Dictionary = {}) -> Dictionary:
	var roadmap_conf: Dictionary = GameData.balance.get("roadmap", {})
	var feature_effects: Dictionary = roadmap_conf.get("featureEffects", {})
	var quick_win_pieces: Dictionary = roadmap_conf.get("quickWinPieces", {})
	var roles: Dictionary = GameData.balance.get("roles", {})
	var designer_conf: Dictionary = roles.get("designer", {})
	var pm_conf: Dictionary = roles.get("pm", {})
	var designer_weight: float = roster_context.get("designer_weight", 0.0)
	var pm_weight: float = roster_context.get("pm_weight", 0.0)

	var valeur_divisor := 1.0
	if designer_weight <= 0.0:
		valeur_divisor = float(designer_conf.get("valeurEffectsDivisorIfAbsent", 2))

	var deltas: Dictionary = {}
	for feature_id in selected_feature_ids:
		var effect: Dictionary = feature_effects.get(feature_id, {})
		for resource_id in effect.keys():
			var value := float(effect[resource_id])
			if resource_id == "valeur-percue":
				value /= valeur_divisor
			deltas[resource_id] = deltas.get(resource_id, 0.0) + value
		deltas["pieces"] = deltas.get("pieces", 0.0) + float(quick_win_pieces.get(feature_id, 0))

	if designer_weight > 0.0 and not selected_feature_ids.is_empty():
		var per_feature: float = min(
			floor(designer_weight) * float(designer_conf.get("valeurPerFeatureDelivered", 1)),
			float(designer_conf.get("valeurPerFeatureDeliveredMax", 2))
		)
		deltas["valeur-percue"] = deltas.get("valeur-percue", 0.0) + per_feature * selected_feature_ids.size()

	if roadmap_points_cost(selected_feature_ids) > capacity_points:
		var penalty: Dictionary = roadmap_conf.get("overCapacityPenalty", {})
		var reduction: float = min(
			pm_weight * float(pm_conf.get("overloadReductionPerPm", 0.25)),
			float(pm_conf.get("overloadReductionMax", 0.5))
		)
		for resource_id in penalty.keys():
			deltas[resource_id] = deltas.get(resource_id, 0.0) + float(penalty[resource_id]) * (1.0 - reduction)

	return round_deltas(deltas)


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
## (celui de resources.json), pseudo-ressource "pieces" (🪙) en dernier.
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
	var pieces_value := int(round(deltas.get("pieces", 0.0)))
	if pieces_value != 0:
		parts.append("🪙 Pièces %s%d" % ["+" if pieces_value > 0 else "−", abs(pieces_value)])
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
