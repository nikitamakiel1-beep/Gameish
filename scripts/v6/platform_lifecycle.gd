extends RefCounted

var automatically_paused := false
var background_events := 0
var foreground_events := 0
var memory_warnings := 0
var back_requests := 0
var controller_connections := 0
var controller_disconnections := 0
var last_background_msec := 0
var last_foreground_msec := 0

func background(state: String, paused: bool) -> Dictionary:
	background_events += 1
	last_background_msec = Time.get_ticks_msec()
	automatically_paused = state == "run" and not paused
	return {
		"save": state == "run",
		"pause": automatically_paused,
		"pause_audio": true,
		"reset_input": true,
	}

func foreground() -> Dictionary:
	foreground_events += 1
	last_foreground_msec = Time.get_ticks_msec()
	var should_resume := automatically_paused
	automatically_paused = false
	return {
		"resume": should_resume,
		"pause_audio": false,
		"reset_input": true,
		"redraw": true,
	}

func memory_warning() -> Dictionary:
	memory_warnings += 1
	return {"release_transient_assets": true, "redraw": true}

func back_request(state: String, paused: bool, settings_open: bool, archive_open: bool) -> Dictionary:
	back_requests += 1
	if settings_open:
		return {"action": "close_settings"}
	if archive_open:
		return {"action": "close_archive"}
	match state:
		"run":
			return {"action": "return_to_title" if paused else "pause"}
		"select", "game_over", "victory":
			return {"action": "return_to_title"}
		_:
			return {"action": "quit"}

func controller_changed(connected: bool) -> void:
	if connected:
		controller_connections += 1
	else:
		controller_disconnections += 1

func report() -> Dictionary:
	return {
		"automatically_paused": automatically_paused,
		"background_events": background_events,
		"foreground_events": foreground_events,
		"memory_warnings": memory_warnings,
		"back_requests": back_requests,
		"controller_connections": controller_connections,
		"controller_disconnections": controller_disconnections,
		"last_background_msec": last_background_msec,
		"last_foreground_msec": last_foreground_msec,
	}
