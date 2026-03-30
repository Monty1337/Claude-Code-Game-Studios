# Karneval Forever — Systems Index

Last updated: 2026-03-28

## Overview

18 systems decomposed from `game-concept.md`. Organized by category, layered
by dependency, and prioritized by milestone tier.

---

## Systems Enumeration

### Core Systems

| # | System | Description | Source | Priority |
|---|--------|-------------|--------|----------|
| 1 | Player Character | 3rd-person character controller — movement, camera, interaction | Core Loop | MVP |
| 2 | Interaction System | Player interacts with objects, items, and NPCs (raycasting, prompts, context actions) | Core Verb | MVP |
| 3 | Costume System | Costume selection, identity assignment, personality/dialogue tags per costume | Playable Costumes | MVP |
| 4 | NPC System | NPC placement, state, reactions to player costume, conversation triggers | Dialogue + Puzzles | MVP |

### Gameplay Systems

| # | System | Description | Source | Priority |
|---|--------|-------------|--------|----------|
| 5 | Item System | Pickable items, inventory, item use/combination for puzzle solving | MDA Mechanics | MVP |
| 6 | Dialogue System | NPC conversations with costume-dependent dialogue lines and branching | MDA Mechanics | MVP |
| 7 | Puzzle System | Framework for defining, tracking, and solving multi-step puzzles | MDA Mechanics | MVP |
| 8 | Mini-Task System | Self-contained humorous activities (beer tasting, Kamelle catching, float building) | MDA Mechanics | Vertical Slice |
| 9 | Hint System | Progressive in-world hints when players are stuck (NPC gossip, environmental clues) | Flow State Design | Vertical Slice |

### Progression Systems

| # | System | Description | Source | Priority |
|---|--------|-------------|--------|----------|
| 10 | Chapter System | Chapter loading, progression gating, story beat triggers, chapter transitions | Chapter Structure | Alpha |
| 11 | Curse Progression | Tracks curse state, triggers visual world changes as chapters are completed | Progression Loop | Alpha |

### Multiplayer Systems

| # | System | Description | Source | Priority |
|---|--------|-------------|--------|----------|
| 12 | Local Multiplayer | Split-screen / shared-screen 1-4 player local co-op | Genre & Platform | Vertical Slice |

### Presentation Systems

| # | System | Description | Source | Priority |
|---|--------|-------------|--------|----------|
| 13 | UI System | Main menu, pause menu, interaction prompts, inventory display, hint display | Infrastructure | MVP |
| 14 | Feedback System | Confetti bursts, comedic SFX, costume-themed animations on interaction | Core Loop | MVP |
| 15 | Audio System | Music, SFX, ambient Karneval sounds, costume-specific sound cues | Humor Pillar | Vertical Slice |
| 16 | Cutscene System | Comedic cutscenes between puzzles and at chapter transitions | Story Beats | Alpha |

### Infrastructure Systems

| # | System | Description | Source | Priority |
|---|--------|-------------|--------|----------|
| 17 | World/Environment | Chapter environments, props, interactables, Karneval decorations | Chapter Structure | MVP |
| 18 | Save/Load System | Save chapter progress, curse state, costume selection; resume later | Infrastructure | Alpha |

---

## Dependency Map

### Layer 1 — Foundation (zero dependencies)

- Player Character
- World/Environment
- Audio System
- UI System

### Layer 2 — Core (depends on Foundation)

| System | Depends On |
|--------|-----------|
| Interaction System | Player Character, World/Environment |
| Costume System | Player Character |
| NPC System | World/Environment |
| Save/Load System | (standalone infrastructure) |

### Layer 3 — Feature (depends on Core)

| System | Depends On |
|--------|-----------|
| Item System | Interaction System, World/Environment |
| Dialogue System | NPC System, Costume System, Interaction System |
| Feedback System | Interaction System, Audio System, Costume System |
| Puzzle System | Interaction System, Item System, Dialogue System, NPC System |

### Layer 4 — Progression (depends on Feature)

| System | Depends On |
|--------|-----------|
| Mini-Task System | Puzzle System, Interaction System, Feedback System |
| Hint System | Puzzle System, NPC System, Dialogue System |
| Cutscene System | Puzzle System, Costume System, Audio System |
| Chapter System | Puzzle System, World/Environment, Curse Progression, Save/Load |
| Curse Progression | Puzzle System, World/Environment, Feedback System |

### Layer 5 — Integration (depends on Progression)

| System | Depends On |
|--------|-----------|
| Local Multiplayer | Player Character, Costume System, Interaction System, Save/Load, all gameplay systems |

### Bottleneck Systems (high-risk — many dependents)

- **Interaction System** — 6 systems depend on it
- **Puzzle System** — 5 systems depend on it
- **Player Character** — 4 systems depend on it
- **World/Environment** — 4 systems depend on it

---

## Recommended Design Order

Design GDDs in this order (dependency + priority combined):

| Order | System | Layer | Priority | Status |
|-------|--------|-------|----------|--------|
| 1 | Player Character | Foundation | MVP | Designed |
| 2 | World/Environment | Foundation | MVP | Designed |
| 3 | Interaction System | Core | MVP | Designed |
| 4 | Costume System | Core | MVP | Designed |
| 5 | NPC System | Core | MVP | Designed |
| 6 | Item System | Feature | MVP | Designed |
| 7 | Dialogue System | Feature | MVP | Designed |
| 8 | Puzzle System | Feature | MVP | Designed |
| 9 | UI System | Foundation | MVP | Designed |
| 10 | Feedback System | Feature | MVP | Designed |
| 11 | Mini-Task System | Progression | Vertical Slice | Not Started |
| 12 | Hint System | Progression | Vertical Slice | Not Started |
| 13 | Audio System | Foundation | Vertical Slice | Not Started |
| 14 | Local Multiplayer | Integration | Vertical Slice | Not Started |
| 15 | Chapter System | Progression | Alpha | Not Started |
| 16 | Curse Progression | Progression | Alpha | Not Started |
| 17 | Save/Load System | Core | Alpha | Not Started |
| 18 | Cutscene System | Progression | Alpha | Not Started |

---

## Progress Tracker

| Milestone | Systems | Designed | Remaining |
|-----------|---------|----------|-----------|
| MVP | 10 | 10 | 0 |
| Vertical Slice | 4 | 0 | 4 |
| Alpha | 4 | 0 | 4 |
| **Total** | **18** | **10** | **8** |
