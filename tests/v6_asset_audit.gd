extends SceneTree

const RegistryScript: Script = preload("res://scripts/v6/asset_registry.gd")

func _init() -> void:
	var registry: RefCounted = RegistryScript.new()
	var report: Dictionary = registry.call("validate_contract")
	print("EDEN_FALL_V6_ASSET_REPORT=" + JSON.stringify(report))
	var errors: Array = report.get("errors", [])
	if not bool(report.get("passed", false)) or not errors.is_empty():
		for error in errors:
			push_error(String(error))
		quit(1)
		return
	var runtime: Script = load("res://scripts/edenfall_v6.gd")
	if runtime == null:
		push_error("v0.6 runtime failed to load")
		quit(2)
		return
	var main_scene: PackedScene = load("res://main.tscn")
	if main_scene == null:
		push_error("Main scene failed to load")
		quit(3)
		return
	var instance := main_scene.instantiate()
	if instance == null:
		push_error("Main scene failed to instantiate")
		quit(4)
		return
	instance.free()
	print("EDEN_FALL_V6_ASSET_AUDIT=PASS")
	quit(0)
