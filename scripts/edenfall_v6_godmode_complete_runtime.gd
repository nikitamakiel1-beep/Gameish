extends "res://scripts/edenfall_v6_godmode_stable_runtime.gd"

const COMPLETE_GODMODE_VERSION := "0.6.1-rc6"

func _ready() -> void:
	if not settings.has("touch_opacity"):
		settings["touch_opacity"] = 0.78
	if not settings.has("reduced_flash"):
		settings["reduced_flash"] = false
	super._ready()

func settings_rows() -> Array:
	var rows: Array = super.settings_rows()
	rows.append({"key":"touch_opacity", "label":"TOUCH CONTROL OPACITY"})
	rows.append({"key":"reduced_flash", "label":"REDUCED FLASHING"})
	return rows

func adjust_setting(key: String, direction: int) -> void:
	if key == "touch_opacity":
		var values := [0.45, 0.60, 0.75, 0.90, 1.0]
		var nearest := 0
		for index in range(values.size()):
			if absf(float(settings.get(key, 0.78)) - float(values[index])) < absf(float(settings.get(key, 0.78)) - float(values[nearest])):
				nearest = index
		settings[key] = values[posmod(nearest + direction, values.size())]
		play_sfx("ui")
		return
	super.adjust_setting(key, direction)

func setting_value(key: String) -> String:
	if key == "touch_opacity":
		return "%d%%" % int(round(float(settings.get(key, 0.78)) * 100.0))
	return super.setting_value(key)

func random_relic_id(excluded: Array = []) -> String:
	var catalog := relic_catalog()
	var unlocked_tier := _archive_relic_tier()
	var ids: Array = []
	for id_variant in catalog.keys():
		var id := String(id_variant)
		if id in excluded:
			continue
		var definition: Dictionary = catalog[id]
		if int(definition.get("tier", 1)) <= unlocked_tier:
			ids.append(id)
	if ids.is_empty():
		return super.random_relic_id(excluded)
	return String(ids[rng.randi_range(0, ids.size() - 1)])

func _archive_relic_tier() -> int:
	var mastery := int(profile.get("mastery", 0))
	var records := Array(profile.get("archive_records", [])).size()
	var guardians := Array(profile.get("guardians_defeated", [])).size()
	var tier := 1
	if mastery >= 180 or records >= 2 or guardians >= 1:
		tier = 2
	if mastery >= 1100 or records >= 5 or guardians >= 3:
		tier = 3
	return tier

func spawn_room(room: Dictionary) -> void:
	super.spawn_room(room)
	var kind := String(room.get("kind", ""))
	if kind not in ["combat", "trial", "contract"] or enemies.is_empty():
		return
	var faction := String(godmode_director.call("faction_for", biome_index, current_room, run_seed))
	var reps: Dictionary = profile.get("faction_reputation", {})
	var reputation := int(reps.get(faction, 0))
	if reputation > -4 or enemies.size() >= 9:
		return
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = int(godmode_director.call("room_seed", run_seed, current_room, biome_index, int(room.get("depth", 0)), 1447))
	var chance := clampf(0.16 + float(abs(reputation) - 4) * 0.045, 0.16, 0.52)
	if local_rng.randf() > chance:
		return
	var ambusher := "caravan_outlaw" if local_rng.randf() < 0.56 else "outlaw_gunner"
	var positions := _encounter_positions(8)
	var spawn_pos := positions[local_rng.randi_range(0, positions.size() - 1)] if not positions.is_empty() else random_arena_position(105.0)
	spawn_enemy(ambusher, spawn_pos, _enemy_uid_counter)
	if reputation <= -8 and not enemies.is_empty():
		promote_enemy_to_elite(enemies.size() - 1, "swift")
	notify("FACTION RETALIATION // %s AMBUSH" % String(Dictionary(godmode_director.call("faction_definition", faction)).get("name", faction)).to_upper())

func update_boss(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> Vector2:
	var stage_before := int(enemy.get("stage", 0))
	var boss_id := String(enemy.get("id", "watcher_engine"))
	var velocity := super.update_boss(enemy, direction, distance, delta)
	var stage_after := int(enemy.get("stage", 0))
	if stage_after > stage_before:
		_apply_guardian_phase_environment(boss_id, enemy, stage_after)
	return velocity

func _apply_guardian_phase_environment(boss_id: String, enemy: Dictionary, stage: int) -> void:
	var origin := Vector2(enemy.get("pos", arena_rect().get_center()))
	match boss_id:
		"first_nephilim":
			_shatter_guardian_cover(origin, stage)
			notify("FIRST NEPHILIM // ARENA STRUCTURE FAILING")
		"gate_cherub":
			var count := mini(2 + stage, maxi(0, 9 - enemies.size()))
			for index in range(count):
				var angle := TAU * float(index) / float(maxi(1, count)) + float(stage) * 0.4
				spawn_enemy("cherub_drone", _resolve_position_against_obstacles(origin + Vector2.RIGHT.rotated(angle) * 118.0, 17.0), _enemy_uid_counter)
			notify("GATE CHERUB // AUXILIARY BODIES DEPLOYED")
		"tower_enoch":
			spawn_room_crossfire()
			room_hazard_timer = minf(room_hazard_timer, 1.25)
			notify("TOWER OF ENOCH // MACHINE LEVEL RECONFIGURED")
		"serpent_interface":
			var count := mini(1 + stage, maxi(0, 9 - enemies.size()))
			for index in range(count):
				var angle := TAU * float(index) / float(maxi(1, count)) - float(stage) * 0.37
				spawn_enemy("serpent_spawn", _resolve_position_against_obstacles(origin + Vector2.RIGHT.rotated(angle) * 106.0, 23.0), _enemy_uid_counter)
			notify("SERPENT INTERFACE // FORKED HOSTS MATERIALIZED")
		_:
			pass

func _shatter_guardian_cover(origin: Vector2, count: int) -> void:
	for iteration in range(count):
		if room_obstacles.is_empty():
			return
		var nearest_index := -1
		var nearest_distance := INF
		for index in range(room_obstacles.size()):
			var rect := Rect2(Dictionary(room_obstacles[index]).get("rect", Rect2()))
			var distance := origin.distance_squared_to(rect.get_center())
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_index = index
		if nearest_index < 0:
			return
		var removed: Dictionary = room_obstacles[nearest_index]
		var rect := Rect2(removed.get("rect", Rect2()))
		room_obstacles.remove_at(nearest_index)
		spawn_effect("explosion", rect.get_center(), Color8(213, 100, 72), 0.0)

func spawn_effect(id: String, position: Vector2, color: Color, angle: float) -> void:
	var safe_color := color
	if bool(settings.get("reduced_flash", false)) and id in ["boss_phase", "explosion", "muzzle", "critical"]:
		safe_color.a = minf(safe_color.a, 0.58)
	var before := effects.size()
	super.spawn_effect(id, position, safe_color, angle)
	if bool(settings.get("reduced_flash", false)) and effects.size() > before:
		var effect: Dictionary = effects[effects.size() - 1]
		effect["life"] = minf(float(effect.get("life", 0.48)), 0.28)
		effect["max_life"] = minf(float(effect.get("max_life", 0.48)), 0.28)
		effects[effects.size() - 1] = effect

func draw_touch_controls() -> void:
	if not OS.has_feature("mobile") and left_touch_id == -1 and right_touch_id == -1:
		return
	var opacity := clampf(float(settings.get("touch_opacity", 0.78)), 0.35, 1.0)
	var base_texture: Texture2D = production_assets.call("utility_texture", "joystick_base")
	var thumb_texture: Texture2D = production_assets.call("utility_texture", "joystick_thumb")
	var dash_texture: Texture2D = production_assets.call("utility_texture", "touch_dash")
	var interact_texture: Texture2D = production_assets.call("utility_texture", "touch_interact")
	var pause_texture: Texture2D = production_assets.call("utility_texture", "touch_pause")
	var left_center := movement_stick_center()
	var right_center := aim_stick_center()
	if base_texture != null:
		draw_texture_rect(base_texture, Rect2(left_center - Vector2(62, 62), Vector2(124, 124)), false, Color(1, 1, 1, opacity * 0.78))
		draw_texture_rect(base_texture, Rect2(right_center - Vector2(62, 62), Vector2(124, 124)), false, Color(1, 1, 1, opacity * 0.78))
	if thumb_texture != null:
		draw_texture_rect(thumb_texture, Rect2(left_center + input_move * 34.0 - Vector2(26, 26), Vector2(52, 52)), false, Color(1, 1, 1, opacity))
		draw_texture_rect(thumb_texture, Rect2(right_center + input_aim * 34.0 - Vector2(26, 26), Vector2(52, 52)), false, Color(1, 1, 1, opacity))
	if dash_texture != null:
		draw_texture_rect(dash_texture, dash_button_rect(), false, Color(1, 1, 1, opacity))
	if interact_texture != null:
		draw_texture_rect(interact_texture, interact_button_rect(), false, Color(1, 1, 1, opacity))
	if pause_texture != null:
		draw_texture_rect(pause_texture, pause_button_rect(), false, Color(1, 1, 1, opacity * 0.92))
	draw_cooldown_ring(dash_button_rect().get_center(), dash_timer / maxf(0.001, float(player.get("dash_delay", 1.0))), Color8(107, 180, 229))

func draw_archive() -> void:
	super.draw_archive()
	var safe := safe_rect()
	var tier := _archive_relic_tier()
	var mastery := int(profile.get("mastery", 0))
	var records := Array(profile.get("archive_records", [])).size()
	var guardians := Array(profile.get("guardians_defeated", [])).size()
	draw_text_centered("ARCHIVE POOL // RELIC TIER %d/3  •  MASTERY %d  •  MEMORY %d  •  GUARDIANS %d" % [tier, mastery, records, guardians], Vector2(safe.get_center().x, safe.position.y + 64.0), 7, Color8(221, 193, 125))

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["complete_godmode_version"] = COMPLETE_GODMODE_VERSION
	report["archive_relic_tier"] = _archive_relic_tier()
	report["touch_opacity"] = float(settings.get("touch_opacity", 0.78))
	report["reduced_flash"] = bool(settings.get("reduced_flash", false))
	return report

func audit_godmode_contract() -> Dictionary:
	var report: Dictionary = super.audit_godmode_contract()
	report["version"] = COMPLETE_GODMODE_VERSION
	report["archive_pool_progression"] = true
	report["faction_ambushes"] = true
	report["guardian_environment_phases"] = true
	report["touch_opacity"] = true
	report["reduced_flash"] = true
	return report
