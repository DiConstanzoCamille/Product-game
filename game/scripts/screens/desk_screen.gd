class_name DeskScreen
extends Node3D
## Le bureau — le hub qui remplace le tunnel d'écrans (issue #54, Lot A ;
## passé en volume par #59).
##
## Neuf écrans plein cadre enchaînés en dur laissaient le joueur devant quinze
## valeurs à surveiller en permanence. Ici il n'y en a plus que trois, écrites
## dans une **zone posée sur le décor** ; tout le reste vient le chercher quand
## ça va mal (`SprintState.get_active_alerts()`).
##
## Trois natures d'élément, et le tri est strict — c'est la règle qui remplace
## les `change_scene_to_file` :
##
##  · **Logiciel** — boîte mail, roadmap, tableau de bord. S'ouvre *dans l'écran
##    de l'ordinateur*, parce que c'est vraiment un écran.
##  · **Objet qui entre** — étal du sprint, clôture, Comité. Un accessoire
##    glisse dans le cadre. Aucune mécanique n'ouvre un écran de plus.
##  · **Décor** — trombinoscope, journal, objectif, tasse. On les lit, on ne les
##    « ouvre » pas ; on les *lève*, ce qui ne coûte rien.
##
## ## Le partage 3D / 2D, et pourquoi la racine est un `Node3D`
##
## Le monde est en volume : la pièce, la table, le portable, les papiers, les
## objets posés. **Tout ce qu'on lit reste en 2D**, dans le `CanvasLayer` — les
## zones de valeurs, les alertes, les info-bulles, le détail d'un poster levé.
## Une interface qu'on lit ne gagne rien à la perspective, elle y perd ; et un
## `CanvasLayer` garantit qu'aucun objet du monde ne passe devant une alerte.
##
## Le contenu des applications, lui, n'est pas dans le `CanvasLayer` : il vit
## dans le `SubViewport` de la dalle, donc il *hérite* de la perspective par la
## texture — sans qu'une seule ligne des écrans de phase soit réécrite, et sans
## que leur texte soit incliné (critère de recette n°1).

const DESIGN := Vector2(1600, 900)

const ZONE_BG := Color(1, 1, 1, 0.9)
const ZONE_BORDER := Color("#cfd5d2")
const DESK_LABEL := Color("#584732")

## Les trois applications du poste de travail. L'ordre est celui du sprint,
## mais rien ne l'impose : on ouvre ce qu'on veut, quand on veut.
const APPS := [
	{"id": "inbox", "name": "Boîte mail", "icon": "mail"},
	{"id": "roadmap", "name": "Roadmap", "icon": "road"},
	{"id": "dashboard", "name": "Tableau de bord", "icon": "dash"},
]

## Les trois papiers, et où ils sont punaisés sur le mur du fond. Le portable
## occupe la colonne centrale : ils vivent donc dans les deux colonnes
## latérales et dans la bande au-dessus de lui — c'est `DeskRoom.CAMERA_AIM_UP`
## qui la dégage. Ils sont **plus bas que le premier jet** : punaisés en haut,
## ils passaient sous la zone de valeurs, et la moitié du trombinoscope se
## lisait derrière un panneau.
const PAPERS := [
	{"kind": "team", "at": Vector2(-1.26, 1.31)},
	{"kind": "journal", "at": Vector2(0.00, 1.62)},
	{"kind": "goal", "at": Vector2(1.42, 1.33)},
]

var _room: DeskRoom = null
var _layer: CanvasLayer = null
var _vitals: PanelContainer = null
var _chip: PanelContainer = null
var _alerts: Control = null
var _tooltip: PanelContainer = null
var _detail: PanelContainer = null
var _energy: Label = null
var _workstation: Control = null
var _mug: Node3D = null

var _papers: Array = []
var _props: Dictionary = {}
var _lifted: Node3D = null
var _paper_click_frame := -1


func _ready() -> void:
	# Sans ça, aucune `Area3D` ne reçoit jamais `input_event` ni `mouse_entered` :
	# le monde entier devient un décor cliquable nulle part, et rien ne le dit.
	get_viewport().physics_object_picking = true
	_build.call_deferred()


## Godot **rejette** `add_child()` sur un nœud encore en train d'installer ses
## enfants, et le signale seulement sur `stderr` : le script continue, la scène
## reste vide. Trois écrans unis d'affilée sur le spike avant de le comprendre.
func _build() -> void:
	_room = DeskRoom.new()
	_room.name = "Room"
	add_child(_room)
	# Explicitement, et avant tout le reste : la caméra donne l'échelle
	# pixel/unité dont dépend la taille de chaque quad qui porte du texte.
	_room.build()

	_build_workstation()
	_build_mug()
	_build_papers()
	_build_props()
	_build_canvas()
	refresh()


## Un seul point de reconstruction : tout écran hôte ou accessoire qui modifie
## l'état rappelle `refresh()`. Aucune valeur n'est mise en cache ici — le
## bureau est une vue sur `SprintState`, jamais un second état.
func refresh() -> void:
	if _room == null:
		return
	_refresh_vitals()
	_refresh_alerts()
	for paper in _papers:
		paper.refresh()
	for id in _props:
		_props[id].refresh()
	if _lifted != null:
		_fill_detail(_lifted)
	else:
		_refresh_anchored_labels()


## Les trois accès dont la recette a besoin. Le harnais de captures et le banc
## UI ne doivent pas connaître l'arbre 3D : `Room/Lid/ScreenViewport/…` est un
## détail de construction, et un test qui l'épelle casse au premier
## déplacement de nœud.
func workstation() -> Control:
	return _workstation


func prop(kind: String) -> Node3D:
	return _props.get(kind, null)


func paper(kind: String) -> Node3D:
	for entry in _papers:
		if String(entry.get("kind")) == kind:
			return entry
	return null


func lifted_paper() -> Node3D:
	return _lifted


## Les mêmes gestes que la souris, sans souris : la recette et le banc doivent
## pouvoir lever un poster ou ouvrir un accessoire sans simuler un raycast.
func lift_paper(kind: String) -> void:
	var target := paper(kind)
	if target != null:
		_on_paper_clicked(target)


func open_app(id: String) -> void:
	if _workstation != null:
		_workstation.call("open_app", id)


func open_prop(kind: String) -> void:
	var target := prop(kind)
	if target != null:
		target.call("expand")


func readable_layer() -> CanvasLayer:
	return _layer


func room() -> DeskRoom:
	return _room


# ── Le monde ─────────────────────────────────────────────────────────────
func _build_workstation() -> void:
	_workstation = Control.new()
	_workstation.name = "Workstation"
	_workstation.set_script(preload("res://scripts/components/workstation.gd"))
	_workstation.set("apps", APPS)
	_room.screen_viewport.add_child(_workstation)
	if _workstation.has_signal("state_changed"):
		_workstation.connect("state_changed", Callable(self, "refresh"))


func _build_mug() -> void:
	_mug = Node3D.new()
	_mug.name = "Mug"
	_mug.set_script(preload("res://scripts/components/desk_mug.gd"))
	_mug.set("room", _room)
	_mug.position = Vector3(-0.80, DeskRoom.DESK_TOP_Y, -0.06)
	_room.add_child(_mug)
	# Construit tout de suite, comme la pièce : ces nœuds se dimensionnent et
	# se placent depuis la caméra, et `refresh()` projette leur position dans
	# la couche 2D. Laisser faire le `call_deferred` de leur `_ready()` les
	# laissait à l'origine pour toute la première trame — assez pour que les
	# étiquettes du plateau se retrouvent empilées au milieu du cadre.
	_mug.call("build")
	_mug.connect("hover_changed", Callable(self, "_on_mug_hover"))


func _build_papers() -> void:
	_papers = []
	for entry in PAPERS:
		var paper := Node3D.new()
		paper.name = "Paper_%s" % entry["kind"]
		paper.set_script(preload("res://scripts/components/wall_paper.gd"))
		paper.set("kind", entry["kind"])
		paper.set("room", _room)
		var at: Vector2 = entry["at"]
		paper.position = _room.wall_point(at.x, at.y) + Vector3(0, 0, 0.05)
		_room.add_child(paper)
		paper.call("build")
		paper.connect("hover_changed", Callable(self, "_on_paper_hover"))
		paper.connect("clicked", Callable(self, "_on_paper_clicked"))
		paper.connect("state_changed", Callable(self, "refresh"))
		paper.connect("open_team_hub", Callable(self, "_open_team_hub"))
		_papers.append(paper)


## Le hub d'équipe complet, appelé depuis le trombinoscope levé. C'est le seul
## endroit du bureau qui soit franchement un modal, et il l'est pour une
## raison : « se séparer de quelqu'un » est irréversible et demande une
## confirmation. Tout le reste — les quatre critères, les actions du
## quotidien — se joue sous le poster, sans quitter la pièce.
func _open_team_hub() -> void:
	var existing := _layer.get_node_or_null("TeamManagementDialog")
	if existing != null:
		return
	var dialog: Control = load("res://scenes/components/team_management_dialog.tscn").instantiate()
	_layer.add_child(dialog)
	dialog.connect("state_changed", Callable(self, "refresh"))


## Chaque mécanique a son accessoire, et la forme dit ce qu'elle est : la
## tablette se feuillette et se repousse (elle est là en permanence), la
## planche se signe une fois (c'est le point de non-retour), le parapheur n'est
## déposé qu'un sprint sur trois.
func _build_props() -> void:
	_props = {}
	for kind in ["shop", "closing", "committee"]:
		var prop := Node3D.new()
		prop.name = kind
		prop.set_script(preload("res://scripts/components/desk_prop.gd"))
		prop.set("kind", kind)
		prop.set("room", _room)
		_room.add_child(prop)
		prop.call("build")
		prop.connect("state_changed", Callable(self, "refresh"))
		_props[kind] = prop


# ── La couche 2D : tout ce qui se lit ────────────────────────────────────
func _build_canvas() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "Readable"
	add_child(_layer)

	## Aucun élément ne prend la largeur ni la hauteur entière : une barre
	## pleine fait interface web sur une scène de jeu, et c'est le défaut qu'on
	## corrige. Le banc UI l'asserte depuis #59.
	_vitals = _zone(Vector2(34, 26))
	_vitals.name = "Vitals"
	_layer.add_child(_vitals)

	_chip = _zone(Vector2(0, 26))
	_chip.name = "SprintChip"
	_layer.add_child(_chip)

	_alerts = Control.new()
	_alerts.name = "Alerts"
	_alerts.position = Vector2(34, 98)
	_alerts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_alerts)

	_energy = Label.new()
	_energy.name = "EnergyCaption"
	_energy.add_theme_color_override("font_color", DESK_LABEL)
	UIHelpers.apply_mono(_energy, 12, true)
	_energy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_energy)

	for kind in _props:
		var hint := Label.new()
		hint.name = "Hint_%s" % kind
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", DESK_LABEL)
		UIHelpers.apply_mono(hint, 11, true)
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layer.add_child(hint)

	_tooltip = _zone(Vector2.ZERO)
	_tooltip.name = "PaperTooltip"
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_tooltip)

	_detail = PanelContainer.new()
	_detail.name = "PaperDetail"
	_detail.visible = false
	# `STOP` : un clic dans le détail ne doit pas être lu comme un « clic
	# ailleurs » qui referme le poster qu'on est en train de lire.
	_detail.mouse_filter = Control.MOUSE_FILTER_STOP
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color("#fdfcf6")
	detail_style.border_color = UIHelpers.COLOR_INK
	detail_style.set_border_width_all(3)
	detail_style.set_corner_radius_all(6)
	detail_style.shadow_color = Color(0, 0, 0, 0.28)
	detail_style.shadow_size = 10
	detail_style.shadow_offset = Vector2(0, 8)
	detail_style.content_margin_left = 22
	detail_style.content_margin_right = 22
	detail_style.content_margin_top = 18
	detail_style.content_margin_bottom = 18
	_detail.add_theme_stylebox_override("panel", detail_style)
	# Sous les zones de valeurs et les alertes : aucune décision ne doit se
	# prendre à l'aveugle pendant qu'un poster est levé.
	_layer.add_child(_detail)
	_layer.move_child(_detail, 0)


func _zone(at: Vector2) -> PanelContainer:
	var zone := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = ZONE_BG
	style.border_color = ZONE_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	zone.add_theme_stylebox_override("panel", style)
	zone.position = at
	return zone


func _refresh_vitals() -> void:
	UIHelpers.clear_children(_vitals)
	var vitals := SprintState.get_desk_vitals()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)

	# 💥 L'Impact est une **progression**, pas un nombre nu : le quota est
	# présent par la forme, sans être un deuxième chiffre à surveiller.
	var impact := HBoxContainer.new()
	impact.name = "Vital_impact"
	impact.add_theme_constant_override("separation", 9)
	impact.tooltip_text = "💥 Impact — solde du portefeuille.\nLe board compare ce solde au quota du trimestre : %d / %d." % [
		vitals.get("impact", 0), vitals.get("quota", 0)]
	impact.add_child(_value_label("💥 %d" % int(vitals.get("impact", 0))))
	impact.add_child(_progress_bar(float(vitals.get("quotaRatio", 0.0))))
	row.add_child(impact)

	row.add_child(_separator())

	var cash := _value_label("💰 %s" % _short_money(int(vitals.get("revenue", 0))))
	cash.name = "Vital_revenue"
	cash.tooltip_text = "💰 Trésorerie — ce qui paie les salaires, les licences et le support.\nCharges du sprint : %d." % int(SprintState.get_recurring_charges().get("total", 0))
	cash.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(cash)

	row.add_child(_separator())

	var users := _value_label("👥 %s" % _short_count(int(vitals.get("users", 0))))
	users.name = "Vital_users"
	users.tooltip_text = "👥 Utilisateurs — la population qui paie chaque sprint.\nElle grandit par les livraisons, elle s'érode au churn."
	users.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(users)

	_vitals.add_child(row)

	UIHelpers.clear_children(_chip)
	var sprint_label := Label.new()
	sprint_label.text = "SPRINT %d · T%d" % [SprintState.sprint_number, SprintState.quarter_index]
	sprint_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	UIHelpers.apply_mono(sprint_label, 12, true)
	_chip.add_child(sprint_label)
	# La pastille est ancrée à droite : sa largeur dépend du texte, donc on la
	# repositionne une fois le conteneur dimensionné.
	_chip.reset_size()
	_chip.position.x = DESIGN.x - _chip.size.x - 34


func _value_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", UIHelpers.COLOR_INK)
	UIHelpers.apply_mono(label, 17, true)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func _separator() -> Control:
	var rule := ColorRect.new()
	rule.color = Color("#dfe3e0")
	rule.custom_minimum_size = Vector2(1, 26)
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rule


## Une barre est un `Control` nu avec deux `Panel` posés à la main : dans un
## conteneur, le remplissage serait étiré sur toute la largeur et la jauge
## paraîtrait toujours pleine (carnet §19, même piège que le Panneau de bord).
func _progress_bar(ratio: float) -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(88, 4)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var track := Panel.new()
	track.add_theme_stylebox_override("panel", _flat(Color("#dfe3e0"), 2))
	bar.add_child(track)
	var fill := Panel.new()
	fill.add_theme_stylebox_override("panel", _flat(UIHelpers.COLOR_GOOD, 2))
	bar.add_child(fill)

	var layout := func():
		track.position = Vector2.ZERO
		track.size = Vector2(bar.size.x, 4)
		fill.position = Vector2.ZERO
		fill.size = Vector2(round(bar.size.x * clampf(ratio, 0.0, 1.0)), 4)
	layout.call()
	bar.resized.connect(layout)
	return bar


## Les alertes n'existent que quand il y en a : c'est le principe de la
## remontée par exception. Une zone vide ne laisse rien à l'écran.
func _refresh_alerts() -> void:
	UIHelpers.clear_children(_alerts)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	_alerts.add_child(row)

	for alert in SprintState.get_active_alerts():
		var danger := String(alert.get("severity", "warn")) == "danger"
		var color := UIHelpers.COLOR_DANGER if danger else UIHelpers.COLOR_WARN

		var chip := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.94)
		style.border_color = color
		style.set_border_width_all(2)
		style.set_corner_radius_all(20)
		style.content_margin_left = 15
		style.content_margin_right = 15
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		chip.add_theme_stylebox_override("panel", style)

		var label := Label.new()
		label.text = "● %s" % String(alert.get("label", ""))
		label.add_theme_color_override("font_color", color)
		label.add_theme_font_size_override("font_size", 13)
		chip.add_child(label)
		row.add_child(chip)


## Les étiquettes qui appartiennent à un objet du monde : elles suivent sa
## projection, mais restent **de face et nettes**. C'est le partage 3D/2D
## appliqué à la plus petite échelle qui soit — un mot sous une tasse.
func _refresh_anchored_labels() -> void:
	_energy.text = "⚡ ÉNERGIE %d" % SprintState.energy
	_energy.tooltip_text = UIHelpers.energy_tooltip()
	_energy.reset_size()
	_energy.position = _anchor(_room.project_to_design(_mug.global_position) + Vector2(0, 30), _energy.size)

	for kind in _props:
		var prop: Node3D = _props[kind]
		var hint: Label = _layer.get_node("Hint_%s" % kind)
		hint.visible = prop.visible and not prop.is_open()
		if not hint.visible:
			continue
		hint.text = prop.hint_text()
		hint.reset_size()
		hint.position = _anchor(_room.project_to_design(prop.hint_anchor()), hint.size)


## Centre une étiquette sur la projection d'un objet, **sans la laisser sortir
## du cadre** : un objet posé au bord du plateau projette son ancre hors champ,
## et l'étiquette disparaissait avec lui sans que rien ne le signale.
func _anchor(at: Vector2, size: Vector2) -> Vector2:
	return Vector2(
		clampf(at.x - size.x * 0.5, 16.0, DESIGN.x - size.x - 16.0),
		clampf(at.y, 16.0, DESIGN.y - size.y - 12.0))


# ── Le survol : deux lignes, en 2D, de face ──────────────────────────────
func _on_paper_hover(paper: Node3D, entered: bool) -> void:
	if not entered or paper == _lifted:
		_tooltip.visible = false
		return
	var summary: Dictionary = paper.hover_summary()
	UIHelpers.clear_children(_tooltip)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var title := Label.new()
	title.text = String(summary.get("title", ""))
	title.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	UIHelpers.apply_mono(title, 10, true)
	box.add_child(title)
	var line := Label.new()
	line.text = String(summary.get("line", ""))
	line.add_theme_font_size_override("font_size", 13)
	box.add_child(line)
	_tooltip.add_child(box)
	_tooltip.visible = true
	_tooltip.reset_size()
	var at := _room.project_to_design(paper.global_position)
	_tooltip.position = Vector2(
		clampf(at.x - _tooltip.size.x * 0.5, 20.0, DESIGN.x - _tooltip.size.x - 20.0),
		at.y + 74.0)


func _on_mug_hover(entered: bool) -> void:
	if not entered:
		_tooltip.visible = false
		return
	UIHelpers.clear_children(_tooltip)
	var line := Label.new()
	line.text = UIHelpers.energy_tooltip()
	line.add_theme_font_size_override("font_size", 12)
	_tooltip.add_child(line)
	_tooltip.visible = true
	_tooltip.reset_size()
	var at := _room.project_to_design(_mug.global_position)
	_tooltip.position = Vector2(
		clampf(at.x - _tooltip.size.x * 0.5, 20.0, DESIGN.x - _tooltip.size.x - 20.0),
		at.y - _tooltip.size.y - 60.0)


# ── La levée du poster ───────────────────────────────────────────────────
## Le geste raconte la mécanique : un menu modal aurait dit « écran de gestion
## RH », la levée dit « je vais voir mes gens ». Elle ne coûte ni Énergie ni
## sprint, et elle s'annule vite — sinon la vue synthétique reste cachée
## pendant qu'une décision se prend à l'aveugle.
func _on_paper_clicked(paper: Node3D) -> void:
	_paper_click_frame = Engine.get_process_frames()
	_tooltip.visible = false
	if _lifted == paper:
		_close_lifted()
		return
	if _lifted != null:
		_lifted.set_lifted(false)
	_lifted = paper
	paper.set_lifted(true)
	_fill_detail(paper)


func _close_lifted() -> void:
	if _lifted == null:
		return
	_lifted.set_lifted(false)
	_lifted = null
	_detail.visible = false
	_set_anchored_labels_visible(true)
	_refresh_anchored_labels()


func _set_anchored_labels_visible(value: bool) -> void:
	_energy.visible = value
	for kind in _props:
		_layer.get_node("Hint_%s" % kind).visible = value


func _fill_detail(paper: Node3D) -> void:
	UIHelpers.clear_children(_detail)
	# Un `PanelContainer` n'accepte qu'UN enfant : lui en donner deux les
	# empile l'un sur l'autre, sans erreur — le bouton de fermeture se
	# retrouvait écrit par-dessus la fiche d'une personne.
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_detail.add_child(column)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(940, 450)
	var content: Control = paper.build_detail()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	column.add_child(scroll)

	var close := Button.new()
	close.name = "CloseDetail"
	close.text = "Reposer la feuille  ·  Échap"
	close.flat = true
	close.add_theme_font_size_override("font_size", 11)
	close.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	close.pressed.connect(_close_lifted)
	column.add_child(close)

	# Les étiquettes accrochées aux objets du plateau disparaissent : elles
	# nomment des choses que la feuille levée recouvre, et elles se dessinaient
	# par-dessus le détail qu'on est en train de lire.
	_set_anchored_labels_visible(false)
	_detail.visible = true
	_detail.reset_size()
	# Sous la feuille levée, jamais plein cadre : le bandeau et les alertes
	# doivent rester lisibles par-dessus.
	_detail.position = Vector2(
		clampf(_room.project_to_design(paper.global_position).x - _detail.size.x * 0.5,
			24.0, DESIGN.x - _detail.size.x - 24.0),
		DESIGN.y - _detail.size.y - 40.0)


## L'annulation rapide, dans les deux sens exigés par la spec : Échap, ou un
## clic ailleurs. Le clic passe par un `call_deferred` parce que la sélection
## physique (`Area3D`) et `_unhandled_input` ne sont pas ordonnés entre eux :
## refermer tout de suite refermerait aussi le poster qu'on vient d'ouvrir.
func _unhandled_input(event: InputEvent) -> void:
	if _lifted == null:
		return
	if event.is_action_pressed("ui_cancel"):
		_close_lifted()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_unless_reclaimed.call_deferred(Engine.get_process_frames())


func _close_unless_reclaimed(frame: int) -> void:
	if _paper_click_frame == frame:
		return
	_close_lifted()


# ── Petits utilitaires ───────────────────────────────────────────────────
func _flat(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style


## Les grands nombres se lisent en un coup d'œil ou ne se lisent pas : la
## trésorerie exacte est dans le tooltip, pas dans la zone.
func _short_money(amount: int) -> String:
	if absi(amount) >= 1000:
		return "%.1f k€" % (float(amount) / 1000.0)
	return "%d €" % amount


func _short_count(count: int) -> String:
	if count >= 10000:
		return "%.1f k" % (float(count) / 1000.0)
	return str(count)
