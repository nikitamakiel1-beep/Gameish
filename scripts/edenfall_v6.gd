extends "res://scripts/edenfall_v5.gd"

const V6_VERSION := "0.6.0"
const ProductionPackScript: Script = preload("res://scripts/v6/production_pack.gd")
const AssetRegistryScript: Script = preload("res://scripts/v6/asset_registry.gd")
const AnimationContractScript: Script = preload("res://scripts/v6/animation_contract.gd")

const HERO_FRAME_V6 := Vector2(48.0, 48.0)
const ENEMY_FRAME_V6 := Vector2(32.0, 32.0)
const BOSS_FRAME_V6 := Vector2(64.0, 64.0)
const BIOME_IDS_V6 := ["eden_biolab", "ash_wastes", "halo_ruins", "nephilim_pits", "serpent_depths"]

var production_pack: RefCounted = ProductionPackScript.new()
var asset_registry: RefCounted
var production_report: Dictionary = {}
var v6_asset_ready := false

func _ready() -> void:
	v6_asset_ready = bool(production_pack.call("mount"))
	if v6_asset_ready:
		asset_registry = AssetRegistryScript.new(production_pack)
	super._ready()
	production_report = production_pack.call("audit") if v6_asset_ready else {"ok": false, "failures": production_pack.get("errors")}
	readiness = audit_v6_readiness()

func production_texture(path: String) -> Texture2D:
	if not v6_asset_ready or path.is_empty():
		return null
	return production_pack.call("load_texture", path) as Texture2D

func player_texture(id: String) -> Texture2D:
	if asset_registry == null:
		return null
	var definition: Dictionary = asset_registry.call("hero", id)
	return production_texture(String(definition.get("sheet", "")))

func enemy_texture(id: String) -> Texture2D:
	if asset_registry == null:
		return null
	var definition: Dictionary = asset_registry.call("enemy", id)
	return production_texture(String(definition.get("sheet", "")))

func boss_texture(index: int) -> Texture2D:
	if asset_registry == null:
		return null
	var id := String(BOSS_IDS[clampi(index, 0, BOSS_IDS.size() - 1)])
	var definition: Dictionary = asset_registry.call("boss", id)
	return production_texture(String(definition.get("sheet", "")))

func hero_portrait(id: String) -> Texture2D:
	if asset_registry == null:
		return null
	var definition: Dictionary = asset_registry.call("hero", id)
	return production_texture(String(definition.get("portrait", "")))

func biome_asset(index: int, key: String) -> Texture2D:
	if asset_registry == null:
		return null
	var definition: Dictionary = asset_registry.call("biome", index)
	return production_texture(String(definition.get(key, "")))

func ui_asset(id: String) -> Texture2D:
	if asset_registry == null:
		return null
	return production_texture(String(asset_registry.call("ui", id)))

func item_asset(id: String) -> Texture2D:
	if asset_registry == null:
		return null
	return production_texture(String(asset_registry.call("item", id)))

func vfx_asset(id: String) -> Texture2D:
	if asset_registry == null:
		return null
	return production_texture(String(asset_registry.call("vfx", id)))

func draw_player() -> void:
	var id := String(player.get("id", "adam"))
	var tex := player_texture(id)
	var action := animation_action()
	var direction := quantize_direction(Vector2(player.get("look", Vector2.DOWN)))
	var row := int(AnimationContractScript.hero_row(action, direction))
	var fps := float({"idle": 6.0, "walk": 11.0, "aim": 8.0, "attack": 16.0, "dash": 18.0, "hurt": 10.0, "death": 8.0}.get(action, 8.0))
	var frame := posmod(int(visual_clock * fps), 8)
	var tint := Color.WHITE
	if invulnerability > 0.0 and int(invulnerability * 20.0) % 2 == 0:
		tint = Color(1, 1, 1, 0.38)
	if tex != null:
		draw_sprite(tex, Vector2(player["pos"]), HERO_FRAME_V6, frame, row, 1.18, tint)
	else:
		draw_missing_asset(Vector2(player["pos"]), "HERO:%s" % id)
	var aim := Vector2(player.get("aim", Vector2.DOWN))
	if bool(player.get("shield", false)):
		draw_arc(Vector2(player["pos"]), 28.0, -PI * 0.84, PI * 0.84, 28, Color8(112, 181, 239), 3.0)
	draw_line(Vector2(player["pos"]) + aim * 13.0, Vector2(player["pos"]) + aim * 30.0, Color(0.95, 0.90, 0.72, 0.55), 2.0)

func draw_enemies() -> void:
	for enemy in enemies:
		var pos := Vector2(enemy["pos"])
		var action := "idle"
		if float(enemy.get("hurt", 0.0)) > 0.0:
			action = "hurt"
		elif float(enemy.get("attack", 0.0)) > 0.0:
			action = "attack"
		elif Vector2(enemy.get("velocity", Vector2.ZERO)).length() > 8.0:
			action = "walk"
		var direction := quantize_direction(Vector2(enemy.get("look", Vector2.DOWN)))
		var fps := 10.0 if action == "walk" else (14.0 if action == "attack" else 6.0)
		var frame := posmod(int((visual_clock + float(enemy.get("variant", 0)) * 0.13) * fps), 8)
		var tex: Texture2D
		var frame_size := ENEMY_FRAME_V6
		var scale := maxf(1.05, float(enemy["radius"]) / 15.0)
		var row := 0
		if bool(enemy.get("boss", false)):
			tex = boss_texture(biome_index)
			frame_size = BOSS_FRAME_V6
			scale = maxf(1.0, float(enemy["radius"]) / 44.0)
			var boss_action := "attack_primary" if action == "attack" else ("phase" if int(enemy.get("stage", 0)) > 0 and int(visual_clock * 4.0) % 7 == 0 else ("hurt" if action == "hurt" else "idle"))
			row = int(AnimationContractScript.boss_row(boss_action, direction))
		else:
			tex = enemy_texture(String(enemy["id"]))
			row = int(AnimationContractScript.enemy_row(action, direction))
		if tex != null:
			draw_sprite(tex, pos, frame_size, frame, row, scale, Color.WHITE)
		else:
			draw_missing_asset(pos, "ENEMY:%s" % String(enemy.get("id", "?")))
		if bool(enemy.get("elite", false)) and not bool(enemy.get("boss", false)):
			var affix := String(enemy.get("affix", ""))
			var overlay_def: Dictionary = asset_registry.call("elite", affix) if asset_registry != null else {}
			var overlay := production_texture(String(overlay_def.get("sheet", "")))
			if overlay != null:
				draw_sprite(overlay, pos, ENEMY_FRAME_V6, frame, direction, scale, Color.WHITE)
		var ratio := maxf(0.0, float(enemy["hp"]) / float(enemy["max_hp"]))
		var width := float(enemy["radius"]) * 2.1
		draw_rect(Rect2(pos + Vector2(-width * 0.5, float(enemy["radius"]) + 9.0), Vector2(width, 5.0)), Color8(38, 22, 22))
		draw_rect(Rect2(pos + Vector2(-width * 0.5, float(enemy["radius"]) + 9.0), Vector2(width * ratio, 5.0)), Color8(205, 70, 64))

func draw_arena() -> void:
	var size := get_viewport_rect().size
	var arena := arena_rect()
	var biome: Dictionary = BIOMES[biome_index]
	var background := biome_asset(biome_index, "background")
	if background != null:
		draw_texture_rect(background, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, 0.72))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color8(4, 7, 8))
	draw_rect(arena, Color(biome["floor"], 0.78))
	var floor_tex := biome_asset(biome_index, "floor")
	if floor_tex != null:
		var row_index := 0
		for y in range(int(arena.position.y), int(arena.end.y), 32):
			var column_index := 0
			for x in range(int(arena.position.x), int(arena.end.x), 32):
				var tile_index := posmod(column_index * 7 + row_index * 11 + biome_index * 5, 64)
				var source := Rect2(Vector2((tile_index % 8) * 32, int(tile_index / 8) * 32), Vector2(32, 32))
				draw_texture_rect_region(floor_tex, Rect2(Vector2(x, y), Vector2(32, 32)), source, Color(1, 1, 1, 0.84))
				column_index += 1
			row_index += 1
	var props := biome_asset(biome_index, "props")
	if props != null:
		for i in range(8):
			var position := arena.position + Vector2(70.0 + float(i) * arena.size.x / 8.4, 78.0 + float(posmod(i * 83, int(maxf(120.0, arena.size.y - 150.0)))))
			var source := Rect2(Vector2((i % 4) * 64, int(i / 4) * 64), Vector2(64, 64))
			draw_texture_rect_region(props, Rect2(position - Vector2(32, 32), Vector2(64, 64)), source, Color(1, 1, 1, 0.80))
	draw_rect(arena, biome["accent"], false, 4.0)

func draw_bullets() -> void:
	var global_fx := vfx_asset("global")
	for bullet in bullets:
		var pos := Vector2(bullet["pos"])
		var velocity := Vector2(bullet["vel"])
		var direction := quantize_direction(velocity)
		var frame := posmod(int(visual_clock * 18.0), 8)
		if String(bullet["owner"]) == "player" and asset_registry != null:
			var hero_id := String(player.get("id", "adam"))
			var hero_definition: Dictionary = asset_registry.call("hero", hero_id)
			var projectile_path := String(hero_definition.get("projectiles", ""))
			var projectile := production_texture(projectile_path)
			if projectile != null:
				draw_sprite(projectile, pos, Vector2(16, 16), frame, direction, maxf(1.0, float(bullet["radius"]) / 4.0), Color.WHITE)
				continue
		if global_fx != null:
			var row := 1 if String(bullet["owner"]) == "enemy" else 0
			draw_sprite(global_fx, pos, Vector2(64, 64), frame, row, 0.34 + float(bullet["radius"]) / 18.0, bullet["color"])
		else:
			draw_circle(pos, float(bullet["radius"]), bullet["color"])

func draw_pickups() -> void:
	var pickup_atlas := item_asset("pickups")
	var relic_atlas := item_asset("relics")
	var kind_rows := {"heart": 0, "health": 0, "shield": 1, "scrap": 2, "genome": 3, "ether": 4, "soul": 5, "data": 6, "key": 7}
	for pickup in pickups:
		var pos := Vector2(pickup["pos"]) + Vector2(0, sin(float(pickup.get("phase", 0.0)) * 2.4) * 4.0)
		var kind := String(pickup.get("kind", "scrap"))
		if kind == "relic" and relic_atlas != null:
			var relic_id := String(pickup.get("id", "relic"))
			var index := posmod(relic_id.hash(), 60)
			draw_sprite(relic_atlas, pos, Vector2(64, 64), index % 10, int(index / 10), 0.55, Color.WHITE)
		elif pickup_atlas != null:
			var row := int(kind_rows.get(kind, 2))
			var frame := posmod(int(visual_clock * 10.0), 8)
			draw_sprite(pickup_atlas, pos, Vector2(32, 32), frame, row, 1.0, Color.WHITE)
		else:
			draw_circle(pos, 9.0, Color8(220, 174, 86))

func draw_effects() -> void:
	var atlas := vfx_asset("global")
	for effect in effects:
		var progress := 1.0 - float(effect["life"]) / maxf(0.001, float(effect["max_life"]))
		if atlas != null:
			var frame := clampi(int(progress * 8.0), 0, 7)
			var row := posmod(String(effect.get("kind", "impact")).hash(), 8)
			draw_sprite(atlas, Vector2(effect["pos"]), Vector2(64, 64), frame, row, 0.72, effect["color"])
		else:
			draw_arc(Vector2(effect["pos"]), 4.0 + progress * 24.0, 0, TAU, 24, Color(effect["color"], 1.0 - progress), 3.0)
	for number in damage_numbers:
		draw_text_centered(String(number["text"]), Vector2(number["pos"]), 14, number["color"])

func draw_panel(rect: Rect2, fill: Color, border: Color) -> void:
	var panel := ui_asset("panel")
	if panel != null:
		draw_texture_rect(panel, rect, false, Color(fill, 0.96))
	else:
		draw_rect(rect, fill)
	draw_rect(rect, border, false, 2.0)

func draw_hud() -> void:
	super.draw_hud()
	if player.is_empty():
		return
	var portrait := hero_portrait(String(player.get("id", "adam")))
	if portrait != null:
		var safe := safe_rect()
		var scale := float(settings["ui_scale"])
		var rect := Rect2(safe.position + Vector2(13, 13) * scale, Vector2(45, 45) * scale)
		draw_texture_rect(portrait, rect, false, Color.WHITE)
		draw_rect(rect, player["color"], false, 2.0)

func draw_touch_controls() -> void:
	if not OS.has_feature("mobile") and left_touch_id == -1 and right_touch_id == -1:
		return
	var atlas := ui_asset("touch")
	if atlas == null:
		super.draw_touch_controls()
		return
	var size := 112.0
	var left_rect := Rect2(movement_stick_center() - Vector2.ONE * size * 0.5, Vector2.ONE * size)
	var right_rect := Rect2(aim_stick_center() - Vector2.ONE * size * 0.5, Vector2.ONE * size)
	draw_texture_rect_region(atlas, left_rect, Rect2(Vector2.ZERO, Vector2(128, 128)), Color.WHITE)
	draw_texture_rect_region(atlas, right_rect, Rect2(Vector2(128, 0), Vector2(128, 128)), Color.WHITE)
	draw_circle(movement_stick_center() + input_move * 32.0, 16.0, Color(0.45, 0.80, 0.62, 0.72))
	draw_circle(aim_stick_center() + input_aim * 32.0, 16.0, Color(0.77, 0.48, 0.85, 0.72))
	draw_panel(dash_button_rect(), Color(0.05, 0.10, 0.13, 0.82), Color8(108, 185, 231))
	draw_text_centered("DASH", dash_button_rect().get_center() + Vector2(0, 5), 11, Color8(200, 230, 244))
	draw_panel(interact_button_rect(), Color(0.12, 0.09, 0.05, 0.82), Color8(224, 190, 113))
	draw_text_centered("USE", interact_button_rect().get_center() + Vector2(0, 5), 11, Color8(239, 211, 151))

func draw_archive() -> void:
	super.draw_archive()
	var relics := item_asset("relics")
	if relics == null:
		return
	var size := get_viewport_rect().size
	var panel := Rect2(Vector2(size.x * 0.5 - 420.0, size.y * 0.5 - 285.0), Vector2(840, 570))
	for index in range(60):
		var column := index % 10
		var row := int(index / 10)
		var target := Rect2(panel.position + Vector2(29 + column * 79, 100 + row * 62), Vector2(48, 48))
		draw_texture_rect_region(relics, target, Rect2(Vector2((index % 10) * 64, row * 64), Vector2(64, 64)), Color.WHITE)

func draw_title() -> void:
	super.draw_title()
	var icon := ui_asset("icon")
	var safe := safe_rect()
	if icon != null:
		var icon_size := 118.0 if safe.size.x >= 700.0 else 84.0
		var rect := Rect2(Vector2(safe.get_center().x - icon_size * 0.5, safe.position.y + 92.0), Vector2.ONE * icon_size)
		draw_texture_rect(icon, rect, false, Color(1, 1, 1, 0.90))
	draw_text("v%s // PRODUCTION ASSET BUILD" % V6_VERSION, Vector2(safe.position.x + 18.0, safe.end.y - 18.0), 11, Color8(158, 194, 169))

func play_biome_audio(force: bool = false) -> void:
	if asset_registry == null:
		super.play_biome_audio(force)
		return
	if biome_index == current_music_biome and not force:
		return
	current_music_biome = biome_index
	var id := BIOME_IDS_V6[clampi(biome_index, 0, BIOME_IDS_V6.size() - 1)]
	var music_path := String(asset_registry.call("audio", "music", id))
	var ambience_path := String(asset_registry.call("audio", "ambience", id))
	var music := production_pack.call("load_wav", music_path, true) as AudioStreamWAV
	var ambience := production_pack.call("load_wav", ambience_path, true) as AudioStreamWAV
	if music != null:
		audio_players["music"].stream = music
		audio_players["music"].play()
	if ambience != null:
		audio_players["ambience"].stream = ambience
		audio_players["ambience"].play()

func play_sfx(id: String, volume_db: float = 0.0, throttle_ms: int = 0) -> void:
	if asset_registry == null or sfx_pool.is_empty():
		super.play_sfx(id, volume_db, throttle_ms)
		return
	var resolved := id
	var registry_data: Dictionary = asset_registry.get("data")
	var audio_data: Dictionary = registry_data.get("audio", {})
	var sfx_data: Dictionary = audio_data.get("sfx", {})
	if not sfx_data.has(resolved):
		if id.begins_with("shot_"):
			resolved = "shot_01"
		elif id in ["hit", "enemy_hit", "explosion"]:
			resolved = "impact"
		elif id in ["heal", "relic", "scrap"]:
			resolved = "pickup"
		else:
			resolved = "ui_confirm"
	var path := String(asset_registry.call("audio", "sfx", resolved))
	var stream := production_pack.call("load_wav", path, false) as AudioStreamWAV
	if stream == null:
		return
	var player_node := sfx_pool[sfx_cursor] as AudioStreamPlayer
	sfx_cursor = (sfx_cursor + 1) % sfx_pool.size()
	player_node.stop()
	player_node.stream = stream
	player_node.volume_db = volume_db
	player_node.pitch_scale = rng.randf_range(0.96, 1.04)
	player_node.play()

func draw_missing_asset(position: Vector2, id: String) -> void:
	var rect := Rect2(position - Vector2(18, 18), Vector2(36, 36))
	draw_rect(rect, Color8(230, 32, 190))
	draw_line(rect.position, rect.end, Color.BLACK, 3.0)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), Color.BLACK, 3.0)
	draw_text_centered(id, position + Vector2(0, 29), 8, Color.WHITE)

func audit_v6_readiness() -> float:
	var checks := [
		super.audit_v5_readiness() >= 90.0,
		v6_asset_ready,
		bool(production_report.get("ok", false)),
		int(production_report.get("file_count", 0)) >= 120,
		player_texture("adam") != null,
		enemy_texture("feral_scavenger") != null,
		boss_texture(0) != null,
		biome_asset(0, "floor") != null,
		item_asset("relics") != null,
		ui_asset("panel") != null,
		FileAccess.file_exists("res://tests/v6_asset_audit.gd"),
		FileAccess.file_exists("res://docs/PRODUCTION_ASSETS_V6.md"),
	]
	var passed := 0
	for check in checks:
		if check:
			passed += 1
	return float(passed) / float(checks.size()) * 100.0
