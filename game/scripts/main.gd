extends Control
## Écran de démarrage minimal : confirme que GameData a bien chargé
## data/*.json. Sert de point de départ, pas d'écran final.

@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	if GameData.is_loaded:
		status_label.text = "Product Tycoon — données chargées : %d ressources, %d cartes, %d époques, %d fins de mandat." % [
			GameData.resources.size(),
			GameData.cards.get("cards", []).size(),
			GameData.eras.size(),
			GameData.endings.size(),
		]
	else:
		status_label.text = "Erreur : les données n'ont pas pu être chargées. Voir la console (Sortie)."
