extends "res://scripts/v6/generated_asset_registry.gd"

const MAX_ENEMY_SHEETS := 8
const MAX_BOSS_SHEETS := 1

var _clock := 0
var _used: Dictionary = {}

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
	_evict("enemy:", MAX_ENEMY_SHEETS, cache_key)
	return texture

func boss_sheet(id: String) -> Texture2D:
	var canonical := String(ALIASES.get(id.to_lower(), id.to_lower()))
	var cache_key := "boss:" + canonical
	var texture := super.boss_sheet(canonical)
	_touch(cache_key)
	_evict("boss:", MAX_BOSS_SHEETS, cache_key)
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

func clear_transient_cache() -> void:
	for value in textures.keys():
		var key := String(value)
		if key.begins_with("enemy:") or key.begins_with("boss:") or key.begins_with("biome:"):
			textures.erase(value)
			_used.erase(key)
	for value in audio.keys():
		if String(value).begins_with("audio:"):
			audio.erase(value)
	_prune()

func clear_caches() -> void:
	super.clear_caches()
	_used.clear()
	_clock = 0

func trim_runtime_cache(active_biome: String, active_enemies: Array[String], active_boss: String) -> void:
	super.trim_runtime_cache(active_biome, active_enemies, active_boss)
	_prune()

func cache_report() -> Dictionary:
	var report := super.cache_report()
	report["enemy_budget"] = MAX_ENEMY_SHEETS
	report["boss_budget"] = MAX_BOSS_SHEETS
	report["tracked_usage"] = _used.size()
	return report

func _touch(key: String) -> void:
	_clock += 1
	_used[key] = _clock

func _retain_biome(active: String) -> void:
	for value in textures.keys():
		var key := String(value)
		if key.begins_with("biome:") and not key.begins_with("biome:%s:" % active):
			textures.erase(value)
			_used.erase(key)
	for value in audio.keys():
		var key := String(value)
		if key.begins_with("audio:") and not key.begins_with("audio:%s:" % active):
			audio.erase(value)

func _evict(prefix: String, limit: int, protected: String) -> void:
	var matching: Array[String] = []
	for value in textures.keys():
		var key := String(value)
		if key.begins_with(prefix):
			matching.append(key)
	while matching.size() > limit:
		var victim := ""
		var oldest := 9223372036854775807
		for key in matching:
			if key == protected:
				continue
			var used := int(_used.get(key, 0))
			if used < oldest:
				oldest = used
				victim = key
		if victim.is_empty():
			break
		textures.erase(victim)
		_used.erase(victim)
		matching.erase(victim)

func _prune() -> void:
	for value in _used.keys():
		if not textures.has(value):
			_used.erase(value)
