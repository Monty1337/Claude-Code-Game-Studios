# Player Character

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Zosamme (Together), Jeck sein (Be Silly)

## Overview

The Player Character system is the first-person character controller that provides
the player's physical presence in the game world. It handles movement, a
first-person camera at head height, and serves as the anchor point for the
Interaction and Costume systems. The character communicates through text-only
dialogue with costume-specific personality. There is no combat, health, death, or
platforming — the controller is focused entirely on exploration, investigation,
and comedic expression. Without this system, the player has no way to exist in or
move through the Karneval world.

> **Design Note**: Originally designed as over-the-shoulder 3rd person. Changed to
> first person after prototype testing (2026-03-30) — first person felt more
> immersive and natural for the investigation gameplay.

## Player Fantasy

> **"I'm this ridiculous character now, and everything I do feels like being in costume."**

The player should feel like they're *inside* their costume — seeing the world
through the Pirate's eyes, the Clown's perspective. First person makes the
investigation feel personal: leaning in to read a sign, looking up at a building,
peering around a corner. Costume identity comes through in the hands/arms visible
at screen edges, costume-specific sounds, and how NPCs react to you. Moving
through the Karneval town should feel like wandering through a festival — relaxed,
curious, and slightly chaotic. The controller serves the **Jeck sein** pillar by
making exploration feel playful, and the **Zosamme** pillar by ensuring
multiplayer feels like being at the party together.

## Detailed Design

### Core Rules

1. **Movement**: WASD/left-stick controls character direction relative to camera
   facing. Movement is instant (no acceleration curve). Release input = immediate
   stop.
2. **Speed**: Two speeds — walk (default) and run (hold shift/button). No stamina.
3. **Hop**: Press space/button for a small hop (~0.5m height). Not for platforming
   — for expression and hopping over small obstacles (curbs, puddles, confetti
   piles). No fall damage.
4. **Auto-step**: Character automatically steps up small elevation changes (stairs,
   curbs) without needing to hop.
5. **Camera**: First-person at head height (~1.6m). Mouse/right-stick controls
   look direction. Standard FPS-style mouse look (captured cursor).
6. **Interaction facing**: The player looks at targets to select them. No
   automatic character rotation needed — camera direction IS facing direction.
7. **Costume visibility**: In first person, costume is visible via hands/arms at
   screen edges (viewmodel) and in the player's shadow. Other players see the
   full costume model in multiplayer. Costume identity is primarily conveyed
   through dialogue personality, NPC reactions, and costume-specific sounds.

### States and Transitions

| State | Description | Transitions To |
|-------|-------------|---------------|
| **Idle** | Standing still, playing idle animation | Moving, Hopping, Interacting |
| **Moving** | Walking or running | Idle, Hopping, Interacting |
| **Hopping** | Small hop, brief airborne | Idle, Moving (on land) |
| **Interacting** | Engaged with object/NPC (locked movement) | Idle (when interaction ends) |
| **In Cutscene** | Player input disabled, controlled by cutscene system | Idle (when cutscene ends) |

All transitions are instant (no blend delays that would eat responsiveness).

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Costume System** | Reads from | Costume ID determines which animation set, visual model, and dialogue personality to use |
| **Interaction System** | Provides to | Character position, facing direction, and interaction request signal. Interaction System handles raycasting and target selection. |
| **Local Multiplayer** | Provides to | Character spawning, input routing (which controller/keyboard controls which character) |
| **Feedback System** | Provides to | Character position for particle spawns (confetti on hop landing, etc.) |
| **Cutscene System** | Receives from | Movement lock signal, scripted position/rotation targets |

## Formulas

```
Walk Speed = WALK_SPEED (m/s)
  Default: 3.0 m/s | Range: 2.0–5.0

Run Speed = RUN_SPEED (m/s)
  Default: 6.0 m/s | Range: 4.0–8.0

Hop Height = HOP_HEIGHT (m)
  Default: 0.5 m | Range: 0.3–1.0

Hop Duration = 2 * sqrt(2 * HOP_HEIGHT / GRAVITY)
  At default (gravity 9.8): ~0.64s total airtime

Auto-Step Height = STEP_HEIGHT (m)
  Default: 0.3 m | Range: 0.1–0.5

Camera Height = CAM_HEIGHT (m)
  Default: 1.6 m | Range: 1.4–1.8

Mouse Sensitivity = MOUSE_SENSITIVITY
  Default: 0.002 | Range: 0.001–0.005

Vertical Look Limit = LOOK_LIMIT (rad)
  Default: PI/4 (~45 deg up/down) | Range: PI/6–PI/3
```

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| **Player hops off a ledge** | Character falls with gravity but takes no damage. Lands with a comedic stumble animation. No invisible walls — if the player finds a way off the map, they respawn at the nearest valid position. |
| **Camera inside wall/object** | First-person camera is at head height inside the collision capsule — clipping is unlikely. If the player is pushed into geometry, the CharacterBody3D physics prevents it. |
| **Player interacts while hopping** | Interaction is queued and executes on landing. Character does not interact mid-air. |
| **Player runs into NPC** | No physics collision with NPCs — characters pass through each other. NPCs play a startled reaction animation. Avoids griefing in multiplayer. |
| **Multiple players try to interact with same object** | Interaction System handles this (not Player Character). Player Character just sends the interaction request. |
| **Player walks into water/restricted area** | Soft boundary — character slows down and turns around (guided redirect). No death, no teleport. |
| **All costume animations not yet available** | Fallback to a shared default animation set. Costume-specific animations are additive, not required. |

## Dependencies

| System | Relationship | Interface | Hard/Soft |
|--------|-------------|-----------|-----------|
| **Costume System** | Depends on (reads) | Costume ID -> animation set, visual model, dialogue personality tag | Soft — character works with a default model if Costume System isn't ready |
| **Interaction System** | Depended on by | Exposes: character position (`global_position`), facing direction (`global_basis`), interaction request signal (`interaction_pressed`) | Hard — Interaction System cannot function without Player Character |
| **Local Multiplayer** | Depended on by | Exposes: character scene for instantiation, input device assignment slot | Hard — multiplayer needs characters to spawn |
| **Feedback System** | Depended on by | Exposes: character position for particle/SFX spawning, state change signals (`hop_landed`, `interaction_started`) | Soft — game works without feedback effects |
| **Cutscene System** | Depended on by | Receives: `enter_cutscene()` / `exit_cutscene()` calls that lock/unlock player input and set scripted transforms | Soft — cutscenes are Alpha tier, not MVP |
| **World/Environment** | Uses | Character moves on the environment's collision geometry (floor, walls, stairs). No explicit API — uses Godot's built-in `CharacterBody3D` physics. | Hard — character needs ground to walk on |

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too Low | Too High |
|------|---------|-----------|---------|---------|----------|
| `WALK_SPEED` | 3.0 m/s | 2.0–5.0 | Exploration pacing | Sluggish, frustrating | Overshoots interactions |
| `RUN_SPEED` | 6.0 m/s | 4.0–8.0 | Traversal speed | Running feels pointless | Hard to control, misses details |
| `HOP_HEIGHT` | 0.5 m | 0.3–1.0 | Expressiveness, obstacle clearance | Can't clear curbs | Feels like platforming |
| `STEP_HEIGHT` | 0.3 m | 0.1–0.5 | Stair/curb navigation | Gets stuck on small bumps | Walks up things that should block |
| `CAM_HEIGHT` | 1.6 m | 1.4–1.8 | Eye height | Too low, child perspective | Too high, floating |
| `MOUSE_SENSITIVITY` | 0.002 | 0.001–0.005 | Look speed | Sluggish | Disorienting |
| `LOOK_LIMIT` | PI/4 | PI/6–PI/3 | Vertical look range | Can barely look up/down | Can look straight up (disorienting) |

## Acceptance Criteria

**Movement:**
- [ ] Character moves in all 4 cardinal + 4 diagonal directions relative to camera
- [ ] Walk and run speeds match tuning knob values (3.0 / 6.0 m/s default)
- [ ] Movement stops instantly on input release (no slide)
- [ ] Character navigates stairs and ramps without getting stuck

**Hop:**
- [ ] Hop reaches ~0.5m height and clears standard curb-height obstacles
- [ ] No fall damage from any height
- [ ] Interaction input during hop is queued and executes on landing

**Camera:**
- [ ] First-person camera at head height (~1.6m)
- [ ] Mouse look is smooth and responsive
- [ ] Vertical look is clamped to ~45 degrees up/down
- [ ] Camera stays inside collision capsule (no wall clipping)

**Interactions:**
- [ ] Player looks at target to select it (camera direction = facing direction)
- [ ] Character movement locks during Interacting state
- [ ] Character returns to Idle when interaction ends

**Costumes:**
- [ ] Costume viewmodel (hands/arms) visible at screen edges
- [ ] Other players see full costume model in multiplayer
- [ ] Characters pass through NPCs without collision (NPC plays reaction)

**Multiplayer:**
- [ ] Up to 4 characters can be spawned simultaneously
- [ ] Each character responds only to its assigned input device
- [ ] All characters can move and interact independently
