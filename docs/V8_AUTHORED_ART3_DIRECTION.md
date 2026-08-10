# EDEN//FALL V8 Art3 — Authored Roguelike Art Direction

Status: production contract for `godmode/production-assets-v6-rebuild`.

This document defines the visual-generation boundary for EDEN//FALL. The target is an original, authored pixel-action roguelike with stochastic content generation. Commercial games and public sprite sheets are reference material for readability, pacing, modularity and composition only; no third-party character pixels, rooms, props, UI, audio or copyrighted designs are imported.

## 1. Core rule

The game must read as **hand-authored pixel art with procedural content**, never as a procedural image generator pretending to be a finished game.

Procedurality is strongest where repetition benefits replayability and weakest where recognition/identity matters.

| System | Fixed / authored | Controlled variation | Highly stochastic |
|---|---|---|---|
| Five protagonists | identity, silhouette, palette family, weapon class, proportions, animation grammar | wear, relic FX, approved costume/attachment layer | never |
| Enemy families | family silhouette, role read, faction palette bounds, hitbox/readability | legal head/armor/weapon/pack modules, damage state, elite accents | encounter instance selection and legal module combination |
| Guardians | core boss identity, directional silhouette, arena ownership | approved phase attachments, damage state, weak-point exposure | pattern order and phase timing within fairness constraints |
| Biomes | palette hierarchy, landmark family, cover vocabulary | surface wear, growth, ruin amount, localized lighting | room recipe, landmark choice, dressing placement, obstacle arrangement |
| UI | hierarchy, iconography, input/readability | contextual text and run data | never |
| Weapons/relics | class/icon grammar and mechanical identity | approved skins/attachments/effects | run acquisition, combinations and reward placement |

## 2. Canonical heroes — never regenerate identity

The five engineered lineages are brand characters, not procedural mobs. `scripts/v8/hero_identity_director.gd` is the canonical source.

### Adam — Edenic Survivor
- stable green/gold survival palette;
- compact survivor silhouette;
- Genesis Rifle family;
- botanical salvage marker;
- no random body/head/weapon class changes.

### Abel — Shepherd of Light
- stable ivory/gold identity;
- compact caster/shepherd silhouette;
- Tithe focus/staff family;
- halo/light motif;
- no random body/head/weapon class changes.

### Cain — Marked Warrior
- stable red/black identity;
- broad aggressive silhouette;
- Mark Cannon is mandatory;
- visible power-pack/cannon mass;
- no alternate weapon class or random palette.

### Seth — Guardian Engineer
- stable blue/steel identity;
- technical rectangular silhouette;
- Watcher Carbine family;
- shoulder/node machinery;
- no random body/head/weapon class changes.

### Naamah — Voice of Mycelia
- stable violet/mycelial identity;
- compact caster silhouette;
- Spore Repeater family;
- fungal buds/spore motif;
- no random body/head/weapon class changes.

### Hero may-vary layer
Allowed only as a secondary overlay after canonical identity is drawn:
- damage/wear;
- biome contamination;
- relic aura;
- small socketed charm/backpack/shoulder attachment;
- approved costume variant preserving silhouette and palette anchors;
- weapon skin within the same weapon class.

The base sprite sheet must remain identical when unrelated RNG state changes. `tests/v8_art_direction_audit.gd` enforces this.

## 3. Sprite language

The active forge is `scripts/v8/procedural_sprite_forge_roguelike.gd`.

### Normal 48×48 actor grammar
- large readable head;
- compact torso;
- short separated legs;
- strong 1–2 px dark outline at source scale;
- weapon/role prop deliberately oversized;
- no random one-pixel texture noise;
- approximately five functional ramp colors per identity/family;
- shadow is subordinate and compact;
- facing must read without relying on UI arrows;
- attack anticipation/recoil is visible in the silhouette.

### Role grammar
- melee: forward weapon mass and aggressive stance;
- ranged: clear firearm barrel/muzzle read;
- charger: broad shoulders/shield/ram mass;
- caster: compact body, staff/focus and ritual head shape;
- skirmisher: lean body with paired weapon read;
- orbiter: non-humanoid floating/rotational construction;
- radial: obvious central emitter/spokes.

### Guardian 96×96 grammar
Every guardian keeps a bespoke core body:
- Watcher Engine — machine core + directional sensor/boom;
- First Nephilim — massive humanoid + blade/horn mass;
- Gate Cherub — wing-frame + lance;
- Tower of Enoch — vertical machine/emitter;
- Serpent Interface — segmented directional serpent.

Boss procedurality may modify phase attachments/effects, never replace the core body with a generic generated humanoid.

## 4. Enemy procedural assembly

`enemy_genome_director_art3.gd` preserves stochastic generation only inside approved family constraints.

Pipeline:
1. select authored enemy/faction family;
2. select one legal silhouette/module profile;
3. select palette only from the family palette set;
4. select legal head/weapon/pack modules;
5. apply bounded size/asymmetry variation;
6. apply elite/damage/biome overlays;
7. generate the 8-direction × 4-frame sheet;
8. freeze that actor's genome for its lifetime and suspension state.

Forbidden:
- unrestricted palette rolls;
- arbitrary body-part combinations;
- random weapon class incompatible with combat role;
- random hero-style identity changes;
- micro-noise used as substitute for design.

## 5. Biome grammar

The active renderer is `procedural_world_director_art3.gd`. Each room uses a stochastic recipe, but its visual hierarchy is curated: quiet base surface → a few large biome motifs → cover/landmarks → localized wear/growth.

### Industrial Eden
- overgrown sealed laboratory;
- containment/service plates, coolant channels, greenhouse breaches;
- tanks, consoles, servers, planters, roots and bio-vats;
- deep green/oxidized teal with restrained warning red;
- no room-sized repeated green-wall rectangles.

### Ash Wastes / devastated city
- shattered roads and crossings;
- convoy wreckage, concrete, rebar, fuel and scrap;
- gray/asphalt/rust hierarchy;
- long road forms rather than laboratory panels.

### Temple-Lab
- ritual circuitry, archive axes and glass processions;
- sacred-machine geometry;
- cool tech values with restrained gold/cyan signals.

### Fungal Garden
- mycelial veins, fruiting rings, spore marshes and root nexuses;
- violet/mauve/fungal beige with organic pools;
- growth clusters rather than tiled decoration.

### Nephilim Ruins
- monolith fields, buried gates, rib processions and bone causeways;
- monumental slabs and sacred ruin mass;
- bone/dusk/gold/scarlet hierarchy.

## 6. Room generation

Procedural rooms must follow the authored-content principle:
- algorithms select/sequence curated room and encounter grammars;
- cover is generated from biome-valid families;
- spawn patterns remain authored role compositions rather than random enemy soup;
- landmarks establish a room identity before micro-decoration;
- the player/enemy contrast budget has priority over floor texture complexity.

## 7. UI and composition

Active presentation layer: `edenfall_v8_authored_presentation_runtime.gd`.

### Title
- asymmetrical reclaimed-city/laboratory silhouette;
- strong logo hierarchy;
- vertical menu rather than a dashboard grid;
- canonical five-hero lineup reinforces stable identity;
- no debug-ring or generic sci-fi HUD motif as the dominant composition.

### Lineage selection
- selected hero is the primary visual;
- canonical hero animation/portrait on the left;
- compact roster on the right;
- stats are secondary to character identity;
- no giant empty rectangular dossier areas.

### Combat HUD
- compact hero icon + HP;
- objective centered but visually quiet;
- resources in a small right module;
- small weapon label;
- combat arena and actors dominate screen area;
- UI borders never compete with bullets or enemies.

## 8. Animation contract

Heroes:
- idle;
- locomotion in eight directions;
- shot/attack anticipation and recoil;
- dash/readable movement accent;
- hurt/death readability.

Enemies:
- idle/move;
- telegraph/wind-up;
- release;
- hurt/death;
- role-specific movement silhouette.

Animation priority is readable anticipation → action → recovery. Extra frames are valuable only when they improve timing/readability; random jitter is forbidden.

## 9. Procedural generation boundary

Highly stochastic:
- room graph and room recipe;
- encounter composition/formation within role rules;
- enemy instance genomes within legal modules;
- drops/relic sequence;
- weapon/relic combinations;
- environmental dressing;
- special-room assignments;
- guardian attack-pattern order.

Semi-procedural:
- enemy visual modules;
- biome cover layouts;
- boss phase attachments/effects;
- hero wear/relic overlays.

Fixed:
- hero base identity;
- boss core identity;
- biome visual vocabulary;
- UI grammar;
- major lore symbols;
- input/readability conventions.

## 10. Quality gates

A release candidate must pass:
- exact Godot 4.7.1 compile-chain probe;
- Art3 hero identity lock;
- canonical hero pixel stability across unrelated RNG states;
- Cain Mark Cannon identity check;
- seven role-family distinctness;
- guardian readability and directional-silhouette gates;
- five biome surface uniqueness + quiet-floor hierarchy;
- stochastic room/enemy/reward entropy gates;
- sprite streaming/memory budget;
- bounded game boot;
- non-threaded, non-PWA Web export verifier;
- representative browser screenshots at 16:9 and mobile-safe aspect ratios.

## 11. Provenance firewall

References such as Enter the Gungeon, Soul Knight and post-apocalyptic games are used to study principles: readable silhouette, compact proportion, authored modularity, encounter composition, contrast hierarchy, and reclaimed-world storytelling. Their characters, sprite sheets, rooms, props, palettes, UI and audio are not copied into EDEN//FALL.

Public sprite repositories may be studied for atlas organization, frame conventions, modular sockets, licensing hygiene and tooling patterns. Their pixels are not included unless a future asset has an explicitly reviewed compatible license and provenance record; Art3 currently remains first-party generated/authored geometry.
