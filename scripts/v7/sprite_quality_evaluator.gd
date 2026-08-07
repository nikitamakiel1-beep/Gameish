extends RefCounted

const VERSION := 7

func evaluate_actor(texture: Texture2D, frame_size: Vector2i, minimum_bbox: Vector2i, minimum_unique_directions: int = 4) -> Dictionary:
	if texture == null:
		return {"passed":false, "reason":"missing texture"}
	var image := texture.get_image()
	if image == null or image.is_empty():
		return {"passed":false, "reason":"empty image"}
	var occupancy_total := 0.0
	var bbox_width_total := 0.0
	var bbox_height_total := 0.0
	var silhouettes: Dictionary = {}
	for direction in range(8):
		var origin := Vector2i(0, direction * frame_size.y)
		var metrics := _frame_metrics(image, origin, frame_size)
		occupancy_total += float(metrics.get("occupancy", 0.0))
		bbox_width_total += float(metrics.get("bbox_width", 0))
		bbox_height_total += float(metrics.get("bbox_height", 0))
		silhouettes[int(metrics.get("silhouette_hash", 0))] = true
	var average_occupancy := occupancy_total / 8.0
	var average_width := bbox_width_total / 8.0
	var average_height := bbox_height_total / 8.0
	var passed := average_occupancy >= 0.075 and average_occupancy <= 0.68
	passed = passed and average_width >= float(minimum_bbox.x) and average_height >= float(minimum_bbox.y)
	passed = passed and silhouettes.size() >= minimum_unique_directions
	return {
		"passed": passed,
		"occupancy": average_occupancy,
		"bbox_width": average_width,
		"bbox_height": average_height,
		"unique_direction_silhouettes": silhouettes.size(),
	}

func _frame_metrics(image: Image, origin: Vector2i, frame_size: Vector2i) -> Dictionary:
	var min_x := frame_size.x
	var min_y := frame_size.y
	var max_x := -1
	var max_y := -1
	var occupied := 0
	var mask := PackedByteArray()
	mask.resize(frame_size.x * frame_size.y)
	var cursor := 0
	for y in range(frame_size.y):
		for x in range(frame_size.x):
			var source_x := origin.x + x
			var source_y := origin.y + y
			var solid := false
			if source_x >= 0 and source_y >= 0 and source_x < image.get_width() and source_y < image.get_height():
				solid = image.get_pixel(source_x, source_y).a > 0.10
			mask[cursor] = 1 if solid else 0
			cursor += 1
			if not solid:
				continue
			occupied += 1
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	var bbox_width := 0 if max_x < min_x else max_x - min_x + 1
	var bbox_height := 0 if max_y < min_y else max_y - min_y + 1
	return {
		"occupancy": float(occupied) / float(maxi(1, frame_size.x * frame_size.y)),
		"bbox_width": bbox_width,
		"bbox_height": bbox_height,
		"silhouette_hash": hash(mask),
	}

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"direction_samples": 8,
		"occupancy_gate": true,
		"silhouette_bbox_gate": true,
		"directional_variation_gate": true,
	}
