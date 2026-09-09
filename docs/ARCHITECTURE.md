# EDEN//FALL — architecture

## Purpose

EDEN//FALL is an offline-first Godot 4.7.1 action-roguelike with a compatibility-preserving layered runtime. The production feature branch keeps historical v0.6/RC7 contracts auditable while the final V8/Art4 layers explicitly own stochastic generation, visual identity, presentation and release binding.

The architecture must preserve these properties:

1. Single-player remains playable without a network dependency.
2. Canonical hero identity is stable across runs and restores.
3. Fresh ordinary excursions are stochastic rather than public fixed-seed replays.
4. Already-generated active-run recipes/state survive suspend/resume without visible rerolling.
5. Cosmetic randomness cannot mutate progression-critical state.
6. Platform/cloud services remain replaceable adapters rather than gameplay dependencies.
7. Browser development can be qualified entirely inside GitHub Codespaces.

## Current release root

`main.tscn` is deliberately minimal and binds one Node2D to the final runtime:

```text
main.tscn
  -> scripts/edenfall_v8_release_runtime.gd
     -> scripts/edenfall_v8_animation_runtime.gd
        -> scripts/edenfall_v8_authored_presentation_runtime.gd
           -> Art3/V8 compatibility presentation/runtime layers
              -> RC7 / RC6 core gameplay lineage
```

The final release root does not pre-install Art3 components. `edenfall_v8_animation_runtime.gd` owns the active Art4 component installation before inherited initialization continues:

```text
Art4SpriteForgeScript
  -> scripts/v8/procedural_sprite_forge_art4.gd

Art4GenomeDirectorScript
  -> scripts/v8/enemy_genome_director_art4.gd

Art4WorldDirectorScript
  -> scripts/v8/procedural_world_director_art4.gd
```

This keeps one unambiguous active art stack while preserving inherited contracts for compatibility audits.

## Runtime responsibilities

### Release root

`scripts/edenfall_v8_release_runtime.gd` owns final product identity and release-level gameplay additions:

- `PRODUCT_REVISION = 0.6.4-authored-art4`;
- Art4 release-binding diagnostics;
- canonical hero restoration after older suspended-run data;
- stochastic enemy trait timers/actions;
- stochastic guardian pattern selection;
- release/godmode/entropy/masterpiece audit flags.

It inherits Art4 installation from the animation runtime rather than installing a competing legacy stack.

### Art4 presentation runtime

`scripts/edenfall_v8_animation_runtime.gd` owns:

- Art4 forge/genome/world installation;
- state-addressed actor frames;
- breathing/bob and controlled idle motion;
- recoil/muzzle/cast feedback;
- dash echoes and hit response;
- soft contact shadows;
- richer room perimeter volume;
- biome-specific animated environmental pockets.

### Art4 sprite forge

`scripts/v8/procedural_sprite_forge_art4.gd` preserves the compact sprite ABI while generating pose-first actor sheets. Heroes use canonical identity fields; enemies use curated family geometry and legal procedural variation.

### Art4 genome director

`scripts/v8/enemy_genome_director_art4.gd` adds family-level constraints to the inherited stochastic genome:

- motion profile;
- material family;
- FX family;
- weapon read;
- silhouette anchor.

The director may vary approved components and combat traits. It may not replace canonical heroes or turn one enemy family into unrelated geometry.

### Art4 world director

`scripts/v8/procedural_world_director_art4.gd` extends the quiet Art3 floor hierarchy with:

- biome story beats;
- macro-structure;
- light/prop/hazard pockets;
- landmark strength and wall damage;
- a persisted Art4 room signature.

The visual room recipe is part of active-run state once created.

## Entropy model

Ordinary excursions use fresh entropy. The design intentionally sets `fixed_seed_replay = false` for the active V8 product.

Separate entropy responsibilities should remain isolated conceptually:

```text
fresh excursion entropy
├── topology / special-room decisions
├── encounter recipes
├── legal enemy instance genomes
├── reward and relic order
├── biome/environment dressing
└── guardian pattern order

presentation-only variation
├── purely cosmetic particles
├── non-authoritative audio variation
├── camera effects
└── menu ambience
```

Presentation-only variation must not consume or alter active-run progression state.

Suspend/resume persists the already-created topology/recipes and active state. A restored run should continue what was created rather than recomputing the same screen from an exposed seed.

A future Daily Protocol may define a special challenge-generation contract. It must be isolated from the ordinary fresh-excursion model.

## Save model

The project remains local-first. Persistent profile and active-run data should provide:

- explicit schema version;
- atomic replacement where supported;
- previous-good recovery path;
- migrations for released schemas;
- bounded validation before restore;
- canonical hero identity normalization after migration;
- persistence of already-generated room/encounter/environment recipes.

A suspended run is disposable if its schema cannot be migrated safely; persistent account progression should not be corrupted to preserve one run.

Cloud authority is intentionally not required for the first release.

## Gameplay/data ownership

The inherited V6/V7 runtime contains established data and combat systems. V8 layers add stochastic directors and final product behavior without silently redefining the v0.6.0 compatibility ABI.

Long-term refactors may move inline dictionaries into `Resource` definitions, but that work must preserve semantic IDs and save migrations rather than changing data merely for architectural neatness.

Core content domains include:

- five lineages;
- enemy/faction definitions;
- guardians/patterns;
- relics and synergies;
- biome/room recipes;
- shops/economy;
- progression/archive;
- settings/accessibility;
- platform lifecycle.

## Rendering architecture

The project targets a 1280x720 logical viewport and Godot GL Compatibility on desktop, mobile and Web.

Pixel-art requirements:

- nearest-neighbor canvas filtering;
- transform/vertex pixel snapping;
- compact 48x48 normal actor frame ABI;
- 96x96 guardian frame ABI where required;
- combat-first contrast;
- restrained floor noise;
- large landmark hierarchy;
- consistent canonical hero identity.

The Web test channel is deliberately non-threaded and non-PWA to minimize cross-origin/header requirements and stale-service-worker failure modes during development.

## Input architecture

Gameplay consumes project actions rather than platform-specific code paths. The active action contract includes movement, aim, attack, dash, interact, pause and Archive navigation actions inherited by the runtime/audits.

Input providers may include:

- keyboard/mouse;
- controller;
- dual-touch mobile controls;
- accessibility/aim-assist policies.

Touch and mouse emulation are configured at the project level. Platform-specific input logic should not become authoritative gameplay state.

## Mobile lifecycle

The architecture must tolerate interruption at arbitrary points in a run:

- app backgrounding;
- focus loss;
- audio interruption;
- safe-area/layout changes;
- thermal/frame-rate constraints.

Save operations and suspend checkpoints should be bounded and should not introduce large synchronous work during dense combat.

## Performance boundaries

Art4 procedural generation is allowed to be expensive during explicit release audits, but normal play should avoid bulk synchronous regeneration during active combat.

Runtime rules:

- reuse/cache reconstructable generated textures;
- prewarm only in low-pressure states where practical;
- bound projectile and transient-effect counts;
- avoid synchronous network work on the gameplay thread;
- keep presentation effects semantically non-authoritative;
- trim caches without mutating active-run recipes;
- preserve 60 FPS as the primary target, with lower-power caps as a platform option.

## Codespaces/no-Actions qualification architecture

The supported online development loop is:

```text
tools/codespaces_sync_preview.sh
  -> fast-forward production feature branch
  -> tools/codespaces_preview.sh
     -> tools/export_web_no_actions.sh
        -> exact Godot 4.7.1
        -> clean editor import
        -> recursive all-GDScript load/instantiate audit
        -> curated bottom-up compile-chain probe
        -> release integrity audit
        -> Art4 visual/reference audit
        -> inherited RC6/RC7/V8 gates
        -> bounded main-scene boot
        -> Web export
        -> static Web/provenance verifier
     -> copy scoped purge page
     -> reverify artifact
     -> tools/codespaces_serve.sh
        -> verify artifact again
        -> require build SHA == current HEAD
        -> start no-cache HTTP server
        -> loopback health check
```

A preview server must not restart after a failed qualification. A stale successful `build/web` from an older commit must not be served as though it were the current build.

The qualification contract emits explicit pass markers including:

```text
EDEN_ALL_GDSCRIPT_COMPILE_AUDIT=PASS
EDEN_COMPILE_CHAIN=PASS
EDEN_FALL_V8_RELEASE_INTEGRITY_AUDIT=PASS
EDEN_FALL_V8_ART4_REFERENCE_AUDIT=PASS
```

## Direct Pages publishing

`tools/publish_gh_pages_no_actions.sh` publishes only an already-qualified artifact and refuses `main`.

It requires:

- current branch is the production feature branch;
- static verifier succeeds;
- build source SHA exactly equals current HEAD;
- product revision equals `0.6.4-authored-art4`;
- exact publish directory verifies after adding `404.html` and scoped `purge.html`;
- remote `gh-pages` tip equals the commit just pushed.

This keeps compilation/qualification separate from static publishing and prevents a stale Web directory from becoming release evidence.

## Optional backend boundary

Any future cloud system should sit behind a profile/service interface. Rules remain:

- local profile loads first;
- offline play does not require authentication;
- cloud restore cannot overwrite newer local progression blindly;
- unlock/stat merges must be migration-aware;
- purchase receipts require server validation if purchases exist;
- server credentials/API secrets are never committed.

## Security and privacy

The current single-player architecture should remain minimal in data collection. Before adding third-party SDKs:

- document transmitted data;
- review license and privacy policy;
- obtain required consent;
- keep telemetry optional where practical;
- avoid persistent device fingerprinting;
- maintain a clear local-save path independent of analytics/account services.

## Refactor rule

Do not refactor solely to reduce file count or inheritance depth while the production candidate is being stabilized. A refactor is justified when it removes a demonstrated failure mode, clarifies a single authoritative owner, improves measurable performance, or makes a release contract testable. Every such change must pass the same Godot 4.7.1 qualification stack before being considered safe.
