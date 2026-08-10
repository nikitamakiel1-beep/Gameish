extends "res://scripts/v8/procedural_sprite_forge_stable.gd"

const AUTHORED_FORGE_VERSION: String = "0.6.2-entropy-art2"

func _draw_actor_frame(image: Image, origin: Vector2i, size: int, genome: Dictionary, direction: Vector2, frame_index: int, boss: bool) -> void:
	if boss:
		_draw_guardian_frame(image, origin, size, genome, direction.normalized(), frame_index)
		return
	super._draw_actor_frame(image, origin, size, genome, direction, frame_index, false)

func _draw_humanoid(image: Image, center: Vector2i, direction: Vector2, stride: int, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, skin: Color, outline: Color, scale: int) -> void:
	var role: String = String(genome.get("role", "melee"))
	var silhouette: String = String(genome.get("silhouette_key", role))
	var perp: Vector2 = Vector2(-direction.y, direction.x)
	var foot_y: int = center.y + 9 * scale
	var body_w: int = clampi(int(genome.get("body_width", 17)) * scale, 13 * scale, 30 * scale)
	var body_h: int = clampi(int(genome.get("body_height", 19)) * scale, 15 * scale, 28 * scale)
	match role:
		"charger": body_w = maxi(body_w, 22 * scale)
		"caster": body_w = mini(body_w, 18 * scale)
		"skirmisher": body_w = mini(body_w, 17 * scale)
		_:
			pass
	var torso_bottom: int = foot_y - 10 * scale
	var torso_top: int = torso_bottom - body_h
	var half_w: int = int(body_w / 2)
	var torso: Rect2i = Rect2i(center.x - half_w, torso_top, body_w, body_h)
	var shadow_center: Vector2i = Vector2i(center.x, foot_y + 1 * scale)
	_fill_ellipse(image, shadow_center, maxi(8 * scale, half_w + 2 * scale), 4 * scale, Color(0.0, 0.0, 0.0, 0.34))

	# Legs are intentionally separated so the actor reads as a body, not a vertical rectangle.
	var step: int = clampi(stride, -2 * scale, 2 * scale)
	var leg_height: int = 10 * scale
	for side_variant in [-1, 1]:
		var side: int = int(side_variant)
		var leg_x: int = center.x + side * (4 * scale) + side * step
		var leg_top: int = torso_bottom - 1 * scale
		_fill_rect(image, Rect2i(leg_x - 3 * scale, leg_top, 6 * scale, leg_height + 2 * scale), outline)
		_fill_rect(image, Rect2i(leg_x - 2 * scale, leg_top, 4 * scale, leg_height), secondary.darkened(0.20))
		_fill_rect(image, Rect2i(leg_x - 3 * scale, foot_y - 3 * scale, 7 * scale, 4 * scale), outline)
		_fill_rect(image, Rect2i(leg_x - 2 * scale, foot_y - 3 * scale, 5 * scale, 2 * scale), secondary.lightened(0.08))

	# Torso mass and role-specific silhouette.
	_fill_rect(image, torso.grow(2 * scale), outline)
	_fill_rect(image, torso, primary)
	_fill_rect(image, Rect2i(torso.position + Vector2i(2 * scale, 2 * scale), Vector2i(maxi(scale, torso.size.x - 4 * scale), 3 * scale)), primary.lightened(0.17))
	_fill_rect(image, Rect2i(torso.position + Vector2i(2 * scale, torso.size.y - 4 * scale), Vector2i(maxi(scale, torso.size.x - 4 * scale), 3 * scale)), primary.darkened(0.28))
	_draw_chest_grammar(image, torso, role, silhouette, genome, secondary, accent, outline, scale)

	var shoulder_y: int = torso_top + 5 * scale
	var shoulder_radius: int = 4 * scale
	if role == "charger": shoulder_radius = 6 * scale
	elif role == "skirmisher": shoulder_radius = 3 * scale
	for side_variant in [-1, 1]:
		var side: int = int(side_variant)
		var shoulder: Vector2i = Vector2i(center.x + side * (half_w + shoulder_radius - scale), shoulder_y)
		_circle(image, shoulder, shoulder_radius + scale, outline)
		_circle(image, shoulder, shoulder_radius - scale, secondary)
		if role == "charger":
			_line(image, shoulder, shoulder + Vector2i(side * 5 * scale, -4 * scale), accent.darkened(0.18), 2 * scale)

	# Head stays inside the frame and has a deliberate facing read.
	var head_center: Vector2i = Vector2i(center.x, torso_top - 6 * scale)
	var head_radius: int = 6 * scale
	if role == "charger": head_radius = 5 * scale
	_circle(image, head_center, head_radius + 2 * scale, outline)
	_circle(image, head_center, head_radius, skin)
	_draw_head_grammar(image, head_center, direction, silhouette, genome, primary, secondary, accent, outline, scale)

	# Category/profile attachments occupy the silhouette instead of random surface noise.
	_draw_profile_attachment(image, torso, head_center, direction, perp, silhouette, genome, secondary, accent, outline, scale)
	_draw_role_weapon(image, Vector2i(center.x, torso_top + 8 * scale), direction, perp, frame_index, role, silhouette, genome, secondary, accent, outline, scale)

func _draw_chest_grammar(image: Image, torso: Rect2i, role: String, silhouette: String, genome: Dictionary, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var inset: int = 3 * scale
	var plate: Rect2i = Rect2i(torso.position + Vector2i(inset, 4 * scale), Vector2i(maxi(scale, torso.size.x - inset * 2), maxi(scale, torso.size.y - 7 * scale)))
	match role:
		"caster":
			_fill_rect(image, plate, secondary.darkened(0.16))
			for row: int in range(4):
				var y: int = torso.end.y - (row + 1) * 3 * scale
				var extra: int = row * 2 * scale
				_fill_rect(image, Rect2i(torso.position.x - extra, y, torso.size.x + extra * 2, 2 * scale), outline)
				_fill_rect(image, Rect2i(torso.position.x - extra + scale, y, torso.size.x + extra * 2 - 2 * scale, scale), secondary.darkened(0.08))
		"charger":
			_fill_rect(image, plate, secondary.darkened(0.24))
			_fill_rect(image, Rect2i(plate.position + Vector2i(2 * scale, 2 * scale), Vector2i(maxi(scale, plate.size.x - 4 * scale), 4 * scale)), accent.darkened(0.18))
			_fill_rect(image, Rect2i(torso.position.x - 3 * scale, torso.get_center().y - 2 * scale, torso.size.x + 6 * scale, 4 * scale), outline)
		"skirmisher":
			_fill_rect(image, plate, secondary.darkened(0.10))
			_line(image, plate.position + Vector2i(1 * scale, plate.size.y - 2 * scale), plate.end - Vector2i(1 * scale, plate.size.y - 2 * scale), accent, scale)
		_:
			_fill_rect(image, plate, secondary.darkened(0.12))
			_fill_rect(image, Rect2i(plate.position + Vector2i(2 * scale, 2 * scale), Vector2i(maxi(scale, plate.size.x - 4 * scale), 2 * scale)), secondary.lightened(0.18))
	if silhouette.find("cain") >= 0 or silhouette.find("gunner") >= 0:
		_fill_rect(image, Rect2i(torso.position.x + 2 * scale, torso.get_center().y - scale, maxi(scale, torso.size.x - 4 * scale), 2 * scale), Color(accent, 0.82))
	if absf(float(genome.get("asymmetry", 0.0))) > 0.50:
		var side: int = -1 if float(genome.get("asymmetry", 0.0)) < 0.0 else 1
		_circle(image, Vector2i(torso.get_center().x + side * 4 * scale, torso.get_center().y), 2 * scale, accent)

func _draw_head_grammar(image: Image, head: Vector2i, direction: Vector2, silhouette: String, genome: Dictionary, primary: Color, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var style: int = int(genome.get("head_style", 0))
	if silhouette.find("cultist") >= 0 or silhouette.find("caster") >= 0:
		_fill_rect(image, Rect2i(head.x - 6 * scale, head.y - 6 * scale, 12 * scale, 11 * scale), primary.darkened(0.30))
		_fill_rect(image, Rect2i(head.x - 5 * scale, head.y - 2 * scale, 10 * scale, 3 * scale), outline)
	elif silhouette.find("hunter") >= 0:
		_fill_rect(image, Rect2i(head.x - 7 * scale, head.y - 6 * scale, 14 * scale, 4 * scale), outline)
		_fill_rect(image, Rect2i(head.x - 8 * scale, head.y - 5 * scale, 16 * scale, 2 * scale), primary.darkened(0.10))
	elif silhouette.find("brute") >= 0 or silhouette.find("giant") >= 0:
		_fill_rect(image, Rect2i(head.x - 6 * scale, head.y - 5 * scale, 12 * scale, 9 * scale), outline)
		_fill_rect(image, Rect2i(head.x - 4 * scale, head.y - 3 * scale, 8 * scale, 5 * scale), secondary.darkened(0.12))
	elif style % 3 == 0:
		_fill_rect(image, Rect2i(head.x - 6 * scale, head.y - 6 * scale, 12 * scale, 5 * scale), primary.darkened(0.18))
	elif style % 3 == 1:
		_fill_rect(image, Rect2i(head.x - 6 * scale, head.y - 5 * scale, 12 * scale, 8 * scale), outline)
		_fill_rect(image, Rect2i(head.x - 4 * scale, head.y - 3 * scale, 8 * scale, 4 * scale), secondary)
	else:
		_circle(image, head, 7 * scale, Color(accent, 0.70), false)
	var eye_offset: Vector2i = Vector2i(roundi(direction.x * 3.0 * scale), roundi(direction.y * 2.0 * scale))
	_circle(image, head + eye_offset, maxi(scale, 1), accent)
	if int(genome.get("eyes", 1)) >= 3:
		_circle(image, head + eye_offset + Vector2i(2 * scale, 0), maxi(scale, 1), accent.darkened(0.12))

func _draw_profile_attachment(image: Image, torso: Rect2i, head: Vector2i, direction: Vector2, perp: Vector2, silhouette: String, genome: Dictionary, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	if silhouette.find("longcoat") >= 0 or silhouette.find("pilgrim") >= 0:
		for side_variant in [-1, 1]:
			var side: int = int(side_variant)
			var start: Vector2i = Vector2i(torso.get_center().x + side * (torso.size.x / 3), torso.end.y - 2 * scale)
			var finish: Vector2i = start + Vector2i(side * 3 * scale, 8 * scale)
			_line(image, start, finish, outline, 3 * scale)
			_line(image, start, finish, secondary.darkened(0.18), scale)
	if silhouette.find("horned") >= 0 or String(genome.get("category", "")) == "nephilim":
		var horn_count: int = maxi(2, int(genome.get("horns", 2)))
		for horn: int in range(mini(3, horn_count)):
			var side: int = -1 if horn % 2 == 0 else 1
			var root: Vector2i = head + Vector2i(side * (3 + horn) * scale, -4 * scale)
			var tip: Vector2i = root + Vector2i(side * (5 + horn) * scale, -7 * scale)
			_line(image, root, tip, outline, 3 * scale)
			_line(image, root, tip, accent.darkened(0.20), scale)
	if silhouette.find("fallen") >= 0 or silhouette.find("halo") >= 0:
		var halo: Vector2i = head - Vector2i(0, 8 * scale)
		_circle(image, halo, 7 * scale, outline, false)
		_circle(image, halo, 6 * scale, Color(accent, 0.78), false)
	if silhouette.find("feral") >= 0:
		var back: Vector2i = torso.get_center() - Vector2i(roundi(direction.x * 7.0 * scale), roundi(direction.y * 7.0 * scale))
		for spike: int in range(3):
			var offset: int = (spike - 1) * 4 * scale
			var root: Vector2i = back + Vector2i(roundi(perp.x * float(offset)), roundi(perp.y * float(offset)))
			_line(image, root, root - Vector2i(roundi(direction.x * 6.0 * scale), roundi(direction.y * 6.0 * scale)), accent.darkened(0.24), 2 * scale)

func _draw_role_weapon(image: Image, chest: Vector2i, direction: Vector2, perp: Vector2, frame_index: int, role: String, silhouette: String, genome: Dictionary, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var recoil: float = 2.0 * float(scale) if frame_index == 2 else 0.0
	var forward: Vector2 = direction * (17.0 * float(scale) - recoil)
	var side_offset: Vector2 = perp * 5.0 * float(scale)
	match role:
		"caster":
			var grip: Vector2i = chest + Vector2i(roundi(side_offset.x), roundi(side_offset.y))
			var tip: Vector2i = grip + Vector2i(roundi(direction.x * 22.0 * scale), roundi(direction.y * 22.0 * scale))
			_line(image, grip, tip, outline, 4 * scale)
			_line(image, grip, tip, secondary.lightened(0.08), 2 * scale)
			_circle(image, tip, 4 * scale, outline)
			_circle(image, tip, (2 + frame_index % 2) * scale, accent)
		"melee":
			var grip: Vector2i = chest + Vector2i(roundi(side_offset.x), roundi(side_offset.y))
			var tip: Vector2i = grip + Vector2i(roundi(direction.x * 19.0 * scale), roundi(direction.y * 19.0 * scale))
			_line(image, grip, tip, outline, 6 * scale)
			_line(image, grip, tip, Color8(215, 208, 181), 2 * scale)
			var blade: Vector2i = tip + Vector2i(roundi(perp.x * 6.0 * scale), roundi(perp.y * 6.0 * scale))
			_line(image, tip, blade, accent, 3 * scale)
		"charger":
			var shield_center: Vector2i = chest + Vector2i(roundi(direction.x * 10.0 * scale), roundi(direction.y * 10.0 * scale))
			_fill_rect(image, Rect2i(shield_center.x - 7 * scale, shield_center.y - 8 * scale, 14 * scale, 16 * scale), outline)
			_fill_rect(image, Rect2i(shield_center.x - 5 * scale, shield_center.y - 6 * scale, 10 * scale, 12 * scale), secondary.darkened(0.14))
			_line(image, shield_center - Vector2i(roundi(perp.x * 5.0 * scale), roundi(perp.y * 5.0 * scale)), shield_center + Vector2i(roundi(perp.x * 5.0 * scale), roundi(perp.y * 5.0 * scale)), accent, 2 * scale)
		"skirmisher":
			for side_variant in [-1, 1]:
				var side: int = int(side_variant)
				var grip: Vector2i = chest + Vector2i(roundi(perp.x * side * 6.0 * scale), roundi(perp.y * side * 6.0 * scale))
				var tip: Vector2i = grip + Vector2i(roundi(direction.x * 14.0 * scale), roundi(direction.y * 14.0 * scale))
				_line(image, grip, tip, outline, 4 * scale)
				_line(image, grip, tip, accent, 2 * scale)
		_:
			var heavy: bool = silhouette.find("cain") >= 0 or silhouette.find("gunner") >= 0 or int(genome.get("weapon_style", 0)) == 5
			var grip: Vector2i = chest + Vector2i(roundi(side_offset.x), roundi(side_offset.y))
			var barrel_len: float = 24.0 if heavy else 18.0
			var tip: Vector2i = grip + Vector2i(roundi(direction.x * barrel_len * scale - direction.x * recoil), roundi(direction.y * barrel_len * scale - direction.y * recoil))
			_line(image, grip, tip, outline, (7 if heavy else 5) * scale)
			_line(image, grip, tip, secondary.lightened(0.05), (4 if heavy else 3) * scale)
			var muzzle_a: Vector2i = tip + Vector2i(roundi(perp.x * 3.0 * scale), roundi(perp.y * 3.0 * scale))
			var muzzle_b: Vector2i = tip - Vector2i(roundi(perp.x * 3.0 * scale), roundi(perp.y * 3.0 * scale))
			_line(image, muzzle_a, muzzle_b, accent, 2 * scale)
			if heavy:
				var stock: Vector2i = grip - Vector2i(roundi(direction.x * 8.0 * scale), roundi(direction.y * 8.0 * scale))
				_fill_rect(image, Rect2i(stock.x - 4 * scale, stock.y - 4 * scale, 8 * scale, 8 * scale), outline)
				_circle(image, stock, 2 * scale, accent.darkened(0.12))

func _draw_orbiter(image: Image, center: Vector2i, direction: Vector2, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var silhouette: String = String(genome.get("silhouette_key", "role_orbiter"))
	var body: Vector2i = center + Vector2i(0, 3 * scale)
	_fill_ellipse(image, body + Vector2i(0, 8 * scale), 12 * scale, 4 * scale, Color(0, 0, 0, 0.30))
	if silhouette.find("serpent") >= 0:
		var previous: Vector2i = body
		var perp: Vector2 = Vector2(-direction.y, direction.x)
		for segment: int in range(7):
			var distance: float = float(segment) * 4.0 * scale
			var wave: float = sin(float(segment + frame_index) * 0.85) * 4.0 * scale
			var point_v: Vector2 = Vector2(body) - direction * distance + perp * wave
			var point: Vector2i = Vector2i(roundi(point_v.x), roundi(point_v.y))
			if segment > 0:
				_line(image, previous, point, outline, 6 * scale)
				_line(image, previous, point, primary, 3 * scale)
			previous = point
		_circle(image, body, 6 * scale, accent)
		return
	if silhouette.find("ophanim") >= 0:
		_circle(image, body, 17 * scale, outline, false)
		_circle(image, body, 13 * scale, accent.darkened(0.18), false)
		_circle(image, body, 8 * scale, secondary, false)
		var eye: Vector2i = body + Vector2i(roundi(direction.x * 6.0 * scale), roundi(direction.y * 6.0 * scale))
		_circle(image, eye, 3 * scale, accent)
		return
	# Cherub/drone family: asymmetric wing blades make facing visible.
	_circle(image, body, 9 * scale, outline)
	_circle(image, body, 6 * scale, primary)
	var eye: Vector2i = body + Vector2i(roundi(direction.x * 4.0 * scale), roundi(direction.y * 4.0 * scale))
	_circle(image, eye, 2 * scale, accent)
	var perp: Vector2 = Vector2(-direction.y, direction.x)
	for side_variant in [-1, 1]:
		var side: int = int(side_variant)
		var root: Vector2i = body + Vector2i(roundi(perp.x * side * 7.0 * scale), roundi(perp.y * side * 7.0 * scale))
		var tip: Vector2i = root + Vector2i(roundi((-direction.x * 5.0 + perp.x * side * 9.0) * scale), roundi((-direction.y * 5.0 + perp.y * side * 9.0) * scale))
		_line(image, root, tip, outline, 5 * scale)
		_line(image, root, tip, secondary, 2 * scale)

func _draw_radial(image: Image, center: Vector2i, direction: Vector2, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var body: Vector2i = center + Vector2i(0, 2 * scale)
	_fill_ellipse(image, body + Vector2i(0, 8 * scale), 16 * scale, 5 * scale, Color(0, 0, 0, 0.32))
	_circle(image, body, 15 * scale, outline)
	_circle(image, body, 12 * scale, primary)
	_fill_rect(image, Rect2i(body.x - 8 * scale, body.y - 5 * scale, 16 * scale, 10 * scale), secondary.darkened(0.12))
	var arm_count: int = 6 + clampi(int(genome.get("accent_count", 2)), 1, 4)
	for arm: int in range(arm_count):
		var angle: float = TAU * float(arm) / float(arm_count) + float(frame_index) * 0.08
		var start: Vector2i = body + Vector2i(roundi(cos(angle) * 10.0 * scale), roundi(sin(angle) * 10.0 * scale))
		var finish: Vector2i = body + Vector2i(roundi(cos(angle) * 20.0 * scale), roundi(sin(angle) * 20.0 * scale))
		_line(image, start, finish, outline, 4 * scale)
		_line(image, start, finish, accent.darkened(0.12), 2 * scale)
	var forward: Vector2i = body + Vector2i(roundi(direction.x * 16.0 * scale), roundi(direction.y * 16.0 * scale))
	_line(image, body, forward, outline, 6 * scale)
	_line(image, body, forward, accent, 3 * scale)
	_circle(image, forward, 3 * scale, accent.lightened(0.18))

func _draw_guardian_frame(image: Image, origin: Vector2i, size: int, genome: Dictionary, direction: Vector2, frame_index: int) -> void:
	var palette_index: int = clampi(int(genome.get("palette_index", 12)), 0, PALETTES.size() - 1)
	var palette: Array = PALETTES[palette_index]
	var primary: Color = Color(palette[0])
	var secondary: Color = Color(palette[1])
	var accent: Color = Color(palette[2])
	var outline: Color = Color(palette[4])
	var id: String = String(genome.get("id", "watcher_engine"))
	var center: Vector2i = origin + Vector2i(int(size / 2), int(size * 0.56))
	var perp: Vector2 = Vector2(-direction.y, direction.x)
	_fill_ellipse(image, center + Vector2i(0, 30), 34, 10, Color(0, 0, 0, 0.36))
	match id:
		"watcher_engine":
			_circle(image, center, 24, outline)
			_circle(image, center, 20, primary)
			_circle(image, center, 11, secondary)
			var eye: Vector2i = center + Vector2i(roundi(direction.x * 12.0), roundi(direction.y * 12.0))
			_circle(image, eye, 6, outline)
			_circle(image, eye, 4, accent)
			for side_variant in [-1, 1]:
				var side: int = int(side_variant)
				var root: Vector2i = center + Vector2i(roundi(perp.x * side * 18.0), roundi(perp.y * side * 18.0))
				var tip: Vector2i = root - Vector2i(roundi(direction.x * 24.0), roundi(direction.y * 24.0)) + Vector2i(roundi(perp.x * side * 10.0), roundi(perp.y * side * 10.0))
				_line(image, root, tip, outline, 8)
				_line(image, root, tip, secondary, 4)
			var boom: Vector2i = center + Vector2i(roundi(direction.x * 35.0), roundi(direction.y * 35.0))
			_line(image, center, boom, outline, 9)
			_line(image, center, boom, accent.darkened(0.12), 5)
			_circle(image, boom, 5, accent)
		"first_nephilim":
			_fill_rect(image, Rect2i(center.x - 20, center.y - 22, 40, 42), outline)
			_fill_rect(image, Rect2i(center.x - 17, center.y - 19, 34, 36), primary)
			var head: Vector2i = center - Vector2i(0, 31)
			_circle(image, head, 12, outline)
			_circle(image, head, 9, secondary)
			for side_variant in [-1, 1]:
				var side: int = int(side_variant)
				var shoulder: Vector2i = center + Vector2i(roundi(perp.x * side * 25.0), roundi(perp.y * side * 25.0)) - Vector2i(0, 12)
				_circle(image, shoulder, 9, outline)
				_circle(image, shoulder, 6, secondary)
			var blade_root: Vector2i = center + Vector2i(roundi(perp.x * 10.0), roundi(perp.y * 10.0))
			var blade_tip: Vector2i = blade_root + Vector2i(roundi(direction.x * 38.0), roundi(direction.y * 38.0))
			_line(image, blade_root, blade_tip, outline, 11)
			_line(image, blade_root, blade_tip, Color8(221, 205, 174), 5)
			_line(image, head + Vector2i(-5, -5), head + Vector2i(-17, -23), outline, 5)
			_line(image, head + Vector2i(5, -5), head + Vector2i(13, -18), accent.darkened(0.18), 4)
		"gate_cherub":
			_circle(image, center, 18, outline)
			_circle(image, center, 14, primary)
			_circle(image, center, 27, accent.darkened(0.20), false)
			for side_variant in [-1, 1]:
				var side: int = int(side_variant)
				var root: Vector2i = center + Vector2i(roundi(perp.x * side * 12.0), roundi(perp.y * side * 12.0))
				var wing_tip: Vector2i = root - Vector2i(roundi(direction.x * 13.0), roundi(direction.y * 13.0)) + Vector2i(roundi(perp.x * side * 29.0), roundi(perp.y * side * 29.0))
				_line(image, root, wing_tip, outline, 9)
				_line(image, root, wing_tip, secondary.lightened(0.10), 4)
			var lance_tip: Vector2i = center + Vector2i(roundi(direction.x * 42.0), roundi(direction.y * 42.0))
			_line(image, center, lance_tip, outline, 8)
			_line(image, center, lance_tip, accent, 4)
			_line(image, lance_tip - Vector2i(roundi(perp.x * 8.0), roundi(perp.y * 8.0)), lance_tip + Vector2i(roundi(perp.x * 8.0), roundi(perp.y * 8.0)), accent, 4)
		"tower_enoch":
			_fill_rect(image, Rect2i(center.x - 18, center.y - 31, 36, 56), outline)
			_fill_rect(image, Rect2i(center.x - 14, center.y - 27, 28, 48), primary)
			for tier: int in range(4):
				var y: int = center.y - 22 + tier * 12
				_fill_rect(image, Rect2i(center.x - 12, y, 24, 5), secondary.darkened(0.08))
				_circle(image, Vector2i(center.x + 7, y + 2), 2, accent)
			var emitter: Vector2i = center + Vector2i(roundi(direction.x * 34.0), roundi(direction.y * 34.0)) - Vector2i(0, 9)
			_line(image, center - Vector2i(0, 8), emitter, outline, 10)
			_line(image, center - Vector2i(0, 8), emitter, accent.darkened(0.16), 5)
			for side_variant in [-1, 1]:
				var side: int = int(side_variant)
				var prong: Vector2i = emitter + Vector2i(roundi(perp.x * side * 8.0), roundi(perp.y * side * 8.0))
				_line(image, emitter, prong, accent, 4)
		"serpent_interface":
			var previous: Vector2i = center - Vector2i(roundi(direction.x * 26.0), roundi(direction.y * 26.0))
			for segment: int in range(11):
				var distance: float = float(segment) * 5.0
				var wave: float = sin(float(segment) * 0.68 + float(frame_index) * 0.25) * 10.0
				var point_v: Vector2 = Vector2(center) - direction * (26.0 - distance) + perp * wave
				var point: Vector2i = Vector2i(roundi(point_v.x), roundi(point_v.y))
				if segment > 0:
					_line(image, previous, point, outline, 13)
					_line(image, previous, point, primary, 7)
				previous = point
			var head: Vector2i = center + Vector2i(roundi(direction.x * 31.0), roundi(direction.y * 31.0))
			_circle(image, head, 12, outline)
			_circle(image, head, 8, secondary)
			var eye: Vector2i = head + Vector2i(roundi(direction.x * 5.0), roundi(direction.y * 5.0))
			_circle(image, eye, 3, accent)
			for side_variant in [-1, 1]:
				var side: int = int(side_variant)
				var crest: Vector2i = head - Vector2i(roundi(direction.x * 4.0), roundi(direction.y * 4.0)) + Vector2i(roundi(perp.x * side * 7.0), roundi(perp.y * side * 7.0))
				var crest_tip: Vector2i = crest - Vector2i(roundi(direction.x * 10.0), roundi(direction.y * 10.0)) + Vector2i(roundi(perp.x * side * 5.0), roundi(perp.y * side * 5.0))
				_line(image, crest, crest_tip, accent.darkened(0.12), 4)
		_:
			_circle(image, center, 24, outline)
			_circle(image, center, 20, primary)
			var forward: Vector2i = center + Vector2i(roundi(direction.x * 35.0), roundi(direction.y * 35.0))
			_line(image, center, forward, accent, 6)

	# Shared animation read: recoil/pulse on frames 1-3 without changing identity.
	if frame_index == 2:
		var pulse_center: Vector2i = center + Vector2i(roundi(direction.x * 27.0), roundi(direction.y * 27.0))
		_circle(image, pulse_center, 5, Color(accent, 0.60), false)

func audit_contract() -> Dictionary:
	var report: Dictionary = super.audit_contract()
	report["authored_forge_version"] = AUTHORED_FORGE_VERSION
	report["authored_role_templates"] = true
	report["guardian_specific_templates"] = true
	report["frame_safe_anatomy"] = true
	report["profile_driven_weapons"] = true
	return report
