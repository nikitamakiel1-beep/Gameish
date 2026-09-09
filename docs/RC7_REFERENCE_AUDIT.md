# EDEN//FALL v0.6.1 RC7 — reference and product audit

## Purpose

RC7 converts external research into explicit EDEN//FALL production rules. The objective is not to imitate another game. It is to identify why strong action roguelikes remain readable, replayable and expressive under pressure, then implement those principles using EDEN//FALL's own lore, semantic atlases, enemies, weapons, factions, rooms and procedural generation.

No commercial sprite, room, projectile, UI element, sound, dialogue, map or proprietary design has been imported.

## Commercial-game benchmark findings

### Soul Knight

Useful production principles:

- immediate movement/aim comprehension;
- strongly differentiated playable characters;
- weapons that communicate function at combat speed;
- compact procedural combat spaces;
- mobile controls that preserve the battlefield;
- fast restart/re-entry into play.

RC7 implementation:

- five lineage-specific weapon identities remain authoritative;
- cover-aware aim assistance does not select targets through structural cover;
- encounter signatures create intentional room pressure rather than random enemy soup;
- room-entry materialization protects mobile players from unfair first-frame damage;
- controls remain landscape-first, twin-stick compatible and left-hand configurable.

### Enter the Gungeon

Useful production principles:

- bullets must be easier to parse than scenery;
- dodge timing is a deliberate defensive commitment;
- room composition matters as much as enemy stats;
- cover and obstruction change lines of attack;
- attacks need learnable wind-ups and recognizable pattern families.

RC7 implementation:

- structural cover blocks actors and projectiles;
- player wall sliding and enemy cover steering remain inherited from RC6;
- authored encounter signatures include pincer, crossfire, anchor, orbit, diamond and ring formations;
- cover-aware aim assistance prevents impossible target suggestions;
- hostile materialization and explicit wind-up arcs/lanes improve hit attribution;
- melee/charge, aimed, radial and guardian-phase attacks have different warning-audio families.

### The Binding of Isaac

Useful production principles:

- build identity should become visible through mechanical changes, not only stat growth;
- reward pools should reflect context;
- room cadence creates anticipation between combat, reward and decision spaces;
- silhouettes and grotesque symbolic identity matter at small scale.

RC7 implementation:

- relic selection now has deterministic context-sensitive pools for shop, treasure, trial, contract, sanctuary and special rooms;
- duplicate/owned relic exclusion is preserved;
- Archive progression broadens possibilities instead of adding permanent raw-stat inflation;
- guardian victories now offer deterministic run-only Genome Adaptations;
- five lineages have five original adaptation definitions each, creating 25 lineage-specific choices;
- sprite quality is gated by occupancy, silhouette bounding box and directional variation rather than only file hashes.

### Nuclear Throne

Useful production principles:

- short, high-pressure rooms benefit from immediately legible character/build mutations;
- mutation choices are effective because they create discrete run identity;
- weapon and movement rhythm should remain aggressive without becoming visually incoherent.

RC7 implementation:

- every nonfinal guardian pauses descent for a two-choice Genome Adaptation;
- adaptations alter existing weapon geometry, cadence, projectiles, defensive systems and ecological mechanics;
- choices are run-only and deterministic from lineage, run seed and biome;
- the final Serpent choice remains separate from ordinary run adaptations.

### Hades

Useful production principles:

- persistent narrative can coexist with repeated fast runs when exposition is interruptible and choices are compact;
- build choices are more memorable when connected to character/world identity;
- combat readability and story state should not compete for the center of the screen.

RC7 implementation:

- short settlement/memory/Serpent choices reuse the same compact decision interface;
- faction reputation, Archive memories and endings remain persistent narrative state;
- lineage adaptations use biological/engineering language specific to each engineered descendant;
- long exposition remains outside active combat.

### UNSIGHTED / Death Trash and post-apocalyptic pixel references

Useful production principles:

- ruined environments become more convincing when social survival systems are visible, not merely when the background is damaged;
- human factions should have their own material cultures and consequences;
- vegetation, machinery, contamination and settlement infrastructure can tell history without cutscenes.

RC7 implementation:

- Salt Caravans, Ash Covenant, Tubal Foundries, Enoch Outlaws, Lamech Houses and The Unnamed remain mechanically persistent factions;
- reputation affects trade and retaliation;
- Industrial Eden, Ash Wastes, Temple-Lab, Fungal Garden and Nephilim Ruins preserve distinct ecological/architectural language;
- special rooms convert lore into decisions rather than static text panels.

### Horizon-style reclaimed-world environmental hierarchy

Useful production principle:

Nature reclaiming advanced infrastructure works when the player can still read the original engineered function underneath the vegetation. Vegetation cannot become uniform decorative noise.

RC7 rule:

- each biome retains a structural/material layer, an ecological layer and an emissive/technological layer;
- environmental contrast stays below actor/projectile contrast during combat;
- scenery and gameplay cover remain semantically separate;
- giant biological architecture and machine remains communicate Nephilim-scale history in the final region.

## Public sprite/code repository findings

### Universal LPC / Liberated Pixel Cup

Useful methodology:

- standard frame dimensions and animation ordering make modular content scalable;
- layered sprite generation benefits from metadata and deterministic assembly;
- large modular art sets require performance profiling and cache discipline;
- provenance/credits must travel with individual components when licenses differ.

License observation:

Universal LPC contains assets under multiple licenses, including attribution and share-alike variants. That makes casual sprite copying inappropriate for this project even when an individual component is open.

EDEN//FALL action:

- retain the existing 48×48 humanoid and 96×96 guardian ABI;
- keep deterministic first-party generation;
- use metadata/audits rather than external sprite imports;
- explicitly separate shallow runtime health checks from deep release generation;
- prewarm only during low-pressure game states.

### Kenney top-down / roguelike packs

Useful methodology:

- consistent palette/shape language lets many props read as one product;
- modular small assets work when silhouette and scale rules are strict;
- clear permissive licensing is valuable for prototypes and reference study.

EDEN//FALL action:

Kenney assets are not imported. RC7 instead applies consistent first-party outline, rim-light and sparse material-value finishing over the established EDEN//FALL actor generator.

### Open roguelike implementations

Useful methodology:

- deterministic seeds should control content selection independently from moment-to-moment combat RNG;
- room/encounter generation is easier to test when composition data is separated from runtime movement/fire logic;
- saved runs should persist semantic state, not only player coordinates/stat values.

EDEN//FALL action:

- floor topology, special rooms and encounter signatures are deterministic;
- encounter composition is isolated in `scripts/v7/encounter_composer.gd`;
- RC6 room-state/RNG/ending persistence remains mandatory under RC7;
- RC7 adds suspend-safe pending guardian-adaptation state.

## Sprite-quality findings

The original screenshot failure was not just palette quality. Characters occupied too little visual area, shared too much body geometry and had insufficient separation from patterned floors.

RC7 adds a second-generation finishing factory and a quantitative deep audit.

Each generated actor frame receives:

- a hard dark silhouette outline;
- selective upper/left rim illumination;
- sparse deterministic material-value texture;
- no smoothing or fractional-pixel resampling.

The quality evaluator tests:

- alpha occupancy;
- minimum silhouette width/height;
- directional silhouette diversity.

Whole-sheet hash uniqueness remains a separate inherited requirement. A sheet must therefore be both technically unique and materially readable.

## Encounter-composition findings

Randomly choosing N enemies from a biome pool creates statistically varied but aesthetically repetitive rooms. RC7 instead chooses a deterministic encounter signature and fills required combat roles from the biome pool.

Current signatures:

- Pressure Pack — pincer pressure;
- Crossfire Cell — ranged crossfire;
- Anchor & Escort — central heavy host with support;
- Orbital Hunt — orbit/skirmish pressure;
- Ritual Battery — caster-oriented diamond;
- Mixed Host Cell — general ring composition.

Caster/radial role caps prevent overlapping high-noise emitters. Trial and contract rooms exclude the weakest generic composition. Bullet-storm rooms avoid stacking a crossfire signature on top of the environmental crossfire modifier.

## Fairness findings

A difficult room should kill the player because of a readable decision failure, not because an enemy materialized on top of the post-transition spawn point.

RC7 therefore adds:

- 0.72-second room-entry grace;
- post-transition spawn clearance measured from the actual player position;
- staggered hostile materialization;
- longer guardian materialization;
- room crossfire/corrosive hazard suppression during entry grace;
- materialization progress visuals.

Difficulty scaling is preserved after activation.

## Reward and progression findings

Automatic room-count weapon scaling reduces player agency. RC7 keeps baseline lineage evolution but adds an explicit choice after every nonfinal guardian.

There are five adaptation definitions per lineage and two are offered deterministically after each guardian. Adaptations remain run-only. Their discovery can be recorded persistently in the Archive without turning account age into permanent damage inflation.

The final Serpent Interface remains a separate narrative/build decision and is never replaced by the adaptation system.

## Audio findings

The previous emergency synthesizer was insufficient for production because biome loops had minimal harmonic/environmental identity and SFX were mostly one generic pitch-swept chirp.

RC7 production synthesis uses:

- 22.05 kHz / 16-bit mono;
- eight-second deterministic biome bases;
- distinct roots, fifths and pulse rates;
- ventilation/turbine/environmental layers;
- process-alarm rhythmic elements;
- choir-like synthesis without sampled liturgical audio;
- functional SFX families;
- separate warning sounds for melee/charge, aimed, radial and guardian-phase threats.

The deep runtime-quality audit verifies that five music loops, five ambience loops and four warning families are data-distinct.

## Loading/performance findings

Deep asset validation must not run during ordinary startup. RC7 therefore separates:

- shallow runtime structural validation;
- explicit deep release qualification.

The runtime prewarms one asset at a time only on the title screen, lineage screen or cleared noncombat rooms. It retains the current biome's hostile pool in cache so prewarming is not discarded by normal trimming.

No speculative prewarming runs during active combat.

## Release acceptance

RC7 is not considered qualified merely because the contracts exist in source.

Release qualification still requires on the exact branch head:

1. Godot 4.7.1 project import and full parse.
2. `tests/v6_product_rebuild_audit.gd` as inherited subsystem evidence.
3. `tests/v7_masterpiece_audit.gd` deep art/gameplay/product gate.
4. `tests/v7_runtime_quality_audit.gd` audio/fairness/loading gate.
5. Bounded boot of `main.tscn`.
6. Screenshot review at representative desktop, phone and tablet landscapes.
7. Audio listening review for biome differentiation and warning recognition.
8. Seeded gameplay runs across all five lineages and all five guardians.
9. Suspend/resume tests during combat, guardian adaptation and final Serpent choice.
10. Frame-time/memory profiling on Web and physical mobile hardware.

The RC7 feature branch remains a release candidate until those runtime checks are executed.
