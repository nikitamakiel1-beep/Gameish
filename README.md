# Gameish: EDEN//FALL

EDEN//FALL is a mobile-first, top-down, room-based action roguelike set in an industrial post-apocalyptic Garden of Eden. The player awakens one of five engineered human lineages in an overgrown biolaboratory and pushes outward through ruined infrastructure, devastated roads and cities, ritualized machine laboratories, fungal ecologies and Nephilim-scale ruins.

The active feature-branch product revision is **0.6.4-authored-art4**, built against **Godot 4.7.1 stable**. The v0.6.0 runtime/asset ABI remains intentionally compatible where persistence and lookup contracts require it.

## Product state

Implemented on `godmode/production-assets-v6-rebuild`:

- Five canonical playable lineages: Adam, Abel, Cain, Seth and Naamah.
- Identity-locked protagonist silhouettes, palettes, proportions and weapon classes.
- Curated procedural enemy families with bounded visual and behavioral variation.
- Fresh stochastic run topology, encounter composition, environmental dressing, rewards and guardian pattern order.
- Five lore biomes with authored macro-grammar and procedural story beats:
  1. Industrial Eden.
  2. Ash Wastes.
  3. Temple-Lab.
  4. Fungal Garden.
  5. Nephilim Ruins.
- Room locking, traversal, combat, shops, relics, factions, bosses, persistence and Serpent-resolution systems inherited from the v0.6/RC7/V8 stack.
- Keyboard/mouse, gamepad-oriented actions and dual-touch twin-stick controls.
- Dash movement with invulnerability and telegraphed enemy/boss actions.
- Local Genome Archive progression and active-run suspend/resume.
- First-party procedural sprite, environment and synthesized-audio generation.
- Art4 runtime presentation with action-addressed sprite frames, breathing/bob, recoil, muzzle feedback, dash echoes, contact shadows and biome-specific room depth.
- Web export for browser testing using GL Compatibility, a 1280x720 logical viewport, nearest-neighbor pixel rendering, non-threaded Web and non-PWA delivery.

The project is still a development candidate, not a finished commercial release. Physical-device performance, final balancing, localization, store assets, signing/notarization and broad hands-on regression testing remain release work.

## Visual direction

Recognition-critical identity is authored; replayability-critical composition is procedural.

Heroes do not receive randomized replacement bodies. Enemy RNG operates inside curated family rules. Rooms use restrained floor texture plus large biome landmarks, collision-matched cover and localized environmental storytelling rather than room-sized procedural wallpaper.

The visual benchmark is compact, readable action-roguelike pixel art: strong silhouettes, oversized readable weapons, clear attack poses, controlled value ramps and combat-first contrast. Enter the Gungeon, Soul Knight and The Binding of Isaac are research references for readability, pacing and authored/procedural balance only. Horizon-style reclaimed technological scale informs environmental storytelling. No third-party commercial sprite pixels, characters, maps or UI are imported.

Detailed Art4 contract: `docs/V8_AUTHORED_ART4_DIRECTION.md`.

## Canonical lineages

- **Adam** — Eden-green survivor; Genesis Rifle; generalist/ranged identity.
- **Abel** — ivory/gold light caster; halo/focus language.
- **Cain** — black/red heavy combat lineage; permanently bound to the Mark Cannon visual identity.
- **Seth** — blue-steel guardian engineer; Watcher Carbine and engineer-node language.
- **Naamah** — violet mycelial caster; fungal cap/buds/tendrils and Spore Repeater identity.

Run-to-run changes may add legal wear, relic and status overlays, but they may not replace the base hero identity.

## Stochastic run model

Fresh excursions are intentionally not fixed-seed replays. Entropy controls route topology, special-room placement, encounter recipes, legal enemy genomes, rewards, environmental dressing and guardian pattern order.

Suspend/resume persists already-created active-run recipes and state. It does not regenerate the visible run from a public deterministic seed. Any future Daily Protocol can use a separately defined challenge contract without making ordinary excursions deterministic.

Cosmetic randomness is kept separate from progression-critical state so presentation cannot silently mutate a restored run.

## Online development: GitHub Codespaces

A local machine is not required for the normal browser-validation loop. The supported development path is a GitHub Codespace on the production feature branch.

From the repository Codespace terminal:

```bash
git checkout godmode/production-assets-v6-rebuild
git pull --ff-only origin godmode/production-assets-v6-rebuild
bash tools/codespaces_sync_preview.sh
```

`codespaces_sync_preview.sh` refuses tracked local edits, fast-forwards the production branch and starts the fail-closed qualification pipeline.

The pipeline:

1. Installs/uses exact Godot 4.7.1 and matching Web export templates.
2. Performs a clean editor import and parser pass.
3. Loads every GDScript under `res://scripts` and `res://tests` and requires `Script.can_instantiate()`.
4. Executes the curated bottom-up V7/V8 compile chain.
5. Verifies Art4 release bindings and version/export metadata.
6. Executes Art4 graphical/reference audits plus inherited RC6, RC7, entropy, presentation, runtime-quality and streaming gates.
7. Performs a bounded real main-scene boot.
8. Exports the non-threaded, non-PWA Web package.
9. Validates `index.html`, `index.js`, `index.wasm`, `index.pck`, build provenance and the Art4 version marker.
10. Starts a no-cache server on forwarded port 8000 only after qualification succeeds.

Important success markers include:

```text
EDEN_ALL_GDSCRIPT_COMPILE_AUDIT=PASS
EDEN_COMPILE_CHAIN=PASS
EDEN_FALL_V8_RELEASE_INTEGRITY_AUDIT=PASS
EDEN_FALL_V8_ART4_REFERENCE_AUDIT=PASS
```

The final Web verifier must report version `0.6.4-authored-art4`, `qualified: true` provenance and a full source commit SHA.

If an older PWA ever controlled the same Codespaces/browser origin, open `/purge.html` once. It unregisters EDEN//FALL workers and clears only the obsolete EDEN cache prefix; local save storage is deliberately preserved.

## Direct GitHub Pages publishing without custom Actions

After a successful Codespaces qualification/export, the same exact artifact can be published directly from the feature branch:

```bash
bash tools/publish_gh_pages_no_actions.sh
```

The publisher refuses `main`, rejects stale or unqualified builds, requires `build-info.json` to match the current source HEAD, verifies the exact publish directory again, pushes to `gh-pages`, and verifies the remote branch tip after the push.

The development contract does not require merging PR #8 to test the Web build.

## Controls

Desktop/browser:

- Move: `WASD` or arrow keys.
- Aim/fire: mouse or configured aim actions.
- Dash: `Space` or configured dash input.
- Interact/use: `E` / configured interact action.
- Pause: `Esc` / configured pause action.

Mobile:

- Left thumb: movement stick.
- Right thumb: aim/fire stick.
- Dedicated dash and utility controls where enabled.

The game is landscape-first and uses a 1280x720 logical viewport with pixel-art filtering and aspect-preserving scaling.

## Repository architecture

The current production lineage is intentionally layered so old ABI-compatible systems can be audited while newer behavior overrides them explicitly:

```text
main.tscn
  -> scripts/edenfall_v8_release_runtime.gd
     -> scripts/edenfall_v8_animation_runtime.gd
        -> Art4 presentation / Art3 compatibility runtime chain

Art4 component bindings:
  scripts/v8/procedural_sprite_forge_art4.gd
  scripts/v8/enemy_genome_director_art4.gd
  scripts/v8/procedural_world_director_art4.gd

Qualification:
  tests/all_gdscript_compile_audit.gd
  tests/v8_compile_chain_probe.gd
  tests/v8_release_integrity_audit.gd
  tests/v8_art4_reference_audit.gd
  inherited RC6 / RC7 / V8 audits
```

See `docs/ARCHITECTURE.md` for ownership boundaries and `ASSET_PIPELINE.md` for the art/audio generation contract.

## Save and backend policy

Single-player remains local-first. Persistent progression and suspended runs must not depend on network availability. Optional cloud/profile services may be added behind adapters later, but authentication failure must never prevent offline play.

No server credentials, signing keys, certificates or private store credentials belong in the repository.

## Originality and provenance

EDEN//FALL uses first-party code-generated/authored geometry and first-party synthesized audio for the active generated asset path. External games and public repositories may be studied for engineering, readability and asset-organization methodology. Their copyrighted art, character designs, maps, audio and UI are not copied into this project.

Any future external asset must have its exact source and license recorded and pass a deliberate provenance review before release use.

## Design and release documents

- `docs/GAME_DESIGN.md`
- `docs/ARCHITECTURE.md`
- `docs/V8_AUTHORED_ART4_DIRECTION.md`
- `ASSET_PIPELINE.md`
- `docs/IOS_APP_STORE.md`
