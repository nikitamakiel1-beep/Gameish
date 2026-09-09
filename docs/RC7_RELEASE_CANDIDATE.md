# EDEN//FALL v0.6.1 RC7 — release-candidate engineering record

## Product revision

- Product revision: `0.6.1-rc7`
- Core v0.6 runtime/asset ABI: `0.6.0`
- Target engine: Godot `4.7.1`
- Active feature-branch root: `res://scripts/edenfall_v7_release_runtime.gd`
- Deep product gate: `res://tests/v7_masterpiece_audit.gd`
- Runtime-quality gate: `res://tests/v7_runtime_quality_audit.gd`

RC7 preserves all RC6 lore, asset IDs, animation dimensions, input paths, factions, special rooms, guardian identities, deterministic topology, save/restore protections and final Serpent resolution.

## RC7 deltas over RC6

### Encounter authorship

Combat/trial/contract rooms no longer depend primarily on independent random enemy picks. `scripts/v7/encounter_composer.gd` classifies all 18 standard enemies by combat role and composes deterministic pressure, crossfire, anchor, orbit, ritual and mixed signatures with role caps and authored formations.

### Reward authorship

`scripts/v7/relic_pool_director.gd` applies deterministic contextual preference to shop, treasure, trial, contract, sanctuary and special-room relic rolls while preserving Archive tier gating and duplicate exclusion.

### Combat fairness

`scripts/v7/combat_fairness_director.gd` and `edenfall_v7_fairness_runtime.gd` add post-transition spawn clearance, staggered hostile materialization, a 0.72-second room grace window and hazard suppression during entry grace.

### Lineage progression

Every nonfinal guardian victory now opens a deterministic two-choice Genome Adaptation before descent. Five original adaptations exist for each of the five lineages, 25 total. Adaptations are run-only and can change weapon projectiles, homing, penetration, explosion, cadence, dash, critical sensing, tissue capacity, shields, orbitals, fungal armor, lifesteal and spore mechanics.

The final Serpent Interface remains the separate RC6 ending decision.

### Sprite production

The RC7 actor factory retains the established atlas ABI and adds first-party pixel finishing: hard silhouette outline, selective rim light and sparse material-value variation. `scripts/v7/sprite_quality_evaluator.gd` rejects undersized or directionally indistinct actor sheets during the deep audit.

### Audio production

The emergency 11.025 kHz generic runtime synthesizer is superseded in the RC7 factory by deterministic 22.05 kHz production synthesis with five biome musical/ambience identities and separate warning families for melee/charge, aimed, radial/caster and guardian-phase danger.

### Runtime loading

RC7 separates runtime structural validation from deep release qualification. Ordinary startup performs a light representative asset check. The active runtime prewarms one asset at a time only during title/select or cleared noncombat states and retains the current biome hostile pool through normal cache trimming.

### Persistence

The RC7 release wrapper predeclares new persistent Archive schema keys before the inherited legacy profile loader executes. Guardian-adaptation pending state is stored separately and restored after inherited run reconstruction. Existing RC6 room/RNG/ending persistence remains mandatory.

## Reference/provenance

`docs/RC7_REFERENCE_AUDIT.md` records the commercial/open-reference research and the production rules derived from it. External games and public sprite repositories are references only. RC7 imports no external commercial sprite/audio data, no public sprite sheet and no external audio sample.

`ASSET_PIPELINE.md` is the current production/provenance specification.

## Qualification boundary

Source implementation and static contract audits do not qualify RC7 as a playable release.

Before the branch may be described as qualified, the exact branch head must pass:

1. Godot 4.7.1 import and complete parse.
2. Historical RC6 product audit.
3. RC7 deep masterpiece audit.
4. RC7 runtime-quality/audio/fairness audit.
5. Bounded `main.tscn` boot.
6. Representative desktop, phone and tablet screenshots.
7. Audio listening review.
8. Seeded runs with all five lineages.
9. All five guardian encounters and four nonfinal adaptation choices.
10. Suspend/restore during combat, guardian adaptation and Serpent resolution.
11. Web and physical-mobile frame-time/memory profiling.

Until those checks execute, RC7 remains a draft, unmerged release candidate.
