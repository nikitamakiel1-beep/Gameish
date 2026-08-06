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

### Horizon Zero Dawn

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

Predamite enemies use recognizable scavenged human equipment: rifles, hoods, heavy armor, scrap tools and caravan hardware.

Fallen enemies use halos, wings, rotating rings, liturgical machinery and biomechanical implants.

Nephilim enemies use abnormal mass, horns, grafts, bone implements, serpentine bodies and overscaled anatomy.

No two enemy atlas sheets may produce identical image hashes. Elite status is an overlay and cannot be the only differentiator.

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
- Trial encounter ceiling: 9 enemies.
- Initial spawn positions use separated rings rather than random clustering.
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

## Interface contract

### Lineage screen

The selected lineage receives a large dossier with portrait, role, starting armament, inherited protocol and normalized stat bars. The five-lineage roster remains visible as a compact navigation strip.

The previous five full-height cards are prohibited because they create excessive empty space and prevent a clear selected-state hierarchy.

Desktop pointer input selects a lineage first and deploys through an explicit confirmation control. Compact touch layouts may deploy by tapping the already-selected lineage.

### Run HUD

Wide layouts use three compact header regions: player state, chapter/objective and resources/minimap. Small landscape and phone layouts use a single header plus a separate objective strip.

The HUD may overlap the arena border but must not consume the central combat field.

### Genome Archive

The archive is an atlas-driven visual reference, not a numbered placeholder grid. Wide layouts expose five lineages, eighteen hostile signatures, five guardian atlases, five biome memories and all sixty relic cells.

### Caravan exchange

Shop rooms expose three selectable relic cards with icons, names, prices and purchased state. Keyboard, controller, pointer and touch interactions must converge on the same inventory state.

### Safe-area and compact thresholds

- Compact dossier: width below 900 px, height below 650 px, or portrait-dominant aspect ratio.
- Compact HUD: width below 920 px or height below 610 px.
- Arena margins scale down for short landscape displays.

## Verification contract

`tests/v6_product_rebuild_audit.gd` must verify:

- Exact Godot 4.7.1 runtime.
- The inherited v0.6 asset-dimension contract.
- Unique hashes for all five heroes, five portraits, eighteen enemies, five bosses and each biome atlas family.
- Non-empty utility atlases.
- Existence of every rebuild layer.
- World collision, swept navigation, archive and shop source contracts.
- `main.tscn` routing to `edenfall_v6_polish_runtime.gd`.

Static review is not a substitute for import, boot, screenshot and gameplay testing. No build may be described as qualified until the exact branch head passes those runtime checks.
