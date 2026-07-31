extends PanelContainer
## Le **Panneau de bord** — l'entreprise toujours à l'écran
## (docs/proposition-ui-interface.md §4). Colonne fixe à droite des écrans de
## phase, il remplace la barre de ressources horizontale : ce qu'on consulte à
## chaque décision devient permanent, ce qu'on lit une fois par mandat reste
## derrière le bouton « Dossier entreprise ».
##
## Diégétiquement, c'est l'écran TV du standup accroché au tableau blanc : un
## îlot sombre dans un monde clair (palette UIHelpers.PANEL_*). Il garantit la
## lisibilité des chiffres là où le post-it échouerait.
##
## Trois choix structurants, tous visibles ici :
##  1. les jauges sont des **barres** et non des pourcentages — c'est la
##     géométrie sur laquelle la preview d'impact du Lot 3 viendra projeter son
##     segment fantôme ;
##  2. le roster est lisible d'un coup d'œil et **actionnable en un clic**
##     (🤝 1:1 · licencier, avec confirmation) ;
##  3. le quota et son bonus qualitatif sont **évalués en direct** — la cible
##     et les arbitrages du trimestre restent lisibles à chaque décision.
##
## Aucun état ne vit ici : tout est relu dans SprintState à chaque refresh().
## L'écran hôte appelle refresh() quand il modifie l'état, et écoute
## `state_changed` quand c'est le panneau qui l'a modifié (embauche annulée par
## un licenciement, 1:1 qui consomme de l'Énergie…).
##
## Piège Godot : une barre de jauge est un `Control` nu avec deux `Panel`
## enfants positionnés à la main. Un conteneur étirerait le remplissage sur
## toute la largeur et **toutes les jauges paraîtraient pleines**.
##
## Refonte UI Lot 3 (docs/proposition-ui-interface.md §5) — ressentir ses
## achats, sans rien changer à la mécanique (Option 1, actée le 30/07/2026) :
##  - **Engagement (§5.3)** : chaque jauge affiche `valeur + pendings` (les
##    deltas déjà décidés ce sprint mais appliqués seulement à la Résolution),
##    avec un marqueur ▲ à l'ancienne valeur et un liseré « engagé ce sprint ».
##    Détecté tout seul d'un `_build()` à l'autre (`_last_engaged` etc.) : pas
##    besoin qu'un écran hôte prévienne le panneau qu'un achat vient d'avoir
##    lieu, `refresh()` suffit, comme avant.
##  - **Preview au survol (§5.1)** : `show_preview()`/`clear_preview()`,
##    branchées par l'écran hôte sur `AssetCard.preview_requested/_cleared`,
##    ajoutent un segment fantôme hachuré (`UIHelpers.HatchOverlay`) entre la
##    valeur engagée et la valeur hypothétique, une chip de delta, une chip ❓
##    scintillante sur les jauges qu'un trait cachée non révélé peut toucher,
##    et estompent les jauges non concernées.
##  - **Impulsion (§5.2)** : `gauge_global_rect()`/`pieces_global_rect()`
##    donnent à l'écran hôte de quoi faire voler une chip depuis la carte
##    (`UIHelpers.fly_chip()`) ; le tween de jauge et le punch de valeur sont
##    automatiques (même détection de changement que l'engagement).

signal state_changed

const BAR_HEIGHT := 8

## Largeur du **rail replié** : de quoi garder les six jauges lisibles en
## vignette et rendre 260 px à l'écran de phase. Sur les Investissements, qui
## empilent deux rayons, ça vaut une colonne de cartes entière.
const RAIL_WIDTH := 62

## Durées d'animation du Lot 3 (présentation pure — groupées ici, voir
## CLAUDE.md « Conventions de code »).
const GAUGE_TWEEN_DURATION := 0.3
const VALUE_PUNCH_DURATION := 0.22
const PIECES_ROLL_DURATION := 0.35
const SLIDE_IN_DURATION := 0.25

## Distance de départ du slide-in d'une nouvelle ligne de roster (§5.2) — pas
## une durée, mais une géométrie de présentation pure au même titre : groupée ici.
const ROSTER_SLIDE_OFFSET := 28.0

var collapsed := false

var _dossier: Control = null
var _fire_dialog: ConfirmationDialog = null
var _pending_fire_id: String = ""

## Preview d'impact active (survol d'une carte d'Actif) — {} si aucune.
## {"resource_deltas": {resource_id: delta}, "pieces_cost": float,
##  "unknown_resource_ids": [resource_id, ...]}, posé par AssetView.
var _preview: Dictionary = {}

## Ce que le panneau a affiché au `_build()` précédent — sert uniquement à
## détecter un changement d'un affichage à l'autre pour l'animer (jauges,
## pièces, roster). Absent d'une clé = « pas encore affiché », auquel cas on
## n'anime pas (premier rendu, ou jauge restée masquée le temps d'un repli).
var _last_engaged: Dictionary = {}       # resource_id -> float
var _last_pieces: int = -1
var _last_roster_ids: Array = []
var _roster_initialized: bool = false

## Rectangles globaux des jauges affichées ce `_build()` — permet à l'écran
## hôte de viser une chip volante (impulsion, §5.2) sans que le panneau ait
## besoin de connaître les cartes qui l'entourent.
var _gauge_nodes: Dictionary = {}        # resource_id -> Control (la barre)
var _pieces_node: Control = null


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = UIHelpers.PANEL_BG
	style.border_color = UIHelpers.COLOR_INK
	style.border_width_left = 8
	add_theme_stylebox_override("panel", style)

	var host := get_parent()
	if host is Control:
		_dossier = UIHelpers.instantiate_company_dossier(host)

	_apply_width()
	_build()


## Le panneau est ancré à droite : sa largeur vient de son `offset_left`, pas
## d'un conteneur. `attach_side_panel()` recale la marge de l'écran hôte sur
## `resized`, donc la place rendue par le rail est immédiatement rendue aux
## cartes.
func _apply_width() -> void:
	var width := RAIL_WIDTH if collapsed else UIHelpers.SIDE_PANEL_WIDTH
	custom_minimum_size = Vector2(width, 0)
	offset_left = -float(width)

	var margin: MarginContainer = get_node("Margin")
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 8 if collapsed else 16)


func _toggle_collapsed() -> void:
	collapsed = not collapsed
	_apply_width()
	_build()


## À appeler après toute modification d'état faite par l'écran hôte (achat,
## embauche, action personnelle) : le panneau est reconstruit de zéro, comme la
## barre de ressources l'était avant lui. Si l'état affiché a changé depuis le
## dernier `_build()` (une jauge, les pièces, le roster), la reconstruction
## anime la transition toute seule — voir `_last_engaged` et consorts.
func refresh() -> void:
	_build()
	if _dossier != null and _dossier.has_method("refresh"):
		_dossier.refresh()


## Preview d'impact au survol d'une carte d'Actif (Lot 3 §5.1) — appelée par
## l'écran hôte sur `AssetCard.preview_requested`. `preview` est le champ posé
## par AssetView sur le descripteur de la carte survolée.
func show_preview(preview: Dictionary) -> void:
	_preview = preview
	if not collapsed:
		_build()


## Fin du survol — `AssetCard.preview_cleared`.
func clear_preview() -> void:
	if _preview.is_empty():
		return
	_preview = {}
	if not collapsed:
		_build()


## Rectangle global de la jauge d'une ressource (ou de l'Énergie, id
## "energie") tel qu'affiché au dernier `_build()` — {} / Rect2() si la jauge
## n'est pas actuellement visible (panneau replié). Sert de cible à
## `UIHelpers.fly_chip()` pour l'impulsion à l'achat (§5.2).
func gauge_global_rect(resource_id: String) -> Rect2:
	var node: Control = _gauge_nodes.get(resource_id, null)
	if node == null or not is_instance_valid(node):
		return Rect2()
	return node.get_global_rect()


## Même chose pour la ligne 🪙 Pièces.
func pieces_global_rect() -> Rect2:
	if _pieces_node == null or not is_instance_valid(_pieces_node):
		return Rect2()
	return _pieces_node.get_global_rect()


func _build() -> void:
	_gauge_nodes = {}
	_pieces_node = null
	var vbox: VBoxContainer = get_node("Margin/Scroll/VBox")
	# Le panneau se reconstruit depuis ses propres boutons (roster, repli,
	# dossier) : voir UIHelpers.clear_children() pour pourquoi pas de `free()`.
	UIHelpers.clear_children(vbox)

	if collapsed:
		_build_rail(vbox)
		return

	vbox.add_child(_collapse_button("◂  Replier", "Replier le panneau en rail : les six jauges restent lisibles et l'écran récupère %d px." % (UIHelpers.SIDE_PANEL_WIDTH - RAIL_WIDTH)))
	_build_header(vbox)
	vbox.add_child(_rule())

	vbox.add_child(_group_label("Entreprise"))
	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		if resource_id == "capital-politique":
			continue  # celle-là est à vous, pas à l'entreprise : bloc « Vous »
		vbox.add_child(_resource_gauge(resource))
	vbox.add_child(_pieces_row())
	vbox.add_child(_rule())

	vbox.add_child(_group_label("Vous"))
	for resource in GameData.resources:
		if resource.get("id", "") == "capital-politique":
			vbox.add_child(_resource_gauge(resource))
	vbox.add_child(_energy_gauge())
	vbox.add_child(_spaced(_rule(), 8, 0))

	_build_team(vbox)
	_build_assets(vbox)
	_build_quota(vbox)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	filler.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(filler)

	var dossier_button := Button.new()
	dossier_button.text = "🏢 Dossier entreprise"
	dossier_button.tooltip_text = "Le contexte long : scénario, modèle économique, objectifs commentés, roster détaillé, rallonge."
	dossier_button.add_theme_font_size_override("font_size", 13)
	dossier_button.pressed.connect(_on_dossier_pressed)
	vbox.add_child(_spaced(dossier_button, 12, 0))


# ── Le rail replié ───────────────────────────────────────────────────────
## Ce qui survit au repli : les six jauges en vignette (barre + valeur, pas de
## libellé — l'icône suffit une fois qu'on les connaît), les pièces et
## l'Énergie. Tout le reste — roster, actifs, détail du quota — se retrouve en
## dépliant. Les tooltips restent complets : le rail n'enlève pas
## l'information, il enlève la place qu'elle prend.
func _build_rail(vbox: VBoxContainer) -> void:
	vbox.add_child(_collapse_button("▸", "Déplier le Panneau de bord"))

	var sprint := _label("S%d\nT%d" % [SprintState.sprint_number, SprintState.quarter_index], 10, UIHelpers.PANEL_MUTED)
	UIHelpers.apply_mono(sprint, 10)
	sprint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sprint.tooltip_text = _quota_tooltip()
	vbox.add_child(_spaced(sprint, 2, 6))

	var quota := SprintState.get_quarter_progress()
	var quota_label := _label("%d/%d" % [int(quota.get("impact", 0)), int(quota.get("quota", 0))], 9, UIHelpers.PANEL_ACCENT)
	quota_label.name = "QuotaRail"
	quota_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quota_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quota_label.tooltip_text = _quota_tooltip()
	vbox.add_child(_spaced(quota_label, 0, 4))

	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		var value: float = SprintState.resource_values.get(resource_id, 0.0)
		var state := EffectResolver.gauge_state(resource_id, value)
		vbox.add_child(_rail_gauge(
			resource.get("icon", "•"), value, 100.0,
			UIHelpers.panel_state_color(state), UIHelpers.resource_tooltip(resource)
		))

	vbox.add_child(_spaced(_rule(), 6, 6))
	vbox.add_child(_rail_gauge("⚡", float(SprintState.energy), float(SprintState.get_energy_max()),
		UIHelpers.panel_state_color(EffectResolver.gauge_state("", float(SprintState.energy))),
		UIHelpers.energy_tooltip()))

	var pieces := _label("🪙\n%d" % SprintState.pieces, 12, UIHelpers.PANEL_FG)
	pieces.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pieces.tooltip_text = "🪙 Budget d'investissement — les moyens disponibles pour recruter, adopter des pratiques et activer des décisions."
	pieces.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(_spaced(pieces, 8, 0))


func _rail_gauge(icon: String, value: float, maximum: float, color: Color, tooltip: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.tooltip_text = tooltip

	var head := _label("%s %d" % [icon, int(round(value))], 10, UIHelpers.PANEL_FG)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)

	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 5)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := Panel.new()
	track.add_theme_stylebox_override("panel", _flat(Color(1, 1, 1, 0.09), 3))
	bar.add_child(track)
	var fill := Panel.new()
	fill.add_theme_stylebox_override("panel", _flat(color, 3))
	bar.add_child(fill)
	var ratio: float = clampf(value / maxf(maximum, 1.0), 0.0, 1.0)
	var layout := func():
		track.position = Vector2.ZERO
		track.size = Vector2(bar.size.x, 5)
		fill.position = Vector2.ZERO
		fill.size = Vector2(round(bar.size.x * ratio), 5)
	layout.call()
	bar.resized.connect(layout)
	box.add_child(bar)

	return _spaced(box, 3, 3)


func _collapse_button(text: String, tooltip: String) -> Control:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", UIHelpers.PANEL_MUTED)
	button.add_theme_color_override("font_hover_color", UIHelpers.PANEL_ACCENT)
	button.pressed.connect(_toggle_collapsed)
	return button


# ── En-tête : qui joue, où on en est ─────────────────────────────────────
func _build_header(vbox: VBoxContainer) -> void:
	vbox.add_child(_label("● ÉCRAN DE STANDUP", 9, UIHelpers.PANEL_MUTED))

	var company: Dictionary = SprintState.get_company()
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 3)

	var top := HBoxContainer.new()
	# Le nom d'entreprise s'enroule : sans ça, un nom long impose sa largeur au
	# panneau entier (la ScrollContainer propage la taille minimale de son
	# contenu) et la colonne recouvre l'écran de phase.
	var name_label := _label("%s %s" % [company.get("icon", "🏢"), company.get("name", "Entreprise")],
		15, UIHelpers.PANEL_FG, true)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIHelpers.apply_heading(name_label, 15, 600.0)
	top.add_child(name_label)
	var sprint_label := _label("SPRINT %d · T%d · %d/%d" % [
		SprintState.sprint_number, SprintState.quarter_index,
		SprintState.quarter_sprint + 1, SprintState.get_quarter_length()
	], 11, UIHelpers.PANEL_MUTED)
	UIHelpers.apply_mono(sprint_label, 11)
	sprint_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(sprint_label)
	head.add_child(top)

	# Le badge de profil d'équipe vit ici depuis la refonte : c'est un trait de
	# la run, pas de la phase (proposition UI §3.3).
	head.add_child(_label("%s · %s" % [_team_profile_label(), SprintState.get_business_model().get("label", "—")],
		10, UIHelpers.PANEL_MUTED, true))
	vbox.add_child(_spaced(head, 10, 10))


# ── Jauges en barres ─────────────────────────────────────────────────────
func _resource_gauge(resource: Dictionary) -> Control:
	var resource_id: String = resource.get("id", "")
	var base_value: float = SprintState.resource_values.get(resource_id, 0.0)
	var pending: float = SprintState.pending_deltas.get(resource_id, 0.0)
	var state := EffectResolver.gauge_state(resource_id, base_value + pending)
	return _gauge(
		resource.get("icon", ""), resource.get("name", ""), resource_id,
		base_value, 100.0, UIHelpers.panel_state_color(state), UIHelpers.resource_tooltip(resource)
	)


func _energy_gauge() -> Control:
	var maximum := float(SprintState.get_energy_max())
	var state := EffectResolver.gauge_state("energie", float(SprintState.energy))
	var gauge := _gauge("⚡", "Énergie", "energie", float(SprintState.energy), maximum,
		UIHelpers.panel_state_color(state), UIHelpers.energy_tooltip())
	if SprintState.breather_planned:
		var note := _label("🧘 Vous soufflez ce sprint : aucune action personnelle.", 9, UIHelpers.PANEL_ACCENT, true)
		var wrapper := VBoxContainer.new()
		wrapper.add_theme_constant_override("separation", 2)
		wrapper.add_child(gauge)
		wrapper.add_child(note)
		return wrapper
	return gauge


## Une jauge en barre, avec **engagement** (§5.3, toujours actif) et **preview**
## (§5.1, seulement pendant `_preview`).
##
## Engagement : `base_value` est la valeur réellement appliquée (celle d'après
## la dernière Résolution) ; `pending` (lu dans SprintState.pending_deltas) est
## la somme des décisions déjà prises ce sprint mais pas encore appliquées —
## Option 1 de la proposition, rien n'est appliqué avant la Résolution, seule
## la lecture change. `engaged_value = base_value + pending` est ce que la
## barre affiche, avec un ▲ discret à `base_value` et un liseré d'accent tant
## que `pending != 0`. Le passage d'un `_build()` à l'autre est comparé à
## `_last_engaged` : s'il a bougé, la barre et la valeur s'y animent au lieu de
## sauter (impulsion, §5.2).
##
## Preview : `_preview.resource_deltas` ajoute un second segment hachuré entre
## `engaged_value` et la valeur hypothétique si l'action survolée est jouée,
## plus une chip de delta ; `_preview.unknown_resource_ids` affiche un ❓
## scintillant à la place (trait caché non révélé) ; les seuils franchis
## ajoutent une ligne ⚠️ (EffectResolver.threshold_consequences()) ; les jauges
## non concernées par la preview en cours s'estompent.
func _gauge(icon: String, name: String, resource_id: String, base_value: float, maximum: float, color: Color, tooltip: String) -> Control:
	var pending: float = SprintState.pending_deltas.get(resource_id, 0.0)
	var engaged_value: float = clampf(base_value + pending, 0.0, maximum)
	var is_engaged: bool = not is_zero_approx(pending)

	var animate_from: float = _last_engaged.get(resource_id, engaged_value)
	_last_engaged[resource_id] = engaged_value
	var should_animate: bool = not is_equal_approx(animate_from, engaged_value)

	var preview_deltas: Dictionary = _preview.get("resource_deltas", {})
	var preview_delta: float = float(preview_deltas.get(resource_id, 0.0))
	var is_unknown: bool = (_preview.get("unknown_resource_ids", []) as Array).has(resource_id)
	var is_concerned: bool = not is_zero_approx(preview_delta) or is_unknown
	var preview_target: float = clampf(engaged_value + preview_delta, 0.0, maximum)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.tooltip_text = tooltip
	if _preview_active() and not is_concerned:
		vbox.modulate.a = 0.35  # « les jauges non concernées s'estompent » (§5.1)

	var top := HBoxContainer.new()
	top.add_child(_label("%s %s" % [icon, name], 11, UIHelpers.PANEL_FG))
	top.add_child(_spacer_h())
	if is_unknown:
		top.add_child(_blinking_chip("❓", UIHelpers.PANEL_WARN))
	elif not is_zero_approx(preview_delta):
		top.add_child(_delta_chip(preview_delta, UIHelpers.PANEL_GOOD if EffectResolver.delta_is_good(resource_id, preview_delta) else UIHelpers.PANEL_DANGER))

	var value_label := _label("%d" % int(round(engaged_value)), 11, UIHelpers.PANEL_FG)
	UIHelpers.apply_mono(value_label, 11, true)
	value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var value_wrap := UIHelpers.wrap_animatable(value_label)
	value_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(value_wrap)
	vbox.add_child(top)

	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge_nodes[resource_id] = bar

	var track := Panel.new()
	track.add_theme_stylebox_override("panel", _flat(Color(1, 1, 1, 0.09), 4))
	bar.add_child(track)

	var fill := Panel.new()
	fill.add_theme_stylebox_override("panel", _engaged_fill_style(color, is_engaged))
	bar.add_child(fill)

	var origin_marker: Control = null
	if is_engaged:
		origin_marker = _origin_marker()
		bar.add_child(origin_marker)

	var ghost: Control = null
	if is_concerned and not is_zero_approx(preview_delta):
		ghost = UIHelpers.HatchOverlay.new()
		ghost.hatch_color = UIHelpers.PANEL_GOOD if EffectResolver.delta_is_good(resource_id, preview_delta) else UIHelpers.PANEL_DANGER
		bar.add_child(ghost)

	var base_ratio: float = clampf(base_value / maxf(maximum, 1.0), 0.0, 1.0)
	var engaged_ratio: float = clampf(engaged_value / maxf(maximum, 1.0), 0.0, 1.0)
	var preview_ratio: float = clampf(preview_target / maxf(maximum, 1.0), 0.0, 1.0)
	fill.set_meta("ratio", clampf(animate_from / maxf(maximum, 1.0), 0.0, 1.0))

	var layout := func():
		track.position = Vector2.ZERO
		track.size = Vector2(bar.size.x, BAR_HEIGHT)
		fill.position = Vector2.ZERO
		fill.size = Vector2(round(bar.size.x * float(fill.get_meta("ratio", engaged_ratio))), BAR_HEIGHT)
		if origin_marker != null:
			origin_marker.position = Vector2(round(bar.size.x * base_ratio) - 2.0, -3.0)
		if ghost != null:
			var from_x: float = round(bar.size.x * engaged_ratio)
			var to_x: float = round(bar.size.x * preview_ratio)
			ghost.position = Vector2(minf(from_x, to_x), 0.0)
			ghost.size = Vector2(maxf(absf(to_x - from_x), 2.0), BAR_HEIGHT)
	layout.call()
	bar.resized.connect(layout)
	vbox.add_child(bar)

	if should_animate:
		# Créés sur le nœud animé, pas sur `self` (le panneau, qui survit à la
		# jauge) : `_build()` reconstruit tout à chaque refresh(), et un tween
		# créé sur `self` continuerait à tourner après que `fill`/`value_wrap`
		# aient été libérés par `UIHelpers.clear_children()` — la fermeture de
		# `tween_method` appellerait alors une méthode sur un objet mort.
		# `Node.create_tween()` tue automatiquement le tween quand le nœud sur
		# lequel il a été créé est libéré.
		var ratio_tween := fill.create_tween()
		ratio_tween.tween_method(func(r: float):
			fill.set_meta("ratio", r)
			layout.call()
		, float(fill.get_meta("ratio")), engaged_ratio, GAUGE_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		value_wrap.pivot_offset = value_wrap.size / 2.0
		var punch_tween := value_wrap.create_tween()
		punch_tween.tween_property(value_wrap, "scale", Vector2(1.35, 1.35), VALUE_PUNCH_DURATION * 0.4) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		punch_tween.tween_property(value_wrap, "scale", Vector2.ONE, VALUE_PUNCH_DURATION * 0.6) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	if is_engaged:
		vbox.add_child(_label("engagé ce sprint · ▲ %d avant Résolution" % int(round(base_value)), 8, UIHelpers.PANEL_ACCENT))

	if is_concerned:
		for line in EffectResolver.threshold_consequences(resource_id, engaged_value, preview_target, SprintState.era_id):
			vbox.add_child(_label("⚠️ %s → %d : %s" % [icon, int(round(preview_target)), line], 9, UIHelpers.PANEL_WARN, true))

	return _spaced(vbox, 3, 3)


## Une preview « active » a quelque chose à montrer — un dict vide (carte déjà
## acquise, ou aucun survol) ne doit ni estomper ni surligner quoi que ce soit.
func _preview_active() -> bool:
	if not (_preview.get("unknown_resource_ids", []) as Array).is_empty():
		return true
	if not is_zero_approx(float(_preview.get("pieces_cost", 0.0))):
		return true
	for delta in (_preview.get("resource_deltas", {}) as Dictionary).values():
		if not is_zero_approx(float(delta)):
			return true
	return false


func _delta_chip(value: float, color: Color) -> Control:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.18)
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	chip.add_theme_stylebox_override("panel", style)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := _label("%s%d" % ["+" if value >= 0.0 else "−", int(round(absf(value)))], 10, color)
	UIHelpers.apply_mono(label, 10, true)
	chip.add_child(label)
	return chip


## Chip ❓ scintillante — « ici, vous pariez » (§5.1). La pulsation est portée
## par `modulate:a`, jamais par `scale`/`rotation` : le nœud vit directement
## dans une HBoxContainer, qui les écraserait à chaque tri.
func _blinking_chip(text: String, color: Color) -> Control:
	var label := _label(text, 12, color)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Créé sur `label`, pas sur `self` : la boucle est infinie
	# (`set_loops()` sans argument), et `self` (le panneau) survit à ce chip
	# le temps que dure la preview — sans ce nœud comme point d'ancrage, le
	# tween tournerait indéfiniment pour rien une fois le chip libéré.
	var tween := label.create_tween().set_loops()
	tween.tween_property(label, "modulate:a", 0.25, 0.55).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	return label


func _origin_marker() -> Control:
	var marker := Label.new()
	marker.text = "▲"
	marker.add_theme_font_size_override("font_size", 9)
	marker.add_theme_color_override("font_color", UIHelpers.PANEL_ACCENT)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return marker


func _engaged_fill_style(color: Color, engaged: bool) -> StyleBoxFlat:
	var style := _flat(color, 4)
	if engaged:
		style.border_color = UIHelpers.PANEL_ACCENT
		style.set_border_width_all(1)
	return style


func _pieces_row() -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.tooltip_text = "🪙 Budget d'investissement.\nSe gagne : Impact du sprint, allocation plancher et combo Quick wins.\nSe dépense : embauches, pratiques, indemnités de licenciement."
	var label := _label("🪙 Budget d'investissement", 12, UIHelpers.PANEL_FG, true)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(_spacer_h())

	if _preview_active():
		var cost := float(_preview.get("pieces_cost", 0.0))
		if not is_zero_approx(cost):
			row.add_child(_delta_chip(-cost, UIHelpers.PANEL_DANGER))
		else:
			row.modulate.a = 0.35

	var current := SprintState.pieces
	var animate_from: int = _last_pieces if _last_pieces >= 0 else current
	_last_pieces = current
	var should_animate: bool = animate_from != current

	var value := _label("%d" % (animate_from if should_animate else current), 13, UIHelpers.PANEL_FG)
	UIHelpers.apply_mono(value, 13, true)
	var value_wrap := UIHelpers.wrap_animatable(value)
	value_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(value_wrap)
	_pieces_node = row

	if should_animate:
		# Sur `value`, pas sur `self` — même raison qu'en `_gauge()` : sans ça,
		# le tween survivrait au `_build()` suivant et sa fermeture appellerait
		# `.text =` sur un Label déjà libéré (observé au smoke test UI, qui
		# enchaîne les refresh() sans laisser les animations finir).
		var tween := value.create_tween()
		tween.tween_method(func(v: int): value.text = "%d" % v, animate_from, current, PIECES_ROLL_DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	return _spaced(row, 6, 8)


# ── Équipe : le roster enfin permanent, et actionnable ───────────────────
func _build_team(vbox: VBoxContainer) -> void:
	var roster: Array = SprintState.get_roster()
	var head := HBoxContainer.new()
	var title := _label("ÉQUIPE", 10, UIHelpers.PANEL_ACCENT)
	UIHelpers.apply_mono(title, 10, true)
	head.add_child(title)
	head.add_child(_spacer_h())
	var stats := _label("%d/%d · %d pts · %d 💰/sprint" % [
		roster.size(), SprintState.get_team_cap(),
		SprintState.get_effective_capacity(), SprintState.get_payroll()
	], 10, UIHelpers.PANEL_MUTED)
	UIHelpers.apply_mono(stats, 10)
	stats.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(stats)
	vbox.add_child(_spaced(head, 10, 6))

	if roster.is_empty():
		vbox.add_child(_label("Plus personne. Une organisation parfaitement silencieuse.", 10, UIHelpers.PANEL_MUTED, true))
		_last_roster_ids = []
		_roster_initialized = true
		return

	# Embauche (§5.2) : « la ligne apparaît dans le roster du panneau en
	# slide-in ». Détectée comme l'engagement des jauges — en comparant le
	# roster de ce `_build()` à celui du précédent — plutôt qu'un signal que
	# l'écran hôte devrait déclencher. `_roster_initialized` évite de faire
	# glisser tout le monde au premier affichage du panneau.
	var roster_ids: Array = []
	var new_ids: Array = []
	for employee in roster:
		var employee_id: String = employee.get("id", "")
		roster_ids.append(employee_id)
		if _roster_initialized and not _last_roster_ids.has(employee_id):
			new_ids.append(employee_id)
	_last_roster_ids = roster_ids
	_roster_initialized = true

	for employee in roster:
		vbox.add_child(_team_row(employee, new_ids.has(employee.get("id", ""))))


func _team_row(employee: Dictionary, slide_in: bool = false) -> Control:
	var roles: Dictionary = GameData.balance.get("roles", {})
	var role_conf: Dictionary = roles.get(employee.get("role", ""), {})
	var revealed: bool = employee.get("hiddenRevealed", false)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.tooltip_text = _employee_tooltip(employee, role_conf)
	row.gui_input.connect(_on_team_row_input.bind(employee.get("id", "")))

	row.add_child(UIHelpers.make_person_badge(employee.get("name", ""), 22))

	var name_label := _label(employee.get("name", ""), 11, UIHelpers.PANEL_FG)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_label)

	var suffix := " 🔒" if not revealed else _hidden_trait_icon(employee)
	var role_label := _label("%s %s%s" % [
		role_conf.get("label", employee.get("role", "")), employee.get("seniority", ""), suffix
	], 10, UIHelpers.PANEL_MUTED)
	UIHelpers.apply_mono(role_label, 10)
	role_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(role_label)

	var spaced := _spaced(row, 3, 3)
	if not slide_in:
		return spaced

	# Le geste déjà généralisé par UIHelpers.wrap_animatable() (punch de valeur
	# de jauge) : extraire la ligne de son VBoxContainer pour lui laisser une
	# `position` que le tri du conteneur ne réécrasera pas.
	var wrap := UIHelpers.wrap_animatable(spaced)
	spaced.position = Vector2(-ROSTER_SLIDE_OFFSET, 0.0)
	var tween := spaced.create_tween().set_parallel(true)
	tween.tween_property(spaced, "position:x", 0.0, SLIDE_IN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	UIHelpers.fade_in(spaced, SLIDE_IN_DURATION)
	return wrap


func _hidden_trait_icon(employee: Dictionary) -> String:
	var hidden_trait: Dictionary = SprintState.get_hidden_trait(employee.get("hidden_trait", ""))
	if hidden_trait.is_empty():
		return ""
	return " %s" % hidden_trait.get("icon", "")


func _employee_tooltip(employee: Dictionary, role_conf: Dictionary) -> String:
	var lines: Array = ["%s %s — %s %s · salaire %d 💰/sprint" % [
		role_conf.get("icon", "👤"), employee.get("name", ""),
		role_conf.get("label", employee.get("role", "")), employee.get("seniority", ""),
		int(employee.get("salary", 0)),
	]]
	if employee.get("trait", "") != "":
		lines.append(employee.get("trait", ""))
	if employee.get("hiddenRevealed", false):
		var hidden_trait: Dictionary = SprintState.get_hidden_trait(employee.get("hidden_trait", ""))
		if not hidden_trait.is_empty():
			lines.append("%s %s — %s" % [
				hidden_trait.get("icon", ""), hidden_trait.get("name", ""), hidden_trait.get("description", "")
			])
	else:
		lines.append("🔒 Période d'essai en cours — trait caché non révélé.")
	lines.append("Clic : actions (🤝 1:1 · licencier)")
	return "\n".join(lines)


## Un clic sur une ligne de roster ouvre le mini-menu d'actions : plus besoin
## d'ouvrir un overlay puis de scroller (retour n°5 de Camille).
func _on_team_row_input(event: InputEvent, employee_id: String) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var employee := SprintState.find_employee(employee_id)
	if employee.is_empty():
		return

	var menu := PopupMenu.new()
	add_child(menu)

	var one_on_one_cost := SprintState.get_personal_action_cost("oneOnOne")
	var refusal := SprintState.personal_action_refusal()
	if employee.get("hiddenRevealed", false):
		menu.add_item("🤝 1:1 — trait déjà connu", 0)
		menu.set_item_disabled(menu.get_item_index(0), true)
	else:
		menu.add_item("🤝 1:1 (%d ⚡)" % one_on_one_cost, 0)
		if refusal != "":
			menu.set_item_disabled(menu.get_item_index(0), true)

	var severance := int(GameData.balance.get("firing", {}).get("severancePieces", 2))
	menu.add_item("🚪 Licencier (%d 🪙)" % severance, 1)
	if SprintState.pieces < severance:
		menu.set_item_disabled(menu.get_item_index(1), true)

	menu.id_pressed.connect(func(id: int):
		if id == 0:
			_on_one_on_one(employee_id)
		elif id == 1:
			_confirm_fire(employee_id)
	)
	menu.popup_hide.connect(menu.queue_free)
	# Un PopupMenu se place en coordonnées écran, pas en coordonnées de canvas.
	menu.position = Vector2i(get_screen_position() + get_local_mouse_position()) + Vector2i(-8, 6)
	menu.popup()


func _on_one_on_one(employee_id: String) -> void:
	var employee := SprintState.find_employee(employee_id)
	if employee.is_empty():
		return
	if SprintState.do_one_on_one(employee) == "":
		refresh()
		state_changed.emit()


## Le licenciement garde sa confirmation : c'est irréversible, ça coûte des
## indemnités, du Moral, et du Cynisme à partir du deuxième du mandat.
func _confirm_fire(employee_id: String) -> void:
	var employee := SprintState.find_employee(employee_id)
	if employee.is_empty():
		return
	var firing: Dictionary = GameData.balance.get("firing", {})
	_pending_fire_id = employee_id

	if _fire_dialog == null:
		_fire_dialog = ConfirmationDialog.new()
		_fire_dialog.title = "Licenciement"
		_fire_dialog.ok_button_text = "Licencier"
		_fire_dialog.cancel_button_text = "Annuler"
		_fire_dialog.confirmed.connect(_on_fire_confirmed)
		add_child(_fire_dialog)

	_fire_dialog.dialog_text = "Licencier %s ?\n\nIndemnités %d 🪙 · 🫶 Moral %d%s\nIrréversible." % [
		employee.get("name", ""),
		int(firing.get("severancePieces", 2)),
		int(firing.get("moral", -4)),
		"\n🎭 Cynisme +%d — l'organisation y verra une politique." % int(firing.get("cynismePerExtraFiring", 3)) if SprintState.fired_count >= 1 else "",
	]
	_fire_dialog.popup_centered()


func _on_fire_confirmed() -> void:
	if _pending_fire_id == "":
		return
	if SprintState.fire_employee(_pending_fire_id) == "":
		_pending_fire_id = ""
		refresh()
		state_changed.emit()


# ── Actifs possédés ──────────────────────────────────────────────────────
func _build_assets(vbox: VBoxContainer) -> void:
	vbox.add_child(_spaced(_rule(), 10, 0))
	vbox.add_child(_group_label("Actifs"))

	var max_activations := SprintState.get_tool_slot_capacity()
	var names: Array = []
	for card_id in SprintState.activated_cards:
		for card in GameData.cards.get("cards", []):
			if card.get("id", "") == card_id:
				names.append(card.get("name", card_id))
	vbox.add_child(_label("🃏 Décisions %d/%d%s" % [
		SprintState.activated_cards.size(), max_activations,
		" : %s" % ", ".join(names) if not names.is_empty() else " — aucune activée"
	], 11, UIHelpers.PANEL_FG, true))

	var icons: Array = []
	var practice_tooltips: Array = []
	for practice_id in SprintState.owned_practices:
		var practice: Dictionary = SprintState.find_practice(practice_id)
		icons.append(practice.get("icon", "✨"))
		practice_tooltips.append("%s %s — %s" % [
			practice.get("icon", ""), practice.get("name", ""), practice.get("description", "")
		])
	var practices_label := _label("✨ Pratiques : %s" % (
		" ".join(icons) if not icons.is_empty() else "aucune adoptée"
	), 11, UIHelpers.PANEL_FG, true)
	if not practice_tooltips.is_empty():
		practices_label.mouse_filter = Control.MOUSE_FILTER_STOP
		practices_label.tooltip_text = "\n".join(practice_tooltips)
	vbox.add_child(practices_label)


# ── Quota trimestriel, évalué en direct ──────────────────────────────────
func _build_quota(vbox: VBoxContainer) -> void:
	var quota: Dictionary = SprintState.get_quarter_progress()
	var impact := int(quota.get("impact", 0))
	var target: int = max(1, int(quota.get("quota", 1)))

	vbox.add_child(_spaced(_rule(), 10, 0))
	var section := VBoxContainer.new()
	section.name = "QuotaSection"
	section.add_theme_constant_override("separation", 5)
	vbox.add_child(section)
	section.add_child(_group_label("Quota trimestriel · T%d" % int(quota.get("quarter", SprintState.quarter_index))))
	section.add_child(_label("Sprint %d/%d · Impact brut %d / %d" % [
		int(quota.get("sprint", 0)) + 1, int(quota.get("length", 3)), impact, target
	], 11, UIHelpers.PANEL_FG, true))

	var bar := ProgressBar.new()
	bar.name = "QuotaProgress"
	bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	bar.max_value = target
	bar.value = clampi(impact, 0, target)
	bar.show_percentage = false
	bar.tooltip_text = _quota_tooltip()
	bar.add_theme_stylebox_override("fill", _flat(UIHelpers.PANEL_ACCENT, 3))
	bar.add_theme_stylebox_override("background", _flat(Color(1, 1, 1, 0.10), 3))
	section.add_child(bar)

	for requirement in SprintState.get_active_quarter_requirements():
		var requirement_label := _label("%s %s\n%s" % [
			requirement.get("icon", "!"), requirement.get("name", "Exigence"), requirement.get("description", "")
		], 10, UIHelpers.PANEL_FG, true)
		requirement_label.tooltip_text = "Exigence active ce trimestre"
		section.add_child(requirement_label)

	var objectives := SprintState.evaluate_board_objectives()
	if not objectives.is_empty():
		section.add_child(_label("Objectifs qualitatifs : bonus +8 Budget", 10, UIHelpers.PANEL_ACCENT, true))
		for objective in objectives:
			var ok: bool = bool(objective.get("ok", false))
			section.add_child(_label("%s %s" % ["✓" if ok else "○", objective.get("label", "")], 10,
				UIHelpers.PANEL_GOOD if ok else UIHelpers.PANEL_MUTED, true))


func _quota_tooltip() -> String:
	var quota := SprintState.get_quarter_progress()
	return "T%d · sprint %d/%d\nImpact brut : %d / %d\n%s" % [
		int(quota.get("quarter", 1)), int(quota.get("sprint", 0)) + 1, int(quota.get("length", 3)),
		int(quota.get("impact", 0)), int(quota.get("quota", 0)), SprintState.get_quarter_requirement_text()
	]


# ── Petits constructeurs ─────────────────────────────────────────────────
func _on_dossier_pressed() -> void:
	if _dossier == null:
		return
	if _dossier.has_method("refresh"):
		_dossier.refresh()
	_dossier.visible = not _dossier.visible


func _label(text: String, size: int, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return label


func _group_label(text: String) -> Control:
	var label := _label(text.to_upper(), 10, UIHelpers.PANEL_ACCENT)
	UIHelpers.apply_mono(label, 10, true)
	return _spaced(label, 10, 7)


func _rule() -> Control:
	var rule := ColorRect.new()
	rule.color = UIHelpers.PANEL_RULE
	rule.custom_minimum_size = Vector2(0, 1)
	return rule


func _flat(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style


func _spaced(node: Control, top: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.add_child(node)
	return margin


func _spacer_h() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _team_profile_label() -> String:
	for profile in GameData.cards.get("teamProfiles", []):
		if profile.get("id", "") == SprintState.team_profile:
			return profile.get("label", SprintState.team_profile)
	return SprintState.team_profile
