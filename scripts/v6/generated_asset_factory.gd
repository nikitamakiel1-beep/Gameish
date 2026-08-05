extends RefCounted

const DIRECTIONS := [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]
const ACTIONS := ["idle", "walk", "attack", "dash", "hurt", "death"]
const HERO_PROFILES := {
	"adam": {"skin": Color8(154, 103, 70), "hair": Color8(237, 226, 199), "primary": Color8(76, 126, 72), "secondary": Color8(197, 174, 103), "eye": Color8(85, 184, 255), "weapon": "vine", "hair_style": "wild"},
	"abel": {"skin": Color8(190, 142, 101), "hair": Color8(222, 185, 126), "primary": Color8(233, 223, 196), "secondary": Color8(174, 81, 56), "eye": Color8(85, 168, 220), "weapon": "staff", "hair_style": "curl"},
	"cain": {"skin": Color8(139, 91, 63), "hair": Color8(35, 29, 25), "primary": Color8(72, 55, 48), "secondary": Color8(203, 55, 42), "eye": Color8(230, 91, 63), "weapon": "gauntlet", "hair_style": "short"},
	"seth": {"skin": Color8(174, 112, 73), "hair": Color8(28, 35, 41), "primary": Color8(34, 75, 104), "secondary": Color8(221, 159, 64), "eye": Color8(84, 177, 255), "weapon": "rifle", "hair_style": "swept"},
	"naamah": {"skin": Color8(119, 75, 62), "hair": Color8(43, 29, 54), "primary": Color8(91, 47, 105), "secondary": Color8(198, 93, 205), "eye": Color8(209, 156, 238), "weapon": "lyre", "hair_style": "long"},
}
const ENEMY_PROFILES := {
	"feral_scavenger": {"kind": "human", "primary": Color8(116, 76, 47), "secondary": Color8(203, 145, 72), "skin": Color8(150, 103, 69), "feature": "ragged"},
	"outlaw_gunner": {"kind": "human", "primary": Color8(83, 62, 49), "secondary": Color8(215, 160, 74), "skin": Color8(168, 113, 74), "feature": "gun"},
	"raider_brute": {"kind": "brute", "primary": Color8(96, 59, 42), "secondary": Color8(190, 88, 48), "skin": Color8(147, 93, 59), "feature": "hammer"},
	"wasteland_hunter": {"kind": "human", "primary": Color8(74, 67, 52), "secondary": Color8(174, 137, 74), "skin": Color8(157, 105, 72), "feature": "bow"},
	"scrap_cultist": {"kind": "caster", "primary": Color8(77, 49, 43), "secondary": Color8(217, 139, 59), "skin": Color8(129, 83, 59), "feature": "hood"},
	"caravan_outlaw": {"kind": "human", "primary": Color8(94, 75, 54), "secondary": Color8(204, 161, 81), "skin": Color8(176, 118, 78), "feature": "blade"},
	"cherub_drone": {"kind": "drone", "primary": Color8(198, 188, 154), "secondary": Color8(242, 218, 137), "skin": Color8(235, 224, 190), "feature": "wings"},
	"fallen_angel": {"kind": "angel", "primary": Color8(83, 75, 71), "secondary": Color8(235, 205, 126), "skin": Color8(180, 142, 110), "feature": "blade"},
	"watcher_acolyte": {"kind": "caster", "primary": Color8(46, 62, 68), "secondary": Color8(224, 194, 111), "skin": Color8(161, 121, 90), "feature": "halo"},
	"halo_sentinel": {"kind": "sentinel", "primary": Color8(58, 67, 66), "secondary": Color8(238, 208, 126), "skin": Color8(181, 143, 104), "feature": "shield"},
	"biomech_pilgrim": {"kind": "robot", "primary": Color8(72, 89, 86), "secondary": Color8(219, 188, 108), "skin": Color8(121, 139, 130), "feature": "cannon"},
	"ophanim_scout": {"kind": "ophanim", "primary": Color8(71, 77, 74), "secondary": Color8(235, 204, 115), "skin": Color8(165, 155, 125), "feature": "ring"},
	"nephilim_husk": {"kind": "monster", "primary": Color8(91, 58, 48), "secondary": Color8(185, 74, 57), "skin": Color8(137, 89, 67), "feature": "husk"},
	"nephilim_giant": {"kind": "giant", "primary": Color8(82, 49, 43), "secondary": Color8(208, 75, 54), "skin": Color8(151, 90, 68), "feature": "giant"},
	"horned_berserker": {"kind": "monster", "primary": Color8(72, 43, 40), "secondary": Color8(226, 70, 49), "skin": Color8(145, 82, 63), "feature": "horns"},
	"bone_shepherd": {"kind": "caster", "primary": Color8(82, 70, 62), "secondary": Color8(215, 196, 159), "skin": Color8(155, 121, 92), "feature": "staff"},
	"grafted_colossus": {"kind": "colossus", "primary": Color8(84, 48, 44), "secondary": Color8(205, 67, 53), "skin": Color8(138, 78, 63), "feature": "grafts"},
	"serpent_spawn": {"kind": "serpent", "primary": Color8(77, 46, 43), "secondary": Color8(222, 75, 54), "skin": Color8(141, 86, 62), "feature": "tail"},
}
const BOSS_COLORS := {
	"watcher_engine": Color8(190, 120, 255),
	"first_nephilim": Color8(245, 65, 54),
	"gate_cherub": Color8(255, 210, 90),
	"tower_enoch": Color8(190, 80, 230),
	"serpent_interface": Color8(160, 225, 65),
}
const BIOME_PALETTES := {
	"industrial_eden": [Color8(17, 33, 28), Color8(31, 59, 47), Color8(78, 105, 76), Color8(131, 159, 102)],
	"ash_wastes": [Color8(45, 29, 23), Color8(77, 45, 29), Color8(128, 78, 43), Color8(189, 124, 65)],
	"temple_lab": [Color8(14, 32, 42), Color8(30, 65, 74), Color8(58, 118, 116), Color8(112, 174, 163)],
	"fungal_garden": [Color8(42, 25, 50), Color8(75, 39, 82), Color8(128, 63, 133), Color8(192, 109, 184)],
	"nephilim_ruins": [Color8(28, 27, 41), Color8(50, 47, 71), Color8(91, 72, 116), Color8(154, 116, 173)],
}

func build_hero_sheet(id: String) -> Image:
	var image := Image.create(384, 2304, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for action_index in range(6):
		for direction in range(8):
			for frame in range(8):
				var cell := hero_frame(id, direction, ACTIONS[action_index], frame)
				image.blend_rect(cell, Rect2i(0, 0, 48, 48), Vector2i(frame * 48, (action_index * 8 + direction) * 48))
	return image

func build_enemy_sheet(id: String) -> Image:
	var image := Image.create(384, 2304, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for action_index in range(6):
		for direction in range(8):
			for frame in range(8):
				var cell := enemy_frame(id, direction, ACTIONS[action_index], frame)
				image.blend_rect(cell, Rect2i(0, 0, 48, 48), Vector2i(frame * 48, (action_index * 8 + direction) * 48))
	return image

func build_boss_sheet(id: String) -> Image:
	var image := Image.create(768, 3072, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for action in range(4):
		for direction in range(8):
			for frame in range(8):
				var cell := boss_frame(id, direction, action, frame)
				image.blend_rect(cell, Rect2i(0, 0, 96, 96), Vector2i(frame * 96, (action * 8 + direction) * 96))
	return image

func build_portrait(id: String) -> Image:
	var profile: Dictionary = HERO_PROFILES[id]
	var image := Image.create(256, 320, false, Image.FORMAT_RGBA8)
	image.fill(Color8(5, 12, 15))
	fill_rect(image, Rect2i(4, 4, 248, 312), Color(profile["primary"], 0.20))
	draw_border(image, Rect2i(4, 4, 248, 312), profile["secondary"])
	var sprite := hero_frame(id, 4, "idle", 0)
	sprite.resize(224, 224, Image.INTERPOLATE_NEAREST)
	image.blend_rect(sprite, Rect2i(0, 0, 224, 224), Vector2i(16, 72))
	return image

func hero_frame(id: String, direction: int, action: String, frame: int) -> Image:
	var p: Dictionary = HERO_PROFILES[id]
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var vector := Vector2(DIRECTIONS[direction]).normalized()
	var bob := [0, -1, 0, 1, 0, -1, 0, 1][frame] if action in ["idle", "walk"] else 0
	var shift := Vector2i.ZERO
	if action == "dash":
		var travel := [0, 1, 3, 5, 4, 2, 0, 0][frame]
		shift = Vector2i(roundi(vector.x * travel), roundi(vector.y * travel))
	elif action == "hurt":
		var knock := [0, -2, 2, -1, 0, 0, 0, 0][frame]
		shift = Vector2i(roundi(vector.x * knock), roundi(vector.y * knock))
	var center_x := 24 + shift.x
	var ground_y := 43 + bob + shift.y
	var outline := Color8(29, 25, 23)
	draw_circle(image, Vector2i(center_x, ground_y), 9, Color(0, 0, 0, 0.32), true, 2)
	var walk_phase := [0, 1, 2, 1, 0, -1, -2, -1][frame] if action == "walk" else 0
	fill_rect(image, Rect2i(center_x - 6 + walk_phase, ground_y - 13, 5, 11), outline)
	fill_rect(image, Rect2i(center_x - 5 + walk_phase, ground_y - 12, 3, 9), p["primary"])
	fill_rect(image, Rect2i(center_x + 2 - walk_phase, ground_y - 13, 5, 11), outline)
	fill_rect(image, Rect2i(center_x + 3 - walk_phase, ground_y - 12, 3, 9), p["primary"])
	fill_rect(image, Rect2i(center_x - 8, ground_y - 27, 17, 16), outline)
	fill_rect(image, Rect2i(center_x - 7, ground_y - 26, 15, 14), p["primary"])
	fill_rect(image, Rect2i(center_x - 7, ground_y - 17, 15, 3), p["secondary"])
	var perpendicular := Vector2(-vector.y, vector.x)
	for side in [-1, 1]:
		var arm := Vector2i(roundi(center_x + perpendicular.x * side * 9.0), roundi(ground_y - 23 + perpendicular.y * side * 2.0))
		draw_circle(image, arm, 3, outline, true)
		draw_circle(image, arm, 2, p["skin"] if id in ["adam", "abel", "naamah"] else p["primary"], true)
	fill_rect(image, Rect2i(center_x - 2, ground_y - 31, 5, 5), p["skin"])
	var head_center := Vector2i(center_x, ground_y - 38)
	draw_circle(image, head_center, 7, outline, true)
	draw_circle(image, head_center, 6, p["skin"], true)
	draw_hair(image, head_center + Vector2i(0, -2), p)
	if direction not in [0, 1, 7]:
		var eye_center := head_center + Vector2i(roundi(vector.x * 3.0), roundi(vector.y * 2.0))
		if direction in [2, 6]:
			draw_circle(image, eye_center, 1, p["eye"], true)
		else:
			draw_circle(image, eye_center + Vector2i(-2, 0), 1, p["eye"], true)
			draw_circle(image, eye_center + Vector2i(2, 0), 1, p["eye"], true)
	draw_hero_weapon(image, Vector2i(center_x, ground_y - 24), vector, p)
	if id == "adam":
		draw_line(image, Vector2i(center_x - 7, ground_y - 22), Vector2i(center_x + 7, ground_y - 22), p["secondary"])
	elif id == "abel":
		fill_rect(image, Rect2i(center_x - 7, ground_y - 26, 15, 4), Color8(233, 230, 213))
	elif id == "cain":
		fill_rect(image, Rect2i(center_x - 9, ground_y - 26, 3, 9), p["secondary"])
		fill_rect(image, Rect2i(center_x + 7, ground_y - 26, 3, 9), p["secondary"])
	elif id == "seth":
		fill_rect(image, Rect2i(center_x - 7, ground_y - 25, 15, 3), p["secondary"])
		draw_circle(image, Vector2i(center_x, ground_y - 22), 2, Color8(80, 190, 255), true)
	else:
		for index in range(3):
			draw_circle(image, Vector2i(center_x - 10 + index * 10, ground_y - 10), 2, p["secondary"], true)
	if action == "attack" and frame in [2, 3, 4]:
		var muzzle := Vector2i(center_x + roundi(vector.x * 18.0), ground_y - 24 + roundi(vector.y * 18.0))
		draw_cross(image, muzzle, p["secondary"], 4)
	if action == "dash" and frame < 5:
		draw_dash(image, p["secondary"], frame, vector)
	if action == "hurt" and frame in [1, 2]:
		tint_nontransparent(image, Color8(255, 90, 70), 0.35)
	if action == "death" and frame >= 2:
		image = collapse(image, frame)
	return image

func enemy_frame(id: String, direction: int, action: String, frame: int) -> Image:
	var p: Dictionary = ENEMY_PROFILES[id]
	var kind := String(p["kind"])
	if kind in ["drone", "ophanim"]:
		return flying_enemy_frame(id, direction, action, frame)
	if kind == "serpent":
		return serpent_enemy_frame(id, direction, action, frame)
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var vector := Vector2(DIRECTIONS[direction]).normalized()
	var scale := 1
	if kind in ["brute", "giant", "colossus", "sentinel"]:
		scale = 2
	var bob := [0, -1, 0, 1, 0, -1, 0, 1][frame] if action in ["idle", "walk"] else 0
	var center := Vector2i(24, 42 + bob)
	var outline := Color8(24, 22, 21)
	draw_circle(image, center, 8 + scale * 2, Color(0, 0, 0, 0.30), true, 2)
	var stride := [0, 1, 2, 1, 0, -1, -2, -1][frame] if action == "walk" else 0
	fill_rect(image, Rect2i(center.x - 5 - scale + stride, center.y - 12, 4 + scale, 10), p["primary"])
	fill_rect(image, Rect2i(center.x + 2 - stride, center.y - 12, 4 + scale, 10), p["primary"])
	fill_rect(image, Rect2i(center.x - 7 - scale, center.y - 27 - scale, 15 + scale * 2, 16 + scale), outline)
	fill_rect(image, Rect2i(center.x - 6 - scale, center.y - 26 - scale, 13 + scale * 2, 14 + scale), p["primary"])
	var head := Vector2i(center.x, center.y - 34 - scale)
	draw_circle(image, head, 6 + scale, outline, true)
	draw_circle(image, head, 5 + scale, p["skin"], true)
	if String(p["feature"]) in ["hood", "halo", "staff"]:
		draw_circle(image, head + Vector2i(0, -2), 7 + scale, p["secondary"], false)
	if String(p["feature"]) == "horns":
		draw_line(image, head + Vector2i(-4, -5), head + Vector2i(-8, -10), p["secondary"])
		draw_line(image, head + Vector2i(4, -5), head + Vector2i(8, -10), p["secondary"])
	if kind == "angel":
		draw_wings(image, center + Vector2i(0, -23), p["secondary"], 12)
	if kind in ["robot", "sentinel"]:
		draw_border(image, Rect2i(center.x - 7 - scale, center.y - 27 - scale, 15 + scale * 2, 16 + scale), p["secondary"])
	var muzzle := center + Vector2i(roundi(vector.x * 15.0), -22 + roundi(vector.y * 15.0))
	if action == "attack" and frame in [2, 3, 4]:
		draw_cross(image, muzzle, p["secondary"], 3 + scale)
	if action == "dash" and frame < 5:
		draw_dash(image, p["secondary"], frame, vector)
	if action == "hurt" and frame in [1, 2]:
		tint_nontransparent(image, Color8(255, 85, 65), 0.42)
	if action == "death" and frame >= 2:
		image = collapse(image, frame)
	return image

func flying_enemy_frame(id: String, direction: int, action: String, frame: int) -> Image:
	var p: Dictionary = ENEMY_PROFILES[id]
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var vector := Vector2(DIRECTIONS[direction]).normalized()
	var center := Vector2i(24, 24 + roundi(sin(float(frame) * PI / 4.0) * 2.0))
	draw_circle(image, center, 9, Color8(21, 24, 24), true)
	draw_circle(image, center, 7, p["primary"], true)
	draw_circle(image, center, 3, p["secondary"], true)
	if String(p["kind"]) == "ophanim":
		draw_circle(image, center, 14, p["secondary"], false)
		draw_circle(image, center, 11, p["secondary"], false)
	else:
		draw_wings(image, center, p["secondary"], 13)
	if action == "attack" and frame in [2, 3, 4]:
		var muzzle := center + Vector2i(roundi(vector.x * 17.0), roundi(vector.y * 17.0))
		draw_cross(image, muzzle, p["secondary"], 4)
	if action == "hurt" and frame in [1, 2]:
		tint_nontransparent(image, Color8(255, 90, 70), 0.45)
	if action == "death" and frame >= 2:
		image = collapse(image, frame)
	return image

func serpent_enemy_frame(id: String, direction: int, action: String, frame: int) -> Image:
	var p: Dictionary = ENEMY_PROFILES[id]
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var vector := Vector2(DIRECTIONS[direction]).normalized()
	var perpendicular := Vector2(-vector.y, vector.x)
	var origin := Vector2(24, 31)
	var points: Array[Vector2i] = []
	for segment in range(7):
		var position := origin - vector * float(segment * 4) + perpendicular * sin(float(segment + frame) * 0.9) * 3.0
		points.append(Vector2i(roundi(position.x), roundi(position.y)))
	for index in range(points.size() - 1):
		draw_line(image, points[index], points[index + 1], p["primary"], 3)
	draw_circle(image, points[0], 5, p["secondary"], true)
	if action == "attack" and frame in [2, 3, 4]:
		draw_cross(image, points[0] + Vector2i(roundi(vector.x * 9.0), roundi(vector.y * 9.0)), p["secondary"], 3)
	if action == "death" and frame >= 2:
		image = collapse(image, frame)
	return image

func boss_frame(id: String, direction: int, action: int, frame: int) -> Image:
	var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var color: Color = BOSS_COLORS[id]
	var dark := Color8(24, 23, 25)
	var vector := Vector2(DIRECTIONS[direction]).normalized()
	var center := Vector2i(48, 50)
	if id == "watcher_engine":
		draw_circle(image, center, 21, dark, true)
		draw_circle(image, center, 17, Color8(71, 66, 75), true)
		draw_circle(image, center, 8, color, true)
		for leg in range(6):
			var angle := float(leg) / 6.0 * TAU
			var start := center + Vector2i(roundi(cos(angle) * 17.0), roundi(sin(angle) * 12.0))
			var end := center + Vector2i(roundi(cos(angle) * 40.0), roundi(sin(angle) * 27.0))
			draw_line(image, start, end, dark, 5)
			draw_line(image, start, end, color, 2)
	elif id == "first_nephilim":
		draw_wings(image, center - Vector2i(0, 10), Color8(68, 36, 38), 34)
		fill_rect(image, Rect2i(34, 28, 29, 43), dark)
		fill_rect(image, Rect2i(37, 31, 23, 37), Color8(115, 55, 48))
		draw_circle(image, Vector2i(48, 22), 11, dark, true)
		draw_circle(image, Vector2i(48, 22), 9, Color8(150, 75, 60), true)
		draw_line(image, Vector2i(42, 15), Vector2i(34, 5), color, 3)
		draw_line(image, Vector2i(54, 15), Vector2i(62, 5), color, 3)
	elif id == "gate_cherub":
		draw_wings(image, center, Color8(221, 188, 105), 36)
		draw_circle(image, center, 18, dark, true)
		draw_circle(image, center, 14, color, true)
		draw_circle(image, center, 29, color, false)
		draw_cross(image, center, Color.WHITE, 7)
	elif id == "tower_enoch":
		for tower in range(7):
			var x := 18 + tower * 10
			var height := 24 + posmod(tower * 13, 34)
			fill_rect(image, Rect2i(x, 80 - height, 8, height), dark)
			draw_border(image, Rect2i(x, 80 - height, 8, height), color)
			draw_circle(image, Vector2i(x + 4, 77 - height), 3, color, true)
		draw_circle(image, center, 13, dark, true)
		draw_circle(image, center, 8, color, true)
	else:
		var points: Array[Vector2i] = []
		for segment in range(12):
			var angle := float(segment) * 0.62 + float(frame) * 0.08
			var radius := 8.0 + float(segment) * 2.7
			points.append(center + Vector2i(roundi(cos(angle) * radius), roundi(sin(angle) * radius * 0.58)))
		for index in range(points.size() - 1):
			draw_line(image, points[index], points[index + 1], dark, 9)
			draw_line(image, points[index], points[index + 1], color, 5)
		draw_circle(image, points[0], 9, dark, true)
		draw_circle(image, points[0], 6, color, true)
	if action == 1 and frame in [2, 3, 4, 5]:
		var muzzle := center + Vector2i(roundi(vector.x * 36.0), roundi(vector.y * 36.0))
		draw_cross(image, muzzle, color, 6)
	elif action == 2:
		draw_border(image, Rect2i(7 + frame, 7 + frame, 82 - frame * 2, 82 - frame * 2), color)
	elif action == 3 and frame >= 2:
		image = collapse(image, frame)
	return image

func draw_hair(image: Image, center: Vector2i, profile: Dictionary) -> void:
	var hair: Color = profile["hair"]
	var dark := hair.darkened(0.38)
	var style := String(profile["hair_style"])
	if style == "wild":
		for offset in [Vector2i(-6, 0), Vector2i(-4, -4), Vector2i(0, -6), Vector2i(4, -5), Vector2i(6, -1), Vector2i(-1, -8), Vector2i(3, -8)]:
			fill_rect(image, Rect2i(center + offset - Vector2i(2, 2), Vector2i(5, 5)), dark)
			fill_rect(image, Rect2i(center + offset - Vector2i(1, 2), Vector2i(3, 4)), hair)
	elif style == "curl":
		for offset in [Vector2i(-5, -3), Vector2i(-2, -6), Vector2i(2, -6), Vector2i(5, -3), Vector2i(-6, 1), Vector2i(6, 1), Vector2i(0, -8)]:
			draw_circle(image, center + offset, 3, dark, true)
			draw_circle(image, center + offset, 2, hair, true)
	elif style == "long":
		fill_rect(image, Rect2i(center - Vector2i(6, 4), Vector2i(13, 14)), dark)
		fill_rect(image, Rect2i(center - Vector2i(5, 5), Vector2i(11, 13)), hair)
		fill_rect(image, Rect2i(center + Vector2i(-7, 0), Vector2i(3, 14)), hair)
		fill_rect(image, Rect2i(center + Vector2i(5, 0), Vector2i(3, 14)), hair)
	elif style == "swept":
		fill_rect(image, Rect2i(center - Vector2i(6, 5), Vector2i(12, 7)), dark)
		fill_rect(image, Rect2i(center - Vector2i(5, 6), Vector2i(11, 7)), hair)
		fill_rect(image, Rect2i(center + Vector2i(3, -8), Vector2i(4, 7)), hair)
	else:
		fill_rect(image, Rect2i(center - Vector2i(5, 5), Vector2i(11, 7)), dark)
		fill_rect(image, Rect2i(center - Vector2i(4, 6), Vector2i(9, 7)), hair)

func draw_hero_weapon(image: Image, center: Vector2i, direction: Vector2, profile: Dictionary) -> void:
	var secondary: Color = profile["secondary"]
	var primary: Color = profile["primary"]
	var dark := Color8(38, 33, 31)
	var perpendicular := Vector2(-direction.y, direction.x)
	match String(profile["weapon"]):
		"staff":
			var start := center + Vector2i(roundi(perpendicular.x * 7.0), roundi(perpendicular.y * 7.0))
			var end := start + Vector2i(roundi(direction.x * 20.0), roundi(direction.y * 20.0))
			draw_line(image, start, end, dark, 3)
			draw_line(image, start, end, secondary)
			draw_circle(image, end, 3, secondary, false)
		"rifle":
			var start := center + Vector2i(roundi(direction.x * 4.0), roundi(direction.y * 4.0))
			var end := center + Vector2i(roundi(direction.x * 18.0), roundi(direction.y * 18.0))
			draw_line(image, start, end, dark, 5)
			draw_line(image, start, end, primary, 3)
			draw_line(image, start, end, secondary)
		"gauntlet":
			for side in [-1, 1]:
				var point := center + Vector2i(roundi(direction.x * 7.0 + perpendicular.x * side * 6.0), roundi(direction.y * 7.0 + perpendicular.y * side * 6.0))
				draw_circle(image, point, 4, dark, true)
				fill_rect(image, Rect2i(point - Vector2i(2, 2), Vector2i(5, 5)), secondary)
		"lyre":
			var point := center + Vector2i(roundi(perpendicular.x * 7.0), roundi(perpendicular.y * 7.0))
			draw_circle(image, point, 6, secondary, false)
			draw_line(image, point - Vector2i(2, 4), point + Vector2i(-2, 4), secondary)
			draw_line(image, point - Vector2i(-2, 4), point + Vector2i(2, 4), secondary)
		_:
			var points: Array[Vector2i] = []
			for index in range(5):
				var wave := sin(float(index) * 1.8) * 2.0
				points.append(center + Vector2i(roundi(direction.x * index * 4.0 - direction.y * wave), roundi(direction.y * index * 4.0 + direction.x * wave)))
			for index in range(points.size() - 1):
				draw_line(image, points[index], points[index + 1], primary, 2)
			for index in range(1, points.size(), 2):
				draw_circle(image, points[index], 2, secondary, true)

func build_biome(id: String, kind: String) -> Image:
	var palette: Array = BIOME_PALETTES[id]
	if kind == "tiles":
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
				draw_line(image, Vector2i(rect.position.x, rect.position.y + 24), Vector2i(rect.end.x - 1, rect.position.y + 17), palette[2])
			elif tile % 4 == 1:
				draw_border(image, rect.grow(-3), Color(palette[2], 0.55))
			else:
				for mark in range(4):
					image.set_pixel(rect.position.x + posmod(seed + tile * 5 + mark * 7, 30) + 1, rect.position.y + posmod(seed + tile * 3 + mark * 11, 30) + 1, palette[3])
		return image
	if kind == "props":
		var image := Image.create(512, 96, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		var seed := absi(id.hash())
		for index in range(18):
			var x := 6 + index * 28
			var height := 18 + posmod(seed + index * 17, 54)
			var width := 8 + posmod(seed + index * 11, 15)
			fill_rect(image, Rect2i(x, 88 - height, width, height), Color(palette[1], 0.92))
			draw_border(image, Rect2i(x, 88 - height, width, height), palette[2])
			if index % 3 == 0:
				draw_cross(image, Vector2i(x + width / 2, 84 - height), palette[3], 3)
		return image
	var background := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	for y in range(360):
		var color: Color = Color(palette[0]).lerp(Color(palette[1]), float(y) / 359.0)
		for x in range(640):
			background.set_pixel(x, y, color)
	var props := build_biome(id, "props")
	props.resize(640, 120, Image.INTERPOLATE_NEAREST)
	background.blend_rect(props, Rect2i(0, 0, 640, 120), Vector2i(0, 240))
	return background

func build_utility(id: String) -> Image:
	if id == "pickups":
		var image := Image.create(288, 144, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		var colors := [Color8(213, 70, 77), Color8(223, 161, 70), Color8(150, 211, 172), Color8(86, 179, 234), Color8(231, 223, 190), Color8(193, 104, 214)]
		for row in range(3):
			for column in range(6):
				var center := Vector2i(column * 48 + 24, row * 48 + 24)
				draw_circle(image, center, 13, Color(5, 12, 15, 0.82), true)
				draw_circle(image, center, 12, colors[column], false)
				if row == 0 and column == 0:
					draw_cross(image, center, Color.WHITE, 7)
				elif row == 2:
					draw_key(image, center, colors[column])
				else:
					draw_cross(image, center, colors[column], 4 + row)
		return image
	if id == "relics":
		var image := Image.create(384, 160, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		for item in range(60):
			var center := Vector2i((item % 12) * 32 + 16, (item / 12) * 32 + 16)
			var color := Color.from_hsv(float(item % 12) / 12.0, 0.48, 0.95)
			draw_circle(image, center, 11, Color(5, 12, 15, 0.90), true)
			draw_circle(image, center, 10, color, false)
			if item % 3 == 0:
				draw_cross(image, center, color, 5)
			elif item % 3 == 1:
				draw_border(image, Rect2i(center - Vector2i(5, 5), Vector2i(11, 11)), color)
			else:
				draw_line(image, center - Vector2i(6, 4), center + Vector2i(6, 4), color)
				draw_line(image, center - Vector2i(6, -4), center + Vector2i(6, -4), color)
		return image
	if id == "projectiles":
		var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		var colors := [Color8(190, 222, 92), Color8(255, 218, 126), Color8(246, 63, 48), Color8(77, 174, 255), Color8(201, 89, 231), Color8(230, 118, 68), Color8(245, 221, 150), Color8(212, 82, 235)]
		for row in range(8):
			for frame in range(8):
				var center := Vector2i(frame * 16 + 7 + frame % 3, row * 16 + 8)
				draw_circle(image, center, 2 + frame % 2, colors[row], true)
				for trail in range(1, 5):
					var point := center - Vector2i(trail * 2, 0)
					if point.x >= frame * 16:
						image.set_pixelv(point, Color(colors[row], 1.0 - float(trail) * 0.18))
		return image
	if id == "effects":
		var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		for row in range(8):
			var color := Color.from_hsv(float(row) / 8.0, 0.58, 1.0)
			for frame in range(8):
				var center := Vector2i(frame * 32 + 16, row * 32 + 16)
				var radius := 2 + frame * 2
				draw_circle(image, center, radius, Color(color, 1.0 - float(frame) * 0.09), false)
				if row % 2 == 0:
					draw_cross(image, center, color, mini(12, radius))
		return image
	if id in ["hud_panel", "menu_panel"]:
		var size := Vector2i(512, 96) if id == "hud_panel" else Vector2i(512, 512)
		var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		image.fill(Color8(7, 16, 19, 242))
		draw_border(image, Rect2i(2, 2, size.x - 4, size.y - 4), Color8(181, 139, 67))
		draw_border(image, Rect2i(6, 6, size.x - 12, size.y - 12), Color8(77, 114, 98))
		return image
	var size := Vector2i(192, 192)
	if id == "joystick_thumb": size = Vector2i(96, 96)
	elif id == "touch_dash": size = Vector2i(128, 128)
	elif id == "touch_interact": size = Vector2i(112, 112)
	elif id == "touch_pause": size = Vector2i(72, 72)
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2i(size.x >> 1, size.y >> 1)
	var color := Color8(105, 181, 145)
	if id == "touch_dash": color = Color8(95, 180, 235)
	elif id == "touch_interact": color = Color8(235, 202, 130)
	elif id == "touch_pause": color = Color8(210, 210, 190)
	draw_circle(image, center, mini(size.x, size.y) / 2 - 4, Color(5, 12, 15, 0.72), true)
	draw_circle(image, center, mini(size.x, size.y) / 2 - 5, color, false)
	if id == "touch_dash":
		draw_line(image, center - Vector2i(18, 0), center + Vector2i(18, -10), color)
		draw_line(image, center - Vector2i(18, 0), center + Vector2i(18, 10), color)
	elif id == "touch_interact":
		draw_border(image, Rect2i(center - Vector2i(12, 12), Vector2i(24, 24)), color)
	elif id == "touch_pause":
		fill_rect(image, Rect2i(center.x - 10, center.y - 15, 7, 30), color)
		fill_rect(image, Rect2i(center.x + 3, center.y - 15, 7, 30), color)
	return image

func synth_loop(index: int, ambience: bool) -> AudioStreamWAV:
	var rate := 11025
	var samples := rate * 4
	var data := PackedByteArray()
	data.resize(samples * 2)
	var roots := [55.0, 61.74, 65.41, 73.42, 49.0]
	var root: float = roots[index]
	for sample in range(samples):
		var time := float(sample) / float(rate)
		var value := sin(TAU * root * time) * 0.22 + sin(TAU * root * 1.5 * time + 0.6) * 0.11
		if ambience:
			value = sin(TAU * (28.0 + index * 7.0) * time) * 0.12 + sin(TAU * (180.0 + index * 43.0) * time + sin(time * 0.7) * 2.0) * 0.03
		data.encode_s16(sample * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream

func synth_sfx(id: String) -> AudioStreamWAV:
	var rate := 11025
	var samples := int(rate * 0.28)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var frequency := 260.0 + float(posmod(id.hash(), 7)) * 73.0
	for sample in range(samples):
		var time := float(sample) / float(rate)
		var envelope := exp(-time * (12.0 if id.begins_with("shot") else 18.0))
		var value := sin(TAU * (frequency + time * 420.0) * time) * envelope * 0.52
		data.encode_s16(sample * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream

func collapse(image: Image, frame: int) -> Image:
	var bounds := image.get_used_rect()
	if bounds.size == Vector2i.ZERO:
		return image
	var sprite := image.get_region(bounds)
	sprite.resize(sprite.get_width(), maxi(8, int(float(sprite.get_height()) * maxf(0.22, 1.0 - float(frame - 1) * 0.11))), Image.INTERPOLATE_NEAREST)
	var result := Image.create(48 if image.get_width() == 48 else 96, 48 if image.get_height() == 48 else 96, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	result.blend_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), Vector2i((result.get_width() - sprite.get_width()) / 2, result.get_height() - sprite.get_height() - 2))
	return result

func draw_wings(image: Image, center: Vector2i, color: Color, span: int) -> void:
	for side in [-1, 1]:
		var root := center + Vector2i(side * 5, -2)
		for feather in range(4):
			var end := center + Vector2i(side * (span - feather * 3), -10 + feather * 7)
			draw_line(image, root, end, Color8(30, 28, 29), 5)
			draw_line(image, root, end, color, 2)

func tint_nontransparent(image: Image, tint: Color, strength: float) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var current := image.get_pixel(x, y)
			if current.a > 0.0:
				image.set_pixel(x, y, current.lerp(Color(tint, current.a), strength))

func draw_key(image: Image, center: Vector2i, color: Color) -> void:
	draw_circle(image, center - Vector2i(5, 0), 5, color, false)
	draw_line(image, center, center + Vector2i(11, 0), color)
	fill_rect(image, Rect2i(center.x + 7, center.y, 2, 5), color)
	fill_rect(image, Rect2i(center.x + 11, center.y, 2, 4), color)

func draw_dash(image: Image, color: Color, frame: int, direction: Vector2) -> void:
	var behind := -direction
	var perpendicular := Vector2(-direction.y, direction.x)
	for index in range(3):
		var origin := Vector2(24, 24) + behind * float(10 + index * 5 + frame * 2) + perpendicular * float((index - 1) * 4)
		var end := origin + behind * float(6 + index * 3)
		draw_line(image, Vector2i(roundi(origin.x), roundi(origin.y)), Vector2i(roundi(end.x), roundi(end.y)), Color(color, 0.65))

func draw_circle(image: Image, center: Vector2i, radius: int, color: Color, filled: bool, vertical_scale: int = 1) -> void:
	var outer := radius * radius
	var inner := maxi(0, (radius - 2) * (radius - 2))
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			var dy := (y - center.y) * vertical_scale
			var distance := (x - center.x) * (x - center.x) + dy * dy
			if distance <= outer and (filled or distance >= inner):
				image.set_pixel(x, y, color)

func draw_cross(image: Image, center: Vector2i, color: Color, radius: int) -> void:
	for offset in range(-radius, radius + 1):
		if center.x + offset >= 0 and center.x + offset < image.get_width() and center.y >= 0 and center.y < image.get_height():
			image.set_pixel(center.x + offset, center.y, color)
		if center.y + offset >= 0 and center.y + offset < image.get_height() and center.x >= 0 and center.x < image.get_width():
			image.set_pixel(center.x, center.y + offset, color)

func draw_line(image: Image, start: Vector2i, end: Vector2i, color: Color, width: int = 1) -> void:
	var points := maxi(absi(end.x - start.x), absi(end.y - start.y))
	for index in range(points + 1):
		var ratio := float(index) / float(maxi(1, points))
		var point := Vector2i(roundi(lerpf(start.x, end.x, ratio)), roundi(lerpf(start.y, end.y, ratio)))
		var half_width := int(width / 2)
		fill_rect(image, Rect2i(point - Vector2i(half_width, half_width), Vector2i(width, width)), color)

func fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(maxi(0, rect.position.y), mini(image.get_height(), rect.end.y)):
		for x in range(maxi(0, rect.position.x), mini(image.get_width(), rect.end.x)):
			image.set_pixel(x, y, color)

func draw_border(image: Image, rect: Rect2i, color: Color) -> void:
	draw_line(image, rect.position, Vector2i(rect.end.x - 1, rect.position.y), color)
	draw_line(image, Vector2i(rect.position.x, rect.end.y - 1), rect.end - Vector2i.ONE, color)
	draw_line(image, rect.position, Vector2i(rect.position.x, rect.end.y - 1), color)
	draw_line(image, Vector2i(rect.end.x - 1, rect.position.y), rect.end - Vector2i.ONE, color)
