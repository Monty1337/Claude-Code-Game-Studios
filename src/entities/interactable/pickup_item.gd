## A pickable item in the game world.
## Bobs and rotates to attract attention. Adds to shared inventory on pickup.
## Implements the interactable interface (interaction_label, interact(), is_available()).
## See: Item System GDD, Interaction System GDD
class_name PickupItem
extends StaticBody3D

@export var item_id: StringName = &"unnamed_item"
@export var item_name: String = "Item"
@export var item_description: String = "An item."
@export var is_key_item: bool = false

@export_group("World Appearance")
@export var bob_speed: float = 1.0
@export var bob_height: float = 0.1
@export var rotate_speed: float = 0.5

var interaction_label: String = ""
var _picked_up := false
var _start_y: float


func _ready() -> void:
	_start_y = position.y
	interaction_label = "Pick up " + item_name
	collision_layer = 2  # Interactable layer
	collision_mask = 0


func _process(delta: float) -> void:
	if _picked_up:
		return
	position.y = _start_y + sin(Time.get_ticks_msec() * 0.001 * bob_speed * TAU) * bob_height
	rotate_y(delta * rotate_speed)


func interact(player: Node) -> void:
	if _picked_up:
		return
	_picked_up = true
	InventoryManager.add_item(item_id)
	EventBus.show_message.emit("Picked up: " + item_name + "\n" + item_description, 2.5)
	if player.has_method("end_interaction"):
		player.end_interaction()
	queue_free()


func is_available() -> bool:
	return not _picked_up
