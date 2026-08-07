extends SceneTree

const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const AudioFactoryScript: Script = preload("res://scripts/v7/audio_asset_factory_masterpiece.gd")
const FairnessDirectorScript: Script = preload("res://scripts/v7/combat_fairness_director.gd")
const EvolutionDirectorScript: Script = preload("res://scripts/v7/lineage_evolution_director.gd")

const FINAL_SCRIPT := "res://scripts/edenfall_v8_release_runtime.gd"
const WARNING_IDS := ["warning_melee","warning_aimed","warning_radial","warning_phase"]

func _init() -> void:
	var errors: Array[String] = []
	var engine: Dictionary = BootstrapScript.new().call("configure")
	if not bool(engine.get("exact_version",false)): errors.append("Exact Godot 4.7.1 is required")

	var audio: RefCounted = AudioFactoryScript.new()
	var audio_contract: Dictionary = audio.call("audit_contract")
	if int(audio_contract.get("mix_rate",0)) != 22050: errors.append("RC7 audio compatibility must remain 22.05 kHz")
	if int(audio_contract.get("biome_motifs",0)) != 5: errors.append("Five biome audio identities are required")
	if int(audio_contract.get("warning_families",0)) != 4: errors.append("Four semantic warning families are required")
	if bool(audio_contract.get("external_samples",true)): errors.append("Production audio must remain first-party synthesis")

	var music_hashes: Dictionary = {}
	var ambience_hashes: Dictionary = {}
	for index in range(5):
		var music: AudioStreamWAV = audio.call("synth_loop",index,false)
		var ambience: AudioStreamWAV = audio.call("synth_loop",index,true)
		if not _valid_loop(music): errors.append("Invalid music loop for biome %d" % index)
		if not _valid_loop(ambience): errors.append("Invalid ambience loop for biome %d" % index)
		if music != null: music_hashes[hash(music.data)] = index
		if ambience != null: ambience_hashes[hash(ambience.data)] = index
	if music_hashes.size() != 5: errors.append("Biome music loops are not materially unique")
	if ambience_hashes.size() != 5: errors.append("Biome ambience loops are not materially unique")

	var warning_hashes: Dictionary = {}
	for id in WARNING_IDS:
		var stream: AudioStreamWAV = audio.call("synth_sfx",id)
		if stream == null or stream.mix_rate != 22050 or stream.data.is_empty(): errors.append("Invalid warning SFX: "+id)
		else: warning_hashes[hash(stream.data)] = id
	if warning_hashes.size() != WARNING_IDS.size(): errors.append("Warning SFX families must remain acoustically distinct")

	var fairness: Dictionary = FairnessDirectorScript.new().call("audit_contract")
	if float(fairness.get("room_grace",0.0)) < 0.5: errors.append("Room-entry grace below quality floor")
	if float(fairness.get("spawn_clearance",0.0)) < 140.0: errors.append("Hostile spawn clearance below quality floor")
	var evolutions: Dictionary = EvolutionDirectorScript.new().call("audit_contract")
	if int(evolutions.get("options",0)) != 25: errors.append("Lineage adaptation catalog must remain complete")

	var runtime: Dictionary = {}
	var godmode: Dictionary = {}
	var entropy: Dictionary = {}
	var main_scene := load("res://main.tscn") as PackedScene
	if main_scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance := main_scene.instantiate()
		var script := instance.get_script() as Script
		if script == null or script.resource_path != FINAL_SCRIPT: errors.append("main.tscn is not routed through V8 release root")
		if instance.has_method("audit_masterpiece_contract"):
			runtime = instance.call("audit_masterpiece_contract")
			for flag in ["semantic_warning_audio","room_entry_grace","staggered_enemy_materialization","safe_state_asset_prewarm","biome_pool_cache_retention","shallow_startup_deep_release_audit","masterpiece_asset_registry","pixel_finish","guardian_adaptation_choices","adaptation_suspend_safe","run_only_lineage_evolution","profile_schema_preseed"]:
				if not bool(runtime.get(flag,false)): errors.append("Inherited RC7 quality flag missing under V8: "+flag)
		else: errors.append("RC7 quality contract unavailable through V8")
		if instance.has_method("audit_godmode_contract"):
			godmode = instance.call("audit_godmode_contract")
			for flag in ["rng_seed_and_state_restored","ending_choice_suspend_safe","serpent_resolution_choice","entropy_floor_graph","active_run_recipe_persistence"]:
				if not bool(godmode.get(flag,false)): errors.append("Runtime persistence/ending guarantee missing: "+flag)
			if bool(godmode.get("deterministic_floor_graph",true)): errors.append("V8 must supersede deterministic floor generation")
		else: errors.append("Godmode compatibility audit unavailable")
		if instance.has_method("audit_entropy_contract"): entropy = instance.call("audit_entropy_contract")
		instance.free()

	var report := {"compatibility_layer":"RC7 runtime quality under V8","engine":engine,"audio":audio_contract,"music_unique":music_hashes.size(),"ambience_unique":ambience_hashes.size(),"warning_unique":warning_hashes.size(),"fairness":fairness,"evolutions":evolutions,"runtime":runtime,"godmode":godmode,"entropy":entropy,"errors":errors,"passed":errors.is_empty()}
	print("EDEN_FALL_V7_RUNTIME_COMPAT_REPORT="+JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V7_RUNTIME_COMPAT_AUDIT=PASS")
		quit(0)
	else:
		for error in errors: push_error(error)
		quit(1)

func _valid_loop(stream: AudioStreamWAV) -> bool:
	return stream != null and stream.mix_rate == 22050 and stream.format == AudioStreamWAV.FORMAT_16_BITS and not stream.data.is_empty() and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_end > 0
