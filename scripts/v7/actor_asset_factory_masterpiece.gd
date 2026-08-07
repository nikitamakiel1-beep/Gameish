extends "res://scripts/v6/actor_asset_factory_rebuild.gd"

const ART_REVISION := "0.6.1-rc7"
const OUTLINE_OFFSETS := [
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
	_finish_pixel_frame(image, hash("boss:" + id) + frame * 131, 0.08)
	return image

func build_portrait(id: String) -> Image:
	var image: Image = super.build_portrait(id)
	_apply_portrait_finish(image, hash("portrait:" + id))
	return image

func _finish_pixel_frame(image: Image, salt: int, texture_strength: float) -> void:
	if image == null or image.is_empty():
		return
	var source := image.duplicate() as Image
	if source == null:
		return
	var outline := Color(0.018, 0.022, 0.024, 0.92)
	var highlight := Color(0.93, 0.86, 0.68, 1.0)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var source_color := source.get_pixel(x, y)
			if source_color.a <= 0.08:
				if _has_solid_neighbor(source, Vector2i(x, y)):
					image.set_pixel(x, y, outline)
				continue
			var output_color := source_color
			var luminance := (source_color.r + source_color.g + source_color.b) / 3.0
			if source_color.a >= 0.88 and luminance >= 0.10:
				var pattern := posmod(x * 19 + y * 31 + salt, 37)
				if pattern == 0:
					output_color = output_color.lightened(texture_strength * 0.55)
				elif pattern == 1:
					output_color = output_color.darkened(texture_strength * 0.42)
			if source_color.a >= 0.82 and luminance >= 0.12 and _is_upper_left_exposed(source, x, y):
				var rim := Color(highlight.r, highlight.g, highlight.b, output_color.a)
				output_color = output_color.lerp(rim, 0.09)
			image.set_pixel(x, y, output_color)

func _has_solid_neighbor(source: Image, point: Vector2i) -> bool:
	for offset in OUTLINE_OFFSETS:
		var sample := point + offset
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
