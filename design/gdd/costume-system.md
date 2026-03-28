# Costume System

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Jeck sein (Be Silly), Echt Kull (Authentically Karneval)

## Overview

The Costume System manages the player's chosen Karneval costume — their visual
appearance, animation set, dialogue personality tag, and comedic identity. It is
a data-driven system: each costume is defined as a resource containing a 3D model,
animation overrides, a personality tag (used by the Dialogue System), and metadata
(name, description, comedy hook). Costumes are selected once at game start and
remain fixed throughout — the entire premise is that the costume is stuck. The
system provides costume identity to every other system that needs it but has no
gameplay mechanics of its own. Without it, all players would look and sound
identical, losing the game's core comedic premise.

## Player Fantasy

> **"I AM the Pirate now. Everything I say and do is through this ridiculous
> costume."**

The costume isn't a skin — it's a character. Choosing a costume means committing
to that identity for the entire game, and the game rewards that commitment with
unique dialogue, NPC reactions, and hidden moments only your costume can trigger.
In multiplayer, the contrast between costumes is half the comedy: the Knight
formally addressing the same bartender the Pirate just threatened. This serves
**Jeck sein** (the costume IS the joke) and **Echt Kull** (Karneval is about
becoming someone else through your costume).

## Detailed Design

### Core Rules

1. **Costume data resource**: Each costume is a Godot `Resource` containing:
   - `costume_id`: StringName (e.g., `"pirate"`, `"clown"`, `"knight"`, `"witch"`)
   - `display_name`: String (e.g., "Der Pirat")
   - `description`: String (one-line comedy pitch)
   - `comedy_hook`: String (behavioral summary for dialogue writers)
   - `personality_tag`: StringName (used by Dialogue System to select lines)
   - `character_model`: PackedScene (the 3D model scene)
   - `animation_overrides`: Dictionary mapping animation names to costume-specific
     animations (idle, walk, run, hop, interact)
   - `idle_sounds`: Array[AudioStream] (ambient costume sounds — armor clink, etc.)
2. **Selection**: Costume is chosen in-world during Chapter 1's opening sequence.
   Player "wakes up" and discovers their costume. Selection is presented as a
   narrative moment, not a menu.
3. **No duplicates**: In multiplayer, once a costume is chosen by one player, it's
   unavailable to others. Selection order: Player 1 first, then Player 2, etc.
   Maximum 4 players = 4 costumes = all taken.
4. **Permanent**: Once selected, the costume cannot be changed during a playthrough.
   This is the game's premise — the costume is stuck.
5. **Costume registry**: A global registry tracks which costumes are in use and
   which player owns each. All systems query the registry via
   `get_costume(player) -> CostumeResource`.
6. **MVP costumes**: Pirate and Clown (2 for Bronze MVP). Knight and Witch added
   for Silver target.

### Costume Definitions

| ID | Name | Personality Tag | Animation Style | Comedy Hook |
|----|------|----------------|----------------|-------------|
| `pirate` | Der Pirat | `boastful` | Swagger walk, dramatic gestures | Takes everything too seriously, threatens inanimate objects |
| `clown` | Der Clown | `mischievous` | Bouncy walk, exaggerated reactions | Physical comedy, honks at inappropriate moments |
| `knight` | Der Ritter | `chivalrous` | Stiff upright walk, formal bows | Treats every situation as a medieval quest |
| `witch` | Die Hexe | `theatrical` | Gliding walk, sweeping arm movements | Pronounces everything as a dark omen |

### States and Transitions

| State | Description | Transitions To |
|-------|-------------|---------------|
| **Unselected** | Game start, no costume assigned | Selected (player chooses in Chapter 1 opening) |
| **Selected** | Costume assigned, permanent for the playthrough | (No transitions — permanent) |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Player Character** | Provides to | `CostumeResource` -> character model, animation overrides, idle sounds. Player Character reads via `get_costume(player)`. |
| **Dialogue System** | Provides to | `personality_tag` -> Dialogue System uses this to select costume-specific dialogue lines. |
| **Feedback System** | Provides to | `costume_id` -> determines costume-specific particle effects, sound cues on interactions. |
| **Cutscene System** | Provides to | `costume_id` -> cutscenes adapt character model and behavior to costume. |
| **Local Multiplayer** | Provides to | Costume registry -> tracks which costumes are taken, prevents duplicates. |
| **Save/Load System** | Provides to | `costume_id` per player -> saved/restored with game state. |

## Formulas

```
No mathematical formulas -- this is a data-driven identity system.

Costume Count:
  MVP (Bronze): 2 costumes (Pirate, Clown)
  Target (Silver): 4 costumes (+ Knight, Witch)
  Stretch (Gold): 4+ (bonus costumes TBD)

Content Scaling per Costume:
  Dialogue lines per NPC = BASE_LINES * COSTUME_VARIANT_MULTIPLIER
    BASE_LINES = number of generic lines per NPC
    COSTUME_VARIANT_MULTIPLIER = 1.0 (each costume gets its own variant)
    Total dialogue per NPC = BASE_LINES * num_costumes

  Animation sets per costume = 5 (idle, walk, run, hop, interact)
  Total animations = num_costumes * 5
```

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| **Solo player -- costume selection in opening** | Normal selection. All 4 costumes available. No duplicate restriction needed. |
| **4 players -- all costumes taken** | Intended behavior. Last player gets the last remaining costume. Show which are already taken. |
| **Player joins mid-game (if supported later)** | Not supported in MVP. If added: joiner gets a random available costume. |
| **Costume model fails to load** | Fallback to a default capsule model with the costume's color. Log error. Game continues. |
| **Costume animations not yet created** | Player Character GDD specifies fallback to shared default animation set. No crash. |
| **Player wants to change costume** | Not possible. The game premise is the costume is stuck. Communicate this clearly during selection: "This is permanent!" |
| **New Game+ or replay** | Player can choose a different costume on a new playthrough. Save does not lock costume permanently across playthroughs. |

## Dependencies

| System | Relationship | Interface | Hard/Soft |
|--------|-------------|-----------|-----------|
| **Player Character** | Depends on | Player Character creates the physical body; Costume System dresses it via `get_costume(player)` | Hard |
| **Dialogue System** | Depended on by | `personality_tag` selects costume-specific dialogue lines | Hard |
| **Feedback System** | Depended on by | `costume_id` for costume-specific effects | Soft |
| **Cutscene System** | Depended on by | `costume_id` for character model in cutscenes | Soft |
| **Local Multiplayer** | Depended on by | Costume registry prevents duplicate selection | Hard |
| **Save/Load System** | Depended on by | `costume_id` per player stored in save data | Soft |

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too Low | Too High |
|------|---------|-----------|---------|---------|----------|
| `NUM_COSTUMES` | 4 | 2-8 | Content variety, replay value | Less reason to replay | Exponential dialogue/animation content cost |
| `SELECTION_TIMEOUT` | None | 0-60s | How long a player can deliberate during selection | Forced rush | Other players wait too long |
| `IDLE_SOUND_INTERVAL` | 10s | 5-30s | How often ambient costume sounds play (armor clink, etc.) | Constant noise, annoying | So rare they're never noticed |
| `IDLE_SOUND_VOLUME` | -12 dB | -20 to -6 dB | Volume of ambient costume sounds | Inaudible | Distracting, masks dialogue |

**Content cost note**: Each costume added multiplies dialogue content by ~1x and
requires 5 unique animations. Keep `NUM_COSTUMES` aligned with available content
budget.

## Acceptance Criteria

**Selection:**
- [ ] Player can choose a costume during Chapter 1 opening (in-world moment)
- [ ] In multiplayer, already-chosen costumes are shown as unavailable
- [ ] Selected costume is permanent -- no way to change mid-playthrough
- [ ] New playthrough allows re-selection

**Visual Identity:**
- [ ] Each costume displays its unique 3D model on the player character
- [ ] Each costume plays its unique idle, walk, run, hop animations
- [ ] Fallback to default animations when costume-specific ones are missing

**System Interface:**
- [ ] `get_costume(player)` returns the correct `CostumeResource` for any player
- [ ] `personality_tag` is correctly passed to and used by the Dialogue System
- [ ] Costume registry correctly tracks which costumes are in use

**Data-Driven:**
- [ ] Adding a new costume requires only creating a new `CostumeResource` -- no code changes
- [ ] Costume definitions are externalized (not hardcoded in scripts)
