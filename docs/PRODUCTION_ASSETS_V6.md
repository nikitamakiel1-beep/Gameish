# EDEN//FALL v0.6 — production asset rebuild

v0.6 replaces poster-board and placeholder runtime presentation with production assets derived from the original generated EDEN//FALL artwork.

## Runtime contract

- Godot 4.7.1.
- Direction order: `N, NE, E, SE, S, SW, W, NW`.
- Eight temporal frames per animation.
- Row formula: `action_index × 8 + direction_index`.
- Hero and standard-enemy frame size: 48×48.
- Boss frame size: 96×96.
- Runtime actions: idle, walk, attack, dash, hurt and death.
- Concept posters are reference-only and are never loaded by the game.

## Integrated production library

- Five generated hero direction strips expanded into complete runtime sheets.
- Eighteen unique standard-enemy direction strips expanded into complete runtime sheets.
- Five boss masters expanded into idle, attack, phase and death sheets.
- Five generated biome tile, prop and background packages.
- Sixty relic icons and eighteen pickup, shop and key icons.
- Projectile and effect atlases.
- Responsive HUD panels and mobile-control skins.
- Five synthesized biome music loops, five ambience loops and event-driven SFX.

## Architecture

`asset_registry.gd` owns decode, cache, sheet generation, biome generation, audio synthesis and validation. Runtime code requests semantic asset IDs rather than repository paths.

The compact bundle stores the transparent pixel-art direction bases extracted from the generated EDEN//FALL atlases. Full animation sheets are rebuilt deterministically in memory, reducing repository and export size while preserving exact 8-direction behavior.

No hero, enemy or boss path falls back to a generic legacy sprite. Missing production assets produce explicit errors and fail the v0.6 audit.

## Validation

`tests/v6_asset_audit.gd` reconstructs the complete asset library, dimension-checks every hero, enemy, boss, biome and interface resource, loads the v0.6 runtime, instantiates the main scene and exits non-zero on any missing or malformed asset.
