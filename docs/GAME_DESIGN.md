# EDEN//FALL — Game Design Bible

## 1. Product definition

**Genre:** Single-player, top-down, room-based action roguelike.

**Primary platform:** iPhone and iPad, landscape orientation.

**Secondary development platform:** Windows, macOS, and Linux desktop.

**Session target:** 15–30 minute complete runs, with useful progress from failed runs.

**Core promise:** Every excursion begins with a deliberately engineered human body and ends in a biological argument about what humanity was before Adam, what it became after Eden, and who is entitled to inherit the ruined world.

## 2. World premise

The Eden Biolaboratory is not a natural paradise. It is a sealed industrial biosphere constructed by a vanished civilization to manufacture a stable successor species after ecological collapse, war, mutagenic contamination, and uncontrolled human enhancement.

The five playable lineages awaken from genomic cradles inside Eden. Their inherited records call them the Adamic Line: an intentionally constrained form of humanity designed to remain fertile, socially coherent, and biologically repairable.

Outside the laboratory live the **preadamic peoples**. They are human populations whose ancestry predates the Adamic program. Some survived naturally; others inherited crude or unstable enhancement systems. They are not a single enemy faction. They form settlements, caravans, workshops, cults, militias, raider bands, and outlaw companies. The player can trade with some and fight others.

The deeper regions contain entities interpreted through damaged religious language:

- **Nephilim:** enlarged human war-lineages with unstable growth and skeletal reinforcement.
- **Fallen Angels:** airborne or levitating biomechanical custodians that rejected central control.
- **Cherubim:** autonomous security constructs protecting restricted genomic or industrial sites.
- **Watchers:** supervisory intelligences embedded in bodies, factories, towers, and orbital remnants.
- **The Serpent:** a later narrative system associated with forbidden adaptation, self-modifying genomes, and knowledge that Eden deliberately suppressed.

The religious names are survivor interpretations of biotechnology, machine intelligence, industrial infrastructure, and ancient political events. The game should preserve ambiguity rather than explicitly declaring that every myth has one technological explanation.

## 3. Player lineages

The launch design uses exactly five selectable engineered descendants.

### Adam — The First Pattern

The stable baseline. High vitality, reliable damage, and forgiving handling.

- Role: Beginner/generalist.
- Trait: Genesis Tissue restores one cell when the boss enters a new phase.
- Narrative tension: Adam is treated as the intended heir, but may be less adaptable than the populations Eden excluded.

### Abel — The Offering

A high-precision, high-mobility body designed for observation, diplomacy, and sacrificial risk.

- Role: Fast critical-hit specialist.
- Trait: Blood Tithe increases critical chance below half health.
- Narrative tension: Abel's genome contains deliberate fail-safe vulnerabilities that may have been political rather than medical.

### Cain — The Marked Weapon

A combat lineage with accelerated aggression, dense motor recruitment, and a visible regulatory implant called the Mark.

- Role: High damage, low health, aggressive dash combat.
- Trait: Mark of Violence damages enemies near the start of a dash.
- Narrative tension: Cain may have been created as Eden's external enforcement body, then blamed for doing what it was designed to do.

### Seth — The Continuation

A maintenance and colonization lineage engineered to preserve infrastructure and survive attrition.

- Role: Defensive engineer.
- Trait: Second Skin blocks one hit and refreshes when entering or clearing a chamber.
- Narrative tension: Seth carries the strongest obedience architecture and may be the least free lineage.

### Naamah — The Resonant Genome

A fungal, microbial, and ecological integration specialist able to exchange signals with altered environments.

- Role: Rapid fire and probabilistic sustain.
- Trait: Mycelial Recall can restore health after kills.
- Narrative tension: Naamah can understand organisms the other lineages classify as contamination and may discover that Eden itself is the invasive species.

## 4. Core run loop

1. Select a lineage in the Eden Biolaboratory.
2. Receive a deterministic run seed.
3. Enter a compact procedural room graph.
4. Clear sealed chambers using twin-stick movement, shooting, and dashing.
5. Collect scrap, healing cells, and run-only relics.
6. Meet pre-Adamite traders and choose whether to spend scarce scrap.
7. Reach the biome guardian or Watcher boss.
8. Die and lose the run build, or defeat the boss and extract a larger genomic sample.
9. Spend or accumulate Genome Archive currency to expand future item and encounter pools.

The player should make meaningful decisions every 30–90 seconds: route, risk, purchase, item choice, health sacrifice, challenge room, or narrative interaction.

## 5. Procedural map grammar

The current vertical slice generates 8–11 connected rooms on a bounded grid.

Guaranteed room types:

- **Biolaboratory Start:** Safe entry room and narrative anchor.
- **Contaminated Chambers:** Standard combat rooms with sealed doors.
- **Genome Reliquary:** Guaranteed run item.
- **Preadamic Exchange:** Three purchasable items.
- **Watcher Sanctum:** Farthest-room boss encounter.

Planned room types:

- Elite mutation room.
- Sacrifice chamber.
- Environmental hazard room.
- Preadamic settlement encounter.
- Challenge contract room.
- Secret maintenance tunnel.
- Serpent terminal.
- Lineage-specific memory chamber.

Map generation must guarantee boss reachability, avoid isolated rooms, provide at least one shop and one relic, and remain reproducible from the run seed.

## 6. Combat language

Combat should be readable on a phone screen and mechanically closer to a bullet-hell duel than to a stat-driven RPG.

Player verbs:

- Move continuously.
- Aim independently.
- Fire continuously or in weapon-specific patterns.
- Dash through danger with a short invulnerability window.
- Position around cover and door geometry in later builds.
- Build item synergies that visibly alter projectiles, movement, defense, or kill effects.

Design rules:

- Enemy projectiles need strong silhouette and contrast.
- Contact damage must be clearly telegraphed.
- Boss attacks should form learnable patterns rather than unavoidable noise.
- Mobile controls should not require more than two simultaneous touch regions plus one dash button.
- Damage should produce immediate visual, audio, and haptic feedback.
- The player should understand why they were hit.

## 7. Enemy progression

### Tier 1 — Preadamic frontier

- Feral melee pursuers.
- Outlaw ranged fighters.
- Scrap drones.
- Improvised turrets.

### Tier 2 — Enhanced populations

- Reinforced raiders.
- Hormonal berserkers.
- Symbiotic marksmen.
- Salvaged cherub operators.

### Tier 3 — Nephilim contamination

- Nephilim Husk: large health pool and radial shock pattern.
- Bone Shepherd: summons or reassembles smaller mutants.
- Giant-Blood Charger: telegraphed lane attack.

### Tier 4 — Fallen custodians

- Fallen Angel: orbital movement and spread fire.
- Broken Cherub: rotating defensive fields.
- Ophanim Wheel: moving projectile emitter.

### Bosses

- **Watcher Engine:** Current vertical-slice boss with escalating radial patterns.
- **First Nephilim:** Grapple, shockwave, and arena destruction.
- **The Gate Cherub:** Multi-body security encounter.
- **Tower of Enoch:** Industrial boss fought while ascending a machine complex.
- **The Serpent Interface:** A nontraditional final encounter based on build mutation and player choice.

## 8. Factions and morality

Preadamic humans must not be represented as universally primitive or evil. Their technological level varies by settlement and access to surviving infrastructure. Some understand Eden better than the player does.

Proposed factions:

- **Salt Caravans:** Neutral traders and route guides.
- **Ash Covenant:** Religious isolationists who consider Adamic bodies artificial invaders.
- **Tubal Foundries:** Industrial settlements specializing in weapon and implant fabrication.
- **Enoch Outlaws:** Mobile raider companies using stolen enhancement rigs.
- **Lamech Houses:** Kinship militias that trade safely until lineage reputation turns hostile.
- **The Unnamed:** Communities that reject Eden's inherited classification system.

Reputation should later influence prices, ambush probability, quests, room replacements, and endings. It should not become a simple good/evil meter.

## 9. Item system

Items are run-only unless explicitly described as an Archive unlock. Strong items should alter behavior, not merely increase numbers.

Current prototype items:

- Seraph Lens: damage and projectile speed.
- Cherub Coil: fire-rate increase.
- Bone Orchard: maximum health and healing.
- Cain's Mark: projectile penetration.
- Salt Genome: parallel projectile.
- Eden Valve: movement and dash recharge.
- Black Manna: kill-based healing chance.
- Industrial Halo: orbiting projectile defense.
- Watcher Gland: critical-hit secondary shard.
- Nephilim Marrow: damage increase with movement penalty.

Planned synergy examples:

- Salt Genome + Seraph Lens = refracted parallel beams.
- Cain's Mark + Nephilim Marrow = heavy penetrating rounds with recoil.
- Industrial Halo + Cherub Coil = halo stores destroyed bullets and releases them after a reload cycle.
- Black Manna + Bone Orchard = overhealing grows temporary fungal armor.
- Watcher Gland + Abel's Blood Tithe = critical shards seek the nearest marked target.

Synergies should be implemented through tags and interactions rather than one-off checks for every possible pair.

## 10. Meta-progression

The persistent layer is the **Genome Archive**.

Allowed persistent advantages:

- New items added to the run pool.
- New room types and factions.
- New lineages or lineage variants.
- Starting-sidegrade choices.
- Lore and memory records.
- Cosmetic biolab changes.
- Additional challenge modifiers.

Avoid permanent raw-stat inflation that makes early rooms trivial. Mastery, knowledge, and broader build possibilities should remain more important than account age.

## 11. Mobile product rules

- Landscape-first.
- Playable offline.
- Run pause/resume must be robust when the app backgrounds.
- Local save writes must be atomic and versioned.
- No mandatory account for single-player.
- No paid randomized functional loot boxes.
- No interstitial advertising during a run.
- Haptics must be adjustable or disableable.
- Aim assist, control sizing, control opacity, left-handed layout, frame-rate cap, and reduced-flash options should be included before release.

A premium paid release is the cleanest initial commercial model. A free demo plus one-time full-game unlock is the second-best option. Monetization should not compromise roguelike balance.

## 12. Art and audio direction

Visual language:

- Industrial Eden rather than pastoral Eden.
- Rusted pressure vessels, stained glass diagnostics, irrigation arteries, cracked cloning glass, concrete roots, halo-shaped machinery, and botanical growth consuming old factories.
- Geometric religious silhouettes interpreted through engineering forms.
- Strong projectile contrast and restrained background detail during combat.
- Original designs only; no imitation of commercial reference-game sprites.

Palette:

- Carbon black, oxidized green, bone ivory, faded gold, arterial red, laboratory cyan, and bruised violet.

Audio language:

- Mechanical liturgy.
- Ventilation drones and distant turbines.
- Process alarms treated as musical rhythm.
- Choir-like synthesis without direct liturgical sampling.
- Distinct warning sound families for melee, aimed shots, radial attacks, and boss phase transitions.

## 13. Narrative delivery

Narrative should occur in short, interruptible fragments suited to repeated runs:

- Trader dialogue.
- Lineage memories.
- Environmental inscriptions.
- Boss identification records.
- Contradictory Archive entries.
- Faction testimony.
- End-of-run discoveries.

The game should never pause a combat run for long exposition. Full records belong in an optional Archive interface in the biolab.

## 14. Vertical-slice acceptance criteria

The first slice is acceptable when:

- A new player can start without instructions and understand movement, shooting, and dashing.
- Every generated map can reach its boss.
- A complete run can be won and lost.
- All five lineages feel mechanically distinct.
- At least five item combinations create visibly different play.
- Touch controls work on multiple iPhone aspect ratios without covering critical play space.
- Backgrounding and restoring the app does not corrupt progression.
- The build remains playable without a network connection.
- No third-party copyrighted game assets are present.
