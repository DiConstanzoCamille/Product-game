extends Control
## Phase 1 — Inbox (docs/carnet-de-regles.md §3). Un événement force un choix
## avant toute planification. Les données viennent de data/inbox-events.json.

const NEXT_SCENE := "res://scenes/screens/roadmap_screen.tscn"
const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var sprint_label: Label = $Margin/VBox/TopBar/SprintLabel
@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var from_row: HBoxContainer = $Margin/VBox/Scroll/Content/FromRow
@onready var from_label: Label = $Margin/VBox/Scroll/Content/FromRow/FromLabel
@onready var subject_label: Label = $Margin/VBox/Scroll/Content/SubjectLabel
@onready var body_label: Label = $Margin/VBox/Scroll/Content/BodyLabel
@onready var choices_container: VBoxContainer = $Margin/VBox/Scroll/Content/ChoicesContainer
@onready var reveal_label: Label = $Margin/VBox/Scroll/Content/RevealLabel
@onready var next_button: Button = $Margin/VBox/BottomBar/NextButton

var event: Dictionary
var choice_buttons: Array[Button] = []
var choice_made: bool = false
var side_panel: Control = null


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(func(): get_tree().change_scene_to_file(NEXT_SCENE))
	next_button.disabled = true
	reveal_label.visible = false

	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.apply_heading(subject_label, 26, 600.0)
	UIHelpers.add_hover_bounce(back_button)
	UIHelpers.add_hover_bounce(next_button)
	UIHelpers.style_primary_button(next_button)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 1 : Inbox" % SprintState.sprint_number

	# Rien de l'écran Inbox ne dépend du roster ni des pièces : le panneau se
	# tient à jour tout seul, l'écran n'a pas à écouter ses changements.
	side_panel = UIHelpers.attach_side_panel(self)

	_load_event()


func _load_event() -> void:
	event = SprintState.draw_inbox_event()
	if event.is_empty():
		subject_label.text = "Aucun événement disponible."
		return

	var sender: String = event.get("from", "")
	var first_name := sender.split(",")[0].strip_edges()
	var avatar := UIHelpers.make_avatar(first_name, 40)
	from_row.add_child(avatar)
	from_row.move_child(avatar, 0)

	from_label.text = "De : %s · %s" % [sender, event.get("status", "")]
	subject_label.text = event.get("subject", "")
	body_label.text = event.get("text", "")

	for choice in event.get("choices", []):
		var btn := Button.new()
		btn.text = choice.get("label", "")
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_choice_pressed.bind(choice))
		choices_container.add_child(btn)
		choice_buttons.append(btn)
		UIHelpers.add_hover_bounce(btn, 1.015)


func _on_choice_pressed(choice: Dictionary) -> void:
	if choice_made:
		return
	choice_made = true

	reveal_label.text = choice.get("reveal", "")
	reveal_label.visible = true
	next_button.disabled = false

	for btn in choice_buttons:
		btn.disabled = true

	var note := "%s → %s" % [event.get("subject", ""), choice.get("label", "")]
	SprintState.add_pending(choice.get("effects", {}), note)
