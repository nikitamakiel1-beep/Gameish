extends SceneTree

const CHAIN: Array[String] = [
	"res://scripts/v7/actor_asset_factory_masterpiece.gd",
	"res://scripts/v7/audio_asset_factory_masterpiece.gd",
	"res://scripts/v7/generated_asset_factory_masterpiece.gd",
	"res://scripts/v7/asset_registry_masterpiece.gd",
	"res://scripts/v7/sprite_quality_evaluator.gd",
	"res://scripts/v8/enemy_genome_director.gd",
	"res://scripts/v8/hero_identity_director.gd",
	"res://scripts/v8/enemy_genome_director_art3.gd",
	"res://scripts/v8/procedural_sprite_forge_stable.gd",
	"res://scripts/v8/procedural_sprite_forge.gd",
	"res://scripts/v8/procedural_sprite_forge_authored.gd",
	"res://scripts/v8/procedural_sprite_forge_premium.gd",
	"res://scripts/v8/procedural_sprite_forge_roguelike.gd",
	"res://scripts/v8/procedural_world_director.gd",
	"res://scripts/v8/procedural_world_director_art3.gd",
	"res://scripts/edenfall_v7_release_runtime.gd",
	"res://scripts/edenfall_v8_entropy_runtime.gd",
	"res://scripts/edenfall_v8_visual_runtime.gd",
	"res://scripts/edenfall_v8_streaming_runtime.gd",
	"res://scripts/edenfall_v8_art_direction_runtime.gd",
	"res://scripts/edenfall_v8_art_integrated_runtime.gd",
	"res://scripts/edenfall_v8_authored_presentation_runtime.gd",
	"res://scripts/edenfall_v8_release_runtime.gd",
]

func _init() -> void:
	var failed: Array[String] = []
	for path: String in CHAIN:
		var script: Script = load(path) as Script
		if script == null:
			failed.append(path)
			push_error("EDEN_COMPILE_CHAIN_FAIL=load:"+path)
			break
		if not script.can_instantiate():
			failed.append(path)
			push_error("EDEN_COMPILE_CHAIN_FAIL=not_instantiable:"+path)
			break
		print("EDEN_COMPILE_CHAIN_PASS="+path)
	if failed.is_empty():
		var factory_script: Script = load("res://scripts/v7/generated_asset_factory_masterpiece.gd") as Script
		var factory: RefCounted = factory_script.new() as RefCounted
		if factory == null:
			failed.append("res://scripts/v7/generated_asset_factory_masterpiece.gd")
			push_error("EDEN_COMPILE_CHAIN_FAIL=factory_instance")
		else:
			var contract: Dictionary = factory.call("audit_contract")
			if not bool(contract.get("actor_factory_ready",false)) or not bool(contract.get("support_factory_ready",false)) or not bool(contract.get("audio_factory_ready",false)):
				failed.append("res://scripts/v7/generated_asset_factory_masterpiece.gd")
				push_error("EDEN_COMPILE_CHAIN_FAIL=factory_dependencies:"+JSON.stringify(contract))
			else:
				print("EDEN_FACTORY_CHAIN_PASS="+JSON.stringify(contract))
	if failed.is_empty():
		print("EDEN_COMPILE_CHAIN=PASS")
		quit(0)
	else:
		print("EDEN_COMPILE_CHAIN=FAIL")
		quit(1)
