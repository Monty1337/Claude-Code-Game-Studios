## Tracks puzzle progress and offers progressive hints when the player is stuck.
## Hints are delivered via EventBus.show_message as NPC gossip.
## See: Hint System concept, Puzzle System GDD
class_name HintManager
extends Node

@export var hint_delay: float = 180.0  # Seconds before first hint (3 min)
@export var hint_repeat: float = 120.0  # Seconds between subsequent hints

## Puzzle hints — array of arrays. Outer = puzzle index, inner = progressive hints.
## Vague first, specific last.
@export var puzzle_hints: Dictionary = {}  # StringName (puzzle_id) -> Array[String]

var _time_since_progress: float = 0.0
var _hint_index: Dictionary = {}  # puzzle_id -> int (how many hints given)
var _active_puzzles: Array[StringName] = []
var _any_puzzle_solved_recently := false


func _ready() -> void:
	EventBus.puzzle_step_completed.connect(_on_progress)
	EventBus.puzzle_solved.connect(_on_puzzle_solved)
	EventBus.item_picked_up.connect(func(_id, _p): _on_progress(&"", 0))


func _process(delta: float) -> void:
	if _active_puzzles.is_empty():
		return

	_time_since_progress += delta

	if _time_since_progress >= hint_delay:
		_offer_hint()
		_time_since_progress = 0.0
		# After first hint, use shorter repeat interval
		hint_delay = hint_repeat


func set_active_puzzles(puzzle_ids: Array[StringName]) -> void:
	_active_puzzles = puzzle_ids
	for pid in puzzle_ids:
		if pid not in _hint_index:
			_hint_index[pid] = 0


func _on_progress(_puzzle_id: StringName, _step: int) -> void:
	_time_since_progress = 0.0


func _on_puzzle_solved(puzzle_id: StringName) -> void:
	_active_puzzles.erase(puzzle_id)
	_time_since_progress = 0.0


func _offer_hint() -> void:
	# Find the first unsolved puzzle with hints available
	for pid in _active_puzzles:
		if pid not in puzzle_hints:
			continue
		var hints: Array = puzzle_hints[pid]
		var idx: int = _hint_index.get(pid, 0)
		if idx >= hints.size():
			continue  # All hints exhausted for this puzzle

		EventBus.show_message.emit("Gossip:\n" + str(hints[idx]), 5.0)
		_hint_index[pid] = idx + 1
		return  # Only one hint at a time
