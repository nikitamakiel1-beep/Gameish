extends "res://scripts/edenfall_v7_audio_runtime.gd"

const ART_RUNTIME_VERSION := "0.6.1-rc7"
const MasterpieceRegistryScript: Script = preload("res://scripts/v7/asset_registry_masterpiece.gd")

var _prewarm_queue: Array[Dictionary] = []
var _prewarm_seen: Dictionary = {}
var _prewarm_clock := 0.0

func _ready() -> void:
	super._ready()
	production_assets = MasterpieceRegistryScript.new()
	v6_asset_report = audit_v6_readiness()
	readiness = float(v6_asset_report.get("readiness", 0.0))
	_queue_frontend_prewarm()
	_queue_biome_prewarm()
	if state == "run":
		play_biome_audio(true)
	queue_redraw()

func start_new_run(lineage_index: int, seed_override: int = 0) -> void:
	_prewarm_queue.clear()
	_prewarm_seen.clear()
	super.start_new_run(lineage_index, seed_override)
	_queue_frontend_prewarm()
	_queue_biome_prewarm()

func _process(delta: float) -> void:
	_prewarm_clock = maxf(0.0, _prewarm_clock - delta)
	if _prewarm_clock <= 0.0 and _can_prewarm_now():
		_prewarm_one()
	super._process(delta)

func enter_room(coord: Vector2i, movement_direction: Vector2i) -> void:
	super.enter_room(coord, movement_direction)
	_queue_biome_prewarm()

func audit_v6_readiness() -> Dictionary:
	var errors: Array[String] = []
	var checks := 0
	var passed := 0
	var idx: Dictionary = production_assets.call("index")
	checks += 1
	if String(idx.get("version", "")) == V6_VERSION: passed += 1
	else: errors.append("Production index ABI version mismatch")
	checks += 1
	if Array(idx.get("hero_ids", [])).size() == 5: passed += 1
	else: errors.append("Five hero packs are required")
	checks += 1
	if Array(idx.get("enemy_ids", [])).size() == 18: passed += 1
	else: errors.append("Eighteen enemy packs are required")
	checks += 1
	if Array(idx.get("boss_ids", [])).size() == 5: passed += 1
	else: errors.append("Five boss packs are required")
	checks += 1
	if Array(idx.get("biome_ids", [])).size() == 5: passed += 1
	else: errors.append("Five biome packs are required")
	var asset_contract: Dictionary = production_assets.call("validate_contract", false)
	checks += 1
	if bool(asset_contract.get("passed", false)): passed += 1
	else: errors.append_array(Array(asset_contract.get("errors", [])))
	checks += 1
	if bool(engine_report.get("exact_version", false)): passed += 1
	else: errors.append("Godot runtime is not exactly 4.7.1")
	checks += 1
	if String(ProjectSettings.get_setting("application/config/version", "")) == V6_VERSION: passed += 1
	else: errors.append("Core project ABI version is not v0.6.0")
	checks += 1
	if RenderingServer.get_current_rendering_method() == "gl_compatibility": passed += 1
	else: errors.append("GL Compatibility renderer is required for the full platform matrix")
	checks += 1
	var input_complete := true
	for action in Array(engine_report.get("input_actions", [])):
		if not InputMap.has_action(StringName(action)):
			input_complete = false
			errors.append("Missing input action: %s" % action)
	if input_complete: passed += 1
	return {"version":V6_VERSION,"product_revision":ART_RUNTIME_VERSION,"validation_mode":"runtime_shallow","checks":checks,"passed_checks":passed,"errors":errors,"asset_contract":asset_contract,"engine":engine_report,"readiness":clampf(float(passed) / float(maxi(1, checks)) * 100.0, 0.0, 100.0)}

func _queue_frontend_prewarm() -> void:
	for id in ["adam", "abel", "cain", "seth", "naamah"]:
		_queue_prewarm("portrait", id)
		_queue_prewarm("hero", id)
	for utility_id in ["projectiles", "effects", "pickups", "relics", "hud_panel", "menu_panel"]:
		_queue_prewarm("utility", utility_id)
	for sfx_id in ["warning_melee", "warning_aimed", "warning_radial", "warning_phase", "enemy_shot", "impact_01"]:
		_queue_prewarm("sfx", sfx_id)

func _queue_biome_prewarm() -> void:
	if biome_index < 0 or biome_index >= BIOMES.size():
		return
	_queue_one_biome_package(biome_index, true)
	if biome_index + 1 < BIOMES.size():
		_queue_one_biome_package(biome_index + 1, false)

func _queue_one_biome_package(index: int, include_visuals: bool) -> void:
	var biome_id := String(BIOMES[index]["id"])
	_queue_prewarm("biome_audio", biome_id, "music")
	_queue_prewarm("biome_audio", biome_id, "ambience")
	if not include_visuals:
		return
	for kind in ["background", "tiles", "props"]:
		_queue_prewarm("biome", biome_id, kind)
	for enemy_id in enemy_pool_for_biome():
		_queue_prewarm("enemy", String(enemy_id))
	if index < BOSS_IDS.size():
		_queue_prewarm("boss", String(BOSS_IDS[index]))

func _queue_prewarm(kind: String, id: String, subkind: String = "") -> void:
	var key := "%s:%s:%s" % [kind, id, subkind]
	if _prewarm_seen.has(key):
		return
	_prewarm_seen[key] = true
	_prewarm_queue.append({"kind":kind, "id":id, "subkind":subkind})

func _can_prewarm_now() -> bool:
	if _prewarm_queue.is_empty(): return false
	if state in ["title", "select"]: return true
	if state != "run" or not enemies.is_empty() or paused or settings_open or archive_open: return false
	if not room_graph.has(current_room): return false
	var room: Dictionary = room_graph[current_room]
	return String(room.get("kind", "")) not in ["combat", "trial", "contract", "boss"]

func _prewarm_one() -> void:
	if _prewarm_queue.is_empty(): return
	var entry: Dictionary = _prewarm_queue.pop_front()
	var kind := String(entry.get("kind", ""))
	var id := String(entry.get("id", ""))
	var subkind := String(entry.get("subkind", ""))
	match kind:
		"hero": production_assets.call("hero_sheet", id)
		"portrait": production_assets.call("hero_portrait", id)
		"enemy": production_assets.call("enemy_sheet", id)
		"boss": production_assets.call("boss_sheet", id)
		"biome": production_assets.call("biome_texture", id, subkind if not subkind.is_empty() else "background")
		"biome_audio": production_assets.call("biome_audio", id, subkind if not subkind.is_empty() else "music")
		"utility": production_assets.call("utility_texture", id)
		"sfx": production_assets.call("sfx", id)
	_prewarm_clock = 0.10

func _trim_runtime_assets() -> void:
	if biome_index < 0 or biome_index >= BIOMES.size(): return
	var retained_enemy_ids: Array[String] = []
	for id in enemy_pool_for_biome():
		var enemy_id := String(id)
		if enemy_id not in retained_enemy_ids: retained_enemy_ids.append(enemy_id)
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		var enemy_id := String(enemy.get("id", ""))
		if not enemy_id.is_empty() and enemy_id not in retained_enemy_ids: retained_enemy_ids.append(enemy_id)
	var active_boss := String(BOSS_IDS[biome_index]) if biome_index < BOSS_IDS.size() else ""
	production_assets.call("trim_runtime_cache", String(BIOMES[biome_index]["id"]), retained_enemy_ids, active_boss)

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["art_runtime_version"] = ART_RUNTIME_VERSION
	report["art_registry"] = production_assets.call("index")
	report["prewarm_pending"] = _prewarm_queue.size()
	report["prewarm_seen"] = _prewarm_seen.size()
	report["startup_validation_mode"] = "runtime_shallow"
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["version"] = ART_RUNTIME_VERSION
	report["masterpiece_asset_registry"] = true
	report["pixel_finish"] = true
	report["safe_state_asset_prewarm"] = true
	report["biome_pool_cache_retention"] = true
	report["transition_audio_prewarm"] = true
	report["biome_audio_cache_retention"] = true
	report["shallow_startup_deep_release_audit"] = true
	return report
