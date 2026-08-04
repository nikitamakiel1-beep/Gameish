extends "res://scripts/edenfall_v4_quality.gd"

const V5_VERSION := "0.5.0"
const GODOT_TARGET := "4.7.1"
const V5_SETTINGS_PATH := "user://edenfall_platform_v5.json"
const PlatformProfileScript: Script = preload("res://scripts/v5/platform_profile.gd")
const UISystemScript: Script = preload("res://scripts/v5/ui_system.gd")
const SaveRepositoryScript: Script = preload("res://scripts/v5/save_repository.gd")
const BuildMatrixScript: Script = preload("res://scripts/v5/build_matrix.gd")

var platform_service: RefCounted = PlatformProfileScript.new()
var ui_system: RefCounted = UISystemScript.new()
var save_repository: RefCounted = SaveRepositoryScript.new()
var build_matrix: RefCounted = BuildMatrixScript.new()
var last_input_family := "keyboard_mouse"
var platform_report: Dictionary = {}
var v5_readiness := 0.0
var performance_target_fps := 60

func _ready() -> void:
	settings["compact_hud"] = bool(settings.get("compact_hud", false))
	settings["large_touch_targets"] = bool(settings.get("large_touch_targets", true))
	settings["show_input_prompts"] = bool(settings.get("show_input_prompts", true))
	settings["performance_mode"] = bool(settings.get("performance_mode", false))
	super._ready()
	refresh_platform_report()
	last_input_family = String(platform_report.get("input_family", "keyboard_mouse"))
	apply_performance_profile()
	v5_readiness = audit_v5_readiness()

func refresh_platform_report() -> void:
	platform_report = platform_service.call("capability_report", get_viewport_rect().size)

func apply_performance_profile() -> void:
	var constrained: bool = bool(settings.get("performance_mode", false))
	var mobile_or_web: bool = bool(platform_service.call("is_mobile")) or bool(platform_service.call("is_web"))
	if constrained:
		performance_target_fps = 45 if mobile_or_web else 60
	else:
		performance_target_fps = 60 if mobile_or_web else 120
	Engine.max_fps = performance_target_fps

func _notification(what: int) -> void:
	super._notification(what)
	if what in [NOTIFICATION_WM_SIZE_CHANGED, NOTIFICATION_APPLICATION_RESUMED]:
		refresh_platform_report()
		apply_performance_profile()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		last_input_family = "keyboard_mouse"
		update_hover_focus(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		last_input_family = "keyboard_mouse"
		if handle_spatial_navigation(event.keycode):
			get_viewport().set_input_as_handled()
			return
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

func update_hover_focus(position: Vector2) -> void:
	if settings_open:
		for i in range(settings_rows().size()):
			if settings_row_rect(i).has_point(position):
				settings_index = i
				return
	elif state == "title":
		for i in range(title_options().size()):
			if title_option_rect(i).has_point(position):
				menu_index = i
				return
	elif state == "select":
		for i in range(LINEAGES.size()):
			if lineage_card_rect(i).has_point(position):
				selected_lineage = i
				return

func handle_spatial_navigation(keycode: Key) -> bool:
	if archive_open:
		return false
	var mode: String = String(ui_system.call("layout_mode", safe_rect()))
	if settings_open and mode != "compact":
		var count := settings_rows().size()
		if keycode in [KEY_UP, KEY_W]:
			settings_index = posmod(settings_index - 2, count)
			return true
		if keycode in [KEY_DOWN, KEY_S]:
			settings_index = posmod(settings_index + 2, count)
			return true
		return false
	if state == "title" and mode != "compact":
		var count := title_options().size()
		if keycode in [KEY_UP, KEY_W]:
			menu_index = posmod(menu_index - 2, count)
			return true
		if keycode in [KEY_DOWN, KEY_S]:
			menu_index = posmod(menu_index + 2, count)
			return true
		if keycode in [KEY_LEFT, KEY_A]:
			menu_index = maxi(0, (menu_index / 2) * 2)
			return true
		if keycode in [KEY_RIGHT, KEY_D]:
			menu_index = mini(count - 1, (menu_index / 2) * 2 + 1)
			return true
	if state == "select":
		var columns := 2 if mode == "compact" else 5
		if keycode in [KEY_UP, KEY_W]:
			selected_lineage = posmod(selected_lineage - columns, LINEAGES.size())
			return true
		if keycode in [KEY_DOWN, KEY_S]:
			selected_lineage = posmod(selected_lineage + columns, LINEAGES.size())
			return true
		if keycode in [KEY_LEFT, KEY_A]:
			selected_lineage = posmod(selected_lineage - 1, LINEAGES.size())
			return true
		if keycode in [KEY_RIGHT, KEY_D]:
			selected_lineage = posmod(selected_lineage + 1, LINEAGES.size())
			return true
	return false

func handle_gamepad_button(button: JoyButton) -> void:
	if settings_open:
		match button:
			JOY_BUTTON_DPAD_UP:
				if not handle_spatial_navigation(KEY_UP): handle_settings_key(KEY_UP)
			JOY_BUTTON_DPAD_DOWN:
				if not handle_spatial_navigation(KEY_DOWN): handle_settings_key(KEY_DOWN)
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
			if button in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_LEFT_SHOULDER]:
				if not handle_spatial_navigation(KEY_UP): handle_key(KEY_UP)
			elif button in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_RIGHT_SHOULDER]:
				if not handle_spatial_navigation(KEY_DOWN): handle_key(KEY_DOWN)
			elif button == JOY_BUTTON_DPAD_LEFT: handle_spatial_navigation(KEY_LEFT)
			elif button == JOY_BUTTON_DPAD_RIGHT: handle_spatial_navigation(KEY_RIGHT)
			elif button == JOY_BUTTON_A: activate_title_option(menu_index)
		"select":
			if button == JOY_BUTTON_DPAD_LEFT: handle_spatial_navigation(KEY_LEFT)
			elif button == JOY_BUTTON_DPAD_RIGHT: handle_spatial_navigation(KEY_RIGHT)
			elif button == JOY_BUTTON_DPAD_UP: handle_spatial_navigation(KEY_UP)
			elif button == JOY_BUTTON_DPAD_DOWN: handle_spatial_navigation(KEY_DOWN)
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
	var extension: Dictionary = save_repository.call("read_json", V5_SETTINGS_PATH, {})
	for key in ["compact_hud", "large_touch_targets", "show_input_prompts", "performance_mode"]:
		if extension.has(key):
			settings[key] = extension[key]

func save_settings() -> void:
	super.save_settings()
	var extension: Dictionary = {
		"compact_hud": bool(settings.get("compact_hud", false)),
		"large_touch_targets": bool(settings.get("large_touch_targets", true)),
		"show_input_prompts": bool(settings.get("show_input_prompts", true)),
		"performance_mode": bool(settings.get("performance_mode", false)),
		"last_input_family": last_input_family,
	}
	save_repository.call("write_json_atomic", V5_SETTINGS_PATH, extension)

func adjust_setting(key: String, direction: int) -> void:
	super.adjust_setting(key, direction)
	if key == "performance_mode":
		apply_performance_profile()

func settings_rows() -> Array:
	var rows: Array = super.settings_rows()
	rows.append({"key":"compact_hud", "label":"COMPACT HUD"})
	rows.append({"key":"large_touch_targets", "label":"LARGE TOUCH TARGETS"})
	rows.append({"key":"show_input_prompts", "label":"CONTEXTUAL INPUT HINTS"})
	rows.append({"key":"performance_mode", "label":"BATTERY / PERFORMANCE MODE"})
	return rows

func safe_rect() -> Rect2:
	return Rect2(platform_service.call("safe_area", get_viewport_rect().size))

func use_compact_layout() -> bool:
	return bool(settings.get("compact_hud", false)) or String(platform_report.get("device_class", "desktop")) == "phone" or safe_rect().size.y < 600.0

func title_option_rect(index: int) -> Rect2:
	var rects: Array[Rect2] = ui_system.call("title_grid", safe_rect(), title_options().size())
	return rects[clampi(index, 0, rects.size() - 1)]

func lineage_card_rect(index: int) -> Rect2:
	var rects: Array[Rect2] = ui_system.call("lineage_grid", safe_rect(), LINEAGES.size())
	return rects[clampi(index, 0, rects.size() - 1)]

func settings_row_rect(index: int) -> Rect2:
	var rects: Array[Rect2] = ui_system.call("settings_grid", safe_rect(), settings_rows().size())
	return rects[clampi(index, 0, rects.size() - 1)]

func close_button_rect() -> Rect2:
	var safe: Rect2 = safe_rect()
	var width: float = minf(260.0, safe.size.x - 32.0)
	return Rect2(Vector2(safe.get_center().x - width * 0.5, safe.end.y - 58.0), Vector2(width, 44.0))

func pause_resume_rect() -> Rect2:
	return pause_action_rect(0)

func pause_settings_rect() -> Rect2:
	return pause_action_rect(1)

func pause_exit_rect() -> Rect2:
	return pause_action_rect(2)

func pause_action_rect(index: int) -> Rect2:
	var safe: Rect2 = safe_rect()
	var width: float = minf(320.0, safe.size.x - 64.0)
	var height := 50.0
	var start_y: float = safe.get_center().y - 83.0
	return Rect2(Vector2(safe.get_center().x - width * 0.5, start_y + float(index) * 66.0), Vector2(width, height))

func movement_stick_center() -> Vector2:
	var safe: Rect2 = safe_rect()
	var target: float = float(platform_service.call("minimum_touch_target", get_viewport_rect().size, bool(settings.get("large_touch_targets", true))))
	var inset: float = target * 1.45
	return Vector2(safe.position.x + inset, safe.end.y - inset) if not bool(settings["left_handed"]) else Vector2(safe.end.x - inset, safe.end.y - inset)

func aim_stick_center() -> Vector2:
	var safe: Rect2 = safe_rect()
	var target: float = float(platform_service.call("minimum_touch_target", get_viewport_rect().size, bool(settings.get("large_touch_targets", true))))
	var inset: float = target * 1.45
	return Vector2(safe.end.x - inset, safe.end.y - inset) if not bool(settings["left_handed"]) else Vector2(safe.position.x + inset, safe.end.y - inset)

func dash_button_rect() -> Rect2:
	var target: float = float(platform_service.call("minimum_touch_target", get_viewport_rect().size, bool(settings.get("large_touch_targets", true))))
	var direction: float = -1.0 if not bool(settings["left_handed"]) else 1.0
	var center: Vector2 = aim_stick_center() + Vector2(direction * target * 1.30, -target * 1.05)
	return Rect2(center - Vector2.ONE * target * 0.5, Vector2.ONE * target)

func interact_button_rect() -> Rect2:
	var target: float = float(platform_service.call("minimum_touch_target", get_viewport_rect().size, bool(settings.get("large_touch_targets", true)))) * 0.88
	var center: Vector2 = aim_stick_center() + Vector2(0.0, -target * 1.45)
	return Rect2(center - Vector2.ONE * target * 0.5, Vector2.ONE * target)

func draw_title() -> void:
	var size: Vector2 = get_viewport_rect().size
	var safe: Rect2 = safe_rect()
	var tokens: Dictionary = ui_system.get("TOKENS")
	draw_rect(Rect2(Vector2.ZERO, size), Color8(5, 10, 11))
	for i in range(10):
		var radius: float = 72.0 + float(i) * 34.0 + sin(visual_clock * 0.7 + float(i)) * 3.0
		draw_arc(Vector2(safe.get_center().x, safe.position.y + safe.size.y * 0.30), radius, 0, TAU, 72, Color(0.22, 0.42, 0.31, 0.16 - float(i) * 0.009), 2.0)
	var hero_y: float = safe.position.y + safe.size.y * 0.26
	draw_text_centered("EDEN//FALL", Vector2(safe.get_center().x, hero_y), 52 if safe.size.x >= 700.0 else 38, Color(tokens["text"]))
	draw_text_centered("THE FIRST GENOME WAS NEVER HUMAN", Vector2(safe.get_center().x, hero_y + 35.0), 14 if safe.size.x >= 700.0 else 11, Color(tokens["muted"]))
	draw_text_centered("v%s  •  GODOT %s  •  %s  •  %d FPS" % [V5_VERSION, GODOT_TARGET, String(platform_report.get("platform", "unknown")).to_upper(), performance_target_fps], Vector2(safe.get_center().x, hero_y + 62.0), 11, Color8(112, 160, 132))
	var options: Array[String] = title_options()
	for i in range(options.size()):
		var rect: Rect2 = title_option_rect(i)
		var selected: bool = i == menu_index
		draw_panel(rect, Color8(34, 54, 48) if selected else Color8(17, 28, 29), Color(tokens["focus"]) if selected else Color(tokens["border"]))
		draw_text_centered(options[i], rect.get_center() + Vector2(0, 6), 15 if safe.size.x >= 700.0 else 13, Color(tokens["text"]))
	var family: String = last_input_family.replace("_", " ").to_upper()
	draw_text_centered("INPUT: %s  •  WINDOWS / LINUX / MACOS / WEB / ANDROID / IOS" % family, Vector2(safe.get_center().x, safe.end.y - 10.0), 10, Color(tokens["muted"]))

func draw_select() -> void:
	var size: Vector2 = get_viewport_rect().size
	var safe: Rect2 = safe_rect()
	var compact: bool = String(ui_system.call("layout_mode", safe)) == "compact"
	draw_rect(Rect2(Vector2.ZERO, size), Color8(6, 10, 12))
	draw_text_centered("SELECT AN ENGINEERED LINEAGE", Vector2(safe.get_center().x, safe.position.y + 30.0), 24 if compact else 30, Color8(229, 216, 176))
	draw_text_centered("MOVE AND AIM IN EIGHT DIRECTIONS", Vector2(safe.get_center().x, safe.position.y + 54.0), 10 if compact else 14, Color8(120, 145, 136))
	for i in range(LINEAGES.size()):
		var lineage: Dictionary = LINEAGES[i]
		var rect: Rect2 = lineage_card_rect(i)
		var selected: bool = i == selected_lineage
		draw_panel(rect, Color8(30, 40, 38) if selected else Color8(18, 24, 26), Color(lineage["color"]) if selected else Color8(55, 67, 66))
		var tex: Texture2D = player_texture(String(lineage["id"]))
		var frame := posmod(int(visual_clock * 5.0 + float(i)), 8)
		var row := directional_row("idle", 4)
		if compact:
			if tex != null: draw_sprite(tex, Vector2(rect.get_center().x, rect.position.y + 45.0), PLAYER_FRAME, frame, row, 0.95)
			draw_text_centered(String(lineage["name"]), Vector2(rect.get_center().x, rect.position.y + 86.0), 16, Color(lineage["color"]))
			draw_text_centered(String(lineage["epithet"]), Vector2(rect.get_center().x, rect.position.y + 104.0), 9, Color8(177, 184, 171))
			draw_wrapped(String(lineage["trait"]), Rect2(rect.position + Vector2(7, 113), Vector2(rect.size.x - 14.0, 42.0)), 9, Color8(204, 201, 181))
			draw_text_centered("HP %.0f  •  DMG %.1f  •  SPD %.0f" % [lineage["max_hp"], lineage["damage"], lineage["speed"]], Vector2(rect.get_center().x, rect.end.y - 24.0), 8, Color8(226, 216, 185))
			draw_text_centered("TAP / %d" % (i + 1), Vector2(rect.get_center().x, rect.end.y - 8.0), 8, Color8(111, 131, 125))
		else:
			if tex != null: draw_sprite(tex, Vector2(rect.get_center().x, rect.position.y + 87.0), PLAYER_FRAME, frame, row, 1.8)
			draw_text_centered(String(lineage["name"]), Vector2(rect.get_center().x, rect.position.y + 155.0), 23, Color(lineage["color"]))
			draw_text_centered(String(lineage["epithet"]), Vector2(rect.get_center().x, rect.position.y + 178.0), 12, Color8(177, 184, 171))
			draw_wrapped(String(lineage["trait"]), Rect2(rect.position + Vector2(12, 205), Vector2(rect.size.x - 24.0, 58.0)), 12, Color8(204, 201, 181))
			draw_text("HP %.0f" % lineage["max_hp"], rect.position + Vector2(16, 292), 13, Color8(226, 216, 185))
			draw_text("DMG %.1f" % lineage["damage"], rect.position + Vector2(16, 315), 13, Color8(226, 216, 185))
			draw_text("SPD %.0f" % lineage["speed"], rect.position + Vector2(16, 338), 13, Color8(226, 216, 185))
			draw_text_centered("TAP / %d" % (i + 1), Vector2(rect.get_center().x, rect.end.y - 16.0), 12, Color8(111, 131, 125))

func draw_settings() -> void:
	var size: Vector2 = get_viewport_rect().size
	var safe: Rect2 = safe_rect()
	var tokens: Dictionary = ui_system.get("TOKENS")
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.84))
	draw_panel(safe.grow(-8.0), Color(tokens["panel"]), Color(tokens["border"]))
	draw_text_centered("ACCESSIBILITY • CONTROLS • INTERFACE", Vector2(safe.get_center().x, safe.position.y + 42.0), 23 if safe.size.x >= 700.0 else 17, Color(tokens["text"]))
	draw_text_centered("Every option is persistent and safe-area aware", Vector2(safe.get_center().x, safe.position.y + 65.0), 11, Color(tokens["muted"]))
	var rows: Array = settings_rows()
	for i in range(rows.size()):
		var rect: Rect2 = settings_row_rect(i)
		var selected: bool = i == settings_index
		draw_rect(rect, Color8(35, 54, 48) if selected else Color8(18, 29, 30))
		draw_rect(rect, Color(tokens["focus"]) if selected else Color8(55, 78, 70), false, 1.5)
		var font_size: int = 12 if rect.size.x < 380.0 else 13
		draw_text(String(rows[i]["label"]), rect.position + Vector2(12, rect.size.y * 0.68), font_size, Color(tokens["text"]))
		var value: String = setting_value(String(rows[i]["key"]))
		var value_width: float = ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_text(value, Vector2(rect.end.x - value_width - 12.0, rect.position.y + rect.size.y * 0.68), font_size, Color8(157, 213, 177))
	draw_panel(close_button_rect(), Color8(46, 69, 59), Color(tokens["focus"]))
	draw_text_centered("CLOSE & SAVE", close_button_rect().get_center() + Vector2(0, 6), 14, Color(tokens["text"]))

func draw_pause() -> void:
	var size: Vector2 = get_viewport_rect().size
	var safe: Rect2 = safe_rect()
	var tokens: Dictionary = ui_system.get("TOKENS")
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.72))
	var panel_width: float = minf(500.0, safe.size.x - 28.0)
	var panel_height: float = minf(440.0, safe.size.y - 24.0)
	var panel: Rect2 = Rect2(Vector2(safe.get_center().x - panel_width * 0.5, safe.get_center().y - panel_height * 0.5), Vector2(panel_width, panel_height))
	draw_panel(panel, Color(tokens["panel"]), Color(tokens["border"]))
	draw_text_centered("EXCURSION PAUSED", Vector2(panel.get_center().x, panel.position.y + 48.0), 25, Color(tokens["text"]))
	draw_text_centered("%s • THREAT %.2f • SCORE %d" % [String(player.get("name", "UNKNOWN")), threat_level, run_score], Vector2(panel.get_center().x, panel.position.y + 76.0), 12, Color(tokens["muted"]))
	for item in [[pause_resume_rect(), "RESUME"], [pause_settings_rect(), "SETTINGS & ACCESSIBILITY"], [pause_exit_rect(), "SAVE & EXIT TO BIOLAB"]]:
		draw_panel(Rect2(item[0]), Color8(29, 45, 41), Color8(84, 126, 105))
		draw_text_centered(String(item[1]), Rect2(item[0]).get_center() + Vector2(0, 6), 15, Color(tokens["text"]))
	var prompt: String = String(ui_system.call("context_prompt", last_input_family, "run"))
	draw_text_centered(prompt, Vector2(panel.get_center().x, panel.end.y - 22.0), 9, Color(tokens["muted"]))

func draw_hud() -> void:
	if use_compact_layout():
		draw_compact_hud()
	else:
		super.draw_hud()
	draw_input_prompt()

func draw_compact_hud() -> void:
	var safe: Rect2 = safe_rect()
	var top := Rect2(safe.position + Vector2(5, 5), Vector2(safe.size.x - 10.0, 52.0))
	draw_panel(top, Color(0.02, 0.04, 0.04, 0.91), Color8(78, 116, 98))
	var name_text := "%s  •  %s" % [String(player.get("name", "UNKNOWN")), String(player.get("weapon", {}).get("name", "WEAPON"))]
	draw_text(name_text, top.position + Vector2(10, 18), 11, Color8(232, 222, 190))
	var hp_ratio := clampf(float(player.get("hp", 0.0)) / maxf(0.001, float(player.get("max_hp", 1.0))), 0.0, 1.0)
	var hp_rect := Rect2(top.position + Vector2(10, 27), Vector2(top.size.x * 0.46, 12))
	draw_rect(hp_rect, Color8(55, 25, 28))
	draw_rect(Rect2(hp_rect.position, Vector2(hp_rect.size.x * hp_ratio, hp_rect.size.y)), Color8(200, 69, 68))
	draw_rect(hp_rect, Color8(232, 194, 151), false, 1.0)
	draw_text("%.1f/%.1f" % [player["hp"], player["max_hp"]], hp_rect.position + Vector2(4, 10), 8, Color.WHITE)
	draw_text("SCRAP %d  •  GENOME %d" % [scraps, int(profile["genome"])], Vector2(top.end.x - 155.0, top.position.y + 19.0), 9, Color8(221, 172, 90))
	draw_text("ROOM %d  •  SCORE %d" % [rooms_cleared, run_score], Vector2(top.end.x - 155.0, top.position.y + 37.0), 9, Color8(154, 207, 177))
	var objective_box := Rect2(Vector2(safe.position.x + 5.0, top.end.y + 4.0), Vector2(safe.size.x - 10.0, 28.0))
	draw_panel(objective_box, Color(0.02, 0.04, 0.04, 0.84), Color(BIOMES[biome_index]["accent"]))
	draw_text_centered(objective, objective_box.get_center() + Vector2(0, 4), 9, Color8(212, 211, 186))
	if boss_max_health > 0.0 and boss_health > 0.0:
		var boss_rect := Rect2(Vector2(safe.position.x + 20.0, objective_box.end.y + 4.0), Vector2(safe.size.x - 40.0, 16.0))
		draw_rect(boss_rect, Color8(37, 18, 21))
		draw_rect(Rect2(boss_rect.position, Vector2(boss_rect.size.x * boss_health / boss_max_health, boss_rect.size.y)), Color8(173, 43, 54))
		draw_rect(boss_rect, Color8(234, 184, 110), false, 1.0)
		draw_text_centered(BOSS_NAMES[biome_index], boss_rect.get_center() + Vector2(0, 3), 8, Color.WHITE)
	draw_rect(pause_button_rect(), Color(0.04, 0.07, 0.07, 0.92))
	draw_text_centered("II", pause_button_rect().get_center() + Vector2(0, 5), 13, Color8(220, 216, 190))
	draw_cooldown_ring(dash_button_rect().get_center(), dash_timer / maxf(0.001, float(player["dash_delay"])), Color8(107, 180, 229))

func draw_input_prompt() -> void:
	if not bool(settings.get("show_input_prompts", true)):
		return
	var prompt: String = String(ui_system.call("context_prompt", last_input_family, state))
	if prompt == "" or (use_compact_layout() and last_input_family == "touch"):
		return
	var regions: Dictionary = ui_system.call("hud_regions", safe_rect(), float(settings["ui_scale"]))
	var context: Rect2 = Rect2(regions["context"])
	if use_compact_layout():
		context.size.x = minf(context.size.x * 0.72, safe_rect().size.x - 24.0)
		context.position.x = safe_rect().get_center().x - context.size.x * 0.5
		context.position.y = safe_rect().end.y - 146.0
	draw_panel(context, Color(0.02, 0.04, 0.04, 0.76), Color8(65, 99, 85))
	draw_text_centered(prompt, context.get_center() + Vector2(0, 4), 9 if context.size.x < 360.0 else 10, Color8(151, 181, 165))

func draw_touch_controls() -> void:
	if not bool(platform_service.call("is_mobile")) and left_touch_id == -1 and right_touch_id == -1:
		return
	var target: float = float(platform_service.call("minimum_touch_target", get_viewport_rect().size, bool(settings.get("large_touch_targets", true))))
	var opacity: float = 0.50 if bool(settings.get("compact_hud", false)) else 0.68
	for pair in [[movement_stick_center(), input_move, Color8(93, 153, 117), "MOVE"], [aim_stick_center(), input_aim, Color8(166, 105, 185), "AIM"]]:
		var center: Vector2 = Vector2(pair[0])
		var vector: Vector2 = Vector2(pair[1])
		var accent: Color = Color(pair[2])
		draw_circle(center, target, Color(0.04, 0.07, 0.07, opacity * 0.75))
		draw_arc(center, target, 0, TAU, 40, Color(accent, opacity), 2.5)
		draw_circle(center + vector * target * 0.62, target * 0.34, Color(accent, opacity))
		draw_text_centered(String(pair[3]), center + Vector2(0, target + 14.0), 9, Color(accent, 0.90))
	for item in [[dash_button_rect(), "DASH", Color8(112, 188, 232)], [interact_button_rect(), "USE", Color8(233, 202, 137)]]:
		var rect: Rect2 = Rect2(item[0])
		var accent: Color = Color(item[2])
		draw_circle(rect.get_center(), rect.size.x * 0.5, Color(accent, opacity * 0.45))
		draw_arc(rect.get_center(), rect.size.x * 0.5, 0, TAU, 32, Color(accent, opacity), 2.0)
		draw_text_centered(String(item[1]), rect.get_center() + Vector2(0, 4), 10, accent)

func audit_v5_readiness() -> float:
	var platform_contract: Dictionary = platform_service.call("capability_report", Vector2(1280, 720))
	var ui_contract: Dictionary = ui_system.call("audit_contract")
	var save_contract: Dictionary = save_repository.call("audit_contract")
	var build_contract: Dictionary = build_matrix.call("audit_contract")
	var phone_safe := Rect2(Vector2(12, 12), Vector2(366, 820))
	var phone_cards: Array[Rect2] = ui_system.call("lineage_grid", phone_safe, 5)
	var cards_fit := phone_cards.size() == 5
	for card in phone_cards:
		cards_fit = cards_fit and phone_safe.encloses(card)
	var checks: Array[bool] = [
		super.audit_quality_readiness() >= 90.0,
		String(ProjectSettings.get_setting("application/config/version", "")) == V5_VERSION,
		Array(platform_contract.get("targets", [])).size() == 6,
		int(ui_contract.get("title_slots", 0)) >= 6,
		int(ui_contract.get("settings_slots", 0)) >= 20,
		bool(save_contract.get("atomic_write", false)),
		int(build_contract.get("presets", 0)) == 7,
		settings_rows().size() >= 20,
		float(platform_service.call("minimum_touch_target", Vector2(390, 844), true)) >= 58.0,
		cards_fit,
		performance_target_fps >= 45,
		FileAccess.file_exists("res://export_presets.cfg"),
		FileAccess.file_exists("res://tests/v5_audit.gd"),
	]
	var passed := 0
	for check in checks:
		if check:
			passed += 1
	return float(passed) / float(checks.size()) * 100.0
