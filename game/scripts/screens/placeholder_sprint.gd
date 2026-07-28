extends Control
## Écran de transition minimal atteint depuis "Nouvelle partie".
## Confirme que GameData a bien chargé data/*.json. Sera remplacé par
## le véritable écran de phase Inbox — voir game/README.md.

const START_SCREEN_SCENE := "res://scenes/screens/start_screen.tscn"

@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	if GameData.is_loaded:
		status_label.text = "Données chargées : %d ressources, %d cartes, %d époques, %d fins de mandat.\n\nLes écrans de sprint (Inbox, Roadmap, Recrutement...) arrivent ensuite." % [
			GameData.resources.size(),
			GameData.cards.get("cards", []).size(),
			GameData.eras.size(),
			GameData.endings.size(),
		]
	else:
		status_label.text = "Erreur : les données n'ont pas pu être chargées. Voir la console (Sortie)."


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(START_SCREEN_SCENE)
