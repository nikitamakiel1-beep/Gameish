extends RefCounted

const VERSION := 5
const TOKENS := {
	"space_1": 6.0,
	"space_2": 10.0,
	"space_3": 16.0,
	"space_4": 24.0,
	"radius_small": 8.0,
	"radius_large": 16.0,
	"panel": Color(0.025, 0.045, 0.047, 0.94),
	"panel_soft": Color(0.040, 0.066, 0.064, 0.90),
	"border": Color8(82, 121, 103),
	"text": Color8(232, 222, 190),
	"muted": Color8(137, 163, 151),
	"focus": Color8(167, 213, 150),
	"danger": Color8(218, 79, 68),
	"gold": Color8(224, 191, 116),
}

func breakpoint(safe: Rect2) -> String:
	if safe.size.x < 700.0:
		return "compact"
	if safe.size.x < 1100.0:
		return "medium"
	return "wide"

func content_width(safe: Rect2) -> float:
	match breakpoint(safe):
		"compact": return safe.size.x - 24.0
		"medium": return minf(860.0, safe.size.x - 48.0)
		_: return minf(1120.0, safe.size.x - 72.0)

func title_grid(safe: Rect2, count: int) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var mode := breakpoint(safe)
	var columns := 1 if mode == "compact" else 2
	var width := (content_width(safe) - float(columns - 1) * 16.0) / float(columns)
	var height := 48.0 if mode == "compact" else 52.0
	var rows := int(ceil(float(count) / float(columns)))
	var total_height := float(rows) * height + float(maxi(0, rows - 1)) * 12.0
	var start := Vector2(safe.get_center().x - content_width(safe) * 0.5, minf(safe.end.y - total_height - 28.0, safe.position.y + safe.size.y * 0.56))
	for i in range(count):
		var column := i % columns
		var row := i / columns
		rects.append(Rect2(start + Vector2(float(column) * (width + 16.0), float(row) * (height + 12.0)), Vector2(width, height)))
	return rects

func lineage_grid(safe: Rect2, count: int) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var mode := breakpoint(safe)
	var columns := 2 if mode == "compact" else 5
	var gap := 12.0
	var width := (safe.size.x - gap * float(columns - 1) - 24.0) / float(columns)
	var top := safe.position.y + (70.0 if mode == "compact" else 84.0)
	var rows := int(ceil(float(count) / float(columns)))
	var height := (safe.end.y - top - 22.0 - gap * float(rows - 1)) / float(rows)
	for i in range(count):
		var column := i % columns
		var row := i / columns
		rects.append(Rect2(Vector2(safe.position.x + 12.0 + float(column) * (width + gap), top + float(row) * (height + gap)), Vector2(width, height)))
	return rects

func settings_grid(safe: Rect2, count: int) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var columns := 1 if breakpoint(safe) == "compact" else 2
	var gap := 10.0
	var panel_width := minf(content_width(safe), 980.0)
	var width := (panel_width - float(columns - 1) * gap) / float(columns)
	var row_height := 36.0
	var rows := int(ceil(float(count) / float(columns)))
	var start_y := safe.position.y + 76.0
	var available := safe.end.y - start_y - 76.0
	if float(rows) * (row_height + 7.0) > available:
		row_height = maxf(29.0, available / float(rows) - 6.0)
	var start_x := safe.get_center().x - panel_width * 0.5
	for i in range(count):
		var column := i % columns
		var row := i / columns
		rects.append(Rect2(Vector2(start_x + float(column) * (width + gap), start_y + float(row) * (row_height + 7.0)), Vector2(width, row_height)))
	return rects

func hud_regions(safe: Rect2, ui_scale: float) -> Dictionary:
	var mode := breakpoint(safe)
	var header_height := 62.0 * ui_scale
	var left_width := minf(330.0 * ui_scale, safe.size.x * (0.46 if mode == "compact" else 0.30))
	var right_width := minf(265.0 * ui_scale, safe.size.x * (0.40 if mode == "compact" else 0.24))
	return {
		"mode": mode,
		"player": Rect2(safe.position + Vector2(8, 8), Vector2(left_width, header_height)),
		"resources": Rect2(Vector2(safe.end.x - right_width - 8.0, safe.position.y + 8.0), Vector2(right_width, header_height)),
		"objective": Rect2(Vector2(safe.get_center().x - minf(240.0 * ui_scale, safe.size.x * 0.24), safe.position.y + 8.0), Vector2(minf(480.0 * ui_scale, safe.size.x * 0.48), header_height)),
		"context": Rect2(Vector2(safe.get_center().x - 230.0 * ui_scale, safe.end.y - 43.0 * ui_scale), Vector2(460.0 * ui_scale, 35.0 * ui_scale)),
	}

func context_prompt(input_family: String, state: String) -> String:
	if state != "run":
		return ""
	match input_family:
		"touch": return "DRAG LEFT TO MOVE  •  DRAG RIGHT TO AIM"
		"controller": return "LS MOVE  •  RS AIM  •  A DASH  •  X USE  •  START PAUSE"
		_: return "WASD MOVE  •  ARROWS/IJKL AIM  •  SPACE DASH  •  E USE"

func audit_contract() -> Dictionary:
	var safe := Rect2(Vector2.ZERO, Vector2(1280, 720))
	return {
		"version": VERSION,
		"breakpoints": [breakpoint(Rect2(Vector2.ZERO, Vector2(480, 800))), breakpoint(Rect2(Vector2.ZERO, Vector2(900, 720))), breakpoint(safe)],
		"title_slots": title_grid(safe, 6).size(),
		"lineage_slots": lineage_grid(safe, 5).size(),
		"settings_slots": settings_grid(safe, 20).size(),
		"minimum_contrast_tokens": 6,
	}
