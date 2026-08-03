extends "res://scripts/game.gd"

const AssetCatalogScript = preload("res://scripts/asset_catalog.gd")
const AudioDirectorScript = preload("res://scripts/audio_director.gd")

var asset_catalog = AssetCatalogScript.new()
var audio_director: Node
var visual_clock := 0.0
var player_motion_speed := 0.0
var player_shoot_timer := 0.0
var player_hurt_timer := 0.0
var enemy_serial := 0
var active_biome := -1

func _ready() -> void:
	audio_director = AudioDirectorScript.new()
	add_child(audio_director)
	super._ready()
	if audio_director.has_method("play_biome"):
		audio_director.play_biome(4)

func _process(delta: float) -> void:
	visual_clock += delta
	player_shoot_timer = maxf(0.0, player_shoot_timer - delta)
	player_hurt_timer = maxf(0.0, player_hurt_timer - delta)
	var before := Vector2.ZERO
	var can_measure := state == "run" and player.has("pos")
	if can_measure:
		before = player["pos"]
	super._process(delta)
	if can_measure and delta > 0.0001 and player.has("pos"):
		player_motion_speed = before.distance_to(player["pos"]) / delta
	else:
		player_motion_speed = 0.0

func _sfx(id: String, pitch := 1.0, volume_db := 0.0, throttle_ms := 0) -> void:
	if audio_director != null and audio_director.has_method("play_sfx"):
		audio_director.play_sfx(id, pitch, volume_db, throttle_ms)

func _biome_index() -> int:
	if rooms.has(current_room):
		var room: Dictionary = rooms[current_room]
		return posmod(int(room.get("depth", rooms_cleared)) / 2, 5)
	return posmod(rooms_cleared / 2, 5)

func _sync_biome_audio(force := false) -> void:
	var biome := _biome_index()
	if biome != active_biome or force:
		active_biome = biome
		if audio_director != null and audio_director.has_method("play_biome"):
			audio_director.play_biome(biome, force)

func start_run(lineage_index: int) -> void:
	enemy_serial = 0
	active_biome = -1
	super.start_run(lineage_index)
	_sync_biome_audio(true)
	_sfx("portal", 1.0, -2.0)

func spawn_enemy(type: String, position: Vector2) -> void:
	super.spawn_enemy(type, position)
	if enemies.is_empty():
		return
	var enemy: Dictionary = enemies[enemies.size() - 1]
	enemy["visual_variant"] = enemy_serial % 5
	enemy["visual_seed"] = enemy_serial
	if type == "boss":
		enemy["visual_boss"] = posmod(genome + runs_completed, 5)
	enemies[enemies.size() - 1] = enemy
	enemy_serial += 1

func fire_player_weapon() -> void:
	player_shoot_timer = 0.13
	super.fire_player_weapon()
	var shot_index := posmod(selected_lineage, 3) + 1
	_sfx("shot_%02d" % shot_index, randf_range(0.94, 1.06), -4.0, 35)

func enemy_shoot(position: Vector2, direction: Vector2, speed: float, damage: float) -> void:
	super.enemy_shoot(position, direction, speed, damage)
	_sfx("enemy_shot", randf_range(0.90, 1.10), -10.0, 90)

func begin_dash() -> void:
	var previous := dash_timer
	super.begin_dash()
	if dash_timer > previous:
		_sfx("dash", randf_range(0.96, 1.04), -2.0, 80)

func damage_enemy(index: int, damage: float) -> void:
	if index >= 0 and index < enemies.size():
		_sfx("impact_%02d" % (1 + posmod(index, 2)), randf_range(0.92, 1.12), -7.0, 24)
	super.damage_enemy(index, damage)

func kill_enemy(index: int) -> void:
	var enemy_type := ""
	if index >= 0 and index < enemies.size():
		enemy_type = String(enemies[index].get("type", ""))
	super.kill_enemy(index)
	if enemy_type == "boss":
		_sfx("boss_phase", 0.78, -1.0)
	else:
		_sfx("kill", randf_range(0.90, 1.12), -4.0, 35)

func damage_player(amount: float) -> void:
	var had_shield := bool(player.get("shield", false)) if not player.is_empty() else false
	var hp_before := float(player.get("hp", 0.0)) if not player.is_empty() else 0.0
	super.damage_player(amount)
	if had_shield and not bool(player.get("shield", false)):
		_sfx("shield", 1.0, -1.0)
	elif float(player.get("hp", hp_before)) < hp_before:
		player_hurt_timer = 0.24
		_sfx("hurt", randf_range(0.94, 1.04), -1.0, 100)

func apply_item(id: String) -> void:
	var before := int(player.get("inventory", []).size()) if not player.is_empty() else 0
	super.apply_item(id)
	if int(player.get("inventory", []).size()) > before:
		_sfx("relic", 1.0 + float(asset_catalog.item_row(id)) * 0.015, -1.0)

func purchase_shop_item(index: int) -> bool:
	var scraps_before := scraps
	var result := super.purchase_shop_item(index)
	if scraps < scraps_before:
		_sfx("shop", 1.0, -2.0)
	elif result:
		_sfx("ui", 0.78, -6.0, 120)
	return result

func check_room_clear() -> void:
	var was_cleared := false
	if rooms.has(current_room):
		was_cleared = bool(rooms[current_room].get("cleared", false))
	super.check_room_clear()
	if rooms.has(current_room) and not was_cleared and bool(rooms[current_room].get("cleared", false)):
		_sfx("door", 1.0, -3.0)

func update_boss(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> void:
	var stage_before := int(enemy.get("boss_stage", 0))
	super.update_boss(enemy, direction, distance, delta)
	if int(enemy.get("boss_stage", 0)) > stage_before:
		_sfx("boss_phase", 1.0 + float(enemy.get("boss_stage", 0)) * 0.08, 0.0)

func finish_run(victory: bool) -> void:
	var previous_state := state
	super.finish_run(victory)
	if previous_state == "run" and state != "run":
		_sfx("victory" if victory else "death", 1.0, 0.0)

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
	var spawn_position := arena.get_center()
	if movement_direction == Vector2i.UP:
		spawn_position.y = arena.end.y - PLAYER_RADIUS - 12.0
	elif movement_direction == Vector2i.DOWN:
		spawn_position.y = arena.position.y + PLAYER_RADIUS + 12.0
	elif movement_direction == Vector2i.LEFT:
		spawn_position.x = arena.end.x - PLAYER_RADIUS - 12.0
	elif movement_direction == Vector2i.RIGHT:
		spawn_position.x = arena.position.x + PLAYER_RADIUS + 12.0
	player["pos"] = spawn_position
	if player["id"] == "seth":
		player["shield"] = true
	notify(room_title(room))
	_sync_biome_audio()
	if movement_direction != Vector2i.ZERO:
		_sfx("portal", randf_range(0.95, 1.05), -5.0, 160)

func check_room_transition() -> void:
	if state != "run":
		return
	var room: Dictionary = rooms[current_room]
	if not room["cleared"]:
		return
	var arena := arena_rect()
	var position: Vector2 = player["pos"]
	var edge := PLAYER_RADIUS + 2.0
	var direction := Vector2i.ZERO
	if position.y <= arena.position.y + edge:
		direction = Vector2i.UP
	elif position.y >= arena.end.y - edge:
		direction = Vector2i.DOWN
	elif position.x <= arena.position.x + edge:
		direction = Vector2i.LEFT
	elif position.x >= arena.end.x - edge:
		direction = Vector2i.RIGHT
	if direction != Vector2i.ZERO and direction in room["neighbors"]:
		enter_room(current_room + direction, direction)

func _draw_atlas(texture: Texture2D, position: Vector2, frame_size: Vector2, frame: int, row: int, scale := 1.0, flip_x := false, modulate := Color.WHITE) -> void:
	if texture == null:
		return
	var source := Rect2(Vector2(float(frame) * frame_size.x, float(row) * frame_size.y), frame_size)
	var signed_scale := Vector2(-scale if flip_x else scale, scale)
	draw_set_transform(position, 0.0, signed_scale)
	draw_texture_rect_region(Rect2(-frame_size * 0.5, frame_size), texture, source, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _player_animation_row() -> int:
	if player_hurt_timer > 0.0:
		return 4
	if dash_time > 0.0:
		return 3
	if player_shoot_timer > 0.0:
		return 2
	if player_motion_speed > 18.0:
		return 1
	return 0

func draw_player() -> void:
	var texture: Texture2D = asset_catalog.player(String(player.get("id", "adam")))
	if texture == null:
		super.draw_player()
		return
	var row := _player_animation_row()
	var fps := [5.0, 10.0, 14.0, 16.0, 10.0, 8.0][row]
	var frame := posmod(int(visual_clock * fps), 8)
	var aim: Vector2 = player.get("aim", Vector2.RIGHT)
	var tint := Color.WHITE
	if invulnerability > 0.0 and int(invulnerability * 20.0) % 2 == 0:
		tint = Color(1.0, 1.0, 1.0, 0.42)
	if dash_time > 0.0:
		for trail_index in range(3, 0, -1):
			_draw_atlas(texture, player["pos"] - player["dash_direction"] * float(trail_index) * 17.0, Vector2(48.0, 48.0), frame, row, 1.08, aim.x < 0.0, Color(1.0, 1.0, 1.0, 0.10 + 0.06 * trail_index))
	_draw_atlas(texture, player["pos"], Vector2(48.0, 48.0), frame, row, 1.08, aim.x < 0.0, tint)
	if bool(player.get("shield", false)):
		draw_arc(player["pos"], 27.0, -PI * 0.85, PI * 0.85, 28, Color8(111, 170, 230), 3.0)
	if bool(player.get("halo", false)):
		var halo := halo_position()
		draw_circle(halo, 11.0, Color8(228, 156, 71))
		draw_arc(player["pos"], 50.0, 0.0, TAU, 40, Color(0.7, 0.47, 0.2, 0.22), 1.0)

func _enemy_category(type: String) -> String:
	if type in ["feral", "outlaw", "nephilim", "fallen"]:
		return type
	return "enhanced"

func draw_enemies() -> void:
	for enemy in enemies:
		var type := String(enemy.get("type", "feral"))
		var pos: Vector2 = enemy["pos"]
		var texture: Texture2D
		var frame_size := Vector2(48.0, 48.0)
		var row := 1
		var fps := 9.0
		var scale := maxf(0.92, float(enemy.get("radius", 17.0)) / 18.0)
		if type == "boss":
			texture = asset_catalog.boss(int(enemy.get("visual_boss", 0)))
			frame_size = Vector2(96.0, 96.0)
			scale = maxf(1.0, float(enemy.get("radius", 48.0)) / 48.0)
			row = 1 if float(enemy.get("cooldown", 1.0)) < 0.28 else 0
			if int(enemy.get("boss_stage", 0)) > 0 and int(visual_clock * 3.0) % 5 == 0:
				row = 2
			fps = 10.0 if row == 1 else 6.0
		else:
			texture = asset_catalog.enemy(_enemy_category(type), int(enemy.get("visual_variant", 0)))
			if float(enemy.get("flash", 0.0)) > 0.0:
				row = 4
				fps = 12.0
			elif float(enemy.get("cooldown", 1.0)) < 0.17 and type != "feral":
				row = 2
				fps = 14.0
		var frame := posmod(int((visual_clock + float(enemy.get("visual_seed", 0)) * 0.17) * fps), 8)
		if texture == null:
			super.draw_enemies()
			return
		var flip := player.has("pos") and player["pos"].x < pos.x
		var tint := Color.WHITE if float(enemy.get("flash", 0.0)) <= 0.0 else Color(1.0, 0.86, 0.82, 1.0)
		_draw_atlas(texture, pos, frame_size, frame, row, scale, flip, tint)
		var ratio: float = maxf(0.0, float(enemy["hp"]) / float(enemy["max_hp"]))
		var bar_width := float(enemy["radius"]) * 2.1
		draw_rect(Rect2(pos + Vector2(-bar_width * 0.5, float(enemy["radius"]) + 10.0), Vector2(bar_width, 5.0)), Color8(37, 24, 24))
		draw_rect(Rect2(pos + Vector2(-bar_width * 0.5, float(enemy["radius"]) + 10.0), Vector2(bar_width * ratio, 5.0)), Color8(193, 69, 67))

func draw_bullets() -> void:
	var texture: Texture2D = asset_catalog.effects()
	if texture == null:
		super.draw_bullets()
		return
	for bullet in bullets:
		var owner := String(bullet.get("owner", "enemy"))
		var row := 5 if bool(bullet.get("critical", false)) else (0 if owner == "player" else 1)
		var frame := posmod(int(visual_clock * 18.0 + float(bullet["pos"].x + bullet["pos"].y) * 0.03), 8)
		var scale := maxf(0.42, float(bullet.get("radius", 5.0)) / 8.0)
		draw_circle(bullet["pos"], float(bullet["radius"]) + 4.0, Color(bullet["color"], 0.16))
		_draw_atlas(texture, bullet["pos"], Vector2(32.0, 32.0), frame, row, scale, false, bullet["color"])

func draw_pickups() -> void:
	var relic_texture: Texture2D = asset_catalog.relics()
	var effect_texture: Texture2D = asset_catalog.effects()
	if relic_texture == null or effect_texture == null:
		super.draw_pickups()
		return
	for pickup in pickups:
		var phase := float(pickup.get("phase", 0.0))
		var position: Vector2 = pickup["pos"] + Vector2(0.0, sin(phase * 2.4) * 4.0)
		if String(pickup.get("kind", "")) == "item":
			var row := asset_catalog.item_row(String(pickup.get("id", "seraph_lens")))
			var frame := posmod(int(visual_clock * 6.0), 4)
			_draw_atlas(relic_texture, position, Vector2(32.0, 32.0), frame, row, 1.15)
		else:
			var effect_row := 3 if String(pickup.get("kind", "")) == "heart" else 6
			var effect_frame := posmod(int(visual_clock * 12.0), 8)
			_draw_atlas(effect_texture, position, Vector2(32.0, 32.0), effect_frame, effect_row, 0.85)

func draw_arena() -> void:
	var texture: Texture2D = asset_catalog.tiles(_biome_index())
	if texture == null:
		super.draw_arena()
		return
	var size := get_viewport_rect().size
	var arena := arena_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color8(5, 8, 9))
	draw_rect(arena, Color8(10, 14, 14))
	var tile_size := 32
	var grid_y := 0
	for y in range(int(arena.position.y), int(arena.end.y), tile_size):
		var grid_x := 0
		for x in range(int(arena.position.x), int(arena.end.x), tile_size):
			var tile_index := posmod(grid_x * 7 + grid_y * 11 + _biome_index() * 5, 32)
			var source := Rect2(Vector2(float(tile_index % 8) * 32.0, float(tile_index / 8) * 32.0), Vector2(32.0, 32.0))
			var destination := Rect2(Vector2(x, y), Vector2(mini(tile_size, int(arena.end.x) - x), mini(tile_size, int(arena.end.y) - y)))
			draw_texture_rect_region(destination, texture, source, Color.WHITE)
			grid_x += 1
		grid_y += 1
	draw_rect(arena, Color8(96, 109, 95), false, 4.0)

func draw_lineage_select() -> void:
	super.draw_lineage_select()
	if not asset_catalog.available():
		return
	for index in range(lineages.size()):
		var lineage: Dictionary = lineages[index]
		var rect := lineage_card_rect(index)
		var texture: Texture2D = asset_catalog.player(String(lineage["id"]))
		if texture != null:
			var frame := posmod(int(visual_clock * 5.0 + index), 8)
			_draw_atlas(texture, Vector2(rect.get_center().x, rect.position.y + 71.0), Vector2(48.0, 48.0), frame, 0, 1.55)
