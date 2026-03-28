# Karneval Forever — Game Concept Document

## Elevator Pitch

After Rosenmontag, the costumes won't come off. You and up to 3 friends must
solve Karneval-themed puzzles across a cursed Rhineland town to break the spell
before Aschermittwoch — or stay in costume forever.

## Genre & Platform

- **Genre**: 3D third-person cooperative puzzle adventure
- **Players**: 1–4 (local co-op; online stretch goal)
- **Platform**: PC (primary), console (stretch)
- **Engine**: Godot 4.6
- **Art Style**: Stylized / low-poly with colorful, exaggerated proportions
- **Asset Strategy**: Free 3D assets, unified through consistent shading and
  Karneval-themed modifications
- **Estimated Playtime**: 2–3 hours (MVP 3 chapters)

## Core Fantasy

> "We're trapped in our ridiculous costumes and have to work together —
> tasting beer, catching Kamelle, and talking to cursed NPCs — to figure
> out what happened and set things right."

The player fantasy is the absurdity of Karneval becoming permanent: a world
where the party never stopped, nobody can take off their costume, and the only
way out is through the most Karneval thing imaginable — more Karneval.

## Core Verb

**Investigate** — players explore environments, find items, talk to NPCs, and
complete humorous tasks (taste-testing beer, catching thrown candy, building
parade floats) to solve Karneval-themed puzzles.

## Unique Hook

Like **It Takes Two**, AND ALSO rooted in authentic Rhineland Karneval culture —
real traditions, dialect, and rituals turned into cooperative puzzle gameplay.
Each costume gives a unique comedic identity, not mechanical abilities: the
Pirate talks like a pirate to NPCs (getting hilarious reactions), the Clown
gets different dialogue, etc. Puzzles are identical regardless of player count —
more players means more chaos and funnier interactions, not different mechanics.

---

## Design Pillars

### 1. Jeck sein (Be Silly)

Humor comes first. Every puzzle, dialogue, and interaction should make players
laugh or smile.

**Design test**: "If we're choosing between clever and funny, we choose funny."

### 2. Zosamme (Together)

The game is better with friends, but never broken alone. Multiplayer amplifies
the fun; solo is complete.

**Design test**: "If a feature only works in co-op, redesign it so solo players
still enjoy it."

### 3. Echt Kull (Authentically Karneval)

Rooted in real Karneval culture — traditions, language, rituals — not a generic
"carnival" skin.

**Design test**: "If a non-Rhinelander wouldn't understand something without
context, add context — but never remove the authenticity."

## Anti-Pillars (What This Game Is NOT)

- **NOT a skill-based action game** — no combat, no reflexes, no difficulty walls
- **NOT a dark/horror take** on the curse — the tone stays comedic even when the
  curse is mysterious
- **NOT an open-world sandbox** — tight, curated chapters with clear progression

---

## MDA Analysis

### Aesthetics (Player Emotions — in priority order)

1. **Fellowship** — shared laughter and cooperative problem-solving
2. **Humor / Submission** — the joy of absurdity and going along with the chaos
3. **Discovery** — finding hidden jokes, NPC stories, and Karneval details
4. **Challenge** — the satisfying "aha!" of puzzle solutions clicking into place

### Dynamics (Emergent Behavior)

- Players naturally divide tasks: "You talk to that NPC, I'll search this room"
- Costume-specific dialogue creates "show and tell" moments: "Wait, what did
  YOUR character say to the bartender?"
- Hidden details reward thorough exploration and repeat playthroughs with
  different costumes
- Humorous failure states (wrong beer choice, bad Büttenrede) are entertaining
  rather than punishing

### Mechanics (Systems)

- Item-finding and environmental investigation
- NPC dialogue with costume-dependent responses
- Humorous mini-tasks (beer tasting, Kamelle catching, float building)
- Multi-step puzzles requiring item combination or sequence completion
- Chapter progression with narrative gating

---

## Core Loop Structure

### 30-Second Loop (Moment-to-Moment)

- Explore the environment, interact with objects and NPCs
- Discover clues, items, or funny details
- Share findings with co-op partners
- Satisfying feedback: costume-themed animations, comedic sound effects,
  confetti bursts

### 5-Minute Loop (Puzzle Cycle)

- Encounter a Karneval-themed puzzle (e.g., "find the right ingredients for
  the Brauhaus's secret Kölsch recipe")
- Investigate: talk to NPCs, search for items, try combinations
- The "aha!" moment when the solution clicks
- Reward: comedic cutscene, curse weakens, new area/information unlocked

### Session Loop (30–60 min per chapter)

- Enter a chapter with a distinct Karneval theme
- Solve 3–4 puzzles that build on each other
- Story beats between puzzles reveal the curse's origin
- Chapter climax: a larger combined puzzle using chapter knowledge
- Comedic payoff transitions to the next chapter

### Progression Loop (Full Game)

- Each chapter solved weakens the curse (visual changes in the world)
- Players piece together the backstory: who caused the curse and why
- Final chapter: the big unmasking — break the curse in a comedic finale

---

## Player Motivation Profile

### Self-Determination Theory

- **Autonomy**: Players choose where to explore, who to talk to, and in what
  order to approach puzzle elements. Costume choice shapes dialogue and
  experience. Multiple valid approaches per puzzle.
- **Competence**: Puzzle difficulty ramps naturally across chapters. Early
  puzzles teach patterns; later puzzles recombine them. The "aha!" moment is
  the primary competence reward.
- **Relatedness**: Co-op play creates shared stories and inside jokes. NPCs
  are memorable characters with their own curse stories. The Karneval theme
  itself is about community and togetherness.

### Flow State Design

- **Anxiety prevention**: No fail states, no time pressure (by default), no
  death. Wrong answers produce funny reactions, not punishment.
- **Boredom prevention**: Puzzle variety (item hunts, dialogue puzzles, mini-
  tasks), environmental humor, costume-specific content.
- **Flow channel**: Puzzles start with clear objectives and become more open-
  ended. Hints available if stuck (framed as NPC gossip or in-world clues).

---

## Target Audience

### Primary: Socializers / Fellowship-Seekers

Players who love shared experiences, inside jokes, and cooperative problem-
solving. They play for the people — the game is the excuse to hang out.

**Reference audiences**: It Takes Two couples/friends, Overcooked groups,
Jackbox party nights.

### Secondary: Explorers / Discoverers

Players who enjoy poking at every object, talking to every NPC, and finding
hidden jokes. The Karneval setting rewards curiosity.

### Who This Is NOT For

- Competitive players looking for PvP or leaderboards
- Hardcore puzzle solvers wanting brain-melting difficulty
- Players who want deep progression systems, builds, or optimization

### Market Validation

- It Takes Two: 10M+ sales, proved co-op puzzle-adventure is mainstream
- Overcooked franchise: consistent commercial success in co-op comedy
- Moving Out, KeyWe, Plate Up: the genre is growing
- Cultural identity (Karneval) provides discoverability and built-in
  Rhineland/German fanbase

---

## Playable Costumes

Each costume defines the player's comedic identity. All players can solve all
puzzles — costumes change the *experience*, not the mechanics.

| Costume | Personality | Dialogue Style | Comedy Hook |
|---------|-------------|---------------|-------------|
| **Pirate** | Blustering, dramatic | Talks in pirate-speak to confused NPCs | Takes everything too seriously |
| **Clown** | Mischievous, chaotic | Slapstick responses, puns | Physical comedy, prop gags |
| **Knight** | Chivalrous, formal | Overly formal medieval speech | Treats modern situations as quests |
| **Witch** | Mysterious, dramatic | Cryptic pronouncements | Over-the-top theatrical reactions |

**Costume-Specific Content**:
- Each costume gets unique dialogue lines with NPCs
- Some NPCs react differently based on costume (a medieval history buff
  loves the Knight, fears the Witch)
- Hidden easter eggs for specific costume/NPC combinations
- Encourages replay with different costumes

---

## Chapter Structure

### Chapter 1: Der Morgen Danach (The Morning After)

**Setting**: The Altstadt (old town) center, morning after Rosenmontag
**Theme**: Tutorial — establish the world, the curse, and basic mechanics
**Puzzles**: 3–4 introductory puzzles (find your way around, talk to first
NPCs, complete a simple item-fetch)
**Story beat**: Wake up, realize costumes are stuck, meet other cursed people,
learn the curse might be breakable

### Chapter 2: Dat Brauhaus (The Brewery)

**Setting**: A legendary Brauhaus and surrounding district
**Theme**: Investigation — deeper puzzles, more NPC interaction
**Puzzles**: 3–4 themed puzzles (beer-tasting challenge, recipe reconstruction,
Kölsch-related traditions)
**Story beat**: Clues point to the curse's origin — something went wrong at the
last Sitzung (Karneval session)

### Chapter 3: Der letzte Zoch (The Final Parade)

**Setting**: The parade route and staging area
**Theme**: Climax — hardest puzzles, emotional payoff
**Puzzles**: 3–4 culminating puzzles (build a float, organize the parade,
the final unmasking ritual)
**Story beat**: Confront the source of the curse and break it in a single
comedic finale

---

## Scope Tiers

| Tier | Content | Notes |
|------|---------|-------|
| **Bronze (MVP)** | 1 chapter, 2 costumes, local 2-player, 3 puzzles | Minimum to test "is the core loop fun?" |
| **Silver (Target)** | 3 chapters, 4 costumes, local 1–4 player, ~12 puzzles | Full game as designed |
| **Gold (Stretch)** | + Online multiplayer, + bonus costumes, + hidden puzzles, + Kölsch dialect voice lines | Post-launch or if development goes fast |

---

## Risk Assessment

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| Multiplayer networking complexity | High | High | Start with local co-op only; defer online to Gold tier |
| Puzzle variety (12 puzzles feeling samey) | Medium | Medium | Build modular puzzle framework; playtest each type in isolation |
| Free asset visual cohesion | Medium | Medium | Choose one art style pack early; unify via post-processing/shading |
| Solo dev scope creep | High | High | Enforce anti-pillars strictly; build Bronze MVP first |
| Karneval theme too niche | Low | Medium | Add in-world context for non-Rhinelanders; humor transcends culture |

---

## Engine Recommendation

**Godot 4.6** — selected by the developer. Strong fit because:
- Free and open-source (matches free-asset philosophy)
- 3D capabilities significantly improved in 4.4–4.6 (Jolt physics default,
  D3D12 on Windows, glow rework)
- Built-in multiplayer API for future online co-op
- GDScript is approachable for solo hobby development
- Active community with extensive documentation

**Caution**: LLM knowledge covers Godot up to ~4.3. Versions 4.4–4.6
introduced breaking changes. Always cross-reference `docs/engine-reference/godot/`
before using Godot API suggestions.

---

## Next Steps

1. `/setup-engine godot 4.6` — configure the engine and populate version-aware
   reference docs
2. `/design-review design/gdd/game-concept.md` — validate this document's
   completeness
3. `/map-systems` — decompose the concept into individual systems (costumes,
   puzzles, multiplayer, dialogue, progression) with dependencies and priorities
4. `/design-system` — author per-system GDDs (guided, section-by-section)
5. `/prototype core-loop` — prototype the first puzzle to validate the fun
6. `/sprint-plan new` — plan the first development sprint
