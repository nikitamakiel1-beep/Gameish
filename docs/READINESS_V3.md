# EDEN//FALL v0.3 readiness model

This document separates a validated playable build from a commercially releasable mobile game. A parser-clean headless boot is necessary but is not equivalent to App Store readiness.

## Implemented in v0.3

- Self-contained Godot 4.6 runtime; the previous four-script inheritance chain is no longer the main-scene dependency.
- Independent movement and aiming vectors for keyboard, mouse, controller and dual-touch input.
- Eight-direction movement, looking, animation selection, aiming and shooting: N, NE, E, SE, S, SW, W and NW.
- Five playable lineages, five biomes, eighteen standard enemy archetypes, five bosses and sixty relic protocols.
- Directional hero, enemy and boss sheets generated on a deterministic 48-row/32-row atlas contract.
- Complete in-run HUD: health, shield, hero identity, biome, objective, resources, boss health, relic inventory, minimap and cooldown feedback.
- Title, lineage selection, pause, settings/accessibility, archive, game-over and victory interfaces.
- Safe-area-aware layout, left-handed touch layout, HUD/text scaling, high contrast, reduced motion, aim assist, auto-fire, haptics and damage-number controls.
- Versioned profile/settings data and suspended-run restoration on mobile lifecycle notifications.
- Music, ambience and pooled event-driven SFX using the first-party generated audio package.

## Readiness weighting

| Area | Weight | Current score | Weighted result |
|---|---:|---:|---:|
| Core gameplay and directional controls | 22% | 92% | 20.24% |
| UI, HUD and accessibility | 18% | 88% | 15.84% |
| Content and progression | 18% | 80% | 14.40% |
| Assets and audio integration | 14% | 82% | 11.48% |
| Save/lifecycle reliability | 10% | 80% | 8.00% |
| Automated technical validation | 8% | 100% | 8.00% |
| Physical-device QA and balancing | 6% | 20% | 1.20% |
| Store/release operations | 4% | 15% | 0.60% |

**Weighted overall readiness: 79.76%, reported as 80%.**

Additional interpretations:

- **Validated playable-build readiness: 90%.** Core combat, directional controls, screens, content contracts and headless boot are implemented and automated.
- **Commercial/App Store release readiness: 62%.** Signing, TestFlight, physical-device testing, thermal and memory profiling, extensive balance telemetry, final localization, screenshots, privacy/support pages and App Review remain.

## Technical source of truth

The strict CI receipt in `validation/V3_RESULT.md` must show all of the following before integration:

- Import/parse exit `0`.
- Directional/content audit exit `0`.
- Main-scene boot exit `0`.
- Fatal log marker status `0`.

The audit scans logs for parser and runtime failures instead of relying only on Godot's process exit code. Physical-device QA and store-release work cannot be marked complete by headless CI.

## Remaining release-critical work

1. Run the full control, safe-area, suspend/resume, haptic and audio matrix on representative physical iPhone and iPad devices.
2. Conduct repeated seeded-run balance tests, frame-time profiling, memory/thermal profiling and long-session crash testing.
3. Replace or selectively polish any procedural art/audio that does not meet the final visual and mix standard.
4. Complete signing, TestFlight distribution, accessibility review, localization, screenshots, metadata, privacy/support pages and App Review preparation.
