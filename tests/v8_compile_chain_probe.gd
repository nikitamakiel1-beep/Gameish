extends SceneTree

const CHAIN: Array[String] = [
	"res://scripts/v7/actor_asset_factory_masterpiece.gd",
	"res://scripts/v7/audio_asset_factory_masterpiece.gd",
	"res://scripts/v7/generated_asset_factory_masterpiece.gd",
	"res://scripts/v7/asset_registry_masterpiece.gd",
	"res://scripts/v7/sprite_quality_evaluator.gd",
	"res://scripts/v8/enemy_genome_director.gd",
	"res://scripts/v8/procedural_sprite_forge.gd",
	"res://scripts/v8/procedural_sprite_forge_premium.gd",
	"res://scripts/v8/procedural_world_director.gd",
	"res://scripts/edenfall_v7_release_runtime.gd",
	"res://scripts/edenfall_v8_entropy_runtime.gd",
	"res://scripts/edenfall_v8_visual_runtime.gd",
	"res://scripts/edenfall_v8_streaming_runtime.gd",
	"res://scripts/edenfall_v8_release_runtime.gd",
]

func _init() -> void:
	var failed: Array[String] = []
	for path: String in CHAIN:
		var script: Script = load(path) as Script
		if script == null:
			failed.append(path)
			push_error("EDEN_COMPILE_CHAIN_FAIL=" + path)
			break
		print("EDEN_COMPILE_CHAIN_PASS=" + path)
	if failed.is_empty():
		print("EDEN_COMPILE_CHAIN=PASS")
		quit(0)
	else:
		print("EDEN_COMPILE_CHAIN=FAIL")
		quit(1)
