extends "res://scripts/v8/procedural_sprite_forge_authored.gd"

const PREMIUM_FORGE_VERSION: String = "0.6.2-entropy-art2"

func _draw_humanoid(image: Image, center: Vector2i, direction: Vector2, stride: int, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, skin: Color, outline: Color, scale: int) -> void:
	super._draw_humanoid(image, center, direction, stride, frame_index, genome, primary, secondary, accent, skin, outline, scale)
	var category: String = String(genome.get("category", "preadamic"))
	var lineage: String = String(genome.get("lineage", ""))
	var perp: Vector2 = Vector2(-direction.y, direction.x)
	var chest: Vector2i = center - Vector2i(0, 18 * scale)
	match category:
		"fallen": _draw_fallen_signature(image, chest, direction, perp, frame_index, accent, outline, scale)
		"nephilim": _draw_nephilim_signature(image, chest, direction, perp, genome, accent, outline, scale)
		"guardian": _draw_guardian_signature(image, chest, direction, perp, frame_index, accent, outline, scale)
		_:
			_draw_preadamic_signature(image, chest, perp, genome, secondary, accent, outline, scale)
	if not lineage.is_empty():
		_draw_lineage_signature(image, lineage, chest, direction, perp, frame_index, accent, outline, scale)

func _draw_fallen_signature(image: Image, chest: Vector2i, direction: Vector2, perp: Vector2, frame_index: int, accent: Color, outline: Color, scale: int) -> void:
	var halo: Vector2i = chest - Vector2i(0, 17 * scale)
	_circle(image, halo, (7 + frame_index % 2) * scale, outline, false)
	_circle(image, halo, 6 * scale, Color(accent, 0.78), false)
	for side_variant in [-1, 1]:
		var side: int = int(side_variant)
		var root: Vector2i = chest + Vector2i(roundi(perp.x * side * 8.0 * scale), roundi(perp.y * side * 8.0 * scale))
		var tip: Vector2i = root + Vector2i(roundi((-direction.x * 8.0 + perp.x * side * 11.0) * scale), roundi((-direction.y * 8.0 + perp.y * side * 11.0) * scale))
		_line(image, root, tip, outline, 4 * scale)
		_line(image, root, tip, Color(accent, 0.72), 2 * scale)

func _draw_nephilim_signature(image: Image, chest: Vector2i, direction: Vector2, perp: Vector2, genome: Dictionary, accent: Color, outline: Color, scale: int) -> void:
	var graft_count: int = 2 + clampi(int(genome.get("horns", 1)), 1, 3)
	for graft: int in range(graft_count):
		var side: int = -1 if graft % 2 == 0 else 1
		var root: Vector2i = chest + Vector2i(roundi(perp.x * side * float(7 + graft) * scale), roundi(perp.y * side * float(7 + graft) * scale)) - Vector2i(0, graft * scale)
		var tip: Vector2i = root + Vector2i(roundi((-direction.x * 4.0 + perp.x * side * 8.0) * scale), roundi((-direction.y * 4.0 + perp.y * side * 8.0) * scale)) - Vector2i(0, 5 * scale)
		_line(image, root, tip, outline, 3 * scale)
		_line(image, root, tip, accent.darkened(0.18), scale)

func _draw_guardian_signature(image: Image, chest: Vector2i, direction: Vector2, perp: Vector2, frame_index: int, accent: Color, outline: Color, scale: int) -> void:
	for side_variant in [-1, 1]:
		var side: int = int(side_variant)
		var node: Vector2i = chest + Vector2i(roundi(perp.x * side * 10.0 * scale), roundi(perp.y * side * 10.0 * scale))
		_circle(image, node, 3 * scale, outline)
		_circle(image, node, (1 + frame_index % 2) * scale, accent)
	var rear: Vector2i = chest - Vector2i(roundi(direction.x * 8.0 * scale), roundi(direction.y * 8.0 * scale))
	_fill_rect(image, Rect2i(rear.x - 3 * scale, rear.y - 4 * scale, 6 * scale, 8 * scale), outline)
	_circle(image, rear, 2 * scale, accent.darkened(0.16))

func _draw_preadamic_signature(image: Image, chest: Vector2i, perp: Vector2, genome: Dictionary, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var side: int = -1 if float(genome.get("asymmetry", 0.0)) < 0.0 else 1
	var plate: Vector2i = chest + Vector2i(roundi(perp.x * side * 9.0 * scale), roundi(perp.y * side * 9.0 * scale))
	_fill_rect(image, Rect2i(plate.x - 4 * scale, plate.y - 5 * scale, 8 * scale, 10 * scale), outline)
	_fill_rect(image, Rect2i(plate.x - 3 * scale, plate.y - 4 * scale, 6 * scale, 8 * scale), secondary.darkened(0.20))
	_line(image, plate - Vector2i(3 * scale, 2 * scale), plate + Vector2i(3 * scale, 2 * scale), Color(accent, 0.62), scale)

func _draw_lineage_signature(image: Image, lineage: String, chest: Vector2i, direction: Vector2, perp: Vector2, frame_index: int, accent: Color, outline: Color, scale: int) -> void:
	match lineage:
		"adam":
			for side_variant in [-1, 1]:
				var side: int = int(side_variant)
				var root: Vector2i = chest + Vector2i(roundi(perp.x * side * 8.0 * scale), roundi(perp.y * side * 8.0 * scale))
				var leaf: Vector2i = root - Vector2i(0, 10 * scale) + Vector2i(side * 3 * scale, 0)
				_line(image, root, leaf, Color(0.28, 0.67, 0.36, 0.90), 2 * scale)
				_circle(image, leaf, 2 * scale, Color(0.47, 0.82, 0.49, 0.86))
		"abel":
			var halo: Vector2i = chest - Vector2i(0, 20 * scale)
			_circle(image, halo, 8 * scale, outline, false)
			_circle(image, halo, 7 * scale, Color(0.96, 0.80, 0.39, 0.84), false)
			var staff_tip: Vector2i = chest + Vector2i(roundi(direction.x * 20.0 * scale), roundi(direction.y * 20.0 * scale))
			_circle(image, staff_tip, 3 * scale, Color(0.96, 0.83, 0.51, 0.92))
		"cain":
			var pack: Vector2i = chest - Vector2i(roundi(direction.x * 10.0 * scale), roundi(direction.y * 10.0 * scale))
			_fill_rect(image, Rect2i(pack.x - 6 * scale, pack.y - 6 * scale, 12 * scale, 12 * scale), outline)
			_fill_rect(image, Rect2i(pack.x - 4 * scale, pack.y - 4 * scale, 8 * scale, 8 * scale), Color(0.42, 0.045, 0.065, 1.0))
			_circle(image, pack, 2 * scale, Color(1.0, 0.20, 0.16, 0.94))
			for side_variant in [-1, 1]:
				var side: int = int(side_variant)
				var rail: Vector2i = chest + Vector2i(roundi(perp.x * side * 6.0 * scale), roundi(perp.y * side * 6.0 * scale))
				var rail_tip: Vector2i = rail + Vector2i(roundi(direction.x * 22.0 * scale), roundi(direction.y * 22.0 * scale))
				_line(image, rail, rail_tip, Color(0.94, 0.16, 0.13, 0.84), 2 * scale)
		"seth":
			for side_variant in [-1, 1]:
				var side: int = int(side_variant)
				var node: Vector2i = chest + Vector2i(roundi(perp.x * side * 11.0 * scale), roundi(perp.y * side * 11.0 * scale))
				_fill_rect(image, Rect2i(node.x - 4 * scale, node.y - 4 * scale, 8 * scale, 8 * scale), outline)
				_circle(image, node, 2 * scale, Color(0.34, 0.68, 0.96, 0.92))
		"naamah":
			for bud: int in range(5):
				var angle: float = TAU * float(bud) / 5.0 + float(frame_index) * 0.10
				var p: Vector2i = chest + Vector2i(roundi(cos(angle) * 10.0 * scale), roundi(sin(angle) * 7.0 * scale)) - Vector2i(0, 4 * scale)
				_circle(image, p, 2 * scale, Color(0.80, 0.31, 0.88, 0.86))
		_:
			pass

func audit_contract() -> Dictionary:
	var report: Dictionary = super.audit_contract()
	report["premium_forge_version"] = PREMIUM_FORGE_VERSION
	report["role_morphology"] = true
	report["category_morphology"] = true
	report["lineage_silhouette_signatures"] = true
	report["cain_heavy_cannon_signature"] = true
	report["authored_template_core"] = true
	return report
