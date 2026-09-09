extends "res://scripts/edenfall_v6.gd"

const PerformanceBudgetScript: Script = preload("res://scripts/v6/performance_budget.gd")
const PlatformLifecycleScript: Script = preload("res://scripts/v6/platform_lifecycle.gd")

var performance_budget: RefCounted = PerformanceBudgetScript.new()
var platform_lifecycle: RefCounted = PlatformLifecycleScript.new()
var performance_profile: Dictionary = {}
var _asset_trim_clock := 0.0

func _ready() -> void:
	performance_profile = performance_budget.call("configure")
	super._ready()
	var joy_callback := Callable(self, "_on_joy_connection_changed")
	if not Input.joy_connection_changed.is_connected(joy_callback):
		Input.joy_connection_changed.connect(joy_callback)
	var resize_callback := Callable(self, "_on_viewport_size_changed")
	if not get_viewport().size_changed.is_connected(resize_callback):
		get_viewport().size_changed.connect(resize_callback)

func _process(delta: float) -> void:
	super._process(delta)
	performance_budget.call("enforce_post_frame", damage_numbers, pickups, state == "run" and not paused)
	_asset_trim_clock += delta
	if _asset_trim_clock >= float(performance_budget.call("trim_interval")):
		_asset_trim_clock = 0.0
		_trim_runtime_assets()

func _input(event: InputEvent) -> void:
	super._input(event)
	if not event is InputEventJoypadButton or not event.pressed:
		return
	match state:
		"title":
			if event.is_action_pressed("move_up"):
				menu_index = posmod(menu_index - 1, title_options().size())
			elif event.is_action_pressed("move_down"):
				menu_index = posmod(menu_index + 1, title_options().size())
			elif event.is_action_pressed("attack") or event.is_action_pressed("interact"):
				activate_title_option(menu_index)
		"select":
			if event.is_action_pressed("move_left"):
				selected_lineage = posmod(selected_lineage - 1, LINEAGES.size())
			elif event.is_action_pressed("move_right"):
				selected_lineage = posmod(selected_lineage + 1, LINEAGES.size())
			elif event.is_action_pressed("attack") or event.is_action_pressed("interact"):
				start_new_run(selected_lineage)
			elif event.is_action_pressed("pause"):
				state = "title"
		"run":
			if event.is_action_pressed("pause"):
				paused = not paused
				if paused:
					save_suspended_run()
			elif not paused and event.is_action_pressed("dash"):
				begin_dash()
			elif not paused and event.is_action_pressed("interact"):
				interact()
			elif event.is_action_pressed("archive"):
				archive_open = not archive_open
		"game_over", "victory":
			if event.is_action_pressed("attack") or event.is_action_pressed("interact"):
				state = "select"
			elif event.is_action_pressed("pause"):
				state = "title"

func _notification(what: int) -> void:
	super._notification(what)
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_apply_lifecycle_actions(platform_lifecycle.call("background", state, paused))
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_apply_lifecycle_actions(platform_lifecycle.call("foreground"))
		NOTIFICATION_OS_MEMORY_WARNING:
			_apply_lifecycle_actions(platform_lifecycle.call("memory_warning"))
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_apply_back_action(platform_lifecycle.call("back_request", state, paused, settings_open, archive_open))

func read_inputs() -> void:
	input_move = Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.18)
	if left_touch_id != -1:
		input_move = (left_touch_pos - left_touch_origin) / 58.0
	if input_move.length() > 1.0:
		input_move = input_move.normalized()

	input_aim = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", 0.22)
	if right_touch_id != -1:
		input_aim = (right_touch_pos - right_touch_origin) / 52.0
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not player.is_empty():
		input_aim = get_viewport().get_mouse_position() - Vector2(player["pos"])
	if input_aim.length() > 1.0:
		input_aim = input_aim.normalized()

func spawn_bullet(position: Vector2, velocity: Vector2, damage: float, owner: String, radius: float, color: Color, pierce: int, critical: bool) -> void:
	if not bool(performance_budget.call("admit_bullet", bullets, owner)):
		return
	super.spawn_bullet(position, velocity, damage, owner, radius, color, pierce, critical)

func spawn_effect(id: String, position: Vector2, color: Color, angle: float) -> void:
	if not bool(performance_budget.call("admit_effect", effects)):
		return
	super.spawn_effect(id, position, color, angle)

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["performance_budget"] = performance_budget.call("report")
	report["asset_cache"] = production_assets.call("cache_report")
	report["lifecycle"] = platform_lifecycle.call("report")
	report["connected_controllers"] = Input.get_connected_joypads()
	report["viewport_size"] = get_viewport_rect().size
	return report

func _trim_runtime_assets() -> void:
	if biome_index < 0 or biome_index >= BIOMES.size():
		return
	var active_enemy_ids: Array = []
	for enemy in enemies:
		var enemy_id := String(enemy.get("id", ""))
		if not enemy_id.is_empty() and enemy_id not in active_enemy_ids:
			active_enemy_ids.append(enemy_id)
	var active_boss := ""
	if biome_index < BOSS_IDS.size():
		active_boss = String(BOSS_IDS[biome_index])
	production_assets.call("trim_runtime_cache", String(BIOMES[biome_index]["id"]), active_enemy_ids, active_boss)

func _apply_lifecycle_actions(actions: Dictionary) -> void:
	if bool(actions.get("pause", false)):
		paused = true
	if bool(actions.get("resume", false)):
		paused = false
	if bool(actions.get("pause_audio", false)):
		_set_runtime_audio_paused(true)
	elif actions.has("pause_audio"):
		_set_runtime_audio_paused(false)
	if bool(actions.get("reset_input", false)):
		_reset_transient_input()
	if bool(actions.get("release_transient_assets", false)):
		production_assets.call("clear_transient_cache")
	if bool(actions.get("redraw", false)):
		queue_redraw()

func _apply_back_action(result: Dictionary) -> void:
	match String(result.get("action", "")):
		"close_settings":
			settings_open = false
			save_settings()
		"close_archive":
			archive_open = false
		"pause":
			paused = true
			save_suspended_run()
		"return_to_title":
			if state == "run":
				save_suspended_run()
			state = "title"
			paused = false
			settings_open = false
			archive_open = false
			_reset_transient_input()
		"quit":
			get_tree().quit()
	queue_redraw()

func _set_runtime_audio_paused(value: bool) -> void:
	for player_variant in audio_players.values():
		var audio_player := player_variant as AudioStreamPlayer
		if audio_player != null:
			audio_player.stream_paused = value
	for audio_player in sfx_pool:
		audio_player.stream_paused = value

func _reset_transient_input() -> void:
	input_move = Vector2.ZERO
	input_aim = Vector2.ZERO
	left_touch_id = -1
	right_touch_id = -1
	left_touch_origin = Vector2.ZERO
	right_touch_origin = Vector2.ZERO
	left_touch_pos = Vector2.ZERO
	right_touch_pos = Vector2.ZERO

func _on_viewport_size_changed() -> void:
	_reset_transient_input()
	queue_redraw()

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	platform_lifecycle.call("controller_changed", connected)
	var controller_name := Input.get_joy_name(device) if connected else "Controller"
	notify("%s %s" % [controller_name, "CONNECTED" if connected else "DISCONNECTED"])
	queue_redraw()
