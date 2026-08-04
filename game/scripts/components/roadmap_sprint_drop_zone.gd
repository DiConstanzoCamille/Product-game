class_name RoadmapSprintDropZone
extends PanelContainer
## Gouttiere de planification : elle ne modifie pas la regle de jeu elle-meme,
## elle transmet simplement le ticket depose a l'ecran Roadmap.

signal ticket_dropped(ticket_id: String)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and not String(data.get("roadmap_ticket_id", "")).is_empty()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	ticket_dropped.emit(String(data.get("roadmap_ticket_id", "")))
