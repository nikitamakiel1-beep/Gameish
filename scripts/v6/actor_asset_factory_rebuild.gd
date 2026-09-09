extends "res://scripts/v6/actor_asset_factory.gd"

const VISUAL_REVISION := "0.6.1"

const ENEMY_VISUALS := {
	"feral_scavenger": {"shape":"scavenger","primary":Color8(92,74,55),"accent":Color8(196,133,64),"skin":Color8(151,101,68)},
	"outlaw_gunner": {"shape":"gunner","primary":Color8(63,56,49),"accent":Color8(224,151,61),"skin":Color8(163,108,72)},
	"raider_brute": {"shape":"brute","primary":Color8(104,63,48),"accent":Color8(209,76,48),"skin":Color8(154,94,68)},
	"wasteland_hunter": {"shape":"hunter","primary":Color8(77,69,50),"accent":Color8(210,161,78),"skin":Color8(173,113,72)},
	"scrap_cultist": {"shape":"cultist","primary":Color8(71,54,45),"accent":Color8(190,107,62),"skin":Color8(139,90,69)},
	"caravan_outlaw": {"shape":"skirmisher","primary":Color8(70,63,50),"accent":Color8(232,168,75),"skin":Color8(170,112,75)},
	"cherub_drone": {"shape":"drone","primary":Color8(84,93,91),"accent":Color8(239,215,124),"skin":Color8(180,157,111)},
	"fallen_angel": {"shape":"angel","primary":Color8(78,80,75),"accent":Color8(216,199,132),"skin":Color8(171,145,108)},
	"watcher_acolyte": {"shape":"acolyte","primary":Color8(63,75,74),"accent":Color8(105,210,200),"skin":Color8(151,132,102)},
	"halo_sentinel": {"shape":"sentinel","primary":Color8(73,82,80),"accent":Color8(239,205,104),"skin":Color8(154,136,102)},
	"biomech_pilgrim": {"shape":"pilgrim","primary":Color8(57,82,78),"accent":Color8(99,196,176),"skin":Color8(145,124,95)},
	"ophanim_scout": {"shape":"ophanim","primary":Color8(74,81,78),"accent":Color8(241,215,115),"skin":Color8(165,144,104)},
	"nephilim_husk": {"shape":"husk","primary":Color8(86,53,49),"accent":Color8(211,72,54),"skin":Color8(139,80,65)},
	"nephilim_giant": {"shape":"giant","primary":Color8(94,55,49),"accent":Color8(224,75,52),"skin":Color8(149,84,66)},
	"horned_berserker": {"shape":"berserker","primary":Color8(81,45,44),"accent":Color8(239,82,52),"skin":Color8(145,77,62)},
	"bone_shepherd": {"shape":"shepherd","primary":Color8(69,57,55),"accent":Color8(222,199,157),"skin":Color8(137,91,75)},
	"grafted_colossus": {"shape":"colossus","primary":Color8(83,50,53),"accent":Color8(204,68,80),"skin":Color8(134,76,67)},
	"serpent_spawn": {"shape":"serpent","primary":Color8(76,47,50),"accent":Color8(226,72,92),"skin":Color8(137,78,68)},
}

func build_portrait(id: String) -> Image:
	var profile: Array = HERO_PROFILES.get(id, HERO_PROFILES["adam"])
	var primary := Color(profile[2])
	var accent := Color(profile[3])
	var image := Image.create(256, 320, false, Image.FORMAT_RGBA8)
	image.fill(Color8(3, 7, 9))
	fill_rect(image, Rect2i(5, 5, 246, 310), primary.darkened(0.62))
	fill_rect(image, Rect2i(11, 11, 234, 298), Color8(8, 14, 16))
	for y in range(26, 296, 22):
		line(image, Vector2i(15, y), Vector2i(241, y - 17), Color(primary, 0.10), 2)
	for radius in [104, 84, 64]:
		circle(image, Vector2i(128, 146), radius, Color(accent, 0.17), false)
	var sprite := _hero_frame(id, 4, "idle", 1)
	sprite.resize(236, 236, Image.INTERPOLATE_NEAREST)
	image.blend_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), Vector2i(10, 60))
	fill_rect(image, Rect2i(17, 286, 222, 15), Color8(4, 9, 11))
	fill_rect(image, Rect2i(17, 286, 222, 3), accent)
	border(image, Rect2i(5, 5, 246, 310), accent.darkened(0.15))
	return image

func _hero_frame(id: String, direction_index: int, action: String, frame: int) -> Image:
	var profile: Array = HERO_PROFILES.get(id, HERO_PROFILES["adam"])
	var skin := Color(profile[0])
	var hair := Color(profile[1])
	var primary := Color(profile[2])
	var accent := Color(profile[3])
	var eye := Color(profile[4])
	var image := blank(48, 48)
	var direction := Vector2(DIRECTIONS[direction_index]).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var phase := float(frame) * PI / 4.0
	var bob := roundi(sin(phase) * (1.0 if action in ["idle", "walk"] else 0.0))
	var stride := roundi(sin(phase) * 2.0) if action == "walk" else 0
	var shift := Vector2i.ZERO
	if action == "dash":
		shift = Vector2i(roundi(direction.x * float([0, 3, 6, 8, 6, 3, 0, 0][frame])), roundi(direction.y * float([0, 3, 6, 8, 6, 3, 0, 0][frame])))
	elif action == "hurt":
		shift = Vector2i(roundi(direction.x * float([0, -2, 2, -1, 0, 0, 0, 0][frame])), roundi(direction.y * float([0, -2, 2, -1, 0, 0, 0, 0][frame])))
	var center := Vector2i(24 + shift.x, 42 + bob + shift.y)
	shadow(image, center + Vector2i(0, 2), 11)
	match id:
		"abel":
			_draw_abel(image, center, direction, perpendicular, stride, skin, hair, primary, accent, eye, action, frame)
		"cain":
			_draw_cain(image, center, direction, perpendicular, stride, skin, hair, primary, accent, eye, action, frame)
		"seth":
			_draw_seth(image, center, direction, perpendicular, stride, skin, hair, primary, accent, eye, action, frame)
		"naamah":
			_draw_naamah(image, center, direction, perpendicular, stride, skin, hair, primary, accent, eye, action, frame)
		_:
			_draw_adam(image, center, direction, perpendicular, stride, skin, hair, primary, accent, eye, action, frame)
	if action == "dash" and frame < 6:
		_draw_dash(image, Vector2(center.x, center.y - 19), direction, accent, frame)
	if action == "hurt" and frame in [1, 2]:
		tint(image, Color8(255, 74, 58), 0.48)
	if action == "death" and frame >= 2:
		return collapse(image, frame)
	return image

func _draw_adam(image: Image, center: Vector2i, direction: Vector2, perpendicular: Vector2, stride: int, skin: Color, hair: Color, primary: Color, accent: Color, eye: Color, action: String, frame: int) -> void:
	_boots(image, center, stride, primary.darkened(0.30))
	fill_rect(image, Rect2i(center.x - 9, center.y - 27, 18, 17), Color8(22, 25, 22))
	fill_rect(image, Rect2i(center.x - 8, center.y - 26, 16, 15), primary)
	fill_rect(image, Rect2i(center.x - 8, center.y - 18, 16, 3), accent)
	for side in [-1, 1]:
		var shoulder := center + Vector2i(roundi(perpendicular.x * float(side) * 10.0), -22 + roundi(perpendicular.y * float(side) * 2.0))
		circle(image, shoulder, 4, Color8(24, 24, 22))
		circle(image, shoulder, 3, skin)
	var head := center + Vector2i(0, -35)
	circle(image, head, 8, Color8(22, 22, 21))
	circle(image, head, 7, skin)
	_draw_hair(image, head, 0, hair)
	_draw_eyes(image, head, _dir_index(direction), direction, eye)
	line(image, center + Vector2i(-8, -19), center + Vector2i(7, -13), accent, 2)
	var muzzle := center + Vector2i(roundi(direction.x * 21.0), -21 + roundi(direction.y * 18.0))
	line(image, center + Vector2i(0, -21), muzzle, Color8(30, 33, 28), 5)
	line(image, center + Vector2i(0, -21), muzzle, accent, 2)
	if action == "attack" and frame in [2, 3, 4]:
		cross(image, muzzle + Vector2i(roundi(direction.x * 3.0), roundi(direction.y * 3.0)), Color8(239, 226, 157), 4)

func _draw_abel(image: Image, center: Vector2i, direction: Vector2, perpendicular: Vector2, stride: int, skin: Color, hair: Color, primary: Color, accent: Color, eye: Color, action: String, frame: int) -> void:
	_boots(image, center, stride, accent.darkened(0.30))
	for row in range(17):
		var half := 6 + int(float(row) * 0.22)
		fill_rect(image, Rect2i(center.x - half, center.y - 28 + row, half * 2 + 1, 1), primary if row < 13 else accent.darkened(0.15))
	border(image, Rect2i(center.x - 8, center.y - 28, 17, 18), Color8(45, 35, 29))
	var head := center + Vector2i(0, -36)
	circle(image, head, 8, Color8(35, 30, 27))
	circle(image, head, 7, skin)
	circle(image, head + Vector2i(0, -1), 9, hair.darkened(0.25), false)
	circle(image, head + Vector2i(0, -2), 11, Color(accent, 0.8), false)
	_draw_eyes(image, head, _dir_index(direction), direction, eye)
	var hand := center + Vector2i(roundi(perpendicular.x * 8.0), -22 + roundi(perpendicular.y * 3.0))
	var staff_tip := hand - Vector2i(roundi(direction.x * 2.0), 19 + roundi(direction.y * 4.0))
	line(image, hand, staff_tip, Color8(77, 53, 35), 3)
	circle(image, staff_tip, 4, accent, false)
	if action == "attack" and frame in [2, 3, 4]:
		for radius in [4, 8, 12]:
			circle(image, staff_tip + Vector2i(roundi(direction.x * 5.0), roundi(direction.y * 5.0)), radius, Color(accent, 0.85), false)

func _draw_cain(image: Image, center: Vector2i, direction: Vector2, perpendicular: Vector2, stride: int, skin: Color, hair: Color, primary: Color, accent: Color, eye: Color, action: String, frame: int) -> void:
	_boots(image, center, stride, Color8(35, 29, 27))
	fill_rect(image, Rect2i(center.x - 11, center.y - 28, 22, 18), Color8(25, 23, 23))
	fill_rect(image, Rect2i(center.x - 10, center.y - 27, 20, 16), primary)
	fill_rect(image, Rect2i(center.x - 10, center.y - 20, 20, 6), accent)
	for side in [-1, 1]:
		var arm := center + Vector2i(roundi(perpendicular.x * float(side) * 12.0), -21 + roundi(perpendicular.y * float(side) * 3.0))
		circle(image, arm, 5, Color8(29, 24, 24))
		circle(image, arm, 4, accent)
		if action == "attack" and frame in [2, 3, 4]:
			cross(image, arm + Vector2i(roundi(direction.x * 9.0), roundi(direction.y * 9.0)), Color8(255, 109, 65), 5)
	var head := center + Vector2i(0, -36)
	circle(image, head, 8, Color8(22, 20, 20))
	circle(image, head, 7, skin)
	fill_rect(image, Rect2i(head.x - 7, head.y - 8, 14, 7), hair.darkened(0.25))
	line(image, head + Vector2i(-5, 4), head + Vector2i(5, -4), accent, 2)
	_draw_eyes(image, head, _dir_index(direction), direction, eye)

func _draw_seth(image: Image, center: Vector2i, direction: Vector2, perpendicular: Vector2, stride: int, skin: Color, hair: Color, primary: Color, accent: Color, eye: Color, action: String, frame: int) -> void:
	_boots(image, center, stride, primary.darkened(0.25))
	fill_rect(image, Rect2i(center.x - 10, center.y - 29, 20, 19), Color8(22, 28, 32))
	fill_rect(image, Rect2i(center.x - 9, center.y - 28, 18, 17), primary)
	fill_rect(image, Rect2i(center.x - 8, center.y - 24, 16, 3), accent)
	var head := center + Vector2i(0, -37)
	circle(image, head, 9, Color8(20, 25, 29))
	fill_rect(image, Rect2i(head.x - 7, head.y - 6, 14, 11), hair)
	fill_rect(image, Rect2i(head.x - 6, head.y - 1, 12, 3), eye)
	var shield_center := center + Vector2i(roundi(perpendicular.x * -11.0), -21 + roundi(perpendicular.y * -11.0))
	circle(image, shield_center, 8, Color8(19, 27, 32))
	circle(image, shield_center, 7, Color(accent, 0.85), false)
	line(image, shield_center - Vector2i(5, 0), shield_center + Vector2i(5, 0), accent, 2)
	line(image, shield_center - Vector2i(0, 5), shield_center + Vector2i(0, 5), accent, 2)
	var gun_start := center + Vector2i(roundi(perpendicular.x * 7.0), -21 + roundi(perpendicular.y * 7.0))
	var gun_end := gun_start + Vector2i(roundi(direction.x * 18.0), roundi(direction.y * 18.0))
	line(image, gun_start, gun_end, Color8(26, 30, 31), 5)
	line(image, gun_start, gun_end, accent, 2)
	if action == "attack" and frame in [2, 3, 4]:
		cross(image, gun_end, Color8(135, 222, 255), 4)

func _draw_naamah(image: Image, center: Vector2i, direction: Vector2, perpendicular: Vector2, stride: int, skin: Color, hair: Color, primary: Color, accent: Color, eye: Color, action: String, frame: int) -> void:
	_boots(image, center, stride, primary.darkened(0.30))
	for row in range(19):
		var half := 7 + int(float(row) * 0.18)
		fill_rect(image, Rect2i(center.x - half, center.y - 29 + row, half * 2 + 1, 1), primary)
	for side in [-1, 1]:
		var cap := center + Vector2i(side * 9, -27)
		circle(image, cap, 5, Color8(31, 21, 36))
		circle(image, cap, 4, accent)
		circle(image, cap + Vector2i(side * 2, -2), 2, Color8(230, 173, 238))
	var head := center + Vector2i(0, -37)
	circle(image, head, 8, Color8(25, 19, 29))
	circle(image, head, 7, skin)
	fill_rect(image, Rect2i(head.x - 7, head.y - 8, 14, 15), hair)
	_draw_eyes(image, head, _dir_index(direction), direction, eye)
	var orb := center + Vector2i(roundi(perpendicular.x * 11.0), -22 + roundi(perpendicular.y * 11.0))
	circle(image, orb, 7, Color8(22, 15, 27))
	circle(image, orb, 6, accent, false)
	for angle in [0.0, 2.1, 4.2]:
		var spore := orb + Vector2i(roundi(cos(angle + float(frame) * 0.2) * 4.0), roundi(sin(angle + float(frame) * 0.2) * 4.0))
		circle(image, spore, 1, Color8(231, 174, 239))
	if action == "attack" and frame in [2, 3, 4]:
		for angle in [-0.35, 0.0, 0.35]:
			var point := orb + Vector2i(roundi(direction.rotated(angle).x * 14.0), roundi(direction.rotated(angle).y * 14.0))
			circle(image, point, 2, accent)

func _boots(image: Image, center: Vector2i, stride: int, color: Color) -> void:
	for side in [-1, 1]:
		var x := center.x + side * 4 + side * stride
		fill_rect(image, Rect2i(x - 3, center.y - 12, 6, 10), Color8(22, 22, 21))
		fill_rect(image, Rect2i(x - 2, center.y - 11, 4, 8), color)
		fill_rect(image, Rect2i(x - 3, center.y - 3, 6, 3), color.darkened(0.35))

func _enemy_frame(id: String, direction_index: int, action: String, frame: int) -> Image:
	var data: Dictionary = ENEMY_VISUALS.get(id, ENEMY_VISUALS["feral_scavenger"])
	var image := blank(48, 48)
	var direction := Vector2(DIRECTIONS[direction_index]).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var phase := float(frame) * PI / 4.0
	var bob := roundi(sin(phase) * (2.0 if String(data["shape"]) in ["drone", "ophanim", "angel"] else 1.0))
	var center := Vector2i(24, 41 + bob)
	var primary := Color(data["primary"])
	var accent := Color(data["accent"])
	var skin := Color(data["skin"])
	var shape := String(data["shape"])
	if shape in ["drone", "ophanim"]:
		_draw_machine_enemy(image, center + Vector2i(0, -14), direction, shape, primary, accent, action, frame)
	elif shape == "angel":
		_draw_angel_enemy(image, center + Vector2i(0, -8), direction, primary, accent, skin, action, frame)
	elif shape == "serpent":
		_draw_serpent_rebuild(image, direction, primary, accent, action, frame)
	else:
		_draw_ground_enemy(image, center, direction, perpendicular, shape, primary, accent, skin, action, frame)
	if action == "hurt" and frame in [1, 2]:
		tint(image, Color8(255, 78, 61), 0.50)
	if action == "death" and frame >= 2:
		return collapse(image, frame)
	return image

func _draw_ground_enemy(image: Image, center: Vector2i, direction: Vector2, perpendicular: Vector2, shape: String, primary: Color, accent: Color, skin: Color, action: String, frame: int) -> void:
	var large := shape in ["brute", "giant", "berserker", "colossus", "sentinel"]
	var huge := shape in ["giant", "colossus"]
	var width := 20 if large else 15
	var height := 20 if large else 16
	if huge:
		width = 26
		height = 24
	shadow(image, center + Vector2i(0, 2), 13 if huge else (11 if large else 9))
	var stride := roundi(sin(float(frame) * PI / 4.0) * 2.0) if action == "walk" else 0
	for side in [-1, 1]:
		var leg_x := center.x + side * (5 if large else 4) + side * stride
		fill_rect(image, Rect2i(leg_x - 3, center.y - 11, 6, 10), Color8(25, 23, 22))
		fill_rect(image, Rect2i(leg_x - 2, center.y - 10, 4, 8), primary.darkened(0.18))
	fill_rect(image, Rect2i(center.x - int(width / 2) - 1, center.y - 12 - height, width + 2, height + 2), Color8(24, 22, 22))
	fill_rect(image, Rect2i(center.x - int(width / 2), center.y - 11 - height, width, height), primary)
	if shape in ["cultist", "acolyte", "shepherd"]:
		for row in range(10):
			var half := int(width / 2) + int(float(row) * 0.25)
			fill_rect(image, Rect2i(center.x - half, center.y - 12 - row, half * 2 + 1, 1), primary.darkened(0.10))
	if shape in ["sentinel", "pilgrim"]:
		fill_rect(image, Rect2i(center.x - int(width / 2) + 2, center.y - 25, width - 4, 3), accent)
	if shape in ["husk", "giant", "berserker", "colossus"]:
		for scar in range(3):
			line(image, center + Vector2i(-int(width / 2) + 3 + scar * 5, -25), center + Vector2i(-int(width / 2) + 7 + scar * 5, -17), accent.darkened(0.10), 2)
	var head := center + Vector2i(0, -17 - height)
	var head_radius := 8 if large else 6
	circle(image, head, head_radius + 1, Color8(23, 21, 21))
	circle(image, head, head_radius, skin)
	match shape:
		"scavenger":
			fill_rect(image, Rect2i(head.x - 7, head.y - 7, 14, 5), primary.darkened(0.35))
			line(image, center + Vector2i(-9, -18), center + Vector2i(10, -29), accent, 2)
		"gunner", "hunter", "skirmisher":
			fill_rect(image, Rect2i(head.x - 7, head.y - 6, 14, 5), primary.darkened(0.35))
			var muzzle := center + Vector2i(roundi(direction.x * 20.0), -23 + roundi(direction.y * 16.0))
			line(image, center + Vector2i(0, -23), muzzle, Color8(27, 25, 23), 5)
			line(image, center + Vector2i(0, -23), muzzle, accent, 2)
			if action == "attack" and frame in [2, 3, 4]:
				cross(image, muzzle, Color8(255, 195, 86), 4)
		"brute":
			for side in [-1, 1]:
				circle(image, center + Vector2i(side * 12, -26), 5, accent)
			if action == "attack" and frame in [2, 3, 4]:
				circle(image, center + Vector2i(roundi(direction.x * 14.0), -22 + roundi(direction.y * 14.0)), 7, Color(accent, 0.85), false)
		"cultist", "acolyte":
			fill_rect(image, Rect2i(head.x - 7, head.y - 7, 14, 10), primary.darkened(0.34))
			circle(image, head + Vector2i(roundi(direction.x * 2.0), roundi(direction.y * 2.0)), 2, accent)
			if action == "attack" and frame in [2, 3, 4]:
				for radius in [4, 8]:
					circle(image, head + Vector2i(roundi(direction.x * 11.0), roundi(direction.y * 11.0)), radius, Color(accent, 0.85), false)
		"sentinel":
			circle(image, head, 10, accent, false)
			fill_rect(image, Rect2i(head.x - 6, head.y - 1, 12, 3), accent)
		"pilgrim":
			fill_rect(image, Rect2i(head.x - 7, head.y - 6, 14, 11), Color8(36, 50, 48))
			fill_rect(image, Rect2i(head.x - 5, head.y - 1, 10, 2), accent)
			for side in [-1, 1]:
				line(image, center + Vector2i(side * 8, -28), center + Vector2i(side * 13, -15), accent, 2)
		"husk":
			fill_rect(image, Rect2i(head.x - 8, head.y - 4, 16, 5), primary.darkened(0.42))
			circle(image, head + Vector2i(-3, 1), 1, accent)
			circle(image, head + Vector2i(3, 1), 1, accent)
		"giant":
			for side in [-1, 1]:
				line(image, head + Vector2i(side * 4, -5), head + Vector2i(side * 11, -13), accent, 3)
			fill_rect(image, Rect2i(center.x - 12, center.y - 30, 24, 5), accent.darkened(0.15))
		"berserker":
			for side in [-1, 1]:
				line(image, head + Vector2i(side * 4, -4), head + Vector2i(side * 10, -12), accent, 3)
				var blade_start := center + Vector2i(roundi(perpendicular.x * float(side) * 11.0), -23 + roundi(perpendicular.y * float(side) * 11.0))
				line(image, blade_start, blade_start + Vector2i(roundi(direction.x * 15.0), roundi(direction.y * 15.0)), Color8(226, 215, 185), 3)
		"shepherd":
			circle(image, head, 9, Color8(221, 204, 168), false)
			var staff := center + Vector2i(10, -22)
			line(image, staff, staff + Vector2i(0, -22), accent, 2)
			circle(image, staff + Vector2i(0, -22), 5, accent, false)
		"colossus":
			for side in [-1, 1]:
				var graft := center + Vector2i(side * 14, -26)
				circle(image, graft, 7, Color8(27, 23, 24))
				circle(image, graft, 5, accent)
			circle(image, center + Vector2i(0, -25), 5, accent, false)
	if action == "attack" and frame in [2, 3, 4] and shape not in ["gunner", "hunter", "skirmisher", "cultist", "acolyte"]:
		cross(image, center + Vector2i(roundi(direction.x * 17.0), -22 + roundi(direction.y * 17.0)), accent, 4)

func _draw_machine_enemy(image: Image, center: Vector2i, direction: Vector2, shape: String, primary: Color, accent: Color, action: String, frame: int) -> void:
	shadow(image, center + Vector2i(0, 14), 10)
	if shape == "drone":
		for side in [-1, 1]:
			var wing_root := center + Vector2i(side * 6, 0)
			var wing_tip := center + Vector2i(side * (17 + frame % 2), -5 + (frame % 3))
			line(image, wing_root, wing_tip, Color8(29, 33, 33), 6)
			line(image, wing_root, wing_tip, accent, 2)
		circle(image, center, 9, Color8(27, 31, 31))
		circle(image, center, 7, primary)
		circle(image, center, 3, accent)
	else:
		for radius in [15, 11, 7]:
			circle(image, center, radius, accent if radius != 11 else primary, false)
		for spoke in range(8):
			var angle := TAU * float(spoke) / 8.0 + float(frame) * 0.08
			line(image, center + Vector2i(roundi(cos(angle) * 5.0), roundi(sin(angle) * 5.0)), center + Vector2i(roundi(cos(angle) * 14.0), roundi(sin(angle) * 14.0)), accent, 2)
		circle(image, center, 3, Color8(239, 226, 150))
	if action == "attack" and frame in [2, 3, 4]:
		var target := center + Vector2i(roundi(direction.x * 20.0), roundi(direction.y * 20.0))
		for radius in [3, 6, 9]:
			circle(image, target, radius, Color(accent, 0.80), false)

func _draw_angel_enemy(image: Image, center: Vector2i, direction: Vector2, primary: Color, accent: Color, skin: Color, action: String, frame: int) -> void:
	shadow(image, center + Vector2i(0, 18), 11)
	for side in [-1, 1]:
		var root := center + Vector2i(side * 5, 2)
		for feather in range(4):
			var tip := center + Vector2i(side * (14 + feather * 3), -10 + feather * 6 + (frame % 2))
			line(image, root, tip, Color8(27, 29, 28), 6)
			line(image, root, tip, accent, 2)
	fill_rect(image, Rect2i(center.x - 7, center.y - 2, 14, 18), primary)
	var head := center + Vector2i(0, -10)
	circle(image, head, 7, skin)
	circle(image, head + Vector2i(0, -3), 10, accent, false)
	if action == "attack" and frame in [2, 3, 4]:
		cross(image, center + Vector2i(roundi(direction.x * 18.0), roundi(direction.y * 18.0)), accent, 5)

func _draw_serpent_rebuild(image: Image, direction: Vector2, primary: Color, accent: Color, action: String, frame: int) -> void:
	var perpendicular := Vector2(-direction.y, direction.x)
	var head := Vector2(24, 26)
	var previous := Vector2i(roundi(head.x), roundi(head.y))
	for segment in range(9):
		var point := head - direction * float(segment * 3) + perpendicular * sin(float(segment) * 0.85 + float(frame) * 0.55) * 5.0
		var current := Vector2i(roundi(point.x), roundi(point.y))
		if segment > 0:
			line(image, previous, current, Color8(24, 21, 23), 8)
			line(image, previous, current, primary, 4)
		previous = current
	circle(image, Vector2i(roundi(head.x), roundi(head.y)), 7, Color8(24, 21, 23))
	circle(image, Vector2i(roundi(head.x), roundi(head.y)), 5, accent)
	for side in [-1, 1]:
		line(image, Vector2i(roundi(head.x), roundi(head.y)) + Vector2i(side * 3, -3), Vector2i(roundi(head.x), roundi(head.y)) + Vector2i(side * 7, -8), accent, 2)
	if action == "attack" and frame in [2, 3, 4]:
		cross(image, Vector2i(roundi(head.x + direction.x * 11.0), roundi(head.y + direction.y * 11.0)), Color8(255, 112, 108), 4)

func _boss_frame(id: String, direction_index: int, action: int, frame: int) -> Image:
	var image := blank(96, 96)
	var index := maxi(0, BOSS_IDS.find(id))
	var color := BOSS_COLORS[index]
	var direction := Vector2(DIRECTIONS[direction_index]).normalized()
	var center := Vector2i(48, 52 + roundi(sin(float(frame) * PI / 4.0) * 2.0))
	shadow(image, center + Vector2i(0, 25), 24)
	match id:
		"watcher_engine":
			for radius in [28, 22, 14]:
				circle(image, center, radius, color if radius != 22 else Color8(53, 61, 61), false)
			for spoke in range(12):
				var angle := TAU * float(spoke) / 12.0 + float(frame) * 0.08
				var inner := center + Vector2i(roundi(cos(angle) * 15.0), roundi(sin(angle) * 15.0))
				var outer := center + Vector2i(roundi(cos(angle) * 31.0), roundi(sin(angle) * 31.0))
				line(image, inner, outer, color, 3)
			circle(image, center, 8, Color8(242, 225, 161))
			circle(image, center, 3, Color8(80, 24, 31))
		"first_nephilim":
			fill_rect(image, Rect2i(center.x - 23, center.y - 32, 46, 51), Color8(42, 28, 29))
			fill_rect(image, Rect2i(center.x - 20, center.y - 30, 40, 47), color.darkened(0.45))
			for side in [-1, 1]:
				line(image, center + Vector2i(side * 10, -27), center + Vector2i(side * 28, -48), color, 7)
				circle(image, center + Vector2i(side * 25, 1), 12, color.darkened(0.20))
			var head := center + Vector2i(0, -42)
			circle(image, head, 15, Color8(92, 49, 45))
			for side in [-1, 1]:
				line(image, head + Vector2i(side * 7, -8), head + Vector2i(side * 18, -25), color, 5)
		"gate_cherub":
			for side in [-1, 1]:
				var root := center + Vector2i(side * 10, 0)
				for feather in range(6):
					line(image, root, center + Vector2i(side * (24 + feather * 5), -28 + feather * 9), Color8(226, 215, 172), 7)
			circle(image, center, 22, Color8(50, 55, 53))
			circle(image, center, 17, color, false)
			circle(image, center, 8, Color8(245, 235, 197))
		"tower_enoch":
			fill_rect(image, Rect2i(center.x - 19, center.y - 36, 38, 58), Color8(37, 30, 45))
			for tier in range(4):
				fill_rect(image, Rect2i(center.x - 23 + tier * 3, center.y - 34 + tier * 14, 46 - tier * 6, 8), color.darkened(float(tier) * 0.08))
			for side in [-1, 1]:
				line(image, center + Vector2i(side * 17, 10), center + Vector2i(side * 31, -26), color, 5)
			circle(image, center + Vector2i(0, -18), 8, Color8(237, 204, 244))
		_:
			var previous := center
			for segment in range(18):
				var angle := float(segment) * 0.50 + float(frame) * 0.10
				var radius := 7.0 + float(segment) * 2.0
				var point := center + Vector2i(roundi(cos(angle) * radius), roundi(sin(angle) * radius * 0.62))
				if segment > 0:
					line(image, previous, point, Color8(29, 23, 31), 12)
					line(image, previous, point, color, 6)
				previous = point
			circle(image, center, 11, Color8(238, 223, 169))
	if action == 1 and frame in [2, 3, 4, 5]:
		var strike := center + Vector2i(roundi(direction.x * 38.0), roundi(direction.y * 38.0))
		for radius in [5, 10, 15]:
			circle(image, strike, radius, Color(color, 0.88), false)
	elif action == 2:
		for radius in [34, 40]:
			circle(image, center, radius + frame % 3, Color(color, 0.75), false)
	elif action == 3 and frame >= 2:
		return collapse(image, frame)
	return image

func _dir_index(direction: Vector2) -> int:
	var best := 0
	var best_dot := -2.0
	for i in range(DIRECTIONS.size()):
		var dot := direction.dot(Vector2(DIRECTIONS[i]).normalized())
		if dot > best_dot:
			best_dot = dot
			best = i
	return best
