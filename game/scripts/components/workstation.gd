extends Control
## Le poste de travail — les *logiciels* du bureau (#54 §2).
##
## Trois applications seulement s'ouvrent « dans un écran », et c'est parce que
## ce sont vraiment des écrans : la boîte mail, la roadmap, le tableau de bord.
## Tout le reste du jeu est du décor ou un accessoire qui entre dans le cadre.
##
## Le moniteur a deux tailles, et c'est le point le plus discutable du lot :
## posé sur le plateau il tiendrait dans ~670×400, où aucune phase existante
## n'est lisible. Ouvrir une application **agrandit la dalle** au lieu de
## réduire le contenu — le bureau reste visible tout autour, donc on n'a pas
## quitté la pièce, mais la phase a la place de se lire. C'est ce qui permet
## d'héberger les écrans existants *tels quels* et de les faire maigrir au lot
## suivant (#10) sans retoucher le hub.
##
## Aucune phase n'est un `change_scene_to_file` : elles sont instanciées ici,
## leurs boutons de navigation sont recâblés vers « retour au bureau », et leur
## Panneau de bord est neutralisé (`UIHelpers.hosted_in_desk`).

signal state_changed

const CLOSED_RECT := Rect2(Vector2(466, 340), Vector2(668, 404))
## La dalle ouverte tient **entre** les papiers du mur : le journal s'arrête à
## x=558, la feuille d'objectif commence à x=1358. Une première version prenait
## 1380 de large et recouvrait les trois — on ne voyait plus ni l'équipe, ni le
## journal, ni l'objectif pendant qu'on jouait une phase, ce qui annule tout
## l'intérêt du hub. Le moniteur reste un objet posé sur un bureau, pas un
## écran plein cadre déguisé.
const OPEN_RECT := Rect2(Vector2(586, 128), Vector2(762, 664))
const BEZEL := 13.0

const SCREEN_BG := Color("#141a26")
const BEZEL_COLOR := Color("#3a4150")
const APP_BG := Color(1, 1, 1, 0.06)
const APP_BORDER := Color(1, 1, 1, 0.14)

const SCENES := {
	"inbox": "res://scenes/screens/inbox_screen.tscn",
	"roadmap": "res://scenes/screens/roadmap_screen.tscn",
}

var apps: Array = []

var _open_id := ""
var _hosted: Control = null
var _body: Control = null
var _rect := CLOSED_RECT


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = Vector2(1600, 900)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_body = Control.new()
	_body.name = "Body"
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)

	_apply_rect(CLOSED_RECT)
	_show_apps()


func is_open() -> bool:
	return _open_id != ""


# ── La dalle ─────────────────────────────────────────────────────────────
func _apply_rect(rect: Rect2) -> void:
	_rect = rect
	_body.position = rect.position + Vector2(BEZEL, BEZEL)
	_body.size = rect.size - Vector2(BEZEL, BEZEL) * 2.0
	queue_redraw()


func _draw() -> void:
	var outer := Rect2(_rect.position - Vector2(BEZEL, BEZEL), _rect.size + Vector2(BEZEL, BEZEL) * 2.0)
	draw_rect(outer, BEZEL_COLOR)
	draw_rect(_rect, SCREEN_BG)

	# Le pied et le clavier ne se dessinent qu'au repos : dalle agrandie, ils
	# seraient sous l'application et ne raconteraient plus rien.
	if is_open():
		return
	var center := _rect.position.x + _rect.size.x * 0.5
	var base := _rect.end.y + BEZEL
	draw_rect(Rect2(Vector2(center - 118, base), Vector2(236, 10)), Color("#2f353f"))
	draw_rect(Rect2(Vector2(center - 82, base + 10), Vector2(164, 28)), BEZEL_COLOR)
	draw_rect(Rect2(Vector2(center - 210, base + 62), Vector2(420, 54)), Color("#dfe2e4"))
	draw_rect(Rect2(Vector2(center - 210, base + 62), Vector2(420, 54)), UIHelpers.COLOR_INK, false, 2.0)
	for i in range(17):
		draw_rect(Rect2(Vector2(center - 198 + i * 24, base + 71), Vector2(18, 36)), Color("#c6cbcf"))


# ── Le bureau du poste : trois tuiles ────────────────────────────────────
func _show_apps() -> void:
	UIHelpers.clear_children(_body)
	_apply_rect(CLOSED_RECT)

	_body.add_child(_os_bar("POSTE DE TRAVAIL", false))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.position = Vector2(0, 90)
	row.size = Vector2(_body.size.x, 200)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_body.add_child(row)

	for app in apps:
		row.add_child(_app_tile(app))


## Chaque tuile porte son état **avant** qu'on l'ouvre : c'est là que la Dette
## se voit sans chiffre (roadmap congestionnée), et que le courrier non traité
## se rappelle au joueur qui allait le sauter.
func _app_tile(app: Dictionary) -> Control:
	var id := String(app.get("id", ""))
	var tile := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = APP_BG
	style.border_color = APP_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 19
	style.content_margin_bottom = 19
	tile.add_theme_stylebox_override("panel", style)
	tile.custom_minimum_size = Vector2(182, 0)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon := Control.new()
	icon.custom_minimum_size = Vector2(56, 50)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_script(preload("res://scripts/components/app_glyph.gd"))
	icon.set("glyph", {"inbox": "mail", "roadmap": "road"}.get(id, "dash"))
	box.add_child(icon)

	var name_label := Label.new()
	name_label.text = String(app.get("name", ""))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", UIHelpers.PANEL_FG)
	box.add_child(name_label)

	var status := _app_status(id)
	var status_label := Label.new()
	status_label.text = String(status.get("text", ""))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(150, 0)
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color",
		UIHelpers.PANEL_DANGER if bool(status.get("hot", false)) else UIHelpers.PANEL_MUTED)
	box.add_child(status_label)

	tile.add_child(box)
	tile.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			open_app(id))
	return tile


func _app_status(id: String) -> Dictionary:
	match id:
		"inbox":
			var pending := SprintState.pending_inbox_count() if SprintState.has_method("pending_inbox_count") else 0
			if pending > 0:
				return {"text": "%d message%s en attente" % [pending, "s" if pending > 1 else ""], "hot": true}
			return {"text": "Rien en attente", "hot": false}
		"roadmap":
			var debt := SprintState.get_resource_value("dette-organisationnelle")
			var capacity := SprintState.get_effective_capacity()
			if debt >= 64.0:
				return {"text": "Congestionnée · capacité %d" % capacity, "hot": true}
			return {"text": "Capacité %d ce sprint" % capacity, "hot": false}
		_:
			var vitals := SprintState.get_desk_vitals()
			return {"text": "%d utilisateurs" % int(vitals.get("users", 0)), "hot": false}


func _os_bar(text: String, closable: bool) -> Control:
	var bar := Control.new()
	bar.position = Vector2.ZERO
	bar.size = Vector2(_body.size.x, 34)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = text.to_upper()
	label.position = Vector2(14, 8)
	label.add_theme_color_override("font_color", UIHelpers.PANEL_MUTED)
	UIHelpers.apply_mono(label, 11, true)
	bar.add_child(label)

	if closable:
		var close := Button.new()
		close.text = "◂  RETOUR AU BUREAU"
		close.flat = true
		close.position = Vector2(_body.size.x - 210, 2)
		close.custom_minimum_size = Vector2(200, 30)
		close.add_theme_font_size_override("font_size", 12)
		close.add_theme_color_override("font_color", UIHelpers.PANEL_ACCENT)
		close.pressed.connect(close_app)
		bar.add_child(close)
	return bar


# ── Ouvrir, fermer ───────────────────────────────────────────────────────
func open_app(id: String) -> void:
	if _open_id == id:
		return
	_open_id = id
	UIHelpers.clear_children(_body)
	_apply_rect(OPEN_RECT)

	var title := "Poste de travail"
	for app in apps:
		if String(app.get("id", "")) == id:
			title = String(app.get("name", ""))
	_body.add_child(_os_bar("Poste de travail  ·  %s" % title, true))

	var host := Control.new()
	host.position = Vector2(0, 34)
	host.size = _body.size - Vector2(0, 34)
	host.clip_contents = true
	_body.add_child(host)

	_hosted = _instantiate_app(id, host)
	state_changed.emit()


func close_app() -> void:
	if _hosted != null and is_instance_valid(_hosted):
		_hosted = null
	_open_id = ""
	_show_apps()
	state_changed.emit()


## Les phases existantes sont hébergées **telles quelles**. Deux neutralisations
## suffisent, et elles évitent de rouvrir les neuf écrans dans ce lot :
##  1. `UIHelpers.hosted_in_desk` fait rendre un panneau vide à
##     `attach_side_panel()` — le Panneau de bord n'existe plus ;
##  2. les boutons de navigation sont **débranchés puis recâblés** vers le
##     retour au bureau : aucun `change_scene_to_file` ne doit survivre, il
##     détruirait le hub.
func _instantiate_app(id: String, host: Control) -> Control:
	if id == "dashboard":
		var dossier := UIHelpers.instantiate_company_dossier(host)
		dossier.visible = true
		return dossier

	var path := String(SCENES.get(id, ""))
	if path == "" or not ResourceLoader.exists(path):
		return null

	UIHelpers.hosted_in_desk = true
	var screen: Control = load(path).instantiate()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(screen)
	UIHelpers.hosted_in_desk = false

	# Les libellés du tunnel mentent une fois hébergés : « ← Accueil » ne ramène
	# plus à l'accueil, et « Suivant : Roadmap » n'est plus la suite de rien
	# puisqu'on choisit son ordre. Le lot B refera ces écrans ; en attendant, on
	# ne laisse pas une promesse fausse à l'écran.
	_rewire(screen, "Margin/VBox/TopBar/BackButton", "← Bureau")
	_rewire(screen, "Margin/VBox/BottomBar/NextButton", "Terminé")
	return screen


## Un bouton hébergé garde son libellé et sa place — c'est le lot B qui refera
## la forme des écrans. Seule sa destination change.
func _rewire(screen: Control, path: String, label: String = "") -> void:
	var button: Node = screen.get_node_or_null(NodePath(path))
	if button == null or not (button is BaseButton):
		return
	for connection in button.pressed.get_connections():
		button.pressed.disconnect(connection.get("callable"))
	button.pressed.connect(close_app)
	if label != "":
		button.text = label
