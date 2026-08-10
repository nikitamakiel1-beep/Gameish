extends RefCounted

const VERSION: String = "0.6.3-authored"

# Heroes are authored identities. These values are intentionally stable across runs.
# Run variation is allowed only in secondary cosmetic/effect fields added elsewhere.
const HEROES: Dictionary = {
	"adam": {
		"category":"lineage", "role":"ranged", "silhouette_key":"lineage_adam",
		"palette_index":1, "body_width":17, "body_height":17, "head_style":0,
		"shoulder_style":1, "weapon_style":3, "backpack_style":1,
		"horns":0, "eyes":1, "asymmetry":-0.18, "accent_count":2,
		"scar_pattern":1, "glow":0.44, "visual_scale":1.04,
		"weapon_identity":"genesis_rifle", "identity_palette":"eden_green_gold"
	},
	"abel": {
		"category":"lineage", "role":"caster", "silhouette_key":"lineage_abel",
		"palette_index":14, "body_width":15, "body_height":18, "head_style":0,
		"shoulder_style":0, "weapon_style":1, "backpack_style":0,
		"horns":0, "eyes":1, "asymmetry":0.10, "accent_count":2,
		"scar_pattern":0, "glow":0.72, "visual_scale":1.04,
		"weapon_identity":"tithe_focus", "identity_palette":"ivory_gold"
	},
	"cain": {
		"category":"lineage", "role":"ranged", "silhouette_key":"lineage_cain",
		"palette_index":15, "body_width":19, "body_height":17, "head_style":1,
		"shoulder_style":3, "weapon_style":5, "backpack_style":3,
		"horns":0, "eyes":1, "asymmetry":0.22, "accent_count":3,
		"scar_pattern":4, "glow":0.62, "visual_scale":1.07,
		"weapon_identity":"mark_cannon", "identity_palette":"mark_red_black"
	},
	"seth": {
		"category":"lineage", "role":"ranged", "silhouette_key":"lineage_seth",
		"palette_index":11, "body_width":17, "body_height":18, "head_style":1,
		"shoulder_style":2, "weapon_style":3, "backpack_style":3,
		"horns":0, "eyes":1, "asymmetry":-0.12, "accent_count":2,
		"scar_pattern":2, "glow":0.58, "visual_scale":1.05,
		"weapon_identity":"watcher_carbine", "identity_palette":"guardian_blue_steel"
	},
	"naamah": {
		"category":"lineage", "role":"caster", "silhouette_key":"lineage_naamah",
		"palette_index":13, "body_width":15, "body_height":18, "head_style":3,
		"shoulder_style":0, "weapon_style":1, "backpack_style":1,
		"horns":0, "eyes":2, "asymmetry":0.16, "accent_count":4,
		"scar_pattern":5, "glow":0.78, "visual_scale":1.04,
		"weapon_identity":"spore_repeater", "identity_palette":"mycelial_violet"
	}
}

func canonical(lineage_id: String, biome_index: int = 0) -> Dictionary:
	var id: String = lineage_id.to_lower()
	var source: Dictionary = HEROES.get(id, HEROES["adam"])
	var genome: Dictionary = source.duplicate(true)
	genome["id"] = id
	genome["lineage"] = id
	genome["trait"] = "canonical_lineage"
	genome["hero_identity_locked"] = true
	genome["visual_signature"] = "hero:%s:canonical-v1" % id
	genome["identity_signature"] = "EDEN-HERO-%s-V1" % id.to_upper()
	genome["hp_mult"] = 1.0
	genome["speed_mult"] = 1.0
	genome["damage_mult"] = 1.0
	genome["cooldown_mult"] = 1.0
	genome["projectile_speed_mult"] = 1.0
	genome["phase_offset"] = 0.0
	genome["boss"] = false
	genome["elite"] = false
	# Biome exposure can change FX/dirt overlays, never identity geometry.
	genome["biome_wear_stage"] = clampi(biome_index, 0, 4)
	return genome

func audit_contract() -> Dictionary:
	var signatures: Dictionary = {}
	var weapons: Dictionary = {}
	for id_variant in HEROES.keys():
		var id: String = String(id_variant)
		var genome: Dictionary = canonical(id)
		signatures[String(genome["identity_signature"])] = true
		weapons[String(genome["weapon_identity"])] = true
	return {
		"version":VERSION,
		"hero_count":HEROES.size(),
		"identity_locked":true,
		"unique_identity_signatures":signatures.size(),
		"unique_weapon_identities":weapons.size(),
		"procedural_body_variation":false,
		"procedural_palette_variation":false,
		"procedural_weapon_class_variation":false
	}
