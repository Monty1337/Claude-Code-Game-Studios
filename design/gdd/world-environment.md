# World / Environment

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Echt Kull (Authentically Karneval)

## Overview

The World/Environment system defines the physical spaces players explore across
the game's 3 chapters. Each chapter takes place in a small, densely detailed area
(~100x100m) inspired by the Köln Altstadt — cobblestone streets, colorful
Fachwerk houses, Brauhäuser, and ubiquitous Karneval decorations. The environment
provides collision geometry for player movement, placement points for NPCs and
interactable objects, and visual storytelling through Karneval-themed set dressing.
Players experience the world passively (it surrounds them) and actively (they
investigate it for puzzle clues). Without this system, there is no space for the
game to happen — the environment IS the puzzle box.

## Player Fantasy

> **"I'm wandering through a Karneval-soaked Köln that never stopped partying."**

The environment should feel like the morning after Rosenmontag — but the party
is still going. Confetti on the ground, Girlanden strung between buildings,
half-deflated balloons, Kamelle wrappers everywhere, a Kölsch glass abandoned
on a windowsill. The Altstadt feels lived-in, messy, and joyful. It serves the
**Echt Kull** pillar by grounding every visual detail in real Karneval culture:
you should be able to point at any object and say "yes, that's Karneval."
The density means every few steps reveal something new — a funny sign, a
hidden detail, a new NPC doing something absurd. Exploration is its own reward.

## Detailed Design

### Core Rules

1. **Chapter areas**: Each chapter is a self-contained scene (~100x100m). Chapters
   are loaded independently — no open-world streaming.
2. **Terrain**: Flat cobblestone streets with minor elevation (stairs, ramps,
   curbs). Step height ≤ 0.3m for auto-step compatibility. No steep terrain or
   cliffs.
3. **Buildings**: Mostly exterior facades. 2-3 key buildings per chapter are
   enterable (doors with interaction prompts). Interior/exterior transitions use
   a brief fade-to-black.
4. **Collision layers**: Static geometry (walls, floors, furniture) on collision
   layer for `CharacterBody3D`. NPCs have no collision with players (pass-through,
   per Player Character GDD).
5. **Interactable placement**: The environment contains designated placement nodes
   for items, NPCs, and puzzle elements. These are empty markers filled by the
   Item System, NPC System, and Puzzle System respectively.
6. **Soft boundaries**: Area edges use invisible slowdown zones (not walls). Player
   speed reduces to 0 over ~2m, then a gentle push-back nudges them inward. No
   death, no teleport.
7. **Set dressing**: Dense Karneval decoration — confetti, Girlanden, balloons,
   Kamelle wrappers, Kölsch glasses, parade remnants. These are non-interactable
   visual props on a dedicated visual-only layer.
8. **Curse visual state**: WorldEnvironment post-processing parameters (saturation,
   fog density, exposure, color grading) are driven by the Curse Progression system.
   Cursed = muted/grey/foggy. Curse weakening = colors return. Curse broken = full
   vibrant Karneval.

### States and Transitions

| State | Description | Visual |
|-------|-------------|--------|
| **Cursed** | Default state at chapter start | Muted colors, grey fog, dim lighting |
| **Weakening** | After solving puzzles in the chapter | Colors slowly returning, fog thinning |
| **Liberated** | Chapter complete, curse broken in this area | Full vibrant Karneval colors, warm lighting |

Transitions are driven by the Curse Progression system (not by this system
directly). The environment exposes a `curse_level` float (0.0 = fully cursed,
1.0 = liberated) that interpolates all post-processing parameters.

### Chapter Environments

| Chapter | Setting | Key Interiors | Landmark |
|---------|---------|--------------|----------|
| **1: Der Morgen Danach** | Altstadt streets around a central Platz | Starting apartment, small Büdchen (kiosk) | A fountain with a Karneval Narr statue |
| **2: Dat Brauhaus** | Brauhaus district, narrow streets | The Brauhaus (main), cellar/Fassraum | The Brauhaus itself (distinctive Kölner Brauhaus facade) |
| **3: Der letzte Zoch** | Parade route, staging area | Float workshop, Bühne (stage area) | A half-built parade float |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Player Character** | Consumed by | Provides collision geometry (StaticBody3D) for CharacterBody3D movement. Step height ≤ 0.3m. |
| **NPC System** | Provides to | NPC spawn/placement markers (Node3D positions) in the scene tree |
| **Item System** | Provides to | Item spawn markers (Node3D positions) for pickable objects |
| **Puzzle System** | Provides to | Puzzle element anchors — positions where puzzle-relevant objects, triggers, or zones exist |
| **Interaction System** | Provides to | Interactable doors, objects, and environmental elements with collision areas for raycast detection |
| **Curse Progression** | Reads from | `curse_level` float (0.0–1.0) drives WorldEnvironment post-processing interpolation |
| **Chapter System** | Consumed by | Each chapter loads a different environment scene. Chapter System manages scene transitions. |

## Formulas

```
Curse Post-Processing Interpolation:
  saturation = lerp(CURSED_SATURATION, LIBERATED_SATURATION, curse_level)
    CURSED_SATURATION = 0.3 | LIBERATED_SATURATION = 1.2

  fog_density = lerp(CURSED_FOG, LIBERATED_FOG, curse_level)
    CURSED_FOG = 0.05 | LIBERATED_FOG = 0.005

  exposure = lerp(CURSED_EXPOSURE, LIBERATED_EXPOSURE, curse_level)
    CURSED_EXPOSURE = 0.7 | LIBERATED_EXPOSURE = 1.0

Soft Boundary Slowdown:
  speed_multiplier = clamp(distance_from_edge / BOUNDARY_WIDTH, 0.0, 1.0)
    BOUNDARY_WIDTH = 2.0 m
  Push-back force = PUSHBACK_FORCE * (1.0 - speed_multiplier)
    PUSHBACK_FORCE = 3.0 m/s
```

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| **Player hops onto a roof or unintended surface** | Roofs have invisible collision blockers. If somehow reached, soft boundary pushes player back to street level. |
| **Interior/exterior transition while other player is outside** | Each player transitions independently. Camera stays with each player's local view. No split across indoor/outdoor. |
| **Curse level set to invalid value** | Clamp `curse_level` to 0.0–1.0. Values outside range are clamped silently. |
| **Player explores entire area before solving any puzzle** | Intended behavior — exploration is encouraged. Puzzle items/NPCs are always present from chapter start. |
| **Free assets have inconsistent scale** | All imported assets are normalized to a standard metric scale during import. Character height = 1.8m reference. |
| **Performance drop from dense set dressing** | Set dressing uses LOD groups. Distant decorations use simplified meshes or are culled. Budget: ≤ 500 draw calls per scene. |

## Dependencies

| System | Relationship | Interface | Hard/Soft |
|--------|-------------|-----------|-----------|
| **Player Character** | Depended on by | Collision geometry (StaticBody3D), step height ≤ 0.3m | Hard |
| **NPC System** | Depended on by | Node3D spawn markers for NPC placement | Hard |
| **Item System** | Depended on by | Node3D spawn markers for item placement | Hard |
| **Puzzle System** | Depended on by | Puzzle element anchors in scene tree | Hard |
| **Interaction System** | Depended on by | Interactable Area3D collision shapes on doors, objects | Hard |
| **Curse Progression** | Reads from | `curse_level` float drives post-processing | Soft — environment works at default visuals without it |
| **Chapter System** | Consumed by | Scene files loaded/unloaded by Chapter System | Hard |
| **Feedback System** | Depended on by | World-space positions for particle effects | Soft |

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too Low | Too High |
|------|---------|-----------|---------|---------|----------|
| `CURSED_SATURATION` | 0.3 | 0.0–0.5 | How grey the cursed world looks | Black & white, depressing | Not noticeably different from liberated |
| `LIBERATED_SATURATION` | 1.2 | 1.0–1.5 | How vibrant the freed world looks | Indistinct from cursed | Garish, eye-strain |
| `CURSED_FOG` | 0.05 | 0.01–0.1 | Fog thickness when cursed | Barely visible | Can't see across the street |
| `LIBERATED_FOG` | 0.005 | 0.0–0.01 | Fog thickness when freed | Zero fog (fine) | Still feels cursed |
| `BOUNDARY_WIDTH` | 2.0 m | 1.0–5.0 | Soft boundary slowdown zone | Abrupt stop, feels like a wall | Player wanders far before stopping |
| `PUSHBACK_FORCE` | 3.0 m/s | 1.0–5.0 | How strongly boundary pushes back | Player can fight through | Feels like being shoved |
| `SET_DRESSING_DENSITY` | 1.0 | 0.5–2.0 | Multiplier on decoration spawns | Bare, empty streets | Performance drop, visual noise |

## Acceptance Criteria

**Environment:**
- [ ] Each chapter scene loads in ≤ 5 seconds
- [ ] Player can walk across the full area without getting stuck on geometry
- [ ] All stairs and ramps have step height ≤ 0.3m
- [ ] Soft boundaries prevent leaving the play area without visible walls
- [ ] 2-3 buildings per chapter are enterable with fade transitions

**Visuals:**
- [ ] Curse visual state interpolates smoothly from cursed (grey) to liberated (vibrant)
- [ ] Set dressing reads as "Karneval in Köln" — confetti, Girlanden, Kölsch glasses visible
- [ ] Scene stays ≤ 500 draw calls with set dressing at default density
- [ ] Free assets are scale-consistent (character height = 1.8m reference)

**Placement:**
- [ ] NPC markers are accessible and visible from player walking paths
- [ ] Item markers are placed at reachable positions (not inside walls or above hop height)
- [ ] Puzzle anchors are correctly positioned per puzzle design

**Multiplayer:**
- [ ] All players share the same environment instance
- [ ] Interior transitions work independently per player
