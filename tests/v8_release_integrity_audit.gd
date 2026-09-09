extends SceneTree

const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const VersionManifestScript: Script = preload("res://scripts/v8/version_manifest.gd")

const EXPECTED_PRODUCT_REVISION: String = "0.6.4-authored-art4"
const EXPECTED_APP_VERSION: String = "0.6.4"
const EXPECTED_RELEASE_ROOT: String = "res://scripts/edenfall_v8_release_runtime.gd"
const EXPECTED_FORGE: String = "res://scripts/v8/procedural_sprite_forge_art4.gd"
const EXPECTED_GENOME: String = "res://scripts/v8/enemy_genome_director_art4.gd"
const EXPECTED_WORLD: String = "res://scripts/v8/procedural_world_director_art4.gd"

func _find_web_preset(config: ConfigFile) -> Dictionary:
	for section_variant in config.get_sections():
		var section: String = String(section_variant)
		if not section.begins_with("preset.") or section.ends_with(".options"):
			continue
		if String(config.get_value(section, "name", "")) != "Web":
			continue
		var options_section: String = section + ".options"
		return {
			"section": section,
			"options": options_section,
			"platform": String(config.get_value(section, "platform", "")),
			"features": String(config.get_value(section, "custom_features", "")),
			"path": String(config.get_value(section, "export_path", "")),
			"threads": bool(config.get_value(options_section, "variant/thread_support", true)),
			"pwa": bool(config.get_value(options_section, "progressive_web_app/enabled", true)),
			"head": String(config.get_value(options_section, "html/head_include", "")),
		}
	return {}

func _loadable_script(path: String, errors: Array[String]) -> bool:
	var script: Script = load(path) as Script
	if script == null:
		errors.append("Release dependency failed to load: " + path)
		return false
	if not script.can_instantiate():
		errors.append("Release dependency cannot instantiate: " + path)
		return false
	return true

func _init() -> void:
	var errors: Array[String] = []
	var engine: Dictionary = BootstrapScript.new().call("configure")
	if not bool(engine.get("exact_version", false)):
		errors.append("Exact Godot 4.7.1 is required")

	var manifest: Dictionary = VersionManifestScript.new().call("report")
	if String(manifest.get("product_revision", "")) != EXPECTED_PRODUCT_REVISION:
		errors.append("V8 version manifest is stale")
	if String(manifest.get("godot", "")) != "4.7.1":
		errors.append("V8 version manifest must declare Godot 4.7.1")

	if String(ProjectSettings.get_setting("application/config/version", "")) != EXPECTED_APP_VERSION:
		errors.append("project.godot application version is not " + EXPECTED_APP_VERSION)
	if String(ProjectSettings.get_setting("application/run/main_scene", "")) != "res://main.tscn":
		errors.append("project.godot main scene is not res://main.tscn")
	if String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")) != "gl_compatibility":
		errors.append("Desktop renderer must remain gl_compatibility")
	if String(ProjectSettings.get_setting("rendering/renderer/rendering_method.web", "")) != "gl_compatibility":
		errors.append("Web renderer must remain gl_compatibility")

	for path: String in [EXPECTED_RELEASE_ROOT, EXPECTED_FORGE, EXPECTED_GENOME, EXPECTED_WORLD]:
		_loadable_script(path, errors)

	var scene: PackedScene = load("res://main.tscn") as PackedScene
	var release_binding: Dictionary = {}
	var runtime_contract: Dictionary = {}
	if scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance: Node = scene.instantiate()
		var runtime_script: Script = instance.get_script() as Script
		if runtime_script == null or runtime_script.resource_path != EXPECTED_RELEASE_ROOT:
			errors.append("main.tscn is not bound to the Art4 release root")
		if instance.has_method("audit_release_binding_contract"):
			release_binding = instance.call("audit_release_binding_contract")
			if String(release_binding.get("product_revision", "")) != EXPECTED_PRODUCT_REVISION:
				errors.append("Release binding product revision is stale")
			if String(release_binding.get("sprite_forge_path", "")) != EXPECTED_FORGE:
				errors.append("Release root is not bound to the Art4 sprite forge")
			if String(release_binding.get("genome_director_path", "")) != EXPECTED_GENOME:
				errors.append("Release root is not bound to the Art4 genome director")
			if String(release_binding.get("world_director_path", "")) != EXPECTED_WORLD:
				errors.append("Release root is not bound to the Art4 world director")
			if bool(release_binding.get("legacy_art3_preinstall", true)):
				errors.append("Legacy Art3 pre-install remains enabled in the release root")
		else:
			errors.append("Release binding audit contract is unavailable")
		if instance.has_method("audit_entropy_contract"):
			runtime_contract = instance.call("audit_entropy_contract")
			if String(runtime_contract.get("product_revision", "")) != EXPECTED_PRODUCT_REVISION:
				errors.append("Live release contract product revision is stale")
			if not bool(runtime_contract.get("release_art4_binding", false)):
				errors.append("Live release contract does not assert Art4 binding")
		else:
			errors.append("Live entropy release contract is unavailable")
		instance.free()

	var release_source: String = FileAccess.get_file_as_string(EXPECTED_RELEASE_ROOT)
	for forbidden: String in ["Art3GenomeDirectorScript", "Art3WorldDirectorScript", "RoguelikeSpriteForgeScript.new()"]:
		if release_source.contains(forbidden):
			errors.append("Obsolete Art3 release binding remains in source: " + forbidden)

	var export_config: ConfigFile = ConfigFile.new()
	var export_error: Error = export_config.load("res://export_presets.cfg")
	var web: Dictionary = {}
	if export_error != OK:
		errors.append("export_presets.cfg failed to load: " + error_string(export_error))
	else:
		web = _find_web_preset(export_config)
		if web.is_empty():
			errors.append("Web export preset is missing")
		else:
			if String(web.get("platform", "")) != "Web":
				errors.append("Web preset platform mismatch")
			if String(web.get("path", "")) != "build/web/index.html":
				errors.append("Web export path mismatch")
			if bool(web.get("threads", true)):
				errors.append("GitHub Pages Web preset must remain non-threaded")
			if bool(web.get("pwa", true)):
				errors.append("GitHub Pages Web preset must remain non-PWA")
			var features: String = String(web.get("features", ""))
			for feature: String in ["web", "production_v8", "entropy", "art4", "github_pages_test"]:
				if not features.split(",").has(feature):
					errors.append("Web preset missing custom feature: " + feature)
			if not String(web.get("head", "")).contains(EXPECTED_PRODUCT_REVISION):
				errors.append("Web HTML build marker is stale")

	var report: Dictionary = {
		"revision": EXPECTED_PRODUCT_REVISION,
		"engine": engine,
		"manifest": manifest,
		"release_binding": release_binding,
		"runtime": runtime_contract,
		"web": web,
		"errors": errors,
		"passed": errors.is_empty(),
	}
	print("EDEN_FALL_V8_RELEASE_INTEGRITY_REPORT=" + JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V8_RELEASE_INTEGRITY_AUDIT=PASS")
		quit(0)
	else:
		for message: String in errors:
			push_error(message)
		quit(1)
