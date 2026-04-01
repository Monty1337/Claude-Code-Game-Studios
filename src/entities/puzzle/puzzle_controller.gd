## Manages all puzzles in the current chapter.
## Tracks step completion, validates item usage, handles rewards.
## One instance per chapter scene.
## See: Puzzle System GDD, ADR-0001
class_name PuzzleController
extends Node

@export var puzzles: Array[PuzzleResource] = []
@export var curse_delta_per_puzzle: float = 0.33

## puzzle_id -> { "solved": bool, "steps_done": Array[int] }
var _puzzle_states: Dictionary = {}


func _ready() -> void:
	# Initialize state for each puzzle
	for puzzle in puzzles:
		_puzzle_states[puzzle.puzzle_id] = {
			"solved": false,
			"steps_done": [],
		}

	# Listen for events that can complete steps
	EventBus.item_used.connect(_on_item_used)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.puzzle_flag_set.connect(_on_flag_set)


func _on_item_used(item_id: StringName, target_id: StringName, _success: bool) -> void:

	for puzzle in puzzles:

		if not _is_available(puzzle):
			continue
		if _is_solved(puzzle):
			continue
		for i in puzzle.steps.size():
			if _is_step_done(puzzle, i):
				continue
			var step := puzzle.steps[i]
			if step.step_type == PuzzleStep.StepType.USE_ITEM:

				if step.item_id == item_id and step.target_id == target_id:
	
					_complete_step(puzzle, i)


func _on_item_picked_up(item_id: StringName, _player: Node) -> void:
	for puzzle in puzzles:
		if not _is_available(puzzle) or _is_solved(puzzle):
			continue
		for i in puzzle.steps.size():
			if _is_step_done(puzzle, i):
				continue
			var step := puzzle.steps[i]
			if step.step_type == PuzzleStep.StepType.COLLECT_ITEM:
				if step.item_id == item_id:
					_complete_step(puzzle, i)


func _on_flag_set(flag_name: StringName, value: bool) -> void:

	if not value:
		return
	for puzzle in puzzles:
		if not _is_available(puzzle) or _is_solved(puzzle):
			continue
		for i in puzzle.steps.size():
			if _is_step_done(puzzle, i):
				continue
			var step := puzzle.steps[i]
			if step.step_type == PuzzleStep.StepType.TALK_TO_NPC:
				if step.dialogue_flag == flag_name:
					_complete_step(puzzle, i)


## Check if an item can be used on a target (called by PuzzleTarget).
func validate_item_use(item_id: StringName, target_id: StringName) -> bool:
	for puzzle in puzzles:
		if not _is_available(puzzle) or _is_solved(puzzle):
			continue
		for step in puzzle.steps:
			if step.step_type == PuzzleStep.StepType.USE_ITEM:
				if step.item_id == item_id and step.target_id == target_id:
					return true
	return false


func _complete_step(puzzle: PuzzleResource, step_index: int) -> void:
	var state: Dictionary = _puzzle_states[puzzle.puzzle_id]
	if step_index in state["steps_done"]:
		return

	state["steps_done"].append(step_index)
	EventBus.puzzle_step_completed.emit(puzzle.puzzle_id, step_index)

	# Also check if any other steps are retroactively complete
	# (e.g., a TalkToNPC flag was set earlier but not caught)
	_check_retroactive_steps(puzzle)

	# Check if all steps are done
	if state["steps_done"].size() >= puzzle.steps.size():
		_solve_puzzle(puzzle)


func _solve_puzzle(puzzle: PuzzleResource) -> void:
	var state: Dictionary = _puzzle_states[puzzle.puzzle_id]
	state["solved"] = true

	EventBus.puzzle_solved.emit(puzzle.puzzle_id)
	EventBus.show_message.emit(puzzle.completion_message, 4.0)

	# Apply reward
	match puzzle.reward_type:
		PuzzleResource.RewardType.WEAKEN_CURSE:
			GameState.advance_curse(curse_delta_per_puzzle)
		PuzzleResource.RewardType.CHAPTER_COMPLETE:
			GameState.advance_curse(curse_delta_per_puzzle)
			EventBus.chapter_completed.emit(GameState.get_chapter())

	# Check if all chapter puzzles are solved
	var all_solved := true
	for p in puzzles:
		if p.chapter == puzzle.chapter and not _is_solved(p):
			all_solved = false
			break
	if all_solved:
		EventBus.chapter_completed.emit(puzzle.chapter)


func _is_available(puzzle: PuzzleResource) -> bool:
	for prereq_id in puzzle.prerequisites:
		if not _is_solved_by_id(prereq_id):
			return false
	return true


func _is_solved(puzzle: PuzzleResource) -> bool:
	var state: Dictionary = _puzzle_states.get(puzzle.puzzle_id, {})
	return state.get("solved", false)


func _is_solved_by_id(puzzle_id: StringName) -> bool:
	var state: Dictionary = _puzzle_states.get(puzzle_id, {})
	return state.get("solved", false)


func _check_retroactive_steps(puzzle: PuzzleResource) -> void:
	var state: Dictionary = _puzzle_states[puzzle.puzzle_id]
	for i in puzzle.steps.size():
		if _is_step_done(puzzle, i):
			continue
		var step := puzzle.steps[i]
		# Check if TalkToNPC flags were already set
		if step.step_type == PuzzleStep.StepType.TALK_TO_NPC:
			if step.dialogue_flag != &"" and GameState.get_puzzle_flag(step.dialogue_flag):
	
				state["steps_done"].append(i)
				EventBus.puzzle_step_completed.emit(puzzle.puzzle_id, i)
		# Check if CollectItem was already picked up
		if step.step_type == PuzzleStep.StepType.COLLECT_ITEM:
			if InventoryManager.has_item(step.item_id):
				state["steps_done"].append(i)
				EventBus.puzzle_step_completed.emit(puzzle.puzzle_id, i)


func _is_step_done(puzzle: PuzzleResource, step_index: int) -> bool:
	var state: Dictionary = _puzzle_states.get(puzzle.puzzle_id, {})
	return step_index in state.get("steps_done", [])
