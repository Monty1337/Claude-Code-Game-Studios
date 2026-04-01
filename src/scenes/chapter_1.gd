## Chapter 1: Der Morgen Danach (The Morning After)
## The player wakes up in the Altstadt, discovers their costume is stuck,
## and must solve 3 puzzles to weaken the curse.
## See: Game Concept, Chapter Structure, all system GDDs
extends Node3D

var _player: PlayerController
var _puzzle_controller: PuzzleController
var _costume_chosen := false


func _ready() -> void:
	_build_environment()
	_build_player()
	_build_lighting()
	_build_ui()
	_build_puzzle_system()

	# Feedback controller for particles/effects
	var feedback := FeedbackController.new()
	add_child(feedback)

	# Show costume selection first
	_show_costume_selection()


# -- Costume Selection --

func _show_costume_selection() -> void:
	var select_ui := CostumeSelectUI.new()
	select_ui.costume_selected.connect(_on_costume_selected)
	add_child(select_ui)


func _on_costume_selected(costume_id: StringName) -> void:
	_costume_chosen = true
	var data := CostumeManager.get_costume_data(costume_id)
	EventBus.show_message.emit(
		"You look down... you're dressed as " + data.get("display_name", str(costume_id)) + "!\n" +
		"And it won't come off...\n" +
		"Alaaf! Time to figure out what happened.",
		4.0
	)
	# Now spawn the NPCs and items (after costume is chosen)
	await get_tree().create_timer(0.5).timeout
	_build_npcs()
	_build_items()


# -- Environment --

func _build_environment() -> void:
	# Ground — large cobblestone plaza
	_box(Vector3(0, -0.05, 0), Vector3(50, 0.1, 50), Color(0.6, 0.55, 0.5))

	# -- Perimeter walls --
	_box(Vector3(0, 2, -25), Vector3(50, 4, 0.5), Color(0.85, 0.75, 0.6))
	_box(Vector3(0, 2, 25), Vector3(50, 4, 0.5), Color(0.8, 0.7, 0.55))
	_box(Vector3(-25, 2, 0), Vector3(0.5, 4, 50), Color(0.9, 0.8, 0.65))
	_box(Vector3(25, 2, 0), Vector3(0.5, 4, 50), Color(0.82, 0.72, 0.58))

	# -- Buildings --
	# Red Fachwerk house (apartment — where you wake up)
	_box(Vector3(-10, 3, -15), Vector3(8, 6, 6), Color(0.85, 0.25, 0.2))
	# Blue building (Büdchen / kiosk)
	_box(Vector3(12, 1.5, -12), Vector3(5, 3, 4), Color(0.3, 0.45, 0.85))
	# Yellow building
	_box(Vector3(15, 2, 8), Vector3(6, 4, 5), Color(0.9, 0.8, 0.2))
	# Green building
	_box(Vector3(-12, 2.5, 12), Vector3(7, 5, 5), Color(0.3, 0.7, 0.35))
	# Small brown shed
	_box(Vector3(-5, 1, 18), Vector3(3, 2, 3), Color(0.5, 0.35, 0.2))

	# -- Fountain (center of the Platz) --
	var fountain := StaticBody3D.new()
	var cyl_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.5
	cyl.bottom_radius = 2.5
	cyl.height = 0.8
	cyl_mesh.mesh = cyl
	var cyl_mat := StandardMaterial3D.new()
	cyl_mat.albedo_color = Color(0.7, 0.7, 0.75)
	cyl_mesh.material_override = cyl_mat
	fountain.add_child(cyl_mesh)
	var cyl_col := CollisionShape3D.new()
	cyl_col.shape = CylinderShape3D.new()
	cyl_col.shape.radius = 2.5
	cyl_col.shape.height = 0.8
	fountain.add_child(cyl_col)
	fountain.position = Vector3(0, 0.4, 0)
	add_child(fountain)

	# Narrenstatue pillar on fountain
	_box(Vector3(0, 1.2, 0), Vector3(0.6, 0.8, 0.6), Color(0.65, 0.65, 0.7))

	# Benches
	_box(Vector3(-5, 0.35, 5), Vector3(2.5, 0.7, 0.6), Color(0.5, 0.35, 0.2))
	_box(Vector3(5, 0.35, 5), Vector3(2.5, 0.7, 0.6), Color(0.5, 0.35, 0.2))

	# Navigation mesh for NPC pathfinding
	var nav_region := NavigationRegion3D.new()
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_radius = 0.4
	nav_mesh.agent_height = 1.8
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.1
	nav_region.navigation_mesh = nav_mesh
	add_child(nav_region)
	# Bake after scene is built (deferred so all geometry exists)
	nav_region.call_deferred("bake_navigation_mesh")

	# Steps near buildings
	_box(Vector3(-10, 0.15, -11.5), Vector3(4, 0.3, 1), Color(0.65, 0.6, 0.55))
	_box(Vector3(12, 0.15, -9.5), Vector3(3, 0.3, 1), Color(0.65, 0.6, 0.55))


func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
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
	_player.position = Vector3(-8, 0.9, -11)  # Near the apartment
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

	# Camera
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


# -- NPCs (spawned after costume selection) --

func _build_npcs() -> void:
	# Story NPC 1: Der Köbes (hints about Puzzle 1) — patrols near fountain
	_add_patrolling_npc(
		Vector3(-3, 0.9, 2), &"koebes", "Der Köbes",
		_make_koebes_dialogue(),
		[Vector3(-3, 0.9, 2), Vector3(2, 0.9, 4), Vector3(3, 0.9, -1), Vector3(-2, 0.9, -2)],
		Color(0.1, 0.1, 0.6)
	)

	# Story NPC 2: Die Blumenmarie (hints about Puzzle 2) — near Büdchen
	_add_patrolling_npc(
		Vector3(8, 0.9, -8), &"blumenmarie", "Die Blumenmarie",
		_make_blumenmarie_dialogue(),
		[Vector3(8, 0.9, -8), Vector3(10, 0.9, -6), Vector3(12, 0.9, -9)],
		Color(0.85, 0.4, 0.6)
	)

	# Story NPC 3: Der Büttenredner (involved in Puzzle 3) — near green building
	_add_patrolling_npc(
		Vector3(-8, 0.9, 10), &"buettenredner", "Der Büttenredner",
		_make_buettenredner_dialogue(),
		[Vector3(-8, 0.9, 10), Vector3(-6, 0.9, 12), Vector3(-10, 0.9, 14), Vector3(-10, 0.9, 10)],
		Color(0.8, 0.2, 0.2)
	)

	# Crowd NPCs (simple, no dialogue trees)
	_add_simple_npc(Vector3(5, 0.9, 12), &"crowd_1", "Verwirrter Tourist",
		["Alaaf! ...oder heißt dat Helau?", "I just wanted to visit the Dom...", "Why can't I take this hat off?!"],
		Color(0.6, 0.6, 0.3))
	_add_simple_npc(Vector3(-15, 0.9, 5), &"crowd_2", "Tanzende Funkenmariechen",
		["*tanzt ununterbrochen*", "My legs... won't... stop!", "Alaaf! *dreht Pirouette*"],
		Color(1.0, 1.0, 1.0))
	_add_simple_npc(Vector3(18, 0.9, 2), &"crowd_3", "Schlafender Jeck",
		["*schnarcht*", "Zzz... noch ein Kölsch... zzz...", "*murmelt* Alaaf..."],
		Color(0.4, 0.5, 0.3))


func _add_patrolling_npc(pos: Vector3, id: StringName, npc_name: String,
		tree: DialogueTree, patrol_points: Array[Vector3], body_color: Color) -> void:
	var npc := CharacterBody3D.new()
	npc.set_script(preload("res://entities/interactable/patrolling_npc.gd"))
	npc.npc_id = id
	npc.npc_name = npc_name
	npc.dialogue_tree = tree
	npc.waypoints = patrol_points
	npc.position = pos
	npc.collision_layer = 2  # Interactable
	npc.collision_mask = 1   # Environment
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


func _add_npc_visuals(npc: StaticBody3D, body_color: Color) -> void:
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


# -- Items (spawned after costume selection) --

func _build_items() -> void:
	# Puzzle 1 item: Goldener Orden
	_add_item(Vector3(14, 0.5, -5), &"golden_orden", "Goldener Orden",
		"A shiny golden Orden with the Dreigestirn emblem.\nSomeone must be missing this!",
		Color(1, 0.84, 0), true)

	# Puzzle 2 item: Strüßjer (flowers)
	_add_item(Vector3(-14, 0.5, -8), &"struessjer", "Strüßjer",
		"A bouquet of Karneval flowers — Strüßjer!\nTraditionally thrown from parade floats.",
		Color(0.9, 0.3, 0.5), true)

	# Puzzle 3 item: Narrenkappe
	_add_item(Vector3(5, 0.5, 18), &"narrenkappe", "Narrenkappe",
		"A classic jester's cap with bells.\nIt jingles when you shake it.",
		Color(1, 0.9, 0.1), true)

	# Flavor items
	_add_item(Vector3(-18, 0.5, 15), &"koelsch_glass", "Kölschglas",
		"A Kölsch Stange — still half full.\nOr is it half empty? Definitely sticky.",
		Color(0.9, 0.85, 0.3), false)
	_add_item(Vector3(20, 0.5, 15), &"kamelle", "Tüte Kamelle",
		"A bag of Karneval candy!\nMostly Gummibärchen and Schokolade.",
		Color(0.8, 0.4, 0.1), false)


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


# -- Puzzle Targets --

func _build_puzzle_system() -> void:
	_puzzle_controller = PuzzleController.new()
	_puzzle_controller.curse_delta_per_puzzle = 0.33

	# Puzzle 1: Place the Orden on the Narrenstatue
	var p1 := PuzzleResource.new()
	p1.puzzle_id = &"orden_puzzle"
	p1.display_name = "Der verlorene Orden"
	p1.chapter = 1
	p1.completion_message = "ALAAF! The Orden fits on the statue!\nThe fountain starts to glow... the curse weakens!"
	var p1_step := PuzzleStep.new()
	p1_step.step_type = PuzzleStep.StepType.USE_ITEM
	p1_step.item_id = &"golden_orden"
	p1_step.target_id = &"narrenstatue"
	p1_step.description = "Place the golden Orden on the Narrenstatue"
	p1.steps = [p1_step]
	_puzzle_controller.puzzles.append(p1)

	# Puzzle 2: Bring Strüßjer to the Blumenmarie
	var p2 := PuzzleResource.new()
	p2.puzzle_id = &"struessjer_puzzle"
	p2.display_name = "Die traurige Blumenmarie"
	p2.chapter = 1
	p2.completion_message = "The Blumenmarie starts dancing again!\nAnother piece of the curse lifts!"
	var p2_step := PuzzleStep.new()
	p2_step.step_type = PuzzleStep.StepType.USE_ITEM
	p2_step.item_id = &"struessjer"
	p2_step.target_id = &"blumenmarie_stand"
	p2_step.description = "Bring the Strüßjer to the Blumenmarie's stand"
	p2.steps = [p2_step]
	_puzzle_controller.puzzles.append(p2)

	# Puzzle 3: Give the Narrenkappe to the Büttenredner (requires talking first)
	var p3 := PuzzleResource.new()
	p3.puzzle_id = &"buettenrede_puzzle"
	p3.display_name = "Die verstummte Büttenrede"
	p3.chapter = 1
	p3.completion_message = "The Büttenredner puts on the Kappe and starts his Rede!\n'Alaaf! Dreimol Alaaf!'\nThe last piece of the curse shatters!"
	p3.reward_type = PuzzleResource.RewardType.CHAPTER_COMPLETE
	var p3_step1 := PuzzleStep.new()
	p3_step1.step_type = PuzzleStep.StepType.TALK_TO_NPC
	p3_step1.npc_id = &"buettenredner"
	p3_step1.dialogue_flag = &"buettenredner_needs_kappe"
	p3_step1.description = "Talk to the Büttenredner to learn what he needs"
	var p3_step2 := PuzzleStep.new()
	p3_step2.step_type = PuzzleStep.StepType.USE_ITEM
	p3_step2.item_id = &"narrenkappe"
	p3_step2.target_id = &"buettenredner_podium"
	p3_step2.description = "Bring the Narrenkappe to the Büttenredner's podium"
	p3.steps = [p3_step1, p3_step2]
	_puzzle_controller.puzzles.append(p3)

	add_child(_puzzle_controller)

	# Hint manager
	var hints := HintManager.new()
	hints.hint_delay = 120.0  # 2 min for first hint
	hints.hint_repeat = 90.0  # 1.5 min between hints
	hints.puzzle_hints = {
		&"orden_puzzle": [
			"I heard someone dropped something shiny near the blue building...",
			"The Köbes mentioned something about a golden Orden and the Narrenstatue.",
			"Find the golden Orden near the Büdchen and place it on the fountain statue!",
		],
		&"struessjer_puzzle": [
			"The Blumenmarie seems sad... she lost something.",
			"There are flowers scattered near the back walls of the Altstadt.",
			"Find the Strüßjer near the back wall and bring them to the Blumenmarie's stand!",
		],
		&"buettenrede_puzzle": [
			"The Büttenredner keeps pacing... he's missing something important.",
			"Talk to the Büttenredner — he'll tell you what he needs.",
			"The Narrenkappe blew behind the brown shed. Bring it to the Redner's podium!",
		],
	}
	var active_ids: Array[StringName] = [&"orden_puzzle", &"struessjer_puzzle", &"buettenrede_puzzle"]
	hints.set_active_puzzles(active_ids)
	add_child(hints)

	# Puzzle targets in the world
	_add_puzzle_target(
		Vector3(0, 1.8, 0), &"narrenstatue", "Narrenstatue",
		&"golden_orden",
		"ALAAF! The Orden clicks into place!",
		"Hmm, dat passt nit... the statue needs something shiny.",
		Color(0.65, 0.65, 0.7)
	)
	_add_puzzle_target(
		Vector3(10, 0.6, -10), &"blumenmarie_stand", "Blumen-Stand",
		&"struessjer",
		"The flowers brighten up the stand instantly!",
		"This stand needs flowers, not that...",
		Color(0.7, 0.5, 0.3)
	)
	_add_puzzle_target(
		Vector3(-7, 0.6, 12), &"buettenredner_podium", "Redner-Podium",
		&"narrenkappe",
		"The Kappe lands perfectly on the podium!",
		"The podium needs something for the Redner's head...",
		Color(0.6, 0.3, 0.3)
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
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	mesh.mesh = box
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

func _make_koebes_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()
	tree.dialogue_id = &"koebes_main"

	var n0 := DialogueData.new()
	n0.speaker_name = "Der Köbes"
	n0.default_text = "Alaaf! I can't stop carrying Kölsch!"
	n0.costume_variants = {
		&"boastful": "Arrr! Another cursed soul! I can't stop carrying Kölsch, ye landlubber!",
		&"mischievous": "Alaaf! *honk* Hey, you're stuck too? I can't stop carrying Kölsch!",
	}
	tree.nodes.append(n0)

	var n1 := DialogueData.new()
	n1.speaker_name = "Der Köbes"
	n1.default_text = "This curse hit everyone after Rosenmontag.\nNobody can take their costume off!"
	tree.nodes.append(n1)

	var n2 := DialogueData.new()
	n2.speaker_name = "Der Köbes"
	n2.default_text = "I heard the Prinz lost his golden Orden\nsomewhere near the blue Büdchen.\nMaybe putting it on the Narrenstatue will help?"
	n2.costume_variants = {
		&"boastful": "Arrr, the Prinz lost his golden Orden!\nIt be near the blue Büdchen, savvy?\nPlace it on the Narrenstatue, ye scallywag!",
		&"mischievous": "Psst! *leans in* The Prinz dropped his Orden!\nI saw it roll toward the blue Büdchen.\nTry sticking it on the Narrenstatue! *wink*",
	}
	tree.nodes.append(n2)

	var n3 := DialogueData.new()
	n3.speaker_name = "Der Köbes"
	n3.default_text = "Good luck! And if you find a free Kölsch,\ndon't bring it to me — I already have 47."
	tree.nodes.append(n3)

	return tree


func _make_blumenmarie_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()
	tree.dialogue_id = &"blumenmarie_main"

	var n0 := DialogueData.new()
	n0.speaker_name = "Die Blumenmarie"
	n0.default_text = "*sniff* All my Strüßjer are gone!\nMy flower stand is completely empty..."
	n0.costume_variants = {
		&"boastful": "*sniff* Ahoy, Pirat! My Strüßjer are all gone!\nMy stand is as empty as the seven seas!",
		&"mischievous": "*sniff* Oh, a Clown... I could use a laugh.\nAll my Strüßjer are gone! My stand is bare!",
	}
	tree.nodes.append(n0)

	var n1 := DialogueData.new()
	n1.speaker_name = "Die Blumenmarie"
	n1.default_text = "I think some Strüßjer blew away in the wind.\nThey might have landed near the back walls.\nIf you find some, please bring them back!"
	tree.nodes.append(n1)

	return tree


func _make_buettenredner_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()
	tree.dialogue_id = &"buettenredner_main"

	var n0 := DialogueData.new()
	n0.speaker_name = "Der Büttenredner"
	n0.default_text = "I'm supposed to give my Büttenrede...\nbut I lost my Narrenkappe!"
	n0.costume_variants = {
		&"boastful": "Arrr, help a fellow performer!\nI can't give me Büttenrede without me Narrenkappe!",
		&"mischievous": "*sad trombone* I lost my Narrenkappe!\nNo Kappe, no Rede, no laughs. Help?",
	}
	# This node sets the puzzle flag so the puzzle system knows we talked
	n0.set_flag = &"buettenredner_needs_kappe"
	n0.set_flag_value = true
	tree.nodes.append(n0)

	var n1 := DialogueData.new()
	n1.speaker_name = "Der Büttenredner"
	n1.default_text = "I think my Narrenkappe flew off toward\nthe brown shed behind the green building.\nPlease find it and put it on my podium!"
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
	sun.rotation_degrees = Vector3(-40, 25, 0)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)

	var env := CurseEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.45, 0.5, 0.6)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.75, 0.85)
	environment.ambient_light_energy = 0.8
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.5, 0.5, 0.55)
	environment.fog_density = 0.04
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.4
	env.environment = environment
	add_child(env)
