# EDEN//FALL v0.4 systems expansion

## Design objective

v0.4 converts the validated v0.3 vertical slice into a deeper, more replayable systems build without discarding the known-good directional runtime. The main scene uses a single v0.4 extension layer over v0.3 and delegates deterministic run logic to `scripts/v4/run_director.gd`.

## Run modes

- **Standard excursion:** normal progression and adaptive threat.
- **Daily protocol:** deterministic date-derived seed, elevated threat and comparable scoring.
- **Training simulation:** reduced threat for onboarding, control practice and accessibility testing.

## Encounter director

The run director calculates threat and encounter budgets from biome, room depth, cleared-room count, floor and run mode. Every combat chamber can receive a deterministic modifier:

- Stable Chamber
- Overclocked
- Blackout
- Corrosive Grid
- Regenerative Hosts
- Watcher Cross-Fire
- Fragile Protocol
- Elite Hunt

Modifiers carry explicit reward multipliers. Floors also contain a Genome Trial and an Eden Sanctuary where topology allows them.

## Lineage weapon identities

| Lineage | Weapon | Combat identity |
|---|---|---|
| Adam | Genesis Rifle | Stable guided rifle |
| Abel | Shepherd Beam | Fast precision, mark and chain |
| Cain | Mark Cannon | Heavy explosive burn projectile |
| Seth | Continuation Lance | Piercing, bouncing defensive lance |
| Naamah | Spore Repeater | Three-projectile slowing infection spread |

Weapon identity is separate from relic progression. Existing relics continue modifying damage, fire delay, projectile velocity, pierce, multishot, luck, shields and ability power.

## Elite enemies

Standard enemies can be promoted to enhanced variants. Affixes alter health, movement and damage, then add a readable combat rule:

- Swift
- Armored
- Volatile
- Vampiric
- Corrosive
- Shielded

Elite enemies have distinct rings, labels, shield indicators and increased scoring. Volatile enemies explode on death. Corrosive enemies emit radial fire. Vampiric enemies regenerate near the player.

## Status system

Player weapons can apply:

- Burn: periodic damage.
- Marked: increased subsequent damage.
- Spore: movement reduction.
- Stagger: short, strong movement interruption.

Status state is stored on each enemy and rendered above the target.

## Run expression and progression

- Kill combo with timed decay.
- Combo damage scaling.
- Score based on target health, elite/boss status, combo and chamber modifier.
- Mastery gained during each run.
- Persistent highest combo, daily best, elite kills and total score.
- Mastery ranks from Dormant through Transcendent.

## Interface improvements

The v0.4 overlay adds:

- Two-column title navigation.
- Standard, daily and training mode messaging.
- Threat and chamber-modifier panel.
- Combo meter.
- Active weapon panel.
- Score and mastery display.
- Elite affix and status indicators.
- Expanded archive statistics.
- Run telemetry on pause and end screens.
- Additional accessibility toggles for colorblind palette, simplified effects, tutorial prompts and adaptive threat.

## Reliability

v0.4 retains the v0.3 suspended-run format for compatibility and writes a second v0.4 extension payload. v0.4 profile and suspend files use temporary-file replacement and retain a `.bak` copy for recovery after interrupted writes.

## Validation contract

`tests/v4_audit.gd` verifies:

- deterministic daily seeds;
- monotonic threat and encounter scaling;
- five distinct lineage weapons;
- modifier, elite and mastery catalogs;
- inherited eight-direction animation and combat contracts;
- title, accessibility and main-scene integration;
- presence of the validated v3 directional asset manifest.

The v0.4 CI gate runs import/parse, v3 regression audit, v4 behavioral audit and main-scene boot, then scans all logs for parser and runtime failure markers.
