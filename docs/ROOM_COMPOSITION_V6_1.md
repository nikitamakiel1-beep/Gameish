# EDEN//FALL v0.6.1 — Room Composition Contract

## Purpose

Rooms are authored gameplay spaces, not empty rectangles with decorative backgrounds. Combat rooms contain deterministic biome-specific cover that affects movement, projectile paths and enemy approach vectors. Noncombat rooms contain a readable focal system and a decision that affects the run or persistent world memory.

## Determinism

Floor topology derives from run seed, biome index and floor number. Room-local systems derive from hashed combinations of:

- run seed;
- room-grid coordinate;
- biome index;
- room depth and room kind;
- a subsystem-specific salt.

Floor generation and room spawning restore the global combat RNG after use. Re-entering or restoring the same room in the same run must therefore reproduce the same room coordinate, encounter composition and authored systems.

## Navigation rules

- Start, sanctuary and treasure rooms remain open for onboarding and reward clarity.
- Boss rooms use large structural cover where compatible with the guardian.
- Normal combat rooms use three to five cover elements.
- Horizontal and vertical door lanes remain clear.
- Actors are pushed out of cover after room generation and after every movement update.
- Enemy separation still applies after obstacle collision resolution.
- Swept collision prevents fast player dashes and enemy movement from tunnelling through narrow cover.
- Player movement can slide along cover rather than stopping on every diagonal contact.
- Enemy steering uses cover tangents to reduce wall-sticking.

## Projectile rules

- Player and enemy projectiles collide with cover.
- Fast projectile movement is sampled along the frame segment to reduce tunnelling.
- Cover impact creates a visible effect and throttled impact sound.
- Piercing projectiles may pierce actors but do not pierce structural cover.
- Seth-style bounce projectiles can reflect from cover while retaining their remaining bounce budget.
- Homing, status, explosion and chain systems remain active after structural collision was added.

## Decision rooms

Decision rooms have no ordinary hostile wave and do not release their gates until the focal interaction is resolved.

### Preadamite settlement

The player approaches a settlement parley point and chooses between trade/favor or immediate salvage/reputation loss. The represented faction becomes part of persistent reputation memory.

### Sacrifice bioreactor

The player may exchange current tissue for a guaranteed relic or refuse the chamber and take a smaller salvage reward. The chamber refuses a lethal sacrifice.

### Lineage memory

The player may recover a contradictory lineage record into the Genome Archive or erase it for immediate resources.

### Maintenance tunnel

A hidden service cache allows a small scrap payment for a relic or can be stripped for immediate copper/salvage.

### Serpent terminal

The terminal offers a deterministic build mutation or a refusal reward. It is distinct from the final Serpent Interface resolution.

### Contract room

Contracts are combat rooms with guaranteed enhanced hosts, elevated rewards and a relic bounty.

## Faction consequences

Faction reputation modifies caravan prices. Sufficiently negative reputation can generate deterministic retaliation ambushes in later combat rooms. This system records consequence without reducing the six factions to a single morality axis.

## Guardian arena behavior

- **Watcher Engine:** rotating radial and aimed pattern families emphasize projectile reading.
- **First Nephilim:** later phases can destroy nearby structural cover, changing the arena during the fight.
- **Gate Cherub:** phase transitions deploy auxiliary cherub bodies and shielding behavior.
- **Tower of Enoch:** phase transitions reconfigure the room through machine crossfire.
- **Serpent Interface:** phase transitions deploy forked serpent hosts; victory is withheld until the final adaptation choice is resolved.

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

## Readability constraints

- Cover uses the biome palette but remains darker than actors and projectiles.
- Every cover element receives a displaced shadow and a clear collision border.
- Central combat lanes remain available even in dense rooms.
- Cover may create flanking routes, but must not seal a player or enemy into an unreachable pocket.
- Door exits remain visible and physically reachable.
- Decision-room focal systems use a distinct shape language and interaction radius.
- Guardian telegraphs must remain visually stronger than room decoration.

## Suspend/resume contract

The suspend extension stores current room, room visit/clear/use state, shop state, RC6 player mechanics and RNG state. Uncleared combat rooms restart their encounter on restoration; cleared rooms remain cleared. Final Serpent resolution has a separate pending marker so app suspension cannot skip the ending decision.

## Verification

`tests/v6_product_rebuild_audit.gd` requires world collision, swept navigation, deterministic floor topology, decision-room contracts, faction systems, fifteen guardian patterns, room-state persistence and `main.tscn` routing to `edenfall_v6_godmode_verified_runtime.gd`.

Exact Godot 4.7.1 import, audit execution, bounded boot, screenshots and gameplay checks remain mandatory before qualification.
