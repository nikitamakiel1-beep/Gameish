extends "res://scripts/v6/generated_asset_registry.gd"

const MAX_ENEMY_SHEETS := 8
const MAX_BOSS_SHEETS := 1

var _usage_clock := 0
var _last_used: Dictionary = {}

func hero_sheet(id: String) -> Texture2D:
	var texture := super.hero_sheet(id)
	_touch("hero:" + id.to_lower())
	return texture

func hero_portrait(id: String) -> Texture2D:
	var texture := super.hero_portrait(id)
	_touch("portrait:" + id.to_lower())
	return texture

func enemy_sheet(id: String) -> Texture2D:
	var canonical := String(ALIASES.get(id.to_lower(), id.to_lower()))
	var cache_key := "enemy:" + canonical
	var texture := super.enemy_sheet(canonical)
	_touch(cache_key)
	_evict_lru("enemy:", MAX_ENEMY_SHEETS, cache_key)
	return texture

func boss_sheet(id: String) -> Texture2D:
	var canonical := String(ALIASES.get(id.to_lower(), id.to_lower()))
	var cache_key := "boss:" + canonical
	var texture := super.boss_sheet(canonical)
	_touch(cache_key)
	_evict_lru("boss:", MAX_BOSS_SHEETS, cache_key)
	return texture

func biome_texture(id: String, kind: String) -> Texture2D:
	var canonical := id.to_lower()
	_retain_biome(canonical)
	var cache_key := "biome:%s:%s" % [canonical, kind]
	var texture := super.biome_texture(canonical, kind)
	_touch(cache_key)
	return texture

func utility_texture(id: String) -> Texture2D:
	var texture := super.utility_texture(id)
	_touch("utility:" + id)
	return texture

func validate_contract(deep: bool = false) -> Dictionary:
	return super.validate_contract(deep)

func clear_caches() -> void:
	super.clear_caches()
	_last_used.clear()
	_usage_clock = 0

func trim_runtime_cache(active_biome: String, active_enemies: Array, active_boss: String) -> void:
	super.trim_runtime_cache(active_biome, _string_array(active_enemies), active_boss)
	_prune_usage_index()

func cache_report() -> Dictionary:
	var report: Dictionary = super.cache_report()
	report["enemy_budget"] = MAX_ENEMY_SHEETS
	report["boss_budget"] = MAX_BOSS_SHEETS
	report["tracked_usage"] = _last_used.size()
	return report

func _touch(cache_key: String) -> void:
	_usage_clock += 1
	_last_used[cache_key] = _usage_clock

func _retain_biome(active_biome: String) -> void:
	for key_variant in textures.keys():
		var key := String(key_variant)
		if key.begins_with("biome:") and not key.begins_with("biome:%s:" % active_biome):
			textures.erase(key_variant)
			_last_used.erase(key)
	for key_variant in audio.keys():
		var key := String(key_variant)
		if key.begins_with("audio:") and not key.begins_with("audio:%s:" % active_biome):
			audio.erase(key_variant)

func _evict_lru(prefix: String, limit: int, protected_key: String) -> void:
	var matching: Array[String] = []
	for key_variant in textures.keys():
		var key := String(key_variant)
		if key.begins_with(prefix):
			matching.append(key)
	while matching.size() > limit:
		var victim := ""
		var oldest := 9223372036854775807
		for key in matching:
			if key == protected_key:
				continue
			var used := int(_last_used.get(key, 0))
			if used < oldest:
				oldest = used
				victim = key
		if victim.is_empty():
			break
		textures.erase(victim)
		_last_used.erase(victim)
		matching.erase(victim)

func _prune_usage_index() -> void:
	for key_variant in _last_used.keys():
		var key := String(key_variant)
		if not textures.has(key):
			_last_used.erase(key_variant)

func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result
