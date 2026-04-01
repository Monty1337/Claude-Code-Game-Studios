# Sprint 4 — 2026-05-13 to 2026-05-26

## Sprint Goal
Expand the game toward the Silver target: add 2 more costumes (Knight + Witch),
build Chapter 2 (Dat Brauhaus), implement save/load, and add the chapter
transition flow so the game has two connected chapters.

## Capacity
- Total days: 14 calendar days
- Hours per week: 5-10 (hobby pace)
- Total hours: ~10-20
- Buffer (20%): ~2-4 hours
- Available: ~8-16 productive hours

## Carryover from Sprint 3
None — all tasks completed.

## Tasks

### Must Have (Critical Path)

| ID | Task | Source GDD | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S4-01 | **Knight + Witch costumes**: Add 2 costumes to CostumeManager with personality tags (chivalrous, theatrical). Update costume selection UI to show 4 options. | Costume GDD | 1 | None | 4 costumes selectable, no duplicates in multiplayer, personality tags work |
| S4-02 | **Knight + Witch dialogue variants**: Add chivalrous/theatrical text variants to all Chapter 1 Story NPC dialogue trees. | Dialogue GDD | 2 | S4-01 | All 4 costumes get unique dialogue from Köbes, Blumenmarie, Büttenredner |
| S4-03 | **Chapter transition flow**: When Chapter 1 is complete, show celebration, then load Chapter 2 via SceneManager. Game state persists. | ADR-0001, Chapter structure | 1.5 | None | Completing Ch.1 fades to Ch.2, inventory/flags/costume persist |
| S4-04 | **Chapter 2 environment**: Build "Dat Brauhaus" — Brauhaus district with narrow streets, the Brauhaus interior, cellar. Larger/denser than Ch.1. | World/Env GDD | 3 | S4-03 | Walkable environment with Brauhaus interior, cellar, street area |
| S4-05 | **Chapter 2 content**: 3-4 puzzles with NPCs, items, dialogue. Beer-tasting theme, Kölsch traditions. Full costume variants. | Puzzle GDD, All GDDs | 4 | S4-04, S4-02 | 3-4 puzzles solvable, curse progresses, chapter completable |

### Should Have

| ID | Task | Source GDD | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S4-06 | **Save/load system**: Save game state (chapter, puzzle flags, inventory, costume) to file. Load from main menu "Continue" button. | Save/Load concept | 2 | S4-03 | Save writes JSON, Continue loads and restores full state |
| S4-07 | **Chapter completion celebration**: Proper end-of-chapter sequence — confetti burst, message, brief pause before transition. | Feedback GDD | 1 | S4-03 | Chapter complete triggers visible celebration before fade |

### Nice to Have

| ID | Task | Source GDD | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S4-08 | **Crowd NPCs for Chapter 2**: 4-6 background NPCs with flavor lines and Brauhaus-themed behavior. | NPC GDD | 1.5 | S4-04 | Background NPCs populate Ch.2 streets and Brauhaus |
| S4-09 | **Ambient audio placeholders**: Background Karneval sounds (crowd noise, distant music). Simple AudioStreamPlayer per chapter. | Audio concept | 1 | None | Ambient loop plays during gameplay, stops in menus |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Chapter 2 content scope too large | High | Medium | Start with 3 puzzles minimum. 4th puzzle is stretch. |
| Writing 4 costume variants per NPC is time-intensive | Medium | Medium | Knight/Witch variants can be shorter. Fall back to default if not written. |
| Save/load serialization edge cases | Medium | Low | Test save/load cycle for each state: mid-puzzle, chapter boundary, fresh start. |

## Definition of Done for this Sprint
- [ ] 4 costumes playable with unique dialogue
- [ ] Chapter 1 → Chapter 2 transition works
- [ ] Chapter 2 has at least 3 solvable puzzles
- [ ] Save/load preserves game state across sessions
- [ ] Two complete chapters playable end-to-end
