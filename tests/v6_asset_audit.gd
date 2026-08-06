extends SceneTree

const RegistryScript: Script = preload("res://scripts/v6/asset_registry.gd")
const REQUIRED_INPUTS := [
	"move_up", "move_down", "move_left", "move_right",
	"aim_up", "aim_down", "aim_left", "aim_right",
	"attack", "dash", "interact", "pause", "archive",
]
const REQUIRED_PRESETS := [
	"Windows Desktop", "Linux X11", "macOS Universal", "Web",
	"Android APK", "Android AAB", "iOS Xcode",
]

func _init() -> void:
	call_deferred("_run_audit")

func _run_audit() -> void:
	var errors: Array[String] = []
	var version := Engine.get_version_info()
	if int(version.get("major", -1)) != 4 or int(version.get("minor", -1)) != 7 or int(version.get("patch", -1)) != 1:
		errors.append("Expected Godot 4.7.1 exactly, running %s" % version)

	if String(ProjectSettings.get_setting("application/config/version", "")) != "0.6.0":
		errors.append("application/config/version must be 0.6.0")
	if String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")) != "gl_compatibility":
		errors.append("GL Compatibility must be the default renderer")
	if int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 0)) != 60:
		errors.append("Physics tick rate must be 60 Hz")

	var registry: RefCounted = RegistryScript.new()
	var asset_report: Dictionary = registry.call("validate_contract", true)
	print("EDEN_FALL_V6_ASSET_REPORT=" + JSON.stringify(asset_report))
	if not bool(asset_report.get("passed", false)):
		for error in Array(asset_report.get("errors", [])):
			errors.append(String(error))
	registry.call("clear_caches")

	var runtime: Script = load("res://scripts/edenfall_v6.gd")
	if runtime == null:
		errors.append("v0.6 runtime failed to load")

	var main_scene: PackedScene = load("res://main.tscn")
	if main_scene == null:
		errors.append("Main scene failed to load")
	else:
		var instance := main_scene.instantiate()
		if instance == null:
			errors.append("Main scene failed to instantiate")
		else:
			root.add_child(instance)
			await process_frame
			var script := instance.get_script() as Script
			if script == null or script.resource_path != "res://scripts/edenfall_v6.gd":
				errors.append("main.tscn is not routed to edenfall_v6.gd")
			for action in REQUIRED_INPUTS:
				if not InputMap.has_action(StringName(action)):
					errors.append("Missing runtime input action: %s" % action)
			if instance.has_method("get_v6_diagnostics"):
				print("EDEN_FALL_V6_RUNTIME_REPORT=" + JSON.stringify(instance.call("get_v6_diagnostics")))
			else:
				errors.append("Runtime diagnostics API is missing")
			instance.queue_free()
			await process_frame

	var presets_file := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	if presets_file == null:
		errors.append("export_presets.cfg is missing")
	else:
		var presets_text := presets_file.get_as_text()
		if presets_text.find("v0.6.0") < 0:
			errors.append("Export matrix is not versioned as v0.6.0")
		for preset in REQUIRED_PRESETS:
			if presets_text.find("name=\"%s\"" % preset) < 0:
				errors.append("Missing export preset: %s" % preset)

	if not errors.is_empty():
		for error in errors:
			push_error(error)
		print("EDEN_FALL_V6_ASSET_AUDIT=FAIL")
		quit(1)
		return

	print("EDEN_FALL_V6_ASSET_AUDIT=PASS")
	quit(0)
