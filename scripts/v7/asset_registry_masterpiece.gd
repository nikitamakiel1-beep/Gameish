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
	return result
