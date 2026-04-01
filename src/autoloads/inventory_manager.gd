## Shared inventory for all players.
## Simple list-based inventory — no weight, no slots, no limits.
## See: Item System GDD
extends Node

var _items: Array[StringName] = []


func add_item(item_id: StringName) -> void:
	_items.append(item_id)
	EventBus.item_picked_up.emit(item_id, null)


func remove_item(item_id: StringName) -> bool:
	var idx := _items.find(item_id)
	if idx >= 0:
		_items.remove_at(idx)
		return true
	return false


func has_item(item_id: StringName) -> bool:
	return item_id in _items


func get_items() -> Array[StringName]:
	return _items


func clear() -> void:
	_items.clear()


func serialize() -> Array[StringName]:
	return _items.duplicate()


func deserialize(data: Array) -> void:
	_items.clear()
	for item in data:
		_items.append(StringName(item))
