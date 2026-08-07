# EDEN//FALL v0.6.1 — Room Composition Contract

## Purpose

Rooms are authored combat spaces, not empty rectangles with decorative backgrounds. Every combat room may contain deterministic biome-specific cover that affects movement, projectile paths, line of sight and enemy approach vectors.

RC7 extends the RC6 world layer by making enemy composition and materialization authored as well as deterministic.

## Determinism

Floor topology derives from run seed, biome and floor number without permanently consuming the moment-to-moment combat RNG stream.

Obstacle layouts derive from:

- run seed;
- room-grid coordinate;
- biome index;
- room depth and room kind.

Encounter signatures derive from the same room identity through a separate hashed seed. Re-entering or restoring the same room in the same run must reproduce compatible topology, semantic room state and authored encounter identity.

## Room categories

Combat-bearing rooms include:

- combat;
- Genome Trial;
- enhanced-host contract;
- guardian/boss.

Decision/noncombat rooms include:

- start;
- treasure;
- caravan/shop;
- sanctuary;
- preadamite settlement;
- sacrifice bioreactor;
- lineage memory;
- maintenance tunnel;
- Serpent terminal.

Special decision rooms keep exits locked until their focal system is deliberately resolved.

## Encounter signatures

RC7 classifies all eighteen standard hostile IDs by combat role and composes rooms from authored signatures instead of treating the biome pool as an undifferentiated bag.

Current signatures:

- **Pressure Pack** — pincer formation with direct pressure and a limited ranged component.
- **Crossfire Cell** — ranged/skirmisher crossfire with pressure support.
- **Anchor & Escort** — a heavy/radial anchor with supporting hosts when the biome pool supports it.
- **Orbital Hunt** — orbiters and skirmishers surrounding the player path.
- **Ritual Battery** — caster-oriented diamond with pressure and charge support.
- **Mixed Host Cell** — controlled ring for general-purpose composition.

Design constraints:

- casters/radial emitters are capped to avoid projectile-noise stacking;
- trial/contract rooms do not default to the weakest generic signature;
- a bullet-storm environmental modifier does not stack with the crossfire signature;
- encounter count remains within the established 4–8 normal and 9 trial/contract ceiling;
- faction retaliation may add a single deterministic ambusher within the global room ceiling.

## Materialization and entry fairness

Room transition happens before final actor/cover resolution. RC7 therefore applies its fairness pass only after current-room cover has been rebuilt and the actual player transition position is known.

- room-entry grace: 0.72 seconds;
- standard hostile target clearance: 152 px before arena/cover correction;
- guardian target clearance: 210 px before correction;
- hostile activation is staggered rather than simultaneous;
- guardians receive a longer materialization delay;
- crossfire and corrosive-grid room hazards are suppressed during entry grace;
- materializing enemies expose a progress ring.

The goal is not to make rooms easier. It is to prevent damage that occurs before a threat can be perceived and attributed.

## Navigation rules

- Start, sanctuary and treasure rooms remain open for onboarding/reward clarity.
- Boss rooms use large structural elements appropriate to the guardian and biome.
- Normal combat rooms use three to five cover elements.
- Horizontal and vertical door lanes remain clear.
- Actors are pushed out of cover after room generation and after movement updates.
- Enemy separation still applies after obstacle collision resolution.
- Player movement supports wall sliding.
- Enemy navigation can steer tangentially around cover.
- Swept collision prevents high-speed dash/enemy tunnelling.

## Projectile and aim rules

- Player and enemy projectiles collide with cover.
- Fast projectile movement is sampled along the frame segment to reduce tunnelling.
- Cover impact creates visible feedback.
- Piercing projectiles may pierce actors but do not automatically pierce structural cover.
- Bounce-capable player projectiles can reflect from structural geometry through the RC6/RC7 projectile stack.
- RC7 aim assist rejects targets whose line to the player intersects structural cover.

## Biome cover families

### Industrial Eden

- overgrown planters;
- containment tanks;
- abandoned control consoles;
- root masses breaking through the laboratory floor.

### Ash Wastes

- vehicle wrecks;
- caravan barricades;
- fractured concrete;
- scrap heaps.

### Temple-Lab

- ritual columns;
- altars;
- glass vats;
- circuit pillars.

### Fungal Garden

- fungal towers;
- spore beds;
- root masses;
- mycelial vats.

### Nephilim Ruins

- ruined slabs;
- giant ribs;
- bone altars;
- collapsed towers.

## Guardian arena behavior

Guardian phases may change the arena rather than only increasing projectile count.

- First Nephilim can destroy cover.
- Gate Cherub can deploy auxiliary bodies.
- Tower of Enoch can reconfigure machine crossfire.
- Serpent Interface can deploy forked hosts.

Fifteen explicit guardian pattern families remain inherited from RC6 and are required under the RC7 audit.

## Readability constraints

- Cover uses the biome palette but remains darker/quieter than actors and projectiles.
- Every cover element receives a displaced shadow and clear collision border.
- Central combat lanes remain available even in dense rooms.
- Cover may create flanking routes, but must not seal the player or enemy into an unreachable pocket.
- Door exits remain visible and physically reachable.
- Encounter signature UI is subordinate to live combat.
- Visual and warning-audio telegraphs indicate attack class before release.

## Reward cadence

Room function now influences reward selection. Treasure, shop, trial, contract, sanctuary and special rooms each have a contextual relic-effect preference while preserving deterministic selection, Archive-tier gating and duplicate exclusion.

Every nonfinal guardian victory introduces a separate run-only Genome Adaptation choice before the next biome begins. This creates a deliberate major decision between biome arcs instead of relying entirely on passive room-count weapon scaling.

## Verification

Final RC7 verification is split across:

- `tests/v6_product_rebuild_audit.gd` for the inherited world/navigation/RC6 contract;
- `tests/v7_masterpiece_audit.gd` for encounter composition, deep art and progression;
- `tests/v7_runtime_quality_audit.gd` for fairness, audio and loading behavior.

`main.tscn` must route to `edenfall_v7_release_runtime.gd`.

Exact Godot 4.7.1 import, audit execution, bounded boot and seeded gameplay remain mandatory before qualification.
