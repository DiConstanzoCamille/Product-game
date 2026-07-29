class_name UIHelpers
extends RefCounted
## Petits utilitaires de style partagés entre les écrans de sprint.
## Licences des assets référencés : game/assets/THIRD_PARTY_NOTICES.md

const COLOR_GOOD := Color(0.498039, 0.890196, 0.647059)   # #7FE3A5
const COLOR_WARN := Color(0.941176, 0.705882, 0.290196)   # #F0B44A
const COLOR_DANGER := Color(0.952941, 0.537255, 0.498039) # #F3897F
const COLOR_SOFT_TEXT := Color(0.666667, 0.713725, 0.8)   # #AAB6CC
const COLOR_AMBER := Color(0.988235, 0.917647, 0.796078)  # #FCEACB

const FONT_SPACE_GROTESK := preload("res://assets/fonts/SpaceGrotesk-Variable.ttf")
const FONT_MONO_MEDIUM := preload("res://assets/fonts/IBMPlexMono-Medium.ttf")
const FONT_MONO_SEMIBOLD := preload("res://assets/fonts/IBMPlexMono-SemiBold.ttf")

const ICON_DIR := "res://assets/icons/"
const AVATAR_DIR := "res://assets/avatars/"

const GAUGE_ICONS := {
	"tresorerie": "wallet",
	"moral": "heart-handshake",
	"dette-organisationnelle": "brick-wall",
	"capital-politique": "target",
	"valeur-percue": "trending-up",
	"cynisme": "drama",
}


static func state_color(state: String) -> Color:
	match state:
		"good":
			return COLOR_GOOD
		"danger":
			return COLOR_DANGER
		_:
			return COLOR_WARN


static func make_bar_fill_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style


static func make_bar_background_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.12)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style


## Police des titres (Space Grotesk), à un poids donné (400-700).
static func heading_font(weight: float = 600.0) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = FONT_SPACE_GROTESK
	variation.variation_opentype = {"wght": weight}
	return variation


static func apply_heading(label: Label, size: int = 20, weight: float = 600.0) -> void:
	label.add_theme_font_override("font", heading_font(weight))
	label.add_theme_font_size_override("font_size", size)


## Police mono (IBM Plex Mono) pour les labels de type "eyebrow" / compteurs.
static func apply_mono(label: Label, size: int = 12, semibold: bool = false) -> void:
	label.add_theme_font_override("font", FONT_MONO_SEMIBOLD if semibold else FONT_MONO_MEDIUM)
	label.add_theme_font_size_override("font_size", size)


static func icon_texture(icon_name: String) -> Texture2D:
	return load(ICON_DIR + icon_name + ".svg")


## Icône Lucide (trait blanc) teintée via modulate — voir assets/THIRD_PARTY_NOTICES.md.
static func make_icon(icon_name: String, size: int = 20, color: Color = Color.WHITE) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = icon_texture(icon_name)
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.modulate = color
	return rect


## Portrait DiceBear si dispo pour `seed_name` (minuscules), sinon icône générique.
static func make_avatar(seed_name: String, size: int = 48) -> TextureRect:
	var rect := TextureRect.new()
	var path := AVATAR_DIR + seed_name.to_lower() + ".svg"
	if ResourceLoader.exists(path):
		rect.texture = load(path)
	else:
		rect.texture = icon_texture("user-round")
		rect.modulate = Color(1, 1, 1, 0.55)
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect


static func fade_in(control: Control, duration: float = 0.3) -> void:
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration)


## Barre compacte des 6 ressources (icône + %), état courant (celui d'après
## la dernière Résolution — pas de preview des effets en attente). Insérée
## en haut des écrans de phase (Inbox, Roadmap, Grandes décisions, Recrutement).
static func build_resource_bar() -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.05)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	panel.add_child(row)

	for resource in GameData.resources:
		var resource_id: String = resource.get("id", "")
		var value: float = SprintState.resource_values.get(resource_id, 0.0)
		var state := EffectResolver.gauge_state(resource_id, value)

		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 5)
		item.mouse_filter = Control.MOUSE_FILTER_STOP
		item.tooltip_text = resource_tooltip(resource)
		item.add_child(make_icon(GAUGE_ICONS.get(resource_id, "target"), 14, state_color(state)))

		var label := Label.new()
		label.text = "%d%%" % int(round(value))
		label.add_theme_color_override("font_color", state_color(state))
		apply_mono(label, 12, true)
		item.add_child(label)

		row.add_child(item)

	return panel


## Texte de tooltip pour une ressource : définition + ce qui la fait
## monter/descendre (resources.json), affiché au survol de la barre.
static func resource_tooltip(resource: Dictionary) -> String:
	var lines: Array = ["%s %s" % [resource.get("icon", ""), resource.get("name", "")]]
	if resource.get("definition", "") != "":
		lines.append(resource.get("definition", ""))
	var rises: Array = resource.get("rises", [])
	if not rises.is_empty():
		lines.append("Monte : %s" % ", ".join(rises))
	var falls: Array = resource.get("falls", [])
	if not falls.is_empty():
		lines.append("Descend : %s" % ", ".join(falls))
	return "\n".join(lines)


## Branche le bouton + panneau "Entreprise" (§16) sur un écran de phase :
## instancie company_panel.tscn en enfant de `screen` (overlay caché par
## défaut, jamais un changement de scène — évite de perturber un état déjà
## consommé, ex. un tirage Inbox), et ajoute un bouton dans sa TopBar pour
## l'ouvrir/fermer. `screen` doit avoir un nœud "Margin/VBox/TopBar".
static func attach_company_menu(screen: Control) -> void:
	var panel_scene: PackedScene = load("res://scenes/components/company_panel.tscn")
	var panel: Control = panel_scene.instantiate()
	screen.add_child(panel)

	var top_bar: Node = screen.get_node("Margin/VBox/TopBar")
	var company: Dictionary = SprintState.get_company()

	var button := Button.new()
	button.text = "%s %s" % [company.get("icon", "🏢"), company.get("name", "Entreprise")]
	button.pressed.connect(func(): panel.visible = not panel.visible)
	add_hover_bounce(button, 1.02)

	top_bar.add_child(button)
	top_bar.move_child(button, 1)


## Léger effet de survol (zoom) sur un bouton — purement cosmétique.
static func add_hover_bounce(button: Button, scale_amount: float = 1.04) -> void:
	button.pivot_offset = button.size / 2.0
	button.resized.connect(func(): button.pivot_offset = button.size / 2.0)
	button.mouse_entered.connect(func():
		var tween := button.create_tween()
		tween.tween_property(button, "scale", Vector2.ONE * scale_amount, 0.12)
	)
	button.mouse_exited.connect(func():
		var tween := button.create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.12)
	)
