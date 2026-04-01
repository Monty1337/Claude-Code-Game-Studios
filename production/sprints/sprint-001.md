# Sprint 1 — 2026-04-01 to 2026-04-14

## Sprint Goal
Build the production foundation: autoloads (EventBus, GameState, Inventory,
CostumeManager, SceneManager), first-person player controller, and the
interaction system — creating a walkable, interactable world from real
production code.

## Capacity
- Total days: 14 calendar days
- Hours per week: 5-10 (hobby pace)
- Total hours: ~10-20
- Buffer (20%): ~2-4 hours reserved for unplanned work
- Available: ~8-16 productive hours

## Tasks

### Must Have (Critical Path)

| ID | Task | Source GDD | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S1-01 | **Project setup**: Create Godot 4.6 project in `src/`, configure project.godot with input mappings, rendering settings, physics (Jolt 3D) | ADR-0001 | 1 | None | Project opens in Godot 4.6, runs empty scene, input actions configured |
| S1-02 | **EventBus autoload**: Implement all signals from ADR-0001. Single file, no logic, just signal declarations | ADR-0001, All GDDs | 0.5 | S1-01 | All cross-system signals declared, autoload registered |
| S1-03 | **GameState autoload**: Puzzle flags (get/set), curse level, chapter tracking, serialize/deserialize for future save/load | ADR-0001, Puzzle GDD | 1 | S1-01 | get/set_puzzle_flag works, curse_level advances, state serializes to Dictionary |
| S1-04 | **InventoryManager autoload**: Shared inventory — add, remove, has, get_items | Item System GDD | 0.5 | S1-01 | Items can be added/removed/queried, shared across scenes |
| S1-05 | **CostumeManager autoload**: Costume registry, resource loading, get_costume(player) | Costume System GDD | 1 | S1-01 | Costume resources load, registry tracks assignments, no duplicates enforced |
| S1-06 | **Player controller**: First-person CharacterBody3D — WASD movement, mouse look, hop, snappy response. Production quality (exported vars, clean code) | Player Char GDD | 3 | S1-01, S1-02 | Moves at 3.0/6.0 m/s walk/run, hops 0.5m, instant stop, mouse look with clamped vertical |
| S1-07 | **Interaction system**: Hybrid raycast + proximity detection, floating prompt, interactable interface (interaction_type, interact(), is_available()) | Interaction GDD | 3 | S1-06, S1-02 | Detects interactables within 4m, shows prompt, dispatches interact() on E press, one interaction at a time |
| S1-08 | **Test scene**: Simple blockout environment (~100x100m) with collision, a few walls/buildings, ground plane. At least 2 interactable test objects | World/Env GDD | 2 | S1-06, S1-07 | Player can walk around, interact with test objects, prompts appear/disappear correctly |

### Should Have

| ID | Task | Source GDD | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S1-09 | **Pickup items**: Item scene with bob/glow, implements interactable interface, adds to InventoryManager on pickup, removed from world | Item System GDD | 2 | S1-07, S1-04 | Items bob in world, prompt shows "Pick up [name]", pickup adds to inventory, item disappears |
| S1-10 | **Basic inventory UI**: Tab toggles inventory panel, shows item names/icons, examine shows description | UI System GDD, Item GDD | 2 | S1-09 | Tab opens/closes panel, items listed, selecting item shows description text |

### Nice to Have

| ID | Task | Source GDD | Est. Hours | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S1-11 | **NPC placeholder**: Static NPC with interactable interface, triggers a hardcoded dialogue sequence (text boxes, advance with E) | NPC GDD, Dialogue GDD | 2 | S1-07 | NPC shows "Talk to" prompt, E opens dialogue, E advances lines, dialogue ends cleanly |
| S1-12 | **SceneManager autoload**: Chapter scene loading with fade-to-black transition | ADR-0001 | 1 | S1-01 | Can load a scene with fade transition, old scene freed, new scene runs |

## Carryover from Previous Sprint
N/A — first sprint.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Godot 4.6 API differences from LLM knowledge | High | Medium | Cross-reference `docs/engine-reference/godot/` before writing API calls. Test incrementally. |
| Interaction detection feels wrong (too sensitive/insensitive) | Medium | Low | Tuning knobs are exported vars — adjust at runtime in editor. Prototype already validated the approach. |
| Scope creep into content creation | Medium | Medium | Sprint 1 is systems only. No puzzle content, no real NPCs, no dialogue trees. Blockout only. |
| Hobby time varies week to week | High | Medium | Must Have tasks estimated at ~12 hours. Even at minimum pace (10 hrs) the critical path fits. |

## Dependencies on External Factors
- Godot 4.6 must be installed and functional
- Free 3D assets not needed yet (blockout with primitives)

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed (S1-01 through S1-08)
- [ ] Player can walk around a test scene in first person
- [ ] Player can interact with at least 2 different object types
- [ ] All 5 autoloads are registered and functional
- [ ] Code follows GDScript naming conventions from technical-preferences.md
- [ ] No hardcoded values — all tuning knobs are exported vars
- [ ] All code committed to git with meaningful commit messages

## Sprint 1 → Sprint 2 Handoff
If Sprint 1 completes fully, Sprint 2 should focus on:
- NPC system with behavior routines
- Dialogue system with data-driven trees and costume variants
- Puzzle system framework
- Costume selection flow
- First real chapter environment (Chapter 1 blockout)
