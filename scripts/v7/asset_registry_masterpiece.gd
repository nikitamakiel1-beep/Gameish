extends "res://scripts/v6/asset_registry_rebuild.gd"

const ART_REVISION := "0.6.1-rc7"
const MasterpieceFactoryScript: Script = preload("res://scripts/v7/generated_asset_factory_masterpiece.gd")

func _init() -> void:
	factory = MasterpieceFactoryScript.new()
	textures.clear()
	audio.clear()

func index() -> Dictionary:
	var result: Dictionary = super.index()
	result["art_revision"] = ART_REVISION
	result["pixel_finish"] = ["hard silhouette outline", "selective rim light", "material value variation"]
	result["biome_audio_retention"] = true
	return result

func _retain_biome(active: String) -> void:
	for value in textures.keys():
		var key := String(value)
		if key.begins_with("biome:") and not key.begins_with("biome:%s:" % active):
			textures.erase(value)
			_used.erase(key)

func trim_runtime_cache(active_biome: String, active_enemies: Array[String], active_boss: String) -> void:
	var keep: Dictionary = {}
	for enemy_id in active_enemies:
		keep[String(ALIASES.get(enemy_id, enemy_id))] = true
	for value in textures.keys():
		var key := String(value)
		if key.begins_with("biome:") and not key.begins_with("biome:%s:" % active_biome):
			textures.erase(value)
			_used.erase(key)
		elif key.begins_with("enemy:") and not keep.has(key.trim_prefix("enemy:")):
			textures.erase(value)
			_used.erase(key)
		elif key.begins_with("boss:") and key != "boss:" + active_boss:
			textures.erase(value)
			_used.erase(key)
	_prune()
