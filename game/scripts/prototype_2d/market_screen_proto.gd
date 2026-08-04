extends Control
## SPIKE DE RÉFÉRENCE VISUELLE — pas du code de production, aucun écran du jeu
## ne l'utilise. Sert de cible validée pour la refonte UI décrite dans
## docs/proposition-ui-interface.md (piste « Post-it & Feutre »).
##
## Port complet de l'écran "Investissements + Panneau de bord" de la maquette :
## contrairement aux essais précédents (qui ne portaient que les couleurs),
## celui-ci reprend la STRUCTURE — anatomie de carte à 6 zones, deux rayons
## titrés, en-tête de phase, panneau de bord permanent façon écran de standup.
## Toutes les valeurs viennent du CSS de la maquette (body[data-style="postit"]).
## Les données affichées sont en dur : rien n'est branché sur SprintState.
##
## Trois pièges Godot que la reprise en production devra éviter (ils ont tous
## été rencontrés ici) : un conteneur étire TOUS ses enfants — d'où `top_level`
## pour les décorations en surimpression, un `Control` nu (et non un conteneur)
## pour les barres de jauge, et `expand_mode = EXPAND_IGNORE_SIZE` sur les
## TextureRect sous peine d'icônes à leur taille native de 100 px.

# ── Palette (hex exacts de la maquette) ───────────────────────────────────
const FG          := Color("#2a2f38")
const MUTED       := Color("#79808d")
const RULE        := Color("#d4d9df")
const FLAVOR      := Color("#40485a")
const SHELF_TITLE := Color("#23408e")
const HEAD_BG     := Color("#3a4150")
const HEAD_FG     := Color("#f2f4f8")
const SCREEN_BG   := Color("#f4f6f3")

const PILL_CANDIDAT := Color("#23408e")
const PILL_PRATIQUE := Color("#8a6d00")
const PILL_DECISION := Color("#a33b3b")

const GOOD := Color("#2f9e63")
const BAD  := Color("#d3543f")

# Panneau (écran TV du standup : monde clair, données sombres)
const P_BG     := Color("#10151f")
const P_FG     := Color("#e8ecf5")
const P_MUTED  := Color("#8b97b0")
const P_RULE   := Color("#262f42")
const P_ACCENT := Color("#7fd3ff")
const P_GOOD   := Color("#7fe3a5")
const P_BAD    := Color("#f3897f")
const P_WARN   := Color("#f0b44a")

const ITEMS := "res://assets/items-kenney/PNG/Colored/genericItem_color_%03d.png"

var _ui: SystemFont
var _display: SystemFont
var _mono: SystemFont
var _frames := 0
var _cards: Array[Control] = []
var _overlays: Array[Dictionary] = []


## Filet pointillé (border-top:1px dashed) — StyleBoxFlat ne sait pas le faire.
class DashedRule extends Control:
	var rule_color: Color = Color.GRAY

	func _init() -> void:
		custom_minimum_size = Vector2(0, 9)

	func _draw() -> void:
		var y := size.y - 5.0
		var x := 0.0
		while x < size.x:
			draw_line(Vector2(x, y), Vector2(minf(x + 3.0, size.x), y), rule_color, 1.0)
			x += 6.0


## Soulignement ondulé des titres de rayon (text-decoration:underline wavy).
class WavyRule extends Control:
	var rule_color: Color = Color.BLUE

	func _init() -> void:
		custom_minimum_size = Vector2(0, 7)

	func _draw() -> void:
		var pts := PackedVector2Array()
		var x := 0.0
		while x <= size.x:
			pts.append(Vector2(x, 3.0 + sin(x * 0.55) * 1.9))
			x += 1.5
		if pts.size() > 1:
			draw_polyline(pts, rule_color, 2.0)


func _ready() -> void:
	get_window().size = Vector2i(1560, 1000)
	_ui = SystemFont.new()
	_ui.font_names = ["Segoe UI", "system-ui"]
	_display = SystemFont.new()
	_display.font_names = ["Segoe Print", "Comic Sans MS"]
	_mono = SystemFont.new()
	_mono.font_names = ["Consolas", "Cascadia Mono"]

	_build_screen_background()

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	root.add_child(_build_screen_head())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	root.add_child(body)

	body.add_child(_build_market())
	body.add_child(_build_panel())

	# Le léger tilt des cartes doit s'appliquer APRÈS le layout du conteneur.
	call_deferred("_apply_card_tilt")


func _apply_card_tilt() -> void:
	for i in range(_cards.size()):
		var card := _cards[i]
		card.pivot_offset = card.size / 2.0
		card.rotation_degrees = -1.1 if i % 2 == 0 else 0.9

	# Les décorations en top_level se placent en coordonnées globales, donc
	# après que les conteneurs ont fini de dimensionner les cartes.
	for o in _overlays:
		var card: Control = o["card"]
		var node: Control = o["node"]
		node.global_position = card.global_position + Vector2(card.size.x / 2.0, 0) + o["offset"]
		node.size = o["size"]


func _process(_delta: float) -> void:
	_frames += 1
	# Lancer avec `-- capture` pour écrire un PNG puis quitter (revue de rendu
	# sans ouvrir la fenêtre à la main). Sans le drapeau, la scène reste
	# affichée normalement.
	if _frames == 8 and OS.get_cmdline_user_args().has("capture"):
		await RenderingServer.frame_post_draw
		var path := "user://proto-market.png"
		get_viewport().get_texture().get_image().save_png(path)
		print("Screenshot : ", ProjectSettings.globalize_path(path))
		get_tree().quit()


# ── Fond d'écran : blanc cassé + lignes réglées à peine visibles ──────────
func _build_screen_background() -> void:
	var bg := ColorRect.new()
	bg.color = SCREEN_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	for y in range(0, 1000, 47):
		var line := ColorRect.new()
		line.color = Color(90.0 / 255.0, 105.0 / 255.0, 130.0 / 255.0, 0.05)
		line.position = Vector2(0, y)
		line.size = Vector2(1560, 1)
		add_child(line)


func _label(text: String, font: Font, size_px: int, color: Color, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
	return l


func _flat(bg: Color, radius: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	return sb


func _margin(node: Control, l: int, t: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(node)
	return m


# ── En-tête d'écran : phase + fil d'Ariane ────────────────────────────────
func _build_screen_head() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat(HEAD_BG))

	var row := HBoxContainer.new()
	var phase := _label("SPRINT 5 · PHASE 3 / 4 — INVESTISSEMENTS", _display, 14, HEAD_FG)
	row.add_child(phase)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var crumb := _label("Inbox ✓ · Roadmap ✓ · Investissements · Résolution", _ui, 12, Color(HEAD_FG.r, HEAD_FG.g, HEAD_FG.b, 0.75))
	row.add_child(crumb)

	panel.add_child(_margin(row, 20, 12, 20, 12))
	return panel


# ── Colonne centrale : les deux rayons ────────────────────────────────────
func _build_market() -> Control:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 22)

	vbox.add_child(_build_shelf_head("📦 L'étal du sprint", "tiré une fois par sprint — revenir sur l'écran ne re-tire pas"))
	var row1 := _card_row()
	vbox.add_child(row1)
	row1.add_child(_build_candidate_card())
	row1.add_child(_build_candidate_card_2())
	row1.add_child(_build_practice_card())
	row1.add_child(_build_practice_card_2())

	vbox.add_child(_build_shelf_head("🃏 Les grandes décisions", "1 activée · 3 slots restants sur 4 · effets calibrés pour votre équipe senior 🏛️"))
	var row2 := _card_row()
	vbox.add_child(row2)
	row2.add_child(_build_decision_card())
	row2.add_child(_build_decision_card_2())

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	return _margin(vbox, 22, 20, 22, 16)


func _card_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	return row


func _build_shelf_head(title: String, sub: String) -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 0)
	row.add_child(title_box)
	title_box.add_child(_label(title, _display, 18, SHELF_TITLE))
	var wavy := WavyRule.new()
	wavy.rule_color = SHELF_TITLE
	title_box.add_child(wavy)

	var sub_lbl := _label(sub, _display, 12, MUTED)
	sub_lbl.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(sub_lbl)

	return vbox


# ── La carte d'Actif : six zones, identiques pour les trois types ─────────
func _new_card(bg: Color, radius: int, extra_top_pad: int = 0) -> Dictionary:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(232, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sb := _flat(bg, radius)
	sb.border_color = Color(0, 0, 0, 0.08)
	sb.set_border_width_all(1)
	sb.shadow_color = Color(40.0 / 255.0, 50.0 / 255.0, 70.0 / 255.0, 0.22)
	sb.shadow_size = 7
	sb.shadow_offset = Vector2(2, 4)
	card.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	card.add_child(_margin(vbox, 14, 13 + extra_top_pad, 14, 12))

	_cards.append(card)
	return {"card": card, "vbox": vbox}


## Zone ① — pastille de type + référence de formulaire.
func _zone_type(vbox: VBoxContainer, pill_text: String, pill_color: Color, ref_text: String) -> void:
	var row := HBoxContainer.new()
	vbox.add_child(row)

	var pill := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0, 0, 0, 0)
	psb.border_color = pill_color
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(4)
	psb.content_margin_left = 7
	psb.content_margin_right = 7
	psb.content_margin_top = 2
	psb.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", psb)
	pill.add_child(_label(pill_text.to_upper(), _ui, 9, pill_color))
	row.add_child(pill)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var ref_lbl := _label(ref_text, _mono, 10, MUTED)
	ref_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ref_lbl)


## Zone ② — identité : pastille avatar (candidat) ou icône, titre, sous-titre.
func _zone_identity(vbox: VBoxContainer, initial: String, icon_id: int, title: String, sub: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	vbox.add_child(row)

	if initial != "":
		var av := PanelContainer.new()
		av.custom_minimum_size = Vector2(36, 36)
		var asb := _flat(PILL_CANDIDAT, 18)
		av.add_theme_stylebox_override("panel", asb)
		var ini := _label(initial, _ui, 14, Color.WHITE)
		ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		av.add_child(ini)
		av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(av)
	elif icon_id > 0:
		var icon := TextureRect.new()
		icon.texture = load(ITEMS % icon_id)
		# EXPAND_IGNORE_SIZE : sans ça la taille naturelle du PNG (~100 px)
		# devient la taille minimale et l'icône écrase la carte.
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(34, 34)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)

	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	texts.add_child(_label(title, _display, 16, FG, true))
	if sub != "":
		texts.add_child(_label(sub, _ui, 11, MUTED))


func _zone_tagline(vbox: VBoxContainer, text: String) -> void:
	vbox.add_child(_label(text, _display, 12, FLAVOR, true))


func _zone_badges(vbox: VBoxContainer, text: String) -> void:
	vbox.add_child(_label(text, _ui, 10, MUTED, true))


## Zone ④ — l'impact, en ressources et non en axes, avec les inconnues.
func _zone_impact(vbox: VBoxContainer, lines: Array) -> void:
	var rule := DashedRule.new()
	rule.rule_color = RULE
	vbox.add_child(rule)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	vbox.add_child(list)

	for line in lines:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		list.add_child(row)

		var is_locked: bool = line.get("locked", false)
		var lbl := _label(line["label"], _ui, 11, MUTED if is_locked else FG, true)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var delta_color: Color = GOOD if line.get("good", true) else BAD
		if line.get("unknown", false):
			delta_color = Color("#c78a1b")
		var delta := _label(line["delta"], _mono, 11, delta_color)
		delta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(delta)


## Zone ⑤ — bandeau de coût, poussé en bas de carte.
func _zone_cost(vbox: VBoxContainer, text: String) -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var rule := DashedRule.new()
	rule.rule_color = RULE
	vbox.add_child(rule)
	vbox.add_child(_label(text, _ui, 11, FG, true))


## Zone ⑥ — actions : verbe spécifique + action personnelle secondaire.
func _zone_actions(vbox: VBoxContainer, primary: String, secondary: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	vbox.add_child(row)

	if secondary != "":
		row.add_child(_button(secondary, false))
	var p := _button(primary, true)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(p)


func _button(text: String, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", _display)
	b.add_theme_font_size_override("font_size", 11)

	var sb := StyleBoxFlat.new()
	sb.bg_color = FG if primary else Color.WHITE
	sb.border_color = FG
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7

	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", Color.WHITE if primary else FG)
	b.add_theme_color_override("font_hover_color", Color.WHITE if primary else FG)
	b.add_theme_color_override("font_pressed_color", Color.WHITE if primary else FG)
	return b


# ── Les six cartes de l'écran ─────────────────────────────────────────────
func _build_candidate_card() -> Control:
	# Candidat = badge d'accès : fond blanc, trou de lanière en haut.
	var d := _new_card(Color.WHITE, 3, 8)
	var v: VBoxContainer = d["vbox"]
	_lanyard_hole(d["card"])
	_zone_type(v, "Candidat", PILL_CANDIDAT, "DEV · SENIOR")
	_zone_identity(v, "L", 0, "Lina", "salaire 2 💰/sprint")
	_zone_tagline(v, "Refuse toute réunion de plus de 25 minutes.")
	_zone_badges(v, "10 ans de legacy Java · a survécu à 3 migrations")
	_zone_impact(v, [
		{"label": "⚙️ Capacité produite", "delta": "+3 pts", "good": true},
		{"label": "💰 Masse salariale", "delta": "−2/sprint", "good": false},
		{"label": "🔒 Trait caché — fin de période d'essai", "delta": "❓", "locked": true, "unknown": true},
	])
	_zone_cost(v, "6 🪙 · effectif 5/7 → 6/7")
	_zone_actions(v, "Embaucher (6 🪙)", "🤝 1:1 (10 ⚡)")
	return d["card"]


func _build_candidate_card_2() -> Control:
	var d := _new_card(Color.WHITE, 3, 8)
	var v: VBoxContainer = d["vbox"]
	_lanyard_hole(d["card"])
	_zone_type(v, "Candidat", PILL_CANDIDAT, "DEV · JUNIOR")
	_zone_identity(v, "T", 0, "Théo", "salaire 1 💰/sprint")
	_zone_tagline(v, "Adopte chaque nouvel outil avec un enthousiasme non négociable.")
	_zone_badges(v, "bootcamp 2023 · a déjà refactoré le README")
	_zone_impact(v, [
		{"label": "⚙️ Capacité produite", "delta": "+2 pts", "good": true},
		{"label": "💰 Masse salariale", "delta": "−1/sprint", "good": false},
		{"label": "🔒 Trait caché — fin de période d'essai", "delta": "❓", "locked": true, "unknown": true},
	])
	_zone_cost(v, "3 🪙 · effectif 5/7 → 6/7")
	_zone_actions(v, "Embaucher (3 🪙)", "🤝 1:1 (10 ⚡)")
	return d["card"]


func _build_practice_card() -> Control:
	# Pratique = post-it jaune, coins quasi vifs, scotch en haut.
	var d := _new_card(Color("#ffef8d"), 1)
	var v: VBoxContainer = d["vbox"]
	_tape(d["card"])
	_zone_type(v, "Pratique", PILL_PRATIQUE, "RÉVÉLATION")
	_zone_identity(v, "", 37, "Discovery", "permanente pour le mandat")
	_zone_tagline(v, "Parler aux clients avant de coder — l'idée choque encore.")
	_zone_impact(v, [
		{"label": "🔓 Révèle la colonne ROI de la roadmap", "delta": "définitif", "good": true},
		{"label": "🎭 Cynisme (un process de plus…)", "delta": "+2", "good": false},
	])
	_zone_cost(v, "4 🪙")
	_zone_actions(v, "Adopter (4 🪙)", "")
	return d["card"]


func _build_practice_card_2() -> Control:
	var d := _new_card(Color("#ffef8d"), 1)
	var v: VBoxContainer = d["vbox"]
	_tape(d["card"])
	_zone_type(v, "Pratique", PILL_PRATIQUE, "RECRUTEMENT")
	_zone_identity(v, "", 149, "Entretiens structurés", "permanente pour le mandat")
	_zone_tagline(v, "Une grille commune au lieu d'un « feeling » après 45 minutes.")
	_zone_impact(v, [
		{"label": "🔓 Les candidats arrivent révélés", "delta": "définitif", "good": true},
		{"label": "🎭 Cynisme", "delta": "+2", "good": false},
	])
	_zone_cost(v, "3 🪙")
	_zone_actions(v, "Adopter (3 🪙)", "")
	return d["card"]


func _build_decision_card() -> Control:
	# Décision = fiche cartonnée crème, scotchée elle aussi.
	var d := _new_card(Color("#fbf7e9"), 3)
	var v: VBoxContainer = d["vbox"]
	_tape(d["card"])
	_zone_type(v, "Décision", PILL_DECISION, "PRD-014")
	_zone_identity(v, "", 74, "RICE Scoring", "Module priorisation")
	_zone_tagline(v, "Reach × Impact × Confidence ÷ Effort. La science contre le petit doigt mouillé.")
	_zone_impact(v, [
		{"label": "🫶 Un contrôle sur un instinct qui marchait", "delta": "−7", "good": false},
		{"label": "📈 Réunions pour négocier les scores", "delta": "−5", "good": false},
		{"label": "🧱 Léger gain d'alignement", "delta": "−2", "good": true},
		{"label": "💰 Un tableur suffit", "delta": "−1", "good": false},
	])
	_zone_cost(v, "1 slot de grande décision")
	_zone_actions(v, "Activer (1 slot)", "")
	return d["card"]


func _build_decision_card_2() -> Control:
	var d := _new_card(Color("#fbf7e9"), 3)
	var v: VBoxContainer = d["vbox"]
	_tape(d["card"])
	_zone_type(v, "Décision", PILL_DECISION, "DOC-003")
	_zone_identity(v, "", 36, "Jira", "Module suivi & doc")
	_zone_tagline(v, "Chaque ticket a un statut. Chaque statut a un mensonge.")
	_zone_impact(v, [
		{"label": "🧱 Traçabilité qui rassure l'audit", "delta": "−7", "good": true},
		{"label": "💰 Licences, mais déjà budgétées", "delta": "−3", "good": false},
		{"label": "🫶 Une routine connue", "delta": "+1", "good": true},
		{"label": "📈 L'équipe sait déjà s'en servir", "delta": "+1", "good": true},
	])
	_zone_cost(v, "1 slot de grande décision")
	_zone_actions(v, "Activer (1 slot)", "")
	return d["card"]


## Bande de scotch translucide en haut de carte (::before de la maquette).
## top_level : sans ça, PanelContainer étire l'enfant sur toute la carte et
## le voile blanc recouvre le contenu.
func _tape(card: Control) -> void:
	var tape := ColorRect.new()
	tape.color = Color(1, 1, 1, 0.55)
	tape.top_level = true
	tape.size = Vector2(64, 16)
	tape.pivot_offset = Vector2(32, 8)
	tape.rotation_degrees = -2
	tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tape)
	_overlays.append({"node": tape, "card": card, "offset": Vector2(-32, -8), "size": Vector2(64, 16)})


## Trou de lanière du badge candidat.
func _lanyard_hole(card: Control) -> void:
	var hole := ColorRect.new()
	hole.color = Color("#e2e6ec")
	hole.top_level = true
	hole.size = Vector2(34, 8)
	hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hole)
	_overlays.append({"node": hole, "card": card, "offset": Vector2(-17, 7), "size": Vector2(34, 8)})


# ── Le panneau de bord permanent (l'écran TV du standup) ──────────────────
func _build_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(308, 0)
	var sb := _flat(P_BG)
	sb.border_color = FG
	sb.border_width_left = 8
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)

	vbox.add_child(_label("● ÉCRAN STANDUP — SALLE ADA LOVELACE", _ui, 9, P_MUTED))

	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 3)
	var co := HBoxContainer.new()
	co.add_child(_label("🏛️ Meridia", _display, 15, P_FG))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	co.add_child(sp)
	var sprint := _label("SPRINT 5/12", _mono, 11, P_MUTED)
	sprint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	co.add_child(sprint)
	head.add_child(co)
	head.add_child(_label("équipe senior 🏛️ · SaaS — revenu récurrent (MRR)", _ui, 10, P_MUTED, true))
	vbox.add_child(_margin(head, 0, 10, 0, 10))
	vbox.add_child(_panel_rule())

	vbox.add_child(_group_label("Entreprise"))
	vbox.add_child(_gauge("💰 Trésorerie", 42, P_WARN))
	vbox.add_child(_gauge("🫶 Moral", 55, P_GOOD))
	vbox.add_child(_gauge("🧱 Dette org.", 38, P_GOOD))
	vbox.add_child(_gauge("📈 Réputation produit", 47, P_WARN))
	vbox.add_child(_gauge("🎭 Cynisme", 44, P_WARN))

	var pieces := HBoxContainer.new()
	pieces.add_child(_label("🪙 Pièces", _ui, 12, P_FG))
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pieces.add_child(sp2)
	pieces.add_child(_label("9", _mono, 13, P_FG))
	vbox.add_child(_margin(pieces, 0, 6, 0, 8))
	vbox.add_child(_panel_rule())

	vbox.add_child(_group_label("Vous"))
	vbox.add_child(_gauge("🎯 Capital politique", 61, P_GOOD))
	vbox.add_child(_gauge("⚡ Énergie", 55, P_GOOD))
	vbox.add_child(_margin(_panel_rule(), 0, 8, 0, 0))

	# Équipe — le roster enfin permanent à l'écran (retour n°5 de Camille).
	var t_head := HBoxContainer.new()
	t_head.add_child(_label("ÉQUIPE", _mono, 10, P_ACCENT))
	var sp3 := Control.new()
	sp3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_head.add_child(sp3)
	t_head.add_child(_label("5/7 · 7 pts · 10 💰/sprint", _mono, 10, P_MUTED))
	vbox.add_child(_margin(t_head, 0, 10, 0, 6))

	for member in [["H", "Hervé", "PM sr"], ["D", "Danielle", "Dev sr"], ["M", "Marek", "Dev sr"],
			["S", "Solange", "Ops sr"], ["P", "Patrice", "Designer sr 🔒"]]:
		vbox.add_child(_team_row(member[0], member[1], member[2]))

	vbox.add_child(_margin(_panel_rule(), 0, 10, 0, 0))
	vbox.add_child(_group_label("Actifs"))
	vbox.add_child(_label("🃏 Décisions 1/4 · ✨ Pratiques : 🔍 🗂️", _ui, 11, P_FG, true))

	vbox.add_child(_margin(_panel_rule(), 0, 10, 0, 0))
	vbox.add_child(_group_label("Revue de board — sprint 6"))
	vbox.add_child(_board_line("🎭 Cynisme ≤ 45", "✗ (47)", false))
	vbox.add_child(_board_line("🃏 ≥ 1 décision active", "✓", true))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var dossier := _button("🏢 Dossier entreprise", false)
	vbox.add_child(_margin(dossier, 0, 12, 0, 0))

	panel.add_child(_margin(vbox, 16, 14, 16, 14))
	return panel


func _panel_rule() -> Control:
	var r := ColorRect.new()
	r.color = P_RULE
	r.custom_minimum_size = Vector2(0, 1)
	return r


func _group_label(text: String) -> Control:
	var l := _label(text.to_upper(), _mono, 10, P_ACCENT)
	return _margin(l, 0, 10, 0, 7)


func _gauge(name: String, value: int, color: Color) -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)

	var top := HBoxContainer.new()
	top.add_child(_label(name, _ui, 11, P_FG))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(_label(str(value), _mono, 11, P_FG))
	vbox.add_child(top)

	# Barre : la géométrie sur laquelle la preview d'impact viendra se projeter.
	# Control (et non PanelContainer) : un conteneur étirerait le remplissage
	# sur toute la largeur et toutes les jauges paraîtraient pleines.
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 8)

	var track := Panel.new()
	track.add_theme_stylebox_override("panel", _flat(Color(1, 1, 1, 0.086), 4))
	bar.add_child(track)

	var fill := Panel.new()
	fill.add_theme_stylebox_override("panel", _flat(color, 4))
	bar.add_child(fill)

	bar.resized.connect(func():
		track.position = Vector2.ZERO
		track.size = Vector2(bar.size.x, 8)
		fill.position = Vector2.ZERO
		fill.size = Vector2(bar.size.x * value / 100.0, 8)
	)
	vbox.add_child(bar)

	return _margin(vbox, 0, 3, 0, 3)


func _team_row(initial: String, name: String, role: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var av := PanelContainer.new()
	av.custom_minimum_size = Vector2(22, 22)
	av.add_theme_stylebox_override("panel", _flat(PILL_CANDIDAT, 11))
	var ini := _label(initial, _ui, 10, Color.WHITE)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(ini)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(av)

	var n := _label(name, _ui, 11, P_FG)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(n)

	var r := _label(role, _mono, 10, P_MUTED)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(r)

	return _margin(row, 0, 3, 0, 3)


func _board_line(text: String, verdict: String, ok: bool) -> Control:
	var row := HBoxContainer.new()
	var l := _label(text, _ui, 11, P_FG)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(_label(verdict, _ui, 11, P_GOOD if ok else P_BAD))
	return _margin(row, 0, 2, 0, 2)
