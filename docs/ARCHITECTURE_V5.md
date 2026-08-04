# EDEN//FALL v0.5 architecture

## Objective

v0.5 preserves the validated action-roguelike simulation while moving platform, layout, persistence and packaging concerns behind explicit service boundaries. This avoids another full runtime rewrite during the Godot 4.7.1 migration.

## Runtime layers

1. `edenfall_v3.gd` — validated directional gameplay, rooms, assets, audio, input and lifecycle baseline.
2. `edenfall_v4.gd` — deterministic run director integration, weapons, statuses, elites, progression and telemetry.
3. `edenfall_v4_quality.gd` — behavioral corrections, controller rumble and diagnostics.
4. `edenfall_v5.gd` — Godot 4.7.1 presentation and platform composition root.

The v5 root is the final inheritance boundary. New platform features should be added as composed services under `scripts/v5/`, not as additional runtime inheritance levels.

## v5 services

### Platform profile

`scripts/v5/platform_profile.gd`

- Detects Windows, Linux, macOS, Web, Android and iOS.
- Classifies phone, tablet and desktop layouts.
- Reports orientation, active input family and performance tier.
- Converts OS safe-area coordinates into viewport coordinates.
- Defines minimum touch-target sizing.

### UI system

`scripts/v5/ui_system.gd`

- Centralizes spacing, color and focus tokens.
- Provides compact, medium and wide breakpoints.
- Generates responsive title, lineage and settings grids.
- Supplies HUD regions and device-specific input prompts.

### Persistence repository

`scripts/v5/save_repository.gd`

- Writes through a temporary file.
- Preserves the previous valid file as `.bak`.
- Restores from backup when the primary file is unreadable.
- Applies a schema version to v5 extension data.

### Build matrix

`scripts/v5/build_matrix.gd`

- Is the machine-readable source of truth for seven export presets.
- Separates buildable test artifacts from signed store deliverables.
- Records platform-specific release requirements.

## UI/UX changes

- One- or two-column title navigation depending on available width.
- Two-row phone lineage selection instead of five compressed cards.
- One- or two-column accessibility settings with adaptive row height.
- Large-touch-target option and safe-area-relative touch placement.
- Controller navigation for title, lineage, settings, pause, archive and end screens.
- Contextual prompts that change between touch, controller and keyboard/mouse.
- Explicit platform and engine identity on the title screen.
- Responsive pause and settings panels.
- Persistent compact-HUD, input-hint and performance-mode preferences.

## Validation rule

No v0.5 readiness increase is valid unless Godot 4.7.1 passes:

- Complete import/parse.
- v3 directional regression.
- v4 behavioral regression.
- v4.1 quality regression.
- v5 module, UI and export contract.
- Main-scene boot.
- Export smoke tests for the supported unsigned/test profiles.
- Fatal-log-marker scan.
