extends RefCounted

const VERSION := 7

const EVOLUTIONS := {
	"adam": [
		{"id":"guided_genesis", "name":"GUIDED GENESIS", "summary":"Rifle guidance strengthens.", "homing":0.14},
		{"id":"twin_pattern", "name":"TWIN PATTERN", "summary":"An additional Genesis round is compiled.", "projectiles":1, "weapon_damage_mult":0.90},
		{"id":"repair_doctrine", "name":"REPAIR DOCTRINE", "summary":"Stable tissue capacity expands.", "max_hp":1.0},
		{"id":"seal_runner", "name":"SEAL RUNNER", "summary":"Dash recovery and projectile velocity improve.", "dash_mult":0.86, "shot_speed_mult":1.08},
		{"id":"prime_ammunition", "name":"PRIME AMMUNITION", "summary":"Dense rounds gain damage and penetration.", "weapon_damage_mult":1.16, "pierce":1},
	],
	"abel": [
		{"id":"shepherd_chain", "name":"SHEPHERD CHAIN", "summary":"Light seeks and passes through additional hosts.", "homing":0.08, "pierce":1},
		{"id":"blood_prism", "name":"BLOOD PRISM", "summary":"Critical calibration sharpens the offering.", "luck":0.10, "weapon_damage_mult":1.08},
		{"id":"offering_velocity", "name":"OFFERING VELOCITY", "summary":"Firing and evasive cadence accelerate.", "fire_delay_mult":0.87, "dash_mult":0.90},
		{"id":"halo_splinter", "name":"HALO SPLINTER", "summary":"The beam divides into parallel light.", "projectiles":1, "weapon_damage_mult":0.92},
		{"id":"martyr_reserve", "name":"MARTYR RESERVE", "summary":"A reserve cell and emergency shield are grown.", "max_hp":1.0, "shield":true},
	],
	"cain": [
		{"id":"violence_engine", "name":"VIOLENCE ENGINE", "summary":"Mark Cannon detonation radius and force increase.", "explosion":34.0, "weapon_damage_mult":1.12},
		{"id":"redline", "name":"REDLINE", "summary":"The marked weapon cycles faster under heat.", "fire_delay_mult":0.84},
		{"id":"mark_bore", "name":"MARK BORE", "summary":"Heavy rounds punch through additional bodies.", "pierce":2, "shot_speed_mult":0.90},
		{"id":"blood_rush", "name":"BLOOD RUSH", "summary":"Violence converts into shorter dash recovery.", "dash_mult":0.78, "weapon_damage_mult":1.06},
		{"id":"detonation_halo", "name":"DETONATION HALO", "summary":"A captured industrial orbital joins the Mark.", "orbitals":1},
	],
	"seth": [
		{"id":"continuation_fork", "name":"CONTINUATION FORK", "summary":"The lance forks while retaining penetration.", "projectiles":1, "pierce":1, "weapon_damage_mult":0.93},
		{"id":"bulwark_relay", "name":"BULWARK RELAY", "summary":"Second Skin gains reserve tissue capacity.", "max_hp":1.0, "shield":true},
		{"id":"capacitor_liturgy", "name":"CAPACITOR LITURGY", "summary":"Coil cadence and projectile speed increase.", "fire_delay_mult":0.86, "shot_speed_mult":1.12},
		{"id":"return_circuit", "name":"RETURN CIRCUIT", "summary":"A defensive orbital intercepts hostile fire.", "orbitals":1},
		{"id":"deep_maintenance", "name":"DEEP MAINTENANCE", "summary":"Temporary armor grows and dash systems recover faster.", "fungal_armor":2, "dash_mult":0.90},
	],
	"naamah": [
		{"id":"spore_bloom", "name":"SPORE BLOOM", "summary":"The repeater releases a wider living volley.", "projectiles":2, "weapon_damage_mult":0.88},
		{"id":"mycelial_choir", "name":"MYCELIAL CHOIR", "summary":"Kills can feed the colony and strengthen spores.", "lifesteal":0.05, "spore_power":1.0},
		{"id":"violet_guidance", "name":"VIOLET GUIDANCE", "summary":"Spores track hosts with improved critical sensing.", "homing":0.12, "luck":0.06},
		{"id":"fruiting_armor", "name":"FRUITING ARMOR", "summary":"Fungal plating and tissue capacity expand.", "fungal_armor":2, "max_hp":1.0},
		{"id":"rapid_colony", "name":"RAPID COLONY", "summary":"The colony cycles and ejects spores faster.", "fire_delay_mult":0.84, "shot_speed_mult":1.10},
	],
}

func choices(lineage_id: String, biome: int, run_seed: int, owned: Array) -> Array[Dictionary]:
	var source: Array = Array(EVOLUTIONS.get(lineage_id, EVOLUTIONS["adam"])).duplicate(true)
	var candidates: Array[Dictionary] = []
	for value in source:
		var definition: Dictionary = value
		if String(definition.get("id", "")) not in owned:
			candidates.append(definition)
	if candidates.size() < 2:
		candidates.clear()
		for value in source:
			candidates.append(Dictionary(value))
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = run_seed ^ lineage_id.hash() ^ (biome + 1) * 0x45D9F3B
	var result: Array[Dictionary] = []
	while result.size() < 2 and not candidates.is_empty():
		var index := local_rng.randi_range(0, candidates.size() - 1)
		result.append(candidates[index])
		candidates.remove_at(index)
	return result

func definition(lineage_id: String, id: String) -> Dictionary:
	for value in Array(EVOLUTIONS.get(lineage_id, [])):
		var definition: Dictionary = value
		if String(definition.get("id", "")) == id:
			return definition.duplicate(true)
	return {}

func audit_contract() -> Dictionary:
	var option_count := 0
	for lineage_id in EVOLUTIONS.keys():
		option_count += Array(EVOLUTIONS[lineage_id]).size()
	return {
		"version": VERSION,
		"lineages": EVOLUTIONS.size(),
		"options": option_count,
		"options_per_lineage": 5,
		"deterministic_two_choice": true,
		"run_only": true,
	}
