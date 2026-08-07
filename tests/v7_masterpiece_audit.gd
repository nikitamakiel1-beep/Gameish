extends SceneTree

const RegistryScript: Script = preload("res://scripts/v7/asset_registry_masterpiece.gd")
const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const EncounterComposerScript: Script = preload("res://scripts/v7/encounter_composer.gd")
const RelicPoolDirectorScript: Script = preload("res://scripts/v7/relic_pool_director.gd")
const SpriteQualityEvaluatorScript: Script = preload("res://scripts/v7/sprite_quality_evaluator.gd")
const VersionManifestScript: Script = preload("res://scripts/v7/version_manifest.gd")

const FINAL_SCRIPT := "res://scripts/edenfall_v7_art_runtime.gd"
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
		"res://scripts/v7/sprite_quality_evaluator.gd",
		"res://scripts/v7/actor_asset_factory_masterpiece.gd",
		"res://scripts/v7/generated_asset_factory_masterpiece.gd",
		"res://scripts/v7/asset_registry_masterpiece.gd",
		"res://scripts/edenfall_v7_masterpiece_runtime.gd",
		FINAL_SCRIPT,
		"res://tests/v6_product_rebuild_audit.gd",
	]:
		if not ResourceLoader.exists(path):
			errors.append("Missing RC7 resource: " + path)

	if not _source_contract("res://scripts/edenfall_v7_masterpiece_runtime.gd", ["spawn_room", "random_relic_id", "assisted_aim", "draw_enemies", "audit_masterpiece_contract"]):
		errors.append("RC7 gameplay runtime source contract failed")
	if not _source_contract(FINAL_SCRIPT, ["MasterpieceRegistryScript", "audit_v6_readiness", "pixel_finish", "audit_masterpiece_contract"]):
		errors.append("RC7 art runtime source contract failed")

	var main_scene := load("res://main.tscn") as PackedScene
	if main_scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance := main_scene.instantiate()
		var script := instance.get_script() as Script
		var script_path := script.resource_path if script != null else ""
		if script_path != FINAL_SCRIPT:
			errors.append("main.tscn does not route to RC7 art runtime: " + script_path)
		if instance.has_method("audit_masterpiece_contract"):
			var runtime_report: Dictionary = instance.call("audit_masterpiece_contract")
			if String(runtime_report.get("version", "")) != "0.6.1-rc7":
				errors.append("Runtime RC7 version contract failed")
			for flag in ["cover_aware_aim_assist", "deterministic_composition", "contextual_relic_pools", "masterpiece_asset_registry", "pixel_finish"]:
				if not bool(runtime_report.get(flag, false)):
					errors.append("Runtime RC7 contract missing: " + flag)
		else:
			errors.append("RC7 runtime audit method is missing")
		instance.free()

	var report := {
		"product_revision":"0.6.1-rc7",
		"engine":engine,
		"version_manifest":version_report,
		"registry":registry_contract,
		"registry_index":index,
		"encounter_composer":composer_report,
		"relic_pool":relic_report,
		"sprite_quality":sprite_report,
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
