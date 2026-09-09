# EDEN//FALL — V8 Art4 graphical direction

Art4 is the production implementation of the approved EDEN//FALL visual reference boards created during development. The boards are targets for silhouette, animation energy, room richness, biome identity, hierarchy and combat readability. They are not source sprite atlases and they are not copied from commercial games.

## Non-negotiable visual target

EDEN//FALL must read as an authored top-down pixel action roguelike whose procedural systems operate inside a strong visual grammar. The game must not look like a procedural sprite generator, a debug visualization, a stock tile map, or a collection of unrelated generated shapes.

Reference qualities:

- chunky, readable actor proportions;
- stable canonical protagonists;
- oversized weapons and class props;
- expressive idle / locomotion / attack / recoil / dash body language;
- strong dark outlines and restrained palette ramps;
- distinct enemy families instead of a common mannequin;
- biome rooms built around recognizable landmarks and story beats;
- quiet floor texture supporting richer macro architecture;
- compact UI secondary to combat;
- projectiles, telegraphs, hit flashes and muzzle effects visible at a glance.

Enter the Gungeon, Soul Knight and related action roguelikes are research references for readability, animation energy and procedural/hand-authored balance only. No copyrighted character, enemy, room, sprite, UI or official art is imported.

## 1. Canonical heroes

Adam, Abel, Cain, Seth and Naamah are identity-locked. RNG may not replace their base silhouette, palette family, body proportions or weapon class.

### Adam — Edenic Survivor

- dark hair / grounded human read;
- green-olive Eden salvage with warm gold highlights;
- Genesis Rifle / long-rifle silhouette;
- agile rifle stance rather than generic upright mannequin;
- botanical relic/growth accents remain secondary.

### Abel — Shepherd of Light

- ivory / cream / gold hierarchy;
- halo remains a primary read;
- light-focus/staff weapon language;
- floating/casting motion profile;
- attack frames emphasize glowing focus and spell release.

### Cain — Marked Warrior

- black / charcoal / blood-red hierarchy;
- widest/heaviest protagonist silhouette;
- Mark Cannon is permanent;
- backpack/core and red trailing cloth reinforce mass and motion;
- attack frame must visibly brace/recoil around the cannon.

### Seth — Guardian Engineer

- blue-steel palette;
- visor and engineer nodes are persistent identity marks;
- Watcher Carbine / guardian-tech weapon language;
- equipment reads as deployable technology, not random armor.

### Naamah — Voice of Mycelia

- violet / fungal pink / dark plum hierarchy;
- fungal cap, buds and tendril language;
- Spore Repeater / caster focus;
- idle and special frames use organic sway rather than mechanical stepping.

Hero runtime variation may affect dirt, damage, relic FX, biome wear or future approved costume overlays only when the canonical identity remains obvious.

## 2. Four-frame action grammar

The existing 48x48 actor ABI remains for Web/mobile memory safety, but frames are state-addressed rather than indiscriminately cycled:

1. idle / breathing pose;
2. locomotion / stride;
3. attack / cast / recoil;
4. dash / hurt / special movement.

Runtime presentation adds controlled bob, contact shadow, recoil, muzzle flash, hit flash and dash echoes. Motion must communicate state before decorative particles are considered.

## 3. Curated procedural enemies

Enemy generation remains stochastic, but each enemy belongs to a visual family with fixed semantic fields:

- `silhouette_anchor`;
- `motion_profile`;
- `material_family`;
- `fx_profile`;
- `weapon_read`.

Examples:

- Outlaw Gunner: braced stride / scrap leather / amber muzzle / long rifle.
- Raider Brute: heavy lurch / scrap plate / impact dust / cleaver mass.
- Scrap Cultist: ritual float / ritual cloth / red ritual FX / focus staff.
- Cherub Drone: wing hover / ivory machine / halo gold / orb shot.
- Biomech Pilgrim: servo stride / ivory biomech / servo gold / pilgrim rifle.
- Nephilim Husk: broken charge / bone-flesh / void violet / mauling limbs.

RNG may select legal modules, bounded proportions, approved palettes, legal equipment variants and combat traits. It may not change the family into a visually unrelated actor.

## 4. Biome target grammar

Every room uses a three-level hierarchy:

1. restrained base surface;
2. large structural landmark / traversal read;
3. localized props, damage, growth, hazard and animated environmental pockets.

Uniform wallpaper tiling and room-sized repeated rectangles are forbidden.

### Industrial Eden

Target: overgrown containment laboratory.

- service plates and inset hatches;
- coolant/service channels;
- pipes, tanks, broken containment equipment;
- failed greenhouses and creeping vegetation;
- sealed gene vault / containment breach story beats;
- subtle bubbles, lamps and plant motion.

### Ash Wastes

Target: destroyed urban/industrial exterior.

- cracked/burned road language;
- convoy wreckage and collapsed checkpoints;
- exposed foundations/rebar;
- embers, dust and reactor scars;
- long sightlines interrupted by meaningful wreck cover.

### Temple-Lab

Target: sacred biotechnology / archive machinery.

- ritual circuitry and geometric floor anchors;
- process machines / archive columns;
- sealed sanctum and choir-machine story beats;
- controlled cyan/gold energy nodes.

### Fungal Garden

Target: mycelial takeover.

- branching fungal veins;
- spore basins and fruiting clusters;
- root-cathedral / nursery landmarks;
- drifting spores and localized organic motion;
- purple-green biology without flooding the entire floor with noise.

### Nephilim Ruins

Target: colossal post-human relic landscape.

- monoliths / buried gates;
- rib causeways and bone structures;
- broken colossal remains;
- giant scale implied through repeated architectural proportions;
- cold relic accents and deep shadow.

## 5. Combat hierarchy

At gameplay scale the visual order must be:

1. player and enemy silhouettes;
2. hostile/friendly projectile trajectories;
3. attack telegraphs and hazards;
4. cover/obstacle collision reads;
5. biome detail;
6. UI.

Environment richness may never hide projectiles or actor silhouettes.

## 6. UI hierarchy

- compact identity block rather than full-screen dashboard chrome;
- objective remains top-center but visually quiet;
- scrap/genome remain top-right;
- weapon identity remains bottom-center;
- lineage selection prioritizes a large canonical hero preview and a compact roster;
- empty framed regions and debug-looking concentric ornaments are not acceptable production composition.

## 7. Procedural boundaries

### Fixed

- five hero identities;
- boss core identity;
- major biome vocabulary;
- UI grammar;
- lineage palette/weapon anchors;
- major lore symbols.

### Curated procedural

- enemy legal modules;
- enemy material/FX variants;
- cover combinations;
- biome story-beat selection;
- environmental dressing;
- boss phase attachments;
- damage/wear overlays.

### Highly procedural

- room topology;
- encounter composition;
- enemy instance combat traits;
- loot/relic order;
- room dressing placement;
- guardian pattern order;
- run adaptations.

## 8. Implementation files

Art4 production stack:

- `scripts/v8/hero_identity_director.gd`
- `scripts/v8/enemy_genome_director_art4.gd`
- `scripts/v8/procedural_sprite_forge_art4.gd`
- `scripts/v8/procedural_world_director_art4.gd`
- `scripts/edenfall_v8_animation_runtime.gd`
- `tests/v8_art4_reference_audit.gd`

The final scene remains routed through `scripts/edenfall_v8_release_runtime.gd`; the animation-runtime ready boundary installs the Art4 genome, world and sprite systems before inherited run initialization.

## 9. Qualification

A Web artifact is not an Art4 candidate unless exact Godot 4.7.1 passes:

- bottom-up `Script.can_instantiate()` probe including Art4 files;
- Art4 reference audit;
- legacy Art3 quality compatibility audit;
- presentation audit;
- RC6/RC7 compatibility and runtime quality audits;
- V8 entropy and sprite-streaming gates;
- bounded real game boot;
- non-threaded, non-PWA Web export verification.

The expected build identity is `0.6.4-authored-art4`.

Fresh browser screenshots remain a mandatory visual acceptance step. Automated metrics can reject obvious regressions; they cannot certify that a sprite or biome actually looks good.
