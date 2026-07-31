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
	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		if not totals.has(resource_id):
			continue
		var value: float = float(totals[resource_id])
		if era_multipliers.has(resource_id):
			value *= float(era_multipliers[resource_id])
		var rounded := int(round(value))
		if rounded == 0:
			continue
		lines.append({
			"resource_id": resource_id,
			"icon": resource.get("icon", ""),
			"name": resource.get("name", ""),
			"note": " · ".join(notes.get(resource_id, [])),
			"value": rounded,
			"good": delta_is_good(resource_id, float(rounded)),
		})
	return lines


## Un delta va-t-il dans le bon sens pour cette ressource ? La dette et le
## cynisme sont "low-good" (balance.json → resourceDirection) : y descendre est
## une bonne nouvelle. Sert à colorer les lignes d'impact des cartes d'Actif.
static func delta_is_good(resource_id: String, value: float) -> bool:
	var direction: String = GameData.balance.get("resourceDirection", {}).get(resource_id, "high-good")
	if direction == "high-good":
		return value >= 0.0
	return value <= 0.0


## Deltas de la Roadmap profonde : les attributs réels viennent directement
## de `backlog.json`. Seuls les items livrés (feature ou epic achevé) gagnent
## leur ROI, impact client et risque; un epic entamé ne fait encore rien.
static func resolve_backlog(delivered_items: Array, spent_points: int, capacity_points: int, roster_context: Dictionary = {}, has_okr: bool = false) -> Dictionary:
	var roadmap_conf: Dictionary = GameData.balance.get("roadmap", {})
	var backlog_conf: Dictionary = GameData.balance.get("backlogDraw", {})
	var roles: Dictionary = GameData.balance.get("roles", {})
	var designer_conf: Dictionary = roles.get("designer", {})
	var pm_conf: Dictionary = roles.get("pm", {})
	var designer_weight: float = roster_context.get("designer_weight", 0.0)
	var pm_weight: float = roster_context.get("pm_weight", 0.0)

	var valeur_divisor := 1.0
	if designer_weight <= 0.0:
		valeur_divisor = float(designer_conf.get("valeurEffectsDivisorIfAbsent", 2))

	var deltas: Dictionary = {}
	for item in delivered_items:
		var client_impact := float(item.get("clientImpact", 0)) / valeur_divisor
		var risk := float(item.get("risk", 0))
		if client_impact != 0.0:
			deltas["valeur-percue"] = deltas.get("valeur-percue", 0.0) + client_impact
		if risk != 0.0:
			deltas["dette-organisationnelle"] = deltas.get("dette-organisationnelle", 0.0) + risk
		for resource_id in item.get("completionEffects", {}).keys():
			deltas[resource_id] = deltas.get(resource_id, 0.0) + float(item["completionEffects"][resource_id])
		if has_okr and int(item.get("roi", 0)) >= int(backlog_conf.get("strongRoiThreshold", 0)):
			deltas["capital-politique"] = deltas.get("capital-politique", 0.0) + float(backlog_conf.get("okrCapitalPolitiqueBonus", 0))

	if designer_weight > 0.0 and not delivered_items.is_empty():
		var per_feature: float = min(
			floor(designer_weight) * float(designer_conf.get("valeurPerFeatureDelivered", 1)),
			float(designer_conf.get("valeurPerFeatureDeliveredMax", 2))
		)
		deltas["valeur-percue"] = deltas.get("valeur-percue", 0.0) + per_feature * delivered_items.size()

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
## "💰 Trésorerie −4 · 🫶 Moral +6". Ignore les deltas nuls, ordre stable
## (celui de resources.json), pseudo-ressources "pieces" (🪙) puis
## "energie" (⚡, jauge personnelle du joueur) en dernier.
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
	var energie_value := int(round(deltas.get("energie", 0.0)))
	if energie_value != 0:
		parts.append("⚡ Énergie %s%d" % ["+" if energie_value > 0 else "−", abs(energie_value)])
	if parts.is_empty():
		return "Aucun changement mesurable."
	return " · ".join(parts)


static func resource_label(resource_id: String) -> String:
	for resource in GameData.resources:
		if resource.get("id", "") == resource_id:
			return "%s %s" % [resource.get("icon", ""), resource.get("name", "")]
	return resource_id


## Deltas immédiats d'un achat de pratique — seul le Cynisme (balance.json →
## shopDraw.practiceCynisme, éventuellement remplacé par une exigence de
## trimestre active — voir SprintState.get_quarter_requirement_effects())
## tombe au moment de l'achat ; le reste de son effet (`perSprint`) entre dans
## la boucle générale des pratiques possédées à la prochaine Résolution, pas
## au clic. Même source que SprintState.buy_practice() applique via
## add_pending() — la preview d'impact (Lot 3 §5.1) et l'achat partagent ce
## seul calcul. `quarter_effects` est optionnel : {} pour un appel hors
## contexte de sprint (aucun test ne le fournit aujourd'hui).
static func practice_purchase_deltas(quarter_effects: Dictionary = {}) -> Dictionary:
	var cynisme := float(quarter_effects.get("practiceCynisme", GameData.balance.get("shopDraw", {}).get("practiceCynisme", 2)))
	return {"cynisme": cynisme} if cynisme != 0.0 else {}


## Ressources potentiellement modifiées par un trait caché non révélé, dérivées
## du pool (data/hidden-traits.json) : seuls les effets `xPerSprint` se voient
## sur une jauge du Panneau de bord (`contributionFactor`, `capacityBonus`,
## `salaryRaiseAtTrialEnd`, `nextHireDiscountPieces`… n'y apparaissent pas).
## Sert la chip ❓ scintillante de la preview d'impact (Lot 3 §5.1) : « ici,
## vous pariez » — sans dire sur quoi si le pool n'a rien qui morde une jauge.
static func hidden_trait_resource_ids() -> Array:
	var ids: Array = []
	for hidden_trait in GameData.hidden_traits.get("traits", []):
		for effect_key in hidden_trait.get("effects", {}).keys():
			if effect_key.ends_with("PerSprint"):
				var resource_id: String = effect_key.substr(0, effect_key.length() - "PerSprint".length())
				if not ids.has(resource_id):
					ids.append(resource_id)
	return ids


## Une projection franchit-elle un seuil, dans le sens qui rapproche du
## déclencheur ? "lte" : on passe de strictement au-dessus à au-dessous ou égal
## (le sens des seuils "low-good" / plancher) ; "gte" l'inverse (plafond).
static func _crosses_threshold(old_value: float, new_value: float, boundary: float, comparison: String) -> bool:
	if comparison == "lte":
		return old_value > boundary and new_value <= boundary
	return old_value < boundary and new_value >= boundary


## Lignes de conséquence quand une projection franchit un seuil mécanique connu
## — « faire parler les seuils » (Lot 3 §5.1) : pas le chiffre, la conséquence.
## Les seuils numériques restent lus à leur unique source (energy, pressure,
## endingThresholds/endingThresholdOverrides) ; seuls les libellés viennent de
## balance.json → thresholdNarratives, pour qu'aucun nombre ne soit dupliqué
## entre la règle et son commentaire. Retourne un tableau de textes (sans le ⚠️,
## ajouté par l'affichage).
static func threshold_consequences(resource_id: String, old_value: float, new_value: float, era_id: String) -> Array:
	var lines: Array = []
	var narratives: Dictionary = GameData.balance.get("thresholdNarratives", {})

	if resource_id == "moral":
		var tiers: Array = GameData.balance.get("energy", {}).get("moralRegenTiers", [])
		var labels: Array = narratives.get("moralRegenTiers", [])
		for i in range(1, tiers.size()):
			var boundary := float(tiers[i - 1].get("moralMin", 0))
			if i < labels.size() and String(labels[i]) != "" and _crosses_threshold(old_value, new_value, boundary, "lte"):
				lines.append(String(labels[i]))

	if resource_id == "valeur-percue":
		var cutoff := float(GameData.balance.get("pressure", {}).get("revenueCutoffValeurPercue", 5))
		var label: String = narratives.get("revenueCutoff", "")
		if label != "" and _crosses_threshold(old_value, new_value, cutoff, "lte"):
			lines.append(label)

	var ending_labels: Dictionary = narratives.get("endingConsequences", {})
	var overrides: Dictionary = GameData.balance.get("endingThresholdOverrides", {}).get(era_id, {})
	for threshold in GameData.balance.get("endingThresholds", []):
		if threshold.get("resource", "") != resource_id:
			continue
		var value := float(overrides.get(resource_id, threshold.get("value", 0)))
		var comparison: String = threshold.get("comparison", "lte")
		var ending_label: String = ending_labels.get(threshold.get("ending", ""), "")
		if ending_label != "" and _crosses_threshold(old_value, new_value, value, comparison):
			lines.append(ending_label)

	return lines


static func _find_card(card_id: String) -> Dictionary:
	for card in GameData.cards.get("cards", []):
		if card.get("id", "") == card_id:
			return card
	return {}
