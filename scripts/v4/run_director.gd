extends RefCounted

const VERSION := 4

const MODIFIERS := {
	"none": {"name":"STABLE CHAMBER","description":"No environmental distortion.","reward":1.0},
	"overclocked": {"name":"OVERCLOCKED","description":"Enemies move and attack faster.","reward":1.18},
	"blackout": {"name":"BLACKOUT","description":"Visibility contracts around the lineage.","reward":1.14},
	"corrosive_grid": {"name":"CORROSIVE GRID","description":"Hazard pulses cross the chamber.","reward":1.22},
	"regenerative": {"name":"REGENERATIVE HOSTS","description":"Hostiles slowly restore tissue.","reward":1.20},
	"bullet_storm": {"name":"WATCHER CROSS-FIRE","description":"The chamber periodically emits projectiles.","reward":1.25},
	"fragile_protocol": {"name":"FRAGILE PROTOCOL","description":"Damage rises for both sides.","reward":1.28},
	"elite_hunt": {"name":"ELITE HUNT","description":"At least one enhanced hostile is present.","reward":1.24},
}

const ELITE_AFFIXES := {
	"swift": {"name":"SWIFT","color":Color8(105,194,233),"hp":1.10,"speed":1.38,"damage":1.05},
	"armored": {"name":"ARMORED","color":Color8(201,184,126),"hp":1.35,"speed":0.92,"damage":1.08},
	"volatile": {"name":"VOLATILE","color":Color8(236,105,65),"hp":1.12,"speed":1.08,"damage":1.15},
	"vampiric": {"name":"VAMPIRIC","color":Color8(207,76,124),"hp":1.22,"speed":1.04,"damage":1.10},
	"corrosive": {"name":"CORROSIVE","color":Color8(119,205,102),"hp":1.16,"speed":1.02,"damage":1.16},
	"shielded": {"name":"SHIELDED","color":Color8(121,158,239),"hp":1.18,"speed":0.98,"damage":1.08},
}

const WEAPONS := {
	"adam": {
		"id":"genesis_rifle","name":"GENESIS RIFLE","description":"Stable rifle with adaptive guidance.",
		"pattern":"rifle","projectiles":1,"spread":0.0,"damage":1.0,"speed":1.0,"pierce":0,"homing":0.11,"explosion":0.0,"status":"none",
	},
	"abel": {
		"id":"shepherd_beam","name":"SHEPHERD BEAM","description":"Fast precision beam that chains through marked targets.",
		"pattern":"beam","projectiles":1,"spread":0.0,"damage":0.88,"speed":1.35,"pierce":1,"homing":0.04,"explosion":0.0,"status":"marked",
	},
	"cain": {
		"id":"mark_cannon","name":"MARK CANNON","description":"Heavy explosive ordnance carrying the mark.",
		"pattern":"cannon","projectiles":1,"spread":0.0,"damage":1.52,"speed":0.72,"pierce":0,"homing":0.0,"explosion":82.0,"status":"burn",
	},
	"seth": {
		"id":"continuation_lance","name":"CONTINUATION LANCE","description":"Defensive piercing lance that rewards controlled fire.",
		"pattern":"lance","projectiles":1,"spread":0.0,"damage":1.08,"speed":1.16,"pierce":3,"homing":0.0,"explosion":0.0,"status":"stagger",
	},
	"naamah": {
		"id":"spore_repeater","name":"SPORE REPEATER","description":"Three-spore spread that slows and infects.",
		"pattern":"spread","projectiles":3,"spread":0.18,"damage":0.62,"speed":0.86,"pierce":0,"homing":0.07,"explosion":0.0,"status":"spore",
	},
}

const MASTERY_THRESHOLDS := [0, 180, 520, 1100, 2100, 3600, 5600, 8200]
const MASTERY_NAMES := ["DORMANT", "AWAKENED", "CALIBRATED", "ASCENDANT", "SERAPHIC", "EDENIC", "ARCHITECT", "TRANSCENDENT"]

var rng := RandomNumberGenerator.new()
var configured_seed := 0
var challenge_mode := "standard"

func configure(seed_value: int, mode: String = "standard") -> void:
	configured_seed = seed_value
	challenge_mode = mode
	rng.seed = seed_value ^ 0x6E64656E

func daily_seed(year: int, day_of_year: int) -> int:
	var value := year * 1000 + day_of_year
	value = int((value * 1103515245 + 12345) & 0x7FFFFFFF)
	return value ^ 0x4544454E

func threat_level(biome: int, rooms_cleared: int, floor_number: int, mode: String = "standard") -> float:
	var threat := 1.0 + float(biome) * 0.24 + float(rooms_cleared) * 0.027 + float(maxi(0, floor_number - 1)) * 0.09
	match mode:
		"daily": threat += 0.24
		"training": threat *= 0.72
		"ascension": threat += 0.42
	return clampf(threat, 0.65, 3.25)

func encounter_budget(biome: int, depth: int, rooms_cleared: int, mode: String = "standard") -> int:
	var threat := threat_level(biome, rooms_cleared, biome + 1, mode)
	return clampi(int(round(4.0 + float(depth) * 0.72 + float(biome) * 1.4 + threat * 1.6)), 4, 18)

func room_modifier(coord: Vector2i, kind: String, depth: int, biome: int) -> String:
	if kind not in ["combat", "trial"]:
		return "none"
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = configured_seed ^ (coord.x * 73856093) ^ (coord.y * 19349663) ^ (depth * 83492791) ^ (biome * 2654435761)
	var chance := 0.28 + float(biome) * 0.055 + (0.12 if challenge_mode == "daily" else 0.0)
	if local_rng.randf() > chance:
		return "none"
	var ids := MODIFIERS.keys()
	ids.erase("none")
	return String(ids[local_rng.randi_range(0, ids.size() - 1)])

func elite_affix(threat: float, forced: bool = false) -> String:
	var chance := clampf(0.06 + (threat - 1.0) * 0.12, 0.05, 0.42)
	if not forced and rng.randf() > chance:
		return ""
	var ids := ELITE_AFFIXES.keys()
	return String(ids[rng.randi_range(0, ids.size() - 1)])

func modifier_reward(id: String) -> float:
	return float(Dictionary(MODIFIERS.get(id, MODIFIERS["none"])).get("reward", 1.0))

func weapon_for(lineage_id: String) -> Dictionary:
	return Dictionary(WEAPONS.get(lineage_id, WEAPONS["adam"])).duplicate(true)

func elite_definition(affix: String) -> Dictionary:
	return Dictionary(ELITE_AFFIXES.get(affix, {})).duplicate(true)

func mastery_rank(points: int) -> int:
	var rank := 0
	for i in range(MASTERY_THRESHOLDS.size()):
		if points >= int(MASTERY_THRESHOLDS[i]):
			rank = i
	return rank

func mastery_name(points: int) -> String:
	return String(MASTERY_NAMES[mastery_rank(points)])

func mastery_progress(points: int) -> float:
	var rank := mastery_rank(points)
	if rank >= MASTERY_THRESHOLDS.size() - 1:
		return 1.0
	var low := int(MASTERY_THRESHOLDS[rank])
	var high := int(MASTERY_THRESHOLDS[rank + 1])
	return clampf(float(points - low) / float(high - low), 0.0, 1.0)

func score_for_kill(max_hp: float, elite: bool, boss: bool, combo: int, modifier: String) -> int:
	var score := int(round(max_hp * 2.0))
	if elite:
		score = int(round(float(score) * 2.2))
	if boss:
		score = int(round(float(score) * 5.0))
	score = int(round(float(score) * (1.0 + minf(1.5, float(combo) * 0.055))))
	score = int(round(float(score) * modifier_reward(modifier)))
	return maxi(1, score)

func room_specials(room_order: Array[Vector2i], room_graph: Dictionary, biome: int) -> Dictionary:
	var result := {"trial":Vector2i(999,999), "sanctuary":Vector2i(999,999)}
	var candidates: Array[Vector2i] = []
	for coord in room_order:
		var room: Dictionary = room_graph[coord]
		if String(room.get("kind", "")) == "combat" and int(room.get("depth", 0)) >= 2:
			candidates.append(coord)
	if candidates.size() >= 2:
		candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return int(room_graph[a]["depth"]) > int(room_graph[b]["depth"]))
		result["trial"] = candidates[0]
		result["sanctuary"] = candidates[candidates.size() - 1]
	elif candidates.size() == 1:
		result["trial"] = candidates[0]
	if biome == 0 and result["sanctuary"] == Vector2i(999,999) and not candidates.is_empty():
		result["sanctuary"] = candidates.back()
	return result

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"modifiers": MODIFIERS.size(),
		"elite_affixes": ELITE_AFFIXES.size(),
		"weapons": WEAPONS.size(),
		"mastery_ranks": MASTERY_NAMES.size(),
		"daily_seed_stable": daily_seed(2026, 215) == daily_seed(2026, 215),
	}
