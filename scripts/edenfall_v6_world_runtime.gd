extends "res://scripts/edenfall_v6_release_candidate.gd"

const WORLD_VERSION := "0.6.1-rc2"

var room_obstacles: Array[Dictionary] = []

func enter_room(coord: Vector2i, movement_direction: Vector2i) -> void:
	super.enter_room(coord, movement_direction)
	_rebuild_room_obstacles()
	_resolve_all_actors_from_obstacles()

func draw_arena() -> void:
	super.draw_arena()
	_draw_room_obstacles()

func update_player(delta: float) -> void:
	var previous := Vector2(player.get("pos", Vector2.ZERO))
	super.update_player(delta)
	if player.is_empty():
		return
	var resolved := _resolve_position_against_obstacles(Vector2(player["pos"]), PLAYER_RADIUS)
	if resolved.distance_squared_to(Vector2(player["pos"])) > 0.01:
		player["pos"] = resolved
		if dash_time > 0.0 and previous.distance_to(resolved) < 2.0:
			dash_time = 0.0

func update_enemies(delta: float) -> void:
	super.update_enemies(delta)
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		enemy["pos"] = _resolve_position_against_obstacles(Vector2(enemy["pos"]), float(enemy["radius"]))
		enemies[index] = enemy
	_apply_enemy_separation()

func update_bullets(delta: float) -> void:
	for index in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[index]
		var previous := Vector2(bullet["pos"])
		var current := previous + Vector2(bullet["vel"]) * delta
		bullet["pos"] = current
		bullet["life"] = float(bullet["life"]) - delta
		if float(bullet["life"]) <= 0.0 or not arena_rect().grow(42.0).has_point(current):
			bullets.remove_at(index)
			continue
		if _bullet_hits_obstacle(previous, current, float(bullet["radius"])):
			spawn_effect("cover_impact", current, Color(bullet["color"]), Vector2(bullet["vel"]).angle())
			play_sfx("impact_01", -11.0, 35)
			bullets.remove_at(index)
			continue
		if String(bullet["owner"]) == "player":
			var consumed := false
			for enemy_index in range(enemies.size() - 1, -1, -1):
				var enemy: Dictionary = enemies[enemy_index]
				if current.distance_to(Vector2(enemy["pos"])) < float(bullet["radius"]) + float(enemy["radius"]):
					damage_enemy(enemy_index, float(bullet["damage"]))
					bullet["pierce"] = int(bullet["pierce"]) - 1
					spawn_effect("impact", current, Color(bullet["color"]), Vector2(bullet["vel"]).angle())
					if int(bullet["pierce"]) < 0:
						consumed = true
						break
			if consumed:
				bullets.remove_at(index)
				continue
		elif current.distance_to(Vector2(player["pos"])) < float(bullet["radius"]) + PLAYER_RADIUS:
			damage_player(float(bullet["damage"]), Vector2(bullet["vel"]).normalized())
			bullets.remove_at(index)
			continue
		if index < bullets.size():
			bullets[index] = bullet

func _rebuild_room_obstacles() -> void:
	room_obstacles.clear()
	if not room_graph.has(current_room):
		return
	var room: Dictionary = room_graph[current_room]
	var room_kind := String(room.get("kind", "combat"))
	if room_kind in ["start", "sanctuary", "treasure"]:
		return
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = int(run_seed) ^ int(current_room.x * 73856093) ^ int(current_room.y * 19349663) ^ int((biome_index + 1) * 83492791)
	var arena := arena_rect()
	var obstacle_count := 2 if room_kind == "boss" else 3 + posmod(int(room.get("depth", 0)) + biome_index, 3)
	var slots := _obstacle_slots(arena)
	for obstacle_index in range(mini(obstacle_count, slots.size())):
		var slot_index := local_rng.randi_range(0, slots.size() - 1)
		var center: Vector2 = slots[slot_index]
		slots.remove_at(slot_index)
		var obstacle_size := _obstacle_size(local_rng, room_kind, obstacle_index)
		var obstacle_rect := Rect2(center - obstacle_size * 0.5, obstacle_size)
		if _blocks_door_lane(obstacle_rect, arena):
			continue
		room_obstacles.append({
			"rect": obstacle_rect,
			"kind": _obstacle_kind(obstacle_index),
			"variant": local_rng.randi_range(0, 3),
		})

func _obstacle_slots(arena: Rect2) -> Array[Vector2]:
	var center := arena.get_center()
	var x_offset := arena.size.x * 0.25
	var y_offset := arena.size.y * 0.22
	return [
		center + Vector2(-x_offset, -y_offset), center + Vector2(x_offset, -y_offset),
		center + Vector2(-x_offset, y_offset), center + Vector2(x_offset, y_offset),
		center + Vector2(-arena.size.x * 0.34, 0), center + Vector2(arena.size.x * 0.34, 0),
		center + Vector2(0, -arena.size.y * 0.31), center + Vector2(0, arena.size.y * 0.31),
	]

func _obstacle_size(local_rng: RandomNumberGenerator, room_kind: String, index: int) -> Vector2:
	if room_kind == "boss":
		return Vector2(68.0, 116.0)
	var long_side := local_rng.randf_range(82.0, 124.0)
	var short_side := local_rng.randf_range(44.0, 68.0)
	return Vector2(long_side, short_side) if index % 2 == 0 else Vector2(short_side, long_side)

func _obstacle_kind(index: int) -> String:
	match biome_index:
		0: return ["planter", "tank", "console", "root_mass"][index % 4]
		1: return ["wreck", "barricade", "concrete", "scrap_heap"][index % 4]
		2: return ["column", "altar", "glass_vat", "circuit_pillar"][index % 4]
		3: return ["fungal_tower", "spore_bed", "root_mass", "mycelial_vat"][index % 4]
		_: return ["ruin_slab", "rib", "bone_altar", "collapsed_tower"][index % 4]

func _blocks_door_lane(rect: Rect2, arena: Rect2) -> bool:
	var horizontal_lane := Rect2(Vector2(arena.position.x, arena.get_center().y - 52.0), Vector2(arena.size.x, 104.0))
	var vertical_lane := Rect2(Vector2(arena.get_center().x - 52.0, arena.position.y), Vector2(104.0, arena.size.y))
	var near_edge := rect.position.x < arena.position.x + 92.0 or rect.end.x > arena.end.x - 92.0 or rect.position.y < arena.position.y + 92.0 or rect.end.y > arena.end.y - 92.0
	return near_edge and (rect.intersects(horizontal_lane) or rect.intersects(vertical_lane))

func _resolve_all_actors_from_obstacles() -> void:
	if not player.is_empty():
		player["pos"] = _resolve_position_against_obstacles(Vector2(player["pos"]), PLAYER_RADIUS)
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		enemy["pos"] = _resolve_position_against_obstacles(Vector2(enemy["pos"]), float(enemy["radius"]))
		enemies[index] = enemy

func _resolve_position_against_obstacles(position: Vector2, radius: float) -> Vector2:
	var resolved := clamp_to_arena(position, radius)
	for _pass_index in range(3):
		var moved := false
		for obstacle in room_obstacles:
			var next := _push_circle_from_rect(resolved, radius, Rect2(obstacle["rect"]))
			if next.distance_squared_to(resolved) > 0.01:
				resolved = clamp_to_arena(next, radius)
				moved = true
		if not moved:
			break
	return resolved

func _push_circle_from_rect(center: Vector2, radius: float, rect: Rect2) -> Vector2:
	var closest := Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
	var delta := center - closest
	var distance_squared := delta.length_squared()
	if distance_squared > 0.0001:
		var distance := sqrt(distance_squared)
		if distance >= radius:
			return center
		return center + delta / distance * (radius - distance)
	if not rect.has_point(center):
		return center
	var left := absf(center.x - rect.position.x)
	var right := absf(rect.end.x - center.x)
	var top := absf(center.y - rect.position.y)
	var bottom := absf(rect.end.y - center.y)
	var minimum := minf(minf(left, right), minf(top, bottom))
	if is_equal_approx(minimum, left): return Vector2(rect.position.x - radius, center.y)
	if is_equal_approx(minimum, right): return Vector2(rect.end.x + radius, center.y)
	if is_equal_approx(minimum, top): return Vector2(center.x, rect.position.y - radius)
	return Vector2(center.x, rect.end.y + radius)

func _bullet_hits_obstacle(previous: Vector2, current: Vector2, radius: float) -> bool:
	for obstacle in room_obstacles:
		var rect := Rect2(obstacle["rect"]).grow(radius)
		if rect.has_point(previous) or rect.has_point(current):
			return true
		var steps := clampi(int(ceil(previous.distance_to(current) / 8.0)), 1, 12)
		for step in range(1, steps + 1):
			if rect.has_point(previous.lerp(current, float(step) / float(steps))):
				return true
	return false

func _draw_room_obstacles() -> void:
	var biome: Dictionary = BIOMES[biome_index]
	var accent := Color(biome["accent"])
	for obstacle in room_obstacles:
		var rect := Rect2(obstacle["rect"])
		var kind := String(obstacle["kind"])
		var variant := int(obstacle["variant"])
		draw_rect(Rect2(rect.position + Vector2(7, 9), rect.size), Color(0, 0, 0, 0.30))
		draw_rect(rect, Color(biome["floor"]).darkened(0.16))
		draw_rect(rect, Color(accent, 0.68), false, 2.0)
		match kind:
			"planter", "root_mass": _draw_plant_cover(rect, accent, variant)
			"tank", "glass_vat", "mycelial_vat": _draw_vat_cover(rect, accent, variant)
			"fungal_tower", "spore_bed": _draw_fungal_cover(rect, accent, variant)
			"rib": _draw_rib_cover(rect, accent)
			_: _draw_structural_cover(rect, accent, variant, kind)

func _draw_plant_cover(rect: Rect2, accent: Color, variant: int) -> void:
	var soil := Rect2(rect.position + Vector2(6, rect.size.y * 0.58), Vector2(rect.size.x - 12.0, rect.size.y * 0.30))
	draw_rect(soil, Color8(45, 37, 28))
	for plant in range(4 + variant):
		var x := rect.position.x + 13.0 + float(plant) * (rect.size.x - 26.0) / float(maxi(1, 3 + variant))
		var root := Vector2(x, soil.position.y)
		draw_line(root, root - Vector2(4.0 - float(plant % 3) * 3.0, 19.0 + float(plant % 2) * 11.0), accent.darkened(0.18), 3.0)
		draw_circle(root - Vector2(5, 15), 5.0, Color(accent.lightened(0.10), 0.72))
		draw_circle(root + Vector2(5, -23), 4.0, Color(accent, 0.66))

func _draw_vat_cover(rect: Rect2, accent: Color, variant: int) -> void:
	var inner := rect.grow(-7.0)
	draw_rect(inner, Color(0.08, 0.16, 0.16, 0.88))
	draw_rect(inner, Color(accent, 0.46), false, 2.0)
	var liquid_height := inner.size.y * (0.34 + float(variant) * 0.10)
	draw_rect(Rect2(Vector2(inner.position.x + 3.0, inner.end.y - liquid_height - 3.0), Vector2(inner.size.x - 6.0, liquid_height)), Color(accent, 0.20))
	for bubble in range(3 + variant):
		var spread := float(maxi(1, 2 + variant))
		var bubble_pos := Vector2(inner.position.x + 8.0 + float(bubble) * (inner.size.x - 16.0) / spread, inner.end.y - 10.0 - float((bubble * 13) % maxi(12, int(liquid_height - 7.0))))
		draw_circle(bubble_pos, 2.0 + float(bubble % 2), Color(accent.lightened(0.24), 0.58), false)

func _draw_structural_cover(rect: Rect2, accent: Color, variant: int, kind: String) -> void:
	var inner := rect.grow(-6.0)
	var base := Color8(62, 49, 42) if kind in ["wreck", "barricade", "scrap_heap"] else Color8(45, 48, 52)
	draw_rect(inner, base)
	for detail in range(3 + variant):
		var ratio := float(detail + 1) / float(4 + variant)
		var start := Vector2(inner.position.x + inner.size.x * ratio, inner.position.y + 5.0)
		draw_line(start, start + Vector2(-7.0 + float(detail % 3) * 7.0, inner.size.y - 10.0), Color(accent, 0.30), 2.0)
	draw_circle(inner.get_center(), minf(inner.size.x, inner.size.y) * 0.16, Color(accent, 0.48), false, 2.0)

func _draw_fungal_cover(rect: Rect2, accent: Color, variant: int) -> void:
	for fungus in range(5 + variant):
		var x := rect.position.x + 10.0 + float(fungus) * (rect.size.x - 20.0) / float(maxi(1, 4 + variant))
		var stem_height := 16.0 + float((fungus * 11 + variant * 7) % maxi(18, int(rect.size.y - 20.0)))
		var root := Vector2(x, rect.end.y - 5.0)
		draw_line(root, root - Vector2(0, stem_height), accent.darkened(0.30), 4.0)
		draw_circle(root - Vector2(0, stem_height), 7.0 + float(fungus % 3), Color8(43, 25, 49))
		draw_line(root - Vector2(7.0 + float(fungus % 3), stem_height), root + Vector2(7.0 + float(fungus % 3), -stem_height), Color(accent, 0.78), 3.0)

func _draw_rib_cover(rect: Rect2, accent: Color) -> void:
	var center := rect.get_center()
	for rib_index in range(5):
		var x := rect.position.x + 10.0 + float(rib_index) * (rect.size.x - 20.0) / 4.0
		var root := Vector2(x, rect.end.y - 3.0)
		var top := Vector2(center.x + (x - center.x) * 0.35, rect.position.y + 5.0 + absf(float(rib_index - 2)) * 5.0)
		draw_line(root, top, Color8(184, 169, 143), 6.0)
		draw_line(root, top, Color(accent, 0.24), 2.0)
