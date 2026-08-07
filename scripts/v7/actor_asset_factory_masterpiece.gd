extends "res://scripts/v6/actor_asset_factory_rebuild.gd"

const ART_REVISION := "0.6.1-rc7"

func _hero_frame(id: String, direction_index: int, action: String, frame: int) -> Image:
	var image: Image = super._hero_frame(id, direction_index, action, frame)
	_finish_pixel_frame(image, hash("hero:" + id), frame, 0.10)
	return image

func _enemy_frame(id: String, direction_index: int, action: String, frame: int) -> Image:
	var image: Image = super._enemy_frame(id, direction_index, action, frame)
	_finish_pixel_frame(image, hash("enemy:" + id), frame, 0.12)
	return image

func _boss_frame(id: String, direction_index: int, action: int, frame: int) -> Image:
	var image: Image = super._boss_frame(id, direction_index, action, frame)
	_finish_pixel_frame(image, hash("boss:" + id), frame, 0.08)
	return image

func build_portrait(id: String) -> Image:
	var image: Image = super.build_portrait(id)
	_apply_portrait_finish(image, hash("portrait:" + id))
	return image

func _finish_pixel_frame(image: Image, salt: int, frame: int, texture_strength: float) -> void:
	if image == null or image.is_empty():
		return
	_apply_material_variation(image, salt + frame * 131, texture_strength)
	_apply_selective_rim(image)
	_apply_hard_outline(image)

func _apply_material_variation(image: Image, salt: int, strength: float) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < 0.88:
				continue
			var luminance := (color.r + color.g + color.b) / 3.0
			if luminance < 0.10:
				continue
			var pattern := posmod(x * 19 + y * 31 + salt, 37)
			if pattern == 0:
				image.set_pixel(x, y, color.lightened(strength * 0.55))
			elif pattern == 1:
				image.set_pixel(x, y, color.darkened(strength * 0.42))

func _apply_selective_rim(image: Image) -> void:
	var source := image.duplicate() as Image
	if source == null:
		return
	for y in range(1, image.get_height() - 1):
		for x in range(1, image.get_width() - 1):
			var color := source.get_pixel(x, y)
			if color.a < 0.82:
				continue
			var exposed := source.get_pixel(x - 1, y).a < 0.10 or source.get_pixel(x, y - 1).a < 0.10
			if not exposed:
				continue
			var luminance := (color.r + color.g + color.b) / 3.0
			if luminance < 0.12:
				continue
			var highlight := Color(0.93, 0.86, 0.68, color.a)
			image.set_pixel(x, y, color.lerp(highlight, 0.09))

func _apply_hard_outline(image: Image) -> void:
	var source := image.duplicate() as Image
	if source == null:
		return
	var outline := Color(0.018, 0.022, 0.024, 0.92)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if source.get_pixel(x, y).a > 0.08:
				continue
			var adjacent := false
			for offset in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,1)]:
				var sample := Vector2i(x, y) + offset
				if sample.x < 0 or sample.y < 0 or sample.x >= source.get_width() or sample.y >= source.get_height():
					continue
				if source.get_pixel(sample.x, sample.y).a > 0.62:
					adjacent = true
					break
			if adjacent:
				image.set_pixel(x, y, outline)

func _apply_portrait_finish(image: Image, salt: int) -> void:
	if image == null or image.is_empty():
		return
	for y in range(18, image.get_height() - 18):
		for x in range(18, image.get_width() - 18):
			var color := image.get_pixel(x, y)
			if color.a < 0.90:
				continue
			var pattern := posmod(x * 11 + y * 17 + salt, 83)
			if pattern == 0:
				image.set_pixel(x, y, color.lightened(0.035))
			elif pattern == 1:
				image.set_pixel(x, y, color.darkened(0.025))
