extends Node2D

const VERSION := "0.3.0"
const SAVE_PATH := "user://edenfall_profile_v3.json"
const SUSPEND_PATH := "user://edenfall_suspend_v3.json"
const SETTINGS_PATH := "user://edenfall_settings_v3.json"
const ASSET_ROOT := "res://assets/generated_v3/"
const LEGACY_ROOT := "res://assets/generated/"
const PLAYER_RADIUS := 16.0
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const DIR_NAMES := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
const ACTION_ROWS := {"idle": 0, "walk": 1, "attack": 2, "dash": 3, "hurt": 4, "death": 5}
const PLAYER_FRAME := Vector2(48.0, 48.0)
const BOSS_FRAME := Vector2(96.0, 96.0)

const LINEAGES := [
	{"id":"adam","name":"ADAM","epithet":"Edenic Survivor","color":Color8(197,174,103),"max_hp":8.0,"speed":250.0,"damage":12.0,"fire_delay":0.30,"shot_speed":690.0,"dash_delay":1.20,"luck":0.06,"trait":"Genesis Tissue: heal after each boss phase."},
	{"id":"abel","name":"ABEL","epithet":"Shepherd of Light","color":Color8(229,207,146),"max_hp":6.0,"speed":278.0,"damage":10.5,"fire_delay":0.23,"shot_speed":760.0,"dash_delay":1.00,"luck":0.16,"trait":"Blood Tithe: wounded critical chance increases."},
	{"id":"cain","name":"CAIN","epithet":"Marked Warrior","color":Color8(218,78,63),"max_hp":5.0,"speed":266.0,"damage":16.0,"fire_delay":0.36,"shot_speed":710.0,"dash_delay":0.88,"luck":0.08,"trait":"Mark of Violence: dashes damage nearby enemies."},
	{"id":"seth","name":"SETH","epithet":"Guardian Engineer","color":Color8(102,161,229),"max_hp":7.0,"speed":244.0,"damage":10.0,"fire_delay":0.27,"shot_speed":650.0,"dash_delay":1.18,"luck":0.10,"trait":"Second Skin: one shield per cleared chamber."},
	{"id":"naamah","name":"NAAMAH","epithet":"Voice of Mycelia","color":Color8(190,112,212),"max_hp":6.0,"speed":258.0,"damage":9.0,"fire_delay":0.20,"shot_speed":610.0,"dash_delay":1.10,"luck":0.14,"trait":"Mycelial Recall: kills may restore a health cell."},
]

const BIOMES := [
	{"id":"industrial_eden","name":"INDUSTRIAL EDEN","subtitle":"The sealed biolab gardens","floor":Color8(20,35,30),"accent":Color8(113,159,107)},
	{"id":"ash_wastes","name":"ASH WASTES","subtitle":"Preadamic caravan country","floor":Color8(45,29,23),"accent":Color8(192,113,61)},
	{"id":"temple_lab","name":"TEMPLE-LAB","subtitle":"Liturgies compiled in glass","floor":Color8(17,38,49),"accent":Color8(84,160,164)},
	{"id":"fungal_garden","name":"FUNGAL GARDEN","subtitle":"Naamah's abandoned chorus","floor":Color8(48,28,56),"accent":Color8(177,94,165)},
	{"id":"nephilim_ruins","name":"NEPHILIM RUINS","subtitle":"The architecture remembers","floor":Color8(29,28,43),"accent":Color8(152,122,179)},
]

const ENEMIES := {
	"feral_scavenger":{"name":"Feral Scavenger","category":"preadamic","hp":24.0,"speed":132.0,"radius":17.0,"damage":1.0,"style":"melee"},
	"outlaw_gunner":{"name":"Outlaw Gunner","category":"preadamic","hp":30.0,"speed":88.0,"radius":18.0,"damage":1.0,"style":"ranged"},
	"raider_brute":{"name":"Raider Brute","category":"preadamic","hp":54.0,"speed":70.0,"radius":23.0,"damage":1.5,"style":"charger"},
	"wasteland_hunter":{"name":"Wasteland Hunter","category":"preadamic","hp":34.0,"speed":104.0,"radius":18.0,"damage":1.0,"style":"ranged"},
	"scrap_cultist":{"name":"Scrap Cultist","category":"preadamic","hp":40.0,"speed":78.0,"radius":19.0,"damage":1.0,"style":"caster"},
	"caravan_outlaw":{"name":"Caravan Outlaw","category":"preadamic","hp":46.0,"speed":116.0,"radius":19.0,"damage":1.0,"style":"skirmisher"},
	"cherub_drone":{"name":"Cherub Drone","category":"fallen","hp":34.0,"speed":128.0,"radius":17.0,"damage":1.0,"style":"orbiter"},
	"fallen_angel":{"name":"Fallen Angel","category":"fallen","hp":58.0,"speed":102.0,"radius":22.0,"damage":1.0,"style":"skirmisher"},
	"watcher_acolyte":{"name":"Watcher Acolyte","category":"fallen","hp":48.0,"speed":76.0,"radius":20.0,"damage":1.0,"style":"caster"},
	"halo_sentinel":{"name":"Halo Sentinel","category":"fallen","hp":72.0,"speed":62.0,"radius":24.0,"damage":1.5,"style":"charger"},
	"biomech_pilgrim":{"name":"Biomech Pilgrim","category":"fallen","hp":66.0,"speed":82.0,"radius":22.0,"damage":1.0,"style":"ranged"},
	"ophanim_scout":{"name":"Ophanim Scout","category":"fallen","hp":44.0,"speed":142.0,"radius":18.0,"damage":1.0,"style":"orbiter"},
	"nephilim_husk":{"name":"Nephilim Husk","category":"nephilim","hp":84.0,"speed":74.0,"radius":27.0,"damage":1.5,"style":"melee"},
	"nephilim_giant":{"name":"Nephilim Giant","category":"nephilim","hp":138.0,"speed":52.0,"radius":35.0,"damage":2.0,"style":"charger"},
	"horned_berserker":{"name":"Horned Nephilim","category":"nephilim","hp":108.0,"speed":112.0,"radius":29.0,"damage":2.0,"style":"skirmisher"},
	"bone_shepherd":{"name":"Bone Shepherd","category":"nephilim","hp":92.0,"speed":68.0,"radius":25.0,"damage":1.5,"style":"caster"},
	"grafted_colossus":{"name":"Grafted Colossus","category":"nephilim","hp":172.0,"speed":44.0,"radius":39.0,"damage":2.0,"style":"radial"},
	"serpent_spawn":{"name":"Serpent-Blood Spawn","category":"nephilim","hp":76.0,"speed":126.0,"radius":23.0,"damage":1.5,"style":"orbiter"},
}

const BOSS_IDS := ["watcher_engine", "first_nephilim", "gate_cherub", "tower_enoch", "serpent_interface"]
const BOSS_NAMES := ["WATCHER ENGINE", "FIRST NEPHILIM", "GATE CHERUB", "TOWER OF ENOCH", "SERPENT INTERFACE"]

var state := "title"
var previous_state := "title"
var paused := false
var settings_open := false
var archive_open := false
var menu_index := 0
var settings_index := 0
var selected_lineage := 0
var profile := {"genome":0,"best_depth":0,"runs":0,"victories":0,"unlocked_biome":1}
var settings := {
	"ui_scale":1.0,"text_scale":1.0,"high_contrast":false,"reduced_motion":false,
	"screen_shake":true,"aim_assist":true,"auto_fire":false,"haptics":true,
	"left_handed":false,"show_damage_numbers":true,"safe_area_debug":false,
}

var rng := RandomNumberGenerator.new()
var run_seed := 0
var biome_index := 0
var floor_number := 1
var room_graph: Dictionary = {}
var room_order: Array[Vector2i] = []
var current_room := Vector2i.ZERO
var player: Dictionary = {}
var enemies: Array = []
var bullets: Array = []
var pickups: Array = []
var effects: Array = []
var damage_numbers: Array = []
var scraps := 0
var rooms_cleared := 0
var notification := ""
var notification_timer := 0.0
var objective := ""
var fire_timer := 0.0
var dash_timer := 0.0
var dash_time := 0.0
var invulnerability := 0.0
var hurt_timer := 0.0
var shoot_timer := 0.0
var visual_clock := 0.0
var camera_shake := Vector2.ZERO
var boss_health := 0.0
var boss_max_health := 0.0
var last_move := Vector2.DOWN
var last_aim := Vector2.DOWN
var input_move := Vector2.ZERO
var input_aim := Vector2.ZERO
var left_touch_id := -1
var right_touch_id := -1
var left_touch_origin := Vector2.ZERO
var right_touch_origin := Vector2.ZERO
var left_touch_pos := Vector2.ZERO
var right_touch_pos := Vector2.ZERO
var textures: Dictionary = {}
var audio_players: Dictionary = {}
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_cursor := 0
var current_music_biome := -1
var can_continue := false
var readiness := 0.0

func _ready() -> void:
	load_profile()
	load_settings()
	can_continue = FileAccess.file_exists(SUSPEND_PATH)
	setup_audio()
	set_process(true)
	queue_redraw()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST]:
		if state == "run":
			save_suspended_run()
		if what == NOTIFICATION_WM_CLOSE_REQUEST:
			get_tree().quit()

func _process(delta: float) -> void:
	visual_clock += delta
	notification_timer = maxf(0.0, notification_timer - delta)
	if state == "run" and not paused and not settings_open:
		update_run(delta)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		handle_key(event.keycode)
	elif event is InputEventMouseButton and event.pressed:
		handle_pointer(event.position, event.button_index)
	elif event is InputEventScreenTouch:
		handle_touch(event)
	elif event is InputEventScreenDrag:
		handle_drag(event)

func handle_key(keycode: Key) -> void:
	if settings_open:
		handle_settings_key(keycode)
		return
	if archive_open:
		if keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
			archive_open = false
		return
	match state:
		"title":
			if keycode in [KEY_UP, KEY_W]: menu_index = posmod(menu_index - 1, title_options().size())
			elif keycode in [KEY_DOWN, KEY_S]: menu_index = posmod(menu_index + 1, title_options().size())
			elif keycode in [KEY_ENTER, KEY_SPACE]: activate_title_option(menu_index)
		"select":
			if keycode in [KEY_LEFT, KEY_A]: selected_lineage = posmod(selected_lineage - 1, LINEAGES.size())
			elif keycode in [KEY_RIGHT, KEY_D]: selected_lineage = posmod(selected_lineage + 1, LINEAGES.size())
			elif keycode >= KEY_1 and keycode <= KEY_5:
				selected_lineage = int(keycode - KEY_1)
				start_new_run(selected_lineage)
			elif keycode in [KEY_ENTER, KEY_SPACE]: start_new_run(selected_lineage)
			elif keycode == KEY_ESCAPE: state = "title"
		"run":
			if keycode in [KEY_ESCAPE, KEY_P]: paused = not paused
			elif keycode == KEY_SPACE: begin_dash()
			elif keycode == KEY_E: interact()
			elif keycode == KEY_TAB: archive_open = true
		"game_over", "victory":
			if keycode in [KEY_ENTER, KEY_SPACE]: state = "select"
			elif keycode == KEY_ESCAPE: state = "title"

func handle_settings_key(keycode: Key) -> void:
	var rows := settings_rows()
	if keycode in [KEY_ESCAPE, KEY_ENTER]:
		settings_open = false
		save_settings()
		return
	if keycode in [KEY_UP, KEY_W]: settings_index = posmod(settings_index - 1, rows.size())
	elif keycode in [KEY_DOWN, KEY_S]: settings_index = posmod(settings_index + 1, rows.size())
	elif keycode in [KEY_LEFT, KEY_A]: adjust_setting(rows[settings_index]["key"], -1)
	elif keycode in [KEY_RIGHT, KEY_D, KEY_SPACE]: adjust_setting(rows[settings_index]["key"], 1)

func handle_pointer(position: Vector2, button: MouseButton) -> void:
	if button != MOUSE_BUTTON_LEFT and button != MOUSE_BUTTON_RIGHT:
		return
	if settings_open:
		var rows := settings_rows()
		for i in range(rows.size()):
			if settings_row_rect(i).has_point(position):
				settings_index = i
				adjust_setting(rows[i]["key"], 1)
				return
		if close_button_rect().has_point(position):
			settings_open = false
			save_settings()
		return
	if archive_open:
		archive_open = false
		return
	match state:
		"title":
			for i in range(title_options().size()):
				if title_option_rect(i).has_point(position): activate_title_option(i)
		"select":
			for i in range(LINEAGES.size()):
				if lineage_card_rect(i).has_point(position):
					selected_lineage = i
					start_new_run(i)
		"run":
			if pause_button_rect().has_point(position): paused = not paused
			elif paused:
				if pause_resume_rect().has_point(position): paused = false
				elif pause_settings_rect().has_point(position): settings_open = true
				elif pause_exit_rect().has_point(position):
					save_suspended_run()
					state = "title"
					paused = false
			elif dash_button_rect().has_point(position): begin_dash()
			elif interact_button_rect().has_point(position): interact()
		"game_over", "victory": state = "select"

func handle_touch(event: InputEventScreenTouch) -> void:
	if state != "run" or paused or settings_open:
		if event.pressed: handle_pointer(event.position, MOUSE_BUTTON_LEFT)
		return
	if event.pressed:
		if pause_button_rect().has_point(event.position):
			paused = true
			return
		if dash_button_rect().has_point(event.position):
			begin_dash()
			return
		if interact_button_rect().has_point(event.position):
			interact()
			return
		var split := safe_rect().get_center().x
		var left_first := not bool(settings["left_handed"])
		var movement_side := event.position.x < split if left_first else event.position.x >= split
		if movement_side and left_touch_id == -1:
			left_touch_id = event.index
			left_touch_origin = event.position
			left_touch_pos = event.position
		elif right_touch_id == -1:
			right_touch_id = event.index
			right_touch_origin = event.position
			right_touch_pos = event.position
	else:
		if event.index == left_touch_id: left_touch_id = -1
		if event.index == right_touch_id: right_touch_id = -1

func handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == left_touch_id: left_touch_pos = event.position
	if event.index == right_touch_id: right_touch_pos = event.position

func title_options() -> Array[String]:
	var result: Array[String] = []
	if can_continue: result.append("CONTINUE EXCURSION")
	result.append("NEW EXCURSION")
	result.append("GENOME ARCHIVE")
	result.append("ACCESSIBILITY & SETTINGS")
	return result

func activate_title_option(index: int) -> void:
	var option := title_options()[clampi(index, 0, title_options().size() - 1)]
	match option:
		"CONTINUE EXCURSION": restore_suspended_run()
		"NEW EXCURSION": state = "select"
		"GENOME ARCHIVE": archive_open = true
		"ACCESSIBILITY & SETTINGS": settings_open = true

func settings_rows() -> Array:
	return [
		{"key":"ui_scale","label":"HUD SCALE"}, {"key":"text_scale","label":"TEXT SCALE"},
		{"key":"high_contrast","label":"HIGH CONTRAST"}, {"key":"reduced_motion","label":"REDUCED MOTION"},
		{"key":"screen_shake","label":"SCREEN SHAKE"}, {"key":"aim_assist","label":"AIM ASSIST"},
		{"key":"auto_fire","label":"AUTO FIRE"}, {"key":"haptics","label":"HAPTICS"},
		{"key":"left_handed","label":"LEFT-HANDED TOUCH"}, {"key":"show_damage_numbers","label":"DAMAGE NUMBERS"},
		{"key":"safe_area_debug","label":"SAFE-AREA OVERLAY"},
	]

func adjust_setting(key: String, direction: int) -> void:
	if key in ["ui_scale", "text_scale"]:
		var values := [0.85, 1.0, 1.15, 1.30]
		var nearest := 0
		for i in range(values.size()):
			if absf(float(settings[key]) - values[i]) < absf(float(settings[key]) - values[nearest]): nearest = i
		settings[key] = values[posmod(nearest + direction, values.size())]
	else:
		settings[key] = not bool(settings[key])
	play_sfx("ui")

func start_new_run(lineage_index: int, seed_override: int = 0) -> void:
	selected_lineage = clampi(lineage_index, 0, LINEAGES.size() - 1)
	var lineage: Dictionary = LINEAGES[selected_lineage]
	player = {
		"id":lineage["id"],"name":lineage["name"],"color":lineage["color"],"pos":Vector2.ZERO,
		"hp":lineage["max_hp"],"max_hp":lineage["max_hp"],"speed":lineage["speed"],"damage":lineage["damage"],
		"fire_delay":lineage["fire_delay"],"shot_speed":lineage["shot_speed"],"dash_delay":lineage["dash_delay"],
		"luck":lineage["luck"],"aim":Vector2.DOWN,"look":Vector2.DOWN,"shield":lineage["id"] == "seth",
		"pierce":0,"parallel":false,"inventory":[],"ability":0.0,
	}
	run_seed = seed_override if seed_override != 0 else (int(Time.get_unix_time_from_system() * 1000.0) ^ randi())
	rng.seed = run_seed
	biome_index = 0
	floor_number = 1
	scraps = 0
	rooms_cleared = 0
	fire_timer = 0.0
	dash_timer = 0.0
	dash_time = 0.0
	invulnerability = 0.0
	enemies.clear(); bullets.clear(); pickups.clear(); effects.clear(); damage_numbers.clear()
	generate_floor()
	enter_room(Vector2i.ZERO, Vector2i.ZERO)
	state = "run"
	paused = false
	can_continue = true
	play_biome_audio(true)
	notify("BIO-LAB SEAL OPENED // SEED %08X" % (run_seed & 0xFFFFFFFF))
	save_suspended_run()

func generate_floor() -> void:
	room_graph.clear(); room_order.clear()
	add_room(Vector2i.ZERO)
	var target := 9 + biome_index
	var attempts := 0
	while room_order.size() < target and attempts < 500:
		attempts += 1
		var base: Vector2i = room_order[rng.randi_range(maxi(0, room_order.size() - 6), room_order.size() - 1)]
		var candidate: Vector2i = base + Vector2i(DIRECTIONS[rng.randi_range(0, DIRECTIONS.size() - 1)])
		if room_graph.has(candidate): continue
		if abs(candidate.x) > 5 or abs(candidate.y) > 4: continue
		add_room(candidate)
	compute_neighbors_and_depths()
	var farthest := Vector2i.ZERO
	var farthest_depth := -1
	var candidates: Array[Vector2i] = []
	for coord in room_order:
		if coord == Vector2i.ZERO: continue
		var depth: int = int(room_graph[coord]["depth"])
		if depth > farthest_depth:
			farthest_depth = depth
			farthest = coord
		candidates.append(coord)
	set_room_kind(farthest, "boss")
	candidates.erase(farthest)
	if not candidates.is_empty():
		var shop: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
		set_room_kind(shop, "shop"); candidates.erase(shop)
	if not candidates.is_empty():
		var treasure: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
		set_room_kind(treasure, "treasure")
	set_room_kind(Vector2i.ZERO, "start")

func add_room(coord: Vector2i) -> void:
	room_graph[coord] = {"kind":"combat","visited":false,"spawned":false,"cleared":false,"depth":0,"neighbors":[],"shop":[]}
	room_order.append(coord)

func set_room_kind(coord: Vector2i, kind: String) -> void:
	var room: Dictionary = room_graph[coord]
	room["kind"] = kind
	room_graph[coord] = room

func compute_neighbors_and_depths() -> void:
	for coord in room_order:
		var room: Dictionary = room_graph[coord]
		var neighbors: Array[Vector2i] = []
		for direction in DIRECTIONS:
			if room_graph.has(coord + direction): neighbors.append(direction)
		room["neighbors"] = neighbors
		room_graph[coord] = room
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	var distance := {Vector2i.ZERO:0}
	while not queue.is_empty():
		var coord: Vector2i = queue.pop_front()
		for direction in room_graph[coord]["neighbors"]:
			var next: Vector2i = coord + direction
			if distance.has(next): continue
			distance[next] = int(distance[coord]) + 1
			queue.append(next)
	for coord in room_order:
		var room: Dictionary = room_graph[coord]
		room["depth"] = int(distance.get(coord, 0))
		room_graph[coord] = room

func enter_room(coord: Vector2i, movement_direction: Vector2i) -> void:
	current_room = coord
	enemies.clear(); bullets.clear(); pickups.clear(); effects.clear()
	var room: Dictionary = room_graph[coord]
	room["visited"] = true
	if not bool(room["spawned"]):
		room["spawned"] = true
		spawn_room(room)
	if room["kind"] in ["start", "shop", "treasure"]: room["cleared"] = true
	room_graph[coord] = room
	var arena := arena_rect()
	var spawn := arena.get_center()
	if movement_direction == Vector2i.UP: spawn.y = arena.end.y - PLAYER_RADIUS - 16.0
	elif movement_direction == Vector2i.DOWN: spawn.y = arena.position.y + PLAYER_RADIUS + 16.0
	elif movement_direction == Vector2i.LEFT: spawn.x = arena.end.x - PLAYER_RADIUS - 16.0
	elif movement_direction == Vector2i.RIGHT: spawn.x = arena.position.x + PLAYER_RADIUS + 16.0
	player["pos"] = spawn
	if String(player["id"]) == "seth": player["shield"] = true
	objective = objective_for_room(room)
	notify(room_title(room))
	play_sfx("portal")
	save_suspended_run()

func spawn_room(room: Dictionary) -> void:
	match String(room["kind"]):
		"start": pass
		"shop": room["shop"] = build_shop()
		"treasure": spawn_relic(arena_rect().get_center(), random_relic_id())
		"boss": spawn_boss()
		_:
			var depth := int(room["depth"])
			var count := 3 + mini(5, depth) + biome_index + rng.randi_range(0, 2)
			var pool := enemy_pool_for_biome()
			for i in range(count):
				spawn_enemy(pool[rng.randi_range(0, pool.size() - 1)], random_arena_position(105.0), i)

func enemy_pool_for_biome() -> Array[String]:
	match biome_index:
		0: return ["feral_scavenger","outlaw_gunner","raider_brute","scrap_cultist"]
		1: return ["wasteland_hunter","caravan_outlaw","raider_brute","outlaw_gunner","cherub_drone"]
		2: return ["cherub_drone","fallen_angel","watcher_acolyte","halo_sentinel","biomech_pilgrim"]
		3: return ["fallen_angel","ophanim_scout","biomech_pilgrim","nephilim_husk","bone_shepherd"]
		_: return ["nephilim_husk","nephilim_giant","horned_berserker","bone_shepherd","grafted_colossus","serpent_spawn"]

func spawn_enemy(id: String, position: Vector2, variant: int = 0) -> void:
	var definition: Dictionary = ENEMIES[id]
	var hp_scale := 1.0 + float(biome_index) * 0.22 + float(floor_number - 1) * 0.08
	enemies.append({
		"id":id,"name":definition["name"],"category":definition["category"],"style":definition["style"],
		"pos":position,"velocity":Vector2.ZERO,"look":Vector2.DOWN,"hp":float(definition["hp"]) * hp_scale,
		"max_hp":float(definition["hp"]) * hp_scale,"speed":float(definition["speed"]),"radius":float(definition["radius"]),
		"damage":float(definition["damage"]),"cooldown":rng.randf_range(0.3,1.3),"phase":rng.randf_range(0.0,TAU),
		"flash":0.0,"hurt":0.0,"attack":0.0,"variant":variant,"boss":false,"stage":0,
	})

func spawn_boss() -> void:
	var hp := 520.0 + float(biome_index) * 210.0
	boss_health = hp; boss_max_health = hp
	enemies.append({
		"id":BOSS_IDS[biome_index],"name":BOSS_NAMES[biome_index],"category":"boss","style":"boss",
		"pos":arena_rect().get_center() + Vector2(0.0,-90.0),"velocity":Vector2.ZERO,"look":Vector2.DOWN,
		"hp":hp,"max_hp":hp,"speed":54.0 + biome_index * 5.0,"radius":48.0 + biome_index * 3.0,
		"damage":2.0,"cooldown":0.8,"phase":0.0,"flash":0.0,"hurt":0.0,"attack":0.0,
		"variant":biome_index,"boss":true,"stage":0,
	})
	play_sfx("boss_phase")
	notify("BOSS SIGNAL // %s" % BOSS_NAMES[biome_index])

func update_run(delta: float) -> void:
	fire_timer = maxf(0.0, fire_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	dash_time = maxf(0.0, dash_time - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	shoot_timer = maxf(0.0, shoot_timer - delta)
	camera_shake = camera_shake.lerp(Vector2.ZERO, minf(1.0, delta * 12.0))
	read_inputs()
	update_player(delta)
	update_enemies(delta)
	update_bullets(delta)
	update_pickups(delta)
	update_effects(delta)
	check_room_clear()
	check_room_transition()

func read_inputs() -> void:
	input_move = Vector2.ZERO
	if Input.is_key_pressed(KEY_A): input_move.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_move.x += 1.0
	if Input.is_key_pressed(KEY_W): input_move.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_move.y += 1.0
	var joy_move := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if joy_move.length() > 0.18: input_move = joy_move
	if left_touch_id != -1: input_move = (left_touch_pos - left_touch_origin) / 58.0
	if input_move.length() > 1.0: input_move = input_move.normalized()
	input_aim = Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_J): input_aim.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_L): input_aim.x += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_I): input_aim.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_K): input_aim.y += 1.0
	var joy_aim := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if joy_aim.length() > 0.22: input_aim = joy_aim
	if right_touch_id != -1: input_aim = (right_touch_pos - right_touch_origin) / 52.0
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): input_aim = get_viewport().get_mouse_position() - Vector2(player["pos"])
	if input_aim.length() > 1.0: input_aim = input_aim.normalized()

func update_player(delta: float) -> void:
	if input_move.length_squared() > 0.02:
		last_move = input_move.normalized()
		player["look"] = last_move
	if input_aim.length_squared() > 0.04:
		last_aim = input_aim.normalized()
		player["aim"] = last_aim
		player["look"] = last_aim
	var move_vector := input_move
	if dash_time > 0.0:
		move_vector = Vector2(player.get("dash_direction", last_move)) * 690.0 / float(player["speed"])
	player["pos"] = Vector2(player["pos"]) + move_vector * float(player["speed"]) * delta
	player["pos"] = clamp_to_arena(Vector2(player["pos"]), PLAYER_RADIUS)
	var shooting := input_aim.length_squared() > 0.04
	if bool(settings["auto_fire"]) and not enemies.is_empty():
		var target: Variant = nearest_enemy(Vector2(player["pos"]))
		if target != null:
			player["aim"] = (Vector2(target["pos"]) - Vector2(player["pos"])).normalized()
			last_aim = player["aim"]
			shooting = true
	if shooting and fire_timer <= 0.0: fire_player_weapon()

func fire_player_weapon() -> void:
	fire_timer = float(player["fire_delay"])
	shoot_timer = 0.13
	var aim := Vector2(player["aim"]).normalized()
	if bool(settings["aim_assist"]): aim = assisted_aim(aim)
	var critical_chance := float(player["luck"])
	if String(player["id"]) == "abel" and float(player["hp"]) <= float(player["max_hp"]) * 0.5: critical_chance += 0.22
	var critical := rng.randf() < critical_chance
	var damage := float(player["damage"]) * (1.8 if critical else 1.0)
	spawn_bullet(Vector2(player["pos"]) + aim * 24.0, aim * float(player["shot_speed"]), damage, "player", 5.0, player["color"], int(player["pierce"]), critical)
	if bool(player["parallel"]):
		for angle in [-0.08, 0.08]: spawn_bullet(Vector2(player["pos"]) + aim * 22.0, aim.rotated(angle) * float(player["shot_speed"]), damage * 0.62, "player", 4.0, Color.WHITE, int(player["pierce"]), false)
	spawn_effect("muzzle", Vector2(player["pos"]) + aim * 25.0, player["color"], aim.angle())
	play_sfx("critical" if critical else "shot_%02d" % (posmod(selected_lineage, 3) + 1))
	haptic(18, 0.22)

func assisted_aim(current: Vector2) -> Vector2:
	var best := current
	var best_angle := 0.20
	for enemy in enemies:
		var delta := Vector2(enemy["pos"]) - Vector2(player["pos"])
		if delta.length() > 520.0: continue
		var candidate := delta.normalized()
		var angle := absf(current.angle_to(candidate))
		if angle < best_angle:
			best_angle = angle
			best = candidate
	return current.slerp(best, 0.55).normalized()

func begin_dash() -> void:
	if state != "run" or paused or dash_timer > 0.0: return
	var direction := input_move
	if direction.length_squared() < 0.04: direction = Vector2(player.get("aim", last_move))
	player["dash_direction"] = direction.normalized()
	dash_time = 0.18
	dash_timer = float(player["dash_delay"])
	invulnerability = maxf(invulnerability, 0.30)
	spawn_effect("dash", Vector2(player["pos"]), player["color"], direction.angle())
	if String(player["id"]) == "cain":
		for i in range(enemies.size() - 1, -1, -1):
			if Vector2(enemies[i]["pos"]).distance_to(Vector2(player["pos"])) < 92.0: damage_enemy(i, float(player["damage"]) * 1.25)
	play_sfx("dash")
	haptic(35, 0.45)

func interact() -> void:
	if state != "run": return
	var room: Dictionary = room_graph[current_room]
	if String(room["kind"]) == "shop":
		var items: Array = room["shop"]
		for i in range(items.size()):
			if not bool(items[i]["bought"]):
				var cost := int(items[i]["cost"])
				if scraps >= cost:
					scraps -= cost
					items[i]["bought"] = true
					apply_relic(String(items[i]["id"]))
					room["shop"] = items; room_graph[current_room] = room
					play_sfx("shop")
					return
				else:
					notify("INSUFFICIENT SCRAP // %d REQUIRED" % cost)
					return

func update_enemies(delta: float) -> void:
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		enemy["cooldown"] = float(enemy["cooldown"]) - delta
		enemy["phase"] = float(enemy["phase"]) + delta
		enemy["flash"] = maxf(0.0, float(enemy["flash"]) - delta)
		enemy["hurt"] = maxf(0.0, float(enemy["hurt"]) - delta)
		enemy["attack"] = maxf(0.0, float(enemy["attack"]) - delta)
		var delta_to_player := Vector2(player["pos"]) - Vector2(enemy["pos"])
		var distance := maxf(1.0, delta_to_player.length())
		var direction := delta_to_player / distance
		enemy["look"] = direction
		var velocity := Vector2.ZERO
		if bool(enemy["boss"]):
			velocity = update_boss(enemy, direction, distance, delta)
		else:
			velocity = update_enemy_style(enemy, direction, distance, delta)
		enemy["velocity"] = velocity
		enemy["pos"] = clamp_to_arena(Vector2(enemy["pos"]) + velocity * delta, float(enemy["radius"]))
		if Vector2(enemy["pos"]).distance_to(Vector2(player["pos"])) < float(enemy["radius"]) + PLAYER_RADIUS:
			damage_player(float(enemy["damage"]), direction)
			player["pos"] = Vector2(player["pos"]) - direction * 26.0
		enemies[i] = enemy

func update_enemy_style(enemy: Dictionary, direction: Vector2, distance: float, _delta: float) -> Vector2:
	var speed := float(enemy["speed"])
	match String(enemy["style"]):
		"melee": return direction * speed
		"charger":
			if float(enemy["cooldown"]) <= 0.0:
				enemy["attack"] = 0.35; enemy["cooldown"] = rng.randf_range(1.5, 2.2)
				return direction * speed * 3.2
			return direction * speed * 0.55
		"ranged":
			if float(enemy["cooldown"]) <= 0.0:
				enemy_shoot(Vector2(enemy["pos"]), direction, 330.0, float(enemy["damage"])); enemy["cooldown"] = rng.randf_range(1.0,1.6); enemy["attack"] = 0.24
			if distance > 300.0: return direction * speed
			if distance < 190.0: return -direction * speed
			return direction.orthogonal() * sin(float(enemy["phase"]) * 2.0) * speed * 0.45
		"caster":
			if float(enemy["cooldown"]) <= 0.0:
				for angle in [-0.28,0.0,0.28]: enemy_shoot(Vector2(enemy["pos"]), direction.rotated(angle), 285.0, float(enemy["damage"]))
				enemy["cooldown"] = 1.8; enemy["attack"] = 0.35
			return direction.orthogonal() * sin(float(enemy["phase"]) * 1.4) * speed * 0.65
		"orbiter":
			if float(enemy["cooldown"]) <= 0.0:
				enemy_shoot(Vector2(enemy["pos"]), direction, 360.0, float(enemy["damage"])); enemy["cooldown"] = 1.1; enemy["attack"] = 0.20
			return (direction * 0.28 + direction.orthogonal() * 0.95).normalized() * speed
		"skirmisher":
			if float(enemy["cooldown"]) <= 0.0:
				for angle in [-0.12,0.12]: enemy_shoot(Vector2(enemy["pos"]), direction.rotated(angle), 390.0, float(enemy["damage"]))
				enemy["cooldown"] = 1.25; enemy["attack"] = 0.22
			return (direction * (1.0 if distance > 230.0 else -0.5) + direction.orthogonal() * sin(float(enemy["phase"]) * 2.4)).normalized() * speed
		"radial":
			if float(enemy["cooldown"]) <= 0.0:
				for n in range(10): enemy_shoot(Vector2(enemy["pos"]), Vector2.RIGHT.rotated(TAU * float(n) / 10.0), 245.0, float(enemy["damage"]))
				enemy["cooldown"] = 2.1; enemy["attack"] = 0.42
			return direction * speed * 0.65
	return direction * speed

func update_boss(enemy: Dictionary, direction: Vector2, _distance: float, _delta: float) -> Vector2:
	var ratio := float(enemy["hp"]) / float(enemy["max_hp"])
	var stage := 0
	if ratio < 0.68: stage = 1
	if ratio < 0.34: stage = 2
	if stage > int(enemy["stage"]):
		enemy["stage"] = stage
		spawn_effect("boss_phase", Vector2(enemy["pos"]), BIOMES[biome_index]["accent"], 0.0)
		play_sfx("boss_phase")
		haptic(90, 0.8)
		if String(player["id"]) == "adam": player["hp"] = minf(float(player["max_hp"]), float(player["hp"]) + 1.0)
	if float(enemy["cooldown"]) <= 0.0:
		enemy["attack"] = 0.42
		var count := 10 + stage * 4 + biome_index * 2
		for n in range(count):
			var angle := TAU * float(n) / float(count) + float(enemy["phase"]) * 0.17
			enemy_shoot(Vector2(enemy["pos"]), Vector2.RIGHT.rotated(angle), 240.0 + stage * 48.0, 1.0)
		for angle in [-0.18,0.0,0.18]: enemy_shoot(Vector2(enemy["pos"]), direction.rotated(angle), 420.0, 1.0)
		enemy["cooldown"] = 1.35 - stage * 0.16
	return direction * float(enemy["speed"]) * (0.55 + stage * 0.15)

func enemy_shoot(position: Vector2, direction: Vector2, speed: float, damage: float) -> void:
	spawn_bullet(position + direction * 22.0, direction.normalized() * speed, damage, "enemy", 6.0, Color8(227,86,77), 0, false)
	play_sfx("enemy_shot", -8.0, 80)

func spawn_bullet(position: Vector2, velocity: Vector2, damage: float, owner: String, radius: float, color: Color, pierce: int, critical: bool) -> void:
	bullets.append({"pos":position,"vel":velocity,"damage":damage,"owner":owner,"radius":radius,"color":color,"life":4.0,"pierce":pierce,"critical":critical})

func update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		bullet["pos"] = Vector2(bullet["pos"]) + Vector2(bullet["vel"]) * delta
		bullet["life"] = float(bullet["life"]) - delta
		if float(bullet["life"]) <= 0.0 or not arena_rect().grow(42.0).has_point(Vector2(bullet["pos"])):
			bullets.remove_at(i); continue
		if String(bullet["owner"]) == "player":
			var consumed := false
			for enemy_index in range(enemies.size() - 1, -1, -1):
				if Vector2(bullet["pos"]).distance_to(Vector2(enemies[enemy_index]["pos"])) < float(bullet["radius"]) + float(enemies[enemy_index]["radius"]):
					damage_enemy(enemy_index, float(bullet["damage"])); bullet["pierce"] = int(bullet["pierce"]) - 1
					spawn_effect("impact", Vector2(bullet["pos"]), bullet["color"], Vector2(bullet["vel"]).angle())
					if int(bullet["pierce"]) < 0: consumed = true; break
			if consumed:
				bullets.remove_at(i); continue
		elif Vector2(bullet["pos"]).distance_to(Vector2(player["pos"])) < float(bullet["radius"]) + PLAYER_RADIUS:
			damage_player(float(bullet["damage"]), Vector2(bullet["vel"]).normalized())
			bullets.remove_at(i); continue
		if i < bullets.size(): bullets[i] = bullet

func damage_enemy(index: int, amount: float) -> void:
	if index < 0 or index >= enemies.size(): return
	var enemy: Dictionary = enemies[index]
	enemy["hp"] = float(enemy["hp"]) - amount
	enemy["flash"] = 0.08; enemy["hurt"] = 0.18
	if bool(settings["show_damage_numbers"]): damage_numbers.append({"text":"%.0f" % amount,"pos":Vector2(enemy["pos"]),"life":0.75,"color":Color8(255,219,126)})
	if bool(enemy["boss"]): boss_health = maxf(0.0, float(enemy["hp"]))
	play_sfx("impact_01", -8.0, 28)
	if float(enemy["hp"]) <= 0.0: kill_enemy(index)
	else: enemies[index] = enemy

func kill_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size(): return
	var enemy: Dictionary = enemies[index]
	var was_boss := bool(enemy["boss"])
	var death_pos := Vector2(enemy["pos"])
	enemies.remove_at(index)
	spawn_effect("death", death_pos, BIOMES[biome_index]["accent"], 0.0)
	scraps += rng.randi_range(1,4) + (8 if String(enemy["category"]) == "nephilim" else 0)
	if rng.randf() < 0.10: pickups.append({"kind":"heart","pos":death_pos,"phase":0.0})
	if String(player["id"]) == "naamah" and rng.randf() < 0.09: player["hp"] = minf(float(player["max_hp"]), float(player["hp"]) + 1.0)
	play_sfx("kill")
	if was_boss: complete_biome()

func damage_player(amount: float, direction: Vector2) -> void:
	if invulnerability > 0.0 or state != "run": return
	if bool(player["shield"]):
		player["shield"] = false; invulnerability = 0.65
		spawn_effect("shield", Vector2(player["pos"]), Color8(102,181,244), 0.0)
		play_sfx("shield"); haptic(45,0.55); notify("SECOND SKIN ABSORBED IMPACT")
		return
	player["hp"] = float(player["hp"]) - amount
	invulnerability = 0.82; hurt_timer = 0.24
	if bool(settings["screen_shake"]): camera_shake = -direction * 8.0
	play_sfx("hurt"); haptic(55,0.70)
	if bool(settings["show_damage_numbers"]): damage_numbers.append({"text":"-%.1f" % amount,"pos":Vector2(player["pos"]),"life":0.8,"color":Color8(255,91,82)})
	if float(player["hp"]) <= 0.0: finish_run(false)

func update_pickups(delta: float) -> void:
	for i in range(pickups.size() - 1, -1, -1):
		var pickup: Dictionary = pickups[i]
		pickup["phase"] = float(pickup["phase"]) + delta * 2.0
		if Vector2(pickup["pos"]).distance_to(Vector2(player["pos"])) < 30.0:
			match String(pickup["kind"]):
				"heart": player["hp"] = minf(float(player["max_hp"]), float(player["hp"]) + 1.0); play_sfx("heal")
				"scrap": scraps += int(pickup.get("amount",3)); play_sfx("pickup")
				"relic": apply_relic(String(pickup["id"]))
			pickups.remove_at(i)
		else: pickups[i] = pickup

func spawn_relic(position: Vector2, id: String) -> void:
	pickups.append({"kind":"relic","id":id,"pos":position,"phase":0.0})

func relic_catalog() -> Dictionary:
	var names := ["Seraph Lens","Cherub Coil","Bone Orchard","Cain's Mark","Salt Genome","Eden Valve","Black Manna","Industrial Halo","Watcher Gland","Nephilim Marrow","Genesis Seed","Abel's Crook","Seth Circuit","Naamah Chord","Ophanim Ring","Enoch Battery","Ash Covenant","Mycelial Crown","Bronze Rib","Gate Fragment"]
	var effects := ["damage","fire_rate","max_hp","pierce","multishot","speed","lifesteal","shield","critical","damage_speed","shot_speed","luck","dash","healing","orbit","ability","armor","spore","scrap","boss_damage"]
	var result := {}
	for tier in range(3):
		for i in range(names.size()):
			var id := "%s_%d" % [String(names[i]).to_lower().replace(" ","_").replace("'","").replace("-","_"), tier + 1]
			result[id] = {"name":"%s %s" % [names[i], ["I","II","III"][tier]],"effect":effects[i],"power":1.0 + tier * 0.55,"tier":tier + 1,"cost":12 + tier * 8 + (i % 5)}
	return result

func random_relic_id(excluded: Array = []) -> String:
	var ids := relic_catalog().keys()
	for id in excluded: ids.erase(id)
	return String(ids[rng.randi_range(0, ids.size() - 1)])

func apply_relic(id: String) -> void:
	var catalog := relic_catalog()
	if not catalog.has(id) or id in player["inventory"]: return
	var relic: Dictionary = catalog[id]
	player["inventory"].append(id)
	var power := float(relic["power"])
	match String(relic["effect"]):
		"damage": player["damage"] = float(player["damage"]) + 2.0 * power
		"fire_rate": player["fire_delay"] = maxf(0.08, float(player["fire_delay"]) * (1.0 - 0.09 * power))
		"max_hp": player["max_hp"] = float(player["max_hp"]) + power; player["hp"] = float(player["hp"]) + power
		"pierce": player["pierce"] = int(player["pierce"]) + 1
		"multishot": player["parallel"] = true
		"speed": player["speed"] = float(player["speed"]) * (1.0 + 0.06 * power)
		"shot_speed": player["shot_speed"] = float(player["shot_speed"]) * (1.0 + 0.08 * power)
		"luck", "critical": player["luck"] = float(player["luck"]) + 0.035 * power
		"dash": player["dash_delay"] = maxf(0.4, float(player["dash_delay"]) * (1.0 - 0.08 * power))
		"healing": player["hp"] = minf(float(player["max_hp"]), float(player["hp"]) + power)
		"armor", "shield": player["shield"] = true
		"damage_speed", "boss_damage": player["damage"] = float(player["damage"]) * (1.0 + 0.08 * power)
		_: player["ability"] = float(player["ability"]) + power
	play_sfx("relic")
	haptic(50,0.60)
	notify("RELIC ASSIMILATED // %s" % relic["name"])

func build_shop() -> Array:
	var result := []
	var used := []
	var catalog := relic_catalog()
	for i in range(3):
		var id := random_relic_id(used); used.append(id)
		result.append({"id":id,"cost":int(catalog[id]["cost"]),"bought":false})
	return result

func check_room_clear() -> void:
	if state != "run" or not enemies.is_empty(): return
	var room: Dictionary = room_graph[current_room]
	if bool(room["cleared"]) or String(room["kind"]) not in ["combat","boss"]: return
	room["cleared"] = true; room_graph[current_room] = room
	rooms_cleared += 1; scraps += 4 + int(room["depth"]) + biome_index
	if String(player["id"]) == "seth": player["shield"] = true
	if rng.randf() < 0.22 and String(room["kind"]) != "boss": spawn_relic(arena_rect().get_center(), random_relic_id())
	objective = "Choose an open gate"
	play_sfx("door")
	notify("CHAMBER PURGED // GATES RELEASED")
	save_suspended_run()

func check_room_transition() -> void:
	if state != "run": return
	var room: Dictionary = room_graph[current_room]
	if not bool(room["cleared"]): return
	var arena := arena_rect(); var pos := Vector2(player["pos"]); var edge := PLAYER_RADIUS + 2.0
	var direction := Vector2i.ZERO
	if pos.y <= arena.position.y + edge: direction = Vector2i.UP
	elif pos.y >= arena.end.y - edge: direction = Vector2i.DOWN
	elif pos.x <= arena.position.x + edge: direction = Vector2i.LEFT
	elif pos.x >= arena.end.x - edge: direction = Vector2i.RIGHT
	if direction != Vector2i.ZERO and direction in room["neighbors"]: enter_room(current_room + direction, direction)

func complete_biome() -> void:
	boss_health = 0.0; boss_max_health = 0.0
	if biome_index >= BIOMES.size() - 1:
		finish_run(true)
		return
	biome_index += 1; floor_number += 1
	profile["unlocked_biome"] = maxi(int(profile["unlocked_biome"]), biome_index + 1)
	generate_floor(); enter_room(Vector2i.ZERO, Vector2i.ZERO)
	play_biome_audio(true)
	notify("DESCENT COMPLETE // %s" % BIOMES[biome_index]["name"])

func finish_run(victory: bool) -> void:
	if state != "run": return
	var gain := maxi(1, int(floor(float(rooms_cleared) * 0.65))) + biome_index * 4 + (18 if victory else 0)
	profile["genome"] = int(profile["genome"]) + gain
	profile["best_depth"] = maxi(int(profile["best_depth"]), rooms_cleared)
	profile["runs"] = int(profile["runs"]) + 1
	if victory: profile["victories"] = int(profile["victories"]) + 1
	save_profile()
	if FileAccess.file_exists(SUSPEND_PATH): DirAccess.remove_absolute(SUSPEND_PATH)
	can_continue = false
	state = "victory" if victory else "game_over"
	play_sfx("victory" if victory else "death")
	haptic(120,1.0)

func spawn_effect(id: String, position: Vector2, color: Color, angle: float) -> void:
	effects.append({"id":id,"pos":position,"color":color,"angle":angle,"life":0.48,"max_life":0.48})

func update_effects(delta: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		effects[i]["life"] = float(effects[i]["life"]) - delta
		if float(effects[i]["life"]) <= 0.0: effects.remove_at(i)
	for i in range(damage_numbers.size() - 1, -1, -1):
		damage_numbers[i]["life"] = float(damage_numbers[i]["life"]) - delta
		damage_numbers[i]["pos"] = Vector2(damage_numbers[i]["pos"]) + Vector2(0.0,-28.0) * delta
		if float(damage_numbers[i]["life"]) <= 0.0: damage_numbers.remove_at(i)

func nearest_enemy(position: Vector2):
	var best = null; var best_distance := INF
	for enemy in enemies:
		var distance := position.distance_squared_to(Vector2(enemy["pos"]))
		if distance < best_distance: best_distance = distance; best = enemy
	return best

func quantize_direction(vector: Vector2) -> int:
	if vector.length_squared() < 0.0001: return 4
	var angle := atan2(vector.y, vector.x)
	return posmod(int(round((angle + PI * 0.5) / (PI * 0.25))), 8)

func direction_vector(index: int) -> Vector2:
	return Vector2.UP.rotated(float(posmod(index, 8)) * PI * 0.25)

func animation_action() -> String:
	if float(player.get("hp",1.0)) <= 0.0: return "death"
	if hurt_timer > 0.0: return "hurt"
	if dash_time > 0.0: return "dash"
	if shoot_timer > 0.0: return "attack"
	if input_move.length_squared() > 0.02: return "walk"
	return "idle"

func safe_rect() -> Rect2:
	var viewport := get_viewport_rect().size
	var margin := 12.0
	var rect := Rect2(Vector2(margin,margin), viewport - Vector2(margin * 2.0, margin * 2.0))
	var display_safe := DisplayServer.get_display_safe_area()
	var screen_size := DisplayServer.screen_get_size()
	if display_safe.size.x > 0 and display_safe.size.y > 0 and screen_size.x > 0 and screen_size.y > 0:
		var scale := Vector2(viewport.x / float(screen_size.x), viewport.y / float(screen_size.y))
		rect = Rect2(Vector2(display_safe.position) * scale, Vector2(display_safe.size) * scale).grow(-8.0)
	return rect

func arena_rect() -> Rect2:
	var safe := safe_rect()
	return Rect2(safe.position + Vector2(24.0, 74.0), safe.size - Vector2(48.0, 110.0))

func clamp_to_arena(position: Vector2, radius: float) -> Vector2:
	var arena := arena_rect()
	return Vector2(clampf(position.x, arena.position.x + radius, arena.end.x - radius), clampf(position.y, arena.position.y + radius, arena.end.y - radius))

func random_arena_position(margin: float) -> Vector2:
	var rect := arena_rect().grow(-margin)
	return Vector2(rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y))

func objective_for_room(room: Dictionary) -> String:
	match String(room["kind"]):
		"start": return "Enter the contaminated chambers"
		"shop": return "Trade with the preadamite exchange"
		"treasure": return "Assimilate the reliquary genome"
		"boss": return "Terminate %s" % BOSS_NAMES[biome_index]
		_: return "Purge all hostile signatures"

func room_title(room: Dictionary) -> String:
	match String(room["kind"]):
		"start": return "%s // ENTRY LAB" % BIOMES[biome_index]["name"]
		"shop": return "PREADAMITE EXCHANGE"
		"treasure": return "GENOME RELIQUARY"
		"boss": return "%s SANCTUM" % BOSS_NAMES[biome_index]
		_: return "%s // CHAMBER %02d" % [BIOMES[biome_index]["name"], int(room["depth"])]

func notify(text: String) -> void:
	notification = text; notification_timer = 2.5

func texture(path: String) -> Texture2D:
	if textures.has(path): return textures[path]
	if not ResourceLoader.exists(path): return null
	var loaded := load(path)
	if loaded is Texture2D: textures[path] = loaded; return loaded
	return null

func player_texture(id: String) -> Texture2D:
	var path := ASSET_ROOT + "players/%s.png" % id
	if ResourceLoader.exists(path): return texture(path)
	return texture(LEGACY_ROOT + "players/%s.png" % id)

func enemy_texture(id: String) -> Texture2D:
	var path := ASSET_ROOT + "enemies/%s.png" % id
	if ResourceLoader.exists(path): return texture(path)
	var category := String(ENEMIES[id]["category"])
	var legacy_category := "nephilim" if category == "nephilim" else ("fallen" if category == "fallen" else "feral")
	return texture(LEGACY_ROOT + "enemies/%s_01.png" % legacy_category)

func boss_texture(index: int) -> Texture2D:
	var path := ASSET_ROOT + "bosses/%s.png" % BOSS_IDS[index]
	if ResourceLoader.exists(path): return texture(path)
	var legacy: String = String(["watcher_engine","nephilim_king","seraph_reactor","void_archon","eden_warden"][index])
	return texture(LEGACY_ROOT + "bosses/%s.png" % legacy)

func draw_sprite(texture_value: Texture2D, position: Vector2, frame_size: Vector2, frame: int, row: int, scale: float = 1.0, tint: Color = Color.WHITE) -> void:
	if texture_value == null: return
	var source := Rect2(Vector2(float(frame) * frame_size.x, float(row) * frame_size.y), frame_size)
	draw_texture_rect_region(texture_value, Rect2(position - frame_size * scale * 0.5, frame_size * scale), source, tint)

func directional_row(action: String, direction: int) -> int:
	return int(ACTION_ROWS.get(action,0)) * 8 + posmod(direction,8)

func _draw() -> void:
	match state:
		"title": draw_title()
		"select": draw_select()
		"run": draw_run()
		"game_over": draw_end(false)
		"victory": draw_end(true)
	if archive_open: draw_archive()
	if settings_open: draw_settings()
	if bool(settings["safe_area_debug"]): draw_rect(safe_rect(), Color(0.1,0.9,0.5,0.8), false, 2.0)

func draw_title() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,size), Color8(5,9,10))
	for i in range(24):
		var y := 25.0 + i * 32.0
		draw_line(Vector2(0,y),Vector2(size.x,y-160),Color8(15,29,27),1.0)
	var center := Vector2(size.x * 0.5, 220.0)
	for radius in [154.0,116.0,78.0]: draw_arc(center,radius,-PI*0.92,PI*0.92,64,Color8(66,102,81),3.0)
	draw_circle(center,46.0,Color8(25,58,46)); draw_circle(center,28.0,Color8(139,190,119))
	draw_text_centered("GAMEISH",Vector2(size.x*0.5,58),22,Color8(126,158,145))
	draw_text_centered("EDEN//FALL",Vector2(size.x*0.5,395),56,Color8(231,216,172))
	draw_text_centered("INDUSTRIAL BIBLICAL ACTION ROGUELIKE",Vector2(size.x*0.5,432),16,Color8(122,148,138))
	for i in range(title_options().size()):
		var rect := title_option_rect(i)
		draw_panel(rect, Color8(35,57,48) if i == menu_index else Color8(19,27,27), Color8(136,181,126) if i == menu_index else Color8(55,72,68))
		draw_text_centered(title_options()[i], rect.get_center()+Vector2(0,6),17,Color8(232,226,197))
	draw_text_centered("GENOME %d  •  BEST %d  •  RUNS %d  •  VICTORIES %d" % [profile["genome"],profile["best_depth"],profile["runs"],profile["victories"]],Vector2(size.x*0.5,size.y-28),13,Color8(98,121,112))
	draw_text("v%s" % VERSION,Vector2(18,size.y-18),12,Color8(74,93,87))

func draw_select() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,size),Color8(6,10,12))
	draw_text_centered("SELECT AN ENGINEERED LINEAGE",Vector2(size.x*0.5,42),30,Color8(229,216,176))
	draw_text_centered("Eight-direction movement and independent eight-direction aim",Vector2(size.x*0.5,72),14,Color8(120,145,136))
	for i in range(LINEAGES.size()):
		var lineage: Dictionary = LINEAGES[i]; var rect := lineage_card_rect(i); var selected := i == selected_lineage
		draw_panel(rect,Color8(30,40,38) if selected else Color8(18,24,26),lineage["color"] if selected else Color8(55,67,66))
		var tex := player_texture(String(lineage["id"])); var frame := posmod(int(visual_clock*5.0+i),8)
		var row := directional_row("idle",4)
		if tex != null: draw_sprite(tex,Vector2(rect.get_center().x,rect.position.y+87),PLAYER_FRAME,frame,row,1.8)
		draw_text_centered(String(lineage["name"]),Vector2(rect.get_center().x,rect.position.y+155),23,lineage["color"])
		draw_text_centered(String(lineage["epithet"]),Vector2(rect.get_center().x,rect.position.y+178),12,Color8(177,184,171))
		draw_wrapped(String(lineage["trait"]),Rect2(rect.position+Vector2(12,205),Vector2(rect.size.x-24,58)),12,Color8(204,201,181))
		draw_text("HP %.0f" % lineage["max_hp"],rect.position+Vector2(16,292),13,Color8(226,216,185))
		draw_text("DMG %.1f" % lineage["damage"],rect.position+Vector2(16,315),13,Color8(226,216,185))
		draw_text("SPD %.0f" % lineage["speed"],rect.position+Vector2(16,338),13,Color8(226,216,185))
		draw_text_centered("TAP / %d" % (i+1),Vector2(rect.get_center().x,rect.end.y-16),12,Color8(111,131,125))

func draw_run() -> void:
	var shake := Vector2.ZERO if bool(settings["reduced_motion"]) else camera_shake
	draw_set_transform(shake)
	draw_arena(); draw_doors(); draw_pickups(); draw_bullets(); draw_enemies(); draw_player(); draw_effects()
	draw_set_transform(Vector2.ZERO)
	draw_hud(); draw_touch_controls()
	if notification_timer > 0.0:
		var box := Rect2(Vector2(get_viewport_rect().size.x*0.5-280,82),Vector2(560,38))
		draw_panel(box,Color(0.02,0.04,0.04,0.94),Color8(112,151,124)); draw_text_centered(notification,box.get_center()+Vector2(0,5),14,Color8(229,222,191))
	if paused: draw_pause()

func draw_arena() -> void:
	var size := get_viewport_rect().size; var arena := arena_rect(); var biome: Dictionary = BIOMES[biome_index]
	draw_rect(Rect2(Vector2.ZERO,size),Color8(4,7,8)); draw_rect(arena,biome["floor"])
	var tile_tex := texture(LEGACY_ROOT + "tiles/biome_%02d.png" % (biome_index+1))
	if tile_tex != null:
		var row := 0
		for y in range(int(arena.position.y),int(arena.end.y),32):
			var col := 0
			for x in range(int(arena.position.x),int(arena.end.x),32):
				var idx := posmod(col*7+row*11+biome_index*5,32)
				draw_texture_rect_region(tile_tex,Rect2(Vector2(x,y),Vector2(32,32)),Rect2(Vector2((idx%8)*32,(idx/8)*32),Vector2(32,32)),Color(1,1,1,0.72))
				col += 1
			row += 1
	for i in range(8):
		var p := arena.position + Vector2(84+i*151,72+posmod(i*83,int(maxf(120.0,arena.size.y-150.0))))
		draw_circle(p,20.0,Color(biome["accent"],0.10)); draw_arc(p,14,0,TAU,16,Color(biome["accent"],0.42),2.0)
	draw_rect(arena,biome["accent"],false,4.0)

func draw_doors() -> void:
	var room: Dictionary = room_graph[current_room]
	for direction in room["neighbors"]:
		var center := door_position(direction); var open := bool(room["cleared"]); var color := Color8(95,183,119) if open else Color8(172,67,61)
		var rect := Rect2(center-Vector2(43,12),Vector2(86,24))
		if direction.x != 0: rect = Rect2(center-Vector2(12,43),Vector2(24,86))
		draw_rect(rect,Color8(7,11,12)); draw_rect(rect,color,false,4.0)
		if not open:
			for i in range(3):
				if direction.x == 0: draw_line(rect.position+Vector2(8,6+i*6),rect.end-Vector2(8,18-i*6),color,2.0)
				else: draw_line(rect.position+Vector2(6+i*6,8),rect.end-Vector2(18-i*6,8),color,2.0)

func door_position(direction: Vector2i) -> Vector2:
	var arena := arena_rect()
	if direction == Vector2i.UP: return Vector2(arena.get_center().x,arena.position.y)
	if direction == Vector2i.DOWN: return Vector2(arena.get_center().x,arena.end.y)
	if direction == Vector2i.LEFT: return Vector2(arena.position.x,arena.get_center().y)
	return Vector2(arena.end.x,arena.get_center().y)

func draw_player() -> void:
	var tex := player_texture(String(player.get("id","adam"))); var action := animation_action(); var dir := quantize_direction(Vector2(player.get("look",Vector2.DOWN)))
	var row: int = directional_row(action,dir); var fps: float = float([5.0,10.0,14.0,16.0,10.0,8.0][int(ACTION_ROWS[action])]); var frame: int = posmod(int(visual_clock*fps),8)
	var tint := Color.WHITE
	if invulnerability > 0.0 and int(invulnerability*20.0)%2 == 0: tint = Color(1,1,1,0.38)
	if tex != null: draw_sprite(tex,Vector2(player["pos"]),PLAYER_FRAME,frame,row,1.18,tint)
	else: draw_circle(Vector2(player["pos"]),PLAYER_RADIUS,player["color"])
	var aim := Vector2(player.get("aim",Vector2.DOWN))
	draw_line(Vector2(player["pos"])+aim*10.0,Vector2(player["pos"])+aim*29.0,Color8(242,228,186),4.0)
	if bool(player["shield"]): draw_arc(Vector2(player["pos"]),26,-PI*0.84,PI*0.84,28,Color8(112,181,239),3.0)

func draw_enemies() -> void:
	for enemy in enemies:
		var pos := Vector2(enemy["pos"]); var action := "idle"
		if float(enemy["hurt"]) > 0.0: action = "hurt"
		elif float(enemy["attack"]) > 0.0: action = "attack"
		elif Vector2(enemy["velocity"]).length() > 8.0: action = "walk"
		var dir := quantize_direction(Vector2(enemy["look"])); var fps := 10.0 if action == "walk" else (14.0 if action == "attack" else 6.0)
		var frame := posmod(int((visual_clock+float(enemy["variant"])*0.13)*fps),8); var tex: Texture2D
		var frame_size := PLAYER_FRAME; var scale := maxf(0.92,float(enemy["radius"])/18.0)
		if bool(enemy["boss"]):
			tex = boss_texture(biome_index); frame_size = BOSS_FRAME; scale = maxf(1.0,float(enemy["radius"])/48.0)
			var boss_action := 1 if action == "attack" else (2 if int(enemy["stage"]) > 0 and int(visual_clock*4.0)%7==0 else 0)
			draw_sprite(tex,pos,frame_size,frame,boss_action*8+dir,scale,Color.WHITE)
		else:
			tex = enemy_texture(String(enemy["id"])); draw_sprite(tex,pos,frame_size,frame,directional_row(action,dir),scale,Color.WHITE)
		var ratio := maxf(0.0,float(enemy["hp"])/float(enemy["max_hp"])); var width := float(enemy["radius"])*2.1
		draw_rect(Rect2(pos+Vector2(-width*0.5,float(enemy["radius"])+9),Vector2(width,5)),Color8(38,22,22))
		draw_rect(Rect2(pos+Vector2(-width*0.5,float(enemy["radius"])+9),Vector2(width*ratio,5)),Color8(205,70,64))

func draw_bullets() -> void:
	for bullet in bullets:
		var pos := Vector2(bullet["pos"]); var radius := float(bullet["radius"]); var color: Color = bullet["color"]
		draw_circle(pos,radius+4,Color(color,0.18)); draw_circle(pos,radius,color)
		var velocity := Vector2(bullet["vel"]).normalized(); draw_line(pos-velocity*8,pos+velocity*5,Color(color,0.65),2.0)

func draw_pickups() -> void:
	for pickup in pickups:
		var pos := Vector2(pickup["pos"])+Vector2(0,sin(float(pickup["phase"])*2.4)*4.0)
		if String(pickup["kind"]) == "heart":
			draw_circle(pos,11,Color8(205,69,73)); draw_rect(Rect2(pos-Vector2(3,8),Vector2(6,16)),Color8(242,188,172)); draw_rect(Rect2(pos-Vector2(8,3),Vector2(16,6)),Color8(242,188,172))
		elif String(pickup["kind"]) == "relic":
			draw_circle(pos,15,Color8(23,29,32)); draw_arc(pos,13,0,TAU,20,BIOMES[biome_index]["accent"],3.0); draw_circle(pos,5,Color8(229,210,147))

func draw_effects() -> void:
	for effect in effects:
		var progress := 1.0 - float(effect["life"])/float(effect["max_life"]); var radius := 4.0 + progress*24.0
		draw_arc(Vector2(effect["pos"]),radius,0,TAU,24,Color(effect["color"],1.0-progress),3.0)
	for number in damage_numbers:
		draw_text_centered(String(number["text"]),Vector2(number["pos"]),14,number["color"])

func draw_hud() -> void:
	var safe := safe_rect(); var scale := float(settings["ui_scale"]); var text_scale := float(settings["text_scale"])
	var top_left := Rect2(safe.position+Vector2(8,8),Vector2(318,58)*scale)
	draw_panel(top_left,Color(0.02,0.04,0.04,0.92),Color8(79,111,97))
	draw_circle(top_left.position+Vector2(29,29)*scale,20*scale,player["color"])
	draw_text(String(player["name"]),top_left.position+Vector2(57,21)*scale,int(15*text_scale),Color8(234,221,184))
	var hp_ratio := clampf(float(player["hp"])/float(player["max_hp"]),0.0,1.0)
	var hp_rect := Rect2(top_left.position+Vector2(57,31)*scale,Vector2(172,12)*scale)
	draw_rect(hp_rect,Color8(55,25,28)); draw_rect(Rect2(hp_rect.position,Vector2(hp_rect.size.x*hp_ratio,hp_rect.size.y)),Color8(200,69,68)); draw_rect(hp_rect,Color8(232,194,151),false,1.0)
	draw_text("%.1f / %.1f" % [player["hp"],player["max_hp"]],hp_rect.position+Vector2(5,10)*scale,int(10*text_scale),Color.WHITE)
	if bool(player["shield"]): draw_text("SHIELD",top_left.position+Vector2(236,40)*scale,int(10*text_scale),Color8(120,190,244))
	var center_box := Rect2(Vector2(safe.get_center().x-210*scale,safe.position.y+8),Vector2(420,58)*scale)
	draw_panel(center_box,Color(0.02,0.04,0.04,0.90),BIOMES[biome_index]["accent"])
	draw_text_centered(String(BIOMES[biome_index]["name"]),center_box.position+Vector2(center_box.size.x*0.5,20*scale),int(14*text_scale),Color8(232,220,184))
	draw_text_centered(objective,center_box.position+Vector2(center_box.size.x*0.5,41*scale),int(11*text_scale),Color8(151,176,165))
	var resource_box := Rect2(Vector2(safe.end.x-260*scale,safe.position.y+8),Vector2(252,58)*scale)
	draw_panel(resource_box,Color(0.02,0.04,0.04,0.90),Color8(79,111,97))
	draw_text("SCRAP %03d" % scraps,resource_box.position+Vector2(14,22)*scale,int(13*text_scale),Color8(221,172,90))
	draw_text("GENOME %04d" % profile["genome"],resource_box.position+Vector2(14,44)*scale,int(12*text_scale),Color8(156,207,177))
	draw_minimap(Rect2(resource_box.position+Vector2(150,8)*scale,Vector2(88,42)*scale))
	if boss_max_health > 0.0 and boss_health > 0.0:
		var boss_rect := Rect2(Vector2(safe.get_center().x-260*scale,safe.position.y+73*scale),Vector2(520,24)*scale)
		draw_rect(boss_rect,Color8(37,18,21)); draw_rect(Rect2(boss_rect.position,Vector2(boss_rect.size.x*boss_health/boss_max_health,boss_rect.size.y)),Color8(173,43,54)); draw_rect(boss_rect,Color8(234,184,110),false,2.0)
		draw_text_centered(BOSS_NAMES[biome_index],boss_rect.get_center()+Vector2(0,5),int(11*text_scale),Color.WHITE)
	var bottom := Rect2(Vector2(safe.position.x+safe.size.x*0.5-210*scale,safe.end.y-50*scale),Vector2(420,42)*scale)
	draw_panel(bottom,Color(0.02,0.04,0.04,0.88),Color8(63,87,81))
	var inventory: Array = player.get("inventory",[])
	for i in range(8):
		var slot := Rect2(bottom.position+Vector2(8+i*49,6)*scale,Vector2(38,30)*scale)
		draw_rect(slot,Color8(18,25,27)); draw_rect(slot,Color8(70,89,84),false,1.0)
		if i < inventory.size(): draw_text_centered(str(i+1),slot.get_center()+Vector2(0,4),int(10*text_scale),Color8(226,205,144))
	draw_cooldown_ring(dash_button_rect().get_center(),dash_timer/maxf(0.001,float(player["dash_delay"])),Color8(107,180,229))
	draw_rect(pause_button_rect(),Color(0.04,0.07,0.07,0.9)); draw_text_centered("II",pause_button_rect().get_center()+Vector2(0,5),14,Color8(220,216,190))

func draw_minimap(rect: Rect2) -> void:
	draw_rect(rect,Color8(8,13,14)); draw_rect(rect,Color8(66,88,81),false,1.0)
	if room_order.is_empty(): return
	var min_x := 999; var max_x := -999; var min_y := 999; var max_y := -999
	for coord in room_order: min_x=mini(min_x,coord.x); max_x=maxi(max_x,coord.x); min_y=mini(min_y,coord.y); max_y=maxi(max_y,coord.y)
	var span := Vector2(maxi(1,max_x-min_x+1),maxi(1,max_y-min_y+1)); var cell := minf(rect.size.x/span.x,rect.size.y/span.y)*0.75
	for coord in room_order:
		var room: Dictionary = room_graph[coord]
		if not bool(room["visited"]) and coord != current_room: continue
		var p := rect.position+Vector2((coord.x-min_x+0.5)*rect.size.x/span.x,(coord.y-min_y+0.5)*rect.size.y/span.y)
		var color := Color8(235,209,131) if coord == current_room else (Color8(94,168,117) if bool(room["cleared"]) else Color8(101,107,104))
		draw_rect(Rect2(p-Vector2.ONE*cell*0.25,Vector2.ONE*cell*0.5),color)

func draw_touch_controls() -> void:
	if not OS.has_feature("mobile") and left_touch_id == -1 and right_touch_id == -1: return
	var left_center := movement_stick_center(); var right_center := aim_stick_center()
	for pair in [[left_center,input_move,Color8(93,153,117)],[right_center,input_aim,Color8(166,105,185)]]:
		draw_circle(pair[0],55,Color(0.05,0.08,0.08,0.55)); draw_arc(pair[0],55,0,TAU,36,Color(pair[2],0.7),2.0); draw_circle(pair[0]+pair[1]*34,20,Color(pair[2],0.72))
	draw_circle(dash_button_rect().get_center(),dash_button_rect().size.x*0.5,Color(0.08,0.13,0.16,0.72)); draw_text_centered("DASH",dash_button_rect().get_center()+Vector2(0,5),11,Color8(190,222,238))
	draw_circle(interact_button_rect().get_center(),interact_button_rect().size.x*0.5,Color(0.13,0.10,0.06,0.72)); draw_text_centered("USE",interact_button_rect().get_center()+Vector2(0,5),11,Color8(235,205,143))

func draw_pause() -> void:
	var size := get_viewport_rect().size; draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,0.68))
	var panel := Rect2(Vector2(size.x*0.5-210,size.y*0.5-190),Vector2(420,380)); draw_panel(panel,Color8(14,22,23),Color8(116,153,126))
	draw_text_centered("EXCURSION PAUSED",Vector2(size.x*0.5,panel.position.y+48),26,Color8(232,218,177))
	for item in [[pause_resume_rect(),"RESUME"],[pause_settings_rect(),"SETTINGS & ACCESSIBILITY"],[pause_exit_rect(),"SAVE & EXIT TO BIOLAB"]]:
		draw_panel(item[0],Color8(29,43,40),Color8(83,119,102)); draw_text_centered(item[1],item[0].get_center()+Vector2(0,6),16,Color8(225,219,191))
	draw_text_centered("Run state is saved during suspension and focus loss.",Vector2(size.x*0.5,panel.end.y-34),12,Color8(119,145,136))

func draw_settings() -> void:
	var size := get_viewport_rect().size; draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,0.78))
	var panel := Rect2(Vector2(size.x*0.5-330,size.y*0.5-310),Vector2(660,620)); draw_panel(panel,Color8(13,21,23),Color8(107,154,126))
	draw_text_centered("ACCESSIBILITY & INTERFACE",Vector2(size.x*0.5,panel.position.y+42),25,Color8(232,218,177))
	var rows := settings_rows()
	for i in range(rows.size()):
		var rect := settings_row_rect(i); var selected := i == settings_index
		draw_rect(rect,Color8(31,48,43) if selected else Color8(19,29,30)); draw_rect(rect,Color8(119,170,132) if selected else Color8(55,76,70),false,1.0)
		draw_text(String(rows[i]["label"]),rect.position+Vector2(14,24),14,Color8(218,215,190)); draw_text(setting_value(String(rows[i]["key"])),rect.position+Vector2(rect.size.x-155,24),14,Color8(154,211,177))
	draw_panel(close_button_rect(),Color8(45,62,56),Color8(113,158,126)); draw_text_centered("CLOSE / SAVE",close_button_rect().get_center()+Vector2(0,6),15,Color8(232,223,194))

func setting_value(key: String) -> String:
	if key in ["ui_scale","text_scale"]: return "%d%%" % int(float(settings[key])*100.0)
	return "ON" if bool(settings[key]) else "OFF"

func draw_archive() -> void:
	var size := get_viewport_rect().size; draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,0.82))
	var panel := Rect2(Vector2(size.x*0.5-420,size.y*0.5-285),Vector2(840,570)); draw_panel(panel,Color8(13,20,22),Color8(120,157,127))
	draw_text_centered("GENOME ARCHIVE",Vector2(size.x*0.5,panel.position.y+40),27,Color8(230,216,176))
	draw_text_centered("60 RELIC PROTOCOLS // 5 LINEAGES // 5 CONTAMINATED BIOMES",Vector2(size.x*0.5,panel.position.y+69),13,Color8(125,157,145))
	var catalog := relic_catalog(); var ids := catalog.keys()
	for i in range(mini(60,ids.size())):
		var col := i%10; var row := i/10; var rect := Rect2(panel.position+Vector2(28+col*79,100+row*62),Vector2(66,49))
		draw_rect(rect,Color8(19,28,30)); draw_rect(rect,BIOMES[i%5]["accent"],false,1.0); draw_text_centered(str(i+1),rect.get_center()+Vector2(0,4),11,Color8(225,205,148))
	draw_text_centered("Tap anywhere or press Escape to close",Vector2(size.x*0.5,panel.end.y-22),12,Color8(113,137,129))

func draw_end(victory: bool) -> void:
	var size := get_viewport_rect().size; draw_rect(Rect2(Vector2.ZERO,size),Color8(6,9,10))
	var color := Color8(113,190,129) if victory else Color8(192,67,65)
	for r in [160.0,116.0,78.0]: draw_arc(Vector2(size.x*0.5,230),r,0,TAU,64,Color(color,0.55),3.0)
	draw_text_centered("EDEN RECLAIMED" if victory else "GENOME TERMINATED",Vector2(size.x*0.5,435),38,color)
	draw_text_centered("Rooms purged %d  •  Biome %d/5" % [rooms_cleared,biome_index+1],Vector2(size.x*0.5,480),16,Color8(207,202,178))
	draw_text_centered("Press Enter or tap to return to lineage selection",Vector2(size.x*0.5,550),14,Color8(121,147,137))

func draw_panel(rect: Rect2, fill: Color, border: Color) -> void:
	draw_rect(rect,fill); draw_rect(rect,border,false,2.0)

func draw_text(text_value: String, position: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font,position,text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func draw_text_centered(text_value: String, position: Vector2, font_size: int, color: Color) -> void:
	var width := ThemeDB.fallback_font.get_string_size(text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string(ThemeDB.fallback_font,position-Vector2(width*0.5,0),text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func draw_wrapped(text_value: String, rect: Rect2, font_size: int, color: Color) -> void:
	draw_multiline_string(ThemeDB.fallback_font,rect.position,text_value,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,font_size,-1,color)

func draw_cooldown_ring(center: Vector2, ratio: float, color: Color) -> void:
	draw_arc(center,34,-PI*0.5,-PI*0.5+TAU*(1.0-clampf(ratio,0.0,1.0)),32,color,3.0)

func title_option_rect(index: int) -> Rect2:
	var size := get_viewport_rect().size; return Rect2(Vector2(size.x*0.5-170,470+index*56),Vector2(340,46))

func lineage_card_rect(index: int) -> Rect2:
	var size := get_viewport_rect().size; var gap := 12.0; var margin := 30.0; var width := (size.x-margin*2-gap*4)/5.0
	return Rect2(Vector2(margin+index*(width+gap),96),Vector2(width,size.y-130))

func settings_row_rect(index: int) -> Rect2:
	var size := get_viewport_rect().size; return Rect2(Vector2(size.x*0.5-285,size.y*0.5-240+index*43),Vector2(570,36))

func close_button_rect() -> Rect2:
	var size := get_viewport_rect().size; return Rect2(Vector2(size.x*0.5-110,size.y*0.5+250),Vector2(220,44))

func pause_button_rect() -> Rect2:
	var safe := safe_rect(); return Rect2(Vector2(safe.end.x-46,safe.position.y+12),Vector2(38,38))

func movement_stick_center() -> Vector2:
	var safe := safe_rect(); return Vector2(safe.position.x+92,safe.end.y-92) if not bool(settings["left_handed"]) else Vector2(safe.end.x-92,safe.end.y-92)

func aim_stick_center() -> Vector2:
	var safe := safe_rect(); return Vector2(safe.end.x-92,safe.end.y-92) if not bool(settings["left_handed"]) else Vector2(safe.position.x+92,safe.end.y-92)

func dash_button_rect() -> Rect2:
	var center := aim_stick_center()+Vector2(-74,-64) if not bool(settings["left_handed"]) else aim_stick_center()+Vector2(74,-64)
	return Rect2(center-Vector2(34,34),Vector2(68,68))

func interact_button_rect() -> Rect2:
	var center := aim_stick_center()+Vector2(0,-92)
	return Rect2(center-Vector2(27,27),Vector2(54,54))

func pause_resume_rect() -> Rect2:
	var size := get_viewport_rect().size; return Rect2(Vector2(size.x*0.5-150,size.y*0.5-78),Vector2(300,52))

func pause_settings_rect() -> Rect2:
	var size := get_viewport_rect().size; return Rect2(Vector2(size.x*0.5-150,size.y*0.5-8),Vector2(300,52))

func pause_exit_rect() -> Rect2:
	var size := get_viewport_rect().size; return Rect2(Vector2(size.x*0.5-150,size.y*0.5+62),Vector2(300,52))

func setup_audio() -> void:
	for kind in ["music","ambience"]:
		var player_node := AudioStreamPlayer.new(); player_node.name = kind.capitalize(); player_node.bus = "Music" if kind == "music" else "Ambience"; add_child(player_node); audio_players[kind] = player_node
	for i in range(12):
		var sfx := AudioStreamPlayer.new(); sfx.name = "SFX%02d" % i; sfx.bus = "SFX"; add_child(sfx); sfx_pool.append(sfx)

func play_biome_audio(force: bool = false) -> void:
	if biome_index == current_music_biome and not force: return
	current_music_biome = biome_index
	for kind in ["music","ambience"]:
		var path := LEGACY_ROOT + "audio/%s/biome_%02d.wav" % [kind,biome_index+1]
		if ResourceLoader.exists(path):
			var stream := load(path)
			if stream is AudioStreamWAV:
				stream = stream.duplicate(); stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			audio_players[kind].stream = stream; audio_players[kind].play()

func play_sfx(id: String, volume_db: float = 0.0, throttle_ms: int = 0) -> void:
	if sfx_pool.is_empty(): return
	var path := LEGACY_ROOT + "audio/sfx/%s.wav" % id
	if not ResourceLoader.exists(path): return
	var p := sfx_pool[sfx_cursor]; sfx_cursor = (sfx_cursor+1)%sfx_pool.size(); p.stop(); p.stream = load(path); p.volume_db = volume_db; p.pitch_scale = rng.randf_range(0.96,1.04); p.play()

func haptic(duration_ms: int, amplitude: float) -> void:
	if bool(settings["haptics"]): Input.vibrate_handheld(duration_ms, amplitude)

func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f := FileAccess.open(SAVE_PATH,FileAccess.READ)
	if f == null: return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for key in profile.keys(): profile[key] = parsed.get(key,profile[key])

func save_profile() -> void:
	var f := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if f != null: f.store_string(JSON.stringify(profile))

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH): return
	var f := FileAccess.open(SETTINGS_PATH,FileAccess.READ)
	if f == null: return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for key in settings.keys(): settings[key] = parsed.get(key,settings[key])

func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH,FileAccess.WRITE)
	if f != null: f.store_string(JSON.stringify(settings))

func save_suspended_run() -> void:
	if state != "run" or player.is_empty(): return
	var data := {
		"version":VERSION,"seed":run_seed,"lineage":selected_lineage,"biome":biome_index,"floor":floor_number,
		"rooms_cleared":rooms_cleared,"scraps":scraps,"current_room":[current_room.x,current_room.y],
		"hp":player["hp"],"max_hp":player["max_hp"],"damage":player["damage"],"speed":player["speed"],
		"fire_delay":player["fire_delay"],"shot_speed":player["shot_speed"],"dash_delay":player["dash_delay"],
		"luck":player["luck"],"pierce":player["pierce"],"parallel":player["parallel"],"shield":player["shield"],
		"inventory":player["inventory"],
	}
	var f := FileAccess.open(SUSPEND_PATH,FileAccess.WRITE)
	if f != null: f.store_string(JSON.stringify(data)); can_continue = true

func restore_suspended_run() -> void:
	if not FileAccess.file_exists(SUSPEND_PATH): state = "select"; return
	var f := FileAccess.open(SUSPEND_PATH,FileAccess.READ)
	if f == null: state = "select"; return
	var data = JSON.parse_string(f.get_as_text())
	if not data is Dictionary: state = "select"; return
	start_new_run(int(data.get("lineage",0)),int(data.get("seed",0)))
	biome_index = clampi(int(data.get("biome",0)),0,BIOMES.size()-1); floor_number = maxi(1,int(data.get("floor",1))); rooms_cleared = int(data.get("rooms_cleared",0)); scraps = int(data.get("scraps",0))
	generate_floor(); enter_room(Vector2i.ZERO,Vector2i.ZERO)
	for key in ["hp","max_hp","damage","speed","fire_delay","shot_speed","dash_delay","luck","pierce","parallel","shield","inventory"]:
		if data.has(key): player[key] = data[key]
	play_biome_audio(true); notify("SUSPENDED EXCURSION RESTORED")

func audit_readiness() -> float:
	var checks := [
		LINEAGES.size() == 5, relic_catalog().size() == 60, ENEMIES.size() >= 18, BIOMES.size() == 5,
		DIR_NAMES.size() == 8, ACTION_ROWS.size() == 6, ResourceLoader.exists(LEGACY_ROOT+"audio/music/biome_01.wav"),
		FileAccess.file_exists("res://tests/v3_audit.gd"), FileAccess.file_exists("res://docs/READINESS_V3.md"),
	]
	var passed := 0
	for check in checks:
		if check: passed += 1
	return float(passed) / float(checks.size()) * 100.0
