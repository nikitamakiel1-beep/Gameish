extends SceneTree

const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const FINAL_SCRIPT: String = "res://scripts/edenfall_v8_release_runtime.gd"
const PRESENTATION_SCRIPT: String = "res://scripts/edenfall_v8_authored_presentation_runtime.gd"
const ANIMATION_SCRIPT: String = "res://scripts/edenfall_v8_animation_runtime.gd"

func _init() -> void:
	var errors: Array[String] = []
	var engine: Dictionary = BootstrapScript.new().call("configure")
	if not bool(engine.get("exact_version",false)):
		errors.append("Exact Godot 4.7.1 is required")

	var presentation_source: String = FileAccess.get_file_as_string(PRESENTATION_SCRIPT)
	for symbol_variant in [
		"func draw_title()","func draw_select()","func draw_hud()",
		"hero_first_selection","vertical_title_menu","reduced_ui_chrome","compact_icon_hud",
		"THE FIRST GENOME WAS NEVER HUMAN","EXCURSION BUILD"
	]:
		var symbol: String = String(symbol_variant)
		if presentation_source.find(symbol) < 0:
			errors.append("Authored presentation symbol missing: "+symbol)

	var animation_source: String = FileAccess.get_file_as_string(ANIMATION_SCRIPT)
	for symbol_variant in [
		"_player_authored_frame","_enemy_authored_frame","state_addressed_frames",
		"idle_pose","locomotion_pose","attack_recoil_pose","dash_hurt_pose"
	]:
		var symbol: String = String(symbol_variant)
		if animation_source.find(symbol) < 0:
			errors.append("Authored animation symbol missing: "+symbol)

	var width: int = int(ProjectSettings.get_setting("display/window/size/viewport_width",0))
	var height: int = int(ProjectSettings.get_setting("display/window/size/viewport_height",0))
	var mode: String = String(ProjectSettings.get_setting("display/window/stretch/mode",""))
	var aspect: String = String(ProjectSettings.get_setting("display/window/stretch/aspect",""))
	if Vector2i(width,height) != Vector2i(1280,720):
		errors.append("Art3 browser composition requires a 1280x720 design viewport")
	if mode != "viewport":
		errors.append("Pixel-art presentation requires stretch mode viewport")
	if aspect != "keep":
		errors.append("Pixel-art presentation requires stretch aspect keep")

	var runtime_contract: Dictionary = {}
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	if scene == null:
		errors.append("main.tscn failed to load")
	else:
		var instance: Node = scene.instantiate()
		var script: Script = instance.get_script() as Script
		if script == null or script.resource_path != FINAL_SCRIPT:
			errors.append("main.tscn is not routed through the Art3 release root")
		if instance.has_method("audit_art_direction_contract"):
			runtime_contract = instance.call("audit_art_direction_contract")
			for flag_variant in [
				"authored_lineage_dossier","compact_combat_hud","actor_screen_presence",
				"authored_title_composition","world_surface_integrated","collision_cover_visuals_integrated",
				"hero_first_selection","vertical_title_menu","reduced_ui_chrome","compact_icon_hud",
				"state_addressed_frames","idle_pose","locomotion_pose","attack_recoil_pose","dash_hurt_pose"
			]:
				var flag: String = String(flag_variant)
				if not bool(runtime_contract.get(flag,false)):
					errors.append("Presentation runtime contract missing: "+flag)
		else:
			errors.append("Art-direction/presentation runtime contract unavailable")
		instance.free()

	var report: Dictionary = {
		"product_revision":"0.6.3-art3",
		"engine":engine,
		"viewport":Vector2i(width,height),
		"stretch_mode":mode,
		"stretch_aspect":aspect,
		"runtime":runtime_contract,
		"errors":errors,
		"passed":errors.is_empty(),
	}
	print("EDEN_FALL_V8_PRESENTATION_REPORT="+JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V8_PRESENTATION_AUDIT=PASS")
		quit(0)
	else:
		for error: String in errors:
			push_error(error)
		quit(1)
