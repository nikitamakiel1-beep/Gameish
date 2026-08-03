# EDEN//FALL v0.4 readiness model

v0.4 is a systems and production-hardening expansion over the validated v0.3 build. Its readiness score must not be increased until the committed source passes Godot 4.6.3 import, both regression audits and main-scene boot with no fatal log markers.

## Added in v0.4

- Deterministic run director and date-derived daily challenge seed.
- Standard, daily and training run modes.
- Eight deterministic chamber modifiers and modifier-linked rewards.
- Genome Trial and Eden Sanctuary special rooms.
- Five distinct lineage weapon identities.
- Four enemy status effects.
- Six elite affixes with readable visuals and behaviors.
- Threat scaling, encounter budgets and optional adaptive difficulty.
- Combo, score, mastery and run telemetry systems.
- Expanded HUD, archive, pause, end screens and accessibility controls.
- Atomic v0.4 profile and suspend extension files with backup recovery.
- v3 regression audit plus v4 behavioral audit.

## Weighted readiness model

| Area | Weight | v0.4 target after green CI |
|---|---:|---:|
| Core gameplay, weapons and controls | 22% | 95% |
| UI, HUD, onboarding and accessibility | 18% | 93% |
| Content, encounters and progression | 18% | 90% |
| Assets and audio integration | 12% | 84% |
| Save and lifecycle reliability | 10% | 90% |
| Automated technical validation | 10% | 100% |
| Physical-device QA and balancing | 6% | 25% |
| Store and release operations | 4% | 15% |

A green committed-source gate would produce a weighted engineering readiness of approximately **85%**. This is not equivalent to App Store release readiness.

## Release interpretation

- **Playable systems build:** target 94% after green CI.
- **Weighted project readiness:** target 85% after green CI.
- **Commercial/App Store readiness:** approximately 66% until physical-device QA and release operations are completed.

## Remaining release-critical work

1. Physical iPhone and iPad input, safe-area, haptic, audio and lifecycle testing.
2. Repeated daily and standard seeded-run balancing.
3. Frame-time, memory, thermal and battery profiling on representative devices.
4. Long-session crash and save-corruption testing.
5. Final art direction, animation cleanup, sound mix and music mastering.
6. Localization, screenshots, metadata, privacy/support pages, signing, TestFlight and App Review preparation.

## Source of truth

The readiness claim is valid only when the v0.4 workflow records all of the following on the committed branch:

- Godot import/parse exit `0`.
- v3 regression audit exit `0`.
- v4 behavioral audit exit `0`.
- Main-scene boot exit `0`.
- Fatal log marker status `0`.
