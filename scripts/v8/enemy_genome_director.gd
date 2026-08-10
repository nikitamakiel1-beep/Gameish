extends RefCounted

const VERSION: String = "0.6.2-entropy-art2"

const ROLE_TRAITS: Dictionary = {
	"melee": ["ripper", "stalker", "leaper", "bloodrush"],
	"ranged": ["burst", "marksman", "suppression", "scatter"],
	"charger": ["ram", "juggernaut", "shockwave", "breach"],
	"caster": ["ritual", "seeker", "zone", "summoner"],
	"skirmisher": ["blink", "flanker", "feint", "dashshot"],
	"orbiter": ["orbit", "satellite", "spiral", "harrier"],
	"radial": ["nova", "pulse", "minefield", "ring"],
}

const CATEGORY_PALETTES: Dictionary = {
	"preadamic": [0, 1, 2, 3],
	"fallen": [4, 5, 6, 7],
	"nephilim": [8, 9, 10, 11],
	"guardian": [12, 13, 14, 15],
}

# Strong authored silhouettes first; stochastic variation happens inside each profile.
const ART_PROFILES: Dictionary = {
	"feral_scavenger": {"silhouette":"feral_runner","body":[14,17,16,19],"head":[0,5],"shoulder":[0,1],"weapon":[0,2],"pack":[0,1]},
	"outlaw_gunner": {"silhouette":"dust_gunner","body":[16,19,16,20],"head":[0,1],"shoulder":[1,2],"weapon":[3,5],"pack":[1,3]},
	"raider_brute": {"silhouette":"scrap_brute","body":[21,25,17,21],"head":[1,2],"shoulder":[3,4],"weapon":[0,4],"pack":[2,3]},
	"wasteland_hunter": {"silhouette":"longcoat_hunter","body":[15,18,18,22],"head":[0,5],"shoulder":[0,2],"weapon":[3,5],"pack":[1,2]},
	"scrap_cultist": {"silhouette":"mask_caster","body":[14,17,19,23],"head":[3,5],"shoulder":[0,1],"weapon":[1,1],"pack":[0,2]},
	"caravan_outlaw": {"silhouette":"dual_skirmisher","body":[14,17,17,20],"head":[0,1],"shoulder":[0,2],"weapon":[2,4],"pack":[1,2]},
	"cherub_drone": {"silhouette":"cherub_drone","body":[14,17,14,17],"head":[4,4],"shoulder":[0,1],"weapon":[0,0],"pack":[0,0]},
	"fallen_angel": {"silhouette":"fallen_blade","body":[17,20,18,22],"head":[1,4],"shoulder":[2,3],"weapon":[0,2],"pack":[0,1]},
	"watcher_acolyte": {"silhouette":"watcher_acolyte","body":[15,18,19,23],"head":[3,4],"shoulder":[0,1],"weapon":[1,1],"pack":[0,2]},
	"halo_sentinel": {"silhouette":"halo_tank","body":[22,26,18,22],"head":[1,4],"shoulder":[3,4],"weapon":[4,5],"pack":[2,3]},
	"biomech_pilgrim": {"silhouette":"pilgrim_gunner","body":[18,21,18,22],"head":[1,5],"shoulder":[1,3],"weapon":[3,5],"pack":[2,3]},
	"ophanim_scout": {"silhouette":"ophanim_wheel","body":[14,17,14,17],"head":[4,4],"shoulder":[0,0],"weapon":[0,0],"pack":[0,0]},
	"nephilim_husk": {"silhouette":"husk_mauler","body":[20,24,19,23],"head":[2,3],"shoulder":[2,4],"weapon":[0,4],"pack":[0,2]},
	"nephilim_giant": {"silhouette":"giant_ram","body":[24,29,20,25],"head":[2,3],"shoulder":[3,4],"weapon":[4,5],"pack":[2,3]},
	"horned_berserker": {"silhouette":"horned_runner","body":[18,22,18,22],"head":[2,3],"shoulder":[2,4],"weapon":[0,2],"pack":[0,2]},
	"bone_shepherd": {"silhouette":"bone_caster","body":[16,19,20,24],"head":[2,3],"shoulder":[1,2],"weapon":[1,1],"pack":[0,2]},
	"grafted_colossus": {"silhouette":"colossus_core","body":[25,30,22,27],"head":[3,4],"shoulder":[3,4],"weapon":[4,5],"pack":[2,3]},
	"serpent_spawn": {"silhouette":"serpent_orbiter","body":[15,18,15,18],"head":[3,4],"shoulder":[0,1],"weapon":[0,0],"pack":[0,0]},
	"watcher_engine": {"silhouette":"boss_watcher","body":[27,31,24,29],"head":[4,4],"shoulder":[4,4],"weapon":[5,5],"pack":[3,3]},
	"first_nephilim": {"silhouette":"boss_nephilim","body":[28,33,25,30],"head":[2,3],"shoulder":[4,4],"weapon":[0,4],"pack":[2,3]},
	"gate_cherub": {"silhouette":"boss_cherub","body":[24,29,23,28],"head":[4,4],"shoulder":[3,4],"weapon":[1,5],"pack":[2,3]},
	"tower_enoch": {"silhouette":"boss_tower","body":[26,31,27,33],"head":[1,4],"shoulder":[3,4],"weapon":[5,5],"pack":[3,3]},
	"serpent_interface": {"silhouette":"boss_serpent","body":[24,29,23,29],"head":[3,4],"shoulder":[1,3],"weapon":[1,4],"pack":[2,3]},
	"adam": {"silhouette":"lineage_adam","body":[17,19,18,21],"head":[0,1],"shoulder":[1,2],"weapon":[2,3],"pack":[1,2]},
	"abel": {"silhouette":"lineage_abel","body":[15,18,19,22],"head":[0,4],"shoulder":[0,1],"weapon":[1,1],"pack":[0,1]},
	"cain": {"silhouette":"lineage_cain","body":[18,21,18,21],"head":[1,3],"shoulder":[2,4],"weapon":[5,5],"pack":[2,3]},
	"seth": {"silhouette":"lineage_seth","body":[18,21,18,22],"head":[1,4],"shoulder":[2,3],"weapon":[3,5],"pack":[2,3]},
	"naamah": {"silhouette":"lineage_naamah","body":[15,18,19,23],"head":[3,5],"shoulder":[0,2],"weapon":[1,2],"pack":[0,2]},
}

func _profile_for(id: String, role: String) -> Dictionary:
	if ART_PROFILES.has(id):
		return Dictionary(ART_PROFILES[id])
	match role:
		"charger": return {"silhouette":"role_charger","body":[21,25,17,21],"head":[1,3],"shoulder":[3,4],"weapon":[4,5],"pack":[1,3]}
		"caster": return {"silhouette":"role_caster","body":[14,17,19,23],"head":[3,5],"shoulder":[0,2],"weapon":[1,1],"pack":[0,2]}
		"skirmisher": return {"silhouette":"role_skirmisher","body":[14,17,17,20],"head":[0,2],"shoulder":[0,2],"weapon":[2,4],"pack":[0,2]}
		"ranged": return {"silhouette":"role_ranged","body":[16,19,17,21],"head":[0,2],"shoulder":[1,3],"weapon":[3,5],"pack":[1,3]}
		"orbiter": return {"silhouette":"role_orbiter","body":[14,18,14,18],"head":[4,4],"shoulder":[0,1],"weapon":[0,0],"pack":[0,0]}
		"radial": return {"silhouette":"role_radial","body":[20,25,18,23],"head":[4,4],"shoulder":[2,4],"weapon":[4,5],"pack":[2,3]}
		_: return {"silhouette":"role_melee","body":[17,21,17,21],"head":[0,3],"shoulder":[1,3],"weapon":[0,2],"pack":[0,2]}

func _pick_int(rng: RandomNumberGenerator, values: Array, start_index: int, end_index: int) -> int:
	return rng.randi_range(int(values[start_index]), int(values[end_index]))

func generate(rng: RandomNumberGenerator, id: String, category: String, role: String, biome_index: int, threat: float, elite: bool = false, boss: bool = false) -> Dictionary:
	var mutation_budget: float = clampf(0.42 + float(biome_index) * 0.10 + maxf(0.0, threat - 1.0) * 0.20 + (0.28 if elite else 0.0) + (0.45 if boss else 0.0), 0.35, 1.55)
	var palette_options: Array = CATEGORY_PALETTES.get(category, CATEGORY_PALETTES["preadamic"])
	var role_traits: Array = ROLE_TRAITS.get(role, ROLE_TRAITS["melee"])
	var profile: Dictionary = _profile_for(id, role)
	var body: Array = profile.get("body", [16,20,17,21])
	var heads: Array = profile.get("head", [0,3])
	var shoulders: Array = profile.get("shoulder", [0,3])
	var weapons: Array = profile.get("weapon", [0,5])
	var packs: Array = profile.get("pack", [0,3])
	var visual_scale: float = rng.randf_range(0.97, 1.07) + (0.08 if elite else 0.0) + (0.24 if boss else 0.0)
	var offense: float = clampf(rng.randfn(1.0, 0.10) + mutation_budget * rng.randf_range(-0.04, 0.10), 0.84, 1.30)
	var defense: float = clampf(rng.randfn(1.0, 0.10) + mutation_budget * rng.randf_range(-0.03, 0.12), 0.84, 1.34)
	var mobility: float = clampf(rng.randfn(1.0, 0.09) + mutation_budget * rng.randf_range(-0.05, 0.10), 0.84, 1.24)
	var accent_count: int = rng.randi_range(1, 4)
	return {
		"id": id,
		"category": category,
		"role": role,
		"silhouette_key": String(profile.get("silhouette", role)),
		"trait": String(role_traits[rng.randi_range(0, role_traits.size() - 1)]),
		"palette_index": int(palette_options[rng.randi_range(0, palette_options.size() - 1)]),
		"body_width": _pick_int(rng, body, 0, 1),
		"body_height": _pick_int(rng, body, 2, 3),
		"head_style": _pick_int(rng, heads, 0, 1),
		"shoulder_style": _pick_int(rng, shoulders, 0, 1),
		"weapon_style": _pick_int(rng, weapons, 0, 1),
		"backpack_style": _pick_int(rng, packs, 0, 1),
		"horns": rng.randi_range(1, 3) if category == "nephilim" else (rng.randi_range(0, 2) if category == "guardian" else 0),
		"eyes": rng.randi_range(2, 4) if category in ["fallen", "nephilim", "guardian"] else rng.randi_range(1, 2),
		"asymmetry": rng.randf_range(-1.0, 1.0),
		"accent_count": accent_count,
		"scar_pattern": rng.randi_range(0, 7),
		"glow": rng.randf_range(0.38, 0.92),
		"visual_scale": visual_scale,
		"hp_mult": defense,
		"speed_mult": mobility,
		"damage_mult": offense,
		"cooldown_mult": clampf(2.0 - offense, 0.74, 1.16),
		"projectile_speed_mult": clampf(0.90 + mobility * 0.10 + rng.randf_range(-0.06, 0.09), 0.86, 1.20),
		"phase_offset": rng.randf_range(0.0, TAU),
		"visual_signature": "%s-%08x" % [id, rng.randi()],
		"boss": boss,
		"elite": elite,
	}

func player_genome(rng: RandomNumberGenerator, lineage_id: String, biome_index: int) -> Dictionary:
	var role: String = "ranged"
	match lineage_id:
		"abel": role = "caster"
		"cain": role = "ranged"
		"seth": role = "ranged"
		"naamah": role = "caster"
		_: role = "skirmisher"
	var genome: Dictionary = generate(rng, lineage_id, "guardian", role, biome_index, 1.0, false, false)
	genome["lineage"] = lineage_id
	genome["visual_scale"] = rng.randf_range(1.04, 1.10)
	if lineage_id == "cain":
		genome["weapon_style"] = 5
		genome["body_width"] = maxi(19, int(genome["body_width"]))
		genome["palette_index"] = 15
	return genome

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"role_families": ROLE_TRAITS.size(),
		"authored_profiles": ART_PROFILES.size(),
		"condition_driven": true,
		"per_instance_visual_genome": true,
		"bounded_stat_mutation": true,
		"authored_silhouette_grammar": true,
		"fixed_seed_replay": false,
	}
