## An NPC with waypoint patrol behavior, player awareness, and dialogue support.
## Walks between waypoints, pauses at each, looks at nearby players,
## reacts when walked through, and uses the full DialogueTree system.
## See: NPC System GDD, Dialogue System GDD
class_name PatrollingNPC
extends CharacterBody3D

@export var npc_id: StringName = &"npc"
@export var npc_name: String = "NPC"
@export var dialogue_tree: DialogueTree
@export var post_progress_tree: DialogueTree
@export var progress_flag: StringName = &""

@export_group("Patrol")
@export var waypoints: Array[Vector3] = []
@export var walk_speed: float = 1.5
@export var min_wait_time: float = 5.0
@export var max_wait_time: float = 15.0

@export_group("Awareness")
@export var awareness_radius: float = 5.0
@export var head_turn_speed: float = 90.0
@export var startled_cooldown: float = 3.0

var interaction_label: String = ""

var _current_waypoint: int = 0
var _waiting := false
var _wait_timer: float = 0.0
var _in_dialogue := false
var _dialogue_controller: DialogueController
var _nav_agent: NavigationAgent3D

# Awareness
var _nearest_player: Node3D = null
var _head_node: Node3D = null  # Set externally if head mesh exists
var _startled_timer: float = 0.0

enum State { PATROLLING, WAITING, AWARE, IN_DIALOGUE, STARTLED }
var _state: State = State.WAITING


func _ready() -> void:
	interaction_label = "Talk to " + npc_name
	collision_layer = 2  # Interactable
	collision_mask = 1   # Collide with environment

	# Navigation agent
	_nav_agent = NavigationAgent3D.new()
	_nav_agent.path_desired_distance = 0.5
	_nav_agent.target_desired_distance = 0.5
	add_child(_nav_agent)

	# Dialogue controller
	_dialogue_controller = DialogueController.new()
	_dialogue_controller.dialogue_finished.connect(_on_dialogue_finished)
	add_child(_dialogue_controller)

	# Start waiting at first position
	_state = State.WAITING
	_wait_timer = randf_range(1.0, 3.0)  # Short initial wait


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	# Startled cooldown
	if _startled_timer > 0:
		_startled_timer -= delta

	match _state:
		State.PATROLLING:
			_process_patrol(delta)
		State.WAITING:
			_process_wait(delta)
		State.AWARE:
			_process_aware(delta)
		State.IN_DIALOGUE:
			velocity.x = 0.0
			velocity.z = 0.0
		State.STARTLED:
			velocity.x = 0.0
			velocity.z = 0.0
			# Brief pause then resume
			_wait_timer -= delta
			if _wait_timer <= 0:
				_state = State.WAITING
				_wait_timer = 1.0

	move_and_slide()
	_check_player_proximity()


func _process_patrol(delta: float) -> void:
	if waypoints.is_empty():
		_state = State.WAITING
		_wait_timer = max_wait_time
		return

	if _nav_agent.is_navigation_finished():
		_state = State.WAITING
		_wait_timer = randf_range(min_wait_time, max_wait_time)
		_advance_waypoint()
		return

	var next_pos: Vector3 = _nav_agent.get_next_path_position()
	var direction := (next_pos - global_position)
	direction.y = 0
	if direction.length() > 0.1:
		direction = direction.normalized()
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
		# Face movement direction
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), delta * 5.0)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _process_wait(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_wait_timer -= delta
	if _wait_timer <= 0:
		_start_patrol_to_next()


func _process_aware(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	# Look at player
	if _nearest_player:
		var dir := (_nearest_player.global_position - global_position)
		dir.y = 0
		if dir.length() > 0.1:
			var target_rot := atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_rot, delta * 3.0)

	# If player leaves, resume
	if not _nearest_player or _nearest_player.global_position.distance_to(global_position) > awareness_radius:
		_nearest_player = null
		_state = State.WAITING
		_wait_timer = 1.0


func _start_patrol_to_next() -> void:
	if waypoints.is_empty():
		_wait_timer = max_wait_time
		return
	_state = State.PATROLLING
	_nav_agent.target_position = waypoints[_current_waypoint]


func _advance_waypoint() -> void:
	_current_waypoint = (_current_waypoint + 1) % waypoints.size()


func _check_player_proximity() -> void:
	if _state == State.IN_DIALOGUE or _state == State.STARTLED:
		return

	# Find nearest player in awareness radius
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		# Fallback: find by class
		for node in get_tree().get_nodes_in_group(""):
			if node is PlayerController:
				players.append(node)
		# If still empty, search all nodes
		if players.is_empty():
			_find_players_fallback()
			return

	var closest: Node3D = null
	var closest_dist: float = awareness_radius
	for p in players:
		if p is Node3D:
			var dist: float = p.global_position.distance_to(global_position)
			if dist < closest_dist:
				closest = p
				closest_dist = dist

	if closest and _state != State.IN_DIALOGUE:
		_nearest_player = closest
		if _state == State.PATROLLING or _state == State.WAITING:
			_state = State.AWARE

		# Check walk-through (very close)
		if closest_dist < 0.8 and _startled_timer <= 0:
			_startled_timer = startled_cooldown
			_state = State.STARTLED
			_wait_timer = 0.5
			EventBus.npc_startled.emit(npc_id, global_position)


func _find_players_fallback() -> void:
	# Simple fallback: scan for PlayerController nodes
	for node in get_tree().root.get_children():
		_scan_for_player(node)


func _scan_for_player(node: Node) -> void:
	if node is PlayerController:
		var dist: float = node.global_position.distance_to(global_position)
		if dist < awareness_radius:
			_nearest_player = node
			if _state == State.PATROLLING or _state == State.WAITING:
				_state = State.AWARE
			if dist < 0.8 and _startled_timer <= 0:
				_startled_timer = startled_cooldown
				_state = State.STARTLED
				_wait_timer = 0.5
				EventBus.npc_startled.emit(npc_id, global_position)
		return
	for child in node.get_children():
		_scan_for_player(child)


# -- Interaction (Dialogue) --

func interact(player: Node) -> void:
	if _in_dialogue:
		return

	var tree := dialogue_tree
	if progress_flag != &"" and GameState.get_puzzle_flag(progress_flag):
		if post_progress_tree:
			tree = post_progress_tree

	if not tree or tree.nodes.is_empty():
		EventBus.show_message.emit(npc_name + ":\n...", 1.5)
		if player.has_method("end_interaction"):
			player.end_interaction()
		return

	_in_dialogue = true
	_state = State.IN_DIALOGUE
	var personality := CostumeManager.get_personality_tag(0)
	EventBus.dialogue_started.emit(npc_id, player)
	set_meta("dialogue_player", player)

	# Face the player
	var dir := (player.global_position - global_position)
	dir.y = 0
	if dir.length() > 0.1:
		rotation.y = atan2(dir.x, dir.z)

	_dialogue_controller.start(tree, player, personality)


func _on_dialogue_finished() -> void:
	_in_dialogue = false
	_state = State.WAITING
	_wait_timer = 2.0
	GameState.record_conversation(npc_id)
	EventBus.dialogue_ended.emit(npc_id)
	var player = get_meta("dialogue_player", null)
	if player and player.has_method("end_interaction"):
		player.end_interaction()


func is_available() -> bool:
	return true
