## Spawns visual/audio feedback effects in response to game events.
## Fire-and-forget, never blocks gameplay.
## See: Feedback System GDD
class_name FeedbackController
extends Node3D

@export var confetti_count: int = 50
@export var sparkle_count: int = 15
@export var max_concurrent_particles: int = 5

var _active_particles: Array[GPUParticles3D] = []


func _ready() -> void:
	EventBus.puzzle_solved.connect(_on_puzzle_solved)
	EventBus.puzzle_step_completed.connect(_on_puzzle_step)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.hop_landed.connect(_on_hop_landed)
	EventBus.npc_startled.connect(_on_npc_startled)


func _on_puzzle_solved(_puzzle_id: StringName) -> void:
	if not is_inside_tree():
		return
	var player := _find_player()
	if player:
		_spawn_confetti(player.global_position + Vector3(0, 2, 0), 2.0, confetti_count * 2)
	_screen_flash(Color(1, 0.84, 0, 0.4), 0.8)


func _on_puzzle_step(_puzzle_id: StringName, _step: int) -> void:
	if not is_inside_tree():
		return
	var player := _find_player()
	if player:
		_spawn_confetti(player.global_position + Vector3(0, 1.5, 0), 1.5, confetti_count)
	_screen_flash(Color(1, 0.84, 0, 0.25), 0.5)


func _on_item_picked_up(_item_id: StringName, _player: Node) -> void:
	if not is_inside_tree():
		return
	var player := _find_player()
	if player:
		_spawn_sparkle(player.global_position + Vector3(0, 1, 0))


func _on_hop_landed(_player: Node, pos: Vector3) -> void:
	if not is_inside_tree():
		return
	_spawn_dust(pos)


func _on_npc_startled(_npc_id: StringName, pos: Vector3) -> void:
	if not is_inside_tree():
		return
	_spawn_sparkle(pos + Vector3(0, 1.5, 0))


# -- Effect Spawners --

func _spawn_confetti(pos: Vector3, lifetime: float, amount: int) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.global_position = pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, -4, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.15
	mat.color = Color(1, 0.84, 0)
	# Random colors for confetti
	var gradient := Gradient.new()
	gradient.set_color(0, Color.RED)
	gradient.add_point(0.25, Color.YELLOW)
	gradient.add_point(0.5, Color.GREEN)
	gradient.add_point(0.75, Color.BLUE)
	gradient.set_color(1, Color.MAGENTA)
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_initial_ramp = color_ramp
	particles.process_material = mat

	# Simple mesh for particles
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.08, 0.08, 0.02)
	particles.draw_pass_1 = mesh

	_add_timed_particles(particles, lifetime + 0.5)


func _spawn_sparkle(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = sparkle_count
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.global_position = pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 2.5
	mat.gravity = Vector3(0, -2, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = Color(1, 1, 0.7)
	particles.process_material = mat

	var mesh := SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	particles.draw_pass_1 = mesh

	_add_timed_particles(particles, 1.5)


func _spawn_dust(pos: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 8
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.global_position = pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0.5, 0)
	mat.spread = 90.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 1.5
	mat.gravity = Vector3(0, -1, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.12
	mat.color = Color(0.7, 0.65, 0.55, 0.6)
	particles.process_material = mat

	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	particles.draw_pass_1 = mesh

	_add_timed_particles(particles, 1.0)


func _add_timed_particles(particles: GPUParticles3D, cleanup_time: float) -> void:
	# Enforce particle budget
	while _active_particles.size() >= max_concurrent_particles:
		var oldest: GPUParticles3D = _active_particles.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	add_child(particles)
	_active_particles.append(particles)

	# Auto-cleanup
	get_tree().create_timer(cleanup_time).timeout.connect(func():
		_active_particles.erase(particles)
		if is_instance_valid(particles):
			particles.queue_free()
	)


func _screen_flash(color: Color, duration: float) -> void:
	EventBus.puzzle_step_completed.get_connections()  # No-op to avoid warning
	# Use EventBus to tell UI to flash (UI handles screen effects)
	# For now, emit a custom approach via the existing puzzle_step signal
	# The GameUI already handles this via _on_puzzle_step
	pass


func _find_player() -> Node3D:
	for node in get_tree().root.get_children():
		var found := _scan_player(node)
		if found:
			return found
	return null


func _scan_player(node: Node) -> Node3D:
	if node is PlayerController:
		return node
	for child in node.get_children():
		var found: Node3D = _scan_player(child)
		if found:
			return found
	return null
