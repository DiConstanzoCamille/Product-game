extends Node
## Autoload singleton : charge au démarrage les données de jeu partagées
## avec la landing page (../data/*.json à la racine du dépôt).
## Source de vérité et schéma détaillé : docs/data-schema.md.
##
## Résolution du dossier de données : en éditeur ou en lancement debug,
## "res://../data/" pointe vers le dossier data/ du dépôt. Dans un export
## packagé, res:// est un .pck et ne permet pas de remonter au-dessus —
## on retombe alors sur un dossier data/ placé à côté de l'exécutable
## (voir game/README.md, section "Exporter le jeu").

const DATA_DIR_DEV := "res://../data/"

var resources: Array = []
var tensions: Array = []
var cards: Dictionary = {}
var eras: Array = []
var endings: Array = []
var foundations: Dictionary = {}
var backlog: Dictionary = {}
var inbox_events: Array = []
var recruitment_archetypes: Dictionary = {}
var recruitment_demo: Dictionary = {}
var hud_demo: Dictionary = {}
var structure: Dictionary = {}
var balance: Dictionary = {}
var companies: Array = []
var candidates: Array = []
var practices: Array = []
var hidden_traits: Dictionary = {}

var is_loaded: bool = false

var _data_dir: String = ""


func _ready() -> void:
	_data_dir = _resolve_data_dir()
	_load_all()


func _resolve_data_dir() -> String:
	if FileAccess.file_exists(DATA_DIR_DEV + "resources.json"):
		return DATA_DIR_DEV
	return OS.get_executable_path().get_base_dir() + "/data/"


func _load_json(file_name: String) -> Variant:
	var path := _data_dir + file_name
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

	var backlog_data = _load_json("backlog.json")
	if backlog_data:
		backlog = backlog_data

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

	var balance_data = _load_json("balance.json")
	if balance_data:
		balance = balance_data

	var companies_data = _load_json("companies.json")
	if companies_data:
		companies = companies_data.get("companies", [])

	var candidates_data = _load_json("candidates.json")
	if candidates_data:
		candidates = candidates_data.get("candidates", [])

	var practices_data = _load_json("practices.json")
	if practices_data:
		practices = practices_data.get("practices", [])

	var hidden_traits_data = _load_json("hidden-traits.json")
	if hidden_traits_data:
		hidden_traits = hidden_traits_data

	is_loaded = resources.size() > 0 and not cards.is_empty() and not balance.is_empty()

	if is_loaded:
		print("GameData: données chargées — %d ressources, %d cartes, %d époques, %d fins de mandat." % [
			resources.size(), cards.get("cards", []).size(), eras.size(), endings.size()
		])
	else:
		push_error("GameData: échec du chargement des données. Vérifiez que data/ existe à la racine du dépôt (ou à côté de l'exécutable en export).")
