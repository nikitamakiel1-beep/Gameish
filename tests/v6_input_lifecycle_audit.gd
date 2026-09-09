extends Node

const RuntimeScript: Script = preload("res://scripts/edenfall_v6_runtime.gd")

func _ready() -> void:
	var errors: Array[String] = []
	var game := Node2D.new()
	game.set_script(RuntimeScript)
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	Input.action_press("move_right", 1.0)
	Input.action_press("aim_up", 1.0)
	game.call("read_inputs")
	var move_vector := Vector2(game.get("input_move"))
	var aim_vector := Vector2(game.get("input_aim"))
	Input.action_release("move_right")
	Input.action_release("aim_up")
	if move_vector.distance_to(Vector2.RIGHT) > 0.01:
		errors.append("Action-map movement did not resolve right: %s" % move_vector)
	if aim_vector.distance_to(Vector2.UP) > 0.01:
		errors.append("Action-map aim did not resolve up: %s" % aim_vector)

	var registry := game.get("production_assets") as RefCounted
	registry.call("enemy_sheet", "feral_scavenger")
	registry.call("boss_sheet", "watcher_engine")
	registry.call("biome_texture", "industrial_eden", "background")
	var cache_before: Dictionary = registry.call("cache_report")
	game.notification(NOTIFICATION_OS_MEMORY_WARNING)
	await get_tree().process_frame
	var cache_after: Dictionary = registry.call("cache_report")
	if int(cache_after.get("textures", 0)) >= int(cache_before.get("textures", 0)):
		errors.append("Memory warning did not release transient textures")

	game.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	game.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	var report: Dictionary = game.call("get_v6_diagnostics")
	var lifecycle: Dictionary = report.get("lifecycle", {})
	if int(lifecycle.get("background_events", 0)) < 1:
		errors.append("Focus-out lifecycle event was not recorded")
	if int(lifecycle.get("foreground_events", 0)) < 1:
		errors.append("Focus-in lifecycle event was not recorded")
	if int(lifecycle.get("memory_warnings", 0)) < 1:
		errors.append("Memory warning was not recorded")
	if not report.has("connected_controllers") or not report.has("viewport_size"):
		errors.append("Platform diagnostics are incomplete")

	print("EDEN_FALL_V6_INPUT_LIFECYCLE_REPORT=" + JSON.stringify({
		"move": move_vector,
		"aim": aim_vector,
		"cache_before": cache_before,
		"cache_after": cache_after,
		"lifecycle": lifecycle,
	}))
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		print("EDEN_FALL_V6_INPUT_LIFECYCLE_AUDIT=FAIL")
		get_tree().quit(1)
		return
	print("EDEN_FALL_V6_INPUT_LIFECYCLE_AUDIT=PASS")
	get_tree().quit(0)
