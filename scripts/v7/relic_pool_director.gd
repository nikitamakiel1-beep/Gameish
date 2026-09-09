extends RefCounted

const VERSION := 7

const CONTEXT_EFFECTS := {
	"shop": ["damage", "fire_rate", "speed", "dash", "max_hp", "armor", "shield", "luck", "critical", "shot_speed"],
	"treasure": ["damage", "fire_rate", "pierce", "multishot", "critical", "dash", "ability", "boss_damage"],
	"trial": ["damage", "pierce", "multishot", "critical", "damage_speed", "boss_damage"],
	"contract": ["damage", "fire_rate", "pierce", "dash", "critical", "boss_damage"],
	"sanctuary": ["max_hp", "healing", "armor", "shield", "speed", "dash"],
	"special": ["ability", "luck", "critical", "spore", "shot_speed", "shield"],
}

func pick(catalog: Dictionary, unlocked_tier: int, excluded: Array, context: String, roll_seed: int) -> String:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = roll_seed
	var allowed_effects: Array = CONTEXT_EFFECTS.get(context, [])
	var preferred: Array[String] = []
	var fallback: Array[String] = []
	for id_variant in catalog.keys():
		var id := String(id_variant)
		if id in excluded:
			continue
		var definition: Dictionary = catalog[id]
		if int(definition.get("tier", 1)) > unlocked_tier:
			continue
		fallback.append(id)
		var effect := String(definition.get("effect", "ability"))
		if effect in allowed_effects:
			preferred.append(id)
	var candidates: Array[String] = preferred if not preferred.is_empty() and local_rng.randf() < 0.78 else fallback
	if candidates.is_empty():
		return ""
	return candidates[local_rng.randi_range(0, candidates.size() - 1)]

func context_for_room(room_kind: String) -> String:
	match room_kind:
		"shop": return "shop"
		"treasure": return "treasure"
		"trial": return "trial"
		"contract": return "contract"
		"sanctuary": return "sanctuary"
		"settlement", "sacrifice", "memory", "maintenance", "serpent_terminal": return "special"
		_: return "treasure"

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"contexts": CONTEXT_EFFECTS.size(),
		"contextual_pools": true,
		"duplicate_exclusion": true,
		"tier_gating": true,
	}
