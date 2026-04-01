## An NPC that uses the full DialogueTree system.
## Supports costume-variant dialogue, conditions, choices, and flag-setting.
## Replaces SimpleNPC for Story NPCs.
## See: NPC System GDD, Dialogue System GDD
class_name DialogueNPC
extends StaticBody3D

@export var npc_id: StringName = &"npc"
@export var npc_name: String = "NPC"
@export var dialogue_tree: DialogueTree
## Optional: alternate dialogue tree shown after puzzle progress.
@export var post_progress_tree: DialogueTree
## Puzzle flag that switches to post_progress_tree.
@export var progress_flag: StringName = &""

var interaction_label: String = ""
var _in_dialogue := false
var _dialogue_controller: DialogueController


func _ready() -> void:
	interaction_label = "Talk to " + npc_name
	collision_layer = 2
	collision_mask = 0

	_dialogue_controller = DialogueController.new()
	_dialogue_controller.dialogue_finished.connect(_on_dialogue_finished)
	add_child(_dialogue_controller)


func interact(player: Node) -> void:
	if _in_dialogue:
		return

	var tree := dialogue_tree
	# Switch to post-progress dialogue if flag is set
	if progress_flag != &"" and GameState.get_puzzle_flag(progress_flag):
		if post_progress_tree:
			tree = post_progress_tree

	if not tree or tree.nodes.is_empty():
		EventBus.show_message.emit(npc_name + ":\n...", 1.5)
		if player.has_method("end_interaction"):
			player.end_interaction()
		return

	_in_dialogue = true
	var personality := CostumeManager.get_personality_tag(0)  # Player 0
	EventBus.dialogue_started.emit(npc_id, player)

	# Store player reference for when dialogue ends
	set_meta("dialogue_player", player)
	_dialogue_controller.start(tree, player, personality)


func _on_dialogue_finished() -> void:
	_in_dialogue = false
	GameState.record_conversation(npc_id)
	EventBus.dialogue_ended.emit(npc_id)
	var player = get_meta("dialogue_player", null)
	if player and player.has_method("end_interaction"):
		player.end_interaction()


func is_available() -> bool:
	return true
