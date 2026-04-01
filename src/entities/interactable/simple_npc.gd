## Simple NPC with linear dialogue.
## Placeholder for the full NPC + Dialogue system. Handles its own input
## during dialogue to advance lines.
## See: NPC System GDD, Dialogue System GDD
class_name SimpleNPC
extends StaticBody3D

@export var npc_id: StringName = &"npc"
@export var npc_name: String = "NPC"
@export var dialogue_lines: PackedStringArray = []

var interaction_label: String = ""
var _current_line := 0
var _in_dialogue := false
var _dialogue_player: Node = null


func _ready() -> void:
	interaction_label = "Talk to " + npc_name
	collision_layer = 2
	collision_mask = 0
	set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if _in_dialogue and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()


func interact(player: Node) -> void:
	if _in_dialogue:
		return
	if dialogue_lines.is_empty():
		EventBus.show_message.emit(npc_name + ":\n...", 1.5)
		if player.has_method("end_interaction"):
			player.end_interaction()
		return

	_dialogue_player = player
	_in_dialogue = true
	_current_line = 0
	EventBus.dialogue_started.emit(npc_id, player)
	EventBus.show_message.emit(npc_name + ":\n" + dialogue_lines[0], 0.0)
	# Delay enabling input so the same E press that started dialogue
	# doesn't immediately advance it
	await get_tree().create_timer(0.15).timeout
	if _in_dialogue:
		set_process_unhandled_input(true)


func _advance_dialogue() -> void:
	_current_line += 1
	if _current_line >= dialogue_lines.size():
		_in_dialogue = false
		set_process_unhandled_input(false)
		EventBus.dialogue_ended.emit(npc_id)
		EventBus.prompt_hide.emit()
		GameState.record_conversation(npc_id)
		if _dialogue_player and _dialogue_player.has_method("end_interaction"):
			_dialogue_player.end_interaction()
		_dialogue_player = null
	else:
		EventBus.show_message.emit(npc_name + ":\n" + dialogue_lines[_current_line], 0.0)


func is_available() -> bool:
	return true
