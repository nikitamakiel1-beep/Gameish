extends "res://scripts/v6/actor_asset_factory.gd"

const ART_REVISION: String = "0.6.1-rc7"
const OUTLINE_OFFSETS: Array[Vector2i] = [
	Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1),
	Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,1),
]

func _hero_frame(id: String, direction_index: int, action: String, frame: int) -> Image:
	var image: Image = super._hero_frame(id, direction_index, action, frame)
	_finish_pixel_frame(image, hash("hero:" + id) + frame * 131, 0.10)
	return image

func _enemy_frame(id: String, direction_index: int, action: String, frame: int) -> Image:
	var image: Image = super._enemy_frame(id, direction_index, action, frame)
	_finish_pixel_frame(image, hash("enemy:" + id) + frame * 131, 0.12)
	return image

func _boss_frame(id: String, direction_index: int, action: int, frame: int) -> Image:
	var image: Image = super._boss_frame(id, direction_index, action, frame)
	# Guardians must communicate facing before their attack animation starts. The
	# V6 substrate is deliberately monumental/radial, so RC7 adds a persistent
	# asymmetric directional feature unique to each guardian family.
	if not (action == 3 and frame >= 2):
		_draw_guardian_direction_signature(image, id, direction_index, frame)
	_finish_pixel_frame(image, hash("boss:" + id) + frame * 131, 0.08)
	return image

func _draw_guardian_direction_signature(image: Image, id: String, direction_index: int, frame: int) -> void:
	if image == null or image.is_empty():
		return
	var safe_direction_index: int = clampi(direction_index, 0, 7)
	var direction: Vector2 = Vector2(DIRECTIONS[safe_direction_index]).normalized()
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	var center: Vector2i = Vector2i(48, 50)
	var outline: Color = Color8(20, 21, 23)
	var accent: Color = Color8(232, 192, 96)
	match id:
		"watcher_engine":
			accent = Color8(190, 120, 255)
			var boom_root: Vector2i = center + _scaled_vec(direction, 15.0)
			var boom_tip: Vector2i = center + _scaled_vec(direction, 39.0)
			line(image, boom_root, boom_tip, outline, 7)
			line(image, boom_root, boom_tip, accent, 3)
			circle(image, boom_tip, 6, outline)
			circle(image, boom_tip, 3 + frame % 2, accent)
			var dish: Vector2i = boom_root + _scaled_vec(perpendicular, 7.0)
			line(image, boom_root, dish, accent, 3)
		"first_nephilim":
			accent = Color8(245, 65, 54)
			var shoulder: Vector2i = center + _scaled_vec(perpendicular, 12.0) - Vector2i(0, 10)
			var blade_tip: Vector2i = center + _scaled_vec(direction, 38.0) + _scaled_vec(perpendicular, 7.0)
			line(image, shoulder, blade_tip, outline, 9)
			line(image, shoulder, blade_tip, accent.darkened(0.14), 5)
			var horn_tip: Vector2i = center + _scaled_vec(direction, 25.0) - Vector2i(0, 23)
			line(image, center - Vector2i(0, 13), horn_tip, outline, 5)
			line(image, center - Vector2i(0, 13), horn_tip, accent, 2)
		"gate_cherub":
			accent = Color8(255, 210, 90)
			var lance_root: Vector2i = center - _scaled_vec(direction, 5.0)
			var lance_tip: Vector2i = center + _scaled_vec(direction, 42.0)
			line(image, lance_root, lance_tip, outline, 7)
			line(image, lance_root, lance_tip, accent, 3)
			var cross_a: Vector2i = lance_tip + _scaled_vec(perpendicular, 7.0) - _scaled_vec(direction, 6.0)
			var cross_b: Vector2i = lance_tip - _scaled_vec(perpendicular, 7.0) - _scaled_vec(direction, 6.0)
			line(image, cross_a, cross_b, accent, 3)
			circle(image, center + _scaled_vec(direction, 11.0), 5, Color(1.0, 0.96, 0.72, 0.82), false)
		"tower_enoch":
			accent = Color8(190, 80, 230)
			var emitter_base: Vector2i = center + _scaled_vec(direction, 18.0)
			var emitter_tip: Vector2i = center + _scaled_vec(direction, 39.0)
			fill_rect(image, Rect2i(emitter_base - Vector2i(6, 6), Vector2i(12, 12)), outline)
			circle(image, emitter_base, 4, accent.darkened(0.15))
			line(image, emitter_base, emitter_tip, outline, 8)
			line(image, emitter_base, emitter_tip, accent, 3)
			for side: int in [-1, 1]:
				var prong_start: Vector2i = emitter_tip - _scaled_vec(direction, 5.0)
				var prong_tip: Vector2i = emitter_tip + _scaled_vec(perpendicular, float(side) * 7.0)
				line(image, prong_start, prong_tip, accent, 3)
		"serpent_interface":
			accent = Color8(160, 225, 65)
			var neck: Vector2i = center + _scaled_vec(direction, 20.0)
			var head: Vector2i = center + _scaled_vec(direction, 35.0)
			line(image, center, neck, outline, 11)
			line(image, center, neck, accent.darkened(0.27), 6)
			circle(image, head, 8, outline)
			circle(image, head, 5, accent.darkened(0.10))
			var eye: Vector2i = head + _scaled_vec(direction, 3.0)
			circle(image, eye, 2, Color8(244, 248, 203))
			for side: int in [-1, 1]:
				var crest_root: Vector2i = head - _scaled_vec(direction, 4.0)
				var crest_tip: Vector2i = head - _scaled_vec(direction, 9.0) + _scaled_vec(perpendicular, float(side) * 9.0)
				line(image, crest_root, crest_tip, outline, 4)
				line(image, crest_root, crest_tip, accent, 2)
		_:
			var generic_tip: Vector2i = center + _scaled_vec(direction, 39.0)
			line(image, center, generic_tip, outline, 7)
			line(image, center, generic_tip, accent, 3)

func _scaled_vec(vector: Vector2, scale_value: float) -> Vector2i:
	return Vector2i(roundi(vector.x * scale_value), roundi(vector.y * scale_value))

func build_portrait(id: String) -> Image:
	var image: Image = super.build_portrait(id)
	_apply_portrait_finish(image, hash("portrait:" + id))
	return image

func _finish_pixel_frame(image: Image, salt: int, texture_strength: float) -> void:
	if image == null or image.is_empty():
		return
	var source: Image = image.duplicate() as Image
	if source == null:
		return
	var outline: Color = Color(0.018, 0.022, 0.024, 0.92)
	var highlight: Color = Color(0.93, 0.86, 0.68, 1.0)
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var source_color: Color = source.get_pixel(x, y)
			if source_color.a <= 0.08:
				if _has_solid_neighbor(source, Vector2i(x, y)):
					image.set_pixel(x, y, outline)
				continue
			var output_color: Color = source_color
			var luminance: float = (source_color.r + source_color.g + source_color.b) / 3.0
			if source_color.a >= 0.88 and luminance >= 0.10:
				var pattern: int = posmod(x * 19 + y * 31 + salt, 37)
				if pattern == 0:
					output_color = output_color.lightened(texture_strength * 0.55)
				elif pattern == 1:
					output_color = output_color.darkened(texture_strength * 0.42)
			if source_color.a >= 0.82 and luminance >= 0.12 and _is_upper_left_exposed(source, x, y):
				var rim: Color = Color(highlight.r, highlight.g, highlight.b, output_color.a)
				output_color = output_color.lerp(rim, 0.09)
			image.set_pixel(x, y, output_color)

func _has_solid_neighbor(source: Image, point: Vector2i) -> bool:
	for offset: Vector2i in OUTLINE_OFFSETS:
		var sample: Vector2i = point + offset
		if sample.x < 0 or sample.y < 0 or sample.x >= source.get_width() or sample.y >= source.get_height():
			continue
		if source.get_pixel(sample.x, sample.y).a > 0.62:
			return true
	return false

func _is_upper_left_exposed(source: Image, x: int, y: int) -> bool:
	if x <= 0 or y <= 0:
		return true
	return source.get_pixel(x - 1, y).a < 0.10 or source.get_pixel(x, y - 1).a < 0.10

func _apply_portrait_finish(image: Image, salt: int) -> void:
	if image == null or image.is_empty():
		return
	for y: int in range(18, image.get_height() - 18):
		for x: int in range(18, image.get_width() - 18):
			var color: Color = image.get_pixel(x, y)
			if color.a < 0.90:
				continue
			var pattern: int = posmod(x * 11 + y * 17 + salt, 83)
			if pattern == 0:
				image.set_pixel(x, y, color.lightened(0.035))
			elif pattern == 1:
				image.set_pixel(x, y, color.darkened(0.025))
