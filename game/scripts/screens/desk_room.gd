class_name DeskRoom
extends Node3D
## Le bureau, en volume — la couche décor du hub (issues #54 et #59).
##
## Remplace le décor 2D de `desk_screen.gd`. Le spike l'a tranché : la
## profondeur vient gratuitement d'une caméra, alors que la simuler en 2D
## demandait un dégradé de plateau, des ombres décalées et une vignette — trois
## ruses pour approcher ce qu'un `Camera3D` donne sans rien.
##
## **Le partage est net, et c'est lui qui rend le lot tenable :**
##
##  · **En 3D** — la pièce, la table, le portable, les objets posés, les
##    papiers du mur. Tout ce qui a un volume et reçoit de la lumière.
##  · **En 2D** — les zones de valeurs, les alertes, les info-bulles, et
##    **tout le contenu des applications**. Une interface qu'on lit ne gagne
##    rien à être en perspective, elle y perd en lisibilité.
##
## La dalle du portable est un `SubViewport` texturé sur un quad : le poste de
## travail et les écrans de phase existants s'y affichent **sans être
## réécrits**, et prennent la perspective de la pièce.
##
## ## Le compromis de cadrage, et pourquoi il n'est pas négociable
##
## Une caméra perpendiculaire à une dalle qui remplit le cadre ne voit plus la
## table : le plateau tombe hors champ dès qu'on regarde l'écran de face. La
## sortie est de **coucher la dalle en arrière** (`LID_TILT_DEGREES`) et de
## plonger la caméra d'autant : l'axe reste sur la normale de la dalle — donc
## le texte n'est pas incliné, critère de recette n°1 — et le plateau rentre
## dans le cadre parce que la caméra le survole.
##
## `CAMERA_AIM_UP` vise ensuite légèrement au-dessus du centre de la dalle : le
## portable descend dans le cadre, et c'est ce qui dégage la bande de mur où
## vivent les papiers. Le désaxement qui en résulte (~5°) est le seul écart à
## la perpendicularité, et il est trop faible pour déformer une lettre.
##
## ## La règle de netteté
##
## `SCREEN_PIXELS` n'est pas une taille choisie au hasard : **la taille du quad
## s'en déduit**, jamais l'inverse (`_pixels_to_world()`). Un `SubViewport` de
## 880 px affiché sur 600 px de dalle rendrait tout le contenu des phases à 68 %
## de sa taille — c'est exactement la façon dont on rate le critère de recette
## n°1 sans qu'aucun test ne bronche. Déplacer la caméra ne peut donc plus
## dérégler la netteté : le quad se re-dimensionne avec elle.

## La dalle du portable, en pixels de rendu. Plus large que la dalle 2D du
## Lot A (762×415) : les écrans de phase hébergés y respirent davantage.
const SCREEN_PIXELS := Vector2i(880, 495)

## La taille de composition du jeu (1600×900). Le rendu 3D, lui, a lieu à la
## résolution réelle de la fenêtre : tout ce qui doit s'aligner avec la couche
## 2D se calcule donc dans ce repère-là, jamais en pixels de fenêtre.
const DESIGN := Vector2(1600, 900)

const CAMERA_FOV := 42.0
const CAMERA_DISTANCE := 1.62
## Vise au-dessus du centre de la dalle : le portable descend dans le cadre et
## dégage la bande de mur. En unités monde, sur l'axe vertical de la caméra.
const CAMERA_AIM_UP := 0.145

const LID_TILT_DEGREES := -22.0
const LID_PIVOT := Vector3(0.0, 0.795, -0.02)
const DALLE_LOCAL := Vector3(0.0, 0.40, 0.013)

const WALL_Z := -1.35
const DESK_TOP_Y := 0.755

## Le mur est **plus sombre que le papier** : à teinte égale, une feuille
## blanche punaisée sur un mur blanc n'est plus une feuille, c'est une tache.
const WALL := Color("#c3ccc5")
const FLOOR := Color("#aca596")
const WOOD := Color("#bd9468")
const WOOD_DARK := Color("#7d5735")
const ALU := Color("#77839a")

## L'encre du trait de contour. C'est la même que celle des écrans 2D
## (`UIHelpers.COLOR_INK`) : un objet du monde et une carte de la Roadmap
## doivent avoir l'air dessinés par la même main.
const INK := Color("#2a2f38")
## Épaisseur du trait **en pixels de composition**, pas en unités monde. Un
## trait déclaré dans le monde s'amincit avec la distance : à 0,0055 il faisait
## 6 px sur la tasse et 2 px sur les papiers du mur, où il se rasterisait en
## pointillés. Un trait dessiné n'a pas de perspective — c'est de l'encre, pas
## un objet — donc son épaisseur se déclare à l'écran et se convertit.
const OUTLINE_PIXELS := 3.0

var screen_viewport: SubViewport = null
var camera: Camera3D = null

var _lid: Node3D = null
var _dalle: MeshInstance3D = null


## Godot rejette `add_child()` sur un nœud encore en train d'installer ses
## enfants — **sans lever d'erreur GDScript**. Le spike a donné trois écrans
## unis avant qu'on le comprenne : on construit donc une fois entré dans
## l'arbre, jamais pendant.
func _ready() -> void:
	build.call_deferred()


func build() -> void:
	if camera != null:
		return
	_build_environment()
	_build_room()
	# La caméra avant la dalle : c'est elle qui donne l'échelle pixel/unité
	# dont la taille du quad se déduit.
	_build_camera()
	_build_laptop()


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = WALL
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e2e6ec")
	env.ambient_light_energy = 0.32
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, -38, 0)
	# Une scène claire a besoin de MOINS de lumière qu'une scène sombre : la
	# première passe du spike, à 1,15, était intégralement brûlée.
	sun.light_energy = 0.62
	sun.shadow_enabled = true
	# La pièce tient dans cinq mètres : laisser la carte d'ombre couvrir cent
	# mètres par défaut, c'est la gaspiller — et c'est ce qui donnait des
	# ombres crénelées sous les papiers du mur, la seule ombre qu'on regarde.
	sun.directional_shadow_max_distance = 4.5
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.shadow_bias = 0.015
	sun.shadow_normal_bias = 1.4
	add_child(sun)


func _build_room() -> void:
	# Le mur et le sol ne portent pas de trait : ce sont les surfaces sur
	# lesquelles les silhouettes se détachent, pas des silhouettes. Les cerner
	# dessinerait un cadre autour de la pièce.
	_box(Vector3(0, 1.7, WALL_Z - 0.04), Vector3(9.0, 3.4, 0.08), WALL, false)
	_box(Vector3(0, -0.02, 0), Vector3(9.0, 0.04, 5.0), FLOOR, false)
	_box(Vector3(0, DESK_TOP_Y - 0.03, 0.10), Vector3(3.6, 0.06, 1.6), WOOD)
	_box(Vector3(0, DESK_TOP_Y - 0.055, -0.68), Vector3(3.6, 0.03, 0.06), WOOD_DARK)
	for x in [-1.68, 1.68]:
		_box(Vector3(x, 0.36, 0.10), Vector3(0.08, 0.73, 1.5), WOOD_DARK)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = CAMERA_FOV
	add_child(camera)

	var center := dalle_center()
	var normal := dalle_normal()
	var position := center + normal * CAMERA_DISTANCE
	# `look_at` et `current` n'ont d'effet qu'une fois le nœud dans l'arbre :
	# les poser avant `add_child()` donne un écran uni, sans la moindre erreur.
	camera.look_at_from_position(position, center, Vector3.UP)
	# Le point visé remonte le long de l'axe vertical *de la caméra*, pas du
	# monde : autrement le décalage rendrait la dalle trapézoïdale.
	var aim := center + camera.global_transform.basis.y * CAMERA_AIM_UP
	camera.look_at_from_position(position, aim, Vector3.UP)
	camera.current = true


func _build_laptop() -> void:
	var quad_size := _pixels_to_world(Vector2(SCREEN_PIXELS), dalle_center())
	var bezel := Vector2(0.055, 0.05)

	_box(Vector3(0, 0.782, 0.30), Vector3(quad_size.x + 0.10, 0.024, 0.56), ALU)
	_box(Vector3(0, 0.795, 0.36), Vector3(quad_size.x * 0.72, 0.006, 0.22), Color("#66718a"))

	_lid = Node3D.new()
	_lid.name = "Lid"
	_lid.position = LID_PIVOT
	_lid.rotation_degrees = Vector3(LID_TILT_DEGREES, 0, 0)
	add_child(_lid)

	var shell := MeshInstance3D.new()
	shell.name = "LidShell"
	var shell_mesh := BoxMesh.new()
	shell_mesh.size = Vector3(quad_size.x + bezel.x * 2.0, quad_size.y + bezel.y * 2.0, 0.016)
	shell.mesh = shell_mesh
	shell.position = DALLE_LOCAL - Vector3(0, 0, 0.014)
	shell.material_override = toon_material(ALU)
	_lid.add_child(shell)
	outline_at(shell, dalle_center())

	screen_viewport = SubViewport.new()
	screen_viewport.name = "ScreenViewport"
	screen_viewport.size = SCREEN_PIXELS
	screen_viewport.transparent_bg = false
	screen_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Sans ça, un clic transmis par `push_input()` n'atteint jamais les Control
	# qui vivent dedans : le SubViewport les filtre au lieu de les router.
	screen_viewport.handle_input_locally = true
	screen_viewport.gui_embed_subwindows = true
	_lid.add_child(screen_viewport)

	_dalle = MeshInstance3D.new()
	_dalle.name = "Dalle"
	var quad := QuadMesh.new()
	quad.size = quad_size
	_dalle.mesh = quad
	_dalle.position = DALLE_LOCAL
	var screen_material := StandardMaterial3D.new()
	screen_material.albedo_texture = screen_viewport.get_texture()
	# Un écran n'est pas une surface qui reçoit la lumière, c'est une surface
	# qui en émet : sans ça, la dalle s'assombrit avec la pièce.
	screen_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_dalle.material_override = screen_material
	_lid.add_child(_dalle)

	var area := Area3D.new()
	area.name = "DalleArea"
	area.position = DALLE_LOCAL + Vector3(0, 0, 0.002)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(quad_size.x, quad_size.y, 0.01)
	shape.shape = box
	area.add_child(shape)
	area.input_event.connect(_on_dalle_input)
	_lid.add_child(area)


# ── Géométrie publique ───────────────────────────────────────────────────
## Le centre de la dalle en coordonnées monde. Calculé, jamais recopié : la
## moitié des erreurs de placement de ce lot venaient d'une constante figée
## après un changement d'inclinaison du capot.
func dalle_center() -> Vector3:
	var tilt := deg_to_rad(LID_TILT_DEGREES)
	return LID_PIVOT + Basis(Vector3.RIGHT, tilt) * DALLE_LOCAL


func dalle_normal() -> Vector3:
	return (Basis(Vector3.RIGHT, deg_to_rad(LID_TILT_DEGREES)) * Vector3.BACK).normalized()


## Combien de pixels **de composition** (1600×900) occupe une unité monde à la
## profondeur d'un point. C'est la fonction qui garantit la netteté : tout ce
## qui porte du texte s'en sert pour se dimensionner.
func design_pixels_per_unit_at(point: Vector3) -> float:
	if camera == null:
		return 1.0
	var depth: float = -camera.global_transform.basis.z.dot(point - camera.global_position)
	if depth <= 0.01:
		return 1.0
	return DESIGN.y / (2.0 * depth * tan(deg_to_rad(camera.fov) * 0.5))


func _pixels_to_world(pixels: Vector2, at: Vector3) -> Vector2:
	return pixels / design_pixels_per_unit_at(at)


## Projette un point du monde dans le repère 2D de composition. `unproject_position`
## rendrait des pixels de **fenêtre** ; la couche 2D, elle, vit en 1600×900 —
## les deux ne coïncident qu'en 1600×900, et l'écart ne se verrait qu'en plein
## écran, c'est-à-dire jamais dans une capture.
func project_to_design(point: Vector3) -> Vector2:
	if camera == null:
		return DESIGN * 0.5
	var basis := camera.global_transform.basis
	var delta := point - camera.global_position
	var depth: float = -basis.z.dot(delta)
	if depth <= 0.01:
		return Vector2(-9999, -9999)
	var scale := DESIGN.y / (2.0 * depth * tan(deg_to_rad(camera.fov) * 0.5))
	return DESIGN * 0.5 + Vector2(basis.x.dot(delta) * scale, -basis.y.dot(delta) * scale)


## Le placement d'un panneau présenté au joueur : plein cadre ou presque, **de
## face**. Un panneau incliné donnerait du texte incliné — c'est l'échec du
## critère de recette n°1, et c'est pour ça que l'inclinaison appartient à
## l'animation d'entrée, jamais à l'état posé.
func presentation_placement(pixels: Vector2i, distance: float) -> Dictionary:
	var basis := camera.global_transform.basis if camera != null else Basis()
	var origin := (camera.global_position if camera != null else Vector3.ZERO) - basis.z * distance
	return {
		"position": origin,
		"basis": basis,
		"size": _pixels_to_world(Vector2(pixels), origin),
	}


## Un point du mur du fond, en coordonnées monde.
func wall_point(x: float, y: float) -> Vector3:
	return Vector3(x, y, WALL_Z)


## La taille **réellement projetée** de la dalle, en pixels de composition.
## Elle doit coller à `SCREEN_PIXELS` : tout écart est un facteur d'échelle
## appliqué au contenu des phases, c'est-à-dire du texte flou. Le banc UI
## l'asserte — c'est le seul garde-fou mécanique du critère de recette n°1,
## et il attrape ce qu'un relecteur ne peut pas voir.
func dalle_projected_size() -> Vector2:
	if _dalle == null or camera == null:
		return Vector2.ZERO
	var quad: QuadMesh = _dalle.mesh
	var half := Vector2(quad.size.x, quad.size.y) * 0.5
	var basis := _dalle.global_transform.basis
	var center := _dalle.global_position
	var left := project_to_design(center - basis.x * half.x)
	var right := project_to_design(center + basis.x * half.x)
	var top := project_to_design(center + basis.y * half.y)
	var bottom := project_to_design(center - basis.y * half.y)
	return Vector2(absf(right.x - left.x), absf(bottom.y - top.y))


func _on_dalle_input(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3, _index: int) -> void:
	route_to_viewport(_dalle, screen_viewport, event, event_position)


## Un quad texturé par un `SubViewport` ne reçoit **rien** : le clic s'arrête
## sur l'`Area3D` du monde 3D et n'entre jamais dans l'UI qui vit dedans. Sans
## ce transfert, les applications du poste de travail seraient un décor.
static func route_to_viewport(quad_node: MeshInstance3D, viewport: SubViewport, event: InputEvent, event_position: Vector3) -> void:
	if viewport == null or quad_node == null or not (event is InputEventMouse):
		return
	var quad: QuadMesh = quad_node.mesh
	var local: Vector3 = quad_node.global_transform.affine_inverse() * event_position
	var uv := Vector2((local.x / quad.size.x) + 0.5, 0.5 - (local.y / quad.size.y))
	var routed: InputEvent = event.duplicate()
	routed.position = uv * Vector2(viewport.size)
	if routed is InputEventMouseMotion:
		routed.relative = Vector2.ZERO
	viewport.push_input(routed, true)


func _box(at: Vector3, box_size: Vector3, color: Color, outlined: bool = true) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	node.mesh = mesh
	node.position = at
	node.material_override = toon_material(color)
	add_child(node)
	if outlined:
		outline_at(node, at)
	return node


func _material(color: Color) -> StandardMaterial3D:
	return toon_material(color)


# ── Le parti pris de rendu : dessiné, pas photographié ───────────────────
## Un dégradé continu sur une boîte, c'est une image de synthèse ; deux aplats
## séparés par une arête franche, c'est un objet de jeu. `DIFFUSE_TOON` coupe
## le dégradé en bandes, la rugosité à 1 supprime le reflet spéculaire qui
## trahissait la primitive, et la couleur peut redevenir franche — un bois
## réaliste est terne, un bois de jeu ne l'est pas.
##
## C'est volontairement le **minimum** : le lot d'habillage reste à faire, et
## il apportera de la matière, pas seulement une façon d'éclairer.
static func toon_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	return material


## Le trait de contour, par coque inversée : une copie du maillage, grossie le
## long de ses normales, peinte en encre unie et rendue **face arrière
## seulement**. Elle dépasse partout où la silhouette se détache, et nulle part
## ailleurs.
##
## Pourquoi cette technique et pas un filtre de contour en post-traitement :
## `gl_compatibility` n'a pas de tampon de profondeur exploitable en
## post-process, et le projet reste sur ce renderer (décision du 05/08). La
## coque inversée, elle, ne dépend d'aucune fonctionnalité de renderer.
##
## Deux règles pour ne pas s'y brûler : ne jamais l'appliquer à un nœud dont on
## anime la `scale` (le trait grossirait avec lui), et couper l'ombre — une
## coque grossie projette une ombre plus grosse que l'objet.
## Le même trait, déclaré en pixels de composition et converti à la profondeur
## de l'objet. C'est la forme à utiliser : la variante en unités monde ne sert
## qu'aux nœuds dont la profondeur n'est pas encore connue à la construction.
func outline_at(target: MeshInstance3D, at: Vector3, pixels: float = OUTLINE_PIXELS) -> MeshInstance3D:
	return add_outline(target, pixels / design_pixels_per_unit_at(at))


static func add_outline(target: MeshInstance3D, thickness: float) -> MeshInstance3D:
	var outline := MeshInstance3D.new()
	outline.name = "Outline"
	outline.mesh = target.mesh
	var ink := StandardMaterial3D.new()
	ink.albedo_color = INK
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.cull_mode = BaseMaterial3D.CULL_FRONT
	ink.grow = true
	ink.grow_amount = thickness
	outline.material_override = ink
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	target.add_child(outline)
	return outline
