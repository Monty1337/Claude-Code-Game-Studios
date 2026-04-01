## Chapter 3: Der letzte Zoch (The Final Parade)
## The player must build a float, organize the parade, and perform the
## unmasking ritual to break the curse once and for all.
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
		"Kapitel 3: Der letzte Zoch\n\n" +
		"The parade route lies silent...\n" +
		"Time to get this Zoch moving — and break the curse for good!",
		4.0
	)


# -- Environment: Parade Route --

func _build_environment() -> void:
	# Ground — long parade route
	_box(Vector3(0, -0.05, 0), Vector3(30, 0.1, 80), Color(0.55, 0.52, 0.48))

	# Street walls (narrow parade route)
	_box(Vector3(-15, 3, 0), Vector3(0.5, 6, 80), Color(0.85, 0.75, 0.6))
	_box(Vector3(15, 3, 0), Vector3(0.5, 6, 80), Color(0.8, 0.7, 0.55))
	# End walls
	_box(Vector3(0, 3, -40), Vector3(30, 6, 0.5), Color(0.75, 0.65, 0.5))
	_box(Vector3(0, 3, 40), Vector3(30, 6, 0.5), Color(0.78, 0.68, 0.55))

	# -- Float Workshop (left side, near start) --
	_box(Vector3(-10, 2.5, 25), Vector3(8, 5, 8), Color(0.6, 0.45, 0.3))  # Main structure
	# Door opening
	_box(Vector3(-7.5, 2.5, 21), Vector3(3, 5, 0.5), Color(0.55, 0.4, 0.25))  # Left of door
	_box(Vector3(-12.5, 2.5, 21), Vector3(3, 5, 0.5), Color(0.55, 0.4, 0.25)) # Right of door
	_box(Vector3(-10, 4.5, 21), Vector3(2, 1, 0.5), Color(0.5, 0.38, 0.22))   # Above door
	# Workshop interior floor
	_box(Vector3(-10, 0.05, 25), Vector3(7.5, 0.1, 7.5), Color(0.5, 0.4, 0.3))
	# Workbench
	_box(Vector3(-10, 0.5, 28), Vector3(5, 1, 1.5), Color(0.45, 0.3, 0.15))

	# -- Stage / Bühne (center, far end of route) --
	_box(Vector3(0, 0.5, -30), Vector3(12, 1, 8), Color(0.6, 0.3, 0.3))   # Stage platform
	_box(Vector3(0, 2, -34), Vector3(12, 3, 0.5), Color(0.7, 0.35, 0.35)) # Stage backdrop
	# Stage steps
	_box(Vector3(0, 0.25, -25.5), Vector3(4, 0.5, 1), Color(0.55, 0.28, 0.28))

	# -- Parade route decorations --
	# Half-built float (center of route)
	_box(Vector3(0, 1, 10), Vector3(5, 2, 8), Color(0.8, 0.6, 0.2))     # Float base
	_box(Vector3(0, 2.5, 10), Vector3(3, 1, 4), Color(0.9, 0.3, 0.3))   # Float upper (incomplete)

	# Viewing stands (right side)
	_box(Vector3(10, 0.75, 0), Vector3(4, 1.5, 10), Color(0.5, 0.45, 0.4))
	_box(Vector3(10, 1.5, -15), Vector3(4, 1.5, 8), Color(0.5, 0.45, 0.4))

	# Lampposts with Girlanden placeholders
	_box(Vector3(-5, 2.5, 15), Vector3(0.15, 5, 0.15), Color(0.3, 0.3, 0.3))
	_box(Vector3(5, 2.5, 15), Vector3(0.15, 5, 0.15), Color(0.3, 0.3, 0.3))
	_box(Vector3(-5, 2.5, -5), Vector3(0.15, 5, 0.15), Color(0.3, 0.3, 0.3))
	_box(Vector3(5, 2.5, -5), Vector3(0.15, 5, 0.15), Color(0.3, 0.3, 0.3))

	# Scattered confetti piles (visual only, small colored boxes on ground)
	_box(Vector3(-3, 0.05, 5), Vector3(1.5, 0.1, 1), Color(1, 0.3, 0.3))
	_box(Vector3(4, 0.05, -10), Vector3(1, 0.1, 1.5), Color(0.3, 1, 0.3))
	_box(Vector3(-6, 0.05, -20), Vector3(1.2, 0.1, 0.8), Color(0.3, 0.3, 1))


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
	_player.position = Vector3(0, 0.9, 35)  # Start at parade route entrance
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
	# Story NPC 1: Der Wagenbauer (float builder)
	_add_patrolling_npc(
		Vector3(-10, 0.9, 25), &"wagenbauer", "Der Wagenbauer",
		_make_wagenbauer_dialogue(),
		[Vector3(-10, 0.9, 25), Vector3(-8, 0.9, 23), Vector3(-12, 0.9, 27)],
		Color(0.6, 0.4, 0.2)
	)

	# Story NPC 2: Die Zugleiterin (parade organizer)
	_add_patrolling_npc(
		Vector3(0, 0.9, 5), &"zugleiterin", "Die Zugleiterin",
		_make_zugleiterin_dialogue(),
		[Vector3(0, 0.9, 5), Vector3(3, 0.9, 0), Vector3(-3, 0.9, 8)],
		Color(0.8, 0.2, 0.5)
	)

	# Story NPC 3: Die Jungfrau (the Dreigestirn member)
	_add_patrolling_npc(
		Vector3(0, 1.4, -30), &"jungfrau", "Die Jungfrau",
		_make_jungfrau_dialogue(),
		[Vector3(-2, 1.4, -30), Vector3(2, 1.4, -30)],
		Color(1, 1, 1)
	)

	# Crowd NPCs
	_add_simple_npc(Vector3(8, 0.9, 20), &"crowd_z1", "Aufgeregtes Kind",
		["Wann kommt der Zoch?!", "Ich will Kamelle!", "Mama, guck mal, ein Pirat! ...oder Clown?"],
		Color(0.9, 0.7, 0.3))
	_add_simple_npc(Vector3(-8, 0.9, -10), &"crowd_z2", "Alter Karnevalist",
		["Dreimol Alaaf!", "Dat wor noch nie su schön...", "In 50 Jahren Karneval hab ich dat noch nie erlebt!"],
		Color(0.5, 0.5, 0.6))
	_add_simple_npc(Vector3(10, 0.9, -20), &"crowd_z3", "Kameramann",
		["*filmt alles*", "Dat gibt bestimmt klicks!", "Karneval Forever — der Film! *lacht*"],
		Color(0.3, 0.3, 0.3))


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
	# Puzzle 1: Float wheel
	_add_item(Vector3(12, 0.5, 30), &"wagenrad", "Wagenrad",
		"A big wooden wheel for a parade float.\nIt's surprisingly heavy!",
		Color(0.6, 0.4, 0.2), true)

	# Puzzle 2: Zugplakette (parade permit)
	_add_item(Vector3(-12, 0.5, -15), &"zugplakette", "Zugplakette",
		"The official parade permit — without this,\nno Zoch can roll!\nStamped with the Festkomitee seal.",
		Color(0.3, 0.5, 0.9), true)

	# Puzzle 3: Dreigestirn-Zepter
	_add_item(Vector3(8, 0.5, -35), &"zepter", "Dreigestirn-Zepter",
		"The ceremonial scepter of the Dreigestirn.\nIt sparkles with Karneval magic.\nThis is the key to the unmasking ritual!",
		Color(0.9, 0.7, 1.0), true)

	# Flavor
	_add_item(Vector3(-5, 0.5, 0), &"konfetti_kanone", "Konfetti-Kanone",
		"A confetti cannon! Still loaded!\n*resists urge to fire it*",
		Color(1, 0.5, 0.2), false)


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
	sphere.radius = 0.25
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.4
	mesh.material_override = mat
	item.add_child(mesh)

	var col := CollisionShape3D.new()
	col.shape = SphereShape3D.new()
	col.shape.radius = 0.35
	item.add_child(col)
	item.position = pos
	add_child(item)


# -- Puzzles --

func _build_puzzle_system() -> void:
	_puzzle_controller = PuzzleController.new()
	_puzzle_controller.curse_delta_per_puzzle = 0.33

	# Puzzle 1: Fix the float — bring the wheel to the workshop
	var p1 := PuzzleResource.new()
	p1.puzzle_id = &"float_puzzle"
	p1.display_name = "Der kaputte Wagen"
	p1.chapter = 3
	p1.completion_message = "The wheel clicks into place!\nThe parade float is ready to roll!\nAlaaf!"
	var p1_step := PuzzleStep.new()
	p1_step.step_type = PuzzleStep.StepType.USE_ITEM
	p1_step.item_id = &"wagenrad"
	p1_step.target_id = &"float_axle"
	p1_step.description = "Attach the wheel to the float"
	p1.steps = [p1_step]
	_puzzle_controller.puzzles.append(p1)

	# Puzzle 2: Get the parade permit — bring it to the Zugleiterin's podium
	var p2 := PuzzleResource.new()
	p2.puzzle_id = &"permit_puzzle"
	p2.display_name = "Die Zugplakette"
	p2.chapter = 3
	p2.completion_message = "The Zugleiterin stamps the permit!\n'Der Zoch kann losgehen!'\nThe parade route comes alive!"
	var p2_step := PuzzleStep.new()
	p2_step.step_type = PuzzleStep.StepType.USE_ITEM
	p2_step.item_id = &"zugplakette"
	p2_step.target_id = &"zugleiterin_desk"
	p2_step.description = "Bring the parade permit to the Zugleiterin"
	p2.steps = [p2_step]
	_puzzle_controller.puzzles.append(p2)

	# Puzzle 3: The Unmasking — bring the scepter to the stage (final puzzle)
	var p3 := PuzzleResource.new()
	p3.puzzle_id = &"unmasking_puzzle"
	p3.display_name = "Die Entmaskierung"
	p3.chapter = 3
	p3.reward_type = PuzzleResource.RewardType.CHAPTER_COMPLETE
	p3.prerequisites = [&"float_puzzle", &"permit_puzzle"]
	p3.completion_message = "You raise the Zepter high on the stage!\n\nThe Jungfrau speaks:\n'Karneval Forever... or is it?'\n\n*A wave of light washes over the town*\n*One by one, the costumes fall away*\n*The curse is BROKEN!*\n\nDREIMOL ALAAF!"
	var p3_step := PuzzleStep.new()
	p3_step.step_type = PuzzleStep.StepType.USE_ITEM
	p3_step.item_id = &"zepter"
	p3_step.target_id = &"stage_altar"
	p3_step.description = "Place the Dreigestirn-Zepter on the stage altar"
	p3.steps = [p3_step]
	_puzzle_controller.puzzles.append(p3)

	add_child(_puzzle_controller)

	# Hints
	var hints := HintManager.new()
	hints.hint_delay = 30.0
	hints.hint_repeat = 30.0
	hints.puzzle_hints = {
		&"float_puzzle": [
			"The parade float is missing something...",
			"The Wagenbauer in the workshop might know what the float needs.",
			"Find the Wagenrad near the right wall and attach it to the float!",
		],
		&"permit_puzzle": [
			"The Zugleiterin can't start the parade without official papers...",
			"An official Zugplakette was last seen near the far end of the route.",
			"Find the Zugplakette and bring it to the Zugleiterin's desk!",
		],
		&"unmasking_puzzle": [
			"The float is ready, the parade is organized... but the curse remains.",
			"The Jungfrau on the stage knows the final ritual.",
			"Find the Dreigestirn-Zepter behind the stage and place it on the altar!",
		],
	}
	var active_ids: Array[StringName] = [&"float_puzzle", &"permit_puzzle", &"unmasking_puzzle"]
	hints.set_active_puzzles(active_ids)
	add_child(hints)

	# Puzzle targets
	_add_puzzle_target(
		Vector3(2, 0.6, 12), &"float_axle", "Wagen-Achse",
		&"wagenrad", "The wheel fits perfectly!", "The axle needs a wheel...",
		Color(0.6, 0.45, 0.25)
	)
	_add_puzzle_target(
		Vector3(0, 0.6, 3), &"zugleiterin_desk", "Zugleiterin-Pult",
		&"zugplakette", "The permit is stamped!", "This desk needs official papers...",
		Color(0.5, 0.4, 0.55)
	)
	_add_puzzle_target(
		Vector3(0, 1.2, -32), &"stage_altar", "Bühnen-Altar",
		&"zepter", "The Zepter glows with power!", "The altar awaits something ceremonial...",
		Color(0.8, 0.6, 0.9)
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

func _make_wagenbauer_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()
	tree.dialogue_id = &"wagenbauer_main"

	var n0 := DialogueData.new()
	n0.speaker_name = "Der Wagenbauer"
	n0.default_text = "My beautiful float! The wheel fell off\nwhen the curse hit!"
	n0.costume_variants = {
		&"boastful": "Arrr! Me float's lost a wheel!\nShe'll never sail— er, roll again without it!",
		&"mischievous": "*kicks float* Stupid wheel! It ran away!\n*honk* Probably rolling around somewhere...",
		&"chivalrous": "My noble chariot has been crippled!\nThe wheel was lost in the chaos of the curse!",
		&"theatrical": "The float... *dramatic pause*\n...is BROKEN! The wheel, torn away by dark forces!",
	}
	tree.nodes.append(n0)

	var n1 := DialogueData.new()
	n1.speaker_name = "Der Wagenbauer"
	n1.default_text = "I think the Wagenrad rolled off\ntoward the right side of the route.\nBring it back and stick it on the axle!"
	tree.nodes.append(n1)
	return tree


func _make_zugleiterin_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()
	tree.dialogue_id = &"zugleiterin_main"

	var n0 := DialogueData.new()
	n0.speaker_name = "Die Zugleiterin"
	n0.default_text = "I can't start the parade without\nthe official Zugplakette!"
	n0.costume_variants = {
		&"boastful": "Arrr! No permit, no parade!\nBureaucracy be the real curse, matey!",
		&"mischievous": "No permit? No parade! *sad trombone*\nRules are rules... even cursed rules! *honk*",
		&"chivalrous": "Without the official permit, this parade\ncannot proceed! 'Tis the law of the land!",
		&"theatrical": "The Zugplakette... VANISHED!\nWithout it, the parade is DOOMED! *faints dramatically*",
	}
	tree.nodes.append(n0)

	var n1 := DialogueData.new()
	n1.speaker_name = "Die Zugleiterin"
	n1.default_text = "The Zugplakette must have blown\ntoward the far end of the parade route.\nBring it to my desk and I'll stamp it!"
	tree.nodes.append(n1)
	return tree


func _make_jungfrau_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()
	tree.dialogue_id = &"jungfrau_main"

	var n0 := DialogueData.new()
	n0.speaker_name = "Die Jungfrau"
	n0.default_text = "I am the Jungfrau of the Dreigestirn.\nOnly the ceremonial Zepter can break this curse."
	n0.costume_variants = {
		&"boastful": "Arrr, Pirat! I am the Jungfrau!\nThe Zepter alone can shatter this accursed spell!",
		&"mischievous": "Hey Clown! Quit honking and listen!\nWe need the Dreigestirn-Zepter to end this!",
		&"chivalrous": "Noble knight, hear me well!\nThe Dreigestirn-Zepter holds the key to our salvation!",
		&"theatrical": "Hexe... you of all people should sense it.\nThe Zepter pulses with the power to break the curse!",
	}
	tree.nodes.append(n0)

	var n1 := DialogueData.new()
	n1.speaker_name = "Die Jungfrau"
	n1.default_text = "The Zepter was behind the stage when the curse hit.\nFind it and place it on the altar.\nBut first — the float must roll and the parade must begin!"
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
	sun.rotation_degrees = Vector3(-30, 45, 0)
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	add_child(sun)

	var env := CurseEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.35, 0.4, 0.5)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.65, 0.65, 0.75)
	environment.ambient_light_energy = 0.65
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.4, 0.4, 0.45)
	environment.fog_density = 0.06
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.3
	env.environment = environment
	add_child(env)


func _on_chapter_completed(_chapter: int) -> void:
	await get_tree().create_timer(6.0).timeout
	SaveManager.delete_save()  # Game complete — clear save
	SceneManager.load_scene("res://scenes/credits.tscn")
