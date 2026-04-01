## Save/load game state to a JSON file.
## Persists: chapter, puzzle flags, inventory, costume assignment, curse level.
extends Node

const SAVE_PATH := "user://savegame.json"


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var data: Dictionary = {
		"version": 1,
		"game_state": GameState.serialize(),
		"inventory": InventoryManager.serialize(),
		"costume_assignments": CostumeManager._assignments.duplicate(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to open save file: " + SAVE_PATH)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func load_game() -> bool:
	if not save_exists():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("Failed to parse save file")
		return false
	var data: Dictionary = json.data
	if data.get("version", 0) != 1:
		push_error("Unknown save version")
		return false

	GameState.deserialize(data.get("game_state", {}))
	InventoryManager.deserialize(data.get("inventory", []))

	# Restore costume assignments
	CostumeManager.clear_assignments()
	var assignments: Dictionary = data.get("costume_assignments", {})
	for key in assignments:
		var player_idx: int = int(key)
		var costume_id: StringName = StringName(assignments[key])
		CostumeManager._assignments[player_idx] = costume_id

	return true


func get_chapter_scene(chapter: int) -> String:
	match chapter:
		1: return "res://scenes/chapter_1.tscn"
		2: return "res://scenes/chapter_2.tscn"
		3: return "res://scenes/chapter_3.tscn"
		_: return "res://scenes/chapter_1.tscn"


func delete_save() -> void:
	if save_exists():
		DirAccess.remove_absolute(SAVE_PATH)
