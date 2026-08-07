# EDEN//FALL v0.6.1 — Visual, Combat and Godmode Direction

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
- Trial and contract encounter ceiling: 9 enemies.
- Initial spawn positions use separated rings rather than random clustering.
- Ranged wind-up: approximately 0.42 seconds.
- Caster wind-up: approximately 0.54 seconds.
- Charger wind-up: approximately 0.62 seconds before a committed charge.
- Enemy special attacks and guardian patterns expose separate telegraph rings.
- Enemy projectiles are larger and warmer than player projectiles.
- Player projectiles retain lineage color and brighter cores.
- Projectile outlines can be forced through accessibility settings.
- Normal enemy health bars appear only after damage; elites and bosses always expose status.
- Player and enemy sprites receive shadows and dark outlines against complex backgrounds.
- Environmental tile contrast remains subordinate to bullets, actors and pickups.
- Structural cover blocks actors and projectiles while preserving door lanes.
- Swept collision prevents fast dashes and enemies from tunnelling through narrow cover.
- First Nephilim phases can destroy structural cover; Gate Cherub deploys auxiliary bodies; Tower Enoch reconfigures crossfire; Serpent phases deploy forked hosts.

## Godmode gameplay contract

### Deterministic run topology

Every floor graph is seeded from run seed, biome index and floor number. Room generation, special-room assignment and encounter spawning are isolated from the global combat RNG. Suspend/resume therefore restores the same room coordinates instead of trying to apply state to a newly randomized graph.

### Decision rooms

The run may include settlements, sacrifice bioreactors, lineage memories, maintenance tunnels, contracts and the Serpent terminal. Noncombat decision rooms lock their exits until the player approaches the focal system and commits to a consequence.

### Factions

Salt Caravans, Ash Covenant, Tubal Foundries, Enoch Outlaws, Lamech Houses and The Unnamed maintain persistent reputation. Reputation affects shop prices and sufficiently negative reputation can generate deterministic retaliation ambushes. Reputation is not a morality score.

### Relic synergies

Relics continue using the sixty-cell semantic atlas, but effects are interpreted as tags. Eight RC6 synergy rules transform projectile behavior, armor, orbitals, dash attacks and guardian damage. The Archive expands available relic tiers through mastery, recovered memories and defeated guardians rather than granting permanent raw combat stats.

### Weapons

The inherited five lineage weapons retain their identities: Adam rifle/homing fire, Abel beam/mark/chain behavior, Cain cannon/explosion/burn behavior, Seth lance/pierce/bounce/stagger behavior and Naamah spread/spore behavior. RC6 restores those projectile systems on top of structural cover collision and adds run-based evolution without replacing the starting identities.

### Serpent resolution

Defeating the Serpent Interface no longer immediately terminates the run. The player must resolve the final adaptation request by rejecting or accepting the forbidden genome. The pending ending choice is saved separately so focus loss or suspension cannot skip the resolution.

## Interface contract

### Lineage screen

The selected lineage receives a large dossier with portrait, role, starting armament, inherited protocol and normalized stat bars. The five-lineage roster remains visible as a compact navigation strip.

The previous five full-height cards are prohibited because they create excessive empty space and prevent a clear selected-state hierarchy.

Desktop pointer input selects a lineage first and deploys through an explicit confirmation control. Compact touch layouts may deploy by tapping the already-selected lineage.

### Run HUD

Wide layouts use three compact header regions: player state, chapter/objective and resources/minimap. Small landscape and phone layouts use a single header plus a separate objective strip.

The HUD may overlap the arena border but must not consume the central combat field. RC6 also exposes synergy, temporary armor, orbital and mutation state without obscuring central projectile space.

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

## Verification contract

`tests/v6_product_rebuild_audit.gd` must verify:

- Exact Godot 4.7.1 runtime.
- The inherited v0.6 asset-dimension contract.
- Unique hashes for all five heroes, five portraits, eighteen enemies, five bosses and each biome atlas family.
- Non-empty utility atlases.
- Existence of every rebuild and godmode layer.
- World collision, swept navigation, archive and shop source contracts.
- Six factions and at least eight tag-based synergy rules.
- Fifteen explicit guardian patterns across five guardians.
- Mandatory special-room decisions, deterministic room seeding and deterministic floor topology.
- Room-state suspend/restore, final Serpent resolution persistence and stale-ending cleanup.
- Archive pool progression, faction ambushes, guardian environment phases and mobile accessibility additions.
- `main.tscn` routing to `edenfall_v6_godmode_verified_runtime.gd`.

Static review is not a substitute for import, boot, screenshot and gameplay testing. No build may be described as qualified until the exact branch head passes those runtime checks.
