# Gameish: EDEN//FALL

A mobile-first, room-based action roguelike set in an industrial, post-apocalyptic Garden of Eden.

The player selects one of five engineered human lineages housed inside the Eden Biolaboratory, then enters a procedurally reconfigured exterior occupied by pre-Adamite traders and outlaws, altered human factions, Nephilim husks, fallen bio-machines, and the Watcher Engine.

This repository currently contains an original **Godot 4.6 vertical slice**. It is intentionally closer in structure to room-based twin-stick roguelikes than to an open-world action RPG: sealed combat chambers, randomized routes, run-only items, shops, a boss, permadeath, and limited persistent unlocks.

## Current status

Implemented:

- Five playable lineages: Adam, Abel, Cain, Seth, and Naamah.
- Seeded procedural room graphs with combat, treasure, trader, start, and boss rooms.
- Room locking and traversal after combat clearance.
- Keyboard/mouse and dual-touch twin-stick controls.
- Dash movement with invulnerability.
- Four escalating enemy archetypes plus the Watcher Engine boss.
- Preadamic trader inventory and scrap economy.
- Ten run items with stat changes and simple synergies.
- Permadeath and local Genome Archive progression.
- Persistent local save in `user://edenfall_save.json`.
- Original procedural vector visuals with no external art dependency.
- Headless parse/boot workflow for GitHub Actions.

Not yet production-complete:

- The first CI validation result is still pending.
- Production sprites, animation, sound, music, haptics, accessibility, balancing, localization, analytics, crash reporting, and final App Store assets are not included yet.
- Nakama cloud saves and leaderboards are designed as an optional later layer and are not a runtime dependency.

## Run the project

1. Install Godot 4.6.3 Standard.
2. Clone or download this repository.
3. Open `project.godot` in Godot.
4. Run the project with F6/F5.

No external packages or imported assets are required for the current vertical slice.

## Controls

Desktop:

- Move: `WASD` or arrow keys.
- Aim/fire: mouse or `IJKL`.
- Dash: `Space` or right mouse button.
- Buy nearby trader item: `E`, or click its card.
- Pause: `Esc` or `P`.

Mobile:

- Left thumb: movement stick.
- Right thumb: aim and continuous fire.
- Bottom-right button: dash.
- Tap trader cards to purchase.

The game is landscape-first and uses a 1280×720 logical viewport that expands to the available aspect ratio.

## Roguelike structure

A run begins in the Eden Biolaboratory. The generated room graph contains a guaranteed trader, a guaranteed reliquary, multiple combat chambers, and a distant boss room. Death erases the current inventory, scrap, route, and combat progress. Only Genome Archive currency and item-pool unlock thresholds persist.

Genome thresholds expand the possible item pool at 5, 8, 12, 18, and 25 recovered Genome.

## Repository layout

```text
.
├── .github/workflows/validate.yml
├── docs/
├── scripts/
│   ├── game_data.gd       # Lineages, enemies, items
│   ├── game_core.gd       # Run generation, combat, economy, persistence
│   ├── game.gd            # Procedural rendering and UI
│   └── game_runtime.gd    # Compatibility/runtime corrections
├── icon.svg
├── main.tscn
└── project.godot
```

## iOS and App Store direction

The code uses GDScript rather than C# and the Compatibility renderer to reduce mobile export risk. A signed App Store build still requires a Mac, Xcode, Godot iOS export templates, an Apple Developer Program account, a unique bundle identifier, signing credentials, App Store Connect metadata, screenshots, privacy disclosures, and review.

See [`docs/IOS_APP_STORE.md`](docs/IOS_APP_STORE.md) for the current release checklist.

## Backend direction

The launch build should remain offline-first. Nakama can later provide:

- Device/account authentication.
- Cloud Genome Archive and settings backup.
- Daily or weekly seeded-run leaderboards.
- Cross-device profile restoration.
- Server-validated purchases if monetization is added.

Do not block single-player startup or local saves on backend availability.

## Originality and reference use

The project takes high-level genre inspiration from room-based action roguelikes. It does not contain copied code, characters, names, art, maps, audio, or item designs from commercial reference games. Public mobile-game repositories are used only as architectural research references; their licenses must be reviewed before any code or asset is imported.

## Design documents

- [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md)
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/IOS_APP_STORE.md`](docs/IOS_APP_STORE.md)
