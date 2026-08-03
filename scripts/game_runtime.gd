extends "res://scripts/game.gd"

# Runtime compatibility layer. Keeping these corrections separate makes the
# gameplay core easy to compare against future engine upgrades.

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
	if player["id"] == "seth": player["shield"] = true
	notify(room_title(room))

func check_room_transition() -> void:
	if state != "run": return
	var room: Dictionary = rooms[current_room]
	if not room["cleared"]: return
	var arena := arena_rect()
	var position: Vector2 = player["pos"]
	var edge := PLAYER_RADIUS + 2.0
	var direction := Vector2i.ZERO
	if position.y <= arena.position.y + edge: direction = Vector2i.UP
	elif position.y >= arena.end.y - edge: direction = Vector2i.DOWN
	elif position.x <= arena.position.x + edge: direction = Vector2i.LEFT
	elif position.x >= arena.end.x - edge: direction = Vector2i.RIGHT
	if direction != Vector2i.ZERO and direction in room["neighbors"]:
		enter_room(current_room + direction, direction)
