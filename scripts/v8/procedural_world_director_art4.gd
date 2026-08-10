extends "res://scripts/v8/procedural_world_director_art3.gd"

const ART4_WORLD_VERSION: String = "0.6.4-authored-art4"

const STORY_BEATS: Dictionary = {
	"industrial_eden":["failed_greenhouse","containment_breach","coolant_spill","sealed_gene_vault"],
	"ash_wastes":["burned_convoy","evacuation_lane","collapsed_checkpoint","reactor_crater"],
	"temple_lab":["archive_procession","ritual_terminal","choir_machine","sealed_sanctum"],
	"fungal_garden":["fruiting_nursery","spore_basin","root_cathedral","mycelial_well"],
	"nephilim_ruins":["buried_colossus","rib_causeway","broken_gate","monolith_grave"]
}

func make_room_recipe(rng: RandomNumberGenerator, biome_id: String, room_kind: String, threat: float, viewport_hint: Vector2 = Vector2(1600,900)) -> Dictionary:
	var recipe: Dictionary = super.make_room_recipe(rng, biome_id, room_kind, threat, viewport_hint)
	var beats: Array = STORY_BEATS.get(biome_id, STORY_BEATS["industrial_eden"])
	recipe["story_beat"] = String(beats[rng.randi_range(0, beats.size() - 1)])
	recipe["landmark_strength"] = rng.randf_range(0.62, 1.0)
	recipe["wall_damage"] = rng.randf_range(0.18, 0.82)
	recipe["light_pockets"] = rng.randi_range(2, 5)
	recipe["prop_clusters"] = rng.randi_range(2, 5)
	recipe["hazard_pockets"] = rng.randi_range(1, 4)
	recipe["art4_room_signature"] = "%s:%s:%08x" % [biome_id, String(recipe["story_beat"]), rng.randi()]
	return recipe

func build_floor_image(recipe: Dictionary, base_color: Color, accent: Color) -> Image:
	var image: Image = super.build_floor_image(recipe, base_color, accent)
	if image == null or image.is_empty():
		return image
	var biome: String = String(recipe.get("biome", "industrial_eden"))
	var local_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	local_rng.seed = int(recipe.get("large_form_seed", recipe.get("floor_noise_seed", 1))) ^ int(String(recipe.get("story_beat", "story")).hash())
	var strength: float = clampf(float(recipe.get("landmark_strength", 0.75)), 0.4, 1.0)
	match biome:
		"industrial_eden": _art4_industrial(image, local_rng, base_color, accent, strength)
		"ash_wastes": _art4_ash(image, local_rng, base_color, accent, strength)
		"temple_lab": _art4_temple(image, local_rng, base_color, accent, strength)
		"fungal_garden": _art4_fungal(image, local_rng, base_color, accent, strength)
		"nephilim_ruins": _art4_nephilim(image, local_rng, base_color, accent, strength)
		_:
			pass
	_art4_story_marks(image, local_rng, biome, String(recipe.get("story_beat", "")), base_color, accent)
	return image

func _art4_industrial(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, strength: float) -> void:
	# Long structural channels and inset hatches create lab architecture without wallpaper tiling.
	for channel_index: int in range(2):
		var horizontal: bool = channel_index == 0 or rng.randf() > 0.45
		if horizontal:
			var y: int = rng.randi_range(24, image.get_height() - 28)
			var h: int = rng.randi_range(4, 7)
			image.fill_rect(Rect2i(0, y, image.get_width(), h), Color(base.darkened(0.38), 0.95))
			image.fill_rect(Rect2i(0, y + 1, image.get_width(), maxi(1, h - 2)), Color(accent.darkened(0.35), 0.20 + 0.16 * strength))
		else:
			var x: int = rng.randi_range(32, image.get_width() - 36)
			image.fill_rect(Rect2i(x, 0, 5, image.get_height()), Color(base.darkened(0.36), 0.94))
			image.fill_rect(Rect2i(x + 2, 0, 1, image.get_height()), Color(accent, 0.16))
	for hatch_index: int in range(3):
		var w: int = rng.randi_range(32, 58)
		var h: int = rng.randi_range(18, 30)
		var x: int = rng.randi_range(12, image.get_width() - w - 12)
		var y: int = rng.randi_range(12, image.get_height() - h - 12)
		var hatch: Rect2i = Rect2i(x, y, w, h)
		image.fill_rect(hatch, base.lightened(0.025))
		_draw_rect_outline(image, hatch, base.darkened(0.34), 2)
		image.fill_rect(Rect2i(x + 6, y + int(h / 2), maxi(4, w - 12), 2), Color(accent, 0.20))
	for growth_index: int in range(4):
		var root: Vector2i = Vector2i(rng.randi_range(8, image.get_width() - 9), rng.randi_range(8, image.get_height() - 9))
		var bend: Vector2i = root + Vector2i(rng.randi_range(-16, 16), rng.randi_range(-20, 20))
		_line(image, root, bend, Color(0.22, 0.42, 0.20, 0.48), 2)
		_circle_pixels(image, bend, rng.randi_range(2, 4), Color(0.36, 0.58, 0.29, 0.48))

func _art4_ash(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, strength: float) -> void:
	var lane_y: int = rng.randi_range(55, image.get_height() - 58)
	image.fill_rect(Rect2i(0, lane_y - 14, image.get_width(), 28), Color(base.darkened(0.08), 0.96))
	for dash_index: int in range(8):
		var x: int = 12 + dash_index * 40 + rng.randi_range(-5, 5)
		image.fill_rect(Rect2i(x, lane_y, 20, 2), Color(0.62, 0.49, 0.30, 0.22))
	for crater_index: int in range(4):
		var c: Vector2i = Vector2i(rng.randi_range(18, image.get_width() - 19), rng.randi_range(18, image.get_height() - 19))
		var radius: int = rng.randi_range(7, 15)
		_circle_pixels(image, c, radius, Color(base.darkened(0.28), 0.52))
		_circle_outline_pixels(image, c, radius, Color(accent.darkened(0.30), 0.24 + 0.10 * strength))
	for rebar_index: int in range(8):
		var start: Vector2i = Vector2i(rng.randi_range(8, image.get_width() - 9), rng.randi_range(8, image.get_height() - 9))
		var finish: Vector2i = start + Vector2i(rng.randi_range(-12, 12), rng.randi_range(-8, 8))
		_line(image, start, finish, Color(0.45, 0.25, 0.16, 0.50), 1)

func _art4_temple(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, strength: float) -> void:
	var center: Vector2i = Vector2i(image.get_width() / 2 + rng.randi_range(-24, 24), image.get_height() / 2 + rng.randi_range(-18, 18))
	for radius_variant in [18, 30, 44]:
		var radius: int = int(radius_variant)
		_circle_outline_pixels(image, center, radius, Color(accent, 0.14 + 0.08 * strength))
	for spoke_index: int in range(8):
		var angle: float = TAU * float(spoke_index) / 8.0
		var inner: Vector2i = center + Vector2i(roundi(cos(angle) * 16.0), roundi(sin(angle) * 16.0))
		var outer: Vector2i = center + Vector2i(roundi(cos(angle) * 50.0), roundi(sin(angle) * 50.0))
		_line(image, inner, outer, Color(accent, 0.16), 1)
	for machine_index: int in range(3):
		var w: int = rng.randi_range(22, 36)
		var h: int = rng.randi_range(28, 48)
		var x: int = rng.randi_range(8, image.get_width() - w - 8)
		var y: int = rng.randi_range(8, image.get_height() - h - 8)
		var machine: Rect2i = Rect2i(x, y, w, h)
		image.fill_rect(machine, base.darkened(0.10))
		_draw_rect_outline(image, machine, Color(accent, 0.28), 1)
		image.fill_rect(Rect2i(x + int(w / 2), y + 4, 1, h - 8), Color(accent, 0.24))

func _art4_fungal(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, strength: float) -> void:
	for vein_index: int in range(7):
		var start: Vector2i = Vector2i(rng.randi_range(10, image.get_width() - 11), rng.randi_range(10, image.get_height() - 11))
		var current: Vector2i = start
		for segment_index: int in range(4):
			var next: Vector2i = current + Vector2i(rng.randi_range(-18, 18), rng.randi_range(-13, 13))
			_line(image, current, next, Color(accent, 0.22 + 0.12 * strength), 2)
			current = next
		_circle_pixels(image, current, rng.randi_range(2, 4), Color(accent.lightened(0.12), 0.44))
	for pool_index: int in range(4):
		var c: Vector2i = Vector2i(rng.randi_range(16, image.get_width() - 17), rng.randi_range(16, image.get_height() - 17))
		var radius: int = rng.randi_range(7, 14)
		_circle_pixels(image, c, radius, Color(accent.darkened(0.38), 0.32))
		_circle_outline_pixels(image, c, radius, Color(accent, 0.34))
		for bud_index: int in range(3):
			var angle: float = TAU * float(bud_index) / 3.0
			var bud: Vector2i = c + Vector2i(roundi(cos(angle) * float(radius + 3)), roundi(sin(angle) * float(radius + 3)))
			_circle_pixels(image, bud, 2, Color(accent.lightened(0.18), 0.62))

func _art4_nephilim(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, strength: float) -> void:
	var causeway_y: int = rng.randi_range(48, image.get_height() - 52)
	image.fill_rect(Rect2i(0, causeway_y - 10, image.get_width(), 20), base.lightened(0.025))
	image.fill_rect(Rect2i(0, causeway_y - 11, image.get_width(), 2), base.darkened(0.38))
	image.fill_rect(Rect2i(0, causeway_y + 9, image.get_width(), 2), base.darkened(0.38))
	for monolith_index: int in range(4):
		var w: int = rng.randi_range(18, 32)
		var h: int = rng.randi_range(30, 60)
		var x: int = rng.randi_range(12, image.get_width() - w - 12)
		var y: int = rng.randi_range(8, image.get_height() - h - 8)
		var slab: Rect2i = Rect2i(x, y, w, h)
		image.fill_rect(slab, base.lightened(0.035))
		_draw_rect_outline(image, slab, base.darkened(0.34), 2)
		_circle_outline_pixels(image, slab.get_center(), maxi(4, int(mini(w, h) * 0.18)), Color(accent, 0.20 + 0.08 * strength))
	for rib_index: int in range(6):
		var root: Vector2i = Vector2i(rng.randi_range(8, image.get_width() - 9), image.get_height() - 6)
		var peak: Vector2i = root + Vector2i(rng.randi_range(-12, 12), -rng.randi_range(16, 46))
		_line(image, root, peak, Color(0.67, 0.62, 0.52, 0.28), 3)

func _art4_story_marks(image: Image, rng: RandomNumberGenerator, biome: String, story_beat: String, base: Color, accent: Color) -> void:
	var marker: Vector2i = Vector2i(rng.randi_range(30, image.get_width() - 31), rng.randi_range(24, image.get_height() - 25))
	if biome == "industrial_eden" and story_beat == "failed_greenhouse":
		var greenhouse: Rect2i = Rect2i(marker.x - 16, marker.y - 10, 32, 20)
		_draw_rect_outline(image, greenhouse, Color(accent, 0.38), 2)
		for plant_index: int in range(4):
			var p: Vector2i = Vector2i(greenhouse.position.x + 6 + plant_index * 7, greenhouse.end.y - 3)
			_line(image, p, p - Vector2i(0, rng.randi_range(5, 10)), Color(0.33, 0.55, 0.29, 0.62), 2)
	elif biome == "ash_wastes" and story_beat == "burned_convoy":
		var wreck: Rect2i = Rect2i(marker.x - 18, marker.y - 9, 36, 18)
		image.fill_rect(wreck, base.darkened(0.30))
		_draw_rect_outline(image, wreck, Color(0.46, 0.24, 0.15, 0.50), 2)
		_circle_pixels(image, wreck.position + Vector2i(7, wreck.size.y), 4, Color(0.08, 0.07, 0.06, 0.8))
		_circle_pixels(image, wreck.position + Vector2i(wreck.size.x - 7, wreck.size.y), 4, Color(0.08, 0.07, 0.06, 0.8))
	elif biome == "temple_lab" and story_beat == "ritual_terminal":
		_circle_outline_pixels(image, marker, 16, Color(accent, 0.42))
		_circle_outline_pixels(image, marker, 8, Color(accent.lightened(0.15), 0.34))
	elif biome == "fungal_garden" and story_beat == "fruiting_nursery":
		for fruit_index: int in range(6):
			var angle: float = TAU * float(fruit_index) / 6.0
			var fruit: Vector2i = marker + Vector2i(roundi(cos(angle) * 12.0), roundi(sin(angle) * 8.0))
			_circle_pixels(image, fruit, 3, Color(accent.lightened(0.18), 0.68))
	elif biome == "nephilim_ruins" and story_beat == "buried_colossus":
		_circle_outline_pixels(image, marker, 18, Color(0.70, 0.65, 0.54, 0.30))
		_line(image, marker - Vector2i(20, 0), marker + Vector2i(20, 0), Color(base.darkened(0.35), 0.85), 3)

func audit_contract() -> Dictionary:
	var report: Dictionary = super.audit_contract()
	report["art4_world_version"] = ART4_WORLD_VERSION
	report["story_beat_families"] = STORY_BEATS.size()
	report["landmark_rich_rooms"] = true
	report["layered_floor_architecture"] = true
	report["environmental_story_marks"] = true
	report["quiet_noise_rich_macro_detail"] = true
	report["biome_specific_structural_grammar"] = true
	return report
