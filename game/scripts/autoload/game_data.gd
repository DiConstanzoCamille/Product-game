extends Node
## Autoload singleton : charge au démarrage les données de jeu partagées
## avec la landing page (../data/*.json à la racine du dépôt).
## Source de vérité et schéma détaillé : docs/data-schema.md.
##
## NOTE export : ce chemin relatif ("res://../data/") ne fonctionne que
## lorsque le projet tourne depuis l'éditeur ou en build debug non empaqueté.
## Pour un export packagé (PCK), il faudra soit copier data/ dans
## res://data/ au moment du build, soit charger depuis un chemin externe
## au binaire (ex: à côté de l'exécutable). Non résolu — voir
## docs/tech-stack.md, section "Questions ouvertes".

const DATA_DIR := "res://../data/"

var resources: Array = []
var tensions: Array = []
var cards: Dictionary = {}
var eras: Array = []
var endings: Array = []
var foundations: Dictionary = {}
var roadmap_features: Dictionary = {}
var inbox_events: Array = []
var recruitment_archetypes: Dictionary = {}
var recruitment_demo: Dictionary = {}
var hud_demo: Dictionary = {}
var structure: Dictionary = {}

var is_loaded: bool = false


func _ready() -> void:
	_load_all()


func _load_json(file_name: String) -> Variant:
	var path := DATA_DIR + file_name
	if not FileAccess.file_exists(path):
		push_error("Fichier de données introuvable : %s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Impossible d'ouvrir %s (erreur %s)" % [path, FileAccess.get_open_error()])
		return null

	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("JSON invalide dans %s" % path)
	return parsed


func _load_all() -> void:
	var resources_data = _load_json("resources.json")
	if resources_data:
		resources = resources_data.get("resources", [])
		tensions = resources_data.get("tensions", [])

	var cards_data = _load_json("cards.json")
	if cards_data:
		cards = cards_data

	var eras_data = _load_json("eras.json")
	if eras_data:
		eras = eras_data.get("eras", [])

	var endings_data = _load_json("endings.json")
	if endings_data:
		endings = endings_data.get("endings", [])

	var foundations_data = _load_json("foundations.json")
	if foundations_data:
		foundations = foundations_data

	var roadmap_data = _load_json("roadmap-features.json")
	if roadmap_data:
		roadmap_features = roadmap_data

	var inbox_data = _load_json("inbox-events.json")
	if inbox_data:
		inbox_events = inbox_data.get("events", [])

	var archetypes_data = _load_json("recruitment-archetypes.json")
	if archetypes_data:
		recruitment_archetypes = archetypes_data

	var recruitment_demo_data = _load_json("recruitment-demo.json")
	if recruitment_demo_data:
		recruitment_demo = recruitment_demo_data

	var hud_data = _load_json("hud-demo.json")
	if hud_data:
		hud_demo = hud_data

	var structure_data = _load_json("structure.json")
	if structure_data:
		structure = structure_data

	is_loaded = resources.size() > 0 and not cards.is_empty()

	if is_loaded:
		print("GameData: données chargées — %d ressources, %d cartes, %d époques, %d fins de mandat." % [
			resources.size(), cards.get("cards", []).size(), eras.size(), endings.size()
		])
	else:
		push_error("GameData: échec du chargement des données. Vérifiez que data/ existe à la racine du dépôt.")
