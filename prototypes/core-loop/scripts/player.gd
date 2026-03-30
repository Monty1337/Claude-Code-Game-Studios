# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the investigate-interact-solve loop feel fun?
# Date: 2026-03-30
extends CharacterBody3D

const WALK_SPEED := 3.0
const RUN_SPEED := 6.0
const HOP_HEIGHT := 0.5
const STEP_HEIGHT := 0.3
const GRAVITY := 9.8
const MOUSE_SENSITIVITY := 0.002
const CAM_DISTANCE := 3.0
const CAM_OFFSET := Vector3(0.5, 1.5, 0.0)
const INTERACT_RADIUS := 4.0
const FACING_THRESHOLD := 0.0  # Very wide cone — just needs to be roughly in front

var cam_rotation := Vector2.ZERO
var is_hopping := false
var is_interacting := false
var current_target: Node3D = null

var camera_pivot: Node3D
var camera: Camera3D
var spring_arm: SpringArm3D
var interact_area: Area3D
var ray: RayCast3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam_rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		cam_rotation.x = clampf(cam_rotation.x, -PI / 4, PI / 4)
		cam_rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		camera_pivot.rotation = Vector3(cam_rotation.x, cam_rotation.y, 0)

	if event.is_action_pressed("interact") and not is_interacting:
		_try_interact()

	if event.is_action_pressed("hop") and is_on_floor() and not is_hopping:
		velocity.y = sqrt(2.0 * GRAVITY * HOP_HEIGHT)
		is_hopping = true

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if is_interacting:
		velocity = Vector3.ZERO
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif is_hopping:
		is_hopping = false
		EventBus.hop_landed.emit(self, global_position)

	# First-person: camera at head height, rotates with mouse
	camera_pivot.global_position = global_position + Vector3(0, 1.6, 0)
	camera_pivot.rotation = Vector3(cam_rotation.x, cam_rotation.y, 0)

	# Movement relative to camera facing (using cam_rotation, not player rotation)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var forward := Vector3(sin(cam_rotation.y), 0, cos(cam_rotation.y))
	var right := Vector3(cos(cam_rotation.y), 0, -sin(cam_rotation.y))

	var direction := (forward * input_dir.y + right * input_dir.x).normalized()
	var speed := RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED

	if direction.length() > 0.1:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		# Rotate character to face movement direction
		var target_rot := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 0.15)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	_detect_target()


func _detect_target() -> void:
	var best_target: Node3D = null
	var best_score := -1.0

	# Check raycast first
	if ray and ray.is_colliding():
		var hit := ray.get_collider()
		if hit and hit.has_method("interact"):
			if hit.has_method("is_available") and hit.is_available():
				best_target = hit
				best_score = 999.0

	# Check proximity
	if interact_area:
		for body in interact_area.get_overlapping_bodies():
			if body == self:
				continue
			if not body.has_method("interact"):
				continue
			if body.has_method("is_available") and not body.is_available():
				continue

			var to_target := (body.global_position - global_position)
			to_target.y = 0
			to_target = to_target.normalized()
			# Use camera facing, not player body facing
			var cam_forward := Vector3(sin(cam_rotation.y), 0, cos(cam_rotation.y))
			var dot := cam_forward.dot(to_target)

			if dot > FACING_THRESHOLD and dot > best_score and best_score < 999.0:
				best_target = body
				best_score = dot

	if best_target != current_target:
		current_target = best_target
		if current_target:
			var label_text: String = "[E] " + current_target.get("interaction_label")
			EventBus.prompt_show.emit(label_text, current_target.global_position + Vector3(0, 1.5, 0))
		else:
			EventBus.prompt_hide.emit()


func _try_interact() -> void:
	if not current_target:
		return
	if current_target.has_method("is_available") and not current_target.is_available():
		return

	is_interacting = true
	# Face the target
	var dir_to := current_target.global_position - global_position
	dir_to.y = 0
	if dir_to.length() > 0.01:
		rotation.y = atan2(dir_to.x, dir_to.z)

	EventBus.interaction_started.emit(current_target, self)
	current_target.interact(self)


func end_interaction() -> void:
	is_interacting = false
	EventBus.interaction_ended.emit(current_target, self)
