extends Node3D
## Un papier punaisé au mur, en volume (#59 ; `docs/spec-bureau-3d.md` §3).
##
## Trois niveaux de lecture, et ils reprennent le motif déjà livré par #43
## plutôt que d'en inventer un :
##
## | Geste | Ce qu'on voit | Dimension |
## |---|---|---|
## | **Rien** | Le papier, et l'état synthétique dessus | 3D |
## | **Survol** | Une info-bulle : le nom, la ligne qui résume | **2D**, de face |
## | **Clic** | Le poster **se lève**, le détail apparaît dessous | 2D sous un geste 3D |
##
## La feuille a une épaisseur : elle se décolle du mur par son ombre propre, pas
## par une ombre dessinée. Mais **la face qui porte le texte est `UNSHADED`** —
## un papier au fond d'une pièce prend la teinte de son éclairage, et un demi-ton
## de gris sur du corps 11 est exactement la façon dont on rate le critère de
## recette n°1 sans qu'aucun test ne bronche. L'épaisseur derrière reçoit la
## lumière, la face qu'on lit non : chacun son travail.
##
## La levée pivote sur le **bord haut**, comme une page de paperboard qu'on
## rabat vers soi. Elle ne coûte ni Énergie ni sprint : c'est de l'information
## qu'on détient déjà (règle de consultation du Lot A).

signal hover_changed(paper: Node3D, entered: bool)
signal clicked(paper: Node3D)
signal state_changed
## Demande d'ouvrir le hub d'équipe complet. Le poster levé porte les actions
## fréquentes ; celles qui demandent une confirmation — se séparer de
## quelqu'un — ont besoin d'un modal, ce que la levée refuse d'être.
signal open_team_hub

const TeamActions := preload("res://scripts/components/team_management_dialog.gd")

const PAPER := Color("#fdfcf8")
const PAPER_WARM := Color("#fffdf3")
const THICKNESS := 0.008
const LIFT_SECONDS := 0.34
## Assez pour lire « la feuille est levée », pas assez pour qu'elle devienne
## une tranche grise vue par le champ. Au-delà de ~60°, le poster ne raconte
## plus un geste, il fait un trou dans le mur.
const LIFT_DEGREES := -58.0

## La taille est déclarée **en pixels** : la taille monde s'en déduit à la
## profondeur du mur (`DeskRoom.design_pixels_per_unit_at`), donc le rendu est
## à l'échelle 1:1 quoi qu'on fasse de la caméra. L'inverse — un quad de taille
## fixe rempli par un viewport de taille fixe — donne un texte redimensionné
## dès que la caméra bouge d'un centimètre.
const KINDS := {
	"team": {"pixels": Vector2i(356, 292), "color": PAPER, "tilt": -0.9},
	"journal": {"pixels": Vector2i(300, 208), "color": PAPER_WARM, "tilt": 1.1},
	"goal": {"pixels": Vector2i(292, 248), "color": PAPER, "tilt": 0.7},
}

@export var kind: String = "team"

var room: Node3D = null

var _sheet: Node3D = null
var _viewport: SubViewport = null
var _content: Control = null
var _lifted := false
var _tween: Tween = null
var _pixels := Vector2i.ZERO


func _ready() -> void:
	build.call_deferred()


func build() -> void:
	if _sheet != null:
		return
	var shape_conf: Dictionary = KINDS.get(kind, KINDS["team"])
	_pixels = shape_conf.get("pixels", Vector2i(320, 240))
	var world := Vector2(_pixels) / _pixels_per_unit()
	var color: Color = shape_conf.get("color", PAPER)

	# Le pivot est le bord HAUT de la feuille : la levée doit se lire comme une
	# page qu'on soulève, pas comme un panneau qui recule.
	_sheet = Node3D.new()
	_sheet.name = "Sheet"
	_sheet.position = Vector3(0, world.y * 0.5, 0)
	_sheet.rotation_degrees = Vector3(0, 0, float(shape_conf.get("tilt", 0.0)))
	add_child(_sheet)

	var back := MeshInstance3D.new()
	back.name = "Back"
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(world.x, world.y, THICKNESS)
	back.mesh = back_mesh
	back.position = Vector3(0, -world.y * 0.5, -THICKNESS * 0.5)
	var back_material := StandardMaterial3D.new()
	back_material.albedo_color = color.darkened(0.06)
	back_material.roughness = 0.94
	back.material_override = back_material
	_sheet.add_child(back)

	_viewport = SubViewport.new()
	_viewport.name = "PaperViewport"
	_viewport.size = _pixels
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sheet.add_child(_viewport)

	var face := MeshInstance3D.new()
	face.name = "Face"
	var quad := QuadMesh.new()
	quad.size = world
	face.mesh = quad
	face.position = Vector3(0, -world.y * 0.5, 0.0008)
	var face_material := StandardMaterial3D.new()
	face_material.albedo_texture = _viewport.get_texture()
	face_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	face.material_override = face_material
	_sheet.add_child(face)

	var area := Area3D.new()
	area.name = "Area"
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(world.x, world.y, 0.03)
	collision.shape = box
	collision.position = Vector3(0, -world.y * 0.5, 0)
	area.add_child(collision)
	# Un objet 3D n'a ni survol ni clic gratuits : les deux se branchent ici,
	# et c'est toute la différence de nature avec `gui_input`.
	area.mouse_entered.connect(func(): hover_changed.emit(self, true))
	area.mouse_exited.connect(func(): hover_changed.emit(self, false))
	area.input_event.connect(_on_area_input)
	_sheet.add_child(area)

	refresh()


func _pixels_per_unit() -> float:
	if room != null and room.has_method("design_pixels_per_unit_at"):
		return maxf(room.design_pixels_per_unit_at(global_position), 1.0)
	return 400.0


func _on_area_input(_camera: Node, event: InputEvent, _at: Vector3, _normal: Vector3, _index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)


# ── L'état synthétique, peint sur le papier ──────────────────────────────
func refresh() -> void:
	if _viewport == null:
		return
	if _content != null:
		UIHelpers.clear_children(_viewport)
	_content = _build_face()
	_viewport.add_child(_content)


func _build_face() -> Control:
	var root := ColorRect.new()
	root.color = Color(KINDS.get(kind, KINDS["team"]).get("color", PAPER))
	root.size = Vector2(_pixels)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin := MarginContainer.new()
	margin.size = Vector2(_pixels)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	root.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)

	match kind:
		"team":
			_fill_team(box)
		"journal":
			_fill_journal(box)
		_:
			_fill_goal(box)
	return root


## 🫶 Le Moral ne s'affiche nulle part en chiffre. Il se lit sur les visages —
## c'est `get_employee_alert()` de #43, rendu visible : l'état synthétique par
## défaut, le détail seulement une fois le poster levé.
func _fill_team(box: VBoxContainer) -> void:
	box.add_child(_title("Équipe · %d" % SprintState.get_roster().size()))
	for employee in SprintState.get_roster():
		var alert := SprintState.get_employee_alert(employee)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var wellbeing := SprintState.employee_wellbeing(employee)
		row.add_child(_face_icon(int(wellbeing.get("moral", 100)), bool(alert.get("active", false))))

		var name_label := Label.new()
		name_label.text = String(employee.get("name", "—"))
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Un nom long poussait la colonne de rôle hors de la feuille : « OPS »
		# devenait « OP », « DESIGNER » devenait « DESI ». C'est le nom qui doit
		# céder, pas le rôle — le rôle est l'information rare.
		name_label.clip_text = true
		name_label.custom_minimum_size = Vector2(70, 0)
		row.add_child(name_label)

		if bool(alert.get("active", false)):
			var flag := Label.new()
			flag.text = String(alert.get("label", ""))
			flag.add_theme_font_size_override("font_size", 10)
			flag.add_theme_color_override("font_color", UIHelpers.COLOR_DANGER)
			flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(flag)
		else:
			var role := Label.new()
			role.text = String(employee.get("role", "")).to_upper()
			role.add_theme_font_size_override("font_size", 9)
			role.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
			role.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(role)
		box.add_child(row)


func _fill_journal(box: VBoxContainer) -> void:
	var journal := SprintState.get_last_journal()
	box.add_child(_title("Le journal" if journal.is_empty()
		else "Sprint %d — le journal" % (SprintState.sprint_number - 1)))

	if journal.is_empty():
		var empty := Label.new()
		empty.text = "Rien encore : aucun sprint n'est clos."
		empty.add_theme_font_size_override("font_size", 11)
		empty.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(empty)
		return

	for line in journal:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = String(line.get("label", ""))
		label.add_theme_font_size_override("font_size", 12)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var amount := int(line.get("amount", 0))
		var value := Label.new()
		value.text = "%+d" % amount
		value.add_theme_color_override("font_color",
			UIHelpers.COLOR_GOOD if amount >= 0 else UIHelpers.COLOR_DANGER)
		UIHelpers.apply_mono(value, 12, true)
		row.add_child(value)
		box.add_child(row)


## 🎯 Le Capital politique n'a pas de barre : c'est le ton de cette feuille qui
## dit ce que le board pense de vous.
func _fill_goal(box: VBoxContainer) -> void:
	box.add_child(_title("Objectif · T%d" % SprintState.quarter_index))

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

	var mood := Label.new()
	mood.text = board_mood()
	mood.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mood.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mood.add_theme_font_size_override("font_size", 11)
	mood.add_theme_color_override("font_color", UIHelpers.COLOR_FLAVOR)
	box.add_child(mood)


func board_mood() -> String:
	var capital := SprintState.get_resource_value("capital-politique")
	if capital >= 66.0:
		return "« On vous suit. »"
	if capital >= 34.0:
		return "« On regarde. »"
	return "« On compte les jours. »"


# ── Le survol : deux lignes, en 2D, de face ──────────────────────────────
func hover_summary() -> Dictionary:
	match kind:
		"team":
			var alerting := 0
			for employee in SprintState.get_roster():
				if bool(SprintState.get_employee_alert(employee).get("active", false)):
					alerting += 1
			return {
				"title": "Trombinoscope",
				"line": "Personne ne va mal en ce moment." if alerting == 0
					else "%d personne%s à voir de près." % [alerting, "s" if alerting > 1 else ""],
			}
		"journal":
			var journal := SprintState.get_last_journal()
			return {
				"title": "Le journal",
				"line": "Aucun sprint clos pour l'instant." if journal.is_empty()
					else "Ce que le sprint %d a laissé." % (SprintState.sprint_number - 1),
			}
	var progress := SprintState.get_quarter_progress()
	return {
		"title": "Objectif du trimestre",
		"line": "%d / %d 💥 — %s" % [
			int(progress.get("impact", 0)), int(progress.get("quota", 0)), board_mood()],
	}


# ── La levée ─────────────────────────────────────────────────────────────
func is_lifted() -> bool:
	return _lifted


func set_lifted(value: bool) -> void:
	if _lifted == value or _sheet == null:
		return
	_lifted = value
	if _tween != null and _tween.is_valid():
		_tween.kill()
	# Une feuille levée qui projette encore son ombre sur le mur pose un grand
	# trapèze gris derrière le détail qu'on essaie de lire. L'ombre sert à
	# décoller le papier au repos ; levé, il est déjà décollé.
	var casting := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if value \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for part in ["Back", "Face"]:
		(_sheet.get_node(part) as GeometryInstance3D).cast_shadow = casting

	_tween = create_tween().set_parallel(true)
	# Le dépassement puis le retour, c'est ce qu'on lit comme du papier : une
	# feuille qu'on rabat a de l'inertie, un panneau qui s'affiche n'en a pas.
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_sheet, "rotation_degrees:x", LIFT_DEGREES if value else 0.0, LIFT_SECONDS)
	_tween.tween_property(_sheet, "position:z", 0.09 if value else 0.0, LIFT_SECONDS)


# ── Le détail, à plat et en 2D, sous le poster levé ──────────────────────
## On lit des chiffres, pas une perspective : ce panneau vit dans le
## `CanvasLayer` du bureau, jamais dans le monde.
func build_detail() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	match kind:
		"team":
			_detail_team(box)
		"journal":
			_detail_journal(box)
		_:
			_detail_goal(box)
	return box


func _detail_team(box: VBoxContainer) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	var title := _detail_title("L'équipe, de près")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	# L'entrée du hub d'équipe vivait dans le Panneau de bord permanent,
	# supprimé par #59. Elle est ici parce que c'est ici qu'on regarde ses
	# gens : le poster porte le quotidien, le hub porte l'irréversible.
	var hub := Button.new()
	hub.name = "OpenTeamManagement"
	hub.text = "Fiche complète"
	hub.add_theme_font_size_override("font_size", 11)
	hub.pressed.connect(func(): open_team_hub.emit())
	head.add_child(hub)
	box.add_child(head)

	var criteria: Array = SprintState.get_individual_team_conf().get("criteria", [])
	for employee in SprintState.get_roster():
		box.add_child(_person_card(employee, criteria))


func _person_card(employee: Dictionary, criteria: Array) -> Control:
	var card := PanelContainer.new()
	card.name = "PersonCard_%s" % String(employee.get("id", ""))
	card.add_theme_stylebox_override("panel", _card_style())

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	card.add_child(rows)

	var wellbeing := SprintState.employee_wellbeing(employee)
	var alert := SprintState.get_employee_alert(employee)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(_face_icon(int(wellbeing.get("moral", 100)), bool(alert.get("active", false))))
	var name_label := Label.new()
	name_label.text = "%s — %s %s" % [
		employee.get("name", ""), employee.get("seniority", ""), employee.get("role", "")]
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(name_label)
	if bool(alert.get("active", false)):
		var flag := Label.new()
		flag.text = String(alert.get("label", ""))
		flag.add_theme_font_size_override("font_size", 12)
		flag.add_theme_color_override("font_color", UIHelpers.COLOR_DANGER)
		flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(flag)
	rows.add_child(head)

	# Les quatre critères, en clair : c'est ce que la levée du poster va
	# chercher, et c'est ce que le survol se refuse à montrer.
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	for criterion in criteria:
		var id := String(criterion)
		var value := int(wellbeing.get(id, 0))
		var cell := Label.new()
		cell.text = "%s %d" % [id.capitalize(), value]
		cell.add_theme_font_size_override("font_size", 12)
		cell.add_theme_color_override("font_color",
			UIHelpers.COLOR_DANGER if value < 35 else (
				UIHelpers.COLOR_WARN if value < 60 else UIHelpers.COLOR_SOFT_TEXT))
		UIHelpers.apply_mono(cell, 12, true)
		grid.add_child(cell)
	rows.add_child(grid)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	var employee_id := String(employee.get("id", ""))
	for action in TeamActions.management_actions(employee):
		if String(action["id"]) == "fire":
			# Se séparer de quelqu'un demande une confirmation, donc un dialogue
			# modal — exactement ce que la levée du poster refuse d'être. Cette
			# action reste dans le hub d'équipe, et seulement là.
			continue
		actions.add_child(_action_button(String(action["label"]), String(action["refusal"]),
			String(action["id"]), employee_id, String(action["node"])))
	rows.add_child(actions)
	return card


func _action_button(label: String, refusal: String, action_id: String, employee_id: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.disabled = refusal != ""
	button.add_theme_font_size_override("font_size", 11)
	button.tooltip_text = TeamActions.refusal_label(refusal) if refusal != "" else label
	button.pressed.connect(func():
		if TeamActions.run_management_action(action_id, employee_id):
			state_changed.emit())
	return button


func _detail_journal(box: VBoxContainer) -> void:
	box.add_child(_detail_title("Ce que les derniers sprints ont laissé"))
	var entries: Array = SprintState.journal
	if entries.is_empty():
		box.add_child(_detail_line("Aucun sprint n'est encore clos.", UIHelpers.COLOR_SOFT_TEXT))
		return
	var recent: Array = entries.slice(maxi(0, entries.size() - 6), entries.size())
	recent.reverse()
	for entry in recent:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _card_style())
		var rows := VBoxContainer.new()
		rows.add_theme_constant_override("separation", 3)
		card.add_child(rows)
		var head := Label.new()
		head.text = "SPRINT %d" % int(entry.get("sprint", 0))
		head.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
		UIHelpers.apply_mono(head, 10, true)
		rows.add_child(head)
		rows.add_child(_detail_line(String(entry.get("text", "")), UIHelpers.COLOR_INK))
		var deltas := String(entry.get("deltas", ""))
		if deltas != "":
			rows.add_child(_detail_line(deltas, UIHelpers.COLOR_FLAVOR))
		box.add_child(card)


## Le mandat entier, et la chaîne de Levier réellement jouée. Les deux
## vivaient dans le Panneau de bord permanent, supprimé par #59 : ce n'est pas
## de l'information à perdre, c'est de l'information à ranger là où on la
## cherche. On la consulte quand on lève l'objectif, pas en permanence.
func _detail_goal(box: VBoxContainer) -> void:
	box.add_child(_detail_title("Le mandat, et ce qu'il faudra rendre"))

	var progress := SprintState.get_quarter_progress()
	var ahead := int(progress.get("impact", 0)) - int(progress.get("quota", 0))
	box.add_child(_detail_line("T%d · sprint %d/%d · portefeuille %d / %d 💥%s" % [
		int(progress.get("quarter", SprintState.quarter_index)),
		int(progress.get("sprint", 0)) + 1, int(progress.get("length", 3)),
		int(progress.get("impact", 0)), int(progress.get("quota", 0)),
		" · %d d'avance" % ahead if ahead > 0 else "",
	], UIHelpers.COLOR_INK))

	var parts: Array = []
	for entry in SprintState.get_mandate_quotas():
		# Le trimestre en cours porte la barre RÉELLE (exigence comprise), les
		# autres leur barème : afficher le barème pour le trimestre courant
		# donnerait deux nombres pour la même échéance.
		if bool(entry.get("current", false)):
			parts.append("▸ T%d %d" % [int(entry.get("quarter", 0)), SprintState.get_current_quota()])
		elif bool(entry.get("reached", false)):
			parts.append("✓ T%d %d" % [int(entry.get("quarter", 0)), int(entry.get("quota", 0))])
		else:
			parts.append("T%d %d" % [int(entry.get("quarter", 0)), int(entry.get("quota", 0))])
	var mandate := _detail_line("Mandat : %s" % " · ".join(parts), UIHelpers.COLOR_SOFT_TEXT)
	mandate.name = "MandateLine"
	box.add_child(mandate)

	for requirement in SprintState.get_active_quarter_requirements():
		box.add_child(_detail_line("%s %s — %s" % [
			requirement.get("icon", "!"), requirement.get("name", "Exigence"),
			requirement.get("description", "")], UIHelpers.COLOR_WARN))

	var objectives := SprintState.evaluate_board_objectives()
	if not objectives.is_empty():
		box.add_child(_detail_line("Objectifs qualitatifs — bonus +%d 💥" % int(
			GameData.quotas.get("qualitativeBonusImpact", 0)), UIHelpers.COLOR_FLAVOR))
		for objective in objectives:
			var ok := bool(objective.get("ok", false))
			box.add_child(_detail_line("%s %s" % ["✓" if ok else "○", objective.get("label", "")],
				UIHelpers.COLOR_GOOD if ok else UIHelpers.COLOR_SOFT_TEXT))

	box.add_child(_lever_chain())


## La chaîne du Levier telle qu'elle a été **jouée** au dernier sprint. Jamais
## celle du prochain : le jeu montre ce qu'un choix a rapporté, pas ce qu'il va
## rapporter (garde-fou de vision n°4).
func _lever_chain() -> Control:
	var report: Dictionary = SprintState.last_score_report
	if report.is_empty():
		var waiting := _detail_line("⚙️ Levier — révélé après le premier sprint.", UIHelpers.COLOR_SOFT_TEXT)
		waiting.name = "LeverChain"
		return waiting

	var factors: Array = []
	# À N>1 les Leviers locaux sont agrégés par moyenne pondérée dans le
	# resolver : multiplier leurs facteurs entre eux mentirait. On ne prend le
	# détail local que quand il n'y a qu'une équipe.
	if report.get("squads", []).size() == 1:
		for squad_report in report.get("squads", []):
			for line in squad_report.get("lines", []):
				if line.get("type", "") == "lever_multiplier":
					factors.append(line)
	for line in report.get("global", {}).get("lines", []):
		if line.get("type", "") == "lever_multiplier":
			factors.append(line)

	var total := 1.0
	var labels: Array = []
	for line in factors:
		var factor := float(line.get("value", 1.0))
		total *= factor
		labels.append("×%.2f %s" % [factor, line.get("icon", "")])
	var uncapped := float(report.get("global", {}).get("uncapped_effective_lever", 0.0))
	var base := uncapped / total if not is_zero_approx(total) else uncapped
	var text := "⚙️ Levier  %.2f" % base
	if not labels.is_empty():
		text += "  %s" % "  ".join(labels)
	text += "  →  %.2f" % float(report.get("global", {}).get("effective_lever", 0.0))

	var chain := _detail_line(text, UIHelpers.COLOR_FLAVOR)
	chain.name = "LeverChain"
	UIHelpers.apply_mono(chain, 12, true)
	return chain


# ── Petits constructeurs ─────────────────────────────────────────────────
## Un visage dessiné plutôt qu'un emoji : sans police à emoji couleur, 🙂 et 😖
## rendent deux cercles au trait quasi identiques — or c'est exactement la
## nuance que ce composant doit porter.
func _face_icon(moral: int, alerting: bool) -> Control:
	var face := Control.new()
	face.custom_minimum_size = Vector2(26, 26)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.set_script(preload("res://scripts/components/mood_face.gd"))
	face.set("moral", moral)
	face.set("alerting", alerting)
	return face


func _title(text: String) -> Label:
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	UIHelpers.apply_mono(label, 10, true)
	return label


func _detail_title(text: String) -> Label:
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	UIHelpers.apply_mono(label, 11, true)
	return label


func _detail_line(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.55)
	style.border_color = Color("#dcd7c9")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style
