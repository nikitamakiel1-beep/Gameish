# EDEN//FALL — Game Design Bible

## 1. Product definition

**Genre:** single-player, top-down, room-based action roguelike.

**Primary product target:** mobile-first landscape play, with first-class browser/desktop development and validation.

**Engine target:** Godot 4.7.1 stable, GL Compatibility.

**Current production candidate:** `0.6.4-authored-art4`.

**Session target:** approximately 15–30 minutes for a complete excursion, with meaningful progress and information gained from failed runs.

**Core promise:** every excursion begins with a deliberately engineered human lineage inside Eden and becomes a biological, technological and historical argument about what humanity was before Adam, what Eden changed, what survived outside it, and who is entitled to inherit the ruined world.

## 2. World premise and progression

The Eden Biolaboratory is not a natural paradise. It is a sealed industrial biosphere constructed by a vanished civilization to manufacture a stable successor species after ecological collapse, war, mutagenic contamination and uncontrolled human enhancement.

The five playable lineages awaken in genomic cradles inside an overgrown laboratory. Their inherited records call them the Adamic Line: intentionally constrained descendants designed to remain fertile, socially coherent and biologically repairable.

The excursion moves physically and aesthetically outward:

1. **Industrial Eden** — sealed biotechnology, containment infrastructure, failed greenhouses, pressure systems and roots penetrating the laboratory.
2. **Ash Wastes** — broken road systems, wrecked convoys, salvage settlements, checkpoints and devastated urban approaches.
3. **Temple-Lab** — surviving scientific infrastructure reorganized into ritual machine culture, archives and sanctums.
4. **Fungal Garden** — mycelial ecologies consuming laboratories, streets, structures and engineered organisms.
5. **Nephilim Ruins** — megacity-scale devastation, giant biological architecture, monoliths, buried gates and ancient machine remains.

Outside Eden live the **preadamic peoples**. Their ancestry predates the Adamic program. Some survived naturally; others inherited crude, unstable or deliberately divergent enhancement systems. They are not one enemy faction. They form settlements, caravans, workshops, cults, militias, raider bands and outlaw companies. The player can trade with some, fight others and learn from groups that understand Eden better than the protagonist does.

The deeper regions contain entities interpreted through damaged religious language:

- **Nephilim:** enlarged human war-lineages with unstable growth and skeletal reinforcement.
- **Fallen Angels:** airborne or levitating biomechanical custodians that rejected central control.
- **Cherubim:** autonomous security constructs protecting restricted genomic/industrial sites.
- **Watchers:** supervisory intelligences embedded in bodies, factories, towers and surviving infrastructure.
- **The Serpent:** a later narrative/adaptation system associated with forbidden self-modifying genomes and knowledge Eden suppressed.

Religious names are survivor interpretations of biotechnology, machine intelligence, industrial infrastructure and ancient political events. The game preserves ambiguity instead of reducing every myth to one definitive technical answer.

## 3. Canonical lineages

The launch design uses exactly five selectable engineered descendants. Their gameplay identity may evolve through run builds; their base visual identity does not reroll.

### Adam — Edenic Survivor

A stable baseline built to survive outside Eden without specializing into one extreme.

- Role: generalist/ranged.
- Canonical visual language: olive/green, dark-hair survivor silhouette, Genesis Rifle, living-Eden detail.
- Trait direction: reliable recovery/continuation rather than burst specialization.
- Narrative tension: Adam is treated as the intended heir but may be less adaptable than populations Eden excluded.

### Abel — Shepherd of Light

A precision/ritual lineage built around observation, sacrifice and controlled luminous systems.

- Role: caster/precision specialist.
- Canonical visual language: ivory/gold, halo/focus silhouette and light-oriented accents.
- Trait direction: risk/reward around health, accuracy and critical output.
- Narrative tension: Abel's fail-safe vulnerabilities may have been political rather than medical.

### Cain — Marked Warrior

A combat lineage with accelerated aggression, dense motor recruitment and the visible regulatory Mark.

- Role: heavy ranged/aggressive dash combat.
- Canonical visual language: black/red mass, Mark implant, permanent Mark Cannon, braced recoil.
- Trait direction: violence rewarded by positioning, momentum and close pressure.
- Narrative tension: Cain may have been Eden's external enforcement body and later blamed for doing what it was designed to do.

### Seth — Guardian Engineer

A maintenance/colonization lineage engineered to preserve infrastructure and survive attrition.

- Role: defensive engineer/ranged.
- Canonical visual language: blue-steel armor, visor/nodes, Watcher Carbine and technical appendages.
- Trait direction: shields, continuity and infrastructure interaction.
- Narrative tension: Seth may carry the strongest obedience architecture and therefore the weakest claim to free will.

### Naamah — Voice of Mycelia

A fungal, microbial and ecological integration specialist able to exchange signals with altered environments.

- Role: caster/rapid sustain.
- Canonical visual language: violet mycelial body language, fungal cap/buds/tendrils and Spore Repeater.
- Trait direction: probabilistic sustain, spores and ecological interaction.
- Narrative tension: Naamah can understand organisms other lineages call contamination and may discover that Eden itself is the invasive species.

## 4. Core excursion loop

1. Select a canonical lineage in the Eden Biolaboratory.
2. Begin a fresh stochastic excursion.
3. Enter a procedurally reconfigured room graph whose visible recipe is created as the run unfolds.
4. Clear sealed chambers using independent movement/aim, weapons, dashing and positioning.
5. Collect scrap, healing resources, relics and Genome information.
6. Encounter traders, factions, special rooms and environmental story beats.
7. Choose routes and risk rather than following one fixed encounter sequence.
8. Defeat a biome guardian or deeper Watcher/Serpent encounter.
9. Die and lose the run build, or extract genomic/archive progress.
10. Expand future possibility space without turning early encounters into trivial stat checks.

The player should face a meaningful decision roughly every 30–90 seconds: route, risk, purchase, relic, sacrifice, faction interaction, challenge, mutation or narrative discovery.

## 5. Stochastic generation rules

Ordinary excursions are deliberately **not** fixed-seed replays. `fixed_seed_replay` is false in the active V8 contract.

Fresh entropy controls:

- room topology;
- special-room placement;
- encounter composition;
- legal enemy-instance genomes;
- relic/reward order;
- environmental dressing and biome story beats;
- guardian pattern order.

Procedural generation is constrained, not arbitrary:

- canonical heroes cannot be replaced by RNG;
- enemy families stay inside authored silhouette/material/motion/weapon rules;
- room surfaces use quiet texture plus biome macro forms and story landmarks;
- gameplay-critical collision and visible structural cover must agree;
- random micro-detail cannot overwhelm projectile/enemy readability.

Suspend/resume preserves already-generated active-run recipes and state. It does not visibly rebuild a suspended room from an exposed seed.

A future Daily Protocol may define shared challenge constraints, but ordinary excursions remain fresh. A daily should not contaminate the normal entropy model merely for leaderboard reproducibility.

## 6. Room grammar

Every generated graph must preserve navigability and progression requirements while allowing meaningful structural variation.

Room families include:

- laboratory/start spaces;
- standard combat chambers;
- elite/challenge encounters;
- reliquary/reward rooms;
- preadamic exchange/trader spaces;
- faction/special rooms;
- environmental hazard rooms;
- secret/maintenance spaces;
- guardian/boss rooms;
- Serpent/choice interfaces.

A room recipe should describe gameplay type, encounter composition, environmental identity and already-generated story dressing. It should be persisted once it becomes active-run state.

## 7. Combat language

Combat is a readable action duel, not a stat-check RPG.

Player verbs:

- move continuously;
- aim independently;
- fire or cast through weapon-specific patterns;
- dash through danger with a short invulnerability window;
- use cover/door geometry where the room supports it;
- interact with room/faction systems;
- build relic synergies that visibly alter projectiles, movement, defense or kill effects.

Design rules:

- enemy projectiles have strong silhouette/contrast against each biome;
- contact damage and dangerous movement are telegraphed;
- enemy windups communicate role before damage occurs;
- bosses use learnable patterns and phase language rather than unavoidable noise;
- mobile controls avoid precision UI demands during combat;
- damage produces immediate visual/audio/haptic feedback where the platform supports it;
- the player should be able to explain why they were hit;
- background dressing may be rich but must visually recede from actors/projectiles.

## 8. Sprite and motion language

The Art4 reference is compact action-roguelike pixel art with original designs.

Normal actor frames retain a 48x48 ABI; bosses may use 96x96 frames. The active four-state frame grammar is:

1. idle/read;
2. locomotion;
3. attack/recoil/cast;
4. dash/special/hurt response.

Required visual properties:

- strong silhouette before internal detail;
- large readable heads/face direction at gameplay scale;
- compact body proportions;
- explicit arms/hands where needed to communicate weapon action;
- deliberately oversized, readable weapon shapes;
- limited coherent value ramps;
- sparse material accents instead of random texture noise;
- family-specific motion and material identity;
- runtime bob/recoil/muzzle/hit/dash feedback that makes sprites feel alive rather than stamped onto the floor.

Enter the Gungeon, Soul Knight and The Binding of Isaac are reference points for readability, authored modularity, pacing and combat hierarchy only. EDEN//FALL must not copy their sprites, characters, rooms or UI.

## 9. Enemy progression and family identity

Preadamic/frontier enemies should read as people and improvised systems before later regions become increasingly biomechanical, ritualized and biologically impossible.

Representative families:

- feral scavengers — skittering short-melee bodies;
- outlaw gunners/hunters — braced long-weapon silhouettes;
- raider brutes — heavy lurching plate/scrap mass;
- cultists/acolytes — ritual cloth, focus/staff and casting language;
- Cherub drones — compact ivory machine cores, wings and halo geometry;
- Fallen — broken glide, cold halo/plate language;
- biomech pilgrims — servo-driven hybrid machine bodies;
- Ophanim — radial/wheel movement and eye-centric silhouette;
- Nephilim husks/giants/berserkers — bone/flesh/plate mass with oversized melee/ram language;
- serpent spawn — swaying body-weapon ecology.

Elite generation can intensify a family; it cannot replace the family identity with an unrelated random body.

### Guardians

The guardian set includes Watcher Engine, First Nephilim, Gate Cherub, Tower Enoch and Serpent Interface identities. Bosses require bespoke silhouette/pattern recognition beyond standard enemy scaling.

## 10. Biome art grammar

### Industrial Eden

Failed containment, pipes, tanks, service channels, greenhouse breaches, coolant and engineered growth. The starting world should communicate that Eden was industrial infrastructure before it was myth.

### Ash Wastes

Broken road geometry, checkpoints, wrecks, burned convoys, rebar, craters and salvage structures. This is the transition from sealed laboratory to devastated human geography.

### Temple-Lab

Ritual circuitry, archive/process machinery, sacred geometry, glass/process structures and sealed sanctums. Religion and engineering become visually inseparable.

### Fungal Garden

Mycelial veins, root structures, spore basins, fruiting nurseries and drifting spores consume laboratory/urban remains.

### Nephilim Ruins

Monoliths, buried gates, rib causeways, colossal remains and megacity-scale destruction suggest entities and construction far larger than the player.

A floor is never just a tiled noisy texture. Composition hierarchy is:

**quiet base -> macro landmark -> collision/cover structure -> localized wear/growth -> actors/projectiles/FX.**

## 11. Factions and morality

Preadamic humans are not universally primitive or evil. Technological level, history and attitude vary by settlement and surviving infrastructure.

Faction direction includes Salt Caravans, Ash Covenant, Tubal Foundries, Enoch Outlaws, Lamech Houses and communities that reject Eden's inherited labels.

Reputation may influence prices, ambushes, quests, room replacements, testimony and endings. It should not become a simple good/evil bar.

## 12. Relics, weapons and synergies

Run-only items should change behavior rather than only adding percentages.

Synergies should be tag/context driven so new content can combine with existing systems without one hard-coded pair check for every possible build.

Useful tags include projectile, critical, fungal, halo, penetration, healing, sacrifice, industrial, seraphic, nephilim, shield, dash and summon.

Build expression must remain visually legible: projectile shape, cadence, trails, orbitals, status FX or movement behavior should communicate major synergy changes.

## 13. Meta-progression

The persistent layer is the Genome Archive.

Allowed persistent advantages:

- additional relics/weapons in future pools;
- new room/special encounter possibilities;
- faction/lore access;
- lineage sidegrades/variants that preserve base identity rules;
- starting choice breadth;
- challenge modifiers;
- cosmetic/biolab progression.

Avoid permanent raw-stat inflation that makes early combat irrelevant. Mastery, knowledge and possibility-space expansion matter more than account age.

## 14. Mobile/browser product rules

- landscape-first;
- offline single-player remains viable;
- robust suspend/resume when mobile lifecycle interrupts play;
- local save writes are migration-aware and recoverable;
- no mandatory account;
- no paid randomized functional loot boxes;
- no interstitial advertising during an excursion;
- adjustable haptics where available;
- aim assist/control sizing/control opacity/left-handed layout/reduced-flash/reduced-motion options before commercial release;
- browser development must not rely on stale service workers or cached PCK files.

The Codespaces preview channel is non-threaded and non-PWA by design. A no-cache server and scoped `/purge.html` retirement page prevent obsolete Web assets from being mistaken for the newest qualified build.

## 15. Audio direction

Audio language is mechanical liturgy:

- ventilation/turbine drones;
- machinery pulses as rhythm;
- synthetic choir-like texture without copied liturgical recordings;
- biome-specific environmental motifs;
- distinct functional warning families;
- weapon/impact feedback differentiated by role.

Gameplay audio variation must not mutate progression-critical entropy state.

## 16. Narrative delivery

Narrative arrives in short, interruptible fragments suited to repeated runs:

- trader/faction dialogue;
- lineage memories;
- environmental story beats;
- inscriptions/terminals;
- boss identification records;
- contradictory Archive entries;
- faction testimony;
- end-of-run discoveries.

Long records belong in the optional Archive rather than interrupting active combat.

## 17. Acceptance criteria for the Art4 vertical product

The current candidate should not be called qualified unless:

- exact Godot 4.7.1 imports the project without parser/resource errors;
- every production/test GDScript loads and can instantiate;
- the curated V7/V8 compile chain passes;
- the final release root is explicitly bound to Art4 forge/genome/world;
- all five canonical hero identities remain stable across unrelated RNG state;
- representative enemy families remain materially distinct;
- Art4 action states are visually distinct;
- all five biome generators produce distinct, story-bearing room surfaces;
- inherited RC6/RC7/V8 gameplay/persistence/entropy/presentation/streaming gates pass;
- the real main scene survives bounded headless boot without fatal diagnostics;
- the Web export is non-threaded/non-PWA and carries exact source provenance;
- the static Web verifier passes;
- browser screenshots are visually inspected for hierarchy, sprite scale, combat clarity and clipping;
- hands-on gameplay confirms that the player understands hits, doors, objectives and rewards;
- no third-party copyrighted commercial-game assets are present.

Automated success is necessary but not sufficient for visual/gameplay quality. Fresh browser and device observation remains part of qualification.
