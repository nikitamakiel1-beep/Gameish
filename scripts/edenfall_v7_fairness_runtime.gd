extends "res://scripts/edenfall_v7_masterpiece_runtime.gd"

const FAIRNESS_VERSION := "0.6.1-rc7"
const FairnessDirectorScript: Script = preload("res://scripts/v7/combat_fairness_director.gd")

var fairness_director: RefCounted = FairnessDirectorScript.new()
var room_grace := 0.0

func enter_room(coord: Vector2i, movement_direction: Vector2i) -> void:
	super.enter_room(coord, movement_direction)
	room_grace = float(fairness_director.ROOM_GRACE)
	_apply_entry_fairness()

func _apply_entry_fairness() -> void:
	if state != "run" or player.is_empty() or enemies.is_empty():
		return
	var player_pos := Vector2(player["pos"])
	var arena := arena_rect()
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		var boss := bool(enemy.get("boss", false))
		enemy["activation_delay"] = float(fairness_director.call("materialize_delay", index, boss))
		enemy["activation_delay_max"] = float(enemy["activation_delay"])
		var enemy_pos := Vector2(enemy["pos"])
		var clearance := float(fairness_director.call("clearance", boss))
		if enemy_pos.distance_to(player_pos) < clearance:
			var away := enemy_pos - player_pos
			if away.length_squared() < 0.001:
				away = arena.get_center() - player_pos
			if away.length_squared() < 0.001:
				away = Vector2.RIGHT.rotated(float(index) * 1.73)
			enemy_pos = player_pos + away.normalized() * clearance
			enemy_pos = clamp_to_arena(enemy_pos, float(enemy["radius"]) + 4.0)
			enemy_pos = _resolve_position_against_obstacles(enemy_pos, float(enemy["radius"]))
			enemy["pos"] = enemy_pos
		enemies[index] = enemy
	_resolve_all_actors_from_obstacles()

func update_run(delta: float) -> void:
	room_grace = maxf(0.0, room_grace - delta)
	super.update_run(delta)

func update_enemy_style(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> Vector2:
	var delay := float(enemy.get("activation_delay", 0.0))
	if delay > 0.0:
		delay = maxf(0.0, delay - delta)
		enemy["activation_delay"] = delay
		enemy["velocity"] = Vector2.ZERO
		enemy["attack"] = maxf(float(enemy.get("attack", 0.0)), delay)
		return Vector2.ZERO
	return super.update_enemy_style(enemy, direction, distance, delta)

func update_boss(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> Vector2:
	var delay := float(enemy.get("activation_delay", 0.0))
	if delay > 0.0:
		delay = maxf(0.0, delay - delta)
		enemy["activation_delay"] = delay
		enemy["velocity"] = Vector2.ZERO
		enemy["attack"] = maxf(float(enemy.get("attack", 0.0)), delay)
		return Vector2.ZERO
	return super.update_boss(enemy, direction, distance, delta)

func spawn_room_crossfire() -> void:
	if room_grace > 0.0:
		return
	super.spawn_room_crossfire()

func pulse_corrosive_grid() -> void:
	if room_grace > 0.0:
		return
	super.pulse_corrosive_grid()

func draw_enemies() -> void:
	super.draw_enemies()
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		var delay := float(enemy.get("activation_delay", 0.0))
		if delay <= 0.0:
			continue
		var maximum := maxf(0.001, float(enemy.get("activation_delay_max", delay)))
		var progress := clampf(1.0 - delay / maximum, 0.0, 1.0)
		var pos := Vector2(enemy["pos"])
		var radius := float(enemy["radius"]) + 12.0
		var accent := Color(BIOMES[biome_index]["accent"])
		draw_circle(pos, float(enemy["radius"]) * (0.45 + progress * 0.42), Color(accent, 0.08 + progress * 0.11))
		draw_arc(pos, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 28, Color(accent, 0.78), 3.0)

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["fairness_version"] = FAIRNESS_VERSION
	report["room_grace"] = room_grace
	report["fairness"] = fairness_director.call("audit_contract")
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["version"] = FAIRNESS_VERSION
	report["room_entry_grace"] = true
	report["staggered_enemy_materialization"] = true
	report["post_transition_spawn_clearance"] = true
	report["hazards_respect_entry_grace"] = true
	return report
