extends "res://scripts/v6/pixel_primitives.gd"

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]
const ACTIONS: Array[String] = ["idle", "walk", "attack", "dash", "hurt", "death"]
const HERO_IDS: Array[String] = ["adam", "abel", "cain", "seth", "naamah"]
const HERO_PROFILES := {
	"adam": [Color8(154, 103, 70), Color8(237, 226, 199), Color8(76, 126, 72), Color8(197, 174, 103), Color8(85, 184, 255), 0],
	"abel": [Color8(190, 142, 101), Color8(222, 185, 126), Color8(233, 223, 196), Color8(174, 81, 56), Color8(85, 168, 220), 1],
	"cain": [Color8(139, 91, 63), Color8(35, 29, 25), Color8(72, 55, 48), Color8(203, 55, 42), Color8(230, 91, 63), 2],
	"seth": [Color8(174, 112, 73), Color8(28, 35, 41), Color8(34, 75, 104), Color8(221, 159, 64), Color8(84, 177, 255), 3],
	"naamah": [Color8(119, 75, 62), Color8(43, 29, 54), Color8(91, 47, 105), Color8(198, 93, 205), Color8(209, 156, 238), 4],
}
const ENEMY_IDS: Array[String] = [
	"feral_scavenger", "outlaw_gunner", "raider_brute", "wasteland_hunter", "scrap_cultist", "caravan_outlaw",
	"cherub_drone", "fallen_angel", "watcher_acolyte", "halo_sentinel", "biomech_pilgrim", "ophanim_scout",
	"nephilim_husk", "nephilim_giant", "horned_berserker", "bone_shepherd", "grafted_colossus", "serpent_spawn",
]
const BOSS_IDS: Array[String] = ["watcher_engine", "first_nephilim", "gate_cherub", "tower_enoch", "serpent_interface"]
const BOSS_COLORS: Array[Color] = [Color8(190, 120, 255), Color8(245, 65, 54), Color8(255, 210, 90), Color8(190, 80, 230), Color8(160, 225, 65)]

func build_hero_sheet(id: String) -> Image:
	return _sheet(id, 48, 6, true)

func build_enemy_sheet(id: String) -> Image:
	return _sheet(id, 48, 6, false)

func build_boss_sheet(id: String) -> Image:
	var sheet := blank(768, 3072)
	for action in range(4):
		for direction in range(8):
			for frame in range(8):
				var cell := _boss_frame(id, direction, action, frame)
				sheet.blend_rect(cell, Rect2i(0, 0, 96, 96), Vector2i(frame * 96, (action * 8 + direction) * 96))
	return sheet

func build_portrait(id: String) -> Image:
	var profile: Array = HERO_PROFILES.get(id, HERO_PROFILES["adam"])
	var image := Image.create(256, 320, false, Image.FORMAT_RGBA8)
	image.fill(Color8(5, 12, 15))
	fill_rect(image, Rect2i(5, 5, 246, 310), alpha(Color(profile[2]), 0.22))
	border(image, Rect2i(5, 5, 246, 310), Color(profile[3]))
	var sprite := _hero_frame(id, 4, "idle", 0)
	sprite.resize(224, 224, Image.INTERPOLATE_NEAREST)
	image.blend_rect(sprite, Rect2i(0, 0, 224, 224), Vector2i(16, 72))
	return image

func _sheet(id: String, frame_size: int, action_count: int, hero: bool) -> Image:
	var sheet := blank(frame_size * 8, frame_size * action_count * 8)
	for action_index in range(action_count):
		for direction in range(8):
			for frame in range(8):
				var cell := _hero_frame(id, direction, ACTIONS[action_index], frame) if hero else _enemy_frame(id, direction, ACTIONS[action_index], frame)
				sheet.blend_rect(cell, Rect2i(0, 0, frame_size, frame_size), Vector2i(frame * frame_size, (action_index * 8 + direction) * frame_size))
	return sheet

func _hero_frame(id: String, direction_index: int, action: String, frame: int) -> Image:
	var profile: Array = HERO_PROFILES.get(id, HERO_PROFILES["adam"])
	var skin := Color(profile[0])
	var hair := Color(profile[1])
	var primary := Color(profile[2])
	var accent := Color(profile[3])
	var eye := Color(profile[4])
	var style := int(profile[5])
	var image := blank(48, 48)
	var direction := Vector2(DIRECTIONS[direction_index]).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var bob := 0
	if action == "idle":
		bob = [0, -1, 0, 0, 0, -1, 0, 0][frame]
	elif action == "walk":
		bob = [0, -1, 0, 1, 0, -1, 0, 1][frame]
	var shift := Vector2i.ZERO
	if action == "dash":
		var travel: int = [0, 2, 4, 6, 4, 2, 0, 0][frame]
		shift = Vector2i(roundi(direction.x * travel), roundi(direction.y * travel))
	elif action == "hurt":
		var knock: int = [0, -2, 2, -1, 0, 0, 0, 0][frame]
		shift = Vector2i(roundi(direction.x * knock), roundi(direction.y * knock))
	var center_x := 24 + shift.x
	var ground := 44 + bob + shift.y
	shadow(image, Vector2i(center_x, ground))
	var stride := 0
	if action == "walk":
		stride = [0, 1, 2, 1, 0, -1, -2, -1][frame]
	_draw_limb(image, Rect2i(center_x - 7 + stride, ground - 13, 5, 11), primary)
	_draw_limb(image, Rect2i(center_x + 2 - stride, ground - 13, 5, 11), primary)
	fill_rect(image, Rect2i(center_x - 9, ground - 29, 19, 18), Color8(28, 25, 23))
	fill_rect(image, Rect2i(center_x - 8, ground - 28, 17, 16), primary)
	fill_rect(image, Rect2i(center_x - 8, ground - 18, 17, 3), accent)
	for side in [-1, 1]:
		var arm := Vector2i(roundi(center_x + perpendicular.x * float(side) * 10.0), roundi(ground - 25 + perpendicular.y * float(side) * 3.0))
		circle(image, arm, 4, Color8(28, 25, 23))
		circle(image, arm, 3, skin)
	var head := Vector2i(center_x, ground - 38)
	circle(image, head, 8, Color8(28, 25, 23))
	circle(image, head, 7, skin)
	_draw_hair(image, head, style, hair)
	_draw_eyes(image, head, direction_index, direction, eye)
	_draw_weapon(image, Vector2i(center_x, ground - 25), direction, perpendicular, style, primary, accent)
	if action == "attack" and frame in [2, 3, 4]:
		cross(image, Vector2i(center_x + roundi(direction.x * 20.0), ground - 25 + roundi(direction.y * 20.0)), accent, 4)
	if action == "dash" and frame < 5:
		_draw_dash(image, Vector2(center_x, ground - 22), direction, accent, frame)
	if action == "hurt" and frame in [1, 2]:
		tint(image, Color8(255, 80, 65), 0.40)
	if action == "death" and frame >= 2:
		return collapse(image, frame)
	return image

func _enemy_frame(id: String, direction_index: int, action: String, frame: int) -> Image:
	var enemy_index := maxi(0, ENEMY_IDS.find(id))
	var family := int(enemy_index / 6)
	var variant := enemy_index % 6
	var primaries: Array[Color] = [Color8(108, 76, 50), Color8(83, 86, 79), Color8(91, 52, 46)]
	var accents: Array[Color] = [Color8(222, 151, 67), Color8(235, 211, 126), Color8(225, 70, 54)]
	var skins: Array[Color] = [Color8(158, 107, 72), Color8(170, 145, 108), Color8(143, 84, 65)]
	var primary := primaries[family].lightened(float(variant) * 0.025)
	var accent := accents[family]
	var skin := skins[family]
	var image := blank(48, 48)
	var direction := Vector2(DIRECTIONS[direction_index]).normalized()
	if family == 1 and variant in [0, 5]:
		return _flying_enemy(image, direction, action, frame, primary, accent, variant == 5)
	if family == 2 and variant == 5:
		return _serpent_enemy(image, direction, action, frame, primary, accent)
	var large := variant in [2, 3, 4]
	var size_bonus := 2 if large else 0
	var bob := 0
	if action in ["idle", "walk"]:
		bob = [0, -1, 0, 1, 0, -1, 0, 1][frame]
	var center := Vector2i(24, 43 + bob)
	shadow(image, center, 9 + size_bonus)
	var stride := 0
	if action == "walk":
		stride = [0, 1, 2, 1, 0, -1, -2, -1][frame]
	_draw_limb(image, Rect2i(center.x - 6 - size_bonus + stride, center.y - 12, 5 + size_bonus, 10), primary)
	_draw_limb(image, Rect2i(center.x + 2 - stride, center.y - 12, 5 + size_bonus, 10), primary)
	fill_rect(image, Rect2i(center.x - 8 - size_bonus, center.y - 28 - size_bonus, 17 + size_bonus * 2, 17 + size_bonus), Color8(25, 23, 22))
	fill_rect(image, Rect2i(center.x - 7 - size_bonus, center.y - 27 - size_bonus, 15 + size_bonus * 2, 15 + size_bonus), primary)
	var head := Vector2i(center.x, center.y - 36 - size_bonus)
	circle(image, head, 7 + size_bonus, Color8(25, 23, 22))
	circle(image, head, 6 + size_bonus, skin)
	if family == 1:
		circle(image, head, 9 + size_bonus, accent, false)
	if family == 2 and variant == 2:
		line(image, head + Vector2i(-4, -5), head + Vector2i(-8, -11), accent, 2)
		line(image, head + Vector2i(4, -5), head + Vector2i(8, -11), accent, 2)
	if action == "attack" and frame in [2, 3, 4]:
		cross(image, center + Vector2i(roundi(direction.x * 18.0), -23 + roundi(direction.y * 18.0)), accent, 3 + size_bonus)
	if action == "hurt" and frame in [1, 2]:
		tint(image, Color8(255, 80, 65), 0.42)
	if action == "death" and frame >= 2:
		return collapse(image, frame)
	return image

func _flying_enemy(image: Image, direction: Vector2, action: String, frame: int, primary: Color, accent: Color, ring: bool) -> Image:
	var center := Vector2i(24, 24 + roundi(sin(float(frame) * PI / 4.0) * 2.0))
	circle(image, center, 10, Color8(23, 24, 24))
	circle(image, center, 8, primary)
	circle(image, center, 3, accent)
	if ring:
		circle(image, center, 15, accent, false)
	else:
		wings(image, center, accent, 14)
	if action == "attack" and frame in [2, 3, 4]:
		cross(image, center + Vector2i(roundi(direction.x * 18.0), roundi(direction.y * 18.0)), accent, 4)
	if action == "death" and frame >= 2:
		return collapse(image, frame)
	return image

func _serpent_enemy(image: Image, direction: Vector2, action: String, frame: int, primary: Color, accent: Color) -> Image:
	var perpendicular := Vector2(-direction.y, direction.x)
	var previous := Vector2i(24, 30)
	for segment in range(7):
		var point := Vector2(24, 30) - direction * float(segment * 4) + perpendicular * sin(float(segment + frame) * 0.9) * 3.0
		var current := Vector2i(roundi(point.x), roundi(point.y))
		if segment > 0:
			line(image, previous, current, Color8(24, 22, 22), 6)
			line(image, previous, current, primary, 3)
		previous = current
	circle(image, Vector2i(24, 30), 6, accent)
	if action == "attack" and frame in [2, 3, 4]:
		cross(image, Vector2i(24, 30) + Vector2i(roundi(direction.x * 10.0), roundi(direction.y * 10.0)), accent, 3)
	if action == "death" and frame >= 2:
		return collapse(image, frame)
	return image

func _boss_frame(id: String, direction_index: int, action: int, frame: int) -> Image:
	var boss_index := maxi(0, BOSS_IDS.find(id))
	var color := BOSS_COLORS[boss_index]
	var image := blank(96, 96)
	var center := Vector2i(48, 50)
	var direction := Vector2(DIRECTIONS[direction_index]).normalized()
	if boss_index == 0:
		circle(image, center, 22, Color8(24, 23, 25))
		circle(image, center, 17, Color8(71, 66, 75))
		circle(image, center, 8, color)
		for leg in range(6):
			var angle := float(leg) / 6.0 * TAU
			line(image, center, center + Vector2i(roundi(cos(angle) * 40.0), roundi(sin(angle) * 28.0)), color, 4)
	elif boss_index == 1:
		wings(image, center - Vector2i(0, 8), Color8(85, 38, 42), 36)
		fill_rect(image, Rect2i(34, 27, 29, 45), Color8(88, 46, 44))
		circle(image, Vector2i(48, 22), 11, color)
	elif boss_index == 2:
		wings(image, center, Color8(221, 188, 105), 37)
		circle(image, center, 18, color)
		circle(image, center, 30, color, false)
		cross(image, center, Color.WHITE, 7)
	elif boss_index == 3:
		for tower in range(7):
			var height := 25 + posmod(tower * 13, 35)
			var rect := Rect2i(17 + tower * 10, 82 - height, 8, height)
			fill_rect(image, rect, Color8(31, 28, 37))
			border(image, rect, color)
		circle(image, center, 9, color)
	else:
		var previous := center
		for segment in range(12):
			var angle := float(segment) * 0.62 + float(frame) * 0.08
			var radius := 8.0 + float(segment) * 2.7
			var point := center + Vector2i(roundi(cos(angle) * radius), roundi(sin(angle) * radius * 0.58))
			if segment > 0:
				line(image, previous, point, Color8(23, 25, 22), 9)
				line(image, previous, point, color, 5)
			previous = point
	if action == 1 and frame in [2, 3, 4, 5]:
		cross(image, center + Vector2i(roundi(direction.x * 38.0), roundi(direction.y * 38.0)), color, 6)
	elif action == 2:
		border(image, Rect2i(7 + frame, 7 + frame, 82 - frame * 2, 82 - frame * 2), color)
	elif action == 3 and frame >= 2:
		return collapse(image, frame)
	return image

func _draw_limb(image: Image, rect: Rect2i, color: Color) -> void:
	fill_rect(image, rect.grow(1), Color8(26, 23, 22))
	fill_rect(image, rect, color)

func _draw_hair(image: Image, head: Vector2i, style: int, color: Color) -> void:
	var dark := color.darkened(0.38)
	if style == 0:
		for offset in [Vector2i(-6, -2), Vector2i(-3, -7), Vector2i(1, -9), Vector2i(5, -6), Vector2i(7, -1)]:
			fill_rect(image, Rect2i(head + offset - Vector2i(2, 2), Vector2i(5, 5)), dark)
			fill_rect(image, Rect2i(head + offset - Vector2i(1, 2), Vector2i(3, 4)), color)
	elif style == 1:
		for offset in [Vector2i(-5, -4), Vector2i(-1, -7), Vector2i(3, -7), Vector2i(6, -3), Vector2i(-6, 0)]:
			circle(image, head + offset, 3, dark)
			circle(image, head + offset, 2, color)
	elif style == 4:
		fill_rect(image, Rect2i(head - Vector2i(6, 6), Vector2i(13, 17)), dark)
		fill_rect(image, Rect2i(head - Vector2i(5, 7), Vector2i(11, 16)), color)
	else:
		fill_rect(image, Rect2i(head - Vector2i(6, 6), Vector2i(12, 8)), dark)
		fill_rect(image, Rect2i(head - Vector2i(5, 7), Vector2i(10, 8)), color)

func _draw_eyes(image: Image, head: Vector2i, direction_index: int, direction: Vector2, color: Color) -> void:
	if direction_index in [0, 1, 7]:
		return
	var center := head + Vector2i(roundi(direction.x * 3.0), roundi(direction.y * 2.0))
	if direction_index in [2, 6]:
		circle(image, center, 1, color)
	else:
		circle(image, center + Vector2i(-2, 0), 1, color)
		circle(image, center + Vector2i(2, 0), 1, color)

func _draw_weapon(image: Image, center: Vector2i, direction: Vector2, perpendicular: Vector2, style: int, primary: Color, accent: Color) -> void:
	var start := center + Vector2i(roundi(direction.x * 3.0), roundi(direction.y * 3.0))
	var finish := center + Vector2i(roundi(direction.x * 20.0), roundi(direction.y * 20.0))
	if style == 1:
		start = center + Vector2i(roundi(perpendicular.x * 7.0), roundi(perpendicular.y * 7.0))
		finish = start + Vector2i(roundi(direction.x * 20.0), roundi(direction.y * 20.0))
		line(image, start, finish, accent, 2)
		circle(image, finish, 3, accent, false)
	elif style == 2:
		for side in [-1, 1]:
			var point := center + Vector2i(roundi(direction.x * 7.0 + perpendicular.x * float(side) * 6.0), roundi(direction.y * 7.0 + perpendicular.y * float(side) * 6.0))
			circle(image, point, 4, accent)
	elif style == 4:
		var point := center + Vector2i(roundi(perpendicular.x * 7.0), roundi(perpendicular.y * 7.0))
		circle(image, point, 6, accent, false)
		line(image, point - Vector2i(2, 4), point + Vector2i(-2, 4), accent)
		line(image, point + Vector2i(2, -4), point + Vector2i(2, 4), accent)
	else:
		line(image, start, finish, Color8(36, 31, 29), 5)
		line(image, start, finish, primary, 3)
		line(image, start, finish, accent)

func _draw_dash(image: Image, center: Vector2, direction: Vector2, color: Color, frame: int) -> void:
	var behind := -direction
	var perpendicular := Vector2(-direction.y, direction.x)
	for index in range(3):
		var start := center + behind * float(10 + index * 5 + frame * 2) + perpendicular * float((index - 1) * 4)
		var finish := start + behind * float(6 + index * 3)
		line(image, Vector2i(roundi(start.x), roundi(start.y)), Vector2i(roundi(finish.x), roundi(finish.y)), alpha(color, 0.65))
