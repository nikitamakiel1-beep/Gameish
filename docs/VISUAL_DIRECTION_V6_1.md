# EDEN//FALL v0.6.1 — Visual and Combat Direction

## Product premise

EDEN//FALL begins inside a sealed biotechnology laboratory that has been reclaimed by roots, vines, fungal growth and failed containment systems. The player breaks the laboratory seal and crosses progressively larger remnants of the dead world: ruined roads and caravans, temple-machines, fungal districts and a megacity whose structures preserve Nephilim-scale biological architecture.

The game is an original industrial-biblical action roguelike. External games are used only as quality and interaction benchmarks. Their characters, rooms, visual assets, wording and proprietary designs must not be copied.

## Reference principles

### Soul Knight

- Inputs must be immediately understandable.
- Each lineage needs a recognizable body shape and starting armament.
- Weapons and pickups must communicate their function at combat speed.
- Mobile layouts must preserve the playfield instead of covering it with interface panels.

### Enter the Gungeon

- Enemy attacks require visible wind-up and readable projectile contrast.
- Dash timing must represent a deliberate defensive commitment.
- Rooms must be composed encounters, not unstructured crowds.
- Enemy positions, bullets, pickups and exits need separate visual channels.

### The Binding of Isaac

- Silhouette and grotesque symbolic identity take priority over ornamental detail.
- Relics must produce recognizable build identity.
- Room-to-room progression must be legible and repeatable while retaining variation.
- Biblical imagery is interpreted through EDEN//FALL's biotechnology and industrial history.

### Horizon-style reclaimed-world direction

- Nature reclaiming engineered ruins is the primary environmental contrast.
- Ancient technology must feel simultaneously mechanical, organic and mythic.
- Ruins tell the history of the lost civilization without relying only on exposition.
- Each biome must show a different stage of ecological and architectural collapse.

## Atlas contract

The existing semantic atlas IDs remain authoritative.

- 5 lineages: Adam, Abel, Cain, Seth and Naamah.
- 18 enemies across preadamite, fallen and Nephilim families.
- 5 bosses.
- 5 biome packages, each containing tiles, props and a background.
- 60 relic cells.
- Pickups, projectiles, effects, HUD panels and touch-control atlases.
- 8 directions.
- 8 frames per animation.
- Idle, walk, attack, dash, hurt and death rows.

The v0.6.1 rebuild changes the generated geometry behind those identifiers. It does not replace the lore taxonomy, animation contract or runtime lookup API.

## Lineage silhouettes

- **Adam:** practical survivor proportions, service rifle, Eden-green field gear and visible biological repair motif.
- **Abel:** light robe, halo geometry and staff/lightcaster silhouette.
- **Cain:** broad red torso, marked face and paired impact-gauntlet silhouette.
- **Seth:** armored engineering suit, visor, shield emitter and coil carbine.
- **Naamah:** fungal mantle, asymmetric caps and orbiting spore focus.

A lineage must remain identifiable at normal gameplay scale without relying on its name label or palette alone.

## Enemy silhouette families

Preadamite enemies use recognizable scavenged human equipment: rifles, hoods, heavy armor, scrap tools and caravan hardware.

Fallen enemies use halos, wings, rotating rings, liturgical machinery and biomechanical implants.

Nephilim enemies use abnormal mass, horns, grafts, bone implements, serpentine bodies and overscaled anatomy.

No two enemy atlas sheets may produce identical image hashes. Elite status is an overlay and cannot be the only differentiator.

RC7 additionally requires material readability rather than hash uniqueness alone. The sprite-quality gate measures frame occupancy, minimum silhouette dimensions and directional silhouette variation for all five lineages, eighteen standard hostiles and five guardians.

RC7 actor frames add first-party hard silhouette outlines, selective rim illumination and sparse deterministic material-value variation while preserving the existing atlas dimensions.

## Biome progression

1. **Industrial Eden — The Garden Below**
   - Overgrown containment chambers.
   - Hydroponics, glass, vines, roots and surviving green systems.
   - The first objective is to open the laboratory seal.

2. **Ash Wastes — Roads of Ash**
   - Devastated highways, caravan wrecks, rubble and industrial dust.
   - Human survival culture becomes visible through salvage infrastructure.

3. **Temple-Lab — The Glass Liturgy**
   - Research architecture reorganized into sacred machine spaces.
   - Circular apparatus, glass, circuitry and ritual geometry.

4. **Fungal Garden — Naamah's Chorus**
   - Dense bioluminescent fungal ecology consuming urban and laboratory remains.
   - Spore structures become both environmental narrative and combat language.

5. **Nephilim Ruins — The City That Remembers**
   - Megacity ruins fused with giant bones, ribs and biological construction.
   - The final environment must make the scale of the former civilization explicit.

## Combat readability budgets

- Normal encounter density: 4–8 enemies.
- Trial/contract encounter ceiling: 9 enemies.
- Encounter composition uses deterministic combat-role signatures rather than independent random picks.
- Authored formations include pincer, crossfire, anchor, orbit, diamond and ring structures.
- Caster/radial role caps prevent unreadable emitter stacking.
- Room-entry grace: 0.72 seconds.
- Standard hostile spawn clearance after transition: at least 152 px before arena correction.
- Guardian spawn clearance: at least 210 px before arena correction.
- Hostiles materialize with staggered activation and a visible progress ring.
- Ranged wind-up: approximately 0.42 seconds.
- Caster wind-up: approximately 0.54 seconds.
- Charger wind-up: approximately 0.62 seconds before a committed charge.
- Enemy projectiles are larger and warmer than player projectiles.
- Player projectiles retain lineage color and brighter cores.
- Normal enemy health bars appear only after damage; elites and bosses always expose status.
- Player and enemy sprites receive shadows and dark outlines against complex backgrounds.
- Environmental tile contrast remains subordinate to bullets, actors and pickups.
- Structural cover blocks actors and projectiles while preserving door lanes.
- Swept collision prevents fast dashes and enemies from tunnelling through narrow cover.
- Aim assist cannot select a target through structural cover.
- Melee/charge, aimed, radial/caster and guardian-phase danger use different warning-audio families.

## Build and reward direction

RC7 reward selection uses contextual pools rather than treating all rooms as equivalent. Shop, treasure, trial, contract, sanctuary and special rooms prefer different existing relic-effect families while remaining deterministic and respecting Archive tier gating.

Every nonfinal guardian victory produces a deterministic two-choice Genome Adaptation. There are five run-only adaptation definitions per lineage, twenty-five total. These choices change existing weapon/player mechanics and create visible run identity without becoming permanent account-stat inflation.

The final Serpent resolution remains separate from ordinary guardian adaptation.

## Interface contract

### Lineage screen

The selected lineage receives a large dossier with portrait, role, starting armament, inherited protocol and normalized stat bars. The five-lineage roster remains visible as a compact navigation strip.

The previous five full-height cards are prohibited because they create excessive empty space and prevent a clear selected-state hierarchy.

Desktop pointer input selects a lineage first and deploys through an explicit confirmation control. Compact touch layouts may deploy by tapping the already-selected lineage.

### Run HUD

Wide layouts use three compact header regions: player state, chapter/objective and resources/minimap. Small landscape and phone layouts use a single header plus a separate objective strip.

The HUD may overlap the arena border but must not consume the central combat field. Synergy, temporary armor, orbital, mutation, adaptation and encounter-signature state must remain subordinate to active combat.

### Genome Archive

The archive is an atlas-driven visual reference, not a numbered placeholder grid. Wide layouts expose five lineages, eighteen hostile signatures, five guardian atlases, five biome memories and all sixty relic cells. The archive also exposes faction memory and current relic-pool tier.

### Caravan exchange

Shop rooms expose three selectable relic cards with icons, names, prices and purchased state. Keyboard, controller, pointer and touch interactions converge on the same inventory state. Faction reputation modifies price without changing the item identity.

### Mobile and accessibility

- Touch-control opacity is adjustable independently of gameplay UI scale.
- Reduced flashing shortens and attenuates high-energy effects.
- Strong attack telegraphs and projectile outlines are independently configurable.
- Left-handed controls, aim assist, reduced motion, simplified FX and haptics remain supported.

### Safe-area and compact thresholds

- Compact dossier: width below 900 px, height below 650 px, or portrait-dominant aspect ratio.
- Compact HUD: width below 920 px or height below 610 px.
- Arena margins scale down for short landscape displays.

## Loading and performance contract

Deep art validation is a release operation, not a startup operation. Runtime startup performs a light representative asset contract. Remaining assets prewarm one at a time only on title/select screens or in cleared noncombat rooms.

No speculative prewarming may occur during active combat. The current biome hostile pool and guardian are retained across ordinary cache trimming.

## Verification contract

RC7 uses two final gates while retaining the RC6 subsystem audit as inherited evidence:

- `tests/v6_product_rebuild_audit.gd` — inherited RC6 product/world/persistence contract.
- `tests/v7_masterpiece_audit.gd` — deep actor/art/encounter/reward/progression/product gate.
- `tests/v7_runtime_quality_audit.gd` — audio/fairness/loading/runtime-quality gate.

The RC7 gates require:

- exact Godot 4.7.1;
- core v0.6 ABI and RC7 product-revision consistency;
- deep generated-asset validation;
- unique and materially readable actor atlases;
- all 18 enemy role classifications and at least six authored encounter signatures;
- contextual relic pools;
- room-entry fairness and post-transition clearance;
- five lineage adaptation families with twenty-five run-only definitions;
- first-party 22.05 kHz biome/warning synthesis contracts;
- safe-state prewarming and shallow-startup/deep-release separation;
- all inherited RC6 deterministic floor, room state, faction, synergy, guardian, final Serpent and ending-persistence guarantees;
- `main.tscn` routing to `edenfall_v7_release_runtime.gd`.

Static review is not a substitute for import, boot, screenshot, audio-listening and gameplay testing. No build may be described as qualified until the exact branch head passes the runtime checks in `docs/RC7_RELEASE_CANDIDATE.md`.
