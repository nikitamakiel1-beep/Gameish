extends SceneTree

const RegistryScript: Script = preload("res://scripts/v7/asset_registry_masterpiece.gd")
const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const EncounterComposerScript: Script = preload("res://scripts/v7/encounter_composer.gd")
const RelicPoolDirectorScript: Script = preload("res://scripts/v7/relic_pool_director.gd")
const SpriteQualityEvaluatorScript: Script = preload("res://scripts/v7/sprite_quality_evaluator.gd")
const FairnessDirectorScript: Script = preload("res://scripts/v7/combat_fairness_director.gd")
const EvolutionDirectorScript: Script = preload("res://scripts/v7/lineage_evolution_director.gd")
const VersionManifestScript: Script = preload("res://scripts/v7/version_manifest.gd")

const ART_SCRIPT := "res://scripts/edenfall_v7_art_runtime.gd"
const FINAL_SCRIPT := "res://scripts/edenfall_v7_progression_runtime.gd"
const HERO_IDS: Array[String] = ["adam", "abel", "cain", "seth", "naamah"]
const ENEMY_IDS: Array[String] = [
	"feral_scavenger", "outlaw_gunner", "raider_brute", "wasteland_hunter", "scrap_cultist", "caravan_outlaw",
	"cherub_drone", "fallen_angel", "watcher_acolyte", "halo_sentinel", "biomech_pilgrim", "ophanim_scout",
	"nephilim_husk", "nephilim_giant", "horned_berserker", "bone_shepherd", "grafted_colossus", "serpent_spawn",
]
const BOSS_IDS: Array[String] = ["watcher_engine", "first_nephilim", "gate_cherub", "tower_enoch", "serpent_interface"]

func _init() -> void:
	var errors: Array[String] = []
	var bootstrap: RefCounted = BootstrapScript.new()
	var engine: Dictionary = bootstrap.call("configure")
	if not bool(engine.get("exact_version", false)):
		errors.append("Exact Godot 4.7.1 is required")

	var manifest: RefCounted = VersionManifestScript.new()
	var version_report: Dictionary = manifest.call("report")
	if String(version_report.get("product_revision", "")) != "0.6.1-rc7":
		errors.append("RC7 product revision mismatch")
	if String(version_report.get("core_abi_version", "")) != "0.6.0":
		errors.append("Core v0.6 ABI declaration mismatch")

	var registry: RefCounted = RegistryScript.new()
	var registry_contract: Dictionary = registry.call("validate_contract", true)
	if not bool(registry_contract.get("passed", false)):
		errors.append_array(Array(registry_contract.get("errors", [])))
	var index: Dictionary = registry.call("index")
	if String(index.get("version", "")) != String(version_report.get("core_abi_version", "")):
		errors.append("Asset registry ABI does not match version manifest")
	if String(index.get("visual_version", "")) != String(version_report.get("visual_version", "")):
		errors.append("Visual registry version does not match version manifest")
	if String(index.get("art_revision", "")) != "0.6.1-rc7":
		errors.append("Masterpiece art registry revision mismatch")

	var composer: RefCounted = EncounterComposerScript.new()
	var composer_report: Dictionary = composer.call("audit_contract")
	if int(composer_report.get("enemy_roles", 0)) != 18:
		errors.append("Encounter composer must classify all 18 enemy IDs")
	if int(composer_report.get("signatures", 0)) < 6:
		errors.append("At least six encounter signatures are required")
	if not bool(composer_report.get("deterministic", false)):
		errors.append("Encounter composition must be deterministic")

	var relic_director: RefCounted = RelicPoolDirectorScript.new()
	var relic_report: Dictionary = relic_director.call("audit_contract")
	if int(relic_report.get("contexts", 0)) < 6 or not bool(relic_report.get("tier_gating", false)):
		errors.append("Contextual relic pool contract is incomplete")

	var fairness_director: RefCounted = FairnessDirectorScript.new()
	var fairness_report: Dictionary = fairness_director.call("audit_contract")
	if float(fairness_report.get("room_grace", 0.0)) < 0.5:
		errors.append("Room-entry grace window is too short")
	if not bool(fairness_report.get("staggered_activation", false)):
		errors.append("Staggered hostile activation contract is missing")

	var evolution_director: RefCounted = EvolutionDirectorScript.new()
	var evolution_report: Dictionary = evolution_director.call("audit_contract")
	if int(evolution_report.get("lineages", 0)) != 5 or int(evolution_report.get("options", 0)) != 25:
		errors.append("Guardian adaptation catalog must expose 25 options across five lineages")
	if not bool(evolution_report.get("deterministic_two_choice", false)):
		errors.append("Guardian adaptations must use deterministic two-choice offers")

	var quality: RefCounted = SpriteQualityEvaluatorScript.new()
	var sprite_report := {"heroes":{}, "enemies":{}, "bosses":{}}
	for id in HERO_IDS:
		var result: Dictionary = quality.call("evaluate_actor", registry.call("hero_sheet", id), Vector2i(48,48), Vector2i(15,24), 3)
		sprite_report["heroes"][id] = result
		if not bool(result.get("passed", false)):
			errors.append("Hero sprite readability gate failed: " + id)
	for id in ENEMY_IDS:
		var result: Dictionary = quality.call("evaluate_actor", registry.call("enemy_sheet", id), Vector2i(48,48), Vector2i(14,21), 3)
		sprite_report["enemies"][id] = result
		if not bool(result.get("passed", false)):
			errors.append("Enemy sprite readability gate failed: " + id)
	for id in BOSS_IDS:
		var result: Dictionary = quality.call("evaluate_actor", registry.call("boss_sheet", id), Vector2i(96,96), Vector2i(28,34), 3)
		sprite_report["bosses"][id] = result
		if not bool(result.get("passed", false)):
			errors.append("Boss sprite readability gate failed: " + id)

	for path in [
		"res://scripts/v7/version_manifest.gd",
		"res://scripts/v7/encounter_composer.gd",
		"res://scripts/v7/relic_pool_director.gd",
		"res://scripts/v7/combat_fairness_director.gd",
		"res://scripts/v7/lineage_evolution_director.gd",
		"res://scripts/v7/sprite_quality_evaluator.gd",
		"res://scripts/v7/audio_asset_factory_masterpiece.gd",
		"res://scripts/v7/actor_asset_factory_masterpiece.gd",
		"res://scripts/v7/generated_asset_factory_masterpiece.gd",
		"res://scripts/v7/asset_registry_masterpiece.gd",
		"res://scripts/edenfall_v7_masterpiece_runtime.gd",
		"res://scripts/edenfall_v7_fairness_runtime.gd",
		"res://scripts/edenfall_v7_audio_runtime.gd",
		ART_SCRIPT, FINAL_SCRIPT,
		"res://tests/v7_runtime_quality_audit.gd",
	]:
		if not ResourceLoader.exists(path):
			errors.append("Missing RC7 resource: " + path)

	if not _source_contract("res://scripts/edenfall_v7_masterpiece_runtime.gd", ["spawn_room", "random_relic_id", "assisted_aim", "draw_enemies", "post_enter_cover_resolution"]):
		errors.append("RC7 gameplay runtime source contract failed")
	if not _source_contract("res://scripts/edenfall_v7_fairness_runtime.gd", ["activation_delay", "spawn_room_crossfire", "pulse_corrosive_grid", "post_transition_spawn_clearance"]):
		errors.append("RC7 fairness runtime source contract failed")
	if not _source_contract(ART_SCRIPT, ["MasterpieceRegistryScript", "validate_contract", "runtime_shallow", "safe_state_asset_prewarm", "biome_pool_cache_retention"]):
		errors.append("RC7 art/runtime-loading contract failed")
	if not _source_contract(FINAL_SCRIPT, ["genome_adaptation", "PROGRESSION_PATH", "adaptation_suspend_safe", "run_only_lineage_evolution"]):
		errors.append("RC7 guardian adaptation runtime contract failed")

	var runtime_report: Dictionary = {}
	var godmode_report: Dictionary = {}
	var main_scene := load("res://main.tscn") as PackedScene
	if main_scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance := main_scene.instantiate()
		var script := instance.get_script() as Script
		var script_path := script.resource_path if script != null else ""
		if script_path != FINAL_SCRIPT:
			errors.append("main.tscn does not route to RC7 progression runtime: " + script_path)
		if instance.has_method("audit_masterpiece_contract"):
			runtime_report = instance.call("audit_masterpiece_contract")
			if String(runtime_report.get("version", "")) != "0.6.1-rc7":
				errors.append("Runtime RC7 version contract failed")
			for flag in [
				"cover_aware_aim_assist", "deterministic_composition", "contextual_relic_pools",
				"post_enter_cover_resolution", "room_entry_grace", "staggered_enemy_materialization",
				"post_transition_spawn_clearance", "hazards_respect_entry_grace", "semantic_warning_audio",
				"masterpiece_asset_registry", "pixel_finish", "safe_state_asset_prewarm",
				"biome_pool_cache_retention", "shallow_startup_deep_release_audit",
				"guardian_adaptation_choices", "adaptation_suspend_safe", "run_only_lineage_evolution",
			]:
				if not bool(runtime_report.get(flag, false)):
					errors.append("Runtime RC7 contract missing: " + flag)
			if int(runtime_report.get("adaptation_options", 0)) != 25:
				errors.append("Runtime adaptation option count is not 25")
		else:
			errors.append("RC7 runtime audit method is missing")
		if instance.has_method("audit_godmode_contract"):
			godmode_report = instance.call("audit_godmode_contract")
			for flag in [
				"restore_guard", "mandatory_special_decisions", "rng_seed_and_state_restored",
				"archive_pool_progression", "faction_ambushes", "guardian_environment_phases",
				"all_room_spawns_rng_isolated", "serpent_resolution_choice", "ending_choice_suspend_safe",
				"deterministic_floor_graph", "manual_new_run_clears_stale_ending",
			]:
				if not bool(godmode_report.get(flag, false)):
					errors.append("Inherited RC6 contract missing under RC7: " + flag)
		else:
			errors.append("Inherited RC6 godmode audit method is missing")
		instance.free()

	var report := {
		"product_revision":"0.6.1-rc7",
		"engine":engine,
		"version_manifest":version_report,
		"registry":registry_contract,
		"registry_index":index,
		"encounter_composer":composer_report,
		"relic_pool":relic_report,
		"fairness":fairness_report,
		"evolutions":evolution_report,
		"sprite_quality":sprite_report,
		"runtime":runtime_report,
		"inherited_godmode":godmode_report,
		"errors":errors,
		"passed":errors.is_empty(),
	}
	print("EDEN_FALL_V7_REPORT=" + JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V7_MASTERPIECE_AUDIT=PASS")
		quit(0)
	else:
		for error in errors:
			push_error(error)
		quit(1)

func _source_contract(path: String, symbols: Array[String]) -> bool:
	var source := FileAccess.get_file_as_string(path)
	if source.is_empty():
		return false
	for symbol in symbols:
		if source.find(symbol) < 0:
			return false
	return true
