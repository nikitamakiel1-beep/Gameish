extends SceneTree

const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const EntropyDirectorScript: Script = preload("res://scripts/v8/entropy_director.gd")
const EnemyGenomeDirectorScript: Script = preload("res://scripts/v8/enemy_genome_director.gd")
const SpriteForgeScript: Script = preload("res://scripts/v8/procedural_sprite_forge.gd")
const WorldDirectorScript: Script = preload("res://scripts/v8/procedural_world_director.gd")
const VersionManifestScript: Script = preload("res://scripts/v8/version_manifest.gd")

const FINAL_SCRIPT := "res://scripts/edenfall_v8_visual_runtime.gd"
const SAMPLE_ROLES := [
	{"id":"feral_scavenger","category":"preadamic","role":"melee"},
	{"id":"outlaw_gunner","category":"preadamic","role":"ranged"},
	{"id":"raider_brute","category":"preadamic","role":"charger"},
	{"id":"watcher_acolyte","category":"fallen","role":"caster"},
	{"id":"fallen_angel","category":"fallen","role":"skirmisher"},
	{"id":"ophanim_scout","category":"fallen","role":"orbiter"},
	{"id":"grafted_colossus","category":"nephilim","role":"radial"},
]

func _init() -> void:
	var errors: Array[String] = []
	var engine: Dictionary = BootstrapScript.new().call("configure")
	if not bool(engine.get("exact_version",false)):
		errors.append("Exact Godot 4.7.1 is required")

	var manifest: Dictionary = VersionManifestScript.new().call("report")
	if String(manifest.get("product_revision","")) != "0.6.2-entropy": errors.append("V8 product revision mismatch")
	if String(manifest.get("generation_mode","")) != "stochastic_condition_driven": errors.append("V8 generation mode mismatch")
	if bool(manifest.get("fixed_seed_replay",true)): errors.append("V8 must not expose fixed-seed replay generation")

	var entropy: RefCounted = EntropyDirectorScript.new()
	var entropy_contract: Dictionary = entropy.call("audit_contract")
	if bool(entropy_contract.get("fixed_seed_replay",true)): errors.append("Entropy director still reports fixed-seed replay")
	var tokens: Dictionary = {}
	for index in range(16):
		tokens[int(entropy.call("token","audit"))] = true
	if tokens.size() < 15: errors.append("Entropy token uniqueness below V8 gate")

	var genomes: RefCounted = EnemyGenomeDirectorScript.new()
	var forge: RefCounted = SpriteForgeScript.new()
	var genome_signatures: Dictionary = {}
	var body_shapes: Dictionary = {}
	for index in range(18):
		var genome: Dictionary = genomes.call("generate",entropy.call("fork","genome_audit"),"outlaw_gunner","preadamic","ranged",1,1.18,false,false)
		genome_signatures[String(genome.get("visual_signature",""))] = true
		body_shapes["%d:%d:%d:%d" % [int(genome.get("body_width",0)),int(genome.get("body_height",0)),int(genome.get("head_style",0)),int(genome.get("weapon_style",0))]] = true
	if genome_signatures.size() < 16: errors.append("Per-instance visual genome signatures are not sufficiently varied")
	if body_shapes.size() < 8: errors.append("Enemy morphology collapses to too few body/head/weapon combinations")

	var role_hashes: Dictionary = {}
	for sample_variant in SAMPLE_ROLES:
		var sample: Dictionary = sample_variant
		var genome: Dictionary = genomes.call("generate",entropy.call("fork","role:"+String(sample["role"])),String(sample["id"]),String(sample["category"]),String(sample["role"]),2,1.30,false,false)
		var sheet: Image = forge.call("build_enemy_sheet",genome)
		if sheet == null or sheet.is_empty():
			errors.append("Generated enemy sheet is empty: "+String(sample["id"]))
			continue
		if sheet.get_size() != Vector2i(192,384): errors.append("Generated enemy sheet has wrong dimensions: "+String(sample["id"]))
		if not _readable_sheet(sheet,48): errors.append("Generated enemy sheet occupancy/readability failed: "+String(sample["id"]))
		role_hashes[hash(sheet.get_data())] = String(sample["role"])
	if role_hashes.size() != SAMPLE_ROLES.size(): errors.append("Role-specific sprite families are not materially unique")

	var lineage_hashes: Dictionary = {}
	for lineage_id in ["adam","abel","cain","seth","naamah"]:
		var genome: Dictionary = genomes.call("player_genome",entropy.call("fork","hero:"+String(lineage_id)),String(lineage_id),0)
		var sheet: Image = forge.call("build_player_sheet",genome)
		if sheet == null or sheet.get_size() != Vector2i(192,384): errors.append("Generated lineage sheet invalid: "+String(lineage_id))
		elif not _readable_sheet(sheet,48): errors.append("Generated lineage readability failed: "+String(lineage_id))
		else: lineage_hashes[hash(sheet.get_data())] = lineage_id
	if lineage_hashes.size() != 5: errors.append("Five lineage procedural sheets must be materially unique")

	var boss_genome: Dictionary = genomes.call("generate",entropy.call("fork","boss"),"watcher_engine","guardian","radial",4,1.7,true,true)
	var boss_sheet: Image = forge.call("build_boss_sheet",boss_genome)
	if boss_sheet == null or boss_sheet.get_size() != Vector2i(384,768): errors.append("Generated guardian sheet dimensions invalid")
	elif not _readable_sheet(boss_sheet,96): errors.append("Generated guardian sheet readability failed")

	var world: RefCounted = WorldDirectorScript.new()
	var room_signatures: Dictionary = {}
	var floor_hashes: Dictionary = {}
	for index in range(8):
		var recipe: Dictionary = world.call("make_room_recipe",entropy.call("fork","world"),"industrial_eden","combat",1.22,Vector2(1600,900))
		room_signatures[String(recipe.get("signature",""))] = true
		var floor_image: Image = world.call("build_floor_image",recipe,Color8(20,35,30),Color8(113,159,107))
		if floor_image == null or floor_image.get_size() != Vector2i(256,144):
			errors.append("Procedural floor texture dimensions invalid")
		elif not floor_image.is_empty():
			floor_hashes[hash(floor_image.get_data())] = true
	if room_signatures.size() < 7: errors.append("Room recipe signatures are insufficiently stochastic")
	if floor_hashes.size() < 7: errors.append("Procedural floor textures are insufficiently varied")

	for path in [
		"res://scripts/v8/entropy_director.gd",
		"res://scripts/v8/enemy_genome_director.gd",
		"res://scripts/v8/procedural_sprite_forge.gd",
		"res://scripts/v8/procedural_world_director.gd",
		"res://scripts/edenfall_v8_entropy_runtime.gd",
		FINAL_SCRIPT,
	]:
		if not ResourceLoader.exists(path): errors.append("Missing V8 resource: "+path)

	var runtime_report: Dictionary = {}
	var main_scene := load("res://main.tscn") as PackedScene
	if main_scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance := main_scene.instantiate()
		var script := instance.get_script() as Script
		if script == null or script.resource_path != FINAL_SCRIPT: errors.append("main.tscn is not routed to V8 visual runtime")
		if instance.has_method("audit_entropy_contract"):
			runtime_report = instance.call("audit_entropy_contract")
			for flag in ["fresh_floor_entropy","stochastic_special_rooms","stochastic_encounters","stochastic_relics","stochastic_adaptations","per_instance_enemy_genomes","procedural_actor_sheets","procedural_room_recipes","suspend_preserves_generated_recipe","eight_direction_generated_sprites","procedural_floor_texture","biome_specific_cover_finishing"]:
				if not bool(runtime_report.get(flag,false)): errors.append("V8 runtime contract missing: "+flag)
			if bool(runtime_report.get("fixed_seed_replay",true)): errors.append("V8 runtime still reports fixed-seed replay")
		else:
			errors.append("V8 entropy audit method missing")
		instance.free()

	var report := {
		"product_revision":"0.6.2-entropy",
		"engine":engine,
		"manifest":manifest,
		"entropy":entropy_contract,
		"token_uniqueness":tokens.size(),
		"genome_uniqueness":genome_signatures.size(),
		"body_shape_uniqueness":body_shapes.size(),
		"role_sprite_uniqueness":role_hashes.size(),
		"lineage_sprite_uniqueness":lineage_hashes.size(),
		"room_signature_uniqueness":room_signatures.size(),
		"floor_texture_uniqueness":floor_hashes.size(),
		"runtime":runtime_report,
		"errors":errors,
		"passed":errors.is_empty(),
	}
	print("EDEN_FALL_V8_ENTROPY_REPORT="+JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V8_ENTROPY_AUDIT=PASS")
		quit(0)
	else:
		for error in errors: push_error(error)
		quit(1)

func _readable_sheet(sheet: Image, frame_size: int) -> bool:
	var readable := 0
	var sampled := 0
	for direction in range(8):
		for frame in range(4):
			var region := sheet.get_region(Rect2i(frame*frame_size,direction*frame_size,frame_size,frame_size))
			var used := region.get_used_rect()
			sampled += 1
			if used.size.x >= int(frame_size*0.28) and used.size.y >= int(frame_size*0.40): readable += 1
	return readable >= int(float(sampled)*0.88)
