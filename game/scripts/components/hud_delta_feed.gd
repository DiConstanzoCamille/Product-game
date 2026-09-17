extends VBoxContainer
## Retour transitoire de valeurs observées, jamais de gain prédit.
const LABELS := {"impact": "Impact", "cash": "Trésorerie", "users": "Utilisateurs", "energy": "Énergie"}
var shown_changes := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 5)


func observe(previous: Dictionary, current: Dictionary) -> void:
	if previous.is_empty() or previous.get("sprint") != current.get("sprint"):
		return
	for key in LABELS:
		var difference := int(current[key]) - int(previous[key])
		if difference == 0:
			continue
		shown_changes += 1
		# Garder un maximum de trois retours, sans recouvrir le bureau.
		while get_child_count() >= 3:
			var oldest := get_child(0)
			remove_child(oldest)
			oldest.queue_free()
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#f7faf8")
		style.border_color = UIHelpers.COLOR_GOOD if difference > 0 else UIHelpers.COLOR_WARN
		style.border_width_left = 4
		style.set_corner_radius_all(5)
		style.content_margin_left = 10
		style.content_margin_right = 12
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		chip.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.text = "%+d %s" % [difference, LABELS[key]]
		label.add_theme_color_override("font_color", UIHelpers.COLOR_INK)
		label.add_theme_font_size_override("font_size", 14)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(label)
		add_child(chip)
		var tween := chip.create_tween()
		tween.tween_interval(2.2)
		tween.tween_property(chip, "modulate:a", 0.0, 0.45)
		tween.tween_callback(chip.queue_free)
