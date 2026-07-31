class_name RoadmapTicket
extends PanelContainer
## Ticket manipulable du board Roadmap. Son contenu est construit par l'ecran ;
## ce composant ne porte que les gestes communs : ouvrir et glisser-deposer.

signal opened(ticket_id: String)

var ticket_id: String = ""
var ticket_title: String = ""


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.double_click:
		opened.emit(ticket_id)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if ticket_id == "":
		return null

	var preview := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ffffff")
	style.border_color = UIHelpers.COLOR_SHELF
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	preview.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = ticket_title
	label.add_theme_font_size_override("font_size", 13)
	preview.add_child(label)
	set_drag_preview(preview)
	return {"roadmap_ticket_id": ticket_id}
