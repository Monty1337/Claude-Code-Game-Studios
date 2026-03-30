# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the investigate-interact-solve loop feel fun?
# Date: 2026-03-30
extends Node

signal interaction_started(target: Node, player: Node)
signal interaction_ended(target: Node, player: Node)
signal item_picked_up(item_id: StringName, player: Node)
signal item_used(item_id: StringName, target_id: StringName, success: bool)
signal puzzle_step_completed(puzzle_id: StringName, step_index: int)
signal puzzle_solved(puzzle_id: StringName)
signal dialogue_started(npc_id: StringName, player: Node)
signal dialogue_ended(npc_id: StringName)
signal hop_landed(player: Node, position: Vector3)
signal prompt_show(text: String, position: Vector3)
signal prompt_hide()
signal show_message(text: String, duration: float)
