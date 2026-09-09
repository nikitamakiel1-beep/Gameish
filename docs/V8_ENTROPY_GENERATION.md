# EDEN//FALL v0.6.2 — Entropy Generation Architecture

## Product rule

V8 removes fixed-seed content replay from the production generation path.

A newly started run receives fresh process/time/OS entropy. The same visible run seed or the same player actions must not reconstruct the same floor topology, special-room assignment, encounter recipe, enemy morphology, relic sequence, lineage-adaptation offer or guardian pattern order on a later run.

This does **not** mean that objects mutate randomly every frame. Generation is stochastic at creation boundaries, then the generated recipe is frozen for the lifetime of that actor/room. Suspension stores those recipes so resuming an active run restores the world the player already saw.

This distinction is mandatory:

- stochastic creation;
- coherent entity lifetime;
- active-run recipe persistence;
- no fixed-seed replay contract.

## Research-derived design rules

### Constrained procedural assembly

High-quality room roguelikes do not achieve readability by scattering arbitrary content. Their useful design principle is procedural assembly inside authored constraints: combat-role budgets, safe spawn distances, room geometry constraints, telegraph rules, reward contexts and biome grammar.

V8 therefore keeps the RC7 encounter composer and fairness director as constraints, but feeds them fresh entropy rather than a replay seed.

### Godot 4.7 generation primitives

The implementation uses Godot-native runtime generation primitives:

- `RandomNumberGenerator.randomize()` for a time-randomized PCG stream;
- `Crypto.generate_random_bytes()` once at reseed to mix OS cryptographic entropy into the session seed;
- fresh context tokens and child RNGs for generation boundaries;
- `FastNoiseLite` for spatially coherent floor contamination/wear fields;
- `Image` for direct procedural pixel construction;
- `ImageTexture.create_from_image()` for runtime rendering of generated sheets and floor skins.

Cryptographic random generation is deliberately **not** called for every reward/enemy roll. It is mixed into the RNG at reseed, then the faster PCG stream plus ticks/counters supplies gameplay generation tokens.

## Procedural actor pipeline

### 1. Gameplay identity remains authored

Enemy IDs still define lore and baseline combat role. For example, an outlaw gunner remains a preadamite ranged host and a Nephilim giant remains a Nephilim charger.

### 2. Per-instance genome

Each spawned actor receives a fresh visual/combat genome constrained by:

- category: preadamite, Fallen, Nephilim or guardian;
- combat role: melee, ranged, charger, caster, skirmisher, orbiter or radial;
- biome depth/threat;
- elite/guardian state;
- lineage for playable characters.

The genome varies body width/height, head construction, shoulder construction, weapon construction, backpack, horns, eye count, asymmetry, wear/scar pattern, emissive strength, palette, visual scale and bounded combat multipliers.

### 3. Premium pixel forge

`scripts/v8/procedural_sprite_forge_premium.gd` generates actual sprite pixels. It does not tint or recolor the old base sprite.

Generated standard actor sheets use:

- 48 × 48 frames;
- 8 directional rows;
- 4 generated motion frames per direction;
- 192 × 384 sheet dimensions.

Generated guardian sheets use:

- 96 × 96 frames;
- 8 directional rows;
- 4 generated motion frames per direction;
- 384 × 768 sheet dimensions.

The forge uses:

- hard dark silhouette outlines;
- top-facing highlights and lower material shadow;
- category palette families;
- randomized but bounded armor proportions;
- role-specific silhouettes;
- category-specific ornaments;
- lineage-specific silhouettes.

#### Role grammar

- melee: forward fists/claws and aggressive close-range mass;
- ranged: ammo drum, sight/antenna and long firearm read;
- charger: expanded shoulder armor and ram silhouette;
- caster: robe flare and ritual crown;
- skirmisher: lean asymmetric fins/scarf and paired weapon read;
- orbiter: mechanical radial body with rotating arms;
- radial: heavy circular emitter with multiple spokes.

#### Category grammar

- preadamite: salvage plating, asymmetric scrap construction;
- Fallen: mechanical halo and wing/feather struts;
- Nephilim: horns, grafts and bone-like protrusions;
- guardian: luminous control nodes and higher-scale structure.

#### Lineage grammar

- Adam: Edenic plant/tissue growth accents;
- Abel: luminous halo/shepherd geometry;
- Cain: red-black power pack and deliberately oversized cannon rails;
- Seth: blue engineering modules;
- Naamah: fungal/mycelial buds.

The reference target is commercial top-down pixel readability and silhouette quality, not reproduction of any external game's sprites.

## Sprite streaming and memory

Generating a unique sheet for every enemy synchronously would create room-entry hitches on Web/mobile. V8 therefore streams procedural sprites:

- one forge job per process tick at most;
- guardians receive queue priority;
- enemies remain in their visible materialization/activation state while their sheet is pending;
- AI and attacks are blocked while `visual_pending` is true;
- old-room enemy sheets are removed at room transition;
- the player sheet is retained;
- live-room actor texture budget is capped at 12 hostile/guardian sheets plus player.

The visual generator is therefore allowed to be richer without turning chamber entry into a synchronous texture-generation burst.

## Procedural biome pipeline

Each room receives a stochastic biome recipe constrained by its biome and room kind.

The recipe controls:

- vegetation density;
- ruin density;
- surviving technology density;
- wetness/contamination;
- light-temperature offset;
- contrast;
- FastNoiseLite seed/frequency;
- cover count and cover families;
- hazard identity;
- normalized decor points;
- normalized obstacle geometry.

The five biome rules remain lore-specific:

1. Industrial Eden — sealed overgrown laboratory, tanks, servers, planters, roots, bio-vats.
2. Ash Wastes — destroyed roads, wrecks, barricades, concrete and fuel/scrap structures.
3. Temple-Lab — ritual technology, glass vats, archive cores, columns and circuitry.
4. Fungal Garden — mycelial towers, spore beds, root masses and fruiting structures.
5. Nephilim Ruins — monumental ruin slabs, bone/rib structures, grafted technology and monoliths.

### Procedural floor skin

Every generated room receives its own 256 × 144 pixel floor image derived from FastNoiseLite plus biome parameters. The runtime scales that image to the arena before cover is drawn.

This changes the dominant floor surface itself rather than placing a few random decals over the old repeating pattern.

### Procedural cover finish

Collision geometry and visual identity use the same generated recipe. Cover families have distinct finishing grammar:

- vats/tanks: glass, liquid and bubbles;
- roots/fungal growth: stems/caps/growth masses;
- consoles/servers/archive circuitry: panels, signal lines and LEDs;
- wrecks/scrap/fuel: rust plates and fuel markings;
- Nephilim structures: rib arcs, bone/monolith motifs and emissive cores.

## Stochastic combat behavior

Visual genomes also carry bounded combat traits. These traits have explicit telegraphs and do not bypass the fairness director.

Examples include:

- burst/marksman/suppression/scatter fire;
- ritual/nova/ring emissions;
- seeker and zone patterns;
- flank/feint/blink/dash-shot movement;
- ram/juggernaut/shockwave/breach pressure;
- orbit/satellite/spiral/harrier emissions;
- ripper/stalker/leaper/bloodrush bursts;
- bounded summoning where encounter population permits.

Guardians no longer iterate their three pattern families in a fixed order. Every attack window chooses a fresh valid pattern through the entropy director while retaining authored phase-specific pattern definitions and wind-ups.

## Rewards and progression

V8 sends fresh entropy tokens into:

- RC7 contextual relic selection;
- encounter-composition selection;
- encounter formation positions;
- faction retaliation rolls;
- special-room assignments;
- contract modifiers;
- lineage-adaptation offers;
- guardian pattern ordering.

The authored constraints remain; the replay seed does not.

## Suspend/resume

Suspension stores generated recipes, not a promise that a public seed can regenerate them later.

The V8 extension stores:

- hidden floor entropy used for the current floor graph;
- player visual genome;
- room kind/modifier/faction/memory state;
- procedural world recipe;
- normalized obstacle recipe;
- encounter recipe;
- per-enemy genomes embedded in that encounter recipe.

On resume, those stored recipes are reapplied before the active room is reconstructed.

## Audit suite

V8 adds two release gates:

### `tests/v8_entropy_audit.gd`

Checks:

- exact Godot 4.7.1;
- no fixed-seed replay flag;
- entropy-token uniqueness;
- repeated same-condition genome diversity;
- body/head/weapon morphology diversity;
- seven role-specific generated sheets;
- five generated lineage sheets;
- guardian generated-sheet dimensions/readability;
- repeated room-recipe diversity;
- repeated procedural-floor diversity;
- final V8 release route;
- recipe-persistence contract.

### `tests/v8_sprite_streaming_audit.gd`

Checks:

- premium role/category/lineage morphology;
- Cain cannon signature contract;
- role/category/lineage sheet uniqueness;
- queued forge implementation;
- one-job-per-tick rule;
- AI blocking while visual generation is pending;
- room-scoped actor texture cache;
- maximum live-room actor texture budget;
- stochastic guardian ordering;
- generated-trait combat actions and telegraphs.

The historical RC6 and RC7 audits now act as compatibility gates through the V8 release root. They verify that V8 did not remove the mature collision, persistence, factions, synergies, guardian logic, audio/fairness, accessibility and final Serpent systems while deliberately superseding deterministic content generation.

## Provenance firewall

External games and public sprite generators are reference/research material only.

No sprite pixels, enemy designs, room layouts or audio samples from Soul Knight, Enter the Gungeon, The Binding of Isaac, Horizon, LPC, Kenney, or public procedural-sprite repositories are imported into V8.

V8 ships first-party procedural geometry, pixel construction and synthesized audio code.