# Sprint 5 — 2026-05-27 to 2026-06-09

## Sprint Goal
Complete the Silver target: build Chapter 3 (Der letzte Zoch), add the chapter
transition from Ch.2 → Ch.3, and create a proper ending sequence. The game
will be fully playable from start to finish with 3 chapters, 4 costumes, and
~9 puzzles.

## Capacity
- Total days: 14 calendar days
- Hours per week: 5-10 (hobby pace)
- Total hours: ~10-20
- Buffer (20%): ~2-4 hours
- Available: ~8-16 productive hours

## Tasks

### Must Have (Critical Path)

| ID | Task | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-------------------|
| S5-01 | **Chapter 2 → 3 transition** | 0.5 | S4 | Ch.2 completion loads Ch.3, state persists |
| S5-02 | **Chapter 3 environment**: Parade route + staging area, float workshop | 3 | S5-01 | Walkable parade route with workshop interior and stage area |
| S5-03 | **Chapter 3 content**: 3 puzzles (build a float, organize parade, unmasking ritual), NPCs, items, 4-costume dialogue | 5 | S5-02 | 3 puzzles solvable, all 4 costumes have variant dialogue |
| S5-04 | **Ending sequence**: Final puzzle triggers curse-breaking celebration, credits/thank you screen, return to menu | 2 | S5-03 | Game has a proper ending, player feels closure |

### Should Have

| ID | Task | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-------------------|
| S5-05 | **Credits screen**: Simple scrolling credits with "Karneval Forever" title, made with Claude Code note | 1 | S5-04 | Credits display after final puzzle, return to menu |
| S5-06 | **Continue game flow**: Loading a save mid-game skips costume selection, drops into correct chapter | 1 | S4-06 | Continue from Ch.2 or Ch.3 works correctly |

## Definition of Done
- [ ] Game playable start to finish (3 chapters, ~9 puzzles)
- [ ] Proper ending with credits
- [ ] Save/load works across all 3 chapters
- [ ] All 4 costumes have dialogue in all chapters
