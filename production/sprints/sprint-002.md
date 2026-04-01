# Sprint 2 — 2026-04-15 to 2026-04-28

## Sprint Goal
Build the gameplay systems that make the game a game: dialogue with costume
variants, puzzle framework, costume selection, and NPC routines. End the sprint
with a playable Chapter 1 blockout where the player picks a costume, talks to
NPCs with costume-specific dialogue, and solves a real multi-step puzzle.

## Capacity
- Total days: 14 calendar days
- Hours per week: 5-10 (hobby pace)
- Total hours: ~10-20
- Buffer (20%): ~2-4 hours reserved
- Available: ~8-16 productive hours

## Carryover from Sprint 1
None — all 12 tasks completed.

## Tasks

### Must Have (Critical Path)

| ID | Task | Source GDD | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S2-01 | **Dialogue system**: Data-driven dialogue trees with nodes, sequences, choice nodes, condition nodes. Load from Resource files. Costume-variant text per node with fallback to default. | Dialogue GDD | 3 | S1 complete | Dialogue trees load from data, costume variants display correctly, choices branch, conditions check GameState flags |
| S2-02 | **Puzzle system framework**: PuzzleResource with typed steps (UseItem, TalkToNPC, CollectItem, ReachLocation). State tracking, validation, completion cascade. Semi-open prerequisites. | Puzzle GDD | 3 | S2-01 | Puzzles load from data, steps complete in any order, prerequisites gate correctly, completion signals EventBus |
| S2-03 | **Costume selection**: In-world costume selection during Chapter 1 opening. Shows available costumes, no duplicates, permanent choice. Wires costume to player. | Costume GDD | 2 | S1-05 | Player picks from available costumes, selection is permanent, CostumeManager tracks assignment |
| S2-04 | **Upgrade NPC to use dialogue system**: Replace SimpleNPC with full NPC that uses the Dialogue system. Story NPCs have dialogue trees; Crowd NPCs have random flavor lines. | NPC GDD, Dialogue GDD | 2 | S2-01 | NPCs trigger dialogue system, costume-dependent lines display, dialogue ends cleanly |

### Should Have

| ID | Task | Source GDD | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S2-05 | **Chapter 1 blockout**: Real environment for "Der Morgen Danach" — Altstadt plaza with 2 interiors (apartment, Büdchen). Place NPC markers, item markers, puzzle anchors. | World/Env GDD | 3 | S2-01 to S2-04 | Walkable Chapter 1 environment with placed NPCs, items, and puzzle elements |
| S2-06 | **Chapter 1 content**: 3 puzzles with real dialogue, items, and NPC interactions. Full playable chapter with curse progression. | Puzzle GDD, All GDDs | 3 | S2-05 | 3 puzzles solvable, curse weakens on each solve, chapter completable |

### Nice to Have

| ID | Task | Source GDD | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S2-07 | **NPC behavior routines**: Waypoint patrol with NavigationAgent3D. Awareness radius, head look-at, startled animation on walk-through. | NPC GDD | 2 | S2-04 | NPCs walk between waypoints, notice player, pause for dialogue |
| S2-08 | **Hint system (basic)**: Track which puzzle the player is stuck on (no progress for N seconds). Hint NPC delivers progressive hints. | Hint GDD (undesigned) | 2 | S2-02, S2-04 | Hints appear via NPC gossip after player is stuck |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Dialogue data format too complex | Medium | Medium | Start with simple JSON/Resource. Iterate on format based on authoring experience. |
| Puzzle step validation edge cases | Medium | Medium | Test each step type in isolation before combining. |
| Chapter 1 content takes longer than estimated | High | Medium | Blockout first (S2-05), content second (S2-06). Ship with placeholder content if needed. |
| Godot 4.6 NavigationAgent3D differences | Medium | Low | NPC routines are Nice to Have — can defer to Sprint 3. |

## Definition of Done for this Sprint
- [ ] Player selects a costume at game start
- [ ] NPCs speak with costume-variant dialogue
- [ ] At least 1 puzzle is solvable with the full step system
- [ ] Chapter 1 blockout is walkable with placed content
- [ ] All code committed with meaningful messages
