extends Node
## Profil persistant du joueur (Lot 4, spec scoring §12.1) — ce qui survit
## entre deux runs, indépendamment de SprintState (qui repart de zéro à
## chaque `reset_run`). Aujourd'hui : les combos de score déjà déclenchés en
## clair (le Compendium des synergies). **Générique et minimal à dessein** :
## le Lot 5 le réutilisera pour la progression de carrière (niveau, XP...)
## sans rien réécrire ici — voir `set_value()` / `get_value()`.
##
## Persistance : un seul `ConfigFile` en `user://player_profile.cfg`. Pas de
## dépendance externe, pas de schéma lourd — deux sections, l'une pour les
## combos (clé = id, valeur = true), l'autre pour l'espace clé/valeur
## générique. Sauvegardé à chaque écriture ; c'est un profil de quelques
## dizaines d'entrées au grand maximum, l'écriture synchrone ne coûte rien.
##
## Interface publique — celle que consommera le Lot 5 :
##   - mark_combo_discovered(combo_id) / is_combo_discovered(combo_id)
##   - get_combo_catalog() -> Array (voir plus bas pour le format)
##   - record_score_report(report) — scanne un rapport ScoreResolver.resolve()
##     et marque tout combo dont la ligne est présente. Un seul calcul (celui
##     du resolver), une seule lecture : on n'a jamais besoin de retester les
##     conditions des combos ici.
##   - set_value(key, value) / get_value(key, default) — espace générique,
##     pour tout ce que la persistance devra porter plus tard.

const SAVE_PATH := "user://player_profile.cfg"
const SECTION_COMBOS := "combos"
const SECTION_VALUES := "values"

var _discovered_combo_ids: Dictionary = {}  # combo_id -> true
var _values: Dictionary = {}               # espace générique clé/valeur, réservé au Lot 5


func _ready() -> void:
	load_profile()


func load_profile() -> void:
	_discovered_combo_ids.clear()
	_values.clear()
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	if config.has_section(SECTION_COMBOS):
		for key in config.get_section_keys(SECTION_COMBOS):
			if bool(config.get_value(SECTION_COMBOS, key, false)):
				_discovered_combo_ids[key] = true
	if config.has_section(SECTION_VALUES):
		for key in config.get_section_keys(SECTION_VALUES):
			_values[key] = config.get_value(SECTION_VALUES, key)


func save_profile() -> void:
	var config := ConfigFile.new()
	for key in _discovered_combo_ids.keys():
		config.set_value(SECTION_COMBOS, key, true)
	for key in _values.keys():
		config.set_value(SECTION_VALUES, key, _values[key])
	config.save(SAVE_PATH)


## Réservé aux tests headless : le profil est un fichier `user://` réel, qui
## survit d'une exécution de test à l'autre — sans ce point d'entrée, toute
## assertion sur un combo "pas encore découvert" deviendrait flaky après le
## premier run. Ne jamais appeler depuis le jeu : reset_run() ne doit jamais
## effacer la progression méta.
func clear_all() -> void:
	_discovered_combo_ids.clear()
	_values.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func mark_combo_discovered(combo_id: String) -> void:
	if combo_id == "" or _discovered_combo_ids.has(combo_id):
		return
	_discovered_combo_ids[combo_id] = true
	save_profile()


func is_combo_discovered(combo_id: String) -> bool:
	return _discovered_combo_ids.has(combo_id)


func set_value(key: String, value: Variant) -> void:
	_values[key] = value
	save_profile()


func get_value(key: String, default_value: Variant = null) -> Variant:
	return _values.get(key, default_value)


## Le catalogue complet du Compendium, familles comprises — reconstruit
## depuis scoring.json à chaque appel, jamais dupliqué : id/icon/label
## viennent de la même table que ScoreResolver, seule la famille est
## ajoutée ici pour le regroupement à l'affichage.
func get_combo_catalog() -> Array:
	var catalog: Array = []
	for combo in GameData.scoring.get("local", {}).get("organizationCombos", []):
		catalog.append(_catalog_entry(combo.get("id", ""), combo, "composition"))
	var hand_bonuses: Dictionary = GameData.scoring.get("traction", {}).get("handBonuses", {})
	for bonus_id in hand_bonuses.keys():
		catalog.append(_catalog_entry(bonus_id, hand_bonuses[bonus_id], "main"))
	var inter_squad: Dictionary = GameData.scoring.get("global", {}).get("interSquadCombos", {})
	for combo_id in inter_squad.keys():
		catalog.append(_catalog_entry(combo_id, inter_squad[combo_id], "inter-squad"))
	return catalog


func _catalog_entry(combo_id: String, data: Dictionary, family: String) -> Dictionary:
	return {
		"id": combo_id,
		"icon": data.get("icon", "✨"),
		"label": data.get("label", combo_id),
		"family": family,
		"discovered": is_combo_discovered(combo_id),
	}


## Scanne un rapport ScoreResolver.resolve() (squads[].lines + global.lines)
## et marque comme découvert tout combo du catalogue dont la ligne apparaît
## — identifié par la paire (icône, libellé), unique par combo dans
## scoring.json. Pas de recalcul des conditions : le rapport a déjà tranché.
func record_score_report(report: Dictionary) -> void:
	if report.is_empty():
		return
	var lookup: Dictionary = {}
	for entry in get_combo_catalog():
		lookup["%s|%s" % [entry.get("icon", ""), entry.get("label", "")]] = entry.get("id", "")

	var changed := false
	for squad_report in report.get("squads", []):
		for line in squad_report.get("lines", []):
			if _mark_if_matching(line, lookup):
				changed = true
	for line in report.get("global", {}).get("lines", []):
		if _mark_if_matching(line, lookup):
			changed = true

	if changed:
		save_profile()


func _mark_if_matching(line: Dictionary, lookup: Dictionary) -> bool:
	var key := "%s|%s" % [line.get("icon", ""), line.get("label", "")]
	if not lookup.has(key):
		return false
	var combo_id: String = lookup[key]
	if combo_id == "" or _discovered_combo_ids.has(combo_id):
		return false
	_discovered_combo_ids[combo_id] = true
	return true
