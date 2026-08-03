# Architecture

## Purpose

The current repository is a dependency-free Godot vertical slice. It deliberately compresses the game into a small number of scripts so the core loop can be evaluated before production assets and backend services are introduced.

The production architecture should preserve three properties:

1. Single-player remains playable offline.
2. A run is reproducible from a seed.
3. Platform services and online services are replaceable adapters rather than gameplay dependencies.

## Current runtime

```text
main.tscn
  └── game_runtime.gd
        └── game.gd
              └── game_core.gd
                    └── game_data.gd
```

### `game_data.gd`

Static definitions for:

- Five lineages.
- Ten prototype items.
- Four standard enemy types and one boss.

### `game_core.gd`

Owns:

- Application state.
- Run seed and random-number generator.
- Room graph generation.
- Room spawning and transitions.
- Player input and movement.
- Bullet and collision simulation.
- Enemy behavior and boss patterns.
- Shop economy.
- Item application.
- Local persistence.

### `game.gd`

Owns procedural vector rendering for:

- Menus.
- Selection cards.
- Arena and doors.
- Player, enemies, projectiles, and pickups.
- HUD and minimap.
- Shop cards.
- Touch controls.
- Pause and run-result screens.

### `game_runtime.gd`

Contains compatibility corrections that can be removed after the core is refactored. It currently ensures the player can cross room boundaries while respecting collision-radius clamping.

## Determinism

All run content should use one run-scoped `RandomNumberGenerator` initialized from `run_seed`.

The following must not consume the run RNG:

- Cosmetic particles.
- Camera shake.
- Audio variation.
- Menu animation.
- Analytics identifiers.

Production code should use separate RNG streams derived from the run seed:

```text
run_seed
├── map_rng
├── encounter_rng
├── loot_rng
└── cosmetic_rng
```

This makes daily seeds, replays, debugging, and leaderboard validation more reliable.

## Save model

The prototype writes one JSON object to `user://edenfall_save.json`.

Production saves should use:

- A schema version.
- Atomic write to a temporary file followed by rename.
- A previous-good backup.
- Checksums for accidental corruption detection.
- Migration functions for every released schema.

Suggested structure:

```json
{
  "schema": 1,
  "profile_id": "local-generated-id",
  "genome": 0,
  "best_depth": 0,
  "runs_completed": 0,
  "unlocks": [],
  "settings": {},
  "statistics": {}
}
```

Do not store active-run authority in the cloud for the first release. A suspended run should be local, resumable, and disposable if its schema becomes incompatible.

## Production refactor

After the vertical slice is validated, split the project by responsibility:

```text
res://
├── assets/
│   ├── art/
│   ├── audio/
│   ├── fonts/
│   └── shaders/
├── data/
│   ├── enemies/
│   ├── items/
│   ├── lineages/
│   └── rooms/
├── scenes/
│   ├── actors/
│   ├── enemies/
│   ├── game/
│   ├── projectiles/
│   ├── rooms/
│   └── ui/
├── systems/
│   ├── audio/
│   ├── backend/
│   ├── combat/
│   ├── input/
│   ├── progression/
│   ├── save/
│   └── telemetry/
├── platform/
│   ├── haptics.gd
│   ├── safe_area.gd
│   └── store.gd
└── tests/
```

Public mobile-game repositories were reviewed as architecture references. No external repository code or assets have been copied into this project.

## Scene model

Recommended production scenes:

- `Boot`: Loads settings, migrations, and platform adapters.
- `MainMenu`: Title, settings, accessibility, Archive.
- `Biolab`: Lineage selection and meta-progression.
- `Run`: Owns map, room state, run RNG, and run inventory.
- `Room`: Owns geometry, doors, enemy spawners, and hazards.
- `Player`: CharacterBody2D with lineage resource.
- `Enemy`: CharacterBody2D with behavior resource or state machine.
- `Projectile`: Pooled Area2D or custom lightweight simulation.
- `RunResults`: Genome recovery, unlock presentation, statistics.

The current custom-array projectile model is efficient enough for the prototype. Production should benchmark custom simulation against pooled nodes on target iPhones before choosing one permanently.

## Data-driven content

Lineages, items, enemies, rooms, and bosses should move from inline dictionaries to Godot `Resource` types.

Suggested resources:

- `LineageDefinition`.
- `ItemDefinition`.
- `EnemyDefinition`.
- `RoomDefinition`.
- `AttackPattern`.
- `StatusEffectDefinition`.

Item behavior should be tag-driven. Example tags:

```text
projectile
critical
fungal
halo
penetration
healing
sacrifice
industrial
seraphic
nephilim
```

A synergy resolver can react to tag combinations without hard-coding every pair into the player script.

## Input architecture

Maintain one abstract action layer:

- `move_vector`.
- `aim_vector`.
- `fire_held`.
- `dash_pressed`.
- `interact_pressed`.
- `pause_pressed`.

Input providers:

- Keyboard/mouse.
- Touch dual-stick.
- Controller.
- Accessibility/one-stick aim-assist mode.

The gameplay layer should never check a platform-specific touch index directly after refactoring.

## Mobile UI

Production UI must account for:

- Safe-area insets.
- Rounded corners and sensor housing.
- Home-indicator exclusion.
- Multiple iPhone and iPad aspect ratios.
- Left-handed control mirroring.
- Adjustable stick radius, opacity, and dead zone.
- Dynamic text scaling.
- Reduced motion and reduced flash.

Critical enemies, projectiles, doors, and pickups must remain inside the visual safe region even when controls are visible.

## Performance budgets

Initial targets on a representative older supported iPhone:

- 60 frames per second gameplay target.
- Optional 30-frame cap for battery and thermal control.
- No frame allocation spikes from bullets or particles.
- Bounded simultaneous hostile projectiles by encounter tier.
- Reused audio players and pooled transient effects.
- No synchronous network request on the gameplay thread.
- No save write during dense combat unless the app is backgrounding.

Compatibility renderer is used in the prototype to maximize device coverage. Reconsider Mobile renderer only after measuring actual target-device performance and shader requirements.

## Optional Nakama boundary

Nakama should be introduced behind an interface such as:

```gdscript
class_name ProfileService

func sign_in() -> bool:
    return false

func pull_profile() -> Dictionary:
    return {}

func push_profile(_profile: Dictionary) -> bool:
    return false

func submit_seed_score(_seed: int, _score: int, _metadata: Dictionary) -> bool:
    return false
```

Implementations:

- `LocalProfileService`: Always available.
- `NakamaProfileService`: Optional authentication, storage, and leaderboard sync.

Rules:

- Local profile loads first.
- Cloud restore must merge monotonically for unlocks and lifetime statistics.
- A stale cloud profile must never overwrite newer local progression.
- Failed authentication must not prevent play.
- Server credentials and API keys must never be committed.
- Purchase receipts must be validated server-side if purchases are introduced.

## Continuous integration

`.github/workflows/validate.yml` downloads the official Godot 4.6.3 Linux binary, imports the project headlessly, parses scripts, and boots the main scene briefly.

Future CI stages:

- GDScript format and lint.
- Deterministic map-generation tests across thousands of seeds.
- Reachability and guaranteed-room tests.
- Save migration tests.
- Item-combination smoke tests.
- Screenshot capture for UI regression.
- Unsigned iOS project export on macOS.
- Signed TestFlight archive only in a protected release workflow with repository secrets.

## Security and privacy

The current build has no network code, analytics SDK, advertising SDK, account system, or in-app purchases.

Before adding third-party SDKs:

- Document every transmitted data type.
- Review license and privacy policy.
- Add consent where required.
- Update the in-app privacy page and App Store privacy answers.
- Keep telemetry optional where possible.
- Avoid persistent device fingerprinting.
