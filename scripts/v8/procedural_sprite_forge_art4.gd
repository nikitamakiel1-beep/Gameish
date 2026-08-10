extends "res://scripts/v8/procedural_sprite_forge_roguelike.gd"

const ART4_FORGE_VERSION: String = "0.6.4-authored-art4"

# Art4 is still procedural, but it is pose-first. The four runtime frames are
# treated as authored states: idle, locomotion, attack/recoil, dash/special.
# Identity geometry is stable for heroes; enemy variation stays inside family rules.
func _draw_humanoid(image: Image, center: Vector2i, direction: Vector2, stride: int, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, skin: Color, outline: Color, scale: int) -> void:
	var facing: Vector2 = direction.normalized()
	if facing.length_squared() < 0.01:
		facing = Vector2.DOWN
	var perp: Vector2 = Vector2(-facing.y, facing.x)
	var role: String = String(genome.get("role", "melee"))
	var silhouette: String = String(genome.get("silhouette_key", role))
	var lineage: String = String(genome.get("lineage", ""))
	var category: String = String(genome.get("category", "preadamic"))
	var action: int = clampi(frame_index, 0, 3)

	var idle_bob: int = -1 if action == 0 else 0
	var move_bob: int = -1 if action == 1 else (1 if action == 3 else 0)
	var attack_lean: int = -2 if action == 2 else (2 if action == 3 else 0)
	var center_shift_v: Vector2 = facing * float(attack_lean * scale) + Vector2(0.0, float((idle_bob + move_bob) * scale))
	var body_center: Vector2i = center + Vector2i(roundi(center_shift_v.x), roundi(center_shift_v.y))
	var foot_y: int = body_center.y + 8 * scale

	var torso_w: int = 12 * scale
	var torso_h: int = 11 * scale
	if role == "charger":
		torso_w = 17 * scale
		torso_h = 12 * scale
	elif role == "caster":
		torso_w = 12 * scale
		torso_h = 13 * scale
	elif role == "skirmisher":
		torso_w = 10 * scale
	elif silhouette.find("giant") >= 0 or silhouette.find("colossus") >= 0:
		torso_w = 18 * scale
		torso_h = 14 * scale

	if lineage == "cain":
		torso_w = 16 * scale
		torso_h = 12 * scale
	elif lineage == "seth":
		torso_w = 14 * scale
	elif lineage in ["abel", "naamah"]:
		torso_h = 13 * scale

	var shadow_w: int = maxi(7 * scale, int(float(torso_w) * 0.64))
	_fill_ellipse(image, Vector2i(body_center.x, foot_y + 3 * scale), shadow_w, 3 * scale, Color(0, 0, 0, 0.38))

	_a4_draw_legs(image, body_center, foot_y, facing, perp, action, role, secondary, outline, scale)

	var torso_center_y: int = foot_y - 12 * scale
	var torso: Rect2i = Rect2i(body_center.x - int(torso_w / 2), torso_center_y - int(torso_h / 2), torso_w, torso_h)
	_fill_rect(image, torso.grow(scale), outline)
	_fill_rect(image, torso, primary)
	_fill_rect(image, Rect2i(torso.position + Vector2i(scale, scale), Vector2i(maxi(scale, torso.size.x - 2 * scale), 2 * scale)), primary.lightened(0.16))
	_fill_rect(image, Rect2i(torso.position + Vector2i(scale, torso.size.y - 3 * scale), Vector2i(maxi(scale, torso.size.x - 2 * scale), 2 * scale)), primary.darkened(0.24))
	_a4_draw_torso_identity(image, torso, role, silhouette, lineage, category, secondary, accent, outline, scale)

	var head_offset_v: Vector2 = facing * float((1 if action == 3 else 0) * scale)
	var head: Vector2i = Vector2i(body_center.x, torso.position.y - 6 * scale) + Vector2i(roundi(head_offset_v.x), roundi(head_offset_v.y))
	var head_rx: int = 7 * scale
	var head_ry: int = 6 * scale
	if role == "charger":
		head_rx = 6 * scale
	if silhouette.find("giant") >= 0 or silhouette.find("colossus") >= 0:
		head_rx = 8 * scale
	_fill_ellipse(image, head, head_rx + 2 * scale, head_ry + 2 * scale, outline)
	_fill_ellipse(image, head, head_rx, head_ry, skin)
	_a4_draw_head_identity(image, head, facing, silhouette, lineage, category, genome, primary, secondary, accent, skin, outline, scale)

	var shoulder_a: Vector2i = Vector2i(torso.position.x + 2 * scale, torso.position.y + 3 * scale)
	var shoulder_b: Vector2i = Vector2i(torso.end.x - 2 * scale, torso.position.y + 3 * scale)
	_a4_draw_weapon_and_arms(image, torso, shoulder_a, shoulder_b, facing, perp, action, role, silhouette, lineage, genome, secondary, accent, skin, outline, scale)
	_a4_draw_back_and_fx(image, torso, head, facing, perp, action, silhouette, lineage, category, primary, secondary, accent, outline, scale)

func _a4_draw_legs(image: Image, body_center: Vector2i, foot_y: int, facing: Vector2, perp: Vector2, action: int, role: String, secondary: Color, outline: Color, scale: int) -> void:
	var stride_amount: int = 0
	if action == 1:
		stride_amount = 2 * scale
	elif action == 3:
		stride_amount = 3 * scale
	for side_variant in [-1, 1]:
		var side: int = int(side_variant)
		var lateral_v: Vector2 = perp * float(side * 3 * scale)
		var forward_v: Vector2 = facing * float(side * stride_amount)
		var leg_root: Vector2i = body_center + Vector2i(roundi(lateral_v.x + forward_v.x), roundi(lateral_v.y + forward_v.y)) + Vector2i(0, 1 * scale)
		var leg_top_y: int = foot_y - 7 * scale
		var leg_x: int = leg_root.x
		_fill_rect(image, Rect2i(leg_x - 2 * scale, leg_top_y, 4 * scale, 7 * scale), outline)
		_fill_rect(image, Rect2i(leg_x - scale, leg_top_y, 2 * scale, 5 * scale), secondary.darkened(0.18))
		var foot_shift: int = 2 * scale if action == 3 else scale
		_fill_rect(image, Rect2i(leg_x - 2 * scale, foot_y - 2 * scale, 4 * scale + foot_shift, 3 * scale), outline)
	if role == "charger" and action == 2:
		_fill_rect(image, Rect2i(body_center.x - 6 * scale, foot_y - 2 * scale, 12 * scale, 2 * scale), outline)

func _a4_draw_torso_identity(image: Image, torso: Rect2i, role: String, silhouette: String, lineage: String, category: String, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	if role == "charger":
		_fill_rect(image, Rect2i(torso.position.x + scale, torso.position.y + 3 * scale, torso.size.x - 2 * scale, 4 * scale), secondary.darkened(0.15))
		_fill_rect(image, Rect2i(torso.position.x - scale, torso.get_center().y - scale, torso.size.x + 2 * scale, 2 * scale), outline)
	elif role == "caster":
		_fill_rect(image, Rect2i(torso.position.x + 2 * scale, torso.position.y + 4 * scale, maxi(2 * scale, torso.size.x - 4 * scale), torso.size.y - 3 * scale), secondary.darkened(0.10))
		_fill_rect(image, Rect2i(torso.position.x - scale, torso.end.y - 3 * scale, torso.size.x + 2 * scale, 3 * scale), outline)
	else:
		_fill_rect(image, Rect2i(torso.position.x + 2 * scale, torso.position.y + 3 * scale, maxi(2 * scale, torso.size.x - 4 * scale), 3 * scale), secondary.darkened(0.08))

	if lineage == "adam":
		_fill_rect(image, Rect2i(torso.position.x + 2 * scale, torso.position.y + 2 * scale, 4 * scale, 5 * scale), Color8(62, 104, 58))
		_circle(image, torso.position + Vector2i(3 * scale, 2 * scale), 2 * scale, Color8(111, 170, 84))
	elif lineage == "abel":
		_fill_rect(image, Rect2i(torso.position.x + scale, torso.end.y - 4 * scale, torso.size.x - 2 * scale, 3 * scale), Color8(221, 207, 164))
		_circle(image, torso.get_center(), 2 * scale, Color8(242, 201, 85))
	elif lineage == "cain":
		_fill_rect(image, Rect2i(torso.position.x + 2 * scale, torso.end.y - 4 * scale, torso.size.x - 4 * scale, 2 * scale), Color8(221, 52, 46))
		_fill_rect(image, Rect2i(torso.position.x + 3 * scale, torso.position.y + 2 * scale, 3 * scale, 3 * scale), Color8(235, 63, 55))
	elif lineage == "seth":
		_fill_rect(image, Rect2i(torso.get_center().x - scale, torso.position.y + scale, 2 * scale, torso.size.y - 2 * scale), Color8(82, 154, 225))
		_fill_rect(image, Rect2i(torso.position.x + scale, torso.position.y + 2 * scale, torso.size.x - 2 * scale, 2 * scale), Color8(110, 184, 238))
	elif lineage == "naamah":
		_circle(image, torso.get_center(), 2 * scale, Color8(208, 93, 220))
		_fill_rect(image, Rect2i(torso.position.x + scale, torso.end.y - 4 * scale, torso.size.x - 2 * scale, 3 * scale), Color8(83, 52, 102))
	elif category == "nephilim":
		_fill_rect(image, Rect2i(torso.get_center().x - scale, torso.position.y + scale, 2 * scale, torso.size.y - 2 * scale), accent.darkened(0.10))
	elif category == "fallen":
		_circle(image, torso.get_center(), 2 * scale, accent)
	elif silhouette.find("gunner") >= 0:
		_fill_rect(image, Rect2i(torso.position.x + 2 * scale, torso.end.y - 4 * scale, torso.size.x - 4 * scale, 2 * scale), accent)

func _a4_draw_head_identity(image: Image, head: Vector2i, facing: Vector2, silhouette: String, lineage: String, category: String, genome: Dictionary, primary: Color, secondary: Color, accent: Color, skin: Color, outline: Color, scale: int) -> void:
	if lineage == "adam":
		var hair: Color = Color8(41, 32, 27)
		_fill_rect(image, Rect2i(head.x - 7 * scale, head.y - 7 * scale, 13 * scale, 4 * scale), outline)
		_fill_rect(image, Rect2i(head.x - 6 * scale, head.y - 6 * scale, 11 * scale, 3 * scale), hair)
		_fill_rect(image, Rect2i(head.x - 7 * scale, head.y - 3 * scale, 3 * scale, 5 * scale), hair)
	elif lineage == "abel":
		_fill_rect(image, Rect2i(head.x - 7 * scale, head.y - 6 * scale, 14 * scale, 6 * scale), Color8(232, 222, 187))
		_fill_rect(image, Rect2i(head.x - 5 * scale, head.y - 3 * scale, 10 * scale, 3 * scale), skin)
		_circle(image, head - Vector2i(0, 8 * scale), 8 * scale, outline, false)
		_circle(image, head - Vector2i(0, 8 * scale), 7 * scale, Color8(239, 202, 87), false)
	elif lineage == "cain":
		_fill_rect(image, Rect2i(head.x - 7 * scale, head.y - 6 * scale, 14 * scale, 6 * scale), outline)
		_fill_rect(image, Rect2i(head.x - 5 * scale, head.y - 4 * scale, 10 * scale, 3 * scale), Color8(80, 33, 35))
		_fill_rect(image, Rect2i(head.x - 4 * scale, head.y - scale, 8 * scale, 2 * scale), Color8(230, 54, 47))
	elif lineage == "seth":
		_fill_rect(image, Rect2i(head.x - 7 * scale, head.y - 6 * scale, 14 * scale, 6 * scale), outline)
		_fill_rect(image, Rect2i(head.x - 5 * scale, head.y - 4 * scale, 10 * scale, 3 * scale), Color8(53, 72, 91))
		_fill_rect(image, Rect2i(head.x - 5 * scale, head.y - scale, 10 * scale, 2 * scale), Color8(84, 169, 236))
	elif lineage == "naamah":
		var cap: Color = Color8(129, 62, 149)
		_fill_ellipse(image, head - Vector2i(0, 5 * scale), 8 * scale, 4 * scale, outline)
		_fill_ellipse(image, head - Vector2i(0, 5 * scale), 7 * scale, 3 * scale, cap)
		for bud_index: int in range(3):
			var bud_x: int = (bud_index - 1) * 5 * scale
			_circle(image, head + Vector2i(bud_x, -8 * scale - absi(bud_index - 1) * scale), 2 * scale, Color8(207, 93, 221))
	elif silhouette.find("cultist") >= 0 or silhouette.find("caster") >= 0:
		_fill_rect(image, Rect2i(head.x - 7 * scale, head.y - 6 * scale, 14 * scale, 7 * scale), outline)
		_fill_rect(image, Rect2i(head.x - 5 * scale, head.y - 4 * scale, 10 * scale, 4 * scale), primary.darkened(0.18))
	elif silhouette.find("hunter") >= 0:
		_fill_rect(image, Rect2i(head.x - 8 * scale, head.y - 6 * scale, 16 * scale, 3 * scale), outline)
		_fill_rect(image, Rect2i(head.x - 7 * scale, head.y - 5 * scale, 14 * scale, 2 * scale), primary)
	elif silhouette.find("brute") >= 0 or silhouette.find("giant") >= 0 or silhouette.find("colossus") >= 0:
		_fill_rect(image, Rect2i(head.x - 7 * scale, head.y - 5 * scale, 14 * scale, 5 * scale), outline)
		_fill_rect(image, Rect2i(head.x - 5 * scale, head.y - 3 * scale, 10 * scale, 2 * scale), secondary)
	elif category == "nephilim":
		_fill_rect(image, Rect2i(head.x - 6 * scale, head.y - 5 * scale, 12 * scale, 4 * scale), outline)
		for horn_side_variant in [-1, 1]:
			var horn_side: int = int(horn_side_variant)
			_line(image, head + Vector2i(horn_side * 4 * scale, -4 * scale), head + Vector2i(horn_side * 8 * scale, -10 * scale), outline, 3 * scale)
	else:
		var head_style: int = int(genome.get("head_style", 0))
		if head_style % 2 == 0:
			_fill_rect(image, Rect2i(head.x - 6 * scale, head.y - 6 * scale, 12 * scale, 3 * scale), primary.darkened(0.16))
		else:
			_fill_rect(image, Rect2i(head.x - 6 * scale, head.y - 4 * scale, 12 * scale, 4 * scale), outline)
			_fill_rect(image, Rect2i(head.x - 4 * scale, head.y - 2 * scale, 8 * scale, 2 * scale), secondary)

	var eye_v: Vector2 = Vector2(head) + facing * float(4 * scale)
	var eye: Vector2i = Vector2i(roundi(eye_v.x), roundi(eye_v.y))
	_fill_rect(image, Rect2i(eye.x - scale, eye.y - scale, 2 * scale, 2 * scale), accent)

func _a4_draw_weapon_and_arms(image: Image, torso: Rect2i, shoulder_a: Vector2i, shoulder_b: Vector2i, facing: Vector2, perp: Vector2, action: int, role: String, silhouette: String, lineage: String, genome: Dictionary, secondary: Color, accent: Color, skin: Color, outline: Color, scale: int) -> void:
	var attack_recoil: float = 3.0 * float(scale) if action == 2 else 0.0
	var grip_center_v: Vector2 = Vector2(torso.get_center()) + facing * float(2 * scale) - facing * attack_recoil
	var grip_center: Vector2i = Vector2i(roundi(grip_center_v.x), roundi(grip_center_v.y))

	var heavy: bool = lineage == "cain" or silhouette.find("gunner") >= 0 or int(genome.get("weapon_style", 0)) == 5
	var caster: bool = role == "caster"
	var melee: bool = role == "melee"
	var charger: bool = role == "charger"
	var dual: bool = role == "skirmisher"

	if caster:
		var staff_tip_v: Vector2 = Vector2(grip_center) + facing * float(19 * scale)
		var staff_tip: Vector2i = Vector2i(roundi(staff_tip_v.x), roundi(staff_tip_v.y))
		_line(image, shoulder_a, grip_center, outline, 4 * scale)
		_line(image, shoulder_a, grip_center, skin.darkened(0.12), 2 * scale)
		_line(image, grip_center, staff_tip, outline, 4 * scale)
		_line(image, grip_center, staff_tip, secondary, 2 * scale)
		_circle(image, staff_tip, 4 * scale if action == 2 else 3 * scale, outline)
		_circle(image, staff_tip, 3 * scale if action == 2 else 2 * scale, accent)
		if action == 2:
			for spark: int in range(4):
				var spark_angle: float = TAU * float(spark) / 4.0
				var spark_pos: Vector2i = staff_tip + Vector2i(roundi(cos(spark_angle) * 6.0 * scale), roundi(sin(spark_angle) * 6.0 * scale))
				_circle(image, spark_pos, scale, accent.lightened(0.20))
		return

	if charger:
		var shield_center_v: Vector2 = Vector2(torso.get_center()) + facing * float(9 * scale)
		var shield_center: Vector2i = Vector2i(roundi(shield_center_v.x), roundi(shield_center_v.y))
		_fill_rect(image, Rect2i(shield_center.x - 7 * scale, shield_center.y - 8 * scale, 14 * scale, 16 * scale), outline)
		_fill_rect(image, Rect2i(shield_center.x - 5 * scale, shield_center.y - 6 * scale, 10 * scale, 12 * scale), secondary.darkened(0.14))
		_fill_rect(image, Rect2i(shield_center.x - scale, shield_center.y - 5 * scale, 2 * scale, 10 * scale), accent)
		_line(image, shoulder_a, shield_center, outline, 4 * scale)
		return

	if melee:
		var blade_tip_v: Vector2 = Vector2(grip_center) + facing * float(18 * scale)
		if action == 2:
			blade_tip_v += perp * float(8 * scale)
		var blade_tip: Vector2i = Vector2i(roundi(blade_tip_v.x), roundi(blade_tip_v.y))
		_line(image, shoulder_a, grip_center, outline, 4 * scale)
		_line(image, shoulder_a, grip_center, skin.darkened(0.14), 2 * scale)
		_line(image, grip_center, blade_tip, outline, 6 * scale)
		_line(image, grip_center, blade_tip, Color8(226, 216, 184), 2 * scale)
		return

	if dual:
		for side_variant in [-1, 1]:
			var side: int = int(side_variant)
			var hand_v: Vector2 = Vector2(torso.get_center()) + perp * float(side * 5 * scale)
			var hand: Vector2i = Vector2i(roundi(hand_v.x), roundi(hand_v.y))
			var muzzle_v: Vector2 = hand_v + facing * float((14 - (2 if action == 2 else 0)) * scale)
			var muzzle: Vector2i = Vector2i(roundi(muzzle_v.x), roundi(muzzle_v.y))
			_line(image, shoulder_a if side < 0 else shoulder_b, hand, outline, 4 * scale)
			_line(image, hand, muzzle, outline, 4 * scale)
			_line(image, hand, muzzle, accent, 2 * scale)
			if action == 2:
				_circle(image, muzzle + Vector2i(roundi(facing.x * 3.0 * scale), roundi(facing.y * 3.0 * scale)), 2 * scale, Color8(255, 207, 104))
		return

	var weapon_length: float = 26.0 if heavy else 19.0
	var muzzle_v: Vector2 = Vector2(grip_center) + facing * weapon_length * float(scale)
	var muzzle: Vector2i = Vector2i(roundi(muzzle_v.x), roundi(muzzle_v.y))
	var support_hand_v: Vector2 = Vector2(grip_center) + facing * float(7 * scale)
	var support_hand: Vector2i = Vector2i(roundi(support_hand_v.x), roundi(support_hand_v.y))
	_line(image, shoulder_a, grip_center, outline, 4 * scale)
	_line(image, shoulder_a, grip_center, skin.darkened(0.12), 2 * scale)
	_line(image, shoulder_b, support_hand, outline, 4 * scale)
	_line(image, shoulder_b, support_hand, skin.darkened(0.12), 2 * scale)
	_line(image, grip_center, muzzle, outline, (8 if heavy else 6) * scale)
	_line(image, grip_center, muzzle, secondary, (5 if heavy else 3) * scale)
	var barrel_a_v: Vector2 = muzzle_v + perp * float((4 if heavy else 3) * scale)
	var barrel_b_v: Vector2 = muzzle_v - perp * float((4 if heavy else 3) * scale)
	_line(image, Vector2i(roundi(barrel_a_v.x), roundi(barrel_a_v.y)), Vector2i(roundi(barrel_b_v.x), roundi(barrel_b_v.y)), accent, 2 * scale)
	if heavy:
		var stock_v: Vector2 = Vector2(grip_center) - facing * float(8 * scale)
		var stock: Vector2i = Vector2i(roundi(stock_v.x), roundi(stock_v.y))
		_fill_rect(image, Rect2i(stock.x - 4 * scale, stock.y - 3 * scale, 8 * scale, 6 * scale), outline)
		_fill_rect(image, Rect2i(stock.x - 2 * scale, stock.y - 2 * scale, 4 * scale, 4 * scale), accent.darkened(0.18))
	if action == 2:
		var flash_center_v: Vector2 = muzzle_v + facing * float(4 * scale)
		var flash_center: Vector2i = Vector2i(roundi(flash_center_v.x), roundi(flash_center_v.y))
		_circle(image, flash_center, 3 * scale, Color8(255, 205, 96))
		_line(image, muzzle, flash_center + Vector2i(roundi(facing.x * 5.0 * scale), roundi(facing.y * 5.0 * scale)), Color8(255, 238, 162), 2 * scale)

func _a4_draw_back_and_fx(image: Image, torso: Rect2i, head: Vector2i, facing: Vector2, perp: Vector2, action: int, silhouette: String, lineage: String, category: String, primary: Color, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var back_v: Vector2 = Vector2(torso.get_center()) - facing * float(8 * scale)
	var back: Vector2i = Vector2i(roundi(back_v.x), roundi(back_v.y))
	if lineage == "cain":
		_fill_rect(image, Rect2i(back.x - 4 * scale, back.y - 4 * scale, 8 * scale, 8 * scale), outline)
		_circle(image, back, 2 * scale, Color8(232, 54, 47))
		var scarf_end_v: Vector2 = back_v - facing * float((10 + action * 2) * scale) + perp * float(3 * scale)
		_line(image, back, Vector2i(roundi(scarf_end_v.x), roundi(scarf_end_v.y)), Color8(151, 33, 38), 3 * scale)
	elif lineage == "seth":
		for side_variant in [-1, 1]:
			var side: int = int(side_variant)
			var node_v: Vector2 = back_v + perp * float(side * 8 * scale)
			var node: Vector2i = Vector2i(roundi(node_v.x), roundi(node_v.y))
			_fill_rect(image, Rect2i(node.x - 2 * scale, node.y - 2 * scale, 4 * scale, 4 * scale), outline)
			_circle(image, node, scale, Color8(88, 177, 240))
	elif lineage == "naamah":
		for tendril: int in range(3):
			var side: float = float(tendril - 1)
			var root_v: Vector2 = Vector2(torso.get_center()) - facing * float(4 * scale) + perp * side * float(3 * scale)
			var tip_v: Vector2 = root_v - facing * float((8 + tendril * 2) * scale) + perp * sin(float(action + tendril)) * float(3 * scale)
			_line(image, Vector2i(roundi(root_v.x), roundi(root_v.y)), Vector2i(roundi(tip_v.x), roundi(tip_v.y)), outline, 3 * scale)
			_line(image, Vector2i(roundi(root_v.x), roundi(root_v.y)), Vector2i(roundi(tip_v.x), roundi(tip_v.y)), Color8(123, 62, 149), scale)
	elif category == "fallen":
		for side_variant in [-1, 1]:
			var side: int = int(side_variant)
			var wing_root_v: Vector2 = Vector2(torso.get_center()) + perp * float(side * 6 * scale) - facing * float(3 * scale)
			var wing_tip_v: Vector2 = wing_root_v + perp * float(side * 8 * scale) - facing * float((8 + action * 2) * scale)
			_line(image, Vector2i(roundi(wing_root_v.x), roundi(wing_root_v.y)), Vector2i(roundi(wing_tip_v.x), roundi(wing_tip_v.y)), outline, 4 * scale)
			_line(image, Vector2i(roundi(wing_root_v.x), roundi(wing_root_v.y)), Vector2i(roundi(wing_tip_v.x), roundi(wing_tip_v.y)), accent.darkened(0.18), 2 * scale)
	elif category == "nephilim" or silhouette.find("husk") >= 0:
		for horn_side_variant in [-1, 1]:
			var horn_side: int = int(horn_side_variant)
			_line(image, head + Vector2i(horn_side * 4 * scale, -4 * scale), head + Vector2i(horn_side * 9 * scale, -11 * scale), outline, 3 * scale)

	if action == 3:
		var trail_start_v: Vector2 = Vector2(torso.get_center()) - facing * float(6 * scale)
		for trail_index: int in range(2):
			var trail_end_v: Vector2 = trail_start_v - facing * float((10 + trail_index * 6) * scale) + perp * float((trail_index * 2 - 1) * scale)
			_line(image, Vector2i(roundi(trail_start_v.x), roundi(trail_start_v.y)), Vector2i(roundi(trail_end_v.x), roundi(trail_end_v.y)), Color(accent, 0.72), 2 * scale)

func _draw_orbiter(image: Image, center: Vector2i, direction: Vector2, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var facing: Vector2 = direction.normalized()
	if facing.length_squared() < 0.01:
		facing = Vector2.DOWN
	var perp: Vector2 = Vector2(-facing.y, facing.x)
	var silhouette: String = String(genome.get("silhouette_key", "role_orbiter"))
	var action: int = clampi(frame_index, 0, 3)
	var hover: int = -1 if action in [0, 2] else 1
	var core: Vector2i = center + Vector2i(0, hover * scale)
	_fill_ellipse(image, core + Vector2i(0, 8 * scale), 11 * scale, 3 * scale, Color(0, 0, 0, 0.30))

	if silhouette.find("ophanim") >= 0:
		_circle(image, core, 13 * scale, outline, false)
		_circle(image, core, 9 * scale, secondary, false)
		_circle(image, core + Vector2i(roundi(facing.x * 5.0 * scale), roundi(facing.y * 5.0 * scale)), 3 * scale, accent)
		for ring_arm: int in range(4):
			var ring_angle: float = TAU * float(ring_arm) / 4.0 + float(action) * 0.18
			var inner: Vector2i = core + Vector2i(roundi(cos(ring_angle) * 8.0 * scale), roundi(sin(ring_angle) * 8.0 * scale))
			var outer: Vector2i = core + Vector2i(roundi(cos(ring_angle) * 16.0 * scale), roundi(sin(ring_angle) * 16.0 * scale))
			_line(image, inner, outer, outline, 3 * scale)
		return

	if silhouette.find("serpent") >= 0:
		var previous: Vector2i = core + Vector2i(roundi(facing.x * 7.0 * scale), roundi(facing.y * 7.0 * scale))
		for segment: int in range(6):
			var sway: float = sin(float(segment) * 0.9 + float(action) * 0.8) * 4.0 * float(scale)
			var point_v: Vector2 = Vector2(core) - facing * float(segment * 5 * scale) + perp * sway
			var point: Vector2i = Vector2i(roundi(point_v.x), roundi(point_v.y))
			if segment > 0:
				_line(image, previous, point, outline, 6 * scale)
				_line(image, previous, point, primary, 3 * scale)
			previous = point
		_circle(image, core + Vector2i(roundi(facing.x * 7.0 * scale), roundi(facing.y * 7.0 * scale)), 4 * scale, accent)
		return

	# Cherub/drone silhouette: small armored core with wide wing blades and halo.
	_fill_rect(image, Rect2i(core.x - 6 * scale, core.y - 5 * scale, 12 * scale, 10 * scale), outline)
	_fill_rect(image, Rect2i(core.x - 4 * scale, core.y - 3 * scale, 8 * scale, 6 * scale), primary)
	_circle(image, core - Vector2i(0, 7 * scale), 7 * scale, Color8(232, 197, 85), false)
	var eye: Vector2i = core + Vector2i(roundi(facing.x * 4.0 * scale), roundi(facing.y * 3.0 * scale))
	_circle(image, eye, 2 * scale, accent)
	for wing_side_variant in [-1, 1]:
		var wing_side: int = int(wing_side_variant)
		var root_v: Vector2 = Vector2(core) + perp * float(wing_side * 6 * scale)
		var wing_length: float = float((10 + (2 if action == 1 else 0)) * scale)
		var tip_v: Vector2 = root_v - facing * float(3 * scale) + perp * float(wing_side) * wing_length
		_line(image, Vector2i(roundi(root_v.x), roundi(root_v.y)), Vector2i(roundi(tip_v.x), roundi(tip_v.y)), outline, 5 * scale)
		_line(image, Vector2i(roundi(root_v.x), roundi(root_v.y)), Vector2i(roundi(tip_v.x), roundi(tip_v.y)), secondary, 2 * scale)
	if action == 2:
		var shot_v: Vector2 = Vector2(core) + facing * float(12 * scale)
		_circle(image, Vector2i(roundi(shot_v.x), roundi(shot_v.y)), 3 * scale, Color8(255, 216, 104))

func _draw_radial(image: Image, center: Vector2i, direction: Vector2, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var facing: Vector2 = direction.normalized()
	if facing.length_squared() < 0.01:
		facing = Vector2.DOWN
	var action: int = clampi(frame_index, 0, 3)
	var core: Vector2i = center + Vector2i(0, (-1 if action == 0 else 0) * scale)
	_fill_ellipse(image, core + Vector2i(0, 9 * scale), 14 * scale, 4 * scale, Color(0, 0, 0, 0.34))
	_circle(image, core, 13 * scale, outline)
	_circle(image, core, 10 * scale, primary)
	_fill_rect(image, Rect2i(core.x - 5 * scale, core.y - 3 * scale, 10 * scale, 6 * scale), secondary)
	var arms: int = 6
	for arm_index: int in range(arms):
		var angle: float = TAU * float(arm_index) / float(arms) + float(action) * 0.10
		var inner: Vector2i = core + Vector2i(roundi(cos(angle) * 9.0 * scale), roundi(sin(angle) * 9.0 * scale))
		var outer_radius: float = 18.0 if action == 2 else 15.0
		var outer: Vector2i = core + Vector2i(roundi(cos(angle) * outer_radius * scale), roundi(sin(angle) * outer_radius * scale))
		_line(image, inner, outer, outline, 3 * scale)
		if action == 2:
			_circle(image, outer, scale, accent)
	var facing_node: Vector2i = core + Vector2i(roundi(facing.x * 11.0 * scale), roundi(facing.y * 11.0 * scale))
	_circle(image, facing_node, 3 * scale, accent)

func audit_contract() -> Dictionary:
	var report: Dictionary = super.audit_contract()
	report["art4_forge_version"] = ART4_FORGE_VERSION
	report["pose_first_frames"] = true
	report["idle_move_attack_special_states"] = true
	report["expressive_arms_and_weapons"] = true
	report["hero_specific_head_and_gear_language"] = true
	report["curated_family_body_language"] = true
	report["muzzle_flash_frames"] = true
	report["dash_trail_frames"] = true
	report["commercial_readability_target"] = true
	return report
