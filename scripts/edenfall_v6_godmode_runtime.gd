extends "res://scripts/edenfall_v6_polish_runtime.gd"

const GODMODE_VERSION := "0.6.2-rc6"
const RC6_SUSPEND_PATH := "user://edenfall_suspend_rc6.json"
const GodmodeDirectorScript: Script = preload("res://scripts/v6/godmode_director.gd")
const BossPatternLibraryScript: Script = preload("res://scripts/v6/boss_pattern_library.gd")

const SPECIAL_ROOM_KINDS := ["settlement", "sacrifice", "memory", "maintenance", "serpent_terminal"]
const COMBAT_ROOM_KINDS := ["combat", "trial", "contract"]

var godmode_director: RefCounted = GodmodeDirectorScript.new()
var boss_patterns: RefCounted = BossPatternLibraryScript.new()
var active_synergies: Dictionary = {}
var choice_open := false
var choice_index := 0
var choice_context := ""
var choice_options: Array[String] = []
var halo_charge := 0
var halo_cooldown := 0.0
var orbital_cooldown := 0.0
var synergy_notice_timer := 0.0
var _enemy_uid_counter := 1
var _restoring_rc6 := false
var _initializing_rc6 := false

func _ready() -> void:
	if not profile.has("faction_reputation"):
		profile["faction_reputation"] = {
			"salt_caravans":0, "ash_covenant":0, "tubal_foundries":0,
			"enoch_outlaws":0, "lamech_houses":0, "unnamed":0,
		}
	if not profile.has("archive_records"):
		profile["archive_records"] = []
	if not profile.has("guardians_defeated"):
		profile["guardians_defeated"] = []
	if not settings.has("strong_telegraphs"):
		settings["strong_telegraphs"] = true
	if not settings.has("projectile_outlines"):
		settings["projectile_outlines"] = true
	super._ready()
	_refresh_build_synergies(false)

func settings_rows() -> Array:
	var rows: Array = super.settings_rows()
	rows.append({"key":"strong_telegraphs", "label":"STRONG ATTACK TELEGRAPHS"})
	rows.append({"key":"projectile_outlines", "label":"PROJECTILE OUTLINES"})
	return rows

func start_new_run(lineage_index: int, seed_override: int = 0) -> void:
	_initializing_rc6 = true
	choice_open = false
	choice_context = ""
	choice_options.clear()
	halo_charge = 0
	halo_cooldown = 0.0
	orbital_cooldown = 0.0
	_enemy_uid_counter = 1
	super.start_new_run(lineage_index, seed_override)
	_initializing_rc6 = false
	if not player.is_empty():
		player["fungal_armor"] = 0
		player["orbitals"] = 0
		player["lifesteal_chance"] = 0.0
		player["spore_power"] = 0.0
		player["serpent_mutations"] = []
	_refresh_build_synergies(false)
	save_suspended_run()

func generate_floor() -> void:
	super.generate_floor()
	_decorate_rc6_floor()

func _decorate_rc6_floor() -> void:
	var assignments: Dictionary = godmode_director.call("special_room_assignments", room_order, room_graph, biome_index, run_seed)
	for coord_variant in assignments.keys():
		var coord := Vector2i(coord_variant)
		if not room_graph.has(coord):
			continue
		var room: Dictionary = room_graph[coord]
		var kind := String(assignments[coord_variant])
		room["kind"] = kind
		room["modifier"] = "none"
		room["reward_multiplier"] = 1.0
		room["rc6_used"] = false
		room["rc6_rewarded"] = false
		if kind == "settlement":
			room["faction"] = godmode_director.call("faction_for", biome_index, coord, run_seed)
		elif kind == "memory":
			room["memory_id"] = "%s_biome_%d" % [String(LINEAGES[selected_lineage]["id"]), biome_index + 1]
		room_graph[coord] = room
	for coord in room_order:
		if not room_graph.has(coord):
			continue
		var existing: Dictionary = room_graph[coord]
		if String(existing.get("kind", "")) == "combat" and int(existing.get("depth", 0)) >= 3:
			var local_seed := int(godmode_director.call("room_seed", run_seed, coord, biome_index, int(existing.get("depth", 0)), 771))
			var local_rng := RandomNumberGenerator.new()
			local_rng.seed = local_seed
			if local_rng.randf() < 0.18:
				existing["kind"] = "contract"
				existing["modifier"] = "elite_hunt"
				existing["reward_multiplier"] = 1.55
				existing["rc6_rewarded"] = false
				room_graph[coord] = existing
	for coord in room_order:
		if not room_graph.has(coord):
			continue
		var room: Dictionary = room_graph[coord]
		if String(room.get("kind", "")) == "shop":
			room["rc6_shop_faction"] = godmode_director.call("faction_for", biome_index, coord, run_seed)
			room["rc6_priced"] = false
			room_graph[coord] = room

func enter_room(coord: Vector2i, movement_direction: Vector2i) -> void:
	choice_open = false
	choice_context = ""
	choice_options.clear()
	super.enter_room(coord, movement_direction)
	if not room_graph.has(current_room):
		return
	var room: Dictionary = room_graph[current_room]
	var kind := String(room.get("kind", ""))
	if kind in SPECIAL_ROOM_KINDS:
		room["cleared"] = true
		room_graph[current_room] = room
		objective = objective_for_room(room)
	if kind == "shop":
		_apply_shop_reputation_price()

func spawn_room(room: Dictionary) -> void:
	var kind := String(room.get("kind", "combat"))
	if kind in SPECIAL_ROOM_KINDS or kind == "sanctuary":
		return
	var saved_state := rng.state
	var depth := int(room.get("depth", 0))
	rng.seed = int(godmode_director.call("room_seed", run_seed, current_room, biome_index, depth, 101))
	match kind:
		"shop":
			room["shop"] = build_shop()
		"treasure":
			spawn_relic(arena_rect().get_center(), random_relic_id())
		"boss":
			spawn_boss()
		"combat", "trial", "contract":
			var count := clampi(3 + int(depth / 2) + biome_index, 4, 8)
			if active_mode == "training":
				count = maxi(3, count - 1)
			elif active_mode == "daily":
				count = mini(8, count + 1)
			if kind == "trial":
				count = mini(9, count + 2)
			elif kind == "contract":
				count = mini(9, count + 1)
			var pool := enemy_pool_for_biome()
			var positions := _encounter_positions(count)
			for index in range(count):
				var enemy_id := pool[rng.randi_range(0, pool.size() - 1)]
				spawn_enemy(enemy_id, positions[index], index)
			if kind in ["trial", "contract"] and not enemies.is_empty():
				promote_enemy_to_elite(0, "armored")
			if kind == "contract" and enemies.size() > 2:
				promote_enemy_to_elite(2, "swift")
		_:
			pass
	rng.state = saved_state

func objective_for_room(room: Dictionary) -> String:
	match String(room.get("kind", "")):
		"settlement": return "Choose how to deal with the preadamite settlement"
		"sacrifice": return "Decide what the chamber is allowed to take"
		"memory": return "Recover or erase the lineage memory"
		"maintenance": return "Open the sealed service cache"
		"serpent_terminal": return "Answer the Serpent adaptation request"
		"contract": return "Fulfil the hostile-clearance contract"
		_: return super.objective_for_room(room)

func room_title(room: Dictionary) -> String:
	match String(room.get("kind", "")):
		"settlement":
			var faction := String(room.get("faction", "unnamed"))
			var definition: Dictionary = godmode_director.call("faction_definition", faction)
			return "%s // SETTLEMENT CONTACT" % String(definition.get("name", "THE UNNAMED"))
		"sacrifice": return "%s // SACRIFICE BIOREACTOR" % BIOME_CHAPTERS[biome_index]
		"memory": return "%s // LINEAGE MEMORY" % BIOME_CHAPTERS[biome_index]
		"maintenance": return "%s // SECRET MAINTENANCE TUNNEL" % BIOME_CHAPTERS[biome_index]
		"serpent_terminal": return "%s // SERPENT TERMINAL" % BIOME_CHAPTERS[biome_index]
		"contract": return "%s // ENHANCED-HOST CONTRACT" % BIOME_CHAPTERS[biome_index]
		_: return super.room_title(room)

func interact() -> void:
	if choice_open:
		_confirm_room_choice()
		return
	if state == "run" and room_graph.has(current_room):
		var room: Dictionary = room_graph[current_room]
		var kind := String(room.get("kind", ""))
		if kind in SPECIAL_ROOM_KINDS:
			if bool(room.get("rc6_used", false)):
				notify("THIS SYSTEM HAS ALREADY BEEN RESOLVED")
				return
			_open_room_choice(room)
			return
	super.interact()

func _open_room_choice(room: Dictionary) -> void:
	choice_open = true
	choice_index = 0
	choice_context = String(room.get("kind", ""))
	choice_options.clear()
	match choice_context:
		"settlement":
			choice_options = ["TRADE 6 SCRAP // FAVOR + REPAIR", "SALVAGE STORES // SCRAP + REPUTATION LOSS"]
		"sacrifice":
			choice_options = ["OFFER 1 CELL // GUARANTEED RELIC", "REFUSE THE OFFER // TAKE LOOSE SCRAP"]
		"memory":
			choice_options = ["RECOVER MEMORY // ARCHIVE + MASTERY", "ERASE MEMORY // IMMEDIATE SALVAGE"]
		"maintenance":
			choice_options = ["OPEN CACHE FOR 4 SCRAP // RELIC", "STRIP SERVICE COPPER // SCRAP"]
		"serpent_terminal":
			choice_options = ["ACCEPT ADAPTATION // MUTATE BUILD", "REFUSE TEMPLATE // REPAIR + SHIELD"]
		_:
			choice_open = false

func _confirm_room_choice() -> void:
	if not choice_open or not room_graph.has(current_room):
		return
	var room: Dictionary = room_graph[current_room]
	var success := true
	match choice_context:
		"settlement":
			var faction := String(room.get("faction", "unnamed"))
			if choice_index == 0:
				if scraps < 6:
					notify("SETTLEMENT TRADE REQUIRES 6 SCRAP")
					success = false
				else:
					scraps -= 6
					_adjust_reputation(faction, 2)
					player["hp"] = minf(float(player["max_hp"]), float(player["hp"]) + 1.0)
					run_score += 120
					notify("SETTLEMENT TRADE ACCEPTED // ROUTE FAVOR INCREASED")
			else:
				scraps += 10 + biome_index * 2
				_adjust_reputation(faction, -2)
				run_score += 45
				notify("STORES STRIPPED // FACTION MEMORY UPDATED")
		"sacrifice":
			if choice_index == 0:
				if float(player["hp"]) <= 1.5:
					notify("BIOREACTOR REFUSES A LETHAL OFFER")
					success = false
				else:
					player["hp"] = maxf(0.5, float(player["hp"]) - 1.0)
					spawn_relic(arena_rect().get_center(), random_relic_id(player.get("inventory", [])))
					run_score += 220
					notify("TISSUE ACCEPTED // RELIC PROTOCOL RELEASED")
			else:
				scraps += 3 + biome_index
				notify("OFFER REFUSED // CHAMBER SALVAGE RECOVERED")
		"memory":
			var memory_id := String(room.get("memory_id", "memory_%d" % biome_index))
			if choice_index == 0:
				var records: Array = profile.get("archive_records", [])
				if memory_id not in records:
					records.append(memory_id)
					profile["archive_records"] = records
				mastery_gained += 45 + biome_index * 10
				run_score += 250
				notify("CONTRADICTORY LINEAGE RECORD ADDED TO ARCHIVE")
			else:
				scraps += 8 + biome_index * 2
				_adjust_reputation("unnamed", -1)
				notify("MEMORY PURGED // COMPONENTS RECOVERED")
		"maintenance":
			if choice_index == 0:
				if scraps < 4:
					notify("SERVICE CACHE REQUIRES 4 SCRAP")
					success = false
				else:
					scraps -= 4
					spawn_relic(arena_rect().get_center(), random_relic_id(player.get("inventory", [])))
					notify("MAINTENANCE CACHE OPEN // PROTOCOL RECOVERED")
			else:
				scraps += 6 + biome_index
				notify("SERVICE CONDUIT STRIPPED")
		"serpent_terminal":
			if choice_index == 0:
				var mutations: Array = player.get("serpent_mutations", [])
				var mutation: Dictionary = godmode_director.call("serpent_mutation", run_seed, String(player["id"]), mutations.size())
				var mutation_id := String(mutation.get("id", "forked_aim"))
				if mutation_id not in mutations:
					mutations.append(mutation_id)
					player["serpent_mutations"] = mutations
					_apply_serpent_mutation(mutation_id)
				notify("SERPENT ADAPTATION ACCEPTED // %s" % String(mutation.get("name", "MUTATION")))
			else:
				player["hp"] = minf(float(player["max_hp"]), float(player["hp"]) + 1.5)
				player["shield"] = true
				run_score += 300
				notify("SERPENT TEMPLATE REFUSED // EDEN BOUNDARY REASSERTED")
		_:
			success = false
	if not success:
		return
	room["rc6_used"] = true
	room_graph[current_room] = room
	choice_open = false
	choice_context = ""
	choice_options.clear()
	play_sfx("ui_confirm", -2.0, 80)
	haptic(45, 0.45)
	save_profile()
	save_suspended_run()

func _apply_serpent_mutation(id: String) -> void:
	match id:
		"hard_skin":
			player["fungal_armor"] = mini(4, int(player.get("fungal_armor", 0)) + 2)
		"predator_signal":
			player["luck"] = float(player["luck"]) + 0.08
		"forked_aim":
			player["parallel"] = true
		"mirror_nerve":
			player["dash_delay"] = maxf(0.42, float(player["dash_delay"]) * 0.90)

func _adjust_reputation(id: String, delta: int) -> void:
	var reps: Dictionary = profile.get("faction_reputation", {})
	reps[id] = clampi(int(reps.get(id, 0)) + delta, -20, 20)
	profile["faction_reputation"] = reps

func _apply_shop_reputation_price() -> void:
	if not room_graph.has(current_room):
		return
	var room: Dictionary = room_graph[current_room]
	if String(room.get("kind", "")) != "shop" or bool(room.get("rc6_priced", false)):
		return
	var faction := String(room.get("rc6_shop_faction", "salt_caravans"))
	var reps: Dictionary = profile.get("faction_reputation", {})
	var reputation := clampi(int(reps.get(faction, 0)), -10, 10)
	var factor := clampf(1.0 - float(reputation) * 0.02, 0.78, 1.22)
	var items: Array = room.get("shop", [])
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var base_cost := int(item.get("base_cost", item.get("cost", 0)))
		item["base_cost"] = base_cost
		item["cost"] = maxi(1, int(round(float(base_cost) * factor)))
		items[index] = item
	room["shop"] = items
	room["rc6_priced"] = true
	room_graph[current_room] = room

func _draw_shop_overlay(room: Dictionary) -> void:
	super._draw_shop_overlay(room)
	var faction := String(room.get("rc6_shop_faction", "salt_caravans"))
	var definition: Dictionary = godmode_director.call("faction_definition", faction)
	var reps: Dictionary = profile.get("faction_reputation", {})
	var safe := safe_rect()
	draw_text_centered("%s  //  REPUTATION %+d" % [String(definition.get("name", "CARAVAN")), int(reps.get(faction, 0))], Vector2(safe.get_center().x, safe.get_center().y - 57.0), 7, Color(definition.get("color", Color8(222,181,102))))

func check_room_clear() -> void:
	if state == "run" and enemies.is_empty() and room_graph.has(current_room):
		var room: Dictionary = room_graph[current_room]
		if String(room.get("kind", "")) == "contract" and not bool(room.get("cleared", false)):
			room["cleared"] = true
			room["rc6_rewarded"] = true
			room_graph[current_room] = room
			rooms_cleared += 1
			var reward := int(round(float(16 + int(room.get("depth", 0)) + biome_index * 3) * float(room.get("reward_multiplier", 1.55))))
			scraps += reward
			run_score += 650 + biome_index * 180
			mastery_gained += 55 + biome_index * 12
			spawn_relic(arena_rect().get_center(), random_relic_id(player.get("inventory", [])))
			_adjust_reputation("enoch_outlaws", -1)
			objective = "Claim the contract relic and choose a gate"
			play_sfx("door")
			notify("CONTRACT FULFILLED // ENHANCED-HOST BOUNTY RELEASED")
			save_suspended_run()
			return
	super.check_room_clear()

func spawn_enemy(id: String, position: Vector2, variant: int = 0) -> void:
	super.spawn_enemy(id, position, variant)
	if enemies.is_empty():
		return
	var index := enemies.size() - 1
	var enemy: Dictionary = enemies[index]
	enemy["spawn_uid"] = _enemy_uid_counter
	_enemy_uid_counter += 1
	enemy["special_timer"] = _enemy_special_interval(id) * rng.randf_range(0.72, 1.18)
	enemy["special_windup"] = 0.0
	enemy["special_windup_max"] = 0.0
	enemies[index] = enemy

func spawn_boss() -> void:
	super.spawn_boss()
	if enemies.is_empty():
		return
	var index := enemies.size() - 1
	var boss: Dictionary = enemies[index]
	boss["spawn_uid"] = _enemy_uid_counter
	_enemy_uid_counter += 1
	boss["boss_pattern_index"] = 0
	boss["boss_windup"] = 0.0
	boss["boss_windup_max"] = 0.0
	boss["boss_pending"] = {}
	boss["boss_charge"] = 0.0
	boss["boss_charge_dir"] = Vector2.DOWN
	boss["boss_charge_multiplier"] = 0.0
	enemies[index] = boss

func update_enemies(delta: float) -> void:
	super.update_enemies(delta)
	_update_enemy_specials(delta)

func _update_enemy_specials(delta: float) -> void:
	var initial_count := enemies.size()
	for index in range(initial_count):
		if index >= enemies.size():
			break
		var enemy: Dictionary = enemies[index]
		if bool(enemy.get("boss", false)):
			continue
		var interval := _enemy_special_interval(String(enemy.get("id", "")))
		if interval <= 0.0:
			continue
		var windup_before := float(enemy.get("special_windup", 0.0))
		if windup_before > 0.0:
			var windup := maxf(0.0, windup_before - delta)
			enemy["special_windup"] = windup
			enemy["attack"] = maxf(float(enemy.get("attack", 0.0)), windup)
			enemies[index] = enemy
			if windup <= 0.0:
				_release_enemy_special(index)
			continue
		var timer := float(enemy.get("special_timer", interval)) - delta
		enemy["special_timer"] = timer
		if timer <= 0.0:
			var windup_duration := 0.54
			enemy["special_windup"] = windup_duration
			enemy["special_windup_max"] = windup_duration
			enemy["special_timer"] = interval
			enemy["attack"] = windup_duration
		enemies[index] = enemy

func _enemy_special_interval(id: String) -> float:
	match id:
		"cherub_drone": return 3.1
		"fallen_angel": return 3.6
		"halo_sentinel": return 4.8
		"ophanim_scout": return 3.4
		"bone_shepherd": return 5.2
		"grafted_colossus": return 4.5
		"serpent_spawn": return 3.2
		_: return 0.0

func _release_enemy_special(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy: Dictionary = enemies[index]
	var id := String(enemy.get("id", ""))
	var origin := Vector2(enemy["pos"])
	var direction := (Vector2(player["pos"]) - origin).normalized()
	match id:
		"cherub_drone":
			for angle in [-0.18, 0.0, 0.18]:
				enemy_shoot(origin, direction.rotated(angle), 390.0, 1.0)
		"fallen_angel":
			for angle in [-0.48, -0.24, 0.0, 0.24, 0.48]:
				enemy_shoot(origin, direction.rotated(angle), 330.0, 1.0)
		"halo_sentinel":
			for other_index in range(enemies.size()):
				if other_index == index:
					continue
				var other: Dictionary = enemies[other_index]
				if bool(other.get("boss", false)):
					continue
				if origin.distance_to(Vector2(other["pos"])) <= 230.0:
					other["shield_hp"] = minf(float(other["max_hp"]) * 0.34, float(other.get("shield_hp", 0.0)) + float(other["max_hp"]) * 0.12)
					enemies[other_index] = other
			spawn_effect("shield", origin, Color8(232, 205, 108), 0.0)
		"ophanim_scout":
			for shot in range(8):
				enemy_shoot(origin, Vector2.RIGHT.rotated(TAU * float(shot) / 8.0 + visual_clock * 0.22), 285.0, 1.0)
		"bone_shepherd":
			if enemies.size() < 9:
				for side in [-1.0, 1.0]:
					spawn_enemy("nephilim_husk", _resolve_position_against_obstacles(origin + Vector2(side * 72.0, 34.0), 27.0), _enemy_uid_counter)
		"grafted_colossus":
			for shot in range(12):
				enemy_shoot(origin, Vector2.RIGHT.rotated(TAU * float(shot) / 12.0), 265.0, 1.0)
		"serpent_spawn":
			for shot in range(6):
				enemy_shoot(origin, Vector2.RIGHT.rotated(TAU * float(shot) / 6.0 + visual_clock * 0.38), 345.0, 1.0)
	enemy["special_windup"] = 0.0
	enemy["attack"] = 0.28
	if index < enemies.size():
		enemies[index] = enemy

func update_boss(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> Vector2:
	var ratio := float(enemy["hp"]) / maxf(0.001, float(enemy["max_hp"]))
	var stage := 0
	if ratio < 0.68:
		stage = 1
	if ratio < 0.34:
		stage = 2
	if stage > int(enemy.get("stage", 0)):
		enemy["stage"] = stage
		spawn_effect("boss_phase", Vector2(enemy["pos"]), Color(BIOMES[biome_index]["accent"]), 0.0)
		play_sfx("boss_phase")
		haptic(90, 0.8)
		if String(player["id"]) == "adam":
			player["hp"] = minf(float(player["max_hp"]), float(player["hp"]) + 1.0)
		if String(enemy.get("id", "")) == "gate_cherub":
			enemy["shield_hp"] = float(enemy.get("shield_hp", 0.0)) + float(enemy["max_hp"]) * 0.08
	var charge := maxf(0.0, float(enemy.get("boss_charge", 0.0)) - delta)
	if float(enemy.get("boss_charge", 0.0)) > 0.0:
		enemy["boss_charge"] = charge
		return Vector2(enemy.get("boss_charge_dir", direction)).normalized() * float(enemy["speed"]) * float(enemy.get("boss_charge_multiplier", 4.0))
	var windup_before := float(enemy.get("boss_windup", 0.0))
	if windup_before > 0.0:
		var windup := maxf(0.0, windup_before - delta)
		enemy["boss_windup"] = windup
		enemy["attack"] = maxf(float(enemy.get("attack", 0.0)), windup)
		if windup <= 0.0:
			_release_boss_pattern(enemy)
		return _boss_movement(enemy, direction, distance, float(Dictionary(enemy.get("boss_pending", {})).get("move_scale", 0.2)))
	if float(enemy.get("cooldown", 0.0)) <= 0.0:
		var pattern_index := int(enemy.get("boss_pattern_index", 0))
		var pattern: Dictionary = boss_patterns.call("build_pattern", String(enemy.get("id", "watcher_engine")), stage, pattern_index, direction, float(enemy.get("phase", 0.0)))
		enemy["boss_pattern_index"] = pattern_index + 1
		enemy["boss_pending"] = pattern
		enemy["boss_telegraph_dir"] = direction
		enemy["boss_windup"] = float(pattern.get("windup", 0.55))
		enemy["boss_windup_max"] = float(pattern.get("windup", 0.55))
		enemy["attack"] = float(pattern.get("windup", 0.55))
		return _boss_movement(enemy, direction, distance, float(pattern.get("move_scale", 0.25)))
	return _boss_movement(enemy, direction, distance, 0.70)

func _release_boss_pattern(enemy: Dictionary) -> void:
	var pattern: Dictionary = enemy.get("boss_pending", {})
	var origin := Vector2(enemy["pos"])
	for shot_variant in Array(pattern.get("shots", [])):
		var shot: Dictionary = shot_variant
		enemy_shoot(origin, Vector2(shot.get("direction", Vector2.DOWN)), float(shot.get("speed", 300.0)), float(shot.get("damage", 1.0)))
	var shield_ratio := float(pattern.get("shield_ratio", 0.0))
	if shield_ratio > 0.0:
		enemy["shield_hp"] = minf(float(enemy["max_hp"]) * 0.30, float(enemy.get("shield_hp", 0.0)) + float(enemy["max_hp"]) * shield_ratio)
	var summon_id := String(pattern.get("summon_id", ""))
	var summon_count := int(pattern.get("summon_count", 0))
	if not summon_id.is_empty() and enemies.size() < 10:
		for summon_index in range(mini(summon_count, 10 - enemies.size())):
			var angle := TAU * float(summon_index) / float(maxi(1, summon_count))
			var summon_pos := _resolve_position_against_obstacles(origin + Vector2.RIGHT.rotated(angle) * 105.0, 20.0)
			spawn_enemy(summon_id, summon_pos, summon_index)
	var charge_duration := float(pattern.get("charge_duration", 0.0))
	if charge_duration > 0.0:
		enemy["boss_charge"] = charge_duration
		enemy["boss_charge_dir"] = Vector2(enemy.get("boss_telegraph_dir", Vector2.DOWN)).normalized()
		enemy["boss_charge_multiplier"] = float(pattern.get("charge_multiplier", 4.0))
	enemy["cooldown"] = float(pattern.get("cooldown", 1.2))
	enemy["boss_windup"] = 0.0
	enemy["boss_pending"] = {}
	enemy["attack"] = 0.34

func _boss_movement(enemy: Dictionary, direction: Vector2, distance: float, scale: float) -> Vector2:
	var speed := float(enemy["speed"]) * scale
	match String(enemy.get("id", "watcher_engine")):
		"watcher_engine":
			return (direction * (0.18 if distance > 260.0 else -0.10) + direction.orthogonal() * 0.82).normalized() * speed
		"first_nephilim":
			return direction * speed * (1.0 if distance > 155.0 else 0.22)
		"gate_cherub":
			return (direction * 0.12 + direction.orthogonal() * 0.94).normalized() * speed
		"tower_enoch":
			return Vector2.ZERO
		"serpent_interface":
			return (direction * 0.16 + direction.orthogonal() * 0.98).normalized() * speed
		_:
			return direction * speed

func apply_relic(id: String) -> void:
	var inventory_before: Array = player.get("inventory", []).duplicate()
	var catalog := relic_catalog()
	var definition: Dictionary = catalog.get(id, {})
	super.apply_relic(id)
	if id in inventory_before or id not in player.get("inventory", []):
		return
	var effect := String(definition.get("effect", ""))
	var power := float(definition.get("power", 1.0))
	match effect:
		"lifesteal":
			player["lifesteal_chance"] = minf(0.32, float(player.get("lifesteal_chance", 0.0)) + 0.025 * power)
		"orbit":
			player["orbitals"] = mini(4, int(player.get("orbitals", 0)) + 1)
		"spore":
			player["spore_power"] = float(player.get("spore_power", 0.0)) + power
		"scrap":
			scraps += int(round(7.0 * power))
	if id.begins_with("industrial_halo"):
		player["orbitals"] = mini(4, int(player.get("orbitals", 0)) + 1)
	_refresh_build_synergies(true)

func _refresh_build_synergies(announce_new: bool) -> void:
	if player.is_empty():
		active_synergies.clear()
		return
	var previous := active_synergies.keys()
	active_synergies = godmode_director.call("synergies_for", player.get("inventory", []), relic_catalog())
	if announce_new:
		for synergy_id in active_synergies.keys():
			if synergy_id not in previous:
				var definition: Dictionary = active_synergies[synergy_id]
				notify("SYNERGY ONLINE // %s" % String(definition.get("name", String(synergy_id).to_upper())))
				synergy_notice_timer = 3.0

func fire_player_weapon() -> void:
	if player.is_empty():
		return
	fire_timer = float(player["fire_delay"])
	shoot_timer = 0.13
	var aim := Vector2(player["aim"]).normalized()
	if bool(settings.get("aim_assist", true)):
		aim = assisted_aim(aim)
	var weapon: Dictionary = player.get("weapon", director.weapon_for(String(player["id"])))
	var critical_chance := float(player["luck"])
	if String(player["id"]) == "abel" and float(player["hp"]) <= float(player["max_hp"]) * 0.5:
		critical_chance += 0.22
	if "predator_signal" in player.get("serpent_mutations", []):
		critical_chance += minf(0.18, float(combo) * 0.006)
	var critical := rng.randf() < critical_chance
	var combo_multiplier := 1.0 + minf(0.55, float(combo) * 0.018)
	var modifier_multiplier := 1.22 if current_modifier == "fragile_protocol" else 1.0
	var base_damage := float(player["damage"]) * float(weapon.get("damage", 1.0)) * combo_multiplier * modifier_multiplier
	if critical:
		base_damage *= 1.8
	var rank := 1 + mini(2, int(rooms_cleared / 5))
	var projectile_count := int(weapon.get("projectiles", 1))
	var spread := float(weapon.get("spread", 0.0))
	match String(player["id"]):
		"adam":
			if rank >= 2:
				projectile_count += 1
				spread = maxf(spread, 0.055)
		"abel":
			pass
		"cain":
			if rank >= 3:
				base_damage *= 1.16
		"seth":
			pass
		"naamah":
			if rank >= 2:
				projectile_count += 2
				spread = maxf(spread, 0.14)
	if "forked_aim" in player.get("serpent_mutations", []):
		projectile_count += 2
		spread = maxf(spread, 0.16)
	for projectile_index in range(projectile_count):
		var offset := float(projectile_index) - float(projectile_count - 1) * 0.5
		_spawn_rc6_projectile(aim.rotated(offset * spread), base_damage, weapon, critical, rank, false)
	if bool(player.get("parallel", false)):
		for angle in [-0.10, 0.10]:
			_spawn_rc6_projectile(aim.rotated(angle), base_damage * 0.60, weapon, false, rank, true)
	if critical and active_synergies.has("shepherd_oracle"):
		for angle in [-0.20, 0.20]:
			_spawn_oracle_shard(aim.rotated(angle), base_damage * 0.34)
	shots_fired += projectile_count + (2 if bool(player.get("parallel", false)) else 0)
	spawn_effect("muzzle", Vector2(player["pos"]) + aim * 25.0, Color(player["color"]), aim.angle())
	play_sfx("critical" if critical else "shot_%02d" % (posmod(selected_lineage, 3) + 1))
	haptic(18, 0.22)

func _spawn_rc6_projectile(direction: Vector2, damage: float, weapon: Dictionary, critical: bool, rank: int, refracted: bool) -> void:
	var speed := float(player["shot_speed"]) * float(weapon.get("speed", 1.0))
	var pattern := String(weapon.get("pattern", "rifle"))
	var radius := 7.0 if pattern == "cannon" else (4.0 if pattern == "beam" else 5.0)
	var pierce := int(player.get("pierce", 0)) + int(weapon.get("pierce", 0))
	var homing := float(weapon.get("homing", 0.0))
	var explosion := float(weapon.get("explosion", 0.0))
	var status := String(weapon.get("status", "none"))
	var chain := 1 if pattern == "beam" else 0
	var bounces := 1 if pattern == "lance" else 0
	if String(player["id"]) == "abel" and rank >= 2:
		chain += 1
	if String(player["id"]) == "cain" and rank >= 2:
		explosion += 24.0
	if String(player["id"]) == "seth" and rank >= 2:
		bounces += 1
	if active_synergies.has("marrow_bore"):
		pierce += 2
		damage *= 1.12
		speed *= 0.92
	if active_synergies.has("refracted_choir") and refracted:
		homing = maxf(homing, 0.22)
		chain += 1
	if active_synergies.has("spore_circuit") and status == "none":
		status = "spore"
	if float(player.get("spore_power", 0.0)) > 0.0 and status == "none" and rng.randf() < 0.16:
		status = "spore"
	var before := bullets.size()
	spawn_bullet(Vector2(player["pos"]) + direction.normalized() * 24.0, direction.normalized() * speed, damage, "player", radius, Color(player["color"]), pierce, critical)
	if bullets.size() <= before:
		return
	var bullet: Dictionary = bullets[bullets.size() - 1]
	bullet["homing"] = homing
	bullet["explosion"] = explosion
	bullet["status"] = status
	bullet["chain"] = chain
	bullet["bounces"] = bounces
	bullet["hit_ids"] = []
	bullets[bullets.size() - 1] = bullet

func _spawn_oracle_shard(direction: Vector2, damage: float) -> void:
	var before := bullets.size()
	spawn_bullet(Vector2(player["pos"]) + direction.normalized() * 20.0, direction.normalized() * float(player["shot_speed"]) * 0.86, damage, "player", 4.0, Color8(245, 224, 151), 0, false)
	if bullets.size() <= before:
		return
	var bullet: Dictionary = bullets[bullets.size() - 1]
	bullet["homing"] = 0.48
	bullet["status"] = "marked"
	bullet["chain"] = 0
	bullet["bounces"] = 0
	bullet["hit_ids"] = []
	bullets[bullets.size() - 1] = bullet

func update_run(delta: float) -> void:
	if choice_open:
		input_move = Vector2.ZERO
		input_aim = Vector2.ZERO
		return
	halo_cooldown = maxf(0.0, halo_cooldown - delta)
	orbital_cooldown = maxf(0.0, orbital_cooldown - delta)
	synergy_notice_timer = maxf(0.0, synergy_notice_timer - delta)
	super.update_run(delta)

func update_bullets(delta: float) -> void:
	for bullet_index in range(bullets.size() - 1, -1, -1):
		if bullet_index >= bullets.size():
			continue
		var bullet: Dictionary = bullets[bullet_index]
		var owner := String(bullet.get("owner", "enemy"))
		if owner == "player" and float(bullet.get("homing", 0.0)) > 0.0 and not enemies.is_empty():
			var target = nearest_enemy(Vector2(bullet["pos"]))
			if target != null:
				var desired := (Vector2(target["pos"]) - Vector2(bullet["pos"])).normalized() * Vector2(bullet["vel"]).length()
				bullet["vel"] = Vector2(bullet["vel"]).lerp(desired, clampf(float(bullet.get("homing", 0.0)) * delta * 6.0, 0.0, 0.34))
		var previous := Vector2(bullet["pos"])
		var current := previous + Vector2(bullet["vel"]) * delta
		bullet["pos"] = current
		bullet["life"] = float(bullet.get("life", 0.0)) - delta
		if float(bullet["life"]) <= 0.0:
			bullets.remove_at(bullet_index)
			continue
		if _bullet_hits_obstacle(previous, current, float(bullet["radius"])):
			if owner == "player" and int(bullet.get("bounces", 0)) > 0:
				var normal := _bullet_cover_normal(current)
				var velocity := Vector2(bullet["vel"])
				if normal.length_squared() < 0.5:
					normal = -velocity.normalized()
				bullet["vel"] = velocity - 2.0 * velocity.dot(normal) * normal
				bullet["bounces"] = int(bullet.get("bounces", 0)) - 1
				bullet["pos"] = previous + Vector2(bullet["vel"]).normalized() * 5.0
				spawn_effect("cover_impact", previous, Color(bullet["color"]), Vector2(bullet["vel"]).angle())
			else:
				spawn_effect("cover_impact", current, Color(bullet["color"]), Vector2(bullet["vel"]).angle())
				bullets.remove_at(bullet_index)
				continue
		var arena := arena_rect()
		if not arena.grow(14.0).has_point(Vector2(bullet["pos"])):
			if owner == "player" and int(bullet.get("bounces", 0)) > 0:
				var velocity := Vector2(bullet["vel"])
				if float(bullet["pos"].x) <= arena.position.x or float(bullet["pos"].x) >= arena.end.x:
					velocity.x *= -1.0
				if float(bullet["pos"].y) <= arena.position.y or float(bullet["pos"].y) >= arena.end.y:
					velocity.y *= -1.0
				bullet["vel"] = velocity
				bullet["bounces"] = int(bullet.get("bounces", 0)) - 1
				bullet["pos"] = clamp_to_arena(Vector2(bullet["pos"]), float(bullet["radius"]) + 2.0)
			else:
				bullets.remove_at(bullet_index)
				continue
		if owner == "enemy" and _reflect_or_absorb_hostile_bullet(bullet_index, bullet):
			continue
		if String(bullet.get("owner", owner)) == "player":
			var consumed := false
			var hit_ids: Array = bullet.get("hit_ids", [])
			for enemy_index in range(enemies.size() - 1, -1, -1):
				if enemy_index >= enemies.size():
					continue
				var enemy: Dictionary = enemies[enemy_index]
				var uid := int(enemy.get("spawn_uid", enemy_index + 1))
				if uid in hit_ids:
					continue
				if Vector2(bullet["pos"]).distance_to(Vector2(enemy["pos"])) < float(bullet["radius"]) + float(enemy["radius"]):
					hit_ids.append(uid)
					bullet["hit_ids"] = hit_ids
					_apply_rc6_bullet_hit(enemy_index, bullet, uid)
					bullet["pierce"] = int(bullet.get("pierce", 0)) - 1
					spawn_effect("impact", Vector2(bullet["pos"]), Color(bullet["color"]), Vector2(bullet["vel"]).angle())
					if int(bullet["pierce"]) < 0:
						consumed = true
						break
			if consumed:
				bullets.remove_at(bullet_index)
				continue
		elif Vector2(bullet["pos"]).distance_to(Vector2(player["pos"])) < float(bullet["radius"]) + PLAYER_RADIUS:
			damage_player(float(bullet["damage"]), Vector2(bullet["vel"]).normalized())
			bullets.remove_at(bullet_index)
			continue
		if bullet_index < bullets.size():
			bullets[bullet_index] = bullet

func _bullet_cover_normal(position: Vector2) -> Vector2:
	for obstacle in room_obstacles:
		var rect := Rect2(obstacle["rect"])
		if not rect.grow(10.0).has_point(position):
			continue
		var left := absf(position.x - rect.position.x)
		var right := absf(rect.end.x - position.x)
		var top := absf(position.y - rect.position.y)
		var bottom := absf(rect.end.y - position.y)
		var minimum := minf(minf(left, right), minf(top, bottom))
		if is_equal_approx(minimum, left): return Vector2.LEFT
		if is_equal_approx(minimum, right): return Vector2.RIGHT
		if is_equal_approx(minimum, top): return Vector2.UP
		return Vector2.DOWN
	return Vector2.ZERO

func _reflect_or_absorb_hostile_bullet(bullet_index: int, bullet: Dictionary) -> bool:
	if player.is_empty():
		return false
	var bullet_pos := Vector2(bullet["pos"])
	if "mirror_nerve" in player.get("serpent_mutations", []) and dash_time > 0.0 and bullet_pos.distance_to(Vector2(player["pos"])) < 58.0:
		bullet["owner"] = "player"
		bullet["vel"] = -Vector2(bullet["vel"]) * 1.08
		bullet["damage"] = maxf(7.0, float(player["damage"]) * 0.48)
		bullet["color"] = Color(player["color"])
		bullet["pierce"] = 0
		bullet["critical"] = false
		bullet["homing"] = 0.12
		bullet["status"] = "stagger"
		bullet["hit_ids"] = []
		bullets[bullet_index] = bullet
		spawn_effect("shield", bullet_pos, Color(player["color"]), 0.0)
		return false
	var orbital_count := int(player.get("orbitals", 0))
	if orbital_count > 0 and orbital_cooldown <= 0.0:
		for orbital_index in range(orbital_count):
			var angle := visual_clock * 2.0 + TAU * float(orbital_index) / float(maxi(1, orbital_count))
			var orbital_pos := Vector2(player["pos"]) + Vector2.RIGHT.rotated(angle) * 39.0
			if bullet_pos.distance_to(orbital_pos) < float(bullet["radius"]) + 11.0:
				orbital_cooldown = 0.18
				bullets.remove_at(bullet_index)
				spawn_effect("shield", orbital_pos, Color8(224, 198, 103), angle)
				return true
	if active_synergies.has("halo_capacitor") and halo_cooldown <= 0.0 and bullet_pos.distance_to(Vector2(player["pos"])) < 48.0:
		halo_charge += 1
		halo_cooldown = 0.34
		bullets.remove_at(bullet_index)
		spawn_effect("shield", bullet_pos, Color8(235, 207, 112), 0.0)
		if halo_charge >= 4:
			_release_halo_capacitor()
		return true
	return false

func _release_halo_capacitor() -> void:
	halo_charge = 0
	halo_cooldown = 1.15
	var origin := Vector2(player["pos"])
	for index in range(10):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 10.0)
		var before := bullets.size()
		spawn_bullet(origin + direction * 22.0, direction * float(player["shot_speed"]) * 0.72, float(player["damage"]) * 0.46, "player", 4.0, Color8(238, 210, 118), 0, false)
		if bullets.size() > before:
			var stored: Dictionary = bullets[bullets.size() - 1]
			stored["homing"] = 0.08
			stored["status"] = "stagger"
			stored["hit_ids"] = []
			bullets[bullets.size() - 1] = stored
	spawn_effect("boss_phase", origin, Color8(238, 210, 118), 0.0)
	play_sfx("shield")

func _apply_rc6_bullet_hit(index: int, bullet: Dictionary, target_uid: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy: Dictionary = enemies[index]
	var damage := float(bullet["damage"])
	if float(enemy.get("marked", 0.0)) > 0.0:
		damage *= 1.18
	if bool(enemy.get("boss", false)) and active_synergies.has("watcher_liturgy"):
		damage *= 1.16
	var shield_hp := float(enemy.get("shield_hp", 0.0))
	if shield_hp > 0.0:
		var shield_multiplier := 1.35 if bool(enemy.get("boss", false)) and active_synergies.has("watcher_liturgy") else 1.0
		var absorbed := minf(shield_hp, damage * shield_multiplier)
		enemy["shield_hp"] = shield_hp - absorbed
		damage -= absorbed / shield_multiplier
		enemies[index] = enemy
		spawn_effect("shield", Vector2(enemy["pos"]), Color8(121, 158, 239), 0.0)
	if damage > 0.0:
		shots_hit += 1
		damage_enemy(index, damage)
	var remaining_index := _enemy_index_by_uid(target_uid)
	if remaining_index >= 0:
		apply_status(remaining_index, String(bullet.get("status", "none")))
	if float(bullet.get("explosion", 0.0)) > 0.0:
		explode_at(Vector2(bullet["pos"]), float(bullet["explosion"]), float(bullet["damage"]) * 0.46, "player")
	if int(bullet.get("chain", 0)) > 0:
		_chain_hit_uid(Vector2(bullet["pos"]), target_uid, float(bullet["damage"]) * 0.52, int(bullet.get("chain", 0)))

func _chain_hit_uid(origin: Vector2, excluded_uid: int, damage: float, jumps: int) -> void:
	var visited: Array[int] = [excluded_uid]
	var current_origin := origin
	for jump in range(jumps):
		var best_index := -1
		var best_distance := 205.0
		for index in range(enemies.size()):
			var enemy: Dictionary = enemies[index]
			var uid := int(enemy.get("spawn_uid", index + 1))
			if uid in visited:
				continue
			var distance := current_origin.distance_to(Vector2(enemy["pos"]))
			if distance < best_distance:
				best_distance = distance
				best_index = index
		if best_index < 0:
			break
		var target: Dictionary = enemies[best_index]
		var target_uid := int(target.get("spawn_uid", best_index + 1))
		var target_pos := Vector2(target["pos"])
		draw_chain_effect(current_origin, target_pos)
		damage_enemy(best_index, damage * pow(0.78, float(jump)))
		visited.append(target_uid)
		current_origin = target_pos

func _enemy_index_by_uid(uid: int) -> int:
	for index in range(enemies.size()):
		if int(Dictionary(enemies[index]).get("spawn_uid", -1)) == uid:
			return index
	return -1

func begin_dash() -> void:
	var before := dash_timer
	super.begin_dash()
	if before > 0.0 or dash_timer <= 0.0 or player.is_empty():
		return
	if active_synergies.has("phase_drive"):
		var origin := Vector2(player["pos"])
		for index in range(enemies.size() - 1, -1, -1):
			if origin.distance_to(Vector2(enemies[index]["pos"])) <= 112.0:
				damage_enemy(index, float(player["damage"]) * 0.62)
				if index < enemies.size():
					apply_status(index, "stagger")
		spawn_effect("dash", origin, Color8(106, 202, 235), Vector2(player.get("dash_direction", Vector2.DOWN)).angle())

func damage_player(amount: float, direction: Vector2) -> void:
	if invulnerability > 0.0 or state != "run":
		return
	var armor := int(player.get("fungal_armor", 0))
	if armor > 0:
		player["fungal_armor"] = armor - 1
		invulnerability = 0.62
		spawn_effect("shield", Vector2(player["pos"]), Color8(177, 112, 205), 0.0)
		play_sfx("shield")
		haptic(42, 0.50)
		notify("MYCELIAL ARMOR ABSORBED IMPACT")
		return
	super.damage_player(amount, direction)

func kill_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy: Dictionary = enemies[index].duplicate(true)
	var was_boss := bool(enemy.get("boss", false))
	var boss_id := String(enemy.get("id", ""))
	super.kill_enemy(index)
	if not player.is_empty():
		var lifesteal := float(player.get("lifesteal_chance", 0.0))
		if lifesteal > 0.0 and rng.randf() < lifesteal:
			var before_hp := float(player["hp"])
			player["hp"] = minf(float(player["max_hp"]), before_hp + 0.5)
			if active_synergies.has("mycelial_armor") and before_hp >= float(player["max_hp"]) - 0.01:
				player["fungal_armor"] = mini(3, int(player.get("fungal_armor", 0)) + 1)
			spawn_effect("heal", Vector2(player["pos"]), Color8(171, 108, 199), 0.0)
		elif active_synergies.has("mycelial_armor") and float(player["hp"]) >= float(player["max_hp"]) - 0.01 and rng.randf() < 0.08:
			player["fungal_armor"] = mini(3, int(player.get("fungal_armor", 0)) + 1)
	if was_boss:
		var defeated: Array = profile.get("guardians_defeated", [])
		if boss_id not in defeated:
			defeated.append(boss_id)
			profile["guardians_defeated"] = defeated
		save_profile()

func draw_player() -> void:
	super.draw_player()
	if player.is_empty():
		return
	var pos := Vector2(player["pos"])
	var orbital_count := int(player.get("orbitals", 0))
	for orbital_index in range(orbital_count):
		var angle := visual_clock * 2.0 + TAU * float(orbital_index) / float(maxi(1, orbital_count))
		var orbital_pos := pos + Vector2.RIGHT.rotated(angle) * 39.0
		draw_circle(orbital_pos, 7.0, Color(0.04, 0.05, 0.04, 0.92))
		draw_arc(orbital_pos, 7.0, 0.0, TAU, 14, Color8(235, 207, 111), 2.0)
		draw_circle(orbital_pos, 2.5, Color8(245, 229, 169))
	var armor := int(player.get("fungal_armor", 0))
	for armor_index in range(armor):
		var armor_angle := -PI * 0.78 + float(armor_index) * 0.36
		var armor_pos := pos + Vector2.UP.rotated(armor_angle) * 31.0
		draw_circle(armor_pos, 4.0, Color8(188, 116, 208))

func draw_enemies() -> void:
	super.draw_enemies()
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		var pos := Vector2(enemy["pos"])
		var radius := float(enemy["radius"])
		var special_windup := float(enemy.get("special_windup", 0.0))
		if special_windup > 0.0:
			var maximum := maxf(0.001, float(enemy.get("special_windup_max", special_windup)))
			var progress := 1.0 - special_windup / maximum
			draw_arc(pos, radius + 15.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 28, Color8(247, 159, 84), 3.0)
			if bool(settings.get("strong_telegraphs", true)):
				draw_text_centered("SPECIAL", pos - Vector2(0, radius + 28.0), 7, Color8(247, 184, 111))
		if bool(enemy.get("boss", false)) and float(enemy.get("boss_windup", 0.0)) > 0.0:
			var maximum := maxf(0.001, float(enemy.get("boss_windup_max", enemy["boss_windup"])))
			var progress := 1.0 - float(enemy["boss_windup"]) / maximum
			draw_arc(pos, radius + 22.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, Color8(255, 107, 78), 5.0)
			var telegraph_dir := Vector2(enemy.get("boss_telegraph_dir", Vector2.DOWN)).normalized()
			draw_line(pos + telegraph_dir * radius, pos + telegraph_dir * (radius + 95.0), Color(1.0, 0.32, 0.22, 0.34), 4.0)
			if bool(settings.get("strong_telegraphs", true)):
				draw_text_centered("GUARDIAN ATTACK", pos - Vector2(0, radius + 34.0), 8, Color8(255, 154, 118))

func draw_bullets() -> void:
	super.draw_bullets()
	if not bool(settings.get("projectile_outlines", true)):
		return
	for bullet_variant in bullets:
		var bullet: Dictionary = bullet_variant
		var pos := Vector2(bullet["pos"])
		var radius := maxf(4.0, float(bullet["radius"]) + 2.0)
		var color := Color8(255, 225, 186) if String(bullet.get("owner", "enemy")) == "enemy" else Color(player.get("color", Color.WHITE))
		draw_arc(pos, radius, 0.0, TAU, 12, Color(color, 0.72), 1.5)

func draw_hud() -> void:
	super.draw_hud()
	if player.is_empty():
		return
	var safe := safe_rect()
	var synergy_count := active_synergies.size()
	var armor := int(player.get("fungal_armor", 0))
	var orbitals := int(player.get("orbitals", 0))
	var mutations: Array = player.get("serpent_mutations", [])
	var width := minf(360.0, safe.size.x * 0.36)
	var rect := Rect2(Vector2(safe.end.x - width - 7.0, safe.end.y - 70.0), Vector2(width, 23.0))
	_draw_beveled_panel(rect, Color(0.015, 0.035, 0.036, 0.82), Color8(73, 109, 94), false)
	draw_text_centered("SYNERGY %d  •  ARMOR %d  •  ORBIT %d  •  MUTATION %d" % [synergy_count, armor, orbitals, mutations.size()], rect.get_center() + Vector2(0, 4), 7, Color8(178, 201, 178))
	if synergy_notice_timer > 0.0 and synergy_count > 0:
		var names: Array[String] = []
		for id in active_synergies.keys():
			names.append(String(Dictionary(active_synergies[id]).get("name", String(id).to_upper())))
		draw_text_centered("BUILD ONLINE // %s" % " + ".join(names), Vector2(safe.get_center().x, safe.position.y + 105.0), 8, Color8(239, 210, 126))

func draw_run() -> void:
	super.draw_run()
	if choice_open:
		_draw_room_choice_overlay()
	elif state == "run" and room_graph.has(current_room):
		var room: Dictionary = room_graph[current_room]
		if String(room.get("kind", "")) in SPECIAL_ROOM_KINDS and not bool(room.get("rc6_used", false)):
			var safe := safe_rect()
			draw_text_centered("E / USE // RESOLVE %s" % String(room.get("kind", "SYSTEM")).replace("_", " ").to_upper(), Vector2(safe.get_center().x, safe.end.y - 76.0), 8, Color8(237, 210, 151))

func _draw_room_choice_overlay() -> void:
	var size := get_viewport_rect().size
	var safe := safe_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.52))
	var width := minf(720.0, safe.size.x - 34.0)
	var panel := Rect2(Vector2(safe.get_center().x - width * 0.5, safe.get_center().y - 112.0), Vector2(width, 224.0))
	_draw_beveled_panel(panel, Color8(7, 17, 19, 248), Color8(188, 151, 90), true)
	draw_text_centered(choice_context.replace("_", " ").to_upper(), Vector2(panel.get_center().x, panel.position.y + 34.0), 18, Color8(239, 223, 184))
	for index in range(choice_options.size()):
		var rect := _choice_rect(index, panel)
		var selected := index == choice_index
		_draw_beveled_panel(rect, Color8(20, 35, 33) if selected else Color8(11, 22, 23), Color8(221, 174, 93) if selected else Color8(65, 91, 80), selected)
		draw_text_centered(choice_options[index], rect.get_center() + Vector2(0, 5), 10, Color8(239, 225, 193) if selected else Color8(165, 181, 168))
	draw_text_centered("←/→ SELECT  •  ENTER / E / TAP CONFIRM  •  ESC CANCEL", Vector2(panel.get_center().x, panel.end.y - 14.0), 8, Color8(119, 147, 133))

func _choice_rect(index: int, panel: Rect2) -> Rect2:
	var gap := 12.0
	var width := (panel.size.x - 36.0 - gap) * 0.5
	return Rect2(Vector2(panel.position.x + 18.0 + float(index) * (width + gap), panel.position.y + 76.0), Vector2(width, 92.0))

func handle_key(keycode: Key) -> void:
	if choice_open:
		if keycode in [KEY_LEFT, KEY_A]:
			choice_index = posmod(choice_index - 1, maxi(1, choice_options.size()))
		elif keycode in [KEY_RIGHT, KEY_D]:
			choice_index = posmod(choice_index + 1, maxi(1, choice_options.size()))
		elif keycode in [KEY_E, KEY_ENTER, KEY_SPACE]:
			_confirm_room_choice()
		elif keycode == KEY_ESCAPE:
			choice_open = false
		return
	super.handle_key(keycode)

func _input(event: InputEvent) -> void:
	if choice_open and event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_LEFT_SHOULDER:
				choice_index = posmod(choice_index - 1, maxi(1, choice_options.size()))
			JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_RIGHT_SHOULDER:
				choice_index = posmod(choice_index + 1, maxi(1, choice_options.size()))
			JOY_BUTTON_A, JOY_BUTTON_X:
				_confirm_room_choice()
			JOY_BUTTON_B:
				choice_open = false
		get_viewport().set_input_as_handled()
		return
	super._input(event)

func handle_pointer(position: Vector2, button: MouseButton) -> void:
	if choice_open and button == MOUSE_BUTTON_LEFT:
		var safe := safe_rect()
		var width := minf(720.0, safe.size.x - 34.0)
		var panel := Rect2(Vector2(safe.get_center().x - width * 0.5, safe.get_center().y - 112.0), Vector2(width, 224.0))
		for index in range(choice_options.size()):
			if _choice_rect(index, panel).has_point(position):
				choice_index = index
				_confirm_room_choice()
				return
		return
	super.handle_pointer(position, button)

func handle_touch(event: InputEventScreenTouch) -> void:
	if choice_open and event.pressed:
		handle_pointer(event.position, MOUSE_BUTTON_LEFT)
		return
	super.handle_touch(event)

func save_suspended_run() -> void:
	super.save_suspended_run()
	if _initializing_rc6 or _restoring_rc6 or state != "run" or player.is_empty():
		return
	var data := {
		"version": GODMODE_VERSION,
		"seed": run_seed,
		"rng_state": rng.state,
		"current_room": [current_room.x, current_room.y],
		"rooms": _serialize_room_state(),
		"enemy_uid_counter": _enemy_uid_counter,
		"halo_charge": halo_charge,
		"player_extra": {
			"fungal_armor": int(player.get("fungal_armor", 0)),
			"orbitals": int(player.get("orbitals", 0)),
			"lifesteal_chance": float(player.get("lifesteal_chance", 0.0)),
			"spore_power": float(player.get("spore_power", 0.0)),
			"serpent_mutations": player.get("serpent_mutations", []),
		},
	}
	atomic_json_write(RC6_SUSPEND_PATH, data)

func restore_suspended_run() -> void:
	super.restore_suspended_run()
	if state != "run":
		return
	var data := read_json_with_backup(RC6_SUSPEND_PATH)
	if data.is_empty() or int(data.get("seed", -1)) != run_seed:
		_refresh_build_synergies(false)
		return
	_restoring_rc6 = true
	_restore_room_state(Array(data.get("rooms", [])))
	_enemy_uid_counter = maxi(1, int(data.get("enemy_uid_counter", 1)))
	halo_charge = int(data.get("halo_charge", 0))
	var extra: Dictionary = data.get("player_extra", {})
	for key in ["fungal_armor", "orbitals", "lifesteal_chance", "spore_power", "serpent_mutations"]:
		if extra.has(key):
			player[key] = extra[key]
	var saved_room: Array = data.get("current_room", [0, 0])
	var coord := Vector2i(int(saved_room[0]), int(saved_room[1])) if saved_room.size() >= 2 else Vector2i.ZERO
	if room_graph.has(coord):
		var current: Dictionary = room_graph[coord]
		if not bool(current.get("cleared", false)):
			current["spawned"] = false
			room_graph[coord] = current
		rng.state = int(data.get("rng_state", rng.state))
		enter_room(coord, Vector2i.ZERO)
	_restoring_rc6 = false
	_refresh_build_synergies(false)
	save_suspended_run()
	notify("RC6 EXCURSION RESTORED // ROOM STATE VERIFIED")

func _serialize_room_state() -> Array:
	var result: Array = []
	for coord in room_order:
		if not room_graph.has(coord):
			continue
		var room: Dictionary = room_graph[coord]
		result.append({
			"x":coord.x, "y":coord.y,
			"kind":String(room.get("kind", "combat")),
			"visited":bool(room.get("visited", false)),
			"spawned":bool(room.get("spawned", false)),
			"cleared":bool(room.get("cleared", false)),
			"modifier":String(room.get("modifier", "none")),
			"reward_multiplier":float(room.get("reward_multiplier", 1.0)),
			"v4_rewarded":bool(room.get("v4_rewarded", false)),
			"rc6_used":bool(room.get("rc6_used", false)),
			"rc6_rewarded":bool(room.get("rc6_rewarded", false)),
			"faction":String(room.get("faction", "")),
			"memory_id":String(room.get("memory_id", "")),
			"rc6_shop_faction":String(room.get("rc6_shop_faction", "")),
			"rc6_priced":bool(room.get("rc6_priced", false)),
			"shop":room.get("shop", []),
		})
	return result

func _restore_room_state(saved_rooms: Array) -> void:
	for room_variant in saved_rooms:
		if not room_variant is Dictionary:
			continue
		var saved: Dictionary = room_variant
		var coord := Vector2i(int(saved.get("x", 0)), int(saved.get("y", 0)))
		if not room_graph.has(coord):
			continue
		var room: Dictionary = room_graph[coord]
		for key in ["kind", "visited", "spawned", "cleared", "modifier", "reward_multiplier", "v4_rewarded", "rc6_used", "rc6_rewarded", "faction", "memory_id", "rc6_shop_faction", "rc6_priced", "shop"]:
			if saved.has(key):
				room[key] = saved[key]
		if not bool(room.get("cleared", false)) and String(room.get("kind", "")) in COMBAT_ROOM_KINDS:
			room["spawned"] = false
		room_graph[coord] = room

func finish_run(victory: bool) -> void:
	var was_running := state == "run"
	super.finish_run(victory)
	if was_running:
		if FileAccess.file_exists(RC6_SUSPEND_PATH):
			DirAccess.remove_absolute(RC6_SUSPEND_PATH)
		if FileAccess.file_exists(RC6_SUSPEND_PATH + ".bak"):
			DirAccess.remove_absolute(RC6_SUSPEND_PATH + ".bak")

func audit_godmode_contract() -> Dictionary:
	var director_contract: Dictionary = godmode_director.call("audit_contract")
	var boss_contract: Dictionary = boss_patterns.call("audit_contract")
	return {
		"version": GODMODE_VERSION,
		"director": director_contract,
		"boss_patterns": boss_contract,
		"special_rooms": SPECIAL_ROOM_KINDS.size(),
		"combat_room_kinds": COMBAT_ROOM_KINDS.size(),
		"synergy_rules": godmode_director.SYNERGY_RULES.size(),
		"factions": godmode_director.FACTIONS.size(),
	}
