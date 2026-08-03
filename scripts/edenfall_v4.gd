extends "res://scripts/edenfall_v3.gd"

const V4_VERSION := "0.4.0"
const V4_PROFILE_PATH := "user://edenfall_profile_v4.json"
const V4_SUSPEND_PATH := "user://edenfall_suspend_v4.json"
const RunDirectorScript := preload("res://scripts/v4/run_director.gd")

const STATUS_COLORS := {
	"burn": Color8(239, 103, 55),
	"marked": Color8(235, 210, 126),
	"spore": Color8(177, 102, 199),
	"stagger": Color8(112, 184, 232),
}

var director = RunDirectorScript.new()
var pending_mode := "standard"
var active_mode := "standard"
var threat_level := 1.0
var current_modifier := "none"
var room_hazard_timer := 0.0
var room_elapsed := 0.0
var combo := 0
var combo_timer := 0.0
var best_combo := 0
var run_score := 0
var mastery_gained := 0
var kills_this_run := 0
var elites_killed := 0
var damage_taken := 0.0
var shots_fired := 0
var shots_hit := 0
var dashes_used := 0
var tutorial_stage := 0
var tutorial_timer := 0.0
var v4_save_recovered := false
var room_reward_claimed: Dictionary = {}

func _ready() -> void:
	profile["mastery"] = int(profile.get("mastery", 0))
	profile["highest_combo"] = int(profile.get("highest_combo", 0))
	profile["daily_best"] = int(profile.get("daily_best", 0))
	profile["elite_kills"] = int(profile.get("elite_kills", 0))
	profile["total_score"] = int(profile.get("total_score", 0))
	settings["colorblind_palette"] = bool(settings.get("colorblind_palette", false))
	settings["simplified_fx"] = bool(settings.get("simplified_fx", false))
	settings["tutorial_prompts"] = bool(settings.get("tutorial_prompts", true))
	settings["adaptive_difficulty"] = bool(settings.get("adaptive_difficulty", true))
	super._ready()
	load_v4_profile()
	readiness = audit_v4_readiness()

func title_options() -> Array[String]:
	var result: Array[String] = []
	if can_continue:
		result.append("CONTINUE EXCURSION")
	result.append("NEW EXCURSION")
	result.append("DAILY PROTOCOL")
	result.append("TRAINING SIMULATION")
	result.append("GENOME ARCHIVE")
	result.append("ACCESSIBILITY & SETTINGS")
	return result

func title_option_rect(index: int) -> Rect2:
	var size := get_viewport_rect().size
	var options := title_options()
	var columns := 2
	var rows := int(ceil(float(options.size()) / float(columns)))
	var width := 300.0
	var gap := 18.0
	var x := size.x * 0.5 - width - gap * 0.5 if index % 2 == 0 else size.x * 0.5 + gap * 0.5
	var y := 466.0 + float(index / 2) * 50.0
	if rows <= 2:
		y += 24.0
	return Rect2(Vector2(x, y), Vector2(width, 42.0))

func activate_title_option(index: int) -> void:
	var options := title_options()
	var option := options[clampi(index, 0, options.size() - 1)]
	match option:
		"CONTINUE EXCURSION":
			restore_suspended_run()
		"NEW EXCURSION":
			pending_mode = "standard"
			state = "select"
		"DAILY PROTOCOL":
			pending_mode = "daily"
			state = "select"
		"TRAINING SIMULATION":
			pending_mode = "training"
			state = "select"
		"GENOME ARCHIVE":
			archive_open = true
		"ACCESSIBILITY & SETTINGS":
			settings_open = true

func settings_rows() -> Array:
	var rows: Array = super.settings_rows()
	rows.append({"key":"colorblind_palette", "label":"COLORBLIND PALETTE"})
	rows.append({"key":"simplified_fx", "label":"SIMPLIFIED EFFECTS"})
	rows.append({"key":"tutorial_prompts", "label":"TUTORIAL PROMPTS"})
	rows.append({"key":"adaptive_difficulty", "label":"ADAPTIVE THREAT"})
	return rows

func settings_row_rect(index: int) -> Rect2:
	var size := get_viewport_rect().size
	return Rect2(Vector2(size.x * 0.5 - 285.0, size.y * 0.5 - 246.0 + float(index) * 34.0), Vector2(570.0, 30.0))

func start_new_run(lineage_index: int, seed_override: int = 0) -> void:
	active_mode = pending_mode
	if active_mode == "daily" and seed_override == 0:
		var date := Time.get_date_dict_from_system()
		var date_code := int(date.get("month", 1)) * 100 + int(date.get("day", 1))
		seed_override = director.daily_seed(int(date.get("year", 2026)), date_code)
	reset_v4_run()
	super.start_new_run(lineage_index, seed_override)
	director.configure(run_seed, active_mode)
	player["weapon"] = director.weapon_for(String(player["id"]))
	player["mastery_charge"] = 0.0
	player["combo_damage"] = 1.0
	notify(mode_banner())
	save_suspended_run()

func reset_v4_run() -> void:
	combo = 0
	combo_timer = 0.0
	best_combo = 0
	run_score = 0
	mastery_gained = 0
	kills_this_run = 0
	elites_killed = 0
	damage_taken = 0.0
	shots_fired = 0
	shots_hit = 0
	dashes_used = 0
	tutorial_stage = 0
	tutorial_timer = 0.0
	room_hazard_timer = 0.0
	room_elapsed = 0.0
	current_modifier = "none"
	room_reward_claimed.clear()

func mode_banner() -> String:
	match active_mode:
		"daily": return "DAILY PROTOCOL // SHARED SEED %08X" % (run_seed & 0xFFFFFFFF)
		"training": return "TRAINING SIMULATION // REDUCED THREAT"
		_: return "EDEN EXCURSION // SEED %08X" % (run_seed & 0xFFFFFFFF)

func generate_floor() -> void:
	super.generate_floor()
	director.configure(run_seed, active_mode)
	decorate_floor_v4()

func decorate_floor_v4() -> void:
	var specials: Dictionary = director.room_specials(room_order, room_graph, biome_index)
	for coord in room_order:
		var room: Dictionary = room_graph[coord]
		room["modifier"] = director.room_modifier(coord, String(room["kind"]), int(room["depth"]), biome_index)
		room["reward_multiplier"] = director.modifier_reward(String(room["modifier"]))
		room["v4_rewarded"] = false
		room_graph[coord] = room
	var trial_coord: Vector2i = Vector2i(specials.get("trial", Vector2i(999,999)))
	var sanctuary_coord: Vector2i = Vector2i(specials.get("sanctuary", Vector2i(999,999)))
	if room_graph.has(trial_coord):
		var trial: Dictionary = room_graph[trial_coord]
		trial["kind"] = "trial"
		trial["modifier"] = "elite_hunt"
		trial["reward_multiplier"] = 1.4
		room_graph[trial_coord] = trial
	if room_graph.has(sanctuary_coord) and sanctuary_coord != trial_coord:
		var sanctuary: Dictionary = room_graph[sanctuary_coord]
		sanctuary["kind"] = "sanctuary"
		sanctuary["modifier"] = "none"
		room_graph[sanctuary_coord] = sanctuary

func enter_room(coord: Vector2i, movement_direction: Vector2i) -> void:
	super.enter_room(coord, movement_direction)
	room_elapsed = 0.0
	room_hazard_timer = 1.4
	var room: Dictionary = room_graph[current_room]
	current_modifier = String(room.get("modifier", "none"))
	if String(room["kind"]) == "sanctuary":
		room["cleared"] = true
		room_graph[current_room] = room
		if not room_reward_claimed.has(current_room):
			room_reward_claimed[current_room] = true
			player["hp"] = minf(float(player["max_hp"]), float(player["hp"]) + 2.0)
			player["shield"] = true
			pickups.append({"kind":"scrap", "amount":8 + biome_index * 3, "pos":arena_rect().get_center() + Vector2(48,0), "phase":0.0})
			notify("SANCTUARY ONLINE // TISSUE AND SHIELD RESTORED")
	save_suspended_run()

func spawn_room(room: Dictionary) -> void:
	var kind := String(room["kind"])
	if kind == "sanctuary":
		return
	if kind in ["combat", "trial"]:
		var depth := int(room["depth"])
		var budget := director.encounter_budget(biome_index, depth, rooms_cleared, active_mode)
		if kind == "trial":
			budget += 3
		var pool := enemy_pool_for_biome()
		for i in range(budget):
			spawn_enemy(pool[rng.randi_range(0, pool.size() - 1)], random_arena_position(102.0), i)
		if kind == "trial" and not enemies.is_empty():
			promote_enemy_to_elite(0, "armored")
		return
	super.spawn_room(room)

func objective_for_room(room: Dictionary) -> String:
	match String(room["kind"]):
		"trial": return "Survive the enhanced-host trial"
		"sanctuary": return "Recover tissue and choose a gate"
		_: return super.objective_for_room(room)

func room_title(room: Dictionary) -> String:
	match String(room["kind"]):
		"trial": return "GENOME TRIAL // %s" % modifier_name(String(room.get("modifier", "none")))
		"sanctuary": return "EDEN SANCTUARY // SYSTEMS PARTIAL"
		_:
			var base := super.room_title(room)
			var modifier := String(room.get("modifier", "none"))
			return base if modifier == "none" else "%s // %s" % [base, modifier_name(modifier)]

func modifier_name(id: String) -> String:
	var definition: Dictionary = director.MODIFIERS.get(id, director.MODIFIERS["none"])
	return String(definition.get("name", "STABLE CHAMBER"))

func spawn_enemy(id: String, position: Vector2, variant: int = 0) -> void:
	super.spawn_enemy(id, position, variant)
	if enemies.is_empty():
		return
	var index := enemies.size() - 1
	var enemy: Dictionary = enemies[index]
	enemy["base_speed"] = float(enemy["speed"])
	enemy["elite"] = false
	enemy["affix"] = ""
	enemy["shield_hp"] = 0.0
	enemy["burn"] = 0.0
	enemy["burn_tick"] = 0.0
	enemy["spore"] = 0.0
	enemy["marked"] = 0.0
	enemy["stagger"] = 0.0
	enemy["elite_timer"] = rng.randf_range(0.7, 1.5)
	enemies[index] = enemy
	var forced := current_modifier == "elite_hunt" and index == 0
	var affix := director.elite_affix(threat_level, forced)
	if affix != "":
		promote_enemy_to_elite(index, affix)

func promote_enemy_to_elite(index: int, affix: String = "") -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy: Dictionary = enemies[index]
	if bool(enemy.get("boss", false)):
		return
	if affix == "":
		affix = director.elite_affix(maxf(1.4, threat_level), true)
	var definition := director.elite_definition(affix)
	if definition.is_empty():
		return
	enemy["elite"] = true
	enemy["affix"] = affix
	enemy["max_hp"] = float(enemy["max_hp"]) * float(definition.get("hp", 1.0))
	enemy["hp"] = float(enemy["max_hp"])
	enemy["base_speed"] = float(enemy.get("base_speed", enemy["speed"])) * float(definition.get("speed", 1.0))
	enemy["speed"] = float(enemy["base_speed"])
	enemy["damage"] = float(enemy["damage"]) * float(definition.get("damage", 1.0))
	if affix in ["shielded", "armored"]:
		enemy["shield_hp"] = float(enemy["max_hp"]) * (0.34 if affix == "shielded" else 0.22)
	enemies[index] = enemy

func spawn_boss() -> void:
	super.spawn_boss()
	if enemies.is_empty():
		return
	var index := enemies.size() - 1
	var boss: Dictionary = enemies[index]
	boss["base_speed"] = float(boss["speed"])
	boss["elite"] = true
	boss["affix"] = "boss"
	boss["shield_hp"] = float(boss["max_hp"]) * 0.12
	boss["burn"] = 0.0
	boss["burn_tick"] = 0.0
	boss["spore"] = 0.0
	boss["marked"] = 0.0
	boss["stagger"] = 0.0
	boss["elite_timer"] = 1.0
	enemies[index] = boss

func update_run(delta: float) -> void:
	threat_level = director.threat_level(biome_index, rooms_cleared, floor_number, active_mode)
	if bool(settings.get("adaptive_difficulty", true)):
		threat_level = clampf(threat_level + float(maxi(0, combo - 8)) * 0.012, 0.65, 3.25)
	super.update_run(delta)
	update_v4_systems(delta)

func update_v4_systems(delta: float) -> void:
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0 and combo > 0:
		combo = maxi(0, combo - 1)
		combo_timer = 0.38 if combo > 0 else 0.0
	room_elapsed += delta
	room_hazard_timer -= delta
	if current_modifier == "bullet_storm" and room_hazard_timer <= 0.0 and not enemies.is_empty():
		spawn_room_crossfire()
		room_hazard_timer = maxf(1.35, 3.2 - threat_level * 0.36)
	elif current_modifier == "corrosive_grid" and room_hazard_timer <= 0.0:
		pulse_corrosive_grid()
		room_hazard_timer = 2.8
	update_tutorial(delta)

func update_tutorial(delta: float) -> void:
	if not bool(settings.get("tutorial_prompts", true)) or active_mode == "daily" or state != "run":
		return
	tutorial_timer += delta
	if tutorial_stage == 0 and tutorial_timer > 1.2:
		notify("MOVE // LEFT STICK OR WASD")
		tutorial_stage = 1
	elif tutorial_stage == 1 and input_move.length() > 0.4:
		notify("AIM AND FIRE // RIGHT STICK, ARROWS OR TOUCH")
		tutorial_stage = 2
	elif tutorial_stage == 2 and shots_fired > 0:
		notify("DASH THROUGH DANGER // SPACE OR DASH BUTTON")
		tutorial_stage = 3
	elif tutorial_stage == 3 and dashes_used > 0:
		notify("CHAIN KILLS TO BUILD COMBO AND MASTERY")
		tutorial_stage = 4

func update_enemies(delta: float) -> void:
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		var base_speed := float(enemy.get("base_speed", enemy["speed"]))
		var speed_factor := 1.0
		if float(enemy.get("spore", 0.0)) > 0.0:
			speed_factor *= 0.62
		if float(enemy.get("stagger", 0.0)) > 0.0:
			speed_factor *= 0.35
		if current_modifier == "overclocked":
			speed_factor *= 1.22
		enemy["speed"] = base_speed * speed_factor
		enemies[i] = enemy
	super.update_enemies(delta)
	for i in range(enemies.size() - 1, -1, -1):
		if i >= enemies.size():
			continue
		var enemy: Dictionary = enemies[i]
		for key in ["burn", "spore", "marked", "stagger"]:
			enemy[key] = maxf(0.0, float(enemy.get(key, 0.0)) - delta)
		enemy["burn_tick"] = float(enemy.get("burn_tick", 0.0)) - delta
		if float(enemy.get("burn", 0.0)) > 0.0 and float(enemy["burn_tick"]) <= 0.0:
			enemy["burn_tick"] = 0.45
			enemies[i] = enemy
			super.damage_enemy(i, 4.0 + float(player.get("ability", 0.0)) * 0.3)
			continue
		if bool(enemy.get("elite", false)):
			enemy["elite_timer"] = float(enemy.get("elite_timer", 1.0)) - delta
			if String(enemy.get("affix", "")) == "regenerative" or current_modifier == "regenerative":
				enemy["hp"] = minf(float(enemy["max_hp"]), float(enemy["hp"]) + float(enemy["max_hp"]) * 0.006 * delta)
			if String(enemy.get("affix", "")) == "vampiric" and Vector2(enemy["pos"]).distance_to(Vector2(player["pos"])) < 170.0:
				enemy["hp"] = minf(float(enemy["max_hp"]), float(enemy["hp"]) + 1.6 * delta)
			if String(enemy.get("affix", "")) == "corrosive" and float(enemy["elite_timer"]) <= 0.0:
				for n in range(6):
					enemy_shoot(Vector2(enemy["pos"]), Vector2.RIGHT.rotated(TAU * float(n) / 6.0), 270.0, 1.0)
				enemy["elite_timer"] = 2.2
		enemies[i] = enemy

func spawn_bullet(position: Vector2, velocity: Vector2, damage: float, owner: String, radius: float, color: Color, pierce: int, critical: bool) -> void:
	super.spawn_bullet(position, velocity, damage, owner, radius, color, pierce, critical)
	if bullets.is_empty():
		return
	var bullet: Dictionary = bullets[bullets.size() - 1]
	bullet["homing"] = 0.0
	bullet["explosion"] = 0.0
	bullet["status"] = "none"
	bullet["chain"] = 0
	bullet["bounces"] = 0
	bullet["hit_ids"] = []
	bullets[bullets.size() - 1] = bullet

func fire_player_weapon() -> void:
	fire_timer = float(player["fire_delay"])
	shoot_timer = 0.13
	var aim := Vector2(player["aim"]).normalized()
	if bool(settings["aim_assist"]):
		aim = assisted_aim(aim)
	var weapon: Dictionary = player.get("weapon", director.weapon_for(String(player["id"])))
	var critical_chance := float(player["luck"])
	if String(player["id"]) == "abel" and float(player["hp"]) <= float(player["max_hp"]) * 0.5:
		critical_chance += 0.22
	var critical := rng.randf() < critical_chance
	var combo_multiplier := 1.0 + minf(0.55, float(combo) * 0.018)
	var modifier_multiplier := 1.22 if current_modifier == "fragile_protocol" else 1.0
	var base_damage := float(player["damage"]) * float(weapon["damage"]) * combo_multiplier * modifier_multiplier
	if critical:
		base_damage *= 1.8
	var projectile_count := int(weapon["projectiles"])
	for i in range(projectile_count):
		var offset := float(i) - float(projectile_count - 1) * 0.5
		var direction := aim.rotated(offset * float(weapon["spread"]))
		spawn_v4_projectile(direction, base_damage, weapon, critical)
	if bool(player["parallel"]):
		for angle in [-0.09, 0.09]:
			spawn_v4_projectile(aim.rotated(angle), base_damage * 0.58, weapon, false)
	shots_fired += projectile_count
	spawn_effect("muzzle", Vector2(player["pos"]) + aim * 25.0, player["color"], aim.angle())
	play_sfx("critical" if critical else "shot_%02d" % (posmod(selected_lineage, 3) + 1))
	haptic(18, 0.22)

func spawn_v4_projectile(direction: Vector2, damage: float, weapon: Dictionary, critical: bool) -> void:
	var speed := float(player["shot_speed"]) * float(weapon["speed"])
	var radius := 7.0 if String(weapon["pattern"]) == "cannon" else (4.0 if String(weapon["pattern"]) == "beam" else 5.0)
	spawn_bullet(Vector2(player["pos"]) + direction * 24.0, direction.normalized() * speed, damage, "player", radius, player["color"], int(player["pierce"]) + int(weapon["pierce"]), critical)
	var bullet: Dictionary = bullets[bullets.size() - 1]
	bullet["homing"] = float(weapon["homing"])
	bullet["explosion"] = float(weapon["explosion"])
	bullet["status"] = String(weapon["status"])
	bullet["chain"] = 1 if String(weapon["pattern"]) == "beam" else 0
	bullet["bounces"] = 1 if String(weapon["pattern"]) == "lance" else 0
	bullets[bullets.size() - 1] = bullet

func update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		if i >= bullets.size():
			continue
		var bullet: Dictionary = bullets[i]
		if String(bullet["owner"]) == "player" and float(bullet.get("homing", 0.0)) > 0.0 and not enemies.is_empty():
			var target = nearest_enemy(Vector2(bullet["pos"]))
			if target != null:
				var desired := (Vector2(target["pos"]) - Vector2(bullet["pos"])).normalized() * Vector2(bullet["vel"]).length()
				bullet["vel"] = Vector2(bullet["vel"]).lerp(desired, clampf(float(bullet["homing"]) * delta * 6.0, 0.0, 0.32))
		bullet["pos"] = Vector2(bullet["pos"]) + Vector2(bullet["vel"]) * delta
		bullet["life"] = float(bullet["life"]) - delta
		if float(bullet["life"]) <= 0.0:
			bullets.remove_at(i)
			continue
		var inside := arena_rect().grow(14.0).has_point(Vector2(bullet["pos"]))
		if not inside:
			if int(bullet.get("bounces", 0)) > 0:
				var arena := arena_rect()
				var velocity := Vector2(bullet["vel"])
				if float(bullet["pos"].x) <= arena.position.x or float(bullet["pos"].x) >= arena.end.x:
					velocity.x *= -1.0
				if float(bullet["pos"].y) <= arena.position.y or float(bullet["pos"].y) >= arena.end.y:
					velocity.y *= -1.0
				bullet["vel"] = velocity
				bullet["bounces"] = int(bullet["bounces"]) - 1
				bullet["pos"] = clamp_to_arena(Vector2(bullet["pos"]), float(bullet["radius"]) + 2.0)
			else:
				bullets.remove_at(i)
				continue
		if String(bullet["owner"]) == "player":
			var consumed := false
			for enemy_index in range(enemies.size() - 1, -1, -1):
				if enemy_index >= enemies.size():
					continue
				if Vector2(bullet["pos"]).distance_to(Vector2(enemies[enemy_index]["pos"])) < float(bullet["radius"]) + float(enemies[enemy_index]["radius"]):
					apply_v4_bullet_hit(enemy_index, bullet)
					bullet["pierce"] = int(bullet["pierce"]) - 1
					spawn_effect("impact", Vector2(bullet["pos"]), bullet["color"], Vector2(bullet["vel"]).angle())
					if int(bullet["pierce"]) < 0:
						consumed = true
						break
			if consumed:
				bullets.remove_at(i)
				continue
		elif Vector2(bullet["pos"]).distance_to(Vector2(player["pos"])) < float(bullet["radius"]) + PLAYER_RADIUS:
			damage_player(float(bullet["damage"]), Vector2(bullet["vel"]).normalized())
			bullets.remove_at(i)
			continue
		if i < bullets.size():
			bullets[i] = bullet

func apply_v4_bullet_hit(index: int, bullet: Dictionary) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy: Dictionary = enemies[index]
	var damage := float(bullet["damage"])
	if float(enemy.get("marked", 0.0)) > 0.0:
		damage *= 1.18
	var shield_hp := float(enemy.get("shield_hp", 0.0))
	if shield_hp > 0.0:
		var absorbed := minf(shield_hp, damage)
		enemy["shield_hp"] = shield_hp - absorbed
		damage -= absorbed
		enemies[index] = enemy
		spawn_effect("shield", Vector2(enemy["pos"]), Color8(121,158,239), 0.0)
	if damage > 0.0:
		shots_hit += 1
		super.damage_enemy(index, damage)
	if index < enemies.size():
		apply_status(index, String(bullet.get("status", "none")))
	if float(bullet.get("explosion", 0.0)) > 0.0:
		explode_at(Vector2(bullet["pos"]), float(bullet["explosion"]), float(bullet["damage"]) * 0.46, "player")
	if int(bullet.get("chain", 0)) > 0:
		chain_hit(Vector2(bullet["pos"]), index, float(bullet["damage"]) * 0.52)

func apply_status(index: int, status: String) -> void:
	if status == "none" or index < 0 or index >= enemies.size():
		return
	var enemy: Dictionary = enemies[index]
	match status:
		"burn": enemy["burn"] = maxf(float(enemy.get("burn", 0.0)), 2.8)
		"marked": enemy["marked"] = maxf(float(enemy.get("marked", 0.0)), 3.5)
		"spore": enemy["spore"] = maxf(float(enemy.get("spore", 0.0)), 3.2)
		"stagger": enemy["stagger"] = maxf(float(enemy.get("stagger", 0.0)), 0.34)
	enemies[index] = enemy

func chain_hit(origin: Vector2, excluded_index: int, damage: float) -> void:
	var best_index := -1
	var best_distance := 190.0
	for i in range(enemies.size()):
		if i == excluded_index:
			continue
		var distance := origin.distance_to(Vector2(enemies[i]["pos"]))
		if distance < best_distance:
			best_distance = distance
			best_index = i
	if best_index >= 0:
		var target_pos := Vector2(enemies[best_index]["pos"])
		draw_chain_effect(origin, target_pos)
		super.damage_enemy(best_index, damage)

func draw_chain_effect(origin: Vector2, target: Vector2) -> void:
	effects.append({"id":"chain", "pos":origin, "target":target, "color":Color8(230,212,142), "angle":0.0, "life":0.22, "max_life":0.22})

func explode_at(position: Vector2, radius: float, damage: float, owner: String) -> void:
	spawn_effect("explosion", position, Color8(236,105,65), 0.0)
	for i in range(enemies.size() - 1, -1, -1):
		if position.distance_to(Vector2(enemies[i]["pos"])) <= radius:
			super.damage_enemy(i, damage)
	if owner == "enemy" and position.distance_to(Vector2(player["pos"])) <= radius:
		damage_player(1.0, (Vector2(player["pos"]) - position).normalized())

func kill_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy: Dictionary = enemies[index].duplicate(true)
	var death_pos := Vector2(enemy["pos"])
	var was_elite := bool(enemy.get("elite", false)) and not bool(enemy.get("boss", false))
	var affix := String(enemy.get("affix", ""))
	var modifier := current_modifier
	var score_gain := director.score_for_kill(float(enemy["max_hp"]), was_elite, bool(enemy["boss"]), combo, modifier)
	super.kill_enemy(index)
	kills_this_run += 1
	if was_elite:
		elites_killed += 1
	combo += 1
	best_combo = maxi(best_combo, combo)
	combo_timer = 3.0
	run_score += score_gain
	mastery_gained += maxi(1, int(round(float(score_gain) * 0.08)))
	if affix == "volatile":
		explode_at(death_pos, 94.0, 12.0 + threat_level * 3.0, "enemy")
	if combo in [5, 10, 20, 35]:
		notify("COMBO PROTOCOL // x%d" % combo)
		haptic(28 + combo, 0.35)

func damage_player(amount: float, direction: Vector2) -> void:
	var before := float(player.get("hp", 0.0))
	var adjusted := amount * (1.20 if current_modifier == "fragile_protocol" else 1.0)
	super.damage_player(adjusted, direction)
	var after := float(player.get("hp", 0.0))
	if after < before:
		damage_taken += before - after
		combo = 0
		combo_timer = 0.0

func begin_dash() -> void:
	var previous := dash_timer
	super.begin_dash()
	if previous <= 0.0 and dash_timer > 0.0:
		dashes_used += 1

func check_room_clear() -> void:
	if state != "run" or not enemies.is_empty():
		return
	var room: Dictionary = room_graph[current_room]
	var kind := String(room["kind"])
	if kind == "trial" and not bool(room["cleared"]):
		room["cleared"] = true
		room_graph[current_room] = room
		rooms_cleared += 1
		scraps += int(round(float(12 + int(room["depth"]) + biome_index * 2) * float(room.get("reward_multiplier", 1.0))))
		spawn_relic(arena_rect().get_center(), random_relic_id())
		objective = "Claim the trial relic and choose a gate"
		play_sfx("door")
		notify("GENOME TRIAL COMPLETE // RELIC RELEASED")
		save_suspended_run()
		return
	var was_cleared := bool(room["cleared"])
	super.check_room_clear()
	if not was_cleared and room_graph.has(current_room):
		var cleared_room: Dictionary = room_graph[current_room]
		if bool(cleared_room["cleared"]) and not bool(cleared_room.get("v4_rewarded", false)):
			cleared_room["v4_rewarded"] = true
			room_graph[current_room] = cleared_room
			var multiplier := float(cleared_room.get("reward_multiplier", 1.0))
			var bonus := int(round(float(2 + combo / 4) * maxf(0.0, multiplier - 1.0)))
			scraps += bonus
			run_score += int(round(100.0 * multiplier))

func spawn_room_crossfire() -> void:
	var arena := arena_rect()
	var target := Vector2(player["pos"])
	var origins := [
		Vector2(arena.position.x + 12.0, target.y),
		Vector2(arena.end.x - 12.0, target.y),
		Vector2(target.x, arena.position.y + 12.0),
		Vector2(target.x, arena.end.y - 12.0),
	]
	for origin in origins:
		enemy_shoot(origin, (target - origin).normalized(), 330.0 + threat_level * 26.0, 1.0)
	notify("WATCHER CROSS-FIRE")

func pulse_corrosive_grid() -> void:
	var arena := arena_rect()
	var center := arena.get_center()
	spawn_effect("grid", center, Color8(112,205,96), 0.0)
	var pos := Vector2(player["pos"])
	if absf(pos.x - center.x) < 34.0 or absf(pos.y - center.y) < 34.0:
		damage_player(1.0, (pos - center).normalized())

func finish_run(victory: bool) -> void:
	if state != "run":
		return
	var final_mode := active_mode
	var final_score := run_score
	var final_mastery := mastery_gained
	var final_combo := best_combo
	var final_elites := elites_killed
	super.finish_run(victory)
	profile["mastery"] = int(profile.get("mastery", 0)) + final_mastery
	profile["highest_combo"] = maxi(int(profile.get("highest_combo", 0)), final_combo)
	profile["elite_kills"] = int(profile.get("elite_kills", 0)) + final_elites
	profile["total_score"] = int(profile.get("total_score", 0)) + final_score
	if final_mode == "daily":
		profile["daily_best"] = maxi(int(profile.get("daily_best", 0)), final_score)
	save_v4_profile()

func draw_title() -> void:
	super.draw_title()
	var size := get_viewport_rect().size
	draw_text_centered("ASCENSION SYSTEMS ONLINE // v%s" % V4_VERSION, Vector2(size.x * 0.5, 454), 12, Color8(116,170,139))
	var date := Time.get_date_dict_from_system()
	var code := int(date.get("month",1)) * 100 + int(date.get("day",1))
	var daily := director.daily_seed(int(date.get("year",2026)), code)
	draw_text("DAILY %08X" % (daily & 0xFFFFFFFF), Vector2(size.x - 150, size.y - 18), 11, Color8(91,116,107))

func draw_select() -> void:
	super.draw_select()
	var size := get_viewport_rect().size
	var mode_text := "STANDARD EXCURSION"
	if pending_mode == "daily": mode_text = "DAILY PROTOCOL // FIXED SEED"
	elif pending_mode == "training": mode_text = "TRAINING SIMULATION // REDUCED THREAT"
	draw_text_centered(mode_text, Vector2(size.x * 0.5, 92), 12, Color8(127,182,146))

func draw_arena() -> void:
	super.draw_arena()
	var arena := arena_rect()
	if current_modifier == "corrosive_grid":
		var pulse := 0.25 + 0.20 * sin(visual_clock * 3.0)
		draw_line(Vector2(arena.get_center().x, arena.position.y), Vector2(arena.get_center().x, arena.end.y), Color(0.35,0.85,0.32,pulse), 5.0)
		draw_line(Vector2(arena.position.x, arena.get_center().y), Vector2(arena.end.x, arena.get_center().y), Color(0.35,0.85,0.32,pulse), 5.0)
	elif current_modifier == "blackout":
		for radius in [330.0, 270.0, 210.0]:
			draw_arc(Vector2(player.get("pos", arena.get_center())), radius, 0.0, TAU, 64, Color(0.0,0.0,0.0,0.34), 42.0)

func draw_enemies() -> void:
	super.draw_enemies()
	for enemy in enemies:
		var pos := Vector2(enemy["pos"])
		if bool(enemy.get("elite", false)):
			var affix := String(enemy.get("affix", ""))
			var definition := director.elite_definition(affix)
			var color: Color = definition.get("color", Color8(226,188,102))
			draw_arc(pos, float(enemy["radius"]) + 7.0, visual_clock, visual_clock + PI * 1.55, 28, color, 3.0)
			if affix != "boss":
				draw_text_centered(String(definition.get("name", affix.to_upper())), pos - Vector2(0, float(enemy["radius"]) + 17.0), 9, color)
		if float(enemy.get("shield_hp", 0.0)) > 0.0:
			draw_arc(pos, float(enemy["radius"]) + 3.0, -PI * 0.85, PI * 0.85, 24, Color8(121,158,239), 2.0)
		var status_index := 0
		for status in ["burn", "marked", "spore", "stagger"]:
			if float(enemy.get(status, 0.0)) > 0.0:
				draw_circle(pos + Vector2(-16.0 + float(status_index) * 11.0, -float(enemy["radius"]) - 8.0), 3.5, STATUS_COLORS[status])
				status_index += 1

func draw_bullets() -> void:
	super.draw_bullets()
	if bool(settings.get("simplified_fx", false)):
		return
	for bullet in bullets:
		if String(bullet["owner"]) == "player" and (float(bullet.get("explosion",0.0)) > 0.0 or String(bullet.get("status","none")) != "none"):
			draw_arc(Vector2(bullet["pos"]), float(bullet["radius"]) + 5.0, 0.0, TAU, 12, Color(bullet["color"],0.48), 1.5)

func draw_effects() -> void:
	super.draw_effects()
	for effect in effects:
		if String(effect.get("id", "")) == "chain" and effect.has("target"):
			var alpha := clampf(float(effect["life"]) / float(effect["max_life"]), 0.0, 1.0)
			draw_line(Vector2(effect["pos"]), Vector2(effect["target"]), Color(effect["color"], alpha), 3.0)

func draw_hud() -> void:
	super.draw_hud()
	var safe := safe_rect()
	var scale := float(settings["ui_scale"])
	var text_scale := float(settings["text_scale"])
	var combo_rect := Rect2(safe.position + Vector2(8.0, 72.0) * scale, Vector2(196.0, 42.0) * scale)
	var combo_color := Color8(221,176,91) if combo > 0 else Color8(73,92,85)
	draw_panel(combo_rect, Color(0.02,0.04,0.04,0.88), combo_color)
	draw_text("COMBO x%02d" % combo, combo_rect.position + Vector2(10,17) * scale, int(12 * text_scale), Color8(235,216,169))
	var combo_progress := clampf(combo_timer / 3.0, 0.0, 1.0)
	draw_rect(Rect2(combo_rect.position + Vector2(10,27) * scale, Vector2(176 * combo_progress,5) * scale), combo_color)
	var threat_rect := Rect2(Vector2(safe.end.x - 204.0 * scale, safe.position.y + 72.0 * scale), Vector2(196,42) * scale)
	draw_panel(threat_rect, Color(0.02,0.04,0.04,0.88), Color8(173,77,69))
	draw_text("THREAT %.2f" % threat_level, threat_rect.position + Vector2(10,17) * scale, int(11 * text_scale), Color8(229,201,177))
	draw_text(modifier_name(current_modifier), threat_rect.position + Vector2(10,33) * scale, int(9 * text_scale), Color8(159,176,164))
	var weapon: Dictionary = player.get("weapon", {})
	if not weapon.is_empty():
		var weapon_rect := Rect2(Vector2(safe.get_center().x - 165 * scale, safe.end.y - 91 * scale), Vector2(330,32) * scale)
		draw_panel(weapon_rect, Color(0.02,0.04,0.04,0.88), player["color"])
		draw_text_centered(String(weapon["name"]), weapon_rect.get_center() + Vector2(0,4), int(11 * text_scale), Color8(232,219,183))
	var score_text := "SCORE %07d  •  MASTERY +%04d" % [run_score, mastery_gained]
	draw_text_centered(score_text, Vector2(safe.get_center().x, safe.position.y + 124 * scale), int(10 * text_scale), Color8(126,158,145))

func draw_pause() -> void:
	super.draw_pause()
	var size := get_viewport_rect().size
	draw_text_centered("SCORE %d  •  KILLS %d  •  ELITES %d  •  BEST COMBO %d" % [run_score,kills_this_run,elites_killed,best_combo], Vector2(size.x * 0.5, size.y * 0.5 + 166), 11, Color8(139,166,154))

func draw_archive() -> void:
	super.draw_archive()
	var size := get_viewport_rect().size
	var mastery := int(profile.get("mastery", 0))
	draw_text_centered("MASTERY %d // %s // HIGHEST COMBO %d // ELITES %d" % [mastery, director.mastery_name(mastery), int(profile.get("highest_combo",0)), int(profile.get("elite_kills",0))], Vector2(size.x * 0.5, size.y * 0.5 + 242), 12, Color8(151,190,164))

func draw_end(victory: bool) -> void:
	super.draw_end(victory)
	var size := get_viewport_rect().size
	draw_text_centered("SCORE %d  •  MASTERY +%d  •  BEST COMBO %d  •  ACCURACY %.0f%%" % [run_score, mastery_gained, best_combo, accuracy_percent()], Vector2(size.x * 0.5, 520), 13, Color8(157,184,171))

func accuracy_percent() -> float:
	if shots_fired <= 0:
		return 0.0
	return clampf(float(shots_hit) / float(shots_fired) * 100.0, 0.0, 100.0)

func save_profile() -> void:
	super.save_profile()
	save_v4_profile()

func save_v4_profile() -> void:
	var data := {
		"version": V4_VERSION,
		"mastery": int(profile.get("mastery",0)),
		"highest_combo": int(profile.get("highest_combo",0)),
		"daily_best": int(profile.get("daily_best",0)),
		"elite_kills": int(profile.get("elite_kills",0)),
		"total_score": int(profile.get("total_score",0)),
	}
	atomic_json_write(V4_PROFILE_PATH, data)

func load_v4_profile() -> void:
	var data := read_json_with_backup(V4_PROFILE_PATH)
	if data.is_empty():
		return
	for key in ["mastery","highest_combo","daily_best","elite_kills","total_score"]:
		if data.has(key):
			profile[key] = data[key]

func save_suspended_run() -> void:
	super.save_suspended_run()
	if state != "run" or player.is_empty():
		return
	var data := {
		"version": V4_VERSION,
		"mode": active_mode,
		"score": run_score,
		"mastery_gained": mastery_gained,
		"combo": combo,
		"best_combo": best_combo,
		"kills": kills_this_run,
		"elite_kills": elites_killed,
		"damage_taken": damage_taken,
		"shots_fired": shots_fired,
		"shots_hit": shots_hit,
		"dashes": dashes_used,
		"tutorial_stage": tutorial_stage,
		"weapon": player.get("weapon", {}),
	}
	atomic_json_write(V4_SUSPEND_PATH, data)

func restore_suspended_run() -> void:
	super.restore_suspended_run()
	var data := read_json_with_backup(V4_SUSPEND_PATH)
	if data.is_empty() or state != "run":
		return
	active_mode = String(data.get("mode", "standard"))
	pending_mode = active_mode
	run_score = int(data.get("score", 0))
	mastery_gained = int(data.get("mastery_gained", 0))
	combo = int(data.get("combo", 0))
	best_combo = int(data.get("best_combo", combo))
	kills_this_run = int(data.get("kills", 0))
	elites_killed = int(data.get("elite_kills", 0))
	damage_taken = float(data.get("damage_taken", 0.0))
	shots_fired = int(data.get("shots_fired", 0))
	shots_hit = int(data.get("shots_hit", 0))
	dashes_used = int(data.get("dashes", 0))
	tutorial_stage = int(data.get("tutorial_stage", 0))
	if data.has("weapon") and data["weapon"] is Dictionary:
		player["weapon"] = data["weapon"]
	director.configure(run_seed, active_mode)
	notify("V0.4 EXCURSION RESTORED // SAVE VERIFIED")

func atomic_json_write(path: String, data: Dictionary) -> bool:
	var temp_path := path + ".tmp"
	var backup_path := path + ".bak"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		var source := FileAccess.open(path, FileAccess.READ)
		var backup := FileAccess.open(backup_path, FileAccess.WRITE)
		if source != null and backup != null:
			backup.store_buffer(source.get_buffer(source.get_length()))
			source.close()
			backup.close()
		DirAccess.remove_absolute(path)
	var result := DirAccess.rename_absolute(temp_path, path)
	return result == OK

func read_json_with_backup(path: String) -> Dictionary:
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var file := FileAccess.open(candidate, FileAccess.READ)
		if file == null:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			v4_save_recovered = candidate.ends_with(".bak")
			return Dictionary(parsed)
	return {}

func audit_v4_readiness() -> float:
	var contract: Dictionary = director.audit_contract()
	var checks := [
		int(contract.get("version",0)) == 4,
		int(contract.get("modifiers",0)) >= 8,
		int(contract.get("elite_affixes",0)) >= 6,
		int(contract.get("weapons",0)) == 5,
		int(contract.get("mastery_ranks",0)) >= 8,
		title_options().size() >= 5,
		settings_rows().size() >= 15,
		FileAccess.file_exists("res://tests/v4_audit.gd"),
		FileAccess.file_exists("res://docs/READINESS_V4.md"),
		ResourceLoader.exists("res://scripts/edenfall_v3.gd"),
	]
	var passed := 0
	for check in checks:
		if check:
			passed += 1
	return float(passed) / float(checks.size()) * 100.0
