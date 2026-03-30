# NPC System

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-30
> **Implements Pillar**: Echt Kull (Authentically Karneval), Jeck sein (Be Silly)

## Overview

The NPC System manages all non-player characters in the game world — from
puzzle-relevant story characters to background crowd NPCs that bring the
Karneval to life. Each NPC is placed at markers defined by the World/Environment
system and follows simple behavior routines (patrol waypoints, idle activities).
NPCs implement the Interaction System's interactable interface, allowing players
to talk to them. Story NPCs have deep, costume-dependent dialogue; crowd NPCs
have short flavor lines. NPCs have no physics collision with players but react
with startled animations when walked through. Without this system, the cursed
town would be empty — and Karneval without people isn't Karneval.

## Player Fantasy

> **"The whole town is cursed, and every person I meet is stuck in their own
> ridiculous situation."**

NPCs are the heart of the comedy. Each story NPC is a memorable character with
their own curse problem — a Köbes who can't stop serving Kölsch, a tourist
who only speaks in Büttenrede rhymes, a Funkenmariechen who can't stop dancing.
Crowd NPCs fill the streets with life — arguing, celebrating, stumbling around
in their stuck costumes. The town should feel like a Karneval that refused to
end. This serves **Echt Kull** (authentic Karneval characters and culture) and
**Jeck sein** (every NPC interaction is a potential laugh).

## Detailed Design

### Core Rules

1. **Two NPC tiers**:
   - **Story NPCs**: Named characters with unique models, deep dialogue trees,
     costume-dependent lines, and puzzle relevance. ~4-6 per chapter.
   - **Crowd NPCs**: Background characters with shared/generic models, 1-3 short
     flavor lines, simple routines. ~10-15 per chapter. Provide atmosphere.
2. **NPC data resource**: Each NPC is defined as a Resource:
   - `npc_id`: StringName
   - `display_name`: String (e.g., "Der Köbes", "Confused Tourist")
   - `npc_tier`: enum (`Story`, `Crowd`)
   - `model`: PackedScene (unique for Story, shared pool for Crowd)
   - `costume_description`: String (what Karneval costume they're stuck in)
   - `routine_waypoints`: Array[Node3D] (positions for patrol/idle behavior)
   - `routine_actions`: Array[StringName] (what they do at each waypoint)
   - `interaction_label`: String (default "Talk to [display_name]")
   - `dialogue_key`: StringName (reference for Dialogue System to look up lines)
   - `puzzle_relevant`: bool (does this NPC have puzzle information or items?)
3. **Behavior routines**: NPCs cycle through their `routine_waypoints` in order:
   - Walk to next waypoint at `NPC_WALK_SPEED`
   - Perform the action at that waypoint for `ACTION_DURATION`
   - Move to next waypoint
   - Repeat (loop back to first waypoint)
4. **Player proximity reaction**: When a player enters `AWARENESS_RADIUS`:
   - NPC turns head toward the player (look-at)
   - If player walks through NPC (pass-through collision): startled animation +
     short reaction sound
5. **Interaction behavior**: When a player interacts (via Interaction System):
   - NPC pauses routine
   - NPC faces the player
   - Dialogue System takes over (Dialogue System owns the conversation flow)
   - When dialogue ends, NPC resumes routine from current waypoint
6. **Interactable contract** (per Interaction System GDD):
   - `interaction_type = NPC`
   - `interaction_label = "Talk to [display_name]"`
   - `interact(player)` -> signals Dialogue System with `(npc_id, player)`
   - `is_available()` -> true unless NPC is already in dialogue with another
     player (Crowd NPCs) or always true (Story NPCs — multiple players can
     talk to same Story NPC simultaneously)
7. **Navigation**: NPCs use Godot's `NavigationAgent3D` for pathfinding between
   waypoints. Crowd NPCs share the same navmesh as players.

### States and Transitions

| State | Description | Transitions To |
|-------|-------------|---------------|
| **Routine** | Following waypoint patrol cycle | Aware (player nearby), InDialogue (interaction triggered) |
| **Aware** | Player within awareness radius, NPC looks at them | Routine (player leaves radius), InDialogue (interaction) |
| **InDialogue** | Routine paused, facing player, Dialogue System active | Routine (dialogue ends) |
| **Startled** | Brief reaction to player walking through | Routine (animation finishes, ~0.5s) |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **World/Environment** | Depends on | NPC spawn markers (`Node3D` positions) define initial placement |
| **Interaction System** | Implements | Interactable interface (`interaction_type`, `interact()`, `is_available()`) |
| **Dialogue System** | Dispatches to | `interact(player)` signals Dialogue System with `(npc_id, player.costume_id)` — Dialogue System owns conversation flow |
| **Costume System** | Reads from | Player's `costume_id`/`personality_tag` passed to Dialogue System for costume-dependent NPC responses |
| **Puzzle System** | Provides to | Story NPCs with `puzzle_relevant = true` can provide clues, accept items, or unlock puzzle states |
| **Hint System** | Provides to | Hint NPCs are Story NPCs that provide progressive puzzle hints disguised as gossip |
| **Player Character** | Reacts to | No collision — pass-through with startled reaction animation |

## Formulas

```
NPC Walk Speed:
  NPC_WALK_SPEED = 1.5 m/s | Range: 0.5-3.0
  (Slower than player walk speed of 3.0 -- NPCs are casual, not rushing)

Action Duration at Waypoint:
  ACTION_DURATION = random_range(MIN_ACTION_TIME, MAX_ACTION_TIME)
    MIN_ACTION_TIME = 5.0s | Range: 2.0-10.0
    MAX_ACTION_TIME = 15.0s | Range: 5.0-30.0
  (Randomized so NPCs don't feel robotic)

Awareness Radius:
  AWARENESS_RADIUS = 5.0 m | Range: 3.0-8.0
  (Larger than Interaction System's INTERACT_RADIUS of 3.0 -- NPC notices
   you before you can interact)

Head Turn Speed:
  HEAD_TURN_SPEED = 90 deg/s | Range: 45-180

NPC Counts per Chapter:
  Story NPCs: 4-6
  Crowd NPCs: 10-15
  Total: ~15-20 per chapter
  Total game (3 chapters): ~45-60 NPCs
  Unique models needed: 4-6 Story + ~5 shared Crowd models = ~11 models
```

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| **Two players talk to same Story NPC** | Both get dialogue simultaneously. Each sees their own costume-specific lines. Story NPCs are always available. |
| **Two players talk to same Crowd NPC** | Second player sees "Busy" -- `is_available()` returns false while Crowd NPC is in dialogue. Crowd NPCs lock to one conversation. |
| **NPC reaches waypoint that's blocked** | NavigationAgent3D reroutes. If stuck for >5s, teleport to next waypoint (invisible to player). |
| **Player interacts with NPC mid-walk** | NPC stops walking, faces player, enters InDialogue. Resumes from interrupted position when dialogue ends. |
| **NPC walked through by multiple players rapidly** | Startled animation plays once, then cooldown of 3s before it can trigger again. Prevents animation spam. |
| **Story NPC removed from scene (bug)** | Puzzle System checks NPC availability. If missing, log error and provide fallback puzzle hint via Hint System. |
| **No free Crowd NPC models** | Crowd NPCs reuse models from a shared pool. Same model can appear multiple times -- acceptable for background characters. |
| **NPC pathfinding fails (no navmesh)** | NPC stays at spawn marker and plays idle animation. Functional but static -- fails gracefully. |

## Dependencies

| System | Relationship | Interface | Hard/Soft |
|--------|-------------|-----------|-----------|
| **World/Environment** | Depends on | NPC spawn markers (`Node3D`) and navmesh for pathfinding | Hard |
| **Interaction System** | Implements | Interactable interface for player-NPC interaction | Hard |
| **Dialogue System** | Depended on by | `interact(player)` dispatches to Dialogue System with `npc_id` + `costume_id` | Hard |
| **Costume System** | Reads from | Player's `costume_id` forwarded to Dialogue System | Hard |
| **Puzzle System** | Depended on by | Story NPCs with `puzzle_relevant = true` provide clues or accept items | Hard |
| **Hint System** | Depended on by | Designated hint NPCs deliver progressive puzzle hints | Soft |
| **Player Character** | Reacts to | Pass-through collision triggers startled animation | Soft |
| **Feedback System** | Depended on by | NPC reaction sounds and startled effects | Soft |

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too Low | Too High |
|------|---------|-----------|---------|---------|----------|
| `NPC_WALK_SPEED` | 1.5 m/s | 0.5-3.0 | How fast NPCs patrol | Glacially slow, feels broken | Faster than players, immersion-breaking |
| `MIN_ACTION_TIME` | 5.0s | 2.0-10.0 | Minimum time at waypoint | Restless, twitchy NPCs | NPCs barely move |
| `MAX_ACTION_TIME` | 15.0s | 5.0-30.0 | Maximum time at waypoint | All NPCs feel identical | NPCs feel frozen |
| `AWARENESS_RADIUS` | 5.0 m | 3.0-8.0 | When NPC notices player | Only notices at point-blank | Notices from across the street |
| `HEAD_TURN_SPEED` | 90 deg/s | 45-180 | How fast NPC looks at player | Sluggish head tracking | Snappy, robotic |
| `STARTLED_COOLDOWN` | 3.0s | 1.0-5.0 | Time before startled can trigger again | Constant startled spam | Very hard to trigger twice |
| `CROWD_NPC_COUNT` | 12 | 8-20 | Background NPCs per chapter | Empty streets | Performance risk |

**Performance note**: `CROWD_NPC_COUNT` directly impacts pathfinding load. At 15+
NPCs with NavigationAgent3D, monitor frame budget. Consider disabling pathfinding
for distant Crowd NPCs (use simple waypoint lerp instead).

## Acceptance Criteria

**Behavior:**
- [ ] Story NPCs follow waypoint routines and perform actions at each stop
- [ ] Crowd NPCs patrol and idle with randomized timing
- [ ] NPCs turn to look at players within awareness radius
- [ ] NPCs pause routine and face player during dialogue
- [ ] NPCs resume routine from current position after dialogue ends

**Interaction:**
- [ ] All NPCs implement the interactable interface correctly
- [ ] Story NPCs are always available for interaction (even with multiple players)
- [ ] Crowd NPCs lock to one conversation at a time
- [ ] Walking through an NPC triggers startled animation (with cooldown)

**Performance:**
- [ ] 15-20 NPCs per scene with pathfinding at <= 2ms total frame cost
- [ ] Crowd NPCs beyond render distance are culled or simplified

**Data-Driven:**
- [ ] Adding a new NPC requires only creating a new NPC Resource -- no code changes
- [ ] NPC routines are defined via waypoint markers in the scene, not in script
