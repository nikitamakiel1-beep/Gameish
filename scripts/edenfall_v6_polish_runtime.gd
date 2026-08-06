extends "res://scripts/edenfall_v6_content_runtime.gd"

const POLISH_VERSION := "0.6.1-rc5"

func _is_shop_room() -> bool:
	if state != "run" or not room_graph.has(current_room):
		return false
	var room: Dictionary = room_graph[current_room]
	return String(room.get("kind", "")) == "shop"

func _draw_relic_grid(rect: Rect2, columns: int, rows: int) -> void:
	if columns == 12 and rows == 5 and rect.size.y >= 90.0:
		var guardian_height := minf(43.0, rect.size.y * 0.25)
		var guardian_rect := Rect2(rect.position, Vector2(rect.size.x, guardian_height))
		_draw_guardian_strip(guardian_rect)
		var relic_rect := Rect2(Vector2(rect.position.x, guardian_rect.end.y + 3.0), Vector2(rect.size.x, rect.end.y - guardian_rect.end.y - 3.0))
		super._draw_relic_grid(relic_rect, columns, rows)
		return
	super._draw_relic_grid(rect, columns, rows)

func _draw_guardian_strip(rect: Rect2) -> void:
	draw_text("GUARDIAN SIGNATURES", rect.position + Vector2(3, 11), 7, Color8(129, 158, 143))
	var start_x := rect.position.x + minf(132.0, rect.size.x * 0.22)
	var available := rect.end.x - start_x - 4.0
	var cell_width := available / 5.0
	for index in range(5):
		var center := Vector2(start_x + (float(index) + 0.5) * cell_width, rect.position.y + rect.size.y * 0.52)
		var texture_value := boss_texture(index)
		if texture_value != null:
			draw_sprite(texture_value, center, BOSS_FRAME, 0, 4, 0.34)
		draw_text_centered(BOSS_NAMES[index], Vector2(center.x, rect.end.y - 2.0), 5, Color8(190, 186, 169))
