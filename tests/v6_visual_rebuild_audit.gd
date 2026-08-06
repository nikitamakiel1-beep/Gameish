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

func _init() -> void:
	var bootstrap: RefCounted = BootstrapScript.new()
	var engine_report: Dictionary = bootstrap.call("configure")
	if not bool(engine_report.get("exact_version", false)):
		push_error("Visual rebuild audit requires exact Godot 4.7.1")
		quit(1)
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
		push_error("Visual registry version is not 0.6.1")
		quit(3)
		return

	var hero_hashes := _texture_hashes(registry, "hero_sheet", HERO_IDS)
	var portrait_hashes := _texture_hashes(registry, "hero_portrait", HERO_IDS)
	var enemy_hashes := _texture_hashes(registry, "enemy_sheet", ENEMY_IDS)
	var boss_hashes := _texture_hashes(registry, "boss_sheet", BOSS_IDS)
	var background_hashes := _biome_hashes(registry, "background")
	var tile_hashes := _biome_hashes(registry, "tiles")
	var prop_hashes := _biome_hashes(registry, "props")

	var expected := {
		"heroes": HERO_IDS.size(),
		"portraits": HERO_IDS.size(),
		"enemies": ENEMY_IDS.size(),
		"bosses": BOSS_IDS.size(),
		"backgrounds": BIOME_IDS.size(),
		"tiles": BIOME_IDS.size(),
		"props": BIOME_IDS.size(),
	}
	var actual := {
		"heroes": hero_hashes.size(),
		"portraits": portrait_hashes.size(),
		"enemies": enemy_hashes.size(),
		"bosses": boss_hashes.size(),
		"backgrounds": background_hashes.size(),
		"tiles": tile_hashes.size(),
		"props": prop_hashes.size(),
	}
	for key in expected.keys():
		if int(actual[key]) != int(expected[key]):
			push_error("Visual family is not materially differentiated: %s has %d unique atlases, expected %d" % [key, actual[key], expected[key]])
			quit(4)
			return

	for utility_id in ["pickups", "relics", "projectiles", "effects", "hud_panel", "menu_panel", "joystick_base", "joystick_thumb", "touch_dash", "touch_interact", "touch_pause"]:
		var utility: Texture2D = registry.call("utility_texture", utility_id)
		if utility == null or utility.get_image().is_empty():
			push_error("Missing rebuilt utility atlas: " + utility_id)
			quit(5)
			return

	var main_scene := load("res://main.tscn") as PackedScene
	if main_scene == null:
		push_error("main.tscn failed to load")
		quit(6)
		return
	var instance := main_scene.instantiate()
	var script := instance.get_script() as Script
	var script_path := script.resource_path if script != null else ""
	instance.free()
	if script_path != "res://scripts/edenfall_v6_visual_rebuild.gd":
		push_error("main.tscn does not route to the visual rebuild runtime: " + script_path)
		quit(7)
		return

	var report := {
		"visual_version": metadata.get("visual_version", ""),
		"unique_atlases": actual,
		"main_script": script_path,
		"contract": contract,
	}
	print("EDEN_FALL_V6_VISUAL_REPORT=" + JSON.stringify(report))
	print("EDEN_FALL_V6_VISUAL_AUDIT=PASS")
	quit(0)

func _texture_hashes(registry: RefCounted, method: String, ids: Array[String]) -> Dictionary:
	var signatures: Dictionary = {}
	for id in ids:
		var texture: Texture2D = registry.call(method, id)
		if texture == null:
			continue
		var image := texture.get_image()
		if image == null or image.is_empty():
			continue
		signatures[hash(image.get_data())] = id
	return signatures

func _biome_hashes(registry: RefCounted, kind: String) -> Dictionary:
	var signatures: Dictionary = {}
	for id in BIOME_IDS:
		var texture: Texture2D = registry.call("biome_texture", id, kind)
		if texture == null:
			continue
		var image := texture.get_image()
		if image == null or image.is_empty():
			continue
		signatures[hash(image.get_data())] = id
	return signatures
