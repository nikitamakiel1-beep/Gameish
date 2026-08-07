extends RefCounted

const VERSION := 8
const REPRESENTATIVE_FRAMES: Array[int] = [0, 2, 4, 6]

func evaluate_actor(texture: Texture2D, frame_size: Vector2i, minimum_bbox: Vector2i, minimum_unique_directions: int = 4) -> Dictionary:
	if texture == null:
		return {"passed":false, "reason":"missing texture"}
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return {"passed":false, "reason":"empty image"}
	if frame_size.x <= 0 or frame_size.y <= 0:
		return {"passed":false, "reason":"invalid frame size"}
	var frames_per_row: int = image.get_width() / frame_size.x
	var total_rows: int = image.get_height() / frame_size.y
	var action_rows: int = total_rows / 8
	if frames_per_row < 1 or action_rows < 1:
		return {"passed":false, "reason":"atlas smaller than one 8-direction action"}

	var occupancy_total := 0.0
	var bbox_width_total := 0.0
	var bbox_height_total := 0.0
	var silhouettes: Dictionary = {}
	var sampled_actions: Dictionary = {}

	for direction in range(8):
		var best_metrics: Dictionary = {}
		var best_score := -1.0
		var best_action := 0
		for action_index in range(action_rows):
			for frame_index in REPRESENTATIVE_FRAMES:
				if frame_index >= frames_per_row:
					continue
				var origin := Vector2i(frame_index * frame_size.x, (action_index * 8 + direction) * frame_size.y)
				var metrics := _frame_metrics(image, origin, frame_size)
				var bbox_area := float(int(metrics.get("bbox_width",0)) * int(metrics.get("bbox_height",0)))
				var score := bbox_area + float(metrics.get("occupancy",0.0)) * 1000.0
				if score > best_score:
					best_score = score
					best_metrics = metrics
					best_action = action_index
		if best_metrics.is_empty():
			continue
		occupancy_total += float(best_metrics.get("occupancy", 0.0))
		bbox_width_total += float(best_metrics.get("bbox_width", 0))
		bbox_height_total += float(best_metrics.get("bbox_height", 0))
		silhouettes[int(best_metrics.get("silhouette_hash", 0))] = true
		sampled_actions[best_action] = true

	var average_occupancy := occupancy_total / 8.0
	var average_width := bbox_width_total / 8.0
	var average_height := bbox_height_total / 8.0
	var occupancy_ok := average_occupancy >= 0.075 and average_occupancy <= 0.68
	var bbox_ok := average_width >= float(minimum_bbox.x) and average_height >= float(minimum_bbox.y)
	var directions_ok := silhouettes.size() >= minimum_unique_directions
	var passed := occupancy_ok and bbox_ok and directions_ok
	var reasons: Array[String] = []
	if not occupancy_ok: reasons.append("occupancy %.4f outside [0.075,0.68]" % average_occupancy)
	if not bbox_ok: reasons.append("bbox %.1fx%.1f below %dx%d" % [average_width,average_height,minimum_bbox.x,minimum_bbox.y])
	if not directions_ok: reasons.append("only %d unique directional silhouettes; need %d" % [silhouettes.size(),minimum_unique_directions])
	return {
		"passed": passed,
		"reason": "; ".join(reasons),
		"occupancy": average_occupancy,
		"bbox_width": average_width,
		"bbox_height": average_height,
		"unique_direction_silhouettes": silhouettes.size(),
		"action_rows": action_rows,
		"sampled_action_rows": sampled_actions.size(),
		"representative_frames": REPRESENTATIVE_FRAMES,
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
		"multi_action_sampling": true,
		"representative_frames": REPRESENTATIVE_FRAMES,
		"occupancy_gate": true,
		"silhouette_bbox_gate": true,
		"directional_variation_gate": true,
	}
