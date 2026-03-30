# ADR-0001: Scene Structure and State Management

## Status
Accepted

## Date
2026-03-30

## Context

### Problem Statement
Karneval Forever has 10 interconnected gameplay systems (Player Character, Puzzle,
Dialogue, Item, NPC, Interaction, Costume, UI, Feedback, World/Environment) that
need to communicate across 3 chapter scenes. We need to decide how systems are
instantiated, how they communicate, and how game state persists across chapter
transitions. This decision shapes the entire codebase architecture and must be
made before prototyping begins.

### Constraints
- Godot 4.6 with GDScript (solo hobby developer)
- Must support 1-4 local co-op players
- 3 chapter scenes loaded independently (not open-world)
- Game state (puzzle flags, inventory, costume selection, curse level) must
  persist across chapter transitions
- Systems must be testable in isolation (per coding standards)
- Data-driven design: all gameplay values in Resources, not hardcoded

### Requirements
- Systems must be accessible from any scene (puzzle state checked during dialogue,
  inventory checked during interaction, etc.)
- Cross-system communication must be decoupled (Feedback System should not need
  to know about Puzzle System internals)
- Chapter transitions must be clean (no leaked state from previous chapter)
- Multiplayer: multiple players sharing the same game state

## Decision

### Architecture: Signal Bus + Autoload Singletons with Full Scene Swap

**System Communication**: A global `EventBus` autoload provides decoupled
cross-system communication via signals. Systems are autoload singletons that
connect to EventBus signals and expose public APIs for direct queries.

**Chapter Loading**: Each chapter is a complete `.tscn` scene. Transitions swap
the entire scene tree via `SceneTree.change_scene_to_packed()` with a fade-to-black
loading screen. Global state lives in autoloads and survives scene changes.

### Architecture Diagram

```
Godot Autoloads (persist across scenes):
+--------------------------------------------------+
| EventBus          | Global signal hub             |
| GameState         | Puzzle flags, curse level,     |
|                   | chapter progress               |
| InventoryManager  | Shared inventory (items)       |
| CostumeManager    | Costume registry (who wears    |
|                   | what, costume resources)        |
| SceneManager      | Chapter loading, transitions    |
+--------------------------------------------------+
         |  signals  |  direct API calls  |
         v           v                    v
+--------------------------------------------------+
| Active Chapter Scene (swapped per chapter):       |
|                                                   |
|   Environment (StaticBody3D, decorations, etc.)   |
|   PlayerSpawner (spawns PlayerCharacter scenes)   |
|   NPCSpawner (spawns NPC scenes from markers)     |
|   ItemSpawner (spawns Item scenes from markers)   |
|   PuzzleController (reads puzzle data, validates) |
|   DialogueController (reads dialogue data, runs)  |
|   InteractionDetector (per-player, on character)  |
|   FeedbackController (listens to EventBus)        |
|   UILayer (CanvasLayer with HUD, overlays, menus) |
+--------------------------------------------------+
```

### Autoload Responsibilities

| Autoload | Responsibility | Persists Across Scenes |
|----------|---------------|----------------------|
| `EventBus` | Signal hub — defines all cross-system signals. No logic, only signal declarations. | Yes |
| `GameState` | Puzzle flags, curse level, chapter progress, conversation history. Serializable for save/load. | Yes |
| `InventoryManager` | Shared inventory contents. Add/remove/query items. | Yes |
| `CostumeManager` | Costume registry. Which player wears which costume. Costume resource lookup. | Yes |
| `SceneManager` | Chapter scene loading with fade transition. Manages loading screen. | Yes |

### Scene-Local Controllers

Each chapter scene contains controller nodes that handle per-scene logic:

| Controller | Responsibility | Lifetime |
|-----------|---------------|----------|
| `PuzzleController` | Loads puzzle data for this chapter, validates steps, signals completion | Per-scene |
| `DialogueController` | Runs dialogue trees, manages text box state | Per-scene |
| `NPCSpawner` | Instantiates NPCs from scene markers | Per-scene |
| `ItemSpawner` | Instantiates items from scene markers | Per-scene |
| `PlayerSpawner` | Spawns player characters (reads from CostumeManager) | Per-scene |
| `FeedbackController` | Connects to EventBus, spawns particles/SFX | Per-scene |

### Key Interfaces

**EventBus signals** (the cross-system communication contract):

```gdscript
# EventBus.gd (Autoload)
extends Node

# Interaction
signal interaction_started(target: Node, player: Node)
signal interaction_ended(target: Node, player: Node)

# Items
signal item_picked_up(item_id: StringName, player: Node)
signal item_used(item_id: StringName, target_id: StringName, success: bool)

# Puzzles
signal puzzle_step_completed(puzzle_id: StringName, step_index: int)
signal puzzle_solved(puzzle_id: StringName)
signal chapter_completed(chapter: int)
signal puzzle_flag_set(flag_name: StringName, value: bool)

# NPCs
signal dialogue_started(npc_id: StringName, player: Node)
signal dialogue_ended(npc_id: StringName)
signal npc_startled(npc_id: StringName, position: Vector3)

# Character
signal hop_landed(player: Node, position: Vector3)

# Curse
signal curse_level_changed(new_level: float)
```

**GameState API**:

```gdscript
# GameState.gd (Autoload)
func get_puzzle_flag(flag: StringName) -> bool
func set_puzzle_flag(flag: StringName, value: bool) -> void
func get_curse_level() -> float
func advance_curse(delta: float) -> void
func get_chapter() -> int
func set_chapter(chapter: int) -> void
func serialize() -> Dictionary  # for save/load
func deserialize(data: Dictionary) -> void
```

### Chapter Transition Flow

```
1. All chapter puzzles solved
2. PuzzleController emits EventBus.chapter_completed(chapter)
3. GameState.set_chapter(next_chapter)
4. SceneManager.load_chapter(next_chapter)
   a. Fade to black (tween CanvasLayer opacity)
   b. SceneTree.change_scene_to_packed(chapter_scene)
   c. New scene's _ready() runs spawners
   d. Spawners read GameState for persistent data
   e. Fade from black
5. Player is in new chapter with all state preserved
```

## Alternatives Considered

### Alternative 1: Pure Autoload Singletons (No Signal Bus)
- **Description**: All systems are autoloads. They call each other's methods
  directly (e.g., `PuzzleManager.solve()` calls `InventoryManager.remove_item()`).
- **Pros**: Simpler, fewer files, direct method calls are easier to trace
- **Cons**: Tight coupling — every system must know about every other system's API.
  Hard to test in isolation. Adding a new system requires modifying existing ones.
- **Rejection Reason**: Violates decoupling principle. Feedback System should react
  to events without knowing which system caused them.

### Alternative 2: Scene Tree Composition (No Autoloads)
- **Description**: All systems are nodes in the chapter scene. No globals. State
  passed between scenes via a temporary Resource.
- **Pros**: Most Godot-idiomatic. Each scene is self-contained and testable.
- **Cons**: Cross-scene state management is awkward. Inventory, puzzle flags, and
  costume registry need to survive scene changes — requires a persistent data
  object passed manually. More boilerplate for a solo dev.
- **Rejection Reason**: Too much ceremony for a solo hobby project. The global
  state problem (inventory, puzzle flags, costumes) is naturally solved by autoloads.

### Alternative 3: Additive Scene Loading
- **Description**: A persistent root scene stays loaded. Chapter scenes are
  added/removed as children.
- **Pros**: Smoother transitions, no scene tree rebuild.
- **Cons**: More complex scene management. Must manually manage which nodes persist
  vs. which are chapter-specific. Risk of leaked nodes/state.
- **Rejection Reason**: Full scene swap is simpler and matches the chapter-based
  structure. The fade-to-black transition is appropriate for the game's pacing.

## Consequences

### Positive
- Clear separation: autoloads own persistent state, scene nodes own per-chapter logic
- Decoupled communication via EventBus — adding new systems just means connecting signals
- Full scene swap ensures clean chapter transitions with no leaked state
- Autoloads are testable in isolation (mock EventBus signals in tests)
- Natural fit for Godot's built-in scene management

### Negative
- Autoloads are global state (singletons) — must be disciplined about not abusing them
- Signal-based communication is harder to trace than direct method calls (mitigated by
  keeping EventBus as a single, documented signal contract)
- Five autoloads add some startup overhead (negligible for this game's scope)

### Risks
- **Autoload bloat**: Risk of adding too many autoloads over time. **Mitigation**: Only
  the 5 defined autoloads. New systems are scene-local controllers, not autoloads.
- **Signal spaghetti**: Risk of too many signals becoming hard to trace. **Mitigation**:
  All signals defined in one file (EventBus.gd). Document which systems emit and
  which consume each signal.
- **Scene swap lag**: Large chapter scenes may cause a load hitch. **Mitigation**:
  Loading screen covers the swap. Consider `ResourceLoader.load_threaded_request()`
  for background loading if needed.

## Performance Implications
- **CPU**: Negligible — autoload lookups are O(1), signal dispatch is efficient
- **Memory**: Each chapter scene fully loaded in memory (~50-100MB estimated for
  stylized low-poly). Previous chapter fully freed on swap.
- **Load Time**: Scene swap with loading screen. Target: ≤ 5s per chapter load
  (per World/Environment GDD acceptance criteria).
- **Network**: N/A (local co-op only in MVP)

## Migration Plan
N/A — this is a greenfield project. No existing code to migrate.

## Validation Criteria
- [ ] All 5 autoloads can be instantiated independently in a test scene
- [ ] EventBus signals can be emitted and received across scene boundaries
- [ ] Chapter transition preserves GameState (puzzle flags, inventory, costumes)
- [ ] Chapter transition frees all per-scene nodes (no memory leak)
- [ ] A new system can be added by creating a scene-local controller and connecting
  to existing EventBus signals — without modifying other systems

## Related Decisions
- `design/gdd/player-character.md` — Player Character states and movement
- `design/gdd/interaction-system.md` — Interactable interface contract
- `design/gdd/puzzle-system.md` — Puzzle state tracking and validation
- `design/gdd/item-system.md` — Shared inventory design
- `design/gdd/costume-system.md` — Costume registry and selection
- `design/gdd/world-environment.md` — Chapter environments and scene structure
