extends Control
## Phase 1 — Inbox. Un événement force un choix avant toute planification.
## Le choix et ses effets restent portés par SprintState ; cet écran les raconte
## comme le fil interne qui vient de tomber dans l'openspace.

const NEXT_SCENE := "res://scenes/screens/roadmap_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"
const DEFAULT_CHANNEL := "#direction-produit"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var channel_label: Label = $Margin/VBox/Thread/ThreadBody/ChannelHeader/ChannelLabel
@onready var channel_meta_label: Label = $Margin/VBox/Thread/ThreadBody/ChannelHeader/ChannelMetaLabel
@onready var scroll: ScrollContainer = $Margin/VBox/Thread/ThreadBody/Scroll
@onready var messages_container: VBoxContainer = $Margin/VBox/Thread/ThreadBody/Scroll/Messages
@onready var next_button: Button = $Margin/VBox/BottomBar/NextButton

var event: Dictionary
var choice_buttons: Array[Button] = []
var choice_made := false
var side_panel: Control = null


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(_on_next_pressed)
	next_button.disabled = true

	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.apply_mono(channel_meta_label, 12)
	UIHelpers.style_primary_button(next_button)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 1 : Inbox" % SprintState.sprint_number
	side_panel = UIHelpers.attach_side_panel(self)
	UIHelpers.attach_decision_workspace(self, NodePath("Margin/VBox"))
	_load_event()


func _load_event() -> void:
	event = SprintState.draw_inbox_event()
	if event.is_empty():
		channel_label.text = DEFAULT_CHANNEL
		channel_meta_label.text = "Aucun message"
		_append_system_note("Aucun événement disponible.")
		return

	var sender: String = event.get("from", "")
	channel_label.text = "💬 %s" % event.get("channel", DEFAULT_CHANNEL)
	channel_meta_label.text = "Sprint %d · %s" % [SprintState.sprint_number, _timestamp()]
	_append_incoming_message(sender, event.get("subject", ""), event.get("text", ""), event.get("status", ""))
	_append_reply_drafts(event.get("choices", []))


func _append_incoming_message(sender: String, subject: String, body: String, status: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	messages_container.add_child(row)

	var avatar := UIHelpers.make_sender_badge(sender, 38)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(avatar)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	row.add_child(column)

	var meta := Label.new()
	meta.text = "%s  ·  %s" % [sender, _timestamp()]
	meta.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	meta.add_theme_font_size_override("font_size", 13)
	column.add_child(meta)

	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.add_theme_stylebox_override("panel", _bubble_style(Color.WHITE, UIHelpers.COLOR_RULE, 7))
	column.add_child(bubble)

	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 6)
	bubble.add_child(copy)

	var subject_row := HBoxContainer.new()
	subject_row.add_theme_constant_override("separation", 10)
	copy.add_child(subject_row)

	var subject_label := Label.new()
	subject_label.text = subject
	subject_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subject_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIHelpers.apply_heading(subject_label, 18, 600.0)
	subject_row.add_child(subject_label)
	if status.to_lower() == "urgent":
		subject_row.add_child(UIHelpers.make_stamp("urgent", 78))

	var body_label := Label.new()
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_color_override("font_color", UIHelpers.COLOR_FLAVOR)
	body_label.add_theme_font_size_override("font_size", 15)
	copy.add_child(body_label)


func _append_reply_drafts(choices: Array) -> void:
	var composer := VBoxContainer.new()
	composer.name = "ReplyComposer"
	composer.add_theme_constant_override("separation", 8)
	messages_container.add_child(composer)

	var separator := HSeparator.new()
	composer.add_child(separator)

	var prompt := Label.new()
	prompt.text = "VOTRE RÉPONSE"
	UIHelpers.apply_mono(prompt, 12, true)
	prompt.add_theme_color_override("font_color", UIHelpers.COLOR_AMBER)
	composer.add_child(prompt)

	var replies := VBoxContainer.new()
	replies.name = "ReplyDrafts"
	replies.add_theme_constant_override("separation", 2)
	composer.add_child(replies)

	for choice in choices:
		var button := Button.new()
		button.text = "▸  %s" % choice.get("label", "")
		button.flat = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 38)
		button.tooltip_text = "Envoyer cette réponse"
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_hover_color", UIHelpers.COLOR_SHELF)
		button.pressed.connect(_on_choice_pressed.bind(choice))
		replies.add_child(button)
		choice_buttons.append(button)


func _on_choice_pressed(choice: Dictionary) -> void:
	if choice_made:
		return
	choice_made = true

	for button in choice_buttons:
		button.disabled = true

	var composer := messages_container.get_node_or_null("ReplyComposer")
	if composer != null:
		composer.queue_free()

	_append_outgoing_message(choice.get("label", ""))
	_append_consequence_message(choice.get("reveal", ""))
	next_button.disabled = false

	var note := "%s → %s" % [event.get("subject", ""), choice.get("label", "")]
	SprintState.apply_inbox_choice(choice, note)
	if SprintState.has_pending_team_events():
		next_button.text = "Traiter la demande suivante (%d) →" % SprintState.pending_team_event_count()
	else:
		next_button.text = "Suivant : Roadmap →"
	call_deferred("_scroll_to_latest")


func _on_next_pressed() -> void:
	if not SprintState.has_pending_team_events():
		get_tree().change_scene_to_file(NEXT_SCENE)
		return
	UIHelpers.clear_children(messages_container)
	choice_buttons.clear()
	choice_made = false
	next_button.disabled = true
	next_button.text = "Suivant : Roadmap →"
	_load_event()


func _append_outgoing_message(text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	messages_container.add_child(row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(0, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	row.add_child(column)

	var meta := Label.new()
	meta.text = "Vous  ·  %s" % _timestamp()
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	meta.add_theme_font_size_override("font_size", 13)
	column.add_child(meta)

	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", _bubble_style(Color("e8f0ff"), UIHelpers.COLOR_SHELF, 7))
	column.add_child(bubble)

	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", UIHelpers.COLOR_INK)
	label.add_theme_font_size_override("font_size", 15)
	bubble.add_child(label)


func _append_consequence_message(text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	messages_container.add_child(row)

	var avatar := UIHelpers.make_person_badge("Mise à jour", 30, UIHelpers.COLOR_SHELF)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(avatar)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	row.add_child(column)

	var meta := Label.new()
	meta.text = "Mise à jour du fil  ·  %s" % _timestamp()
	meta.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	meta.add_theme_font_size_override("font_size", 13)
	column.add_child(meta)

	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.add_theme_stylebox_override("panel", _bubble_style(Color("fff7db"), UIHelpers.COLOR_AMBER, 7))
	column.add_child(bubble)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	bubble.add_child(header)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", UIHelpers.COLOR_FLAVOR)
	label.add_theme_font_size_override("font_size", 15)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	header.add_child(UIHelpers.make_stamp("validated", 82))


func _append_system_note(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", UIHelpers.COLOR_SOFT_TEXT)
	messages_container.add_child(label)


func _bubble_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	return style


func _timestamp() -> String:
	return "09:%02d" % (10 + SprintState.sprint_number)


func _scroll_to_latest() -> void:
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
