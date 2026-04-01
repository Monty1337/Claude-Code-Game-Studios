# Sprint 3 — 2026-04-29 to 2026-05-12

## Sprint Goal
Polish Chapter 1 into a complete vertical slice: NPC behavior routines, curse
visual progression, basic hint system, audio/feedback juice, and a proper main
menu. End the sprint with a demo-ready Chapter 1 that feels like a real game.

## Capacity
- Total days: 14 calendar days
- Hours per week: 5-10 (hobby pace)
- Total hours: ~10-20
- Buffer (20%): ~2-4 hours reserved
- Available: ~8-16 productive hours

## Carryover from Sprint 2
None — all 6 tasks completed.

## Tasks

### Must Have (Critical Path)

| ID | Task | Source GDD | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S3-01 | **Curse visual progression**: WorldEnvironment post-processing interpolates based on curse_level. Fog thins, saturation increases, colors warm as puzzles are solved. | World/Env GDD | 2 | S2 complete | Solving each puzzle visibly brightens the world. 0.0=grey/foggy, 1.0=vibrant. |
| S3-02 | **NPC behavior routines**: NPCs walk between waypoints using NavigationAgent3D. Pause at waypoints, perform idle actions. Pause for dialogue, resume after. | NPC GDD | 3 | S2-04 | NPCs patrol visibly, stop when talked to, resume after dialogue ends. |
| S3-03 | **Hint system (basic)**: If player hasn't solved a puzzle in 3+ minutes, nearby NPC offers a gossip-style hint via dialogue. Progressive (vague → specific). | Hint concept | 2 | S2-01, S2-02 | Hints appear after inactivity, get more specific on repeat, never give full answer. |
| S3-04 | **Main menu**: Title screen with New Game, Quit. Karneval-themed styling. New Game loads Chapter 1. | UI GDD | 1.5 | None | Main menu displays on launch, New Game starts Chapter 1, Quit exits. |

### Should Have

| ID | Task | Source GDD | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S3-05 | **Feedback juice**: Confetti particles on puzzle solve, dust on hop landing, pickup sparkle, wrong-use trombone sound (placeholder SFX). | Feedback GDD | 2 | S2 complete | Puzzle solve = confetti burst. Hop = dust puff. Pickup = sparkle. Wrong use = fail sound. |
| S3-06 | **NPC awareness**: NPCs turn head toward nearby player. Startled reaction when walked through (brief animation + cooldown). | NPC GDD | 1.5 | S3-02 | NPCs look at approaching player, react when passed through, cooldown prevents spam. |
| S3-07 | **Pause menu**: Escape opens pause overlay (Resume, Main Menu). Pauses game. | UI GDD | 1 | S3-04 | Escape pauses, Resume continues, Main Menu returns to title. |

### Nice to Have

| ID | Task | Source GDD | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S3-08 | **Chapter 1 completion flow**: After all 3 puzzles solved, show "Chapter 1 Complete" celebration, then return to main menu (or placeholder "To be continued"). | Chapter structure | 1 | S3-01 | Solving puzzle 3 triggers finale message and credits/menu return. |
| S3-09 | **Save/load (basic)**: Save game state on chapter complete or manual save. Load from main menu "Continue" button. | Save/Load concept | 2 | S3-04 | Save writes to file, Continue loads state, inventory/flags persist. |
| S3-10 | **Item examine in inventory**: Selecting an item in the inventory panel shows its full description in a detail pane. | Item GDD, UI GDD | 1 | S2 complete | Click/select item in inventory shows description text. |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| NavigationAgent3D API differences in 4.6 | Medium | Medium | Check engine reference docs. Fall back to simple lerp between waypoints if navmesh is problematic. |
| Post-processing interpolation looks bad | Low | Medium | Use simple lerp on fog_density and saturation. Test incrementally. |
| Hint timing feels wrong (too early/late) | Medium | Low | Make hint delay an exported var. Easy to tune at runtime. |
| Particle/SFX placeholder quality | Low | Low | Placeholder is fine — polish comes in Sprint 4+. |

## Definition of Done for this Sprint
- [ ] Solving puzzles visibly changes the world (curse progression)
- [ ] NPCs walk around and react to the player
- [ ] Hints appear when the player is stuck
- [ ] Main menu → Chapter 1 → Chapter Complete flow works end-to-end
- [ ] At least 3 feedback effects are in place (confetti, dust, sparkle)
- [ ] All code committed with meaningful messages

## Sprint 3 → Sprint 4 Handoff
If Sprint 3 completes fully, Sprint 4 should focus on:
- Chapter 2 content (Dat Brauhaus — new environment, puzzles, NPCs)
- More costumes (Knight + Witch for Silver target)
- Audio system (music, ambient Karneval sounds)
- Local multiplayer foundation (split input, multiple players)
