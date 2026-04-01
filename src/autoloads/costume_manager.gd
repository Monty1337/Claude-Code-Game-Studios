## Costume registry — tracks which player wears which costume.
## Enforces no-duplicate rule in multiplayer.
## See: Costume System GDD
extends Node

## Costume data — will be replaced by CostumeResource files later.
var _costume_data: Dictionary = {
	&"pirate": {
		"display_name": "Der Pirat",
		"personality_tag": &"boastful",
		"description": "Takes everything too seriously, threatens inanimate objects.",
		"body_color": Color(0.2, 0.15, 0.1),
	},
	&"clown": {
		"display_name": "Der Clown",
		"personality_tag": &"mischievous",
		"description": "Physical comedy, honks at inappropriate moments.",
		"body_color": Color(0.9, 0.2, 0.2),
	},
	&"knight": {
		"display_name": "Der Ritter",
		"personality_tag": &"chivalrous",
		"description": "Treats every situation as a medieval quest.",
		"body_color": Color(0.6, 0.6, 0.65),
	},
	&"witch": {
		"display_name": "Die Hexe",
		"personality_tag": &"theatrical",
		"description": "Pronounces everything as a dark omen.",
		"body_color": Color(0.3, 0.1, 0.4),
	},
}

## Player -> costume_id mapping
var _assignments: Dictionary = {}  # int (player_index) -> StringName


func get_available_costumes() -> Array[StringName]:
	var available: Array[StringName] = []
	var taken := _assignments.values()
	for id in _costume_data.keys():
		if id not in taken:
			available.append(id)
	return available


func assign_costume(player_index: int, costume_id: StringName) -> bool:
	if costume_id not in _costume_data:
		return false
	# Check no duplicate
	if costume_id in _assignments.values():
		return false
	_assignments[player_index] = costume_id
	return true


func get_costume_id(player_index: int) -> StringName:
	return _assignments.get(player_index, &"")


func get_costume_data(costume_id: StringName) -> Dictionary:
	return _costume_data.get(costume_id, {})


func get_personality_tag(player_index: int) -> StringName:
	var costume_id := get_costume_id(player_index)
	var data := get_costume_data(costume_id)
	return data.get("personality_tag", &"default")


func is_assigned(costume_id: StringName) -> bool:
	return costume_id in _assignments.values()


func clear_assignments() -> void:
	_assignments.clear()
