extends "res://scripts/edenfall_v4.gd"

const QUALITY_VERSION := "0.4.1"

var frame_samples: Array[float] = []
var average_fps := 60.0
var low_health_pulse := 0.0

func _ready() -> void:
	settings["controller_rumble"] = bool(settings.get("controller_rumble", true))
	super._ready()
	readiness = audit_quality_readiness()

func settings_rows() -> Array:
	var rows: Array = super.settings_rows()
	rows.append({"key":"controller_rumble", "label":"CONTROLLER RUMBLE"})
	return rows

func enter_room(coord: Vector2i, movement_direction: Vector2i) -> void:
	if room_graph.has(coord):
		var upcoming: Dictionary = room_graph[coord]
		current_modifier = String(upcoming.get("modifier", "none"))
	super.enter_room(coord, movement_direction)

func update_run(delta: float) -> void:
	if current_modifier == "overclocked":
		for i in range(enemies.size()):
			var enemy: Dictionary = enemies[i]
			enemy["cooldown"] = float(enemy.get("cooldown", 0.0)) - delta * 0.22
			enemies[i] = enemy
	super.update_run(delta)
	if current_modifier == "regenerative":
		for i in range(enemies.size()):
			var enemy: Dictionary = enemies[i]
			enemy["hp"] = minf(float(enemy["max_hp"]), float(enemy["hp"]) + float(enemy["max_hp"]) * 0.005 * delta)
			enemies[i] = enemy
	update_performance_monitor(delta)
	var hp_ratio := 1.0
	if not player.is_empty() and float(player.get("max_hp",0.0)) > 0.0:
		hp_ratio = float(player.get("hp",0.0)) / float(player["max_hp"])
	low_health_pulse = maxf(0.0, 1.0 - hp_ratio * 3.0)

func update_performance_monitor(delta: float) -> void:
	if delta <= 0.0:
		return
	frame_samples.append(1.0 / delta)
	if frame_samples.size() > 120:
		frame_samples.pop_front()
	var total := 0.0
	for sample in frame_samples:
		total += sample
	if not frame_samples.is_empty():
		average_fps = total / float(frame_samples.size())

func haptic(duration_ms: int, amplitude: float) -> void:
	super.haptic(duration_ms, amplitude)
	if bool(settings.get("controller_rumble", true)) and not Input.get_connected_joypads().is_empty():
		Input.start_joy_vibration(0, clampf(amplitude * 0.55,0.0,1.0), clampf(amplitude,0.0,1.0), float(duration_ms) / 1000.0)

func finish_run(victory: bool) -> void:
	var was_running := state == "run"
	super.finish_run(victory)
	if was_running:
		if FileAccess.file_exists(V4_SUSPEND_PATH):
			DirAccess.remove_absolute(V4_SUSPEND_PATH)
		if FileAccess.file_exists(V4_SUSPEND_PATH + ".bak"):
			DirAccess.remove_absolute(V4_SUSPEND_PATH + ".bak")

func draw_title() -> void:
	super.draw_title()
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2(8,size.y-35),Vector2(92,28)),Color8(5,9,10))
	draw_text("v%s" % QUALITY_VERSION,Vector2(18,size.y-18),12,Color8(112,160,132))

func draw_enemies() -> void:
	super.draw_enemies()
	if not bool(settings.get("colorblind_palette", false)):
		return
	for enemy in enemies:
		var labels: Array[String] = []
		if float(enemy.get("burn",0.0)) > 0.0: labels.append("B")
		if float(enemy.get("marked",0.0)) > 0.0: labels.append("M")
		if float(enemy.get("spore",0.0)) > 0.0: labels.append("S")
		if float(enemy.get("stagger",0.0)) > 0.0: labels.append("T")
		if not labels.is_empty():
			draw_text_centered("/".join(labels),Vector2(enemy["pos"])-Vector2(0,float(enemy["radius"])+27.0),9,Color.WHITE)

func draw_hud() -> void:
	super.draw_hud()
	var safe := safe_rect()
	if low_health_pulse > 0.0:
		var alpha := low_health_pulse * (0.10 + 0.08 * sin(visual_clock * 7.0))
		draw_rect(safe,Color(0.78,0.08,0.06,maxf(0.0,alpha)),false,5.0)
	if bool(settings.get("safe_area_debug",false)):
		draw_text("FPS %.0f" % average_fps,Vector2(safe.position.x+10,safe.end.y-12),10,Color8(142,181,158))

func audit_quality_readiness() -> float:
	var checks := [
		super.audit_v4_readiness() >= 90.0,
		settings_rows().size() >= 16,
		FileAccess.file_exists("res://tests/v4_quality_audit.gd"),
		FileAccess.file_exists("res://docs/QUALITY_V4.md"),
		ResourceLoader.exists("res://scripts/edenfall_v4.gd"),
		ResourceLoader.exists("res://scripts/v4/run_director.gd"),
	]
	var passed := 0
	for check in checks:
		if check:
			passed += 1
	return float(passed) / float(checks.size()) * 100.0
