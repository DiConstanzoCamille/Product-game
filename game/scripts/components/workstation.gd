extends Control
## Le poste de travail — les *logiciels* du bureau (#54 §2).
##
## Trois applications seulement s'ouvrent « dans un écran », et c'est parce que
## ce sont vraiment des écrans : la boîte mail, la roadmap, le tableau de bord.
## Tout le reste du jeu est du décor ou un accessoire qui entre dans le cadre.
##
## Depuis #59, ce nœud **vit dans le `SubViewport` de la dalle** du portable en
## volume : il n'a plus à dessiner ni cadre ni coque — la machine est un objet
## de la scène 3D, avec sa tranche et son ombre. Deux conséquences directes :
##
##  · il n'y a plus de « dalle qui s'agrandit » quand on ouvre une application.
##    La taille de l'écran est celle d'un écran, elle ne change pas parce qu'on
##    ouvre un logiciel. Le Lot A avait besoin de ce truc pour gagner de la
##    place ; le cadrage 3D la donne (880×495 contre 762×415) ;
##  · le contenu reste du `Control` net et de face. Il hérite de la perspective
##    de la pièce **par la texture**, pas par une transformation de l'UI.
##
## Aucune phase n'est un `change_scene_to_file` : elles sont instanciées ici et
## configurées par leur contrat `configure_for_host()`. L'hôte ne cherche ni ne
## modifie leurs boutons : le chrome du laptop et la logique métier de l'app
## restent deux responsabilités distinctes.

signal state_changed

const SCREEN_BG := Color("#141a26")
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
var _glow: ColorRect = null

## Piste 3 : combien la dalle brille. 0 = la pièce et l'écran ont la même
## matière ; 1 = contraste franc. C'est un réglage, donc il vit dans
## `balance.json → desk.screen.glowIntensity` et se lit par une fonction de
## résolution — la variable statique n'existe que pour que le harnais de
## captures puisse comparer plusieurs intensités sur la même scène.
static var screen_intensity := -1.0


static func resolved_screen_intensity() -> float:
	if screen_intensity >= 0.0:
		return screen_intensity
	return float(SprintState.get_desk_conf().get("screen", {}).get("glowIntensity", 0.45))


func _ready() -> void:
	# Le poste occupe toute la dalle : c'est le `SubViewport` qui donne la
	# taille, et lui seul. Rien ici ne connaît la géométrie de la pièce.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background := ColorRect.new()
	background.name = "ScreenBackground"
	background.color = SCREEN_BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_body = Control.new()
	_body.name = "Body"
	_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)

	# La couche de dalle se pose APRÈS le contenu : elle relit ce qui a été
	# peint dessous (hint_screen_texture), donc son ordre dans l'arbre compte.
	_glow = ColorRect.new()
	_glow.name = "ScreenGlow"
	_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_material := ShaderMaterial.new()
	glow_material.shader = preload("res://resources/shaders/screen_glow.gdshader")
	glow_material.set_shader_parameter("intensity", resolved_screen_intensity())
	_glow.material = glow_material
	add_child(_glow)

	_show_apps.call_deferred()


func is_open() -> bool:
	return _open_id != ""


# ── Le bureau du poste : trois tuiles ────────────────────────────────────
func _show_apps() -> void:
	UIHelpers.clear_children(_body)
	move_child(_glow, get_child_count() - 1)
	_body.add_child(_os_bar("POSTE DE TRAVAIL", false))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.position = Vector2(0, 62)
	row.size = Vector2(_body.size.x, _body.size.y - 74)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_body.add_child(row)

	for app in apps:
		row.add_child(_app_tile(app))
	# Un HBoxContainer positionne ses enfants au tri suivant : mémoriser la
	# position de repos avant serait mémoriser zéro (piège conteneur connu).
	row.sort_children.connect(func():
		for tile in row.get_children():
			if not tile.has_meta("rest_y"):
				tile.set_meta("rest_y", tile.position.y), CONNECT_ONE_SHOT)


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
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	tile.add_theme_stylebox_override("panel", style)
	tile.custom_minimum_size = Vector2(156, 0)
	tile.mouse_filter = Control.MOUSE_FILTER_STOP

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon := Control.new()
	icon.custom_minimum_size = Vector2(56, 44)
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
	status_label.custom_minimum_size = Vector2(128, 0)
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color",
		UIHelpers.PANEL_DANGER if bool(status.get("hot", false)) else UIHelpers.PANEL_MUTED)
	box.add_child(status_label)

	tile.add_child(box)
	# Le survol soulève la tuile et l'éclaire. C'est la différence de sensation
	# entre « un bouton » et « un objet qu'on prend » — et ça ne se voit sur
	# aucune capture, seulement en jouant.
	tile.pivot_offset = Vector2(78, 70)
	tile.mouse_entered.connect(func(): _lift(tile, -6.0, 1.035))
	tile.mouse_exited.connect(func(): _lift(tile, 0.0, 1.0))
	tile.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			open_app(id))
	return tile


## Un ressort court, jamais un fondu : `TRANS_BACK` dépasse légèrement la cible
## puis revient, et c'est ce dépassement qu'on lit comme de la matière.
func _lift(node: Control, offset: float, scale_to: float) -> void:
	var tween := node.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", node.get_meta("rest_y", node.position.y) + offset, 0.18)
	tween.tween_property(node, "scale", Vector2.ONE * scale_to, 0.18)


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


func hosted_app() -> Control:
	return _hosted


func close_app() -> void:
	if _hosted != null and is_instance_valid(_hosted):
		_hosted = null
	_open_id = ""
	_show_apps()
	state_changed.emit()


## Les phases gardent leur logique métier lorsqu'elles sont hébergées. Elles
## exposent des signaux de fin et de mutation au bureau : débrancher leurs
## boutons détruirait notamment la validation de la Roadmap et la lecture du
## courrier.
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

	if screen.has_method("configure_for_host"):
		screen.call("configure_for_host", {"kind": "workstation", "size": host.size})
	if screen.has_signal("desk_done"):
		screen.connect("desk_done", close_app)
	if screen.has_signal("desk_state_changed"):
		screen.connect("desk_state_changed", _on_hosted_state_changed)
	return screen

func _on_hosted_state_changed() -> void:
	state_changed.emit()
