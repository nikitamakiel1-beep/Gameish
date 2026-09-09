extends "res://scripts/v8/enemy_genome_director_art3.gd"

const ART4_GENOME_VERSION: String = "0.6.4-authored-art4"

const FAMILY_DIRECTION: Dictionary = {
	"feral_scavenger":{"motion":"skitter","material":"rag_bone","fx":"dust","weapon_read":"claw_short"},
	"outlaw_gunner":{"motion":"braced_stride","material":"scrap_leather","fx":"muzzle_amber","weapon_read":"long_rifle"},
	"raider_brute":{"motion":"heavy_lurch","material":"plate_scrap","fx":"impact_dust","weapon_read":"cleaver_mass"},
	"wasteland_hunter":{"motion":"low_stalk","material":"dust_cloth","fx":"tracer_amber","weapon_read":"marksman_long"},
	"scrap_cultist":{"motion":"ritual_float","material":"ritual_cloth","fx":"ritual_red","weapon_read":"focus_staff"},
	"caravan_outlaw":{"motion":"side_step","material":"road_leather","fx":"dual_flash","weapon_read":"dual_short"},
	"cherub_drone":{"motion":"wing_hover","material":"ivory_machine","fx":"halo_gold","weapon_read":"orb_shot"},
	"fallen_angel":{"motion":"broken_glide","material":"fallen_plate","fx":"cold_halo","weapon_read":"blade_arc"},
	"watcher_acolyte":{"motion":"ritual_float","material":"watcher_cloth","fx":"watcher_cyan","weapon_read":"focus_staff"},
	"halo_sentinel":{"motion":"shield_march","material":"ivory_plate","fx":"halo_gold","weapon_read":"tower_shield"},
	"biomech_pilgrim":{"motion":"servo_stride","material":"ivory_biomech","fx":"servo_gold","weapon_read":"pilgrim_rifle"},
	"ophanim_scout":{"motion":"wheel_orbit","material":"watcher_ring","fx":"watcher_cyan","weapon_read":"radial_eye"},
	"nephilim_husk":{"motion":"broken_charge","material":"bone_flesh","fx":"void_violet","weapon_read":"maul_limbs"},
	"nephilim_giant":{"motion":"colossal_step","material":"bone_plate","fx":"ground_shock","weapon_read":"massive_ram"},
	"horned_berserker":{"motion":"blood_sprint","material":"bone_hide","fx":"blood_red","weapon_read":"horn_melee"},
	"bone_shepherd":{"motion":"ritual_drag","material":"bone_cloth","fx":"bone_violet","weapon_read":"bone_staff"},
	"grafted_colossus":{"motion":"colossal_step","material":"grafted_plate","fx":"void_violet","weapon_read":"colossus_mass"},
	"serpent_spawn":{"motion":"serpent_sway","material":"mycelial_hide","fx":"spore_violet","weapon_read":"body_weapon"},
}

const HERO_MOTION: Dictionary = {
	"adam":"rifle_stride",
	"abel":"light_float",
	"cain":"heavy_brace",
	"seth":"engineer_step",
	"naamah":"mycelial_sway",
}

func generate(rng: RandomNumberGenerator, id: String, category: String, role: String, biome_index: int, threat: float, elite: bool = false, boss: bool = false) -> Dictionary:
	var genome: Dictionary = super.generate(rng, id, category, role, biome_index, threat, elite, boss)
	var direction: Dictionary = FAMILY_DIRECTION.get(id, {})
	if not direction.is_empty():
		genome["motion_profile"] = String(direction.get("motion", role))
		genome["material_family"] = String(direction.get("material", category))
		genome["fx_profile"] = String(direction.get("fx", "neutral"))
		genome["weapon_read"] = String(direction.get("weapon_read", role))
	else:
		genome["motion_profile"] = role
		genome["material_family"] = category
		genome["fx_profile"] = "neutral"
		genome["weapon_read"] = role
	genome["silhouette_anchor"] = String(genome.get("silhouette_key", role))
	genome["art4_curated_family"] = true
	# Elites may intensify a legal profile but never replace it.
	genome["fx_intensity"] = clampf(float(genome.get("glow", 0.5)) + (0.18 if elite else 0.0), 0.28, 1.0)
	return genome

func player_genome(rng: RandomNumberGenerator, lineage_id: String, biome_index: int) -> Dictionary:
	var genome: Dictionary = super.player_genome(rng, lineage_id, biome_index)
	genome["motion_profile"] = String(HERO_MOTION.get(lineage_id, "hero_stride"))
	genome["material_family"] = String(genome.get("identity_palette", "canonical"))
	genome["fx_profile"] = lineage_id
	genome["weapon_read"] = String(genome.get("weapon_identity", "canonical_weapon"))
	genome["art4_curated_family"] = true
	return genome

func audit_contract() -> Dictionary:
	var report: Dictionary = super.audit_contract()
	report["art4_genome_version"] = ART4_GENOME_VERSION
	report["curated_motion_families"] = FAMILY_DIRECTION.size()
	report["canonical_hero_motion_profiles"] = HERO_MOTION.size()
	report["material_family_constraints"] = true
	report["fx_family_constraints"] = true
	report["weapon_read_constraints"] = true
	report["identity_replacement_by_rng"] = false
	return report
