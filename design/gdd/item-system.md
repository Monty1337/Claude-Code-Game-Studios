# Item System

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-30
> **Implements Pillar**: Jeck sein (Be Silly), Echt Kull (Authentically Karneval)

## Overview

The Item System manages pickable objects in the game world — Karneval-themed
items that players find, carry, examine, and use to solve puzzles. Items exist
in the world as interactable 3D objects (placed at markers by the World/Environment
system) and move into a simple unlimited inventory when picked up. Players can
examine items for descriptions and humor, use items on puzzle elements or NPCs,
and combine items when required by a puzzle. There is no weight, no slots, no
crafting — just find things and figure out where they go. Without this system,
puzzles would have no tangible objects to manipulate.

## Player Fantasy

> **"What's this weird thing? I bet I need it for something."**

Every item should spark curiosity and humor. A half-eaten Berliner, a suspicious
Kölsch coaster with writing on it, a Narrenkappe that hums when shaken. Picking
up items should feel rewarding (funny description, satisfying sound) and using
them should produce comedic results — especially wrong answers. This serves
**Jeck sein** (items are comedy props) and **Echt Kull** (items are real
Karneval objects — Kamelle, Orden, Strüßjer, Kölschgläser).

## Detailed Design

### Core Rules

1. **Item data resource**: Each item is a Resource:
   - `item_id`: StringName
   - `display_name`: String (e.g., "Mysteriöses Kölschglas")
   - `description`: String (humorous examine text)
   - `model`: PackedScene (3D model for world placement)
   - `icon`: Texture2D (for inventory UI)
   - `is_key_item`: bool (puzzle-critical items cannot be discarded)
   - `use_targets`: Array[StringName] (valid `npc_id` or `puzzle_element_id`
     this item can be used on)
   - `wrong_use_response`: String (funny text when used on the wrong target)
2. **Picking up**: Player interacts with a world item (via Interaction System).
   Item is removed from the world and added to the shared inventory. Pickup
   animation + sound plays.
3. **Shared inventory**: One inventory for the entire party. Any player can pick
   up items; any player can use them. In solo, it's just the player's inventory.
4. **Examining**: Player can select an item in inventory to read its description.
   Descriptions are humorous and may contain puzzle hints.
5. **Using items**: Player selects an item from inventory, then targets an NPC or
   puzzle element in the world. If target is in the item's `use_targets`: success
   (Puzzle System handles the result). If not: funny failure text
   (`wrong_use_response`).
6. **No combining**: Items are not combined with each other -- only used on world
   targets. Keeps the system simple.
7. **No discarding key items**: Items with `is_key_item = true` cannot be dropped.
   Non-key flavor items can be dropped back into the world.
8. **Interactable contract** (per Interaction System GDD):
   - `interaction_type = Item`
   - `interaction_label = "Pick up [display_name]"`
   - `interact(player)` -> removes item from world, adds to shared inventory
   - `is_available()` -> true if item is still in the world (not yet picked up)

### States and Transitions (Item Lifecycle)

| State | Description | Transitions To |
|-------|-------------|---------------|
| **InWorld** | Item exists as a 3D object at its spawn marker | InInventory (player picks up) |
| **InInventory** | Item is in the shared inventory, accessible via UI | Used (used on valid target), InWorld (dropped, non-key only) |
| **Used** | Item consumed by puzzle. Removed from inventory. | (Terminal -- item is gone) |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Interaction System** | Implements | Interactable interface for world items (pick up) |
| **World/Environment** | Depends on | Item spawn markers (`Node3D`) define where items appear |
| **Puzzle System** | Depended on by | `use_item(item_id, target_id)` -> Puzzle System validates and handles success/failure |
| **NPC System** | Used with | Items can be used on NPCs (give item to NPC as part of a puzzle) |
| **UI System** | Provides to | Inventory contents, item icons, descriptions for inventory display |
| **Feedback System** | Signals to | `item_picked_up(item_id)`, `item_used(item_id, target_id)` for pickup/use sounds and effects |
| **Save/Load System** | Provides to | Inventory state (which items are carried, which are used) for save data |

## Formulas

```
No complex math -- this is a simple adventure game inventory.

Item Count Budget per Chapter:
  Puzzle-critical items: 3-5 per chapter (one per puzzle step)
  Flavor/optional items: 2-3 per chapter (funny but not required)
  Total items per chapter: ~5-8
  Total game (3 chapters): ~15-24 items
  Unique 3D models needed: ~15-24 (each item is visually distinct)
  Unique icons needed: same count

Inventory Size:
  MAX_ITEMS = unlimited (no cap)
  Typical carry at any time: 2-5 items (puzzles consume items as you go)
```

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| **Two players try to pick up same item simultaneously** | First `interact()` call wins. Item removed from world. Second player's prompt disappears (Interaction System handles via `is_available()`). |
| **Player uses item on wrong target** | Display `wrong_use_response` text. Item is NOT consumed. Player can try again. |
| **Player tries to drop a key item** | Blocked. Show message: "You can't get rid of this -- it seems important." |
| **Item used but puzzle state not ready** | Puzzle System rejects the use. Item stays in inventory. Contextual hint: "Maybe I need something else first." |
| **Player picks up item they already have (duplicate)** | Not possible -- each item is a unique world object. Once picked up, it's gone from the world. |
| **Inventory checked by player who didn't pick up the item** | Works fine -- shared inventory. All players see all items. |
| **Item model fails to load** | Item still functions (inventory icon + description work). World representation shows a fallback placeholder mesh. |
| **All items picked up, puzzle not solved** | Intended state -- player may need to use items, talk to NPCs, or examine items for hints. Hint System provides guidance. |

## Dependencies

| System | Relationship | Interface | Hard/Soft |
|--------|-------------|-----------|-----------|
| **Interaction System** | Depends on | Implements interactable interface for pickup | Hard |
| **World/Environment** | Depends on | Item spawn markers (`Node3D`) | Hard |
| **Puzzle System** | Depended on by | `use_item(item_id, target_id)` validates and consumes items | Hard |
| **NPC System** | Used with | Items can target NPCs via `use_targets` | Soft |
| **UI System** | Depended on by | Inventory display (icons, names, descriptions) | Hard |
| **Feedback System** | Depended on by | Pickup/use sound and particle signals | Soft |
| **Save/Load System** | Depended on by | Inventory state serialization | Soft |

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too Low | Too High |
|------|---------|-----------|---------|---------|----------|
| `PICKUP_ANIM_DURATION` | 0.5s | 0.2-1.0 | How long the pickup animation takes | Too fast to notice | Sluggish, breaks flow |
| `EXAMINE_TEXT_SPEED` | Instant | -- | How description text appears | -- | -- |
| `WRONG_USE_COOLDOWN` | 1.0s | 0.5-3.0 | Delay before player can try using item again after failure | Spam wrong-use responses | Frustrating wait |
| `ITEM_HIGHLIGHT_COLOR` | Gold glow | -- | Visual highlight on world items | -- | -- |
| `ITEM_BOB_SPEED` | 1.0 cycle/s | 0.5-2.0 | How fast world items bob/rotate | Static, easy to miss | Distracting |
| `ITEM_BOB_HEIGHT` | 0.1 m | 0.05-0.3 | How much world items bob up and down | Barely visible | Items look broken |

## Acceptance Criteria

**Pickup:**
- [ ] Player can pick up items via Interaction System
- [ ] Picked-up items are removed from the world
- [ ] Picked-up items appear in the shared inventory
- [ ] Pickup plays animation and sound feedback

**Inventory:**
- [ ] All players see the same shared inventory contents
- [ ] Players can examine items to read descriptions
- [ ] Key items cannot be discarded
- [ ] Non-key items can be dropped back into the world

**Using Items:**
- [ ] Items can be used on valid targets (NPCs, puzzle elements)
- [ ] Valid use consumes the item and triggers Puzzle System response
- [ ] Invalid use shows funny failure text and does NOT consume the item
- [ ] Items can only be used on targets listed in `use_targets`

**Data-Driven:**
- [ ] Adding a new item requires only creating a new Item Resource
- [ ] Item descriptions, use targets, and wrong-use responses are externalized
