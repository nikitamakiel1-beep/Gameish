extends "res://scripts/v6/pixel_primitives.gd"

const BIOME_PALETTES := {
	"industrial_eden": [Color8(17, 33, 28), Color8(31, 59, 47), Color8(78, 105, 76), Color8(131, 159, 102)],
	"ash_wastes": [Color8(45, 29, 23), Color8(77, 45, 29), Color8(128, 78, 43), Color8(189, 124, 65)],
	"temple_lab": [Color8(14, 32, 42), Color8(30, 65, 74), Color8(58, 118, 116), Color8(112, 174, 163)],
	"fungal_garden": [Color8(42, 25, 50), Color8(75, 39, 82), Color8(128, 63, 133), Color8(192, 109, 184)],
	"nephilim_ruins": [Color8(28, 27, 41), Color8(50, 47, 71), Color8(91, 72, 116), Color8(154, 116, 173)],
}

func build_biome(id: String, kind: String) -> Image:
	var palette: Array = BIOME_PALETTES.get(id, BIOME_PALETTES["industrial_eden"])
	if kind == "tiles":
		return _tiles(id, palette)
	if kind == "props":
		return _props(id, palette)
	return _background(id, palette)

func build_utility(id: String) -> Image:
	match id:
		"pickups": return _pickups()
		"relics": return _relics()
		"projectiles": return _projectiles()
		"effects": return _effects()
		"hud_panel": return _panel(Vector2i(512, 96))
		"menu_panel": return _panel(Vector2i(512, 512))
		"joystick_base": return _touch(Vector2i(192, 192), 0)
		"joystick_thumb": return _touch(Vector2i(96, 96), 1)
		"touch_dash": return _touch(Vector2i(128, 128), 2)
		"touch_interact": return _touch(Vector2i(112, 112), 3)
		"touch_pause": return _touch(Vector2i(72, 72), 4)
	return Image.new()

func _tiles(id: String, palette: Array) -> Image:
	var image := Image.create(256, 128, false, Image.FORMAT_RGBA8)
	var seed := absi(id.hash())
	for y in range(128):
		for x in range(256):
			var tile := int(x / 32) + int(y / 32) * 8
			var noise := posmod(x * 17 + y * 31 + tile * 13 + seed, 13) - 6
			var base := Color(palette[0 if tile % 3 else 1])
			image.set_pixel(x, y, Color(clampf(base.r + float(noise) / 255.0, 0.0, 1.0), clampf(base.g + float(noise) / 255.0, 0.0, 1.0), clampf(base.b + float(noise) / 255.0, 0.0, 1.0), 1.0))
	for tile in range(32):
		var rect := Rect2i((tile % 8) * 32, int(tile / 8) * 32, 32, 32)
		if tile % 4 == 0:
			line(image, Vector2i(rect.position.x, rect.position.y + 24), Vector2i(rect.end.x - 1, rect.position.y + 17), Color(palette[2]))
		elif tile % 4 == 1:
			border(image, rect.grow(-3), alpha(Color(palette[2]), 0.60))
		else:
			for mark in range(4):
				image.set_pixel(rect.position.x + posmod(seed + tile * 5 + mark * 7, 30) + 1, rect.position.y + posmod(seed + tile * 3 + mark * 11, 30) + 1, Color(palette[3]))
	return image

func _props(id: String, palette: Array) -> Image:
	var image := blank(512, 96)
	var seed := absi(id.hash())
	for index in range(18):
		var x := 6 + index * 28
		var height := 18 + posmod(seed + index * 17, 54)
		var width := 8 + posmod(seed + index * 11, 15)
		var rect := Rect2i(x, 88 - height, width, height)
		fill_rect(image, rect, alpha(Color(palette[1]), 0.92))
		border(image, rect, Color(palette[2]))
		if index % 3 == 0:
			cross(image, Vector2i(x + int(width / 2), 84 - height), Color(palette[3]), 3)
	return image

func _background(id: String, palette: Array) -> Image:
	var image := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	for y in range(360):
		var color := Color(palette[0]).lerp(Color(palette[1]), float(y) / 359.0)
		for x in range(640):
			image.set_pixel(x, y, color)
	var props := _props(id, palette)
	props.resize(640, 120, Image.INTERPOLATE_NEAREST)
	image.blend_rect(props, Rect2i(0, 0, 640, 120), Vector2i(0, 240))
	return image

func _pickups() -> Image:
	var image := blank(288, 144)
	var colors: Array[Color] = [Color8(213, 70, 77), Color8(223, 161, 70), Color8(150, 211, 172), Color8(86, 179, 234), Color8(231, 223, 190), Color8(193, 104, 214)]
	for row in range(3):
		for column in range(6):
			var center := Vector2i(column * 48 + 24, row * 48 + 24)
			circle(image, center, 13, Color8(5, 12, 15, 220))
			circle(image, center, 12, colors[column], false)
			cross(image, center, colors[column], 4 + row)
	return image

func _relics() -> Image:
	var image := blank(384, 160)
	for item in range(60):
		var center := Vector2i((item % 12) * 32 + 16, int(item / 12) * 32 + 16)
		var color := Color.from_hsv(float(item % 12) / 12.0, 0.48, 0.95)
		circle(image, center, 11, Color8(5, 12, 15, 230))
		circle(image, center, 10, color, false)
		if item % 3 == 0:
			cross(image, center, color, 5)
		elif item % 3 == 1:
			border(image, Rect2i(center - Vector2i(5, 5), Vector2i(11, 11)), color)
		else:
			line(image, center - Vector2i(6, 4), center + Vector2i(6, 4), color)
	return image

func _projectiles() -> Image:
	var image := blank(128, 128)
	for row in range(8):
		var color := Color.from_hsv(float(row) / 8.0, 0.62, 1.0)
		for frame in range(8):
			var center := Vector2i(frame * 16 + 8, row * 16 + 8)
			circle(image, center, 2 + frame % 2, color)
			for trail in range(1, 5):
				var x := center.x - trail * 2
				if x >= frame * 16:
					image.set_pixel(x, center.y, alpha(color, 1.0 - float(trail) * 0.18))
	return image

func _effects() -> Image:
	var image := blank(256, 256)
	for row in range(8):
		var color := Color.from_hsv(float(row) / 8.0, 0.58, 1.0)
		for frame in range(8):
			var center := Vector2i(frame * 32 + 16, row * 32 + 16)
			var radius := 2 + frame * 2
			circle(image, center, radius, alpha(color, 1.0 - float(frame) * 0.09), false)
			if row % 2 == 0:
				cross(image, center, color, mini(12, radius))
	return image

func _panel(size: Vector2i) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color8(7, 16, 19, 242))
	border(image, Rect2i(2, 2, size.x - 4, size.y - 4), Color8(181, 139, 67))
	border(image, Rect2i(6, 6, size.x - 12, size.y - 12), Color8(77, 114, 98))
	return image

func _touch(size: Vector2i, style: int) -> Image:
	var image := blank(size.x, size.y)
	var center := Vector2i(int(size.x / 2), int(size.y / 2))
	var colors: Array[Color] = [Color8(105, 181, 145), Color8(105, 181, 145), Color8(95, 180, 235), Color8(235, 202, 130), Color8(210, 210, 190)]
	var color := colors[style]
	circle(image, center, int(mini(size.x, size.y) / 2) - 4, Color8(5, 12, 15, 190))
	circle(image, center, int(mini(size.x, size.y) / 2) - 6, color, false)
	if style == 2:
		line(image, center - Vector2i(18, 0), center + Vector2i(18, -10), color, 3)
		line(image, center - Vector2i(18, 0), center + Vector2i(18, 10), color, 3)
	elif style == 3:
		border(image, Rect2i(center - Vector2i(12, 12), Vector2i(24, 24)), color)
	elif style == 4:
		fill_rect(image, Rect2i(center.x - 10, center.y - 15, 7, 30), color)
		fill_rect(image, Rect2i(center.x + 3, center.y - 15, 7, 30), color)
	return image
