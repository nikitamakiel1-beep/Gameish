extends "res://scripts/v8/enemy_genome_director.gd"

const ART3_VERSION: String = "0.6.3-authored"
const HeroIdentityDirectorScript: Script = preload("res://scripts/v8/hero_identity_director.gd")

var _hero_identity: RefCounted = HeroIdentityDirectorScript.new()

# Palette choice remains procedural, but only inside a readable authored family.
const ENEMY_PALETTE_FAMILIES: Dictionary = {
	"feral_scavenger":[0,1], "outlaw_gunner":[0,2], "raider_brute":[0,2],
	"wasteland_hunter":[0,3], "scrap_cultist":[2,3], "caravan_outlaw":[0,1],
	"cherub_drone":[4,5], "fallen_angel":[4,7], "watcher_acolyte":[5,7],
	"halo_sentinel":[4,6], "biomech_pilgrim":[4,5], "ophanim_scout":[5,6],
	"nephilim_husk":[8,10], "nephilim_giant":[8,10], "horned_berserker":[8,9],
	"bone_shepherd":[9,10], "grafted_colossus":[8,11], "serpent_spawn":[9,11],
	"watcher_engine":[12], "first_nephilim":[10], "gate_cherub":[14],
	"tower_enoch":[12], "serpent_interface":[13]
}

const FAMILY_VARIATION: Dictionary = {
	"feral_scavenger":{"head":[0,1],"weapon":[0,2],"pack":[0,1]},
	"outlaw_gunner":{"head":[0,1],"weapon":[3,5],"pack":[1,2]},
	"raider_brute":{"head":[1,2],"weapon":[0,4],"pack":[2,3]},
	"scrap_cultist":{"head":[3,5],"weapon":[1,1],"pack":[0,2]},
	"cherub_drone":{"head":[4,4],"weapon":[0,0],"pack":[0,0]},
	"fallen_angel":{"head":[1,4],"weapon":[0,2],"pack":[0,1]},
	"ophanim_scout":{"head":[4,4],"weapon":[0,0],"pack":[0,0]},
	"nephilim_giant":{"head":[2,3],"weapon":[4,5],"pack":[2,3]},
	"serpent_spawn":{"head":[3,4],"weapon":[0,0],"pack":[0,0]}
}

func _pick_from_pair(rng: RandomNumberGenerator, values: Array, fallback: int) -> int:
	if values.is_empty():
		return fallback
	if values.size() == 1:
		return int(values[0])
	return rng.randi_range(int(values[0]), int(values[1]))

func generate(rng: RandomNumberGenerator, id: String, category: String, role: String, biome_index: int, threat: float, elite: bool = false, boss: bool = false) -> Dictionary:
	var genome: Dictionary = super.generate(rng,id,category,role,biome_index,threat,elite,boss)
	var palettes: Array = ENEMY_PALETTE_FAMILIES.get(id,[])
	if not palettes.is_empty():
		genome["palette_index"] = int(palettes[rng.randi_range(0,palettes.size()-1)])
	var rules: Dictionary = FAMILY_VARIATION.get(id,{})
	if rules.has("head"):
		genome["head_style"] = _pick_from_pair(rng,Array(rules["head"]),int(genome.get("head_style",0)))
	if rules.has("weapon"):
		genome["weapon_style"] = _pick_from_pair(rng,Array(rules["weapon"]),int(genome.get("weapon_style",0)))
	if rules.has("pack"):
		genome["backpack_style"] = _pick_from_pair(rng,Array(rules["pack"]),int(genome.get("backpack_style",0)))
	genome["module_family"] = String(genome.get("silhouette_key",role))
	genome["generation_scope"] = "approved_modules_only"
	genome["palette_family_locked"] = not palettes.is_empty()
	# Keep variation visible but bounded; extreme proportions are a readability failure.
	genome["visual_scale"] = clampf(float(genome.get("visual_scale",1.0)),0.98,1.12 if not boss else 1.32)
	genome["asymmetry"] = clampf(float(genome.get("asymmetry",0.0)),-0.62,0.62)
	return genome

func player_genome(rng: RandomNumberGenerator, lineage_id: String, biome_index: int) -> Dictionary:
	# Deliberately ignore RNG for protagonist identity.
	return _hero_identity.call("canonical",lineage_id,biome_index)

func audit_contract() -> Dictionary:
	var report: Dictionary = super.audit_contract()
	report["art3_version"] = ART3_VERSION
	report["curated_enemy_palette_families"] = ENEMY_PALETTE_FAMILIES.size()
	report["approved_module_generation"] = true
	report["hero_identity_locked"] = true
	report["hero_random_body_variation"] = false
	report["hero_random_palette_variation"] = false
	return report
