extends SceneTree

const WorldScript: Script = preload("res://scripts/v8/procedural_world_director_art4.gd")
const GenomeScript: Script = preload("res://scripts/v8/enemy_genome_director_art4.gd")

const REVISION: String = "0.6.4-authored-art4"
const BIOMES: Array[String] = ["industrial_eden", "ash_wastes", "temple_lab", "fungal_garden", "nephilim_ruins"]
const ENEMIES: Array[Dictionary] = [
	{"id":"feral_scavenger", "category":"preadamic", "role":"melee"},
	{"id":"outlaw_gunner", "category":"preadamic", "role":"ranged"},
	{"id":"raider_brute", "category":"preadamic", "role":"charger"},
	{"id":"wasteland_hunter", "category":"preadamic", "role":"ranged"},
	{"id":"scrap_cultist", "category":"preadamic", "role":"caster"},
	{"id":"caravan_outlaw", "category":"preadamic", "role":"ranged"},
	{"id":"cherub_drone", "category":"fallen", "role":"ranged"},
	{"id":"fallen_angel", "category":"fallen", "role":"skirmisher"},
	{"id":"watcher_acolyte", "category":"fallen", "role":"caster"},
	{"id":"halo_sentinel", "category":"fallen", "role":"charger"},
	{"id":"biomech_pilgrim", "category":"fallen", "role":"ranged"},
	{"id":"ophanim_scout", "category":"fallen", "role":"orbiter"},
	{"id":"nephilim_husk", "category":"nephilim", "role":"melee"},
	{"id":"nephilim_giant", "category":"nephilim", "role":"charger"},
	{"id":"horned_berserker", "category":"nephilim", "role":"charger"},
	{"id":"bone_shepherd", "category":"nephilim", "role":"caster"},
	{"id":"grafted_colossus", "category":"nephilim", "role":"radial"},
	{"id":"serpent_spawn", "category":"nephilim", "role":"skirmisher"},
]

func _fail(errors: Array[String], condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)

func _bucket(value: float, low: float, high: float) -> int:
	if high <= low:
		return 0
	return clampi(int(floor(((value - low) / (high - low)) * 3.0)), 0, 2)

func _world_expressive_range(errors: Array[String]) -> Dictionary:
	var world: RefCounted = WorldScript.new()
	var report: Dictionary = {}
	var all_story: Dictionary = {}
	var all_landmarks: Dictionary = {}
	var all_hazards: Dictionary = {}
	var global_semantic_cells: Dictionary = {}

	for biome_index: int in range(BIOMES.size()):
		var biome: String = BIOMES[biome_index]
		var story: Dictionary = {}
		var landmarks: Dictionary = {}
		var hazards: Dictionary = {}
		var surfaces: Dictionary = {}
		var macro_buckets: Dictionary = {}
		var micro_buckets: Dictionary = {}
		var obstacle_families: Dictionary = {}
		var story_landmark_pairs: Dictionary = {}
		var semantic_cells: Dictionary = {}

		for sample: int in range(64):
			var rng := RandomNumberGenerator.new()
			rng.seed = 810000 + biome_index * 10000 + sample * 977
			var recipe: Dictionary = world.call("make_room_recipe", rng, biome, "combat", 1.35, Vector2(1280, 720))
			var story_id := String(recipe.get("story_beat", ""))
			var landmark_id := String(recipe.get("landmark", ""))
			var hazard_id := String(recipe.get("hazard", ""))
			var surface := int(recipe.get("surface_variant", -1))
			var macro := float(recipe.get("macro_density", -1.0))
			var micro := float(recipe.get("micro_density", -1.0))
			_fail(errors, not story_id.is_empty(), biome + " generated an empty story beat")
			_fail(errors, not landmark_id.is_empty(), biome + " generated an empty landmark")
			_fail(errors, not hazard_id.is_empty(), biome + " generated an empty hazard")
			_fail(errors, surface >= 0 and surface <= 4, biome + " surface variant escaped legal range")
			_fail(errors, macro >= 0.34 and macro <= 0.68, biome + " macro density escaped Art3/Art4 range")
			_fail(errors, micro >= 0.10 and micro <= 0.28, biome + " micro density escaped Art3/Art4 range")

			story[story_id] = true
			landmarks[landmark_id] = true
			hazards[hazard_id] = true
			surfaces[surface] = true
			var macro_bucket := _bucket(macro, 0.34, 0.68)
			var micro_bucket := _bucket(micro, 0.10, 0.28)
			macro_buckets[macro_bucket] = true
			micro_buckets[micro_bucket] = true
			story_landmark_pairs[story_id + "|" + landmark_id] = true
			var semantic := "%s|%s|%s|%d|%d|%d" % [story_id, landmark_id, hazard_id, surface, macro_bucket, micro_bucket]
			semantic_cells[semantic] = true
			global_semantic_cells[biome + "|" + semantic] = true
			all_story[story_id] = biome
			all_landmarks[landmark_id] = biome
			all_hazards[hazard_id] = biome
			for obstacle_variant in Array(recipe.get("obstacle_families", [])):
				obstacle_families[String(obstacle_variant)] = true

		_fail(errors, story.size() == 4, biome + " did not cover all four authored story beats in 64 samples")
		_fail(errors, landmarks.size() == 4, biome + " did not cover all four authored landmarks in 64 samples")
		_fail(errors, hazards.size() >= 3, biome + " hazard expressive range collapsed below three families")
		_fail(errors, surfaces.size() >= 4, biome + " surface expressive range collapsed below four variants")
		_fail(errors, macro_buckets.size() == 3, biome + " macro-density expressive range did not cover three buckets")
		_fail(errors, micro_buckets.size() == 3, biome + " micro-density expressive range did not cover three buckets")
		_fail(errors, obstacle_families.size() >= 4, biome + " obstacle-family expressive range collapsed")
		_fail(errors, story_landmark_pairs.size() >= 10, biome + " story/landmark pair coverage is too narrow")
		_fail(errors, semantic_cells.size() >= 48, biome + " semantic room coverage is too narrow")

		report[biome] = {
			"story_beats": story.size(),
			"landmarks": landmarks.size(),
			"hazards": hazards.size(),
			"surface_variants": surfaces.size(),
			"macro_buckets": macro_buckets.size(),
			"micro_buckets": micro_buckets.size(),
			"obstacle_families": obstacle_families.size(),
			"story_landmark_pairs": story_landmark_pairs.size(),
			"semantic_cells": semantic_cells.size(),
		}

	_fail(errors, all_story.size() == 20, "Story-beat vocabularies are not fully distinct across five biomes")
	_fail(errors, all_landmarks.size() == 20, "Landmark vocabularies are not fully distinct across five biomes")
	_fail(errors, all_hazards.size() >= 18, "Hazard vocabularies overlap/collapse too heavily across biomes")
	_fail(errors, global_semantic_cells.size() >= 240, "Global 320-room expressive range collapsed below 240 semantic cells")
	report["global_semantic_cells"] = global_semantic_cells.size()
	return report

func _enemy_expressive_range(errors: Array[String]) -> Dictionary:
	var genomes: RefCounted = GenomeScript.new()
	var family_anchor_cells: Dictionary = {}
	var global_legal_variants: Dictionary = {}
	var per_family: Dictionary = {}

	for enemy: Dictionary in ENEMIES:
		var id := String(enemy["id"])
		var category := String(enemy["category"])
		var role := String(enemy["role"])
		var anchors: Dictionary = {}
		var variants: Dictionary = {}
		for sample: int in range(24):
			var rng := RandomNumberGenerator.new()
			rng.seed = 920000 + id.hash() * 17 + sample * 811
			var genome: Dictionary = genomes.call("generate", rng, id, category, role, sample % 5, 1.0 + float(sample % 5) * 0.18, sample % 7 == 0, false)
			_fail(errors, bool(genome.get("art4_curated_family", false)), id + " lost Art4 curated-family marker")
			_fail(errors, String(genome.get("generation_scope", "")) == "approved_modules_only", id + " escaped approved-module generation")
			var anchor := "%s|%s|%s|%s" % [
				String(genome.get("motion_profile", "")),
				String(genome.get("material_family", "")),
				String(genome.get("fx_profile", "")),
				String(genome.get("weapon_read", "")),
			]
			anchors[anchor] = true
			var variant := "%d|%d|%d|%d|%.2f" % [
				int(genome.get("palette_index", -1)),
				int(genome.get("head_style", -1)),
				int(genome.get("weapon_style", -1)),
				int(genome.get("backpack_style", -1)),
				float(genome.get("visual_scale", 1.0)),
			]
			variants[variant] = true
			global_legal_variants[id + "|" + variant] = true
		_fail(errors, anchors.size() == 1, id + " family identity anchor changed across RNG samples")
		for anchor_variant in anchors.keys():
			family_anchor_cells[String(anchor_variant)] = id
		_fail(errors, variants.size() >= 2, id + " produced no meaningful legal instance variation")
		per_family[id] = {"anchors": anchors.size(), "legal_variants": variants.size()}

	_fail(errors, family_anchor_cells.size() == ENEMIES.size(), "The 18 enemy families do not retain 18 distinct Art4 identity anchors")
	_fail(errors, global_legal_variants.size() >= 90, "Enemy legal-module expressive range is too narrow across 432 samples")
	return {
		"families": per_family,
		"identity_anchor_cells": family_anchor_cells.size(),
		"legal_variant_cells": global_legal_variants.size(),
	}

func _init() -> void:
	var errors: Array[String] = []
	var report: Dictionary = {
		"revision": REVISION,
		"method": "semantic expressive-range coverage; authored identity fixed, procedural dimensions sampled",
		"world": _world_expressive_range(errors),
		"enemies": _enemy_expressive_range(errors),
	}
	report["errors"] = errors
	report["passed"] = errors.is_empty()
	print("EDEN_FALL_V8_EXPRESSIVE_RANGE_COUNTERAUDIT_REPORT=" + JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V8_EXPRESSIVE_RANGE_COUNTERAUDIT=PASS")
		quit(0)
	else:
		for error: String in errors:
			push_error(error)
		quit(1)
