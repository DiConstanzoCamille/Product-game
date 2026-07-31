class_name AssetView
extends RefCounted
## Traduit les trois pools de données du jeu — grandes décisions
## (data/cards.json), candidats (data/candidates.json) et pratiques
## (data/practices.json) — en **descripteurs de carte d'Actif** consommés par
## scenes/components/asset_card.tscn.
##
## C'est la couche qui rend concrète l'abstraction de la proposition UI §2 :
## « les différences entre les trois types (monnaie, récurrence, disponibilité)
## sont des valeurs de champs, pas des raisons d'avoir trois composants ». Les
## fichiers de données ne sont **pas** fusionnés (§2.3) — ils sont seulement
## présentés par le même composant.
##
## Rien ici ne modifie l'état : ces fonctions lisent SprintState pour calculer
## ce qui est activable/abordable et retournent du texte prêt à afficher.
## L'application des effets reste chez SprintState et EffectResolver.

## Icônes d'objet Kenney par Actif (assets/items-kenney, CC0) — la « fausse 3D
## d'objets posés sur le tableau » de la piste Post-it. Les quatre premières
## sont celles validées dans le spike market_screen_proto.
const DECISION_ICONS := {
	"rice": 74,             # calculatrice
	"notion": 32,           # livre ouvert
	"jira": 36,             # dossier suspendu
	"daily-standup": 137,   # mug de café
	"sprint-retro": 148,    # classeur à flèches
}

const PRACTICE_ICONS := {
	"discovery": 37,                # presse-papiers
	"ux-research": 31,              # palette
	"tech-radar": 162,              # boussole
	"entretiens-structures": 149,   # formulaire imprimé
	"product-analytics": 111,       # microscope
	"segmentation-clients": 158,    # billets
	"okr": 34,                      # manuel jaune
	"retros-sinceres": 124,         # cafetière
}

const DEFAULT_ITEM_ICON := 50  # ordinateur portable, pour tout id inconnu

## Famille d'une pratique, affichée en référence de carte (zone ①) — l'équivalent
## du « PRD-014 » des décisions : à quoi sert ce post-it.
const PRACTICE_FAMILIES := {
	"roi": "RÉVÉLATION",
	"clientImpact": "RÉVÉLATION",
	"risk": "RÉVÉLATION",
	"hiddenTraits": "RECRUTEMENT",
	"burndown": "PILOTAGE",
	"accounts": "PILOTAGE",
	"okrBonus": "OBJECTIFS",
	"moralPerSprint": "RITUEL",
}

## Ce que déverrouille une pratique, en une ligne d'impact. Sert de repli quand
## la description ne contient pas de seconde phrase mécanique (voir
## _practice_flavor_and_effect).
const PRACTICE_UNLOCK_LABELS := {
	"roi": "Révèle la colonne ROI de la roadmap",
	"clientImpact": "Révèle la colonne Impact client des features",
	"risk": "Révèle la colonne Risque (Dette) des features",
	"hiddenTraits": "Les candidats de l'étal arrivent révélés",
	"burndown": "Déverrouille le Burn down du Dossier entreprise",
	"accounts": "Déverrouille Grands comptes du Dossier entreprise",
	"okrBonus": "+2 🎯 par feature à fort ROI livrée",
	"moralPerSprint": "Moral en hausse à chaque sprint",
}


# ── Grande décision ───────────────────────────────────────────────────────
static func for_decision(card: Dictionary) -> Dictionary:
	var card_id: String = card.get("id", "")
	var activated: bool = SprintState.activated_cards.has(card_id)
	var max_activations := int(GameData.balance.get("structuralDecisionMaxActivations", 4))
	var used: int = SprintState.activated_cards.size()

	var impacts: Array = []
	for line in EffectResolver.card_impact_lines(card_id, SprintState.team_profile, SprintState.era_id):
		var note: String = line.get("note", "")
		impacts.append({
			"label": "%s %s" % [line.get("icon", ""), note if note != "" else line.get("name", "")],
			"delta": signed(int(line.get("value", 0))),
			"good": line.get("good", true),
			"tooltip": "%s %s %s — effet calibré pour votre %s" % [
				line.get("icon", ""), line.get("name", ""), signed(int(line.get("value", 0))),
				_team_profile_label(),
			],
		})

	# 🔒 Une carte à prérequis reste lisible mais inactivable tant que sa
	# condition n'est pas vraie — et la condition est affichée **comme une ligne
	# d'impact**, au même endroit que les deltas : le prérequis est une donnée de
	# la décision, pas un message d'erreur.
	var requirement := SprintState.card_requirement_state(card)
	if requirement.get("gated", false):
		var expiry := SprintState.get_lease_expiry(card_id)
		impacts.push_front({
			"label": "🔒 %s" % requirement.get("label", ""),
			"delta": requirement.get("current", ""),
			"good": requirement.get("ok", false),
			"unknown": not requirement.get("ok", false),
			"locked": not requirement.get("ok", false),
			"tooltip": "Punaisée au rayon jusqu'au sprint %d — vous avez jusque-là pour réunir la condition." % expiry if expiry > 0 else "",
		})

	var cost := SprintState.decision_cost(card_id)
	var tool_frozen: bool = SprintState.is_quarter_requirement_active("toolsFrozen") \
		and card.get("family", "") in ["outil-process", "methodologie-orga"]

	var primary: Dictionary = {}
	if activated:
		primary = {
			"text": "Activée ✓ (sprint %d)" % int(SprintState.activated_card_sprints.get(card_id, 0)),
			"disabled": true,
		}
	elif tool_frozen:
		primary = {
			"text": "🔒 Outillage gelé ce trimestre",
			"disabled": true,
			"tooltip": "Exigence active : %s" % SprintState.get_quarter_requirement_text(),
		}
	elif requirement.get("gated", false) and not requirement.get("ok", false):
		primary = {
			"text": "🔒 Verrouillée — %s" % requirement.get("label", ""),
			"disabled": true,
			"tooltip": "Elle reste sur le rayon jusqu'au sprint %d." % SprintState.get_lease_expiry(card_id),
		}
	elif used >= max_activations:
		primary = {"text": "Plus de slot ce mandat", "disabled": true}
	elif SprintState.pieces < cost:
		primary = {
			"text": "Activer (%d 🪙 — insuffisant)" % cost,
			"disabled": true,
			"tooltip": "Il vous manque %d 🪙 de budget d'investissement. Une grande décision se paie comme une embauche." % (cost - SprintState.pieces),
		}
	else:
		primary = {
			"text": "Activer (%d 🪙 + 1 slot)" % cost,
			"disabled": false,
			"tooltip": "Deux coûts distincts : %d 🪙 de budget d'investissement tout de suite et 1 des %d slots du mandat.\nIrréversible. Les effets tombent à la Résolution." % [cost, max_activations],
		}

	return _with_shared({
		"kind": "decision",
		"pill_text": "Décision",
		"pill_color": UIHelpers.PILL_DECISION,
		"ref": card.get("refId", ""),
		"bg_color": UIHelpers.COLOR_CARD_DECISION,
		"corner_radius": 3,
		"decoration": "tape",
		"item_icon": DECISION_ICONS.get(card_id, DEFAULT_ITEM_ICON),
		"title": card.get("name", ""),
		"subtitle": card.get("category", ""),
		"tagline": card.get("tagline", ""),
		"impacts": impacts,
		"cost": "%d 🪙 · 1 slot de grande décision · %d/%d activées" % [cost, used, max_activations],
		"primary": primary,
		"dimmed": activated,
		"stamp": "ACTIVÉE" if activated else "",
		# Le tampon SVG signale le seul blocage structurel : une condition à
		# atteindre. Le manque de pièces, lui, reste une information de coût.
		"status_stamp": "blocked" if requirement.get("gated", false) and not requirement.get("ok", false) else "",
	}, "decision", card_id, card, activated)


# ── Candidat ──────────────────────────────────────────────────────────────
static func for_candidate(candidate: Dictionary) -> Dictionary:
	var role_id: String = candidate.get("role", "")
	var role_conf: Dictionary = GameData.balance.get("roles", {}).get(role_id, {})
	var seniority: String = candidate.get("seniority", "junior")
	var salary := int(candidate.get("salary", GameData.balance.get("salaries", {}).get(seniority, 1)))
	var cost: int = max(0, int(candidate.get("costPieces", 0)) - SprintState.next_hire_discount)
	var hired: bool = candidate.get("hired", false)
	var cap := SprintState.get_team_cap()
	var headcount := SprintState.get_roster().size()

	var impacts: Array = _role_impact_lines(role_id, seniority)
	impacts.append({
		"label": "💰 Masse salariale, chaque sprint",
		"delta": "−%d/sprint" % salary,
		"good": false,
		"tooltip": "Prélevée sur la Trésorerie à chaque Résolution, tant que la personne est là.",
	})
	impacts.append(_hidden_trait_line(candidate))

	var primary: Dictionary = {}
	if hired:
		primary = {"text": "Embauché·e ✓", "disabled": true}
	elif SprintState.is_quarter_requirement_active("hiringFrozen"):
		primary = {
			"text": "🧊 Embauches gelées ce trimestre",
			"disabled": true,
			"tooltip": "Exigence active : %s" % SprintState.get_quarter_requirement_text(),
		}
	elif headcount >= cap:
		primary = {"text": "Cap d'effectif atteint (%d/%d)" % [headcount, cap], "disabled": true}
	elif SprintState.pieces < cost:
		primary = {"text": "Embaucher (%d 🪙 — insuffisant)" % cost, "disabled": true}
	else:
		primary = {"text": "Embaucher (%d 🪙)" % cost, "disabled": false}

	var secondary: Dictionary = {}
	if not hired and not candidate.get("hiddenRevealed", false):
		secondary = _one_on_one_action()

	var cost_text := "%d 🪙 · effectif %d/%d → %d/%d" % [cost, headcount, cap, headcount + 1, cap]
	if SprintState.next_hire_discount > 0:
		cost_text += " · réseau −%d 🪙" % SprintState.next_hire_discount

	return _with_shared({
		"kind": "candidate",
		"pill_text": "Candidat",
		"pill_color": UIHelpers.PILL_CANDIDATE,
		"ref": "%s · %s" % [role_conf.get("label", role_id).to_upper(), seniority.to_upper()],
		"bg_color": UIHelpers.COLOR_CARD_CANDIDATE,
		"corner_radius": 3,
		"decoration": "lanyard",
		"person_name": candidate.get("name", ""),
		"title": candidate.get("name", ""),
		"subtitle": "%s %s · salaire %d 💰/sprint" % [role_conf.get("icon", "👤"), role_conf.get("label", role_id), salary],
		"tagline": candidate.get("trait", ""),
		"badges": " · ".join(candidate.get("badges", [])),
		"impacts": impacts,
		"cost": cost_text,
		"primary": primary,
		"secondary": secondary,
		"dimmed": hired,
		"stamp": "EMBAUCHÉ·E" if hired else "",
	}, "candidate", candidate.get("id", ""), candidate, hired)


# ── Pratique ──────────────────────────────────────────────────────────────
static func for_practice(practice: Dictionary) -> Dictionary:
	var practice_id: String = practice.get("id", "")
	var owned: bool = SprintState.has_practice(practice_id)
	var cost := int(practice.get("costPieces", 0))
	var flavor_and_effect := _practice_flavor_and_effect(practice)

	var impacts: Array = [{
		"label": "🔓 %s" % flavor_and_effect[1],
		"delta": "définitif",
		"good": true,
	}]
	for resource_id in practice.get("perSprint", {}).keys():
		var value := float(practice.get("perSprint", {})[resource_id])
		impacts.append({
			"label": "%s, chaque sprint" % EffectResolver.resource_label(resource_id),
			"delta": "%s/sprint" % signed(int(value)),
			"good": EffectResolver.delta_is_good(resource_id, value),
		})
	var cynisme := int(GameData.balance.get("shopDraw", {}).get("practiceCynisme", 2))
	impacts.append({
		"label": "🎭 Cynisme — un process de plus",
		"delta": signed(cynisme),
		"good": false,
		"tooltip": "Toute pratique adoptée coûte du Cynisme : l'organisation lève les yeux au ciel avant d'essayer.",
	})

	var primary: Dictionary = {}
	if owned:
		primary = {"text": "Adoptée ✓", "disabled": true}
	elif SprintState.pieces < cost:
		primary = {"text": "Adopter (%d 🪙 — insuffisant)" % cost, "disabled": true}
	else:
		primary = {"text": "Adopter (%d 🪙)" % cost, "disabled": false}

	return _with_shared({
		"kind": "practice",
		"pill_text": "Pratique",
		"pill_color": UIHelpers.PILL_PRACTICE,
		"ref": PRACTICE_FAMILIES.get(practice.get("unlocks", ""), "PRATIQUE"),
		"bg_color": UIHelpers.COLOR_CARD_PRACTICE,
		"corner_radius": 1,
		"decoration": "tape",
		"item_icon": PRACTICE_ICONS.get(practice_id, DEFAULT_ITEM_ICON),
		"title": practice.get("name", ""),
		"subtitle": "permanente pour le mandat",
		"tagline": flavor_and_effect[0],
		"impacts": impacts,
		"cost": "%d 🪙" % cost,
		"primary": primary,
		"dimmed": owned,
		"stamp": "ADOPTÉE" if owned else "",
	}, "practice", practice_id, practice, owned)


# ── Ce que les trois types partagent : rareté et punaise ──────────────────

## Libellés et couleurs des paliers de rareté. `commune` n'affiche rien : un
## marquage qui apparaît sur toutes les cartes ne marque plus rien — c'est
## l'exception qui doit se voir.
const RARITY_LABELS := {
	"notable": "◆ NOTABLE",
	"rare": "◆◆ RARE",
}
const RARITY_COLORS := {
	"notable": Color("#23408e"),
	"rare": Color("#8a3fbf"),
}


## Ajoute au descripteur ce qui ne dépend pas du type : le liseré de rareté et
## l'action 📌 Réserver. `acquired` coupe la punaise — on ne réserve pas ce
## qu'on possède déjà.
static func _with_shared(descriptor: Dictionary, kind: String, asset_id: String, data: Dictionary, acquired: bool) -> Dictionary:
	var rarity: String = SprintState.asset_rarity(data)
	descriptor["rarity"] = rarity
	descriptor["rarity_label"] = RARITY_LABELS.get(rarity, "")
	descriptor["rarity_color"] = RARITY_COLORS.get(rarity, UIHelpers.COLOR_SOFT_TEXT)

	if acquired:
		return descriptor

	var reserved: bool = SprintState.is_reserved(kind, asset_id)
	descriptor["pin"] = {
		"active": reserved,
		"text": "📌" if reserved else "📍",
		"tooltip": ("Réservé — cet Actif sera encore là au prochain sprint, et un re-tirage ne l'emporte pas. Cliquez pour décoller la punaise et récupérer la pièce."
			if reserved else
			"📌 Réserver pour %d 🪙 — il sera encore là au prochain sprint (et un 🎲 re-tirage ne l'emportera pas)." % SprintState.reserve_cost()),
		"disabled": not reserved and SprintState.pieces < SprintState.reserve_cost(),
	}
	return descriptor


# ── Fabriques d'impacts partagées ─────────────────────────────────────────

## Ce que le rôle apporte réellement, lu dans balance.json → roles : de la
## capacité de roadmap pour les Devs et les PM, et pour Designer et Ops la
## levée de la pénalité que leur absence fait payer (spec profondeur §4.2).
static func _role_impact_lines(role_id: String, seniority: String) -> Array:
	var role_conf: Dictionary = GameData.balance.get("roles", {}).get(role_id, {})
	var lines: Array = []

	var capacity := int(role_conf.get("capacityPerEmployee", {}).get(seniority, 0))
	if capacity > 0:
		lines.append({
			"label": "⚙️ Capacité de roadmap",
			"delta": "+%d pts" % capacity,
			"good": true,
			"tooltip": "Rendements décroissants au-delà de %d personnes du même rôle." % int(role_conf.get("fullYieldCount", 99)),
		})

	match role_id:
		"pm":
			lines.append({
				"label": "📋 Amortit la surchauffe de roadmap",
				"delta": "−%d %%" % int(float(role_conf.get("overloadReductionPerPm", 0.25)) * 100.0),
				"good": true,
				"tooltip": "Réduction plafonnée à −%d %% de la pénalité de dépassement de capacité." % int(float(role_conf.get("overloadReductionMax", 0.5)) * 100.0),
			})
		"designer":
			if SprintState.get_role_weight("designer") <= 0.0:
				lines.append({
					"label": "📈 Sans Designer, les effets Valeur perçue sont divisés par %d" % int(role_conf.get("valeurEffectsDivisorIfAbsent", 2)),
					"delta": "fin du ÷%d" % int(role_conf.get("valeurEffectsDivisorIfAbsent", 2)),
					"good": true,
				})
			else:
				lines.append({
					"label": "📈 Valeur perçue par feature livrée",
					"delta": "+%d (max +%d)" % [
						int(role_conf.get("valeurPerFeatureDelivered", 1)),
						int(role_conf.get("valeurPerFeatureDeliveredMax", 2)),
					],
					"good": true,
				})
		"ops":
			if SprintState.get_role_weight("ops") <= 0.0:
				lines.append({
					"label": "🧱 Personne aux manettes Ops : la dette monte de +%d/sprint" % int(role_conf.get("dettePerSprintIfAbsent", 2)),
					"delta": "fin de la dérive",
					"good": true,
				})
			else:
				lines.append({
					"label": "🧱 Entretien de la dette organisationnelle",
					"delta": "%d/sprint" % int(role_conf.get("dettePerOps", -1)),
					"good": true,
				})
	return lines


## L'inconnu est une ligne d'impact comme les autres (proposition UI §2.2) :
## le pari est affiché à la même place que les deltas connus, et acheter de
## l'information (1:1, Entretiens structurés) transforme la ligne 🔒 en ligne
## lisible, sur place.
static func _hidden_trait_line(person: Dictionary) -> Dictionary:
	if not person.get("hiddenRevealed", false):
		return {
			"label": "🔒 Trait caché — révélé en fin de période d'essai",
			"delta": "❓",
			"locked": true,
			"unknown": true,
			"tooltip": "Un 🤝 1:1 (%d ⚡) le révèle avant de signer." % SprintState.get_personal_action_cost("oneOnOne"),
		}

	var hidden_trait: Dictionary = SprintState.get_hidden_trait(person.get("hidden_trait", ""))
	if hidden_trait.is_empty():
		return {
			"label": "🔓 Rien à signaler. Vraiment.",
			"delta": "révélé",
			"good": true,
		}
	return {
		"label": "%s %s — %s" % [
			hidden_trait.get("icon", ""), hidden_trait.get("name", ""), hidden_trait.get("description", "")
		],
		"delta": "révélé",
		"good": hidden_trait.get("polarity", "negative") == "positive",
	}


## Action personnelle secondaire de la carte candidat : payer en Énergie la
## révélation du trait caché avant de signer (spec profondeur §7.2).
static func _one_on_one_action() -> Dictionary:
	var cost := SprintState.get_personal_action_cost("oneOnOne")
	match SprintState.personal_action_refusal():
		"souffler":
			return {"text": "🤝 1:1 — 🧘 vous soufflez", "disabled": true}
		"epuise":
			return {"text": "🤝 1:1 (%d ⚡ — épuisé·e)" % cost, "disabled": true}
		_:
			return {
				"text": "🤝 1:1 (%d ⚡)" % cost,
				"disabled": false,
				"tooltip": "Un vrai entretien, pas un pitch — révèle le trait caché avant embauche.",
			}


## Les descriptions de practices.json sont écrites « accroche. effet. » : la
## première phrase a du mordant, la seconde annonce la mécanique. On sépare les
## deux pour que l'accroche aille en zone ③ et l'effet en zone ④, sans écrire le
## texte deux fois. Repli sur PRACTICE_UNLOCK_LABELS si la forme change.
static func _practice_flavor_and_effect(practice: Dictionary) -> Array:
	var description: String = practice.get("description", "")
	var fallback: String = PRACTICE_UNLOCK_LABELS.get(practice.get("unlocks", ""), "Effet permanent pour le mandat")
	var cut := description.find(". ")
	if cut == -1:
		return [description, fallback]
	return [description.substr(0, cut + 1), description.substr(cut + 2).strip_edges()]


static func signed(value: int) -> String:
	return "%s%d" % ["+" if value >= 0 else "−", abs(value)]


static func _team_profile_label() -> String:
	for profile in GameData.cards.get("teamProfiles", []):
		if profile.get("id", "") == SprintState.team_profile:
			return profile.get("shortLabel", SprintState.team_profile)
	return SprintState.team_profile
