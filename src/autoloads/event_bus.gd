## Global signal bus for decoupled cross-system communication.
## All cross-system signals are declared here. Systems emit and connect
## to these signals without needing direct references to each other.
## See: ADR-0001, docs/architecture/adr-0001-scene-structure-and-state-management.md
extends Node

# -- Interaction --
signal interaction_started(target: Node, player: Node)
signal interaction_ended(target: Node, player: Node)

# -- Items --
signal item_picked_up(item_id: StringName, player: Node)
signal item_used(item_id: StringName, target_id: StringName, success: bool)

# -- Puzzles --
signal puzzle_step_completed(puzzle_id: StringName, step_index: int)
signal puzzle_solved(puzzle_id: StringName)
signal chapter_completed(chapter: int)
signal puzzle_flag_set(flag_name: StringName, value: bool)

# -- NPCs / Dialogue --
signal dialogue_started(npc_id: StringName, player: Node)
signal dialogue_ended(npc_id: StringName)
signal npc_startled(npc_id: StringName, position: Vector3)

# -- Player --
signal hop_landed(player: Node, position: Vector3)

# -- Curse --
signal curse_level_changed(new_level: float)

# -- UI --
signal prompt_show(text: String, world_position: Vector3)
signal prompt_hide()
signal show_message(text: String, duration: float)
