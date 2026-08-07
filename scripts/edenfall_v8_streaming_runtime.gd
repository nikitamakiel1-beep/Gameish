extends "res://scripts/edenfall_v8_visual_runtime.gd"

const V8_STREAMING_VERSION := "0.6.2-entropy"
const MAX_ROOM_ACTOR_TEXTURES := 12
const FORGE_INTERVAL_DESKTOP := 0.012
const FORGE_INTERVAL_WEB := 0.028
const FORGE_INTERVAL_MOBILE := 0.036

var _forge_queue: Array[Dictionary] = []
var _forge_queued: Dictionary = {}
var _forge_clock := 0.0
var _forge_generated := 0
var _forge_discarded := 0

func start_new_run(lineage_index: int, seed_override: int = 0) -> void:
	_clear_forge_queue()
	super.start_new_run(lineage_index,seed_override)

func enter_room(coord: Vector2i, movement_direction: Vector2i) -> void:
	# Old-room per-instance enemy textures have no value after a room transition.
	# Player art is retained and the current room is rebuilt/streamed independently.
	_prune_actor_texture_cache(true)
	_clear_forge_queue()
	super.enter_room(coord,movement_direction)
	_prime_current_room_forge_queue()

func spawn_enemy(id: String, position: Vector2, variant: int = 0) -> void:
	super.spawn_enemy(id,position,variant)
	if enemies.is_empty():
		return
	var index := enemies.size()-1
	var enemy: Dictionary = enemies[index]
	var key := _enemy_visual_cache_key(enemy)
	if key.is_empty():
		enemies[index] = enemy
		return
	if not _v8_sprite_textures.has(key):
		enemy["visual_pending"] = true
		enemy["activation_delay"] = maxf(float(enemy.get("activation_delay",0.0)),0.46+float(index%4)*0.07)
		enemy["activation_delay_max"] = maxf(float(enemy.get("activation_delay_max",0.0)),float(enemy["activation_delay"]))
		_queue_enemy_forge(enemy,0 if bool(enemy.get("boss",false)) else 10+index)
	else:
		enemy["visual_pending"] = false
	enemies[index] = enemy

func _process(delta: float) -> void:
	_forge_clock = maxf(0.0,_forge_clock-delta)
	if _forge_clock <= 0.0 and not _forge_queue.is_empty():
		_forge_one()
	super._process(delta)

func update_enemy_style(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> Vector2:
	if bool(enemy.get("visual_pending",false)):
		enemy["velocity"] = Vector2.ZERO
		enemy["attack"] = maxf(float(enemy.get("attack",0.0)),0.12)
		return Vector2.ZERO
	return super.update_enemy_style(enemy,direction,distance,delta)

func update_boss(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> Vector2:
	if bool(enemy.get("visual_pending",false)):
		enemy["velocity"] = Vector2.ZERO
		enemy["attack"] = maxf(float(enemy.get("attack",0.0)),0.16)
		return Vector2.ZERO
	return super.update_boss(enemy,direction,distance,delta)

func _enemy_entropy_texture(enemy: Dictionary) -> Texture2D:
	var key := _enemy_visual_cache_key(enemy)
	if key.is_empty():
		return null
	if _v8_sprite_textures.has(key):
		return _v8_sprite_textures[key] as Texture2D
	_queue_enemy_forge(enemy,0 if bool(enemy.get("boss",false)) else 20)
	return null

func _enemy_visual_cache_key(enemy: Dictionary) -> String:
	var genome: Dictionary = enemy.get("v8_visual_genome",{})
	if genome.is_empty():
		return ""
	var prefix := "boss:" if bool(enemy.get("boss",false)) else "enemy:"
	return prefix+String(genome.get("visual_signature",enemy.get("visual_key",enemy.get("id","enemy"))))

func _queue_enemy_forge(enemy: Dictionary, priority: int) -> void:
	var key := _enemy_visual_cache_key(enemy)
	if key.is_empty() or _v8_sprite_textures.has(key) or _forge_queued.has(key):
		return
	var genome: Dictionary = enemy.get("v8_visual_genome",{})
	if genome.is_empty():
		return
	_forge_queued[key] = true
	_forge_queue.append({
		"key":key,
		"genome":genome.duplicate(true),
		"boss":bool(enemy.get("boss",false)),
		"priority":priority,
	})
	_forge_queue.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a.get("priority",20)) < int(b.get("priority",20)))

func _prime_current_room_forge_queue() -> void:
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		var key := _enemy_visual_cache_key(enemy)
		if key.is_empty() or _v8_sprite_textures.has(key):
			continue
		enemy["visual_pending"] = true
		enemy["activation_delay"] = maxf(float(enemy.get("activation_delay",0.0)),0.40+float(index%4)*0.06)
		enemy["activation_delay_max"] = maxf(float(enemy.get("activation_delay_max",0.0)),float(enemy["activation_delay"]))
		enemies[index] = enemy
		_queue_enemy_forge(enemy,0 if bool(enemy.get("boss",false)) else 10+index)

func _forge_one() -> void:
	if _forge_queue.is_empty():
		return
	var entry: Dictionary = _forge_queue.pop_front()
	var key := String(entry.get("key",""))
	_forge_queued.erase(key)
	if key.is_empty() or _v8_sprite_textures.has(key):
		_forge_clock = _forge_interval()
		return
	if not _visual_key_is_live(key):
		_forge_discarded += 1
		_forge_clock = _forge_interval()
		return
	var genome: Dictionary = entry.get("genome",{})
	var boss := bool(entry.get("boss",false))
	var image: Image = sprite_forge.call("build_boss_sheet",genome) if boss else sprite_forge.call("build_enemy_sheet",genome)
	if image != null and not image.is_empty():
		var texture := ImageTexture.create_from_image(image)
		if texture != null:
			_v8_sprite_textures[key] = texture
			_forge_generated += 1
			_mark_visual_ready(key)
			_prune_actor_texture_cache(false)
	_forge_clock = _forge_interval()

func _visual_key_is_live(key: String) -> bool:
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		if _enemy_visual_cache_key(enemy) == key:
			return true
	return false

func _mark_visual_ready(key: String) -> void:
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		if _enemy_visual_cache_key(enemy) != key:
			continue
		enemy["visual_pending"] = false
		enemy["activation_delay"] = maxf(float(enemy.get("activation_delay",0.0)),0.18)
		enemy["activation_delay_max"] = maxf(float(enemy.get("activation_delay_max",0.0)),float(enemy["activation_delay"]))
		enemies[index] = enemy

func _forge_interval() -> float:
	if OS.has_feature("mobile"):
		return FORGE_INTERVAL_MOBILE
	if OS.has_feature("web"):
		return FORGE_INTERVAL_WEB
	return FORGE_INTERVAL_DESKTOP

func _prune_actor_texture_cache(transition: bool) -> void:
	var keep: Dictionary = {}
	if not player.is_empty():
		var player_genome: Dictionary = player.get("v8_visual_genome",{})
		if not player_genome.is_empty():
			keep["player:"+String(player_genome.get("visual_signature",player.get("id","player")))] = true
	if not transition:
		for enemy_variant in enemies:
			var enemy: Dictionary = enemy_variant
			var key := _enemy_visual_cache_key(enemy)
			if not key.is_empty():
				keep[key] = true
	var removable: Array[String] = []
	for key_variant in _v8_sprite_textures.keys():
		var key := String(key_variant)
		if key.begins_with("player:"):
			continue
		if not keep.has(key):
			removable.append(key)
	for key in removable:
		_v8_sprite_textures.erase(key)
	if _v8_sprite_textures.size() <= MAX_ROOM_ACTOR_TEXTURES+1:
		return
	# Normally the live-room set is below the cap. This defensive branch removes
	# only non-live actor sheets and never evicts a currently drawn enemy.
	for key_variant in _v8_sprite_textures.keys():
		if _v8_sprite_textures.size() <= MAX_ROOM_ACTOR_TEXTURES+1:
			break
		var key := String(key_variant)
		if not key.begins_with("player:") and not keep.has(key):
			_v8_sprite_textures.erase(key)

func _clear_forge_queue() -> void:
	_forge_queue.clear()
	_forge_queued.clear()
	_forge_clock = 0.0

func restore_suspended_run() -> void:
	_clear_forge_queue()
	super.restore_suspended_run()
	_prime_current_room_forge_queue()

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["v8_streaming_version"] = V8_STREAMING_VERSION
	report["forge_pending"] = _forge_queue.size()
	report["forge_generated"] = _forge_generated
	report["forge_discarded"] = _forge_discarded
	report["actor_texture_cache"] = _v8_sprite_textures.size()
	report["actor_texture_budget"] = MAX_ROOM_ACTOR_TEXTURES+1
	return report

func audit_entropy_contract() -> Dictionary:
	var report: Dictionary = super.audit_entropy_contract()
	report["version"] = V8_STREAMING_VERSION
	report["queued_sprite_forge"] = true
	report["one_forge_job_per_tick"] = true
	report["visual_pending_blocks_ai"] = true
	report["room_scoped_sprite_cache"] = true
	report["max_room_actor_textures"] = MAX_ROOM_ACTOR_TEXTURES
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["queued_sprite_forge"] = true
	report["room_scoped_sprite_cache"] = true
	return report
