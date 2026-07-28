extends Control
## Écran d'accueil. Point d'entrée du jeu (run/main_scene dans project.godot).

const PLACEHOLDER_SPRINT_SCENE := "res://scenes/screens/placeholder_sprint.tscn"

@onready var new_game_button: Button = $CenterContainer/VBoxContainer/MenuButtons/NewGameButton
@onready var rules_button: Button = $CenterContainer/VBoxContainer/MenuButtons/RulesButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/MenuButtons/QuitButton
@onready var rules_panel: PanelContainer = $RulesPanel
@onready var rules_text: RichTextLabel = $RulesPanel/VBoxContainer/ScrollContainer/RulesText
@onready var rules_close_button: Button = $RulesPanel/VBoxContainer/CloseButton


func _ready() -> void:
	rules_panel.visible = false

	new_game_button.pressed.connect(_on_new_game_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	rules_close_button.pressed.connect(_on_rules_close_pressed)

	_populate_rules_text()


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file(PLACEHOLDER_SPRINT_SCENE)


func _on_rules_pressed() -> void:
	rules_panel.visible = true


func _on_rules_close_pressed() -> void:
	rules_panel.visible = false


func _on_quit_pressed() -> void:
	get_tree().quit()


func _populate_rules_text() -> void:
	# Résumé condensé du carnet de règles (docs/carnet-de-regles.md).
	# Reste un raccourci pour l'écran d'accueil, pas une source de vérité :
	# en cas de désaccord avec le carnet de règles, c'est le carnet qui gagne.
	rules_text.text = "[b]Concept[/b]\nVous incarnez le·la CPO fraîchement nommé·e d'une organisation que vous n'avez pas construite. Contexte tiré au sort, équipe héritée, décisions rarement réversibles. Chaque bonne pratique promet une amélioration théorique — son effet réel dépend de qui la reçoit.\n\n[b]Un sprint, cinq phases[/b]\n1. [b]Inbox[/b] — un événement force un choix avant toute planification.\n2. [b]Roadmap[/b] — 2 à 4 features proposées, limitées par la capacité de l'équipe.\n3. [b]Grandes décisions[/b] — activation optionnelle d'un outil, d'une stack ou d'une méthodologie.\n4. [b]Recrutement[/b] — accès optionnel au shop.\n5. [b]Résolution[/b] — les effets s'appliquent, le delta s'affiche.\n\n[b]Six ressources, aucune à optimiser seule[/b]\n💰 Trésorerie · 🫶 Moral & confiance d'équipe · 🧱 Dette organisationnelle · 🎯 Capital politique · 📈 Valeur perçue · 🎭 Cynisme\n\n[b]Le contexte change les règles[/b]\nÀ chaque run, une époque est tirée au sort (les années garage, la transformation agile, l'ère de l'IA) — même carte, même joueur·se, résultat différent.\n\n[i]Document de travail : rien n'est encore équilibré. Détail complet dans docs/carnet-de-regles.md.[/i]"
