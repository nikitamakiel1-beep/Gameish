extends SceneTree

const RegistryScript: Script = preload("res://scripts/v6/asset_registry_rebuild.gd")
const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")

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
const FINAL_SCRIPT := "res://scripts/edenfall_v6_polish_runtime.gd"

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
		WORLD_SCRIPT, NAVIGATION_SCRIPT, CONTENT_SCRIPT, FINAL_SCRIPT,
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
	if not _source_contract(FINAL_SCRIPT, ["_draw_guardian_strip", "_reconcile_shop_inventory"]):
		return
	if FileAccess.get_file_as_string(WORLD_SCRIPT).find(".translated(") >= 0:
		_fail(7, "World runtime contains an unsupported Rect2 translation call")
		return

	var main_scene := load("res://main.tscn") as PackedScene
	if main_scene == null:
		_fail(8, "main.tscn failed to load")
		return
	var instance := main_scene.instantiate()
	var script := instance.get_script() as Script
	var script_path := script.resource_path if script != null else ""
	instance.free()
	if script_path != FINAL_SCRIPT:
		_fail(9, "main.tscn does not route to the final product runtime: " + script_path)
		return

	var report := {
		"product_version": "0.6.1-rc5",
		"engine": engine_report,
		"unique_atlases": uniqueness,
		"main_script": script_path,
		"world_collision": true,
		"swept_navigation": true,
		"atlas_archive": true,
		"shop_interface": true,
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
