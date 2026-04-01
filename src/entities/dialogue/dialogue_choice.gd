## A dialogue choice option.
## See: Dialogue System GDD
class_name DialogueChoice
extends Resource

@export var label: String = ""
## Index in the dialogue tree to jump to when this choice is selected.
@export var goto_index: int = -1
## Optional: set a puzzle flag when this choice is picked.
@export var set_flag: StringName = &""
@export var set_flag_value: bool = true
