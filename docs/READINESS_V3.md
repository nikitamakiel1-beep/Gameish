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

| Area | Weight | Green-gate requirement |
|---|---:|---|
| Core gameplay and directional controls | 22% | Eight-direction unit checks and booted combat runtime |
| UI, HUD and accessibility | 18% | All screens reachable; safe-area and scaling contract present |
| Content and progression | 18% | Five lineages/biomes/bosses, 18 enemies and 60 relics |
| Assets and audio integration | 14% | All directional atlases and audio load successfully |
| Save/lifecycle reliability | 10% | Versioned profile, settings and suspend/restore contract |
| Automated technical validation | 8% | Import, audit and boot pass with zero fatal log markers |
| Device QA and balancing | 6% | Physical-device matrix and repeated seeded-run balance tests |
| Store/release operations | 4% | Signing, TestFlight, metadata, privacy and review assets |

The CI receipt in `validation/V3_RESULT.md` is the source of truth for technical readiness. Device QA and store-release work cannot be marked complete by headless CI.
