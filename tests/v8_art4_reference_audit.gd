extends SceneTree

const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const ForgeScript: Script = preload("res://scripts/v8/procedural_sprite_forge_art4.gd")
const GenomeScript: Script = preload("res://scripts/v8/enemy_genome_director_art4.gd")
const WorldScript: Script = preload("res://scripts/v8/procedural_world_director_art4.gd")
const HeroScript: Script = preload("res://scripts/v8/hero_identity_director.gd")

const LINEAGES: Array[String] = ["adam", "abel", "cain", "seth", "naamah"]
const BIOMES: Array[String] = ["industrial_eden", "ash_wastes", "temple_lab", "fungal_garden", "nephilim_ruins"]
const ENEMY_SAMPLES: Array[Dictionary] = [
	{"id":"feral_scavenger", "category":"preadamic", "role":"melee"},
	{"id":"outlaw_gunner", "category":"preadamic", "role":"ranged"},
	{"id":"raider_brute", "category":"preadamic", "role":"charger"},
	{"id":"scrap_cultist", "category":"preadamic", "role":"caster"},
	{"id":"caravan_outlaw", "category":"preadamic", "role":"skirmisher"},
	{"id":"cherub_drone", "category":"fallen", "role":"orbiter"},
	{"id":"grafted_colossus", "category":"nephilim", "role":"radial"},
]

func _frame_hashes(sheet: Image, frame_size: int, direction_index: int) -> Dictionary:
	var hashes: Dictionary = {}
	for frame_index: int in range(4):
		var region: Image = sheet.get_region(Rect2i(frame_index * frame_size, direction_index * frame_size, frame_size, frame_size))
		hashes[hash(region.get_data())] = true
	return hashes

func _init() -> void:
	var errors: Array[String] = []
	var engine: Dictionary = BootstrapScript.new().call("configure")
	if not bool(engine.get("exact_version", false)):
		errors.append("Exact Godot 4.7.1 is required")

	var forge: RefCounted = ForgeScript.new()
	var genomes: RefCounted = GenomeScript.new()
	var world: RefCounted = WorldScript.new()
	var heroes: RefCounted = HeroScript.new()

	var forge_contract: Dictionary = forge.call("audit_contract")
	for flag_variant in [
		"pose_first_frames", "idle_move_attack_special_states", "expressive_arms_and_weapons",
		"hero_specific_head_and_gear_language", "curated_family_body_language",
		"muzzle_flash_frames", "dash_trail_frames", "commercial_readability_target"
	]:
		var flag: String = String(flag_variant)
		if not bool(forge_contract.get(flag, false)):
			errors.append("Art4 forge contract missing: " + flag)

	var genome_contract: Dictionary = genomes.call("audit_contract")
	if int(genome_contract.get("curated_motion_families", 0)) < 18:
		errors.append("Art4 curated motion catalog must cover all standard enemies")
	if int(genome_contract.get("canonical_hero_motion_profiles", 0)) != 5:
		errors.append("Art4 must define five canonical hero motion profiles")
	for flag_variant in ["material_family_constraints", "fx_family_constraints", "weapon_read_constraints"]:
		var flag: String = String(flag_variant)
		if not bool(genome_contract.get(flag, false)):
			errors.append("Art4 genome contract missing: " + flag)

	var hero_sheet_hashes: Dictionary = {}
	for lineage: String in LINEAGES:
		var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
		var rng_b: RandomNumberGenerator = RandomNumberGenerator.new()
		rng_a.seed = 1001 + lineage.hash()
		rng_b.seed = 900001 + lineage.hash()
		var genome_a: Dictionary = genomes.call("player_genome", rng_a, lineage, 0)
		var genome_b: Dictionary = genomes.call("player_genome", rng_b, lineage, 4)
		if String(genome_a.get("identity_signature", "")) != String(genome_b.get("identity_signature", "")):
			errors.append("Canonical identity changed across RNG states: " + lineage)
		if String(genome_a.get("weapon_read", "")) == "":
			errors.append("Hero weapon-read identity missing: " + lineage)
		var image_a: Image = forge.call("build_player_sheet", genome_a)
		var image_b: Image = forge.call("build_player_sheet", genome_b)
		if image_a == null or image_b == null or image_a.is_empty() or image_b.is_empty():
			errors.append("Art4 hero sheet failed: " + lineage)
			continue
		if hash(image_a.get_data()) != hash(image_b.get_data()):
			errors.append("Canonical hero pixels changed across unrelated RNG state: " + lineage)
		var action_hashes: Dictionary = _frame_hashes(image_a, 48, 2)
		if action_hashes.size() < 3:
			errors.append("Hero action poses are not materially distinct: " + lineage)
		hero_sheet_hashes[hash(image_a.get_data())] = true
	if hero_sheet_hashes.size() != LINEAGES.size():
		errors.append("All five heroes must remain visually unique")

	var cain: Dictionary = heroes.call("canonical", "cain", 0)
	if String(cain.get("weapon_identity", "")) != "mark_cannon":
		errors.append("Cain must retain Mark Cannon identity")

	var enemy_sheet_hashes: Dictionary = {}
	for sample: Dictionary in ENEMY_SAMPLES:
		var enemy_rng: RandomNumberGenerator = RandomNumberGenerator.new()
		enemy_rng.seed = 4000 + String(sample["id"]).hash()
		var genome: Dictionary = genomes.call("generate", enemy_rng, String(sample["id"]), String(sample["category"]), String(sample["role"]), 2, 1.4, false, false)
		for field_variant in ["motion_profile", "material_family", "fx_profile", "weapon_read", "silhouette_anchor"]:
			var field: String = String(field_variant)
			if String(genome.get(field, "")) == "":
				errors.append("Enemy Art4 direction field missing: %s.%s" % [String(sample["id"]), field])
		var image: Image = forge.call("build_enemy_sheet", genome)
		if image == null or image.is_empty():
			errors.append("Art4 enemy sheet failed: " + String(sample["id"]))
			continue
		var action_hashes: Dictionary = _frame_hashes(image, 48, 2)
		if action_hashes.size() < 2:
			errors.append("Enemy action states collapsed: " + String(sample["id"]))
		enemy_sheet_hashes[hash(image.get_data())] = true
	if enemy_sheet_hashes.size() != ENEMY_SAMPLES.size():
		errors.append("Seven representative enemy families must remain materially distinct")

	var world_contract: Dictionary = world.call("audit_contract")
	for flag_variant in ["landmark_rich_rooms", "layered_floor_architecture", "environmental_story_marks", "quiet_noise_rich_macro_detail", "biome_specific_structural_grammar"]:
		var flag: String = String(flag_variant)
		if not bool(world_contract.get(flag, false)):
			errors.append("Art4 world contract missing: " + flag)
	if int(world_contract.get("story_beat_families", 0)) != 5:
		errors.append("Art4 must define five story-beat biome families")

	var biome_hashes: Dictionary = {}
	for biome_index: int in range(BIOMES.size()):
		var biome_id: String = BIOMES[biome_index]
		var room_rng: RandomNumberGenerator = RandomNumberGenerator.new()
		room_rng.seed = 7100 + biome_index * 881
		var recipe: Dictionary = world.call("make_room_recipe", room_rng, biome_id, "combat", 1.5, Vector2(1280, 720))
		if String(recipe.get("story_beat", "")) == "" or String(recipe.get("art4_room_signature", "")) == "":
			errors.append("Biome Art4 story recipe incomplete: " + biome_id)
		var base: Color = Color8(20 + biome_index * 5, 28 + biome_index * 3, 28 + biome_index * 4)
		var accent: Color = [Color8(113,159,107), Color8(192,113,61), Color8(84,160,164), Color8(177,94,165), Color8(152,122,179)][biome_index]
		var image: Image = world.call("build_floor_image", recipe, base, accent)
		if image == null or image.get_size() != Vector2i(320, 180):
			errors.append("Art4 biome floor output invalid: " + biome_id)
		elif not image.is_empty():
			biome_hashes[hash(image.get_data())] = true
	if biome_hashes.size() != BIOMES.size():
		errors.append("Five Art4 biome surfaces must remain visually distinct")

	var runtime_contract: Dictionary = {}
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	if scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance: Node = scene.instantiate()
		if instance.has_method("audit_art_direction_contract"):
			runtime_contract = instance.call("audit_art_direction_contract")
			for flag_variant in [
				"active_art4_forge", "active_art4_world", "active_art4_genome", "alive_state_motion",
				"breathing_bob", "recoil_muzzle_feedback", "soft_contact_shadows",
				"animated_biome_pockets", "landmark_wall_volume"
			]:
				var flag: String = String(flag_variant)
				if not bool(runtime_contract.get(flag, false)):
					errors.append("Live Art4 runtime flag missing: " + flag)
		else:
			errors.append("Live Art4 art-direction contract unavailable")
		instance.free()

	var report: Dictionary = {
		"revision":"0.6.4-authored-art4",
		"engine":engine,
		"forge":forge_contract,
		"genome":genome_contract,
		"world":world_contract,
		"hero_uniqueness":hero_sheet_hashes.size(),
		"enemy_family_uniqueness":enemy_sheet_hashes.size(),
		"biome_uniqueness":biome_hashes.size(),
		"runtime":runtime_contract,
		"errors":errors,
		"passed":errors.is_empty(),
	}
	print("EDEN_FALL_V8_ART4_REFERENCE_REPORT=" + JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V8_ART4_REFERENCE_AUDIT=PASS")
		quit(0)
	else:
		for error: String in errors:
			push_error(error)
		quit(1)
