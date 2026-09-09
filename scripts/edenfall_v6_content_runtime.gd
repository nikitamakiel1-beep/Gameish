extends "res://scripts/edenfall_v6_navigation_runtime.gd"

const CONTENT_VERSION := "0.6.1-rc4"

var shop_index := 0

func enter_room(coord: Vector2i, movement_direction: Vector2i) -> void:
	shop_index = 0
	super.enter_room(coord, movement_direction)

func draw_run() -> void:
	super.draw_run()
	if state == "run" and not paused and not settings_open and not archive_open and room_graph.has(current_room):
		var room: Dictionary = room_graph[current_room]
		if String(room.get("kind", "")) == "shop":
			_draw_shop_overlay(room)

func draw_archive() -> void:
	var size := get_viewport_rect().size
	var safe := safe_rect()
	var compact := safe.size.x < 900.0 or safe.size.y < 650.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.88))
	var panel := safe.grow(-10.0)
	_draw_beveled_panel(panel, Color8(5, 12, 14, 250), Color8(102, 151, 121), false)
	draw_text_centered("GENOME ARCHIVE", Vector2(panel.get_center().x, panel.position.y + 31.0), 24 if not compact else 18, Color8(239, 225, 183))
	draw_text_centered("LINEAGES • HOSTILES • GUARDIANS • BIOMES • 60 RELIC PROTOCOLS", Vector2(panel.get_center().x, panel.position.y + 52.0), 9, Color8(125, 159, 143))
	if compact:
		_draw_archive_compact(panel)
	else:
		_draw_archive_wide(panel)
	draw_text_centered("ESC / B / TAP OUTSIDE TO CLOSE", Vector2(panel.get_center().x, panel.end.y - 9.0), 8, Color8(104, 132, 119))

func handle_key(keycode: Key) -> void:
	if state == "run" and not paused and not settings_open and not archive_open and _is_shop_room():
		if keycode in [KEY_LEFT, KEY_A]:
			shop_index = posmod(shop_index - 1, 3)
			return
		if keycode in [KEY_RIGHT, KEY_D]:
			shop_index = posmod(shop_index + 1, 3)
			return
		if keycode in [KEY_E, KEY_ENTER, KEY_SPACE]:
			_purchase_selected_shop_item()
			return
	super.handle_key(keycode)

func handle_pointer(position: Vector2, button: MouseButton) -> void:
	if button != MOUSE_BUTTON_LEFT and button != MOUSE_BUTTON_RIGHT:
		return
	if state == "select" and not settings_open and not archive_open:
		var safe := safe_rect()
		var compact := safe.size.x < 900.0 or safe.size.y < 650.0 or safe.size.y > safe.size.x * 1.08
		for index in range(LINEAGES.size()):
			if lineage_card_rect(index).has_point(position):
				if compact and index == selected_lineage:
					start_new_run(index)
				else:
					selected_lineage = index
					play_sfx("ui_confirm", -6.0, 80)
				return
		if not compact and _lineage_deploy_rect().has_point(position):
			start_new_run(selected_lineage)
			return
		return
	if state == "run" and not paused and not settings_open and not archive_open and _is_shop_room():
		for index in range(3):
			if _shop_card_rect(index).has_point(position):
				shop_index = index
				_purchase_selected_shop_item()
				return
	super.handle_pointer(position, button)

func handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and state == "run" and not paused and not settings_open and not archive_open and _is_shop_room():
		for index in range(3):
			if _shop_card_rect(index).has_point(event.position):
				shop_index = index
				_purchase_selected_shop_item()
				return
	super.handle_touch(event)

func interact() -> void:
	if _is_shop_room():
		_purchase_selected_shop_item()
		return
	super.interact()

func _lineage_deploy_rect() -> Rect2:
	var safe := safe_rect()
	var roster_top := lineage_card_rect(0).position.y
	var content := Rect2(Vector2(safe.position.x + 22.0, safe.position.y + 76.0), Vector2(safe.size.x - 44.0, roster_top - safe.position.y - 90.0))
	var portrait_width := content.size.x * 0.39
	var dossier := Rect2(Vector2(content.position.x + portrait_width + 14.0, content.position.y), Vector2(content.size.x - portrait_width - 14.0, content.size.y))
	return Rect2(Vector2(dossier.position.x + 30.0, dossier.end.y - 52.0), Vector2(dossier.size.x - 60.0, 36.0))

func _is_shop_room() -> bool:
	return state == "run" and room_graph.has(current_room) and String(Dictionary(room_graph[current_room]).get("kind", "")) == "shop"

func _purchase_selected_shop_item() -> void:
	if not _is_shop_room():
		return
	var room: Dictionary = room_graph[current_room]
	var items: Array = room.get("shop", [])
	if items.is_empty():
		return
	shop_index = clampi(shop_index, 0, items.size() - 1)
	var item: Dictionary = items[shop_index]
	if bool(item.get("bought", false)):
		notify("RELIC SLOT ALREADY ASSIMILATED")
		return
	var cost := int(item.get("cost", 0))
	if scraps < cost:
		notify("INSUFFICIENT SCRAP // %d REQUIRED" % cost)
		play_sfx("ui_cancel", -4.0, 100)
		return
	scraps -= cost
	item["bought"] = true
	items[shop_index] = item
	room["shop"] = items
	room_graph[current_room] = room
	apply_relic(String(item["id"]))
	play_sfx("ui_confirm", -3.0, 80)
	save_suspended_run()

func _draw_shop_overlay(room: Dictionary) -> void:
	var safe := safe_rect()
	var compact := safe.size.x < 850.0 or safe.size.y < 590.0
	var width := minf(760.0, safe.size.x - 34.0)
	var height := 176.0 if not compact else 136.0
	var panel := Rect2(Vector2(safe.get_center().x - width * 0.5, safe.get_center().y - height * 0.5 + 18.0), Vector2(width, height))
	draw_rect(panel.grow(6.0), Color(0, 0, 0, 0.50))
	_draw_beveled_panel(panel, Color(0.015, 0.035, 0.036, 0.96), Color8(196, 143, 72), false)
	draw_text_centered("PREADAMITE CARAVAN EXCHANGE", Vector2(panel.get_center().x, panel.position.y + 25.0), 15 if not compact else 11, Color8(239, 222, 182))
	draw_text_centered("CHOOSE A RECOVERED PROTOCOL", Vector2(panel.get_center().x, panel.position.y + 43.0), 8, Color8(132, 158, 145))
	var items: Array = room.get("shop", [])
	for index in range(3):
		var rect := _shop_card_rect(index)
		var selected := index == shop_index
		_draw_beveled_panel(rect, Color8(16, 29, 29, 245) if selected else Color8(8, 17, 19, 236), Color8(224, 174, 91) if selected else Color8(62, 84, 77), selected)
		if index >= items.size():
			continue
		var item: Dictionary = items[index]
		var relic_id := String(item.get("id", ""))
		var definition: Dictionary = relic_catalog().get(relic_id, {})
		_draw_relic_icon(relic_id, Rect2(rect.position + Vector2(8, 8), Vector2(38, 38)))
		var bought := bool(item.get("bought", false))
		var name := String(definition.get("name", relic_id.replace("_", " ").capitalize()))
		draw_text(name, rect.position + Vector2(53, 20), 9 if compact else 11, Color8(153, 158, 148) if bought else Color8(232, 221, 191))
		draw_text("ASSIMILATED" if bought else "SCRAP %02d" % int(item.get("cost", 0)), rect.position + Vector2(53, 39), 8, Color8(112, 169, 130) if bought else Color8(224, 173, 82))
	draw_text_centered("A/D OR ←/→ SELECT  •  E / ENTER / TAP PURCHASE", Vector2(panel.get_center().x, panel.end.y - 10.0), 8, Color8(116, 143, 130))

func _shop_card_rect(index: int) -> Rect2:
	var safe := safe_rect()
	var compact := safe.size.x < 850.0 or safe.size.y < 590.0
	var width := minf(760.0, safe.size.x - 34.0)
	var panel_height := 176.0 if not compact else 136.0
	var panel := Rect2(Vector2(safe.get_center().x - width * 0.5, safe.get_center().y - panel_height * 0.5 + 18.0), Vector2(width, panel_height))
	var gap := 8.0
	var card_width := (panel.size.x - 28.0 - gap * 2.0) / 3.0
	var card_height := 73.0 if not compact else 58.0
	return Rect2(Vector2(panel.position.x + 14.0 + float(index) * (card_width + gap), panel.position.y + 54.0), Vector2(card_width, card_height))

func _draw_archive_wide(panel: Rect2) -> void:
	var top := panel.position.y + 70.0
	var hero_area := Rect2(Vector2(panel.position.x + 16.0, top), Vector2(panel.size.x * 0.34, 134.0))
	var biome_area := Rect2(Vector2(hero_area.end.x + 10.0, top), Vector2(panel.end.x - hero_area.end.x - 26.0, 134.0))
	_draw_beveled_panel(hero_area, Color8(8, 18, 20), Color8(67, 98, 88), false)
	_draw_beveled_panel(biome_area, Color8(8, 18, 20), Color8(67, 98, 88), false)
	draw_text("LINEAGES", hero_area.position + Vector2(10, 17), 9, Color8(143, 174, 157))
	for index in range(LINEAGES.size()):
		var lineage: Dictionary = LINEAGES[index]
		var cell_width := (hero_area.size.x - 18.0) / 5.0
		var cell := Rect2(Vector2(hero_area.position.x + 9.0 + float(index) * cell_width, hero_area.position.y + 25.0), Vector2(cell_width - 2.0, 99.0))
		var portrait: Texture2D = production_assets.call("hero_portrait", String(lineage["id"]))
		if portrait != null:
			draw_texture_rect(portrait, Rect2(Vector2(cell.get_center().x - 23.0, cell.position.y + 2.0), Vector2(46, 58)), false, Color.WHITE)
		draw_text_centered(String(lineage["name"]), Vector2(cell.get_center().x, cell.position.y + 76.0), 8, Color(lineage["color"]))
		draw_text_centered(String(HERO_ROLES[String(lineage["id"])]).get_slice(" / ", 0), Vector2(cell.get_center().x, cell.position.y + 91.0), 6, Color8(113, 139, 127))
	draw_text("BIOME MEMORY", biome_area.position + Vector2(10, 17), 9, Color8(143, 174, 157))
	for index in range(BIOMES.size()):
		var cell_width := (biome_area.size.x - 18.0) / 5.0
		var cell := Rect2(Vector2(biome_area.position.x + 9.0 + float(index) * cell_width, biome_area.position.y + 26.0), Vector2(cell_width - 3.0, 96.0))
		var background: Texture2D = production_assets.call("biome_texture", String(BIOMES[index]["id"]), "background")
		if background != null:
			draw_texture_rect(background, Rect2(cell.position, Vector2(cell.size.x, 66.0)), false, Color(0.84, 0.88, 0.84, 0.78))
		draw_rect(Rect2(cell.position, Vector2(cell.size.x, 66.0)), Color(BIOMES[index]["accent"], 0.34), false, 1.0)
		draw_text_centered(String(BIOMES[index]["name"]), Vector2(cell.get_center().x, cell.position.y + 83.0), 6, Color8(205, 202, 181))
	var enemy_area := Rect2(Vector2(panel.position.x + 16.0, top + 144.0), Vector2(panel.size.x - 32.0, 112.0))
	_draw_beveled_panel(enemy_area, Color8(8, 18, 20), Color8(67, 98, 88), false)
	draw_text("HOSTILE SIGNATURES", enemy_area.position + Vector2(10, 17), 9, Color8(143, 174, 157))
	var enemy_ids := ENEMIES.keys()
	for index in range(mini(18, enemy_ids.size())):
		var cell_width := (enemy_area.size.x - 18.0) / 18.0
		var center := Vector2(enemy_area.position.x + 9.0 + (float(index) + 0.5) * cell_width, enemy_area.position.y + 60.0)
		var enemy_id := String(enemy_ids[index])
		var texture_value := enemy_texture(enemy_id)
		if texture_value != null:
			draw_sprite(texture_value, center, PLAYER_FRAME, 0, directional_row("idle", 4), 0.82)
	var relic_area := Rect2(Vector2(panel.position.x + 16.0, enemy_area.end.y + 10.0), Vector2(panel.size.x - 32.0, panel.end.y - enemy_area.end.y - 31.0))
	_draw_beveled_panel(relic_area, Color8(8, 18, 20), Color8(67, 98, 88), false)
	draw_text("RELIC PROTOCOLS", relic_area.position + Vector2(10, 17), 9, Color8(143, 174, 157))
	_draw_relic_grid(relic_area.grow(-8.0), 12, 5)

func _draw_archive_compact(panel: Rect2) -> void:
	var hero_strip := Rect2(Vector2(panel.position.x + 8.0, panel.position.y + 62.0), Vector2(panel.size.x - 16.0, 68.0))
	_draw_beveled_panel(hero_strip, Color8(8, 18, 20), Color8(67, 98, 88), false)
	for index in range(LINEAGES.size()):
		var lineage: Dictionary = LINEAGES[index]
		var cell_width := hero_strip.size.x / 5.0
		var texture_value := player_texture(String(lineage["id"]))
		var center := Vector2(hero_strip.position.x + (float(index) + 0.5) * cell_width, hero_strip.position.y + 30.0)
		if texture_value != null:
			draw_sprite(texture_value, center, PLAYER_FRAME, 0, directional_row("idle", 4), 0.68)
		draw_text_centered(String(lineage["name"]), Vector2(center.x, hero_strip.end.y - 7.0), 6, Color(lineage["color"]))
	var relic_area := Rect2(Vector2(panel.position.x + 8.0, hero_strip.end.y + 8.0), Vector2(panel.size.x - 16.0, panel.end.y - hero_strip.end.y - 27.0))
	_draw_beveled_panel(relic_area, Color8(8, 18, 20), Color8(67, 98, 88), false)
	_draw_relic_grid(relic_area.grow(-7.0), 10, 6)

func _draw_relic_grid(rect: Rect2, columns: int, rows: int) -> void:
	var cell_width := rect.size.x / float(columns)
	var cell_height := rect.size.y / float(rows)
	var icon_size := minf(30.0, minf(cell_width - 3.0, cell_height - 3.0))
	var catalog_ids := relic_catalog().keys()
	for index in range(mini(60, catalog_ids.size())):
		var column := index % columns
		var row := int(index / columns)
		var center := Vector2(rect.position.x + (float(column) + 0.5) * cell_width, rect.position.y + (float(row) + 0.5) * cell_height)
		_draw_relic_icon(String(catalog_ids[index]), Rect2(center - Vector2.ONE * icon_size * 0.5, Vector2.ONE * icon_size))

func _draw_relic_icon(id: String, rect: Rect2) -> void:
	var atlas: Texture2D = production_assets.call("utility_texture", "relics")
	if atlas == null:
		return
	var relic_number := absi(id.hash()) % 60
	var source := Rect2(Vector2(float(relic_number % 12) * 32.0, float(relic_number / 12) * 32.0), Vector2(32, 32))
	draw_texture_rect_region(atlas, rect, source)
