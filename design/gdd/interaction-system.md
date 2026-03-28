# Interaction System

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-28
> **Implements Pillar**: All (Jeck sein, Zosamme, Echt Kull)

## Overview

The Interaction System is the bridge between the player and everything in the
game world — NPCs, items, doors, puzzle elements, and environmental objects.
It handles target detection (raycast from camera), proximity checks, interaction
prompts (UI labels showing what can be interacted with), and dispatching
interaction events to the appropriate downstream system (Dialogue, Item, Puzzle,
etc.). The player actively triggers interactions via a button press; the system
determines *what* they're interacting with and routes the event accordingly.
Without this system, the player can walk around but cannot touch, talk to,
pick up, or affect anything in the world.

## Player Fantasy

> **"I see something interesting, I press a button, something fun happens."**

The interaction system should feel invisible — the player never thinks about *how*
they interact, only *what* they interact with. Prompts appear naturally when
looking at something reachable. The button press is instant and responsive.
The system serves all three pillars: **Jeck sein** by making every interaction
a potential comedy moment, **Zosamme** by letting multiple players interact with
the same world simultaneously, and **Echt Kull** by surfacing authentic Karneval
objects and traditions as things you can poke, examine, and engage with.

## Detailed Design

### Core Rules

1. **Detection**: Hybrid proximity + raycast. Every physics frame:
   a. Find all interactable nodes within `INTERACT_RADIUS` of the player
   b. Cast a ray from camera center into the scene
   c. If ray hits an interactable, that's the **primary target**
   d. If ray misses all interactables, pick the closest one to the player's
      facing direction within the radius
   e. If no interactables in radius, no target (prompt hidden)
2. **Interactable interface**: Any node that wants to be interactable implements
   a common contract:
   - `interaction_type`: enum (`NPC`, `Item`, `Door`, `PuzzleElement`,
     `Environmental`)
   - `interaction_label`: String (displayed in prompt, e.g., "Talk", "Pick up",
     "Open", "Examine")
   - `interact(player: PlayerCharacter)`: called when the player confirms
     interaction
   - `is_available()`: bool — can this be interacted with right now? (e.g.,
     door already open = false)
3. **Prompt display**: When a target is detected, show a UI prompt near the
   target: "[E] Talk to Köbes" or "[E] Pick up Kölsch glass". Prompt disappears
   when target is lost.
4. **Interaction trigger**: Player presses interact button → system calls
   `interact(player)` on the current target → target's owning system handles
   the result (Dialogue opens, Item is picked up, etc.)
5. **One interaction at a time**: Player enters "Interacting" state (per Player
   Character GDD). Cannot start a new interaction until the current one ends.
6. **Multiplayer**: Each player has their own interaction detection. Multiple
   players can interact with different targets simultaneously. Two players
   interacting with the same NPC: both get dialogue (NPC doesn't "lock").

### States and Transitions

| State | Description | Transitions To |
|-------|-------------|---------------|
| **Scanning** | Actively detecting targets each frame | Target Found |
| **Target Found** | A valid target detected, prompt displayed | Scanning (target lost), Dispatched (player presses interact) |
| **Dispatched** | Interaction event sent to target's system, awaiting completion | Scanning (interaction ends) |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Player Character** | Reads from | `global_position`, `global_basis` for proximity/facing. `interaction_pressed` signal triggers dispatch. Sets player to Interacting state. |
| **World/Environment** | Reads from | `Area3D` shapes on interactable objects for raycast/proximity detection |
| **Item System** | Dispatches to | Calls `interact(player)` on items with `interaction_type = Item` |
| **Dialogue System** | Dispatches to | Calls `interact(player)` on NPCs with `interaction_type = NPC` |
| **Puzzle System** | Dispatches to | Calls `interact(player)` on puzzle elements with `interaction_type = PuzzleElement` |
| **Mini-Task System** | Dispatches to | Calls `interact(player)` on mini-task triggers with `interaction_type = PuzzleElement` |
| **Feedback System** | Signals to | Emits `interaction_started(target)` and `interaction_ended(target)` for visual/audio feedback |
| **UI System** | Provides to | Prompt data: target position, label text, input icon |

## Formulas

```
Target Selection Priority:
  1. Raycast hit (if hits an interactable) -> highest priority
  2. Facing alignment = dot(player_facing, direction_to_target)
     Pick target with highest dot product (closest to facing)
     Minimum threshold: FACING_THRESHOLD = 0.5 (~60 degree cone)
  3. Distance tiebreaker: if equal facing, pick nearest

Proximity Detection:
  INTERACT_RADIUS = 3.0 m | Range: 1.5-5.0
  Raycast length = INTERACT_RADIUS (same range)

Prompt Positioning:
  prompt_screen_pos = camera.unproject_position(target.global_position + PROMPT_OFFSET)
  PROMPT_OFFSET = Vector3(0, 1.5, 0)  -- above target's head
```

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| **Two interactables at equal distance and facing** | Prefer raycast target. If neither hit by ray, prefer the one closer to screen center. |
| **Interactable becomes unavailable mid-approach** | `is_available()` checked every frame. Prompt disappears if target becomes unavailable. |
| **Player spams interact button** | Ignored while in Dispatched state. One interaction at a time. |
| **Target destroyed/removed during interaction** | Interaction ends gracefully. Player returns to Idle. No crash. |
| **Two players interact with same item** | First player picks it up. Second player's prompt updates (item gone = no target). Item System handles depletion. |
| **Two players interact with same NPC** | Both get dialogue simultaneously. NPC doesn't lock. Each player sees their own costume-specific dialogue. |
| **Interactable behind a wall** | Raycast is blocked by wall collision. Proximity still detects it but facing alignment won't select it if a wall is between (raycast miss = lower priority). |
| **No interactables in scene** | System stays in Scanning state. No prompt shown. No errors. |

## Dependencies

| System | Relationship | Interface | Hard/Soft |
|--------|-------------|-----------|-----------|
| **Player Character** | Depends on | Position, facing, interaction signal, Interacting state | Hard |
| **World/Environment** | Depends on | Area3D collision shapes on interactable objects | Hard |
| **Item System** | Depended on by | Dispatches `interact(player)` to Item-type targets | Hard |
| **Dialogue System** | Depended on by | Dispatches `interact(player)` to NPC-type targets | Hard |
| **Puzzle System** | Depended on by | Dispatches `interact(player)` to PuzzleElement-type targets | Hard |
| **Mini-Task System** | Depended on by | Dispatches via PuzzleElement type | Hard |
| **Hint System** | Depended on by | Hint NPCs use NPC interaction type | Soft |
| **Feedback System** | Depended on by | `interaction_started`/`interaction_ended` signals | Soft |
| **UI System** | Depended on by | Prompt position, label, and input icon data | Hard |

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too Low | Too High |
|------|---------|-----------|---------|---------|----------|
| `INTERACT_RADIUS` | 3.0 m | 1.5–5.0 | How close you need to be to interact | Must stand on top of target | Interact with things across the street |
| `FACING_THRESHOLD` | 0.5 | 0.3–0.8 | How precisely you must face a target (dot product) | Must look directly at it | Interacts with things behind you |
| `PROMPT_OFFSET` | (0, 1.5, 0) | Y: 1.0–2.5 | Where prompt floats above target | Prompt clips into target | Prompt floats too high to read |
| `RAYCAST_LAYER` | Interactable layer | — | Which collision layer raycast checks | — | — |

**Knob interactions**: `INTERACT_RADIUS` and Player Character's `CAM_DISTANCE`
should be considered together — if camera is far, radius may need to be larger
to match visual expectation.

## Acceptance Criteria

**Detection:**
- [ ] Raycast selects the interactable the player is looking at
- [ ] When raycast misses, the closest-to-facing target within radius is selected
- [ ] Targets outside `INTERACT_RADIUS` are never detected
- [ ] Targets behind walls are not prioritized over visible targets

**Prompts:**
- [ ] Prompt appears when target is detected, disappears when lost
- [ ] Prompt shows correct label ("Talk", "Pick up", etc.) and input icon
- [ ] Prompt position tracks target smoothly (no jitter)

**Dispatch:**
- [ ] Pressing interact calls `interact(player)` on the current target
- [ ] Player enters Interacting state and movement locks
- [ ] Player cannot start a second interaction while one is active
- [ ] Interaction ends cleanly and player returns to Idle

**Multiplayer:**
- [ ] Each player has independent target detection
- [ ] Two players can interact with different targets simultaneously
- [ ] Two players can both talk to the same NPC simultaneously

**Interface Contract:**
- [ ] All interactable types (NPC, Item, Door, PuzzleElement, Environmental) work through the same interface
- [ ] `is_available()` correctly hides unavailable targets
