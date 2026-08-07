extends RefCounted

const VERSION := "0.6.2-entropy"
const FRAME := 48
const BOSS_FRAME := 96
const FRAMES := 4
const DIRECTIONS := [
	Vector2.UP,
	Vector2(1,-1).normalized(),
	Vector2.RIGHT,
	Vector2(1,1).normalized(),
	Vector2.DOWN,
	Vector2(-1,1).normalized(),
	Vector2.LEFT,
	Vector2(-1,-1).normalized(),
]

const PALETTES := [
	[Color8(71,47,37),Color8(126,78,49),Color8(220,106,54),Color8(236,199,145),Color8(25,21,20)],
	[Color8(54,60,55),Color8(104,112,78),Color8(204,171,78),Color8(224,206,167),Color8(20,23,22)],
	[Color8(68,42,37),Color8(142,61,45),Color8(229,113,63),Color8(190,153,120),Color8(24,19,19)],
	[Color8(43,53,54),Color8(74,95,91),Color8(179,127,68),Color8(211,181,142),Color8(19,23,24)],
	[Color8(58,61,62),Color8(126,134,126),Color8(226,211,155),Color8(221,203,166),Color8(20,22,23)],
	[Color8(42,55,63),Color8(70,112,124),Color8(112,226,219),Color8(217,215,183),Color8(16,22,26)],
	[Color8(65,60,48),Color8(126,112,74),Color8(238,214,142),Color8(221,205,172),Color8(23,22,18)],
	[Color8(47,43,66),Color8(94,78,128),Color8(176,145,235),Color8(226,218,194),Color8(20,18,28)],
	[Color8(64,36,40),Color8(117,56,60),Color8(224,86,75),Color8(163,112,99),Color8(24,17,20)],
	[Color8(53,43,59),Color8(104,75,115),Color8(201,116,207),Color8(190,157,145),Color8(22,18,27)],
	[Color8(70,53,44),Color8(132,98,67),Color8(217,165,100),Color8(169,132,113),Color8(25,21,18)],
	[Color8(43,48,58),Color8(75,89,115),Color8(146,179,231),Color8(180,165,154),Color8(17,20,26)],
	[Color8(36,52,45),Color8(74,111,88),Color8(126,221,151),Color8(215,204,171),Color8(15,22,19)],
	[Color8(49,43,68),Color8(99,81,132),Color8(201,141,231),Color8(222,208,182),Color8(19,17,27)],
	[Color8(64,55,42),Color8(119,100,67),Color8(236,200,113),Color8(223,205,165),Color8(22,20,16)],
	[Color8(48,22,27),Color8(116,39,45),Color8(239,71,62),Color8(190,128,111),Color8(18,14,17)],
]

func build_enemy_sheet(genome: Dictionary) -> Image:
	return _build_sheet(genome, false)

func build_player_sheet(genome: Dictionary) -> Image:
	return _build_sheet(genome, false)

func build_boss_sheet(genome: Dictionary) -> Image:
	return _build_sheet(genome, true)

func _build_sheet(genome: Dictionary, boss: bool) -> Image:
	var frame_size := BOSS_FRAME if boss else FRAME
	var image := Image.create_empty(frame_size * FRAMES, frame_size * 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0))
	for direction_index in range(8):
		for frame_index in range(FRAMES):
			_draw_actor_frame(image, Vector2i(frame_index * frame_size, direction_index * frame_size), frame_size, genome, DIRECTIONS[direction_index], frame_index, boss)
	return image

func _draw_actor_frame(image: Image, origin: Vector2i, size: int, genome: Dictionary, direction: Vector2, frame_index: int, boss: bool) -> void:
	var palette: Array = PALETTES[clampi(int(genome.get("palette_index", 0)), 0, PALETTES.size() - 1)]
	var primary := Color(palette[0])
	var secondary := Color(palette[1])
	var accent := Color(palette[2])
	var skin := Color(palette[3])
	var outline := Color(palette[4])
	var role := String(genome.get("role", "melee"))
	var scale := 2 if boss else 1
	var stride := roundi(sin(float(frame_index) * PI * 0.5) * float(2 * scale))
	var bob := roundi(absf(sin(float(frame_index) * PI * 0.5)) * float(scale))
	var center := origin + Vector2i(size / 2, int(float(size) * 0.69) + bob)
	if role == "orbiter":
		_draw_orbiter(image, center, direction, frame_index, genome, primary, secondary, accent, outline, scale)
	elif role == "radial":
		_draw_radial(image, center, direction, frame_index, genome, primary, secondary, accent, outline, scale)
	else:
		_draw_humanoid(image, center, direction, stride, frame_index, genome, primary, secondary, accent, skin, outline, scale)
	_apply_frame_wear(image, Rect2i(origin, Vector2i(size,size)), genome, accent)

func _draw_humanoid(image: Image, center: Vector2i, direction: Vector2, stride: int, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, skin: Color, outline: Color, scale: int) -> void:
	var perp := Vector2(-direction.y, direction.x)
	var body_w := clampi(int(genome.get("body_width", 16)) * scale, 12 * scale, 30 * scale)
	var body_h := clampi(int(genome.get("body_height", 18)) * scale, 13 * scale, 34 * scale)
	var half_w := int(body_w / 2)
	var role := String(genome.get("role", "melee"))
	var shadow_y := center.y + 2 * scale
	_fill_ellipse(image, Vector2i(center.x, shadow_y), maxi(7 * scale, half_w), 4 * scale, Color(0,0,0,0.34))

	var leg_y := center.y - 9 * scale
	for side in [-1,1]:
		var leg_x := center.x + side * (4 * scale) + side * stride
		_fill_rect(image, Rect2i(leg_x - 3 * scale, leg_y, 6 * scale, 10 * scale), outline)
		_fill_rect(image, Rect2i(leg_x - 2 * scale, leg_y, 4 * scale, 8 * scale), secondary.darkened(0.18))
		_fill_rect(image, Rect2i(leg_x - 3 * scale, leg_y + 7 * scale, 6 * scale, 3 * scale), outline.lightened(0.04))

	var torso := Rect2i(center.x - half_w, center.y - (body_h + 10 * scale), body_w, body_h)
	_fill_rect(image, torso.grow(2 * scale), outline)
	_fill_rect(image, torso, primary)
	_fill_rect(image, Rect2i(torso.position + Vector2i(2 * scale,2 * scale), Vector2i(maxi(scale, torso.size.x - 4 * scale), 3 * scale)), primary.lightened(0.16))
	_fill_rect(image, Rect2i(torso.position + Vector2i(2 * scale,torso.size.y - 4 * scale), Vector2i(maxi(scale, torso.size.x - 4 * scale), 3 * scale)), primary.darkened(0.28))
	_draw_armor_plate(image, torso, genome, secondary, accent, outline, scale)

	var shoulder_style := int(genome.get("shoulder_style", 0))
	for side in [-1,1]:
		var shoulder := Vector2i(center.x + side * (half_w + 2 * scale), torso.position.y + 5 * scale)
		match shoulder_style:
			0:
				_circle(image, shoulder, 4 * scale, outline)
				_circle(image, shoulder, 3 * scale, secondary)
			1:
				_fill_rect(image, Rect2i(shoulder.x - 4 * scale, shoulder.y - 2 * scale, 8 * scale, 5 * scale), outline)
				_fill_rect(image, Rect2i(shoulder.x - 3 * scale, shoulder.y - scale, 6 * scale, 3 * scale), accent.darkened(0.12))
			2:
				_line(image, shoulder - Vector2i(0,2*scale), shoulder + Vector2i(side * 6 * scale, -5 * scale), outline, 4 * scale)
				_line(image, shoulder, shoulder + Vector2i(side * 6 * scale, -5 * scale), secondary, 2 * scale)
			3:
				_circle(image, shoulder, 5 * scale, outline)
				_circle(image, shoulder, 3 * scale, accent.darkened(0.12))
			_:
				_fill_rect(image, Rect2i(shoulder.x - 3 * scale, shoulder.y - 3 * scale, 6 * scale, 6 * scale), outline)
				_circle(image, shoulder, 2 * scale, accent)

	var head_center := Vector2i(center.x, torso.position.y - 6 * scale)
	_draw_head(image, head_center, direction, genome, primary, secondary, accent, skin, outline, scale)
	_draw_backpack(image, center, direction, perp, genome, secondary, accent, outline, scale)
	_draw_weapon(image, center + Vector2i(0,-20*scale), direction, perp, frame_index, genome, role, primary, secondary, accent, outline, scale)

func _draw_head(image: Image, head: Vector2i, direction: Vector2, genome: Dictionary, primary: Color, secondary: Color, accent: Color, skin: Color, outline: Color, scale: int) -> void:
	var style := int(genome.get("head_style", 0))
	_circle(image, head, 7 * scale, outline)
	_circle(image, head, 5 * scale, skin)
	match style:
		0:
			_fill_rect(image, Rect2i(head.x - 6 * scale, head.y - 6 * scale, 12 * scale, 6 * scale), primary.darkened(0.12))
			_fill_rect(image, Rect2i(head.x - 5 * scale, head.y - scale, 10 * scale, 2 * scale), accent)
		1:
			_fill_rect(image, Rect2i(head.x - 6 * scale, head.y - 5 * scale, 12 * scale, 10 * scale), outline)
			_fill_rect(image, Rect2i(head.x - 4 * scale, head.y - 3 * scale, 8 * scale, 5 * scale), secondary)
			_fill_rect(image, Rect2i(head.x - 4 * scale, head.y - scale, 8 * scale, 2 * scale), accent)
		2:
			for side in [-1,1]:
				_line(image, head + Vector2i(side * 4 * scale,-4*scale), head + Vector2i(side * 9 * scale,-10*scale), outline, 3 * scale)
				_line(image, head + Vector2i(side * 4 * scale,-4*scale), head + Vector2i(side * 9 * scale,-10*scale), accent.darkened(0.18), scale)
			_fill_rect(image, Rect2i(head.x - 5 * scale, head.y - 5 * scale, 10 * scale, 5 * scale), primary)
		3:
			_fill_rect(image, Rect2i(head.x - 6 * scale, head.y - 6 * scale, 12 * scale, 12 * scale), primary.darkened(0.30))
			for eye in range(clampi(int(genome.get("eyes",1)),1,4)):
				var ex := head.x + (eye - 1) * 3 * scale
				_circle(image, Vector2i(ex, head.y), scale, accent)
		4:
			_circle(image, head, 8 * scale, accent.darkened(0.18), false)
			_fill_rect(image, Rect2i(head.x - 5 * scale, head.y - 2 * scale, 10 * scale, 4 * scale), outline)
			_circle(image, head + Vector2i(roundi(direction.x * 2.0 * scale), roundi(direction.y * 2.0 * scale)), 2 * scale, accent)
		_:
			_fill_rect(image, Rect2i(head.x - 7 * scale, head.y - 6 * scale, 14 * scale, 5 * scale), secondary.darkened(0.25))
			_line(image, head + Vector2i(-5*scale,2*scale), head + Vector2i(5*scale,2*scale), accent, 2 * scale)

	var horns := clampi(int(genome.get("horns",0)),0,3)
	for horn in range(horns):
		var side := -1 if horn % 2 == 0 else 1
		var xoff := (4 + horn) * side * scale
		_line(image, head + Vector2i(xoff,-4*scale), head + Vector2i((8 + horn*2)*side*scale,-11*scale), outline, 2 * scale)
		_set_pixel_safe(image, head.x + (8 + horn*2)*side*scale, head.y - 11*scale, accent)

func _draw_armor_plate(image: Image, torso: Rect2i, genome: Dictionary, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var inset := 3 * scale
	var plate := Rect2i(torso.position + Vector2i(inset, 4*scale), Vector2i(maxi(scale,torso.size.x - inset*2), maxi(scale,torso.size.y - 8*scale)))
	_fill_rect(image, plate, secondary.darkened(0.12))
	_fill_rect(image, Rect2i(plate.position + Vector2i(scale,scale), Vector2i(maxi(scale, plate.size.x - 2*scale), 2*scale)), secondary.lightened(0.16))
	var accents := clampi(int(genome.get("accent_count",2)),1,4)
	for index in range(accents):
		var y := plate.position.y + 4 * scale + index * 4 * scale
		if y < plate.end.y - scale:
			_fill_rect(image, Rect2i(plate.position.x + 2*scale, y, maxi(scale,plate.size.x - 4*scale), scale), Color(accent,0.74))
	if absf(float(genome.get("asymmetry",0.0))) > 0.35:
		var side := -1 if float(genome.get("asymmetry",0.0)) < 0.0 else 1
		_circle(image, Vector2i(plate.get_center().x + side * 4*scale, plate.get_center().y), 2*scale, accent)

func _draw_backpack(image: Image, center: Vector2i, direction: Vector2, perp: Vector2, genome: Dictionary, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var style := int(genome.get("backpack_style",0))
	if style == 0:
		return
	var back := center + Vector2i(roundi(-direction.x * 8.0 * scale), roundi(-direction.y * 8.0 * scale) - 22*scale)
	if style == 1:
		_fill_rect(image, Rect2i(back.x - 4*scale, back.y - 5*scale, 8*scale, 10*scale), outline)
		_fill_rect(image, Rect2i(back.x - 3*scale, back.y - 4*scale, 6*scale, 8*scale), secondary)
	elif style == 2:
		for side in [-1,1]:
			var p := back + Vector2i(roundi(perp.x * side * 5.0 * scale), roundi(perp.y * side * 5.0 * scale))
			_circle(image, p, 3*scale, outline)
			_circle(image, p, 2*scale, accent.darkened(0.10))
	else:
		_fill_rect(image, Rect2i(back.x - 5*scale, back.y - 4*scale, 10*scale, 8*scale), outline)
		_circle(image, back, 2*scale, accent)

func _draw_weapon(image: Image, origin: Vector2i, direction: Vector2, perp: Vector2, frame_index: int, genome: Dictionary, role: String, primary: Color, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var style := int(genome.get("weapon_style",0))
	var reach := 15 * scale
	if role == "charger": reach = 12 * scale
	elif role == "caster": reach = 17 * scale
	elif role == "skirmisher": reach = 13 * scale
	if style == 5:
		reach += 6 * scale
	var grip := origin + Vector2i(roundi(perp.x * 3.0 * scale), roundi(perp.y * 3.0 * scale))
	var muzzle := grip + Vector2i(roundi(direction.x * reach), roundi(direction.y * reach))
	match role:
		"caster":
			_line(image, grip, muzzle, outline, 4*scale)
			_line(image, grip, muzzle, secondary, 2*scale)
			_circle(image, muzzle, 4*scale, outline)
			_circle(image, muzzle, 2*scale + (frame_index%2)*scale, accent)
		"melee":
			_line(image, grip, muzzle, outline, 5*scale)
			_line(image, grip, muzzle, Color8(216,211,183), 2*scale)
			_line(image, muzzle, muzzle + Vector2i(roundi(perp.x*5.0*scale),roundi(perp.y*5.0*scale)), accent, 2*scale)
		"charger":
			for side in [-1,1]:
				var start := grip + Vector2i(roundi(perp.x*side*4.0*scale),roundi(perp.y*side*4.0*scale))
				var end := start + Vector2i(roundi(direction.x*reach),roundi(direction.y*reach))
				_line(image,start,end,outline,5*scale)
				_line(image,start,end,secondary,2*scale)
		"skirmisher":
			for side in [-1,1]:
				var start := grip + Vector2i(roundi(perp.x*side*4.0*scale),roundi(perp.y*side*4.0*scale))
				var end := start + Vector2i(roundi(direction.x*(reach-2*scale)),roundi(direction.y*(reach-2*scale)))
				_line(image,start,end,outline,4*scale)
				_line(image,start,end,accent,2*scale)
		_:
			var thickness := 7*scale if style == 5 else 5*scale
			_line(image,grip,muzzle,outline,thickness)
			_line(image,grip,muzzle,secondary,maxi(scale,thickness-3*scale))
			var barrel_side := muzzle + Vector2i(roundi(perp.x*3.0*scale),roundi(perp.y*3.0*scale))
			_line(image,muzzle,barrel_side,accent,2*scale)
			_circle(image,muzzle,2*scale,accent)

func _draw_orbiter(image: Image, center: Vector2i, direction: Vector2, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	_fill_ellipse(image, center + Vector2i(0,7*scale), 11*scale, 4*scale, Color(0,0,0,0.30))
	var spin := float(frame_index) * 0.65 + float(genome.get("phase_offset",0.0))
	_circle(image, center, 12*scale, outline)
	_circle(image, center, 9*scale, primary)
	_circle(image, center, 5*scale, secondary)
	_circle(image, center + Vector2i(roundi(direction.x*3.0*scale),roundi(direction.y*3.0*scale)), 2*scale, accent)
	for arm in range(4 + int(genome.get("accent_count",2))):
		var angle := spin + TAU * float(arm) / float(4 + int(genome.get("accent_count",2)))
		var inner := center + Vector2i(roundi(cos(angle)*10.0*scale),roundi(sin(angle)*10.0*scale))
		var outer := center + Vector2i(roundi(cos(angle)*17.0*scale),roundi(sin(angle)*17.0*scale))
		_line(image,inner,outer,outline,3*scale)
		_set_pixel_safe(image,outer.x,outer.y,accent)

func _draw_radial(image: Image, center: Vector2i, direction: Vector2, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	_fill_ellipse(image, center + Vector2i(0,8*scale), 14*scale, 5*scale, Color(0,0,0,0.32))
	_circle(image,center,15*scale,outline)
	_circle(image,center,12*scale,primary)
	_circle(image,center,8*scale,secondary)
	var arms := 6 + int(genome.get("horns",0))
	for arm in range(arms):
		var angle := TAU * float(arm) / float(arms) + float(frame_index)*0.14
		var start := center + Vector2i(roundi(cos(angle)*10.0*scale),roundi(sin(angle)*10.0*scale))
		var end := center + Vector2i(roundi(cos(angle)*20.0*scale),roundi(sin(angle)*20.0*scale))
		_line(image,start,end,outline,4*scale)
		_line(image,start,end,accent.darkened(0.10),2*scale)
	_circle(image,center + Vector2i(roundi(direction.x*4.0*scale),roundi(direction.y*4.0*scale)),3*scale,accent)

func _apply_frame_wear(image: Image, rect: Rect2i, genome: Dictionary, accent: Color) -> void:
	var pattern := int(genome.get("scar_pattern",0))
	var count := clampi(int(genome.get("accent_count",2)),1,4)
	for index in range(count):
		var x := rect.position.x + 8 + posmod(pattern*17 + index*11, maxi(1,rect.size.x-16))
		var y := rect.position.y + 10 + posmod(pattern*13 + index*7, maxi(1,rect.size.y-20))
		var c := image.get_pixel(x,y)
		if c.a > 0.75:
			_set_pixel_safe(image,x,y,c.lightened(0.18))
			if index % 2 == 0:
				_set_pixel_safe(image,x+1,y,Color(accent,0.72))

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	if clipped.size.x > 0 and clipped.size.y > 0:
		image.fill_rect(clipped,color)

func _circle(image: Image, center: Vector2i, radius: int, color: Color, filled: bool = true) -> void:
	var r2 := radius*radius
	var inner := maxi(0,radius-2)
	var inner2 := inner*inner
	for y in range(center.y-radius,center.y+radius+1):
		for x in range(center.x-radius,center.x+radius+1):
			var dx := x-center.x
			var dy := y-center.y
			var d2 := dx*dx+dy*dy
			if d2 <= r2 and (filled or d2 >= inner2):
				_set_pixel_safe(image,x,y,color)

func _fill_ellipse(image: Image, center: Vector2i, rx: int, ry: int, color: Color) -> void:
	if rx <= 0 or ry <= 0:
		return
	for y in range(center.y-ry,center.y+ry+1):
		for x in range(center.x-rx,center.x+rx+1):
			var nx := float(x-center.x)/float(rx)
			var ny := float(y-center.y)/float(ry)
			if nx*nx+ny*ny <= 1.0:
				_set_pixel_safe(image,x,y,color)

func _line(image: Image, start: Vector2i, finish: Vector2i, color: Color, width: int = 1) -> void:
	var x0 := start.x
	var y0 := start.y
	var x1 := finish.x
	var y1 := finish.y
	var dx := absi(x1-x0)
	var sx := 1 if x0 < x1 else -1
	var dy := -absi(y1-y0)
	var sy := 1 if y0 < y1 else -1
	var err := dx+dy
	while true:
		var half := maxi(0,int(width/2))
		for py in range(y0-half,y0+half+1):
			for px in range(x0-half,x0+half+1):
				_set_pixel_safe(image,px,py,color)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2*err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

func _set_pixel_safe(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		image.set_pixel(x,y,color)

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"directions": 8,
		"animation_frames": FRAMES,
		"instance_unique": true,
		"role_specific_silhouettes": true,
		"hard_pixel_outline": true,
		"procedural_weapons": true,
		"procedural_armor": true,
		"external_sprite_data": false,
	}
