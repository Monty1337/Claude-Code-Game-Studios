## A puzzle target — an object that accepts a specific item to solve a puzzle step.
## Shows funny text on wrong item, success text on correct item.
## Implements the interactable interface.
## See: Puzzle System GDD, Item System GDD
class_name PuzzleTarget
extends StaticBody3D

@export var target_id: StringName = &"puzzle_target"
@export var target_name: String = "Puzzle Target"
@export var required_item: StringName = &""
@export var success_message: String = "It worked!"
@export var wrong_message: String = "That doesn't seem right..."
@export var solved_color: Color = Color.GREEN

var interaction_label: String = ""
var _solved := false


func _ready() -> void:
	interaction_label = "Examine " + target_name
	collision_layer = 2
	collision_mask = 0


func interact(player: Node) -> void:
	if _solved:
		EventBus.show_message.emit("Already solved!", 1.5)
		if player.has_method("end_interaction"):
			player.end_interaction()
		return

	if required_item != &"" and InventoryManager.has_item(required_item):
		_solved = true
		InventoryManager.remove_item(required_item)
		EventBus.item_used.emit(required_item, target_id, true)
		EventBus.puzzle_step_completed.emit(&"prototype_puzzle", 0)
		EventBus.show_message.emit(success_message, 3.0)
		_set_solved_visual()
	else:
		EventBus.show_message.emit(wrong_message, 2.0)

	if player.has_method("end_interaction"):
		player.end_interaction()


func is_available() -> bool:
	return not _solved


func _set_solved_visual() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = solved_color
			child.material_override = mat
			break
