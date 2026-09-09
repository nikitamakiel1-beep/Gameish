extends RefCounted

const VERSION := 6

const FACTIONS := {
	"salt_caravans": {"name":"SALT CARAVANS", "color":Color8(222, 181, 102)},
	"ash_covenant": {"name":"ASH COVENANT", "color":Color8(198, 105, 71)},
	"tubal_foundries": {"name":"TUBAL FOUNDRIES", "color":Color8(103, 181, 190)},
	"enoch_outlaws": {"name":"ENOCH OUTLAWS", "color":Color8(205, 77, 67)},
	"lamech_houses": {"name":"LAMECH HOUSES", "color":Color8(177, 145, 199)},
	"unnamed": {"name":"THE UNNAMED", "color":Color8(125, 190, 147)},
}

const ROOM_PROGRAMS := {
	0: ["memory", "maintenance"],
	1: ["settlement", "contract"],
	2: ["sacrifice", "maintenance"],
	3: ["memory", "contract"],
	4: ["serpent_terminal", "sacrifice"],
}

const SYNERGY_RULES := {
	"refracted_choir": {
		"name":"REFRACTED CHOIR",
		"requires":["damage", "multishot"],
		"description":"Parallel fire refracts into guided side-beams.",
	},
	"marrow_bore": {
		"name":"MARROW BORE",
		"requires":["pierce", "damage_speed"],
		"description":"Heavy rounds gain penetration and impact force.",
	},
	"halo_capacitor": {
		"name":"HALO CAPACITOR",
		"requires":["shield", "fire_rate"],
		"description":"A timed halo consumes hostile rounds and discharges stored fire.",
	},
	"mycelial_armor": {
		"name":"MYCELIAL ARMOR",
		"requires":["lifesteal", "max_hp"],
		"description":"Healing overflow grows temporary fungal armor.",
	},
	"shepherd_oracle": {
		"name":"SHEPHERD ORACLE",
		"requires":["critical", "luck"],
		"description":"Critical hits emit seeking marked shards.",
	},
	"phase_drive": {
		"name":"PHASE DRIVE",
		"requires":["speed", "dash"],
		"description":"Dash wake damages and staggers nearby hostiles.",
	},
	"spore_circuit": {
		"name":"SPORE CIRCUIT",
		"requires":["spore", "ability"],
		"description":"Ability energy propagates spore status through weapon fire.",
	},
	"watcher_liturgy": {
		"name":"WATCHER LITURGY",
		"requires":["boss_damage", "shot_speed"],
		"description":"Fast projectiles destabilize guardian shielding.",
	},
}

const SERPENT_MUTATIONS := [
	{"id":"forked_aim", "name":"FORKED AIM", "description":"Adds two unstable side projectiles."},
	{"id":"hard_skin", "name":"HARD SKIN", "description":"Adds two temporary armor plates."},
	{"id":"mirror_nerve", "name":"MIRROR NERVE", "description":"Dash wake reflects nearby hostile fire."},
	{"id":"predator_signal", "name":"PREDATOR SIGNAL", "description":"Critical chance rises after consecutive kills."},
]

func room_seed(seed_value: int, coord: Vector2i, biome: int, depth: int, salt: int = 0) -> int:
	var token := "%d:%d:%d:%d:%d:%d" % [seed_value, coord.x, coord.y, biome, depth, salt]
	return hash(token)

func special_room_assignments(room_order: Array[Vector2i], room_graph: Dictionary, biome: int, seed_value: int) -> Dictionary:
	var candidates: Array[Vector2i] = []
	for coord in room_order:
		if not room_graph.has(coord):
			continue
		var room: Dictionary = room_graph[coord]
		if String(room.get("kind", "")) == "combat" and int(room.get("depth", 0)) >= 2:
			candidates.append(coord)
	var result: Dictionary = {}
	var program: Array = ROOM_PROGRAMS.get(biome, [])
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = room_seed(seed_value, Vector2i.ZERO, biome, candidates.size(), 991)
	for kind_variant in program:
		if candidates.is_empty():
			break
		var index := local_rng.randi_range(0, candidates.size() - 1)
		var coord := candidates[index]
		candidates.remove_at(index)
		result[coord] = String(kind_variant)
	return result

func faction_for(biome: int, coord: Vector2i, seed_value: int) -> String:
	var pools := {
		0: ["unnamed", "salt_caravans"],
		1: ["salt_caravans", "ash_covenant", "enoch_outlaws"],
		2: ["tubal_foundries", "ash_covenant", "lamech_houses"],
		3: ["unnamed", "lamech_houses", "salt_caravans"],
		4: ["lamech_houses", "unnamed", "enoch_outlaws"],
	}
	var pool: Array = pools.get(biome, ["unnamed"])
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = room_seed(seed_value, coord, biome, 0, 313)
	return String(pool[local_rng.randi_range(0, pool.size() - 1)])

func synergies_for(inventory: Array, catalog: Dictionary) -> Dictionary:
	var tags: Dictionary = {}
	for id_variant in inventory:
		var id := String(id_variant)
		if not catalog.has(id):
			continue
		var definition: Dictionary = catalog[id]
		var effect := String(definition.get("effect", ""))
		if not effect.is_empty():
			tags[effect] = true
	var active: Dictionary = {}
	for synergy_id in SYNERGY_RULES.keys():
		var rule: Dictionary = SYNERGY_RULES[synergy_id]
		var complete := true
		for required_variant in Array(rule.get("requires", [])):
			if not tags.has(String(required_variant)):
				complete = false
				break
		if complete:
			active[String(synergy_id)] = rule.duplicate(true)
	return active

func serpent_mutation(seed_value: int, lineage_id: String, acquired_count: int) -> Dictionary:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = hash("%d:%s:%d:SERPENT" % [seed_value, lineage_id, acquired_count])
	return Dictionary(SERPENT_MUTATIONS[local_rng.randi_range(0, SERPENT_MUTATIONS.size() - 1)]).duplicate(true)

func faction_definition(id: String) -> Dictionary:
	return Dictionary(FACTIONS.get(id, FACTIONS["unnamed"])).duplicate(true)

func synergy_definition(id: String) -> Dictionary:
	return Dictionary(SYNERGY_RULES.get(id, {})).duplicate(true)

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"factions": FACTIONS.size(),
		"room_programs": ROOM_PROGRAMS.size(),
		"synergies": SYNERGY_RULES.size(),
		"serpent_mutations": SERPENT_MUTATIONS.size(),
		"deterministic_seed": room_seed(12345, Vector2i(2, -3), 4, 7, 9) == room_seed(12345, Vector2i(2, -3), 4, 7, 9),
	}
