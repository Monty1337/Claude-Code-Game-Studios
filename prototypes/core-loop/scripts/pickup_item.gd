# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the investigate-interact-solve loop feel fun?
# Date: 2026-03-30
extends StaticBody3D

@export var item_id: StringName = &"mystery_item"
@export var item_name: String = "Mysterious Object"
@export var item_description: String = "It looks... interesting."
@export var interaction_label: String = "Pick up"
@export var bob_speed: float = 1.0
@export var bob_height: float = 0.1

var _picked_up := false
var _start_y: float


func _ready() -> void:
	_start_y = position.y
	interaction_label = "Pick up " + item_name


func _process(delta: float) -> void:
	if _picked_up:
		return
	position.y = _start_y + sin(Time.get_ticks_msec() * 0.001 * bob_speed * TAU) * bob_height
	rotate_y(delta * 0.5)


func interact(player: Node) -> void:
	if _picked_up:
		return
	_picked_up = true
	Inventory.add_item(item_id)
	EventBus.item_picked_up.emit(item_id, player)
	EventBus.show_message.emit("Picked up: " + item_name + "\n" + item_description, 2.0)
	player.end_interaction()
	queue_free()


func is_available() -> bool:
	return not _picked_up
