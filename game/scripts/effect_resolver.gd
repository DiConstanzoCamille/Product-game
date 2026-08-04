class_name EffectResolver
extends RefCounted
## Fonctions pures de résolution d'effets — convertit les données brutes de
## data/*.json + data/balance.json en deltas sur les 5 jauges et les deux
## monnaies (💥 Impact, 💰 Revenue), selon le
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


## Lignes d'impact d'une grande décision pour la carte d'Actif, exprimées **en
## ressources et non en axes** (docs/proposition-ui-interface.md §2.2) : même
## calcul que resolve_card_activation() — axe → ressource via
## balance.json → cardAxisResourceMap, puis multiplicateur d'époque et arrondi
## — mais les notes d'axe sont conservées comme texte de la ligne. C'est la
## condition pour que la preview d'impact du Lot 3 soit honnête : on projettera
## sur les jauges exactement ce qui est écrit sur la carte.
## Retourne [{resource_id, icon, name, note, value, good}], dans l'ordre de
## resources.json ; les deltas nuls sont omis, comme à l'application.
static func card_impact_lines(card_id: String, team_profile: String, era_id: String) -> Array:
	var card := _find_card(card_id)
	if card.is_empty():
		return []

	var effects: Dictionary = card.get("effects", {}).get(team_profile, {})
	var axis_map: Dictionary = GameData.balance.get("cardAxisResourceMap", {})
	var era_multipliers: Dictionary = GameData.balance.get("eraCardEffectMultipliers", {}).get(era_id, {})

	var totals: Dictionary = {}
	var notes: Dictionary = {}
	for axis_id in effects.keys():
		var mapping: Dictionary = axis_map.get(axis_id, {})
		var resource_id: String = mapping.get("resource", "")
		if resource_id == "":
			continue
		var raw_value: float = float(effects[axis_id].get("value", 0))
		if mapping.get("invert", false):
			raw_value = -raw_value
		totals[resource_id] = totals.get(resource_id, 0.0) + raw_value
		var note: String = effects[axis_id].get("note", "")
		if note != "":
			var collected: Array = notes.get(resource_id, [])
			collected.append(note)
			notes[resource_id] = collected

	var lines: Array = []
	# L'ordre d'affichage suit resources.json, **puis** le 💰 Revenue : il n'y
	# est plus (ce n'est pas une jauge) mais l'axe « coût financier » d'une
	# carte le frappe toujours, et une ligne d'impact qui disparaît de la carte
	# est un piège pour le joueur.
	for resource_id in _display_order():
		if not totals.has(resource_id):
			continue
		var value: float = float(totals[resource_id])
		if era_multipliers.has(resource_id):
			value *= float(era_multipliers[resource_id])
		var rounded := int(round(value))
		if rounded == 0:
			continue
		var label := resource_label(resource_id).split(" ", false, 1)
		lines.append({
			"resource_id": resource_id,
			"icon": label[0] if label.size() > 0 else "",
			"name": label[1] if label.size() > 1 else resource_id,
			"note": " · ".join(notes.get(resource_id, [])),
			"value": rounded,
			"good": delta_is_good(resource_id, float(rounded)),
		})
	return lines


## Les identifiants affichables dans l'ordre : les jauges de resources.json,
## puis les deux monnaies, qui n'y vivent pas.
static func _display_order() -> Array:
	var ids: Array = []
	for resource in GameData.resources:
		ids.append(resource.get("id", ""))
	ids.append("revenue")
	ids.append("impact")
	return ids


## Un delta va-t-il dans le bon sens pour cette ressource ? La dette et le
## cynisme sont "low-good" (balance.json → resourceDirection) : y descendre est
## une bonne nouvelle. Sert à colorer les lignes d'impact des cartes d'Actif.
static func delta_is_good(resource_id: String, value: float) -> bool:
	var direction: String = GameData.balance.get("resourceDirection", {}).get(resource_id, "high-good")
	if direction == "high-good":
		return value >= 0.0
	return value <= 0.0


## Deltas de la Roadmap profonde : les attributs réels viennent directement
## de `backlog.json`. Seuls les items livrés (feature ou epic achevé) portent
## leur effet client et leur risque ; un epic entamé ne fait encore rien.
##
## 📈 **C'est ici, et nulle part ailleurs, que naît la Réputation produit**
## (docs/spec-clients-revenue.md §5.1.1) : elle vient de ce qu'on livre, jamais
## de ce qu'on score. La règle qui la fabriquait à partir de l'Impact a été
## supprimée — c'était le premier maillon de la fuite
## `Impact → perception → Revenue`. Le 📣 Product marketing amplifie ce que les
## livraisons font à cette réputation (`reputation_multiplier` du contexte de
## roster) : même équipe subie, même niveau 0-5, autre entrée.
static func resolve_backlog(delivered_items: Array, spent_points: int, capacity_points: int, roster_context: Dictionary = {}, has_okr: bool = false) -> Dictionary:
	var roadmap_conf: Dictionary = GameData.balance.get("roadmap", {})
	var backlog_conf: Dictionary = GameData.balance.get("backlogDraw", {})
	var roles: Dictionary = GameData.balance.get("roles", {})
	var designer_conf: Dictionary = roles.get("designer", {})
	var pm_conf: Dictionary = roles.get("pm", {})
	var designer_weight: float = roster_context.get("designer_weight", 0.0)
	var pm_weight: float = roster_context.get("pm_weight", 0.0)
	var reputation_multiplier: float = roster_context.get("reputation_multiplier", 1.0)

	var reputation_divisor := 1.0
	if designer_weight <= 0.0:
		reputation_divisor = float(designer_conf.get("reputationEffectsDivisorIfAbsent", 2))

	var deltas: Dictionary = {}
	var reputation := 0.0
	for item in delivered_items:
		var client_effect := float(item.get("clients", 0)) / reputation_divisor
		var risk := float(item.get("risk", 0))
		if client_effect != 0.0:
			reputation += client_effect
		if risk != 0.0:
			deltas["dette-organisationnelle"] = deltas.get("dette-organisationnelle", 0.0) + risk
		for resource_id in item.get("completionEffects", {}).keys():
			deltas[resource_id] = deltas.get(resource_id, 0.0) + float(item["completionEffects"][resource_id])
		if has_okr and int(item.get("clients", 0)) >= int(backlog_conf.get("strongClientsThreshold", 0)):
			deltas["capital-politique"] = deltas.get("capital-politique", 0.0) + float(backlog_conf.get("okrCapitalPolitiqueBonus", 0))

	if designer_weight > 0.0 and not delivered_items.is_empty():
		var per_feature: float = min(
			floor(designer_weight) * float(designer_conf.get("reputationPerFeatureDelivered", 1)),
			float(designer_conf.get("reputationPerFeatureDeliveredMax", 2))
		)
		reputation += per_feature * delivered_items.size()

	if reputation != 0.0:
		deltas["reputation-produit"] = deltas.get("reputation-produit", 0.0) + reputation * reputation_multiplier

	if spent_points > capacity_points:
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
## "💰 Revenue −4 · 🫶 Moral +6". Ignore les deltas nuls, ordre stable (celui de
## resources.json), puis les deux monnaies — 💥 Impact et 💰 Revenue — et enfin
## la pseudo-ressource "energie" (⚡, jauge personnelle du joueur).
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
	var impact_value := int(round(deltas.get("impact", 0.0)))
	if impact_value != 0:
		parts.append("💥 Impact %s%d" % ["+" if impact_value > 0 else "−", abs(impact_value)])
	var revenue_value := int(round(deltas.get("revenue", 0.0)))
	if revenue_value != 0:
		parts.append("💰 Revenue %s%d" % ["+" if revenue_value > 0 else "−", abs(revenue_value)])
	# 👥 Un effet client se raconte en clients réels, jamais en points : la
	# conversion passe par SprintState, seul détenteur du modèle économique du
	# run — « +72 » veut dire quelque chose, « +3 » ne veut rien dire.
	var clients_points := float(deltas.get("clients", 0.0))
	if not is_zero_approx(clients_points):
		var real_clients := int(round(SprintState.clients_for_points(clients_points)))
		if real_clients != 0:
			parts.append("👥 Clients %s%d" % ["+" if real_clients > 0 else "−", abs(real_clients)])
	var energie_value := int(round(deltas.get("energie", 0.0)))
	if energie_value != 0:
		parts.append("⚡ Énergie %s%d" % ["+" if energie_value > 0 else "−", abs(energie_value)])
	if parts.is_empty():
		return "Aucun changement mesurable."
	return " · ".join(parts)


## Libellé d'affichage d'une jauge **ou** d'une des deux monnaies : celles-ci
## ne vivent pas dans resources.json (elles n'ont pas de jauge) mais s'affichent
## au même endroit dans les lignes d'impact d'une carte.
static func resource_label(resource_id: String) -> String:
	for resource in GameData.resources:
		if resource.get("id", "") == resource_id:
			return "%s %s" % [resource.get("icon", ""), resource.get("name", "")]
	match resource_id:
		"revenue":
			return "💰 Revenue"
		"impact":
			return "💥 Impact"
		"energie":
			return "⚡ Énergie"
	return resource_id


static func _find_card(card_id: String) -> Dictionary:
	for card in GameData.cards.get("cards", []):
		if card.get("id", "") == card_id:
			return card
	return {}
