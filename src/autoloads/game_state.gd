## Persistent game state that survives scene transitions.
## Tracks puzzle flags, curse level, chapter progress, and conversation history.
## See: ADR-0001, Puzzle System GDD, World/Environment GDD
extends Node

var _puzzle_flags: Dictionary = {}  # StringName -> bool
var _curse_level: float = 0.0       # 0.0 = fully cursed, 1.0 = liberated
var _current_chapter: int = 1
var _conversations_had: Dictionary = {}  # StringName -> int (npc_id -> talk count)


# -- Puzzle Flags --

func get_puzzle_flag(flag: StringName) -> bool:
	return _puzzle_flags.get(flag, false)


func set_puzzle_flag(flag: StringName, value: bool) -> void:
	_puzzle_flags[flag] = value
	EventBus.puzzle_flag_set.emit(flag, value)


# -- Curse Level --

func get_curse_level() -> float:
	return _curse_level


func advance_curse(delta: float) -> void:
	_curse_level = clampf(_curse_level + delta, 0.0, 1.0)
	EventBus.curse_level_changed.emit(_curse_level)


# -- Chapter --

func get_chapter() -> int:
	return _current_chapter


func set_chapter(chapter: int) -> void:
	_current_chapter = chapter


# -- Conversation Tracking --

func record_conversation(npc_id: StringName) -> void:
	_conversations_had[npc_id] = _conversations_had.get(npc_id, 0) + 1


func get_conversation_count(npc_id: StringName) -> int:
	return _conversations_had.get(npc_id, 0)


# -- Serialization (for future save/load) --

func serialize() -> Dictionary:
	return {
		"puzzle_flags": _puzzle_flags.duplicate(),
		"curse_level": _curse_level,
		"current_chapter": _current_chapter,
		"conversations_had": _conversations_had.duplicate(),
	}


func deserialize(data: Dictionary) -> void:
	_puzzle_flags = data.get("puzzle_flags", {})
	_curse_level = data.get("curse_level", 0.0)
	_current_chapter = data.get("current_chapter", 1)
	_conversations_had = data.get("conversations_had", {})


func reset() -> void:
	_puzzle_flags.clear()
	_curse_level = 0.0
	_current_chapter = 1
	_conversations_had.clear()
