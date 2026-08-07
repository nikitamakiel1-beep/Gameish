extends RefCounted

const VERSION := "0.6.2-entropy"

const ROLE_TRAITS := {
	"melee": ["ripper", "stalker", "leaper", "bloodrush"],
	"ranged": ["burst", "marksman", "suppression", "scatter"],
	"charger": ["ram", "juggernaut", "shockwave", "breach"],
	"caster": ["ritual", "seeker", "zone", "summoner"],
	"skirmisher": ["blink", "flanker", "feint", "dashshot"],
	"orbiter": ["orbit", "satellite", "spiral", "harrier"],
	"radial": ["nova", "pulse", "minefield", "ring"],
}

const CATEGORY_PALETTES := {
	"preadamic": [0, 1, 2, 3],
	"fallen": [4, 5, 6, 7],
	"nephilim": [8, 9, 10, 11],
	"guardian": [12, 13, 14, 15],
}

func generate(rng: RandomNumberGenerator, id: String, category: String, role: String, biome_index: int, threat: float, elite: bool = false, boss: bool = false) -> Dictionary:
	var mutation_budget := clampf(0.42 + float(biome_index) * 0.10 + maxf(0.0, threat - 1.0) * 0.20 + (0.28 if elite else 0.0) + (0.45 if boss else 0.0), 0.35, 1.55)
	var palette_options: Array = CATEGORY_PALETTES.get(category, CATEGORY_PALETTES["preadamic"])
	var role_traits: Array = ROLE_TRAITS.get(role, ROLE_TRAITS["melee"])
	var visual_scale := rng.randf_range(0.92, 1.10) + (0.10 if elite else 0.0) + (0.35 if boss else 0.0)
	var offense := clampf(rng.randfn(1.0, 0.12) + mutation_budget * rng.randf_range(-0.04, 0.13), 0.82, 1.34)
	var defense := clampf(rng.randfn(1.0, 0.12) + mutation_budget * rng.randf_range(-0.03, 0.15), 0.82, 1.38)
	var mobility := clampf(rng.randfn(1.0, 0.10) + mutation_budget * rng.randf_range(-0.05, 0.12), 0.82, 1.28)
	var accent_count := rng.randi_range(1, 4)
	return {
		"id": id,
		"category": category,
		"role": role,
		"trait": String(role_traits[rng.randi_range(0, role_traits.size() - 1)]),
		"palette_index": int(palette_options[rng.randi_range(0, palette_options.size() - 1)]),
		"body_width": rng.randi_range(12, 20) + (6 if boss else 0),
		"body_height": rng.randi_range(14, 23) + (8 if boss else 0),
		"head_style": rng.randi_range(0, 5),
		"shoulder_style": rng.randi_range(0, 4),
		"weapon_style": rng.randi_range(0, 5),
		"backpack_style": rng.randi_range(0, 3),
		"horns": rng.randi_range(0, 3) if category in ["nephilim", "guardian"] else rng.randi_range(0, 1),
		"eyes": rng.randi_range(1, 4) if category in ["fallen", "nephilim", "guardian"] else rng.randi_range(1, 2),
		"asymmetry": rng.randf_range(-1.0, 1.0),
		"accent_count": accent_count,
		"scar_pattern": rng.randi_range(0, 5),
		"glow": rng.randf_range(0.32, 0.92),
		"visual_scale": visual_scale,
		"hp_mult": defense,
		"speed_mult": mobility,
		"damage_mult": offense,
		"cooldown_mult": clampf(2.0 - offense, 0.72, 1.18),
		"projectile_speed_mult": clampf(0.90 + mobility * 0.10 + rng.randf_range(-0.07, 0.10), 0.84, 1.22),
		"phase_offset": rng.randf_range(0.0, TAU),
		"visual_signature": "%s-%08x" % [id, rng.randi()],
		"boss": boss,
		"elite": elite,
	}

func player_genome(rng: RandomNumberGenerator, lineage_id: String, biome_index: int) -> Dictionary:
	var role := "ranged"
	match lineage_id:
		"abel": role = "caster"
		"cain": role = "ranged"
		"seth": role = "ranged"
		"naamah": role = "caster"
		_: role = "skirmisher"
	var genome := generate(rng, lineage_id, "guardian", role, biome_index, 1.0, false, false)
	genome["lineage"] = lineage_id
	genome["visual_scale"] = rng.randf_range(1.02, 1.12)
	if lineage_id == "cain":
		genome["weapon_style"] = 5
		genome["body_width"] = maxi(16, int(genome["body_width"]))
		genome["palette_index"] = 15
	return genome

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"role_families": ROLE_TRAITS.size(),
		"condition_driven": true,
		"per_instance_visual_genome": true,
		"bounded_stat_mutation": true,
		"fixed_seed_replay": false,
	}
