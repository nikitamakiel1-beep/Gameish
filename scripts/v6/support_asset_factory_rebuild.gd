extends "res://scripts/v6/support_asset_factory.gd"

const ENVIRONMENT_REVISION := "0.6.1"

const REBUILD_PALETTES := {
	"industrial_eden": {
		"floor": Color8(14, 28, 24), "floor_alt": Color8(22, 43, 34),
		"structure": Color8(53, 75, 64), "highlight": Color8(117, 166, 111),
		"nature": Color8(52, 118, 68), "emissive": Color8(137, 222, 145),
		"sky": Color8(8, 17, 18),
	},
	"ash_wastes": {
		"floor": Color8(43, 28, 23), "floor_alt": Color8(66, 39, 29),
		"structure": Color8(102, 65, 48), "highlight": Color8(201, 126, 68),
		"nature": Color8(112, 88, 51), "emissive": Color8(238, 171, 85),
		"sky": Color8(30, 20, 21),
	},
	"temple_lab": {
		"floor": Color8(12, 29, 38), "floor_alt": Color8(20, 51, 60),
		"structure": Color8(54, 92, 96), "highlight": Color8(116, 190, 176),
		"nature": Color8(49, 111, 94), "emissive": Color8(112, 233, 210),
		"sky": Color8(7, 18, 25),
	},
	"fungal_garden": {
		"floor": Color8(36, 23, 43), "floor_alt": Color8(61, 35, 69),
		"structure": Color8(92, 59, 101), "highlight": Color8(188, 102, 184),
		"nature": Color8(91, 111, 62), "emissive": Color8(225, 133, 225),
		"sky": Color8(21, 12, 28),
	},
	"nephilim_ruins": {
		"floor": Color8(25, 25, 37), "floor_alt": Color8(42, 39, 58),
		"structure": Color8(77, 69, 95), "highlight": Color8(163, 122, 188),
		"nature": Color8(70, 91, 76), "emissive": Color8(205, 142, 230),
		"sky": Color8(12, 11, 22),
	},
}

func build_biome(id: String, kind: String) -> Image:
	var palette: Dictionary = REBUILD_PALETTES.get(id, REBUILD_PALETTES["industrial_eden"])
	match kind:
		"tiles":
			return _rebuild_tiles(id, palette)
		"props":
			return _rebuild_props(id, palette)
		_:
			return _rebuild_background(id, palette)

func build_utility(id: String) -> Image:
	match id:
		"relics":
			return _rebuild_relics()
		"projectiles":
			return _rebuild_projectiles()
		"effects":
			return _rebuild_effects()
		"hud_panel":
			return _rebuild_panel(Vector2i(512, 96), false)
		"menu_panel":
			return _rebuild_panel(Vector2i(512, 512), true)
		_:
			return super.build_utility(id)

func _rebuild_tiles(id: String, palette: Dictionary) -> Image:
	var image := blank(256, 128)
	var seed := absi(id.hash())
	for tile in range(32):
		var origin := Vector2i((tile % 8) * 32, int(tile / 8) * 32)
		var rect := Rect2i(origin, Vector2i(32, 32))
		var base: Color = palette["floor"] if tile % 3 != 0 else palette["floor_alt"]
		fill_rect(image, rect, base)
		fill_rect(image, Rect2i(origin + Vector2i(1, 1), Vector2i(30, 3)), base.lightened(0.045))
		fill_rect(image, Rect2i(origin + Vector2i(1, 28), Vector2i(30, 3)), base.darkened(0.12))
		match id:
			"industrial_eden":
				_tile_lab(image, origin, tile, seed, palette)
			"ash_wastes":
				_tile_ash(image, origin, tile, seed, palette)
			"temple_lab":
				_tile_temple(image, origin, tile, seed, palette)
			"fungal_garden":
				_tile_fungal(image, origin, tile, seed, palette)
			_:
				_tile_ruins(image, origin, tile, seed, palette)
	return image

func _tile_lab(image: Image, origin: Vector2i, tile: int, seed: int, palette: Dictionary) -> void:
	var structure: Color = palette["structure"]
	var nature: Color = palette["nature"]
	if tile % 4 == 0:
		border(image, Rect2i(origin + Vector2i(3, 3), Vector2i(26, 26)), Color(structure, 0.62))
		line(image, origin + Vector2i(4, 16), origin + Vector2i(28, 16), Color(structure, 0.48), 2)
	elif tile % 4 == 1:
		line(image, origin + Vector2i(0, 25), origin + Vector2i(31, 9), Color(structure, 0.55), 2)
		line(image, origin + Vector2i(9, 31), origin + Vector2i(18, 18), Color(structure, 0.40), 2)
	else:
		for leaf in range(4):
			var p := origin + Vector2i(posmod(seed + tile * 7 + leaf * 11, 26) + 3, posmod(seed + tile * 13 + leaf * 5, 26) + 3)
			circle(image, p, 2 + leaf % 2, Color(nature, 0.72))
			line(image, p, p + Vector2i(0, 5), Color(nature.darkened(0.28), 0.72))

func _tile_ash(image: Image, origin: Vector2i, tile: int, seed: int, palette: Dictionary) -> void:
	var structure: Color = palette["structure"]
	var highlight: Color = palette["highlight"]
	if tile % 5 == 0:
		fill_rect(image, Rect2i(origin + Vector2i(0, 11), Vector2i(32, 10)), structure.darkened(0.33))
		line(image, origin + Vector2i(0, 16), origin + Vector2i(31, 16), Color(highlight, 0.42), 2)
		for dash in range(3):
			fill_rect(image, Rect2i(origin + Vector2i(3 + dash * 11, 15), Vector2i(6, 2)), Color8(210, 184, 128, 130))
	else:
		for rock in range(5):
			var p := origin + Vector2i(posmod(seed + tile * 5 + rock * 9, 28) + 2, posmod(seed + tile * 11 + rock * 7, 25) + 4)
			fill_rect(image, Rect2i(p, Vector2i(2 + rock % 3, 2 + (rock + 1) % 3)), structure.darkened(float(rock % 2) * 0.14))
		if tile % 3 == 0:
			line(image, origin + Vector2i(4, 29), origin + Vector2i(25, 5), Color(highlight, 0.34), 2)

func _tile_temple(image: Image, origin: Vector2i, tile: int, seed: int, palette: Dictionary) -> void:
	var structure: Color = palette["structure"]
	var emissive: Color = palette["emissive"]
	if tile % 3 == 0:
		border(image, Rect2i(origin + Vector2i(4, 4), Vector2i(24, 24)), Color(structure, 0.65))
		circle(image, origin + Vector2i(16, 16), 7, Color(emissive, 0.42), false)
		cross(image, origin + Vector2i(16, 16), Color(emissive, 0.55), 4)
	elif tile % 3 == 1:
		for x in [6, 16, 26]:
			line(image, origin + Vector2i(x, 2), origin + Vector2i(x - 5, 30), Color(structure, 0.48), 2)
	else:
		line(image, origin + Vector2i(2, 26), origin + Vector2i(29, 7), Color(emissive, 0.36), 2)
		for node in range(3):
			circle(image, origin + Vector2i(8 + node * 8, 22 - node * 5), 2, Color(emissive, 0.56))

func _tile_fungal(image: Image, origin: Vector2i, tile: int, seed: int, palette: Dictionary) -> void:
	var nature: Color = palette["nature"]
	var emissive: Color = palette["emissive"]
	for fungus in range(3 + tile % 3):
		var p := origin + Vector2i(posmod(seed + tile * 7 + fungus * 9, 25) + 3, posmod(seed + tile * 3 + fungus * 11, 22) + 7)
		line(image, p, p + Vector2i(0, 5), Color(nature, 0.65), 2)
		circle(image, p, 3 + fungus % 2, Color(emissive, 0.44))
		fill_rect(image, Rect2i(p + Vector2i(-3, 0), Vector2i(7, 2)), Color(emissive, 0.70))
	if tile % 4 == 0:
		circle(image, origin + Vector2i(17, 18), 10, Color(nature, 0.24), false)

func _tile_ruins(image: Image, origin: Vector2i, tile: int, seed: int, palette: Dictionary) -> void:
	var structure: Color = palette["structure"]
	var emissive: Color = palette["emissive"]
	if tile % 4 == 0:
		fill_rect(image, Rect2i(origin + Vector2i(3, 6), Vector2i(26, 20)), structure.darkened(0.24))
		for window in range(3):
			fill_rect(image, Rect2i(origin + Vector2i(6 + window * 8, 10), Vector2i(4, 7)), Color(emissive, 0.24))
		line(image, origin + Vector2i(4, 25), origin + Vector2i(27, 7), Color8(16, 15, 21), 3)
	else:
		for crack in range(3):
			var start := origin + Vector2i(posmod(seed + tile * 5 + crack * 9, 24) + 4, posmod(seed + tile * 8 + crack * 5, 19) + 5)
			line(image, start, start + Vector2i(4 + crack * 2, 8 + crack * 3), Color(structure.lightened(0.12), 0.48), 2)

func _rebuild_props(id: String, palette: Dictionary) -> Image:
	var image := blank(512, 96)
	var structure: Color = palette["structure"]
	var highlight: Color = palette["highlight"]
	var nature: Color = palette["nature"]
	var emissive: Color = palette["emissive"]
	match id:
		"industrial_eden":
			for section in range(4):
				var x := section * 128
				fill_rect(image, Rect2i(x + 8, 34, 34, 54), structure.darkened(0.28))
				border(image, Rect2i(x + 8, 34, 34, 54), highlight)
				fill_rect(image, Rect2i(x + 14, 43, 22, 35), Color(emissive, 0.20))
				for vine in range(4):
					var start := Vector2i(x + 54 + vine * 14, 5 + vine * 4)
					line(image, start, start + Vector2i(-6 + vine * 2, 70), nature, 3)
					for leaf in range(3):
						circle(image, start + Vector2i(-2 + leaf * 2, 18 + leaf * 17), 3, nature.lightened(0.12))
				line(image, Vector2i(x + 45, 82), Vector2i(x + 120, 82), highlight.darkened(0.30), 5)
		"ash_wastes":
			for section in range(4):
				var x := section * 128
				fill_rect(image, Rect2i(x + 8, 55, 66, 25), structure.darkened(0.22))
				fill_rect(image, Rect2i(x + 20, 43, 34, 16), structure)
				for wheel_x in [20, 61]:
					circle(image, Vector2i(x + wheel_x, 82), 8, Color8(22, 20, 20))
					circle(image, Vector2i(x + wheel_x, 82), 4, highlight.darkened(0.35), false)
				for rubble in range(7):
					fill_rect(image, Rect2i(x + 78 + rubble * 6, 75 - (rubble % 3) * 4, 7, 8 + (rubble % 2) * 5), structure.darkened(float(rubble % 3) * 0.08))
		"temple_lab":
			for section in range(4):
				var x := section * 128
				for pillar in [16, 99]:
					fill_rect(image, Rect2i(x + pillar, 18, 13, 70), structure.darkened(0.18))
					fill_rect(image, Rect2i(x + pillar - 4, 14, 21, 7), highlight.darkened(0.25))
				circle(image, Vector2i(x + 64, 48), 25, highlight, false)
				circle(image, Vector2i(x + 64, 48), 14, emissive, false)
				cross(image, Vector2i(x + 64, 48), Color(emissive, 0.75), 8)
		"fungal_garden":
			for section in range(4):
				var x := section * 128
				for fungus in range(6):
					var fx := x + 12 + fungus * 19
					var height := 25 + (fungus * 13 + section * 7) % 50
					line(image, Vector2i(fx, 88), Vector2i(fx, 88 - height), nature, 5)
					circle(image, Vector2i(fx, 86 - height), 9 + fungus % 4, Color8(34, 22, 39))
					fill_rect(image, Rect2i(fx - 9 - fungus % 4, 83 - height, 19 + (fungus % 4) * 2, 5), emissive)
					circle(image, Vector2i(fx - 3, 82 - height), 2, Color8(238, 184, 236))
		_:
			for section in range(4):
				var x := section * 128
				fill_rect(image, Rect2i(x + 4, 39, 58, 49), structure.darkened(0.23))
				for window in range(3):
					fill_rect(image, Rect2i(x + 10 + window * 16, 48, 8, 15), Color8(13, 12, 21))
				for rib in range(4):
					var root := Vector2i(x + 70 + rib * 14, 88)
					line(image, root, root + Vector2i(-9 + rib * 5, -58 - rib * 5), Color8(174, 158, 137), 5)
					line(image, root + Vector2i(-9 + rib * 5, -58 - rib * 5), root + Vector2i(10 + rib * 4, -71 + rib * 2), emissive.darkened(0.25), 2)
	return image

func _rebuild_background(id: String, palette: Dictionary) -> Image:
	var image := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	var sky: Color = palette["sky"]
	var floor: Color = palette["floor"]
	var highlight: Color = palette["highlight"]
	var nature: Color = palette["nature"]
	var emissive: Color = palette["emissive"]
	for y in range(360):
		var t := float(y) / 359.0
		var color := sky.lerp(floor.darkened(0.12), pow(t, 1.35))
		for x in range(640):
			image.set_pixel(x, y, color)
	for band in range(6):
		var x := 35 + band * 113
		fill_rect(image, Rect2i(x, 0, 34, 360), Color(highlight, 0.012 + float(band % 2) * 0.006))
	for building in range(18):
		var width := 22 + (building * 17 + absi(id.hash())) % 52
		var height := 48 + (building * 31 + absi(id.hash())) % 165
		var x := building * 39 - 18
		var rect := Rect2i(x, 270 - height, width, height)
		fill_rect(image, rect, Color(palette["structure"]).darkened(0.42))
		if id in ["industrial_eden", "nephilim_ruins"]:
			for window_y in range(rect.position.y + 10, rect.end.y - 8, 18):
				for window_x in range(rect.position.x + 7, rect.end.x - 5, 13):
					fill_rect(image, Rect2i(window_x, window_y, 4, 7), Color(emissive, 0.11))
	if id in ["industrial_eden", "fungal_garden", "nephilim_ruins"]:
		for vine in range(27):
			var start := Vector2i(posmod(absi(id.hash()) + vine * 47, 640), 92 + posmod(vine * 31, 190))
			var length := 42 + posmod(vine * 17, 110)
			line(image, start, start + Vector2i(-8 + vine % 17, length), Color(nature, 0.45), 3)
			for leaf in range(4):
				circle(image, start + Vector2i((leaf % 2) * 5 - 2, 11 + leaf * int(length / 5)), 3, Color(nature.lightened(0.08), 0.52))
	elif id == "ash_wastes":
		for smoke in range(12):
			var center := Vector2i(30 + smoke * 55, 120 + posmod(smoke * 23, 100))
			for radius in [8, 13, 19]:
				circle(image, center + Vector2i(radius, -radius), radius, Color8(70, 48, 42, 40))
	var props := _rebuild_props(id, palette)
	props.resize(640, 120, Image.INTERPOLATE_NEAREST)
	image.blend_rect(props, Rect2i(Vector2i.ZERO, props.get_size()), Vector2i(0, 240))
	return image

func _rebuild_relics() -> Image:
	var image := blank(384, 160)
	var base_colors: Array[Color] = [Color8(132, 190, 119), Color8(232, 197, 112), Color8(221, 84, 67), Color8(94, 172, 228), Color8(194, 111, 211), Color8(117, 211, 176)]
	for item in range(60):
		var center := Vector2i((item % 12) * 32 + 16, int(item / 12) * 32 + 16)
		var color := base_colors[item % base_colors.size()].lightened(float(int(item / 12)) * 0.035)
		circle(image, center, 13, Color8(3, 8, 10, 235))
		circle(image, center, 11, Color(color, 0.88), false)
		match item % 8:
			0:
				line(image, center + Vector2i(0, -8), center + Vector2i(0, 8), color, 3)
				line(image, center + Vector2i(-6, 1), center + Vector2i(6, 1), color, 2)
			1:
				circle(image, center, 6, color, false)
				circle(image, center, 2, Color8(239, 229, 185))
			2:
				for side in [-1, 1]:
					line(image, center, center + Vector2i(side * 8, -7), color, 2)
					line(image, center, center + Vector2i(side * 8, 7), color, 2)
			3:
				border(image, Rect2i(center - Vector2i(6, 6), Vector2i(13, 13)), color)
				cross(image, center, color, 4)
			4:
				for radius in [3, 6, 9]:
					circle(image, center, radius, Color(color, 0.72), false)
			5:
				line(image, center + Vector2i(-8, 7), center + Vector2i(0, -8), color, 3)
				line(image, center + Vector2i(0, -8), center + Vector2i(8, 7), color, 3)
			6:
				for angle in [0.0, 2.1, 4.2]:
					circle(image, center + Vector2i(roundi(cos(angle) * 6), roundi(sin(angle) * 6)), 3, color)
			_:
				line(image, center + Vector2i(-8, -5), center + Vector2i(8, 5), color, 3)
				line(image, center + Vector2i(-8, 5), center + Vector2i(8, -5), color, 3)
	return image

func _rebuild_projectiles() -> Image:
	var image := blank(128, 128)
	var colors: Array[Color] = [Color8(155, 225, 144), Color8(241, 218, 137), Color8(255, 91, 68), Color8(104, 187, 250), Color8(220, 128, 236), Color8(233, 77, 71), Color8(236, 186, 91), Color8(185, 210, 213)]
	for row in range(8):
		var color := colors[row]
		for frame in range(8):
			var cell := Vector2i(frame * 16, row * 16)
			var center := cell + Vector2i(8, 8)
			for trail in range(5):
				var alpha_value := 0.65 - float(trail) * 0.11
				fill_rect(image, Rect2i(center + Vector2i(-6 - trail * 2, -1), Vector2i(3, 3)), Color(color, alpha_value))
			circle(image, center, 4 if row in [2, 5] else 3, Color8(255, 244, 207))
			circle(image, center, 3 if row in [2, 5] else 2, color)
			if row in [1, 4, 6]:
				circle(image, center, 6, Color(color, 0.48), false)
	return image

func _rebuild_effects() -> Image:
	var image := blank(256, 256)
	var colors: Array[Color] = [Color8(147, 223, 137), Color8(244, 210, 119), Color8(245, 89, 67), Color8(102, 185, 242), Color8(218, 124, 229), Color8(236, 73, 74), Color8(233, 174, 81), Color8(173, 209, 199)]
	for row in range(8):
		var color := colors[row]
		for frame in range(8):
			var center := Vector2i(frame * 32 + 16, row * 32 + 16)
			var progress := float(frame) / 7.0
			var radius := 3 + frame * 2
			circle(image, center, radius, Color(color, 0.88 - progress * 0.55), false)
			for ray in range(6):
				var angle := TAU * float(ray) / 6.0 + float(frame) * 0.17
				var start := center + Vector2i(roundi(cos(angle) * float(radius - 2)), roundi(sin(angle) * float(radius - 2)))
				var finish := center + Vector2i(roundi(cos(angle) * float(radius + 7)), roundi(sin(angle) * float(radius + 7)))
				line(image, start, finish, Color(color, 0.72 - progress * 0.45), 2)
	return image

func _rebuild_panel(size: Vector2i, large: bool) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color8(4, 10, 12, 246))
	fill_rect(image, Rect2i(4, 4, size.x - 8, size.y - 8), Color8(10, 20, 22, 244))
	border(image, Rect2i(2, 2, size.x - 4, size.y - 4), Color8(218, 183, 101))
	border(image, Rect2i(7, 7, size.x - 14, size.y - 14), Color8(72, 116, 96))
	if large:
		for line_y in range(22, size.y - 16, 28):
			line(image, Vector2i(13, line_y), Vector2i(size.x - 14, line_y - 12), Color8(72, 116, 96, 38), 2)
	return image
