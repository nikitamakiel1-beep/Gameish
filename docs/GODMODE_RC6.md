# EDEN//FALL v0.6.1 RC6 — Godmode Systems Record

## Status

RC6 is a feature-branch release candidate. It is not qualified until the exact branch head is parsed, imported, audited, booted and played under Godot 4.7.1.

The active scene contract is:

`main.tscn` → `edenfall_v6_godmode_verified_runtime.gd`

The verified runtime extends the existing production stack rather than replacing the established semantic atlas, lore, input, save, audio and platform systems.

## Design benchmark policy

Soul Knight, Enter the Gungeon, The Binding of Isaac and Horizon Zero Dawn are interaction, readability and atmosphere benchmarks only. EDEN//FALL does not copy their characters, item names, room layouts, art assets or proprietary visual designs.

The benchmark translation is:

- immediate twin-stick readability and compact pickup feedback;
- committed dodging, explicit projectile telegraphs and authored combat chambers;
- relic-driven build transformation, strong silhouettes and repeatable randomized runs;
- nature reclaiming ancient engineered ruins with environmental storytelling.

EDEN//FALL remains an industrial-biblical biotechnology setting centered on Adam, Abel, Cain, Seth, Naamah, preadamite cultures, Watcher/Fallen machinery, Nephilim biology and the Serpent Interface.

## Runtime stack

1. `edenfall_v6_visual_rebuild.gd` — atlas-driven presentation and responsive HUD.
2. `edenfall_v6_product_runtime.gd` — encounter spacing and explicit attack wind-ups.
3. `edenfall_v6_release_candidate.gd` — compact/wide layout stabilization.
4. `edenfall_v6_world_runtime.gd` — deterministic biome cover and projectile/actor collision.
5. `edenfall_v6_navigation_runtime.gd` — swept actor collision and cover steering.
6. `edenfall_v6_content_runtime.gd` — Archive, shop and deliberate lineage deployment.
7. `edenfall_v6_polish_runtime.gd` — guardian Archive strip and restored-shop reconciliation.
8. `edenfall_v6_godmode_runtime.gd` — deep combat, special rooms, factions, synergies, boss state machines and RC6 suspend extension.
9. `edenfall_v6_godmode_stable_runtime.gd` — restore guard, mandatory decision rooms and RNG seed/state isolation.
10. `edenfall_v6_godmode_complete_runtime.gd` — Archive pool progression, faction ambushes, guardian arena consequences and mobile accessibility completion.
11. `edenfall_v6_godmode_release_runtime.gd` — deterministic spawn isolation and final Serpent ending choice.
12. `edenfall_v6_godmode_verified_runtime.gd` — deterministic floor topology and stale-ending protection.

## Determinism model

Godot 4.7.1 exposes both `RandomNumberGenerator.seed` and `RandomNumberGenerator.state`. RC6 follows the engine guidance that externally sourced seeds should be hash-mixed and that saved generator state should only be restored from a previously captured state.

Three independent deterministic layers are used:

- floor graph seed: `run_seed + biome_index + floor_number`;
- room subsystem seed: run seed + room coordinate + biome/depth + subsystem salt;
- global combat RNG: preserved across floor and room generation and saved for suspension.

This separation prevents generation order from silently changing the floor graph or encounter identity.

## Weapon semantics restored over cover collision

The RC5 world collision loop had replaced the inherited projectile update path. RC6 restores the previously implemented weapon metadata while retaining cover collision:

- homing;
- pierce;
- bounce;
- explosion;
- chain;
- burn;
- marked;
- spore;
- stagger;
- critical projectiles;
- lineage-specific projectile identities.

The five starting weapons also evolve during a run without becoming interchangeable.

## Relic build transformations

RC6 interprets the existing sixty relics through effect tags. Eight initial synergy contracts are implemented:

- Refracted Choir — damage + multishot;
- Marrow Bore — pierce + damage-speed;
- Halo Capacitor — shield + fire-rate;
- Mycelial Armor — lifesteal + max-health;
- Shepherd Oracle — critical + luck;
- Phase Drive — speed + dash;
- Spore Circuit — spore + ability;
- Watcher Liturgy — boss-damage + shot-speed.

These transformations modify projectile or defensive behavior instead of only increasing numbers.

## Archive progression

Persistent progression broadens possibility space instead of directly increasing base damage or health.

Relic tier access is expanded by a combination of:

- mastery;
- recovered lineage memories;
- defeated guardians.

Tier I remains available from the start. Later tiers expand the random pool as the Archive develops.

## Special rooms

RC6 implements the design-bible room types as deterministic run structures:

- preadamite settlement;
- sacrifice bioreactor;
- lineage memory;
- secret maintenance/cache room;
- enhanced-host contract;
- Serpent terminal.

Noncombat decision rooms lock exits until the focal interaction is resolved. Decisions affect scrap, health, relic access, mastery, Archive records, mutations or faction reputation.

## Factions

Persistent reputation is tracked for:

- Salt Caravans;
- Ash Covenant;
- Tubal Foundries;
- Enoch Outlaws;
- Lamech Houses;
- The Unnamed.

Reputation changes caravan pricing and can create retaliation ambushes at sufficiently negative values. It is intentionally not a good/evil meter.

## Enemy specials

Selected enemy identities now have explicit timed special attacks in addition to the inherited movement/style behaviors:

- Cherub Drone — aimed burst;
- Fallen Angel — broad fan;
- Halo Sentinel — allied shield pulse;
- Ophanim Scout — radial discharge;
- Bone Shepherd — Nephilim husk summons;
- Grafted Colossus — heavy radial burst;
- Serpent Spawn — rotating burst.

Each special receives its own wind-up state and RC6 telegraph overlay.

## Guardians

The five guardian IDs have three explicit pattern families each, for fifteen pattern contracts total.

- Watcher Engine — radial surveillance rings, aimed fans and rotating spokes.
- First Nephilim — committed charges, shock-like rings and heavy aimed fans; phases destroy structural cover.
- Gate Cherub — wing fans, cross patterns and shield cycles; phases deploy auxiliary cherub bodies.
- Tower of Enoch — axial machine fire, rotating patterns and summoned security; phases reconfigure crossfire.
- Serpent Interface — spirals, mirrored attacks and forked host summons.

The Serpent Interface does not immediately end the run when defeated. Victory is withheld until the player rejects or accepts the final adaptation request.

## Serpent ending persistence

The unresolved final ending choice is stored in a separate atomic marker keyed to the run seed. Suspend/resume reopens the resolution if necessary. Starting a genuinely new run removes a stale ending marker. Resolving the choice records the ending in persistent profile data and only then finalizes victory.

## Mobile and accessibility

RC6 retains existing safe-area, left-handed, haptic, aim-assist, reduced-motion and simplified-FX support and adds:

- adjustable touch-control opacity;
- reduced-flash attenuation and shortened high-energy effects;
- explicit strong-telegraph toggle;
- explicit projectile-outline toggle.

## Persistence

The inherited v3/v4 suspension system remains for compatibility. RC6 adds room-state persistence containing:

- current room coordinate;
- visited/spawned/cleared state;
- special-room use state;
- shop inventory and pricing state;
- room modifiers/reward flags;
- RC6 player armor/orbital/lifesteal/spore/mutation state;
- RNG state.

Uncleared combat encounters restart on restoration. Cleared rooms remain cleared. Deterministic floor topology ensures saved coordinates refer to the same generated graph.

## Verification gate

`tests/v6_product_rebuild_audit.gd` requires:

- exact Godot 4.7.1;
- inherited semantic atlas contract and unique atlas hashes;
- all runtime layers and source symbols;
- six factions and at least eight synergies;
- five guardians and exactly fifteen guardian pattern families;
- collision and swept navigation;
- Archive/shop content systems;
- deterministic special rooms and floor graph;
- room-state suspension;
- Archive pool progression;
- faction ambushes;
- guardian arena phase behavior;
- touch opacity and reduced flash;
- final Serpent resolution and suspend-safe ending marker;
- `main.tscn` routed to `edenfall_v6_godmode_verified_runtime.gd`.

The current environment cannot perform a local repository checkout because outbound DNS/network access is unavailable. Therefore these source contracts are not a substitute for the pending exact-engine runtime qualification.
