# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the investigate-interact-solve loop feel fun?
# Date: 2026-03-30
extends StaticBody3D

@export var npc_id: StringName = &"test_npc"
@export var npc_name: String = "Der Köbes"
@export var interaction_label: String = "Talk to"

var dialogue_lines: Array[String] = [
	"Alaaf! I'm stuck in this waiter costume!",
	"I can't stop carrying Kölsch...",
	"Hey, have you seen a golden Orden around here?\nI heard it fell off the Prinz's float.",
	"Bring me dat Orden and maybe we can figure\nout how to break this crazy curse!",
]
var current_line := 0
var in_dialogue := false
var _dialogue_player: Node = null


func _ready() -> void:
	interaction_label = "Talk to " + npc_name
	set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if in_dialogue and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()


func interact(player: Node) -> void:
	if in_dialogue:
		return

	_dialogue_player = player
	in_dialogue = true
	current_line = 0
	set_process_unhandled_input(true)
	EventBus.dialogue_started.emit(npc_id, player)
	EventBus.show_message.emit(npc_name + ":\n" + dialogue_lines[0], 0.0)


func _advance_dialogue() -> void:
	current_line += 1
	if current_line >= dialogue_lines.size():
		in_dialogue = false
		set_process_unhandled_input(false)
		EventBus.dialogue_ended.emit(npc_id)
		EventBus.prompt_hide.emit()
		if _dialogue_player:
			_dialogue_player.end_interaction()
		_dialogue_player = null
	else:
		EventBus.show_message.emit(npc_name + ":\n" + dialogue_lines[current_line], 0.0)


func is_available() -> bool:
	return true
