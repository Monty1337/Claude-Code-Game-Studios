## First-person player controller.
## Handles movement, mouse look, hop, and interaction state.
## Camera is a separate node (not a child) to avoid rotation feedback loops.
## See: Player Character GDD
class_name PlayerController
extends CharacterBody3D

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var run_speed: float = 9.0
@export var gravity: float = 9.8

@export_group("Hop")
@export var hop_height: float = 0.5
@export var step_height: float = 0.3

@export_group("Camera")
@export var mouse_sensitivity: float = 0.002
@export var look_limit: float = PI / 4  # ~45 degrees up/down
@export var cam_height: float = 1.6

@export_group("Interaction")
@export var interact_radius: float = 4.0
@export var facing_threshold: float = 0.0

## Set by the scene that spawns this player.
var camera_pivot: Node3D
var camera: Camera3D
var interact_ray: RayCast3D
var interact_area: Area3D

var cam_rotation := Vector2.ZERO
var is_hopping := false
var is_interacting := false
var current_target: Node3D = null
var player_index: int = 0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam_rotation.x -= event.relative.y * mouse_sensitivity
		cam_rotation.x = clampf(cam_rotation.x, -look_limit, look_limit)
		cam_rotation.y -= event.relative.x * mouse_sensitivity

	# Interact
	if event.is_action_pressed("interact") and not is_interacting:
		_try_interact()

	# Hop
	if event.is_action_pressed("hop") and is_on_floor() and not is_hopping:
		velocity.y = sqrt(2.0 * gravity * hop_height)
		is_hopping = true

	# Escape handled by GameUI (pause menu)


func _physics_process(delta: float) -> void:
	# Update camera pivot position and rotation
	if camera_pivot:
		camera_pivot.global_position = global_position + Vector3(0, cam_height, 0)
		camera_pivot.rotation = Vector3(cam_rotation.x, cam_rotation.y, 0)

	# Interacting: freeze movement
	if is_interacting:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif is_hopping:
		is_hopping = false
		EventBus.hop_landed.emit(self, global_position)

	# Movement input relative to camera facing
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var forward := Vector3(sin(cam_rotation.y), 0, cos(cam_rotation.y))
	var right := Vector3(cos(cam_rotation.y), 0, -sin(cam_rotation.y))
	var direction := (forward * input_dir.y + right * input_dir.x).normalized()
	var speed := run_speed if Input.is_action_pressed("run") else walk_speed

	if direction.length() > 0.1:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	_detect_target()


func _detect_target() -> void:
	var best_target: Node3D = null
	var best_score := -1.0

	# Priority 1: Raycast hit
	if interact_ray and interact_ray.is_colliding():
		var hit := interact_ray.get_collider()
		if _is_valid_interactable(hit):
			best_target = hit
			best_score = 999.0

	# Priority 2: Proximity + camera facing
	if interact_area:
		for body in interact_area.get_overlapping_bodies():
			if body == self or not _is_valid_interactable(body):
				continue
			var to_target := (body.global_position - global_position)
			to_target.y = 0
			if to_target.length() < 0.01:
				continue
			to_target = to_target.normalized()
			var cam_forward := Vector3(sin(cam_rotation.y), 0, cos(cam_rotation.y))
			var dot := cam_forward.dot(to_target)
			if dot > facing_threshold and dot > best_score and best_score < 999.0:
				best_target = body
				best_score = dot

	# Update prompt
	if best_target != current_target:
		current_target = best_target
		if current_target and current_target.get("interaction_label"):
			EventBus.prompt_show.emit(
				"[E] " + current_target.interaction_label,
				current_target.global_position + Vector3(0, 1.5, 0)
			)
		else:
			EventBus.prompt_hide.emit()


func _is_valid_interactable(node: Node) -> bool:
	if not node or not node.has_method("interact"):
		return false
	if node.has_method("is_available") and not node.is_available():
		return false
	return true


func _try_interact() -> void:
	if not current_target:
		return
	is_interacting = true
	EventBus.interaction_started.emit(current_target, self)
	current_target.interact(self)


func end_interaction() -> void:
	is_interacting = false
	EventBus.interaction_ended.emit(current_target, self)
