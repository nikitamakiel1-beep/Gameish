extends "res://scripts/edenfall_v5.gd"

const V6_VERSION := "0.6.0"
const ProductionAssetRegistryScript: Script = preload("res://scripts/v6/asset_registry.gd")

var production_assets: RefCounted = ProductionAssetRegistryScript.new()
var v6_asset_report: Dictionary = {}
var _v6_sfx_last_ms: Dictionary = {}

func _ready() -> void:
	super._ready()
	v6_asset_report = audit_v6_readiness()
	readiness = float(v6_asset_report.get("readiness", 0.0))

func player_texture(id: String) -> Texture2D:
	return production_assets.call("hero_sheet", id)

func enemy_texture(id: String) -> Texture2D:
	return production_assets.call("enemy_sheet", id)

func boss_texture(index: int) -> Texture2D:
	var safe_index := clampi(index, 0, BOSS_IDS.size() - 1)
	return production_assets.call("boss_sheet", String(BOSS_IDS[safe_index]))

func draw_arena() -> void:
	var size := get_viewport_rect().size
	var arena := arena_rect()
	var biome: Dictionary = BIOMES[biome_index]
	var biome_id := String(biome["id"])
	draw_rect(Rect2(Vector2.ZERO, size), Color8(3, 6, 7))
	var background: Texture2D = production_assets.call("biome_texture", biome_id, "background")
	if background != null:
		draw_texture_rect(background, arena, false, Color(1.0, 1.0, 1.0, 0.34))
	else:
		draw_rect(arena, Color(biome["floor"]))
	var tile_texture: Texture2D = production_assets.call("biome_texture", biome_id, "tiles")
	if tile_texture != null:
		var row := 0
		for y in range(int(arena.position.y), int(arena.end.y), 32):
			var column := 0
			for x in range(int(arena.position.x), int(arena.end.x), 32):
				var tile_index := posmod(column * 7 + row * 11 + biome_index * 5, 32)
				var source := Rect2(Vector2(float(tile_index % 8) * 32.0, float(tile_index / 8) * 32.0), Vector2(32, 32))
				draw_texture_rect_region(tile_texture, Rect2(Vector2(x, y), Vector2(32, 32)), source, Color(1.0, 1.0, 1.0, 0.92))
				column += 1
			row += 1
	var props: Texture2D = production_assets.call("biome_texture", biome_id, "props")
	if props != null:
		var prop_height := minf(74.0, arena.size.y * 0.14)
		draw_texture_rect(props, Rect2(arena.position + Vector2(10, 6), Vector2(arena.size.x - 20, prop_height)), false, Color(1, 1, 1, 0.72))
		draw_texture_rect(props, Rect2(Vector2(arena.position.x + 10, arena.end.y - prop_height - 6), Vector2(arena.size.x - 20, prop_height)), false, Color(1, 1, 1, 0.82))
	draw_rect(arena, Color(biome["accent"]), false, 4.0)

func draw_bullets() -> void:
	var atlas: Texture2D = production_assets.call("utility_texture", "projectiles")
	if atlas == null:
		return
	var frame := posmod(int(visual_clock * 18.0), 8)
	for bullet in bullets:
		var row := 5
		if String(bullet["owner"]) == "player":
			row = clampi(selected_lineage, 0, 4)
		var source := Rect2(Vector2(float(frame * 16), float(row * 16)), Vector2(16, 16))
		var radius := maxf(8.0, float(bullet["radius"]) * 2.4)
		var destination := Rect2(Vector2(bullet["pos"]) - Vector2.ONE * radius * 0.5, Vector2.ONE * radius)
		draw_texture_rect_region(atlas, destination, source)

func draw_pickups() -> void:
	var pickup_atlas: Texture2D = production_assets.call("utility_texture", "pickups")
	var relic_atlas: Texture2D = production_assets.call("utility_texture", "relics")
	for pickup in pickups:
		var pos := Vector2(pickup["pos"]) + Vector2(0, sin(float(pickup["phase"]) * 2.4) * 4.0)
		var kind := String(pickup["kind"])
		if kind == "relic" and relic_atlas != null:
			var relic_number := absi(String(pickup.get("id", "relic")).hash()) % 60
			var source := Rect2(Vector2(float(relic_number % 12) * 32.0, float(relic_number / 12) * 32.0), Vector2(32, 32))
			draw_texture_rect_region(relic_atlas, Rect2(pos - Vector2(18, 18), Vector2(36, 36)), source)
		elif pickup_atlas != null:
			var cell := Vector2i.ZERO
			match kind:
				"heart": cell = Vector2i(0, 0)
				"scrap": cell = Vector2i(1, 0)
				"genome": cell = Vector2i(2, 0)
				_: cell = Vector2i(3, 0)
			var source := Rect2(Vector2(cell * 48), Vector2(48, 48))
			draw_texture_rect_region(pickup_atlas, Rect2(pos - Vector2(20, 20), Vector2(40, 40)), source)

func draw_hud() -> void:
	super.draw_hud()
	if player.is_empty():
		return
	var portrait: Texture2D = production_assets.call("hero_portrait", String(player.get("id", "adam")))
	if portrait != null:
		var safe := safe_rect()
		var portrait_rect := Rect2(safe.position + Vector2(12, 12), Vector2(42, 46))
		draw_texture_rect(portrait, portrait_rect, false, Color.WHITE)
	var relics: Texture2D = production_assets.call("utility_texture", "relics")
	if relics != null:
		var inventory: Array = player.get("inventory", [])
		var safe := safe_rect()
		var base := Vector2(safe.get_center().x - 190.0, safe.end.y - 43.0)
		for i in range(mini(8, inventory.size())):
			var relic_number := absi(String(inventory[i]).hash()) % 60
			var source := Rect2(Vector2(float(relic_number % 12) * 32.0, float(relic_number / 12) * 32.0), Vector2(32, 32))
			draw_texture_rect_region(relics, Rect2(base + Vector2(float(i) * 48.0, 0), Vector2(30, 30)), source)

func draw_touch_controls() -> void:
	if not OS.has_feature("mobile") and left_touch_id == -1 and right_touch_id == -1:
		return
	var base_texture: Texture2D = production_assets.call("utility_texture", "joystick_base")
	var thumb_texture: Texture2D = production_assets.call("utility_texture", "joystick_thumb")
	var dash_texture: Texture2D = production_assets.call("utility_texture", "touch_dash")
	var interact_texture: Texture2D = production_assets.call("utility_texture", "touch_interact")
	var left_center := movement_stick_center()
	var right_center := aim_stick_center()
	if base_texture != null:
		draw_texture_rect(base_texture, Rect2(left_center - Vector2(62, 62), Vector2(124, 124)), false, Color(1, 1, 1, 0.78))
		draw_texture_rect(base_texture, Rect2(right_center - Vector2(62, 62), Vector2(124, 124)), false, Color(1, 1, 1, 0.78))
	if thumb_texture != null:
		draw_texture_rect(thumb_texture, Rect2(left_center + input_move * 34.0 - Vector2(26, 26), Vector2(52, 52)), false, Color(1, 1, 1, 0.92))
		draw_texture_rect(thumb_texture, Rect2(right_center + input_aim * 34.0 - Vector2(26, 26), Vector2(52, 52)), false, Color(1, 1, 1, 0.92))
	if dash_texture != null:
		draw_texture_rect(dash_texture, dash_button_rect(), false, Color.WHITE)
	if interact_texture != null:
		draw_texture_rect(interact_texture, interact_button_rect(), false, Color.WHITE)
	draw_cooldown_ring(dash_button_rect().get_center(), dash_timer / maxf(0.001, float(player["dash_delay"])), Color8(107, 180, 229))

func draw_title() -> void:
	super.draw_title()
	var safe := safe_rect()
	var hero_y := safe.position.y + safe.size.y * 0.26
	var patch := Rect2(Vector2(safe.get_center().x - 225.0, hero_y + 45.0), Vector2(450.0, 28.0))
	draw_rect(patch, Color8(5, 10, 11))
	draw_text_centered("v%s  •  GODOT %s  •  PRODUCTION ART ACTIVE" % [V6_VERSION, GODOT_TARGET], Vector2(safe.get_center().x, hero_y + 63.0), 11, Color8(126, 182, 145))

func draw_select() -> void:
	super.draw_select()
	var safe := safe_rect()
	draw_text_centered("GENERATED PRODUCTION SHEETS // 8 DIRECTIONS × 8 FRAMES", Vector2(safe.get_center().x, safe.end.y - 10.0), 10, Color8(130, 165, 150))

func play_biome_audio(force: bool = false) -> void:
	if biome_index == current_music_biome and not force:
		return
	current_music_biome = biome_index
	var biome_id := String(BIOMES[biome_index]["id"])
	for kind in ["music", "ambience"]:
		var stream: AudioStreamWAV = production_assets.call("biome_audio", biome_id, kind)
		if stream != null:
			audio_players[kind].stream = stream
			audio_players[kind].play()

func play_sfx(id: String, volume_db: float = 0.0, throttle_ms: int = 0) -> void:
	if sfx_pool.is_empty():
		return
	var now := Time.get_ticks_msec()
	if throttle_ms > 0 and now - int(_v6_sfx_last_ms.get(id, -1000000)) < throttle_ms:
		return
	_v6_sfx_last_ms[id] = now
	var stream: AudioStreamWAV = production_assets.call("sfx", id)
	if stream == null:
		return
	var player_node: AudioStreamPlayer = sfx_pool[sfx_cursor]
	sfx_cursor = (sfx_cursor + 1) % sfx_pool.size()
	player_node.stop()
	player_node.stream = stream
	player_node.volume_db = volume_db
	player_node.pitch_scale = rng.randf_range(0.97, 1.03)
	player_node.play()

func audit_v6_readiness() -> Dictionary:
	var errors: Array[String] = []
	var idx: Dictionary = production_assets.call("index")
	if String(idx.get("version", "")) != V6_VERSION:
		errors.append("Production index version mismatch")
	if Array(idx.get("hero_ids", [])).size() != 5:
		errors.append("Five hero packs are required")
	if Array(idx.get("enemy_ids", [])).size() != 18:
		errors.append("Eighteen enemy packs are required")
	if Array(idx.get("boss_ids", [])).size() != 5:
		errors.append("Five boss packs are required")
	if Array(idx.get("biome_ids", [])).size() != 5:
		errors.append("Five biome packs are required")
	for id in ["adam", "abel", "cain", "seth", "naamah"]:
		if production_assets.call("hero_sheet", id) == null:
			errors.append("Hero sheet failed: %s" % id)
	for id in ["watcher_engine", "first_nephilim", "gate_cherub", "tower_enoch", "serpent_interface"]:
		if production_assets.call("boss_sheet", id) == null:
			errors.append("Boss sheet failed: %s" % id)
	var checks := 10
	var passed := checks - errors.size()
	return {
		"version": V6_VERSION,
		"errors": errors,
		"readiness": clampf(float(passed) / float(checks) * 100.0, 0.0, 100.0),
	}
