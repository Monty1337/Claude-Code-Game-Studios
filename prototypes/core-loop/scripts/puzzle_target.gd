# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the investigate-interact-solve loop feel fun?
# Date: 2026-03-30
extends StaticBody3D

@export var target_id: StringName = &"puzzle_target"
@export var target_name: String = "Puzzle Target"
@export var required_item: StringName = &"mystery_item"
@export var success_message: String = "Alaaf! It worked!"
@export var wrong_message: String = "Dat passt nit... (That doesn't fit)"
@export var interaction_label: String = "Examine"

var _solved := false


func _ready() -> void:
	interaction_label = "Examine " + target_name


func interact(player: Node) -> void:
	if _solved:
		EventBus.show_message.emit("Already solved!", 1.5)
		player.end_interaction()
		return

	if Inventory.has_item(required_item):
		# Success!
		_solved = true
		Inventory.remove_item(required_item)
		EventBus.item_used.emit(required_item, target_id, true)
		EventBus.puzzle_step_completed.emit(&"prototype_puzzle", 0)
		EventBus.show_message.emit(success_message, 3.0)
		# Change color to green
		var mesh := find_child("MeshInstance3D", true, false) as MeshInstance3D
		if mesh:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color.GREEN
			mesh.material_override = mat
	else:
		EventBus.show_message.emit(wrong_message, 2.0)

	player.end_interaction()


func is_available() -> bool:
	return not _solved
