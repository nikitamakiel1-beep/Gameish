# EDEN//FALL v0.6 production asset rebuild

v0.6 replaces the runtime's generated-v3 and generic legacy visual fallback path with a mounted production resource library.

## Runtime library

- Pack SHA-256: `d7c10c03caac2db6bd331e2138bdbe5ae4443c994e35321db34497c628466018`
- ZIP bytes: `4406763`
- Base64 transport chunks: `10`
- Runtime files inside the mounted pack: `124`
- Five hero packages with generated-atlas-derived eight-direction sprites.
- Eighteen standard enemy sheets.
- Six elite-affix overlays.
- Five boss sheets.
- Five biome floor, wall, prop, hazard and background kits.
- Sixty relic icons and eight pickup families.
- UI panels, HUD skin, touch controls, app icon and boot splash.
- Global VFX plus generated music, ambience and SFX.

The large presentation boards remain reference material only. They are never listed in `registry.json` and cannot be selected by the runtime asset registry.

## Loading architecture

`production_pack.gd` reconstructs and SHA-256 verifies the ZIP from repository-safe text chunks, writes it to `user://`, and mounts it with `ProjectSettings.load_resource_pack`.

PNG files are decoded directly from mounted pack bytes into `ImageTexture` instances. WAV files are parsed from the mounted pack into `AudioStreamWAV` objects. This avoids dependency on editor-generated import sidecars inside the transport pack.

`asset_registry.gd` resolves heroes, enemies, bosses, biomes, UI, effects, items and audio. `animation_contract.gd` owns the exact action and direction row contracts.

## Acceptance rules

- No runtime registry path may contain `concept`.
- Hero sheets must be `384 × 4224`, use 48-pixel cells and contain 11 actions × 8 directions.
- Enemy sheets must be `256 × 1280`, use 32-pixel cells and contain 5 actions × 8 directions.
- Boss sheets must be `512 × 4096`, use 64-pixel cells and contain 8 actions × 8 directions.
- Required sprites must contain transparent pixels.
- Missing production assets display an explicit magenta diagnostic instead of silently substituting a generic character.
- The headless v0.6 audit mounts the pack, validates registry counts and dimensions, instantiates the main scene, and requires runtime readiness above 90%.
