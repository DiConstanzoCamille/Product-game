class_name UIHelpers
extends RefCounted
## Petits utilitaires de style partagés entre les écrans de sprint.
## Licences des assets référencés : game/assets/THIRD_PARTY_NOTICES.md
##
## Palette CLAIRE depuis la refonte UI (docs/proposition-ui-interface.md §6,
## piste « Post-it & Feutre ») : le monde de jeu est du papier — blanc cassé,
## encre foncée, fiches et post-it. Le seul îlot sombre est le panneau de bord
## (scenes/components/side_panel.tscn), l'écran TV du standup : ses couleurs
## sont préfixées PANEL_ ci-dessous. Les hex de référence viennent du spike
## validé scenes/prototype_2d/market_screen_proto.tscn.

# ── Le monde clair ────────────────────────────────────────────────────────
const COLOR_SCREEN_BG := Color("#f4f6f3")
const COLOR_INK := Color("#2a2f38")        # texte courant, filets épais
const COLOR_FLAVOR := Color("#40485a")     # accroches, texte « à la main »
const COLOR_SOFT_TEXT := Color("#79808d")  # sous-textes, mentions secondaires
const COLOR_RULE := Color("#d4d9df")       # filets pointillés des cartes
const COLOR_AMBER := Color("#8a6d00")      # eyebrows, catégories, coûts
const COLOR_SHELF := Color("#23408e")      # titres de rayon

## L'encre du tampon d'acquisition (« ADOPTÉE », « EMBAUCHÉ·E », « ACTIVÉE ») —
## le rouge de tampon administratif, volontairement hors palette : c'est la
## seule marque qui dise « c'est fait, et ça ne se défait pas ».
const COLOR_STAMP := Color("#c0392b")

const COLOR_GOOD := Color("#2f9e63")
const COLOR_WARN := Color("#b3801a")
const COLOR_DANGER := Color("#d3543f")
const COLOR_UNKNOWN := Color("#c78a1b")    # les lignes d'impact 🔒 / ❓

# Fonds des trois types d'Actif : badge d'accès, post-it, fiche cartonnée.
const COLOR_CARD_CANDIDATE := Color("#ffffff")
const COLOR_CARD_PRACTICE := Color("#ffef8d")
const COLOR_CARD_DECISION := Color("#fbf7e9")

const PILL_CANDIDATE := Color("#23408e")
const PILL_PRACTICE := Color("#8a6d00")
const PILL_DECISION := Color("#a33b3b")

# ── Le panneau de bord (écran de standup : données claires sur fond sombre) ─
const PANEL_BG := Color("#10151f")
const PANEL_FG := Color("#e8ecf5")
const PANEL_MUTED := Color("#8b97b0")
const PANEL_RULE := Color("#262f42")
const PANEL_ACCENT := Color("#7fd3ff")
const PANEL_GOOD := Color("#7fe3a5")
const PANEL_WARN := Color("#f0b44a")
const PANEL_DANGER := Color("#f3897f")

const SIDE_PANEL_WIDTH := 320

## Ombre portée des objets de papier, au repos et au survol. Le survol d'un
## **bouton** ne touche pas à sa géométrie : il grossit son ombre, et le bouton
## se soulève de la page sans grandir. C'est le thème
## (resources/theme/main_theme.tres) qui porte ces valeurs pour les boutons
## ordinaires ; style_primary_button() les reprend pour les appels à l'action.
##
## Un zoom au survol (l'ancien `add_hover_bounce()`) était un bug d'affichage :
## un bouton large occupe *exactement* la largeur de son conteneur et tous les
## ScrollContainer ont `clip_contents = true` — le grossissement se faisait donc
## couper sur les côtés. Le mouvement est réservé aux objets qui ont de la marge
## autour d'eux : les cartes d'Actif, qui se redressent et se soulèvent
## (asset_card.gd).
const SHADOW_COLOR := Color(0.156863, 0.196078, 0.27451, 0.22)
const SHADOW_SIZE_REST := 5
const SHADOW_SIZE_HOVER := 11
const SHADOW_OFFSET_REST := Vector2(1, 2)
const SHADOW_OFFSET_HOVER := Vector2(2, 6)

const FONT_SPACE_GROTESK := preload("res://assets/fonts/SpaceGrotesk-Variable.ttf")
const FONT_MONO_MEDIUM := preload("res://assets/fonts/IBMPlexMono-Medium.ttf")
const FONT_MONO_SEMIBOLD := preload("res://assets/fonts/IBMPlexMono-SemiBold.ttf")
const FONT_PRODUCT_ICONS := preload("res://assets/fonts/ProductIcons.ttf")

const ICON_DIR := "res://assets/icons/"
const AVATAR_DIR := "res://assets/avatars/"
const ITEM_ICON_PATH := "res://assets/items-kenney/PNG/Colored/genericItem_color_%03d.png"
const DECOR_DIR := "res://assets/decor/"
const STAMP_DIR := "res://assets/stamps/"
const SENDER_BADGE_DIR := "res://assets/sender-badges/"
const DECISION_DESK_SCRIPT := preload("res://scripts/components/decision_desk.gd")

const GAUGE_ICONS := {
	"revenue": "wallet",
	"moral": "heart-handshake",
	"dette-organisationnelle": "brick-wall",
	"capital-politique": "target",
	"reputation-produit": "trending-up",
	"cynisme": "drama",
}


## Filet pointillé horizontal (l'équivalent d'un `border-top: 1px dashed`) —
## StyleBoxFlat ne sait pas dessiner de pointillés. Sépare les zones de la
## carte d'Actif.
class DashedRule extends Control:
	var rule_color: Color = Color("#d4d9df")
	var dash: float = 3.0
	var gap: float = 3.0

	func _init() -> void:
		custom_minimum_size = Vector2(0, 9)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var y := size.y - 5.0
		var x := 0.0
		while x < size.x:
			draw_line(Vector2(x, y), Vector2(minf(x + dash, size.x), y), rule_color, 1.0)
			x += dash + gap


## Soulignement ondulé des titres de rayon (l'équivalent d'un
## `text-decoration: underline wavy`) — le trait de feutre sous le titre écrit
## à la main sur le tableau blanc.
class WavyRule extends Control:
	var rule_color: Color = Color("#23408e")

	func _init() -> void:
		custom_minimum_size = Vector2(0, 7)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var points := PackedVector2Array()
		var x := 0.0
		while x <= size.x:
			points.append(Vector2(x, 3.0 + sin(x * 0.55) * 1.9))
			x += 1.5
		if points.size() > 1:
			draw_polyline(points, rule_color, 2.0)


## Vide un conteneur qu'on va reconstruire — **détacher d'abord, libérer
## ensuite**.
##
## Tous les composants de l'UI se reconstruisent de zéro à chaque changement
## d'état, et cette reconstruction est presque toujours déclenchée par le clic
## d'un bouton… qui vit dans le conteneur qu'on vide. Un `free()` direct détruit
## donc le bouton **pendant que son signal `pressed` est en cours d'émission** :
## Godot log « Object was freed or unreferenced while a signal is being emitted
## from it » et prévient du risque de crash. Symptôme observé à chaque embauche,
## chaque achat de pratique et chaque rallonge négociée.
##
## `queue_free()` seul ne suffit pas : le nœud resterait dans l'arbre jusqu'à la
## fin de la frame et se ferait mettre en page **à côté** de son remplaçant.
## D'où les deux temps — `remove_child()` sort le nœud du layout tout de suite,
## `queue_free()` le détruit quand plus personne ne s'en sert.
static func clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


## En-tête de rayon : titre souligné au feutre + mention de la règle du rayon
## (« tiré une fois par sprint », « 2 slots sur 4 »…). Commun aux deux rayons
## des écrans d'acquisition.
static func make_shelf_head(title: String, subtitle: String) -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 0)
	row.add_child(title_box)

	var title_label := Label.new()
	title_label.text = title
	apply_heading(title_label, 19, 600.0)
	title_label.add_theme_color_override("font_color", COLOR_SHELF)
	title_box.add_child(title_label)

	var wavy := WavyRule.new()
	wavy.rule_color = COLOR_SHELF
	title_box.add_child(wavy)

	if subtitle != "":
		var subtitle_label := Label.new()
		subtitle_label.text = subtitle
		subtitle_label.add_theme_font_size_override("font_size", 12)
		subtitle_label.add_theme_color_override("font_color", COLOR_SOFT_TEXT)
		subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		subtitle_label.size_flags_vertical = Control.SIZE_SHRINK_END
		row.add_child(subtitle_label)

	return vbox


## Le désordre des objets posés à la main sur le tableau. Une alternance
## régulière se lirait comme un motif ; ces angles-là n'ont pas de période
## évidente et le scotch ne tombe jamais tout à fait au même endroit.
const CARD_TILTS := [-1.3, 0.9, -0.6, 1.4, -1.1, 0.5, -1.6, 1.2]
const CARD_DECORATION_SHIFTS := [0.0, -9.0, 7.0, -4.0, 11.0, -6.0, 3.0, -11.0]


## Pose une carte sur le tableau : son angle et le décalage de sa décoration
## (scotch, trou de lanière), d'après son rang dans le rayon. À appeler sur le
## descripteur avant de le donner à AssetCard.
static func apply_card_placement(descriptor: Dictionary, index: int) -> Dictionary:
	descriptor["tilt"] = CARD_TILTS[index % CARD_TILTS.size()]
	descriptor["decoration_shift"] = CARD_DECORATION_SHIFTS[index % CARD_DECORATION_SHIFTS.size()]
	return descriptor


static func state_color(state: String) -> Color:
	match state:
		"good":
			return COLOR_GOOD
		"danger":
			return COLOR_DANGER
		_:
			return COLOR_WARN


## Même code d'état, mais dans les tons du panneau de bord sombre.
static func panel_state_color(state: String) -> Color:
	match state:
		"good":
			return PANEL_GOOD
		"danger":
			return PANEL_DANGER
		_:
			return PANEL_WARN


static func make_bar_fill_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style


static func make_bar_background_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.1)
	style.set_corner_radius_all(4)
	return style


## Police des titres (Space Grotesk), à un poids donné (400-700).
static func heading_font(weight: float = 600.0) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = FONT_SPACE_GROTESK
	variation.fallbacks = [FONT_PRODUCT_ICONS]
	variation.variation_opentype = {"wght": weight}
	return variation


static func apply_heading(label: Label, size: int = 20, weight: float = 600.0) -> void:
	label.add_theme_font_override("font", heading_font(weight))
	label.add_theme_font_size_override("font_size", size)


## Police mono (IBM Plex Mono) pour les labels de type "eyebrow" / compteurs.
static func apply_mono(label: Label, size: int = 12, semibold: bool = false) -> void:
	var variation := FontVariation.new()
	variation.base_font = FONT_MONO_SEMIBOLD if semibold else FONT_MONO_MEDIUM
	variation.fallbacks = [FONT_PRODUCT_ICONS]
	label.add_theme_font_override("font", variation)
	label.add_theme_font_size_override("font_size", size)


static func icon_texture(icon_name: String) -> Texture2D:
	return load(ICON_DIR + icon_name + ".svg")


## Icône Lucide (trait blanc) teintée via modulate — voir assets/THIRD_PARTY_NOTICES.md.
static func make_icon(icon_name: String, size: int = 20, color: Color = COLOR_INK) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = icon_texture(icon_name)
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.modulate = color
	return rect


## Icône d'objet Kenney (les « objets physiques » de la direction Post-it) —
## `index` est le numéro de genericItem_color_NNN.png. EXPAND_IGNORE_SIZE est
## obligatoire : sans lui, la taille native du PNG (~100 px) devient la taille
## minimale et l'icône écrase la carte (piège rencontré dans le spike).
static func make_item_icon(index: int, size: int = 34) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load(ITEM_ICON_PATH % index)
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect


## Portrait DiceBear si disponible pour `seed_name` (minuscules), sinon icône générique.
static func make_avatar(seed_name: String, size: int = 48) -> TextureRect:
	var rect := TextureRect.new()
	var path := AVATAR_DIR + seed_name.to_lower() + ".svg"
	if ResourceLoader.exists(path):
		rect.texture = load(path)
	else:
		rect.texture = icon_texture("user-round")
		rect.modulate = Color(COLOR_INK.r, COLOR_INK.g, COLOR_INK.b, 0.45)
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect


## Identité d'une personne : le portrait DiceBear s'il existe, sinon une
## pastille d'initiale. Tous les personnages nommés du roster et du marché ont
## désormais un portrait ; la pastille reste le repli explicite des expéditeurs
## collectifs (board, juridique, équipe…) et des futurs profils anonymes.
static func make_person_badge(person_name: String, size: int = 36, bg: Color = PILL_CANDIDATE) -> Control:
	var path := AVATAR_DIR + person_name.to_lower() + ".svg"
	if ResourceLoader.exists(path):
		var avatar := make_avatar(person_name, size)
		avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return avatar

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(size, size)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(int(size / 2.0))
	badge.add_theme_stylebox_override("panel", style)

	var initial := Label.new()
	initial.text = person_name.substr(0, 1).to_upper() if person_name != "" else "?"
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial.add_theme_font_size_override("font_size", int(size * 0.42))
	initial.add_theme_color_override("font_color", Color.WHITE)
	badge.add_child(initial)
	return badge


## Les expéditeurs de l'Inbox sont soit des personnes (portrait), soit des
## collectifs. Dans ce second cas, un badge métier évite de faire passer le
## board ou le juridique pour une personne anonyme.
static func make_sender_badge(sender: String, size: int = 38) -> Control:
	var first_name := sender.split(",")[0].strip_edges()
	var portrait_path := AVATAR_DIR + first_name.to_lower() + ".svg"
	if ResourceLoader.exists(portrait_path):
		return make_person_badge(first_name, size)

	var collective := ""
	match sender.to_lower():
		"le board", "un investisseur historique": collective = "board"
		"direction juridique": collective = "legal"
		"équipe technique", "l'équipe": collective = "tech"
		"équipe commerciale": collective = "sales"
		"équipe rh": collective = "hr"
		"veille concurrentielle": collective = "market-watch"
	if collective == "":
		return make_person_badge(first_name, size, COLOR_SHELF)

	var badge := TextureRect.new()
	badge.texture = load(SENDER_BADGE_DIR + collective + ".svg")
	badge.custom_minimum_size = Vector2(size, size)
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return badge


## Tampon vectoriel prêt à être posé dans un flux ou sur un ticket. Les
## libellés dynamiques des cartes d'Actif restent construits en texte ; ces
## fichiers servent aux états partagés de l'interface.
static func make_stamp(kind: String, width: int = 110) -> TextureRect:
	var stamp := TextureRect.new()
	stamp.texture = load(STAMP_DIR + kind + ".svg")
	stamp.custom_minimum_size = Vector2(width, round(float(width) * 80.0 / 240.0))
	stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return stamp


## Installe l'espace de décision dans un portable posé sur un bureau. Contrairement
## au premier cadre SVG, la dalle est opaque : le papier réglé appartient à
## l'ordinateur et aucun élément de mobilier ne passe devant les contrôles.
static func attach_decision_workspace(screen: Control, decision_path: NodePath) -> void:
	var target := screen.get_node_or_null(decision_path)
	var margin := screen.get_node_or_null("Margin")
	var background := screen.get_node_or_null("Background")
	if not (target is Control) or not (margin is Control) or not (background is ColorRect):
		return

	# Le fond quadrillé quitte le plein écran pour devenir la dalle du portable.
	# Le reste de l'écran est le bureau ; le Panneau de bord continue d'être un
	# écran séparé, à droite, comme le moniteur de stand-up de l'équipe.
	var desk_background := background as ColorRect
	desk_background.material = null
	desk_background.color = Color("#c9ad88")
	# On rend de la place sous la dalle : le portable a un menton et une base,
	# ce ne sont pas des éléments qui doivent se faire couper par la BottomBar.
	if margin is MarginContainer:
		var content_margin := margin as MarginContainer
		content_margin.add_theme_constant_override("margin_bottom",
			content_margin.get_theme_constant("margin_bottom") + 72)

	var desk = DECISION_DESK_SCRIPT.new()
	desk.name = "DecisionDesk"
	desk.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desk.modulate.a = 0.0
	screen.add_child(desk)
	screen.move_child(desk, margin.get_index())

	var paper := ColorRect.new()
	paper.name = "LaptopDisplay"
	paper.material = load("res://resources/shaders/grid_background_material.tres")
	paper.color = COLOR_SCREEN_BG
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.modulate.a = 0.0
	screen.add_child(paper)
	screen.move_child(paper, margin.get_index())

	var props: Array[TextureRect] = []
	for file_name in ["desk-sticky-note.svg", "desk-paperclip.svg", "desk-coffee.svg"]:
		var prop := TextureRect.new()
		prop.texture = load(DECOR_DIR + file_name)
		prop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		prop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		prop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prop.modulate = Color(1, 1, 1, 0.0)
		screen.add_child(prop)
		screen.move_child(prop, desk.get_index())
		props.append(prop)

	var place := func():
		var target_rect := (target as Control).get_global_rect()
		var local_target := Rect2(target_rect.position - screen.get_global_rect().position, target_rect.size)
		if local_target.size.x < 360.0 or local_target.size.y < 220.0:
			desk.visible = false
			paper.visible = false
			for prop in props:
				prop.visible = false
			return
		desk.visible = true
		paper.visible = true
		for prop in props:
			prop.visible = true
		var display := local_target.grow(12)
		paper.position = display.position
		paper.size = display.size
		desk.set_display_rect(display)
		# Accessoires volontairement hors de la dalle : ils donnent l'échelle du
		# bureau sans jamais recouvrir l'interface.
		props[0].position = Vector2(maxf(12.0, display.position.x - 74.0), display.position.y + 46.0)
		props[0].size = Vector2(62, 58)
		props[1].position = Vector2(display.position.x + 18.0, maxf(14.0, display.position.y - 72.0))
		props[1].size = Vector2(42, 54)
		props[2].position = Vector2(maxf(14.0, display.position.x - 94.0), display.end.y - 96.0)
		props[2].size = Vector2(86, 86)
	place.call()
	screen.resized.connect(place)
	(target as Control).resized.connect(place)
	# Au premier affichage, les Containers finissent leur passe de mise en page
	# après `_ready()`. Ce second placement garantit le bon calage dès la frame 1.
	screen.get_tree().process_frame.connect(place, CONNECT_ONE_SHOT)
	var tween := screen.create_tween().set_parallel(true)
	tween.tween_property(desk, "modulate:a", 1.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(paper, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for prop in props:
		tween.tween_property(prop, "modulate:a", 0.72, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func fade_in(control: Control, duration: float = 0.3) -> void:
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration)


## Bouton d'appel à l'action : l'encre remplit le bouton au lieu de le cerner.
## Le thème global (resources/theme/main_theme.tres) donne le bouton « papier »
## par défaut ; celui-ci est réservé au geste principal d'un écran ou d'une
## carte (Activer / Embaucher / Adopter, Suivant).
static func style_primary_button(button: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_INK
	style.border_color = COLOR_INK
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	style.shadow_color = SHADOW_COLOR
	style.shadow_size = SHADOW_SIZE_REST
	style.shadow_offset = SHADOW_OFFSET_REST

	# Au survol, l'ombre grandit : le bouton se soulève sans changer de taille.
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = COLOR_FLAVOR
	hover.border_color = COLOR_FLAVOR
	hover.shadow_size = SHADOW_SIZE_HOVER
	hover.shadow_offset = SHADOW_OFFSET_HOVER

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color.WHITE)


## Tooltip de la jauge d'Énergie — chiffres tirés de balance.json → energy.
static func energy_tooltip() -> String:
	var conf: Dictionary = GameData.balance.get("energy", {})
	var actions: Dictionary = conf.get("actions", {})
	return "\n".join([
		"⚡ Énergie — votre jauge personnelle. L'entreprise a ses ressources, vous n'avez que celle-là.",
		"Régénère +%d par sprint à la Résolution, modulée par le Moral de l'équipe (×1 si ≥ 60, ×0.5 entre 30 et 60, ×0 sous 30)." % int(conf.get("regenPerSprint", 12)),
		"Se dépense en actions personnelles : 🤝 1:1 (%d ⚡), 🔧 Faire le taf soi-même (%d ⚡), 🏛️ Rallonge (%d ⚡)." % [
			int(actions.get("oneOnOne", {}).get("cost", 10)),
			int(actions.get("selfWork", {}).get("cost", 25)),
			int(actions.get("extension", {}).get("cost", 10)),
		],
		"À 0 à la Résolution : burn-out fondateur·rice — fin de mandat.",
	])


## Texte de tooltip pour une ressource : définition + ce qui la fait
## monter/descendre (resources.json), affiché au survol d'une jauge.
static func resource_tooltip(resource: Dictionary) -> String:
	var lines: Array = ["%s %s" % [resource.get("icon", ""), resource.get("name", "")]]
	if resource.get("definition", "") != "":
		lines.append(resource.get("definition", ""))
	var rises: Array = resource.get("rises", [])
	if not rises.is_empty():
		lines.append("Monte : %s" % ", ".join(rises))
	var falls: Array = resource.get("falls", [])
	if not falls.is_empty():
		lines.append("Descend : %s" % ", ".join(falls))
	return "\n".join(lines)


## Branche le Panneau de bord (§4 de la proposition UI) sur un écran de phase :
## une colonne fixe à droite, présente en continu, qui remplace la barre de
## ressources horizontale. Instancié par chaque écran — il n'a aucun état à
## préserver, tout vit dans SprintState. `screen` doit avoir un nœud "Margin"
## (MarginContainer) : sa marge droite est repoussée pour laisser la place.
static func attach_side_panel(screen: Control) -> Control:
	var panel_scene: PackedScene = load("res://scenes/components/side_panel.tscn")
	var panel: Control = panel_scene.instantiate()
	screen.add_child(panel)

	var margin: Node = screen.get_node_or_null("Margin")
	if margin is MarginContainer:
		# La marge suit la largeur *réelle* du panneau : un contenu qui impose sa
		# taille minimale (nom d'entreprise long, roster large) ne doit jamais
		# finir par recouvrir le contenu de la phase — et le rail replié doit
		# rendre sa place aux cartes, pas la garder pour rien.
		var keep_clear := func():
			margin.add_theme_constant_override("margin_right",
				int(max(panel.size.x, panel.get_combined_minimum_size().x)) + 28)
		keep_clear.call()
		panel.resized.connect(keep_clear)
	return panel


## Branche le bouton + overlay "Dossier entreprise" (§16) sur un écran qui n'a
## pas de Panneau de bord (la Résolution) : instancie company_panel.tscn en
## enfant de `screen` (overlay caché par défaut, jamais un changement de scène
## — évite de perturber un état déjà consommé, ex. un tirage Inbox), et ajoute
## un bouton dans sa TopBar pour l'ouvrir/fermer. Sur les écrans de phase,
## c'est le Panneau de bord qui porte ce bouton.
## `screen` doit avoir un nœud "Margin/VBox/TopBar".
static func attach_company_menu(screen: Control) -> void:
	var panel := instantiate_company_dossier(screen)

	var top_bar: Node = screen.get_node("Margin/VBox/TopBar")
	var button := Button.new()
	button.text = "🏢 Dossier entreprise"
	button.pressed.connect(func(): panel.visible = not panel.visible)

	top_bar.add_child(button)
	top_bar.move_child(button, 1)


## Habille un écran de choix (accueil, scénario, entreprise, fin de mandat) du
## cadre de l'ordinateur portable — l'immersion sans changer une ligne de
## contenu : le cadre se pose par-dessus et les marges de l'écran sont repoussées
## pour tenir dans la dalle. Réservé aux écrans qui parlent *à travers un outil* ;
## les écrans de phase sont le monde physique de l'openspace.
static func attach_device_frame(screen: Control) -> Control:
	var frame_scene: PackedScene = load("res://scenes/components/device_frame.tscn")
	var frame: Control = frame_scene.instantiate()
	screen.add_child(frame)

	var margin: Node = screen.get_node_or_null("Margin")
	if margin is MarginContainer:
		for side in ["left", "top", "right"]:
			margin.add_theme_constant_override("margin_" + side,
				margin.get_theme_constant("margin_" + side) + frame.BEZEL)
		margin.add_theme_constant_override("margin_bottom",
			margin.get_theme_constant("margin_bottom") + frame.CHIN)
	return frame


static func instantiate_company_dossier(screen: Control) -> Control:
	var panel_scene: PackedScene = load("res://scenes/components/company_panel.tscn")
	var panel: Control = panel_scene.instantiate()
	screen.add_child(panel)
	return panel
