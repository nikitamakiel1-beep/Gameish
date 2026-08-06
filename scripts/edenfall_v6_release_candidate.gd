extends "res://scripts/edenfall_v6_product_runtime.gd"

const RELEASE_CANDIDATE_VERSION := "0.6.1-rc1"

func arena_rect() -> Rect2:
	var safe := safe_rect()
	var short_landscape := safe.size.y < 610.0 and safe.size.x > safe.size.y
	var top_inset := 98.0 if short_landscape else 116.0
	var bottom_inset := 48.0 if short_landscape else 60.0
	var side_inset := 14.0 if safe.size.x < 760.0 else 20.0
	var width := maxf(220.0, safe.size.x - side_inset * 2.0)
	var height := maxf(190.0, safe.size.y - top_inset - bottom_inset)
	return Rect2(safe.position + Vector2(side_inset, top_inset), Vector2(width, height))

func lineage_card_rect(index: int) -> Rect2:
	var safe := safe_rect()
	var compact := _use_compact_dossier(safe)
	if compact:
		var gap := 7.0
		var columns := 2
		var width := (safe.size.x - 23.0 - gap) * 0.5
		var height := 58.0 if safe.size.y < 560.0 else 64.0
		var row := int(index / columns)
		var column := index % columns
		var start_y := safe.end.y - 3.0 * (height + gap) - 7.0
		return Rect2(
			Vector2(safe.position.x + 8.0 + float(column) * (width + gap), start_y + float(row) * (height + gap)),
			Vector2(width, height)
		)
	return super.lineage_card_rect(index)

func draw_select() -> void:
	var size := get_viewport_rect().size
	var safe := safe_rect()
	var lineage: Dictionary = LINEAGES[selected_lineage]
	var id := String(lineage["id"])
	var compact := _use_compact_dossier(safe)
	draw_rect(Rect2(Vector2.ZERO, size), Color8(3, 7, 9))
	var background: Texture2D = production_assets.call("biome_texture", "industrial_eden", "background")
	if background != null:
		draw_texture_rect(background, Rect2(Vector2.ZERO, size), false, Color(0.66, 0.75, 0.68, 0.36))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.018, 0.020, 0.58))
	draw_text_centered(
		"SELECT AN ENGINEERED LINEAGE",
		Vector2(safe.get_center().x, safe.position.y + 30.0),
		19 if compact else 27,
		Color8(238, 225, 186)
	)
	draw_text_centered(
		"FIVE SURVIVORS OF THE SEALED EDEN LAB",
		Vector2(safe.get_center().x, safe.position.y + 50.0),
		9 if compact else 10,
		Color8(129, 160, 145)
	)
	if compact:
		_draw_select_compact(safe, lineage, id)
	else:
		_draw_select_wide(safe, lineage, id)
	for i in range(LINEAGES.size()):
		_draw_lineage_roster_card(i, lineage_card_rect(i), i == selected_lineage)

func draw_player() -> void:
	if player.is_empty():
		return
	var position := Vector2(player["pos"])
	var texture_value := player_texture(String(player.get("id", "adam")))
	var action := animation_action()
	var direction_index := quantize_direction(Vector2(player.get("look", Vector2.DOWN)))
	var row := directional_row(action, direction_index)
	var frame_rate := float([5.0, 10.0, 14.0, 16.0, 10.0, 8.0][int(ACTION_ROWS[action])])
	var frame := posmod(int(visual_clock * frame_rate), 8)
	var scale := 1.58 if safe_rect().size.x >= 900.0 else 1.34
	var tint_color := Color.WHITE
	if invulnerability > 0.0 and int(invulnerability * 20.0) % 2 == 0:
		tint_color = Color(1, 1, 1, 0.42)
	draw_circle(position + Vector2(0, 19), 22.0, Color(0, 0, 0, 0.30))
	if texture_value != null:
		for offset in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
			draw_sprite(
				texture_value,
				position + offset,
				PLAYER_FRAME,
				frame,
				row,
				scale,
				Color(0.02, 0.025, 0.025, tint_color.a * 0.72)
			)
		draw_sprite(texture_value, position, PLAYER_FRAME, frame, row, scale, tint_color)
	else:
		draw_circle(position, PLAYER_RADIUS, Color(player["color"]))
	var aim := Vector2(player.get("aim", Vector2.DOWN)).normalized()
	draw_line(position + aim * 18.0, position + aim * 42.0, Color(0.96, 0.91, 0.75, 0.50), 3.0)
	draw_circle(position + aim * 43.0, 3.0, Color(0.96, 0.91, 0.75, 0.72))
	if bool(player.get("shield", false)):
		draw_arc(position, 34.0, -PI * 0.86, PI * 0.86, 32, Color8(112, 190, 247), 4.0)

func draw_hud() -> void:
	if player.is_empty():
		return
	var safe := safe_rect()
	if not _use_compact_hud(safe):
		super.draw_hud()
		return
	_draw_compact_release_hud(safe)

func _draw_compact_release_hud(safe: Rect2) -> void:
	var header := Rect2(safe.position + Vector2(5, 5), Vector2(safe.size.x - 10.0, 50.0))
	_draw_beveled_panel(header, Color(0.012, 0.030, 0.032, 0.95), Color(player["color"], 0.72), false)
	var portrait: Texture2D = production_assets.call("hero_portrait", String(player.get("id", "adam")))
	if portrait != null:
		draw_texture_rect(portrait, Rect2(header.position + Vector2(5, 4), Vector2(34, 42)), false, Color.WHITE)
	var name_x := header.position.x + 45.0
	draw_text(String(player["name"]), Vector2(name_x, header.position.y + 17.0), 11, Color8(240, 228, 194))
	var hp_ratio := clampf(float(player["hp"]) / maxf(0.001, float(player["max_hp"])), 0.0, 1.0)
	var right_zone := minf(176.0, header.size.x * 0.37)
	var hp_rect := Rect2(Vector2(name_x, header.position.y + 25.0), Vector2(maxf(70.0, header.size.x - 50.0 - right_zone), 13.0))
	draw_rect(hp_rect, Color8(48, 21, 24))
	draw_rect(Rect2(hp_rect.position, Vector2(hp_rect.size.x * hp_ratio, hp_rect.size.y)), Color8(207, 69, 65))
	draw_rect(hp_rect, Color8(230, 194, 145), false, 1.0)
	draw_text("%.1f/%.1f" % [float(player["hp"]), float(player["max_hp"])], hp_rect.position + Vector2(4, 10), 8, Color.WHITE)
	var resources_x := header.end.x - right_zone + 8.0
	draw_text("SCRAP %03d" % scraps, Vector2(resources_x, header.position.y + 17.0), 9, Color8(228, 175, 85))
	draw_text("GENOME %04d" % int(profile.get("genome", 0)), Vector2(resources_x, header.position.y + 34.0), 8, Color8(149, 210, 173))
	var pause_rect := Rect2(Vector2(header.end.x - 34.0, header.position.y + 8.0), Vector2(27, 30))
	draw_rect(pause_rect, Color(0.02, 0.05, 0.05, 0.92))
	draw_rect(pause_rect, Color8(102, 126, 113), false, 1.0)
	draw_text_centered("II", pause_rect.get_center() + Vector2(0, 4), 10, Color8(224, 218, 190))

	var objective_box := Rect2(Vector2(safe.position.x + 5.0, header.end.y + 4.0), Vector2(safe.size.x - 10.0, 28.0))
	_draw_beveled_panel(objective_box, Color(0.012, 0.030, 0.032, 0.90), Color(BIOMES[biome_index]["accent"], 0.68), false)
	var objective_text := "%s  //  %s" % [String(BIOME_CHAPTERS[biome_index]), objective.to_upper()]
	draw_text_centered(objective_text, objective_box.get_center() + Vector2(0, 4), 7, Color8(221, 216, 190))

	var combo_box := Rect2(Vector2(safe.position.x + 5.0, objective_box.end.y + 3.0), Vector2(102, 20))
	var threat_box := Rect2(Vector2(safe.end.x - 137.0, objective_box.end.y + 3.0), Vector2(132, 20))
	_draw_beveled_panel(combo_box, Color(0.012, 0.030, 0.032, 0.84), Color8(210, 164, 80) if combo > 0 else Color8(58, 81, 74), false)
	_draw_beveled_panel(threat_box, Color(0.012, 0.030, 0.032, 0.84), Color8(182, 76, 68), false)
	draw_text_centered("COMBO %02d" % combo, combo_box.get_center() + Vector2(0, 3), 7, Color8(233, 216, 173))
	draw_text_centered("THREAT %.2f" % threat_level, threat_box.get_center() + Vector2(0, 3), 7, Color8(224, 199, 178))

	if boss_max_health > 0.0 and boss_health > 0.0:
		var boss_rect := Rect2(Vector2(safe.position.x + 34.0, combo_box.end.y + 3.0), Vector2(safe.size.x - 68.0, 16.0))
		draw_rect(boss_rect, Color8(36, 15, 19))
		draw_rect(Rect2(boss_rect.position, Vector2(boss_rect.size.x * boss_health / boss_max_health, boss_rect.size.y)), Color8(183, 45, 57))
		draw_rect(boss_rect, Color8(235, 190, 113), false, 1.0)
		draw_text_centered(BOSS_NAMES[biome_index], boss_rect.get_center() + Vector2(0, 3), 7, Color.WHITE)

	var weapon: Dictionary = player.get("weapon", {})
	if not weapon.is_empty():
		var weapon_width := minf(260.0, safe.size.x * 0.46)
		var weapon_rect := Rect2(Vector2(safe.get_center().x - weapon_width * 0.5, safe.end.y - 32.0), Vector2(weapon_width, 23.0))
		_draw_beveled_panel(weapon_rect, Color(0.012, 0.030, 0.032, 0.90), Color(player["color"], 0.68), false)
		draw_text_centered(String(weapon["name"]), weapon_rect.get_center() + Vector2(0, 3), 8, Color8(233, 220, 184))
	_draw_compact_relics(safe)
	var dash_ready := clampf(1.0 - dash_timer / maxf(0.001, float(player["dash_delay"])), 0.0, 1.0)
	var dash_center := Vector2(safe.end.x - 25.0, safe.end.y - 23.0)
	draw_circle(dash_center, 15.0, Color(0.02, 0.05, 0.06, 0.90))
	draw_arc(dash_center, 14.0, -PI * 0.5, -PI * 0.5 + TAU * dash_ready, 20, Color8(105, 186, 237), 3.0)
	draw_text_centered("D", dash_center + Vector2(0, 3), 8, Color8(194, 222, 235))

func _draw_compact_relics(safe: Rect2) -> void:
	var relics: Texture2D = production_assets.call("utility_texture", "relics")
	var inventory: Array = player.get("inventory", [])
	if relics == null or inventory.is_empty():
		return
	var start := Vector2(safe.position.x + 6.0, safe.end.y - 29.0)
	for i in range(mini(5, inventory.size())):
		var relic_number := absi(String(inventory[i]).hash()) % 60
		var source := Rect2(Vector2(float(relic_number % 12) * 32.0, float(relic_number / 12) * 32.0), Vector2(32, 32))
		draw_texture_rect_region(relics, Rect2(start + Vector2(float(i) * 29.0, 0), Vector2(25, 25)), source)

func _encounter_positions(count: int) -> Array[Vector2]:
	var raw_arena := arena_rect()
	var margin := clampf(minf(raw_arena.size.x, raw_arena.size.y) * 0.16, 30.0, 88.0)
	var spawn_area := raw_arena.grow(-margin)
	if spawn_area.size.x < 100.0 or spawn_area.size.y < 100.0:
		spawn_area = raw_arena.grow(-18.0)
	var center := spawn_area.get_center()
	var positions: Array[Vector2] = []
	var radius_x := maxf(56.0, spawn_area.size.x * 0.36)
	var radius_y := maxf(44.0, spawn_area.size.y * 0.33)
	var phase := rng.randf_range(0.0, TAU)
	for index in range(count):
		var angle := phase + TAU * float(index) / float(maxi(1, count))
		var ring := 0.70 + float(index % 3) * 0.12
		var point := center + Vector2(cos(angle) * radius_x * ring, sin(angle) * radius_y * ring)
		point += Vector2(rng.randf_range(-14.0, 14.0), rng.randf_range(-12.0, 12.0))
		point.x = clampf(point.x, spawn_area.position.x, spawn_area.end.x)
		point.y = clampf(point.y, spawn_area.position.y, spawn_area.end.y)
		positions.append(point)
	return positions

func _draw_beveled_panel(rect: Rect2, fill: Color, border_color: Color, focused: bool) -> void:
	draw_rect(rect, fill)
	var border := Color(border_color, 0.92 if focused else 0.68)
	var width := 2.0 if focused else 1.0
	draw_rect(rect, border, false, width)
	var corner := minf(12.0, minf(rect.size.x, rect.size.y) * 0.18)
	draw_line(rect.position, rect.position + Vector2(corner, 0), border, 2.0)
	draw_line(rect.position, rect.position + Vector2(0, corner), border, 2.0)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x - corner, rect.position.y), border, 2.0)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.position.y + corner), border, 2.0)
	draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x + corner, rect.end.y), border, 2.0)
	draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x, rect.end.y - corner), border, 2.0)
	draw_line(rect.end, rect.end - Vector2(corner, 0), border, 2.0)
	draw_line(rect.end, rect.end - Vector2(0, corner), border, 2.0)

func _use_compact_dossier(safe: Rect2) -> bool:
	return safe.size.x < 900.0 or safe.size.y < 650.0 or safe.size.y > safe.size.x * 1.08

func _use_compact_hud(safe: Rect2) -> bool:
	return safe.size.x < 920.0 or safe.size.y < 610.0
