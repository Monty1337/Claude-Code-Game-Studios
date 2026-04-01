## A complete puzzle definition.
## See: Puzzle System GDD
class_name PuzzleResource
extends Resource

enum RewardType {
	UNLOCK_AREA,
	WEAKEN_CURSE,
	UNLOCK_PUZZLE,
	CHAPTER_COMPLETE,
}

@export var puzzle_id: StringName = &""
@export var display_name: String = ""
@export var chapter: int = 1
@export var steps: Array[PuzzleStep] = []
@export var prerequisites: Array[StringName] = []  ## Other puzzle_ids that must be solved first
@export var reward_type: RewardType = RewardType.WEAKEN_CURSE
@export var completion_message: String = "Puzzle solved!"
