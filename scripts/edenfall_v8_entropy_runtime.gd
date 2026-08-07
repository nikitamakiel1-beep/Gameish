extends "res://scripts/edenfall_v7_release_runtime.gd"

const ENTROPY_VERSION := "0.6.2-entropy"
const ENTROPY_SUSPEND_PATH := "user://edenfall_entropy_v8.json"
const EntropyDirectorScript: Script = preload("res://scripts/v8/entropy_director.gd")
const EnemyGenomeDirectorScript: Script = preload("res://scripts/v8/enemy_genome_director.gd")
const ProceduralSpriteForgeScript: Script = preload("res://scripts/v8/procedural_sprite_forge.gd")
const ProceduralWorldDirectorScript: Script = preload("res://scripts/v8/procedural_world_director.gd")

var entropy: RefCounted = EntropyDirectorScript.new()
var genome_director: RefCounted = EnemyGenomeDirectorScript.new()
var sprite_forge: RefCounted = ProceduralSpriteForgeScript.new()
var world_director: RefCounted = ProceduralWorldDirectorScript.new()

var _floor_entropy := 1
var _restoring_entropy := false
var _restore_floor_entropy := 0
var _restore_room_recipes: Dictionary = {}
var _restore_player_genome: Dictionary = {}
var _next_enemy_genome: Dictionary = {}
var _v8_sprite_textures: Dictionary = {}
var _v8_room_noise: Dictionary = {}
var _entropy_session := ""

func _ready() -> void:
	entropy.call("reseed")
	_entropy_session = "%08x" % (int(entropy.call("token", "session")) & 0xffffffff)
	super._ready()

func start_new_run(lineage_index: int, seed_override: int = 0) -> void:
	_v8_sprite_textures.clear()
	_v8_room_noise.clear()
	_next_enemy_genome.clear()
	if not _restoring_entropy:
		entropy.call("reseed")
		_entropy_session = "%08x" % (int(entropy.call("token", "run_session")) & 0xffffffff)
		_floor_entropy = _fresh_floor_entropy()
		seed_override = int(entropy.call("token", "run_identity")) & 0x7fffffff
	else:
		_floor_entropy = maxi(1, _restore_floor_entropy)
	super.start_new_run(lineage_index, seed_override)
	rng.randomize()
	if not player.is_empty():
		var player_genome: Dictionary
		if _restoring_entropy and not _restore_player_genome.is_empty():
			player_genome = _restore_player_genome.duplicate(true)
		else:
			player_genome = genome_director.call("player_genome", entropy.call("fork", "player_visual"), String(player["id"]), biome_index)
		player["v8_visual_genome"] = player_genome
		_player_entropy_texture()
	if not _restoring_entropy:
		save_suspended_run()

func generate_floor() -> void:
	if _restoring_entropy and _restore_floor_entropy != 0:
		_floor_entropy = _restore_floor_entropy
	else:
		_floor_entropy = _fresh_floor_entropy()
	super.generate_floor()
	if _restoring_entropy and not _restore_room_recipes.is_empty():
		_apply_saved_room_recipes()

func _floor_graph_seed() -> int:
	return maxi(1, _floor_entropy)

func _fresh_floor_entropy() -> int:
	return maxi(1, int(entropy.call("token", "floor:%d:%d" % [biome_index, floor_number])) & 0x7fffffff)

func _decorate_rc6_floor() -> void:
	var candidates: Array[Vector2i] = []
	for coord in room_order:
		if not room_graph.has(coord):
			continue
		var room: Dictionary = room_graph[coord]
		if String(room.get("kind", "combat")) == "combat" and int(room.get("depth", 0)) >= 2:
			candidates.append(coord)
	var shuffled: Array = entropy.call("shuffled", candidates)
	var special_kinds: Array[String] = ["settlement","sacrifice","memory","maintenance"]
	if biome_index >= 2:
		special_kinds.append("serpent_terminal")
	var special_count := mini(shuffled.size(), clampi(1 + biome_index / 2 + (1 if bool(entropy.call("chance",0.44)) else 0), 1, 3))
	for index in range(special_count):
		var coord := Vector2i(shuffled[index])
		var room: Dictionary = room_graph[coord]
		var kind := String(entropy.call("pick", special_kinds, "memory"))
		room["kind"] = kind
		room["modifier"] = "none"
		room["reward_multiplier"] = 1.0
		room["rc6_used"] = false
		room["rc6_rewarded"] = false
		if kind == "settlement":
			room["faction"] = String(entropy.call("pick", ["salt_caravans","ash_covenant","tubal_foundries","enoch_outlaws","lamech_houses","unnamed"], "unnamed"))
		elif kind == "memory":
			room["memory_id"] = "%s_biome_%d_fragment_%d" % [String(LINEAGES[selected_lineage]["id"]), biome_index + 1, int(entropy.call("token","memory")) & 3]
		room_graph[coord] = room
	for coord in room_order:
		if not room_graph.has(coord):
			continue
		var room: Dictionary = room_graph[coord]
		var kind := String(room.get("kind",""))
		if kind == "combat" and int(room.get("depth",0)) >= 3 and bool(entropy.call("chance", clampf(0.12 + biome_index*0.035,0.12,0.30))):
			room["kind"] = "contract"
			room["modifier"] = String(entropy.call("pick", ["elite_hunt","crossfire","blackout","corrosive_grid"], "elite_hunt"))
			room["reward_multiplier"] = randf_range(1.35,1.72)
			room["rc6_rewarded"] = false
		elif kind == "shop":
			room["rc6_shop_faction"] = String(entropy.call("pick", ["salt_caravans","ash_covenant","tubal_foundries","enoch_outlaws","lamech_houses","unnamed"], "unnamed"))
			room["rc6_priced"] = false
		room_graph[coord] = room

func spawn_room(room: Dictionary) -> void:
	var kind := String(room.get("kind", "combat"))
	if kind not in ["combat","trial","contract"]:
		super.spawn_room(room)
		return
	var recipe: Dictionary = room.get("v8_encounter_recipe", {})
	if recipe.is_empty():
		recipe = _build_encounter_recipe(room)
		room["v8_encounter_recipe"] = recipe
		room_graph[current_room] = room
	_spawn_encounter_recipe(recipe, kind)

func _build_encounter_recipe(room: Dictionary) -> Dictionary:
	var kind := String(room.get("kind","combat"))
	var depth := int(room.get("depth",0))
	var count := clampi(3 + int(depth/2) + biome_index + randi_range(-1,1), 4, 8)
	if active_mode == "training": count = maxi(3,count-1)
	elif active_mode == "daily": count = mini(9,count+1)
	if kind == "trial": count = mini(9,count+2)
	elif kind == "contract": count = mini(9,count+1)
	var pool: Array = enemy_pool_for_biome()
	var composition_token := int(entropy.call("token", "encounter:%s" % _coord_key(current_room)))
	var composition: Dictionary = encounter_composer.call("compose", pool, count, composition_token, kind, String(room.get("modifier","none")))
	var ids: Array = composition.get("ids",[])
	var formation := String(composition.get("formation","ring"))
	var positions_token := int(entropy.call("token", "positions:%s" % _coord_key(current_room)))
	var positions: Array = encounter_composer.call("positions", arena_rect(), ids.size(), formation, positions_token)
	var arena := arena_rect()
	var entries: Array = []
	for index in range(ids.size()):
		var id := String(ids[index])
		var definition: Dictionary = ENEMIES.get(id,{})
		var position := Vector2(positions[index]) if index < positions.size() else random_arena_position(105.0)
		var u := clampf((position.x-arena.position.x)/maxf(1.0,arena.size.x),0.06,0.94)
		var v := clampf((position.y-arena.position.y)/maxf(1.0,arena.size.y),0.08,0.92)
		var genome: Dictionary = genome_director.call("generate", entropy.call("fork","enemy:%s:%d" % [id,index]), id, String(definition.get("category","preadamic")), String(definition.get("style","melee")), biome_index, _entropy_threat(), false, false)
		entries.append({"id":id,"u":u,"v":v,"genome":genome})
	return {
		"name":String(composition.get("name","UNSTABLE HOST CELL")),
		"signature":String(composition.get("id","mixed")),
		"formation":formation,
		"entries":entries,
		"entropy":"%08x" % (composition_token & 0xffffffff),
	}

func _spawn_encounter_recipe(recipe: Dictionary, kind: String) -> void:
	var arena := arena_rect()
	var entries: Array = recipe.get("entries",[])
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		var position := arena.position + Vector2(float(entry.get("u",0.5))*arena.size.x,float(entry.get("v",0.5))*arena.size.y)
		_next_enemy_genome = Dictionary(entry.get("genome",{})).duplicate(true)
		spawn_enemy(String(entry.get("id","feral_scavenger")),position,index)
	_next_enemy_genome.clear()
	if kind in ["trial","contract"] and not enemies.is_empty():
		promote_enemy_to_elite(0,"armored")
	if kind == "contract" and enemies.size() > 2:
		promote_enemy_to_elite(2,"swift")
	_spawn_rc7_faction_retaliation(room_graph.get(current_room,{}),int(entropy.call("token","retaliation")))
	encounter_signature = String(recipe.get("name","UNSTABLE HOST CELL"))
	encounter_signature_id = String(recipe.get("signature","mixed"))

func spawn_enemy(id: String, position: Vector2, variant: int = 0) -> void:
	super.spawn_enemy(id,position,variant)
	if enemies.is_empty():
		return
	var index := enemies.size()-1
	var enemy: Dictionary = enemies[index]
	var definition: Dictionary = ENEMIES.get(id,{})
	var genome: Dictionary = _next_enemy_genome.duplicate(true) if not _next_enemy_genome.is_empty() else genome_director.call("generate", entropy.call("fork","spawn:%s:%d" % [id,index]), id, String(definition.get("category",enemy.get("category","preadamic"))), String(definition.get("style",enemy.get("style","melee"))), biome_index, _entropy_threat(), bool(enemy.get("elite",false)), bool(enemy.get("boss",false)))
	enemy["v8_visual_genome"] = genome
	enemy["visual_key"] = String(genome.get("visual_signature","%s-%d" % [id,index]))
	var hp_mult := float(genome.get("hp_mult",1.0))
	var speed_mult := float(genome.get("speed_mult",1.0))
	var damage_mult := float(genome.get("damage_mult",1.0))
	var cooldown_mult := float(genome.get("cooldown_mult",1.0))
	if enemy.has("max_hp"):
		enemy["max_hp"] = float(enemy["max_hp"])*hp_mult
		enemy["hp"] = float(enemy["max_hp"])
	else:
		enemy["hp"] = float(enemy.get("hp",1.0))*hp_mult
		enemy["max_hp"] = float(enemy["hp"])
	if enemy.has("speed"): enemy["speed"] = float(enemy["speed"])*speed_mult
	if enemy.has("damage"): enemy["damage"] = float(enemy["damage"])*damage_mult
	if enemy.has("cooldown"): enemy["cooldown"] = float(enemy["cooldown"])*cooldown_mult
	if enemy.has("radius"): enemy["radius"] = float(enemy["radius"])*float(genome.get("visual_scale",1.0))
	enemy["name"] = "%s // %s" % [String(enemy.get("name",id)),String(genome.get("trait","variant")).to_upper()]
	enemies[index] = enemy
	_enemy_entropy_texture(enemy)

func spawn_boss() -> void:
	super.spawn_boss()
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		if not bool(enemy.get("boss",false)):
			continue
		var genome: Dictionary = enemy.get("v8_visual_genome",{})
		if genome.is_empty() or not bool(genome.get("boss",false)):
			genome = genome_director.call("generate",entropy.call("fork","boss:%d" % biome_index),String(BOSS_IDS[biome_index]),"guardian",String(enemy.get("style","radial")),biome_index,_entropy_threat()+0.35,true,true)
			enemy["v8_visual_genome"] = genome
			enemy["visual_key"] = String(genome.get("visual_signature","boss-%d" % biome_index))
			enemies[index] = enemy
		_enemy_entropy_texture(enemy)

func random_relic_id(excluded: Array = []) -> String:
	var catalog := relic_catalog()
	var room_kind := "treasure"
	if room_graph.has(current_room): room_kind = String(room_graph[current_room].get("kind","treasure"))
	var context := String(relic_pool_director.call("context_for_room",room_kind))
	var inventory: Array = player.get("inventory",[]) if not player.is_empty() else []
	var combined := excluded.duplicate()
	for id in inventory:
		if id not in combined: combined.append(id)
	var picked := String(relic_pool_director.call("pick",catalog,_archive_relic_tier(),combined,context,int(entropy.call("token","relic:%s" % context))))
	return picked if not picked.is_empty() else super.random_relic_id(combined)

func _open_guardian_adaptation() -> void:
	if player.is_empty():
		super._open_guardian_adaptation()
		return
	var lineage_id := String(player["id"])
	var owned: Array = player.get("weapon_evolutions",[])
	pending_adaptations = evolution_director.call("choices",lineage_id,biome_index,int(entropy.call("token","adaptation:%d" % biome_index)),owned)
	if pending_adaptations.size() < 2:
		super._open_guardian_adaptation()
		return
	choice_open = true
	choice_index = 0
	choice_context = "genome_adaptation"
	choice_options.clear()
	for definition in pending_adaptations:
		choice_options.append(String(definition.get("name","GENOME ADAPTATION")))
	boss_health = 0.0
	boss_max_health = 0.0
	objective = "Choose an unstable lineage adaptation before descent"
	player["pos"] = arena_rect().get_center()
	notify("GUARDIAN GENOME DECODED // OUTCOME NOT REPLAYABLE")
	save_suspended_run()

func _rebuild_room_obstacles() -> void:
	room_obstacles.clear()
	if not room_graph.has(current_room):
		return
	var room: Dictionary = room_graph[current_room]
	var kind := String(room.get("kind","combat"))
	if kind in ["start","sanctuary","treasure"]:
		return
	var recipe := _ensure_world_recipe(room)
	var arena := arena_rect()
	var obstacles: Array = recipe.get("obstacles",[])
	if obstacles.is_empty():
		var slots := _obstacle_slots(arena)
		var local_rng: RandomNumberGenerator = entropy.call("fork","cover:%s" % _coord_key(current_room))
		var families: Array = recipe.get("obstacle_families",[])
		var target := mini(int(recipe.get("cover_count",3)),slots.size())
		for index in range(target):
			if slots.is_empty(): break
			var slot_index := local_rng.randi_range(0,slots.size()-1)
			var center := Vector2(slots[slot_index])
			slots.remove_at(slot_index)
			var width := local_rng.randf_range(58.0,126.0)
			var height := local_rng.randf_range(44.0,106.0)
			if index%2 == 1:
				var temp := width; width = height; height = temp
			var rect := Rect2(center-Vector2(width,height)*0.5,Vector2(width,height))
			if _blocks_door_lane(rect,arena): continue
			var family := String(families[index%families.size()]) if not families.is_empty() else "console"
			obstacles.append({
				"u":(rect.position.x-arena.position.x)/maxf(1.0,arena.size.x),
				"v":(rect.position.y-arena.position.y)/maxf(1.0,arena.size.y),
				"w":rect.size.x/maxf(1.0,arena.size.x),
				"h":rect.size.y/maxf(1.0,arena.size.y),
				"kind":family,
				"variant":local_rng.randi_range(0,5),
			})
		recipe["obstacles"] = obstacles
		room["v8_world_recipe"] = recipe
		room_graph[current_room] = room
	for obstacle_variant in obstacles:
		var item: Dictionary = obstacle_variant
		var rect := Rect2(arena.position+Vector2(float(item.get("u",0.2))*arena.size.x,float(item.get("v",0.2))*arena.size.y),Vector2(float(item.get("w",0.08))*arena.size.x,float(item.get("h",0.08))*arena.size.y))
		room_obstacles.append({"rect":rect,"kind":String(item.get("kind","console")),"variant":int(item.get("variant",0))})

func _ensure_world_recipe(room: Dictionary) -> Dictionary:
	var recipe: Dictionary = room.get("v8_world_recipe",{})
	if not recipe.is_empty(): return recipe
	var biome_id := String(BIOMES[biome_index]["id"])
	recipe = world_director.call("make_room_recipe",entropy.call("fork","world:%s" % _coord_key(current_room)),biome_id,String(room.get("kind","combat")),_entropy_threat(),get_viewport_rect().size)
	room["v8_world_recipe"] = recipe
	room_graph[current_room] = room
	return recipe

func draw_arena() -> void:
	super.draw_arena()
	_draw_entropy_environment_overlay()

func _draw_entropy_environment_overlay() -> void:
	if not room_graph.has(current_room): return
	var room: Dictionary = room_graph[current_room]
	var recipe: Dictionary = room.get("v8_world_recipe",{})
	if recipe.is_empty(): return
	var arena := arena_rect()
	var accent := Color(BIOMES[biome_index]["accent"])
	var vegetation := float(recipe.get("vegetation",0.3))
	var ruin := float(recipe.get("ruin",0.3))
	var tech := float(recipe.get("tech",0.5))
	for item_variant in Array(recipe.get("decor",[])):
		var item: Dictionary = item_variant
		var pos := arena.position+Vector2(float(item.get("u",0.5))*arena.size.x,float(item.get("v",0.5))*arena.size.y)
		var size := float(item.get("size",1.0))
		var intensity := float(item.get("intensity",0.5))
		match int(item.get("kind",0)):
			0:
				var length := 15.0+24.0*size
				var angle := float(item.get("rotation",0.0))
				draw_line(pos-Vector2.RIGHT.rotated(angle)*length*0.5,pos+Vector2.RIGHT.rotated(angle)*length*0.5,Color(accent,0.07+ruin*0.09),2.0)
				draw_line(pos,pos+Vector2(8,-11).rotated(angle),Color(0.62,0.67,0.59,0.05+ruin*0.07),1.0)
			1:
				for leaf in range(3+int(vegetation*3.0)):
					var p := pos+Vector2(-7+leaf*5,sin(float(leaf)*1.7)*6.0)
					draw_circle(p,2.0+size*1.5,Color(accent,0.05+vegetation*0.12))
			2:
				draw_circle(pos,10.0+size*12.0,Color(0.02,0.07,0.06,0.03+float(recipe.get("wet",0.0))*0.10))
			3:
				var rect := Rect2(pos-Vector2(10,4)*size,Vector2(20,8)*size)
				draw_rect(rect,Color(accent,0.03+tech*0.08))
				draw_rect(rect,Color(accent,0.10+tech*0.14),false,1.0)
			4:
				for bit in range(3):
					var p := pos+Vector2(bit*5-5,(bit%2)*4)
					draw_rect(Rect2(p,Vector2(3,2)*size),Color(0.38,0.35,0.31,0.07+ruin*0.09))
			_:
				draw_circle(pos,1.5+size,Color(accent.lightened(0.26),0.16+intensity*0.30))

func update_enemy_style(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> Vector2:
	var result: Vector2 = super.update_enemy_style(enemy,direction,distance,delta)
	var genome: Dictionary = enemy.get("v8_visual_genome",{})
	if genome.is_empty(): return result
	var behavior_trait: String = String(genome.get("trait",""))
	var phase: float = visual_clock*2.2+float(genome.get("phase_offset",0.0))
	match behavior_trait:
		"flanker","feint","harrier": result = result.rotated(sin(phase)*0.22)
		"bloodrush","breach":
			if distance < 210.0: result *= 1.12
		"marksman","suppression":
			if distance < 185.0: result *= -0.34
		"spiral","orbit": result = result.rotated(0.18*sin(phase))
		_:
			pass
	return result

func draw_player() -> void:
	if player.is_empty(): return
	var texture := _player_entropy_texture()
	if texture == null:
		super.draw_player(); return
	var genome: Dictionary = player.get("v8_visual_genome",{})
	var pos := Vector2(player["pos"])
	var direction_index := quantize_direction(Vector2(player.get("look",last_aim)))
	var moving := input_move.length_squared() > 0.04
	var frame := posmod(int(visual_clock*(10.0 if moving else 4.0)),4)
	var display := 72.0*float(genome.get("visual_scale",1.0))
	var alpha := 0.42 if invulnerability > 0.0 and int(invulnerability*20.0)%2 == 0 else 1.0
	draw_circle(pos+Vector2(0,17),23.0,Color(0,0,0,0.31))
	var dest := Rect2(pos-Vector2(display*0.5,display*0.68),Vector2(display,display))
	var src := Rect2(Vector2(frame*48,direction_index*48),Vector2(48,48))
	draw_texture_rect_region(texture,dest,src,Color(1,1,1,alpha))
	var aim := Vector2(player.get("aim",last_aim)).normalized()
	if aim.length_squared() > 0.01:
		draw_line(pos+aim*20.0,pos+aim*44.0,Color(0.96,0.86,0.67,0.50),2.0)
		draw_circle(pos+aim*45.0,2.5,Color(0.96,0.86,0.67,0.78))
	if bool(player.get("shield",false)):
		draw_arc(pos,35.0,-PI*0.88,PI*0.88,30,Color8(112,190,247),4.0)

func draw_enemies() -> void:
	var strong := bool(settings.get("strong_telegraphs",true))
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		var pos := Vector2(enemy["pos"])
		var radius := float(enemy.get("radius",18.0))
		var boss := bool(enemy.get("boss",false))
		var genome: Dictionary = enemy.get("v8_visual_genome",{})
		var delay := float(enemy.get("activation_delay",0.0))
		var windup := maxf(float(enemy.get("windup",0.0)),maxf(float(enemy.get("special_windup",0.0)),float(enemy.get("boss_windup",0.0))))
		if windup > 0.0:
			var maximum := maxf(windup,maxf(float(enemy.get("windup_max",0.0)),maxf(float(enemy.get("special_windup_max",0.0)),float(enemy.get("boss_windup_max",0.0)))))
			var progress := clampf(1.0-windup/maxf(0.001,maximum),0.0,1.0)
			var danger := Color(1.0,0.34,0.22,0.92 if strong else 0.62)
			draw_arc(pos,radius+16.0,-PI*0.5,-PI*0.5+TAU*progress,30,danger,4.0 if strong else 2.0)
			var tdir := Vector2(enemy.get("telegraph_dir",enemy.get("look",Vector2.DOWN))).normalized()
			if tdir.length_squared() > 0.1 and String(enemy.get("style","")) in ["charger","ranged","skirmisher"]:
				draw_line(pos+tdir*(radius+5.0),pos+tdir*(190.0 if String(enemy.get("style",""))=="charger" else 128.0),Color(danger,0.23),4.0 if strong else 2.0)
		if delay > 0.0:
			var max_delay := maxf(0.001,float(enemy.get("activation_delay_max",delay)))
			var p := clampf(1.0-delay/max_delay,0.0,1.0)
			var accent := Color(BIOMES[biome_index]["accent"])
			draw_circle(pos,radius*(0.42+p*0.38),Color(accent,0.08+p*0.10))
			draw_arc(pos,radius+12.0,-PI*0.5,-PI*0.5+TAU*p,26,Color(accent,0.78),3.0)
		var texture := _enemy_entropy_texture(enemy)
		var source_size := 96 if boss else 48
		var direction_index := quantize_direction(Vector2(enemy.get("look",Vector2.DOWN)))
		var frame := posmod(int((visual_clock+float(enemy.get("variant",0))*0.17)*9.0),4)
		var scale := float(genome.get("visual_scale",1.0))
		var display := (118.0+radius*0.65)*scale if boss else (56.0+radius*0.75)*scale
		draw_circle(pos+Vector2(0,radius*0.72),radius*0.74,Color(0,0,0,0.30))
		if texture != null:
			var alpha := 0.55+0.45*clampf(1.0-delay/maxf(0.001,float(enemy.get("activation_delay_max",1.0))),0.0,1.0) if delay > 0.0 else 1.0
			var dest := Rect2(pos-Vector2(display*0.5,display*0.66),Vector2(display,display))
			var src := Rect2(Vector2(frame*source_size,direction_index*source_size),Vector2(source_size,source_size))
			draw_texture_rect_region(texture,dest,src,Color(1,1,1,alpha))
		if bool(enemy.get("elite",false)):
			var definition: Dictionary = director.elite_definition(String(enemy.get("affix","armored")))
			var elite_color := Color(definition.get("color",Color8(226,188,102)))
			draw_arc(pos,radius+10.0,visual_clock,visual_clock+PI*1.6,28,elite_color,3.0)
		if float(enemy.get("shield_hp",0.0)) > 0.0:
			draw_arc(pos,radius+6.0,-PI*0.86,PI*0.86,24,Color8(121,171,244),3.0)
		var hp_ratio := clampf(float(enemy.get("hp",1.0))/maxf(0.001,float(enemy.get("max_hp",enemy.get("hp",1.0)))),0.0,1.0)
		if hp_ratio < 0.999 or boss or bool(enemy.get("elite",false)):
			var width := clampf(radius*2.25,38.0,110.0)
			var health := Rect2(pos+Vector2(-width*0.5,radius+14.0),Vector2(width,6.0 if boss else 5.0))
			draw_rect(health,Color8(31,16,18,225))
			draw_rect(Rect2(health.position,Vector2(health.size.x*hp_ratio,health.size.y)),Color8(217,68,59))
			draw_rect(health,Color8(236,196,142,165),false,1.0)
		var status_index := 0
		for status in ["burn","marked","spore","stagger"]:
			if float(enemy.get(status,0.0)) > 0.0:
				var status_color := Color8(226,110,80) if status=="burn" else (Color8(224,86,70) if status=="marked" else (Color8(177,104,207) if status=="spore" else Color8(226,196,105)))
				draw_circle(pos+Vector2(-15.0+status_index*10.0,-radius-10.0),3.2,status_color)
				status_index += 1

func _player_entropy_texture() -> Texture2D:
	if player.is_empty(): return null
	var genome: Dictionary = player.get("v8_visual_genome",{})
	if genome.is_empty(): return null
	var key := "player:"+String(genome.get("visual_signature",player.get("id","player")))
	if _v8_sprite_textures.has(key): return _v8_sprite_textures[key]
	var image: Image = sprite_forge.call("build_player_sheet",genome)
	var texture := ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null
	if texture != null: _v8_sprite_textures[key] = texture
	return texture

func _enemy_entropy_texture(enemy: Dictionary) -> Texture2D:
	var genome: Dictionary = enemy.get("v8_visual_genome",{})
	if genome.is_empty(): return null
	var boss := bool(enemy.get("boss",false))
	var key := ("boss:" if boss else "enemy:")+String(genome.get("visual_signature",enemy.get("id","enemy")))
	if _v8_sprite_textures.has(key): return _v8_sprite_textures[key]
	var image: Image = sprite_forge.call("build_boss_sheet",genome) if boss else sprite_forge.call("build_enemy_sheet",genome)
	var texture := ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null
	if texture != null: _v8_sprite_textures[key] = texture
	return texture

func _entropy_threat() -> float:
	return 1.0+float(biome_index)*0.16+float(floor_number-1)*0.07+float(rooms_cleared)*0.012

func save_suspended_run() -> void:
	super.save_suspended_run()
	if _restoring_entropy or state != "run" or player.is_empty(): return
	var room_recipes: Dictionary = {}
	for coord in room_order:
		if not room_graph.has(coord): continue
		var room: Dictionary = room_graph[coord]
		room_recipes[_coord_key(coord)] = {
			"kind":String(room.get("kind","combat")),
			"modifier":String(room.get("modifier","none")),
			"reward_multiplier":float(room.get("reward_multiplier",1.0)),
			"faction":String(room.get("faction",room.get("rc6_shop_faction",""))),
			"memory_id":String(room.get("memory_id","")),
			"rc6_used":bool(room.get("rc6_used",false)),
			"rc6_rewarded":bool(room.get("rc6_rewarded",false)),
			"world":Dictionary(room.get("v8_world_recipe",{})).duplicate(true),
			"encounter":Dictionary(room.get("v8_encounter_recipe",{})).duplicate(true),
		}
	atomic_json_write(ENTROPY_SUSPEND_PATH,{
		"version":ENTROPY_VERSION,
		"seed":run_seed,
		"floor_entropy":_floor_entropy,
		"session":_entropy_session,
		"player_genome":Dictionary(player.get("v8_visual_genome",{})).duplicate(true),
		"rooms":room_recipes,
	})

func restore_suspended_run() -> void:
	var data := read_json_with_backup(ENTROPY_SUSPEND_PATH)
	_restore_floor_entropy = int(data.get("floor_entropy",0))
	_restore_room_recipes = Dictionary(data.get("rooms",{})).duplicate(true)
	_restore_player_genome = Dictionary(data.get("player_genome",{})).duplicate(true)
	_entropy_session = String(data.get("session",""))
	_restoring_entropy = true
	super.restore_suspended_run()
	_restoring_entropy = false
	if state == "run" and not player.is_empty() and not _restore_player_genome.is_empty():
		player["v8_visual_genome"] = _restore_player_genome.duplicate(true)
	_v8_sprite_textures.clear()
	_restore_room_recipes.clear()
	_restore_player_genome.clear()
	_restore_floor_entropy = 0

func _apply_saved_room_recipes() -> void:
	for key_variant in _restore_room_recipes.keys():
		var coord := _coord_from_key(String(key_variant))
		if not room_graph.has(coord): continue
		var saved: Dictionary = _restore_room_recipes[key_variant]
		var room: Dictionary = room_graph[coord]
		for field in ["kind","modifier","reward_multiplier","memory_id","rc6_used","rc6_rewarded"]:
			if saved.has(field): room[field] = saved[field]
		var faction := String(saved.get("faction",""))
		if not faction.is_empty():
			if String(room.get("kind","")) == "shop": room["rc6_shop_faction"] = faction
			else: room["faction"] = faction
		if saved.has("world") and not Dictionary(saved["world"]).is_empty(): room["v8_world_recipe"] = Dictionary(saved["world"]).duplicate(true)
		if saved.has("encounter") and not Dictionary(saved["encounter"]).is_empty(): room["v8_encounter_recipe"] = Dictionary(saved["encounter"]).duplicate(true)
		room_graph[coord] = room

func finish_run(victory: bool) -> void:
	var was_running := state == "run"
	super.finish_run(victory)
	if was_running:
		for path in [ENTROPY_SUSPEND_PATH,ENTROPY_SUSPEND_PATH+".bak",ENTROPY_SUSPEND_PATH+".tmp"]:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func _coord_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x,coord.y]

func _coord_from_key(value: String) -> Vector2i:
	var parts := value.split(",")
	if parts.size() != 2: return Vector2i.ZERO
	return Vector2i(int(parts[0]),int(parts[1]))

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["entropy_version"] = ENTROPY_VERSION
	report["entropy_session"] = _entropy_session
	report["floor_entropy"] = _floor_entropy
	report["procedural_sprite_cache"] = _v8_sprite_textures.size()
	report["entropy"] = entropy.call("audit_contract")
	report["enemy_genomes"] = genome_director.call("audit_contract")
	report["sprite_forge"] = sprite_forge.call("audit_contract")
	report["world_generator"] = world_director.call("audit_contract")
	return report

func audit_entropy_contract() -> Dictionary:
	return {
		"version":ENTROPY_VERSION,
		"fixed_seed_replay":false,
		"fresh_floor_entropy":true,
		"stochastic_special_rooms":true,
		"stochastic_encounters":true,
		"stochastic_relics":true,
		"stochastic_adaptations":true,
		"per_instance_enemy_genomes":true,
		"procedural_actor_sheets":true,
		"procedural_room_recipes":true,
		"suspend_preserves_generated_recipe":true,
		"eight_direction_generated_sprites":true,
	}

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["version"] = ENTROPY_VERSION
	report["entropy_generation"] = true
	report["fixed_seed_replay"] = false
	report["per_instance_enemy_genomes"] = true
	report["procedural_actor_sheets"] = true
	report["procedural_room_recipes"] = true
	report["stochastic_encounters"] = true
	report["suspend_preserves_generated_recipe"] = true
	return report
