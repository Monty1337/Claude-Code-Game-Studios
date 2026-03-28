# Player Character

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Zosamme (Together), Jeck sein (Be Silly)

## Overview

The Player Character system is the 3rd-person character controller that provides
the player's physical presence in the game world. It handles movement, an
over-the-shoulder camera, and serves as the anchor point for the Interaction and
Costume systems. The character communicates through text-only dialogue with
costume-specific personality, and expressive animations. There is no combat,
health, death, or platforming — the controller is focused entirely on exploration,
investigation, and comedic expression. Without this system, the player has no way
to exist in or move through the Karneval world.

## Player Fantasy

> **"I'm this ridiculous character now, and everything I do feels like being in costume."**

The player should feel like they're *inhabiting* their costume — not just wearing
it. When the Pirate walks, there's a swagger. When the Clown moves, there's a
bounce. The character controller isn't just functional transportation; it's the
first layer of comedy. Moving through the Karneval town should feel like wandering
through a festival — relaxed, curious, and slightly chaotic. The controller serves
the **Jeck sein** pillar by making even basic movement entertaining, and the
**Zosamme** pillar by ensuring multiple characters sharing the screen creates
visual comedy through contrasting movement styles.

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
5. **Camera**: Over-the-shoulder, right-side offset. Mouse/right-stick orbits
   around the character. Camera collision prevents clipping through walls.
6. **Interaction facing**: When the player initiates an interaction (NPC dialogue,
   item pickup), the character smoothly rotates to face the target.
7. **Costume animations**: Each costume has a unique idle, walk, and run animation
   set that reflects its personality (Pirate swagger, Clown bounce, etc.). Hop
   animation is shared but with costume-specific landing effects.

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

Camera Distance = CAM_DISTANCE (m)
  Default: 3.0 m | Range: 2.0–5.0

Camera Shoulder Offset = CAM_OFFSET (m)
  Default: 0.5 m right | Range: 0.0–1.0

Interaction Facing Rotation Speed = FACE_SPEED (deg/s)
  Default: 360 deg/s | Range: 180–720
```

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| **Player hops off a ledge** | Character falls with gravity but takes no damage. Lands with a comedic stumble animation. No invisible walls — if the player finds a way off the map, they respawn at the nearest valid position. |
| **Camera clips through wall** | Camera collision pushes camera closer to the character (reducing CAM_DISTANCE dynamically). Restores to default when obstruction clears. |
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
| `CAM_DISTANCE` | 3.0 m | 2.0–5.0 | Framing, spatial awareness | Too close, claustrophobic | Too far, loses costume detail |
| `CAM_OFFSET` | 0.5 m | 0.0–1.0 | Shoulder offset | Centered (less cinematic) | Character blocks too much view |
| `CAM_SENSITIVITY` | 1.0 | 0.3–3.0 | Camera orbit speed | Sluggish camera | Disorienting |
| `FACE_SPEED` | 360 deg/s | 180–720 | Interaction turn speed | Slow, noticeable delay | Instant, robotic snap |

**Knob interactions**: `WALK_SPEED` and `CAM_DISTANCE` are linked — if walk speed
increases, camera distance may need to increase to maintain comfortable framing.

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
- [ ] Over-the-shoulder camera follows character with right-side offset
- [ ] Camera orbits smoothly with mouse/right-stick
- [ ] Camera does not clip through walls (collision pushes camera closer)
- [ ] Camera restores to default distance when obstruction clears

**Interactions:**
- [ ] Character smoothly rotates to face interaction target when interaction begins
- [ ] Character movement locks during Interacting state
- [ ] Character returns to Idle when interaction ends

**Costumes:**
- [ ] Each costume displays its unique idle, walk, and run animations
- [ ] Fallback animations work when costume-specific animations are missing
- [ ] Characters pass through NPCs without collision (NPC plays reaction)

**Multiplayer:**
- [ ] Up to 4 characters can be spawned simultaneously
- [ ] Each character responds only to its assigned input device
- [ ] All characters can move and interact independently
