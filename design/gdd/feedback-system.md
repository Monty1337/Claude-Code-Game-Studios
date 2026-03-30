# Feedback System

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-30
> **Implements Pillar**: Jeck sein (Be Silly)

## Overview

The Feedback System provides the "juice" — visual effects, sound effects, and
screen responses that make every interaction feel satisfying and comedic. It
receives signals from gameplay systems (interaction started, item picked up,
puzzle solved, hop landed, NPC startled) and triggers appropriate feedback:
confetti bursts, comedic sound effects, screen shake, particle effects, and
costume-specific visual cues. The system is purely reactive — it never affects
gameplay logic, only presentation. Without this system, the game would feel
flat and silent — the comedy would fall flat without comedic timing and feedback.

## Player Fantasy

> **"Everything I do gets a fun reaction — confetti when I solve a puzzle, a
> honk when the Clown picks something up, a dramatic chord when the Witch
> examines an item."**

Feedback is what makes the difference between "I solved it" and "I SOLVED IT!"
The confetti burst on puzzle completion, the satisfying *pop* on item pickup,
the ridiculous sound effect when you walk through an NPC. Every interaction
should feel like the game is celebrating with you. Costume-specific feedback
makes each character feel alive — the Knight gets a fanfare, the Clown gets
a honk, the Pirate gets a dramatic sea shanty sting. This is the primary
delivery mechanism for the **Jeck sein** pillar: humor lives in timing,
sound, and visual payoff.

## Detailed Design

### Core Rules

1. **Event-driven**: The system listens for signals from other systems. It never
   polls or checks state — it reacts to events.
2. **Feedback types**:
   - **Particles**: Confetti bursts, sparkles, smoke puffs (Godot `GPUParticles3D`)
   - **Sound effects**: Comedic stings, pickup sounds, interaction sounds
     (Godot `AudioStreamPlayer3D` / `AudioStreamPlayer`)
   - **Screen effects**: Brief screen shake, flash, vignette pulse (camera/post-processing)
   - **UI effects**: Text pop-ups, icon bounces, flash highlights
3. **Feedback profiles**: Each event type has a profile defining which effects
   to play:
   - `item_picked_up`: pickup SFX + item icon bounce + small sparkle
   - `puzzle_step_complete`: medium confetti + progress chime
   - `puzzle_solved`: big confetti burst + fanfare + screen flash
   - `chapter_complete`: maximum confetti + full fanfare + screen celebration
   - `hop_landed`: small dust puff + thud SFX
   - `npc_startled`: startled SFX + small particle reaction
   - `wrong_item_use`: comedic fail SFX (trombone wah-wah / honk)
   - `interaction_started`: subtle click SFX
4. **Costume-specific SFX**: For key events (pickup, puzzle solve), the system
   checks the player's `costume_id` and plays a costume-variant sound if one
   exists. Fallback to generic SFX if no variant.
   - Pirate: dramatic sting, cannon boom
   - Clown: honk, slide whistle
   - Knight: fanfare, sword clash
   - Witch: magical chime, cauldron bubble
5. **Layered feedback**: Major events (puzzle solved) layer multiple feedback
   types simultaneously: particles + SFX + screen effect. Minor events (item
   pickup) use 1-2 types.
6. **Non-blocking**: All feedback is fire-and-forget. Never blocks gameplay.
   Effects time out and clean themselves up.

### States and Transitions

No states — this is a stateless reactive system. It receives signals and fires
effects. No persistence, no tracking.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Interaction System** | Receives from | `interaction_started(target)`, `interaction_ended(target)` |
| **Item System** | Receives from | `item_picked_up(item_id)`, `item_used(item_id, target_id)` |
| **Puzzle System** | Receives from | `puzzle_step_complete(puzzle_id, step)`, `puzzle_solved(puzzle_id)` |
| **Player Character** | Receives from | `hop_landed(position)`, state change signals |
| **NPC System** | Receives from | `npc_startled(npc_id, position)` |
| **Costume System** | Reads from | `costume_id` for costume-specific SFX selection |
| **World/Environment** | Uses | World-space positions for 3D particle/sound placement |

## Formulas

```
No mathematical formulas -- effect-driven system.

Effect Budgets:
  Particles per effect: 20-100 (confetti), 5-20 (sparkles/dust)
  Active particle systems at once: max 5 (to stay within performance budget)
  SFX concurrent: max 8 AudioStreamPlayers

Timing:
  Particle lifetime: 1.0-3.0s (auto-cleanup)
  Screen shake duration: 0.1-0.5s
  Screen flash duration: 0.05-0.15s
  Fanfare SFX length: 1.0-3.0s
```

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| **Multiple events fire simultaneously** | All effects play. Particle budget prevents excess -- oldest particle system freed if over limit. SFX uses priority (puzzle_solved > item_pickup). |
| **Event fires with no player in scene** | Effect plays at event position regardless. No crash. |
| **Costume-specific SFX missing** | Fall back to generic SFX. Log warning. |
| **Screen shake during dialogue** | Suppressed -- no screen shake while UI overlays are active (dialogue, inventory). SFX and particles still play. |
| **Performance drop from too many particles** | Hard cap on concurrent particle systems (5). Oldest auto-freed when cap reached. |
| **Event fires during cutscene** | Feedback suppressed during cutscene state. Cutscene System handles its own effects. |

## Dependencies

| System | Relationship | Interface | Hard/Soft |
|--------|-------------|-----------|-----------|
| **Interaction System** | Receives from | Interaction start/end signals | Soft |
| **Item System** | Receives from | Item pickup/use signals | Soft |
| **Puzzle System** | Receives from | Puzzle step/solve signals | Soft |
| **Player Character** | Receives from | Hop landed, state signals | Soft |
| **NPC System** | Receives from | NPC startled signal | Soft |
| **Costume System** | Reads from | Costume ID for SFX variants | Soft |
| **World/Environment** | Uses | World positions for 3D effect placement | Soft |

All dependencies are **Soft** -- the game functions without feedback effects.
The Feedback System is purely additive presentation.

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too Low | Too High |
|------|---------|-----------|---------|---------|----------|
| `CONFETTI_COUNT` | 50 | 20-200 | Particles per confetti burst | Sparse, underwhelming | Performance drop |
| `SCREEN_SHAKE_INTENSITY` | 3.0 px | 1-10 | Screen shake displacement | Barely noticeable | Disorienting |
| `SCREEN_SHAKE_DURATION` | 0.2s | 0.1-0.5 | How long screen shakes | Too brief | Nauseating |
| `SFX_VOLUME_FEEDBACK` | -6 dB | -15 to 0 | Volume of feedback SFX | Inaudible | Drowns out dialogue/music |
| `MAX_CONCURRENT_PARTICLES` | 5 | 3-10 | Particle system cap | Miss some effects | Performance risk |
| `EFFECT_COOLDOWN` | 0.1s | 0-0.5 | Minimum time between same effect type | Spam | Miss rapid events |

## Acceptance Criteria

**Effects:**
- [ ] Item pickup triggers SFX and sparkle particle
- [ ] Puzzle step completion triggers confetti and chime
- [ ] Puzzle solved triggers full celebration (confetti + fanfare + screen flash)
- [ ] Hop landing triggers dust puff and thud
- [ ] NPC startled triggers reaction SFX and particle
- [ ] Wrong item use triggers comedic fail SFX

**Costume Variants:**
- [ ] Each costume has at least 1 unique pickup and puzzle-solve SFX
- [ ] Missing variants fall back to generic SFX without error

**Performance:**
- [ ] Max 5 concurrent particle systems enforced
- [ ] Effects auto-cleanup after lifetime expires
- [ ] No frame drops from feedback effects at default settings

**Non-Blocking:**
- [ ] All effects are fire-and-forget -- never block gameplay
- [ ] Screen shake suppressed during UI overlay states
