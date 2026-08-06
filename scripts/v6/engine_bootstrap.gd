extends RefCounted

const TARGET_VERSION := {"major": 4, "minor": 7, "patch": 1}
const REQUIRED_ACTIONS := [
	"move_up", "move_down", "move_left", "move_right",
	"aim_up", "aim_down", "aim_left", "aim_right",
	"attack", "dash", "interact", "pause", "archive",
]

func configure() -> Dictionary:
	_configure_simulation()
	_configure_input_map()
	var version: Dictionary = Engine.get_version_info()
	var exact_version := (
		int(version.get("major", -1)) == int(TARGET_VERSION["major"])
		and int(version.get("minor", -1)) == int(TARGET_VERSION["minor"])
		and int(version.get("patch", -1)) == int(TARGET_VERSION["patch"])
	)
	var report := {
		"target": "4.7.1",
		"running": "%d.%d.%d-%s" % [
			int(version.get("major", 0)),
			int(version.get("minor", 0)),
			int(version.get("patch", 0)),
			String(version.get("status", "unknown")),
		],
		"exact_version": exact_version,
		"renderer": RenderingServer.get_current_rendering_method(),
		"platform": OS.get_name(),
		"mobile": OS.has_feature("mobile"),
		"web": OS.has_feature("web"),
		"input_actions": REQUIRED_ACTIONS.duplicate(),
	}
	if not exact_version:
		push_warning("EDEN//FALL targets Godot 4.7.1 exactly; running %s" % report["running"])
	return report

func _configure_simulation() -> void:
	Engine.physics_ticks_per_second = 60
	Engine.max_physics_steps_per_frame = 8
	Engine.physics_jitter_fix = 0.5
	if OS.has_feature("mobile") or OS.has_feature("web"):
		Engine.max_fps = 60

func _configure_input_map() -> void:
	for action in REQUIRED_ACTIONS:
		_ensure_action(action)

	_bind_key("move_up", KEY_W)
	_bind_key("move_down", KEY_S)
	_bind_key("move_left", KEY_A)
	_bind_key("move_right", KEY_D)

	_bind_key("aim_up", KEY_I)
	_bind_key("aim_up", KEY_UP)
	_bind_key("aim_down", KEY_K)
	_bind_key("aim_down", KEY_DOWN)
	_bind_key("aim_left", KEY_J)
	_bind_key("aim_left", KEY_LEFT)
	_bind_key("aim_right", KEY_L)
	_bind_key("aim_right", KEY_RIGHT)
	_bind_key("attack", KEY_SPACE)
	_bind_mouse("attack", MOUSE_BUTTON_LEFT)
	_bind_key("dash", KEY_SHIFT)
	_bind_key("interact", KEY_E)
	_bind_key("pause", KEY_ESCAPE)
	_bind_key("archive", KEY_TAB)

	_bind_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_bind_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_bind_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_bind_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_bind_axis("aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_bind_axis("aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_bind_axis("aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_bind_axis("aim_down", JOY_AXIS_RIGHT_Y, 1.0)
	_bind_button("move_up", JOY_BUTTON_DPAD_UP)
	_bind_button("move_down", JOY_BUTTON_DPAD_DOWN)
	_bind_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_bind_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_bind_button("attack", JOY_BUTTON_RIGHT_SHOULDER)
	_bind_button("dash", JOY_BUTTON_A)
	_bind_button("interact", JOY_BUTTON_X)
	_bind_button("pause", JOY_BUTTON_START)
	_bind_button("archive", JOY_BUTTON_Y)

func _ensure_action(action: StringName) -> void:
	var deadzone := 0.22
	if String(action).begins_with("move_"):
		deadzone = 0.18
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
	else:
		InputMap.action_set_deadzone(action, deadzone)

func _bind_key(action: StringName, physical_keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	_add_event_once(action, event)

func _bind_mouse(action: StringName, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	_add_event_once(action, event)

func _bind_axis(action: StringName, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	_add_event_once(action, event)

func _bind_button(action: StringName, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	_add_event_once(action, event)

func _add_event_once(action: StringName, candidate: InputEvent) -> void:
	for existing in InputMap.action_get_events(action):
		if existing.is_match(candidate):
			return
	InputMap.action_add_event(action, candidate)
