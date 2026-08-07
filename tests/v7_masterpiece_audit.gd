extends SceneTree

const RegistryScript: Script = preload("res://scripts/v7/asset_registry_masterpiece.gd")
const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const EncounterComposerScript: Script = preload("res://scripts/v7/encounter_composer.gd")
const RelicPoolDirectorScript: Script = preload("res://scripts/v7/relic_pool_director.gd")
const FairnessDirectorScript: Script = preload("res://scripts/v7/combat_fairness_director.gd")
const EvolutionDirectorScript: Script = preload("res://scripts/v7/lineage_evolution_director.gd")
const SpriteQualityEvaluatorScript: Script = preload("res://scripts/v7/sprite_quality_evaluator.gd")
const VersionManifestScript: Script = preload("res://scripts/v7/version_manifest.gd")

const FINAL_SCRIPT := "res://scripts/edenfall_v7_release_runtime.gd"
const PROGRESSION_SCRIPT := "res://scripts/edenfall_v7_progression_runtime.gd"
const ART_SCRIPT := "res://scripts/edenfall_v7_art_runtime.gd"
const HERO_IDS: Array[String] = ["adam", "abel", "cain", "seth", "naamah"]
const ENEMY_IDS: Array[String] = ["feral_scavenger","outlaw_gunner","raider_brute","wasteland_hunter","scrap_cultist","caravan_outlaw","cherub_drone","fallen_angel","watcher_acolyte","halo_sentinel","biomech_pilgrim","ophanim_scout","nephilim_husk","nephilim_giant","horned_berserker","bone_shepherd","grafted_colossus","serpent_spawn"]
const BOSS_IDS: Array[String] = ["watcher_engine","first_nephilim","gate_cherub","tower_enoch","serpent_interface"]

func _init() -> void:
	var errors: Array[String] = []
	var engine: Dictionary = BootstrapScript.new().call("configure")
	if not bool(engine.get("exact_version", false)):
		errors.append("Exact Godot 4.7.1 is required")

	var version_report: Dictionary = VersionManifestScript.new().call("report")
	if String(version_report.get("product_revision", "")) != "0.6.1-rc7": errors.append("RC7 product revision mismatch")
	if String(version_report.get("core_abi_version", "")) != "0.6.0": errors.append("Core ABI mismatch")

	var registry: RefCounted = RegistryScript.new()
	var registry_contract: Dictionary = registry.call("validate_contract", true)
	if not bool(registry_contract.get("passed", false)):
		errors.append_array(Array(registry_contract.get("errors", [])))
	var registry_index: Dictionary = registry.call("index")
	if String(registry_index.get("version", "")) != "0.6.0": errors.append("Registry ABI mismatch")
	if String(registry_index.get("visual_version", "")) != "0.6.1": errors.append("Registry visual version mismatch")
	if String(registry_index.get("art_revision", "")) != "0.6.1-rc7": errors.append("Registry art revision mismatch")

	var encounter_report: Dictionary = EncounterComposerScript.new().call("audit_contract")
	if int(encounter_report.get("enemy_roles", 0)) != 18 or int(encounter_report.get("signatures", 0)) < 6 or not bool(encounter_report.get("deterministic", false)):
		errors.append("Authored encounter contract incomplete")
	var relic_report: Dictionary = RelicPoolDirectorScript.new().call("audit_contract")
	if int(relic_report.get("contexts", 0)) < 6 or not bool(relic_report.get("tier_gating", false)):
		errors.append("Contextual relic-pool contract incomplete")
	var fairness_report: Dictionary = FairnessDirectorScript.new().call("audit_contract")
	if float(fairness_report.get("room_grace", 0.0)) < 0.5 or not bool(fairness_report.get("staggered_activation", false)):
		errors.append("Combat-fairness contract incomplete")
	var evolution_report: Dictionary = EvolutionDirectorScript.new().call("audit_contract")
	if int(evolution_report.get("lineages", 0)) != 5 or int(evolution_report.get("options", 0)) != 25 or not bool(evolution_report.get("deterministic_two_choice", false)):
		errors.append("Guardian adaptation contract incomplete")

	var quality: RefCounted = SpriteQualityEvaluatorScript.new()
	var sprite_report := {"heroes":{},"enemies":{},"bosses":{}}
	for id in HERO_IDS:
		var result: Dictionary = quality.call("evaluate_actor", registry.call("hero_sheet", id), Vector2i(48,48), Vector2i(15,24), 3)
		sprite_report["heroes"][id] = result
		if not bool(result.get("passed", false)): errors.append("Hero readability failed: " + id)
	for id in ENEMY_IDS:
		var result: Dictionary = quality.call("evaluate_actor", registry.call("enemy_sheet", id), Vector2i(48,48), Vector2i(14,21), 3)
		sprite_report["enemies"][id] = result
		if not bool(result.get("passed", false)): errors.append("Enemy readability failed: " + id)
	for id in BOSS_IDS:
		var result: Dictionary = quality.call("evaluate_actor", registry.call("boss_sheet", id), Vector2i(96,96), Vector2i(28,34), 3)
		sprite_report["bosses"][id] = result
		if not bool(result.get("passed", false)): errors.append("Boss readability failed: " + id)

	var required_paths := [
		"res://scripts/v7/version_manifest.gd","res://scripts/v7/encounter_composer.gd","res://scripts/v7/relic_pool_director.gd",
		"res://scripts/v7/combat_fairness_director.gd","res://scripts/v7/lineage_evolution_director.gd","res://scripts/v7/sprite_quality_evaluator.gd",
		"res://scripts/v7/audio_asset_factory_masterpiece.gd","res://scripts/v7/actor_asset_factory_masterpiece.gd","res://scripts/v7/generated_asset_factory_masterpiece.gd",
		"res://scripts/v7/asset_registry_masterpiece.gd","res://scripts/edenfall_v7_masterpiece_runtime.gd","res://scripts/edenfall_v7_fairness_runtime.gd",
		"res://scripts/edenfall_v7_audio_runtime.gd",ART_SCRIPT,PROGRESSION_SCRIPT,FINAL_SCRIPT,"res://tests/v7_runtime_quality_audit.gd"
	]
	for path in required_paths:
		if not ResourceLoader.exists(path): errors.append("Missing RC7 resource: " + path)

	if not _source_contract(PROGRESSION_SCRIPT, ["genome_adaptation","PROGRESSION_PATH","adaptation_suspend_safe","run_only_lineage_evolution"]): errors.append("Progression source contract failed")
	if not _source_contract(FINAL_SCRIPT, ["adaptations_discovered","profile_schema_preseed","audit_masterpiece_contract"]): errors.append("Release schema source contract failed")
	if not _source_contract(ART_SCRIPT, ["runtime_shallow","safe_state_asset_prewarm","biome_pool_cache_retention"]): errors.append("Art/loading source contract failed")

	var runtime_report: Dictionary = {}
	var inherited_report: Dictionary = {}
	var main_scene := load("res://main.tscn") as PackedScene
	if main_scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance := main_scene.instantiate()
		var script := instance.get_script() as Script
		if script == null or script.resource_path != FINAL_SCRIPT: errors.append("main.tscn is not routed to RC7 release runtime")
		if instance.has_method("audit_masterpiece_contract"):
			runtime_report = instance.call("audit_masterpiece_contract")
			for flag in ["cover_aware_aim_assist","deterministic_composition","contextual_relic_pools","post_enter_cover_resolution","room_entry_grace","staggered_enemy_materialization","post_transition_spawn_clearance","hazards_respect_entry_grace","semantic_warning_audio","masterpiece_asset_registry","pixel_finish","safe_state_asset_prewarm","biome_pool_cache_retention","shallow_startup_deep_release_audit","guardian_adaptation_choices","adaptation_suspend_safe","run_only_lineage_evolution","profile_schema_preseed"]:
				if not bool(runtime_report.get(flag, false)): errors.append("RC7 runtime flag missing: " + flag)
			if int(runtime_report.get("adaptation_options", 0)) != 25: errors.append("Runtime adaptation option count is not 25")
		else: errors.append("RC7 runtime audit method missing")
		if instance.has_method("audit_godmode_contract"):
			inherited_report = instance.call("audit_godmode_contract")
			for flag in ["restore_guard","mandatory_special_decisions","rng_seed_and_state_restored","archive_pool_progression","faction_ambushes","guardian_environment_phases","all_room_spawns_rng_isolated","serpent_resolution_choice","ending_choice_suspend_safe","deterministic_floor_graph","manual_new_run_clears_stale_ending"]:
				if not bool(inherited_report.get(flag, false)): errors.append("Inherited RC6 flag missing: " + flag)
		else: errors.append("Inherited RC6 audit method missing")
		instance.free()

	var report := {"product_revision":"0.6.1-rc7","engine":engine,"version":version_report,"registry":registry_contract,"encounters":encounter_report,"relics":relic_report,"fairness":fairness_report,"evolutions":evolution_report,"sprite_quality":sprite_report,"runtime":runtime_report,"inherited":inherited_report,"errors":errors,"passed":errors.is_empty()}
	print("EDEN_FALL_V7_REPORT=" + JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V7_MASTERPIECE_AUDIT=PASS")
		quit(0)
	else:
		for error in errors: push_error(error)
		quit(1)

func _source_contract(path: String, symbols: Array[String]) -> bool:
	var source := FileAccess.get_file_as_string(path)
	if source.is_empty(): return false
	for symbol in symbols:
		if source.find(symbol) < 0: return false
	return true
