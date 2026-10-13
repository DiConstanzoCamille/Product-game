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
var _prop_close: Button = null
var _workstation: Control = null
var _mug: Node3D = null

var _papers: Array = []
var _props: Dictionary = {}
var _lifted: Node3D = null
var _paper_click_frame := -1
var _prop_click_frame := -1
var _view: DeskViewController
var _reticle: Label
var _view_hint: Label
var _view_mode: Button
var _aimed: Area3D
var _last_activity: Dictionary = {}
var _activity_elapsed := 0.0
var _delta_feed: VBoxContainer
var _surface_input = preload("res://scripts/components/desk_surface_input.gd").new()


func _ready() -> void:
	# Observation par rayon explicite ; lecture par relais de surface. Ne pas
	# rejouer une seconde fois les mêmes clics via le picking physique différé.
	get_viewport().physics_object_picking = false
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
	_view = DeskViewController.new()
	_view.name = "SeatedView"
	add_child(_view)
	_view.setup(_room.camera, SprintState.get_desk_conf()["camera"])
	_view.target_requested.connect(_activate_target)
	_view.state_changed.connect(_on_view_state_changed)
	_view.pose_changed.connect(_refresh_anchored_labels)
	get_viewport().size_changed.connect(_on_canvas_resized)
	_room.get_node("Lid/DalleArea").set_meta("desk_target", "laptop")
	_mug.get_node("Area").set_meta("desk_target", "mug")
	for entry in _papers:
		entry.get_node("Sheet/Area").set_meta("desk_target", "paper:" + String(entry.kind))
	for kind in _props:
		_props[kind].get_node("Area").set_meta("desk_target", "prop:" + kind)
	refresh()
	_on_view_state_changed()
	_on_canvas_resized()


func _on_canvas_resized() -> void:
	if _view == null:
		return
	var canvas := _room.canvas_size()
	_reticle.position = canvas * 0.5 - Vector2(7, 15)
	_view_mode.position.y = canvas.y - 64
	_view_hint.position.y = canvas.y - 50
	_chip.position.x = canvas.x - _chip.size.x - 34
	if _view.state == DeskViewController.State.FOCUS:
		_room.camera.fov = float(_room.reading_pose()["fov"])
	_refresh_prop_close()
	_refresh_anchored_labels()


func view_controller() -> DeskViewController:
	return _view


func _on_view_state_changed() -> void:
	if _view == null:
		return
	if _view.state != DeskViewController.State.FOCUS:
		_surface_input.reset()
	if _view.state == DeskViewController.State.FOCUS:
		_room.camera.fov = float(_room.reading_pose()["fov"])
	_clear_aim()
	_sync_interaction_scope()
	_refresh_prop_close()
	_refresh_anchored_labels()
	_view_mode.disabled = not _view.observing()
	_view_mode.text = "Regard : clic droit maintenu" if _view.comfort else "Regard : immersif"
	_reticle.visible = _view.state == DeskViewController.State.LOOK
	if _view.observing():
		_view_hint.text = "Visez un objet · clic pour l'utiliser · Échap : libérer la souris" if _reticle.visible else ("Clic droit maintenu : regarder · clic gauche : utiliser" if _view.comfort else "Cliquez sur un objet pour l'utiliser · ailleurs pour regarder")
	else:
		_view_hint.text = "Mode curseur · cliquez, glissez, faites défiler · Échap : revenir" if not _view.transitioning() else ""


func _process(_delta: float) -> void:
	_activity_elapsed += _delta
	if _activity_elapsed >= 0.15 and _delta_feed != null:
		_activity_elapsed = 0.0
		_observe_activity()
	if _view == null or not _view.observing():
		return
	var at := get_viewport().get_mouse_position() if _view.state == DeskViewController.State.FREE else get_viewport().get_visible_rect().size * 0.5
	var hit := _view.hit_at(at)
	var area: Area3D = hit.get("collider") as Area3D
	if area != _aimed:
		_clear_aim()
		_aimed = area
		if _aimed != null:
			_aimed.mouse_entered.emit()
	_reticle.modulate = Color("#e4b578") if _aimed != null else Color.WHITE


func _clear_aim() -> void:
	if is_instance_valid(_aimed):
		_aimed.mouse_exited.emit()
	_aimed = null


func _activate_target(id: String) -> void:
	if id == "laptop":
		_focus_on("laptop", func(): pass)
	elif id.begins_with("prop:"):
		open_prop(id.trim_prefix("prop:"))
	elif id.begins_with("paper:"):
		lift_paper(id.trim_prefix("paper:"))
	elif id == "mug":
		_focus_on("mug", func(): _on_mug_hover(true))


func _focus_on(id: String, action: Callable) -> void:
	if _view == null:
		action.call()
		return
	if _view.focus_target == id and _view.state == DeskViewController.State.FOCUS:
		action.call()
		return
	var pose := _room.reading_pose()
	if id.begins_with("prop:"):
		pose = prop(id.trim_prefix("prop:")).focus_pose()
	_view.begin_focus(id, pose, action)


func _leave_focus() -> void:
	_tooltip.visible = false
	if _view != null:
		_view.return_to_observation()


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
	_refresh_prop_close()
	_sync_interaction_scope()
	_observe_activity()


func _observe_activity() -> void:
	if _delta_feed == null:
		return
	var activity := SprintState.get_desk_activity()
	if activity == _last_activity:
		return
	_delta_feed.observe(_last_activity, activity)
	_last_activity = activity
	_workstation.refresh_status()
	_refresh_vitals()
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
	if _open_prop_node() != null:
		return
	var target := paper(kind)
	if target != null:
		_focus_on("paper:" + kind, func(): _on_paper_clicked(target))


func open_app(id: String) -> void:
	if _workstation != null and _open_prop_node() == null:
		_focus_on("laptop", func(): _workstation.call("open_app", id))


func open_prop(kind: String) -> void:
	if _open_prop_node() != null:
		return
	var target := prop(kind)
	if target != null and target.visible:
		_focus_on("prop:" + kind, func(): target.call("expand"))


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
	_mug.position = Vector3(-0.87, DeskRoom.DESK_TOP_Y, 0.43)
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
		prop.connect("interacted", Callable(self, "_on_prop_interacted"))
		prop.connect("hover_changed", Callable(self, "_on_prop_hover"))
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
	_delta_feed = preload("res://scripts/components/hud_delta_feed.gd").new()
	_delta_feed.name = "ResourceChanges"
	_delta_feed.position = Vector2(34, 154)
	_layer.add_child(_delta_feed)

	_energy = Label.new()
	_energy.name = "EnergyCaption"
	_energy.add_theme_color_override("font_color", DESK_LABEL)
	UIHelpers.apply_mono(_energy, 12, true)
	_energy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_energy)

	# La commande appartient au bureau, pas à la texture de l'accessoire. Elle
	# reste donc nette, stable et au-dessus du monde quel que soit l'objet ouvert.
	_prop_close = Button.new()
	_prop_close.name = "PropClose"
	_prop_close.text = "Reposer  ·  Échap"
	_prop_close.visible = false
	_prop_close.position = Vector2(DESIGN.x - 234, 92)
	_prop_close.custom_minimum_size = Vector2(200, 42)
	_prop_close.add_theme_font_size_override("font_size", 13)
	_prop_close.add_theme_color_override("font_color", UIHelpers.COLOR_INK)
	_prop_close.add_theme_stylebox_override("normal", _flat(Color(1, 1, 1, 0.94), 10))
	_prop_close.add_theme_stylebox_override("hover", _flat(Color("#fff4cc"), 10))
	_prop_close.pressed.connect(_close_focused_object)
	_layer.add_child(_prop_close)

	_view_mode = Button.new()
	_view_mode.name = "ViewMode"
	_view_mode.position = Vector2(34, 836)
	_view_mode.custom_minimum_size = Vector2(240, 40)
	_view_mode.pressed.connect(func(): _view.set_comfort(not _view.comfort))
	_layer.add_child(_view_mode)
	_view_hint = Label.new()
	_view_hint.name = "ViewHint"
	_view_hint.position = Vector2(390, 850)
	_view_hint.add_theme_font_size_override("font_size", 13)
	_view_hint.add_theme_color_override("font_color", Color("#fff7e7"))
	_view_hint.add_theme_color_override("font_shadow_color", Color("#242e35"))
	_view_hint.add_theme_constant_override("shadow_offset_x", 1)
	_view_hint.add_theme_constant_override("shadow_offset_y", 1)
	_view_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_view_hint)
	_reticle = Label.new()
	_reticle.name = "Reticle"
	_reticle.text = "+"
	_reticle.position = DESIGN * 0.5 - Vector2(7, 15)
	_reticle.add_theme_font_size_override("font_size", 22)
	_reticle.add_theme_color_override("font_color", Color.WHITE)
	_reticle.add_theme_color_override("font_shadow_color", Color("#242e35"))
	_reticle.add_theme_constant_override("shadow_offset_x", 1)
	_reticle.add_theme_constant_override("shadow_offset_y", 1)
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticle.visible = false
	_layer.add_child(_reticle)

	for kind in _props:
		var hint := preload("res://scripts/components/desk_object_badge.gd").new()
		hint.name = "Hint_%s" % kind
		hint.pressed.connect(func(): open_prop(kind))
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
	impact.add_child(_value_label("💥 Impact %d" % int(vitals.get("impact", 0))))
	impact.add_child(_progress_bar(float(vitals.get("quotaRatio", 0.0))))
	row.add_child(impact)

	row.add_child(_separator())

	var cash := _value_label("💰 Trésorerie %s" % _short_money(int(vitals.get("revenue", 0))))
	cash.name = "Vital_revenue"
	cash.tooltip_text = "💰 Trésorerie — ce qui paie les salaires, les licences et le support.\nCharges du sprint : %d." % int(SprintState.get_recurring_charges().get("total", 0))
	cash.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(cash)

	row.add_child(_separator())

	var users := _value_label("👥 Utilisateurs %s" % _short_count(int(vitals.get("users", 0))))
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
	if _energy == null or _room == null:
		return
	_energy.text = "⚡ ÉNERGIE %d" % SprintState.energy
	_energy.tooltip_text = UIHelpers.energy_tooltip()
	_energy.reset_size()
	var mug_point := _room.project_to_design(_mug.global_position)
	_energy.visible = _lifted == null and Rect2(Vector2.ZERO, _room.canvas_size()).has_point(mug_point)
	_energy.position = _anchor(mug_point + Vector2(0, 30), _energy.size)

	for kind in _props:
		var prop: Node3D = _props[kind]
		var hint: Button = _layer.get_node("Hint_%s" % kind)
		var point := _room.project_to_design(prop.hint_anchor())
		hint.visible = (_view == null or _view.observing()) and _lifted == null and prop.visible and not prop.is_open() and Rect2(Vector2.ZERO, _room.canvas_size()).has_point(point)
		if not hint.visible:
			continue
		hint.text = {"shop": "BOUTIQUE  ›\nRecruter · outils · pratiques", "committee": "COMITÉ  ›\nInvestissements du trimestre", "closing": "FIN DE SPRINT  ›"}.get(kind, prop.hint_text())
		if kind == "closing":
			var activity := SprintState.get_desk_activity()
			var plan_text := "%d ticket%s enregistré%s" % [activity["tickets"], "s" if activity["tickets"] != 1 else "", "s" if activity["tickets"] != 1 else ""] if activity["saved"] else "Plan non enregistré"
			hint.text += "\n%s\n%d message%s en attente" % [plan_text, activity["pending"], "s" if activity["pending"] != 1 else ""]
		hint.reset_size()
		hint.position = _anchor(point, hint.size)


func _refresh_prop_close() -> void:
	if _prop_close == null:
		return
	var opened := _open_prop_node()
	_prop_close.visible = opened != null or (_view != null and _view.state == DeskViewController.State.FOCUS and _lifted == null)
	if opened != null:
		_prop_close.text = "Reposer %s  ·  Échap" % String(opened.call("hint_text")).to_lower()
		_prop_close.reset_size()
		_prop_close.position.x = _room.canvas_size().x - _prop_close.size.x - 34.0
	elif _prop_close.visible:
		_prop_close.text = "Quitter l'ordinateur · Échap" if _view.focus_target == "laptop" else "Reposer · Échap"
		_prop_close.reset_size()
		_prop_close.position.x = _room.canvas_size().x - _prop_close.size.x - 34.0


## Centre une étiquette sur la projection d'un objet, **sans la laisser sortir
## du cadre** : un objet posé au bord du plateau projette son ancre hors champ,
## et l'étiquette disparaissait avec lui sans que rien ne le signale.
func _anchor(at: Vector2, size: Vector2) -> Vector2:
	var canvas := _room.canvas_size()
	return Vector2(
		clampf(at.x - size.x * 0.5, 16.0, canvas.x - size.x - 16.0),
		clampf(at.y, 16.0, maxf(16.0, canvas.y - size.y - 80.0)))


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


func _on_prop_hover(prop: Node3D, entered: bool) -> void:
	var hint: Button = _layer.get_node_or_null("Hint_%s" % prop.kind)
	if hint == null:
		return
	hint.set_world_hover(entered)
	_refresh_anchored_labels()


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
	_leave_focus()


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
func _input(event: InputEvent) -> void:
	# Un geste commencé dans l'ordinateur lui appartient jusqu'au relâchement,
	# même si la souris passe sur le bouton Reposer du CanvasLayer.
	if _surface_input.held and event is InputEventMouse and _room != null:
		if _surface_input.route(_room.camera, event):
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _view != null and _view.state == DeskViewController.State.FOCUS:
		if event.is_action_pressed("ui_cancel") and is_instance_valid(_surface_input.viewport) and _surface_input.viewport.gui_is_dragging():
			_surface_input.reset()
			get_viewport().set_input_as_handled()
			return
		var surface: MeshInstance3D
		var target: SubViewport
		if _view.focus_target == "laptop":
			surface = _room.get_node("Lid/Dalle")
			target = _room.screen_viewport
		elif _open_prop_node() != null:
			surface = _open_prop_node().get_node("PanelPivot/Panel")
			target = _open_prop_node().get_node("PanelPivot/PropViewport")
		if target != null:
			_surface_input.bind(surface, target)
			if _surface_input.route(_room.camera, event):
				get_viewport().set_input_as_handled()
				return
	if _view != null and _view.handle_observation(event):
		get_viewport().set_input_as_handled()
		return
	if _view != null and _view.transitioning():
		if event.is_action_pressed("ui_cancel"):
			_view.release_look()
			_leave_focus()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		if _lifted != null:
			_close_lifted()
			get_viewport().set_input_as_handled()
			return
		if _open_prop_node() != null:
			_close_open_prop()
			get_viewport().set_input_as_handled()
			return
		if _workstation != null and bool(_workstation.call("is_open")):
			_workstation.call("close_app")
			get_viewport().set_input_as_handled()
			return
		if _view != null and _view.state == DeskViewController.State.FOCUS:
			_leave_focus()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var frame := Engine.get_process_frames()
		if _lifted != null:
			_close_unless_reclaimed.call_deferred(frame)
		elif _open_prop_node() != null:
			_close_prop_unless_reclaimed.call_deferred(frame)
		elif _view != null and _view.state == DeskViewController.State.FOCUS:
			_close_laptop_unless_hit.call_deferred(event.position)


func _close_laptop_unless_hit(at: Vector2) -> void:
	if _view == null or _view.state != DeskViewController.State.FOCUS:
		return
	# La dalle a la couche 2 en focus : le rayon d'observation ne la sélectionne pas.
	var camera := _room.camera
	var origin := camera.project_ray_origin(at)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(at) * float(SprintState.get_desk_conf()["camera"]["rayLength"]), 2)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	if camera.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		_close_focused_object()


func _close_focused_object() -> void:
	if _open_prop_node() != null:
		_close_open_prop()
	elif _lifted != null:
		_close_lifted()
	else:
		if _workstation != null and _workstation.is_open():
			_workstation.close_app()
		_leave_focus()


func _close_unless_reclaimed(frame: int) -> void:
	if _paper_click_frame == frame:
		return
	_close_lifted()


func _on_prop_interacted() -> void:
	_prop_click_frame = Engine.get_process_frames()


func _open_prop_node() -> Node3D:
	for kind in _props:
		var candidate: Node3D = _props[kind]
		if bool(candidate.call("is_open")):
			return candidate
	return null


func _close_open_prop() -> void:
	var opened := _open_prop_node()
	if opened != null:
		opened.call("collapse")
	_leave_focus()


func _close_prop_unless_reclaimed(frame: int) -> void:
	if _prop_click_frame == frame:
		return
	_close_open_prop()


## Un accessoire présenté est modal dans la scène 3D : son panneau reste
## interactif, tout ce qui est derrière devient temporairement du décor. On
## neutralise aussi les Controls du CanvasLayer (hors « Reposer »), afin qu'un
## clic sur les valeurs permanentes soit bien lu comme un clic extérieur.
func _sync_interaction_scope() -> void:
	if _room == null:
		return
	var opened := _open_prop_node()
	var observing := _view == null or _view.observing()
	var ready_focus := _view != null and _view.state == DeskViewController.State.FOCUS
	var world_unlocked := opened == null and observing
	for area in _room.find_children("*", "Area3D", true, false):
		(area as Area3D).input_ray_pickable = false
		(area as Area3D).collision_layer = 1 if world_unlocked and area.has_meta("desk_target") and area.is_visible_in_tree() else 0
	for kind in _props:
		var prop: Node3D = _props[kind]
		var prop_ready: bool = ready_focus and prop == opened and not prop.is_presenting()
		prop.call("set_input_scope", false, prop_ready)
		var panel_area: Area3D = prop.get_node("PanelPivot/PanelArea")
		panel_area.collision_layer = 2 if panel_area.input_ray_pickable else 0
		var viewport: SubViewport = prop.get_node("PanelPivot/PropViewport")
		viewport.gui_disable_input = not prop_ready
	var dalle_area: Area3D = _room.get_node("Lid/DalleArea")
	dalle_area.input_ray_pickable = ready_focus and _view.focus_target == "laptop"
	if dalle_area.input_ray_pickable:
		dalle_area.collision_layer = 2
	_room.screen_viewport.gui_disable_input = not dalle_area.input_ray_pickable
	_set_canvas_interactions_locked(not world_unlocked)
	# Le relais géométrique traite les événements immédiatement, sans attendre
	# le picking physique ni perdre le relâchement à l'extérieur du panneau.
	get_viewport().physics_object_picking = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_EXIT_TREE:
		_surface_input.reset()


func _set_canvas_interactions_locked(locked: bool) -> void:
	if _layer == null:
		return
	var pending: Array[Node] = [_layer]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child in node.get_children():
			pending.append(child)
		if not (node is Control) or node == _prop_close or node == _view_mode or node == _detail or _detail.is_ancestor_of(node) or node.name == "TeamManagementDialog" or (_layer.get_node_or_null("TeamManagementDialog") != null and _layer.get_node("TeamManagementDialog").is_ancestor_of(node)):
			continue
		var control := node as Control
		if locked:
			if not control.has_meta("desk_mouse_filter"):
				control.set_meta("desk_mouse_filter", control.mouse_filter)
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif control.has_meta("desk_mouse_filter"):
			control.mouse_filter = int(control.get_meta("desk_mouse_filter"))
			control.remove_meta("desk_mouse_filter")


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
