extends SceneTree

const RUNTIME_PATH := "res://scripts/edenfall_v5.gd"
const PLATFORM_PATH := "res://scripts/v5/platform_profile.gd"
const UI_PATH := "res://scripts/v5/ui_system.gd"
const SAVE_PATH := "res://scripts/v5/save_repository.gd"
const BUILD_PATH := "res://scripts/v5/build_matrix.gd"

var failures: Array[String] = []

func _init() -> void:
	validate_project()
	validate_modules()
	validate_runtime()
	validate_export_matrix()
	if failures.is_empty():
		print("EDEN//FALL v5 audit passed: Godot 4.7.1, responsive UI, platform services, persistence and seven export profiles")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("EDEN//FALL v5 audit failed with %d issue(s)" % failures.size())
		quit(1)

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func validate_project() -> void:
	var project_text := FileAccess.get_file_as_string("res://project.godot")
	expect(project_text.contains("config/version=\"0.5.0\""), "Project version is not v0.5.0")
	expect(project_text.contains("PackedStringArray(\"4.7\""), "Project feature contract is not Godot 4.7")
	expect(project_text.contains("renderer/rendering_method.web=\"gl_compatibility\""), "Web compatibility renderer is not explicit")
	var scene_text := FileAccess.get_file_as_string("res://main.tscn")
	expect(scene_text.contains("scripts/edenfall_v5.gd"), "Main scene does not load the v5 runtime")

func validate_modules() -> void:
	for path in [PLATFORM_PATH, UI_PATH, SAVE_PATH, BUILD_PATH]:
		expect(ResourceLoader.exists(path), "Missing v5 module: %s" % path)
	var platform = load(PLATFORM_PATH).new()
	var report: Dictionary = platform.capability_report(Vector2(1280, 720))
	expect(Array(report.get("targets", [])).size() == 6, "Platform service must expose six target families")
	expect(platform.device_class(Vector2(390, 844)) == "phone", "Phone breakpoint failed")
	expect(platform.device_class(Vector2(1024, 1366)) == "tablet", "Tablet breakpoint failed")
	expect(platform.device_class(Vector2(1920, 1080)) == "desktop", "Desktop breakpoint failed")
	var ui = load(UI_PATH).new()
	var ui_contract: Dictionary = ui.audit_contract()
	expect(int(ui_contract.get("version", 0)) == 5, "UI contract version mismatch")
	expect(ui.title_grid(Rect2(Vector2.ZERO, Vector2(1280, 720)), 6).size() == 6, "Title grid is incomplete")
	expect(ui.lineage_grid(Rect2(Vector2.ZERO, Vector2(390, 844)), 5).size() == 5, "Phone lineage grid is incomplete")
	expect(ui.settings_grid(Rect2(Vector2.ZERO, Vector2(1280, 720)), 20).size() == 20, "Settings grid is incomplete")
	var save = load(SAVE_PATH).new()
	var save_contract: Dictionary = save.audit_contract()
	expect(bool(save_contract.get("atomic_write", false)), "Atomic persistence contract missing")
	var audit_path := "user://edenfall_v5_repository_audit.json"
	expect(save.write_json_atomic(audit_path, {"probe":47}), "Atomic write probe failed")
	expect(int(save.read_json(audit_path, {}).get("probe", 0)) == 47, "Atomic read probe failed")
	save.remove_with_backup(audit_path)
	var build = load(BUILD_PATH).new()
	var build_contract: Dictionary = build.audit_contract()
	expect(String(build_contract.get("godot", "")) == "4.7.1", "Build matrix Godot version mismatch")
	expect(int(build_contract.get("presets", 0)) == 7, "Expected seven export presets")
	expect(Array(build_contract.get("platforms", [])).size() == 6, "Expected six platform families")

func validate_runtime() -> void:
	expect(ResourceLoader.exists(RUNTIME_PATH), "Missing v5 runtime")
	if not ResourceLoader.exists(RUNTIME_PATH):
		return
	var script: Script = load(RUNTIME_PATH) as Script
	expect(script != null, "Could not parse v5 runtime")
	if script == null:
		return
	var runtime: Node2D = script.new() as Node2D
	expect(runtime != null, "Could not instantiate v5 runtime")
	if runtime == null:
		return
	expect(runtime.quantize_direction(Vector2.UP) == 0, "Inherited north direction contract failed")
	expect(runtime.quantize_direction(Vector2.DOWN) == 4, "Inherited south direction contract failed")
	expect(runtime.directional_row("attack", 4) == 20, "Inherited south attack row failed")
	expect(runtime.relic_catalog().size() == 60, "Relic catalog regression")
	expect(runtime.settings_rows().size() >= 20, "v5 settings are incomplete")
	expect(runtime.audit_v5_readiness() >= 90.0, "v5 readiness contract is below 90 percent")
	runtime.free()

func validate_export_matrix() -> void:
	expect(FileAccess.file_exists("res://export_presets.cfg"), "Export preset file missing")
	var text := FileAccess.get_file_as_string("res://export_presets.cfg")
	for preset in ["Windows Desktop", "Linux X11", "macOS Universal", "Web", "Android APK", "Android AAB", "iOS Xcode"]:
		expect(text.contains("name=\"%s\"" % preset), "Missing export preset: %s" % preset)
	expect(text.contains("package/unique_name=\"com.gameish.edenfall\""), "Android package identifier missing")
	expect(text.contains("application/bundle_identifier=\"com.gameish.edenfall\""), "Apple bundle identifier missing")
	expect(FileAccess.file_exists("res://docs/MULTIPLATFORM_V5.md"), "Multiplatform documentation missing")
