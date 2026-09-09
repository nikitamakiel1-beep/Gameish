extends SceneTree

const RegistryScript: Script = preload("res://scripts/v6/asset_registry_rebuild.gd")
const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const GodmodeDirectorScript: Script = preload("res://scripts/v6/godmode_director.gd")
const BossPatternLibraryScript: Script = preload("res://scripts/v6/boss_pattern_library.gd")

const FINAL_SCRIPT := "res://scripts/edenfall_v8_release_runtime.gd"
const REQUIRED_V6_PATHS := [
	"res://scripts/v6/actor_asset_factory_rebuild.gd",
	"res://scripts/v6/support_asset_factory_rebuild.gd",
	"res://scripts/v6/generated_asset_factory_rebuild.gd",
	"res://scripts/v6/asset_registry_rebuild.gd",
	"res://scripts/edenfall_v6_visual_rebuild.gd",
	"res://scripts/edenfall_v6_product_runtime.gd",
	"res://scripts/edenfall_v6_release_candidate.gd",
	"res://scripts/edenfall_v6_world_runtime.gd",
	"res://scripts/edenfall_v6_navigation_runtime.gd",
	"res://scripts/edenfall_v6_content_runtime.gd",
	"res://scripts/edenfall_v6_polish_runtime.gd",
	"res://scripts/edenfall_v6_godmode_runtime.gd",
	"res://scripts/edenfall_v6_godmode_stable_runtime.gd",
	"res://scripts/edenfall_v6_godmode_complete_runtime.gd",
	"res://scripts/edenfall_v6_godmode_release_runtime.gd",
	"res://scripts/edenfall_v6_godmode_verified_runtime.gd",
]

func _init() -> void:
	var errors: Array[String] = []
	var engine: Dictionary = BootstrapScript.new().call("configure")
	if not bool(engine.get("exact_version",false)): errors.append("Exact Godot 4.7.1 is required")

	var registry: RefCounted = RegistryScript.new()
	var asset_contract: Dictionary = registry.call("validate_contract",true)
	if not bool(asset_contract.get("passed",false)): errors.append_array(Array(asset_contract.get("errors",[])))
	var metadata: Dictionary = registry.call("index")
	if String(metadata.get("visual_version","")) != "0.6.1": errors.append("RC6 visual registry compatibility version mismatch")

	for path in REQUIRED_V6_PATHS:
		if not ResourceLoader.exists(path): errors.append("Missing inherited RC6 resource: "+String(path))

	var director_report: Dictionary = GodmodeDirectorScript.new().call("audit_contract")
	if int(director_report.get("factions",0)) != 6: errors.append("RC6 faction contract missing")
	if int(director_report.get("synergies",0)) < 8: errors.append("RC6 synergy contract missing")
	var boss_report: Dictionary = BossPatternLibraryScript.new().call("audit_contract")
	if int(boss_report.get("bosses",0)) != 5 or int(boss_report.get("patterns",0)) != 15: errors.append("RC6 guardian pattern contract missing")

	var main_scene := load("res://main.tscn") as PackedScene
	var inherited: Dictionary = {}
	var entropy: Dictionary = {}
	if main_scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance := main_scene.instantiate()
		var script := instance.get_script() as Script
		if script == null or script.resource_path != FINAL_SCRIPT: errors.append("main.tscn is not routed through the V8 release root")
		if instance.has_method("audit_godmode_contract"):
			inherited = instance.call("audit_godmode_contract")
			for flag in ["restore_guard","mandatory_special_decisions","rng_seed_and_state_restored","archive_pool_progression","faction_ambushes","guardian_environment_phases","touch_opacity","reduced_flash","all_room_spawns_rng_isolated","serpent_resolution_choice","ending_choice_suspend_safe","manual_new_run_clears_stale_ending"]:
				if not bool(inherited.get(flag,false)): errors.append("Inherited RC6 guarantee missing under V8: "+flag)
			if bool(inherited.get("deterministic_floor_graph",true)): errors.append("V8 must supersede RC6 deterministic floor generation")
			if not bool(inherited.get("entropy_floor_graph",false)): errors.append("V8 entropy floor override is missing")
		else:
			errors.append("Inherited RC6 godmode audit is unavailable")
		if instance.has_method("audit_entropy_contract"): entropy = instance.call("audit_entropy_contract")
		instance.free()

	var report := {
		"compatibility_layer":"RC6 under V8",
		"engine":engine,
		"asset_contract":asset_contract,
		"director":director_report,
		"guardians":boss_report,
		"inherited":inherited,
		"entropy":entropy,
		"errors":errors,
		"passed":errors.is_empty(),
	}
	print("EDEN_FALL_V6_COMPAT_REPORT="+JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V6_COMPAT_AUDIT=PASS")
		quit(0)
	else:
		for error in errors: push_error(error)
		quit(1)
