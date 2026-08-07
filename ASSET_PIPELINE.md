# EDEN//FALL — production asset pipeline

## Status

The current feature-branch product revision is **0.6.1-rc7**. The underlying v0.6 runtime/asset ABI remains **0.6.0** so older lookup contracts and saved metadata are not silently redefined.

EDEN//FALL uses first-party procedural visual and audio generation. The historical committed v0.2 pack remains covered by `assets/generated/ASSET_NOTICE.txt`. RC7 does not import commercial-game artwork, third-party sprite sheets, recordings, or samples.

## Reference policy

External games and public art repositories are research references only.

Commercial design benchmarks:

- Soul Knight — immediate controls, readable hero/weapon identity, compact procedural combat.
- Enter the Gungeon — bullet hierarchy, deliberate dodge timing, room composition, cover and telegraph discipline.
- The Binding of Isaac — contextual reward pools, build identity, silhouette-first enemy language and room cadence.
- Horizon — environmental storytelling through reclaimed machinery, vegetation and ruined technological scale.

Public/open art and code references inspected for production methodology include Universal LPC, Kenney top-down/roguelike packs, open Godot roguelike examples and open-source roguelike projects. Their useful lessons are frame conventions, modular asset organization, palette consistency, metadata, attribution discipline, testing and performance profiling. Their pixels are not copied into EDEN//FALL.

Universal LPC contains mixed licenses and explicit attribution/share-alike requirements for many components. Kenney publishes many packs under CC0. RC7 deliberately remains first-party anyway so EDEN//FALL keeps a coherent visual identity and avoids accidental license/provenance ambiguity.

Any future external asset must be isolated from first-party generated content, have its exact source/license recorded, and pass a deliberate provenance review before entering a release candidate.

## Current visual ABI

The semantic atlas contract is unchanged:

- 5 playable lineages: Adam, Abel, Cain, Seth and Naamah.
- 18 standard hostile IDs.
- 5 guardian IDs.
- 5 biome packages.
- 60 relic cells.
- pickups, projectiles, effects, HUD/menu panels and touch-control atlases.
- 8 directions.
- 8 frames per animation.
- idle, walk, attack, dash, hurt and death action rows.

Humanoid frames remain **48 × 48**. Guardian frames remain **96 × 96**. RC7 changes rendering quality behind those contracts, not the lookup API.

## RC7 generation chain

Runtime visual requests flow through:

1. `scripts/v7/asset_registry_masterpiece.gd`
2. `scripts/v7/generated_asset_factory_masterpiece.gd`
3. `scripts/v7/actor_asset_factory_masterpiece.gd` for actors/portraits
4. `scripts/v6/support_asset_factory_rebuild.gd` for environments/UI/projectiles/effects
5. `scripts/v7/audio_asset_factory_masterpiece.gd` for music, ambience and SFX

The RC7 actor factory inherits the established v0.6.1 silhouettes and adds a single finishing pass per actor frame:

- hard one-pixel dark silhouette outline;
- selective upper/left rim light;
- sparse deterministic value variation for material texture.

The finishing operations use the frame's source alpha mask, so outline generation cannot recursively grow itself. They execute once per generated frame rather than three independent full-frame passes.

## Sprite-quality gate

`scripts/v7/sprite_quality_evaluator.gd` measures more than file uniqueness. The deep RC7 audit evaluates each lineage, all 18 standard hostiles and all five guardians for:

- non-empty frame occupancy;
- minimum silhouette bounding-box width/height;
- multiple distinct directional silhouettes.

This prevents technically different sheets from passing while still reading as undersized or near-identical placeholder figures.

Whole-atlas uniqueness checks from the v0.6 product audit remain in force as a separate layer.

## Environment generation

The five environments preserve the lore progression:

1. Industrial Eden — sealed biotechnology, glass, irrigation arteries, roots and containment infrastructure.
2. Ash Wastes — ruined roads, caravans, wreckage, concrete and salvage culture.
3. Temple-Lab — scientific architecture reorganized into ritual machine space.
4. Fungal Garden — mycelial ecology consuming laboratories and urban remains.
5. Nephilim Ruins — devastated megacity scale, giant biological architecture and ancient machine remains.

Tiles/backgrounds establish material and ecological identity. Structural cover is generated separately by the world runtime and has gameplay collision; scenery cannot masquerade as passable cover.

## RC7 audio

The old emergency runtime synthesizer used four-second 11.025 kHz mono loops with two oscillators and hash-derived chirps. RC7 replaces that production path with deterministic **22.05 kHz, 16-bit mono** synthesis.

Each biome now has an eight-second looping musical/ambience basis with distinct roots, fifths, pulse rates, machinery texture and environmental events. The intended language remains mechanical liturgy rather than sampled cinematic music.

Combat SFX are classified by function instead of receiving one generic chirp. Families include player fire, hostile fire, impacts, critical hits, dash, damage, shields, doors, portals, relic/shop confirmation, boss phases, victory/death and four warning families:

- melee/charge warning;
- aimed-shot warning;
- radial/caster warning;
- guardian-phase warning.

No external recording or audio sample is used by the RC7 factory.

## Runtime generation and hitch control

Release validation and runtime startup are intentionally different operations.

Runtime startup performs a **shallow structural contract**. It verifies registry counts, ABI metadata, engine/input/rendering requirements and factory structure without generating every asset.

The active runtime then prewarms one asset at a time only during low-pressure states:

- title;
- lineage selection;
- cleared noncombat rooms.

It never performs speculative prewarming while hostiles are active. The current biome enemy pool and guardian are retained in the runtime cache so prewarmed sheets are not immediately discarded by the normal trimming cycle.

The explicit deep release audit is responsible for generating and inspecting the entire required catalog.

## Validation

`tests/v7_masterpiece_audit.gd` is the RC7 deep product gate. It is designed to require:

- exact Godot 4.7.1;
- core ABI and product revision consistency;
- deep generated-asset validation;
- hero/enemy/guardian sprite readability metrics;
- authored encounter-composition contracts;
- contextual relic pools;
- combat fairness/materialization contracts;
- inherited RC6 persistence, faction, synergy, guardian and Serpent-ending contracts;
- the final `main.tscn` route.

`tests/v6_product_rebuild_audit.gd` remains the historical RC6 subsystem audit. RC7 supersedes it as the final release gate while retaining its inherited runtime contracts.

Static/source audits do not qualify a release. Exact Godot 4.7.1 parsing, import, deep audit execution, bounded main-scene boot, screenshots, audio listening and hands-on seeded gameplay are still mandatory.

## Provenance statement

The existing first-party notice remains authoritative for committed generated assets:

> All images, animation frames, music, ambience and sound effects in the generated asset pack were produced from original project geometry/synthesis code; no third-party artwork, samples or recordings are used.

RC7 preserves that policy. Reference research changes engineering and art-direction rules, not asset ownership.
