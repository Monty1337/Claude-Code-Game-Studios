# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the investigate-interact-solve loop feel fun?
# Date: 2026-03-30
extends Node3D

## Builds the entire prototype scene programmatically.
## This avoids complex .tscn files and keeps everything in one place.


func _ready() -> void:
	_build_environment()
	_build_player()
	_build_items()
	_build_npc()
	_build_puzzle_target()
	_build_ui()
	_build_lighting()

	EventBus.puzzle_step_completed.connect(_on_puzzle_solved)
	EventBus.show_message.emit(
		"KARNEVAL FOREVER — Core Loop Prototype\n" +
		"WASD: Move | Mouse: Look | E: Interact | Space: Hop | Tab: Inventory | Shift: Run",
		5.0
	)


func _build_environment() -> void:
	# Ground plane
	var ground := StaticBody3D.new()
	var ground_mesh := MeshInstance3D.new()
	ground_mesh.mesh = PlaneMesh.new()
	ground_mesh.mesh.size = Vector2(40, 40)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.6, 0.55, 0.5)  # Cobblestone-ish
	ground_mesh.material_override = ground_mat
	ground.add_child(ground_mesh)
	var ground_col := CollisionShape3D.new()
	ground_col.shape = BoxShape3D.new()
	ground_col.shape.size = Vector3(40, 0.1, 40)
	ground_col.position.y = -0.05
	ground.add_child(ground_col)
	add_child(ground)

	# Walls / buildings (simple boxes)
	_make_wall(Vector3(-8, 1.5, -10), Vector3(16, 3, 0.5), Color(0.85, 0.75, 0.6))  # Back wall
	_make_wall(Vector3(-8, 1.5, 8), Vector3(6, 3, 0.5), Color(0.8, 0.7, 0.55))     # Front left
	_make_wall(Vector3(4, 1.5, 8), Vector3(6, 3, 0.5), Color(0.75, 0.65, 0.5))      # Front right
	_make_wall(Vector3(-10, 1.5, 0), Vector3(0.5, 3, 20), Color(0.9, 0.8, 0.65))    # Left wall
	_make_wall(Vector3(10, 1.5, 0), Vector3(0.5, 3, 20), Color(0.82, 0.72, 0.58))   # Right wall

	# Some "buildings" (colored boxes)
	_make_wall(Vector3(-6, 2, -6), Vector3(3, 4, 3), Color(0.9, 0.3, 0.3))  # Red building
	_make_wall(Vector3(5, 1.5, -5), Vector3(4, 3, 3), Color(0.3, 0.5, 0.9)) # Blue building
	_make_wall(Vector3(6, 1, 4), Vector3(2, 2, 2), Color(0.9, 0.8, 0.2))    # Yellow kiosk

	# A bench
	_make_wall(Vector3(-3, 0.3, 3), Vector3(2, 0.6, 0.5), Color(0.5, 0.35, 0.2))

	# Fountain (cylinder placeholder)
	var fountain := StaticBody3D.new()
	var ftn_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.5
	cyl.bottom_radius = 1.5
	cyl.height = 0.8
	ftn_mesh.mesh = cyl
	var ftn_mat := StandardMaterial3D.new()
	ftn_mat.albedo_color = Color(0.7, 0.7, 0.75)
	ftn_mesh.material_override = ftn_mat
	fountain.add_child(ftn_mesh)
	var ftn_col := CollisionShape3D.new()
	ftn_col.shape = CylinderShape3D.new()
	ftn_col.shape.radius = 1.5
	ftn_col.shape.height = 0.8
	fountain.add_child(ftn_col)
	fountain.position = Vector3(0, 0.4, -2)
	add_child(fountain)


func _make_wall(pos: Vector3, size: Vector3, color: Color) -> void:
	var wall := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	wall.add_child(mesh)
	var col := CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = size
	wall.add_child(col)
	wall.position = pos
	add_child(wall)


func _build_player() -> void:
	var player := CharacterBody3D.new()
	player.position = Vector3(0, 0.9, 5)

	# Body (capsule)
	var body_mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	body_mesh.mesh = capsule
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.2, 0.7, 0.3)  # Green costume
	body_mesh.material_override = body_mat
	player.add_child(body_mesh)

	# Collision
	var col := CollisionShape3D.new()
	col.shape = CapsuleShape3D.new()
	col.shape.radius = 0.3
	col.shape.height = 1.8
	player.add_child(col)

	# Interact area (proximity sphere) — stays on player
	var area := Area3D.new()
	area.name = "InteractArea"
	area.collision_mask = 2
	var area_col := CollisionShape3D.new()
	area_col.shape = SphereShape3D.new()
	area_col.shape.radius = INTERACT_RADIUS
	area.add_child(area_col)
	player.add_child(area)

	# Attach player script
	var script := load("res://scripts/player.gd")
	player.set_script(script)

	add_child(player)

	# Camera pivot — NOT a child of player (avoids rotation feedback loop)
	var pivot := Node3D.new()
	pivot.name = "CameraPivot"
	pivot.top_level = true
	pivot.position = player.position + Vector3(0, 1.6, 0)
	add_child(pivot)

	# Camera — directly on pivot (first person, no spring arm)
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.current = true
	pivot.add_child(cam)

	# Interact raycast (from camera forward)
	var ray := RayCast3D.new()
	ray.name = "InteractRay"
	ray.target_position = Vector3(0, 0, -INTERACT_RADIUS)
	ray.collision_mask = 2
	cam.add_child(ray)

	# Player needs references to camera nodes — set them after both exist
	player.camera_pivot = pivot
	player.camera = cam
	player.spring_arm = null
	player.interact_area = area
	player.ray = ray


# First-person camera — no distance/offset needed
const INTERACT_RADIUS := 4.0


func _build_items() -> void:
	# Item 1: Golden Orden (the puzzle item)
	_make_item(
		Vector3(7, 0.5, -3),
		&"golden_orden",
		"Goldener Orden",
		"A shiny golden Orden — looks important!\nIt has the Dreigestirn emblem on it.",
		Color(1.0, 0.84, 0.0)  # Gold
	)

	# Item 2: A red nose (flavor item)
	_make_item(
		Vector3(-4, 0.5, 5),
		&"red_nose",
		"Rote Pappnase",
		"A classic red clown nose. Honk honk!\nSmells like Kölsch.",
		Color(1.0, 0.1, 0.1)  # Red
	)


func _make_item(pos: Vector3, id: StringName, item_name: String, desc: String, color: Color) -> void:
	var item := StaticBody3D.new()
	item.collision_layer = 2  # Interactable layer
	item.collision_mask = 0

	var mesh := MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
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
	var script := load("res://scripts/pickup_item.gd")
	item.set_script(script)
	item.item_id = id
	item.item_name = item_name
	item.item_description = desc
	add_child(item)


func _build_npc() -> void:
	var npc := StaticBody3D.new()
	npc.collision_layer = 2
	npc.collision_mask = 0
	npc.position = Vector3(-2, 0.9, -4)

	# Body
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	body.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.6)  # Blue uniform (Köbes)
	body.material_override = mat
	npc.add_child(body)

	# Head
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	head.mesh = sphere
	head.position.y = 1.1
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.9, 0.75, 0.65)
	head.material_override = head_mat
	npc.add_child(head)

	var col := CollisionShape3D.new()
	col.shape = CapsuleShape3D.new()
	col.shape.radius = 0.35
	col.shape.height = 2.0
	npc.add_child(col)

	var script := load("res://scripts/npc.gd")
	npc.set_script(script)

	add_child(npc)


func _build_puzzle_target() -> void:
	var target := StaticBody3D.new()
	target.collision_layer = 2
	target.collision_mask = 0
	target.position = Vector3(0, 0.9, -1.5)  # On the fountain

	var mesh := MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.4, 0.4)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.4, 0.8)  # Purple pedestal
	mesh.material_override = mat
	target.add_child(mesh)

	var col := CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(0.5, 0.5, 0.5)
	target.add_child(col)

	var script := load("res://scripts/puzzle_target.gd")
	target.set_script(script)
	target.target_id = &"fountain_pedestal"
	target.target_name = "Narrenstatue-Sockel"
	target.required_item = &"golden_orden"
	target.success_message = "ALAAF! The Orden fits perfectly!\nThe fountain starts glowing...\nThe curse weakens!"
	target.wrong_message = "Hmm, dat passt nit auf den Sockel...\n(Doesn't fit on the pedestal)"

	add_child(target)


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	var script := load("res://scripts/prototype_ui.gd")
	ui.set_script(script)
	add_child(ui)


func _build_lighting() -> void:
	# Directional light (sun)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)

	# World environment
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.6, 0.75, 0.95)  # Light blue sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.8, 0.8, 0.9)
	environment.ambient_light_energy = 0.4
	env.environment = environment
	add_child(env)


func _on_puzzle_solved(_puzzle_id: StringName, _step: int) -> void:
	await get_tree().create_timer(3.5).timeout
	EventBus.show_message.emit(
		"PROTOTYPE COMPLETE!\n" +
		"The core loop works: Explore -> Interact -> Solve\n\n" +
		"Press Escape to exit",
		0.0
	)
