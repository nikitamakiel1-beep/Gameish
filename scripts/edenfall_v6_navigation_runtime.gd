extends "res://scripts/edenfall_v6_world_runtime.gd"

const NAVIGATION_VERSION := "0.6.1-rc3"

func _on_viewport_size_changed() -> void:
	super._on_viewport_size_changed()
	_rebuild_room_obstacles()
	_resolve_all_actors_from_obstacles()

func update_player(delta: float) -> void:
	if player.is_empty():
		super.update_player(delta)
		return
	var previous := Vector2(player["pos"])
	var move_direction := input_move
	if dash_time > 0.0:
		move_direction = Vector2(player.get("dash_direction", last_move))
	super.update_player(delta)
	if move_direction.length_squared() < 0.02:
		return
	var current := Vector2(player["pos"])
	var expected_distance := (690.0 if dash_time > 0.0 else float(player["speed"])) * delta * move_direction.length()
	if previous.distance_to(current) >= expected_distance * 0.45:
		return
	var travel := move_direction.normalized() * expected_distance
	var x_candidate := _resolve_position_against_obstacles(previous + Vector2(travel.x, 0.0), PLAYER_RADIUS)
	var y_candidate := _resolve_position_against_obstacles(previous + Vector2(0.0, travel.y), PLAYER_RADIUS)
	player["pos"] = x_candidate if previous.distance_squared_to(x_candidate) >= previous.distance_squared_to(y_candidate) else y_candidate

func update_enemies(delta: float) -> void:
	var previous_positions: Array[Vector2] = []
	for enemy_variant in enemies:
		var enemy_before: Dictionary = enemy_variant
		previous_positions.append(Vector2(enemy_before["pos"]))
	super.update_enemies(delta)
	for index in range(mini(enemies.size(), previous_positions.size())):
		var enemy: Dictionary = enemies[index]
		var velocity := Vector2(enemy.get("velocity", Vector2.ZERO))
		if velocity.length_squared() < 25.0:
			continue
		var previous := previous_positions[index]
		var current := Vector2(enemy["pos"])
		var expected_distance := velocity.length() * delta
		if previous.distance_to(current) >= expected_distance * 0.30:
			continue
		var radius := float(enemy["radius"])
		var cover_normal := _nearest_cover_normal(current, radius)
		if cover_normal.length_squared() < 0.5:
			continue
		var tangent := cover_normal.orthogonal()
		if int(enemy.get("variant", index)) % 2 != 0:
			tangent = -tangent
		if tangent.dot(velocity) < 0.0:
			tangent = -tangent
		var steering_distance := minf(float(enemy["speed"]) * delta * 0.72, 18.0)
		var steered := _resolve_position_against_obstacles(current + tangent.normalized() * steering_distance, radius)
		enemy["pos"] = steered
		enemy["velocity"] = tangent.normalized() * float(enemy["speed"]) * 0.72
		enemies[index] = enemy
	_apply_enemy_separation()

func _nearest_cover_normal(position: Vector2, radius: float) -> Vector2:
	var best_normal := Vector2.ZERO
	var best_distance := INF
	for obstacle in room_obstacles:
		var rect := Rect2(obstacle["rect"])
		var closest := Vector2(clampf(position.x, rect.position.x, rect.end.x), clampf(position.y, rect.position.y, rect.end.y))
		var delta := position - closest
		var distance := delta.length()
		if distance > radius + 4.0 or distance >= best_distance:
			continue
		best_distance = distance
		if distance > 0.001:
			best_normal = delta / distance
		else:
			var from_center := position - rect.get_center()
			best_normal = from_center.normalized() if from_center.length_squared() > 0.001 else Vector2.UP
	return best_normal
