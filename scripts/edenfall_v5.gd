extends "res://scripts/edenfall_v4_quality.gd"

const V5_VERSION := "0.5.0"
const GODOT_TARGET := "4.7.1"
const V5_SETTINGS_PATH := "user://edenfall_platform_v5.json"
const PlatformProfileScript := preload("res://scripts/v5/platform_profile.gd")
const UISystemScript := preload("res://scripts/v5/ui_system.gd")
const SaveRepositoryScript := preload("res://scripts/v5/save_repository.gd")
const BuildMatrixScript := preload("res://scripts/v5/build_matrix.gd")

var platform_service = PlatformProfileScript.new()
var ui_system = UISystemScript.new()
var save_repository = SaveRepositoryScript.new()
var build_matrix = BuildMatrixScript.new()
var last_input_family := "keyboard_mouse"
var platform_report: Dictionary = {}
var v5_readiness := 0.0

func _ready() -> void:
	settings["compact_hud"] = bool(settings.get("compact_hud", false))
	settings["large_touch_targets"] = bool(settings.get("large_touch_targets", true))
	settings["show_input_prompts"] = bool(settings.get("show_input_prompts", true))
	settings["performance_mode"] = bool(settings.get("performance_mode", false))
	super._ready()
	refresh_platform_report()
	last_input_family = String(platform_report.get("input_family", "keyboard_mouse"))
	v5_readiness = audit_v5_readiness()

func refresh_platform_report() -> void:
	platform_report = platform_service.capability_report(get_viewport_rect().size)

func _notification(what: int) -> void:
	super._notification(what)
	if what in [NOTIFICATION_WM_SIZE_CHANGED, NOTIFICATION_APPLICATION_RESUMED]:
		refresh_platform_report()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		last_input_family = "controller"
		if event.pressed:
			handle_gamepad_button(event.button_index)
			get_viewport().set_input_as_handled()
		return
	elif event is InputEventJoypadMotion:
		last_input_family = "controller"
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		last_input_family = "touch"
	elif event is InputEventKey or event is InputEventMouse:
		last_input_family = "keyboard_mouse"
	super._input(event)

func handle_gamepad_button(button: JoyButton) -> void:
	if settings_open:
		match button:
			JOY_BUTTON_DPAD_UP: handle_settings_key(KEY_UP)
			JOY_BUTTON_DPAD_DOWN: handle_settings_key(KEY_DOWN)
			JOY_BUTTON_DPAD_LEFT: handle_settings_key(KEY_LEFT)
			JOY_BUTTON_DPAD_RIGHT: handle_settings_key(KEY_RIGHT)
			JOY_BUTTON_A: handle_settings_key(KEY_SPACE)
			JOY_BUTTON_B: handle_settings_key(KEY_ESCAPE)
		return
	if archive_open:
		if button in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_Y]:
			archive_open = false
		return
	match state:
		"title":
			if button in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_LEFT_SHOULDER]: handle_key(KEY_UP)
			elif button in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_RIGHT_SHOULDER]: handle_key(KEY_DOWN)
			elif button == JOY_BUTTON_A: activate_title_option(menu_index)
		"select":
			if button == JOY_BUTTON_DPAD_LEFT: handle_key(KEY_LEFT)
			elif button == JOY_BUTTON_DPAD_RIGHT: handle_key(KEY_RIGHT)
			elif button == JOY_BUTTON_A: start_new_run(selected_lineage)
			elif button == JOY_BUTTON_B: state = "title"
		"run":
			if button == JOY_BUTTON_START: paused = not paused
			elif paused and button == JOY_BUTTON_A: paused = false
			elif button == JOY_BUTTON_A: begin_dash()
			elif button == JOY_BUTTON_X: interact()
			elif button == JOY_BUTTON_Y: archive_open = true
			elif button == JOY_BUTTON_B: paused = true
		"game_over", "victory":
			if button == JOY_BUTTON_A: state = "select"
			elif button == JOY_BUTTON_B: state = "title"

func load_settings() -> void:
	super.load_settings()
	var extension := save_repository.read_json(V5_SETTINGS_PATH, {})
	for key in ["compact_hud", "large_touch_targets", "show_input_prompts", "performance_mode"]:
		if extension.has(key):
			settings[key] = extension[key]

func save_settings() -> void:
	super.save_settings()
	var extension := {
		"compact_hud": bool(settings.get("compact_hud", false)),
		"large_touch_targets": bool(settings.get("large_touch_targets", true)),
		"show_input_prompts": bool(settings.get("show_input_prompts", true)),
		"performance_mode": bool(settings.get("performance_mode", false)),
		"last_input_family": last_input_family,
	}
	save_repository.write_json_atomic(V5_SETTINGS_PATH, extension)

func settings_rows() -> Array:
	var rows: Array = super.settings_rows()
	rows.append({"key":"compact_hud", "label":"COMPACT HUD"})
	rows.append({"key":"large_touch_targets", "label":"LARGE TOUCH TARGETS"})
	rows.append({"key":"show_input_prompts", "label":"CONTEXTUAL INPUT HINTS"})
	rows.append({"key":"performance_mode", "label":"BATTERY / PERFORMANCE MODE"})
	return rows

func safe_rect() -> Rect2:
	return platform_service.safe_area(get_viewport_rect().size)

func title_option_rect(index: int) -> Rect2:
	var rects := ui_system.title_grid(safe_rect(), title_options().size())
	return rects[clampi(index, 0, rects.size() - 1)]

func lineage_card_rect(index: int) -> Rect2:
	var rects := ui_system.lineage_grid(safe_rect(), LINEAGES.size())
	return rects[clampi(index, 0, rects.size() - 1)]

func settings_row_rect(index: int) -> Rect2:
	var rects := ui_system.settings_grid(safe_rect(), settings_rows().size())
	return rects[clampi(index, 0, rects.size() - 1)]

func close_button_rect() -> Rect2:
	var safe := safe_rect()
	var width := minf(260.0, safe.size.x - 32.0)
	return Rect2(Vector2(safe.get_center().x - width * 0.5, safe.end.y - 58.0), Vector2(width, 44.0))

func movement_stick_center() -> Vector2:
	var safe := safe_rect()
	var target := platform_service.minimum_touch_target(get_viewport_rect().size, bool(settings.get("large_touch_targets", true)))
	var inset := target * 1.45
	return Vector2(safe.position.x + inset, safe.end.y - inset) if not bool(settings["left_handed"]) else Vector2(safe.end.x - inset, safe.end.y - inset)

func aim_stick_center() -> Vector2:
	var safe := safe_rect()
	var target := platform_service.minimum_touch_target(get_viewport_rect().size, bool(settings.get("large_touch_targets", true)))
	var inset := target * 1.45
	return Vector2(safe.end.x - inset, safe.end.y - inset) if not bool(settings["left_handed"]) else Vector2(safe.position.x + inset, safe.end.y - inset)

func dash_button_rect() -> Rect2:
	var target := platform_service.minimum_touch_target(get_viewport_rect().size, bool(settings.get("large_touch_targets", true)))
	var direction := -1.0 if not bool(settings["left_handed"]) else 1.0
	var center := aim_stick_center() + Vector2(direction * target * 1.30, -target * 1.05)
	return Rect2(center - Vector2.ONE * target * 0.5, Vector2.ONE * target)

func interact_button_rect() -> Rect2:
	var target := platform_service.minimum_touch_target(get_viewport_rect().size, bool(settings.get("large_touch_targets", true))) * 0.88
	var center := aim_stick_center() + Vector2(0.0, -target * 1.45)
	return Rect2(center - Vector2.ONE * target * 0.5, Vector2.ONE * target)

func draw_title() -> void:
	var size := get_viewport_rect().size
	var safe := safe_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color8(5, 10, 11))
	for i in range(10):
		var radius := 72.0 + float(i) * 34.0 + sin(visual_clock * 0.7 + float(i)) * 3.0
		draw_arc(Vector2(safe.get_center().x, safe.position.y + safe.size.y * 0.30), radius, 0, TAU, 72, Color(0.22, 0.42, 0.31, 0.16 - float(i) * 0.009), 2.0)
	var hero_y := safe.position.y + safe.size.y * 0.26
	draw_text_centered("EDEN//FALL", Vector2(safe.get_center().x, hero_y), 52 if safe.size.x >= 700.0 else 38, ui_system.TOKENS["text"])
	draw_text_centered("THE FIRST GENOME WAS NEVER HUMAN", Vector2(safe.get_center().x, hero_y + 35.0), 14 if safe.size.x >= 700.0 else 11, ui_system.TOKENS["muted"])
	draw_text_centered("v%s  •  GODOT %s  •  %s" % [V5_VERSION, GODOT_TARGET, String(platform_report.get("platform", "unknown")).to_upper()], Vector2(safe.get_center().x, hero_y + 62.0), 11, Color8(112, 160, 132))
	var options := title_options()
	for i in range(options.size()):
		var rect := title_option_rect(i)
		var selected := i == menu_index
		draw_panel(rect, Color8(34, 54, 48) if selected else Color8(17, 28, 29), ui_system.TOKENS["focus"] if selected else ui_system.TOKENS["border"])
		draw_text_centered(options[i], rect.get_center() + Vector2(0, 6), 15 if safe.size.x >= 700.0 else 13, ui_system.TOKENS["text"])
	var family := last_input_family.replace("_", " ").to_upper()
	draw_text_centered("INPUT: %s  •  WINDOWS / LINUX / MACOS / WEB / ANDROID / IOS" % family, Vector2(safe.get_center().x, safe.end.y - 10.0), 10, ui_system.TOKENS["muted"])

func draw_settings() -> void:
	var size := get_viewport_rect().size
	var safe := safe_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.84))
	draw_panel(safe.grow(-8.0), ui_system.TOKENS["panel"], ui_system.TOKENS["border"])
	draw_text_centered("ACCESSIBILITY • CONTROLS • INTERFACE", Vector2(safe.get_center().x, safe.position.y + 42.0), 23 if safe.size.x >= 700.0 else 17, ui_system.TOKENS["text"])
	draw_text_centered("Every option is persistent and safe-area aware", Vector2(safe.get_center().x, safe.position.y + 65.0), 11, ui_system.TOKENS["muted"])
	var rows := settings_rows()
	for i in range(rows.size()):
		var rect := settings_row_rect(i)
		var selected := i == settings_index
		draw_rect(rect, Color8(35, 54, 48) if selected else Color8(18, 29, 30))
		draw_rect(rect, ui_system.TOKENS["focus"] if selected else Color8(55, 78, 70), false, 1.5)
		var font_size := 12 if rect.size.x < 380.0 else 13
		draw_text(String(rows[i]["label"]), rect.position + Vector2(12, rect.size.y * 0.68), font_size, ui_system.TOKENS["text"])
		var value := setting_value(String(rows[i]["key"]))
		var value_width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_text(value, Vector2(rect.end.x - value_width - 12.0, rect.position.y + rect.size.y * 0.68), font_size, Color8(157, 213, 177))
	draw_panel(close_button_rect(), Color8(46, 69, 59), ui_system.TOKENS["focus"])
	draw_text_centered("CLOSE & SAVE", close_button_rect().get_center() + Vector2(0, 6), 14, ui_system.TOKENS["text"])

func draw_pause() -> void:
	var size := get_viewport_rect().size
	var safe := safe_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.72))
	var panel_width := minf(500.0, safe.size.x - 28.0)
	var panel := Rect2(Vector2(safe.get_center().x - panel_width * 0.5, safe.get_center().y - 220.0), Vector2(panel_width, 440.0))
	draw_panel(panel, ui_system.TOKENS["panel"], ui_system.TOKENS["border"])
	draw_text_centered("EXCURSION PAUSED", Vector2(panel.get_center().x, panel.position.y + 48.0), 25, ui_system.TOKENS["text"])
	draw_text_centered("%s • THREAT %.2f • SCORE %d" % [String(player.get("name", "UNKNOWN")), threat_level, run_score], Vector2(panel.get_center().x, panel.position.y + 76.0), 12, ui_system.TOKENS["muted"])
	for item in [[pause_resume_rect(), "RESUME"], [pause_settings_rect(), "SETTINGS & ACCESSIBILITY"], [pause_exit_rect(), "SAVE & EXIT TO BIOLAB"]]:
		draw_panel(item[0], Color8(29, 45, 41), Color8(84, 126, 105))
		draw_text_centered(item[1], item[0].get_center() + Vector2(0, 6), 15, ui_system.TOKENS["text"])
	var prompt := ui_system.context_prompt(last_input_family, "run")
	draw_text_centered(prompt, Vector2(panel.get_center().x, panel.end.y - 32.0), 10, ui_system.TOKENS["muted"])

func draw_hud() -> void:
	super.draw_hud()
	if not bool(settings.get("show_input_prompts", true)):
		return
	var prompt := ui_system.context_prompt(last_input_family, state)
	if prompt == "":
		return
	var regions := ui_system.hud_regions(safe_rect(), float(settings["ui_scale"]))
	var context: Rect2 = regions["context"]
	if bool(settings.get("compact_hud", false)):
		context.size.x *= 0.72
		context.position.x = safe_rect().get_center().x - context.size.x * 0.5
	draw_panel(context, Color(0.02, 0.04, 0.04, 0.76), Color8(65, 99, 85))
	draw_text_centered(prompt, context.get_center() + Vector2(0, 4), 9 if context.size.x < 360.0 else 10, Color8(151, 181, 165))

func draw_touch_controls() -> void:
	if not platform_service.is_mobile() and left_touch_id == -1 and right_touch_id == -1:
		return
	var target := platform_service.minimum_touch_target(get_viewport_rect().size, bool(settings.get("large_touch_targets", true)))
	var opacity := 0.50 if bool(settings.get("compact_hud", false)) else 0.68
	for pair in [[movement_stick_center(), input_move, Color8(93, 153, 117), "MOVE"], [aim_stick_center(), input_aim, Color8(166, 105, 185), "AIM"]]:
		draw_circle(pair[0], target, Color(0.04, 0.07, 0.07, opacity * 0.75))
		draw_arc(pair[0], target, 0, TAU, 40, Color(pair[2], opacity), 2.5)
		draw_circle(pair[0] + pair[1] * target * 0.62, target * 0.34, Color(pair[2], opacity))
		draw_text_centered(pair[3], pair[0] + Vector2(0, target + 14.0), 9, Color(pair[2], 0.90))
	for item in [[dash_button_rect(), "DASH", Color8(112, 188, 232)], [interact_button_rect(), "USE", Color8(233, 202, 137)]]:
		draw_circle(item[0].get_center(), item[0].size.x * 0.5, Color(item[2], opacity * 0.45))
		draw_arc(item[0].get_center(), item[0].size.x * 0.5, 0, TAU, 32, Color(item[2], opacity), 2.0)
		draw_text_centered(item[1], item[0].get_center() + Vector2(0, 4), 10, item[2])

func audit_v5_readiness() -> float:
	var platform_contract: Dictionary = platform_service.capability_report(Vector2(1280, 720))
	var ui_contract: Dictionary = ui_system.audit_contract()
	var save_contract: Dictionary = save_repository.audit_contract()
	var build_contract: Dictionary = build_matrix.audit_contract()
	var checks := [
		super.audit_quality_readiness() >= 90.0,
		String(ProjectSettings.get_setting("application/config/version", "")) == V5_VERSION,
		Array(platform_contract.get("targets", [])).size() == 6,
		int(ui_contract.get("title_slots", 0)) >= 6,
		int(ui_contract.get("settings_slots", 0)) >= 20,
		bool(save_contract.get("atomic_write", false)),
		int(build_contract.get("presets", 0)) == 7,
		settings_rows().size() >= 20,
		FileAccess.file_exists("res://export_presets.cfg"),
		FileAccess.file_exists("res://tests/v5_audit.gd"),
	]
	var passed := 0
	for check in checks:
		if check:
			passed += 1
	return float(passed) / float(checks.size()) * 100.0
