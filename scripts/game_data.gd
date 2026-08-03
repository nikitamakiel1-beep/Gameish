class_name GameData
extends RefCounted

static func lineages() -> Array:
	return [
		{
			"id": "adam",
			"name": "ADAM",
			"epithet": "The First Pattern",
			"description": "Stable genome. High vitality and reliable firepower.",
			"color": Color8(224, 191, 126),
			"max_hp": 7.0,
			"speed": 250.0,
			"damage": 12.0,
			"fire_delay": 0.31,
			"shot_speed": 650.0,
			"dash_delay": 1.35,
			"luck": 0.05,
			"trait": "Genesis Tissue: recover one cell after each boss phase."
		},
		{
			"id": "abel",
			"name": "ABEL",
			"epithet": "The Offering",
			"description": "Fast and precise. Critical hits intensify while wounded.",
			"color": Color8(151, 220, 205),
			"max_hp": 5.0,
			"speed": 285.0,
			"damage": 11.0,
			"fire_delay": 0.24,
			"shot_speed": 760.0,
			"dash_delay": 1.05,
			"luck": 0.16,
			"trait": "Blood Tithe: critical chance rises below half health."
		},
		{
			"id": "cain",
			"name": "CAIN",
			"epithet": "The Marked Weapon",
			"description": "Heavy damage, low resilience. Dashes wound nearby enemies.",
			"color": Color8(218, 91, 76),
			"max_hp": 4.0,
			"speed": 265.0,
			"damage": 16.0,
			"fire_delay": 0.37,
			"shot_speed": 700.0,
			"dash_delay": 0.90,
			"luck": 0.08,
			"trait": "Mark of Violence: dash impact deals weapon damage."
		},
		{
			"id": "seth",
			"name": "SETH",
			"epithet": "The Continuation",
			"description": "Defensive engineer with a regenerating composite shield.",
			"color": Color8(122, 163, 225),
			"max_hp": 5.0,
			"speed": 245.0,
			"damage": 10.0,
			"fire_delay": 0.27,
			"shot_speed": 620.0,
			"dash_delay": 1.25,
			"luck": 0.10,
			"trait": "Second Skin: blocks one hit in every cleared chamber."
		},
		{
			"id": "naamah",
			"name": "NAAMAH",
			"epithet": "The Resonant Genome",
			"description": "Biotechnician whose spores can reclaim life from kills.",
			"color": Color8(195, 132, 210),
			"max_hp": 5.0,
			"speed": 255.0,
			"damage": 9.0,
			"fire_delay": 0.21,
			"shot_speed": 590.0,
			"dash_delay": 1.20,
			"luck": 0.13,
			"trait": "Mycelial Recall: kills have a small chance to restore health."
		}
	]

static func items() -> Dictionary:
	return {
		"seraph_lens": {
			"name": "Seraph Lens",
			"description": "+3 damage; projectiles accelerate.",
			"rarity": "uncommon",
			"color": Color8(242, 207, 104),
			"cost": 18
		},
		"cherub_coil": {
			"name": "Cherub Coil",
			"description": "Faster firing and shorter recoil cycle.",
			"rarity": "common",
			"color": Color8(151, 209, 224),
			"cost": 14
		},
		"bone_orchard": {
			"name": "Bone Orchard",
			"description": "+2 maximum cells and heal 2.",
			"rarity": "common",
			"color": Color8(218, 209, 184),
			"cost": 15
		},
		"cains_mark": {
			"name": "Cain's Mark",
			"description": "Shots pierce one additional body.",
			"rarity": "rare",
			"color": Color8(205, 78, 65),
			"cost": 24
		},
		"salt_genome": {
			"name": "Salt Genome",
			"description": "Adds a parallel projectile with reduced damage.",
			"rarity": "rare",
			"color": Color8(234, 234, 224),
			"cost": 25
		},
		"eden_valve": {
			"name": "Eden Valve",
			"description": "Move faster; dash recharges sooner.",
			"rarity": "common",
			"color": Color8(107, 205, 142),
			"cost": 13
		},
		"black_manna": {
			"name": "Black Manna",
			"description": "Kills may grow a restorative cell.",
			"rarity": "uncommon",
			"color": Color8(100, 85, 127),
			"cost": 20
		},
		"industrial_halo": {
			"name": "Industrial Halo",
			"description": "A rotating shield destroys hostile rounds.",
			"rarity": "rare",
			"color": Color8(224, 153, 72),
			"cost": 26
		},
		"watcher_gland": {
			"name": "Watcher Gland",
			"description": "Critical hits release a secondary shard.",
			"rarity": "uncommon",
			"color": Color8(222, 113, 157),
			"cost": 19
		},
		"nephilim_marrow": {
			"name": "Nephilim Marrow",
			"description": "+30% damage, but slightly slower movement.",
			"rarity": "rare",
			"color": Color8(153, 104, 82),
			"cost": 27
		}
	}

static func enemy_defs() -> Dictionary:
	return {
		"feral": {
			"name": "Preadamic Feral",
			"hp": 24.0,
			"speed": 128.0,
			"radius": 17.0,
			"damage": 1.0,
			"color": Color8(170, 143, 101)
		},
		"outlaw": {
			"name": "Preadamic Outlaw",
			"hp": 30.0,
			"speed": 82.0,
			"radius": 18.0,
			"damage": 1.0,
			"color": Color8(183, 103, 75)
		},
		"nephilim": {
			"name": "Nephilim Husk",
			"hp": 72.0,
			"speed": 71.0,
			"radius": 29.0,
			"damage": 1.5,
			"color": Color8(115, 88, 77)
		},
		"fallen": {
			"name": "Fallen Angel",
			"hp": 52.0,
			"speed": 96.0,
			"radius": 21.0,
			"damage": 1.0,
			"color": Color8(116, 109, 167)
		},
		"boss": {
			"name": "THE WATCHER ENGINE",
			"hp": 430.0,
			"speed": 55.0,
			"radius": 48.0,
			"damage": 2.0,
			"color": Color8(184, 72, 78)
		}
	}

static func lineage_by_id(id: String) -> Dictionary:
	for lineage in lineages():
		if lineage.id == id:
			return lineage
	return lineages()[0]
