extends Node2D

const GameData = preload("res://scripts/game_data.gd")
const PLAYER_RADIUS := 17.0
const SAVE_PATH := "user://edenfall_save.json"
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var state := "title"
var paused := false
var lineages: Array = []
var item_defs: Dictionary = {}
var enemy_defs: Dictionary = {}
var selected_lineage := 0

var genome := 0
var best_depth := 0
var runs_completed := 0
var last_genome_gain := 0
var last_rooms_cleared := 0

var rng := RandomNumberGenerator.new()
var run_seed := 0
var rooms: Dictionary = {}
var room_order: Array[Vector2i] = []
var current_room := Vector2i.ZERO
var player: Dictionary = {}
var enemies: Array = []
var bullets: Array = []
var pickups: Array = []
var scraps := 0
var rooms_cleared := 0
var fire_timer := 0.0
var dash_timer := 0.0
var dash_time := 0.0
var invulnerability := 0.0
var halo_angle := 0.0
var notification := ""
var notification_timer := 0.0

var left_touch_id := -1
var left_touch_start := Vector2.ZERO
var left_touch_pos := Vector2.ZERO
var right_touch_id := -1
var right_touch_start := Vector2.ZERO
var right_touch_pos := Vector2.ZERO

func _ready() -> void:
	lineages = GameData.lineages()
	item_defs = GameData.items()
	enemy_defs = GameData.enemy_defs()
	load_progress()
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if state == "run" and not paused:
		update_run(delta)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		handle_key(event.keycode)
	elif event is InputEventMouseButton and event.pressed:
		handle_pointer_press(event.position, event.button_index)
	elif event is InputEventScreenTouch:
		handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		handle_screen_drag(event)

func handle_key(keycode: Key) -> void:
	match state:
		"title":
			if keycode in [KEY_ENTER, KEY_SPACE]: state = "select"
		"select":
			if keycode >= KEY_1 and keycode <= KEY_5:
				selected_lineage = int(keycode - KEY_1)
				start_run(selected_lineage)
			elif keycode in [KEY_LEFT, KEY_A]:
				selected_lineage = posmod(selected_lineage - 1, lineages.size())
			elif keycode in [KEY_RIGHT, KEY_D]:
				selected_lineage = posmod(selected_lineage + 1, lineages.size())
			elif keycode in [KEY_ENTER, KEY_SPACE]:
				start_run(selected_lineage)
		"run":
			if keycode in [KEY_ESCAPE, KEY_P]: paused = not paused
			elif keycode == KEY_SPACE: begin_dash()
			elif keycode == KEY_E: attempt_nearest_shop_purchase()
		"game_over", "victory":
			if keycode in [KEY_ENTER, KEY_SPACE]: state = "select"

func handle_pointer_press(position: Vector2, button: MouseButton) -> void:
	if state == "run":
		if paused:
			paused = false
			return
		if button == MOUSE_BUTTON_RIGHT:
			begin_dash()
		elif button == MOUSE_BUTTON_LEFT:
			attempt_shop_purchase_at(position)
		return
	if state == "title":
		state = "select"
	elif state == "select":
		for i in range(lineages.size()):
			if lineage_card_rect(i).has_point(position):
				selected_lineage = i
				start_run(i)
				break
	elif state in ["game_over", "victory"]:
		state = "select"

func handle_screen_touch(event: InputEventScreenTouch) -> void:
	if state != "run":
		if event.pressed: handle_pointer_press(event.position, MOUSE_BUTTON_LEFT)
		return
	if event.pressed:
		if paused:
			paused = false
			return
		if attempt_shop_purchase_at(event.position): return
		if dash_button_rect().has_point(event.position):
			begin_dash()
			return
		if event.position.x < get_viewport_rect().size.x * 0.5 and left_touch_id == -1:
			left_touch_id = event.index
			left_touch_start = event.position
			left_touch_pos = event.position
		elif right_touch_id == -1:
			right_touch_id = event.index
			right_touch_start = event.position
			right_touch_pos = event.position
	else:
		if event.index == left_touch_id: left_touch_id = -1
		if event.index == right_touch_id: right_touch_id = -1

func handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == left_touch_id: left_touch_pos = event.position
	if event.index == right_touch_id: right_touch_pos = event.position

func start_run(lineage_index: int) -> void:
	selected_lineage = clampi(lineage_index, 0, lineages.size() - 1)
	var lineage: Dictionary = lineages[selected_lineage]
	player = {
		"id": lineage["id"], "name": lineage["name"], "color": lineage["color"],
		"pos": Vector2.ZERO, "hp": lineage["max_hp"], "max_hp": lineage["max_hp"],
		"speed": lineage["speed"], "damage": lineage["damage"],
		"fire_delay": lineage["fire_delay"], "shot_speed": lineage["shot_speed"],
		"dash_delay": lineage["dash_delay"], "luck": lineage["luck"],
		"aim": Vector2.RIGHT, "dash_direction": Vector2.RIGHT,
		"shield": lineage["id"] == "seth", "pierce": 0, "parallel_shot": false,
		"halo": false, "black_manna": false, "watcher_gland": false,
		"inventory": []
	}
	run_seed = int(Time.get_unix_time_from_system() * 1000.0) ^ randi()
	rng.seed = run_seed
	scraps = 0
	rooms_cleared = 0
	fire_timer = 0.0
	dash_timer = 0.0
	dash_time = 0.0
	invulnerability = 0.0
	enemies.clear()
	bullets.clear()
	pickups.clear()
	generate_rooms()
	enter_room(Vector2i.ZERO, Vector2i.ZERO)
	state = "run"
	paused = false
	notify("BIO-LAB SEAL OPENED // EXCURSION %08X" % (run_seed & 0xFFFFFFFF))

func generate_rooms() -> void:
	rooms.clear()
	room_order.clear()
	add_room(Vector2i.ZERO)
	var target := 8 + rng.randi_range(0, 3)
	var attempts := 0
	while room_order.size() < target and attempts < 300:
		attempts += 1
		var base_index := rng.randi_range(maxi(0, room_order.size() - 5), room_order.size() - 1)
		var base: Vector2i = room_order[base_index]
		var direction: Vector2i = DIRECTIONS[rng.randi_range(0, DIRECTIONS.size() - 1)]
		var candidate := base + direction
		if rooms.has(candidate): continue
		if abs(candidate.x) > 4 or abs(candidate.y) > 3: continue
		add_room(candidate)
	compute_room_graph()
	var farthest := Vector2i.ZERO
	var farthest_depth := -1
	var candidates: Array[Vector2i] = []
	for coord in room_order:
		if coord == Vector2i.ZERO: continue
		var depth: int = rooms[coord]["depth"]
		if depth > farthest_depth:
			farthest_depth = depth
			farthest = coord
		candidates.append(coord)
	set_room_kind(farthest, "boss")
	candidates.erase(farthest)
	if not candidates.is_empty():
		var shop_coord: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
		set_room_kind(shop_coord, "shop")
		candidates.erase(shop_coord)
	if not candidates.is_empty():
		var treasure_coord: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
		set_room_kind(treasure_coord, "treasure")
	set_room_kind(Vector2i.ZERO, "start")

func add_room(coord: Vector2i) -> void:
	rooms[coord] = {
		"kind": "combat", "visited": false, "spawned": false, "cleared": false,
		"depth": 0, "neighbors": [], "shop_items": []
	}
	room_order.append(coord)

func set_room_kind(coord: Vector2i, kind: String) -> void:
	var room: Dictionary = rooms[coord]
	room["kind"] = kind
	rooms[coord] = room

func compute_room_graph() -> void:
	for coord in room_order:
		var room: Dictionary = rooms[coord]
		var neighbors: Array[Vector2i] = []
		for direction in DIRECTIONS:
			if rooms.has(coord + direction): neighbors.append(direction)
		room["neighbors"] = neighbors
		rooms[coord] = room
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	var distances := {Vector2i.ZERO: 0}
	while not queue.is_empty():
		var coord: Vector2i = queue.pop_front()
		for direction in rooms[coord]["neighbors"]:
			var next: Vector2i = coord + direction
			if distances.has(next): continue
			distances[next] = int(distances[coord]) + 1
			queue.append(next)
	for coord in room_order:
		var room: Dictionary = rooms[coord]
		room["depth"] = int(distances.get(coord, 0))
		rooms[coord] = room

func enter_room(coord: Vector2i, movement_direction: Vector2i) -> void:
	current_room = coord
	enemies.clear()
	bullets.clear()
	pickups.clear()
	var room: Dictionary = rooms[coord]
	room["visited"] = true
	if not room["spawned"]:
		room["spawned"] = true
		spawn_room(room)
	if room["kind"] in ["start", "shop", "treasure"]:
		room["cleared"] = true
	rooms[coord] = room
	var arena := arena_rect()
	player["pos"] = arena.get_center()
	if movement_direction == Vector2i.UP: player["pos"].y = arena.end.y - 52.0
	elif movement_direction == Vector2i.DOWN: player["pos"].y = arena.position.y + 52.0
	elif movement_direction == Vector2i.LEFT: player["pos"].x = arena.end.x - 52.0
	elif movement_direction == Vector2i.RIGHT: player["pos"].x = arena.position.x + 52.0
	if player["id"] == "seth": player["shield"] = true
	notify(room_title(room))

func spawn_room(room: Dictionary) -> void:
	match room["kind"]:
		"start": pass
		"shop": room["shop_items"] = build_shop_inventory()
		"treasure": spawn_item_pickup(arena_rect().get_center(), random_unlocked_item())
		"boss": spawn_enemy("boss", arena_rect().get_center() + Vector2(0.0, -100.0))
		_:
			var count := 2 + mini(5, int(room["depth"])) + rng.randi_range(0, 2)
			for i in range(count):
				var pool := ["feral", "outlaw"]
				if room["depth"] >= 3: pool.append("nephilim")
				if room["depth"] >= 5: pool.append("fallen")
				spawn_enemy(pool[rng.randi_range(0, pool.size() - 1)], random_arena_position(120.0))

func spawn_enemy(type: String, position: Vector2) -> void:
	var definition: Dictionary = enemy_defs[type]
	enemies.append({
		"type": type, "name": definition["name"], "pos": position,
		"hp": definition["hp"], "max_hp": definition["hp"],
		"speed": definition["speed"], "radius": definition["radius"],
		"damage": definition["damage"], "color": definition["color"],
		"cooldown": rng.randf_range(0.4, 1.2), "phase": rng.randf_range(0.0, TAU),
		"flash": 0.0, "boss_stage": 0
	})

func update_run(delta: float) -> void:
	fire_timer = maxf(0.0, fire_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	dash_time = maxf(0.0, dash_time - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	notification_timer = maxf(0.0, notification_timer - delta)
	halo_angle += delta * 2.8
	update_player(delta)
	update_enemies(delta)
	update_bullets(delta)
	update_pickups(delta)
	check_room_clear()
	check_room_transition()

func update_player(delta: float) -> void:
	var move := keyboard_move()
	if left_touch_id != -1:
		move = (left_touch_pos - left_touch_start) / 55.0
		if move.length() > 1.0: move = move.normalized()
	var aim := keyboard_aim()
	var shooting := aim.length_squared() > 0.05
	if right_touch_id != -1:
		aim = right_touch_pos - right_touch_start
		shooting = aim.length() > 12.0
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		aim = get_viewport().get_mouse_position() - player["pos"]
		shooting = true
	if aim.length_squared() > 0.05: player["aim"] = aim.normalized()
	if dash_time > 0.0:
		player["pos"] += player["dash_direction"] * 690.0 * delta
	else:
		player["pos"] += move * player["speed"] * delta
	player["pos"] = clamp_to_arena(player["pos"], PLAYER_RADIUS)
	if shooting and fire_timer <= 0.0:
		fire_player_weapon()

func keyboard_move() -> Vector2:
	var value := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): value.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): value.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): value.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): value.y += 1.0
	return value.normalized() if value.length_squared() > 1.0 else value

func keyboard_aim() -> Vector2:
	var value := Vector2.ZERO
	if Input.is_key_pressed(KEY_J): value.x -= 1.0
	if Input.is_key_pressed(KEY_L): value.x += 1.0
	if Input.is_key_pressed(KEY_I): value.y -= 1.0
	if Input.is_key_pressed(KEY_K): value.y += 1.0
	return value.normalized() if value.length_squared() > 0.0 else value

func begin_dash() -> void:
	if state != "run" or paused or dash_timer > 0.0: return
	var direction: Vector2 = keyboard_move()
	if left_touch_id != -1: direction = left_touch_pos - left_touch_start
	if direction.length_squared() < 0.05: direction = player.get("aim", Vector2.RIGHT)
	player["dash_direction"] = direction.normalized()
	dash_time = 0.18
	dash_timer = player["dash_delay"]
	invulnerability = maxf(invulnerability, 0.28)
	if player["id"] == "cain":
		for i in range(enemies.size() - 1, -1, -1):
			if enemies[i]["pos"].distance_to(player["pos"]) < 90.0:
				damage_enemy(i, player["damage"] * 1.25)

func fire_player_weapon() -> void:
	fire_timer = player["fire_delay"]
	var aim: Vector2 = player["aim"]
	var critical_chance: float = player["luck"]
	if player["id"] == "abel" and player["hp"] <= player["max_hp"] * 0.5: critical_chance += 0.22
	var critical := rng.randf() < critical_chance
	var damage: float = player["damage"] * (1.8 if critical else 1.0)
	spawn_bullet(player["pos"] + aim * 25.0, aim * player["shot_speed"], damage, "player", 5.0, player["color"], player["pierce"], critical)
	if player["parallel_shot"]:
		var side := aim.orthogonal() * 9.0
		spawn_bullet(player["pos"] + aim * 24.0 + side, aim.rotated(0.06) * player["shot_speed"], damage * 0.62, "player", 4.0, Color8(232, 232, 219), player["pierce"], false)
	if critical and player["watcher_gland"]:
		spawn_bullet(player["pos"] + aim * 21.0, aim.rotated(-0.22) * player["shot_speed"] * 0.9, damage * 0.45, "player", 3.0, Color8(224, 115, 160), 0, false)

func spawn_bullet(position: Vector2, velocity: Vector2, damage: float, owner: String, radius: float, color: Color, pierce := 0, critical := false) -> void:
	bullets.append({"pos": position, "vel": velocity, "damage": damage, "owner": owner, "radius": radius, "color": color, "life": 4.0, "pierce": pierce, "critical": critical})

func update_enemies(delta: float) -> void:
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		enemy["cooldown"] -= delta
		enemy["phase"] += delta
		enemy["flash"] = maxf(0.0, enemy["flash"] - delta)
		var delta_to_player: Vector2 = player["pos"] - enemy["pos"]
		var distance := maxf(1.0, delta_to_player.length())
		var direction := delta_to_player / distance
		match enemy["type"]:
			"feral": enemy["pos"] += direction * enemy["speed"] * delta
			"outlaw":
				if distance > 260.0: enemy["pos"] += direction * enemy["speed"] * delta
				elif distance < 170.0: enemy["pos"] -= direction * enemy["speed"] * delta
				if enemy["cooldown"] <= 0.0:
					enemy_shoot(enemy["pos"], direction, 310.0, 1.0)
					enemy["cooldown"] = rng.randf_range(1.0, 1.6)
			"nephilim":
				enemy["pos"] += direction * enemy["speed"] * delta
				if enemy["cooldown"] <= 0.0:
					for n in range(8): enemy_shoot(enemy["pos"], Vector2.RIGHT.rotated(TAU * n / 8.0), 220.0, 1.0)
					enemy["cooldown"] = 2.2
			"fallen":
				var tangent := direction.orthogonal() * sin(enemy["phase"] * 1.7)
				enemy["pos"] += (direction * 0.35 + tangent).normalized() * enemy["speed"] * delta
				if enemy["cooldown"] <= 0.0:
					for angle in [-0.22, 0.0, 0.22]: enemy_shoot(enemy["pos"], direction.rotated(angle), 350.0, 1.0)
					enemy["cooldown"] = 1.25
			"boss": update_boss(enemy, direction, distance, delta)
		enemy["pos"] = clamp_to_arena(enemy["pos"], enemy["radius"])
		if enemy["pos"].distance_to(player["pos"]) < enemy["radius"] + PLAYER_RADIUS:
			damage_player(enemy["damage"])
			player["pos"] -= direction * 28.0
		enemies[i] = enemy
	if player["halo"]:
		var halo := halo_position()
		for i in range(bullets.size() - 1, -1, -1):
			if bullets[i]["owner"] == "enemy" and bullets[i]["pos"].distance_to(halo) < 18.0:
				bullets.remove_at(i)

func update_boss(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> void:
	var ratio: float = enemy["hp"] / enemy["max_hp"]
	var stage := 0
	if ratio < 0.66: stage = 1
	if ratio < 0.33: stage = 2
	if stage > enemy["boss_stage"]:
		enemy["boss_stage"] = stage
		if player["id"] == "adam": player["hp"] = minf(player["max_hp"], player["hp"] + 1.0)
		notify("WATCHER ENGINE PHASE %d" % (stage + 1))
	enemy["pos"] += direction * enemy["speed"] * (0.65 + stage * 0.18) * delta
	if enemy["cooldown"] <= 0.0:
		var count := 10 + stage * 4
		for n in range(count):
			var angle := TAU * float(n) / float(count) + enemy["phase"] * 0.18
			enemy_shoot(enemy["pos"], Vector2.RIGHT.rotated(angle), 245.0 + stage * 40.0, 1.0)
		for angle in [-0.18, 0.0, 0.18]: enemy_shoot(enemy["pos"], direction.rotated(angle), 390.0, 1.0)
		enemy["cooldown"] = 1.35 - stage * 0.18

func enemy_shoot(position: Vector2, direction: Vector2, speed: float, damage: float) -> void:
	spawn_bullet(position + direction * 20.0, direction.normalized() * speed, damage, "enemy", 6.0, Color8(220, 86, 81))

func update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		if i >= bullets.size(): continue
		var bullet: Dictionary = bullets[i]
		bullet["pos"] += bullet["vel"] * delta
		bullet["life"] -= delta
		if bullet["life"] <= 0.0 or not arena_rect().grow(30.0).has_point(bullet["pos"]):
			bullets.remove_at(i)
			continue
		if bullet["owner"] == "player":
			var consumed := false
			for enemy_index in range(enemies.size() - 1, -1, -1):
				if bullet["pos"].distance_to(enemies[enemy_index]["pos"]) < bullet["radius"] + enemies[enemy_index]["radius"]:
					damage_enemy(enemy_index, bullet["damage"])
					bullet["pierce"] -= 1
					if bullet["pierce"] < 0:
						consumed = true
						break
			if consumed:
				if i < bullets.size(): bullets.remove_at(i)
				continue
		elif bullet["pos"].distance_to(player["pos"]) < bullet["radius"] + PLAYER_RADIUS:
			damage_player(bullet["damage"])
			bullets.remove_at(i)
			continue
		if i < bullets.size(): bullets[i] = bullet

func damage_enemy(index: int, damage: float) -> void:
	if index < 0 or index >= enemies.size(): return
	var enemy: Dictionary = enemies[index]
	enemy["hp"] -= damage
	enemy["flash"] = 0.08
	if enemy["hp"] <= 0.0: kill_enemy(index)
	else: enemies[index] = enemy

func kill_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size(): return
	var enemy: Dictionary = enemies[index]
	enemies.remove_at(index)
	scraps += rng.randi_range(1, 4) + (4 if enemy["type"] == "nephilim" else 0)
	if rng.randf() < 0.11: pickups.append({"kind": "heart", "pos": enemy["pos"], "phase": 0.0})
	if player["id"] == "naamah" and rng.randf() < 0.09: player["hp"] = minf(player["max_hp"], player["hp"] + 1.0)
	if player["black_manna"] and rng.randf() < 0.055: player["hp"] = minf(player["max_hp"], player["hp"] + 1.0)
	if enemy["type"] == "boss": finish_run(true)

func damage_player(amount: float) -> void:
	if invulnerability > 0.0 or state != "run": return
	if player["shield"]:
		player["shield"] = false
		invulnerability = 0.65
		notify("SECOND SKIN ABSORBED IMPACT")
		return
	player["hp"] -= amount
	invulnerability = 0.85
	if player["hp"] <= 0.0: finish_run(false)

func update_pickups(delta: float) -> void:
	for i in range(pickups.size() - 1, -1, -1):
		var pickup: Dictionary = pickups[i]
		pickup["phase"] += delta * 2.0
		if pickup["pos"].distance_to(player["pos"]) < 32.0:
			match pickup["kind"]:
				"heart":
					if player["hp"] >= player["max_hp"]: continue
					player["hp"] = minf(player["max_hp"], player["hp"] + 1.0)
				"scrap": scraps += int(pickup.get("amount", 3))
				"item": apply_item(pickup["id"])
			pickups.remove_at(i)
		else:
			pickups[i] = pickup

func check_room_clear() -> void:
	if state != "run" or not enemies.is_empty(): return
	var room: Dictionary = rooms[current_room]
	if room["cleared"] or room["kind"] not in ["combat", "boss"]: return
	room["cleared"] = true
	rooms[current_room] = room
	rooms_cleared += 1
	scraps += 4 + int(room["depth"])
	if player["id"] == "seth": player["shield"] = true
	if rng.randf() < 0.18 and room["kind"] != "boss": spawn_item_pickup(arena_rect().get_center(), random_unlocked_item())
	notify("CHAMBER PURGED // DOORS RELEASED")

func check_room_transition() -> void:
	if state != "run": return
	var room: Dictionary = rooms[current_room]
	if not room["cleared"]: return
	var arena := arena_rect()
	var direction := Vector2i.ZERO
	if player["pos"].y <= arena.position.y + 4.0: direction = Vector2i.UP
	elif player["pos"].y >= arena.end.y - 4.0: direction = Vector2i.DOWN
	elif player["pos"].x <= arena.position.x + 4.0: direction = Vector2i.LEFT
	elif player["pos"].x >= arena.end.x - 4.0: direction = Vector2i.RIGHT
	if direction != Vector2i.ZERO and direction in room["neighbors"]:
		enter_room(current_room + direction, direction)

func build_shop_inventory() -> Array:
	var result: Array = []
	var used: Array[String] = []
	for i in range(3):
		var id := random_unlocked_item(used)
		used.append(id)
		result.append({"id": id, "bought": false})
	return result

func random_unlocked_item(excluded: Array[String] = []) -> String:
	var pool: Array[String] = ["cherub_coil", "bone_orchard", "eden_valve"]
	if genome >= 5: pool.append("seraph_lens")
	if genome >= 8: pool.append("black_manna")
	if genome >= 12: pool.append("watcher_gland")
	if genome >= 18: pool.append_array(["cains_mark", "salt_genome"])
	if genome >= 25: pool.append_array(["industrial_halo", "nephilim_marrow"])
	for id in excluded: pool.erase(id)
	if pool.is_empty(): return "cherub_coil"
	return pool[rng.randi_range(0, pool.size() - 1)]

func spawn_item_pickup(position: Vector2, id: String) -> void:
	pickups.append({"kind": "item", "id": id, "pos": position, "phase": 0.0})

func apply_item(id: String) -> void:
	if id in player["inventory"]: return
	player["inventory"].append(id)
	match id:
		"seraph_lens": player["damage"] += 3.0; player["shot_speed"] *= 1.12
		"cherub_coil": player["fire_delay"] *= 0.82
		"bone_orchard": player["max_hp"] += 2.0; player["hp"] = minf(player["max_hp"], player["hp"] + 2.0)
		"cains_mark": player["pierce"] += 1
		"salt_genome": player["parallel_shot"] = true
		"eden_valve": player["speed"] *= 1.13; player["dash_delay"] *= 0.78
		"black_manna": player["black_manna"] = true
		"industrial_halo": player["halo"] = true
		"watcher_gland": player["watcher_gland"] = true
		"nephilim_marrow": player["damage"] *= 1.30; player["speed"] *= 0.92
	notify("ASSIMILATED: %s" % item_defs[id]["name"])

func attempt_nearest_shop_purchase() -> bool:
	if state != "run" or rooms[current_room]["kind"] != "shop": return false
	var items: Array = rooms[current_room]["shop_items"]
	for i in range(items.size()):
		if not items[i]["bought"] and shop_card_rect(i, items.size()).grow(35.0).has_point(player["pos"]):
			return purchase_shop_item(i)
	return false

func attempt_shop_purchase_at(position: Vector2) -> bool:
	if state != "run" or not rooms.has(current_room) or rooms[current_room]["kind"] != "shop": return false
	var items: Array = rooms[current_room]["shop_items"]
	for i in range(items.size()):
		if shop_card_rect(i, items.size()).has_point(position): return purchase_shop_item(i)
	return false

func purchase_shop_item(index: int) -> bool:
	var room: Dictionary = rooms[current_room]
	var items: Array = room["shop_items"]
	if index < 0 or index >= items.size() or items[index]["bought"]: return false
	var id: String = items[index]["id"]
	var cost: int = item_defs[id]["cost"]
	if scraps < cost:
		notify("INSUFFICIENT SCRAP")
		return true
	scraps -= cost
	items[index]["bought"] = true
	room["shop_items"] = items
	rooms[current_room] = room
	apply_item(id)
	return true

func finish_run(victory: bool) -> void:
	if state != "run": return
	last_rooms_cleared = rooms_cleared
	last_genome_gain = maxi(1, int(floor(float(rooms_cleared) * 0.6))) + (10 if victory else 0)
	genome += last_genome_gain
	best_depth = maxi(best_depth, rooms_cleared)
	runs_completed += 1
	save_progress()
	state = "victory" if victory else "game_over"
	left_touch_id = -1
	right_touch_id = -1

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		genome = int(parsed.get("genome", 0))
		best_depth = int(parsed.get("best_depth", 0))
		runs_completed = int(parsed.get("runs_completed", 0))

func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify({"genome": genome, "best_depth": best_depth, "runs_completed": runs_completed}))

func arena_rect() -> Rect2:
	var size := get_viewport_rect().size
	return Rect2(Vector2(34.0, 70.0), Vector2(size.x - 68.0, size.y - 104.0))

func clamp_to_arena(position: Vector2, radius: float) -> Vector2:
	var arena := arena_rect()
	return Vector2(clampf(position.x, arena.position.x + radius, arena.end.x - radius), clampf(position.y, arena.position.y + radius, arena.end.y - radius))

func random_arena_position(margin: float) -> Vector2:
	var arena := arena_rect().grow(-margin)
	return Vector2(rng.randf_range(arena.position.x, arena.end.x), rng.randf_range(arena.position.y, arena.end.y))

func halo_position() -> Vector2:
	return player["pos"] + Vector2.RIGHT.rotated(halo_angle) * 50.0

func room_title(room: Dictionary) -> String:
	match room["kind"]:
		"start": return "THE EDEN BIO-LAB"
		"shop": return "PREADAMIC EXCHANGE"
		"treasure": return "GENOME RELIQUARY"
		"boss": return "WATCHER ENGINE SANCTUM"
		_: return "CONTAMINATED CHAMBER %02d" % int(room["depth"])

func notify(text: String) -> void:
	notification = text
	notification_timer = 2.4

func dash_button_rect() -> Rect2:
	var size := get_viewport_rect().size
	return Rect2(size - Vector2(140.0, 140.0), Vector2(112.0, 112.0))

# Implemented by the rendering subclass.
func lineage_card_rect(_index: int) -> Rect2:
	return Rect2()

func shop_card_rect(_index: int, _count: int) -> Rect2:
	return Rect2()
