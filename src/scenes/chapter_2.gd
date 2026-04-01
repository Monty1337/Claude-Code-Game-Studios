## Chapter 2: Dat Brauhaus (The Brewery)
## The player investigates the Brauhaus district to find clues about the curse.
## Puzzles involve beer-tasting, recipe reconstruction, and Kölsch traditions.
## See: Game Concept, Chapter Structure
extends Node3D

var _player: PlayerController
var _puzzle_controller: PuzzleController


func _ready() -> void:
	_build_environment()
	_build_player()
	_build_lighting()
	_build_ui()
	_build_puzzle_system()
	_build_npcs()
	_build_items()

	var feedback := FeedbackController.new()
	add_child(feedback)

	EventBus.chapter_completed.connect(_on_chapter_completed)

	EventBus.show_message.emit(
		"Kapitel 2: Dat Brauhaus\n\n" +
		"The Brauhaus district... the curse is thick here.\n" +
		"Time to investigate!",
		4.0
	)


# -- Environment --

func _build_environment() -> void:
	# Ground
	_box(Vector3(0, -0.05, 0), Vector3(60, 0.1, 60), Color(0.55, 0.5, 0.45))

	# Perimeter walls (narrow streets feel)
	_box(Vector3(0, 2.5, -30), Vector3(60, 5, 0.5), Color(0.8, 0.7, 0.55))
	_box(Vector3(0, 2.5, 30), Vector3(60, 5, 0.5), Color(0.75, 0.65, 0.5))
	_box(Vector3(-30, 2.5, 0), Vector3(0.5, 5, 60), Color(0.85, 0.75, 0.6))
	_box(Vector3(30, 2.5, 0), Vector3(0.5, 5, 60), Color(0.78, 0.68, 0.55))

	# -- The Brauhaus (main building, center-left) --
	# Front wall with door gap (3m wide opening in center)
	_box(Vector3(-14, 3, -5), Vector3(4, 6, 0.5), Color(0.7, 0.4, 0.2))   # Left of door
	_box(Vector3(-6, 3, -5), Vector3(4, 6, 0.5), Color(0.7, 0.4, 0.2))    # Right of door
	_box(Vector3(-10, 5.2, -5), Vector3(4, 1.4, 0.5), Color(0.6, 0.35, 0.15))  # Above door
	# Side walls
	_box(Vector3(-16, 3, -10), Vector3(0.5, 6, 10), Color(0.65, 0.38, 0.18))
	_box(Vector3(-4, 3, -10), Vector3(0.5, 6, 10), Color(0.65, 0.38, 0.18))
	# Back wall
	_box(Vector3(-10, 3, -15), Vector3(12, 6, 0.5), Color(0.6, 0.35, 0.15))
	# Interior floor (slightly raised)
	_box(Vector3(-10, 0.05, -10), Vector3(11.5, 0.1, 9.5), Color(0.5, 0.35, 0.2))
	# Bar counter
	_box(Vector3(-10, 0.6, -13), Vector3(8, 1.2, 1), Color(0.4, 0.25, 0.12))
	# Tables
	_box(Vector3(-13, 0.45, -8), Vector3(1.5, 0.9, 1.5), Color(0.45, 0.3, 0.15))
	_box(Vector3(-7, 0.45, -8), Vector3(1.5, 0.9, 1.5), Color(0.45, 0.3, 0.15))
	_box(Vector3(-10, 0.45, -8), Vector3(1.5, 0.9, 1.5), Color(0.45, 0.3, 0.15))

	# -- Cellar entrance (behind Brauhaus) --
	_box(Vector3(-10, 0.75, -18), Vector3(4, 1.5, 3), Color(0.4, 0.35, 0.3))  # Cellar structure
	_box(Vector3(-10, -0.5, -20), Vector3(3, 1, 2), Color(0.3, 0.25, 0.2))  # Stairs down

	# -- Street buildings --
	_box(Vector3(10, 3, -15), Vector3(8, 6, 6), Color(0.9, 0.85, 0.6))   # Yellow house
	_box(Vector3(20, 2.5, -8), Vector3(6, 5, 5), Color(0.3, 0.5, 0.8))   # Blue house
	_box(Vector3(15, 2, 10), Vector3(7, 4, 5), Color(0.85, 0.3, 0.3))    # Red house
	_box(Vector3(-20, 2, 15), Vector3(6, 4, 6), Color(0.4, 0.7, 0.4))    # Green house
	_box(Vector3(5, 1.5, 20), Vector3(5, 3, 4), Color(0.9, 0.8, 0.3))    # Small yellow
	_box(Vector3(-5, 1, 25), Vector3(3, 2, 3), Color(0.5, 0.4, 0.3))     # Storage shed

	# -- Street furniture --
	# Barrels outside Brauhaus
	var barrel := StaticBody3D.new()
	var barrel_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.4
	cyl.height = 0.8
	barrel_mesh.mesh = cyl
	var barrel_mat := StandardMaterial3D.new()
	barrel_mat.albedo_color = Color(0.45, 0.3, 0.15)
	barrel_mesh.material_override = barrel_mat
	barrel.add_child(barrel_mesh)
	var barrel_col := CollisionShape3D.new()
	barrel_col.shape = CylinderShape3D.new()
	barrel_col.shape.radius = 0.4
	barrel_col.shape.height = 0.8
	barrel.add_child(barrel_col)
	barrel.position = Vector3(-3, 0.4, -3)
	add_child(barrel)

	# Benches
	_box(Vector3(0, 0.35, 5), Vector3(2.5, 0.7, 0.6), Color(0.5, 0.35, 0.2))
	_box(Vector3(10, 0.35, 5), Vector3(2.5, 0.7, 0.6), Color(0.5, 0.35, 0.2))

	# Lamppost placeholder
	_box(Vector3(5, 2, 0), Vector3(0.2, 4, 0.2), Color(0.3, 0.3, 0.3))
	_box(Vector3(-15, 2, 5), Vector3(0.2, 4, 0.2), Color(0.3, 0.3, 0.3))


func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = size
	mesh.mesh = bx
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = size
	body.add_child(col)
	body.position = pos
	add_child(body)


# -- Player --

func _build_player() -> void:
	_player = PlayerController.new()
	_player.position = Vector3(0, 0.9, 10)
	_player.collision_layer = 4
	_player.collision_mask = 1

	var col := CollisionShape3D.new()
	col.shape = CapsuleShape3D.new()
	col.shape.radius = 0.3
	col.shape.height = 1.8
	_player.add_child(col)

	var area := Area3D.new()
	area.name = "InteractArea"
	area.collision_layer = 0
	area.collision_mask = 2
	var area_col := CollisionShape3D.new()
	area_col.shape = SphereShape3D.new()
	area_col.shape.radius = _player.interact_radius
	area.add_child(area_col)
	_player.add_child(area)

	add_child(_player)

	var pivot := Node3D.new()
	pivot.position = _player.position + Vector3(0, 1.6, 0)
	add_child(pivot)

	var cam := Camera3D.new()
	cam.current = true
	pivot.add_child(cam)

	var ray := RayCast3D.new()
	ray.target_position = Vector3(0, 0, -_player.interact_radius)
	ray.collision_mask = 2
	cam.add_child(ray)

	_player.camera_pivot = pivot
	_player.camera = cam
	_player.interact_ray = ray
	_player.interact_area = area


# -- NPCs --

func _build_npcs() -> void:
	# Story NPC 1: Der Braumeister
	_add_patrolling_npc(
		Vector3(-10, 0.9, -12), &"braumeister", "Der Braumeister",
		_make_braumeister_dialogue(),
		[Vector3(-10, 0.9, -12), Vector3(-13, 0.9, -10), Vector3(-7, 0.9, -10)],
		Color(0.6, 0.35, 0.1)
	)

	# Story NPC 2: Die Wirtin
	_add_patrolling_npc(
		Vector3(-10, 0.9, -8), &"wirtin", "Die Wirtin",
		_make_wirtin_dialogue(),
		[Vector3(-10, 0.9, -8), Vector3(-8, 0.9, -6), Vector3(-12, 0.9, -7)],
		Color(0.8, 0.5, 0.3)
	)

	# Story NPC 3: Der Stammgast
	_add_patrolling_npc(
		Vector3(-7, 0.9, -8), &"stammgast", "Der Stammgast",
		_make_stammgast_dialogue(),
		[Vector3(-7, 0.9, -8), Vector3(-5, 0.9, -6), Vector3(-8, 0.9, -9)],
		Color(0.4, 0.5, 0.3)
	)

	# Crowd NPCs
	_add_simple_npc(Vector3(8, 0.9, -10), &"crowd_b1", "Bierkutscher",
		["*poliert sein Fass* Dat Kölsch is alle...", "Früher war mehr Kölsch!", "Die Brauerei steht still..."],
		Color(0.5, 0.4, 0.2))
	_add_simple_npc(Vector3(15, 0.9, 5), &"crowd_b2", "Kölsche Jung",
		["Alaaf! Wann gibt et wieder Kölsch?", "Ohne Kölsch is nix los!", "*singt* In unserem Veedel..."],
		Color(0.3, 0.4, 0.7))
	_add_simple_npc(Vector3(-20, 0.9, 10), &"crowd_b3", "Alte Marktfrau",
		["Dat hät et früher nit jejovve!", "Die Jugend von heute...", "*schüttelt den Kopf*"],
		Color(0.6, 0.5, 0.6))


func _add_patrolling_npc(pos: Vector3, id: StringName, npc_name: String,
		tree: DialogueTree, patrol_points: Array[Vector3], body_color: Color) -> void:
	var npc := CharacterBody3D.new()
	npc.set_script(preload("res://entities/interactable/patrolling_npc.gd"))
	npc.npc_id = id
	npc.npc_name = npc_name
	npc.dialogue_tree = tree
	npc.waypoints = patrol_points
	npc.position = pos
	npc.collision_layer = 2
	npc.collision_mask = 1
	_add_npc_visuals(npc, body_color)
	add_child(npc)


func _add_simple_npc(pos: Vector3, id: StringName, npc_name: String,
		lines: PackedStringArray, body_color: Color) -> void:
	var npc := StaticBody3D.new()
	npc.set_script(preload("res://entities/interactable/simple_npc.gd"))
	npc.npc_id = id
	npc.npc_name = npc_name
	npc.dialogue_lines = lines
	npc.position = pos
	_add_npc_visuals(npc, body_color)
	add_child(npc)


func _add_npc_visuals(npc: Node3D, body_color: Color) -> void:
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	body.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	body.material_override = mat
	npc.add_child(body)

	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	head.mesh = sphere
	head.position.y = 1.15
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.9, 0.75, 0.65)
	head.material_override = head_mat
	npc.add_child(head)

	var col := CollisionShape3D.new()
	col.shape = CapsuleShape3D.new()
	col.shape.radius = 0.35
	col.shape.height = 2.0
	npc.add_child(col)


# -- Items --

func _build_items() -> void:
	_add_item(Vector3(-10, 0.5, -20), &"geheimrezept", "Geheimes Rezept",
		"An old parchment with a Kölsch recipe.\nThe ink is faded but still readable...\n'3 Teile Malz, 1 Teil Hopfen, und ein Geheimnis...'",
		Color(0.9, 0.85, 0.7), true)

	_add_item(Vector3(18, 0.5, -5), &"bierhahn", "Goldener Bierhahn",
		"A golden tap handle shaped like a rooster.\nThe Brauhaus logo is engraved on it.",
		Color(0.85, 0.75, 0.2), true)

	_add_item(Vector3(-22, 0.5, 18), &"malzsack", "Sack voll Malz",
		"A heavy sack of brewing malt.\nSmells wonderful — like fresh bread!",
		Color(0.7, 0.6, 0.3), true)

	# Flavor
	_add_item(Vector3(12, 0.5, 15), &"bierdeckel", "Beschriebener Bierdeckel",
		"A Bierdeckel with something scribbled on it:\n'Der Braumeister weiß alles!'",
		Color(0.8, 0.75, 0.65), false)


func _add_item(pos: Vector3, id: StringName, item_name: String,
		desc: String, color: Color, key: bool) -> void:
	var item := StaticBody3D.new()
	item.set_script(preload("res://entities/interactable/pickup_item.gd"))
	item.item_id = id
	item.item_name = item_name
	item.item_description = desc
	item.is_key_item = key

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.3
	mesh.material_override = mat
	item.add_child(mesh)

	var col := CollisionShape3D.new()
	col.shape = SphereShape3D.new()
	col.shape.radius = 0.3
	item.add_child(col)
	item.position = pos
	add_child(item)


# -- Puzzles --

func _build_puzzle_system() -> void:
	_puzzle_controller = PuzzleController.new()
	_puzzle_controller.curse_delta_per_puzzle = 0.33

	# Puzzle 1: Find the secret recipe in the cellar, bring it to the Braumeister
	var p1 := PuzzleResource.new()
	p1.puzzle_id = &"rezept_puzzle"
	p1.display_name = "Das Geheimrezept"
	p1.chapter = 2
	p1.completion_message = "The Braumeister's eyes light up!\n'Dat is et! Das Geheimrezept!'\nThe first Kölsch starts flowing again!"
	var p1_step := PuzzleStep.new()
	p1_step.step_type = PuzzleStep.StepType.USE_ITEM
	p1_step.item_id = &"geheimrezept"
	p1_step.target_id = &"braukessel"
	p1_step.description = "Bring the secret recipe to the brewing kettle"
	p1.steps = [p1_step]
	_puzzle_controller.puzzles.append(p1)

	# Puzzle 2: Find the golden tap handle, place it on the bar
	var p2 := PuzzleResource.new()
	p2.puzzle_id = &"bierhahn_puzzle"
	p2.display_name = "Der goldene Hahn"
	p2.chapter = 2
	p2.completion_message = "The golden tap clicks into place!\nKölsch flows freely again!\nThe Wirtin cheers: 'Alaaf!'"
	var p2_step := PuzzleStep.new()
	p2_step.step_type = PuzzleStep.StepType.USE_ITEM
	p2_step.item_id = &"bierhahn"
	p2_step.target_id = &"zapfhahn"
	p2_step.description = "Place the golden tap handle on the bar"
	p2.steps = [p2_step]
	_puzzle_controller.puzzles.append(p2)

	# Puzzle 3: Talk to Stammgast, then bring malt to the cellar
	var p3 := PuzzleResource.new()
	p3.puzzle_id = &"brauen_puzzle"
	p3.display_name = "Dat Brauen"
	p3.chapter = 2
	p3.reward_type = PuzzleResource.RewardType.CHAPTER_COMPLETE
	p3.prerequisites = [&"rezept_puzzle", &"bierhahn_puzzle"]
	p3.completion_message = "The malt goes into the kettle!\nThe Brauhaus rumbles... the brewing begins!\n\n'ALAAF! Kölsch für alle!'\nThe curse shatters in the Brauhaus district!"
	var p3_step := PuzzleStep.new()
	p3_step.step_type = PuzzleStep.StepType.USE_ITEM
	p3_step.item_id = &"malzsack"
	p3_step.target_id = &"malztrichter"
	p3_step.description = "Pour the malt into the Malztrichter"
	p3.steps = [p3_step]
	_puzzle_controller.puzzles.append(p3)

	add_child(_puzzle_controller)

	# Hints
	var hints := HintManager.new()
	hints.hint_delay = 30.0
	hints.hint_repeat = 30.0
	hints.puzzle_hints = {
		&"rezept_puzzle": [
			"The Braumeister keeps mumbling about a lost recipe...",
			"There's a cellar behind the Brauhaus. Maybe something's down there?",
			"Find the Geheimrezept in the cellar and bring it to the Braukessel!",
		],
		&"bierhahn_puzzle": [
			"The Wirtin says the tap is broken — the handle is missing...",
			"A golden handle was seen near the blue house on the east side.",
			"Find the Goldener Bierhahn near the blue house and put it on the Zapfhahn!",
		],
		&"brauen_puzzle": [
			"The recipe and tap are ready, but something else is needed to brew...",
			"The Stammgast might know what's missing. Talk to him!",
			"The Malzsack is near the green house. Bring it to the Braukessel!",
		],
	}
	var active_ids: Array[StringName] = [&"rezept_puzzle", &"bierhahn_puzzle", &"brauen_puzzle"]
	hints.set_active_puzzles(active_ids)
	add_child(hints)

	# Puzzle targets
	_add_puzzle_target(
		Vector3(-10, 0.6, -17), &"braukessel", "Braukessel",
		&"geheimrezept", "The recipe goes into the kettle!", "The kettle needs something else...",
		Color(0.5, 0.45, 0.4)
	)
	_add_puzzle_target(
		Vector3(-8, 0.9, -13), &"zapfhahn", "Zapfhahn",
		&"bierhahn", "Click! The tap is restored!", "This needs a specific handle...",
		Color(0.7, 0.6, 0.3)
	)
	_add_puzzle_target(
		Vector3(-12, 0.6, -17), &"malztrichter", "Malztrichter",
		&"malzsack", "The malt pours into the kettle!", "This funnel needs malt...",
		Color(0.6, 0.5, 0.35)
	)


func _add_puzzle_target(pos: Vector3, id: StringName, target_name: String,
		req_item: StringName, success: String, wrong: String, color: Color) -> void:
	var target := StaticBody3D.new()
	target.set_script(preload("res://entities/interactable/puzzle_target.gd"))
	target.target_id = id
	target.target_name = target_name
	target.required_item = req_item
	target.success_message = success
	target.wrong_message = wrong

	var mesh := MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var bx := BoxMesh.new()
	bx.size = Vector3(0.5, 0.5, 0.5)
	mesh.mesh = bx
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	target.add_child(mesh)

	var col := CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(0.6, 0.6, 0.6)
	target.add_child(col)
	target.position = pos
	add_child(target)


# -- Dialogue Trees --

func _make_braumeister_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()
	tree.dialogue_id = &"braumeister_main"

	var n0 := DialogueData.new()
	n0.speaker_name = "Der Braumeister"
	n0.default_text = "Dat Brauhaus steht still!\nI can't brew without my Geheimrezept!"
	n0.costume_variants = {
		&"boastful": "Arrr! The brewery is dead in the water!\nI need me secret recipe back, ye hear?!",
		&"mischievous": "*sad honk* The Brauhaus is silent!\nNo recipe, no Kölsch, no fun!",
		&"chivalrous": "The Brauhaus lies dormant, good knight!\nMy sacred recipe has vanished from the cellar!",
		&"theatrical": "*dramatic gasp* The brewing cauldron is COLD!\nThe recipe... STOLEN by dark forces!",
	}
	tree.nodes.append(n0)

	var n1 := DialogueData.new()
	n1.speaker_name = "Der Braumeister"
	n1.default_text = "Check the cellar behind the Brauhaus.\nMaybe the recipe fell down there\nwhen the curse hit."
	tree.nodes.append(n1)
	return tree


func _make_wirtin_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()
	tree.dialogue_id = &"wirtin_main"

	var n0 := DialogueData.new()
	n0.speaker_name = "Die Wirtin"
	n0.default_text = "Kein Kölsch! Der Zapfhahn ist kaputt!\nThe golden tap handle just... disappeared!"
	n0.costume_variants = {
		&"boastful": "Arrr! No Kölsch for any of us!\nThe golden tap handle vanished, ye bilge rat!",
		&"mischievous": "*fake tears* No Kölsch! THE HORROR!\nThe tap handle is gone... *honk*",
		&"chivalrous": "My lady's tap is broken, noble knight!\nThe golden handle was taken — a grievous theft!",
		&"theatrical": "The tap... is SILENT! *clutches bar*\nThe golden handle was taken by the curse itself!",
	}
	tree.nodes.append(n0)

	var n1 := DialogueData.new()
	n1.speaker_name = "Die Wirtin"
	n1.default_text = "I think it rolled toward the blue house\non the east side of the street.\nBring it back and put it on the Zapfhahn!"
	tree.nodes.append(n1)
	return tree


func _make_stammgast_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()
	tree.dialogue_id = &"stammgast_main"

	var n0 := DialogueData.new()
	n0.speaker_name = "Der Stammgast"
	n0.default_text = "Ich sitz hier seit drei Tagen...\nund kein einziges Kölsch!"
	n0.costume_variants = {
		&"boastful": "Arrr, matey! Three days without Kölsch!\nThis be worse than scurvy!",
		&"mischievous": "*pokes empty glass* Three days! No Kölsch!\nThis is a crime against humanity! *honk*",
		&"chivalrous": "Three days I have stood vigil at this table,\nand not a single Kölsch has graced my lips!",
		&"theatrical": "Three days... *stares into empty glass*\n...an eternity of thirst... a desert of despair...",
	}
	n0.set_flag = &"stammgast_malz_hint"
	n0.set_flag_value = true
	tree.nodes.append(n0)

	var n1 := DialogueData.new()
	n1.speaker_name = "Der Stammgast"
	n1.default_text = "You know what the Braumeister needs?\nMalz! A whole sack of it!\nI think there's one near the green house."
	tree.nodes.append(n1)
	return tree


# -- UI --

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.set_script(preload("res://ui/game_ui.gd"))
	add_child(ui)


# -- Lighting --

func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -20, 0)
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	add_child(sun)

	var env := CurseEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.4, 0.45, 0.55)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.7, 0.7, 0.8)
	environment.ambient_light_energy = 0.7
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.45, 0.45, 0.5)
	environment.fog_density = 0.05
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.35
	env.environment = environment
	add_child(env)


func _on_chapter_completed(_chapter: int) -> void:
	EventBus.show_message.emit(
		"KAPITEL 2 GESCHAFFT!\n\n" +
		"The Brauhaus is brewing again!\n" +
		"Kölsch flows freely through the streets!\n\n" +
		"But the curse still grips the parade route...",
		0.0
	)
	await get_tree().create_timer(5.0).timeout
	GameState.set_chapter(3)
	SaveManager.save_game()
	SceneManager.load_scene("res://scenes/chapter_3.tscn")
