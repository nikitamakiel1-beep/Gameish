extends SceneTree

const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const EntropyScript: Script = preload("res://scripts/v8/entropy_director.gd")
const GenomeScript: Script = preload("res://scripts/v8/enemy_genome_director_art3.gd")
const HeroScript: Script = preload("res://scripts/v8/hero_identity_director.gd")
const ForgeScript: Script = preload("res://scripts/v8/procedural_sprite_forge_roguelike.gd")
const WorldScript: Script = preload("res://scripts/v8/procedural_world_director_art3.gd")
const EvaluatorScript: Script = preload("res://scripts/v7/sprite_quality_evaluator.gd")

const FINAL_SCRIPT: String = "res://scripts/edenfall_v8_release_runtime.gd"
const ROLE_SAMPLES: Array[Dictionary] = [
	{"id":"feral_scavenger","category":"preadamic","role":"melee"},
	{"id":"outlaw_gunner","category":"preadamic","role":"ranged"},
	{"id":"raider_brute","category":"preadamic","role":"charger"},
	{"id":"watcher_acolyte","category":"fallen","role":"caster"},
	{"id":"fallen_angel","category":"fallen","role":"skirmisher"},
	{"id":"ophanim_scout","category":"fallen","role":"orbiter"},
	{"id":"grafted_colossus","category":"nephilim","role":"radial"},
]
const LINEAGES: Array[String] = ["adam","abel","cain","seth","naamah"]
const BOSSES: Array[String] = ["watcher_engine","first_nephilim","gate_cherub","tower_enoch","serpent_interface"]
const BIOMES: Array[String] = ["industrial_eden","ash_wastes","temple_lab","fungal_garden","nephilim_ruins"]
const HERO_LOCK_FIELDS: Array[String] = [
	"silhouette_key","palette_index","body_width","body_height","head_style",
	"shoulder_style","weapon_style","backpack_style","weapon_identity","identity_signature"
]

func _texture(image: Image) -> Texture2D:
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _quality_error(label: String, result: Dictionary) -> String:
	return "%s // %s // occupancy=%.4f bbox=%.1fx%.1f dirs=%d" % [
		label,
		String(result.get("reason","unspecified")),
		float(result.get("occupancy",0.0)),
		float(result.get("bbox_width",0.0)),
		float(result.get("bbox_height",0.0)),
		int(result.get("unique_direction_silhouettes",0)),
	]

func _init() -> void:
	var errors: Array[String] = []
	var engine: Dictionary = BootstrapScript.new().call("configure")
	if not bool(engine.get("exact_version",false)):
		errors.append("Exact Godot 4.7.1 is required")

	var entropy: RefCounted = EntropyScript.new()
	entropy.call("reseed")
	var genomes: RefCounted = GenomeScript.new()
	var heroes: RefCounted = HeroScript.new()
	var forge: RefCounted = ForgeScript.new()
	var world: RefCounted = WorldScript.new()
	var evaluator: RefCounted = EvaluatorScript.new()

	var hero_contract: Dictionary = heroes.call("audit_contract")
	if int(hero_contract.get("hero_count",0)) != 5:
		errors.append("Canonical hero catalog must contain exactly five lineages")
	if not bool(hero_contract.get("identity_locked",false)):
		errors.append("Hero identity lock is disabled")
	if bool(hero_contract.get("procedural_body_variation",true)) or bool(hero_contract.get("procedural_palette_variation",true)) or bool(hero_contract.get("procedural_weapon_class_variation",true)):
		errors.append("Hero body/palette/weapon class may not be procedurally regenerated")

	var genome_contract: Dictionary = genomes.call("audit_contract")
	if int(genome_contract.get("authored_profiles",0)) < 28:
		errors.append("Authored silhouette profile catalog must cover 18 enemies + 5 bosses + 5 lineages")
	if not bool(genome_contract.get("authored_silhouette_grammar",false)):
		errors.append("Genome director is not using authored silhouette constraints")
	if not bool(genome_contract.get("approved_module_generation",false)):
		errors.append("Enemy procedural generation must stay inside approved modules")
	if not bool(genome_contract.get("hero_identity_locked",false)):
		errors.append("Active genome director does not lock protagonist identity")

	var forge_contract: Dictionary = forge.call("audit_contract")
	for flag: String in [
		"authored_template_core","authored_role_templates","guardian_specific_templates",
		"frame_safe_anatomy","profile_driven_weapons","lineage_silhouette_signatures",
		"cain_heavy_cannon_signature","chunky_proportions","large_head_compact_body",
		"oversized_weapon_read","five_color_ramp_discipline"
	]:
		if not bool(forge_contract.get(flag,false)):
			errors.append("Authored forge contract missing: "+flag)
	if bool(forge_contract.get("random_microdetail",true)):
		errors.append("Random microdetail must not be part of the active sprite grammar")

	# Protagonist identity must remain byte-for-byte stable even with unrelated RNG state.
	var lineage_hashes: Dictionary = {}
	for lineage: String in LINEAGES:
		var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
		var rng_b: RandomNumberGenerator = RandomNumberGenerator.new()
		rng_a.seed = 101 + lineage.hash()
		rng_b.seed = 91919 + lineage.hash()
		var genome_a: Dictionary = genomes.call("player_genome",rng_a,lineage,0)
		var genome_b: Dictionary = genomes.call("player_genome",rng_b,lineage,4)
		for field: String in HERO_LOCK_FIELDS:
			if genome_a.get(field,null) != genome_b.get(field,null):
				errors.append("Hero identity changed across runs: %s.%s" % [lineage,field])
		if not bool(genome_a.get("hero_identity_locked",false)):
			errors.append("Hero identity lock marker missing: "+lineage)
		var image_a: Image = forge.call("build_player_sheet",genome_a)
		var image_b: Image = forge.call("build_player_sheet",genome_b)
		if image_a == null or image_b == null or image_a.is_empty() or image_b.is_empty():
			errors.append("Canonical lineage sheet failed: "+lineage)
			continue
		if hash(image_a.get_data()) != hash(image_b.get_data()):
			errors.append("Canonical hero pixels changed across unrelated RNG states: "+lineage)
		var texture: Texture2D = _texture(image_a)
		var result: Dictionary = evaluator.call("evaluate_actor",texture,Vector2i(48,48),Vector2i(15,22),3)
		if not bool(result.get("passed",false)):
			errors.append(_quality_error("Lineage "+lineage,result))
		lineage_hashes[hash(image_a.get_data())] = true
	if lineage_hashes.size() != LINEAGES.size():
		errors.append("Five canonical lineages must remain visually distinct")

	var cain: Dictionary = heroes.call("canonical","cain",0)
	if String(cain.get("weapon_identity","")) != "mark_cannon" or int(cain.get("weapon_style",0)) != 5 or int(cain.get("palette_index",0)) != 15:
		errors.append("Cain canonical identity must retain the red-black Mark Cannon")

	# Enemy roles remain stochastic, but family silhouette/palette rules remain constrained.
	var role_hashes: Dictionary = {}
	for sample: Dictionary in ROLE_SAMPLES:
		var sample_rng: RandomNumberGenerator = entropy.call("fork","art3_role:"+String(sample["id"]))
		var genome: Dictionary = genomes.call("generate",sample_rng,String(sample["id"]),String(sample["category"]),String(sample["role"]),2,1.25,false,false)
		if String(genome.get("generation_scope","")) != "approved_modules_only":
			errors.append("Enemy escaped approved-module generation: "+String(sample["id"]))
		var image: Image = forge.call("build_enemy_sheet",genome)
		var texture: Texture2D = _texture(image)
		var result: Dictionary = evaluator.call("evaluate_actor",texture,Vector2i(48,48),Vector2i(14,20),3)
		if not bool(result.get("passed",false)):
			errors.append(_quality_error("Role "+String(sample["role"]),result))
		if image != null and not image.is_empty():
			role_hashes[hash(image.get_data())] = true
	if role_hashes.size() != ROLE_SAMPLES.size():
		errors.append("Seven combat roles must produce seven materially distinct sheets")

	var boss_hashes: Dictionary = {}
	for boss_id: String in BOSSES:
		var genome: Dictionary = genomes.call("generate",entropy.call("fork","art3_boss:"+boss_id),boss_id,"guardian","radial",4,2.0,true,true)
		var image: Image = forge.call("build_boss_sheet",genome)
		var texture: Texture2D = _texture(image)
		var result: Dictionary = evaluator.call("evaluate_actor",texture,Vector2i(96,96),Vector2i(42,46),4)
		if not bool(result.get("passed",false)):
			errors.append(_quality_error("Guardian "+boss_id,result))
		if image != null and not image.is_empty():
			boss_hashes[hash(image.get_data())] = true
	if boss_hashes.size() != BOSSES.size():
		errors.append("Five guardians must use five distinct authored templates")

	var world_contract: Dictionary = world.call("audit_contract")
	if not bool(world_contract.get("quiet_floor_hierarchy",false)):
		errors.append("Art3 world generator must use a quiet floor hierarchy")
	if bool(world_contract.get("room_sized_wallpaper_panels",true)):
		errors.append("Room-sized wallpaper panels are forbidden")
	if int(world_contract.get("authored_landmark_families",0)) != 5:
		errors.append("Each lore biome must have an authored landmark family")
	var biome_hashes: Dictionary = {}
	for biome_index: int in range(BIOMES.size()):
		var biome_id: String = BIOMES[biome_index]
		var room_rng: RandomNumberGenerator = RandomNumberGenerator.new()
		room_rng.seed = 9101 + biome_index * 733
		var recipe: Dictionary = world.call("make_room_recipe",room_rng,biome_id,"combat",1.4,Vector2(1280,720))
		if String(recipe.get("landmark","")) == "":
			errors.append("Biome room recipe missing authored landmark: "+biome_id)
		var base: Color = Color8(20+biome_index*5,28+biome_index*3,28+biome_index*4)
		var accent: Color = [Color8(113,159,107),Color8(192,113,61),Color8(84,160,164),Color8(177,94,165),Color8(152,122,179)][biome_index]
		var image: Image = world.call("build_floor_image",recipe,base,accent)
		if image == null or image.get_size() != Vector2i(320,180):
			errors.append("Biome floor output invalid: "+biome_id)
		elif not image.is_empty():
			biome_hashes[hash(image.get_data())] = true
	if biome_hashes.size() != BIOMES.size():
		errors.append("Five biome surface grammars must produce distinct images")

	var runtime_contract: Dictionary = {}
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	if scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance: Node = scene.instantiate()
		var script: Script = instance.get_script() as Script
		if script == null or script.resource_path != FINAL_SCRIPT:
			errors.append("Game scene is not routed through the V8 release root")
		if instance.has_method("audit_entropy_contract"):
			runtime_contract = instance.call("audit_entropy_contract")
			for flag: String in ["chunky_roguelike_sprite_forge","hero_identity_locked","curated_enemy_module_families","quiet_biome_visual_hierarchy"]:
				if not bool(runtime_contract.get(flag,false)):
					errors.append("Art3 release flag missing: "+flag)
		else:
			errors.append("V8 entropy/art release contract is unavailable")
		instance.free()

	var report: Dictionary = {
		"product_revision":"0.6.3-art3",
		"engine":engine,
		"heroes":hero_contract,
		"genome":genome_contract,
		"forge":forge_contract,
		"world":world_contract,
		"role_uniqueness":role_hashes.size(),
		"lineage_uniqueness":lineage_hashes.size(),
		"guardian_uniqueness":boss_hashes.size(),
		"biome_uniqueness":biome_hashes.size(),
		"runtime":runtime_contract,
		"errors":errors,
		"passed":errors.is_empty(),
	}
	print("EDEN_FALL_V8_ART_DIRECTION_REPORT="+JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V8_ART_DIRECTION_AUDIT=PASS")
		quit(0)
	else:
		for error: String in errors:
			push_error(error)
		quit(1)
