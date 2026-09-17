class_name RoadmapSprintDropZone
extends PanelContainer
## Gouttiere de planification : elle ne modifie pas la regle de jeu elle-meme,
## elle transmet simplement le ticket depose a l'ecran Roadmap.

signal ticket_dropped(ticket_id: String)
const HUD := preload("res://scripts/components/hud_language.gd")
var drop_highlight := false


func _process(_delta: float) -> void:
	var data: Variant = get_viewport().gui_get_drag_data()
	var active := get_viewport().gui_is_dragging() and _can_drop_data(Vector2.ZERO, data) and Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position())
	if active != drop_highlight:
		drop_highlight = active
		queue_redraw()


func _draw() -> void:
	if drop_highlight:
		draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), HUD.CHOICE, false, 4)
		draw_rect(Rect2(Vector2(6, 6), size - Vector2(12, 12)), Color(0.16, 0.36, 0.58, 0.08))


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and not String(data.get("roadmap_ticket_id", "")).is_empty()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	ticket_dropped.emit(String(data.get("roadmap_ticket_id", "")))
