# UI System

> **Status**: Designed
> **Author**: User + Claude
> **Last Updated**: 2026-03-30
> **Implements Pillar**: Jeck sein (Be Silly), Echt Kull (Authentically Karneval)

## Overview

The UI System provides all on-screen interface elements — main menu, pause menu,
interaction prompts, inventory display, dialogue text boxes, choice menus, and
puzzle progress indicators. It renders Godot `Control` nodes in a `CanvasLayer`
overlaid on the 3D world. The system is reactive: it receives data from gameplay
systems (Interaction, Item, Dialogue, Puzzle) and presents it visually. The player
interacts with UI through button inputs (navigate menus, advance dialogue, open
inventory). In multiplayer, each player has their own interaction prompts and
dialogue boxes, while the inventory display is shared. Without this system, the
player has no way to access inventory, read dialogue, see interaction prompts,
or navigate menus.

## Player Fantasy

> **"The UI feels like part of the Karneval — festive, playful, and never in my way."**

The UI should be minimal during gameplay (just the interaction prompt when needed)
and Karneval-themed when opened (inventory, pause menu). Think confetti borders,
warm carnival colors, playful fonts. It shouldn't feel like a spreadsheet — it
should feel like a party program. But above all, it must be **invisible when not
needed** and **instantly responsive when summoned**. This serves **Jeck sein**
(festive visual style) and **Echt Kull** (Karneval aesthetic in every detail).

## Detailed Design

### Core Rules

1. **UI layers** (rendered in `CanvasLayer`, front to back):
   - **HUD layer**: Interaction prompts (always visible when target detected)
   - **Overlay layer**: Inventory panel, dialogue boxes (opened on demand)
   - **Menu layer**: Main menu, pause menu, costume selection (blocks gameplay)
2. **UI components**:
   - **Interaction Prompt**: Floating label near interaction target. Shows input
     icon + action text (e.g., "[E] Talk to Köbes"). Positioned via
     `camera.unproject_position()`. Fades in/out smoothly.
   - **Dialogue Box**: Bottom-screen panel. Shows speaker name, text content.
     Advance button icon. During choices: 2-3 selectable options listed vertically.
   - **Inventory Panel**: Grid/list of item icons with names. Toggle open/close
     with inventory button (Tab/Select). Select item to examine (shows description)
     or use (enters "use mode" -- next interact targets the item at world objects).
   - **Pause Menu**: Overlay with Resume, Settings, Quit. Pauses the game.
   - **Main Menu**: Title screen with New Game, Continue, Settings, Quit.
   - **Costume Selection**: In-world UI during Chapter 1 opening. Shows available
     costumes with names and descriptions. Locked costumes greyed out (multiplayer).
3. **Input routing**: UI consumes input when active (menus, dialogue). Gameplay
   input resumes when UI closes. UI navigation: WASD/D-pad for menu items, E/A
   to confirm, Escape/B to back/cancel.
4. **Multiplayer UI**: Each player has their own interaction prompt and dialogue
   box (positioned per-player). Inventory panel is shared (one panel, any player
   can open it). Pause menu pauses for all players.
5. **Godot implementation**: All UI in `Control` node tree. Theme resource for
   consistent Karneval styling (colors, fonts, borders). Responsive to window
   resize.

### States and Transitions

| State | Description | Input Mode | Transitions To |
|-------|-------------|-----------|---------------|
| **Gameplay** | HUD only (interaction prompts) | Gameplay input | Inventory (Tab), Dialogue (NPC interact), Paused (Escape) |
| **Inventory** | Inventory panel open | UI navigation | Gameplay (Tab/Escape), UseMode (select item) |
| **UseMode** | Item selected, targeting world objects | Gameplay + modified prompts | Gameplay (cancel or item used) |
| **Dialogue** | Dialogue box active | Dialogue input | Gameplay (dialogue ends) |
| **Paused** | Pause menu overlay, game frozen | Menu navigation | Gameplay (Resume), MainMenu (Quit) |
| **MainMenu** | Title screen, no gameplay | Menu navigation | Gameplay (New Game/Continue) |
| **CostumeSelect** | In-world costume selection | Menu navigation | Gameplay (costume chosen) |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Interaction System** | Receives from | Prompt data (target position, label, input icon). Show/hide prompt. |
| **Item System** | Receives from | Inventory contents (icons, names, descriptions). Examine text. Use mode validation. |
| **Dialogue System** | Receives from | Text box content, speaker name, choice options. Start/end signals. |
| **Puzzle System** | Receives from | (Optional) puzzle progress hints for HUD |
| **Costume System** | Receives from | Costume list for selection screen. Availability flags. |
| **Player Character** | Signals to | UI state changes toggle gameplay input on/off |

## Formulas

```
No mathematical formulas -- layout and presentation system.

Prompt Positioning:
  screen_pos = camera.unproject_position(target.global_position + PROMPT_OFFSET)
  (Defined in Interaction System GDD -- UI just renders at this position)

Fade Timing:
  PROMPT_FADE_IN = 0.15s | Range: 0.05-0.3
  PROMPT_FADE_OUT = 0.1s | Range: 0.05-0.2
  MENU_FADE = 0.2s | Range: 0.1-0.5

UI Budget:
  Main Menu: 1 scene
  Pause Menu: 1 overlay
  Inventory Panel: 1 overlay
  Dialogue Box: 1 per-player overlay
  Interaction Prompt: 1 per-player HUD element
  Costume Selection: 1 overlay
  Total UI scenes: ~6-8
```

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| **Inventory opened during dialogue** | Blocked -- dialogue takes priority. Inventory button ignored while in Dialogue state. |
| **Pause during dialogue** | Allowed -- game pauses, dialogue stays visible underneath pause overlay. Resume returns to dialogue. |
| **Two players open inventory simultaneously** | One shared panel. Second player's input joins the same panel. Either player can navigate/select. |
| **Prompt target moves off-screen** | Prompt clamped to screen edge with arrow pointing toward target. Or hidden if too far off-screen. |
| **Window resized during gameplay** | UI uses anchors and containers for responsive layout. Theme resource handles scaling. |
| **Controller disconnected** | Show reconnect prompt. Pause game. Resume when controller reconnects. |
| **UseMode but no valid targets nearby** | Prompt shows item name but no target. Cancel with Escape/B returns to inventory. |
| **Dialogue box text too long for box** | Text auto-wraps. If still too long, split into multiple pages (auto-paginate). |

## Dependencies

| System | Relationship | Interface | Hard/Soft |
|--------|-------------|-----------|-----------|
| **Interaction System** | Depended on by | Receives prompt data (position, label, icon) | Hard |
| **Item System** | Depended on by | Receives inventory data (icons, names, descriptions) | Hard |
| **Dialogue System** | Depended on by | Receives text, speaker, choices for dialogue display | Hard |
| **Puzzle System** | Depended on by | Receives optional puzzle progress for HUD | Soft |
| **Costume System** | Depended on by | Receives costume list and availability for selection | Hard (for costume select only) |
| **Player Character** | Signals to | Input routing: gameplay vs UI input mode | Hard |

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too Low | Too High |
|------|---------|-----------|---------|---------|----------|
| `PROMPT_FADE_IN` | 0.15s | 0.05-0.3 | How fast prompts appear | Instant pop (jarring) | Slow, misses fast interactions |
| `PROMPT_FADE_OUT` | 0.1s | 0.05-0.2 | How fast prompts disappear | Instant pop | Lingers after target lost |
| `DIALOGUE_BOX_WIDTH` | 80% screen | 60-90% | Dialogue text area width | Narrow, lots of wrapping | Covers too much gameplay |
| `INVENTORY_COLUMNS` | 4 | 3-6 | Grid layout for inventory | Tall and narrow | Wide and shallow |
| `UI_SCALE` | 1.0 | 0.75-1.5 | Overall UI element scaling | Too small to read | Covers gameplay |
| `MENU_FADE` | 0.2s | 0.1-0.5 | Menu transition speed | Instant, feels cheap | Sluggish, unresponsive |

## Acceptance Criteria

**Prompts:**
- [ ] Interaction prompts appear when target detected and disappear when lost
- [ ] Prompts show correct label and input icon
- [ ] Prompts track target position smoothly (no jitter)

**Dialogue:**
- [ ] Dialogue box shows speaker name and text content
- [ ] Advance input progresses to next text node
- [ ] Choice nodes display 2-3 selectable options
- [ ] Cancel input ends dialogue and returns to gameplay

**Inventory:**
- [ ] Inventory panel toggles open/close with inventory button
- [ ] Items display with icon and name
- [ ] Selecting item shows description text
- [ ] Use mode changes interaction prompts to show item usage
- [ ] Shared inventory accessible by all players

**Menus:**
- [ ] Main menu: New Game, Continue, Settings, Quit all functional
- [ ] Pause menu: pauses game, Resume returns to gameplay
- [ ] Costume selection: shows available costumes, locks chosen ones in multiplayer

**Responsiveness:**
- [ ] UI scales correctly on window resize
- [ ] All UI navigable with both keyboard/mouse and controller
- [ ] Input routing correctly switches between gameplay and UI modes
