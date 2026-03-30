# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the investigate-interact-solve loop feel fun?
# Date: 2026-03-30
extends Node

var items: Array[StringName] = []

func add_item(item_id: StringName) -> void:
	items.append(item_id)

func has_item(item_id: StringName) -> bool:
	return item_id in items

func remove_item(item_id: StringName) -> void:
	var idx := items.find(item_id)
	if idx >= 0:
		items.remove_at(idx)

func get_items() -> Array[StringName]:
	return items
