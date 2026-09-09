extends SceneTree

const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const EntropyScript: Script = preload("res://scripts/v8/entropy_director.gd")
const GenomeScript: Script = preload("res://scripts/v8/enemy_genome_director_art3.gd")
const RoguelikeForgeScript: Script = preload("res://scripts/v8/procedural_sprite_forge_roguelike.gd")

const FINAL_SCRIPT := "res://scripts/edenfall_v8_release_runtime.gd"

func _init() -> void:
	var errors: Array[String] = []
	var engine: Dictionary = BootstrapScript.new().call("configure")
	if not bool(engine.get("exact_version",false)): errors.append("Exact Godot 4.7.1 is required")

	var entropy: RefCounted = EntropyScript.new()
	var genomes: RefCounted = GenomeScript.new()
	var forge: RefCounted = RoguelikeForgeScript.new()
	var forge_contract: Dictionary = forge.call("audit_contract")
	for flag in ["role_morphology","category_morphology","lineage_silhouette_signatures","cain_heavy_cannon_signature","chunky_proportions","oversized_weapon_read"]:
		if not bool(forge_contract.get(flag,false)): errors.append("Art3 forge contract missing: "+flag)

	var role_hashes: Dictionary = {}
	for sample in [
		{"id":"feral_scavenger","category":"preadamic","role":"melee"},
		{"id":"outlaw_gunner","category":"preadamic","role":"ranged"},
		{"id":"raider_brute","category":"preadamic","role":"charger"},
		{"id":"watcher_acolyte","category":"fallen","role":"caster"},
		{"id":"fallen_angel","category":"fallen","role":"skirmisher"},
		{"id":"ophanim_scout","category":"fallen","role":"orbiter"},
		{"id":"grafted_colossus","category":"nephilim","role":"radial"},
	]:
		var genome: Dictionary = genomes.call("generate",entropy.call("fork","art3_role"),String(sample["id"]),String(sample["category"]),String(sample["role"]),2,1.25,false,false)
		var image: Image = forge.call("build_enemy_sheet",genome)
		if image == null or image.get_size() != Vector2i(192,384):
			errors.append("Art3 role sheet invalid: "+String(sample["role"]))
		else:
			role_hashes[hash(image.get_data())] = String(sample["role"])
	if role_hashes.size() != 7: errors.append("Seven combat roles do not produce seven distinct authored sprite sheets")

	var category_hashes: Dictionary = {}
	for category in ["preadamic","fallen","nephilim","guardian"]:
		var genome: Dictionary = genomes.call("generate",entropy.call("fork","art3_category"),"audit_host",String(category),"ranged",2,1.25,false,false)
		var image: Image = forge.call("build_enemy_sheet",genome)
		if image != null and not image.is_empty(): category_hashes[hash(image.get_data())] = category
	if category_hashes.size() != 4: errors.append("Faction/category morphology is not materially distinct")

	var lineage_hashes: Dictionary = {}
	for lineage in ["adam","abel","cain","seth","naamah"]:
		var genome: Dictionary = genomes.call("player_genome",entropy.call("fork","canonical_lineage"),String(lineage),0)
		if not bool(genome.get("hero_identity_locked",false)):
			errors.append("Canonical lineage identity is not locked: "+String(lineage))
		var image: Image = forge.call("build_player_sheet",genome)
		if image == null or image.get_size() != Vector2i(192,384):
			errors.append("Canonical lineage sheet invalid: "+String(lineage))
		else:
			lineage_hashes[hash(image.get_data())] = lineage
	if lineage_hashes.size() != 5: errors.append("Five canonical lineages must remain materially distinct")

	var streaming_source: String = FileAccess.get_file_as_string("res://scripts/edenfall_v8_streaming_runtime.gd")
	for symbol in ["MAX_ROOM_ACTOR_TEXTURES","_forge_queue","_forge_one","visual_pending","_prune_actor_texture_cache","one_forge_job_per_tick"]:
		if streaming_source.find(symbol) < 0: errors.append("Streaming sprite contract missing symbol: "+symbol)

	var release_source: String = FileAccess.get_file_as_string(FINAL_SCRIPT)
	for symbol in ["RoguelikeSpriteForgeScript","Art3GenomeDirectorScript","Art3WorldDirectorScript","stochastic_guardian_pattern_order","generated_trait_combat_actions","trait_windups"]:
		if release_source.find(symbol) < 0: errors.append("V8 release behavior/art contract missing symbol: "+symbol)

	var runtime: Dictionary = {}
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	if scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance: Node = scene.instantiate()
		var script: Script = instance.get_script() as Script
		if script == null or script.resource_path != FINAL_SCRIPT: errors.append("main.tscn is not routed to the V8 release root")
		if instance.has_method("audit_entropy_contract"):
			runtime = instance.call("audit_entropy_contract")
			for flag in ["premium_sprite_forge","chunky_roguelike_sprite_forge","hero_identity_locked","curated_enemy_module_families","queued_sprite_forge","one_forge_job_per_tick","visual_pending_blocks_ai","room_scoped_sprite_cache","stochastic_guardian_pattern_order","generated_trait_combat_actions","trait_windups"]:
				if not bool(runtime.get(flag,false)): errors.append("Runtime sprite/behavior flag missing: "+flag)
			if int(runtime.get("max_room_actor_textures",0)) > 12: errors.append("Per-room procedural actor texture budget exceeds 12")
		else:
			errors.append("V8 entropy runtime audit is unavailable")
		instance.free()

	var report := {
		"product_revision":"0.6.3-art3",
		"forge":forge_contract,
		"role_uniqueness":role_hashes.size(),
		"category_uniqueness":category_hashes.size(),
		"lineage_uniqueness":lineage_hashes.size(),
		"runtime":runtime,
		"errors":errors,
		"passed":errors.is_empty(),
	}
	print("EDEN_FALL_V8_SPRITE_STREAMING_REPORT="+JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V8_SPRITE_STREAMING_AUDIT=PASS")
		quit(0)
	else:
		for error in errors: push_error(error)
		quit(1)
