# EDEN//FALL v0.6 — production runtime contract

v0.6 replaces poster boards, block sprites and incomplete staging bundles with one deterministic Godot 4.7.1 production pipeline.

## Animation contract

- Direction order: `N, NE, E, SE, S, SW, W, NW`.
- Eight temporal frames per animation.
- Actor row formula: `action_index × 8 + direction_index`.
- Hero and standard-enemy frame size: 48×48.
- Boss frame size: 96×96.
- Actor actions: idle, walk, attack, dash, hurt and death.
- Boss actions: idle, attack, phase transition and destruction.
- Concept posters and review atlases are reference-only and are never loaded by the game.

## Production library

- Five lineage-specific hero sheets and portraits.
- Eighteen enemy packages with distinct silhouettes and combat identities.
- Five boss packages with directional threats and phase states.
- Five biome tile, prop and background packages.
- Sixty relic icons plus pickup, key, shop and interactable graphics.
- Projectile and effect atlases.
- Responsive HUD, menu and mobile-control assets.
- Five music loops, five ambience loops and event-driven SFX.

## Godot architecture

- `main.tscn` boots `scripts/edenfall_v6.gd`.
- `engine_bootstrap.gd` applies the exact-version report, deterministic 60 Hz simulation defaults and unified keyboard, mouse, controller and touch action map.
- `asset_registry.gd` routes directly to `generated_asset_registry.gd`.
- `generated_asset_registry.gd` owns semantic IDs, caching, contract validation and audio routing.
- `generated_asset_factory.gd` constructs transparent runtime sprites, biomes, VFX, UI assets and PCM audio deterministically.
- `edenfall_v6.gd` integrates those assets into the player, enemy, boss, projectile, pickup, HUD, touch-control, biome and audio paths.

There is no external Drive dependency and no incomplete encoded chunk bundle. Missing production resources emit explicit engine errors and fail validation instead of silently falling back to generic circles or legacy sheets.

## Validation

`tests/v6_asset_audit.gd` verifies:

- exact Godot 4.7.1 execution;
- project and export versioning;
- GL Compatibility rendering and 60 Hz physics;
- every required asset family and dimension;
- the complete runtime input map;
- `main.tscn` routing to v0.6;
- main-scene instantiation and runtime diagnostics;
- all seven export presets.

`.github/workflows/v6-godot-4.7.1.yml` imports, audits, boots and exports the exact pull-request head. The pull request remains draft until those gates pass.
