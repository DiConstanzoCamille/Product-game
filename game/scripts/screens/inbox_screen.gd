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


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(START_SCREEN_SCENE))
	next_button.pressed.connect(func(): get_tree().change_scene_to_file(NEXT_SCENE))
	next_button.disabled = true
	reveal_label.visible = false

	UIHelpers.apply_mono(sprint_label, 12)
	UIHelpers.apply_heading(subject_label, 26, 600.0)
	UIHelpers.add_hover_bounce(back_button)
	UIHelpers.add_hover_bounce(next_button)
	UIHelpers.fade_in(self)

	sprint_label.text = "Sprint %d — Phase 1 : Inbox" % SprintState.sprint_number
	_load_event()


func _load_event() -> void:
	var events: Array = GameData.inbox_events
	if events.is_empty():
		subject_label.text = "Aucun événement disponible."
		return

	event = events[(SprintState.sprint_number - 1) % events.size()]

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
		btn.pressed.connect(_on_choice_pressed.bind(choice.get("reveal", "")))
		choices_container.add_child(btn)
		UIHelpers.add_hover_bounce(btn, 1.015)


func _on_choice_pressed(reveal: String) -> void:
	reveal_label.text = reveal
	reveal_label.visible = true
	next_button.disabled = false
