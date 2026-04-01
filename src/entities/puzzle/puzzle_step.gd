## A single step in a puzzle. Typed by step_type.
## See: Puzzle System GDD
class_name PuzzleStep
extends Resource

enum StepType {
	USE_ITEM,       ## Use item_id on target_id
	TALK_TO_NPC,    ## Talk to npc_id until dialogue_flag is set
	COLLECT_ITEM,   ## Pick up item_id
	REACH_LOCATION, ## Enter area area_id
	MINI_TASK,      ## Complete mini-task task_id (future)
}

@export var step_type: StepType = StepType.USE_ITEM
@export var description: String = ""

## Parameters (used depending on step_type)
@export var item_id: StringName = &""
@export var target_id: StringName = &""
@export var npc_id: StringName = &""
@export var dialogue_flag: StringName = &""
@export var area_id: StringName = &""
@export var task_id: StringName = &""

## Optional: this step requires another step index to be done first
@export var step_prerequisite: int = -1
