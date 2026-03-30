# Dialogue System

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-30
> **Implements Pillar**: Jeck sein (Be Silly), Echt Kull (Authentically Karneval)

## Overview

The Dialogue System manages all text-based conversations between players and
NPCs. It receives interaction events from the NPC System (with NPC identity and
player costume), selects the appropriate dialogue content based on the player's
`personality_tag`, and displays it as text boxes. Crowd NPCs deliver 1-3 linear
flavor lines. Story NPCs have deeper conversations with optional 1-2 choice
points for puzzle-relevant information or comedy branches. All dialogue is
written in standard German with Kölsch dialect words and phrases sprinkled in
for authenticity. The system also handles puzzle hints, item-related dialogue,
and NPC reactions to wrong item usage. Without this system, the player cannot
communicate with the cursed townsfolk — and the comedy goes silent.

## Player Fantasy

> **"Every person I talk to says something different because of my ridiculous
> costume — and it's hilarious."**

Dialogue is the primary comedy delivery vehicle. The Pirate threatening a
Kölschglas, the Knight formally requesting passage through a Brauhaus door,
the Clown honking mid-conversation. The costume-dependent lines make every
replay feel fresh and every multiplayer session full of "wait, what did YOUR
character say?" moments. Kölsch phrases like "Alaaf!", "Dat is jeck!", and
"Einmal Halve Hahn!" ground the comedy in authentic culture. This serves
**Jeck sein** (every conversation is a joke) and **Echt Kull** (real Kölsch
language and humor traditions).

## Detailed Design

### Core Rules

1. **Dialogue data**: All dialogue is stored in external data files (JSON or Godot
   Resource), not in scripts. Each NPC has a dialogue tree referenced by
   `dialogue_key` (from NPC Resource).
2. **Dialogue tree structure**:
   - **Node**: A single text box with speaker name, text content, and optional
     portrait/expression
   - **Sequence**: Ordered list of nodes displayed one after another (advance with
     button press)
   - **Choice node**: Presents 2-3 player response options, each branching to a
     different sequence
   - **Condition node**: Checks game state (puzzle progress, items held, prior
     conversations) and branches silently
3. **Costume-dependent lines**: Each dialogue node can have variant text per
   `personality_tag`:
   ```
   node: "greeting"
     default: "Alaaf! Wer bist du denn?"
     boastful: "Alaaf! Arrr, was will der Pirat hier?"
     mischievous: "Alaaf! Oh nein, ein Clown..."
     chivalrous: "Alaaf! Ein Ritter! Welch Ehre!"
     theatrical: "Alaaf! Eine Hexe! *tritt zurück*"
   ```
   If no variant exists for a costume, fall back to `default`.
4. **Crowd NPC dialogue**: Simple 1-3 node sequences. No choices. No conditions.
   Random selection from a small pool (so re-talking gives different flavor lines).
5. **Story NPC dialogue**: Multi-node sequences with 1-2 optional choice points.
   Choices can gate puzzle-critical information or unlock comedy branches.
6. **Conversation flow**:
   a. NPC System dispatches `(npc_id, player)` to Dialogue System
   b. System looks up `dialogue_key` from NPC Resource
   c. System evaluates condition nodes (puzzle state, items, prior talks)
   d. System selects text variant matching player's `personality_tag`
   e. Text boxes display sequentially (player advances with button press)
   f. At choice nodes, player picks from options
   g. Conversation ends -> signal NPC System to resume routine
7. **Localization-ready**: All text stored with string keys. Actual text in
   separate locale files. Kölsch terms kept as-is across locales (with tooltip
   support for non-German players -- stretch goal).

### States and Transitions

| State | Description | Transitions To |
|-------|-------------|---------------|
| **Inactive** | No conversation active | Active (NPC interaction dispatched) |
| **Active** | Displaying text boxes, advancing on input | Choice (choice node reached), Inactive (conversation ends) |
| **Choice** | Player picking from response options | Active (option selected, continue sequence) |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **NPC System** | Receives from | `start_dialogue(npc_id, player)` triggers conversation. `dialogue_ended` signal returns control to NPC. |
| **Costume System** | Reads from | `player.costume.personality_tag` selects text variant |
| **Interaction System** | Triggered by | NPC interaction dispatches to Dialogue System via NPC System |
| **Puzzle System** | Reads/writes | Condition nodes check puzzle state. Dialogue choices can advance puzzle state (`set_puzzle_flag`). |
| **Item System** | Reads | Condition nodes can check if player has an item. NPCs can reference items in dialogue. |
| **Hint System** | Provides to | Hint NPCs use the Dialogue System to deliver progressive hints -- dialogue content is tagged as hints. |
| **UI System** | Provides to | Text box content, speaker name, choice options for dialogue UI rendering. |

## Formulas

```
No mathematical formulas -- text-driven system.

Content Budget:
  Crowd NPCs: 3 flavor lines per NPC x ~12 Crowd NPCs/chapter = ~36 lines/chapter
  Story NPCs: ~10-15 nodes per NPC x ~5 Story NPCs/chapter = ~50-75 nodes/chapter
  Costume variants: each node x 4 costumes (+ default) = up to 5 variants per node

  Estimated total per chapter:
    Crowd lines: ~36 (no costume variants -- generic only)
    Story nodes: ~60 base x ~3 avg variants = ~180 text entries
    Total per chapter: ~216 text entries
    Total game (3 chapters): ~650 text entries

  MVP (1 chapter, 2 costumes):
    Crowd: ~36 lines
    Story: ~60 base x ~2 variants = ~120 text entries
    Total MVP: ~156 text entries

Text Display Speed:
  TEXT_SPEED = instant (full text appears at once, advance with button)
  Alternative: typewriter effect at CHARS_PER_SECOND = 60 | Range: 30-120
```

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| **No costume variant exists for a node** | Fall back to `default` text. Always require a `default` entry. |
| **Two players talk to same Story NPC simultaneously** | Each player gets their own independent dialogue instance with their own costume variant. Instances don't interfere. |
| **Player walks away during dialogue** | Dialogue stays active (player is in Interacting state, movement locked). Player must advance through or explicitly cancel. |
| **Player cancels dialogue mid-conversation** | Cancel button ends conversation immediately. NPC resumes routine. Any unseen dialogue is lost (player can re-talk). |
| **Condition node references missing puzzle flag** | Treat as `false` (unmet condition). Log warning. Conversation continues on default branch. |
| **Dialogue references item player doesn't have** | Condition node gates this correctly. If bypassed (bug), NPC text should still make narrative sense without the item. |
| **Re-talking to an NPC after puzzle progress** | Condition nodes route to updated dialogue. NPCs acknowledge progress: "Oh, du hast es geschafft!" |
| **Dialogue data file missing or corrupt** | NPC says a fallback line: "..." and conversation ends. Log error. Game continues. |
| **Crowd NPC has no more unseen lines** | Lines cycle from the beginning. Crowd NPCs are background -- repetition is acceptable. |

## Dependencies

| System | Relationship | Interface | Hard/Soft |
|--------|-------------|-----------|-----------|
| **NPC System** | Depends on | `start_dialogue(npc_id, player)` initiates; `dialogue_ended` signal releases NPC | Hard |
| **Costume System** | Depends on | `personality_tag` selects text variant per node | Hard |
| **Interaction System** | Depends on | NPC interaction dispatch triggers dialogue flow | Hard |
| **Puzzle System** | Bidirectional | Reads puzzle flags for conditions; writes puzzle flags via dialogue choices | Hard |
| **Item System** | Reads from | Condition nodes check inventory for item presence | Soft |
| **Hint System** | Depended on by | Hint delivery uses dialogue trees tagged as hints | Soft |
| **UI System** | Depended on by | Provides text, speaker name, choice options for dialogue UI | Hard |

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too Low | Too High |
|------|---------|-----------|---------|---------|----------|
| `TEXT_SPEED` | Instant | Instant or 30-120 chars/s | How text appears in the box | -- | Too slow, impatient players |
| `CHOICE_TIMEOUT` | None | 0-30s | Time limit to pick a choice | Rushed | -- |
| `ADVANCE_INPUT` | E / A button | -- | Which input advances text | -- | -- |
| `CANCEL_INPUT` | Escape / B button | -- | Which input cancels dialogue | -- | -- |
| `CROWD_LINE_POOL` | 3 | 2-5 | How many random lines each Crowd NPC has | Repetitive quickly | More writing work |
| `MAX_CHOICE_OPTIONS` | 3 | 2-4 | Maximum choices at a choice node | Binary only | Decision paralysis |

## Acceptance Criteria

**Core Flow:**
- [ ] Talking to an NPC displays text boxes that advance on button press
- [ ] Conversation ends and returns control to NPC System
- [ ] Player movement is locked during dialogue

**Costume Variants:**
- [ ] Each costume sees different text for nodes that have variants
- [ ] Nodes without a costume variant fall back to `default` text
- [ ] Replaying with a different costume shows different lines

**Choices:**
- [ ] Story NPC choice nodes display 2-3 options
- [ ] Selecting an option continues on the correct branch
- [ ] Choices can gate puzzle-critical information

**Conditions:**
- [ ] Condition nodes correctly check puzzle state and branch accordingly
- [ ] Re-talking to an NPC after puzzle progress shows updated dialogue
- [ ] Condition nodes can check item inventory

**Data-Driven:**
- [ ] All dialogue content is in external data files, not in scripts
- [ ] Adding new dialogue requires no code changes
- [ ] Dialogue supports localization string keys
