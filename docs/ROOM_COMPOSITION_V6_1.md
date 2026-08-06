# EDEN//FALL v0.6.1 — Room Composition Contract

## Purpose

Rooms are authored combat spaces, not empty rectangles with decorative backgrounds. Every combat room may contain deterministic biome-specific cover that affects movement, projectile paths, line of sight and enemy approach vectors.

## Determinism

Obstacle layouts derive from:

- run seed;
- room-grid coordinate;
- biome index;
- room depth and room kind.

Re-entering the same room in the same run must reproduce the same geometry.

## Navigation rules

- Start, sanctuary and treasure rooms remain open for onboarding and reward clarity.
- Boss rooms use two large vertical cover elements.
- Normal combat rooms use three to five cover elements.
- Horizontal and vertical door lanes remain clear.
- Actors are pushed out of cover after room generation and after every movement update.
- Enemy separation still applies after obstacle collision resolution.
- Dash movement terminates when the player is blocked by cover.

## Projectile rules

- Player and enemy projectiles collide with cover.
- Fast projectile movement is sampled along the frame segment to reduce tunnelling.
- Cover impact creates a visible effect and throttled impact sound.
- Piercing projectiles may pierce actors but do not pierce structural cover.

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

## Verification

`tests/v6_product_rebuild_audit.gd` requires the world runtime, collision symbols, safe geometry APIs, and `main.tscn` routing to `edenfall_v6_world_runtime.gd`.

Exact Godot 4.7.1 import, boot and gameplay checks remain mandatory before qualification.
