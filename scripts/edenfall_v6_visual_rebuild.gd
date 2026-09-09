extends "res://scripts/edenfall_v6_runtime.gd"

const VISUAL_VERSION := "0.6.1"
const VisualRegistryScript: Script = preload("res://scripts/v6/asset_registry_rebuild.gd")

const HERO_ROLES := {
	"adam": "SURVIVOR / SUSTAIN",
	"abel": "PRECISION / CRITICAL",
	"cain": "BREACHER / CLOSE RANGE",
	"seth": "ENGINEER / DEFENSE",
	"naamah": "MYCELIAL / RECOVERY",
}
const HERO_WEAPONS := {
	"adam": "EDEN SERVICE RIFLE",
	"abel": "SHEPHERD LIGHTCASTER",
	"cain": "MARKED IMPACT GAUNTLETS",
	"seth": "AEGIS COIL CARBINE",
	"naamah": "SPORE CHOIR ORB",
}
const BIOME_CHAPTERS := [
	"I  THE GARDEN BELOW",
	"II  ROADS OF ASH",
	"III  THE GLASS LITURGY",
	"IV  NAAMAH'S CHORUS",
	"V  THE CITY THAT REMEMBERS",
]

func _ready() -> void:
	production_assets = VisualRegistryScript.new()
	super._ready()

func lineage_card_rect(index: int) -> Rect2:
	var safe := safe_rect()
	var compact := safe.size.x < 760.0 or safe.size.y > safe.size.x * 1.18
	if compact:
		var gap := 8.0
		var columns := 2
		var width := (safe.size.x - 24.0 - gap) * 0.5
		var height := 62.0
		var row := index / columns
		var column := index % columns
		var start_y := safe.end.y - 3.0 * (height + gap) - 10.0
		return Rect2(Vector2(safe.position.x + 8.0 + float(column) * (width + gap), start_y + float(row) * (height + gap)), Vector2(width, height))
	var gap := 10.0
	var margin := 22.0
	var width := (safe.size.x - margin * 2.0 - gap * 4.0) / 5.0
	var height := clampf(safe.size.y * 0.145, 86.0, 118.0)
	return Rect2(Vector2(safe.position.x + margin + float(index) * (width + gap), safe.end.y - height - 18.0), Vector2(width, height))

func draw_title() -> void:
	var size := get_viewport_rect().size
	var safe := safe_rect()
	var biome: Texture2D = production_assets.call("biome_texture", "industrial_eden", "background")
	draw_rect(Rect2(Vector2.ZERO, size), Color8(3, 7, 9))
	if biome != null:
		draw_texture_rect(biome, Rect2(Vector2.ZERO, size), false, Color(0.72, 0.82, 0.75, 0.62))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.025, 0.026, 0.44))
	var portal := Vector2(safe.get_center().x, safe.position.y + safe.size.y * 0.31)
	for radius in [176.0, 139.0, 104.0, 70.0]:
		draw_arc(portal, radius, -PI * 0.90, PI * 0.90, 80, Color(0.43, 0.72, 0.48, 0.20), 3.0)
	for rib in range(9):
		var angle := lerpf(-PI * 0.78, PI * 0.78, float(rib) / 8.0)
		var start := portal + Vector2(cos(angle), sin(angle)) * 74.0
		var finish := portal + Vector2(cos(angle), sin(angle)) * 166.0
		draw_line(start, finish, Color(0.52, 0.72, 0.48, 0.16), 2.0)
	draw_text_centered("GAMEISH", Vector2(safe.get_center().x, safe.position.y + 31.0), 13, Color8(124, 159, 143))
	draw_text_centered("EDEN//FALL", Vector2(safe.get_center().x, safe.position.y + safe.size.y * 0.49), 58 if safe.size.x >= 900.0 else 40, Color8(239, 225, 181))
	draw_text_centered("LEAVE THE GARDEN. CROSS THE DEAD CITIES. FIND WHAT BUILT EDEN.", Vector2(safe.get_center().x, safe.position.y + safe.size.y * 0.49 + 37.0), 13 if safe.size.x >= 900.0 else 10, Color8(154, 181, 165))
	for i in range(title_options().size()):
		var rect := title_option_rect(i)
		var selected := i == menu_index
		_draw_beveled_panel(rect, Color8(17, 31, 30, 244) if selected else Color8(8, 17, 19, 226), Color8(153, 202, 135) if selected else Color8(61, 91, 81), selected)
		draw_text_centered(title_options()[i], rect.get_center() + Vector2(0, 6), 14, Color8(240, 230, 198) if selected else Color8(179, 191, 178))
	var footer := "v%s  •  GODOT 4.7.1  •  %s  •  GENOME %d" % [VISUAL_VERSION, String(platform_report.get("platform", "unknown")).to_upper(), int(profile.get("genome", 0))]
	draw_text_centered(footer, Vector2(safe.get_center().x, safe.end.y - 10.0), 10, Color8(102, 132, 119))

func draw_select() -> void:
	var size := get_viewport_rect().size
	var safe := safe_rect()
	var lineage: Dictionary = LINEAGES[selected_lineage]
	var id := String(lineage["id"])
	var compact := safe.size.x < 760.0 or safe.size.y > safe.size.x * 1.18
	draw_rect(Rect2(Vector2.ZERO, size), Color8(3, 7, 9))
	var background: Texture2D = production_assets.call("biome_texture", "industrial_eden", "background")
	if background != null:
		draw_texture_rect(background, Rect2(Vector2.ZERO, size), false, Color(0.66, 0.75, 0.68, 0.36))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.018, 0.020, 0.58))
	draw_text_centered("SELECT AN ENGINEERED LINEAGE", Vector2(safe.get_center().x, safe.position.y + 33.0), 27 if not compact else 20, Color8(238, 225, 186))
	draw_text_centered("FIVE SURVIVORS OF THE SEALED EDEN LAB", Vector2(safe.get_center().x, safe.position.y + 55.0), 10, Color8(129, 160, 145))
	if compact:
		_draw_select_compact(safe, lineage, id)
	else:
		_draw_select_wide(safe, lineage, id)
	for i in range(LINEAGES.size()):
		_draw_lineage_roster_card(i, lineage_card_rect(i), i == selected_lineage)

func _draw_select_wide(safe: Rect2, lineage: Dictionary, id: String) -> void:
	var roster_top := lineage_card_rect(0).position.y
	var content := Rect2(Vector2(safe.position.x + 22.0, safe.position.y + 76.0), Vector2(safe.size.x - 44.0, roster_top - safe.position.y - 90.0))
	var portrait_panel := Rect2(content.position, Vector2(content.size.x * 0.39, content.size.y))
	var dossier_panel := Rect2(Vector2(portrait_panel.end.x + 14.0, content.position.y), Vector2(content.end.x - portrait_panel.end.x - 14.0, content.size.y))
	_draw_beveled_panel(portrait_panel, Color8(7, 16, 18, 238), Color(lineage["color"]), true)
	_draw_beveled_panel(dossier_panel, Color8(7, 16, 18, 238), Color8(74, 106, 95), false)
	var portrait: Texture2D = production_assets.call("hero_portrait", id)
	if portrait != null:
		var max_height := portrait_panel.size.y - 46.0
		var portrait_width := minf(portrait_panel.size.x - 36.0, max_height * 0.80)
		var portrait_height := portrait_width * 1.25
		var portrait_rect := Rect2(Vector2(portrait_panel.get_center().x - portrait_width * 0.5, portrait_panel.get_center().y - portrait_height * 0.5 + 6.0), Vector2(portrait_width, portrait_height))
		draw_texture_rect(portrait, portrait_rect, false, Color.WHITE)
	draw_text(String(HERO_ROLES[id]), portrait_panel.position + Vector2(20, 29), 11, Color8(149, 184, 163))
	draw_text_centered(String(lineage["name"]), Vector2(dossier_panel.get_center().x, dossier_panel.position.y + 53.0), 42, Color(lineage["color"]))
	draw_text_centered(String(lineage["epithet"]).to_upper(), Vector2(dossier_panel.get_center().x, dossier_panel.position.y + 81.0), 13, Color8(195, 201, 184))
	var weapon_box := Rect2(dossier_panel.position + Vector2(30, 105), Vector2(dossier_panel.size.x - 60.0, 42.0))
	_draw_beveled_panel(weapon_box, Color8(12, 25, 26), Color(lineage["color"], 0.72), false)
	draw_text("STARTING ARMAMENT", weapon_box.position + Vector2(13, 16), 9, Color8(116, 147, 134))
	draw_text(String(HERO_WEAPONS[id]), weapon_box.position + Vector2(13, 33), 12, Color8(236, 225, 194))
	var trait_box := Rect2(dossier_panel.position + Vector2(30, 158), Vector2(dossier_panel.size.x - 60.0, 84.0))
	_draw_beveled_panel(trait_box, Color8(10, 21, 22), Color8(61, 92, 83), false)
	draw_text("INHERITED PROTOCOL", trait_box.position + Vector2(13, 18), 9, Color8(116, 147, 134))
	draw_wrapped(String(lineage["trait"]), Rect2(trait_box.position + Vector2(12, 29), Vector2(trait_box.size.x - 24.0, 48.0)), 13, Color8(224, 216, 190))
	var stats_top := trait_box.end.y + 17.0
	_draw_stat_bar(dossier_panel, "VITALITY", float(lineage["max_hp"]) / 8.0, "%.0f CELLS" % float(lineage["max_hp"]), stats_top, Color8(209, 76, 70))
	_draw_stat_bar(dossier_panel, "DAMAGE", float(lineage["damage"]) / 16.0, "%.1f" % float(lineage["damage"]), stats_top + 35.0, Color(lineage["color"]))
	_draw_stat_bar(dossier_panel, "MOBILITY", inverse_lerp(220.0, 290.0, float(lineage["speed"])), "%.0f" % float(lineage["speed"]), stats_top + 70.0, Color8(105, 184, 226))
	var deploy := Rect2(Vector2(dossier_panel.position.x + 30.0, dossier_panel.end.y - 52.0), Vector2(dossier_panel.size.x - 60.0, 36.0))
	_draw_beveled_panel(deploy, Color(lineage["color"], 0.16), Color(lineage["color"]), true)
	draw_text_centered("ENTER / CLICK ROSTER TO BREAK THE LAB SEAL", deploy.get_center() + Vector2(0, 5), 11, Color8(242, 233, 203))

func _draw_select_compact(safe: Rect2, lineage: Dictionary, id: String) -> void:
	var cards_top := lineage_card_rect(0).position.y
	var summary := Rect2(Vector2(safe.position.x + 8.0, safe.position.y + 68.0), Vector2(safe.size.x - 16.0, cards_top - safe.position.y - 78.0))
	_draw_beveled_panel(summary, Color8(7, 16, 18, 238), Color(lineage["color"]), true)
	var portrait: Texture2D = production_assets.call("hero_portrait", id)
	var portrait_width := minf(summary.size.x * 0.38, summary.size.y * 0.64)
	if portrait != null:
		draw_texture_rect(portrait, Rect2(summary.position + Vector2(10, 15), Vector2(portrait_width, portrait_width * 1.25)), false, Color.WHITE)
	var text_x := summary.position.x + portrait_width + 24.0
	draw_text(String(lineage["name"]), Vector2(text_x, summary.position.y + 36.0), 26, Color(lineage["color"]))
	draw_text(String(lineage["epithet"]), Vector2(text_x, summary.position.y + 57.0), 11, Color8(188, 197, 181))
	draw_text(String(HERO_ROLES[id]), Vector2(text_x, summary.position.y + 76.0), 9, Color8(127, 159, 143))
	draw_wrapped(String(lineage["trait"]), Rect2(Vector2(text_x, summary.position.y + 91.0), Vector2(summary.end.x - text_x - 10.0, 48.0)), 10, Color8(222, 214, 188))
	draw_text("HP %.0f   DMG %.1f   SPD %.0f" % [float(lineage["max_hp"]), float(lineage["damage"]), float(lineage["speed"])], Vector2(text_x, summary.end.y - 17.0), 10, Color8(236, 224, 193))

func _draw_lineage_roster_card(index: int, rect: Rect2, selected: bool) -> void:
	var lineage: Dictionary = LINEAGES[index]
	var id := String(lineage["id"])
	_draw_beveled_panel(rect, Color8(17, 31, 30, 245) if selected else Color8(7, 15, 17, 230), Color(lineage["color"]) if selected else Color8(54, 76, 70), selected)
	var texture_value: Texture2D = player_texture(id)
	var frame := posmod(int(visual_clock * 5.0 + float(index)), 8)
	if texture_value != null:
		draw_sprite(texture_value, Vector2(rect.position.x + 39.0, rect.get_center().y + 2.0), PLAYER_FRAME, frame, directional_row("idle", 4), 1.05 if rect.size.y > 70.0 else 0.82)
	var name_x := rect.position.x + 76.0
	draw_text(String(lineage["name"]), Vector2(name_x, rect.position.y + 29.0), 15 if rect.size.y > 70.0 else 12, Color(lineage["color"]))
	draw_text(String(HERO_ROLES[id]), Vector2(name_x, rect.position.y + 48.0), 8, Color8(131, 158, 145))
	if rect.size.y > 80.0:
		draw_text("%d" % (index + 1), Vector2(rect.end.x - 22.0, rect.end.y - 12.0), 9, Color8(108, 134, 122))

func draw_run() -> void:
	var shake := Vector2.ZERO if bool(settings["reduced_motion"]) else camera_shake
	draw_set_transform(shake)
	draw_arena()
	draw_doors()
	draw_pickups()
	draw_bullets()
	draw_enemies()
	draw_player()
	draw_effects()
	draw_set_transform(Vector2.ZERO)
	draw_hud()
	draw_touch_controls()
	if notification_timer > 0.0:
		var safe := safe_rect()
		var width := minf(560.0, safe.size.x - 36.0)
		var box := Rect2(Vector2(safe.get_center().x - width * 0.5, safe.position.y + 78.0), Vector2(width, 34.0))
		_draw_beveled_panel(box, Color(0.02, 0.05, 0.05, 0.94), Color8(121, 174, 135), false)
		draw_text_centered(notification, box.get_center() + Vector2(0, 5), 11, Color8(234, 226, 196))
	if paused:
		draw_pause()

func draw_arena() -> void:
	var size := get_viewport_rect().size
	var arena := arena_rect()
	var biome: Dictionary = BIOMES[biome_index]
	var biome_id := String(biome["id"])
	draw_rect(Rect2(Vector2.ZERO, size), Color8(3, 7, 9))
	var background: Texture2D = production_assets.call("biome_texture", biome_id, "background")
	if background != null:
		draw_texture_rect(background, Rect2(Vector2.ZERO, size), false, Color(0.78, 0.82, 0.78, 0.52))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.005, 0.014, 0.016, 0.38))
	draw_rect(arena.grow(9.0), Color(0.01, 0.025, 0.025, 0.86))
	draw_rect(arena, Color(biome["floor"], 0.93))
	var tiles: Texture2D = production_assets.call("biome_texture", biome_id, "tiles")
	if tiles != null:
		var cell := 96
		var row := 0
		for y in range(int(arena.position.y), int(arena.end.y), cell):
			var column := 0
			for x in range(int(arena.position.x), int(arena.end.x), cell):
				var tile_index := posmod(column * 5 + row * 9 + biome_index * 7 + current_room.x * 3 + current_room.y * 11, 32)
				var source := Rect2(Vector2(float(tile_index % 8) * 32.0, float(tile_index / 8) * 32.0), Vector2(32, 32))
				var destination := Rect2(Vector2(x, y), Vector2(mini(cell, int(arena.end.x) - x), mini(cell, int(arena.end.y) - y)))
				draw_texture_rect_region(tiles, destination, source, Color(1, 1, 1, 0.31))
				column += 1
			row += 1
	for x in range(int(arena.position.x + 96.0), int(arena.end.x), 96):
		draw_line(Vector2(x, arena.position.y), Vector2(x, arena.end.y), Color(0.42, 0.55, 0.47, 0.055), 1.0)
	for y in range(int(arena.position.y + 96.0), int(arena.end.y), 96):
		draw_line(Vector2(arena.position.x, y), Vector2(arena.end.x, y), Color(0.42, 0.55, 0.47, 0.055), 1.0)
	_draw_environment_decals(arena, biome_id, Color(biome["accent"]))
	var props: Texture2D = production_assets.call("biome_texture", biome_id, "props")
	if props != null:
		var prop_height := clampf(arena.size.y * 0.17, 62.0, 104.0)
		draw_texture_rect(props, Rect2(Vector2(arena.position.x + 8.0, arena.position.y + 3.0), Vector2(arena.size.x - 16.0, prop_height)), false, Color(1, 1, 1, 0.72))
		draw_texture_rect(props, Rect2(Vector2(arena.position.x + 8.0, arena.end.y - prop_height - 3.0), Vector2(arena.size.x - 16.0, prop_height)), false, Color(0.86, 0.92, 0.86, 0.80))
	draw_rect(arena, Color(biome["accent"], 0.80), false, 3.0)
	draw_rect(arena.grow(-6.0), Color(0.70, 0.82, 0.72, 0.12), false, 1.0)
	if current_modifier == "corrosive_grid":
		var pulse := 0.22 + 0.16 * sin(visual_clock * 3.0)
		draw_line(Vector2(arena.get_center().x, arena.position.y), Vector2(arena.get_center().x, arena.end.y), Color(0.35, 0.85, 0.32, pulse), 7.0)
		draw_line(Vector2(arena.position.x, arena.get_center().y), Vector2(arena.end.x, arena.get_center().y), Color(0.35, 0.85, 0.32, pulse), 7.0)
	elif current_modifier == "blackout" and not player.is_empty():
		for radius in [380.0, 315.0, 250.0]:
			draw_arc(Vector2(player.get("pos", arena.get_center())), radius, 0.0, TAU, 72, Color(0.0, 0.0, 0.0, 0.32), 48.0)

func _draw_environment_decals(arena: Rect2, biome_id: String, accent: Color) -> void:
	var seed := absi((biome_id + str(current_room)).hash())
	for index in range(15):
		var x := arena.position.x + 64.0 + float(posmod(seed + index * 173, maxi(1, int(arena.size.x - 128.0))))
		var y := arena.position.y + 60.0 + float(posmod(seed + index * 97, maxi(1, int(arena.size.y - 120.0))))
		var pos := Vector2(x, y)
		var edge_distance := minf(minf(pos.x - arena.position.x, arena.end.x - pos.x), minf(pos.y - arena.position.y, arena.end.y - pos.y))
		if edge_distance < 105.0:
			match biome_id:
				"industrial_eden":
					draw_line(pos - Vector2(12, 18), pos + Vector2(5, 20), Color(accent, 0.24), 3.0)
					for leaf in range(3):
						draw_circle(pos + Vector2(-8 + leaf * 7, -8 + leaf * 12), 4.0, Color(accent.lightened(0.12), 0.18))
				"ash_wastes":
					draw_line(pos - Vector2(17, 9), pos + Vector2(18, 12), Color(accent, 0.22), 3.0)
					draw_rect(Rect2(pos - Vector2(11, 5), Vector2(22, 10)), Color(0.15, 0.09, 0.07, 0.20))
				"temple_lab":
					draw_arc(pos, 17.0, 0.0, TAU, 24, Color(accent, 0.20), 2.0)
					draw_line(pos - Vector2(11, 0), pos + Vector2(11, 0), Color(accent, 0.18), 2.0)
				"fungal_garden":
					for spore in range(4):
						draw_circle(pos + Vector2(-7 + spore * 5, sin(float(spore)) * 7.0), 3.0 + float(spore % 2), Color(accent, 0.18))
				_:
					draw_line(pos - Vector2(14, 17), pos + Vector2(10, 19), Color(accent, 0.17), 3.0)
					draw_line(pos + Vector2(8, -15), pos - Vector2(11, 18), Color(0.75, 0.70, 0.64, 0.13), 2.0)

func draw_doors() -> void:
	if not room_graph.has(current_room):
		return
	var room: Dictionary = room_graph[current_room]
	for direction_variant in room["neighbors"]:
		var direction := Vector2i(direction_variant)
		var center := door_position(direction)
		var open := bool(room["cleared"])
		var color := Color8(105, 215, 137) if open else Color8(210, 73, 65)
		var horizontal := direction.y != 0
		var rect := Rect2(center - (Vector2(58, 14) if horizontal else Vector2(14, 58)), Vector2(116, 28) if horizontal else Vector2(28, 116))
		draw_rect(rect.grow(5.0), Color(0.01, 0.025, 0.026, 0.95))
		draw_rect(rect, Color(0.025, 0.055, 0.055, 0.96))
		draw_rect(rect, Color(color, 0.86), false, 3.0)
		if open:
			draw_rect(rect.grow(-7.0), Color(color, 0.08))
			draw_line(rect.get_center() - (Vector2(29, 0) if horizontal else Vector2(0, 29)), rect.get_center() + (Vector2(29, 0) if horizontal else Vector2(0, 29)), Color(color, 0.74), 3.0)
		else:
			for bar in range(4):
				if horizontal:
					var y := rect.position.y + 6.0 + float(bar) * 5.0
					draw_line(Vector2(rect.position.x + 9.0, y), Vector2(rect.end.x - 9.0, y), Color(color, 0.64), 2.0)
				else:
					var x := rect.position.x + 6.0 + float(bar) * 5.0
					draw_line(Vector2(x, rect.position.y + 9.0), Vector2(x, rect.end.y - 9.0), Color(color, 0.64), 2.0)

func draw_player() -> void:
	if player.is_empty():
		return
	var pos := Vector2(player["pos"])
	var texture_value := player_texture(String(player.get("id", "adam")))
	var action := animation_action()
	var direction_index := quantize_direction(Vector2(player.get("look", Vector2.DOWN)))
	var row := directional_row(action, direction_index)
	var frame_rate := float([5.0, 10.0, 14.0, 16.0, 10.0, 8.0][int(ACTION_ROWS[action])])
	var frame := posmod(int(visual_clock * frame_rate), 8)
	var scale := 1.58 if safe_rect().size.x >= 900.0 else 1.38
	var tint_color := Color.WHITE
	if invulnerability > 0.0 and int(invulnerability * 20.0) % 2 == 0:
		tint_color = Color(1, 1, 1, 0.42)
	draw_set_transform(Vector2.ZERO)
	draw_circle(pos + Vector2(0, 19), 22.0, Color(0, 0, 0, 0.30))
	if texture_value != null:
		for offset in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
			draw_sprite(texture_value, pos + offset, PLAYER_FRAME, frame, row, scale, Color(0.02, 0.025, 0.025, tint_color.a * 0.72))
		draw_sprite(texture_value, pos, PLAYER_FRAME, frame, row, scale, tint_color)
	else:
		draw_circle(pos, PLAYER_RADIUS, Color(player["color"]))
	var aim := Vector2(player.get("aim", Vector2.DOWN)).normalized()
	draw_line(pos + aim * 18.0, pos + aim * 42.0, Color(0.96, 0.91, 0.75, 0.50), 3.0)
	draw_circle(pos + aim * 43.0, 3.0, Color(0.96, 0.91, 0.75, 0.72))
	if bool(player.get("shield", false)):
		draw_arc(pos, 34.0, -PI * 0.86, PI * 0.86, 32, Color8(112, 190, 247), 4.0)

func draw_enemies() -> void:
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		var pos := Vector2(enemy["pos"])
		var radius := float(enemy["radius"])
		var action := "idle"
		if float(enemy.get("hurt", 0.0)) > 0.0:
			action = "hurt"
		elif float(enemy.get("attack", 0.0)) > 0.0:
			action = "attack"
		elif Vector2(enemy.get("velocity", Vector2.ZERO)).length() > 8.0:
			action = "walk"
		var direction_index := quantize_direction(Vector2(enemy.get("look", Vector2.DOWN)))
		var frame_rate := 10.0 if action == "walk" else (14.0 if action == "attack" else 6.0)
		var frame := posmod(int((visual_clock + float(enemy.get("variant", 0)) * 0.13) * frame_rate), 8)
		var texture_value: Texture2D
		var frame_size := PLAYER_FRAME
		var scale := maxf(1.18, radius / 18.0 * 1.16)
		var row := directional_row(action, direction_index)
		if bool(enemy.get("boss", false)):
			texture_value = boss_texture(biome_index)
			frame_size = BOSS_FRAME
			scale = maxf(1.15, radius / 48.0 * 1.20)
			var boss_action := 1 if action == "attack" else (2 if int(enemy.get("stage", 0)) > 0 and int(visual_clock * 4.0) % 7 == 0 else 0)
			row = boss_action * 8 + direction_index
		else:
			texture_value = enemy_texture(String(enemy["id"]))
		draw_circle(pos + Vector2(0, radius * 0.78), radius * 0.78, Color(0, 0, 0, 0.27))
		if float(enemy.get("cooldown", 1.0)) < 0.22 and not bool(enemy.get("boss", false)):
			var pulse := 0.45 + 0.35 * sin(visual_clock * 18.0)
			draw_arc(pos, radius + 13.0, 0.0, TAU, 28, Color(1.0, 0.48, 0.28, pulse), 3.0)
			if String(enemy.get("style", "")) in ["ranged", "caster", "skirmisher"] and not player.is_empty():
				draw_line(pos, Vector2(player["pos"]), Color(1.0, 0.34, 0.25, 0.10), 2.0)
		if texture_value != null:
			for offset in [Vector2(-1.5, 0), Vector2(1.5, 0), Vector2(0, -1.5), Vector2(0, 1.5)]:
				draw_sprite(texture_value, pos + offset, frame_size, frame, row, scale, Color(0.02, 0.02, 0.02, 0.68))
			draw_sprite(texture_value, pos, frame_size, frame, row, scale, Color.WHITE)
		var elite := bool(enemy.get("elite", false))
		if elite:
			var affix := String(enemy.get("affix", ""))
			var definition: Dictionary = director.elite_definition(affix)
			var elite_color: Color = definition.get("color", Color8(226, 188, 102))
			draw_arc(pos, radius + 10.0, visual_clock, visual_clock + PI * 1.60, 30, elite_color, 3.0)
			if affix != "boss":
				draw_text_centered(String(definition.get("name", affix.to_upper())), pos - Vector2(0, radius + 18.0), 8, elite_color)
		if float(enemy.get("shield_hp", 0.0)) > 0.0:
			draw_arc(pos, radius + 5.0, -PI * 0.85, PI * 0.85, 26, Color8(121, 171, 244), 3.0)
		var hp_ratio := clampf(float(enemy["hp"]) / maxf(0.001, float(enemy["max_hp"])), 0.0, 1.0)
		if hp_ratio < 0.999 or elite or bool(enemy.get("boss", false)):
			var width := clampf(radius * 2.25, 36.0, 98.0)
			var health_rect := Rect2(pos + Vector2(-width * 0.5, radius + 13.0), Vector2(width, 7.0 if elite else 5.0))
			draw_rect(health_rect, Color8(35, 17, 19, 225))
			draw_rect(Rect2(health_rect.position, Vector2(health_rect.size.x * hp_ratio, health_rect.size.y)), Color8(215, 72, 64))
			draw_rect(health_rect, Color8(238, 193, 142, 170), false, 1.0)
		var status_index := 0
		for status in ["burn", "marked", "spore", "stagger"]:
			if float(enemy.get(status, 0.0)) > 0.0:
				draw_circle(pos + Vector2(-16.0 + float(status_index) * 11.0, -radius - 9.0), 3.5, STATUS_COLORS[status])
				status_index += 1

func draw_bullets() -> void:
	var atlas: Texture2D = production_assets.call("utility_texture", "projectiles")
	if atlas == null:
		return
	var frame := posmod(int(visual_clock * 20.0), 8)
	for bullet_variant in bullets:
		var bullet: Dictionary = bullet_variant
		var pos := Vector2(bullet["pos"])
		var velocity := Vector2(bullet["vel"])
		var owner := String(bullet["owner"])
		var color: Color = Color(bullet["color"])
		var row := clampi(selected_lineage, 0, 4) if owner == "player" else 5
		var size := 17.0 if owner == "player" else 20.0
		if bool(bullet.get("critical", false)):
			size += 7.0
		var direction := velocity.normalized()
		for trail in range(1, 4):
			var trail_pos := pos - direction * float(trail * 7)
			draw_circle(trail_pos, maxf(1.5, size * 0.18 - float(trail) * 0.45), Color(color, 0.30 - float(trail) * 0.065))
		draw_circle(pos, size * 0.58, Color(color, 0.16))
		var source := Rect2(Vector2(float(frame * 16), float(row * 16)), Vector2(16, 16))
		draw_texture_rect_region(atlas, Rect2(pos - Vector2.ONE * size * 0.5, Vector2.ONE * size), source, Color.WHITE)
		if owner == "enemy":
			draw_arc(pos, size * 0.38, 0.0, TAU, 12, Color(1.0, 0.72, 0.54, 0.82), 2.0)

func draw_effects() -> void:
	var atlas: Texture2D = production_assets.call("utility_texture", "effects")
	for effect_variant in effects:
		var effect: Dictionary = effect_variant
		var id := String(effect.get("id", "effect"))
		if id == "chain" and effect.has("target"):
			var chain_alpha := clampf(float(effect["life"]) / maxf(0.001, float(effect["max_life"])), 0.0, 1.0)
			draw_line(Vector2(effect["pos"]), Vector2(effect["target"]), Color(effect["color"], chain_alpha), 4.0)
			continue
		var progress := 1.0 - float(effect["life"]) / maxf(0.001, float(effect["max_life"]))
		var frame := clampi(int(progress * 7.99), 0, 7)
		var row := absi(id.hash()) % 8
		var size := 34.0 + progress * 32.0
		if atlas != null:
			var source := Rect2(Vector2(float(frame * 32), float(row * 32)), Vector2(32, 32))
			draw_texture_rect_region(atlas, Rect2(Vector2(effect["pos"]) - Vector2.ONE * size * 0.5, Vector2.ONE * size), source, Color(effect["color"], 1.0 - progress * 0.55))
		else:
			draw_arc(Vector2(effect["pos"]), size * 0.4, 0.0, TAU, 24, Color(effect["color"], 1.0 - progress), 3.0)
	for number_variant in damage_numbers:
		var number: Dictionary = number_variant
		draw_text_centered(String(number["text"]), Vector2(number["pos"]), 15, Color(number["color"]))

func draw_hud() -> void:
	if player.is_empty():
		return
	var safe := safe_rect()
	var compact := use_compact_layout()
	var header_height := 64.0 if not compact else 54.0
	var gap := 8.0
	var left_width := minf(330.0, safe.size.x * (0.31 if not compact else 0.48))
	var right_width := minf(275.0, safe.size.x * (0.26 if not compact else 0.43))
	var left := Rect2(safe.position + Vector2(7, 7), Vector2(left_width, header_height))
	var right := Rect2(Vector2(safe.end.x - right_width - 7.0, safe.position.y + 7.0), Vector2(right_width, header_height))
	var center := Rect2(Vector2(left.end.x + gap, safe.position.y + 7.0), Vector2(maxf(160.0, right.position.x - left.end.x - gap * 2.0), header_height))
	_draw_beveled_panel(left, Color(0.015, 0.035, 0.036, 0.94), Color(player["color"], 0.72), false)
	_draw_beveled_panel(center, Color(0.015, 0.035, 0.036, 0.92), Color(BIOMES[biome_index]["accent"], 0.66), false)
	_draw_beveled_panel(right, Color(0.015, 0.035, 0.036, 0.94), Color8(66, 94, 85), false)
	var portrait: Texture2D = production_assets.call("hero_portrait", String(player.get("id", "adam")))
	if portrait != null:
		draw_texture_rect(portrait, Rect2(left.position + Vector2(7, 6), Vector2(40, 50)), false, Color.WHITE)
	var text_x := left.position.x + 54.0
	draw_text(String(player["name"]), Vector2(text_x, left.position.y + 21.0), 13, Color8(240, 228, 194))
	var hp_ratio := clampf(float(player["hp"]) / maxf(0.001, float(player["max_hp"])), 0.0, 1.0)
	var hp_rect := Rect2(Vector2(text_x, left.position.y + 30.0), Vector2(left.end.x - text_x - 10.0, 14.0))
	draw_rect(hp_rect, Color8(48, 21, 24))
	draw_rect(Rect2(hp_rect.position, Vector2(hp_rect.size.x * hp_ratio, hp_rect.size.y)), Color8(207, 69, 65))
	draw_rect(hp_rect, Color8(230, 194, 145), false, 1.0)
	draw_text("%.1f / %.1f" % [float(player["hp"]), float(player["max_hp"])], hp_rect.position + Vector2(5, 11), 8, Color.WHITE)
	if bool(player.get("shield", false)):
		draw_text("AEGIS", Vector2(left.end.x - 45.0, left.position.y + 21.0), 8, Color8(116, 195, 247))
	draw_text_centered(String(BIOME_CHAPTERS[biome_index]), Vector2(center.get_center().x, center.position.y + 20.0), 11 if not compact else 8, Color8(236, 223, 188))
	draw_text_centered(objective.to_upper(), Vector2(center.get_center().x, center.position.y + 41.0), 9 if not compact else 7, Color8(144, 173, 159))
	if not compact:
		draw_text("SCRAP %03d" % scraps, right.position + Vector2(12, 21), 11, Color8(228, 175, 85))
		draw_text("GENOME %04d" % int(profile.get("genome", 0)), right.position + Vector2(12, 42), 10, Color8(149, 210, 173))
		draw_minimap(Rect2(Vector2(right.end.x - 101.0, right.position.y + 7.0), Vector2(91, 49)))
	else:
		draw_text("S %03d  G %04d" % [scraps, int(profile.get("genome", 0))], right.position + Vector2(10, 22), 9, Color8(220, 187, 119))
		draw_text("ROOM %02d" % rooms_cleared, right.position + Vector2(10, 41), 8, Color8(145, 194, 168))
	var chip_y := safe.position.y + header_height + 13.0
	var combo_chip := Rect2(Vector2(safe.position.x + 7.0, chip_y), Vector2(138, 24))
	var threat_chip := Rect2(Vector2(safe.end.x - 168.0, chip_y), Vector2(161, 24))
	_draw_beveled_panel(combo_chip, Color(0.015, 0.035, 0.036, 0.87), Color8(215, 170, 84) if combo > 0 else Color8(60, 83, 76), false)
	draw_text_centered("COMBO %02d" % combo, combo_chip.get_center() + Vector2(0, 4), 9, Color8(233, 216, 173))
	_draw_beveled_panel(threat_chip, Color(0.015, 0.035, 0.036, 0.87), Color8(182, 76, 68), false)
	draw_text_centered("THREAT %.2f  %s" % [threat_level, modifier_name(current_modifier)], threat_chip.get_center() + Vector2(0, 4), 8, Color8(224, 199, 178))
	if boss_max_health > 0.0 and boss_health > 0.0:
		var boss_width := minf(620.0, safe.size.x - 80.0)
		var boss_rect := Rect2(Vector2(safe.get_center().x - boss_width * 0.5, chip_y + 31.0), Vector2(boss_width, 19.0))
		draw_rect(boss_rect, Color8(36, 15, 19))
		draw_rect(Rect2(boss_rect.position, Vector2(boss_rect.size.x * boss_health / boss_max_health, boss_rect.size.y)), Color8(183, 45, 57))
		draw_rect(boss_rect, Color8(235, 190, 113), false, 2.0)
		draw_text_centered(BOSS_NAMES[biome_index], boss_rect.get_center() + Vector2(0, 4), 9, Color.WHITE)
	var weapon: Dictionary = player.get("weapon", {})
	if not weapon.is_empty():
		var weapon_width := minf(330.0, safe.size.x * 0.38)
		var weapon_rect := Rect2(Vector2(safe.get_center().x - weapon_width * 0.5, safe.end.y - 43.0), Vector2(weapon_width, 27.0))
		_draw_beveled_panel(weapon_rect, Color(0.015, 0.035, 0.036, 0.88), Color(player["color"], 0.68), false)
		draw_text_centered(String(weapon["name"]), weapon_rect.get_center() + Vector2(0, 4), 9, Color8(233, 220, 184))
	var relics: Texture2D = production_assets.call("utility_texture", "relics")
	var inventory: Array = player.get("inventory", [])
	if relics != null and not inventory.is_empty():
		var start := Vector2(safe.position.x + 8.0, safe.end.y - 39.0)
		for i in range(mini(8, inventory.size())):
			var relic_number := absi(String(inventory[i]).hash()) % 60
			var source := Rect2(Vector2(float(relic_number % 12) * 32.0, float(relic_number / 12) * 32.0), Vector2(32, 32))
			draw_texture_rect_region(relics, Rect2(start + Vector2(float(i) * 37.0, 0), Vector2(31, 31)), source)
	var dash_ready := clampf(1.0 - dash_timer / maxf(0.001, float(player["dash_delay"])), 0.0, 1.0)
	var dash_center := Vector2(safe.end.x - 31.0, safe.end.y - 29.0)
	draw_circle(dash_center, 18.0, Color(0.02, 0.05, 0.06, 0.86))
	draw_arc(dash_center, 17.0, -PI * 0.5, -PI * 0.5 + TAU * dash_ready, 24, Color8(105, 186, 237), 3.0)
	draw_text_centered("D", dash_center + Vector2(0, 4), 9, Color8(194, 222, 235))
	draw_rect(pause_button_rect(), Color(0.02, 0.05, 0.05, 0.90))
	draw_rect(pause_button_rect(), Color8(102, 126, 113), false, 1.0)
	draw_text_centered("II", pause_button_rect().get_center() + Vector2(0, 5), 12, Color8(224, 218, 190))
	if bool(settings.get("show_input_prompts", true)) and not compact:
		var prompt := String(ui_system.call("context_prompt", last_input_family, "run"))
		draw_text_centered(prompt, Vector2(safe.get_center().x, safe.end.y - 4.0), 8, Color8(107, 132, 121))

func _draw_stat_bar(panel: Rect2, label: String, ratio: float, value: String, y: float, color: Color) -> void:
	var x := panel.position.x + 31.0
	var width := panel.size.x - 62.0
	draw_text(label, Vector2(x, y + 12.0), 9, Color8(126, 154, 141))
	var value_width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_text(value, Vector2(x + width - value_width, y + 12.0), 9, Color8(224, 216, 190))
	var bar := Rect2(Vector2(x, y + 18.0), Vector2(width, 8.0))
	draw_rect(bar, Color8(22, 31, 31))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(ratio, 0.0, 1.0), bar.size.y)), color)
	draw_rect(bar, Color8(66, 87, 79), false, 1.0)

func _draw_beveled_panel(rect: Rect2, fill: Color, border: Color, focused: bool) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, Color(border, 0.92 if focused else 0.68), false, 2.0 if focused else 1.0)
	var corner := minf(12.0, minf(rect.size.x, rect.size.y) * 0.18)
	for pair in [
		[rect.position, Vector2(corner, 0), Vector2(0, corner)],
		[Vector2(rect.end.x, rect.position.y), Vector2(-corner, 0), Vector2(0, corner)],
		[Vector2(rect.position.x, rect.end.y), Vector2(corner, 0), Vector2(0, -corner)],
		[rect.end, Vector2(-corner, 0), Vector2(0, -corner)],
	]:
		var origin := Vector2(pair[0])
		draw_line(origin, origin + Vector2(pair[1]), Color(border, 0.92), 2.0)
		draw_line(origin, origin + Vector2(pair[2]), Color(border, 0.92), 2.0)
