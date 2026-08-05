extends RefCounted

const VERSION := "0.6.0"
const INDEX_PATH := "res://assets/production_v6_compact/bundle_index.json"
const HERO_IDS := ["adam", "abel", "cain", "seth", "naamah"]
const BOSS_IDS := ["watcher_engine", "first_nephilim", "gate_cherub", "tower_enoch", "serpent_interface"]
const BIOME_IDS := ["industrial_eden", "ash_wastes", "temple_lab", "fungal_garden", "nephilim_ruins"]
const ENEMY_IDS := [
	"feral_scavenger", "outlaw_gunner", "raider_brute", "wasteland_hunter", "scrap_cultist", "caravan_outlaw",
	"cherub_drone", "fallen_angel", "watcher_acolyte", "halo_sentinel", "biomech_pilgrim", "ophanim_scout",
	"nephilim_husk", "nephilim_giant", "horned_berserker", "bone_shepherd", "grafted_colossus", "serpent_spawn",
]
const ALIASES := {
	"ritual_gunner": "outlaw_gunner",
	"biotech_pilgrim": "biomech_pilgrim",
	"horned_nephilim_berserker": "horned_berserker",
	"serpent_blood_spawn": "serpent_spawn",
	"tower_of_enoch": "tower_enoch",
}
const HERO_COLORS := {
	"adam": Color8(190, 222, 92),
	"abel": Color8(255, 218, 126),
	"cain": Color8(246, 63, 48),
	"seth": Color8(77, 174, 255),
	"naamah": Color8(201, 89, 231),
}
const BIOME_PALETTES := {
	"industrial_eden": [Color8(17, 33, 28), Color8(31, 59, 47), Color8(78, 105, 76), Color8(131, 159, 102)],
	"ash_wastes": [Color8(45, 29, 23), Color8(77, 45, 29), Color8(128, 78, 43), Color8(189, 124, 65)],
	"temple_lab": [Color8(14, 32, 42), Color8(30, 65, 74), Color8(58, 118, 116), Color8(112, 174, 163)],
	"fungal_garden": [Color8(42, 25, 50), Color8(75, 39, 82), Color8(128, 63, 133), Color8(192, 109, 184)],
	"nephilim_ruins": [Color8(28, 27, 41), Color8(50, 47, 71), Color8(91, 72, 116), Color8(154, 116, 173)],
}

var _bundle_cache: Dictionary = {}
var _image_cache: Dictionary = {}
var _texture_cache: Dictionary = {}
var _audio_cache: Dictionary = {}
var last_error := ""

func index() -> Dictionary:
	return _bundle()

func hero_sheet(id: String) -> Texture2D:
	var key := id.to_lower()
	if key not in HERO_IDS:
		return _fail_texture("Unknown hero: %s" % id)
	if _texture_cache.has("hero_sheet:" + key):
		return _texture_cache["hero_sheet:" + key]
	var base := _base_image("heroes/%s.png" % key)
	var sheet := _build_actor_sheet(base, 48, Color(HERO_COLORS[key]))
	return _cache_texture("hero_sheet:" + key, sheet)

func hero_portrait(id: String) -> Texture2D:
	var key := id.to_lower()
	if key not in HERO_IDS:
		return _fail_texture("Unknown hero portrait: %s" % id)
	if _texture_cache.has("portrait:" + key):
		return _texture_cache["portrait:" + key]
	var base := _base_image("heroes/%s.png" % key)
	var portrait := Image.create(256, 320, false, Image.FORMAT_RGBA8)
	portrait.fill(Color8(5, 12, 15))
	_fill_rect(portrait, Rect2i(4, 4, 248, 312), Color(HERO_COLORS[key], 0.18))
	_draw_border(portrait, Rect2i(4, 4, 248, 312), Color(HERO_COLORS[key]))
	var sprite := base.get_region(Rect2i(4 * 48, 0, 48, 48))
	sprite.resize(208, 208, Image.INTERPOLATE_NEAREST)
	portrait.blend_rect(sprite, Rect2i(0, 0, 208, 208), Vector2i(24, 74))
	return _cache_texture("portrait:" + key, portrait)

func enemy_sheet(id: String) -> Texture2D:
	var key := String(ALIASES.get(id.to_lower(), id.to_lower()))
	if key not in ENEMY_IDS:
		return _fail_texture("Unknown enemy: %s" % id)
	if _texture_cache.has("enemy_sheet:" + key):
		return _texture_cache["enemy_sheet:" + key]
	var base := _base_image("enemies/%s.png" % key)
	var color := Color8(230, 154, 76)
	if ENEMY_IDS.find(key) >= 6 and ENEMY_IDS.find(key) < 12:
		color = Color8(241, 210, 126)
	elif ENEMY_IDS.find(key) >= 12:
		color = Color8(224, 74, 63)
	return _cache_texture("enemy_sheet:" + key, _build_actor_sheet(base, 48, color))

func boss_sheet(id: String) -> Texture2D:
	var key := String(ALIASES.get(id.to_lower(), id.to_lower()))
	if key not in BOSS_IDS:
		return _fail_texture("Unknown boss: %s" % id)
	if _texture_cache.has("boss_sheet:" + key):
		return _texture_cache["boss_sheet:" + key]
	var base := _base_image("bosses/%s.png" % key)
	var color := [Color8(190, 120, 255), Color8(245, 65, 54), Color8(255, 210, 90), Color8(190, 80, 230), Color8(160, 225, 65)][BOSS_IDS.find(key)]
	return _cache_texture("boss_sheet:" + key, _build_boss_sheet(base, color))

func biome_texture(id: String, kind: String) -> Texture2D:
	var key := id.to_lower()
	if key not in BIOME_IDS or kind not in ["tiles", "props", "background"]:
		return _fail_texture("Unknown biome texture: %s/%s" % [id, kind])
	var cache_key := "biome:%s:%s" % [key, kind]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	var palette: Array = BIOME_PALETTES[key]
	var image := Image.new()
	if kind == "tiles":
		image = _build_tiles(key, palette)
	elif kind == "props":
		image = _build_props(key, palette)
	else:
		image = _build_background(key, palette)
	return _cache_texture(cache_key, image)

func utility_texture(id: String) -> Texture2D:
	var mapping := {
		"pickups": "items/pickups.png",
		"relics": "items/relics.png",
		"projectiles": "vfx/projectiles.png",
		"effects": "vfx/effects.png",
		"hud_panel": "ui/hud_panel.png",
		"menu_panel": "ui/menu_panel.png",
		"joystick_base": "ui/joystick_base.png",
		"joystick_thumb": "ui/joystick_thumb.png",
		"touch_dash": "ui/touch_dash.png",
		"touch_interact": "ui/touch_interact.png",
		"touch_pause": "ui/touch_pause.png",
	}
	if not mapping.has(id):
		return _fail_texture("Unknown utility texture: %s" % id)
	if _texture_cache.has("utility:" + id):
		return _texture_cache["utility:" + id]
	return _cache_texture("utility:" + id, _base_image(String(mapping[id])))

func biome_audio(id: String, kind: String) -> AudioStreamWAV:
	var key := id.to_lower()
	if key not in BIOME_IDS or kind not in ["music", "ambience"]:
		return null
	var cache_key := "audio:%s:%s" % [key, kind]
	if _audio_cache.has(cache_key):
		return _audio_cache[cache_key]
	var stream := _synth_loop(BIOME_IDS.find(key), kind == "ambience")
	_audio_cache[cache_key] = stream
	return stream

func sfx(id: String) -> AudioStreamWAV:
	var cache_key := "sfx:" + id
	if _audio_cache.has(cache_key):
		return _audio_cache[cache_key]
	var stream := _synth_sfx(id)
	_audio_cache[cache_key] = stream
	return stream

func validate_contract() -> Dictionary:
	var errors: Array[String] = []
	var decoded := 0
	var idx := index()
	if String(idx.get("version", "")) != VERSION:
		errors.append("Bundle version mismatch")
	if String(idx.get("concept_policy", "")).findn("reference-only") < 0:
		errors.append("Reference-only concept policy missing")
	if Array(idx.get("directions", [])).size() != 8:
		errors.append("Eight directions required")
	for id in HERO_IDS:
		if _check_size(hero_sheet(id), Vector2i(384, 2304), "hero:" + id, errors): decoded += 1
		if _check_size(hero_portrait(id), Vector2i(256, 320), "portrait:" + id, errors): decoded += 1
	for id in ENEMY_IDS:
		if _check_size(enemy_sheet(id), Vector2i(384, 2304), "enemy:" + id, errors): decoded += 1
	for id in BOSS_IDS:
		if _check_size(boss_sheet(id), Vector2i(768, 3072), "boss:" + id, errors): decoded += 1
	for id in BIOME_IDS:
		if _check_size(biome_texture(id, "tiles"), Vector2i(256, 128), "tiles:" + id, errors): decoded += 1
		if _check_size(biome_texture(id, "props"), Vector2i(512, 96), "props:" + id, errors): decoded += 1
		if _check_size(biome_texture(id, "background"), Vector2i(640, 360), "background:" + id, errors): decoded += 1
	var expected := {
		"pickups": Vector2i(288, 144), "relics": Vector2i(384, 160), "projectiles": Vector2i(128, 128),
		"effects": Vector2i(256, 256), "hud_panel": Vector2i(512, 96), "menu_panel": Vector2i(512, 512),
		"joystick_base": Vector2i(192, 192), "joystick_thumb": Vector2i(96, 96),
		"touch_dash": Vector2i(128, 128), "touch_interact": Vector2i(112, 112), "touch_pause": Vector2i(72, 72),
	}
	for id in expected.keys():
		if _check_size(utility_texture(String(id)), Vector2i(expected[id]), "utility:" + String(id), errors): decoded += 1
	return {"version": VERSION, "decoded_textures": decoded, "errors": errors, "passed": errors.is_empty()}

func _bundle() -> Dictionary:
	if not _bundle_cache.is_empty():
		return _bundle_cache
	var file := FileAccess.open(INDEX_PATH, FileAccess.READ)
	if file == null:
		last_error = "Compact production bundle index missing"
		push_error(last_error)
		return {}
	var parsed_index: Variant = JSON.parse_string(file.get_as_text())
	if not parsed_index is Dictionary:
		last_error = "Compact production bundle index invalid"
		push_error(last_error)
		return {}
	var encoded := ""
	for chunk in Array((parsed_index as Dictionary).get("chunks", [])):
		var chunk_file := FileAccess.open(String(chunk), FileAccess.READ)
		if chunk_file == null:
			last_error = "Compact bundle chunk missing: %s" % chunk
			push_error(last_error)
			return {}
		encoded += chunk_file.get_as_text().strip_edges()
	var compressed := Marshalls.base64_to_raw(encoded)
	var raw := compressed.decompress_dynamic(8 * 1024 * 1024, FileAccess.COMPRESSION_GZIP)
	if raw.is_empty():
		last_error = "Compact production bundle decompression failed"
		push_error(last_error)
		return {}
	var parsed: Variant = JSON.parse_string(raw.get_string_from_utf8())
	if not parsed is Dictionary:
		last_error = "Compact production bundle JSON failed"
		push_error(last_error)
		return {}
	_bundle_cache = parsed
	return _bundle_cache

func _base_image(path: String) -> Image:
	if _image_cache.has(path):
		return (_image_cache[path] as Image).duplicate()
	var files: Dictionary = _bundle().get("files", {})
	var encoded := String(files.get(path, ""))
	if encoded.is_empty():
		last_error = "Production image missing: %s" % path
		push_error(last_error)
		return Image.new()
	var image := Image.new()
	var result := image.load_png_from_buffer(Marshalls.base64_to_raw(encoded))
	if result != OK:
		last_error = "Production image decode failed: %s" % path
		push_error(last_error)
		return Image.new()
	_image_cache[path] = image
	return image.duplicate()

func _build_actor_sheet(strip: Image, frame_size: int, color: Color) -> Image:
	var sheet := Image.create(frame_size * 8, frame_size * 48, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for action in range(6):
		for direction in range(8):
			var source := strip.get_region(Rect2i(direction * frame_size, 0, frame_size, frame_size))
			for frame in range(8):
				var cell := Image.create(frame_size, frame_size, false, Image.FORMAT_RGBA8)
				cell.fill(Color(0, 0, 0, 0))
				var sprite := source.duplicate()
				var offset := Vector2i.ZERO
				if action == 0:
					offset.y = -1 if frame in [1, 5] else 0
				elif action == 1:
					offset = Vector2i([0, 1, 0, -1, 0, 1, 0, -1][frame], [0, -1, 0, 1, 0, -1, 0, 1][frame])
				elif action == 2:
					offset.x = [0, 0, 1, 2, 1, 0, 0, 0][frame]
				elif action == 3:
					offset.x = [0, 1, 3, 5, 4, 2, 0, 0][frame]
				elif action == 4:
					offset.x = [0, -2, 2, -1, 0, 0, 0, 0][frame]
				elif action == 5 and frame >= 2:
					sprite.resize(frame_size, maxi(12, frame_size - frame * 5), Image.INTERPOLATE_NEAREST)
					offset.y = frame_size - sprite.get_height()
				cell.blend_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), offset)
				if action == 2 and frame in [2, 3, 4]:
					_draw_cross(cell, Vector2i(frame_size - 8, frame_size / 2), color, 2 + frame % 2)
				if action == 3 and frame < 5:
					_draw_dash(cell, color, frame)
				sheet.blend_rect(cell, Rect2i(0, 0, frame_size, frame_size), Vector2i(frame * frame_size, (action * 8 + direction) * frame_size))
	return sheet

func _build_boss_sheet(base: Image, color: Color) -> Image:
	var sheet := Image.create(96 * 8, 96 * 32, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for action in range(4):
		for direction in range(8):
			for frame in range(8):
				var cell := Image.create(96, 96, false, Image.FORMAT_RGBA8)
				cell.fill(Color(0, 0, 0, 0))
				var sprite := base.duplicate()
				if action == 3 and frame >= 2:
					sprite.resize(maxi(24, 96 - frame * 8), maxi(16, 96 - frame * 10), Image.INTERPOLATE_NEAREST)
				cell.blend_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), Vector2i((96 - sprite.get_width()) / 2, 96 - sprite.get_height()))
				if action == 1 and frame in [2, 3, 4, 5]:
					_draw_cross(cell, Vector2i(80, 48), color, 5)
				elif action == 2:
					_draw_border(cell, Rect2i(8 + frame, 8 + frame, 80 - frame * 2, 80 - frame * 2), color)
				sheet.blend_rect(cell, Rect2i(0, 0, 96, 96), Vector2i(frame * 96, (action * 8 + direction) * 96))
	return sheet

func _build_tiles(id: String, palette: Array) -> Image:
	var image := Image.create(256, 128, false, Image.FORMAT_RGBA8)
	var seed := absi(id.hash())
	for y in range(128):
		for x in range(256):
			var tile := (x / 32) + (y / 32) * 8
			var noise := posmod(x * 17 + y * 31 + tile * 13 + seed, 13) - 6
			var base: Color = palette[0 if tile % 3 else 1]
			image.set_pixel(x, y, Color(clampf(base.r + float(noise) / 255.0, 0, 1), clampf(base.g + float(noise) / 255.0, 0, 1), clampf(base.b + float(noise) / 255.0, 0, 1), 1))
	for tile in range(32):
		var rect := Rect2i((tile % 8) * 32, (tile / 8) * 32, 32, 32)
		if tile % 4 == 0:
			_draw_line(image, Vector2i(rect.position.x, rect.position.y + 24), Vector2i(rect.end.x - 1, rect.position.y + 17), palette[2])
		elif tile % 4 == 1:
			_draw_border(image, rect.grow(-3), Color(palette[2], 0.55))
		else:
			for n in range(4):
				image.set_pixel(rect.position.x + posmod(seed + tile * 5 + n * 7, 30) + 1, rect.position.y + posmod(seed + tile * 3 + n * 11, 30) + 1, palette[3])
	return image

func _build_props(id: String, palette: Array) -> Image:
	var image := Image.create(512, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var seed := absi(id.hash())
	for i in range(18):
		var x := 6 + i * 28
		var height := 18 + posmod(seed + i * 17, 54)
		var width := 8 + posmod(seed + i * 11, 15)
		_fill_rect(image, Rect2i(x, 88 - height, width, height), Color(palette[1], 0.92))
		_draw_border(image, Rect2i(x, 88 - height, width, height), palette[2])
		if i % 3 == 0:
			_draw_cross(image, Vector2i(x + width / 2, 84 - height), palette[3], 3)
	return image

func _build_background(id: String, palette: Array) -> Image:
	var image := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	for y in range(360):
		var color: Color = (palette[0] as Color).lerp(palette[1], float(y) / 359.0)
		for x in range(640):
			image.set_pixel(x, y, color)
	var props := _build_props(id, palette)
	props.resize(640, 120, Image.INTERPOLATE_NEAREST)
	image.blend_rect(props, Rect2i(0, 0, 640, 120), Vector2i(0, 240))
	return image

func _synth_loop(index: int, ambience: bool) -> AudioStreamWAV:
	var rate := 11025
	var samples := rate * 4
	var data := PackedByteArray()
	data.resize(samples * 2)
	var roots := [55.0, 61.74, 65.41, 73.42, 49.0]
	var root: float = roots[index]
	for i in range(samples):
		var t := float(i) / float(rate)
		var value := 0.0
		if ambience:
			value = sin(TAU * (28.0 + index * 7.0) * t) * 0.12 + sin(TAU * (180.0 + index * 43.0) * t + sin(t * 0.7) * 2.0) * 0.03
		else:
			value = sin(TAU * root * t) * 0.22 + sin(TAU * root * 1.5 * t + 0.6) * 0.11 + sin(TAU * root * 2.0 * t) * 0.06
		data.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream

func _synth_sfx(id: String) -> AudioStreamWAV:
	var rate := 11025
	var samples := int(rate * 0.28)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var frequency := 260.0 + float(posmod(id.hash(), 7)) * 73.0
	for i in range(samples):
		var t := float(i) / float(rate)
		var envelope := exp(-t * (12.0 if id.begins_with("shot") else 18.0))
		var value := sin(TAU * (frequency + t * 420.0) * t) * envelope * 0.52
		data.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream

func _cache_texture(key: String, image: Image) -> Texture2D:
	if image.is_empty():
		return _fail_texture("Generated image empty: %s" % key)
	var texture := ImageTexture.create_from_image(image)
	texture.resource_name = key
	_texture_cache[key] = texture
	return texture

func _check_size(texture: Texture2D, expected: Vector2i, label: String, errors: Array[String]) -> bool:
	if texture == null:
		errors.append("Missing texture: " + label)
		return false
	var size := texture.get_size()
	if Vector2i(int(size.x), int(size.y)) != expected:
		errors.append("Wrong size %s: %s expected %s" % [label, size, expected])
		return false
	return true

func _draw_cross(image: Image, center: Vector2i, color: Color, radius: int) -> void:
	for i in range(-radius, radius + 1):
		if center.x + i >= 0 and center.x + i < image.get_width() and center.y >= 0 and center.y < image.get_height():
			image.set_pixel(center.x + i, center.y, color)
		if center.y + i >= 0 and center.y + i < image.get_height() and center.x >= 0 and center.x < image.get_width():
			image.set_pixel(center.x, center.y + i, color)

func _draw_dash(image: Image, color: Color, frame: int) -> void:
	for line in range(3):
		var x0 := maxi(1, 12 - frame * 2 - line * 4)
		var y0 := 22 + line * 5
		for x in range(x0, mini(22, x0 + 8 + line * 2)):
			image.set_pixel(x, y0, Color(color, 0.65))

func _draw_line(image: Image, start: Vector2i, end: Vector2i, color: Color) -> void:
	var points := maxi(absi(end.x - start.x), absi(end.y - start.y))
	for i in range(points + 1):
		var t := float(i) / float(maxi(1, points))
		var point := Vector2i(roundi(lerpf(start.x, end.x, t)), roundi(lerpf(start.y, end.y, t)))
		if point.x >= 0 and point.y >= 0 and point.x < image.get_width() and point.y < image.get_height():
			image.set_pixelv(point, color)

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(maxi(0, rect.position.y), mini(image.get_height(), rect.end.y)):
		for x in range(maxi(0, rect.position.x), mini(image.get_width(), rect.end.x)):
			image.set_pixel(x, y, color)

func _draw_border(image: Image, rect: Rect2i, color: Color) -> void:
	_draw_line(image, rect.position, Vector2i(rect.end.x - 1, rect.position.y), color)
	_draw_line(image, Vector2i(rect.position.x, rect.end.y - 1), rect.end - Vector2i.ONE, color)
	_draw_line(image, rect.position, Vector2i(rect.position.x, rect.end.y - 1), color)
	_draw_line(image, Vector2i(rect.end.x - 1, rect.position.y), rect.end - Vector2i.ONE, color)

func _fail_texture(message: String) -> Texture2D:
	last_error = message
	push_error(message)
	return null
