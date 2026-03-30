# Puzzle System

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-30
> **Implements Pillar**: All (Jeck sein, Zosamme, Echt Kull)

## Overview

The Puzzle System is the core gameplay framework — it defines, tracks, and
resolves the multi-step puzzles that drive player progression through each
chapter. A puzzle is a data-driven sequence of **steps** (find an item, talk to
an NPC, use an item on a target, complete a mini-task) that the player completes
in any order. The system tracks which steps are complete, validates item usage
and dialogue choices against puzzle requirements, and triggers rewards (comedic
cutscenes, curse weakening, area unlocking) when a puzzle is fully solved. There
are no fail states, no time pressure, and no punishment for wrong answers — only
funny responses. Without this system, the game has no goals and no progression.

## Player Fantasy

> **"I figured it out! That Kölschglas goes to the Köbes, not the tourist!"**

The puzzle system delivers the "aha!" moment — the satisfying click when
disconnected clues suddenly connect. Puzzles should feel like being a detective
at a Karneval party: talk to people, pick up weird objects, try combinations,
and laugh at the wrong answers until the right one clicks. The comedy pillar
(**Jeck sein**) means wrong answers are entertaining, not frustrating. The
authenticity pillar (**Echt Kull**) means puzzles are rooted in real Karneval
traditions — brewing Kölsch, building a float, organizing a Büttenrede. The
togetherness pillar (**Zosamme**) means friends can split up, gather clues,
and piece things together.

## Detailed Design

### Core Rules

1. **Puzzle data resource**: Each puzzle is a Resource:
   - `puzzle_id`: StringName
   - `display_name`: String (e.g., "Das Kölsch-Rezept")
   - `chapter`: int (which chapter this puzzle belongs to)
   - `steps`: Array[PuzzleStep] — the individual tasks that must be completed
   - `prerequisites`: Array[StringName] — other `puzzle_id`s that must be solved
     first (for semi-open gating)
   - `reward_type`: enum (`UnlockArea`, `WeakenCurse`, `UnlockPuzzle`,
     `ChapterComplete`)
   - `reward_data`: Dictionary (specific reward parameters)
   - `completion_dialogue_key`: StringName (comedic completion cutscene/dialogue)
2. **PuzzleStep types**:
   - `UseItem(item_id, target_id)` — use a specific item on a specific target
   - `TalkToNPC(npc_id, dialogue_flag)` — talk to an NPC and reach a specific
     dialogue branch (sets a flag)
   - `MiniTask(task_id)` — complete a mini-task (beer tasting, Kamelle catching,
     etc. — handled by Mini-Task System)
   - `CollectItem(item_id)` — simply pick up a specific item
   - `ReachLocation(area_id)` — go to a specific place
3. **Step completion is order-independent**: Steps within a puzzle can be completed
   in any order unless a step has its own `step_prerequisites` (rare — most steps
   are parallel).
4. **Puzzle state tracking**: A global puzzle state manager tracks:
   - Per-puzzle: which steps are complete, whether the puzzle is solved
   - Per-chapter: which puzzles are solved, whether the chapter is complete
   - Puzzle flags: named booleans set by dialogue choices or step completions
     (used by Dialogue System condition nodes)
5. **Validation**: When the Item System calls `use_item(item_id, target_id)`:
   - Check all active puzzles for a matching `UseItem` step
   - If found and prerequisites met: mark step complete, consume item, return
     success
   - If not found: return failure (Item System shows `wrong_use_response`)
6. **Completion cascade**: When the last step of a puzzle completes:
   - Trigger `completion_dialogue_key` (comedic reward)
   - Execute `reward_type` (unlock area, weaken curse, etc.)
   - Signal Curse Progression system
   - Check if all chapter puzzles are solved -> trigger chapter completion
7. **No fail states**: Wrong actions produce funny responses but never lock the
   player out of progress. Every puzzle remains solvable at all times.
8. **Semi-open structure**: Each chapter has 3-4 puzzles. Some are available
   immediately, some require prerequisites. Example:
   ```
   Ch.2: Dat Brauhaus
     Puzzle A: "Find the Recipe" -- available immediately
     Puzzle B: "Convince the Köbes" -- available immediately
     Puzzle C: "Brew the Kölsch" -- requires A AND B
     Puzzle D: "The Toast" -- requires C (chapter finale)
   ```

### States and Transitions

**Per Puzzle:**

| State | Description | Transitions To |
|-------|-------------|---------------|
| **Locked** | Prerequisites not met. Puzzle elements hidden/inactive. | Available (prerequisites completed) |
| **Available** | Puzzle is active. Steps can be completed. | Solved (all steps done) |
| **Solved** | All steps complete. Reward triggered. | (Terminal) |

**Per Chapter:**

| State | Description | Transitions To |
|-------|-------------|---------------|
| **InProgress** | Chapter loaded, puzzles active | Complete (all chapter puzzles solved) |
| **Complete** | All puzzles solved. Chapter finale triggered. | (Terminal -- next chapter loads) |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Interaction System** | Depends on | Puzzle elements implement interactable interface (`interaction_type = PuzzleElement`) |
| **Item System** | Depends on | `use_item(item_id, target_id)` validated against active puzzle steps |
| **Dialogue System** | Bidirectional | Condition nodes read puzzle flags; dialogue choices write puzzle flags via `set_puzzle_flag` |
| **NPC System** | Depends on | Story NPCs with `puzzle_relevant = true` are step targets |
| **Mini-Task System** | Dispatches to | `MiniTask` steps delegate to Mini-Task System for self-contained activities |
| **Curse Progression** | Signals to | Puzzle completion signals `puzzle_solved(puzzle_id)` to advance curse state |
| **Chapter System** | Signals to | Chapter completion signal when all chapter puzzles solved |
| **Hint System** | Read by | Hint System reads puzzle state to determine which hints to provide |
| **World/Environment** | Reads from | Puzzle element anchors positioned in the environment |

## Formulas

```
No complex math -- logic-driven system.

Puzzle Budget:
  Puzzles per chapter: 3-4
  Steps per puzzle: 2-5 (avg 3)
  Total puzzles (3 chapters): ~10-12
  Total steps: ~30-40

Curse Progression per Puzzle:
  curse_delta = 1.0 / TOTAL_PUZZLES_IN_CHAPTER
  Example (4 puzzles in chapter): each puzzle solved adds 0.25 to curse_level

Chapter Completion:
  chapter_complete = (solved_puzzles == total_puzzles_in_chapter)

MVP (1 chapter):
  Puzzles: 3
  Steps: ~9-12
  Curse delta per puzzle: 0.33
```

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| **Player completes steps out of intended order** | Fully supported -- steps are order-independent. Puzzle tracks completion set, not sequence. |
| **Player completes a step for a Locked puzzle** | Not possible -- Locked puzzle elements are hidden/inactive. Steps can only be completed on Available puzzles. |
| **Prerequisite puzzle becomes unsolvable (bug)** | Not possible by design -- no fail states. All puzzles remain solvable at all times. If a prerequisite NPC is missing, fallback hint via Hint System. |
| **Item used on correct target but puzzle step not active** | Item System gets failure response. Item NOT consumed. Player can try again when puzzle becomes Available. |
| **All steps complete but reward fails** | Log error. Mark puzzle as Solved anyway. Curse Progression uses fallback: manually increment curse_level. |
| **Player solves puzzle while another player is in dialogue with puzzle NPC** | Puzzle completes normally. Dialogue instance continues but post-completion dialogue branch activates for future talks. |
| **Save/load mid-puzzle** | Puzzle state (completed steps, puzzle flags) is serialized. Restoring a save resumes from exact puzzle state. |
| **Puzzle data file missing** | Chapter loads without that puzzle. Log error. Remaining puzzles function normally. Chapter may be completable with fewer puzzles (graceful degradation). |

## Dependencies

| System | Relationship | Interface | Hard/Soft |
|--------|-------------|-----------|-----------|
| **Interaction System** | Depends on | Puzzle elements use interactable interface | Hard |
| **Item System** | Depends on | `use_item()` validation against puzzle steps | Hard |
| **Dialogue System** | Bidirectional | Reads/writes puzzle flags | Hard |
| **NPC System** | Depends on | Story NPCs are puzzle step targets | Hard |
| **World/Environment** | Depends on | Puzzle element anchors in scenes | Hard |
| **Mini-Task System** | Depended on by | MiniTask steps delegate to Mini-Task System | Hard |
| **Hint System** | Depended on by | Reads puzzle state for progressive hints | Soft |
| **Curse Progression** | Depended on by | `puzzle_solved` signal advances curse | Hard |
| **Chapter System** | Depended on by | Chapter completion signal | Hard |
| **Cutscene System** | Depended on by | Completion cutscenes triggered via `completion_dialogue_key` | Soft |
| **Save/Load System** | Depended on by | Puzzle state serialization | Soft |

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too Low | Too High |
|------|---------|-----------|---------|---------|----------|
| `PUZZLES_PER_CHAPTER` | 3-4 | 2-6 | Chapter length and pacing | Too short, unsatisfying | Too long for ~30-60min chapters |
| `STEPS_PER_PUZZLE` | 3 | 2-5 | Individual puzzle complexity | Trivially simple | Overwhelming, no "aha" |
| `CURSE_DELTA` | 1/num_puzzles | -- | How much curse weakens per puzzle | -- | -- |
| `PREREQ_UNLOCK_DELAY` | 0s | 0-3s | Delay before gated puzzle becomes available | Instant, no drama | Confusing wait |
| `COMPLETION_FANFARE_DURATION` | 3s | 1-5s | How long the completion celebration plays | Blink and miss it | Interrupts flow |

## Acceptance Criteria

**Core Flow:**
- [ ] Puzzles with no prerequisites are Available from chapter start
- [ ] Puzzles with prerequisites become Available only when prerequisites are Solved
- [ ] Completing all steps of a puzzle marks it Solved and triggers rewards
- [ ] Completing all puzzles in a chapter triggers chapter completion

**Step Types:**
- [ ] UseItem steps validate against item_id + target_id correctly
- [ ] TalkToNPC steps complete when correct dialogue flag is set
- [ ] CollectItem steps complete when item is picked up
- [ ] ReachLocation steps complete when player enters area
- [ ] MiniTask steps dispatch to Mini-Task System and complete on task success

**No Fail States:**
- [ ] No puzzle can become unsolvable
- [ ] Wrong item usage produces funny text, does not consume item
- [ ] No time limits on any puzzle (by default)

**State Tracking:**
- [ ] Puzzle state persists across save/load
- [ ] Puzzle flags are readable by Dialogue System condition nodes
- [ ] Dialogue choices correctly set puzzle flags

**Data-Driven:**
- [ ] Adding a new puzzle requires only creating a new Puzzle Resource
- [ ] Puzzle steps, prerequisites, and rewards are externalized
