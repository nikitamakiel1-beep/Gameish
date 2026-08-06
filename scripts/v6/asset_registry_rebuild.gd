extends "res://scripts/v6/runtime_asset_registry.gd"

const VISUAL_VERSION := "0.6.1"
const RebuildFactoryScript: Script = preload("res://scripts/v6/generated_asset_factory_rebuild.gd")

func _init() -> void:
	factory = RebuildFactoryScript.new()
	textures.clear()
	audio.clear()

func index() -> Dictionary:
	var result: Dictionary = super.index()
	result["visual_version"] = VISUAL_VERSION
	result["visual_direction"] = "Overgrown laboratory to reclaimed apocalyptic cities; atlas IDs and lore contract preserved."
	result["reference_principles"] = [
		"instant twin-stick readability",
		"telegraphed bullet-hell combat",
		"strong grotesque biblical silhouettes",
		"nature reclaiming ancient industrial ruins",
	]
	return result
