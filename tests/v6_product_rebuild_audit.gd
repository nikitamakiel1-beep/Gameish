extends SceneTree

const RegistryScript: Script = preload("res://scripts/v6/asset_registry_rebuild.gd")
const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const GodmodeDirectorScript: Script = preload("res://scripts/v6/godmode_director.gd")
const BossPatternLibraryScript: Script = preload("res://scripts/v6/boss_pattern_library.gd")

const HERO_IDS: Array[String] = ["adam", "abel", "cain", "seth", "naamah"]
const ENEMY_IDS: Array[String] = [
	"feral_scavenger", "outlaw_gunner", "raider_brute", "wasteland_hunter", "scrap_cultist", "caravan_outlaw",
	"cherub_drone", "fallen_angel", "watcher_acolyte", "halo_sentinel", "biomech_pilgrim", "ophanim_scout",
	"nephilim_husk", "nephilim_giant", "horned_berserker", "bone_shepherd", "grafted_colossus", "serpent_spawn",
]
const BOSS_IDS: Array[String] = ["watcher_engine", "first_nephilim", "gate_cherub", "tower_enoch", "serpent_interface"]
const BIOME_IDS: Array[String] = ["industrial_eden", "ash_wastes", "temple_lab", "fungal_garden", "nephilim_ruins"]
const UTILITY_IDS: Array[String] = [
	"pickups", "relics", "projectiles", "effects", "hud_panel", "menu_panel",
	"joystick_base", "joystick_thumb", "touch_dash", "touch_interact", "touch_pause",
]

const WORLD_SCRIPT := "res://scripts/edenfall_v6_world_runtime.gd"
const NAVIGATION_SCRIPT := "res://scripts/edenfall_v6_navigation_runtime.gd"
const CONTENT_SCRIPT := "res://scripts/edenfall_v6_content_runtime.gd"
const POLISH_SCRIPT := "res://scripts/edenfall_v6_polish_runtime.gd"
const GODMODE_DIRECTOR := "res://scripts/v6/godmode_director.gd"
const BOSS_LIBRARY := "res://scripts/v6/boss_pattern_library.gd"
const GODMODE_SCRIPT := "res://scripts/edenfall_v6_godmode_runtime.gd"
const STABLE_SCRIPT := "res://scripts/edenfall_v6_godmode_stable_runtime.gd"
const COMPLETE_SCRIPT := "res://scripts/edenfall_v6_godmode_complete_runtime.gd"
const FINAL_SCRIPT := "res://scripts/edenfall_v6_godmode_release_runtime.gd"

func _init() -> void:
	var bootstrap: RefCounted = BootstrapScript.new()
	var engine_report: Dictionary = bootstrap.call("configure")
	if not bool(engine_report.get("exact_version", false)):
		_fail(1, "Product rebuild audit requires exact Godot 4.7.1")
		return

	var registry: RefCounted = RegistryScript.new()
	var contract: Dictionary = registry.call("validate_contract", true)
	if not bool(contract.get("passed", false)):
		for error in Array(contract.get("errors", [])):
			push_error(String(error))
		quit(2)
		return
	var metadata: Dictionary = registry.call("index")
	if String(metadata.get("visual_version", "")) != "0.6.1":
		_fail(3, "Visual registry version is not 0.6.1")
		return

	var uniqueness := {
		"heroes": _texture_hashes(registry, "hero_sheet", HERO_IDS).size(),
		"portraits": _texture_hashes(registry, "hero_portrait", HERO_IDS).size(),
		"enemies": _texture_hashes(registry, "enemy_sheet", ENEMY_IDS).size(),
		"bosses": _texture_hashes(registry, "boss_sheet", BOSS_IDS).size(),
		"backgrounds": _biome_hashes(registry, "background").size(),
		"tiles": _biome_hashes(registry, "tiles").size(),
		"props": _biome_hashes(registry, "props").size(),
	}
	var expected := {
		"heroes": 5, "portraits": 5, "enemies": 18, "bosses": 5,
		"backgrounds": 5, "tiles": 5, "props": 5,
	}
	for key in expected.keys():
		if int(uniqueness[key]) != int(expected[key]):
			_fail(4, "Visual family %s has %d unique atlases; expected %d" % [key, uniqueness[key], expected[key]])
			return

	for utility_id in UTILITY_IDS:
		var utility: Texture2D = registry.call("utility_texture", utility_id)
		if utility == null:
			_fail(5, "Missing utility atlas: " + utility_id)
			return
		var image := utility.get_image()
		if image == null or image.is_empty():
			_fail(5, "Empty utility atlas: " + utility_id)
			return

	var required_paths := [
		"res://scripts/v6/actor_asset_factory_rebuild.gd",
		"res://scripts/v6/support_asset_factory_rebuild.gd",
		"res://scripts/v6/generated_asset_factory_rebuild.gd",
		"res://scripts/v6/asset_registry_rebuild.gd",
		"res://scripts/edenfall_v6_visual_rebuild.gd",
		"res://scripts/edenfall_v6_product_runtime.gd",
		"res://scripts/edenfall_v6_release_candidate.gd",
		WORLD_SCRIPT, NAVIGATION_SCRIPT, CONTENT_SCRIPT, POLISH_SCRIPT,
		GODMODE_DIRECTOR, BOSS_LIBRARY, GODMODE_SCRIPT, STABLE_SCRIPT, COMPLETE_SCRIPT, FINAL_SCRIPT,
	]
	for path in required_paths:
		if not ResourceLoader.exists(String(path)):
			_fail(6, "Product rebuild resource is missing: " + String(path))
			return

	if not _source_contract(WORLD_SCRIPT, ["room_obstacles", "_bullet_hits_obstacle", "_resolve_position_against_obstacles", "_draw_room_obstacles"]):
		return
	if not _source_contract(NAVIGATION_SCRIPT, ["_sweep_actor", "_nearest_cover_normal", "_on_viewport_size_changed"]):
		return
	if not _source_contract(CONTENT_SCRIPT, ["_draw_shop_overlay", "_purchase_selected_shop_item", "draw_archive", "_draw_relic_grid"]):
		return
	if not _source_contract(POLISH_SCRIPT, ["_draw_guardian_strip", "_reconcile_shop_inventory"]):
		return
	if not _source_contract(GODMODE_DIRECTOR, ["FACTIONS", "SYNERGY_RULES", "special_room_assignments", "synergies_for", "serpent_mutation"]):
		return
	if not _source_contract(BOSS_LIBRARY, ["build_pattern", "_watcher_engine", "_first_nephilim", "_gate_cherub", "_tower_enoch", "_serpent_interface"]):
		return
	if not _source_contract(GODMODE_SCRIPT, ["update_bullets", "_apply_rc6_bullet_hit", "_release_enemy_special", "_release_boss_pattern", "_serialize_room_state", "_restore_room_state", "_refresh_build_synergies"]):
		return
	if not _source_contract(STABLE_SCRIPT, ["restore_suspended_run", "SPECIAL_INTERACT_RADIUS", "_special_interaction_point", "mandatory_special_decisions", "audit_godmode_contract"]):
		return
	if not _source_contract(COMPLETE_SCRIPT, ["_archive_relic_tier", "faction_ambushes", "_apply_guardian_phase_environment", "touch_opacity", "reduced_flash"]):
		return
	if not _source_contract(FINAL_SCRIPT, ["ENDING_PENDING_PATH", "_open_serpent_resolution", "serpent_resolution_choice", "all_room_spawns_rng_isolated", "ending_choice_suspend_safe"]):
		return
	if FileAccess.get_file_as_string(WORLD_SCRIPT).find(".translated(") >= 0:
		_fail(7, "World runtime contains an unsupported Rect2 translation call")
		return

	var director: RefCounted = GodmodeDirectorScript.new()
	var director_report: Dictionary = director.call("audit_contract")
	if int(director_report.get("version", 0)) != 6 or int(director_report.get("factions", 0)) != 6 or int(director_report.get("synergies", 0)) < 8:
		_fail(8, "RC6 director contract is incomplete")
		return
	if not bool(director_report.get("deterministic_seed", false)):
		_fail(8, "RC6 director does not report deterministic room seeding")
		return

	var pattern_library: RefCounted = BossPatternLibraryScript.new()
	var boss_report: Dictionary = pattern_library.call("audit_contract")
	if int(boss_report.get("version", 0)) != 6 or int(boss_report.get("bosses", 0)) != 5 or int(boss_report.get("patterns", 0)) != 15:
		_fail(9, "RC6 boss pattern contract must expose 15 patterns across five guardians")
		return

	var main_scene := load("res://main.tscn") as PackedScene
	if main_scene == null:
		_fail(10, "main.tscn failed to load")
		return
	var instance := main_scene.instantiate()
	var script := instance.get_script() as Script
	var script_path := script.resource_path if script != null else ""
	if script_path != FINAL_SCRIPT:
		instance.free()
		_fail(11, "main.tscn does not route to the complete RC6 release runtime: " + script_path)
		return
	var godmode_report: Dictionary = instance.call("audit_godmode_contract")
	instance.free()
	if String(godmode_report.get("version", "")) != "0.6.1-rc6":
		_fail(12, "RC6 release runtime version contract is incorrect")
		return
	for required_flag in [
		"restore_guard", "mandatory_special_decisions", "rng_seed_and_state_restored",
		"archive_pool_progression", "faction_ambushes", "guardian_environment_phases",
		"touch_opacity", "reduced_flash", "all_room_spawns_rng_isolated",
		"serpent_resolution_choice", "ending_choice_suspend_safe",
	]:
		if not bool(godmode_report.get(required_flag, false)):
			_fail(12, "RC6 runtime contract is missing flag: " + required_flag)
			return

	var report := {
		"product_version": "0.6.1-rc6",
		"engine": engine_report,
		"unique_atlases": uniqueness,
		"main_script": script_path,
		"world_collision": true,
		"swept_navigation": true,
		"atlas_archive": true,
		"shop_interface": true,
		"deterministic_special_rooms": true,
		"faction_reputation": true,
		"tag_synergies": int(director_report.get("synergies", 0)),
		"guardian_patterns": int(boss_report.get("patterns", 0)),
		"room_state_suspend": true,
		"weapon_systems_restored_over_cover_collision": true,
		"archive_pool_progression": true,
		"faction_ambushes": true,
		"guardian_environment_phases": true,
		"mobile_accessibility_completed": true,
		"serpent_resolution_choice": true,
		"godmode": godmode_report,
		"contract": contract,
	}
	print("EDEN_FALL_V6_PRODUCT_REPORT=" + JSON.stringify(report))
	print("EDEN_FALL_V6_PRODUCT_AUDIT=PASS")
	quit(0)

func _source_contract(path: String, symbols: Array[String]) -> bool:
	var source := FileAccess.get_file_as_string(path)
	if source.is_empty():
		_fail(7, "Runtime source could not be read: " + path)
		return false
	for symbol in symbols:
		if source.find(symbol) < 0:
			_fail(7, "%s is missing required symbol: %s" % [path, symbol])
			return false
	return true

func _texture_hashes(registry: RefCounted, method: String, ids: Array[String]) -> Dictionary:
	var signatures: Dictionary = {}
	for id in ids:
		var texture: Texture2D = registry.call(method, id)
		if texture == null:
			continue
		var image := texture.get_image()
		if image != null and not image.is_empty():
			signatures[hash(image.get_data())] = id
	return signatures

func _biome_hashes(registry: RefCounted, kind: String) -> Dictionary:
	var signatures: Dictionary = {}
	for id in BIOME_IDS:
		var texture: Texture2D = registry.call("biome_texture", id, kind)
		if texture == null:
			continue
		var image := texture.get_image()
		if image != null and not image.is_empty():
			signatures[hash(image.get_data())] = id
	return signatures

func _fail(code: int, message: String) -> void:
	push_error(message)
	quit(code)
