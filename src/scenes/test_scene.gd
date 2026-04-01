## Test scene for Sprint 1 — blockout environment with player and interactables.
## Builds everything programmatically for fast iteration without .tscn dependencies.
extends Node3D


func _ready() -> void:
	_build_environment()
	_build_player()
	_build_items()
	_build_npc()
	_build_puzzle_target()
	_build_ui()
	_build_lighting()

	EventBus.show_message.emit(
		"KARNEVAL FOREVER — Sprint 1 Test Scene\n" +
		"WASD: Move | Mouse: Look | E: Interact | Space: Hop | Tab: Inventory",
		4.0
	)


# -- Environment --

func _build_environment() -> void:
	# Ground
	_add_static_box(Vector3.ZERO, Vector3(40, 0.1, 40), Color(0.6, 0.55, 0.5))

	# Perimeter walls
	_add_static_box(Vector3(0, 1.5, -20), Vector3(40, 3, 0.5), Color(0.85, 0.75, 0.6))
	_add_static_box(Vector3(0, 1.5, 20), Vector3(40, 3, 0.5), Color(0.8, 0.7, 0.55))
	_add_static_box(Vector3(-20, 1.5, 0), Vector3(0.5, 3, 40), Color(0.9, 0.8, 0.65))
	_add_static_box(Vector3(20, 1.5, 0), Vector3(0.5, 3, 40), Color(0.82, 0.72, 0.58))

	# Buildings
	_add_static_box(Vector3(-8, 2, -10), Vector3(5, 4, 5), Color(0.9, 0.3, 0.3))
	_add_static_box(Vector3(8, 2, -8), Vector3(6, 4, 4), Color(0.3, 0.5, 0.9))
	_add_static_box(Vector3(10, 1.5, 8), Vector3(4, 3, 4), Color(0.9, 0.8, 0.2))
	_add_static_box(Vector3(-10, 1, 10), Vector3(3, 2, 3), Color(0.5, 0.8, 0.4))

	# Fountain (center)
	var fountain := StaticBody3D.new()
	var cyl_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.0
	cyl.bottom_radius = 2.0
	cyl.height = 0.8
	cyl_mesh.mesh = cyl
	var cyl_mat := StandardMaterial3D.new()
	cyl_mat.albedo_color = Color(0.7, 0.7, 0.75)
	cyl_mesh.material_override = cyl_mat
	fountain.add_child(cyl_mesh)
	var cyl_col := CollisionShape3D.new()
	cyl_col.shape = CylinderShape3D.new()
	cyl_col.shape.radius = 2.0
	cyl_col.shape.height = 0.8
	fountain.add_child(cyl_col)
	fountain.position = Vector3(0, 0.4, 0)
	add_child(fountain)

	# Bench
	_add_static_box(Vector3(-4, 0.35, 5), Vector3(2.5, 0.7, 0.6), Color(0.5, 0.35, 0.2))
	# Steps
	_add_static_box(Vector3(4, 0.15, 5), Vector3(3, 0.3, 1), Color(0.65, 0.6, 0.55))


func _add_static_box(pos: Vector3, size: Vector3, color: Color) -> void:
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
	var player := CharacterBody3D.new()
	player.set_script(preload("res://entities/player/player_controller.gd"))
	player.position = Vector3(0, 0.9, 8)
	player.collision_layer = 4  # Player layer
	player.collision_mask = 1   # Collide with environment

	# Collision capsule
	var col := CollisionShape3D.new()
	col.shape = CapsuleShape3D.new()
	col.shape.radius = 0.3
	col.shape.height = 1.8
	player.add_child(col)

	# Interact area (proximity detection)
	var area := Area3D.new()
	area.name = "InteractArea"
	area.collision_layer = 0
	area.collision_mask = 2  # Detect interactable layer
	var area_col := CollisionShape3D.new()
	area_col.shape = SphereShape3D.new()
	area_col.shape.radius = player.interact_radius
	area.add_child(area_col)
	player.add_child(area)

	add_child(player)

	# Camera pivot (independent from player to avoid rotation feedback)
	var pivot := Node3D.new()
	pivot.name = "CameraPivot"
	pivot.position = player.position + Vector3(0, 1.6, 0)
	add_child(pivot)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.current = true
	pivot.add_child(cam)

	var ray := RayCast3D.new()
	ray.name = "InteractRay"
	ray.target_position = Vector3(0, 0, -player.interact_radius)
	ray.collision_mask = 2
	cam.add_child(ray)

	# Wire up references
	player.camera_pivot = pivot
	player.camera = cam
	player.interact_ray = ray
	player.interact_area = area


# -- Interactables --

func _build_items() -> void:
	_add_item(Vector3(12, 0.5, -5), &"golden_orden", "Goldener Orden",
		"A shiny golden Orden with the Dreigestirn emblem.\nIt must be important!",
		Color(1, 0.84, 0), true)

	_add_item(Vector3(-6, 0.5, 8), &"red_nose", "Rote Pappnase",
		"A classic red clown nose. Honk honk!\nSmells faintly of Kölsch.",
		Color(1, 0.1, 0.1), false)

	_add_item(Vector3(-12, 0.5, -5), &"koelsch_glass", "Kölschglas",
		"A Kölsch Stange — still half full.\nOr is it half empty?",
		Color(0.9, 0.85, 0.3), false)


func _add_item(pos: Vector3, id: StringName, item_name: String, desc: String,
		color: Color, key: bool) -> void:
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


func _build_npc() -> void:
	var npc := StaticBody3D.new()
	npc.set_script(preload("res://entities/interactable/simple_npc.gd"))
	npc.npc_id = &"koebes"
	npc.npc_name = "Der Köbes"
	npc.dialogue_lines = PackedStringArray([
		"Alaaf! I can't get this waiter costume off!",
		"Every time I try, my hands just start\ncarrying more Kölsch...",
		"Hey, have you found a golden Orden?\nIt fell off the Prinz's float somewhere.",
		"Bring it to the Narrenstatue fountain!\nMaybe that will weaken this crazy curse!",
	])
	npc.position = Vector3(-3, 0.9, -3)

	# Body
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	body.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.6)
	body.material_override = mat
	npc.add_child(body)

	# Head
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
	add_child(npc)


func _build_puzzle_target() -> void:
	var target := StaticBody3D.new()
	target.set_script(preload("res://entities/interactable/puzzle_target.gd"))
	target.target_id = &"fountain_pedestal"
	target.target_name = "Narrenstatue-Sockel"
	target.required_item = &"golden_orden"
	target.success_message = "ALAAF! The Orden fits perfectly!\nThe fountain glows... the curse weakens!"
	target.wrong_message = "Hmm, dat passt nit...\nI need something specific for this pedestal."
	target.position = Vector3(0, 0.9, -1.5)

	var mesh := MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.4, 0.8)
	mesh.material_override = mat
	target.add_child(mesh)

	var col := CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(0.6, 0.6, 0.6)
	target.add_child(col)
	add_child(target)


# -- UI --

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.set_script(preload("res://ui/game_ui.gd"))
	add_child(ui)


# -- Lighting --

func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.6, 0.75, 0.95)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.8, 0.8, 0.9)
	environment.ambient_light_energy = 0.4
	env.environment = environment
	add_child(env)
