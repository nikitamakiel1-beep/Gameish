extends RefCounted

func blank(width: int, height: int) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	return image

func alpha(color: Color, value: float) -> Color:
	return Color(color.r, color.g, color.b, value)

func fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(maxi(0, rect.position.y), mini(image.get_height(), rect.end.y)):
		for x in range(maxi(0, rect.position.x), mini(image.get_width(), rect.end.x)):
			image.set_pixel(x, y, color)

func line(image: Image, start: Vector2i, finish: Vector2i, color: Color, width: int = 1) -> void:
	var steps := maxi(absi(finish.x - start.x), absi(finish.y - start.y))
	var half := int(width / 2)
	for index in range(steps + 1):
		var ratio := float(index) / float(maxi(1, steps))
		var point := Vector2i(
			roundi(lerpf(float(start.x), float(finish.x), ratio)),
			roundi(lerpf(float(start.y), float(finish.y), ratio))
		)
		fill_rect(image, Rect2i(point - Vector2i(half, half), Vector2i(width, width)), color)

func circle(image: Image, center: Vector2i, radius: int, color: Color, filled: bool = true, vertical_scale: int = 1) -> void:
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

func cross(image: Image, center: Vector2i, color: Color, radius: int) -> void:
	for offset in range(-radius, radius + 1):
		if center.x + offset >= 0 and center.x + offset < image.get_width() and center.y >= 0 and center.y < image.get_height():
			image.set_pixel(center.x + offset, center.y, color)
		if center.y + offset >= 0 and center.y + offset < image.get_height() and center.x >= 0 and center.x < image.get_width():
			image.set_pixel(center.x, center.y + offset, color)

func border(image: Image, rect: Rect2i, color: Color) -> void:
	line(image, rect.position, Vector2i(rect.end.x - 1, rect.position.y), color)
	line(image, Vector2i(rect.position.x, rect.end.y - 1), rect.end - Vector2i.ONE, color)
	line(image, rect.position, Vector2i(rect.position.x, rect.end.y - 1), color)
	line(image, Vector2i(rect.end.x - 1, rect.position.y), rect.end - Vector2i.ONE, color)

func tint(image: Image, tint_color: Color, strength: float) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var current := image.get_pixel(x, y)
			if current.a > 0.0:
				image.set_pixel(x, y, current.lerp(alpha(tint_color, current.a), strength))

func collapse(image: Image, frame: int) -> Image:
	var bounds := image.get_used_rect()
	if bounds.size == Vector2i.ZERO:
		return image
	var sprite := image.get_region(bounds)
	var target_height := maxi(8, int(float(sprite.get_height()) * maxf(0.22, 1.0 - float(frame - 1) * 0.11)))
	sprite.resize(sprite.get_width(), target_height, Image.INTERPOLATE_NEAREST)
	var result := blank(image.get_width(), image.get_height())
	result.blend_rect(
		sprite,
		Rect2i(Vector2i.ZERO, sprite.get_size()),
		Vector2i((result.get_width() - sprite.get_width()) / 2, result.get_height() - sprite.get_height() - 2)
	)
	return result

func shadow(image: Image, center: Vector2i, radius: int = 10) -> void:
	circle(image, center, radius, Color(0.0, 0.0, 0.0, 0.30), true, 2)

func wings(image: Image, center: Vector2i, color: Color, span: int) -> void:
	for side in [-1, 1]:
		var root := center + Vector2i(side * 5, -2)
		for feather in range(4):
			var finish := center + Vector2i(side * (span - feather * 3), -10 + feather * 7)
			line(image, root, finish, Color8(28, 26, 27), 5)
			line(image, root, finish, color, 2)
