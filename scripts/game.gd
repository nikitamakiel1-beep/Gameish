extends "res://scripts/game_core.gd"

var ui_font: Font

func _ready() -> void:
	ui_font = ThemeDB.fallback_font
	super._ready()

func _draw() -> void:
	match state:
		"title": draw_title()
		"select": draw_lineage_select()
		"run": draw_run()
		"game_over": draw_end_screen(false)
		"victory": draw_end_screen(true)

func draw_title() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color8(7, 11, 12))
	for i in range(18):
		var y := 76.0 + float(i) * 39.0
		draw_line(Vector2(0.0, y), Vector2(size.x, y - 160.0), Color8(17, 30, 29), 1.0)
	var core := Vector2(size.x * 0.5, 248.0)
	for radius in [151.0, 116.0, 78.0]:
		draw_arc(core, radius, -PI * 0.92, PI * 0.92, 64, Color8(65, 97, 81), 3.0)
	draw_circle(core, 47.0, Color8(24, 56, 45))
	draw_circle(core, 31.0, Color8(126, 182, 111))
	draw_line(core - Vector2(0.0, 90.0), core + Vector2(0.0, 90.0), Color8(154, 202, 137), 2.0)
	draw_centered("GAMEISH", Vector2(size.x * 0.5, 90.0), 22, Color8(128, 161, 148))
	draw_centered("EDEN//FALL", Vector2(size.x * 0.5, 407.0), 58, Color8(226, 214, 174))
	draw_centered("INDUSTRIAL BIBLICAL ROGUELIKE", Vector2(size.x * 0.5, 448.0), 18, Color8(129, 150, 141))
	draw_centered("Five engineered descendants. One contaminated creation.", Vector2(size.x * 0.5, 501.0), 19, Color8(184, 187, 168))
	var button := Rect2(Vector2(size.x * 0.5 - 150.0, 549.0), Vector2(300.0, 63.0))
	draw_panel(button, Color8(33, 57, 48), Color8(121, 171, 126))
	draw_centered("OPEN THE BIOLAB", button.get_center() + Vector2(0.0, 7.0), 21, Color8(231, 226, 199))
	draw_centered("Genome %d   •   Best purge %d   •   Runs %d" % [genome, best_depth, runs_completed], Vector2(size.x * 0.5, size.y - 42.0), 15, Color8(104, 125, 116))

func draw_lineage_select() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color8(8, 12, 14))
	draw_centered("SELECT AN ENGINEERED LINEAGE", Vector2(size.x * 0.5, 53.0), 31, Color8(226, 215, 180))
	draw_centered("Each body is a biological doctrine. Death resets the excursion.", Vector2(size.x * 0.5, 83.0), 15, Color8(121, 142, 135))
	for i in range(lineages.size()):
		var lineage: Dictionary = lineages[i]
		var rect := lineage_card_rect(i)
		var selected := i == selected_lineage
		draw_panel(rect, Color8(34, 45, 42) if selected else Color8(23, 29, 31), lineage["color"] if selected else Color8(61, 73, 72))
		draw_circle(Vector2(rect.get_center().x, rect.position.y + 69.0), 36.0, lineage["color"])
		draw_circle(Vector2(rect.get_center().x, rect.position.y + 69.0), 22.0, Color8(21, 27, 28))
		draw_centered(lineage["name"], Vector2(rect.get_center().x, rect.position.y + 132.0), 24, lineage["color"])
		draw_centered(lineage["epithet"], Vector2(rect.get_center().x, rect.position.y + 158.0), 13, Color8(173, 180, 170))
		draw_wrapped(lineage["description"], Rect2(rect.position + Vector2(13.0, 186.0), Vector2(rect.size.x - 26.0, 63.0)), 14, Color8(195, 197, 182))
		draw_text("HP  %.0f" % lineage["max_hp"], rect.position + Vector2(17.0, 275.0), 14, Color8(216, 209, 184))
		draw_text("DMG %.0f" % lineage["damage"], rect.position + Vector2(17.0, 300.0), 14, Color8(216, 209, 184))
		draw_text("SPD %.0f" % lineage["speed"], rect.position + Vector2(17.0, 325.0), 14, Color8(216, 209, 184))
		draw_wrapped(lineage["trait"], Rect2(rect.position + Vector2(13.0, 354.0), Vector2(rect.size.x - 26.0, 69.0)), 12, lineage["color"])
		draw_centered("TAP / %d" % (i + 1), Vector2(rect.get_center().x, rect.end.y - 17.0), 12, Color8(115, 132, 127))
	draw_centered("Archive pool expands at Genome 5 / 8 / 12 / 18 / 25", Vector2(size.x * 0.5, size.y - 22.0), 13, Color8(100, 118, 112))

func lineage_card_rect(index: int) -> Rect2:
	var size := get_viewport_rect().size
	var gap := 12.0
	var margin := 34.0
	var width := (size.x - margin * 2.0 - gap * 4.0) / 5.0
	return Rect2(Vector2(margin + float(index) * (width + gap), 107.0), Vector2(width, size.y - 153.0))

func draw_run() -> void:
	draw_arena()
	draw_doors()
	draw_pickups()
	draw_bullets()
	draw_enemies()
	draw_player()
	var room: Dictionary = rooms[current_room]
	if room["kind"] == "shop": draw_shop(room)
	draw_hud()
	draw_touch_controls()
	if notification_timer > 0.0:
		var box := Rect2(Vector2(get_viewport_rect().size.x * 0.5 - 270.0, 78.0), Vector2(540.0, 38.0))
		draw_panel(box, Color(0.03, 0.05, 0.05, 0.93), Color8(110, 147, 123))
		draw_centered(notification, box.get_center() + Vector2(0.0, 5.0), 14, Color8(223, 219, 191))
	if paused: draw_pause_overlay()

func draw_arena() -> void:
	var size := get_viewport_rect().size
	var arena := arena_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color8(7, 10, 11))
	draw_rect(arena, Color8(24, 29, 28))
	for x in range(int(arena.position.x), int(arena.end.x), 48):
		draw_line(Vector2(x, arena.position.y), Vector2(x, arena.end.y), Color8(30, 38, 36), 1.0)
	for y in range(int(arena.position.y), int(arena.end.y), 48):
		draw_line(Vector2(arena.position.x, y), Vector2(arena.end.x, y), Color8(30, 38, 36), 1.0)
	for i in range(7):
		var p := arena.position + Vector2(94.0 + float(i) * 165.0, 70.0 + float((i * 71) % maxi(100, int(arena.size.y - 140.0))))
		draw_circle(p, 25.0, Color8(28, 42, 34))
		draw_arc(p, 17.0, 0.0, TAU, 18, Color8(68, 94, 71), 2.0)
	draw_rect(arena, Color8(96, 109, 95), false, 4.0)

func draw_doors() -> void:
	var room: Dictionary = rooms[current_room]
	for direction in room["neighbors"]:
		var center := door_position(direction)
		var open: bool = room["cleared"]
		var color := Color8(90, 160, 111) if open else Color8(138, 65, 60)
		var rect := Rect2(center - Vector2(43.0, 12.0), Vector2(86.0, 24.0))
		if direction.x != 0: rect = Rect2(center - Vector2(12.0, 43.0), Vector2(24.0, 86.0))
		draw_rect(rect, Color8(10, 14, 14))
		draw_rect(rect, color, false, 4.0)
		if not open:
			for i in range(3):
				if direction.x == 0:
					draw_line(rect.position + Vector2(8.0, 6.0 + i * 6.0), rect.end - Vector2(8.0, 18.0 - i * 6.0), color, 2.0)
				else:
					draw_line(rect.position + Vector2(6.0 + i * 6.0, 8.0), rect.end - Vector2(18.0 - i * 6.0, 8.0), color, 2.0)

func door_position(direction: Vector2i) -> Vector2:
	var arena := arena_rect()
	if direction == Vector2i.UP: return Vector2(arena.get_center().x, arena.position.y)
	if direction == Vector2i.DOWN: return Vector2(arena.get_center().x, arena.end.y)
	if direction == Vector2i.LEFT: return Vector2(arena.position.x, arena.get_center().y)
	return Vector2(arena.end.x, arena.get_center().y)

func draw_player() -> void:
	var position: Vector2 = player["pos"]
	var color: Color = player["color"]
	if invulnerability > 0.0 and int(invulnerability * 18.0) % 2 == 0: color = Color(color, 0.35)
	if dash_time > 0.0:
		for i in range(3):
			draw_circle(position - player["dash_direction"] * float(i + 1) * 18.0, PLAYER_RADIUS - float(i) * 3.0, Color(color, 0.16))
	draw_circle(position, PLAYER_RADIUS + 5.0, Color8(11, 15, 16))
	draw_circle(position, PLAYER_RADIUS, color)
	draw_circle(position, 8.0, Color8(30, 37, 38))
	var aim: Vector2 = player.get("aim", Vector2.RIGHT)
	draw_line(position + aim * 9.0, position + aim * 29.0, Color8(236, 226, 190), 5.0)
	if player.get("shield", false): draw_arc(position, 25.0, -PI * 0.85, PI * 0.85, 28, Color8(111, 170, 230), 3.0)
	if player.get("halo", false):
		var halo := halo_position()
		draw_circle(halo, 11.0, Color8(228, 156, 71))
		draw_arc(position, 50.0, 0.0, TAU, 40, Color(0.7, 0.47, 0.2, 0.22), 1.0)

func draw_enemies() -> void:
	for enemy in enemies:
		var pos: Vector2 = enemy["pos"]
		var color: Color = Color.WHITE if enemy["flash"] > 0.0 else enemy["color"]
		match enemy["type"]:
			"feral":
				draw_colored_polygon(PackedVector2Array([pos + Vector2(0.0, -enemy["radius"]), pos + Vector2(enemy["radius"], enemy["radius"]), pos + Vector2(-enemy["radius"], enemy["radius"])]), color)
			"outlaw":
				draw_rect(Rect2(pos - Vector2.ONE * enemy["radius"], Vector2.ONE * enemy["radius"] * 2.0), color)
				draw_line(pos, pos + (player["pos"] - pos).normalized() * 27.0, Color8(32, 26, 24), 4.0)
			"nephilim":
				draw_circle(pos, enemy["radius"], color)
				draw_circle(pos, enemy["radius"] * 0.48, Color8(51, 42, 38))
				draw_line(pos + Vector2(-18.0, -21.0), pos + Vector2(-29.0, -38.0), color, 7.0)
				draw_line(pos + Vector2(18.0, -21.0), pos + Vector2(29.0, -38.0), color, 7.0)
			"fallen":
				draw_circle(pos, enemy["radius"], color)
				draw_arc(pos, enemy["radius"] + 11.0, enemy["phase"], enemy["phase"] + PI * 1.35, 24, Color8(180, 173, 217), 4.0)
			"boss":
				draw_circle(pos, enemy["radius"], color)
				draw_arc(pos, enemy["radius"] + 19.0, enemy["phase"], enemy["phase"] + PI * 1.45, 42, Color8(212, 138, 80), 6.0)
				for i in range(4):
					var node_pos := pos + Vector2.RIGHT.rotated(enemy["phase"] + TAU * float(i) / 4.0) * 34.0
					draw_circle(node_pos, 7.0, Color8(247, 200, 103))
		var ratio: float = maxf(0.0, enemy["hp"] / enemy["max_hp"])
		var bar_width := enemy["radius"] * 2.1
		draw_rect(Rect2(pos + Vector2(-bar_width * 0.5, enemy["radius"] + 10.0), Vector2(bar_width, 5.0)), Color8(37, 24, 24))
		draw_rect(Rect2(pos + Vector2(-bar_width * 0.5, enemy["radius"] + 10.0), Vector2(bar_width * ratio, 5.0)), Color8(193, 69, 67))

func draw_bullets() -> void:
	for bullet in bullets:
		draw_circle(bullet["pos"], bullet["radius"] + 3.0, Color(bullet["color"], 0.18))
		draw_circle(bullet["pos"], bullet["radius"], bullet["color"])

func draw_pickups() -> void:
	for pickup in pickups:
		var pos: Vector2 = pickup["pos"] + Vector2(0.0, sin(pickup["phase"]) * 5.0)
		match pickup["kind"]:
			"scrap":
				draw_colored_polygon(PackedVector2Array([pos + Vector2(0.0, -10.0), pos + Vector2(9.0, 4.0), pos + Vector2(0.0, 11.0), pos + Vector2(-9.0, 4.0)]), Color8(207, 141, 74))
			"heart": draw_heart(pos, 1.0)
			"item":
				var definition: Dictionary = item_defs[pickup["id"]]
				draw_circle(pos, 22.0, Color8(14, 18, 19))
				draw_arc(pos, 21.0, 0.0, TAU, 32, definition["color"], 4.0)
				draw_circle(pos, 9.0, definition["color"])
				draw_centered(definition["name"], pos + Vector2(0.0, 42.0), 12, Color8(218, 213, 190))

func draw_shop(room: Dictionary) -> void:
	var center := arena_rect().get_center()
	draw_circle(center + Vector2(0.0, -118.0), 31.0, Color8(156, 127, 82))
	draw_rect(Rect2(center + Vector2(-24.0, -90.0), Vector2(48.0, 55.0)), Color8(74, 60, 46))
	draw_centered("PREADAMIC FACTOR // NON-HOSTILE", center + Vector2(0.0, -157.0), 14, Color8(198, 181, 143))
	var shop_items: Array = room["shop_items"]
	for i in range(shop_items.size()):
		var item: Dictionary = shop_items[i]
		var definition: Dictionary = item_defs[item["id"]]
		var rect := shop_card_rect(i, shop_items.size())
		var sold: bool = item["bought"]
		draw_panel(rect, Color8(22, 26, 26), Color8(66, 70, 65) if sold else definition["color"])
		draw_circle(Vector2(rect.get_center().x, rect.position.y + 35.0), 14.0, Color8(12, 15, 16) if sold else definition["color"])
		draw_centered("SOLD" if sold else definition["name"], Vector2(rect.get_center().x, rect.position.y + 70.0), 13, Color8(103, 109, 105) if sold else Color8(224, 216, 188))
		draw_centered("%d SCRAP" % definition["cost"], Vector2(rect.get_center().x, rect.position.y + 96.0), 14, Color8(116, 121, 115) if sold else Color8(223, 153, 78))

func shop_card_rect(index: int, count: int) -> Rect2:
	var width := 190.0
	var gap := 24.0
	var total := width * float(count) + gap * float(count - 1)
	var start_x := get_viewport_rect().size.x * 0.5 - total * 0.5
	return Rect2(Vector2(start_x + float(index) * (width + gap), arena_rect().get_center().y + 10.0), Vector2(width, 116.0))

func draw_hud() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 54.0)), Color8(9, 13, 14))
	draw_text(player["name"], Vector2(23.0, 35.0), 18, player["color"])
	var cells := int(ceil(player["max_hp"]))
	for i in range(cells):
		var rect := Rect2(Vector2(118.0 + float(i) * 23.0, 17.0), Vector2(17.0, 17.0))
		draw_rect(rect, Color8(61, 37, 39))
		var filled := clampf(player["hp"] - float(i), 0.0, 1.0)
		if filled > 0.0: draw_rect(Rect2(rect.position, Vector2(rect.size.x * filled, rect.size.y)), Color8(202, 73, 81))
	draw_text("SCRAP %03d" % scraps, Vector2(380.0, 35.0), 16, Color8(219, 151, 77))
	draw_text("DMG %.1f" % player["damage"], Vector2(495.0, 35.0), 15, Color8(193, 190, 171))
	draw_text("SEED %08X" % (run_seed & 0xFFFFFFFF), Vector2(596.0, 35.0), 13, Color8(107, 124, 117))
	draw_minimap(Vector2(size.x - 195.0, 12.0))
	var dash_ratio := 1.0 if dash_timer <= 0.0 else 1.0 - dash_timer / player["dash_delay"]
	draw_rect(Rect2(Vector2(size.x - 89.0, size.y - 35.0), Vector2(59.0, 7.0)), Color8(49, 56, 54))
	draw_rect(Rect2(Vector2(size.x - 89.0, size.y - 35.0), Vector2(59.0 * dash_ratio, 7.0)), Color8(111, 170, 157))

func draw_minimap(origin: Vector2) -> void:
	var cell := 13.0
	for coord in room_order:
		var room: Dictionary = rooms[coord]
		if not room["visited"] and coord != current_room: continue
		var p := origin + Vector2(coord.x, coord.y) * cell
		var color := Color8(81, 95, 90)
		if room["kind"] == "shop": color = Color8(210, 150, 75)
		elif room["kind"] == "treasure": color = Color8(116, 174, 144)
		elif room["kind"] == "boss": color = Color8(183, 67, 71)
		if coord == current_room: color = Color8(235, 226, 190)
		draw_rect(Rect2(p, Vector2(9.0, 9.0)), color)

func draw_touch_controls() -> void:
	if left_touch_id != -1:
		draw_circle(left_touch_start, 50.0, Color(0.7, 0.8, 0.75, 0.08))
		draw_arc(left_touch_start, 50.0, 0.0, TAU, 32, Color(0.7, 0.8, 0.75, 0.22), 2.0)
		draw_circle(left_touch_pos, 19.0, Color(0.7, 0.8, 0.75, 0.25))
	if right_touch_id != -1:
		draw_circle(right_touch_start, 48.0, Color(0.8, 0.72, 0.5, 0.07))
		draw_line(right_touch_start, right_touch_pos, Color(0.9, 0.75, 0.45, 0.25), 3.0)
	var rect := dash_button_rect()
	var center := rect.get_center()
	draw_circle(center, rect.size.x * 0.40, Color(0.12, 0.18, 0.17, 0.72))
	draw_arc(center, rect.size.x * 0.40, 0.0, TAU, 32, Color8(99, 145, 132), 3.0)
	draw_centered("DASH", center + Vector2(0.0, 5.0), 13, Color8(190, 210, 198))

func draw_pause_overlay() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.70))
	var panel := Rect2(Vector2(size.x * 0.5 - 250.0, size.y * 0.5 - 130.0), Vector2(500.0, 260.0))
	draw_panel(panel, Color8(20, 27, 27), Color8(102, 137, 119))
	draw_centered("EXCURSION SUSPENDED", Vector2(size.x * 0.5, panel.position.y + 60.0), 28, Color8(226, 215, 180))
	draw_centered("Tap, Esc, or P to resume", Vector2(size.x * 0.5, panel.position.y + 106.0), 16, Color8(154, 170, 162))
	draw_centered("WASD move  •  Mouse / IJKL fire  •  Space / right-click dash", Vector2(size.x * 0.5, panel.position.y + 156.0), 14, Color8(187, 188, 174))
	draw_centered("Mobile: left thumb move, right thumb fire, DASH button evade", Vector2(size.x * 0.5, panel.position.y + 188.0), 14, Color8(187, 188, 174))

func draw_end_screen(victory: bool) -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color8(8, 11, 12))
	var color := Color8(119, 177, 130) if victory else Color8(188, 73, 76)
	for radius in [190.0, 146.0, 104.0]: draw_arc(Vector2(size.x * 0.5, 250.0), radius, 0.0, TAU, 64, Color(color, 0.24), 3.0)
	draw_centered("CREATION RECLAIMED" if victory else "LINEAGE TERMINATED", Vector2(size.x * 0.5, 177.0), 42, color)
	draw_centered("THE WATCHER ENGINE IS SILENT" if victory else "THE ARCHIVE RETAINS WHAT THE BODY LOST", Vector2(size.x * 0.5, 222.0), 16, Color8(175, 181, 168))
	draw_centered("Chambers purged   %d" % last_rooms_cleared, Vector2(size.x * 0.5, 348.0), 20, Color8(216, 209, 184))
	draw_centered("Genome recovered  +%d" % last_genome_gain, Vector2(size.x * 0.5, 386.0), 20, Color8(216, 209, 184))
	draw_centered("Archive total     %d" % genome, Vector2(size.x * 0.5, 424.0), 20, Color8(216, 209, 184))
	var button := Rect2(Vector2(size.x * 0.5 - 140.0, 492.0), Vector2(280.0, 62.0))
	draw_panel(button, Color8(29, 44, 39), color)
	draw_centered("SELECT A NEW BODY", button.get_center() + Vector2(0.0, 7.0), 18, Color8(230, 224, 198))
	draw_centered("Every run reconfigures the chambers, enemies, offers, and seed.", Vector2(size.x * 0.5, size.y - 50.0), 14, Color8(105, 124, 116))

func draw_heart(center: Vector2, scale: float) -> void:
	draw_circle(center + Vector2(-5.0, -2.0) * scale, 7.0 * scale, Color8(205, 76, 87))
	draw_circle(center + Vector2(5.0, -2.0) * scale, 7.0 * scale, Color8(205, 76, 87))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-11.0, 0.0) * scale, center + Vector2(11.0, 0.0) * scale, center + Vector2(0.0, 15.0) * scale]), Color8(205, 76, 87))

func draw_panel(rect: Rect2, fill: Color, border: Color) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, border, false, 2.0)

func draw_text(text: String, baseline: Vector2, size: int, color: Color) -> void:
	draw_string(ui_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)

func draw_centered(text: String, baseline: Vector2, size: int, color: Color) -> void:
	var width := ui_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	draw_string(ui_font, baseline - Vector2(width * 0.5, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)

func draw_wrapped(text: String, rect: Rect2, size: int, color: Color) -> void:
	var words := text.split(" ")
	var line := ""
	var y := rect.position.y + float(size)
	for word in words:
		var candidate := word if line.is_empty() else line + " " + word
		if ui_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x > rect.size.x and not line.is_empty():
			draw_text(line, Vector2(rect.position.x, y), size, color)
			line = word
			y += float(size) + 5.0
		else:
			line = candidate
	if not line.is_empty() and y <= rect.end.y + float(size): draw_text(line, Vector2(rect.position.x, y), size, color)
