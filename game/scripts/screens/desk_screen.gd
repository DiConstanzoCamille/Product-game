extends Node2D
## Le bureau — le hub qui remplace le tunnel d'écrans (issue #54, Lot A).
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
##    « ouvre » pas.
##
## Pourquoi un `Node2D` et pas un arbre de conteneurs : la cible artistique est
## une vraie scène (perspective, matière). Poser des placeholders à des
## positions explicites coûte zéro aujourd'hui ; convertir plus tard une mise en
## page de `HBoxContainer` en scène, c'est une réécriture. Même raison pour les
## accessoires : ce sont des nœuds de la scène qui s'animent par `Tween`, pas
## des `Popup` — un popup Godot ne sait pas glisser depuis le bord.

const DESIGN := Vector2(1600, 900)
const WALL_RATIO := 0.52          ## hauteur du mur ; sous cette ligne, le plateau

const WALL_BG := Color("#eceee9")
const WOOD_TOP := Color("#c9b59b")
const WOOD_BOTTOM := Color("#a58d73")
const ZONE_BG := Color(1, 1, 1, 0.9)
const ZONE_BORDER := Color("#cfd5d2")
const PAPER := Color("#ffffff")
const PAPER_WARM := Color("#fffdf3")
const DESK_LABEL := Color("#584732")

## Les trois applications du poste de travail. L'ordre est celui du sprint,
## mais rien ne l'impose : on ouvre ce qu'on veut, quand on veut.
const APPS := [
	{"id": "inbox", "name": "Boîte mail", "icon": "mail"},
	{"id": "roadmap", "name": "Roadmap", "icon": "road"},
	{"id": "dashboard", "name": "Tableau de bord", "icon": "dash"},
]

var _vitals: Control = null
var _alerts: Control = null
var _wall: Control = null
var _workstation: Control = null
var _props: Dictionary = {}       ## id → { node, rest_x, in_x }


func _ready() -> void:
	_build_room()
	_build_vitals()
	_build_wall()
	_build_plateau()
	_build_workstation()
	_build_props()
	refresh()


## Un seul point de reconstruction : tout écran hôte ou accessoire qui modifie
## l'état rappelle `refresh()`. Aucune valeur n'est mise en cache ici — le
## bureau est une vue sur `SprintState`, jamais un second état.
func refresh() -> void:
	_refresh_vitals()
	_refresh_alerts()
	_refresh_wall()
	_refresh_props()


# ── La pièce ─────────────────────────────────────────────────────────────
func _build_room() -> void:
	var wall := ColorRect.new()
	wall.color = WALL_BG
	wall.position = Vector2.ZERO
	wall.size = Vector2(DESIGN.x, DESIGN.y * WALL_RATIO)
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wall)

	# Le plateau est un dégradé : c'est ce qui donne la profondeur sans
	# perspective, et c'est ce qu'un habillage ultérieur remplacera par une
	# vraie texture sans toucher au reste.
	var desk := TextureRect.new()
	desk.texture = _vertical_gradient(WOOD_TOP, WOOD_BOTTOM)
	desk.position = Vector2(0, DESIGN.y * WALL_RATIO)
	desk.size = Vector2(DESIGN.x, DESIGN.y * (1.0 - WALL_RATIO))
	desk.stretch_mode = TextureRect.STRETCH_SCALE
	desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(desk)

	var edge := ColorRect.new()
	edge.color = Color("#8d7358")
	edge.position = Vector2(0, DESIGN.y * WALL_RATIO)
	edge.size = Vector2(DESIGN.x, 3)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(edge)


func _vertical_gradient(top: Color, bottom: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, top)
	gradient.set_color(1, bottom)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	return texture


# ── Les zones : posées, jamais un bandeau ────────────────────────────────
## Aucun élément ne prend la largeur ni la hauteur entière : une barre pleine
## fait interface web sur une scène de jeu, et c'est le défaut qu'on corrige.
func _build_vitals() -> void:
	_vitals = _zone(Vector2(34, 26), Vector2(0, 0))
	add_child(_vitals)

	var sprint := _zone(Vector2(0, 26), Vector2(0, 0))
	sprint.name = "SprintChip"
	add_child(sprint)

	_alerts = Control.new()
	_alerts.name = "Alerts"
	_alerts.position = Vector2(34, 98)
	_alerts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_alerts)


func _zone(at: Vector2, minimum: Vector2) -> PanelContainer:
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
	zone.custom_minimum_size = minimum
	return zone


func _refresh_vitals() -> void:
	UIHelpers.clear_children(_vitals)
	var vitals := SprintState.get_desk_vitals()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)

	# 💥 L'Impact est une **progression**, pas un nombre nu : le quota est
	# présent par la forme, sans être un deuxième chiffre à surveiller.
	var impact := HBoxContainer.new()
	impact.add_theme_constant_override("separation", 9)
	impact.tooltip_text = "💥 Impact — solde du portefeuille.\nLe board compare ce solde au quota du trimestre : %d / %d." % [
		vitals.get("impact", 0), vitals.get("quota", 0)]
	impact.add_child(_value_label("💥 %d" % int(vitals.get("impact", 0))))
	impact.add_child(_progress_bar(float(vitals.get("quotaRatio", 0.0))))
	row.add_child(impact)

	row.add_child(_separator())

	var cash := _value_label("💰 %s" % _short_money(int(vitals.get("revenue", 0))))
	cash.tooltip_text = "💰 Trésorerie — ce qui paie les salaires, les licences et le support.\nCharges du sprint : %d." % int(SprintState.get_recurring_charges().get("total", 0))
	cash.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(cash)

	row.add_child(_separator())

	var users := _value_label("👥 %s" % _short_count(int(vitals.get("users", 0))))
	users.tooltip_text = "👥 Utilisateurs — la population qui paie chaque sprint.\nElle grandit par les livraisons, elle s'érode au churn."
	users.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(users)

	_vitals.add_child(row)

	var chip: PanelContainer = get_node("SprintChip")
	UIHelpers.clear_children(chip)
	var sprint_label := Label.new()
	sprint_label.text = "SPRINT %d · T%d" % [SprintState.sprint_number, SprintState.quarter_index]
	sprint_label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	UIHelpers.apply_mono(sprint_label, 12, true)
	chip.add_child(sprint_label)
	# La pastille est ancrée à droite : sa largeur dépend du texte, donc on la
	# repositionne une fois le conteneur dimensionné.
	chip.reset_size()
	chip.position.x = DESIGN.x - chip.size.x - 34


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


# ── Le mur : le papier ───────────────────────────────────────────────────
func _build_wall() -> void:
	_wall = Control.new()
	_wall.name = "Wall"
	_wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wall)


func _refresh_wall() -> void:
	UIHelpers.clear_children(_wall)
	_wall.add_child(_team_pin())
	_wall.add_child(_journal_pin())
	_wall.add_child(_goal_pin())


## 🫶 Le Moral ne s'affiche nulle part en chiffre. Il se lit sur les visages —
## c'est `get_employee_alert()` de #43, rendu visible : l'état synthétique par
## défaut, le détail seulement au survol.
func _team_pin() -> Control:
	var pin := _paper(Vector2(38, 166), 286, PAPER, -0.8)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(_pin_title("Équipe · %d" % SprintState.get_roster().size()))

	for employee in SprintState.get_roster():
		var alert := SprintState.get_employee_alert(employee)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var wellbeing := SprintState.employee_wellbeing(employee)
		row.add_child(_face(int(wellbeing.get("moral", 100)), bool(alert.get("active", false))))

		var name_label := Label.new()
		name_label.text = String(employee.get("name", "—"))
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(name_label)

		var role := Label.new()
		role.text = String(employee.get("role", "")).to_upper()
		role.add_theme_font_size_override("font_size", 10)
		role.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
		role.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(role)

		if bool(alert.get("active", false)):
			var flag := Label.new()
			flag.text = String(alert.get("label", ""))
			flag.add_theme_font_size_override("font_size", 11)
			flag.add_theme_color_override("font_color", UIHelpers.COLOR_DANGER)
			flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(flag)

		row.tooltip_text = _employee_tooltip(employee, wellbeing)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		box.add_child(row)

	pin.add_child(box)
	return pin


func _employee_tooltip(employee: Dictionary, wellbeing: Dictionary) -> String:
	var lines := ["%s — %s %s" % [employee.get("name", ""), employee.get("seniority", ""), employee.get("role", "")]]
	for criterion in SprintState.get_individual_team_conf().get("criteria", []):
		lines.append("%s : %d" % [String(criterion).capitalize(), int(wellbeing.get(criterion, 0))])
	return "\n".join(lines)


## Un visage dessiné plutôt qu'un emoji : sans police à emoji couleur, 🙂 et 😖
## rendent deux cercles au trait quasi identiques — or c'est exactement la
## nuance que ce composant doit porter.
func _face(moral: int, alerting: bool) -> Control:
	var face := Control.new()
	face.custom_minimum_size = Vector2(30, 30)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.set_script(preload("res://scripts/components/mood_face.gd"))
	face.set("moral", moral)
	face.set("alerting", alerting)
	return face


func _journal_pin() -> Control:
	var pin := _paper(Vector2(352, 172), 206, PAPER_WARM, 1.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var journal := SprintState.get_last_journal()
	box.add_child(_pin_title("Le journal" if journal.is_empty()
		else "Sprint %d — le journal" % (SprintState.sprint_number - 1)))

	if journal.is_empty():
		var empty := Label.new()
		empty.text = "Rien encore : aucun sprint n'est clos."
		empty.add_theme_font_size_override("font_size", 11)
		empty.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(180, 0)
		box.add_child(empty)
	else:
		for line in journal:
			box.add_child(_journal_line(line))

	pin.add_child(box)
	return pin


func _journal_line(line: Dictionary) -> Control:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = String(line.get("label", ""))
	label.add_theme_font_size_override("font_size", 12)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var amount := int(line.get("amount", 0))
	var value := Label.new()
	value.text = "%+d" % amount
	value.add_theme_font_size_override("font_size", 12)
	value.add_theme_color_override("font_color", UIHelpers.COLOR_GOOD if amount >= 0 else UIHelpers.COLOR_DANGER)
	UIHelpers.apply_mono(value, 12, true)
	row.add_child(value)
	return row


## 🎯 Le Capital politique n'a pas de barre : c'est le ton de cette feuille qui
## dit ce que le board pense de vous.
func _goal_pin() -> Control:
	var pin := _paper(Vector2(0, 110), 198, PAPER, 0.9)
	pin.name = "GoalPin"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_pin_title("Objectif · T%d" % SprintState.quarter_index))

	var progress := SprintState.get_quarter_progress()
	var value := Label.new()
	value.text = "%d / %d" % [int(progress.get("impact", 0)), int(progress.get("quota", 0))]
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIHelpers.apply_mono(value, 22, true)
	box.add_child(value)

	var remaining := int(progress.get("length", 0)) - int(progress.get("sprint", 0)) - 1
	var sub := Label.new()
	sub.text = "%d sprint%s restant%s" % [remaining, "s" if remaining > 1 else "", "s" if remaining > 1 else ""]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	box.add_child(sub)

	var capital := SprintState.get_resource_value("capital-politique")
	var mood := Label.new()
	mood.text = _board_mood(capital)
	mood.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mood.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mood.custom_minimum_size = Vector2(170, 0)
	mood.add_theme_font_size_override("font_size", 11)
	mood.add_theme_color_override("font_color", UIHelpers.COLOR_FLAVOR)
	box.add_child(mood)

	pin.add_child(box)
	pin.position.x = DESIGN.x - 198 - 44
	return pin


func _board_mood(capital: float) -> String:
	if capital >= 66.0:
		return "« On vous suit. »"
	if capital >= 34.0:
		return "« On regarde. »"
	return "« On compte les jours. »"


func _paper(at: Vector2, width: float, color: Color, tilt_degrees: float) -> PanelContainer:
	var pin := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = UIHelpers.COLOR_INK
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.12)
	style.shadow_size = 4
	style.shadow_offset = Vector2(3, 4)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	pin.add_theme_stylebox_override("panel", style)
	pin.position = at
	pin.custom_minimum_size = Vector2(width, 0)
	# `rotation` d'un Control n'est écrasée que par un conteneur parent : ici
	# le mur est un `Control` nu, donc l'inclinaison tient (piège Godot connu).
	pin.pivot_offset = Vector2(width * 0.5, 60)
	pin.rotation = deg_to_rad(tilt_degrees)
	pin.mouse_filter = Control.MOUSE_FILTER_STOP
	return pin


func _pin_title(text: String) -> Label:
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	UIHelpers.apply_mono(label, 10, true)
	return label


# ── Le plateau : seulement ce qui est vraiment un objet ──────────────────
func _build_plateau() -> void:
	var mug := Control.new()
	mug.name = "Mug"
	mug.position = Vector2(224, 592)
	mug.custom_minimum_size = Vector2(118, 98)
	mug.size = Vector2(118, 98)
	mug.set_script(preload("res://scripts/components/coffee_mug.gd"))
	add_child(mug)

	var caption := Label.new()
	caption.text = "ÉNERGIE"
	caption.position = Vector2(236, 700)
	caption.add_theme_font_size_override("font_size", 11)
	caption.add_theme_color_override("font_color", DESK_LABEL)
	UIHelpers.apply_mono(caption, 11, true)
	add_child(caption)


func _build_workstation() -> void:
	_workstation = Control.new()
	_workstation.name = "Workstation"
	_workstation.set_script(preload("res://scripts/components/workstation.gd"))
	_workstation.set("apps", APPS)
	add_child(_workstation)
	if _workstation.has_signal("state_changed"):
		_workstation.connect("state_changed", Callable(self, "refresh"))


# ── Les objets qui entrent dans le cadre ─────────────────────────────────
## Chaque mécanique a son accessoire, et la forme dit ce qu'elle est : la
## tablette se feuillette et se repousse (elle est là en permanence), la
## planche se signe une fois (c'est le point de non-retour), le parapheur n'est
## déposé qu'un sprint sur trois.
func _build_props() -> void:
	_props = {}
	for kind in ["shop", "closing", "committee"]:
		var prop := Control.new()
		prop.name = kind
		prop.set_script(preload("res://scripts/components/desk_prop.gd"))
		prop.set("kind", kind)
		add_child(prop)
		_props[kind] = prop
		prop.connect("state_changed", Callable(self, "refresh"))


func _refresh_props() -> void:
	for id in _props:
		var prop: Control = _props[id]
		if prop.has_method("refresh"):
			prop.refresh()


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
