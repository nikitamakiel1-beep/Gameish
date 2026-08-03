# EDEN//FALL v0.4.1 quality hardening

The first v0.4 CI pass was technically green. A subsequent behavioral review identified integration details that were not adequately represented by import and unit-style contracts. v0.4.1 corrects those issues without changing the validated v3 base.

## Corrections

- The upcoming chamber modifier is now assigned before room content spawns. Elite Hunt and other modifier-dependent spawning therefore affect the correct chamber.
- Regenerative Hosts now restores every hostile in the chamber rather than only enhanced variants.
- Overclocked chambers accelerate both enemy movement and attack cadence.
- The v0.4 suspend extension and backup are removed when a run ends.
- The inherited v0.3 corner label is replaced by the active v0.4.1 version.
- Controller rumble supplements mobile haptics when a gamepad is connected.
- Colorblind mode adds letter-coded status indicators instead of relying only on color.
- A rolling frame-rate monitor is available inside the safe-area diagnostic overlay.
- Low-health state gains a restrained border pulse that respects the existing HUD layout.

## Runtime structure

`main.tscn` loads `edenfall_v4_quality.gd`, which is a narrow quality layer over `edenfall_v4.gd`. v0.4 remains the systems implementation and v0.3 remains the directional regression base. The layers are intentionally explicit:

1. `edenfall_v3.gd` — validated directional game and UI baseline.
2. `edenfall_v4.gd` — director, weapons, modifiers, elites, status, mastery and save extension.
3. `edenfall_v4_quality.gd` — behavioral integration corrections and device-feedback hardening.

The quality layer contains no content catalog and does not duplicate the core runtime.

## Validation

`tests/v4_quality_audit.gd` verifies that the quality runtime loads, preserves directional behavior, exposes the expanded settings contract, reaches the quality readiness threshold and is connected to the main scene.
