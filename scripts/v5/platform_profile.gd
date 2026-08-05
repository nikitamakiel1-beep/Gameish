extends RefCounted

const VERSION := 5
const TARGETS := ["windows", "linux", "macos", "web", "android", "ios"]

func platform_id() -> String:
	for id in ["android", "ios", "web", "windows", "macos", "linux"]:
		if OS.has_feature(id):
			return id
	return "unknown"

func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

func is_web() -> bool:
	return OS.has_feature("web")

func input_family() -> String:
	if is_mobile():
		return "touch"
	if not Input.get_connected_joypads().is_empty():
		return "controller"
	return "keyboard_mouse"

func device_class(viewport_size: Vector2) -> String:
	var shortest := minf(viewport_size.x, viewport_size.y)
	var longest := maxf(viewport_size.x, viewport_size.y)
	if shortest < 520.0:
		return "phone"
	if shortest <= 1100.0 and longest <= 1500.0:
		return "tablet"
	return "desktop"

func orientation(viewport_size: Vector2) -> String:
	return "portrait" if viewport_size.y > viewport_size.x else "landscape"

func minimum_touch_target(viewport_size: Vector2, enlarged: bool = false) -> float:
	var base := 58.0 if device_class(viewport_size) == "phone" else 52.0
	return base * (1.18 if enlarged else 1.0)

func recommended_ui_scale(viewport_size: Vector2) -> float:
	match device_class(viewport_size):
		"phone": return 0.92
		"tablet": return 1.05
		_: return clampf(viewport_size.y / 720.0, 0.95, 1.35)

func performance_tier(viewport_size: Vector2) -> String:
	if is_web():
		return "balanced"
	if is_mobile() and minf(viewport_size.x, viewport_size.y) < 700.0:
		return "mobile"
	return "full"

func safe_area(viewport_size: Vector2, fallback_margin: float = 12.0) -> Rect2:
	var fallback := Rect2(Vector2(fallback_margin, fallback_margin), viewport_size - Vector2.ONE * fallback_margin * 2.0)
	var display_safe := DisplayServer.get_display_safe_area()
	var screen_size := DisplayServer.screen_get_size()
	if display_safe.size.x <= 0 or display_safe.size.y <= 0 or screen_size.x <= 0 or screen_size.y <= 0:
		return fallback
	var scale := Vector2(viewport_size.x / float(screen_size.x), viewport_size.y / float(screen_size.y))
	var converted := Rect2(Vector2(display_safe.position) * scale, Vector2(display_safe.size) * scale).grow(-8.0)
	if converted.size.x < 320.0 or converted.size.y < 240.0:
		return fallback
	return converted

func capability_report(viewport_size: Vector2) -> Dictionary:
	return {
		"version": VERSION,
		"platform": platform_id(),
		"device_class": device_class(viewport_size),
		"orientation": orientation(viewport_size),
		"input_family": input_family(),
		"mobile": is_mobile(),
		"web": is_web(),
		"haptics": is_mobile(),
		"controller": not Input.get_connected_joypads().is_empty(),
		"performance_tier": performance_tier(viewport_size),
		"targets": TARGETS.duplicate(),
	}
