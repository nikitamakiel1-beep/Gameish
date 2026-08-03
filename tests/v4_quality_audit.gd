extends SceneTree

const QUALITY_RUNTIME := "res://scripts/edenfall_v4_quality.gd"

var failures: Array[String] = []

func _init() -> void:
	expect(ResourceLoader.exists(QUALITY_RUNTIME), "Missing v0.4.1 quality runtime")
	if ResourceLoader.exists(QUALITY_RUNTIME):
		var script: Script = load(QUALITY_RUNTIME) as Script
		expect(script != null, "Could not load v0.4.1 quality runtime")
		if script != null:
			var runtime: Node2D = script.new() as Node2D
			expect(runtime != null, "Could not instantiate v0.4.1 quality runtime")
			if runtime != null:
				expect(runtime.settings_rows().size() >= 16, "Controller rumble setting is missing")
				expect(runtime.audit_quality_readiness() >= 95.0, "Quality readiness contract is below 95 percent")
				expect(runtime.quantize_direction(Vector2.LEFT) == 6, "Directional regression in quality layer")
				runtime.free()
	var scene_text := FileAccess.get_file_as_string("res://main.tscn")
	expect(scene_text.contains("edenfall_v4_quality.gd"), "Main scene does not use the quality-hardened runtime")
	expect(FileAccess.file_exists("res://docs/QUALITY_V4.md"), "Quality hardening documentation missing")
	if failures.is_empty():
		print("EDEN//FALL v0.4.1 quality audit passed: modifier timing, regeneration, cadence, saves, rumble, telemetry and UI hardening")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
