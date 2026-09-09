extends "res://scripts/edenfall_v6_visual_rebuild.gd"

const PRODUCT_VERSION := "0.6.1"

func arena_rect() -> Rect2:
	var safe := safe_rect()
	var top_inset := 110.0 if safe.size.y >= 620.0 else 92.0
	var bottom_inset := 58.0 if safe.size.y >= 620.0 else 48.0
	return Rect2(safe.position + Vector2(18.0, top_inset), safe.size - Vector2(36.0, top_inset + bottom_inset))

func spawn_room(room: Dictionary) -> void:
	var kind := String(room["kind"])
	if kind == "sanctuary":
		return
	if kind in ["combat", "trial"]:
		var depth := int(room.get("depth", 0))
		var count := clampi(3 + int(depth / 2) + biome_index, 4, 8)
		if active_mode == "training":
			count = maxi(3, count - 1)
		elif active_mode == "daily":
			count = mini(8, count + 1)
		if kind == "trial":
			count = mini(9, count + 2)
		var pool := enemy_pool_for_biome()
		var positions := _encounter_positions(count)
		for index in range(count):
			var enemy_id := pool[rng.randi_range(0, pool.size() - 1)]
			spawn_enemy(enemy_id, positions[index], index)
		if kind == "trial" and not enemies.is_empty():
			promote_enemy_to_elite(0, "armored")
		return
	super.spawn_room(room)

func spawn_enemy(id: String, position: Vector2, variant: int = 0) -> void:
	super.spawn_enemy(id, position, variant)
	if enemies.is_empty():
		return
	var index := enemies.size() - 1
	var enemy: Dictionary = enemies[index]
	enemy["windup"] = 0.0
	enemy["windup_max"] = 0.0
	enemy["charge_time"] = 0.0
	enemy["telegraph_dir"] = Vector2.DOWN
	enemies[index] = enemy

func update_enemy_style(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> Vector2:
	var style := String(enemy.get("style", "melee"))
	var speed := float(enemy["speed"])
	var charge_time := maxf(0.0, float(enemy.get("charge_time", 0.0)) - delta)
	enemy["charge_time"] = charge_time
	if charge_time > 0.0:
		return Vector2(enemy.get("telegraph_dir", direction)).normalized() * speed * 3.2

	var windup := maxf(0.0, float(enemy.get("windup", 0.0)) - delta)
	if float(enemy.get("windup", 0.0)) > 0.0:
		enemy["windup"] = windup
		enemy["attack"] = maxf(float(enemy.get("attack", 0.0)), 0.14)
		if windup <= 0.0:
			_release_enemy_attack(enemy, Vector2(enemy.get("telegraph_dir", direction)).normalized())
		return _windup_movement(style, direction, speed, distance, enemy)

	if style != "melee" and float(enemy.get("cooldown", 0.0)) <= 0.0:
		var delay := _windup_duration(style)
		enemy["windup"] = delay
		enemy["windup_max"] = delay
		enemy["telegraph_dir"] = direction
		enemy["attack"] = delay
		return _windup_movement(style, direction, speed, distance, enemy)

	match style:
		"melee":
			return direction * speed
		"charger":
			return direction * speed * 0.52
		"ranged":
			if distance > 310.0:
				return direction * speed
			if distance < 205.0:
				return -direction * speed
			return direction.orthogonal() * sin(float(enemy["phase"]) * 1.8) * speed * 0.42
		"caster":
			return direction.orthogonal() * sin(float(enemy["phase"]) * 1.35) * speed * 0.58
		"orbiter":
			return (direction * 0.24 + direction.orthogonal() * 0.97).normalized() * speed
		"skirmisher":
			var approach := 0.80 if distance > 250.0 else -0.42
			return (direction * approach + direction.orthogonal() * sin(float(enemy["phase"]) * 2.2)).normalized() * speed
		"radial":
			return direction * speed * 0.58
	return direction * speed

func update_enemies(delta: float) -> void:
	super.update_enemies(delta)
	_apply_enemy_separation()

func objective_for_room(room: Dictionary) -> String:
	var kind := String(room["kind"])
	match kind:
		"start":
			return "Open the overgrown laboratory seal" if biome_index == 0 else "Enter the next contaminated district"
		"shop":
			return "Trade salvage with the preadamite caravan"
		"treasure":
			return "Choose one recovered genome relic"
		"trial":
			return "Survive the enhanced-host containment trial"
		"sanctuary":
			return "Recover tissue and choose the next gate"
		"boss":
			return "Break the guardian signal: %s" % BOSS_NAMES[biome_index]
		_:
			return "Purge the chamber and unlock its blast doors"

func room_title(room: Dictionary) -> String:
	var kind := String(room["kind"])
	var chapter := String(BIOME_CHAPTERS[biome_index])
	match kind:
		"start":
			return "%s // %s" % [chapter, "OVERGROWN BIO-LAB" if biome_index == 0 else "DISTRICT ENTRY"]
		"shop":
			return "%s // CARAVAN EXCHANGE" % chapter
		"treasure":
			return "%s // GENOME VAULT" % chapter
		"trial":
			return "%s // %s" % [chapter, modifier_name(String(room.get("modifier", "elite_hunt")))]
		"sanctuary":
			return "%s // RECLAMATION SHELTER" % chapter
		"boss":
			return "%s // %s" % [chapter, BOSS_NAMES[biome_index]]
		_:
			var modifier := String(room.get("modifier", "none"))
			var base := "%s // SECTOR %02d" % [chapter, int(room.get("depth", 0))]
			return base if modifier == "none" else "%s // %s" % [base, modifier_name(modifier)]

func _encounter_positions(count: int) -> Array[Vector2]:
	var arena := arena_rect().grow(-88.0)
	var center := arena.get_center()
	var positions: Array[Vector2] = []
	var radius_x := maxf(110.0, arena.size.x * 0.34)
	var radius_y := maxf(85.0, arena.size.y * 0.31)
	var phase := rng.randf_range(0.0, TAU)
	for index in range(count):
		var angle := phase + TAU * float(index) / float(maxi(1, count))
		var ring := 0.74 + float(index % 3) * 0.11
		var point := center + Vector2(cos(angle) * radius_x * ring, sin(angle) * radius_y * ring)
		point += Vector2(rng.randf_range(-22.0, 22.0), rng.randf_range(-18.0, 18.0))
		point.x = clampf(point.x, arena.position.x, arena.end.x)
		point.y = clampf(point.y, arena.position.y, arena.end.y)
		positions.append(point)
	return positions

func _windup_duration(style: String) -> float:
	match style:
		"charger": return 0.62
		"caster": return 0.54
		"radial": return 0.68
		"skirmisher": return 0.38
		"orbiter": return 0.34
		_: return 0.42

func _windup_movement(style: String, direction: Vector2, speed: float, distance: float, enemy: Dictionary) -> Vector2:
	match style:
		"charger":
			return -direction * speed * 0.12
		"ranged":
			return -direction * speed * 0.10 if distance < 190.0 else Vector2.ZERO
		"caster", "radial":
			return direction.orthogonal() * sin(float(enemy["phase"]) * 2.0) * speed * 0.14
		"orbiter", "skirmisher":
			return direction.orthogonal() * speed * 0.18
	return Vector2.ZERO

func _release_enemy_attack(enemy: Dictionary, direction: Vector2) -> void:
	var style := String(enemy.get("style", "melee"))
	var origin := Vector2(enemy["pos"])
	var damage := float(enemy["damage"])
	match style:
		"charger":
			enemy["charge_time"] = 0.30
			enemy["cooldown"] = rng.randf_range(1.55, 2.15)
		"ranged":
			enemy_shoot(origin, direction, 350.0, damage)
			enemy["cooldown"] = rng.randf_range(1.05, 1.55)
		"caster":
			for angle in [-0.30, 0.0, 0.30]:
				enemy_shoot(origin, direction.rotated(angle), 295.0, damage)
			enemy["cooldown"] = 1.85
		"orbiter":
			enemy_shoot(origin, direction, 370.0, damage)
			enemy["cooldown"] = 1.15
		"skirmisher":
			for angle in [-0.13, 0.13]:
				enemy_shoot(origin, direction.rotated(angle), 400.0, damage)
			enemy["cooldown"] = 1.28
		"radial":
			for index in range(10):
				enemy_shoot(origin, Vector2.RIGHT.rotated(TAU * float(index) / 10.0), 255.0, damage)
			enemy["cooldown"] = 2.15
	enemy["attack"] = 0.26

func _apply_enemy_separation() -> void:
	for first_index in range(enemies.size()):
		for second_index in range(first_index + 1, enemies.size()):
			var first: Dictionary = enemies[first_index]
			var second: Dictionary = enemies[second_index]
			var first_pos := Vector2(first["pos"])
			var second_pos := Vector2(second["pos"])
			var delta := second_pos - first_pos
			var distance := delta.length()
			var required := (float(first["radius"]) + float(second["radius"])) * 0.78
			if distance >= required:
				continue
			var normal := delta / distance if distance > 0.001 else Vector2.RIGHT.rotated(float(first_index + second_index))
			var correction := normal * (required - distance) * 0.50
			first["pos"] = clamp_to_arena(first_pos - correction, float(first["radius"]))
			second["pos"] = clamp_to_arena(second_pos + correction, float(second["radius"]))
			enemies[first_index] = first
			enemies[second_index] = second
