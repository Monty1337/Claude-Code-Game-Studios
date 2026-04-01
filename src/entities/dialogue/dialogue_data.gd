## Data structures for the dialogue system.
## Dialogue trees are built from these resources.
## See: Dialogue System GDD
class_name DialogueData
extends Resource

## A single line of dialogue with optional costume variants.
@export var speaker_name: String = ""
@export var default_text: String = ""
@export var costume_variants: Dictionary = {}  # StringName -> String
## If not empty, this node presents choices instead of text.
@export var choices: Array[DialogueChoice] = []
## Condition: only show this node if a puzzle flag is set (or not set).
@export var condition_flag: StringName = &""
@export var condition_value: bool = true
## If condition fails, skip to this node index (-1 = skip entirely).
@export var condition_fail_goto: int = -1
## On reaching this node, set a puzzle flag.
@export var set_flag: StringName = &""
@export var set_flag_value: bool = true


func get_text(personality_tag: StringName) -> String:
	if personality_tag in costume_variants:
		return costume_variants[personality_tag]
	return default_text


func has_choices() -> bool:
	return not choices.is_empty()


func check_condition() -> bool:
	if condition_flag == &"":
		return true
	return GameState.get_puzzle_flag(condition_flag) == condition_value
