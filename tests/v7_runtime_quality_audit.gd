extends SceneTree

const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const AudioFactoryScript: Script = preload("res://scripts/v7/audio_asset_factory_masterpiece.gd")
const FairnessDirectorScript: Script = preload("res://scripts/v7/combat_fairness_director.gd")

const FINAL_SCRIPT := "res://scripts/edenfall_v7_art_runtime.gd"
const WARNING_IDS := ["warning_melee", "warning_aimed", "warning_radial", "warning_phase"]

func _init() -> void:
	var errors: Array[String] = []
	var bootstrap: RefCounted = BootstrapScript.new()
	var engine: Dictionary = bootstrap.call("configure")
	if not bool(engine.get("exact_version", false)):
		errors.append("Exact Godot 4.7.1 is required")

	var audio: RefCounted = AudioFactoryScript.new()
	var audio_contract: Dictionary = audio.call("audit_contract")
	if int(audio_contract.get("mix_rate", 0)) != 22050:
		errors.append("RC7 audio must synthesize at 22.05 kHz")
	if int(audio_contract.get("biome_motifs", 0)) != 5:
		errors.append("RC7 audio must expose five biome motifs")
	if int(audio_contract.get("warning_families", 0)) != 4:
		errors.append("RC7 audio must expose four warning families")
	if bool(audio_contract.get("external_samples", true)):
		errors.append("RC7 production audio must remain first-party synthesis")

	var music_hashes: Dictionary = {}
	var ambience_hashes: Dictionary = {}
	for index in range(5):
		var music: AudioStreamWAV = audio.call("synth_loop", index, false)
		var ambience: AudioStreamWAV = audio.call("synth_loop", index, true)
		if not _valid_loop(music):
			errors.append("Invalid music loop for biome %d" % index)
		if not _valid_loop(ambience):
			errors.append("Invalid ambience loop for biome %d" % index)
		if music != null:
			music_hashes[hash(music.data)] = index
		if ambience != null:
			ambience_hashes[hash(ambience.data)] = index
	if music_hashes.size() != 5:
		errors.append("Five biome music loops must be materially unique")
	if ambience_hashes.size() != 5:
		errors.append("Five biome ambience loops must be materially unique")

	var warning_hashes: Dictionary = {}
	for id in WARNING_IDS:
		var stream: AudioStreamWAV = audio.call("synth_sfx", id)
		if stream == null or stream.mix_rate != 22050 or stream.data.is_empty():
			errors.append("Invalid warning SFX family: " + id)
		else:
			warning_hashes[hash(stream.data)] = id
	if warning_hashes.size() != WARNING_IDS.size():
		errors.append("Warning SFX families must be acoustically distinct at the data level")

	var fairness: RefCounted = FairnessDirectorScript.new()
	var fairness_report: Dictionary = fairness.call("audit_contract")
	if float(fairness_report.get("room_grace", 0.0)) < 0.5:
		errors.append("Room grace is below the RC7 fairness floor")
	if float(fairness_report.get("spawn_clearance", 0.0)) < 140.0:
		errors.append("Standard hostile spawn clearance is too small")

	var runtime_report: Dictionary = {}
	var inherited_report: Dictionary = {}
	var main_scene := load("res://main.tscn") as PackedScene
	if main_scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance := main_scene.instantiate()
		var script := instance.get_script() as Script
		if script == null or script.resource_path != FINAL_SCRIPT:
			errors.append("main.tscn is not routed to the RC7 art runtime")
		if instance.has_method("audit_masterpiece_contract"):
			runtime_report = instance.call("audit_masterpiece_contract")
			for flag in [
				"semantic_warning_audio", "room_entry_grace", "staggered_enemy_materialization",
				"safe_state_asset_prewarm", "biome_pool_cache_retention",
				"shallow_startup_deep_release_audit", "masterpiece_asset_registry", "pixel_finish",
			]:
				if not bool(runtime_report.get(flag, false)):
					errors.append("RC7 runtime quality flag missing: " + flag)
		else:
			errors.append("RC7 runtime quality audit method is missing")
		if instance.has_method("audit_godmode_contract"):
			inherited_report = instance.call("audit_godmode_contract")
			for flag in ["deterministic_floor_graph", "rng_seed_and_state_restored", "ending_choice_suspend_safe", "serpent_resolution_choice"]:
				if not bool(inherited_report.get(flag, false)):
					errors.append("Inherited RC6 guarantee missing: " + flag)
		else:
			errors.append("Inherited RC6 audit contract is unavailable")
		instance.free()

	var report := {
		"product_revision":"0.6.1-rc7",
		"audio":audio_contract,
		"music_unique":music_hashes.size(),
		"ambience_unique":ambience_hashes.size(),
		"warning_unique":warning_hashes.size(),
		"fairness":fairness_report,
		"runtime":runtime_report,
		"inherited":inherited_report,
		"errors":errors,
		"passed":errors.is_empty(),
	}
	print("EDEN_FALL_V7_RUNTIME_QUALITY_REPORT=" + JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V7_RUNTIME_QUALITY_AUDIT=PASS")
		quit(0)
	else:
		for error in errors:
			push_error(error)
		quit(1)

func _valid_loop(stream: AudioStreamWAV) -> bool:
	return stream != null and stream.mix_rate == 22050 and stream.format == AudioStreamWAV.FORMAT_16_BITS and not stream.data.is_empty() and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_end > 0
