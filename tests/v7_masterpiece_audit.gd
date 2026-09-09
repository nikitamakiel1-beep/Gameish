extends SceneTree

const RegistryScript: Script = preload("res://scripts/v7/asset_registry_masterpiece.gd")
const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const EncounterComposerScript: Script = preload("res://scripts/v7/encounter_composer.gd")
const RelicPoolDirectorScript: Script = preload("res://scripts/v7/relic_pool_director.gd")
const FairnessDirectorScript: Script = preload("res://scripts/v7/combat_fairness_director.gd")
const EvolutionDirectorScript: Script = preload("res://scripts/v7/lineage_evolution_director.gd")
const SpriteQualityEvaluatorScript: Script = preload("res://scripts/v7/sprite_quality_evaluator.gd")

const FINAL_SCRIPT := "res://scripts/edenfall_v8_release_runtime.gd"
const HERO_IDS: Array[String] = ["adam","abel","cain","seth","naamah"]
const ENEMY_IDS: Array[String] = ["feral_scavenger","outlaw_gunner","raider_brute","wasteland_hunter","scrap_cultist","caravan_outlaw","cherub_drone","fallen_angel","watcher_acolyte","halo_sentinel","biomech_pilgrim","ophanim_scout","nephilim_husk","nephilim_giant","horned_berserker","bone_shepherd","grafted_colossus","serpent_spawn"]
const BOSS_IDS: Array[String] = ["watcher_engine","first_nephilim","gate_cherub","tower_enoch","serpent_interface"]

func _quality_error(label: String, id: String, result: Dictionary) -> String:
	return "%s readability failed: %s // %s // occupancy=%.4f bbox=%.1fx%.1f directions=%d action_rows=%d sampled_actions=%d" % [
		label,
		id,
		String(result.get("reason","unspecified")),
		float(result.get("occupancy",0.0)),
		float(result.get("bbox_width",0.0)),
		float(result.get("bbox_height",0.0)),
		int(result.get("unique_direction_silhouettes",0)),
		int(result.get("action_rows",0)),
		int(result.get("sampled_action_rows",0)),
	]

func _init() -> void:
	var errors: Array[String] = []
	var engine: Dictionary = BootstrapScript.new().call("configure")
	if not bool(engine.get("exact_version",false)): errors.append("Exact Godot 4.7.1 is required")

	var registry: RefCounted = RegistryScript.new()
	var registry_contract: Dictionary = registry.call("validate_contract",true)
	if not bool(registry_contract.get("passed",false)): errors.append_array(Array(registry_contract.get("errors",[])))
	var index: Dictionary = registry.call("index")
	if String(index.get("art_revision","")) != "0.6.1-rc7": errors.append("RC7 art registry compatibility revision mismatch")

	var composer: Dictionary = EncounterComposerScript.new().call("audit_contract")
	if int(composer.get("enemy_roles",0)) != 18 or int(composer.get("signatures",0)) < 6: errors.append("RC7 authored encounter grammar missing")
	var relics: Dictionary = RelicPoolDirectorScript.new().call("audit_contract")
	if int(relics.get("contexts",0)) < 6 or not bool(relics.get("tier_gating",false)): errors.append("RC7 contextual relic grammar missing")
	var fairness: Dictionary = FairnessDirectorScript.new().call("audit_contract")
	if float(fairness.get("room_grace",0.0)) < 0.5 or not bool(fairness.get("staggered_activation",false)): errors.append("RC7 fairness contract missing")
	var evolutions: Dictionary = EvolutionDirectorScript.new().call("audit_contract")
	if int(evolutions.get("lineages",0)) != 5 or int(evolutions.get("options",0)) != 25: errors.append("RC7 lineage evolution catalog missing")

	var quality: RefCounted = SpriteQualityEvaluatorScript.new()
	for id in HERO_IDS:
		var result: Dictionary = quality.call("evaluate_actor",registry.call("hero_sheet",id),Vector2i(48,48),Vector2i(15,24),3)
		if not bool(result.get("passed",false)): errors.append(_quality_error("RC7 base hero",id,result))
	for id in ENEMY_IDS:
		var result: Dictionary = quality.call("evaluate_actor",registry.call("enemy_sheet",id),Vector2i(48,48),Vector2i(14,21),3)
		if not bool(result.get("passed",false)): errors.append(_quality_error("RC7 base enemy",id,result))
	for id in BOSS_IDS:
		var result: Dictionary = quality.call("evaluate_actor",registry.call("boss_sheet",id),Vector2i(96,96),Vector2i(28,34),3)
		if not bool(result.get("passed",false)): errors.append(_quality_error("RC7 base guardian",id,result))

	var runtime_report: Dictionary = {}
	var entropy_report: Dictionary = {}
	var main_scene := load("res://main.tscn") as PackedScene
	if main_scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance := main_scene.instantiate()
		var script := instance.get_script() as Script
		if script == null or script.resource_path != FINAL_SCRIPT: errors.append("main.tscn is not routed through V8 release root")
		if instance.has_method("audit_masterpiece_contract"):
			runtime_report = instance.call("audit_masterpiece_contract")
			for flag in ["cover_aware_aim_assist","contextual_relic_pools","post_enter_cover_resolution","room_entry_grace","staggered_enemy_materialization","post_transition_spawn_clearance","hazards_respect_entry_grace","semantic_warning_audio","masterpiece_asset_registry","pixel_finish","safe_state_asset_prewarm","biome_pool_cache_retention","shallow_startup_deep_release_audit","guardian_adaptation_choices","adaptation_suspend_safe","run_only_lineage_evolution","profile_schema_preseed"]:
				if not bool(runtime_report.get(flag,false)): errors.append("Inherited RC7 runtime flag missing under V8: "+flag)
		else: errors.append("RC7 masterpiece audit method unavailable through V8")
		if instance.has_method("audit_entropy_contract"):
			entropy_report = instance.call("audit_entropy_contract")
			if bool(entropy_report.get("fixed_seed_replay",true)): errors.append("V8 must replace seed-replay generation")
			if not bool(entropy_report.get("procedural_actor_sheets",false)): errors.append("V8 procedural sprite forge not active")
		else: errors.append("V8 entropy audit method unavailable")
		instance.free()

	var report := {"compatibility_layer":"RC7 under V8","engine":engine,"registry":registry_contract,"encounters":composer,"relics":relics,"fairness":fairness,"evolutions":evolutions,"runtime":runtime_report,"entropy":entropy_report,"errors":errors,"passed":errors.is_empty()}
	print("EDEN_FALL_V7_COMPAT_REPORT="+JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V7_COMPAT_AUDIT=PASS")
		quit(0)
	else:
		for error in errors: push_error(error)
		quit(1)
