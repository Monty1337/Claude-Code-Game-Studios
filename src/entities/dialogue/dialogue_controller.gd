## Runs a dialogue tree — displays text, handles choices, checks conditions,
## sets flags, and manages costume-variant line selection.
## Owns the conversation flow. NPC triggers it; this system runs it.
## See: Dialogue System GDD
class_name DialogueController
extends Node

signal dialogue_finished()

var _tree: DialogueTree
var _current_index: int = 0
var _personality_tag: StringName = &"default"
var _player: Node = null
var _active := false
var _showing_choices := false
var _choice_options: Array[DialogueChoice] = []


func start(tree: DialogueTree, player: Node, personality_tag: StringName = &"default") -> void:
	if _active:
		return
	_tree = tree
	_player = player
	_personality_tag = personality_tag
	_current_index = 0
	_active = true
	_showing_choices = false
	set_process_unhandled_input(true)
	_show_current_node()


func _ready() -> void:
	set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if _showing_choices:
		# Number keys 1-4 to pick choices
		if event is InputEventKey and event.pressed:
			var key: int = event.keycode
			if key >= KEY_1 and key <= KEY_4:
				var choice_idx: int = key - KEY_1
				if choice_idx < _choice_options.size():
					get_viewport().set_input_as_handled()
					_pick_choice(choice_idx)
	else:
		if event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			_advance()


func _show_current_node() -> void:
	if _current_index < 0 or _current_index >= _tree.nodes.size():
		_end_dialogue()
		return

	var node := _tree.nodes[_current_index]

	# Check condition
	if not node.check_condition():
		if node.condition_fail_goto >= 0:
			_current_index = node.condition_fail_goto
			_show_current_node()
		else:
			# Skip this node
			_current_index += 1
			_show_current_node()
		return

	# Set flag if specified
	if node.set_flag != &"":
		GameState.set_puzzle_flag(node.set_flag, node.set_flag_value)

	# Show choices or text
	if node.has_choices():
		_showing_choices = true
		_choice_options = node.choices
		var text := node.get_text(_personality_tag)
		# Append choice labels
		for i in _choice_options.size():
			text += "\n  [" + str(i + 1) + "] " + _choice_options[i].label
		EventBus.show_message.emit(
			node.speaker_name + ":\n" + text, 0.0
		)
	else:
		_showing_choices = false
		EventBus.show_message.emit(
			node.speaker_name + ":\n" + node.get_text(_personality_tag), 0.0
		)


func _advance() -> void:
	_current_index += 1
	# Small delay to prevent double-advancing
	await get_tree().create_timer(0.1).timeout
	if _active:
		_show_current_node()


func _pick_choice(choice_idx: int) -> void:
	if choice_idx >= _choice_options.size():
		return
	var choice := _choice_options[choice_idx]

	# Set flag if specified
	if choice.set_flag != &"":
		GameState.set_puzzle_flag(choice.set_flag, choice.set_flag_value)

	_showing_choices = false
	_choice_options = []

	# Jump to target or advance
	if choice.goto_index >= 0:
		_current_index = choice.goto_index
	else:
		_current_index += 1

	await get_tree().create_timer(0.1).timeout
	if _active:
		_show_current_node()


func _end_dialogue() -> void:
	_active = false
	_showing_choices = false
	set_process_unhandled_input(false)
	EventBus.prompt_hide.emit()
	# Hide message after a brief moment
	EventBus.show_message.emit("", 0.01)
	dialogue_finished.emit()
