extends SceneTree

const ForgeScript: Script = preload("res://scripts/v8/procedural_sprite_forge_art4.gd")
const GenomeScript: Script = preload("res://scripts/v8/enemy_genome_director_art4.gd")
const WorldScript: Script = preload("res://scripts/v8/procedural_world_director_art4.gd")

const REVISION: String = "0.6.4-authored-art4"
const FRAME: int = 48
const DIRECTIONS: int = 8
const STATES: int = 4
const LINEAGES: Array[String] = ["adam", "abel", "cain", "seth", "naamah"]
const BIOMES: Array[String] = ["industrial_eden", "ash_wastes", "temple_lab", "fungal_garden", "nephilim_ruins"]
const ENEMIES: Array[Dictionary] = [
	{"id":"feral_scavenger", "category":"preadamic", "role":"melee"},
	{"id":"outlaw_gunner", "category":"preadamic", "role":"ranged"},
	{"id":"raider_brute", "category":"preadamic", "role":"charger"},
	{"id":"scrap_cultist", "category":"preadamic", "role":"caster"},
	{"id":"caravan_outlaw", "category":"preadamic", "role":"skirmisher"},
	{"id":"cherub_drone", "category":"fallen", "role":"orbiter"},
	{"id":"grafted_colossus", "category":"nephilim", "role":"radial"},
]

func _cell(sheet: Image, frame_index: int, direction_index: int, frame_size: int = FRAME) -> Image:
	return sheet.get_region(Rect2i(frame_index * frame_size, direction_index * frame_size, frame_size, frame_size))

func _metrics(image: Image) -> Dictionary:
	var opaque: int = 0
	var colors: Dictionary = {}
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var color: Color = image.get_pixel(x, y)
			if color.a > 0.05:
				opaque += 1
				colors[hash(color)] = true
	var used: Rect2i = image.get_used_rect()
	return {
		"opaque": opaque,
		"colors": colors.size(),
		"used_width": used.size.x,
		"used_height": used.size.y,
	}

func _check_actor_cell(label: String, image: Image, errors: Array[String]) -> void:
	var metrics: Dictionary = _metrics(image)
	if int(metrics["opaque"]) < 40:
		errors.append(label + " has too little visible sprite mass")
	if int(metrics["opaque"]) > 1800:
		errors.append(label + " occupies implausibly much of a 48x48 cell")
	if int(metrics["colors"]) < 4:
		errors.append(label + " has insufficient palette/material separation")
	if int(metrics["used_width"]) < 8 or int(metrics["used_height"]) < 10:
		errors.append(label + " silhouette bounds are too small for gameplay readability")

func _direction_hashes(sheet: Image, frame_index: int, frame_size: int = FRAME) -> Dictionary:
	var hashes: Dictionary = {}
	for direction_index: int in range(DIRECTIONS):
		var region: Image = _cell(sheet, frame_index, direction_index, frame_size)
		hashes[hash(region.get_data())] = true
	return hashes

func _state_hashes(sheet: Image, direction_index: int, frame_size: int = FRAME) -> Dictionary:
	var hashes: Dictionary = {}
	for frame_index: int in range(STATES):
		var region: Image = _cell(sheet, frame_index, direction_index, frame_size)
		hashes[hash(region.get_data())] = true
	return hashes

func _init() -> void:
	var errors: Array[String] = []
	var forge: RefCounted = ForgeScript.new()
	var genomes: RefCounted = GenomeScript.new()
	var world: RefCounted = WorldScript.new()

	var hero_hashes: Dictionary = {}
	var hero_direction_diversity: Dictionary = {}
	var hero_state_diversity: Dictionary = {}
	for lineage: String in LINEAGES:
		var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
		var rng_b: RandomNumberGenerator = RandomNumberGenerator.new()
		rng_a.seed = 120001 + lineage.hash()
		rng_b.seed = 920001 + lineage.hash()
		var genome_a: Dictionary = genomes.call("player_genome", rng_a, lineage, 0)
		var genome_b: Dictionary = genomes.call("player_genome", rng_b, lineage, 4)
		var sheet_a: Image = forge.call("build_player_sheet", genome_a)
		var sheet_b: Image = forge.call("build_player_sheet", genome_b)
		if sheet_a == null or sheet_b == null or sheet_a.is_empty() or sheet_b.is_empty():
			errors.append("Hero sheet generation failed: " + lineage)
			continue
		if sheet_a.get_width() < FRAME * STATES or sheet_a.get_height() < FRAME * DIRECTIONS:
			errors.append("Hero sheet is below Art4 state/direction ABI: " + lineage)
			continue
		if hash(sheet_a.get_data()) != hash(sheet_b.get_data()):
			errors.append("Canonical hero pixels vary across unrelated RNG/biome state: " + lineage)
		hero_hashes[hash(sheet_a.get_data())] = true

		for state_index: int in range(STATES):
			_check_actor_cell("hero:%s:state:%d" % [lineage, state_index], _cell(sheet_a, state_index, 2), errors)
		var state_hashes: Dictionary = _state_hashes(sheet_a, 2)
		var direction_hashes: Dictionary = _direction_hashes(sheet_a, 0)
		hero_state_diversity[lineage] = state_hashes.size()
		hero_direction_diversity[lineage] = direction_hashes.size()
		if state_hashes.size() < 3:
			errors.append("Hero does not have at least three materially distinct action states: " + lineage)
		if direction_hashes.size() < 4:
			errors.append("Hero directional silhouettes collapse excessively: " + lineage)

	if hero_hashes.size() != LINEAGES.size():
		errors.append("Five canonical heroes are not pixel-unique")

	var enemy_hashes: Dictionary = {}
	var enemy_state_diversity: Dictionary = {}
	for sample: Dictionary in ENEMIES:
		var id: String = String(sample["id"])
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 330001 + id.hash()
		var genome: Dictionary = genomes.call(
			"generate", rng, id, String(sample["category"]), String(sample["role"]), 2, 1.5, false, false
		)
		var sheet: Image = forge.call("build_enemy_sheet", genome)
		if sheet == null or sheet.is_empty():
			errors.append("Enemy sheet generation failed: " + id)
			continue
		if sheet.get_width() < FRAME * STATES or sheet.get_height() < FRAME * DIRECTIONS:
			errors.append("Enemy sheet is below Art4 state/direction ABI: " + id)
			continue
		for state_index: int in range(STATES):
			_check_actor_cell("enemy:%s:state:%d" % [id, state_index], _cell(sheet, state_index, 2), errors)
		var states: Dictionary = _state_hashes(sheet, 2)
		enemy_state_diversity[id] = states.size()
		if states.size() < 2:
			errors.append("Enemy action states collapse: " + id)
		enemy_hashes[hash(sheet.get_data())] = true
	if enemy_hashes.size() != ENEMIES.size():
		errors.append("Representative enemy families are not pixel-unique")

	var biome_hashes: Dictionary = {}
	var biome_quadrant_diversity: Dictionary = {}
	for biome_index: int in range(BIOMES.size()):
		var biome: String = BIOMES[biome_index]
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 770001 + biome_index * 1709
		var recipe: Dictionary = world.call("make_room_recipe", rng, biome, "combat", 1.5, Vector2(1280, 720))
		var base: Color = Color8(20 + biome_index * 5, 28 + biome_index * 3, 28 + biome_index * 4)
		var accent: Color = [Color8(113,159,107), Color8(192,113,61), Color8(84,160,164), Color8(177,94,165), Color8(152,122,179)][biome_index]
		var floor: Image = world.call("build_floor_image", recipe, base, accent)
		if floor == null or floor.is_empty() or floor.get_size() != Vector2i(320, 180):
			errors.append("Biome floor generation failed ABI: " + biome)
			continue
		biome_hashes[hash(floor.get_data())] = true
		var quadrants: Dictionary = {}
		for qy: int in range(2):
			for qx: int in range(2):
				var region: Image = floor.get_region(Rect2i(qx * 160, qy * 90, 160, 90))
				quadrants[hash(region.get_data())] = true
		biome_quadrant_diversity[biome] = quadrants.size()
		if quadrants.size() < 2:
			errors.append("Biome macro surface is effectively repeated wallpaper: " + biome)
		var sample_colors: Dictionary = {}
		for y: int in range(0, floor.get_height(), 12):
			for x: int in range(0, floor.get_width(), 12):
				sample_colors[hash(floor.get_pixel(x, y))] = true
		if sample_colors.size() < 4:
			errors.append("Biome sampled palette/material variation is too flat: " + biome)
	if biome_hashes.size() != BIOMES.size():
		errors.append("Five biome surfaces are not pixel-unique")

	var report: Dictionary = {
		"revision": REVISION,
		"hero_uniqueness": hero_hashes.size(),
		"hero_direction_diversity": hero_direction_diversity,
		"hero_state_diversity": hero_state_diversity,
		"enemy_family_uniqueness": enemy_hashes.size(),
		"enemy_state_diversity": enemy_state_diversity,
		"biome_uniqueness": biome_hashes.size(),
		"biome_quadrant_diversity": biome_quadrant_diversity,
		"errors": errors,
		"passed": errors.is_empty(),
	}
	print("EDEN_FALL_V8_ART4_PIXEL_COUNTERAUDIT_REPORT=" + JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V8_ART4_PIXEL_COUNTERAUDIT=PASS")
		quit(0)
	else:
		for message: String in errors:
			push_error(message)
		quit(1)
